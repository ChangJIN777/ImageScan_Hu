#include "mex.h"
#include <windows.h>
#include <stdio.h>
#include <process.h>
#include <string>
#include <vector>
#include "Serial.h" // serial.h must come before handles.h
#include "DAC.h"
#include "scan.h"
#include "handles.h"
#include "bestfit.h"
#include "Madlib.h"

DAC _DAC;
scan _scan;
planeInfo _planeInfo;
handles _handles;

bool measure;
bool is_surface;
bool is_thread;
bool is_surface_flagged;

double current_bridge;
std::vector<double> bridge_data;
double current_phase;
std::vector<double> phase_data;

double min_flag;
double max_flag;

double x_pos;
double y_pos;
double axes_min;
double axes_max;
bool is_button_down;
bool is_min_move;
bool is_max_move;

double approach_min;
double approach_max;
double approach_rate;
double approach_retract;


static mxArray* mxy_data;
double* y_data;
static mxArray* mxtheta_data;
double* theta_data;

HANDLE tip_read_thread;
HANDLE phase_read_thread;
HANDLE approach_thread_handle;
HANDLE check_approach_thread_handle;
HANDLE scan_thread_handle;
HANDLE micronix_approach_thread_handle;

double axes_handle;
double min_line_handle;
double max_line_handle;
double textbox_tip_volt_handle;
double textbox_min_volt_handle;
double textbox_max_volt_handle;
double thor_handle;
double z_in_disp_handle;

// added to adapt to the new mex file format (Chang Jin 12/7/21) =========
int axes_handle_index;
int min_line_handle_index;
int max_line_handle_index;
int textbox_tip_volt_handle_index;
int textbox_min_volt_handle_index;
int textbox_max_volt_handle_index;
int thor_handle_index;
int z_in_disp_handle_index;
// =======================================================================

int buffer;
int n_steps;
int cur_line;
bool is_scan;
bool direction;
bool filtered;
bool is_draw_tip_position;
bool is_enable_tip_position;

std::vector<plane_point> pp;
bool is_valid_plane;

UINT_PTR timer_graph,timer_readout,thor_timer,update_scan_timer,update_scan_data_timer,matlab_data_timer;
DWORD last_graph,last_readout;

bool is_step;

UINT_PTR MCL_timer;
int MCL_handle;
double MCL_x_pos,MCL_y_pos,MCL_z_pos;
bool is_MCL_readout;
HANDLE MCL_thread;

bool is_calibrate_thread;
HANDLE calibrate_handle;

int n_cal_pts;

bool is_update_scan_info;
bool is_update_scan_data;
bool is_update_MCL_readout;

double z_adder_calibration;

int which_zmotor; // 1=Thorlabs PT1-Z8, 2=micronix PPS-20 18 mm,
HANDLE Micronix_thread;
UINT_PTR Micronix_timer;
UINT_PTR Micronix_approach_timer;
bool is_Micronix_readout;
bool is_update_Micronix_readout;
bool is_Micronix_commanded;
char read_Micronix_x_pos[32];
char read_Micronix_y_pos[32];
char read_Micronix_z_pos[32];
int read_Micronix_which_axis;
double Micronix_approach_z_stepsize;

bool is_tracking;
bool is_tracking_complete;

double phase_mVPerDeg; 

void mexFunction(int nlhs, mxArray *plhs[],
	int nrhs, const mxArray*prhs[])

