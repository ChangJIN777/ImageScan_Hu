#include "scan.h"
//#include "stdio.h"
//#include "NIDAQmx.h"
#include <fstream>
#include <cmath>
#include "bestfit.h"
#include <vector>

#include "mysql.h"
#include "FreeImage.h" 
#include "mex.h"

UINT_PTR timer_matlab;
bool is_matlab_data;

scan::scan()
{
	pi = 3.14159265358979323846264;

	x_min = 0;
	x_max = 0;
	y_min = 0;
	y_max = 0;

	for(int i = 0; i < 8; i++)
	{
		min_max[i] = 0;
	}
	z_min = &min_max[2];
	z_max = &min_max[3];

	for(int i = 0; i < 28; i++)
	{
		ch_min_max[i] = 0;
	}

	x_tip = 0;
	y_tip = 0;

	nx_step = 0;
	ny_step = 0;
	//n_averages = 0;

	freq = 0;

	x_min_scan = 0;
	x_max_scan = 10;
	y_min_scan = 0;
	y_max_scan = 10;

	data_plot = 0;
	data_plot_rev = 0;
	data_filter = 0;
	data_filter_rev = 0;

	for(int k = 0; k < 7; k++)
	{
		ch_data[k] = 0;
	}




	is_tip_thread = false;
	is_scan_thr = false;
	is_get_current_z_thread = false;
    pulse_seq = false;

	is_aborted = false; //variable to stop execution in the middle of a line

	gate_state = false;
	gate_volt = 0;

	num_scan_ch = 1;
	is_scan_ch[0] = true;
	for(int i = 1; i < 8; i++)
	{
		is_scan_ch[i] = false;
	}
   // is_scan_ch[7] = true;//Always meaure counter

	num_selected_ch = 0;
    
    max_tip_velocity = 0.05;
    max_tip_accel = 0.2;
    
    scan_save_dir = "C:\\AFM\\scans";
    
    MySQL_host = "localhost";
    MySQL_login = "lab";
    MySQL_password = "NVc3nt3r";
    MySQL_dbase = "AFM";
    
    comment = "";
    currscan_fname = "current_scan.scan";
    currscan_pic = "current_scan.png";
    
    for(int i = 0; i < 8; i++)
	{
		scan_ch_label[i] = "";
	}
    
    scan_ch_label[0] = "Z Piezo";
    scan_ch_label[7] = "Counter";
    
    x_chan = "PXI1Slot3/ao0";
    y_chan = "PXI1Slot3/ao1";
    z_chan = "PXI1Slot3/ao2";
    z_fdbk_chan = "PXI1Slot3/ai0";
    extra_chan = "PXI1Slot3/ai";

    laser_x = 0;
    laser_y = 0;
    
    counter_val = 0;
    
    is_matlab_data = false;
    is_measuring_matlab = false;

	num_matlab_chan = 7;
	matlab_data = 0; // pointer; memory will be allocated
	/*for (int i = 0; i < num_matlab_chan; i++){
		matlab_data[i] = 0;
	}*/
}
scan::~scan()
{
	if(data_plot != 0)
	{
		for(int i = 0; i < nx_step; i++)
		{
			delete [] data_plot[i];
		}
		delete [] data_plot;
	}
	if(data_plot_rev != 0)
	{
		for(int i = 0; i < nx_step; i++)
		{
			delete [] data_plot_rev[i];
		}
		delete [] data_plot_rev;
	}
	if(data_filter != 0)
	{
		for(int i = 0; i < nx_step; i++)
		{
			delete [] data_filter[i];
		}
		delete [] data_filter;
	}
	if(data_filter_rev != 0)
	{
		for(int i = 0; i < nx_step; i++)
		{
			delete [] data_filter_rev[i];
		}
		delete [] data_filter_rev;
	}
	if(x_axis != 0)
	{
		delete [] x_axis;
	}
	if(y_axis != 0)
	{
		delete [] y_axis;
	}
	if (matlab_data != 0) 
	{
		delete[] matlab_data;
	}

	//Delete arrays for other scan channels (Ch1-Ch7)
	for(int k = 0; k < 7; k++)
	{
		if(ch_data[k] != 0)
		{
			for(int i = 0; i < nx_step; i++)
			{
				delete [] ch_data[k][i];
			}
			delete [] ch_data[k];

			for(int i = 0; i < nx_step; i++)
			{
				delete [] ch_data_rev[k][i];
			}
			delete [] ch_data_rev[k];
		}
        /*
        if(counter_data != 0)
        {
            for(int i = 0; i < nx_step; i++)
			{
				delete [] counter_data[i];
			}
			delete [] ch_data[k];

			for(int i = 0; i < nx_step; i++)
			{
				delete [] counter_data_rev[i];
			}
			delete [] counter_data_rev;
            
            
        }
         */
	}

}
double scan::plane_z(double x, double y)
{
	//If snap to plane is active, determine z value based on plane,
	//otherwise, use current z value

	double ret = 0;

	if(_planeInfo->is_plane_active == true)
	{
		ret = (_planeInfo->a)*x + (_planeInfo->b)*y + (_planeInfo->c) + _planeInfo->offset; //Negative sign for sign flip in feedback box
	}
	else
	{
		ret = _DAC->z_in_current;
	}


	return ret; 
}
void scan::get_laser_position()
{
    /*
    TaskHandle laser_pos;
    DAQmxCreateTask("",&laser_pos);
        
        DAQmxCreateAIVoltageChan(laser_pos,"PXI1Slot2/_ao0_vs_aognd","",DAQmx_Val_Diff ,-10,10,DAQmx_Val_Volts,NULL);
       
        DAQmxCreateAIVoltageChan(laser_pos,"PXI1Slot2/_ao1_vs_aognd","",DAQmx_Val_Diff ,-10,10,DAQmx_Val_Volts,NULL);

        
        DAQmxCfgSampClkTiming(laser_pos,"",10000,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,10000);
        
        float64 dat[20000];
        int32 read=0;
       
      DAQmxReadAnalogF64(laser_pos,10000,DAQmx_Val_WaitInfinitely,DAQmx_Val_GroupByChannel,dat,20000,&read,NULL);
       
    
      DAQmxStartTask(laser_pos);
    
        DAQmxWaitUntilTaskDone(laser_pos,DAQmx_Val_WaitInfinitely);
        
        DAQmxStopTask(laser_pos);
        DAQmxClearTask(laser_pos);
        
        double x_val = 0;
        double y_val = 0;

        for(int i = 0; i < 10000; i++)
        {
           x_val += dat[i]/(double)10000;
           y_val += dat[i+10000]/(double)10000;
        }
        */
    /*
        const mxArray* x_pos_mex_str_c;
        const mxArray* y_pos_mex_str_c;
       
        x_pos_mex_str_c = mexGet(laser_handle_x,"String");
        y_pos_mex_str_c = mexGet(laser_handle_y,"String");
        
        mxArray* x_pos_mex_str;
        mxArray* y_pos_mex_str;
        
        x_pos_mex_str = mxDuplicateArray(x_pos_mex_str_c);
        y_pos_mex_str = mxDuplicateArray(y_pos_mex_str_c);
        
        if(x_pos_mex_str == 0 || y_pos_mex_str == 0) MessageBox(0,"Null pointer",0,0);
        
        char x_str[100];
        char y_str[100];
        
        int x_err = mxGetString(x_pos_mex_str, x_str, 100);
        int y_err = mxGetString(y_pos_mex_str, y_str, 100);
        
        if(x_err == 1 || y_err == 1) MessageBox(0,"GetString Error",0,0);
            
        
        double laser_x_coord = atof(x_str);
        double laser_y_coord = atof(y_str);
        
        laser_x = laser_x_coord*((double)1/laser_x_cal);
        laser_y = laser_y_coord*((double)1/laser_y_cal);
       */
        laser_x_start = laser_x + ((x_max - x_min)/2)*MCL_x_cal/laser_x_cal;//10.000/58.0471;
        laser_y_start = laser_y - ((y_max - y_min)/2)*MCL_y_cal/laser_y_cal;//10.000/55.3411;
        
       //  mxDestroyArray(x_pos_mex_str);
       //  mxDestroyArray(y_pos_mex_str);
        
       // char disp[500];
       // sprintf_s(disp,500,"%f %f , %f %f", laser_x,laser_y,laser_x_start,laser_y_start);
     //   MessageBox(0,disp,0,0);
        
    return;
}
void scan::set_tracking(double x_center, double y_center)
{
    /*
    //Get the center of mass of the counter image to align the tip to an NV
    
    if(!is_scan_ch[7]) return; //Counter channel not measured
    
    int n = 5; //Weighting for the counts data (higher n gives more weight to bright points)
    //CM along x:
    
    double integral_x = 0;
    double integral_y = 0;
    double integral = 0;
    
    for(int i = 0; i < nx_step; i++)
    {
        for(int j = 0; j < ny_step; j++)
        {
            integral += pow(ch_data[6][i][j],n);
            integral_x += pow(ch_data[6][i][j],n)*x_axis[i];
            integral_y += pow(ch_data[6][i][j],n)*y_axis[j]; 
        }
    }
    
    double x_center = integral_x/integral;
    double y_center = integral_y/integral;
    
   // char disp[300];
   // sprintf_s(disp,300,"%f, %f",x_center,y_center);
   // MessageBox(0,disp,0,0);
   */
   
    
    
        double x_center_old = (x_max + x_min)/2;
   
        double _x_max = x_max + (x_center - x_center_old);
        double _x_min = x_min + (x_center - x_center_old);
        
        double y_center_old = (y_max + y_min)/2;
   
        double _y_max = y_max + (y_center - y_center_old);
        double _y_min = y_min + (y_center - y_center_old);
      
        //Move only if total motion is less than 200 nm
        if( sqrt((double)(x_center_old - x_center)*(x_center_old - x_center)+(double)(y_center_old - y_center)*(y_center_old - y_center)) <= 0.1)
        {
             //Set center and tip position to be new center coordinates
            WaitForSingleObject(set_tip_xy(x_center,y_center),100000);

            set(_x_min,_x_max,_y_min,_y_max,nx_step,ny_step,freq,theta);
        }
    
    
    
}
void scan::move_tip_laser(double dx, double dy,double x_l,double y_l)
{
   //Move the tip and the laser the same distance (dx,dy) in nm from the current position
    //x_l and y_l are the current laser position values in um from the ImageScan code

	// note MCL_x_cal and MCL_y_cal are the same currently mDAC('set_cal',..) does 10 microns/volt
    
	// added WaitForSingleObject around this on 11/13/15
	WaitForSingleObject( set_tip_xy(x_tip + (dx / (float)1000) / (MCL_x_cal), y_tip + (dy / (float)1000) / (MCL_y_cal)),100000 );
   
   laser_x = x_l*((double)1/(laser_x_cal)); //converting laser positions from microns to volts
   laser_y = y_l*((double)1/(laser_y_cal));
            
   // commented out for Micronix configuration. the nv sample does not scan
   //set_laser_position(laser_x - (dx/(float)1000)*((double)1/(laser_x_cal)),laser_y + (dy/(float)1000)*((double)1/(laser_y_cal)));
    

}
void scan::set_laser_position(double x_laser_pos,double y_laser_pos)
{
    TaskHandle scanxy;
	DAQmxCreateTask("",&scanxy);

    // commented out for micronix configuration make sure it doesn't scan laser.
    //DAQmxCreateAOVoltageChan(scanxy,"PXI1Slot2/ao0","",-10,10,DAQmx_Val_Volts,NULL);
    //DAQmxCreateAOVoltageChan(scanxy,"PXI1Slot2/ao1","",-10,10,DAQmx_Val_Volts,NULL);
    
    float64 out[4];
    out[0] = x_laser_pos;
    out[1] = y_laser_pos;
   
    out[2] = x_laser_pos;
    out[3] = y_laser_pos;
   
    DAQmxWriteAnalogF64(scanxy, 1, 1, 10, DAQmx_Val_GroupByChannel , out, NULL, NULL);
    DAQmxWaitUntilTaskDone(scanxy,DAQmx_Val_WaitInfinitely);

    DAQmxStopTask(scanxy);
    DAQmxClearTask(scanxy);
    
}
bool scan::scan_line_smooth(int line_num)
{
 
	//Move the tip smoothly to the start of the scan area
	//if(line_num == 0)
	{
		double x = x_min + ( (x_max - x_min) / (float64)(nx_step - 1) ) * (0 % nx_step) - x_center;
		double y = y_min + ( (y_max - y_min) / (float64)(ny_step - 1) ) * (line_num) - y_center;

		double _x = x*cos(theta) - y*sin(theta) + x_center;
		if(_x < x_min_scan) _x = x_min_scan;
		if(_x > x_max_scan) _x = x_max_scan;

		double _y = x*sin(theta) + y*cos(theta) + y_center;

		if(_y < y_min_scan) _y = y_min_scan;
		if(_y > y_max_scan) _y = y_max_scan;

		WaitForSingleObject(set_tip_xy(_x,_y),100000);
	}

	double x = x_min - x_center;
	double y = y_min + ( (y_max - y_min) / (float64)(ny_step - 1) ) * (line_num) - y_center;

	//Starting point
	double x0 = x*cos(theta) - y*sin(theta) + x_center;
	double y0 = x*sin(theta) + y*cos(theta) + y_center;

	x = x_max - x_center;

	//End point
	double x1 = x*cos(theta) - y*sin(theta) + x_center;
	double y1 = x*sin(theta) + y*cos(theta) + y_center;


	double r1 = sqrt((x1 - x0)*(x1 - x0)+(y1 - y0)*(y1 - y0));

	//Set the maximum velocity to be equal to the distance traveled divided by the time set by the scan speed

	double v0 = r1 / ((double)nx_step / (double)freq);

	if( v0 > max_tip_velocity) v0 = max_tip_velocity; //Make sure velocity is beneath limit

	double a0 = max_tip_accel; //maximum acceleration in volt/sec^2

	//double v0 = 0.5; //maximum velocity in volt/sec

	double t0 = 4*v0/a0; //t0 is set by the maximum acceleration and velocity

	//Compute the time the path is at the maximum velocity
	double tc = 4*(r1 - a0*t0*t0/8)/(a0*t0);

	if(tc < 0) //If the path  never reaches the set maximum velocity, eliminate constant velocity segment
	{
		tc = 0;
		t0 = sqrt(8*r1/a0);
	}
	
	//Length of output vector one way (1e5 Hz)

	//If scan rate is too slow, vector becomes very large. Below 10 Hz, reduce read rate.
	 
	int scan_rate = 1e5;
	
	if(freq <= 10) 
	{
		scan_rate = (int)( (double)(1e4)*(double)freq );
	}

	int n_pts = (int)((t0+tc)*scan_rate);

	//float64 * out = new float64[2*(n_pts + 1)];
	float64 * out = new float64[2*n_pts];

    if(!out) return 0;
    
	for(int i = 0; i < n_pts; i++)
	{
		out[i] = x0 + r((t0+tc)/(n_pts - 1)*i,a0,t0,tc)*cos(theta);
		if(out[i] < x_min_scan) out[i] = x_min_scan;
		if(out[i] > x_max_scan) out[i] = x_max_scan;

		out[i + n_pts] = y0 + r((t0+tc)/(n_pts - 1)*i,a0,t0,tc)*sin(theta);
		//out[i + n_pts + 1] = y0 + r((t0+tc)/(n_pts - 1)*i,a0,t0,tc)*sin(theta);
		//if(out[i + n_pts + 1] < y_min_scan) out[i + n_pts + 1] = y_min_scan;
		//if(out[i + n_pts + 1] > y_max_scan) out[i + n_pts + 1] = y_max_scan;
		if(out[i + n_pts] < y_min_scan) out[i + n_pts] = y_min_scan;
		if(out[i + n_pts] > y_max_scan) out[i + n_pts] = y_max_scan;
	}
    
  
	
	//out[n_pts] = out[n_pts - 1];
	//out[2*n_pts + 1] = out[2*n_pts];

	//int32  error; 
	DAQmxCreateTask("",&scant);
	DAQmxCreateTask("",&readv);
    	
	DAQmxCreateAOVoltageChan(scant,x_chan.c_str(),"",0,10,DAQmx_Val_Volts,NULL);
	DAQmxCreateAOVoltageChan(scant,y_chan.c_str(),"",0,10,DAQmx_Val_Volts,NULL);
	DAQmxCreateAOVoltageChan(scant,z_chan.c_str(),"",-10,10,DAQmx_Val_Volts,NULL);

	DAQmxCreateAIVoltageChan(readv,z_fdbk_chan.c_str(),"",DAQmx_Val_Diff ,-10,10,DAQmx_Val_Volts,NULL);
	//Add other channels if they are active
	for(int k = 1; k < 8; k++)
	{
		if(is_scan_ch[k])
		{
			char id[50];
			sprintf_s(id,50,"PXI1Slot3/ai%d",k);
			DAQmxCreateAIVoltageChan(readv,id,"",DAQmx_Val_Diff ,-10,10,DAQmx_Val_Volts,NULL);
		}
	}
    
    //Sample and output at set scan rate, adjust scan path to reflect set scan rate
	DAQmxCfgSampClkTiming(readv,"",scan_rate,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,2*(n_pts));
	DAQmxCfgSampClkTiming(scant,"",scan_rate,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,2*(n_pts));
    
    DAQmxCfgDigEdgeStartTrig (scant, "/PXI1Slot3/ai/SampleClock", DAQmx_Val_Rising);
    
    
    //Setup counter and pulse train to read counter
    int32 error = 0;
	
    //TaskHandle pulse_train;
    DAQmxCreateTask("",&pulse_train);
    
    DAQmxCreateCOPulseChanFreq(pulse_train,"/PXI1Slot2/ctr0","",DAQmx_Val_Hz,DAQmx_Val_Low,0,scan_rate,0.5);        
    DAQmxCfgImplicitTiming(pulse_train,DAQmx_Val_ContSamps,2*(n_pts));
    
   
   
   // TaskHandle counter_in;
    DAQmxCreateTask("",&counter_in);
    
    DAQmxCreateCICountEdgesChan(counter_in,"/PXI1Slot2/ctr2","",DAQmx_Val_Rising,0,DAQmx_Val_CountUp);        
    DAQmxSetCICountEdgesTerm(counter_in,"/PXI1Slot2/ctr2","/PXI1Slot2/PFI0");
        
    DAQmxCfgSampClkTiming(counter_in,"/PXI1Slot2/PFI12",scan_rate,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,2*(n_pts));
    DAQmxCfgDigEdgeStartTrig (pulse_train, "/PXI1Slot3/ai/SampleClock", DAQmx_Val_Rising);

    DAQmxStartTask(pulse_train);
    DAQmxStartTask(counter_in);
    
   
     DAQmxCreateTask("",&counter_in2);

    DAQmxCreateCICountEdgesChan(counter_in2,"/PXI1Slot3/ctr2","",DAQmx_Val_Rising,0,DAQmx_Val_CountUp); 
    DAQmxSetCICountEdgesTerm(counter_in2,"/PXI1Slot3/ctr2","/PXI1Slot3/20MHzTimebase");


    
    
    
    //Setup laser scan   
   
    DAQmxCreateTask("",&scan_laser);
       
    // commented two lines here for micronix configuration doesn't need laser scan
    //DAQmxCreateAOVoltageChan(scan_laser,"PXI1Slot2/ao0","",-5,5,DAQmx_Val_Volts,NULL);
    //DAQmxCreateAOVoltageChan(scan_laser,"PXI1Slot2/ao1","",-5,5,DAQmx_Val_Volts,NULL);
    
    DAQmxCfgSampClkTiming(scan_laser,"",scan_rate,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,2*(n_pts));
    DAQmxCfgDigEdgeStartTrig (scan_laser, "/PXI1Slot3/ai/SampleClock", DAQmx_Val_Rising);
    
    //Generate laser scan output voltages (scan rotation is not accounted for here)
    
    //Get current laser position
    

    float64 * out_laser = new float64[2*n_pts];
    if(!out_laser) return 0;
    
    for(int i = 0; i < n_pts; i++)
	{
		out_laser[i] = laser_x_start - (out[i] - out[0])*MCL_x_cal/laser_x_cal;
		//if(out[i] < x_min_scan) out[i] = x_min_scan;
		//if(out[i] > x_max_scan) out[i] = x_max_scan;

		out_laser[i + n_pts] = laser_y_start + ( (y_max - y_min) / (float64)(ny_step - 1) ) * (line_num)*MCL_y_cal/laser_y_cal + (out[i+n_pts] - out[n_pts])*MCL_y_cal/laser_y_cal;
		//out[i + n_pts + 1] = y0 + r((t0+tc)/(n_pts - 1)*i,a0,t0,tc)*sin(theta);
		//if(out[i + n_pts + 1] < y_min_scan) out[i + n_pts + 1] = y_min_scan;
		//if(out[i + n_pts + 1] > y_max_scan) out[i + n_pts + 1] = y_max_scan;
		//if(out[i + n_pts] < y_min_scan) out[i + n_pts] = y_min_scan;
		//if(out[i + n_pts] > y_max_scan) out[i + n_pts] = y_max_scan;
	}
    
    
    float64* out_laser_fb =  new float64[2*(2*(n_pts))];
    
    for(int i = 0; i < n_pts; i++)
	{
		out_laser_fb[i] = out_laser[i];
		out_laser_fb[2*n_pts-i-1] = out_laser[i];

		out_laser_fb[2*n_pts+i] = out_laser[n_pts+i];
		out_laser_fb[2*(2*n_pts)-i-1] = out_laser[n_pts+i];
	}
   
    //DAQmxConnectTerms("/Dev2/ai/StartTrigger","/Dev2/RTSI0",DAQmx_Val_DoNotInvertPolarity);

	//DAQmxCfgDigEdgeStartTrig(scant,"/Dev1/RTSI0",DAQmx_Val_Rising);
int32 sampsPerChanWritten_laser = 0;
	
    error = DAQmxWriteAnalogF64(scan_laser, 2*(n_pts), 0, DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByChannel , out_laser_fb, &sampsPerChanWritten_laser, NULL);
    DAQmxStartTask(scan_laser);
	
/*
	float64 * outfb = new float64[2*(2*n_pts)+ 2];

	for(int i = 0; i < n_pts; i++)
	{
		outfb[i] = out[i];
		outfb[2*n_pts - i -1] = out[i];
		outfb[2*n_pts+1+i] = out[n_pts+1+i];
		outfb[2*(2*n_pts)-i] = out[n_pts+1+i];
	}

	outfb[2*n_pts] = outfb[2*n_pts - 1];
	outfb[2*(2*n_pts) + 1] = outfb[2*(2*n_pts)];
	*/

	float64 * outfb = new float64[3*(2*(n_pts))];
    
   

	for(int i = 0; i < n_pts; i++)
	{
		outfb[i] = out[i];
		outfb[2*n_pts-i-1] = out[i];

		outfb[2*n_pts+i] = out[n_pts+i];
		outfb[2*(2*n_pts)-i-1] = out[n_pts+i];

		outfb[2*(2*n_pts)+i] = plane_z(out[i],out[n_pts+i])/_DAC->z_adder_calibration; 
		outfb[3*(2*n_pts)-i-1] = plane_z(out[i],out[n_pts+i])/_DAC->z_adder_calibration; 
	}


     //float64 * data = new float64[2*(n_pts + 1)*num_scan_ch];
	float64 * data = new float64[2*(n_pts)*num_scan_ch];
	
	
 DAQmxStartTask(counter_in2); 
	int32 sampsPerChanWritten = 0;
	int32 read = 0;

	//DAQmxWriteAnalogF64(scant, 2*(n_pts)+1, 0, DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByChannel , outfb, &sampsPerChanWritten, NULL);
	error = DAQmxWriteAnalogF64(scant, 2*(n_pts), 0, DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByChannel , outfb, &sampsPerChanWritten, NULL);
   /* if(error != 0)
    {
        char disp[500];
        DAQmxGetErrorString(error, disp, 500);
        MessageBox(0,disp,0,0);
    }
    */
	error = DAQmxStartTask(scant);

	
	//DAQmxReadAnalogF64(readv,2*(n_pts)+1,DAQmx_Val_WaitInfinitely,DAQmx_Val_GroupByChannel,data,(2*(n_pts)+1)*num_scan_ch,&read,NULL);
	error = DAQmxReadAnalogF64(readv,2*(n_pts),DAQmx_Val_WaitInfinitely,DAQmx_Val_GroupByChannel,data,(2*(n_pts))*num_scan_ch,&read,NULL);
   
    error = DAQmxStartTask(readv);
	
	DAQmxWaitUntilTaskDone(scant,DAQmx_Val_WaitInfinitely);

	
     DAQmxStopTask(scant);
     DAQmxClearTask(scant);

     DAQmxStopTask(readv);
     DAQmxClearTask(readv);
   
     DAQmxStopTask(scan_laser);
     DAQmxClearTask(scan_laser);
     

     // DAQmxTaskControl(counter_in2, DAQmx_Val_Task_Abort);
     DAQmxStopTask(counter_in2);
     DAQmxClearTask(counter_in2);

   
	//Read the data
  

	if(is_aborted)
	{
		is_aborted = false;
        
        
        
        
        double last_pos_d = (double)counter_val/(double)20e6*scan_rate;
        
        int last_pos = (int)last_pos_d;
        
        // char disp[300];
       // sprintf_s(disp,300,"%f",last_pos);
       // MessageBox(0,disp,0,0);
       /*
        
      
        
        TaskHandle read_tip;
        DAQmxCreateTask("",&read_tip);
        
        DAQmxCreateAIVoltageChan(read_tip,"PXI1Slot3/_ao0_vs_aognd","",DAQmx_Val_Diff ,-10,10,DAQmx_Val_Volts,NULL);
       
        DAQmxCreateAIVoltageChan(read_tip,"PXI1Slot3/_ao1_vs_aognd","",DAQmx_Val_Diff ,-10,10,DAQmx_Val_Volts,NULL);
        
        DAQmxCreateAIVoltageChan(read_tip,"PXI1Slot3/_ao2_vs_aognd","",DAQmx_Val_Diff ,-10,10,DAQmx_Val_Volts,NULL);
       
        
        DAQmxCfgSampClkTiming(read_tip,"",1000,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,1000);
        
        float64 dat[3000];
       
        DAQmxReadAnalogF64(read_tip,1000,DAQmx_Val_WaitInfinitely,DAQmx_Val_GroupByChannel,dat,3000,&read,NULL);
        
        DAQmxStartTask(read_tip);
        
        DAQmxWaitUntilTaskDone(read_tip,DAQmx_Val_WaitInfinitely);
        
        DAQmxStopTask(read_tip);
        DAQmxClearTask(read_tip);
        
        double x_val = 0;
        double y_val = 0;
        double z_val = 0;
        
        for(int i = 0; i < 1000; i++)
        {
           x_val += dat[i]/(double)1000;
           y_val += dat[i+1000]/(double)1000;
           z_val += dat[i+2000]/(double)1000;
        }
       
        x_tip = x_val;
        y_tip = y_val;
        _DAC->z_in_current = z_val*_DAC->z_adder_calibration;
     */
        /*

		//Set the current tip position correctly
        char disp[300];
        sprintf_s(disp,300,"%d",read);
        MessageBox(0,disp,0,0);
        */
        if(last_pos != 0 && last_pos <= (2*(n_pts)) )
		{
			x_tip = outfb[last_pos - 1];
			//y_tip = outfb[read + 2*n_pts];
			y_tip = outfb[last_pos - 1 + 2*n_pts];
			_DAC->z_in_current = outfb[last_pos - 1 + 2*(2*n_pts)]*_DAC->z_adder_calibration;
		}
        else if(last_pos >= (2*(n_pts)))
        {
            x_tip = outfb[2*(n_pts) - 1];
			//y_tip = outfb[read + 2*n_pts];
			y_tip = outfb[2*(n_pts) - 1 + 2*n_pts];
			_DAC->z_in_current = outfb[2*(n_pts) - 1 + 2*(2*n_pts)]*_DAC->z_adder_calibration;
            
        }
         
        
         DAQmxStopTask(pulse_train);
        DAQmxClearTask(pulse_train);
         DAQmxStopTask(counter_in);
         DAQmxClearTask(counter_in);
         
          //DAQmxStopTask(pulse_train2);
       // DAQmxClearTask(pulse_train2);
       //  DAQmxStopTask(counter_in2);
       //  DAQmxClearTask(counter_in2);

		delete [] data;
		delete [] out;

		delete [] outfb;
        
        delete [] out_laser;
        delete [] out_laser_fb;

		return 0;
	}
     
          
       uInt32* BufferData = new uInt32[2*(n_pts)];
       float* BufferData_diff = new float[2*(n_pts)];
      int32 samps_read;
      error = DAQmxReadCounterU32(counter_in,2*(n_pts),DAQmx_Val_WaitInfinitely,BufferData,2*(n_pts),&samps_read,NULL);
      if(error != 0)
    {
        char disp[500];
        DAQmxGetErrorString(error, disp, 500);
        MessageBox(0,disp,0,0);
    }
      BufferData_diff[0] = 0;
      for(int i = 1; i < 2*(n_pts); i++)
      {
          BufferData_diff[i] = (BufferData[i] - BufferData[i-1])*(float)scan_rate;
          
      }
      //char disp[300];
     //sprintf_s(disp,300,"%d, %d, %f",samps_read,2*(n_pts),BufferData_diff[1000]);
     // MessageBox(0,disp,0,0);
      
      DAQmxStopTask(pulse_train);
     DAQmxClearTask(pulse_train);
     DAQmxStopTask(counter_in);
     DAQmxClearTask(counter_in);
       

	int* data_count = new int[2*nx_step*num_scan_ch];

	for(int i = 0; i < nx_step; i++)
	{
		data_plot[i][line_num] = 0;
		data_plot_rev[i][line_num] = 0;
		//data_count[i] = 0;
		//data_count[i + nx_step] = 0;

	}
	for(int i = 0; i < 2*nx_step*num_scan_ch; i++)
	{
		data_count[i] = 0;
	}
	
	for(int i = 0; i < n_pts; i++)
	{
		//For each measured (x,y) point, find the closest (x,y) point in the data set

		//Figure out what (x,y) point data_plot[j][line_num] corresponds to

		//int j = (int)( (outfb[i] - x0)/(x1 - x0)*nx_step - 0.5);
		//int j = (int)( (sqrt( (outfb[i+1] - x0)*(outfb[i+1] - x0) + (outfb[ i + 2*n_pts + 2] - y0)*(outfb[ i + 2*n_pts + 2] - y0) )/r1 )*nx_step - 0.5   );
		int j = (int)( (sqrt( (outfb[i] - x0)*(outfb[i] - x0) + (outfb[ i + 2*n_pts] - y0)*(outfb[ i + 2*n_pts] - y0) )/r1 )*nx_step - 0.5   );
		
		if( !( j < 0 || j > nx_step - 1) )
		{
			//data_plot[j][line_num] += data[i+1];
			data_plot[j][line_num] += data[i];
			//count how many points are added together
			data_count[j]++;

			//Do the same for the other active channels
			int cum_chan = 1;
			for(int q = 0; q < 7; q++)
			{
				if(is_scan_ch[q+1])
				{
                    if(q==6)
                    {
                        ch_data[q][j][line_num] += BufferData_diff[i];  
                    }
                    else
                    {
                        	//ch_data[q][j][line_num] += data[i+1+(cum_chan)*2*n_pts];
					ch_data[q][j][line_num] += data[i+(cum_chan)*2*n_pts];
					//data_count[j+nx_step*(cum_chan)*2]++;
                        
                    }
                    data_count[j+nx_step*(cum_chan)*2]++;
				
					cum_chan++;
				}
			}
             
		}

		//int k = (int)( (sqrt( (outfb[i+n_pts+1] - x0)*(outfb[i+n_pts+1] - x0) + (outfb[ i + 3*n_pts + 2] - y0)*(outfb[ i + 3*n_pts + 2] - y0) )/r1 )*nx_step - 0.5   );
		int k = (int)( (sqrt( (outfb[i+n_pts] - x0)*(outfb[i+n_pts] - x0) + (outfb[ i + 3*n_pts] - y0)*(outfb[ i + 3*n_pts] - y0) )/r1 )*nx_step - 0.5   );
		
		//int k = (int)( (outfb[i+n_pts+1] - x0)/(x1 - x0)*nx_step - 0.5);
		if( !( k < 0 || k > nx_step - 1) )
		{
			//data_plot_rev[k][line_num] += data[i+n_pts+1];
			data_plot_rev[k][line_num] += data[i+n_pts];
			data_count[k + nx_step]++;

			int cum_chan = 1;
			for(int q = 0; q < 7; q++)
			{
				if(is_scan_ch[q+1])
				{
                    if(q==6)
                    {
                        ch_data_rev[q][k][line_num] += BufferData_diff[i+n_pts];
                    }
                    else
                    {
                        //ch_data_rev[q][k][line_num] += data[i+1+(cum_chan)*2*n_pts+n_pts];
                        ch_data_rev[q][k][line_num] += data[i+(cum_chan)*2*n_pts+n_pts];
                       
                    }
                     data_count[k+nx_step*(cum_chan)*2+nx_step]++;
					cum_chan++;
				}
			}
            
		}

	}
	for(int i = 0; i < nx_step; i++)
	{

		if(data_count[i] != 0)
		{
			data_plot[i][line_num] = data_plot[i][line_num]/(double)data_count[i];
		}
		else
		{
			data_plot[i][line_num] = 0;
		}

		if(data_count[i+nx_step] != 0)
		{
			data_plot_rev[i][line_num] = data_plot_rev[i][line_num]/(double)data_count[i + nx_step];
		}
		else
		{
			data_plot_rev[i][line_num] = 0;
		}

		int cum_chan = 1;
		for(int q = 0; q < 7; q++)
		{
			if(is_scan_ch[q+1])
			{
				if(data_count[i+nx_step*(cum_chan)*2] != 0)
				{
					ch_data[q][i][line_num] = ch_data[q][i][line_num]/(double)data_count[i+nx_step*(cum_chan)*2];
				}
				else
				{
					ch_data[q][i][line_num] = 0;
				}

				if(data_count[i+nx_step*(cum_chan)*2+nx_step] != 0)
				{
					ch_data_rev[q][i][line_num] = ch_data_rev[q][i][line_num]/(double)data_count[i+nx_step*(cum_chan)*2+nx_step];
				}
				else
				{
					ch_data_rev[q][i][line_num] = 0;
				}
				cum_chan++;
			}
		}
	}

	
	//Subtract plane from data in data_filter

	filter(data_plot,data_filter,line_num);
	filter(data_plot_rev,data_filter_rev,line_num);

	min_max[0] = data_plot[0][0];
	min_max[1] = data_plot[0][0];

	min_max[2] = data_filter[0][0];
	min_max[3] = data_filter[0][0];

	min_max[4] = data_plot_rev[0][0];
	min_max[5] = data_plot_rev[0][0];

	min_max[6] = data_filter_rev[0][0];
	min_max[7] = data_filter_rev[0][0];

	bool is_set = false;
	
	for(int i = 0; i < nx_step; i++)
	{
		for(int j = 0; j <= line_num; j++)
		{
			double x = (x_axis[i] - (x_min+x_max)/2)*cos(theta*3.14159/180)-(y_axis[j] - (y_min+y_max)/2)*sin(theta*3.14159/180)+(x_min+x_max)/2;
			double y = (x_axis[i] - (x_min+x_max)/2)*sin(theta*3.14159/180)+(y_axis[j] - (y_min+y_max)/2)*cos(theta*3.14159/180)+(y_min+y_max)/2;

			if(x < x_min_scan || x > x_max_scan || y < y_min_scan || y > y_max_scan) continue;
			if(!is_set)
			{
				min_max[0] = data_plot[i][j];
				min_max[1] = data_plot[i][j];

				min_max[2] = data_filter[i][j];
				min_max[3] = data_filter[i][j];

				min_max[4] = data_plot_rev[i][j];
				min_max[5] = data_plot_rev[i][j];

				min_max[6] = data_filter_rev[i][j];
				min_max[7] = data_filter_rev[i][j];

				for(int q = 0; q < 7; q++)
				{
					if(is_scan_ch[q+1])
					{
						ch_min_max[2*q] = ch_data[q][i][j];
						ch_min_max[2*q+1] = ch_data[q][i][j];

						ch_min_max[2*q+14] = ch_data_rev[q][i][j];
						ch_min_max[2*q+15] = ch_data_rev[q][i][j];
					}
				}

				is_set = true;
			}
			else
			{

				if(data_plot[i][j] < min_max[0]) min_max[0] = data_plot[i][j];
				if(data_plot[i][j] > min_max[1]) min_max[1] = data_plot[i][j];

				if(data_filter[i][j] < min_max[2]) min_max[2] = data_filter[i][j];
				if(data_filter[i][j] > min_max[3]) min_max[3] = data_filter[i][j];

				if(data_plot_rev[i][j] < min_max[4]) min_max[4] = data_plot_rev[i][j];
				if(data_plot_rev[i][j] > min_max[5]) min_max[5] = data_plot_rev[i][j];

				if(data_filter_rev[i][j] < min_max[6]) min_max[6] = data_filter_rev[i][j];
				if(data_filter_rev[i][j] > min_max[7]) min_max[7] = data_filter_rev[i][j];

				for(int q = 0; q < 7; q++)
				{
					if(is_scan_ch[q+1])
					{
						if(ch_data[q][i][j] < ch_min_max[2*q]) ch_min_max[2*q] = ch_data[q][i][j];
						if(ch_data[q][i][j] > ch_min_max[2*q+1]) ch_min_max[2*q+1] = ch_data[q][i][j];
						
						if(ch_data_rev[q][i][j] < ch_min_max[2*q+14]) ch_min_max[2*q+14] = ch_data_rev[q][i][j];
						if(ch_data_rev[q][i][j] > ch_min_max[2*q+15]) ch_min_max[2*q+15] = ch_data_rev[q][i][j];
					}
				}

			}
		}
	}
	
	
	
	
	x_tip = outfb[2*n_pts - 1];
	y_tip = outfb[2*(2*n_pts) - 1];
	_DAC->z_in_current = outfb[3*(2*n_pts) - 1]*_DAC->z_adder_calibration;
    
    //update z_min and z_max
    if(num_selected_ch > 0 && num_selected_ch < 8)
    {
       z_min = &ch_min_max[ (num_selected_ch - 1)*2 ];
       z_max = &ch_min_max[ (num_selected_ch - 1)*2 + 1]; 
        
    }
    
   

	
	delete [] data;
	delete [] out;

	delete [] outfb;
	delete [] data_count;
    
    delete [] out_laser;
    delete [] out_laser_fb;

    delete [] BufferData;
    delete [] BufferData_diff;
	
	return 1;
}

