#include "mex.h"
#include <windows.h>
#include <stdio.h>
#include <process.h>
#include <string>
#include <vector>
#include "DAC.h"
#include "scan.h"
#include "handles.h"
#include "bestfit.h"
#include "Madlib.h"
#include "Serial.h"

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

HANDLE tip_read_thread;
HANDLE approach_thread_handle;
HANDLE check_approach_thread_handle;
HANDLE scan_thread_handle;

double axes_handle;
double min_line_handle;
double max_line_handle;
double textbox_tip_volt_handle;
double textbox_min_volt_handle;
double textbox_max_volt_handle;
double thor_handle;
double z_in_disp_handle;

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

void get_matlab_data()
{
    if(!_scan.is_matlab_data && _scan.is_measuring_matlab)
    {
        _scan.is_measuring_matlab = false;
     
        mxArray* lhs[1];
        mexCallMATLAB(1,lhs,0,NULL,"scan_pulse_seq");

        _scan.matlab_data = mxGetScalar(lhs[0]);
         mxDestroyArray(lhs[0]);

        _scan.is_matlab_data = true;
        _scan.is_measuring_matlab = true;

       
    }
    
}

void Thor_Step()
{
   if(is_step)
   {
       
    // Send Message to ThorLabs executable
     HWND hwnd = FindWindow(NULL, "ThorLabsAPT");
    SendMessage(hwnd, WM_APP + 1001, NULL, NULL);
     is_step = false;
   }
    
    
}

void MicronixZ_Step()
{
   if(is_step)
   {
       
    // step the set amount for an approach 
    // tip is below sample, so the MicronixZ must step
    // in the down direction. this is Increment > 0
     is_step = false;
   }   
    
}

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
   
    mexSet(axes_handle,"YData",mxy_data);
    
      
    
    char disp_str[50];
    
     mxArray* tip_volt;
     
    sprintf_s(disp_str,50,"%.3f mV",1000*y_data[buffer - 1]);
    tip_volt = mxCreateString(disp_str);
      mexMakeArrayPersistent(tip_volt);
     mexSet(textbox_tip_volt_handle,"String",tip_volt);  
     
     mxDestroyArray(tip_volt);
     
       mxArray* min_volt;
     
    sprintf_s(disp_str,50,"%.3f mV",1000*min_flag);
    min_volt = mxCreateString(disp_str);
      mexMakeArrayPersistent(min_volt);
     mexSet(textbox_min_volt_handle,"String",min_volt);  
     
     mxDestroyArray(min_volt);
     
      mxArray* max_volt;
     
    sprintf_s(disp_str,50,"%.3f mV",1000*max_flag);
    max_volt = mxCreateString(disp_str);
      mexMakeArrayPersistent(max_volt);
     mexSet(textbox_max_volt_handle,"String",max_volt);  
     
     mxDestroyArray(max_volt);
     
      mxArray* z_in_disp;
     
      sprintf_s(disp_str,50,"%.3f",_DAC.z_in_current);
    z_in_disp = mxCreateString(disp_str);
      mexMakeArrayPersistent(z_in_disp);
     mexSet(z_in_disp_handle,"String",z_in_disp);  
     
     mxDestroyArray(z_in_disp);
     
         mxArray* off_str;
        off_str = mxCreateString("off");
        
        mxArray* on_str;
        on_str = mxCreateString("on");
    
      if(measure)
     {
       
       
        if(is_thread)
         {

            mexSet(_handles.start_approach_handle,"Enable",off_str);
            mexSet(_handles.stop_approach_handle,"Enable",on_str); 
             mexSet(_handles.start_graph_handle,"Enable",off_str);
              mexSet(_handles.stop_graph_handle,"Enable",off_str);  
         }
         else
         {
             mexSet(_handles.start_graph_handle,"Enable",off_str);
        mexSet(_handles.stop_graph_handle,"Enable",on_str);  
            mexSet(_handles.start_approach_handle,"Enable",on_str);
            mexSet(_handles.stop_approach_handle,"Enable",off_str);

         }
     }
     else
     {
        mexSet(_handles.start_graph_handle,"Enable",on_str);
        mexSet(_handles.stop_graph_handle,"Enable",off_str);
         mexSet(_handles.start_approach_handle,"Enable",off_str);
            mexSet(_handles.stop_approach_handle,"Enable",off_str);  
     }
        
    
        
    
    
    
      mxDestroyArray(off_str);
      mxDestroyArray(on_str);
    
}


