#ifndef _HANDLES_H
#define _HANDLES_H

class handles
{
public:
	double x_tip_position;
    double y_tip_position;
    
    double x_scan_size;
    double y_scan_size;
    
    double x_scan_center;
    double y_scan_center;
    
    double scan_speed;
    
    double x_points;
    double y_points;
    
    double snap_plane_handle;
    
    double start_scan_handle;
    double stop_scan_handle;
    
    double start_approach_handle;
    double stop_approach_handle;
    
    double start_graph_handle;
    double stop_graph_handle;
    
    double scan_axes_handle;
    double scan_grid_handle;
    double cur_line_handle;
    
    double tip_position_x_handle;
    double tip_position_y_handle;
    
    //Menu handles
    double channel_item[8];
    
    double input_channel_item;
    double forward_item;
    double reverse_item;
    double filtered_item;
    double unfiltered_item;
    //double grid_line_item;
   // double vary_colorbar_item;
    double tip_position_item;
    double invert_colorbar_item;
    
    //Input channel dialog handles
    double input_channel_dialog_handle;
    double ch_checkbox[8];
    double ch_edit[8];
    
    //Plane set dialog box handles
    double plane_x_edit;
    double plane_y_edit;
    double plane_z_edit;
    double plane_listbox;
    double plane_offset_edit;
    double plane_a_text;
    double plane_b_text;
    double plane_c_text;
    double plane_r2_text;
    
    double MCL_x;
    double MCL_y;
    double MCL_z;
    double z_in_handle;
    
    CSerial Micronix_serial;

	double mic_xpos;
	double mic_ypos;
	double mic_zpos;
	double mic_port_status;
	double mic_figure;
	double mic_debug1;
	double mic_debug2;
	double mic_debug3;
	double mic_radio_x;
	double mic_radio_y;
	double mic_radio_z;
	double mic_n_steps;
	double mic_feedback_type_x;
	double mic_feedback_type_y;
	double mic_feedback_type_z;
	double mic_command_window;

	double phase_volt;
	double phase_deg;
	double phase_axes;
	double phase_conversion;
};


#endif __HANDLES_H