bool scan::scan_line_sequence(int line_num, std::string fn)
{
    //Move the tip discretely to each point in the scan line, then run a MATLAB function and save the return value of the function
    
	//if(line_num == 0)
    //Move the tip smoothly to the start of the scan area
	{

		// for theta=0 this just sets x = xmin and tip will move to xmin of the scan area
		double x = x_min + ( (x_max - x_min) / (float64)(nx_step - 1) ) * (0 % nx_step) - x_center;
		double y = y_min + ( (y_max - y_min) / (float64)(ny_step - 1) ) * (line_num) - y_center;

		double _x = x*cos(theta) - y*sin(theta) + x_center;
		if(_x < x_min_scan) _x = x_min_scan;
		if(_x > x_max_scan) _x = x_max_scan;

		double _y = x*sin(theta) + y*cos(theta) + y_center;

		if(_y < y_min_scan) _y = y_min_scan;
		if(_y > y_max_scan) _y = y_max_scan;

		WaitForSingleObject(set_tip_xy(_x,_y),100000);
	}
    
    //Generate a list of xyz points to scan the tip
    double x = x_min - x_center;
	double y = y_min + ( (y_max - y_min) / (float64)(ny_step - 1) ) * (line_num) - y_center;

	//Starting point
	double x0 = x*cos(theta) - y*sin(theta) + x_center;
	double y0 = x*sin(theta) + y*cos(theta) + y_center;

	x = x_max - x_center;

	//End point
	double x1 = x*cos(theta) - y*sin(theta) + x_center;
	double y1 = x*sin(theta) + y*cos(theta) + y_center;
    
    double * x_out = new double[2*nx_step];
    double * y_out = new double[2*nx_step];
    double * z_out = new double[2*nx_step];
    
	

	// made this a two-dimensional array to account for more channels of pulse data
	/*double** data_f; 
	double** data_r;

	data_f = new double * [nx_step];
	data_r = new double * [nx_step];

	for (int i = 0; i < num_matlab_chan; i++)
	{
		data_f[i] = new double [num_matlab_chan];
		data_r[i] = new double [num_matlab_chan];
	}*/
	double * data_f = new double[nx_step*num_matlab_chan];
	double * data_r = new double[nx_step*num_matlab_chan];


    for(int i = 0; i < nx_step; i++)
    {
        x_out[i] = x0 + ( (x1 - x0) / (float64)(nx_step - 1) ) * i;
        y_out[i] = y0 + ( (y1 - y0) / (float64)(nx_step - 1) ) * i;
        z_out[i] = plane_z(x_out[i],y_out[i])/_DAC->z_adder_calibration;
       
        x_out[2*nx_step-1-i] = x_out[i];
        y_out[2*nx_step-1-i] = y_out[i];
        z_out[2*nx_step-1-i] = z_out[i];
        
		for (int d = 0; d < num_matlab_chan; d++)
		{
			/*data_f[i][d] = 0;
			data_r[i][d] = 0;*/
			data_f[d*nx_step + i];
			data_r[d*nx_step + i];
		}
    }
    
    //laser positioning is not necessary for the inverted AFM setup (2015)
    
    double * out_laser_x = new double[2*nx_step];
    double * out_laser_y = new double[2*nx_step];
    
    for(int i = 0; i < nx_step; i++)
	{
		out_laser_x[i] = laser_x_start - (x_out[i] - x_out[0])*MCL_x_cal/laser_x_cal;
		out_laser_y[i] = laser_y_start + ( (y_max - y_min) / (float64)(ny_step - 1) ) * (line_num)*MCL_y_cal/laser_y_cal + (y_out[i] - y_out[0])*MCL_y_cal/laser_y_cal;
		
        out_laser_x[2*nx_step-1-i] = out_laser_x[i];
        out_laser_y[2*nx_step-1-i] = out_laser_y[i];
	}
    
    int last_pos = 0;

    
	double* val = new double[num_matlab_chan];
    for(int j = 0; j < 2*nx_step; j++)
    {
        //Move to x-y tip position
        WaitForSingleObject(set_tip_xy(x_out[j],y_out[j]),100000);
        
        //Move to z tip position
       // _DAC->z_in(z_out[j]);
        
        //Set laser position
        // commented out for Micronix configuration
        //set_laser_position(out_laser_x[j],out_laser_y[j]);
        
      
        //Run MATLAB function  
        is_measuring_matlab = true;
        is_matlab_data = false;
       
        
        // ---wait while matlab does its pulse sequence, as flagged by is_measuring_matlab
        while(!is_matlab_data)
        {
            Sleep(50);   
        }
        // -----finished (mDAC call), retrieved data----
		
        is_measuring_matlab = false;
        

		for (int d = 0; d < num_matlab_chan; d++) {
			val[d]= matlab_data[d];
		}

        // store data in the forward or reverse scan array
        if(j < nx_step)
        {
			for (int d = 0; d < num_matlab_chan; d++){
				//data_f[j][d] = val[d];
				data_f[d*nx_step + j] = val[d];
			}
        }
        else if(j >= nx_step)
        {
			for (int d = 0; d < num_matlab_chan; d++){
				//data_r[nx_step - 1 - (j - nx_step)][d] = val[d];
				data_r[d*nx_step + nx_step - 1 - (j - nx_step)] = val[d];
			}
        }  
        
        if(is_aborted) //Stop the data taking if the scan has been halted 
        {
           last_pos = j; 
           break; 
        }
    }
	
    is_measuring_matlab = false;
    
    if(is_aborted)
    {  
        is_aborted = false;
 
        x_tip = x_out[last_pos];
        y_tip = y_out[last_pos];
       // _DAC->z_in_current = z_out[last_pos-1]*_DAC->z_adder_calibration;

        delete [] x_out;
        delete [] y_out;
        delete [] z_out;
        
        delete [] out_laser_x;
        delete [] out_laser_y;

		// delete two-dimensional array
		/*for (int i = 0; i < nx_step; i++)
		{
			delete[] data_f[i];
			delete[] data_r[i];
		}*/
		delete[] data_f;
		delete[] data_r;

		delete[] val;
		//delete[] matlab_data; // don't delete this here actually

        return 0;
 
    }
    
    //Put data back into display buffers (Ch7 for counts)
	//is_scan_ch[0]=z height, but ch_data excludes z height, so ch_data[0] is "1", ch_data[6] is "7" counter
	// count backwards, 7,6,5,4... for the data channels, since ch7 was already the default counter channel
    int qstart = 6; 
	for (int d = 0; d < num_matlab_chan; d++) 
	{
		int q = qstart - d;
		if(is_scan_ch[q+1])
		{
			for(int i = 0; i < nx_step; i++)
			{
				//ch_data[q][i][line_num] = data_f[i][d];

				//ch_data_rev[q][i][line_num] = data_r[i][d];
				ch_data[q][i][line_num] = data_f[d*nx_step+i];

				ch_data_rev[q][i][line_num] = data_r[d*nx_step+i];   
			}
       
		}
	}

    //Update min/max
    bool is_set = false;
	
	for(int i = 0; i < nx_step; i++)
	{
		for(int j = 0; j <= line_num; j++)
		{
			double x = (x_axis[i] - (x_min+x_max)/2)*cos(theta*3.14159/180)-(y_axis[j] - (y_min+y_max)/2)*sin(theta*3.14159/180)+(x_min+x_max)/2;
			double y = (x_axis[i] - (x_min+x_max)/2)*sin(theta*3.14159/180)+(y_axis[j] - (y_min+y_max)/2)*cos(theta*3.14159/180)+(y_min+y_max)/2;

			if(x < x_min_scan || x > x_max_scan || y < y_min_scan || y > y_max_scan) continue;
			if(!is_set)
			{

				for(int d = 0; d < num_matlab_chan; d++)
				{
					int q = qstart - d;
					if(is_scan_ch[q+1])
					{
						ch_min_max[2*q] = ch_data[q][i][j];
						ch_min_max[2*q+1] = ch_data[q][i][j];

						ch_min_max[2*q+14] = ch_data_rev[q][i][j];
						ch_min_max[2*q+15] = ch_data_rev[q][i][j];
					}
				}

				is_set = true;
			}
			else
			{

				for (int d = 0; d < num_matlab_chan; d++)
				{
					int q = qstart - d;
					if(is_scan_ch[q+1])
					{
						if(ch_data[q][i][j] < ch_min_max[2*q]) ch_min_max[2*q] = ch_data[q][i][j];
						if(ch_data[q][i][j] > ch_min_max[2*q+1]) ch_min_max[2*q+1] = ch_data[q][i][j];
						
						if(ch_data_rev[q][i][j] < ch_min_max[2*q+14]) ch_min_max[2*q+14] = ch_data_rev[q][i][j];
						if(ch_data_rev[q][i][j] > ch_min_max[2*q+15]) ch_min_max[2*q+15] = ch_data_rev[q][i][j];
					}
				}

			}
		}
	}
    
    x_tip = x_out[2*nx_step-1];
	y_tip = y_out[2*nx_step-1];
	//_DAC->z_in_current = z_out[2*nx_step-1]*_DAC->z_adder_calibration;
    
    delete [] x_out;
    delete [] y_out;
    delete [] z_out;
    
    delete [] out_laser_x;
    delete [] out_laser_y;
    
	// delete two-dimensional array
	/*for (int i = 0; i < nx_step; i++)
	{
		delete[] data_f[i];
		delete[] data_r[i];
	}*/
	delete[] data_f;
	delete[] data_r;
	delete[] val;
	//delete[] matlab_data;
   
 
    return 1;   
}
void scan::filter(float64 ** raw_data,float64 ** filtered_data, int line_num)
{
	//If only one line, subtract off line
	if(line_num == 0)
	{
	
		double filter_min = raw_data[0][line_num];
		double filter_max = raw_data[nx_step - 1][line_num];
		std::vector<double> plane_fit_vector;
		double plane[4];

		for(int i = 0; i < nx_step; i++)
		{
			double x = x_min + ( (x_max - x_min) / (float64)(nx_step - 1) ) * (i % nx_step) - x_center;
			double y = y_min + ( (y_max - y_min) / (float64)(ny_step - 1) ) * (line_num) - y_center;
			double xr = x*cos(theta) - y*sin(theta) + x_center;
			double yr = x*sin(theta) + y*cos(theta) + y_center;

			if(!(xr < x_min_scan || xr > x_max_scan || yr < y_min_scan || yr > y_max_scan))
			{
				plane_fit_vector.push_back(i);
				plane_fit_vector.push_back(0);
				plane_fit_vector.push_back(raw_data[i][line_num]);

				plane_fit_vector.push_back(i);
				plane_fit_vector.push_back(1);
				plane_fit_vector.push_back(raw_data[i][line_num]);
			}

		}

		double* plane_fit = new double[plane_fit_vector.size()];

		for(unsigned int i = 0; i < plane_fit_vector.size(); i++)
		{	
			plane_fit[i] = plane_fit_vector[i];
		}

		getBestFitPlane(plane_fit_vector.size()/3,plane_fit,3*sizeof(double),0,0,plane);

		for(int i = 0; i < nx_step; i++)
		{
			double x = x_min + ( (x_max - x_min) / (float64)(nx_step - 1) ) * (i % nx_step) - x_center;
			double y = y_min + ( (y_max - y_min) / (float64)(ny_step - 1) ) * (line_num) - y_center;
			double xr = x*cos(theta) - y*sin(theta) + x_center;
			double yr = x*sin(theta) + y*cos(theta) + y_center;

			if(!(xr < x_min_scan || xr > x_max_scan || yr < y_min_scan || yr > y_max_scan))
			{
				filtered_data[i][line_num] = raw_data[i][line_num] - (-plane[3] - plane[0]*i)/(plane[2]);
			}
				
		}

		delete [] plane_fit;

	}
	else
	{

		double plane[4];
		//Put data in correct format for plane fitting
		std::vector<double> plane_fit_vector;

		for(int i = 0; i < nx_step; i++)
		{
			for(int j = 0; j <= line_num; j++)
			{
				double x = x_min + ( (x_max - x_min) / (float64)(nx_step - 1) ) * (i % nx_step) - x_center;
				double y = y_min + ( (y_max - y_min) / (float64)(ny_step - 1) ) * (j) - y_center;
				double xr = x*cos(theta) - y*sin(theta) + x_center;
				double yr = x*sin(theta) + y*cos(theta) + y_center;

				if(!(xr < x_min_scan || xr > x_max_scan || yr < y_min_scan || yr > y_max_scan))
				{
					plane_fit_vector.push_back(i);
					plane_fit_vector.push_back(j);
					plane_fit_vector.push_back(raw_data[i][j]);
				}
			}
		}

		double* plane_fit = new double[plane_fit_vector.size()];

		for(unsigned int i = 0; i < plane_fit_vector.size(); i++)
		{	
			plane_fit[i] = plane_fit_vector[i];
		}

		getBestFitPlane(plane_fit_vector.size()/3,plane_fit,3*sizeof(double),0,0,plane);

		
		for(int i = 0; i < nx_step; i++)
		{
			for(int j = 0; j <= line_num; j++)
			{
				double x = x_min + ( (x_max - x_min) / (float64)(nx_step - 1) ) * (i % nx_step) - x_center;
				double y = y_min + ( (y_max - y_min) / (float64)(ny_step - 1) ) * (j) - y_center;
				double xr = x*cos(theta) - y*sin(theta) + x_center;
				double yr = x*sin(theta) + y*cos(theta) + y_center;

				if(!(xr < x_min_scan || xr > x_max_scan || yr < y_min_scan || yr > y_max_scan))
				{
					filtered_data[i][j] = raw_data[i][j] - (-plane[3] - plane[0]*i - plane[1]*j)/(plane[2]);
				}
				
				
			}
		}

		delete [] plane_fit;

	}


}
void scan::stop_scan()
{
     //uInt32 val = 0;
     DAQmxReadCounterScalarU32(counter_in2, 0, &counter_val, NULL);
    
   // char disp[300];
    //    sprintf_s(disp,300,"%d",val);
    //    MessageBox(0,disp,0,0);
        
	DAQmxTaskControl(scant, DAQmx_Val_Task_Abort);
	DAQmxTaskControl(readv, DAQmx_Val_Task_Abort);
    DAQmxTaskControl(scan_laser, DAQmx_Val_Task_Abort);
    DAQmxTaskControl(pulse_train, DAQmx_Val_Task_Abort);
    DAQmxTaskControl(counter_in, DAQmx_Val_Task_Abort);
   // DAQmxTaskControl(pulse_train2, DAQmx_Val_Task_Abort);
    DAQmxTaskControl(counter_in2, DAQmx_Val_Task_Abort);
	
   
    
    DAQmxStopTask(scant);
    DAQmxStopTask(readv);
    
	DAQmxClearTask(scant);
	DAQmxClearTask(readv);
    
     DAQmxStopTask(scan_laser);
     DAQmxClearTask(scan_laser);
     
    DAQmxStopTask(pulse_train);
	DAQmxClearTask(pulse_train);
    
    DAQmxStopTask(counter_in);
	DAQmxClearTask(counter_in);
    
    DAQmxStopTask(counter_in2);
    DAQmxClearTask(counter_in2);
    
   // DAQmxStopTask(pulse_train2);
   // DAQmxClearTask(pulse_train2);
    
   
    
   // DAQmxStopTask(pulse_train2);
	//DAQmxClearTask(pulse_train2);
    
   // DAQmxStopTask(counter_in2);
	//DAQmxClearTask(counter_in2);
   // DAQmxWaitUntilTaskDone(scant,DAQmx_Val_WaitInfinitely);

}
void scan::set(double _x_min, double _x_max, double _y_min, double _y_max, int _nx_step, int _ny_step, double _freq, double _theta)
{
	if(data_plot != 0)
	{
		for(int i = 0; i < nx_step; i++)
		{
			delete [] data_plot[i];
		}
		delete [] data_plot;
	}
	if(data_plot_rev != 0)
	{
		for(int i = 0; i < nx_step; i++)
		{
			delete [] data_plot_rev[i];
		}
		delete [] data_plot_rev;
	}
	if(data_filter != 0)
	{
		for(int i = 0; i < nx_step; i++)
		{
			delete [] data_filter[i];
		}
		delete [] data_filter;
	}
	if(data_filter_rev != 0)
	{
		for(int i = 0; i < nx_step; i++)
		{
			delete [] data_filter_rev[i];
		}
		delete [] data_filter_rev;
	}
	//delete arrays for the data collected by the pulse sequence
	if (matlab_data != 0) // check if it is not a null pointer
	{
		delete[] matlab_data;
	}
	

	//Delete arrays for other scan channels (Ch1-Ch7)
	for(int k = 0; k < 7; k++)
	{
		if(ch_data[k] != 0)
		{
			for(int i = 0; i < nx_step; i++)
			{
				delete [] ch_data[k][i];
			}
			delete [] ch_data[k];
            

			for(int i = 0; i < nx_step; i++)
			{
				delete [] ch_data_rev[k][i];
			}
			delete [] ch_data_rev[k];
            
		}
	}

	


	x_min = _x_min;
	x_max = _x_max;
	y_min = _y_min;
	y_max = _y_max;
	x_center = (x_max + x_min)/2;
	y_center = (y_max + y_min)/2;

	nx_step = _nx_step;

	ny_step = _ny_step;

	freq = _freq;

	theta = _theta*pi/180;

	
	//Allocate arrays for topography data (Ch0)
	data_plot = new double * [nx_step];
	data_plot_rev = new double * [nx_step];
	

	for(int i = 0; i < nx_step; i++)
	{	
		data_plot[i] = new double [ny_step];
		data_plot_rev[i] = new double [ny_step];
	}
	
	
	
	for(int i = 0; i < nx_step; i++)
	{
		for(int j = 0; j < ny_step; j++)
		{
			data_plot[i][j] = 0;
			data_plot_rev[i][j] = 0;

		}

	}
	
	data_filter = new double * [nx_step];
	data_filter_rev = new double * [nx_step];
	
	for(int i = 0; i < nx_step; i++)
	{	
		data_filter[i] = new double [ny_step];
		data_filter_rev[i] = new double [ny_step];
	}
	
	for(int j = 0; j < ny_step; j++)
	{
		for(int i = 0; i < nx_step; i++)
		{
			data_filter[i][j] = 0;
			data_filter_rev[i][j] = 0;
		}


	}
	//allocate arrays for the data collected by the pulse sequence
	matlab_data = new double[num_matlab_chan];

	//Allocate arrays for other scan channels (Ch1-Ch7)
	for(int k = 0; k < 7; k++)
	{
		if(is_scan_ch[k+1])
		{
			ch_data[k] = new double * [nx_step];
			ch_data_rev[k] = new double * [nx_step];

			for(int i = 0; i < nx_step; i++)
			{	
				ch_data[k][i] = new double [ny_step];
				ch_data_rev[k][i] = new double [ny_step];
			}
			
			for(int i = 0; i < nx_step; i++)
			{
				for(int j = 0; j < ny_step; j++)
				{
					ch_data[k][i][j] = 0;
					ch_data_rev[k][i][j] = 0;
				}
			}
		}
		else
		{
			ch_data[k] = 0;
		}
	}

	if(x_axis != 0)
	{
		delete [] x_axis;
	}

	

	x_axis = new double [nx_step];
	for(int i = 0; i < nx_step; i++)
	{
		x_axis[i] = x_min + (x_max - x_min)/(float)(nx_step - 1)*i;
	}

	if(y_axis != 0)
	{
		delete [] y_axis;
	}

	y_axis = new double [ny_step];
	for(int i = 0; i < ny_step; i++)
	{		
		y_axis[i] = y_min + (y_max - y_min)/(float)(ny_step - 1)*i;
	}

	disp_data = data_filter;

	for(int i = 0; i < 8; i++)
	{
		min_max[i] = 0;
	}
    
    for(int i = 0; i < 28; i++)
	{
		ch_min_max[i] = 0;
	}


}
double r(double t, double a0, double t0, double tc)
{
	double ret = 0;

	if(t < t0/4)
	{
		ret = 2*a0/(3*t0)*t*t*t;
	}
	else if(t >= t0/4 && t < t0/2)
	{
		ret = a0*t0*t0/48 - (a0*t0/4)*t + a0*t*t - 2*a0/(3*t0)*t*t*t;
	}
	else if(t >= t0/2 && t < t0/2 + tc)
	{
		ret = a0*t0*t0/16 + a0*t0/4*(t-t0/2);
	}
	else if(t >= t0/2 + tc && t <= 3*t0/4 + tc)
	{
		ret = a0*t0*t0/48 - (a0*t0/4)*(t - tc) + a0*(t - tc)*(t - tc) - 2*a0/(3*t0)*(t - tc)*(t - tc)*(t - tc) + a0*t0/4*tc;

	}
	else if(t >= 3*t0/4 + tc)
	{
		ret = -13*a0*t0*t0/24 + 2*a0*t0*(t - tc) - 2*a0*(t - tc)*(t - tc) + 2*a0/(3*t0)*(t - tc)*(t - tc)*(t - tc) + a0*t0/4*tc;
	}

	return ret;
}

