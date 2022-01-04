#ifndef __SCAN_H
#define __SCAN_H

//The scan class handles all DAC commands associated with scanning.
//This class should be declared only once in a global scope.

#include <windows.h>
#include "NIDAQmx.h"
#include "DAC.h"
#include "planeInfo.h"

double r(double t, double a0, double t0, double tc);

void save_scan_image(double** data, int x_size, int y_size, double z_min, double z_max, std::string file_path);

class scan
{
public:
	scan();
	~scan();

	void set_scan_labels();

	void stop_scan(); //Stop the scan task

	HANDLE set_tip_xy(double x, double y); //Thread for setting the tip position

	void set(double _x_min, double _x_max, double _y_min, double _y_max, int _nx_step, int _ny_step, double _freq, double _theta); //theta in degrees
	/*
		double _x_min - Minimum x voltage for scan
		double _x_max - Maximum x voltage for scan
		double _y_min - Minimum y voltage for scan
		double _y_max - Maximum y voltage for scan
		int _nx_step - Number of points in x axis
		int _ny_step - Number of points in y axis
		double _freq - Scan speed in points/second (NOT lines/second)
		double _theta - Rotation of scan field about scan center defined by (x_min,y_min) to (x_max,y_max)

	*/

	bool scan_line_smooth(int line_num); //Scans one line of the field (set by line_num) in a smooth fashion (smooth acceleration)

    bool scan_line_sequence(int line_num, std::string fn); //Scans one line of the field in a discrete fashion, executing a MATLAB function at each point, then plotting the return value of the function
    
	bool save(bool _is_auto, bool _is_update); //Save current scan

	float64 ** get_data(){ return disp_data;} //Return a pointer to the current scan data set

	void set_disp_data(int num, int dir); //Set which scan data set to display (num = 0 for unfiltered, num = 1 for filtered, dir = 1 for forward scan, dir = 0 for reverse scan)

	float64* get_x_axis(){return x_axis;} //Return a pointer to the array of x axis values

	float64* get_y_axis(){return y_axis;} //Return a pointer to the array of y axis values

	void set_freq(double _freq){freq = _freq;} //Reset scan frequency without resetting data

	//void calibrate(double max); //Does a calibration scan for the x and y piezos

	//Tip position (in volts)
	double x_tip;
	double y_tip;

	//Position of unrotated scan area (in volts)
	double x_min;
	double x_max;
	double y_min;
	double y_max;

	//Pointers that point to the min and max z value for the current scan selected
	double* z_min;
	double* z_max;

	//Center position of scan (in volts)
	double x_center;
	double y_center;

	//Scan size in x and y
	int nx_step;
	int ny_step;

	//Boundaries of allowed scan area, set by piezo limitations (in volts)
	double x_min_scan;
	double x_max_scan;
	double y_min_scan;
	double y_max_scan;

	//Rotation of scan field (in radians)
	double theta;

	//Boolean variables
	bool is_tip_thread; //Thread is open that moves the tip
	bool is_aborted; //Scan has been aborted
	bool is_auto; //Scan is being automatically saved
	bool is_update; //Scan is being saved as a real-time update of the current scan

	HANDLE tip_thread; //Thread that handles moving the tip

	HANDLE scan_save_thr; //Thread for saving a scan

	bool is_scan_thr; //Thread for saving a scan is active

	HWND hInfo;  //Handle of scan info window
	HWND hComment; //Handle of comment window

	void set_info(HWND hwnd){ hInfo = hwnd;} //Set the window handle for the scan info window
	void set_info_comment(HWND hwnd) {hComment = hwnd;} //Set the window handle for the comment window in the scan info window

	void filter(float64 ** raw_data, float64 ** filtered_data, int line_num); //Filter the data passed by subtracting off a best fit plane

	//Temporary variables that store the next position the tip has been moved to by the user
	double tip_x;
	double tip_y;

	float64 ** disp_data; //Pointer to data selected for display in the MDIGraph_Scan window

	//Pointers to values of x and y axes
	float64* x_axis;
	float64* y_axis;

	double pi;

	//Scan speed in points/second
	double freq;
	
	//Array that stores minimum and maximum z values for all 4 current data sets (filtered/unfiltered and forward/reverse)
	double min_max[8];