void get_dac_data()
{
	int count = 0;
	while(measure)
	{
    		current_bridge = _DAC.approach_check();
            count++;
       

			// printf("%d\r\n",count);
		//if( (count % 5) == 0) 
		//	{
				bridge_data.push_back(current_bridge);
				if(bridge_data.size() == (buffer + 1) ) 
               {
                    bridge_data.erase(bridge_data.begin());
                }
         //  }
    
	}

	return;
}

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
     mexSet(_handles.x_tip_position,"String",disp_array);  
     mxDestroyArray(disp_array);

     
    sprintf_s(disp_str,50,"%.4f V",_scan.y_tip);
    disp_array = mxCreateString(disp_str);
     mexSet(_handles.y_tip_position,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
     double x_size = (_scan.x_max - _scan.x_min);
     
       sprintf_s(disp_str,50,"%.4f V",x_size);
    disp_array = mxCreateString(disp_str);
     mexSet(_handles.x_scan_size,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
      double y_size = (_scan.y_max - _scan.y_min);
     
       sprintf_s(disp_str,50,"%.4f V",y_size);
    disp_array = mxCreateString(disp_str);
     mexSet(_handles.y_scan_size,"String",disp_array);  
     
     mxDestroyArray(disp_array);
    
     
       sprintf_s(disp_str,50,"%.4f V",_scan.x_center);
    disp_array = mxCreateString(disp_str);
     mexSet(_handles.x_scan_center,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
       sprintf_s(disp_str,50,"%.4f V",_scan.y_center);
    disp_array = mxCreateString(disp_str);
     mexSet(_handles.y_scan_center,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
     
     sprintf_s(disp_str,50,"%d Hz",(int)_scan.freq);
    disp_array = mxCreateString(disp_str);
     mexSet(_handles.scan_speed,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
      sprintf_s(disp_str,50,"%d",_scan.nx_step);
    disp_array = mxCreateString(disp_str);
     mexSet(_handles.x_points,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
       sprintf_s(disp_str,50,"%d",_scan.ny_step);
    disp_array = mxCreateString(disp_str);
     mexSet(_handles.y_points,"String",disp_array);  
     
     mxDestroyArray(disp_array);
     
        mxArray* off_str;
        off_str = mxCreateString("off");
        
        mxArray* on_str;
        on_str = mxCreateString("on");
    
     
     if(is_scan)
     {

        mexSet(_handles.start_scan_handle,"Enable",off_str);
        mexSet(_handles.stop_scan_handle,"Enable",on_str);  
     }
     else
     {
    
        mexSet(_handles.start_scan_handle,"Enable",on_str);
        mexSet(_handles.stop_scan_handle,"Enable",off_str);
 
     }
        
        if(is_valid_plane)
        {
             mexSet(_handles.snap_plane_handle,"Enable",on_str);
     
        }
        else
        {
              mexSet(_handles.snap_plane_handle,"Enable",off_str);
        }
    
    
      mxDestroyArray(off_str);
      mxDestroyArray(on_str);
    
}
void update_scan_data()
{
 if(!is_update_scan_data) return;
    mxArray* str;
 
 str = mxCreateString("on");
 
 mexSet(_handles.scan_axes_handle,"Visible",str);
 
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

      
     
    mexSet(_handles.cur_line_handle,"XData",x_line_data);
    mexSet(_handles.cur_line_handle,"YData",y_line_data);
    mexSet(_handles.cur_line_handle,"ZData",z_line_data);
    mexSet(_handles.cur_line_handle,"Visible",on_str);
    
    mxDestroyArray(x_line_data);
    mxDestroyArray(y_line_data);
    mxDestroyArray(z_line_data);
    
     
 }
 else
 {
      
       
      mexSet(_handles.cur_line_handle,"Visible",off_str);

     
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
       
        mexSet(_handles.tip_position_x_handle,"XData",x_tip_data);
        mexSet(_handles.tip_position_x_handle,"YData",y_tip_data);
        mexSet(_handles.tip_position_x_handle,"ZData",z_tip_data);
        
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
       
        mexSet(_handles.tip_position_y_handle,"XData",x_tip_data);
        mexSet(_handles.tip_position_y_handle,"YData",y_tip_data);
        mexSet(_handles.tip_position_y_handle,"ZData",z_tip_data);
        
        mxArray* green_str;
        mxArray* blue_str;
        mxArray* red_str;
        
        green_str = mxCreateString("green");
        blue_str = mxCreateString("blue");
        red_str = mxCreateString("red");
        
        if(is_enable_tip_position)
        {
             mexSet(_handles.tip_position_x_handle,"Color",green_str);
             mexSet(_handles.tip_position_y_handle,"Color",green_str);
        }
        else
        {
            if(_scan.x_tip < _scan.x_min || _scan.x_tip > _scan.x_max || _scan.y_tip < _scan.y_min || _scan.y_tip > _scan.y_max)
            {
                mexSet(_handles.tip_position_x_handle,"Color",red_str);
                mexSet(_handles.tip_position_y_handle,"Color",red_str);
                
            }
            else
            {
                mexSet(_handles.tip_position_x_handle,"Color",blue_str);
                mexSet(_handles.tip_position_y_handle,"Color",blue_str);   
            }
            
            
        }
     
      mexSet(_handles.tip_position_x_handle,"Visible",on_str);
       mexSet(_handles.tip_position_y_handle,"Visible",on_str);
       
       mxDestroyArray(x_tip_data);
       mxDestroyArray(y_tip_data);
       mxDestroyArray(z_tip_data);
       mxDestroyArray(green_str);
       mxDestroyArray(blue_str);
       mxDestroyArray(red_str);
     
 }
 else
 {
     mexSet(_handles.tip_position_x_handle,"Visible",off_str);
       mexSet(_handles.tip_position_y_handle,"Visible",off_str);
     
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
   mexSet(_handles.scan_grid_handle,"XLim",x_lim);
   mexSet(_handles.scan_grid_handle,"YLim",y_lim);
 
  mxDestroyArray(x_lim);
  mxDestroyArray(y_lim);
       

 mexSet(_handles.scan_axes_handle,"XData",x_data);
 mexSet(_handles.scan_axes_handle,"YData",y_data);
 mexSet(_handles.scan_axes_handle,"ZData",scan_data);
  mexSet(_handles.scan_axes_handle,"CData",c_data);
 //Set scaling for colormap
  /* mxArray* color_data;
       mwSize color_dim[2] = {1,2};
       color_data = mxCreateNumericArray(2,color_dim,mxDOUBLE_CLASS,mxREAL);
       double* color_data_ptr = mxGetPr(color_data);
       
       color_data_ptr[0] = *(_scan.z_min);
       color_data_ptr[1] = *(_scan.z_max);
      
       
 
  mexSet(_handles.scan_axes_handle,"CLim",color_data);
 
 mxDestroyArray(color_data);
  */ 
  
    
  
 
     mxDestroyArray(x_data);
   mxDestroyArray(y_data);
  
 mxDestroyArray(scan_data);
  mxDestroyArray(c_data);

 

    
}

void scan_thread()
{
    
    if(cur_line == 0)
    {
        //Stop tip graph
        measure = false;
        WaitForSingleObject(tip_read_thread,1000);
        CloseHandle(tip_read_thread);
   
       
        //Get current laser position
        _scan.get_laser_position();
        
        //Start tip graph
        measure = true;
        tip_read_thread = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&get_dac_data,NULL,NULL,NULL);
              
        
    }
    
    if(is_scan)
    {
        _scan.save(true,true);
  
       if(_scan.pulse_seq)
       {
            _scan.scan_line_sequence(cur_line,"");
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
    
    if(cur_line == _scan.ny_step - 1)
    {     
        _scan.save(true,false);
 
         //Reset laser and tip position to the center of the scan
        _scan.set_tip_xy((_scan.x_max + _scan.x_min)/(double)2, (_scan.y_max+_scan.y_min)/(double)2);
        _scan.set_laser_position(_scan.laser_x,_scan.laser_y);
       // if(_scan.use_tracking)
       // {
       //     _scan.get_center();
       // }
        is_scan = false;
        
          _scan.save(true,true);
        
        
    }
    else
    {
        cur_line++;
        scan_thread_handle = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&scan_thread,NULL,NULL,NULL);
    }
    
    
}
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
        
        mexSet(_handles.plane_x_edit,"String",null_str);
        mexSet(_handles.plane_y_edit,"String",null_str);
        mexSet(_handles.plane_z_edit,"String",null_str);
        
      
        
        if(pp.size() == 0)
        {

          mexSet(_handles.plane_listbox,"String",null_str);

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
            mexSet(_handles.plane_listbox,"Value",one_arr);
            mexSet(_handles.plane_listbox,"String",plane_list);
            
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
            mexSet(_handles.plane_a_text,"String",a_str);

            char btxt[30];
            sprintf_s(btxt,30,"%.5f",_planeInfo.b);
            b_str = mxCreateString(btxt);
            mexSet(_handles.plane_b_text,"String",b_str);

            char ctxt[30];
            sprintf_s(ctxt,30,"%.5f",_planeInfo.c);
            c_str = mxCreateString(ctxt);
            mexSet(_handles.plane_c_text,"String",c_str);

            char r2txt[30];
            sprintf_s(r2txt,30,"%.4f",_planeInfo.r2);
            r2_str = mxCreateString(r2txt);
            mexSet(_handles.plane_r2_text,"String",r2_str);
            
            mxDestroyArray(a_str);
             mxDestroyArray(b_str);
              mxDestroyArray(c_str);
               mxDestroyArray(r2_str);
            
        }
        else
        {
         
            is_valid_plane = false;
            mexSet(_handles.plane_a_text,"String",null_str);
            mexSet(_handles.plane_b_text,"String",null_str);
            mexSet(_handles.plane_c_text,"String",null_str);
            mexSet(_handles.plane_r2_text,"String",null_str);
    
        }
        
        char offstr[100];
	    sprintf(offstr,"%.1f",_planeInfo.offset*(double)1000);
        
        mxArray* offset_arr;
        offset_arr = mxCreateString(offstr);
        mexSet(_handles.plane_offset_edit,"String",offset_arr);
        
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

     mexSet(_handles.MCL_x,"String",x_value);  
     mexSet(_handles.MCL_y,"String",y_value);  
     mexSet(_handles.MCL_z,"String",z_value);  
     
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
void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
     
{ 

    char str[100];
    
    mxGetString(prhs[0],str,100);
    
    std::string func_name(str);
    
    double* args;
    int nargs = nrhs - 1;
    
    if(nrhs >= 1)
    {
        
        args = new double[nargs];
        
        for(int k = 0; k < nargs; k++)
        {
            args[k] = mxGetScalar(prhs[k + 1]);
        }
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
         buffer = mxGetScalar(prhs[8]);
         
       
         
            mwSize dims[2] = {1,buffer};
     
           mxy_data = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
           mexMakeArrayPersistent(mxy_data);
           y_data = mxGetPr(mxy_data);
           
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
        
        is_button_down = false;
        is_min_move = false;
        is_max_move = false;
        is_step = false;
        
        min_flag = -0.5;
        max_flag = 0.5;
        
        axes_min = -1;
        axes_max = 1;
        
        approach_min = 1;
        approach_max = 9;
        approach_rate = 0.0725;
        approach_retract = 0.05;
        
        n_steps = 0;
        
        cur_line = 0;
        is_scan = false;
        
        direction = true;
        filtered = true;
        
        is_draw_tip_position = false;
        is_enable_tip_position = false;
      
        
        _DAC.define_approach_task();
        
        measure = true;
        is_update_scan_info = true;
        is_update_scan_data = true;
        is_update_MCL_readout = true;
        tip_read_thread = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&get_dac_data,NULL,NULL,NULL);
        
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
       
       is_calibrate_thread = false;
       
       n_cal_pts = 250;
       
       _scan.laser_x_cal = 10.000/58.0471;
       _scan.laser_y_cal = 10.000/55.3411;
       
 
       
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
       
    }
    else if(func_name == "close")
    {
        // Send Message to ThorLabs executable
         HWND hwnd = FindWindow(NULL, "ThorLabsAPT");
        SendMessage(hwnd, WM_CLOSE, NULL, NULL);
        //  KillTimer(NULL,timer_readout);
        
        // close Micronix port
        CloseHandle(_handle.Micronix_serial);
         
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
        
     
   
          KillTimer(NULL,timer_graph);
          KillTimer(NULL,thor_timer);
          KillTimer(NULL,matlab_data_timer);
           KillTimer(NULL,update_scan_timer);
           KillTimer(NULL,update_scan_data_timer);
             KillTimer(NULL,MCL_timer);
  
             WaitForSingleObject(MCL_thread,1000);
              WaitForSingleObject(calibrate_thread,1000);
        WaitForSingleObject(tip_read_thread,1000);
           WaitForSingleObject(approach_thread,1000);
           WaitForSingleObject(check_approach_thread,1000);
           WaitForSingleObject(scan_thread_handle,1000);
       
       
           
        CloseHandle( MCL_thread );
        CloseHandle(calibrate_thread);
        CloseHandle( tip_read_thread );
         CloseHandle( approach_thread );
          CloseHandle( check_approach_thread );
         CloseHandle( scan_thread_handle);
         
          MCL_ReleaseAllHandles();
         
         
          mxDestroyArray(mxy_data);
    
          
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
    
        
    }
    else if(func_name == "set_MCL_handles" && nargs == 3)
    {
        _handles.MCL_x = mxGetScalar(prhs[1]);
        _handles.MCL_y = mxGetScalar(prhs[2]);
        _handles.MCL_z = mxGetScalar(prhs[3]);

    }
    else if(func_name == "set_Micronix_port
    {   
        _handles.Micronix_serial = CreateFile("COM5", GENERIC_READ | GENERIC_WRITE,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
        if(_handles.Micronix_serial==INVALID_VALUE){
            if(GetLastError()==ERROR_FILE_NOT_FOUND){
                // add an output error message to GUI or Matlab terminal: Serial port does not exist
            }
            // add an output error message to GUI or Matlab terminal
        }
        
        // parameters
        DCB dcbSerialParams = {0};
        dcbSerial.DCBlength=sizeof(dcbSerialParams);
        if(!GetCommState(_handles.Micronix_serial,&dcbSerialParams)){
            // add an output error message: state is not retrieved
        }
        dcbSerialParams.BaudRate=CBR_38400;
        dcbSerialParams.ByteSize=8;
        dcbSerialParams.StopBits=ONESTOPBIT;
        dcbSerialParams.Parity=NOPARITY;
        if(~SetCommState(_handles.Micronix_serial,&dcbSerialParams)){
            // add an output error message: COM parameters not set
        }
        
        // alternative to having a serial thread running:
        COMMTIMEOUTS timeouts={0};
        timeouts.ReadIntervalTimeout=50; // wait time between characters (ms) before timeout
        timeouts.ReadTotalTimeoutConstant=50; //wait time before returning
        timeouts.ReadTotalTimeoutMultipiler=10; //additional time before returning for each byte in a read
        timeouts.WriteTotalTimeoutConstant=50; //wait time before returning
        timeouts.WriteTotalTimeoutMultipiler=10; //additional time before returning for each byte in a write
        if(!SetCommTimeouts(_handles.Micronix_serial,&timeouts)){
            // add an output error message: serial timeouts not set
        }
        
            
    }
    else if(func_name == "z_in" && nargs == 1)
    {
        _DAC.z_in(args[0]);
         update_scan_info();
    }
    else if(func_name == "start_approach")
    {
          //Set properties in ThorLabs executable
          HWND hwnd = FindWindow(NULL, "ThorLabsAPT");
        SendMessage(hwnd, WM_APP + 1000, NULL, NULL);
        
         SetTimer(NULL,thor_timer,100,(TIMERPROC)Thor_Step);
         
         is_thread = true;
        approach_thread_handle = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&approach_thread,NULL,NULL,NULL);
        check_approach_thread_handle = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&check_approach_thread,NULL,NULL,NULL);
    }
    else if(func_name == "stop_approach")
    {
        _DAC.stop_sweep();
       
        KillTimer(NULL,thor_timer);
		is_thread = false;
    }
    else if(func_name == "stop_graph")
    {
        measure = false;
        WaitForSingleObject(tip_read_thread,1000);
        CloseHandle(tip_read_thread);
    }  
     else if(func_name == "start_graph")
    {
        measure = true;
        tip_read_thread = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&get_dac_data,NULL,NULL,NULL);
 
    }
    else if(func_name == "set_tip_x" && nargs == 1)
    {
        _scan.set_tip_xy(args[0],_scan.y_tip);
    }
    else if(func_name == "set_tip_y" && nargs == 1)
    {
        _scan.set_tip_xy(_scan.x_tip,args[0]);
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
    else if(func_name == "set_scan_speed" && nargs == 1)
    {
        _scan.set_freq(args[0]);
    }
    else if(func_name == "set_scan_points_x" && nargs == 1)
    {
        _scan.set(_scan.x_min,_scan.x_max,_scan.y_min,_scan.y_max,args[0],_scan.ny_step,_scan.freq,_scan.theta);
    }
     else if(func_name == "set_scan_points_y" && nargs == 1)
    {
        _scan.set(_scan.x_min,_scan.x_max,_scan.y_min,_scan.y_max,_scan.nx_step,args[0],_scan.freq,_scan.theta);
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
            mexSet(_handles.channel_item[k],"Label",ch_label);
            if(_scan.is_scan_ch[k])
            {
                 mexSet(_handles.channel_item[k],"Enable",on_str);
            }
            else
            {
                 mexSet(_handles.channel_item[k],"Enable",off_str);
            }
            if(_scan.num_selected_ch == k)
            {
                 mexSet(_handles.channel_item[k],"Checked",on_str);
            }
            else
            {
                mexSet(_handles.channel_item[k],"Checked",off_str);
            }
            mxDestroyArray(ch_label);
        }
        
         //Set forward/reverse check
        if(direction) //Forward
        {
            mexSet(_handles.forward_item,"Checked",on_str);
            mexSet(_handles.reverse_item,"Checked",off_str);
        }
        else //Reverse
        {
            mexSet(_handles.forward_item,"Checked",off_str);
            mexSet(_handles.reverse_item,"Checked",on_str);
        }
        
          //Set filtered/unfiltered check
        //If current view is channel 0, set filtered/unfiltered, otherwise disable
        if(_scan.num_selected_ch == 0)
        {
             mexSet(_handles.filtered_item,"Enable",on_str);
             mexSet(_handles.unfiltered_item,"Enable",on_str); 
             
            if(filtered) //Filtered
            {
                mexSet(_handles.filtered_item,"Checked",on_str);
                mexSet(_handles.unfiltered_item,"Checked",off_str);
            }
            else //Unfiltered
            {
                mexSet(_handles.filtered_item,"Checked",off_str);
                mexSet(_handles.unfiltered_item,"Checked",on_str);
            }
        }
        else
        {
             mexSet(_handles.filtered_item,"Checked",off_str);
             mexSet(_handles.unfiltered_item,"Checked",off_str);
             
              mexSet(_handles.filtered_item,"Enable",off_str);
             mexSet(_handles.unfiltered_item,"Enable",off_str);
            
        }
        
        //Set tip position check
        if(is_draw_tip_position)
        {
             mexSet(_handles.tip_position_item,"Checked",on_str);
        }
        else
        {
             mexSet(_handles.tip_position_item,"Checked",off_str);
        }
        
        mxDestroyArray(on_str);
        mxDestroyArray(off_str);
        
     }
     else if(func_name == "set_scan_menu_items" && nargs == 15)
     {
        for(int i = 0; i < 8; i++)
        {
         _handles.channel_item[i] = args[i];   
        }
        
        _handles.input_channel_item = args[8];
        _handles.forward_item = args[9];
        _handles.reverse_item = args[10];
        _handles.filtered_item = args[11];
        _handles.unfiltered_item = args[12];  
        _handles.tip_position_item = args[13];
        _handles.invert_colorbar_item = args[14];
        
        
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
           _handles.ch_edit[i] = args[i+9];
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
         mexSet( _handles.ch_edit[0],"Enable",off_str);
         mexSet( _handles.ch_checkbox[0],"Enable",off_str);
            

        for(int k = 0; k < 8; k++)
        {
            
            
            //Populate channel names
            
            mxArray* ch_label;
            ch_label = mxCreateString(_scan.scan_ch_label[k].c_str());
            mexSet( _handles.ch_edit[k],"String",ch_label);
            
            mxDestroyArray(ch_label);
            
           
            //Check enabled channels
            if(_scan.is_scan_ch[k])
            {
                mexSet(_handles.ch_checkbox[k],"Value",one);
            }
            else
            {
                 mexSet(_handles.ch_checkbox[k],"Value",zero);
               
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
            ret_value = (mxArray*)mexGet(_handles.ch_checkbox[i],"Value");
            
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
            
            ret_value = (mxArray*)mexGet(_handles.ch_edit[i],"String");
            
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
        offset_arr = mexGet(_handles.plane_offset_edit,"String");
        
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
           
           mexSet(min_line_handle,"YData",y_set);
            
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
           
           mexSet(max_line_handle,"YData",y_set);
            
           mxDestroyArray(y_set);
           
            
       }
     }
        
        
        
    
    delete [] args;
 
    return;
}