bool set_tip_xy_thread(scan* scan_ptr)
{
/*
	//If snap to plane is on, move z smoothly to plane value
	if(!scan_ptr->_DAC->is_z_in_thr)
	{
		if( abs((double)(scan_ptr->plane_z(scan_ptr->x_tip,scan_ptr->y_tip) - scan_ptr->_DAC->z_in_current)) > 1e-2)
		{

			scan_ptr->_DAC->z_in(-scan_ptr->plane_z(scan_ptr->x_tip,scan_ptr->y_tip));
			WaitForSingleObject(scan_ptr->_DAC->z_in_thr,INFINITE);
		}
	}
	*/
   
		
	top:

	//int length = scan_ptr->tip_position_vector.size();

	//if(length == 0) return 0;

	double x = scan_ptr->tip_x;
	double y = scan_ptr->tip_y;
	double x_tip = scan_ptr->x_tip;
	double y_tip = scan_ptr->y_tip;
	
	//scan_ptr->tip_position_vector.erase(scan_ptr->tip_position_vector.begin(),scan_ptr->tip_position_vector.begin()+length);
	/*
	Move from current tip position to the set position with a smooth acceleration (no jumps)
	
	Choose a path with the following acceleration:

	a(t) = { (4a0/t0)*t, t < t0/4
	       { 2a0 - (4a0/t0)*t, t0/4 < t < t0/2
		   { 0, t0/2 < t < t0/2 + tc,
		   { 2a0 - (4a0/t0)*(t - tc), t0/2 + tc < t < 3t0/4 + tc
		   { -4a0 + (4a0/t0)*(t - tc), 3t0/4 + tc < t < t0 + tc

    This path takes a time t0 + tc to reach the end, and the acceleration has a sawtooth pattern with maximum accelerations +/- a0.
	The time tc is the time the motion spends at a constant velocity, set by the maximum velocity v0 = 1/4*a0*t0.
	The time t0 is the time spent accelerating/decelerating.

	The position versus time is

	r(t) =  { 2a0/(3t0)*t^3, t < t0/4
	        { a0*t0^2/48 - (a0*t0/4)*t + a0*t^2 - 2a0/(3t0)*t^3, t0/4 < t < t0/2
			{ a0*t0*t0/16 + (a0*t0/4)*(t-t0/2), t0/2 < t < t0/2 + tc
			{ a0*t0*t0/48 - (a0*t0/4)*(t - tc) + a0*(t - tc)^2 - 2*a0/(3*t0)*(t - tc)^3 + a0*t0/4*tc, t0/2 + tc < t < 3t0/4 + tc
			{ -13*a0*t0*t0/24 + 2*a0*t0*(t - tc) - 2*a0*(t - tc)^2 + 2*a0/(3*t0)*(t - tc)^3 + a0*t0/4*tc, 3t0/4 + tc < t < t0 + tc.
	
	At time t0 + tc, the position is a0*t0^2/8 + a0*t0*tc/4.

	Since the attocube electronics have a filter at about 1600 Hz, 
	computing this path would be useless if t0 < about 1 ms, 
	since it would be averaged away by the filter.

	Therefore, compute t0+tc and if it is less than 1 ms, just jump directly to the specified point and let the filter do it smoothly.
	
	Use r(t) in polar coordinates to move diagonally from (x0,y0) to (x1,y1). Then, r1 = sqrt((x1-x0)^2+(y1-y0)^2).
	*/

	double a0 = scan_ptr->max_tip_accel; //maximum acceleration in volt/sec^2

	double v0 = scan_ptr->max_tip_velocity; //maximum velocity in volt/sec

	double t0 = 4*v0/a0; //t0 is set by the maximum acceleration and velocity

	double r1 = sqrt((x_tip - x)*(x_tip - x)+(y_tip - y)*(y_tip - y));

	//Compute the time the path is at the maximum velocity
	double tc = 4*(r1 - a0*t0*t0/8)/(a0*t0);

	if(tc < 0) //If the path  never reaches the set maximum velocity, eliminate constant velocity segment
	{
		tc = 0;
		t0 = sqrt(8*r1/a0);
	}

	//Divide total time by 1 ms to see if a smooth path is needed
	int n_pts = (int)((t0 + tc)/(1e-3));

	if(n_pts <= 1) //Move tip directly to new position
	{
		TaskHandle scanxy;
		DAQmxCreateTask("",&scanxy);

		DAQmxCreateAOVoltageChan(scanxy,scan_ptr->x_chan.c_str(),"",-10,10,DAQmx_Val_Volts,NULL);
		DAQmxCreateAOVoltageChan(scanxy,scan_ptr->y_chan.c_str(),"",-10,10,DAQmx_Val_Volts,NULL);
		DAQmxCreateAOVoltageChan(scanxy,scan_ptr->z_chan.c_str(),"",-10,10,DAQmx_Val_Volts,NULL);

		float64 out[6];
		out[0] = x;
		out[1] = y;
		out[2] = scan_ptr->plane_z(x,y)/((scan_ptr->_DAC)->z_adder_calibration);

		// DAQ card requires an analog output list of length a multiple of 2, but it is the same output here twice.
		out[3] = x;
		out[4] = y;
		out[5] = scan_ptr->plane_z(x,y)/((scan_ptr->_DAC)->z_adder_calibration);

		DAQmxWriteAnalogF64(scanxy, 1, 1, 10, DAQmx_Val_GroupByChannel , out, NULL, NULL);
		DAQmxWaitUntilTaskDone(scanxy,DAQmx_Val_WaitInfinitely);

		DAQmxStopTask(scanxy);
		DAQmxClearTask(scanxy);

	}
	else //Handle shape of curve in 1 ms segments at a speed of 1000 Hz
	{
		if(n_pts % 2 == 0) n_pts++;

		//char disp[300];
		//sprintf(disp,"%d",n_pts);
		//MessageBox(0,disp,0,0);

		float64* out = new float64[3*(n_pts + 1)];

		double theta = atan((y - y_tip)/(x - x_tip));

		int sgn_x,sgn_y;

		if(x == x_tip)
		{
			sgn_x = 0;
			if(y > y_tip) sgn_y = 1; else sgn_y = -1;
			theta = 3.14159/2;
		}
		else if(y == y_tip)
		{
			sgn_y = 0;
			if(x > x_tip) sgn_x = 1; else sgn_x = -1;
			theta = 0;

		}
		else
		{
			if(x > x_tip) sgn_x = 1; else sgn_x = -1;
			if(y > y_tip) sgn_y = 1; else sgn_y = -1;
		}

		//Set the x and y points for the curve (interlaced)
		
		for(int i = 0; i < n_pts; i++)
		{
			double ri = r((t0+tc)/(n_pts - 1)*i,a0,t0,tc);

			out[3*i] = x_tip + ri*abs(cos(theta))*sgn_x;
			out[3*i+1] = y_tip + ri*abs(sin(theta))*sgn_y;
			out[3*i+2] = scan_ptr->plane_z(out[3*i],out[3*i+1])/((scan_ptr->_DAC)->z_adder_calibration);
		}

		out[3*(n_pts)] = out[3*(n_pts) - 3];
		out[3*(n_pts)+1] = out[3*(n_pts) - 2];
		out[3*(n_pts)+2] = out[3*(n_pts) - 1];

		//out[2*n_pts] = out[2*n_pts - 2];
		//out[2*n_pts + 1] = out[2*n_pts - 1];

		TaskHandle scanxy;
		int32 write;
		DAQmxCreateTask("",&scanxy);

		DAQmxCreateAOVoltageChan(scanxy,scan_ptr->x_chan.c_str(),"",-10,10,DAQmx_Val_Volts,NULL);
		DAQmxCreateAOVoltageChan(scanxy,scan_ptr->y_chan.c_str(),"",-10,10,DAQmx_Val_Volts,NULL);
		DAQmxCreateAOVoltageChan(scanxy,scan_ptr->z_chan.c_str(),"",-10,10,DAQmx_Val_Volts,NULL);


		DAQmxCfgSampClkTiming(scanxy,"",1000,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_pts+1);

		int32 error = DAQmxWriteAnalogF64(scanxy, n_pts+1, 1, DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByScanNumber, out, &write, NULL);

		//char er[300];
		//DAQmxGetErrorString(error,er,300);

		//if(error != NULL);
		//MessageBox(0,er,0,0);

		DAQmxWaitUntilTaskDone(scanxy,DAQmx_Val_WaitInfinitely);

		//char disp[50];
		//sprintf(disp,"%d",write);
		//MessageBox(0,disp,0,0);

		DAQmxStopTask(scanxy);
		DAQmxClearTask(scanxy);

		delete [] out;
	}

	scan_ptr->x_tip = x;
	scan_ptr->y_tip = y;
	scan_ptr->_DAC->z_in_current = scan_ptr->plane_z(x,y);

	//Update the scan info window
	//scan_ptr->update_scan_ptr();
	
	//If there are no new points to move to return, otherwise go back to the top and move to the most recent mouse position
	if(scan_ptr->tip_x == x && scan_ptr->tip_y == y)
	{
		scan_ptr->is_tip_thread = false;
		return 1;
	}
	else
	{
		goto top;
	}
	

	return 1;


}

