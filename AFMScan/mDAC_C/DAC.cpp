#include "DAC.h"
#include "stdio.h"
#include "NIDAQmx.h"

#include <cmath>
#include <string>
#include <fstream>
#include <complex>

DAC::DAC()
{	
	
	is_readout = false;
	is_stepper_thread = false;
	
	is_sweep_aborted = false;
	is_z_in_thr = false;
	
	n_samp = 100; //Samples for tip input and phase input
	n_chan = 4;
	n_chan_active = 0;

	n_buf = 500;

	redefine = false;
	
	//n_mult = 25;

	measure = new bool[n_chan];

	input_val = new double*[n_chan];

	for(int i = 0; i < n_chan; i++)
	{
		input_val[i] = new double[n_buf];

		for(int j = 0; j < n_buf; j++)
		{
			input_val[i][j] = 0;
		}

		measure[i] = true;
	}

	z_set = 0;
	z_set_offset = 0;

	b_zero = 0;

	//freq_current = 0;

	//inputs = new float64[n_chan];
	inputavg = new float64[n_samp*n_chan];
	
	//handles = new TaskHandle[n_chan];

	x_step = 0;
	y_step = 0;
	z_step = 0;

	z_in(0);

	exc_hilo = 0;

	sweep_max = 3;

	n_steps = 10;
    
    z_chan = "PXI1Slot3/ao2";
    tip_chan = /*"PXI1Slot3/ai0"*/"PXI1Slot2/ai17"; // should be "AI1" port on 2nd BNC-2110 of DAQ slot2
	phase_chan = "PXI1Slot2/ai18"; // should be "AI2" port on 2nd BNC-2110 of DAQ slot2
    
    z_in_current = 0;
    
	// correct for adder output of circuit when adding two inputs
   z_adder_calibration = 0.989391;

}
DAC::~DAC()
{
	delete [] inputavg;
	for(int i = 0; i < n_chan; i++)
	{
		delete [] input_val[i];
	}
	delete [] input_val;
	//delete [] handles;
}
void DAC::define_tasks()
{
	DAQmxStopTask(handle);
	DAQmxClearTask(handle);

	DAQmxCreateTask("",&handle);

	n_chan_active = 0;

	for(int i = 0; i < n_chan; i++)
	{
		if(measure[i])
		{
			n_chan_active++;
			char num[10];
			_itoa_s(i,num,10,10);
			std::string port_num = std::string("Dev3/ai") + std::string(num);
			if(i != 4 && i != 5 && i != 6) DAQmxCreateAIVoltageChan(handle,port_num.c_str(),"",DAQmx_Val_Diff ,-10,10,DAQmx_Val_Volts,NULL);
			else  DAQmxCreateAIVoltageChan(handle,port_num.c_str(),"",DAQmx_Val_Diff ,0,1,DAQmx_Val_Volts,NULL);
		}
	}

	DAQmxCfgSampClkTiming(handle,"",100000,DAQmx_Val_Rising,DAQmx_Val_ContSamps,n_samp);
	DAQmxSetReadRelativeTo(handle,DAQmx_Val_CurrReadPos );
	DAQmxSetReadOffset(handle,0);

	DAQmxStartTask(handle);
	Sleep(100);  //Let the buffer refresh

}
void DAC::stop_task()
{
	DAQmxStopTask(handle);
}
void DAC::clear_task()
{
	DAQmxClearTask(handle);
}
void DAC::start_task()
{
	DAQmxStartTask(handle);
}