{
	char str[100];

	mxGetString(prhs[0], str, 100);

	std::string func_name(str);

	double* args;
	int nargs = nrhs - 1; // args has one less element than prhs 

	if (nrhs >= 1)
	{

		args = new double[nargs];

		for (int k = 0; k < nargs; k++)
		{
			args[k] = mxGetScalar(prhs[k + 1]); // args is shifted by 1 relative to prhs
		}
	}

// get_matlab_data() runs via a timer set in the mDAC "init" function
// but only excutes its contents given the flags which are set by the 
// scan.cpp subroutine "scan::scan_line_sequence"
void get_matlab_data()
{
    if(!_scan.is_matlab_data && _scan.is_measuring_matlab)
    {
		
        _scan.is_measuring_matlab = false;

		// by default the mxArray is lhs[1]: has been size 1
		// but for scanning pulse sequence measurements I want several channels
		// to be getting raw data from the sig1, sig2, ref1, ref2, etc...
		int numDataChan = _scan.num_matlab_chan;
        mxArray* lhs[7];
		//mxArray* rhs[1];
		//mwSize dm[2];
		//dm[0] = numDataChan;
		//dm[1] = 1; // dm is a dimensions array so it sets here a 4x1 matrix
		//mwSize dm2[2];
		//dm2[0] = 1;
		//dm2[1] = 1; // dm2 is a dimensions array, so it sets here a 1x1 matrix
		//lhs[0] = mxCreateNumericArray(1, dm, mxDOUBLE_CLASS, mxREAL); // if we set 1st arg ndim<2 it automatically sets it to 2
		//rhs[0] = mxCreateNumericArray(1, dm2, mxDOUBLE_CLASS, mxREAL); 
		//double rset[1];
		//rset[0] = numDatachan;
		//double* rhs_ptr = mxGetPr(rhs[0]);
		//rhs_ptr[0] = numDataChan;

        // this calls the scan_pulse_seq.m file in "ImageScan/ImageAquire"
        // the function "presses the start button" of the ESRControl pulse sequence
		//mexCallMATLAB(nlhs,plhs,nrhs,prhs[0],functionName)
        //mexCallMATLAB(numDataChan,lhs,1,rhs,"scan_pulse_seq_nchan");
		mexCallMATLAB(7, lhs, 0, NULL, "scan_pulse_seq_7chan");

        // store returned data array in the scan class
		// by default _scan.matlab_data has been a double scalar
		// for multiple data channels this needs to have been defined as an array or have many of them
		for (int j = 0; j < numDataChan; j++) {
			_scan.matlab_data[j]= mxGetScalar(lhs[j]);
			mxDestroyArray(lhs[j]);
		}

        _scan.is_matlab_data = true;
        _scan.is_measuring_matlab = true;


    }
    
}

void do_matlab_tracking()
{
	if (is_tracking)
	{
		is_tracking = false;
		mexCallMATLAB(0, NULL, 0, NULL, "scan_tracking");


		is_tracking_complete = true;
	}




}

void Thor_Step()
{
	/* Thor_Step is timed to occur every 100 ms
	but it does nothing unless is_step was turned to
	true to signal a required step during approach*/
   if(is_step)
   {
       
    // Send Message to ThorLabs executable
     HWND hwnd = FindWindow(NULL, "ThorLabsAPT");
    SendMessage(hwnd, WM_APP + 1001, NULL, NULL);
     is_step = false;
   }
    
    
}

void Micronix_approach_step()
{
   if(is_step)
   {
	   
	   // step the set amount for an approach 
	   // tip is below sample, so the MicronixZ must step
	   // in the down direction. this is Increment > 0
	   is_Micronix_commanded = true;
	   char mvrStr[50];
	   int numCharD = sprintf_s(mvrStr, 50, "%iMVR%1.6f\r", 3, Micronix_approach_z_stepsize);
	   _handles.Micronix_serial.SendData(mvrStr, numCharD); // MVR: move relative
	   Sleep(100);

	   is_Micronix_commanded = false;
	   is_step = false;
	   
   }   
    
}

// added by Chang 12/7/21 (wrapper function used to adapt the code for new versions of MATLAB
/*void mexSetProperty(MATLABobject, ) 
{
	
}*/

void CALLBACK update_graph(HWND hwnd,
    UINT uMsg,
    UINT_PTR idEvent,
    DWORD dwTime)
{
  // if(!measure) return;
   if(bridge_data.size() < buffer)
   {
       for(int j = 0; j < buffer; j++)
        {
              y_data[j] = 0;
         }
   }
        
   for(int j = 0; j < bridge_data.size(); j++)
    {
          y_data[buffer - 1 - j] = bridge_data[bridge_data.size() - 1 - j];
     }
   
    
    
    // mexSet(axes_handle, "YData", mxy_data); // updated by Chang 12/6/21 

	//---- for phase measurement
	if (phase_data.size() < buffer)
	{
		for (int j = 0; j < buffer; j++)
		{
			theta_data[j] = 0;
		}
	}

	for (int j = 0; j < phase_data.size(); j++)
	{
		theta_data[buffer - 1 - j] = phase_data[phase_data.size() - 1 - j];
	}

	mxSetProperty(prhs[_handles.phase_axes_index],0, "YData", mxtheta_data); 


	//-------------------------
      
    
    char disp_str[50];
	char step_str[16];

     mxArray* tip_volt;
	 mxArray* n_stepsmx;
     
    sprintf_s(disp_str,50,"%.3f mV",1000*y_data[buffer - 1]);
    tip_volt = mxCreateString(disp_str);
      mexMakeArrayPersistent(tip_volt);
	  mxSetProperty(prhs[textbox_tip_volt_handle_index],0, "String", tip_volt);

     mxDestroyArray(tip_volt);
     
       mxArray* min_volt;
     
    sprintf_s(disp_str,50,"%.3f mV",1000*min_flag);
    min_volt = mxCreateString(disp_str);
      mexMakeArrayPersistent(min_volt);
	  mxSetProperty(prhs[textbox_min_volt_handle_index],0, "String", min_volt);

     mxDestroyArray(min_volt);
     
      mxArray* max_volt;
     
    sprintf_s(disp_str,50,"%.3f mV",1000*max_flag);
    max_volt = mxCreateString(disp_str);
      mexMakeArrayPersistent(max_volt);
	  mxSetProperty(prhs[textbox_max_volt_handle_index],0, "String", max_volt);

     mxDestroyArray(max_volt);
     
      mxArray* z_in_disp;
     
      sprintf_s(disp_str,50,"%.3f",_DAC.z_in_current);
    z_in_disp = mxCreateString(disp_str);
      mexMakeArrayPersistent(z_in_disp);
	  mxSetProperty(prhs[z_in_disp_handle_index],0, "String", z_in_disp);

     mxDestroyArray(z_in_disp);

	 mxArray* mxphase_volt;
	 sprintf_s(disp_str, 50, "%.3f mV", 1000 * phase_data[buffer - 1]);
	 mxphase_volt = mxCreateString(disp_str);
	 mexMakeArrayPersistent(mxphase_volt);
	 mxSetProperty(prhs[_handles.phase_volt_index],0, "String", mxphase_volt);
	 mxDestroyArray(mxphase_volt);

	 mxArray* mxphase_deg;
	 sprintf_s(disp_str, 50, "%.3f", 1000 * (1/phase_mVPerDeg) * phase_data[buffer - 1]);
	 mxphase_deg = mxCreateString(disp_str);
	 mexMakeArrayPersistent(mxphase_deg);
	 mxSetProperty(prhs[_handles.phase_deg_index],0, "String", mxphase_deg);
	 mxDestroyArray(mxphase_deg);
     
         mxArray* off_str;
        off_str = mxCreateString("off");
        
        mxArray* on_str;
        on_str = mxCreateString("on");

		
    
      if(measure)
     {
       
       
        if(is_thread)
         {

            mxSetProperty(prhs[_handles.start_approach_handle_index],0,"Enable",off_str);
            mxSetProperty(prhs[_handles.stop_approach_handle_index],0,"Enable",on_str); 
            mxSetProperty(prhs[_handles.start_graph_handle_index],0,"Enable",off_str);
            mxSetProperty(prhs[_handles.stop_graph_handle_index],0,"Enable",off_str);  
			mxSetProperty(prhs[_handles.mic_radio_x_index],0, "Enable", off_str);
			mxSetProperty(prhs[_handles.mic_radio_y_index],0, "Enable", off_str);
			mxSetProperty(prhs[_handles.mic_radio_z_index],0, "Enable", off_str);

			sprintf_s(step_str, 16, "%i", n_steps);
			n_stepsmx = mxCreateString(step_str);
			mxSetProperty(prhs[_handles.mic_n_steps_index],0, "String", n_stepsmx);
         }
         else
         {
             mxSetProperty(prhs[_handles.start_graph_handle_index],0,"Enable",off_str);
			mxSetProperty(prhs[_handles.stop_graph_handle_index],0,"Enable",on_str);  
            mxSetProperty(prhs[_handles.start_approach_handle_index],0,"Enable",on_str);
            mxSetProperty(prhs[_handles.stop_approach_handle_index],0,"Enable",off_str);
			mxSetProperty(prhs[_handles.mic_radio_x_index],0, "Enable", on_str);
			mxSetProperty(prhs[_handles.mic_radio_y_index],0, "Enable", on_str);
			mxSetProperty(prhs[_handles.mic_radio_z_index],0, "Enable", on_str);

         }
     }
     else
     {
        mxSetProperty(prhs[_handles.start_graph_handle_index],0,"Enable",on_str);
        mxSetProperty(prhs[_handles.stop_graph_handle_index],0,"Enable",off_str);
        mxSetProperty(prhs[_handles.start_approach_handle_index],0,"Enable",off_str);
        mxSetProperty(prhs[_handles.stop_approach_handle_index],0,"Enable",off_str);  
     }
        
    
      mxDestroyArray(off_str);
      mxDestroyArray(on_str);
	  mxDestroyArray(n_stepsmx);
    
}


void get_dac_data()
{
	int count = 0;
	float* DAC_out;
	while(measure)
	{
		DAC_out = _DAC.approach_check();
    		current_bridge = DAC_out[1];
			current_phase = DAC_out[2];
            count++;
       

			// printf("%d\r\n",count);
		//if( (count % 5) == 0) 
		//	{
				bridge_data.push_back(current_bridge);
				if(bridge_data.size() == (buffer + 1) ) 
				{
                    bridge_data.erase(bridge_data.begin());
                }


				// test only
				phase_data.push_back(current_phase);
				if (phase_data.size() == (buffer + 1))
				{
					phase_data.erase(phase_data.begin());
				}
         //  }
    
	}

	return;
}

/*void get_dac_phase_data()
{
	int count = 0;
	while (measure)
	{
		current_phase = _DAC.phase_check();
		count++;


		// printf("%d\r\n",count);
		//if( (count % 5) == 0) 
		//	{

		phase_data.push_back(current_phase);
		if (phase_data.size() == (buffer + 1))
		{
			phase_data.erase(phase_data.begin());
		}
		//  }

	}

	return;

}*/

void approach_thread()
{
	
	is_surface = false;

	if((_DAC.z_in_current) <= 0.1)
	{
		HANDLE z_in_thread = _DAC.z_in(approach_min);
		WaitForSingleObject(z_in_thread,INFINITE);
	}
	while(!is_surface && is_thread)
	{
		_DAC.z_sweep(_DAC.z_in_current,approach_max,approach_rate);
		
        if(_DAC.is_sweep_aborted) //Sweep has been stopped by a surface flag
        {
            while(is_surface_flagged) //Wait for check_approach thread to determine if surface is real or not
            {
                Sleep(10);
            }
            
            if(is_surface)
            {
                return;
            }  
        }
        
		if(is_thread && !_DAC.is_sweep_aborted) 
		{
			
			HANDLE z_in_thread = _DAC.z_in(approach_min);
			WaitForSingleObject(z_in_thread,INFINITE);
			
			is_step = true;
            while(is_step) Sleep(1000); //Wait for step to happen
			
			n_steps++;
			
		}
	}
	

}

void check_approach_thread()
{
	while(1)
	{
		if(current_bridge < min_flag || current_bridge > max_flag)
		{	
            _DAC.stop_sweep(); //PAUSE Z MOTION
            is_surface_flagged = true;
			int test = 0;
			for(int j = 0; j < 5; j++)
			{
                
				Sleep(50);
				if(current_bridge < min_flag || current_bridge > max_flag) test++; 
				
			}
			if(test == 5)
			{
				is_surface = true;
				
				// Close approach thread

				if(is_thread)
				{
					_DAC.z_in(_DAC.z_in_current-approach_retract);
					_DAC.stop_sweep();
					is_thread = false;
					if (which_zmotor == 1){
						KillTimer(NULL, thor_timer);
					}
					else if (which_zmotor == 2){
						KillTimer(NULL, Micronix_approach_timer);
					}
				}
        
			}
			else
			{
                is_surface_flagged = false;
				is_surface = false;
			}
		}
		else
		{
			is_surface = false;
		}
		Sleep(10);
	}

}

void update_scan_info()
{
    if(!is_update_scan_info) return;
     char disp_str[50];
     mxArray* disp_array;
     
    sprintf_s(disp_str,50,"%.4f V",_scan.x_tip);
    disp_array = mxCreateString(disp_str);
     mxSetProperty(prhs[_handles.x_tip_position_index],0,"String",disp_array);  
     mxDestroyArray(disp_array);

     
    sprintf_s(disp_str,50,"%.4f V",_scan.y_tip);
    disp_array = mxCreateString(disp_str);
     mxSetProperty(prhs[_handles.y_tip_position_index],0,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
     double x_size = (_scan.x_max - _scan.x_min);
     
       sprintf_s(disp_str,50,"%.4f V",x_size);
    disp_array = mxCreateString(disp_str);
     mxSetProperty(prhs[_handles.x_scan_size_index],0,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
      double y_size = (_scan.y_max - _scan.y_min);
     
       sprintf_s(disp_str,50,"%.4f V",y_size);
    disp_array = mxCreateString(disp_str);
     mxSetProperty(prhs[_handles.y_scan_size_index],0,"String",disp_array);  
     
     mxDestroyArray(disp_array);
    
     
       sprintf_s(disp_str,50,"%.4f V",_scan.x_center);
    disp_array = mxCreateString(disp_str);
     mxSetProperty(prhs[_handles.x_scan_center_index],0,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
       sprintf_s(disp_str,50,"%.4f V",_scan.y_center);
    disp_array = mxCreateString(disp_str);
     mxSetProperty(prhs[_handles.y_scan_center_index],0,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
     
     sprintf_s(disp_str,50,"%d Hz",(int)_scan.freq);
    disp_array = mxCreateString(disp_str);
     mxSetProperty(prhs[_handles.scan_speed_index],0,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
      sprintf_s(disp_str,50,"%d",_scan.nx_step);
    disp_array = mxCreateString(disp_str);
     mxSetProperty(prhs[_handles.x_points_index],0,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
       sprintf_s(disp_str,50,"%d",_scan.ny_step);
    disp_array = mxCreateString(disp_str);
    mxSetProperty(prhs[_handles.y_points_index],0,"String",disp_array);  
     
    mxDestroyArray(disp_array);
     
    mxArray* off_str;
    off_str = mxCreateString("off");
        
    mxArray* on_str;
    on_str = mxCreateString("on");
    
     
    if(is_scan)
    {

        mxSetProperty(prhs[_handles.start_scan_handle_index],0,"Enable",off_str);
        mxSetProperty(prhs[_handles.stop_scan_handle_index],0,"Enable",on_str);  
    }
     else
     {
    
        mxSetProperty(prhs[_handles.start_scan_handle_index],0,"Enable",on_str);
        mxSetProperty(prhs[_handles.stop_scan_handle_index],0,"Enable",off_str);
 
     }
        
    if(is_valid_plane)
    {
        mxSetProperty(prhs[_handles.snap_plane_handle_index],0,"Enable",on_str);
     
    }
    else
    {
        mxSetProperty(prhs[_handles.snap_plane_handle_index],0,"Enable",off_str);
    }
    
    
      mxDestroyArray(off_str);
      mxDestroyArray(on_str);
    
}
void update_scan_data()
{
 if(!is_update_scan_data) return;
    mxArray* str;
 
 str = mxCreateString("on");
 
 mxSetProperty(prhs[],0,"Visible",str);
 
 mxDestroyArray(str);

    
 mxArray* scan_data;
 mxArray* c_data;
 mxArray* x_data;
 mxArray* y_data;
 
 mwSize dims[2] = {_scan.ny_step,_scan.nx_step};
 mwSize x_dim[2] = {1,_scan.nx_step};
 mwSize y_dim[2] = {1,_scan.ny_step};
 
 x_data = mxCreateNumericArray(2,x_dim,mxDOUBLE_CLASS,mxREAL);
 y_data = mxCreateNumericArray(2,y_dim,mxDOUBLE_CLASS,mxREAL);
 scan_data  = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
 c_data  = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
 
double* x_data_ptr = mxGetPr(x_data);
double* y_data_ptr = mxGetPr(y_data);

 double* set_data = mxGetPr(scan_data);
 double* set_c_data = mxGetPr(c_data);
 
 for(int i = 0; i < _scan.nx_step; i++)
 {
    x_data_ptr[i] = _scan.x_min + (_scan.x_max - _scan.x_min)/(_scan.nx_step - 1)*i;
 }
 
 for(int j = 0; j < _scan.ny_step; j++)
    {
       y_data_ptr[j] = _scan.y_min + (_scan.y_max - _scan.y_min)/(_scan.ny_step - 1)*j;
    }
 double** current_data = _scan.get_data();


 
 mwSize nsubs = 2;
 mwIndex subs[2];
 
 for(int i = 0; i < _scan.nx_step; i++)
 {
    for(int j = 0; j < _scan.ny_step; j++)
    {
        subs[0] = j;
        subs[1] = i;
        
        set_data[mxCalcSingleSubscript(scan_data,nsubs,subs)] = current_data[i][j];
        
        double color = current_data[i][j];
        if(color > *(_scan.z_max)) color = *(_scan.z_max);
        if(color < *(_scan.z_min)) color = *(_scan.z_min);
        
        set_c_data[mxCalcSingleSubscript(c_data,nsubs,subs)] = color;
    }
 }
 
   mxArray* off_str;
     off_str = mxCreateString("off");
     
      mxArray* on_str;
      on_str = mxCreateString("on");
 

 //Draw current scan line
 if(is_scan)
 {
        mxArray* x_line_data;
        mwSize x_line_dim[2] = {1,2};
       x_line_data = mxCreateNumericArray(2,x_line_dim,mxDOUBLE_CLASS,mxREAL);
       double* x_line_data_ptr = mxGetPr(x_line_data);
       
       x_line_data_ptr[0] = _scan.x_min;
       x_line_data_ptr[1] = _scan.x_max;
       
       mxArray* y_line_data;
        mwSize y_line_dim[2] = {1,2};
       y_line_data = mxCreateNumericArray(2,y_line_dim,mxDOUBLE_CLASS,mxREAL);
       double* y_line_data_ptr = mxGetPr(y_line_data);
       
       y_line_data_ptr[0] = y_data_ptr[cur_line];
       y_line_data_ptr[1] = y_data_ptr[cur_line];
       
        mxArray* z_line_data;
        mwSize z_line_dim[2] = {1,2};
       z_line_data = mxCreateNumericArray(2,z_line_dim,mxDOUBLE_CLASS,mxREAL);
       double* z_line_data_ptr = mxGetPr(z_line_data);
       
      
       z_line_data_ptr[0] = 1e6;
       z_line_data_ptr[1] = 1e6;

      
     
    mxSetProperty(prhs[_handles.cur_line_handle_index],0,"XData",x_line_data);
    mxSetProperty(prhs[_handles.cur_line_handle_index],0,"YData",y_line_data);
    mxSetProperty(prhs[_handles.cur_line_handle_index],0,"ZData",z_line_data);
    mxSetProperty(prhs[_handles.cur_line_handle_index],0,"Visible",on_str);
    
    mxDestroyArray(x_line_data);
    mxDestroyArray(y_line_data);
    mxDestroyArray(z_line_data);
    
     
 }
 else
 {
      
       
      mxSetProperty(prhs[_handles.cur_line_handle_index],0,"Visible",off_str);

     
 }
 
 //Draw current tip position
 if(is_draw_tip_position)
 {
       mxArray* x_tip_data;
       mwSize x_tip_dim[2] = {1,2};
       x_tip_data = mxCreateNumericArray(2,x_tip_dim,mxDOUBLE_CLASS,mxREAL);
       double* x_tip_data_ptr = mxGetPr(x_tip_data);
       
       mxArray* y_tip_data;
       mwSize y_tip_dim[2] = {1,2};
       y_tip_data = mxCreateNumericArray(2,y_tip_dim,mxDOUBLE_CLASS,mxREAL);
       double* y_tip_data_ptr = mxGetPr(y_tip_data);
       
       mxArray* z_tip_data;
       mwSize z_tip_dim[2] = {1,2};
       z_tip_data = mxCreateNumericArray(2,z_tip_dim,mxDOUBLE_CLASS,mxREAL);
       double* z_tip_data_ptr = mxGetPr(z_tip_data);
       
       x_tip_data_ptr[0] = _scan.x_min;
       x_tip_data_ptr[1] = _scan.x_max;  
       
       if(_scan.y_tip < _scan.y_min)
       {
            y_tip_data_ptr[0] = _scan.y_min;
            y_tip_data_ptr[1] = _scan.y_min; 
       }
       else if(_scan.y_tip > _scan.y_max)
       {
           y_tip_data_ptr[0] = _scan.y_max;
           y_tip_data_ptr[1] = _scan.y_max;  
       }
       else
       {
           y_tip_data_ptr[0] = _scan.y_tip;
           y_tip_data_ptr[1] = _scan.y_tip;    
       }
          
     
       
       z_tip_data_ptr[0] = 1e6;
       z_tip_data_ptr[1] = 1e6;
       
        mxSetProperty(prhs[_handles.tip_position_x_handle_index],0,"XData",x_tip_data);
        mxSetProperty(prhs[_handles.tip_position_x_handle_index],0,"YData",y_tip_data);
        mxSetProperty(prhs[_handles.tip_position_x_handle_index],0,"ZData",z_tip_data);
        
       if(_scan.x_tip < _scan.x_min)
       {
            x_tip_data_ptr[0] = _scan.x_min;
            x_tip_data_ptr[1] = _scan.x_min;     
       }
       else if(_scan.x_tip > _scan.x_max)
       {
            x_tip_data_ptr[0] = _scan.x_max;
            x_tip_data_ptr[1] = _scan.x_max;       
       }
       else
       {
            x_tip_data_ptr[0] = _scan.x_tip;
            x_tip_data_ptr[1] = _scan.x_tip;               
       }
       
       
       y_tip_data_ptr[0] = _scan.y_min;
       y_tip_data_ptr[1] = _scan.y_max;
       
        mxSetProperty(prhs[_handles.tip_position_y_handle_index],0,"XData",x_tip_data);
        mxSetProperty(prhs[_handles.tip_position_y_handle_index],0,"YData",y_tip_data);
        mxSetProperty(prhs[_handles.tip_position_y_handle_index],0,"ZData",z_tip_data);
        
        mxArray* green_str;
        mxArray* blue_str;
        mxArray* red_str;
        
        green_str = mxCreateString("green");
        blue_str = mxCreateString("blue");
        red_str = mxCreateString("red");
        
        if(is_enable_tip_position)
        {
             mxSetProperty(prhs[_handles.tip_position_x_handle_index],0,"Color",green_str);
             mxSetProperty(prhs[_handles.tip_position_y_handle_index],0,"Color",green_str);
        }
        else
        {
            if(_scan.x_tip < _scan.x_min || _scan.x_tip > _scan.x_max || _scan.y_tip < _scan.y_min || _scan.y_tip > _scan.y_max)
            {
                mxSetProperty(prhs[_handles.tip_position_x_handle_index],0,"Color",red_str);
                mxSetProperty(prhs[_handles.tip_position_y_handle_index],0,"Color",red_str);
                
            }
            else
            {
                mxSetProperty(prhs[_handles.tip_position_x_handle_index],0,"Color",blue_str);
                mxSetProperty(prhs[_handles.tip_position_y_handle_index],0,"Color",blue_str);   
            }
            
            
        }
     
      mxSetProperty(prhs[_handles.tip_position_x_handle_index],0,"Visible",on_str);
       mxSetProperty(prhs[_handles.tip_position_y_handle_index],0,"Visible",on_str);
       
       mxDestroyArray(x_tip_data);
       mxDestroyArray(y_tip_data);
       mxDestroyArray(z_tip_data);
       mxDestroyArray(green_str);
       mxDestroyArray(blue_str);
       mxDestroyArray(red_str);
     
 }
 else
 {
     mxSetProperty(prhs[_handles.tip_position_x_handle_index],0,"Visible",off_str);
       mxSetProperty(prhs[_handles.tip_position_y_handle_index],0,"Visible",off_str);
     
 }
      
       mxDestroyArray(on_str);
       mxDestroyArray(off_str);
       
       //Set axes limits
 mxArray* x_lim;
 mxArray* y_lim;
 
 mwSize lim_size[2] = {1,2};
 
 x_lim = mxCreateNumericArray(2,lim_size,mxDOUBLE_CLASS,mxREAL);
 double* x_lim_ptr = mxGetPr(x_lim);
 
 x_lim_ptr[0] = x_data_ptr[0];
 x_lim_ptr[1] = x_data_ptr[_scan.nx_step - 1];
 
  
 y_lim = mxCreateNumericArray(2,lim_size,mxDOUBLE_CLASS,mxREAL);
 double* y_lim_ptr = mxGetPr(y_lim);
 
 y_lim_ptr[0] = y_data_ptr[0];
 y_lim_ptr[1] = y_data_ptr[_scan.ny_step - 1];
 
 mxArray* xrhs[1];
  mxArray* yrhs[1];
  
 
 xrhs[1] = x_lim;
 yrhs[1] = y_lim;
  
 // mexCallMATLAB(0,NULL,1,xrhs,"xlim");
 // mexCallMATLAB(0,NULL,1,yrhs,"ylim");
   mxSetProperty(prhs[_handles.scan_grid_handle_index],0,"XLim",x_lim);
   mxSetProperty(prhs[_handles.scan_grid_handle_index],0,"YLim",y_lim);
 
  mxDestroyArray(x_lim);
  mxDestroyArray(y_lim);
       

 mxSetProperty(prhs[_handles.scan_axes_handle_index],0,"XData",x_data);
 mxSetProperty(prhs[_handles.scan_axes_handle_index],0,"YData",y_data);
 mxSetProperty(prhs[_handles.scan_axes_handle_index],0,"ZData",scan_data);
  mxSetProperty(prhs[_handles.scan_axes_handle_index],0,"CData",c_data);
 //Set scaling for colormap
  /* mxArray* color_data;
       mwSize color_dim[2] = {1,2};
       color_data = mxCreateNumericArray(2,color_dim,mxDOUBLE_CLASS,mxREAL);
       double* color_data_ptr = mxGetPr(color_data);
       
       color_data_ptr[0] = *(_scan.z_min);
       color_data_ptr[1] = *(_scan.z_max);
      
       
 
  mxSetProperty(prhs[_handles.scan_axes_handle_index],0,"CLim",color_data);
 
 mxDestroyArray(color_data);
  */ 
  
    
  
 
     mxDestroyArray(x_data);
   mxDestroyArray(y_data);
  
 mxDestroyArray(scan_data);
  mxDestroyArray(c_data);

 

    
}

void scan_thread()
{
	is_tracking = true;
	is_tracking_complete = true;

	while (is_tracking_complete == false)
	{
		Sleep(50);
	}

	// if(cur_line == 0)
	// {
	//Stop tip graph
	// measure = false;
	// WaitForSingleObject(tip_read_thread,1000);
	// CloseHandle(tip_read_thread);


	//Get current laser position
	// _scan.get_laser_position();

	//Start tip graph
	// measure = true;
	// tip_read_thread = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&get_dac_data,NULL,NULL,NULL);


	// }

	if (is_scan)
	{
		_scan.save(true, true);

		if (_scan.pulse_seq)
		{
			_scan.scan_line_sequence(cur_line, "");
		}
		else
		{
			_scan.scan_line_smooth(cur_line);
		}

	}
	else
	{
		cur_line = _scan.ny_step - 1;
	}

	if (cur_line == _scan.ny_step - 1)
	{


		//Reset laser and tip position to the center of the scan
		//  _scan.set_tip_xy((_scan.x_max + _scan.x_min)/(double)2, (_scan.y_max+_scan.y_min)/(double)2);
		//  _scan.set_laser_position(_scan.laser_x,_scan.laser_y);
		// if(_scan.use_tracking)
		// {
		//     _scan.get_center();
		// }
		is_scan = false;

		_scan.save(true, false);


	}
	else
	{
		cur_line++;
		//Run tracking

		scan_thread_handle = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)&scan_thread, NULL, NULL, NULL);
	}


}

//void scan_thread()
//{
//    
//    if(cur_line == 0)
//    {
//        //Stop tip graph
//        measure = false;
//        WaitForSingleObject(tip_read_thread,1000);
//        CloseHandle(tip_read_thread);
//   
//       
//        //Get current laser position
//        _scan.get_laser_position();
//        
//        //Start tip graph
//        measure = true;
//        tip_read_thread = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&get_dac_data,NULL,NULL,NULL);
//              
//        
//    }
//    
//    if(is_scan)
//    {
//        _scan.save(true,true); // (true do an auto save, 2nd true is to update a scan)
//  
//       if(_scan.pulse_seq)
//       {
//            _scan.scan_line_sequence(cur_line,"");
//       }
//       else
//       {
//            _scan.scan_line_smooth(cur_line);
//       }
//  
//    }
//    else
//    {
//        cur_line = _scan.ny_step - 1;
//    }
//    
//    if(cur_line == _scan.ny_step - 1)
//    {     
//        _scan.save(true,false);
// 
//         //Reset laser and tip position to the center of the scan
//        _scan.set_tip_xy((_scan.x_max + _scan.x_min)/(double)2, (_scan.y_max+_scan.y_min)/(double)2);
//        
//        // commented out for micronix configuration
//        //_scan.set_laser_position(_scan.laser_x,_scan.laser_y);
//        
//       // if(_scan.use_tracking)
//       // {
//       //     _scan.get_center();
//       // }
//        is_scan = false;
//        
//        //  _scan.save(true,true);
//        
//        
//    }
//    else
//    {
//        cur_line++;
//        scan_thread_handle = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&scan_thread,NULL,NULL,NULL);
//    }
//    
//    
//}
void compute_plane()
{
 	//Put all points into one vector
	std::vector<double> plane_fit_vector;

	for(int i = 0; i < pp.size(); i++)
	{
		plane_fit_vector.push_back(pp[i].x);
		plane_fit_vector.push_back(pp[i].y);
		plane_fit_vector.push_back(pp[i].z);
	}

	double* plane_fit = new double[plane_fit_vector.size()];

	for(unsigned int i = 0; i < plane_fit_vector.size(); i++)
	{	
		plane_fit[i] = plane_fit_vector[i];
	}

	double plane[4];
   

	getBestFitPlane(plane_fit_vector.size()/3,plane_fit,3*sizeof(double),0,0,plane);

	//Output is in the form ax+by+cz+d = 0, change to form aX + bY = Z - c

	_planeInfo.a = -plane[0]/plane[2];
	_planeInfo.b = -plane[1]/plane[2];
	_planeInfo.c = -plane[3]/plane[2];

	//compute R^2 coefficient

	//Find mean of z values
	double z_mean = 0;
	for(int i = 0; i < pp.size(); i++)
	{
		z_mean += pp[i].z/( (double)pp.size() );
	}

	//compute total sum of squares
	double ss_tot = 0;
	double ss_err = 0;
	for(int i = 0; i < pp.size(); i++)
	{
		ss_tot += (pp[i].z - z_mean)*(pp[i].z - z_mean);
		ss_err += (pp[i].z - (_planeInfo.a*pp[i].x + _planeInfo.b*pp[i].y + _planeInfo.c) )
			*(pp[i].z - (_planeInfo.a*pp[i].x + _planeInfo.b*pp[i].y + _planeInfo.c) );
	}

	_planeInfo.r2 = 1 - (double)ss_err/(double)ss_tot;

	delete [] plane_fit;   
    
}

void redraw_plane_dialog()
{
        mxArray* null_str;
        null_str = mxCreateString("");
        
        mxSetProperty(prhs[_handles.plane_x_edit_index],0,"String",null_str);
        mxSetProperty(prhs[_handles.plane_y_edit_index],0,"String",null_str);
        mxSetProperty(prhs[_handles.plane_z_edit_index],0,"String",null_str);
        
      
        
        if(pp.size() == 0)
        {

          mxSetProperty(prhs[_handles.plane_listbox_index],0,"String",null_str);

        }
        else if(pp.size() > 0)
        {
            mxArray* plane_list;
            mwSize dims[1] = {pp.size()};

            plane_list = mxCreateCellArray(1,dims);

            //Reset listbox contents
            for(int i = 0; i < pp.size(); i++)
            {
                char point[200];
                sprintf_s(point,200,"(%.5f,%.5f,%.5f)",(pp[i]).x,(pp[i]).y,(pp[i]).z);

                mxArray* point_string;
                point_string = mxCreateString(point);
                mxSetCell(plane_list,i,point_string);

            }

            mxArray* one_arr;
            one_arr = mxCreateDoubleScalar(1);
            mxSetProperty(prhs[_handles.plane_listbox_index],0,"Value",one_arr);
            mxSetProperty(prhs[_handles.plane_listbox_index],0,"String",plane_list);
            
            mxDestroyArray(one_arr);
            mxDestroyArray(plane_list);
        }
        
        
        if(pp.size() >= 3)
        {
            compute_plane();
            is_valid_plane = true;
     
             mxArray* a_str;
             mxArray* b_str;
             mxArray* c_str;
             mxArray* r2_str;
             
            char atxt[30];
            sprintf_s(atxt,30,"%.5f",_planeInfo.a);
            a_str = mxCreateString(atxt);
            mxSetProperty(prhs[_handles.plane_a_text_index],0,"String",a_str);

            char btxt[30];
            sprintf_s(btxt,30,"%.5f",_planeInfo.b);
            b_str = mxCreateString(btxt);
            mxSetProperty(prhs[_handles.plane_b_text_index],0,"String",b_str);

            char ctxt[30];
            sprintf_s(ctxt,30,"%.5f",_planeInfo.c);
            c_str = mxCreateString(ctxt);
            mxSetProperty(prhs[_handles.plane_c_text_index],0,"String",c_str);

            char r2txt[30];
            sprintf_s(r2txt,30,"%.4f",_planeInfo.r2);
            r2_str = mxCreateString(r2txt);
            mxSetProperty(prhs[_handles.plane_r2_text_index],0,"String",r2_str);
            
            mxDestroyArray(a_str);
             mxDestroyArray(b_str);
              mxDestroyArray(c_str);
               mxDestroyArray(r2_str);
            
        }
        else
        {
         
            is_valid_plane = false;
            mxSetProperty(prhs[_handles.plane_a_text_index],0,"String",null_str);
            mxSetProperty(prhs[_handles.plane_b_text_index],0,"String",null_str);
            mxSetProperty(prhs[_handles.plane_c_text_index],0,"String",null_str);
            mxSetProperty(prhs[_handles.plane_r2_text_index],0,"String",null_str);
    
        }
        
        char offstr[100];
	    sprintf(offstr,"%.1f",_planeInfo.offset*(double)1000);
        
        mxArray* offset_arr;
        offset_arr = mxCreateString(offstr);
        mxSetProperty(prhs[_handles.plane_offset_edit_index],0,"String",offset_arr);
        
        mxDestroyArray(offset_arr);
          mxDestroyArray(null_str);
    
}
void add_plane_point(double x_point,double y_point, double z_point)
{
     plane_point new_point;
        
        new_point.x = x_point;
        new_point.y = y_point;
        new_point.z = z_point;
        
        pp.push_back(new_point);
        
        redraw_plane_dialog();
}
void update_readout()
{
    if(!is_update_MCL_readout) return;
     mxArray* x_value;
     mxArray* y_value;
     mxArray* z_value;
     char disp_str[50];
     
     
     sprintf_s(disp_str,50,"%.3f",MCL_x_pos);
     x_value = mxCreateString(disp_str);
     
     sprintf_s(disp_str,50,"%.3f",MCL_y_pos);
     y_value = mxCreateString(disp_str);
     
     sprintf_s(disp_str,50,"%.3f",MCL_z_pos);
     z_value = mxCreateString(disp_str);

     mxSetProperty(prhs[_handles.MCL_x_index],0,"String",x_value);  
     mxSetProperty(prhs[_handles.MCL_y_index],0,"String",y_value);  
     mxSetProperty(prhs[_handles.MCL_z_index],0,"String",z_value);  
     
     mxDestroyArray(x_value);
     mxDestroyArray(y_value);
     mxDestroyArray(z_value);
    
}
void MCL_readout()
{
    
    int k = 0;
    int n_avg = 10;
    
    double x_temp = 0;
    double y_temp = 0;
    double z_temp = 0;
    
    while ( is_MCL_readout )
    {
        x_temp = 0;
        y_temp = 0;
        z_temp = 0;
    
        for(k = 0; k < n_avg; k++)
        {
            x_temp += MCL_SingleReadN(1,MCL_handle);
            y_temp += MCL_SingleReadN(2,MCL_handle);
            z_temp += MCL_SingleReadN(3,MCL_handle);
        }
        
        
            MCL_x_pos = x_temp/(double)n_avg;
            MCL_y_pos = y_temp/(double)n_avg;
            MCL_z_pos = z_temp/(double)n_avg;
            
            Sleep(200);
    }
   
} 

void Micronix_readout(){
	// Micronix_thread executes function

	int ax = 1;
	char pos1Str[50];
	char pos2Str[50];
	char pos3Str[50];
	int numCharPos;
	char trashStr[32];

	int dataPosBytesRead;
	int j;

	while (is_Micronix_readout) {
		if (!is_Micronix_commanded){
			ax = read_Micronix_which_axis; // set by GUI radio buttons
			
			numCharPos = sprintf_s(pos1Str, 50, "%iPOS\?\r", ax);
			_handles.Micronix_serial.SendData(pos1Str, numCharPos);
			Sleep(50);
			if (!is_Micronix_commanded){
				if (ax == 1){
					dataPosBytesRead = _handles.Micronix_serial.ReadData(read_Micronix_x_pos, 32);
				}
				else if (ax == 2){
					dataPosBytesRead = _handles.Micronix_serial.ReadData(read_Micronix_y_pos, 32);
				}
				else if (ax==3){
					dataPosBytesRead = _handles.Micronix_serial.ReadData(read_Micronix_z_pos, 32);
				}
			}
		}
		Sleep(300);
	}

	//is_Micronix_readout = false; // for testing no readout
	/*while (is_Micronix_readout){
		if (!is_Micronix_commanded){
			// check x encoder position in mm
			ax = 1;
			for (j = 1; j <= 3; j++){
				dataPosBytesRead = _handles.Micronix_serial.ReadData(trashStr, 32);
			}
			numCharPos = sprintf_s(pos1Str, 50, "%iPOS\?\r", ax);
			_handles.Micronix_serial.SendData(pos1Str, numCharPos);

			if (!is_Micronix_commanded){
				dataPosBytesRead = _handles.Micronix_serial.ReadData(read_Micronix_x_pos, 32);
			}
			Sleep(50);
		}
			
		if (!is_Micronix_commanded){
			// check y encoder position in mm
			ax = 2;
			for (j = 1; j <= 3; j++){
				dataPosBytesRead = _handles.Micronix_serial.ReadData(trashStr, 32);
			}
			numCharPos = sprintf_s(pos2Str, 50, "%iPOS\?\r", ax);
			_handles.Micronix_serial.SendData(pos2Str, numCharPos);

			if (!is_Micronix_commanded){
				dataPosBytesRead = _handles.Micronix_serial.ReadData(read_Micronix_y_pos, 32);
			}
			Sleep(50);
		}

		if (!is_Micronix_commanded){
			// check z encoder position in mm
			ax = 3;
			for (j = 1; j <= 3; j++){
				dataPosBytesRead = _handles.Micronix_serial.ReadData(trashStr, 32);
			}
			numCharPos = sprintf_s(pos3Str, 50, "%iPOS\?\r", ax);
			_handles.Micronix_serial.SendData(pos3Str, numCharPos);

			if (!is_Micronix_commanded){
				dataPosBytesRead = _handles.Micronix_serial.ReadData(read_Micronix_z_pos, 32);
			}
			Sleep(50);
		}
		Sleep(300); // not necessary to update fast
	}*/
}

void update_Micronix_GUI(){
	// Micronix_timer set to execute function
	if (!is_update_Micronix_readout) return;

	//x
	mxArray* readpos_x_str;
	readpos_x_str = mxCreateString(read_Micronix_x_pos);
	mxSetProperty(prhs[_handles.mic_xpos_index],0, "String", readpos_x_str);
	//y
	mxArray* readpos_y_str;
	readpos_y_str = mxCreateString(read_Micronix_y_pos);
	mxSetProperty(prhs[_handles.mic_ypos_index],0, "String", readpos_y_str);
	//z
	mxArray* readpos_z_str;
	readpos_z_str = mxCreateString(read_Micronix_z_pos);
	mxSetProperty(prhs[_handles.mic_zpos_index],0, "String", readpos_z_str);

	mxDestroyArray(readpos_x_str);
	mxDestroyArray(readpos_y_str);
	mxDestroyArray(readpos_z_str);
}

void calibrate_thread() //Calibrate DAC voltage to MCL readout position
{
    if(is_scan) return;
    
    //Sweep x tip voltage and measure MCL readout at each point
    
    is_MCL_readout = false; //Turn continuous readout off
    
    double* x_cal_volt = new double[n_cal_pts];
    double* x_cal_readout = new double[n_cal_pts];
    
    double x_cal_volt_min = 0;
    double x_cal_volt_max = 1;
    
    double* y_cal_volt = new double[n_cal_pts];
    double* y_cal_readout = new double[n_cal_pts];
    
    double y_cal_volt_min = 0;
    double y_cal_volt_max = 1;
    
    double* z_cal_volt = new double[n_cal_pts];
    double* z_cal_readout = new double[n_cal_pts];
    
    double z_cal_volt_min = 0;
    double z_cal_volt_max = 1;
    
    double plane[4];
    
    //Calibrate x
    
    for(int i = 0; i < n_cal_pts; i++)
    {
        if(!is_calibrate_thread) return;
        x_cal_volt[i] = x_cal_volt_min + ((double)i/(double)(n_cal_pts - 1)) * (x_cal_volt_max - x_cal_volt_min); 
        _scan.set_tip_xy(x_cal_volt[i],0);
        while(_scan.is_tip_thread){ Sleep(10); } //Wait for tip to move
        x_cal_readout[i] = MCL_SingleReadN(1,MCL_handle);
    }
    
    //Compute best fit line
    double* x_plane_fit = new double[3*n_cal_pts];

	for(int i = 0; i < n_cal_pts; i++)
	{	
		x_plane_fit[3*i] = x_cal_volt[i];
        x_plane_fit[3*i + 1] = x_cal_readout[i];
        x_plane_fit[3*i + 2] = i%2;
	}

	getBestFitPlane(n_cal_pts,x_plane_fit,3*sizeof(double),0,0,plane);

	//Output is in the form ax+by+cz+d = 0, change to form aX + bY = Z - c

	double x_slope = -plane[0]/plane[1];
    double x_offset = -plane[3]/plane[1];
    
    _scan.set_tip_xy(0,0);
    
    //Calibrate y
    
    for(int i = 0; i < n_cal_pts; i++)
    {
        if(!is_calibrate_thread) return;
        y_cal_volt[i] = y_cal_volt_min + ((double)i/(double)(n_cal_pts - 1)) * (y_cal_volt_max - y_cal_volt_min); 
        _scan.set_tip_xy(0,y_cal_volt[i]);
        while(_scan.is_tip_thread){ Sleep(10); } //Wait for tip to move
        y_cal_readout[i] = MCL_SingleReadN(2,MCL_handle);
    }
    
    //Compute best fit line
    double* y_plane_fit = new double[3*n_cal_pts];

	for(int i = 0; i < n_cal_pts; i++)
	{	
		y_plane_fit[3*i] = y_cal_volt[i];
        y_plane_fit[3*i + 1] = y_cal_readout[i];
        y_plane_fit[3*i + 2] = i%2;
	}

	getBestFitPlane(n_cal_pts,y_plane_fit,3*sizeof(double),0,0,plane);

	//Output is in the form ax+by+cz+d = 0, change to form aX + bY = Z - c

	double y_slope = -plane[0]/plane[1];
    double y_offset = -plane[3]/plane[1];
    
    _scan.set_tip_xy(0,0);
    
     //Calibrate z
    
    for(int i = 0; i < n_cal_pts; i++)
    {
        if(!is_calibrate_thread) return;
        z_cal_volt[i] = z_cal_volt_min + ((double)i/(double)(n_cal_pts - 1)) * (z_cal_volt_max - z_cal_volt_min); 
        _DAC.z_in(z_cal_volt[i]);
        while(_scan.is_tip_thread){ Sleep(10); } //Wait for tip to move
        z_cal_readout[i] = MCL_SingleReadN(3,MCL_handle);
    }
    
    //Compute best fit line
    double* z_plane_fit = new double[3*n_cal_pts];

	for(int i = 0; i < n_cal_pts; i++)
	{	
		z_plane_fit[3*i] = z_cal_volt[i];
        z_plane_fit[3*i + 1] = z_cal_readout[i];
        z_plane_fit[3*i + 2] = i%2;
	}

	getBestFitPlane(n_cal_pts,z_plane_fit,3*sizeof(double),0,0,plane);

	//Output is in the form ax+by+cz+d = 0, change to form aX + bY = Z - c

	double z_slope = -plane[0]/plane[1];
    double z_offset = -plane[3]/plane[1];
    
    _DAC.z_in(0);
    
    char result[500];
    sprintf_s(result,500,"x-slope: %.4f um/V x-offset: %.4f um\r\ny-slope: %.4f um/V y-offset: %.4f um\r\nz-slope: %.4f um/V z-offset: %.4f um",x_slope,x_offset,y_slope,y_offset,z_slope,z_offset);
    MessageBox(0,result,0,0);
    
    delete [] x_cal_volt;
    delete [] x_cal_readout;
    delete [] x_plane_fit;
    
    delete [] y_cal_volt;
    delete [] y_cal_readout;
    delete [] y_plane_fit;
    
    delete [] z_cal_volt;
    delete [] z_cal_readout;
    delete [] z_plane_fit;
    
    
    is_calibrate_thread = false;
    
    _scan.set_tip_xy(0,0);
    _DAC.z_in(0);
    
     is_MCL_readout = true; //Turn continuous readout on
      MCL_thread = (HANDLE)CreateThread( NULL, 0, (LPTHREAD_START_ROUTINE)&MCL_readout, NULL, NULL,NULL );
    
    
}


	
	
    if(func_name == "init" && nargs == 8)
    {
          z_adder_calibration = 0.989391;
                
         axes_handle = mxGetScalar(prhs[1]);
         min_line_handle = mxGetScalar(prhs[2]);
         max_line_handle = mxGetScalar(prhs[3]);
         textbox_tip_volt_handle = mxGetScalar(prhs[4]);
         textbox_min_volt_handle = mxGetScalar(prhs[5]);
		 textbox_max_volt_handle = mxGetScalar(prhs[6]);
        // thor_handle = mxGetScalar(prhs[7]);
         z_in_disp_handle = mxGetScalar(prhs[7]);
         buffer = mxGetScalar(prhs[8]); // buffer input in test_gui has been 2500. 2013-2015..
         
		 // added to adapt the code to the new format of mex files (Chang Jin 12/7/21)
		 axes_handle_index = 1;
		 min_line_handle_index = 2;
		 max_line_handle_index = 3;
		 textbox_tip_volt_handle_index = 4;
		 textbox_min_volt_handle_index = 5;
		 textbox_max_volt_handle_index = 6;
		 z_in_disp_handle_index = 7;
		 buffer_index = 8; // buffer input in test_gui has been 2500. 2013-2015..

            mwSize dims[2] = {1,buffer};
     
           mxy_data = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
           mexMakeArrayPersistent(mxy_data);
           y_data = mxGetPr(mxy_data);

		   mxtheta_data = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL);
		   mexMakeArrayPersistent(mxtheta_data);
		   theta_data = mxGetPr(mxtheta_data);
           
        _planeInfo.a = 0; 
        _planeInfo.b = 0; 
        _planeInfo.c = 0; 
        _planeInfo.r2 = 0; 
        _planeInfo.offset = 0; 
        _planeInfo.is_plane_active = false; 
        
        _DAC.set_z_cal_factor(z_adder_calibration);
        _DAC.set_plane_info_ptr(&_planeInfo);
        _DAC.z_in(0);
        measure = false;
        current_bridge = 0;
		current_phase = 0;
        
        is_button_down = false;
        is_min_move = false;
        is_max_move = false;
        is_step = false;
        
        min_flag = -0.5;
        max_flag = 0.5;
        
        axes_min = -1;
        axes_max = 1;
        
        approach_min = 1; // MCL min 1 volt = 10 um
        approach_max = 9; // MCL max 9 volt = 90 um
		approach_rate = 0.004; //0.0725; // rate for first Si-tip test Nov 2014 was 0.0725, decrease
								// value for 3/30/15 was 0.03.
								// changed back to 40 nm/s on 4/30/15, same value Matt used for Gd
        approach_retract = 0.05;
        
        n_steps = 0;
        
        cur_line = 0;
        is_scan = false;
        
        direction = true;
        filtered = true;
        
        is_draw_tip_position = false;
        is_enable_tip_position = false;
      
        
        _DAC.define_approach_task();
		//_DAC.define_phase_task();
        
        measure = true;
        is_update_scan_info = true;
        is_update_scan_data = true;
        is_update_MCL_readout = true;
		is_update_Micronix_readout = true;
        tip_read_thread = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&get_dac_data,NULL,NULL,NULL);
		//phase_read_thread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)&get_dac_phase_data, NULL, NULL, NULL);
        
        SetTimer(NULL,timer_graph,50,(TIMERPROC)update_graph);
        
        SetTimer(NULL,update_scan_timer,250,(TIMERPROC)update_scan_info);
        
        SetTimer(NULL,update_scan_data_timer,200,(TIMERPROC)update_scan_data);
        
        SetTimer(NULL,matlab_data_timer,100,(TIMERPROC)get_matlab_data);
        
        //Initialize scan class
        _scan.set_DAC_ptr(&_DAC);
        _scan.set_plane_info_ptr(&_planeInfo);
        _scan.set(0,1,0,1,200,200,50,0); 
        _scan.set_tip_xy(0,0);
        _scan.set_update_scan_ptr(&update_scan_info);
        _scan.set_disp_data(filtered,direction);
        _scan.set_plane_info_ptr(&_planeInfo);
        update_scan_info();
        
        pp.clear();
        is_valid_plane = false;
        
        MCL_x_pos = 0;
        MCL_y_pos = 0;
        MCL_z_pos = 0;
        MCL_handle = MCL_InitHandleOrGetExisting();
    
        is_MCL_readout = true;

       MCL_thread = (HANDLE)CreateThread( NULL, 0, (LPTHREAD_START_ROUTINE)&MCL_readout, NULL, NULL,NULL );
       SetTimer(NULL,MCL_timer,100,(TIMERPROC)update_readout);

	   // Micronix thread begin
	   is_Micronix_readout = true;
	   Micronix_thread = (HANDLE)CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)&Micronix_readout, NULL, NULL, NULL);
	   SetTimer(NULL, Micronix_timer, 200, (TIMERPROC)update_Micronix_GUI);
	   
	   Micronix_approach_z_stepsize = 0.06; // in mm (for 60 um steps)
       
       is_calibrate_thread = false;
       
       n_cal_pts = 250;
       
       _scan.laser_x_cal = 10.000/58.0471;
       _scan.laser_y_cal = 10.000/55.3411;
       
        which_zmotor = 2; // 1=Thorlabs PZ1, 2=Micronix MMC-100 controller

		is_tracking = false;
		is_tracking_complete = false;

		phase_mVPerDeg = 28;
       
    }
    else  if(func_name == "set_cal" && nargs == 6)
    {
         double x_laser_cal = mxGetScalar(prhs[1]);
         double y_laser_cal = mxGetScalar(prhs[2]);
         
         double x_MCL_cal = mxGetScalar(prhs[3]);
         double y_MCL_cal = mxGetScalar(prhs[4]);
         
         double x_laser_handle = mxGetScalar(prhs[5]);
         double y_laser_handle = mxGetScalar(prhs[6]);
         
       _scan.laser_x_cal = x_laser_cal;
       _scan.laser_y_cal = y_laser_cal;
       
       _scan.MCL_x_cal = x_MCL_cal;
       _scan.MCL_y_cal = y_MCL_cal;
       
       _scan.laser_handle_x = x_laser_handle;
       _scan.laser_handle_y = y_laser_handle;

	   // added to adapt to the new mex files (Chang Jin 12/7/21) =========
	   _scan.laser_x_cal_index = 1;
	   _scan.laser_y_cal_index = 2;

	   _scan.MCL_x_cal_index = 3;
	   _scan.MCL_y_cal_index = 4;

	   _scan.laser_handle_x_index = 5;
	   _scan.laser_handle_y_index = 6;
       // =================================================================
    }
    else if(func_name == "close")
    {
        // Send Message to ThorLabs executable
         HWND hwnd = FindWindow(NULL, "ThorLabsAPT");
        SendMessage(hwnd, WM_CLOSE, NULL, NULL);
        //  KillTimer(NULL,timer_readout);
        
        // close Micronix port
		_handles.Micronix_serial.Close(); // calls CloseHandle in class
		Sleep(100);
         
        measure = false;
        Sleep(100);
        is_thread = false;
         Sleep(100);
        is_surface_flagged = false;
         Sleep(100);
        is_step = false;
         Sleep(100);
        is_scan = false;
         Sleep(100);
        is_calibrate_thread = false;
         Sleep(100);
         is_update_scan_info = false;
          Sleep(100);
        is_update_scan_data = false;
         Sleep(100);
        is_update_MCL_readout = false;
         Sleep(100);
        is_MCL_readout = false;
         Sleep(100);
		is_update_Micronix_readout = false;
		 Sleep(100);
		is_Micronix_readout = false;
		 Sleep(100);
        
     
   
          KillTimer(NULL,timer_graph);
          KillTimer(NULL,thor_timer);
          KillTimer(NULL,matlab_data_timer);
           KillTimer(NULL,update_scan_timer);
           KillTimer(NULL,update_scan_data_timer);
             KillTimer(NULL,MCL_timer);
			 KillTimer(NULL, Micronix_timer);
			 KillTimer(NULL, Micronix_approach_timer);

  
			 WaitForSingleObject(Micronix_thread, 1000);
             WaitForSingleObject(MCL_thread,1000);
              WaitForSingleObject(calibrate_thread,1000);
        WaitForSingleObject(tip_read_thread,1000);
		WaitForSingleObject(phase_read_thread, 1000);
           WaitForSingleObject(approach_thread_handle,1000);
           WaitForSingleObject(check_approach_thread_handle,1000);
           WaitForSingleObject(scan_thread_handle,1000);
		   WaitForSingleObject(Micronix_approach_step,1000);
       
       
		   CloseHandle(Micronix_thread);
        CloseHandle( MCL_thread );
        CloseHandle(calibrate_handle);
        CloseHandle( tip_read_thread );
		CloseHandle(phase_read_thread);
         CloseHandle( approach_thread_handle );
          CloseHandle( check_approach_thread_handle );
         CloseHandle( scan_thread_handle);
		 CloseHandle(micronix_approach_thread_handle);
         
          MCL_ReleaseAllHandles();
         
         
          mxDestroyArray(mxy_data);
		  mxDestroyArray(mxtheta_data);
          
    }
    else if(func_name == "set_scan_handles" && nargs == 21)
    {
        _handles.x_tip_position = mxGetScalar(prhs[1]);
        _handles.y_tip_position = mxGetScalar(prhs[2]);
        
        _handles.x_scan_size = mxGetScalar(prhs[3]);
        _handles.y_scan_size = mxGetScalar(prhs[4]);
        
        _handles.x_scan_center = mxGetScalar(prhs[5]);
        _handles.y_scan_center = mxGetScalar(prhs[6]);
        
        _handles.scan_speed = mxGetScalar(prhs[7]);
        
        _handles.x_points = mxGetScalar(prhs[8]);
        _handles.y_points = mxGetScalar(prhs[9]);
        
        _handles.scan_axes_handle = mxGetScalar(prhs[10]);
        _handles.scan_grid_handle = mxGetScalar(prhs[11]);
        _handles.cur_line_handle = mxGetScalar(prhs[12]);
        
        _handles.tip_position_x_handle = mxGetScalar(prhs[13]);
        _handles.tip_position_y_handle = mxGetScalar(prhs[14]);
        
        _handles.start_scan_handle = mxGetScalar(prhs[15]);
        _handles.stop_scan_handle = mxGetScalar(prhs[16]);
        
        _handles.start_approach_handle = mxGetScalar(prhs[17]);
        _handles.stop_approach_handle = mxGetScalar(prhs[18]);
        
        _handles.snap_plane_handle = mxGetScalar(prhs[19]);
        
        _handles.stop_graph_handle = mxGetScalar(prhs[20]);
        _handles.start_graph_handle = mxGetScalar(prhs[21]);

        // added to adapt to the new mex file format (Chang Jin 12/7/21)=========
        _handles.x_tip_position_index = 1;
        _handles.y_tip_position_index = 2;
        
        _handles.x_scan_size_index = 3;
        _handles.y_scan_size_index = 4;
        
        _handles.x_scan_center_index = 5;
        _handles.y_scan_center_index = 6;
        
        _handles.scan_speed_index = 7;
        
        _handles.x_points_index = 8;
        _handles.y_points_index = 9;
        
        _handles.scan_axes_handle_index = 10;
        _handles.scan_grid_handle_index = 11[_handles.cur_line_handle_index],0 = 12;
        
        _handles.tip_position_x_handle_index = 13;
        _handles.tip_position_y_handle_index = 14;
        
        _handles.start_scan_handle_index = 15;
        _handles.stop_scan_handle_index = 16;
        
        _handles.start_approach_handle_index = 17;
        _handles.stop_approach_handle_index = 18;
        
        _handles.snap_plane_handle_index = 19;
        
        _handles.stop_graph_handle_index = 20;
        _handles.start_graph_handle_index = 21;
        // ======================================================================
    }
    else if(func_name == "set_MCL_handles" && nargs == 3)
    {
        _handles.MCL_x = mxGetScalar(prhs[1]);
        _handles.MCL_y = mxGetScalar(prhs[2]);
        _handles.MCL_z = mxGetScalar(prhs[3]);

        // added to adapt to the new mex file format (Chang Jin 12/7/21)=========
        _handles.MCL_x_index = 1;
        _handles.MCL_y_index = 2;
        _handles.MCL_z_index = 3;
        // ======================================================================

    }
    else if(func_name == "set_Micronix_port" && nargs == 2)
    {   
        // alternative to thread for serial, we will set the timeouts of the serial port
		CSerial tempSerial;
		_handles.Micronix_serial = tempSerial;
		int portNum = (int)mxGetScalar(prhs[1]);
		int baudRate = (int)mxGetScalar(prhs[2]);
		mxArray* port_str;
		mxArray* debug1_str;
		mxArray* debug2_str;
		mxArray* debug3_str;
		mxArray* on_str;
		on_str = mxCreateString("on");
		mxArray* off_str;
		off_str = mxCreateString("off");
		char rezStr[50], encStr[50], fbkStr[50], accStr[50], decStr[50], velStr[50], pidStr[50];
		int numChar;
		if (_handles.Micronix_serial.Open(portNum, baudRate)){
			// send commands to set the x,y,z axes properties
			unsigned int mic_stepsPerMicron = 8000;   // step resolution
			double mic_micronsPerEncCount = 0.01;     // analog encoder resolution
			unsigned int mic_fdbk = 0;                //closed loop operation=3, openloop=0
			double mic_accel = 100;                   // mm/s^2
			double mic_decel = 100;                   //mm/s^2
			double mic_vel = 0.5;                     // mm/2
			double mic_PID_P = 0.2;                   // closed loop PID
			// for X axis we want 0.2 PID_P as this was re tuned by Manfred at MicronixUSA
			// actually it's better not to set any of these pid parameters here..
			double mic_PID_I = 0;
			double mic_PID_D = 0;
			int ax;
			
			// 02-05-16 Commented out setting default PID and Feedback. We want to alternate between guis and not set any new defaults here.
			for (ax = 1; ax <= 3; ax++){
				
				numChar=sprintf_s(rezStr, 50, "%iREZ%u\r", ax, mic_stepsPerMicron);
				_handles.Micronix_serial.SendData(rezStr, numChar);
				Sleep(100);
				numChar=sprintf_s(encStr, 50, "%iENC%1.3f\r", ax, mic_micronsPerEncCount);
				_handles.Micronix_serial.SendData(encStr, numChar);
				Sleep(100);
				//numChar = sprintf_s(fbkStr, 50, "%iFBK%u\r", ax, mic_fdbk);
				//_handles.Micronix_serial.SendData(fbkStr, numChar);
				Sleep(100);
				numChar = sprintf_s(accStr, 50, "%iACC%1.3f\r", ax, mic_accel);
				_handles.Micronix_serial.SendData(accStr,numChar);
				Sleep(100);
				numChar = sprintf_s(decStr, 50, "%iDEC%1.3f\r", ax, mic_decel);
				_handles.Micronix_serial.SendData(decStr, numChar);
				Sleep(100);
				numChar=sprintf_s(velStr, 50, "%iVEL%1.3f\r", ax, mic_vel);
				_handles.Micronix_serial.SendData(velStr, numChar);
				Sleep(100);
				//numChar=sprintf_s(pidStr, 50, "%iPID%1.3f,%1.3f,%1.3f\r", ax, mic_PID_P, mic_PID_I, mic_PID_D);
				//_handles.Micronix_serial.SendData(pidStr, numChar);
				Sleep(100);

			}
			// add message indicating port successfully opened
			
			port_str = mxCreateString("Port is opened");
			mxSetProperty(prhs[_handles.mic_port_status_index],0, "String", port_str);

			debug1_str = mxCreateString(encStr);
			mxSetProperty(prhs[_handles.mic_debug1_index],0, "String", debug1_str);

			debug2_str = mxCreateString(accStr);
			mxSetProperty(prhs[_handles.mic_debug2_index],0, "String", debug2_str);

			debug3_str = mxCreateString(pidStr);
			mxSetProperty(prhs[_handles.mic_debug3_index],0, "String", debug3_str);

			//disable button (I labeled as "figure" but it refers to 'open' button)
			mxSetProperty(prhs[_handles.mic_figure_index],0, "Enable", off_str);
        }
        else
        {
			// add an error message: failed to open port.
			port_str = mxCreateString("Port open failed");
			mxSetProperty(prhs[_handles.mic_port_status_index],0, "String", port_str);
        }   
        
		mxDestroyArray(on_str);
		mxDestroyArray(off_str);
    }
	else if (func_name == "close_Micronix_port")
	{
		mxArray* port_str;
		mxArray* on_str;
		on_str = mxCreateString("on");
		if (_handles.Micronix_serial.Close())
		{
			port_str = mxCreateString("Port closed successfully");
			mxSetProperty(prhs[_handles.mic_port_status_index],0, "String", port_str);
			//enable the open button (I labeled as "figure" but it refers to 'open' button)
			mxSetProperty(prhs[_handles.mic_figure_index],0, "Enable", on_str);
		}
		else
		{
			// add an error message: failed to close port.
			port_str = mxCreateString("Port still open, close failed");
			mxSetProperty(prhs[_handles.mic_port_status_index],0, "String", port_str);
		}
	}
	else if (func_name == "set_Micronix_handles" && nargs == 16){
		_handles.mic_figure = mxGetScalar(prhs[1]);
		_handles.mic_port_status = mxGetScalar(prhs[2]);
		_handles.mic_xpos = mxGetScalar(prhs[3]);
		_handles.mic_ypos = mxGetScalar(prhs[4]);
		_handles.mic_zpos = mxGetScalar(prhs[5]);
		_handles.mic_debug1 = mxGetScalar(prhs[6]);
		_handles.mic_debug2 = mxGetScalar(prhs[7]);
		_handles.mic_debug3 = mxGetScalar(prhs[8]);
		_handles.mic_radio_x = mxGetScalar(prhs[9]);
		_handles.mic_radio_y = mxGetScalar(prhs[10]);
		_handles.mic_radio_z = mxGetScalar(prhs[11]);
		_handles.mic_n_steps = mxGetScalar(prhs[12]);
		_handles.mic_feedback_type_x = mxGetScalar(prhs[13]);
		_handles.mic_feedback_type_y = mxGetScalar(prhs[14]);
		_handles.mic_feedback_type_z = mxGetScalar(prhs[15]);
		_handles.mic_command_window = mxGetScalar(prhs[16]);
		
        // added to adapt to the new mex file format (Chang Jin 12/7/21) =========
        _handles.mic_figure_index = 1;
		_handles.mic_port_status_index = 2;
		_handles.mic_xpos_index = 3;
		_handles.mic_ypos_index = 4;
		_handles.mic_zpos_index = 5;
		_handles.mic_debug1_index = 6;
		_handles.mic_debug2_index = 7;
		_handles.mic_debug3_index = 8;
		_handles.mic_radio_x_index = 9;
		_handles.mic_radio_y_index = 10;
		_handles.mic_radio_z_index = 11;
		_handles.mic_n_steps_index = 12;
		_handles.mic_feedback_type_x_index = 13;
		_handles.mic_feedback_type_y_index = 14;
		_handles.mic_feedback_type_z_index = 15;
		_handles.mic_command_window_index = 16;
        // =======================================================================

		read_Micronix_which_axis = 1; // reading x axis at start
	}
	else if(func_name == "change_Micronix_read_axis" && nargs==1){
		read_Micronix_which_axis = mxGetScalar(prhs[1]);
	}
	else if(func_name == "change_Micronix_feedback" && nargs == 2){
		int axis = (int)mxGetScalar(prhs[1]);
		int newVal = (int)mxGetScalar(prhs[2])-1; // -1 because matlab popup is 1-4, FBK command is 0-3

		char fbkStr[50];
		int numChar;

		numChar = sprintf_s(fbkStr, 50, "%iFBK%i\r", axis, newVal);
		_handles.Micronix_serial.SendData(fbkStr, numChar);
		Sleep(100);
	}
	else if(func_name == "zero_Micronix_position" && nargs == 1){
		int axis = (int)mxGetScalar(prhs[1]);
		char zroStr[50];
		int numChar;
		numChar = sprintf_s(zroStr, 50, "%iZRO\r", axis);
		_handles.Micronix_serial.SendData(zroStr, numChar);
		Sleep(100);
	}
	else if (func_name == "send_Micronix_command")
    {
		
		mxArray* cmdMat;
		cmdMat = (mxArray*)mxGetProperty(_handles.mic_command_window, "String");
		
		char cmdStr[100];
		char countedStr[100];
		int numChar;
		mxGetString(cmdMat, cmdStr, 100);
		numChar = sprintf_s(countedStr, 100, "%s\r", cmdStr); // essentially counts the # characters and adds carriage return
		_handles.Micronix_serial.SendData(countedStr, numChar);
		Sleep(500);
	}
	else if (func_name == "set_phase_handles" && nargs == 3)
	{
		_handles.phase_volt = mxGetScalar(prhs[1]);
		_handles.phase_deg = mxGetScalar(prhs[2]);
		_handles.phase_axes = mxGetScalar(prhs[3]);
        
        // added to adapt to the new mex file format (Chang Jin 12/7/21) =========
        _handles.phase_volt_index = 1;
		_handles.phase_deg_index = 2;
		_handles.phase_axes_index = 3;
        // =======================================================================
	}
	else if (func_name == "set_phase_conversion" && nargs == 1)
	{
		phase_mVPerDeg = args[0];
		// edit of the gui number display is just done in matlab
	}
    else if(func_name == "z_in" && nargs == 1)
    {
        _DAC.z_in(args[0]);
         update_scan_info();
    }
	else if(func_name == "start_approach_pid")
	{
		// start the updated approach sequence
		if (which_zmotor==2) {
            // set up the Micronix axis 3 (Z) to approach
            // sample stepping down towards tip requires increments dz>0

			// first set micronix continuous position monitoring to z axis
			read_Micronix_which_axis = 3;
			// set timer to check often: whether it is supposed to step
			
			//SetTimer(NULL, Micronix_approach_timer, 100, (TIMERPROC)Micronix_approach_step);
			//micronix_approach_thread_handle = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&Micronix_approach_step,NULL,NULL,NULL);
        }
	}
	else if (func_name == "z_in_relative_approach" && nargs==1)
	{
		// since it is more of a pain to return a left hand side argument to matlab, do the whole check z_in_current and move 
		double currentZ = _DAC.z_in_current;
		double stepZ = mxGetScalar(prhs[1]);

		// check that the approach max is not exceeded, 
		if  (stepZ + currentZ >= approach_max-stepZ)
		{
			
			//if so do not move up to max but go back to min and initiate a step of micronix.
			HANDLE z_in_thread = _DAC.z_in(approach_min);
			WaitForSingleObject(z_in_thread,INFINITE);
			update_scan_info();

			// now the piezo is at the bottom, so step the micronix up
			
			is_step = true;
           // while(is_step) Sleep(1000); //Wait for step to happen

			//-----new, try doing this inline not in a thread---------
			   // step the set amount for an approach 
			   // tip is below sample, so the MicronixZ must step
			   // in the down direction. this is Increment > 0
			   is_Micronix_commanded = true;
			   char mvrStr[50];
			   int numCharD = sprintf_s(mvrStr, 50, "%iMVR%1.6f\r", 3, Micronix_approach_z_stepsize);
			   _handles.Micronix_serial.SendData(mvrStr, numCharD); // MVR: move relative
			   Sleep(100);

			   is_Micronix_commanded = false;
			   is_step = false;
			   
			//--------------------------------------------------------

			
			n_steps++;
			update_scan_info();
		}
		else
		{	
			//if there is space still then go up a step
			HANDLE z_in_thread = _DAC.z_in(currentZ+stepZ);
			WaitForSingleObject(z_in_thread,INFINITE);
			update_scan_info();
		}
	}
	else if(func_name == "stop_approach_pid")
	{
		// main thing is to stop the timer for the motor step
		if (which_zmotor == 2){
			KillTimer(NULL, Micronix_approach_timer);

		}
	}
	
    else if(func_name == "start_approach")
    {
        if (which_zmotor==1) {
            //Set properties in ThorLabs executable
            HWND hwnd = FindWindow(NULL, "ThorLabsAPT");
            SendMessage(hwnd, WM_APP + 1000, NULL, NULL);
        
            SetTimer(NULL,thor_timer,100,(TIMERPROC)Thor_Step);
        }
        else if (which_zmotor==2) {
            // set up the Micronix axis 3 (Z) to approach
            // sample stepping down towards tip requires increments dz>0

			// first set micronix continuous position monitoring to z axis
			read_Micronix_which_axis = 3;
			// set timer to check often: whether it is supposed to step
			SetTimer(NULL, Micronix_approach_timer, 100, (TIMERPROC)Micronix_approach_step);

        }
         
        is_thread = true;
        approach_thread_handle = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&approach_thread,NULL,NULL,NULL);
        check_approach_thread_handle = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&check_approach_thread,NULL,NULL,NULL);
    }
	else if (func_name == "stop_approach")
	{
		_DAC.stop_sweep();

		if (which_zmotor == 1){
			KillTimer(NULL, thor_timer);
		}
		else if (which_zmotor == 2){
			KillTimer(NULL, Micronix_approach_timer);

		}
		is_thread = false;
    }
    else if(func_name == "stop_graph")
    {
        measure = false;
        WaitForSingleObject(tip_read_thread,1000);
        CloseHandle(tip_read_thread);
		WaitForSingleObject(phase_read_thread, 1000);
		CloseHandle(phase_read_thread);
    }  
     else if(func_name == "start_graph")
    {
        measure = true;
        tip_read_thread = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&get_dac_data,NULL,NULL,NULL);
		//phase_read_thread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)&get_dac_phase_data, NULL, NULL, NULL);
    }
    else if(func_name == "set_tip_x" && nargs == 1)
    {
		// ----avoid accidentally moving to invalid positions and unpredictable voltages
		double posx = args[0];
		if (posx < _scan.x_min_scan) {
			posx = _scan.x_min_scan;
		}
		if (posx > _scan.x_max_scan) {
			posx = _scan.x_max_scan;
		}
		if (_isnan(posx)) {		// visual C++ doesn't recognize isnan or std::isnan
			posx = _scan.x_tip;
		}
		/*if (posx == 1.0/0.0) {	// visual C++ doesn't recognize isinf() ot std::isinf() or _isinf
			posx = _scan.x_tip;
		}*/
		//-----------
        _scan.set_tip_xy(posx,_scan.y_tip);
    }
    else if(func_name == "set_tip_y" && nargs == 1)
    {
		// ----avoid accidentally moving to invalid positions and unpredictable voltages
		double posy = args[0];
		if (posy < _scan.y_min_scan) {
			posy = _scan.y_min_scan;
		}
		if (posy > _scan.y_max_scan) {
			posy = _scan.y_max_scan;
		}
		if (_isnan(posy)) {
			posy = _scan.y_tip;
		}
		/*if (posy== 1.0 / 0.0) {
			posy = _scan.y_tip;
		}*/
		//------
        _scan.set_tip_xy(_scan.x_tip,posy);
    }
    else if(func_name == "set_scan_size_x" && nargs == 1)
    {
        double x_center = (_scan.x_max + _scan.x_min)/2;
        double x_min = x_center - args[0]/2;
        double x_max = x_center + args[0]/2;
        
        _scan.set(x_min,x_max,_scan.y_min,_scan.y_max,_scan.nx_step,_scan.ny_step,_scan.freq,_scan.theta);
    }
    else if(func_name == "set_scan_size_y" && nargs == 1)
    {
        double y_center = (_scan.y_max + _scan.y_min)/2;
        double y_min = y_center - args[0]/2;
        double y_max = y_center + args[0]/2;
        
        _scan.set(_scan.x_min,_scan.x_max,y_min,y_max,_scan.nx_step,_scan.ny_step,_scan.freq,_scan.theta);
    }
    else if(func_name == "set_scan_center_x" && nargs == 1)
    {
        double x_center = args[0];
        double x_center_old = (_scan.x_max + _scan.x_min)/2;
   
        double x_max = _scan.x_max + (x_center - x_center_old);
        double x_min = _scan.x_min + (x_center - x_center_old);
        
        _scan.set(x_min,x_max,_scan.y_min,_scan.y_max,_scan.nx_step,_scan.ny_step,_scan.freq,_scan.theta);
    }
    else if(func_name == "set_scan_center_y" && nargs == 1)
    {
        double y_center = args[0];
        double y_center_old = (_scan.y_max + _scan.y_min)/2;
   
        double y_max = _scan.y_max + (y_center - y_center_old);
        double y_min = _scan.y_min + (y_center - y_center_old);
        
        _scan.set(_scan.x_min,_scan.x_max,y_min,y_max,_scan.nx_step,_scan.ny_step,_scan.freq,_scan.theta);
    }
	else if (func_name == "set_scan_speed" && nargs == 1)
	{
		double spd = args[0];
		if (spd < 1) {
			spd = 1;
		}
        _scan.set_freq(spd);
    }
	else if (func_name == "set_scan_points_x" && nargs == 1)
	{
		double npts = args[0];
		if (npts < 2) {
			npts = 2; // avoid fatal error that occurs when it was set to 1
		}
        _scan.set(_scan.x_min,_scan.x_max,_scan.y_min,_scan.y_max,npts,_scan.ny_step,_scan.freq,_scan.theta);
    }
     else if(func_name == "set_scan_points_y" && nargs == 1)
    {
		 double npts = args[0];
		 if (npts < 2) {
			 npts = 2; // avoid fatal error that occurs when it was set to 1
		 }
        _scan.set(_scan.x_min,_scan.x_max,_scan.y_min,_scan.y_max,_scan.nx_step,npts,_scan.freq,_scan.theta);
    }
     else if(func_name == "move_tip_laser" && nargs == 4)
     {
         double dx =  mxGetScalar(prhs[1]);
         double dy =  mxGetScalar(prhs[2]);
 
         double x_l = mxGetScalar(prhs[3]);
         double y_l = mxGetScalar(prhs[4]);
         
         _scan.move_tip_laser(dx,dy,x_l,y_l);
     }
     else if(func_name == "start_scan" && nargs == 2)
     {
        WaitForSingleObject(scan_thread_handle,10000);
        CloseHandle( scan_thread_handle );
        
            double x_l = mxGetScalar(prhs[1]);
            double y_l = mxGetScalar(prhs[2]);
            _scan.laser_x = x_l*((double)1/(_scan.laser_x_cal));
            _scan.laser_y = y_l*((double)1/(_scan.laser_y_cal));
        is_scan = true;
        cur_line = 0;
         scan_thread_handle = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&scan_thread,NULL,NULL,NULL);
        
     }
     else if(func_name == "stop_scan" && nargs == 0)
     {

        is_scan = false;
        _scan.is_aborted = true;
        cur_line = 0;
        _scan.stop_scan();  
        
        // WaitForSingleObject(scan_thread_handle,5000);
       //  CloseHandle(scan_thread_handle);
        
         //Reset laser and tip position to the center of the scan
       // _scan.set_tip_xy((_scan.x_max + _scan.x_min)/(double)2, (_scan.y_max+_scan.y_min)/(double)2);
       // _scan.set_laser_position(_scan.laser_x,_scan.laser_y);
     }
     else if(func_name == "set_scan_menu" && nargs == 0)
     {
       
        mxArray* on_str;
        on_str = mxCreateString("on");
        
        mxArray* off_str;
        off_str = mxCreateString("off");
        
        //Set View Channel information
        for(int k = 0; k < 8; k++)
		{
        	char lbl[100];
			sprintf_s(lbl,100,"%d - %s",k,_scan.scan_ch_label[k].c_str());
            
            mxArray* ch_label;
            ch_label = mxCreateString(lbl);
            mxSetProperty(prhs[_handles.channel_item_indices[k]],0,"Label",ch_label);
            if(_scan.is_scan_ch[k])
            {
                 mxSetProperty(prhs[_handles.channel_item_indices[k]],0,"Enable",on_str);
            }
            else
            {
                 mxSetProperty(prhs[_handles.channel_item_indices[k]],0,"Enable",off_str);
            }
            if(_scan.num_selected_ch == k)
            {
                 mxSetProperty(prhs[_handles.channel_item_indices[k]],0,"Checked",on_str);
            }
            else
            {
                mxSetProperty(prhs[_handles.channel_item_indices[k]],0,"Checked",off_str);
            }
            mxDestroyArray(ch_label);
        }
        
         //Set forward/reverse check
        if(direction) //Forward
        {
            mxSetProperty(prhs[,_handles.forward_item_index],0,"Checked",on_str);
            mxSetProperty(prhs[_handles.reverse_item_index],0,"Checked",off_str);
        }
        else //Reverse
        {
            mxSetProperty(prhs[_handles.forward_item_index],0,"Checked",off_str);
            mxSetProperty(prhs[_handles.reverse_item_index],0,"Checked",on_str);
        }
        
          //Set filtered/unfiltered check
        //If current view is channel 0, set filtered/unfiltered, otherwise disable
        if(_scan.num_selected_ch == 0)
        {
             mxSetProperty(prhs[_handles.filtered_item_index],0,"Enable",on_str);
             mxSetProperty(prhs[_handles.unfiltered_item_index],0,"Enable",on_str); 
             
            if(filtered) //Filtered
            {
                mxSetProperty(prhs[_handles.filtered_item_index],0,"Checked",on_str);
                mxSetProperty(prhs[_handles.unfiltered_item_index],0,"Checked",off_str);
            }
            else //Unfiltered
            {
                mxSetProperty(prhs[_handles.filtered_item_index],0,"Checked",off_str);
                mxSetProperty(prhs[_handles.unfiltered_item_index],0,"Checked",on_str);
            }
        }
        else
        {
             mxSetProperty(prhs[_handles.filtered_item_index],0,"Checked",off_str);
             mxSetProperty(prhs[_handles.unfiltered_item_index],0,"Checked",off_str);
             
              mxSetProperty(prhs[_handles.filtered_item_index],0,"Enable",off_str);
             mxSetProperty(prhs[_handles.unfiltered_item_index],0,"Enable",off_str);
            
        }
        
        //Set tip position check
        if(is_draw_tip_position)
        {
             mxSetProperty(prhs[_handles.tip_position_item_index],0,"Checked",on_str);
        }
        else
        {
             mxSetProperty(prhs[_handles.tip_position_item_index],0,"Checked",off_str);
        }
        
        mxDestroyArray(on_str);
        mxDestroyArray(off_str);
        
     }
     else if(func_name == "set_scan_menu_items" && nargs == 15)
     {
        for(int i = 0; i < 8; i++)
        {
         _handles.channel_item[i] = args[i]; 
        // added by Chang (12/07/21)
        _handles.channel_item_indices[i] = i+1;  // referring to prhs as suppose to args
        }
        
        _handles.input_channel_item = args[8];
        _handles.forward_item = args[9];
        _handles.reverse_item = args[10];
        _handles.filtered_item = args[11];
        _handles.unfiltered_item = args[12];  
        _handles.tip_position_item = args[13];
        _handles.invert_colorbar_item = args[14];
        
        // added by Chang (12/07/21)
        _handles.input_channel_item_index = 9;
        _handles.forward_item_index = 10;
        _handles.reverse_item_index = 11;
        _handles.filtered_item_index = 12;
        _handles.unfiltered_item_index = 13;  
        _handles.tip_position_item_index = 14;
        _handles.invert_colorbar_item_index = 15;
        
     }
     else if(func_name == "set_view_channel" && nargs == 1)
     {
        _scan.num_selected_ch = args[0];
	    _scan.set_disp_data(args[0]+1,direction);
        if(args[0] == 0) filtered = true;
        
     }
     else if(func_name == "input_channel_dialog_set" && nargs == 17)
     {
        _handles.input_channel_dialog_handle = args[0];
        
        for(int i = 0; i < 8; i++)
        {
           _handles.ch_checkbox[i] = args[i+1];  
           // added by Chang (12/07/21)
           _handles.ch_checkbox_indices[i] = i+2; 
           _handles.ch_edit[i] = args[i+9];
           // added by Chang (12/07/21)
           _handles.ch_edit_indices[i] = i+10;
        }
        
        //Set current state of scan in dialog box
        mxArray* on_str;
        on_str = mxCreateString("on");
        
        mxArray* off_str;
        off_str = mxCreateString("off");
        
        mxArray* one;
        one = mxCreateDoubleScalar(1);
        
        mxArray* zero;
        zero = mxCreateDoubleScalar(0);
        
         //Disable editing channel zero
         mxSetProperty(prhs[_handles.ch_edit_indices[0]],0,"Enable",off_str);
         mxSetProperty(prhs[_handles.ch_checkbox_indices[0]],0,"Enable",off_str);
            

        for(int k = 0; k < 8; k++)
        {
            
            
            //Populate channel names
            
            mxArray* ch_label;
            ch_label = mxCreateString(_scan.scan_ch_label[k].c_str());
            mxSetProperty(prhs[_handles.ch_edit_indices[k]],0,"String",ch_label);
            
            mxDestroyArray(ch_label);
            
           
            //Check enabled channels
            if(_scan.is_scan_ch[k])
            {
                mxSetProperty(prhs[_handles.ch_checkbox_indices[k]],0,"Value",one);
            }
            else
            {
                mxSetProperty(prhs[_handles.ch_checkbox_indices[k]],0,"Value",zero);
               
            }
            
        }
        
        mxDestroyArray(on_str);
        mxDestroyArray(off_str);
        
         mxDestroyArray(one);
         mxDestroyArray(zero);
     }
     else if(func_name == "input_channel_dialog_ok" && nargs == 0)
     {
        int n_active = 0;
        //Update scan information based on dialog box entries
        for(int i = 0; i < 8; i++)
        {
            mxArray* ret_value;
            ret_value = (mxArray*)mxGetProperty(_handles.ch_checkbox[i],"Value");
            
            int value = mxGetScalar(ret_value);
            mxDestroyArray(ret_value);
            
            if(value == 0)
            {
                 _scan.is_scan_ch[i] = false;   
            }
            else
            {
                _scan.is_scan_ch[i] = true; 
                n_active++;
            }
            
            ret_value = (mxArray*)mxGetProperty(_handles.ch_edit[i],"String");
            
            char lbl[100];
            mxGetString(ret_value,lbl,100);
            
            _scan.scan_ch_label[i] = lbl;
            
            mxDestroyArray(ret_value);
        }
        
        _scan.num_scan_ch = n_active;
        
         _scan.set(_scan.x_min,_scan.x_max,_scan.y_min,_scan.y_max,_scan.nx_step,_scan.ny_step,_scan.freq,_scan.theta);
         _scan.set_disp_data(filtered,direction);
         
         //If current graph view is a channel no longer being measured, switch back to channel 0
		if(_scan.is_scan_ch[_scan.num_selected_ch] == false)
		{
			_scan.num_selected_ch = 0;
		}
        
     }
     else if(func_name == "set_forward" && nargs == 0)
     {
        direction = true;
        if(_scan.num_selected_ch == 0)
        {
            _scan.set_disp_data(filtered,direction);
        }
        else
        {
            _scan.set_disp_data(_scan.num_selected_ch+1,direction);
        }
        
     }
     else if(func_name == "set_reverse" && nargs == 0)
     {
        direction = false;
        if(_scan.num_selected_ch == 0)
        {
            _scan.set_disp_data(filtered,direction);
        }
        else
        {
            _scan.set_disp_data(_scan.num_selected_ch+1,direction);
        }
        
     }
     else if(func_name == "set_filtered" && nargs == 0)
     {
        filtered = true;
	    _scan.set_disp_data(filtered,direction); 
     }
     else if(func_name == "set_unfiltered" && nargs == 0)
     {
        filtered = false;
	    _scan.set_disp_data(filtered,direction); 
     }
     else if(func_name == "draw_tip_position")
     {
        //Toggle drawing tip position
        is_draw_tip_position = !is_draw_tip_position;
 
     }
     else if(func_name == "enable_tip_motion" && nargs == 2)
     {
            //Check to see if mouse clicked near tip to enable motion
        
            double x_pos = args[0];
            double y_pos = args[1];
            
            if(!is_draw_tip_position)  
            {
                is_enable_tip_position = false;
            }
            else
            {
                //Enable tip motion
                if( abs( (double)((x_pos - _scan.x_tip) / (_scan.x_max - _scan.x_min) )) < 0.01 && abs( (double)((y_pos - _scan.y_tip) / (_scan.y_max - _scan.y_min) )) < 0.01 )
                {
                     is_enable_tip_position = true;
                }
                else
                {
                     is_enable_tip_position = false;
                }
            }
     }
     else if(func_name == "tip_motion" && nargs == 2)
     {
        if(is_draw_tip_position && is_enable_tip_position)
        {
            if(args[0] < _scan.x_min_scan) args[0] = _scan.x_min_scan;
            if(args[0] > _scan.x_max_scan) args[0] = _scan.x_max_scan;

            if(args[1] < _scan.y_min_scan) args[1] = _scan.y_min_scan;
            if(args[1] > _scan.y_max_scan) args[1] = _scan.y_max_scan;
             
            _scan.set_tip_xy(args[0],args[1]); 
        }
     }
    else if(func_name == "adjust_tip_position" && nargs == 2)
     {
        //Arguments are amount to move the tip in X and Y in um.
        //Use calibration factor of 10 um = 1 V.
        double new_x = _scan.x_tip + args[0]/(float)10;
        double new_y = _scan.y_tip + args[1]/(float)10;
        
         if(new_x < _scan.x_min_scan) new_x = _scan.x_min_scan;
         if(new_x > _scan.x_max_scan) new_x = _scan.x_max_scan;

         if(new_y < _scan.y_min_scan) new_y = _scan.y_min_scan;
         if(new_y > _scan.y_max_scan) new_y = _scan.y_max_scan;

        _scan.set_tip_xy(new_x,new_y);
     }
     else if(func_name == "disable_tip_motion" && nargs == 0)
     {  
        is_enable_tip_position = false;
     }
     else if(func_name == "set_plane_dialog_items" && nargs == 9)
     {
        _handles.plane_x_edit = args[0];
        _handles.plane_y_edit = args[1];
        _handles.plane_z_edit = args[2];
        _handles.plane_listbox = args[3];
        _handles.plane_offset_edit = args[4];
        _handles.plane_a_text = args[5];
        _handles.plane_b_text = args[6];
        _handles.plane_c_text = args[7];
        _handles.plane_r2_text = args[8];

        // added to adapt to the new mex file format (Chang Jin 12/7/21) ============
        _handles.plane_x_edit_index = 1;
        _handles.plane_y_edit_index = 2;
        _handles.plane_z_edit_index = 3;
        _handles.plane_listbox_index = 4;
        _handles.plane_offset_edit_index = 5;
        _handles.plane_a_text_index = 6;
        _handles.plane_b_text_index = 7;
        _handles.plane_c_text_index = 8;
        _handles.plane_r2_text_index = 9;
        //===========================================================================
        
        redraw_plane_dialog();
     }
     else if(func_name == "add_plane_point" && nargs == 3)
     {
        add_plane_point(args[0],args[1],args[2]);  
     }
     else if(func_name == "get_current_position" && nargs == 0)
     {
        HANDLE z_thread_handle = _scan.get_current_z();
        WaitForSingleObject(z_thread_handle,INFINITE);
        add_plane_point(_scan.x_tip,_scan.y_tip,_scan.current_z);
        
     }
     else if(func_name == "delete_all_position" && nargs == 0)
     {
        is_valid_plane = false;
        pp.clear();
        
       redraw_plane_dialog();
        
     }
     else if(func_name == "delete_selected_position" && nargs == 1)
     {
            int val = args[0];
            if(val >= 1 && val <= pp.size())
            {
                pp.erase(pp.begin() + val - 1);
            }
            
            redraw_plane_dialog();
            
        
     }
     else if(func_name == "plane_ok" && nargs == 0)
     {
        //Save offset voltage
        const mxArray* offset_arr;
        offset_arr = mxGetProperty(_handles.plane_offset_edit,"String");
        
        char* offset_str;
        offset_str = mxArrayToString(offset_arr);
        
        _planeInfo.offset = atof(offset_str)/(double)1000;
        
     }
     else if(func_name == "snap_plane" && nargs == 1)
     {
        if(args[0] == 1) //Snap plane box has been checked
        {
            _planeInfo.is_plane_active = true;
            _scan.set_tip_xy(_scan.tip_x,_scan.tip_y);
        }
        else if(args[0] == 0) //Snap plane box has been unchecked
        {
             _planeInfo.is_plane_active = false;
        }
     }
     else if(func_name == "pulse_seq" && nargs == 1)
     {
        if(args[0] == 1) //Pulse seq box has been checked
        {
            _scan.pulse_seq = true;
        }
        else if(args[0] == 0) //Pulse seq box has been unchecked
        {
             _scan.pulse_seq = false;
        }
     }
     else if(func_name == "tip_tracking" && nargs == 2)
     {
      //Move tip and scan center from tracking routine
        
        
         _scan.set_tracking(args[0],args[1]);
        
     }
     else if(func_name == "is_scan" && nargs == 0)
     {
        mxArray* iss;
        iss = mxCreateDoubleScalar(is_scan);
        plhs[0] = iss;
        
     }
     else if(func_name == "move_MCL" && nargs == 2)
     {
        is_MCL_readout = false;
        WaitForSingleObject(MCL_thread,1000);
        
        int axis = args[0];
        double move = args[1];
        
        if(axis == 1)
        {
            MCL_SingleWriteN(MCL_x_pos + move,1,MCL_handle);
        }
        else if(axis == 2)
        {
            MCL_SingleWriteN(MCL_y_pos + move,2,MCL_handle);
        }
        else if(axis == 3)
        {
            MCL_SingleWriteN(MCL_z_pos + move,3,MCL_handle);
        }
        
        is_MCL_readout = true;
        MCL_thread = (HANDLE)CreateThread( NULL, 0, (LPTHREAD_START_ROUTINE)&MCL_readout, NULL, NULL,NULL );
        
     }
     else if(func_name == "calibrate" && nargs == 0)
     {
        if(!is_calibrate_thread)
        {
            is_calibrate_thread = true;
            calibrate_handle = (HANDLE)CreateThread( NULL, 0, (LPTHREAD_START_ROUTINE)&calibrate_thread, NULL, NULL,NULL );
        }
        
     }
     else if(func_name == "micronix_x_mvr" && nargs==1)
     {
       // micronix .
        double xstep = 0.001*args[0]; // in mm (args in um  <0 or >0 depending on button pressed)
        // do not execute position step if approaching or scanning
        if(!is_thread && !is_scan) {
            int ax=1; // x

			is_Micronix_commanded = true;
			// set relative position
			char mvrStr[50];
			int numCharD = sprintf_s(mvrStr, 50, "%iMVR%1.6f\r", ax, xstep);
            _handles.Micronix_serial.SendData(mvrStr,numCharD); // MVR: move relative
			Sleep(100);

			/*----begin comment to test micronix_thread

			//mxArray* bufferSizeOut;
			//bufferSizeOut = mxCreateDoubleScalar(dataPosBytesRead);
			char numBytesStr[50];
			sprintf_s(numBytesStr, 50, "%i", dataPosBytesRead);

			mxArray* readpos_str;
			readpos_str = mxCreateString(readPos);
			mxSetProperty(prhs[_handles.mic_xpos, "Str],0ing", readpos_str);

			mxArray* debug1_str;
			debug1_str = mxCreateString(mvrStr);
			mxSetProperty(prhs[_handles.mic_debug1, "S],0tring", debug1_str);

			mxArray* debug2_str;
			debug2_str = mxCreateString(posStr);
			mxSetProperty(prhs[_handles.mic_debug2, "S],0tring", debug2_str);

			mxArray* debug3_str;
			debug3_str = mxCreateString(readPos);
			mxSetProperty(prhs[_handles.mic_debug3, "S],0tring", debug3_str);

			-----end comment to test micronix_thread*/
			is_Micronix_commanded = false;
        }
     }
     else if(func_name == "micronix_y_mvr" && nargs==1)
     {
		 // micronix .
		 double ystep = 0.001*args[0]; // in mm (args in um  <0 or >0 depending on button pressed)
		 // do not execute position step if approaching or scanning
		 if (!is_thread && !is_scan) {
			 int ax = 2; // y

			 is_Micronix_commanded = true;
			 // set relative position
			 char mvrStr[50];
			 int numCharD = sprintf_s(mvrStr, 50, "%iMVR%1.6f\r", ax, ystep);
			 _handles.Micronix_serial.SendData(mvrStr, numCharD); // MVR: move relative
			 Sleep(100);

			 is_Micronix_commanded = false;
		 }
     }
	 else if (func_name == "micronix_z_mvr" && nargs == 1)
	 {
		 // micronix .
		 double zstep = 0.001*args[0]; // in mm (args in um  <0 or >0 depending on button pressed)
		 // do not execute position step if approaching or scanning
		 if (!is_thread && !is_scan) {
			 int ax = 3; // z

			 is_Micronix_commanded = true;
			 // set relative position
			 char mvrStr[50];
			 int numCharD = sprintf_s(mvrStr, 50, "%iMVR%1.6f\r", ax, zstep);
			 _handles.Micronix_serial.SendData(mvrStr, numCharD); // MVR: move relative
			 Sleep(100);

			 is_Micronix_commanded = false;
		 }
	 }
    
    else if(func_name == "button_down" && nargs == 2)
    {
        x_pos = args[0];
        y_pos = args[1];
        
         if( abs((double)(y_pos - min_flag))/(double)(axes_max - axes_min) < 0.01)
            {
             //Move position of min line  
               is_min_move = true;
            }
         else if( abs((double)(y_pos - max_flag))/(double)(axes_max - axes_min) < 0.01)
            {

             //Move position of max line  
               is_max_move = true;  
            }
 
    }
     else if(func_name == "button_up" && nargs == 2)
    {
        x_pos = args[0];
        y_pos = args[1];
        
        is_min_move = false;
        is_max_move = false;
        
        
        
    }
     else if(func_name == "button_drag" && nargs == 2)
    {
        x_pos = args[0];
        y_pos = args[1];
        
    
       if(is_min_move && y_pos < max_flag && y_pos >= axes_min && y_pos <= axes_max)
       {
           min_flag = y_pos;
           
           mxArray* y_set;
           mwSize dims[2] = {1,2};
     
           y_set = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
           mexMakeArrayPersistent(y_set);
           double* y_set_ptr = mxGetPr(y_set);
           
           y_set_ptr[0] = y_pos;
           y_set_ptr[1] = y_pos;
           
           // mexSet(min_line_handle,"YData",y_set);
           mxSetProperty(prhs[min_line_handle_index],0,"YData",y_set);

           mxDestroyArray(y_set);
           
            
       }
       else if (is_max_move && y_pos > min_flag && y_pos >= axes_min && y_pos <= axes_max)
       {
           max_flag = y_pos;
           
           mxArray* y_set;
           mwSize dims[2] = {1,2};
     
           y_set = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
           mexMakeArrayPersistent(y_set);
           double* y_set_ptr = mxGetPr(y_set);
           
           y_set_ptr[0] = y_pos;
           y_set_ptr[1] = y_pos;
           
           // mexSet(max_line_handle,"YData",y_set);
           mxSetProperty(prhs[max_line_handle_index],0,"YData",y_set);

            
           mxDestroyArray(y_set);
           
            
       }
     }
        
        
        
    
    delete [] args;
 
    return;
}