HANDLE scan::set_tip_xy(double x, double y)
{
	//tip_thread_data ttd;

	//ttd.x = x;
	//ttd.y = y;

	//Add the new point to the list of points to go to
	//tip_position_vector.push_back(ttd);
	tip_x = x;
	tip_y = y;

	if(!is_tip_thread) //Start a thread if there are no threads running
	{
		is_tip_thread = true;
		tip_thread = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)set_tip_xy_thread,this,NULL,NULL);
	}

	return tip_thread;
}
void get_current_z_thr(scan* _scan)
{

	TaskHandle readz;
	DAQmxCreateTask("",&readz);
	DAQmxCreateAIVoltageChan(readz,(_scan->z_fdbk_chan).c_str(),"",DAQmx_Val_Diff ,-10,10,DAQmx_Val_Volts,NULL);

	int n_pts = 1e5;

	DAQmxCfgSampClkTiming(readz,"",1e5,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_pts);

	int32 read = 0;
	float64* data = new float64[n_pts];

	int32 error = DAQmxReadAnalogF64(readz,n_pts,DAQmx_Val_WaitInfinitely,DAQmx_Val_GroupByChannel,data,n_pts,&read,NULL);
	
	DAQmxStartTask(readz);

	
	DAQmxWaitUntilTaskDone(readz,DAQmx_Val_WaitInfinitely);

	DAQmxStopTask(readz);
	DAQmxClearTask(readz);

	//Average data
	double sum = 0;
	for(int i = 0; i < n_pts; i++)
	{
		sum += data[i]/(float)n_pts;
	}


	_scan->current_z = sum;
	
	//SendMessage(_scan->dlg_hwnd,WM_APP,0,0); //Update dialog box

	delete [] data;

	_scan->is_get_current_z_thread = false;

}
HANDLE scan::get_current_z()
{
	if(!is_get_current_z_thread) //Start a thread if there are no threads running
	{
		is_get_current_z_thread = true;
		getz_thread = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)get_current_z_thr,this,NULL,NULL);
        return getz_thread;
	}


}
void scan_save_thread(scan* s)
{
		/*
	Saves a scan. 
	
	If the save is automatic after a scan is stopped or finished, data is saved to three files
	in the scan directory set in the .ini file (this now appears to not be an .ini file but in this function's constructor); 
	.scan file is the scan data, .info describes the scan,
	and .png is an image of the scan for fast searching. An entry is added to a SQL database for indexing.

	If the user chooses to save a scan from the menu or keyboard, only one file is saved in the target directory,
	a .dat file, that includes the scan info and scan data, no thumbnail is saved, and the scan data is not added to the SQL
	database, since it is always automatically saved when a scan ends.

	If is_update is true, then the current scan is saved to a temporary file that stores the current scan so long
	scans can be monitored.

	*/

	char curr_dir[MAX_PATH];
	GetCurrentDirectory(MAX_PATH,curr_dir);

	std::ofstream output;

	OPENFILENAME ofn;
	char szFileName[MAX_PATH];
	
	//Get the current time
	SYSTEMTIME syst;
	GetLocalTime(&syst);

	char time[100];

	sprintf_s(time,100,"%.2d-%.2d-%d  %.2dh%.2dm%.2ds",syst.wMonth,syst.wDay,syst.wYear,syst.wHour,syst.wMinute,syst.wSecond);
	strcpy_s(szFileName,MAX_PATH,time);

	ZeroMemory(&ofn, sizeof(ofn));

	ofn.lStructSize = sizeof(ofn); // SEE NOTE BELOW
	ofn.hwndOwner = s->hInfo;
	ofn.lpstrFilter = "DAT (.dat)\0*.dat\0All Files (*.*)\0*.*\0";
	ofn.lpstrFile = szFileName;
	ofn.nMaxFile = MAX_PATH;
	ofn.Flags = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT;
	ofn.lpstrDefExt = "dat";

	// typically in current usage (2015) is_auto is never set to false
	if(!s->is_auto)
	{
		if(!GetSaveFileName(&ofn))
		{
			return;
		}
	}
	
	

	//Only add entries to the SQL database for automatically saved files
	// the other conditional branch is is_update

	if(s->is_auto && !s->is_update)
	{
		char szFileNamePic[MAX_PATH];
		char szFileNameInfo[MAX_PATH];
		SetCurrentDirectory(s->scan_save_dir.c_str());

		MYSQL *connection, mysql;
		
		mysql_init(&mysql);

		// see settings above in constructor for database
		connection = mysql_real_connect(&mysql,s->MySQL_host.c_str(),s->MySQL_login.c_str(),s->MySQL_password.c_str(),s->MySQL_dbase.c_str(),0,0,0);
		
		if(!connection)
		{
			MessageBox(0,"Can't connect to the SQL database. Files will be named with current date and time.","Error",0);
			sprintf_s(szFileName,MAX_PATH,"%s.scan",time);
			sprintf_s(szFileNamePic,MAX_PATH,"%s.png",time);
			sprintf_s(szFileNameInfo,MAX_PATH,"%s.info",time);

			mysql_close(connection);
				
		}
		else //Connected to SQL database
		{
			//Find the maximum ID to determine the new filename
			
			mysql_query(connection, "SELECT id FROM scan");

			MYSQL_RES *result;
			
			result = mysql_store_result(connection);
		
			if(!result)
			{
				MessageBox(0,"Can't read from the SQL database. Files will be named with current date and time.","Error",0);
				sprintf_s(szFileName,MAX_PATH,"%s.scan",time);
				sprintf_s(szFileNamePic,MAX_PATH,"%s.png",time);
				sprintf_s(szFileNameInfo,MAX_PATH,"%s.info",time);
			}
			else
			{
				int n_row = mysql_num_rows(result);
				int num;

				if(n_row == 0) //No entries in database
				{
					num = 1;

					// so make a new directory for scans in the database starting with 
					char ndir[MAX_PATH];
					sprintf_s(ndir,MAX_PATH,"%s\\%d",s->scan_save_dir.c_str(),num);
					CreateDirectory(ndir,NULL);
					SetCurrentDirectory(ndir);

					sprintf_s(szFileName,MAX_PATH,"%06d.scan",num);
					sprintf_s(szFileNamePic,MAX_PATH,"%06d.png",num);
					sprintf_s(szFileNameInfo,MAX_PATH,"%06d.info",num);
				}
				else //Figure out next ID number
				{
					mysql_query(connection, "SELECT MAX(id) FROM scan");
			
					result = mysql_store_result(connection);

					MYSQL_ROW row;
					row = mysql_fetch_row(result);
					
					if(!row)
					{
						MessageBox(0,"Can't read from the SQL database. Files will be named with current date and time.","Error",0);
						sprintf_s(szFileName,MAX_PATH,"%s.scan",time);
						sprintf_s(szFileNamePic,MAX_PATH,"%s.png",time);
						sprintf_s(szFileNameInfo,MAX_PATH,"%s.info",time);
					
					}
					else
					{
						//MessageBox(0, "expected to get here 1.", "Error", 0);
						num = atoi(row[0])+1;
						//Make new directory based on scan number
						char ndir[MAX_PATH];
						sprintf_s(ndir,MAX_PATH,"%s\\%d",s->scan_save_dir.c_str(),num);
						CreateDirectory(ndir,NULL);
						SetCurrentDirectory(ndir);

						sprintf_s(szFileName,MAX_PATH,"%06d.scan",num);
						sprintf_s(szFileNamePic,MAX_PATH,"%06d.png",num);
						sprintf_s(szFileNameInfo,MAX_PATH,"%06d.info",num);
					}
				}
			}
				
			//Add file information to SQL database
			char sql_query[5000];

			//char comment[1000];
			//SendMessage(s->hComment,WM_GETTEXT,1000,(LPARAM)comment);//Get the comment from the edit control

			sprintf_s(sql_query,5000,"INSERT INTO scan VALUES(NULL,'%s','%s',NOW(),%f,%f,%f,%f,%d,%d,%f,%f,'%s',%d,%d,%d,%d,%d,%d,%d,'%s','%s','%s','%s','%s','%s','%s','%s',%d,%f,%f,%f,%f)",szFileName,szFileNamePic,
				(s->x_max - s->x_min),(s->y_max - s->y_min),s->x_center,s->y_center,s->nx_step,s->ny_step,s->freq,s->theta*180/s->pi,s->comment.c_str(),
				s->is_scan_ch[1],s->is_scan_ch[2],s->is_scan_ch[3],s->is_scan_ch[4],s->is_scan_ch[5],s->is_scan_ch[6],s->is_scan_ch[7],
				s->scan_ch_label[0].c_str(),s->scan_ch_label[1].c_str(),s->scan_ch_label[2].c_str(),s->scan_ch_label[3].c_str(),s->scan_ch_label[4].c_str(),s->scan_ch_label[5].c_str(),s->scan_ch_label[6].c_str(),s->scan_ch_label[7].c_str(),
				//s->_scan_set->sd_bias,s->_scan_set->scan_dep,s->_scan_set->chip_dep,s->_scan_set->back_gate,s->_scan_set->tip_volt,s->_planeInfo->offset,s->_scan_set->exc_size,s->_scan_set->exc_freq,s->sens_convert(s->_scan_set->sens),s->tc_convert(s->_scan_set->tc),
				/*s->tc_filter_convert(s->_scan_set->tc_filt),s->curr_amp_gain_convert(s->_scan_set->cur_amp),s->exc_applied_convert(s->_scan_set->exc_applied).c_str(),*/s->_planeInfo->is_plane_active,s->_planeInfo->a,s->_planeInfo->b,s->_planeInfo->c,s->_planeInfo->r2);
			
			int query_state = mysql_query(connection, sql_query);
			
			if(query_state)
			{
				MessageBox(0,"Could not save to SQL database. Files will be named with current date and time.","Error",0);
				sprintf_s(szFileName,MAX_PATH,"%s.scan",time);
				sprintf_s(szFileNamePic,MAX_PATH,"%s.png",time);
				sprintf_s(szFileNameInfo,MAX_PATH,"%s.info",time);
			}

			s->is_current_scan_saved = true;

			mysql_free_result(result);
			mysql_close(connection);

		}

			

			//Save .info file
			std::ofstream info_file;
			info_file.open(szFileNameInfo);

			char time[100];

			sprintf_s(time,"%d/%d/%d %.2d:%.2d:%.2d",syst.wMonth,syst.wDay,syst.wYear,syst.wHour,syst.wMinute,syst.wSecond);
			
			info_file << time << std::endl;
			info_file << "Size: " << (s->x_max - s->x_min) << " V x " << (s->y_max - s->y_min) << " V" << std::endl;
			info_file << "Center: (" << s->x_center << " V, " << s->y_center << " V)" << std::endl;
			info_file << "Resolution: " << s->nx_step << " x " << s->ny_step << std::endl;
			info_file << "Scan Speed: " << s->freq << " Hz" << std::endl;
			info_file << "Rotation: " << s->theta*180/s->pi << " deg" << std::endl;
			
			info_file << std::endl;
			info_file << "Column Headings:" << std::endl;
			info_file << "X" << " / " << " Y " << " / " << "Ch0 - Forward" << " / " << "Ch0 - Forward filtered" << " / " << "Ch0 - Reverse" << " / " << "Ch0 - Reverse filtered";
			
			for(int q = 0; q < 7; q++)
			{
				if(s->is_scan_ch[q+1])
				{
					info_file << " / " << s->scan_ch_label[q+1].c_str() << " - Forward / " << s->scan_ch_label[q+1].c_str() << " - Reverse";

				}
			}
			info_file.close();

			//Save image of scan (topography data)
			save_scan_image(s->data_filter,s->nx_step,s->ny_step,s->min_max[2],s->min_max[3],std::string(szFileNamePic));

			//Save images of other scan channels if applicable
			for(int q = 0; q < 7; q++)
			{
				if(s->is_scan_ch[q+1])
				{
					std::string img_fname = szFileNamePic;
					int n_pos = img_fname.find(".");

					if(n_pos != std::string::npos)
					{
						char ins[10];
						sprintf_s(ins,10,"-%d",q+1);
						img_fname.insert(n_pos,ins);
						save_scan_image(s->ch_data[q],s->nx_step,s->ny_step,s->ch_min_max[q*2],s->ch_min_max[q*2 + 1],img_fname);
					}
				}
			}
		
	}
	else if(s->is_auto && s->is_update)
	{
		std::string scan_file = std::string(s->scan_save_dir) + std::string("\\") + std::string(s->currscan_fname);
		strcpy_s(szFileName, MAX_PATH,scan_file.c_str());

		std::string pic_file = std::string(s->scan_save_dir) + std::string("\\") + std::string(s->currscan_pic);

		//SendMessage(s->hInfo,WM_APP,(WPARAM)pic_file.c_str(),NULL);
		save_scan_image(s->data_plot,s->nx_step,s->ny_step,s->min_max[0],s->min_max[1],pic_file);

		//Save image of scan (topography data)
			save_scan_image(s->data_filter,s->nx_step,s->ny_step,s->min_max[2],s->min_max[3],pic_file);

			//Save images of other scan channels if applicable
			for(int q = 0; q < 7; q++)
			{
				if(s->is_scan_ch[q+1])
				{
					std::string img_fname = pic_file;
					int n_pos = img_fname.find(".");

					if(n_pos != std::string::npos)
					{
						char ins[10];
						sprintf_s(ins,10,"-%d",q+1);
						img_fname.insert(n_pos,ins);
						save_scan_image(s->ch_data[q],s->nx_step,s->ny_step,s->ch_min_max[q*2],s->ch_min_max[q*2 + 1],img_fname);
					}
				}
			}

		MYSQL *connection, mysql;
		
		mysql_init(&mysql);

		connection = mysql_real_connect(&mysql,s->MySQL_host.c_str(),s->MySQL_login.c_str(),s->MySQL_password.c_str(),s->MySQL_dbase.c_str(),0,0,0);

		if(connection)
		{
			char sql_query[5000];
			sprintf_s(sql_query,5000,"UPDATE currscan SET created = NOW(), x_size = %f, y_size = %f, x_center = %f, y_center = %f, x_res = %d, y_res = %d, speed = %f, rot = %f, isc1=%d, isc2=%d, isc3=%d, isc4=%d, isc5=%d, isc6=%d, isc7=%d, c0lbl='%s', c1lbl='%s', c2lbl='%s', c3lbl='%s', c4lbl='%s', c5lbl='%s', c6lbl='%s', c7lbl='%s', is_plane = %d, plane_a = %f, plane_b = %f, plane_c = %f, plane_r2 = %f, comments='%s' WHERE id = 1",
				(s->x_max - s->x_min),(s->y_max - s->y_min),s->x_center,s->y_center,s->nx_step,s->ny_step,s->freq,s->theta*180/s->pi,
				s->is_scan_ch[1],s->is_scan_ch[2],s->is_scan_ch[3],s->is_scan_ch[4],s->is_scan_ch[5],s->is_scan_ch[6],s->is_scan_ch[7],
				s->scan_ch_label[0].c_str(),s->scan_ch_label[1].c_str(),s->scan_ch_label[2].c_str(),s->scan_ch_label[3].c_str(),s->scan_ch_label[4].c_str(),s->scan_ch_label[5].c_str(),s->scan_ch_label[6].c_str(),s->scan_ch_label[7].c_str(),
				//s->_scan_set->sd_bias,s->_scan_set->scan_dep,s->_scan_set->chip_dep,s->_scan_set->back_gate,s->_scan_set->tip_volt,s->_planeInfo->offset,s->_scan_set->exc_size,s->_scan_set->exc_freq,s->sens_convert(s->_scan_set->sens),s->tc_convert(s->_scan_set->tc),
				/*s->tc_filter_convert(s->_scan_set->tc_filt),s->curr_amp_gain_convert(s->_scan_set->cur_amp),s->exc_applied_convert(s->_scan_set->exc_applied).c_str(),*/s->_planeInfo->is_plane_active,s->_planeInfo->a,s->_planeInfo->b,s->_planeInfo->c,s->_planeInfo->r2,s->comment.c_str());

			mysql_query(connection, sql_query);
			
			mysql_close(connection);
		}
	}

	output.open(szFileName);
	
	if(!s->is_auto)
	{
		char time[100];

		sprintf_s(time,"%d/%d/%d %.2d:%.2d:%.2d",syst.wMonth,syst.wDay,syst.wYear,syst.wHour,syst.wMinute,syst.wSecond);
		
		output << time << std::endl;
		output << "Size: " << (s->x_max - s->x_min) << " V x " << (s->y_max - s->y_min) << " V" << std::endl;
		output << "Center: (" << s->x_center << " V, " << s->y_center << " V)" << std::endl;
		output << "Resolution: " << s->nx_step << " x " << s->ny_step << std::endl;
		output << "Scan Speed: " << s->freq << " Hz" << std::endl;
		output << "Rotation: " << s->theta*180/s->pi << " deg" << std::endl;
		
		output << std::endl ;
		output << "Column Headings:" << std::endl;
		output << "X" << " / " << " Y " << " / " << "Ch0 - Forward" << " / " << "Ch0 - Forward filtered" << " / " << "Ch0 - Reverse" << " / " << "Ch0 - Reverse filtered";
		
		for(int q = 0; q < 7; q++)
		{
			if(s->is_scan_ch[q+1])
			{
				output << " / " << s->scan_ch_label[q+1].c_str() << " - Forward / " << s->scan_ch_label[q+1].c_str() << " - Reverse";

			}
		}
		output << std::endl;
		output << std::endl;

		
	}

	
	for(int i = 0; i < s->nx_step; i++)
	{
		for(int j = 0; j < s->ny_step; j++)
		{
			output << s->x_axis[i] << "\t" << s->y_axis[j] << "\t" << s->data_plot[i][j] << "\t" << s->data_filter[i][j] << "\t" << s->data_plot_rev[i][j] << "\t" << s->data_filter_rev[i][j];
			for(int q = 0; q < 7; q++)
			{
				if(s->is_scan_ch[q+1])
				{
					output << "\t" << s->ch_data[q][i][j] << "\t" << s->ch_data_rev[q][i][j];

				}
			}
			output << std::endl;
		}

	}
	

	output.close();	
	SetCurrentDirectory(curr_dir);
	s->is_scan_thr = false;
	


}
bool scan::save(bool _is_auto, bool _is_update)
{

	is_auto = _is_auto;
	is_update = _is_update;

	WaitForSingleObject(scan_save_thr,500);
	TerminateThread(scan_save_thr,NULL);

	is_scan_thr = true;
	// parameter passed to the thread is "this", referring to the instance of scan class
	scan_save_thr = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)scan_save_thread,this,NULL,NULL);