double DAC::r(double t, double a0, double t0, double tc)
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
void z_in_thread(DAC* _DAC)
{
	if(_DAC->z_in_thread_value < 0 || _DAC->z_in_thread_value > 10) return;

	double z = _DAC->z_in_thread_value; 
    
	double a0 = 10; //maximum acceleration in volt/sec^2

	double v0 = 1; //maximum velocity in volt/sec

	double t0 = 4*v0/a0; //t0 is set by the maximum acceleration and velocity

	double r1 = abs(z - _DAC->z_in_current);

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
		
		DAQmxCreateTask("",&_DAC->scanz);
		// the adder inverts the input sum, so the minimum is set to -10 V and max = 0 V.
		DAQmxCreateAOVoltageChan(_DAC->scanz,(_DAC->z_chan).c_str(),"",-10,0,DAQmx_Val_Volts,NULL);

		float64 out[1] = {z/_DAC->z_adder_calibration};

		DAQmxWriteAnalogF64(_DAC->scanz, 1, 1, 10, DAQmx_Val_GroupByChannel , out, NULL, NULL);

		DAQmxStopTask(_DAC->scanz);
		DAQmxClearTask(_DAC->scanz);
		
		
		//_DAC->_Keithley.set_volt(-z*15.0);

		//_DAC->_Yokogawa.set_volt(-z*15.0);
	}
	else
	{
		float64* out = new float64[n_pts + 1];
		int extra = 0;

		int sgn = 1;

		if(z < _DAC->z_in_current) sgn = -1;
	
		for(int i = 0; i < n_pts; i++)
		{
			double ri = _DAC->r((t0+tc)/(n_pts - 1)*i,a0,t0,tc);

			out[i] = (_DAC->z_in_current + ri*sgn)/_DAC->z_adder_calibration;

			
		}

		if(n_pts % 2 == 1) //For this card, the output must have an even number of elements
		{
			out[n_pts] = out[n_pts - 1];
			extra = 1;
		}


		
		int32 write;
		DAQmxCreateTask("",&_DAC->scanz);
		
		DAQmxCreateAOVoltageChan(_DAC->scanz,(_DAC->z_chan).c_str(),"",-10,10,DAQmx_Val_Volts,NULL);

		DAQmxCfgSampClkTiming(_DAC->scanz,"",1000,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_pts + extra);

		DAQmxWriteAnalogF64(_DAC->scanz, n_pts + extra, 1, 600, DAQmx_Val_GroupByScanNumber, out, &write, NULL);
		DAQmxWaitUntilTaskDone(_DAC->scanz,600.0);

		DAQmxStopTask(_DAC->scanz);
		DAQmxClearTask(_DAC->scanz);
		
		delete [] out;
		

	}

	_DAC->z_in_current = z;
	_DAC->is_z_in_thr = false;
	return;


}
HANDLE DAC::z_in(double z)
{
    WaitForSingleObject(z_in_thr,INFINITE);
	z_in_thread_value = z;
	CloseHandle(z_in_thr);
	is_z_in_thr = true;
	z_in_thr = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&z_in_thread,this,NULL,NULL);
	return z_in_thr;
}
void DAC::stop_z()
{
	DAQmxStopTask(scanz);
	DAQmxClearTask(scanz);
}
void DAC::get_input()
{
	for(int i = 0; i < n_chan; i++)
	{
		if(measure[i])
		{
			for(int j = 0; j < n_buf - 1; j++)
			{
				input_val[i][j] = input_val[i][j + 1];

			}
		}
	}

	int32 error = DAQmxReadAnalogF64(handle,n_samp,0,DAQmx_Val_GroupByChannel,inputavg,n_samp*n_chan_active,NULL,NULL);

	DAQmxSetReadRelativeTo(handle,DAQmx_Val_MostRecentSamp );
	DAQmxSetReadOffset(handle,-n_samp*n_chan_active);
	
	int count = 0;
	for(int i = 0; i < n_chan; i++)
	{
		if(measure[i])
		{
			double avg = 0;
			for(int j = 0; j < n_samp; j++)
			{
				avg += inputavg[count*n_samp + j] / (float)n_samp;
			}
			if(i == 3) avg = -avg; //Feedback sense output is inverted in the adder in the feedback box

			input_val[i][n_buf - 1] = avg;
			count++;
		}
		
	}
	
	/*
	if(temp)
	{
		input_val[0][n_buf - 1] = 1;
		input_val[1][n_buf - 1] = 2;
		input_val[2][n_buf - 1] = 3;
		input_val[3][n_buf - 1] = 4;
		input_val[4][n_buf - 1] = 0.005;
	}
	else
	{
		input_val[0][n_buf - 1] = 0;
		input_val[1][n_buf - 1] = 0;
		input_val[2][n_buf - 1] = 0;
		input_val[3][n_buf - 1] = 0;
		input_val[4][n_buf - 1] = 0;


	}
	temp = !temp;
	*/

	return;

}

