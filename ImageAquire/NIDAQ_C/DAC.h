#ifndef _DAC_H
#define _DAC_H

/*
The DAC class handles all non-scanning operations of the NI DAC cards.
Scanning functions are defined in the scan class.
Only one instance of this class should be called in a global scope.
*/

#include <windows.h>
#include <vector>
#include <string>
#include "NIDAQmx.h"
#include "planeInfo.h"

class DAC
{
public:
	DAC();//Constructor
	~DAC();//Destructot
    
	void feedback(bool val); //Turn feedback on and off
	void int_reset(); //Reset the integrator

	bool z_set_pt(double z); //Setpoint for z feedback
	HANDLE z_in(double z); //z signal to add to feedback, returns a HANDLE to z in thread
	HANDLE z_in_thr; //Hande for thread that changes z in
	double z_in_thread_value; //Value to pass to z in thread
	TaskHandle scanz; //Handle for NI task of changing z-in value

	void z_sweep(float start, float end, float rate); //Sweep z piezo
	void stop_sweep(); //Stop a z sweep
	bool is_sweep_aborted;

	//Function that defines a smooth path between two voltages
	double r(double t, double a0, double t0, double tc);

	//Oscilloscope window functions
	void define_tasks();//Define the channels to be read
	void stop_task();//Start oscilloscope read
	void start_task();//Stop oscilloscope read
	void clear_task();

	void stop_z();//Stop the z-axis value from changing, for use in stopping a change started by z_in()

	bool readout_exc(bool status); //Turn on excitation voltage for stepper readout
	bool exc_hilo; //Stores high or low excitation voltage for stepper readout
	void readout_exc_value(bool _exc_hilo) {exc_hilo = _exc_hilo;} //specify high or low excitiation voltage (0 = 1 V, 1 = 0.1 V)
		
	void get_input(); //Update the input_val array for all active oscilloscope inputs

	double** input_val; //Pointer to the array that stores the oscilloscope current and past values

	int n_buf; //Number of values in the buffer for each oscilloscope channel
	int n_chan; //Number of oscilloscope channels to read

	double z_set; //Set point for z feedback
	double z_set_offset; //Offset for set point (accounts for offset in feedback electronics, set in .ini file)

	bool is_set_point; //Has the set point been set?
	bool is_feedback; //Is the feedback on?
	bool is_readout; //Is the stepper readout on?

	bool* measure; //Pointer to an array of Boolean variables of length n_chan, true if channel is active

	bool redefine; //Status of active oscilloscope channels has changed, define_tasks() must be called to redefine active channels

	//Stepper readout values
	double x_step;
	double y_step;
	double z_step;

	HWND mdidac_hwnd; //Window handle of the MDIDAC parent window
	
	HANDLE stepper_thread; //Handle to the thread for measuring attocube stepper readout
	bool is_stepper_thread; //Stepper thread active

	double b_zero; //Offset value for zeroing the bridge
	double z_in_current; //Current value for z-axis input signal before added to feedback



    planeInfo* _planeInfo; 
  
    void set_plane_info_ptr(planeInfo* pIptr){_planeInfo = pIptr;} 
	
	void set_output(int chan, float value);

	float approach_check();

	void define_approach_task();

	double sweep_max; //Maximum voltage to sweep z piezo on approach

	bool is_z_in_thr; //True if z in thread is active

	int n_steps; //Number of Attocube steps to take after one Approach sequence
    
     std::string z_chan;
     std::string tip_chan;
     
     void set_z_cal_factor(double z_cal){z_adder_calibration = z_cal;}
     
    double z_adder_calibration; //Calbration factor for adder on z piezo voltage

	
private:
	
	int n_samp; //Number of samples to average over for each oscilloscope reading

	int n_chan_active; //Number of active oscilloscope channels

//	double freq_current; //Current voltage output for PLL frequency set point

	TaskHandle handle; //Handle for NI task running oscilloscope card


	TaskHandle approach_handle,sweep_handle,sweep_count; 

	float64 defl[1];
	int32 approach_read;
	

	float64* inputavg; //Pointer to variable that reads data from oscilloscope card
    
   
};
#endif __DAC_H