/*

	if(!is_scan_thr)
	{
		is_scan_thr = true;
		scan_save_thr = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)scan_save_thread,this,NULL,NULL);
	}
	else
	{
		if(!is_update) //Archive scan
		{
			TerminateThread(scan_save_thr,NULL);
			scan_save_thr = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)scan_save_thread,this,NULL,NULL);
		}

	}
	*/
	return 1;

}
void scan::set_disp_data(int num, int dir)
{

	if(num == 0 && dir == 1) 
	{
		disp_data = data_plot;
		z_min = &min_max[0];
		z_max = &min_max[1];
	}
	else if(num == 1 && dir == 1)
	{
		disp_data = data_filter;
		z_min = &min_max[2];
		z_max = &min_max[3];
	}
	else if(num == 0 && dir == 0)
	{
		disp_data = data_plot_rev;
		z_min = &min_max[4];
		z_max = &min_max[5];
	}
	else if(num == 1 && dir == 0) 
	{
		disp_data = data_filter_rev;
		z_min = &min_max[6];
		z_max = &min_max[7];
	}
	else
	{
		if(num > 8) return;
		if(dir == 1)
		{
			disp_data = ch_data[num-2];
			z_min = &ch_min_max[ (num - 2)*2 ];
			z_max = &ch_min_max[ (num - 2)*2 + 1];
		}
		else if(dir == 0)
		{
			disp_data = ch_data_rev[num-2];
			z_min = &ch_min_max[ (num - 2)*2 + 14];
			z_max = &ch_min_max[ (num - 2)*2 + 15];
		}
        num_selected_ch = num - 1;
	}

}
void scan::update_scan_info()
{
	//Update the comment in the SQL database if it has been saved
	if(is_current_scan_saved)
	{
		MYSQL *connection, mysql;
		
		mysql_init(&mysql);

		connection = mysql_real_connect(&mysql,MySQL_host.c_str(),MySQL_login.c_str(),MySQL_password.c_str(),MySQL_dbase.c_str(),0,0,0);

		if(!connection)
		{
			MessageBox(0,"Can't connect to the SQL database.","Error",0);
			

			mysql_close(connection);
				
		}
		else //Connected to SQL database
		{
			//Find the maximum ID to determine last saved file
			
			mysql_query(connection, "SELECT MAX(id) from scan");

			MYSQL_RES *result;
			
			result = mysql_store_result(connection);
		
			if(!result)
			{
				MessageBox(0,"Can't read from the SQL database.","Error",0);
			}
			else
			{
				MYSQL_ROW row;
				row = mysql_fetch_row(result);

				if(!row)
				{
					MessageBox(0,"Can't read from the SQL database.","Error",0);
				}
				else
				{
					int num = atoi(row[0]);

					char sql_query[5000];

					sprintf_s(sql_query,5000,"UPDATE scan SET is_plane = %d, plane_a = %f, plane_b = %f, plane_c = %f, plane_r2 = %f, comments='%s' WHERE id=%d",
						/*_scan_set->sd_bias,_scan_set->scan_dep,_scan_set->chip_dep,_scan_set->back_gate,_scan_set->tip_volt,_planeInfo->offset,_scan_set->exc_size,_scan_set->exc_freq,sens_convert(_scan_set->sens),tc_convert(_scan_set->tc),
						tc_filter_convert(_scan_set->tc_filt),curr_amp_gain_convert(_scan_set->cur_amp),exc_applied_convert(_scan_set->exc_applied).c_str(),*/_planeInfo->is_plane_active,_planeInfo->a,_planeInfo->b,_planeInfo->c,_planeInfo->r2,comment.c_str(),num);
					
					int query_state = mysql_query(connection, sql_query);
			
					if(query_state)
					{
						MessageBox(0,"Could not update scan info.","Error",0);
						
					}

					sprintf_s(sql_query,5000,"UPDATE currscan SET created = NOW(), x_size = %f, y_size = %f, x_center = %f, y_center = %f, x_res = %d, y_res = %d, speed = %f, rot = %f, isc1=%d, isc2=%d, isc3=%d, isc4=%d, isc5=%d, isc6=%d, isc7=%d, c0lbl='%s', c1lbl='%s', c2lbl='%s', c3lbl='%s', c4lbl='%s', c5lbl='%s', c6lbl='%s', c7lbl='%s', is_plane = %d, plane_a = %f, plane_b = %f, plane_c = %f, plane_r2 = %f, comments='%s' WHERE id = 1",
					(x_max - x_min),(y_max - y_min),x_center,y_center,nx_step,ny_step,freq,theta*180/pi,
					is_scan_ch[1],is_scan_ch[2],is_scan_ch[3],is_scan_ch[4],is_scan_ch[5],is_scan_ch[6],is_scan_ch[7],
					scan_ch_label[0].c_str(),scan_ch_label[1].c_str(),scan_ch_label[2].c_str(),scan_ch_label[3].c_str(),scan_ch_label[4].c_str(),scan_ch_label[5].c_str(),scan_ch_label[6].c_str(),scan_ch_label[7].c_str(),
					/*_scan_set->sd_bias,_scan_set->scan_dep,_scan_set->chip_dep,_scan_set->back_gate,_scan_set->tip_volt,_planeInfo->offset,_scan_set->exc_size,_scan_set->exc_freq,sens_convert(_scan_set->sens),tc_convert(_scan_set->tc),
					tc_filter_convert(_scan_set->tc_filt),curr_amp_gain_convert(_scan_set->cur_amp),exc_applied_convert(_scan_set->exc_applied).c_str(),*/_planeInfo->is_plane_active,_planeInfo->a,_planeInfo->b,_planeInfo->c,_planeInfo->r2,comment.c_str());

					query_state = mysql_query(connection, sql_query);
			
					if(query_state)
					{
						MessageBox(0,"Could not update current scan info.","Error",0);
						
					}

				}
				
			}


			mysql_free_result(result);
			mysql_close(connection);
		}


	}
}
void scan::set_scan_labels()
{
	/*for(int i = 0; i < 8; i++)
	{
		scan_ch_label[i] = _ini->scan_input_labels[i];
	}
*/
}