void DAC::define_approach_task()
{
     DAQmxStopTask(approach_handle);
	DAQmxClearTask(approach_handle);

	DAQmxCreateTask("",&approach_handle);

	DAQmxCreateAIVoltageChan(approach_handle,tip_chan.c_str(),"",DAQmx_Val_Diff ,-1,1,DAQmx_Val_Volts,NULL);
	DAQmxCreateAIVoltageChan(approach_handle,phase_chan.c_str(),"",DAQmx_Val_Diff,-1,1,DAQmx_Val_Volts, NULL);
     DAQmxCfgSampClkTiming(approach_handle,"",100000,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samp);
	
	
}
float* DAC::approach_check()
{
    float64* value = new float64[2*n_samp];
	// n_samp is the number of samples, per channel. I have two channels: amplitude and phase
       
	int32 error = DAQmxReadAnalogF64(approach_handle,n_samp,DAQmx_Val_WaitInfinitely,DAQmx_Val_GroupByChannel,value,2*n_samp,&approach_read,NULL);
		/*char str[300];
		 DAQmxGetErrorString(error,str,300);
			MessageBox(0,str,0,0);*/
	DAQmxStartTask(approach_handle);

	DAQmxWaitUntilTaskDone(approach_handle,1);
	DAQmxStopTask(approach_handle);
  //  DAQmxClearTask(approach_handle);
 

	float defl_avg = 0; 
	
     for(int i = 0; i < n_samp; i++)
	{
		defl_avg += value[i]/(float)n_samp;
	}

	 // for fillMode of GroupByChannel the first n_samp are the amplitude, then next n_samp are the phase
	float phase_avg = 0;

	for (int i = (n_samp); i < 2*n_samp; i++)
	{
		phase_avg += value[i] / (float)n_samp;
	}

    
    delete [] value;

	static float ai_array[2];
	ai_array[1] = defl_avg;
	ai_array[2] = phase_avg;

	return ai_array;
}

/*void DAC::define_phase_task()
{
	DAQmxStopTask(phase_handle);
	DAQmxClearTask(phase_handle);

	DAQmxCreateTask("", &phase_handle);

	DAQmxCreateAIVoltageChan(phase_handle, phase_chan.c_str(), "", DAQmx_Val_Diff, -1, 1, DAQmx_Val_Volts, NULL);
	DAQmxCfgSampClkTiming(phase_handle, "", 100000, DAQmx_Val_Rising, DAQmx_Val_FiniteSamps, n_samp);
}
float DAC::phase_check()
{
	float64* value = new float64[n_samp];

	int32 error = DAQmxReadAnalogF64(phase_handle, n_samp, DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByChannel, value, n_samp, &phase_read, NULL);
	// char str[300];
	//DAQmxGetErrorString(error,str,300);
	// MessageBox(0,str,0,0);
	DAQmxStartTask(phase_handle);

	DAQmxWaitUntilTaskDone(phase_handle, 1);
	DAQmxStopTask(phase_handle);
	//  DAQmxClearTask(phase_handle);


	float phase_avg = 0;

	for (int i = 0; i < n_samp; i++)
	{
		phase_avg += value[i] / (float)n_samp;
	}


	delete[] value;

	return phase_avg;
}*/

void DAC::z_sweep(float start, float end, float rate)
{

	//Ramp voltage at about 400 Hz (max DAC card will allow with individual writes)
	//Determine number of points in sweep (rate in volts per second)

	int n_pts = (int)(  (end-start)/(float)(rate)*400  + 0.5);

	float64* out_sweep = new float64[n_pts+1];

	is_sweep_aborted = false;
    
	for(int i = 0; i < n_pts; i++)
	{
		out_sweep[i] = (start + (end-start)*(float)(i)/(float)(n_pts - 1))/z_adder_calibration;
	}	
		int32 write;
		DAQmxCreateTask("",&sweep_handle);
		
		DAQmxCreateAOVoltageChan(sweep_handle,z_chan.c_str(),"",-10,10,DAQmx_Val_Volts,NULL);	
		DAQmxCfgSampClkTiming(sweep_handle,"",10000,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,2);


		for(int i = 0; i < n_pts; i++)
		{
			float64 op[2];
			op[0] = out_sweep[i];
			op[1] = out_sweep[i];

			int32 error = DAQmxWriteAnalogF64(sweep_handle, 2, 1, 600, DAQmx_Val_GroupByScanNumber, op, &write, NULL);
			if(error != 0) 
			{
				char estr[300];
				DAQmxGetErrorString(error,estr,300);
				MessageBox(0,estr,0,0);
			}
			/*
			error = DAQmxStartTask(sweep_handle);
			if(error != 0) 
			{
				char estr[300];
				DAQmxGetErrorString(error,estr,300);
				MessageBox(0,estr,0,0);
			}
			*/
			DAQmxWaitUntilTaskDone(sweep_handle,600.0);
			DAQmxStopTask(sweep_handle);
			
			z_in_current = op[1]*z_adder_calibration;

			if(is_sweep_aborted) break;

		}


		DAQmxStopTask(sweep_handle);
		DAQmxClearTask(sweep_handle);
		

		delete [] out_sweep;
	
}
void DAC::stop_sweep()
{
	is_sweep_aborted = true;
}