	//Array the stores minimum and maximum z values for all other channel data sets
	double ch_min_max[28]; //7 channels, each with a min/max and forward/reverse (index 0 - 13, forward scan, 14-27 reverse scan)

	//Pointers to 4 data sets based on current scan information (for Ch0, topography)
	float64 ** data_plot;
	float64 ** data_plot_rev;

	float64 ** data_filter;
	float64 ** data_filter_rev;

	//Pointers to data for other channels (Ch1-Ch7)
	float64** ch_data[7];
	float64** ch_data_rev[7];
    
    float64** counter_data[7];
	float64** counter_data_rev[7];

	//NI DAC handles for performing the scan and reading the data during a scan
	TaskHandle scant;
	TaskHandle readv;

	void update_scan_info(); //Update the current scan information to the database

	bool is_current_scan_saved; //True if current scan has been saved to the SQL database (not current scan)

	int num_scan_ch; //Number of channels to read in a scan
	int num_selected_ch; //Current selected channel number
	bool is_scan_ch[8]; //Store which of the 8 input channels are read during a scan
	std::string scan_ch_label[8]; //Labels for each scan channel

	void set_gate(bool val); //Turns gate on and off
	void set_gate_voltage(float voltage); //Turns gate on and off

	bool gate_state; //True, gate is on

	float gate_volt; //Tip gate voltage

	double plane_z(double x, double y); //Get value for plane fit if active

	planeInfo* _planeInfo;
	
	DAC* _DAC;

	void set_plane_info_ptr(planeInfo* pIptr){_planeInfo = pIptr;}
	
	void set_DAC_ptr(DAC* DACptr){_DAC = DACptr;}
    
    double max_tip_velocity; //in volts/sec
	double max_tip_accel; //in volts/sec^2
    std::string scan_save_dir;
    
    std::string MySQL_host;
    std::string MySQL_login;
    std::string MySQL_password;
    std::string MySQL_dbase;

    std::string comment;
    std::string currscan_fname;
    std::string currscan_pic;
    
	HANDLE get_current_z(); //Measure the current z output of the feedback box for plane fitting
	double current_z; //Current measured z value from get_current_z function
	HANDLE getz_thread;
	bool is_get_current_z_thread;
	HWND dlg_hwnd; //Window handle for dialog box requesting get_current_z value

    
    //DAC channel addresses
     std::string x_chan;
      std::string y_chan;
       std::string z_chan;
       std::string z_fdbk_chan;
       std::string extra_chan;
       
//function pointer to update scan info
       void (*update_scan_ptr)();
       // void set_update_scan_ptr(void (*ptr)()){update_scan_ptr = ptr;}
	   void set_update_scan_ptr(void(*ptr)()) { update_scan_ptr = ptr; }

       void get_laser_position(); //Get the current voltages on the laser galvo mirrors
       void set_laser_position(double x_laser_pos,double y_laser_pos);

       double laser_x;
       double laser_y;
       double laser_x_start;
       double laser_y_start;
               
       double laser_x_cal; //Calibration from laser scan voltage to MCL scan voltage
       double laser_y_cal;
       
	   // added to adapt to the new mex file format (Chang Jin 12/7/21)
       int laser_x_cal_index; 
       int laser_y_cal_index;

       double laser_handle_x; //Handle to text box defining laser position in ImageScan window
       double laser_handle_y;
       
	   // added to adapt to the new mex file format (Chang Jin 12/7/21)
	   int laser_handle_x_index; 
       int laser_handle_y_index;

       double MCL_x_cal;
       double MCL_y_cal;
       
	   // added to adapt to the new mex file format (Chang Jin 12/7/21)
	   int MCL_x_cal_index;
       int MCL_y_cal_index;

       void set_tracking(double x_center, double y_center); //Recenter tip and scan area based on tracking information
       bool pulse_seq; //If true, do a scan where a pulse sequence is run at each point
       
        TaskHandle scan_laser;
         TaskHandle pulse_train;
          TaskHandle counter_in;
          
          TaskHandle pulse_train2;
          TaskHandle counter_in2;
          
          uInt32 counter_val;
          
          bool is_matlab_data;
          bool is_measuring_matlab;
		  int num_matlab_chan;
          //double matlab_data[4];
         double* matlab_data; // define pointer so matlab_data can be dynamically allocated later

          void move_tip_laser(double dx, double dy,double x_l,double y_l);

		  
       
};
#endif __SCAN_H