void save_scan_image(double** data, int x_size, int y_size, double z_min, double z_max, std::string file_path) 
{ 
    FreeImage_Initialise(TRUE); 
    FIBITMAP *bitmap = FreeImage_Allocate(x_size,y_size,24); 
  
    for (int y = 0; y < y_size; ++y) 
    { 
        for (int x = 0; x < x_size; ++x) 
        { 
            double clr = (data[x][y] - z_min)/(z_max - z_min); 
            if(clr < 0) clr = 0; 
            else if(clr > 1) clr = 1; 
  
            clr = clr*255; 
  
            RGBQUAD color; 
            color.rgbRed = clr; 
            color.rgbGreen = clr; 
            color.rgbBlue = clr; 
            FreeImage_SetPixelColor(bitmap,x,(y_size - 1 - y),&color); 
             //Align the pixels correctly 
        } 
     } 
  
      
    int n_pos = file_path.find("."); 
              
    if(n_pos != std::string::npos) 
    { 
        if(file_path.substr(n_pos,4) == ".bmp") 
        { 
            FreeImage_Save(FIF_BMP,bitmap,file_path.c_str(),BMP_DEFAULT); 
        } 
        else if(file_path.substr(n_pos,4) == ".png") 
        { 
            FreeImage_Save(FIF_PNG,bitmap,file_path.c_str(),BMP_DEFAULT); 
        } 
        else if(file_path.substr(n_pos,4) == ".jpg") 
        { 
            FreeImage_Save(FIF_JPEG,bitmap,file_path.c_str(),BMP_DEFAULT); 
        } 
    } 
  
    FreeImage_Unload(bitmap); 
  
  
  
  
} 