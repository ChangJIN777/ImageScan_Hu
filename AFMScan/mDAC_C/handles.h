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
    
    // added to adapt to the new mex file format (Chang Jin 12/7/21)=========
    int x_tip_position_index;
    int y_tip_position_index;
        
    int x_scan_size_index;
    int y_scan_size_index;
        
    int x_scan_center_index;
    int y_scan_center_index;
        
    int scan_speed_index;
        
    int x_points_index;
    int y_points_index;
        
    int scan_axes_handle_index;
    int scan_grid_handle_index;
    int cur_line_handle_index;
        
    int tip_position_x_handle_index;
    int tip_position_y_handle_index;
        
    int start_scan_handle_index;
    int stop_scan_handle_index;
        
    int start_approach_handle_index;
    int stop_approach_handle_index;
        
    int snap_plane_handle_index;
        
    int stop_graph_handle_index;
    int start_graph_handle_index;
    // ======================================================================

    //Menu handles
    double channel_item[8];
    
    // added to adapt to the new mex file format (Chang Jin 12/7/21)
    int channel_item_indices[8];

    // ============================================================
    double input_channel_item;
    double forward_item;
    double reverse_item;
    double filtered_item;
    double unfiltered_item;
    //double grid_line_item;
   // double vary_colorbar_item;
    double tip_position_item;
    double invert_colorbar_item;
    
    // added to adapt to the new mex file format (Chang Jin 12/7/21) ====
    double input_channel_item_index;
    double forward_item_index;
    double reverse_item_index;
    double filtered_item_index;
    double unfiltered_item_index;
    //double grid_line_item;
   // double vary_colorbar_item;
    double tip_position_item_index;
    double invert_colorbar_item_index;
    // =====================================================================

    //Input channel dialog handles
    double input_channel_dialog_handle;
    double ch_checkbox[8];
    double ch_edit[8];
    // added to adapt to the new mex file format (Chang Jin 12/7/21)
    int input_channel_dialog_handle_index;
    int ch_checkbox_indices[8];
    int ch_edit_indices[8];

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
    
    // added to adapt to the new mex file format (Chang Jin 12/7/21) =========
    double plane_x_edit_index;
    double plane_y_edit_index;
    double plane_z_edit_index;
    double plane_listbox_index;
    double plane_offset_edit_index;
    double plane_a_text_index;
    double plane_b_text_index;
    double plane_c_text_index;
    double plane_r2_text_index;   
    // =======================================================================

    double MCL_x;
    double MCL_y;
    double MCL_z;
    double z_in_handle;
    
    // added to adapt to the new mex file format (Chang Jin 12/7/21) =========
    double MCL_x_index;
    double MCL_y_index;
    double MCL_z_index;
    double z_in_disp_handle_index;
    // =======================================================================

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
    
    // added to adapt to the new mex file format (Chang Jin 12/7/21) =========
    int phase_volt_index;
	int phase_deg_index;
	int phase_axes_index;

    // added to adapt to the new mex file format (Chang Jin 12/7/21) =========
    int mic_figure_index;
	int mic_port_status_index;
	int mic_xpos_index;
	int mic_ypos_index;
	int mic_zpos_index;
	int mic_debug1_index;
	int mic_debug2_index;
	int mic_debug3_index;
	int mic_radio_x_index;
	int mic_radio_y_index;
	int mic_radio_z_index;
	int mic_n_steps_index;
	int mic_feedback_type_x_index;
	int mic_feedback_type_y_index;
	int mic_feedback_type_z_index;
	int mic_command_window_index;
    // =======================================================================

};


#endif __HANDLES_H