#include "mex.h"
#include <windows.h>
#include <stdio.h>
#include <process.h>
#include <string>
#include <vector>
#include "NIDAQmx.h"
#include <math.h>
// struct clock_line
// {
//     std::string logical_name;
//     std::string physical_name;
//     int rate;
//
// };

std::vector<TaskHandle> th_static;
std::vector<int32> error_codes;
//std::vector<clock_line> clock_lines;
uInt64 write_timeout = 10;
uInt64 read_timeout = 10;
HANDLE diff_thr;
bool is_diff_thr = false;

TaskHandle thandle;

int find_task_num(std::string task_name)
{
    for(int i = 0; i < th_static.size(); i++)
    {
        char curr_task[100];
        DAQmxGetTaskName(th_static[i], curr_task, 100);
        
        if(task_name == std::string(curr_task)) return i;
        
    }
    
    return -1;
    
}

void difference_thread()
{
    int n_samps = 10e3;
    
    DAQmxCreateTask("TimeTrace",&thandle);
    
    int error = DAQmxCreateCICountEdgesChan(thandle,"/PXI1Slot2/Ctr2","",DAQmx_Val_Rising,1e6,DAQmx_Val_ExtControlled);
    if(error != 0) error_codes.push_back(error);
    
    
    error = DAQmxSetCICountEdgesTerm(thandle,"/PXI1Slot2/Ctr2","/PXI1Slot2/PFI0");
    if(error != 0) error_codes.push_back(error);
    
    
    error = DAQmxCfgSampClkTiming(thandle,"/PXI1Slot2/100kHzTimebase",100e3,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samps);
    if(error != 0)  error_codes.push_back(error);
    
    
    
    TaskHandle out_handle;
    DAQmxCreateTask("Out",&out_handle);
    
    DAQmxCreateAOVoltageChan(out_handle,"PXI1Slot2/ao3","",-10,10,DAQmx_Val_Volts,NULL);
    
    uInt32* BufferData = new uInt32[n_samps];
    
    while(is_diff_thr)
    {
        
        
        
        
        int32 samps_read;
        
        error = DAQmxReadCounterU32(thandle,n_samps,DAQmx_Val_WaitInfinitely,BufferData,n_samps,&samps_read,NULL);
        if(error != 0) error_codes.push_back(error);
        
        DAQmxStopTask(thandle);
        DAQmxClearTask(thandle);
        
        
        
        float64 out[1] = {(BufferData[n_samps-1] - 1e6)/((float)100)};
        
        DAQmxWriteAnalogF64(out_handle, 1, 1, 10, DAQmx_Val_GroupByChannel , out, NULL, NULL);
        
        DAQmxStopTask(out_handle);
        DAQmxClearTask(out_handle);
        
        
        if(is_diff_thr == false)
        {
            break;
        }
        
    }
    
    
    delete [] BufferData;
    
    return;
    
    
    
}

// int find_clock_num(std::string clock_name)
// {
//     for(int i = 0; i < clock_lines.size(); i++)
//     {
//        if(clock_name == clock_lines[i].logical_name) return i;
//     }
//
//     return -1;
//
// }

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
    
    
    if(func_name == "init" && nargs == 0)
    {
        MessageBox(0,"Yes",0,0);
    }
    else if(func_name == "WriteAnalogOutVoltage" && nargs == 4)
    {
        int32 error;
        char dev[100];
        mxGetString(prhs[1],dev,100);
        std::string device(dev);
        
        double value =  mxGetScalar(prhs[2]);
        double min = mxGetScalar(prhs[3]);
        double max = mxGetScalar(prhs[4]);
        
//          std::string task_name("Counter");
//
//          int i = find_task_num(task_name);
//          if(i != -1)
//          {
//              MessageBox(0,"Y",0,0);
//              //Scan is running, wait until scan is done
//             error = DAQmxWaitUntilTaskDone(th_static[i],-1);
//              if(error != 0) error_codes.push_back(error);
//          }
        
        int32 write;
        TaskHandle ao_th;
        
        double out[2];
        out[0] = value;
        out[1] = value;
        
        DAQmxCreateTask("",&ao_th);
        
        
        
        error = DAQmxCreateAOVoltageChan(ao_th,device.c_str(),"",min,max,DAQmx_Val_Volts,NULL);
        if(error != 0) error_codes.push_back(error);
        
        error = DAQmxCfgSampClkTiming(ao_th,"",1000,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,2);
        if(error != 0) error_codes.push_back(error);
        
        error = DAQmxWriteAnalogF64(ao_th, 2, 1, 600, DAQmx_Val_GroupByScanNumber, out, &write, NULL);
        if(error != 0) error_codes.push_back(error);
        
        error = DAQmxWaitUntilTaskDone(ao_th,600.0);
        if(error != 0) error_codes.push_back(error);
        
        error = DAQmxStopTask(ao_th);
        if(error != 0) error_codes.push_back(error);
        
        error = DAQmxClearTask(ao_th);
        if(error != 0) error_codes.push_back(error);
    }
    else if(func_name == "CreateTask" && nargs == 1)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        bool does_task_exist = false;
        
        if(find_task_num(task_name) != -1)
        {
            does_task_exist = true;
        }
        
        if(does_task_exist)
        {
            // MessageBox(0,"Task already exists.",0,0);
        }
        else
        {
            TaskHandle th_new;
            error = DAQmxCreateTask(task_name.c_str(),&th_new);
            if(error != 0) error_codes.push_back(error);
            
            th_static.push_back(th_new);
        }
        
    }
    else if(func_name == "ClearTask" && nargs == 1)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        bool does_task_exist = false;
        
        int i = find_task_num(task_name);
        if(i != -1)
        {
            does_task_exist = true;
            error = DAQmxStopTask(th_static[i]);
            if(error != 0) error_codes.push_back(error);
            error = DAQmxClearTask(th_static[i]);
            if(error != 0) error_codes.push_back(error);
            
            th_static.erase(th_static.begin()+i);
        }
        
        if(does_task_exist)
        {
            // MessageBox(0,"Task deleted.",0,0);
        }
        else
        {
            // MessageBox(0,"Task does not exist. (ClearTask)",0,0);
        }
        
    }
    else if(func_name == "ClearAllTasks" && nargs == 0)
    {
        int32 error;
        for(int i = 0; i < th_static.size(); i++)
        {
            error = DAQmxStopTask(th_static[i]);
            if(error != 0) error_codes.push_back(error);
            error = DAQmxClearTask(th_static[i]);
            if(error != 0) error_codes.push_back(error);
        }
        th_static.clear();
        
    }
    else if(func_name == "StartTask" && nargs == 1)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        bool does_task_exist = false;
        
        int i = find_task_num(task_name);
        if(i != -1)
        {
            does_task_exist = true;
            error = DAQmxStartTask(th_static[i]);
            if(error != 0) error_codes.push_back(error);
        }
        
        if(!does_task_exist)
        {
            //MessageBox(0,"Task does not exist. (StartTask)",0,0);
        }
    }
    else if(func_name == "StopTask" && nargs == 1)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        bool does_task_exist = false;
        
        int i = find_task_num(task_name);
        if(i != -1)
        {
            does_task_exist = true;
            error =  DAQmxStopTask(th_static[i]);
            if(error != 0) error_codes.push_back(error);
        }
        
        if(!does_task_exist)
        {
            //MessageBox(0,"Task does not exist. (StopTask)",0,0);
        }
    }
    else if(func_name == "IsTaskDone" && nargs == 1)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        bool does_task_exist = false;
        
        int i = find_task_num(task_name);
        if(i != -1)
        {
            does_task_exist = true;
            bool32 is_done;
            error =  DAQmxIsTaskDone(th_static[i],&is_done);
            if(error != 0) error_codes.push_back(error);
            
            plhs[0] = mxCreateDoubleScalar(is_done);
            nlhs = 1;
        }
        else
        {
            plhs[0] = mxCreateDoubleScalar(1);
            nlhs = 1;
        }
        
        if(!does_task_exist)
        {
            // MessageBox(0,"Task does not exist. (IsTaskDone)",0,0);
        }
    }
    else if(func_name == "WaitUntilTaskDone" && nargs == 1)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        bool does_task_exist = false;
        
        int i = find_task_num(task_name);
        if(i != -1)
        {
            does_task_exist = true;
            bool32 is_done;
            error =  DAQmxWaitUntilTaskDone(th_static[i],read_timeout);
            if(error != 0) error_codes.push_back(error);
            if(error == -200560)
            {
                DAQmxStopTask(th_static[i]);
            }
        }
        
        if(!does_task_exist)
        {
            // MessageBox(0,"Task does not exist. (WaitUntilTaskDone)",0,0);
        }
    }
    else if(func_name == "NumErrors")
    {
        
        plhs[0] = mxCreateDoubleScalar(error_codes.size());
        nlhs = 1;
    }
    else if(func_name == "CheckErrorStatus")
    {
        std::string error_string;
        
        //Readout all error codes and reset error buffer
        for(int i = 0; i < error_codes.size(); i++)
        {
            char str[500];
            DAQmxGetErrorString(error_codes[i], str, 500);
            error_string += std::string(str);
            error_string += std::string("\n");
        }
        
        //return error strings delimited by "\n"
        
        plhs[0] = mxCreateString(error_string.c_str());
        
        error_codes.clear();
        
    }
//      else if(func_name == "addClockLine" && nargs == 3)
//      {
//         char lname[100];
//          mxGetString(prhs[1],lname,100);
//          std::string l_name(lname);
//
//          char pname[100];
//          mxGetString(prhs[1],pname,100);
//          std::string p_name(pname);
//
//          int rate =  mxGetScalar(prhs[3]);
//
//          clock_line new_clock;
//          new_clock.logical_name = l_name;
//          new_clock.physical_name = p_name;
//          new_clock.rate = rate;
//
//     }
    else if(func_name == "ConfigureClockOut" && nargs == 5)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        char cname[100];
        mxGetString(prhs[2],cname,100);
        std::string clock_name(cname);
        
        float64 clock_freq =  mxGetScalar(prhs[3]);
        float64 duty_cycle =  mxGetScalar(prhs[4]);
        uInt64 counter_out_samples =  mxGetScalar(prhs[5]);
        
        int tn = find_task_num(task_name);
        // int cn = find_clock_num(clock_name);
        
        if(tn == -1)
        {
            MessageBox(0,"No Task1",0,0);
            
        }
        else
        {
            
            float64 initial_delay=0.0;
            
            error = DAQmxCreateCOPulseChanFreq(th_static[tn],clock_name.c_str(),"",DAQmx_Val_Hz,DAQmx_Val_Low,initial_delay,clock_freq,duty_cycle);
            if(error != 0) error_codes.push_back(error);
            
            error = DAQmxCfgImplicitTiming(th_static[tn],DAQmx_Val_ContSamps,counter_out_samples);
            if(error != 0) error_codes.push_back(error);
            
        }
        
    }
    else if(func_name == "ConfigureVoltageOut" && nargs == 9)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        char dname[100];
        mxGetString(prhs[2],dname,100);
        std::string dev_name(dname);
        
        uInt64 lines =  mxGetScalar(prhs[3]);
        uInt64 voltages_per_line =  mxGetScalar(prhs[4]);
        
        char cname[100];
        mxGetString(prhs[5],cname,100);
        std::string clock_name(cname);
        
        float64 clock_rate =  mxGetScalar(prhs[6]);
        float64 minV =  mxGetScalar(prhs[7]);
        float64 maxV =  mxGetScalar(prhs[8]);
        
        float64* out = (float64*)mxGetPr(prhs[9]);
        
        
        int tn = find_task_num(task_name);
        
        
        if(tn == -1)
        {
            MessageBox(0,"No Task2",0,0);
        }
        else
        {
            error = DAQmxCreateAOVoltageChan(th_static[tn],dev_name.c_str(),"",minV,maxV,DAQmx_Val_Volts,NULL);
            if(error != 0) error_codes.push_back(error);
            
            error = DAQmxCfgSampClkTiming(th_static[tn],clock_name.c_str(),clock_rate,DAQmx_Val_Rising, DAQmx_Val_FiniteSamps,voltages_per_line);
            if(error != 0) error_codes.push_back(error);
            
            int auto_start = 0;
            int32 write = 0;
            error = DAQmxWriteAnalogF64(th_static[tn],voltages_per_line,auto_start,write_timeout,DAQmx_Val_GroupByChannel,out,&write,NULL);
            if(error != 0) error_codes.push_back(error);
        }
        
    }
    else if(func_name == "ConfigureVoltageOutCont" && nargs == 9)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        char dname[100];
        mxGetString(prhs[2],dname,100);
        std::string dev_name(dname);
        
        uInt64 lines =  mxGetScalar(prhs[3]);
        uInt64 bufferSize =  mxGetScalar(prhs[4]);
        
        char cname[100];
        mxGetString(prhs[5],cname,100);
        std::string clock_name(cname);
        
        float64 clock_rate =  mxGetScalar(prhs[6]);
        float64 minV =  mxGetScalar(prhs[7]);
        float64 maxV =  mxGetScalar(prhs[8]);
        
        float64* out = (float64*)mxGetPr(prhs[9]);
        
        
        int tn = find_task_num(task_name);
        
        
        if(tn == -1)
        {
            MessageBox(0,"No Task2",0,0);
        }
        else
        {
            DAQmxStopTask(th_static[tn]);
            DAQmxClearTask(th_static[tn]);
            
            error = DAQmxCreateAOVoltageChan(th_static[tn],dev_name.c_str(),"",minV,maxV,DAQmx_Val_Volts,NULL);
            if(error != 0) error_codes.push_back(error);
            
            error = DAQmxCfgSampClkTiming(th_static[tn],clock_name.c_str(),clock_rate,DAQmx_Val_Rising, DAQmx_Val_ContSamps, bufferSize);
            if(error != 0) error_codes.push_back(error);
            
            int auto_start = 0;
            error = DAQmxWriteAnalogF64(th_static[tn],bufferSize,auto_start,write_timeout,DAQmx_Val_GroupByChannel,out,NULL,NULL);
            if(error != 0) error_codes.push_back(error);
        }
        
    }
    else if(func_name == "ReadAnalogInVoltage" && nargs == 1)
    {
        
        char dev[100];
        mxGetString(prhs[1],dev,100);
        std::string device(dev);
        
        int n_samp = 50;
        int32 n_samp_read;
        TaskHandle ai_handle;
        
        float64* values;
        values = new float64[n_samp];
        
        DAQmxCreateTask("",&ai_handle);
        DAQmxCreateAIVoltageChan(ai_handle, device.c_str(), "", DAQmx_Val_NRSE, -10, 10, DAQmx_Val_Volts, NULL);
        DAQmxCfgSampClkTiming(ai_handle,"",100000,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samp);
        
        int32 error = DAQmxReadAnalogF64(ai_handle, n_samp, DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByChannel, values, n_samp, &n_samp_read, NULL);
        
        double avg_voltage;
        
        for (int i = 0; i < n_samp; i++) {
            avg_voltage = avg_voltage + values[i];
        }
        avg_voltage = avg_voltage/n_samp;
        
        mxArray* avg_value_mx;
        avg_value_mx = mxCreateDoubleScalar(avg_voltage);
        plhs[0] = avg_value_mx;
        
        DAQmxStopTask(ai_handle);
        DAQmxClearTask(ai_handle);
        delete [] values;
        
    }
    else if(func_name == "ReadAnalogInVoltageStd" && nargs == 1)
    {
        
        char dev[100];
        mxGetString(prhs[1],dev,100);
        std::string device(dev);
        
        int n_samp = 500;
        int32 n_samp_read;
        TaskHandle ai_handle;
//
        float64* values;
        values = new float64[n_samp];
        
        DAQmxCreateTask("",&ai_handle);
        DAQmxCreateAIVoltageChan(ai_handle, device.c_str(), "", DAQmx_Val_NRSE, -10, 10, DAQmx_Val_Volts, NULL);
        DAQmxCfgSampClkTiming(ai_handle,"",100000,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samp);
        
        int32 error = DAQmxReadAnalogF64(ai_handle, n_samp, DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByChannel, values, n_samp, &n_samp_read, NULL);
        
        double avg_voltage = 0;
        double std_voltage = 0;
        
        for (int i = 0; i < n_samp; i++) {
            avg_voltage = avg_voltage + values[i];
        }
        avg_voltage = avg_voltage/n_samp;
        
        for (int i = 0; i < n_samp; i++) {
            std_voltage = std_voltage + pow(values[i]-avg_voltage, 2);
        }
        std_voltage = sqrt(std_voltage/(n_samp-1));
        
        mxArray* avg_value_mx;
        mxArray* std_value_mx;
        avg_value_mx = mxCreateDoubleScalar(avg_voltage);
        std_value_mx = mxCreateDoubleScalar(std_voltage);
        
        plhs[0] = mxCreateDoubleScalar(avg_voltage);
        plhs[1] = mxCreateDoubleScalar(std_voltage);
        
        nlhs = 2;
        
        DAQmxStopTask(ai_handle);
        DAQmxClearTask(ai_handle);
        delete [] values;
        
    }
    else if(func_name == "ReadAnalogInVoltageDiff" && nargs == 1)
    {
        
        char dev[100];
        mxGetString(prhs[1],dev,100);
        std::string device(dev);
        
        int n_samp = 500;
        int32 n_samp_read;
        TaskHandle ai_handle;
        
        float64* values;
        values = new float64[n_samp];
        
        DAQmxCreateTask("",&ai_handle);
        DAQmxCreateAIVoltageChan(ai_handle, device.c_str(), "", DAQmx_Val_Diff, -10, 10, DAQmx_Val_Volts, NULL);
        DAQmxCfgSampClkTiming(ai_handle,"",100000,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samp);
        
        int32 error = DAQmxReadAnalogF64(ai_handle, n_samp, DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByChannel, values, n_samp, &n_samp_read, NULL);
        
        double avg_voltage;
        
        for (int i = 0; i < n_samp; i++) {
            avg_voltage = avg_voltage + values[i];
        }
        avg_voltage = avg_voltage/n_samp;
        
        mxArray* avg_value_mx;
        avg_value_mx = mxCreateDoubleScalar(avg_voltage);
        plhs[0] = avg_value_mx;
        
        DAQmxStopTask(ai_handle);
        DAQmxClearTask(ai_handle);
        delete [] values;
        
    }
    else if(func_name == "ReadAnalogInVoltageTransportDiff" && nargs == 4)
    {
        
        char dev[100];
        mxGetString(prhs[1],dev,100);
        std::string device(dev);
        
        double rate = mxGetScalar(prhs[2]);
        int n_samps = mxGetScalar(prhs[3]);
        double range = mxGetScalar(prhs[4]);
        
        int32 n_samps_read;
        TaskHandle ai_handle;
        
        float64* values;
        values = new float64[n_samps];
        
        DAQmxCreateTask("",&ai_handle);
        DAQmxCreateAIVoltageChan(ai_handle, device.c_str(), "", DAQmx_Val_Diff, -range, range, DAQmx_Val_Volts, NULL);
        DAQmxCfgSampClkTiming(ai_handle,"",rate,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samps);
        
        int32 error = DAQmxReadAnalogF64(ai_handle, n_samps, DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByChannel, values, n_samps, &n_samps_read, NULL);
        
        mxArray* voltage_samples;
        mwSize dims[2] = {1,n_samps};
        voltage_samples = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
        double* voltage_samples_ptr = mxGetPr(voltage_samples);
        
        for(int i = 0; i < n_samps; i++)
        {
            voltage_samples_ptr[i] = values[i];
        }
        
        plhs[0] = voltage_samples;
        
        DAQmxStopTask(ai_handle);
        DAQmxClearTask(ai_handle);
        delete [] values;
        
        
        
    }
    else if(func_name == "ReadAnalogInVoltageSlow" && nargs == 1)
    {
        
        char dev[100];
        mxGetString(prhs[1],dev,100);
        std::string device(dev);
        
        int n_samp = 50;
        int32 n_samp_read;
        TaskHandle aislow_handle;
        
        float64* values;
        values = new float64[n_samp];
        
        DAQmxCreateTask("",&aislow_handle);
        DAQmxCreateAIVoltageChan(aislow_handle, device.c_str(), "", DAQmx_Val_RSE, -10, 10, DAQmx_Val_Volts, NULL);
        DAQmxCfgSampClkTiming(aislow_handle,"",100,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samp);
        
        int32 error = DAQmxReadAnalogF64(aislow_handle, n_samp, DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByChannel, values, n_samp, &n_samp_read, NULL);
        
        double avg_voltage;
        
        for (int i = 0; i < n_samp; i++) {
            avg_voltage = avg_voltage + values[i];
        }
        avg_voltage = avg_voltage/n_samp;
        
        mxArray* avg_value_mx;
        avg_value_mx = mxCreateDoubleScalar(avg_voltage);
        plhs[0] = avg_value_mx;
        
        DAQmxStopTask(aislow_handle);
        DAQmxClearTask(aislow_handle);
        delete [] values;
        
    }
    else if(func_name == "ConfigureCounterIn" && nargs == 6)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        char counter_name[100];
        mxGetString(prhs[2],counter_name,100);
        std::string counter_device(counter_name);
        
        char counter_line_name[100];
        mxGetString(prhs[3],counter_line_name,100);
        std::string counter_line_physical(counter_line_name);
        
        char clock_line_name[100];
        mxGetString(prhs[4],clock_line_name,100);
        std::string clock_line_physical(clock_line_name);
        
        float64 clock_rate =  mxGetScalar(prhs[5]);
        uInt64 n_samps =  mxGetScalar(prhs[6]);
        
        int tn = find_task_num(task_name);
        
        
        if(tn == -1)
        {
            MessageBox(0,"No Task3",0,0);
        }
        else
        {
            error = DAQmxCreateCICountEdgesChan(th_static[tn],counter_device.c_str(),"",DAQmx_Val_Rising,0,DAQmx_Val_CountUp);
            if(error != 0) error_codes.push_back(error);
            
            error = DAQmxSetCICountEdgesTerm(th_static[tn],counter_device.c_str(),counter_line_physical.c_str());
            if(error != 0) error_codes.push_back(error);
            
            float64 freq;
            
            if(clock_rate <= 0)
            {
                freq = 1000;
            }
            else
            {
                freq = clock_rate;
            }
            
            error = DAQmxCfgSampClkTiming(th_static[tn],clock_line_physical.c_str(),freq,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samps);
            if(error != 0) error_codes.push_back(error);
//
//                error =  DAQmxSetPauseTrigType(th_static[tn], DAQmx_Val_DigLvl );
//              if(error != 0) error_codes.push_back(error);
//
//               error = DAQmxSetDigLvlPauseTrigSrc(th_static[tn], "/PXI1Slot2/PFI2");
//                  if(error != 0) error_codes.push_back(error);
//
//                 error =  DAQmxSetDigLvlPauseTrigWhen(th_static[tn], DAQmx_Val_High );
//                  if(error != 0) error_codes.push_back(error);
//
        }
        
        
        
    }
    else if(func_name == "ConfigureCounterUpDownIn" && nargs == 6)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        char counter_name[100];
        mxGetString(prhs[2],counter_name,100);
        std::string counter_device(counter_name);
        
        char counter_line_name[100];
        mxGetString(prhs[3],counter_line_name,100);
        std::string counter_line_physical(counter_line_name);
        
        char clock_line_name[100];
        mxGetString(prhs[4],clock_line_name,100);
        std::string clock_line_physical(clock_line_name);
        
        float64 clock_rate =  mxGetScalar(prhs[5]);
        uInt64 n_samps =  mxGetScalar(prhs[6]);
        
        int tn = find_task_num(task_name);
        
        
        if(tn == -1)
        {
            MessageBox(0,"No Task3",0,0);
        }
        else
        {
            error = DAQmxCreateCICountEdgesChan(th_static[tn],counter_device.c_str(),"",DAQmx_Val_Rising,1e9,DAQmx_Val_ExtControlled);
            if(error != 0) error_codes.push_back(error);
            
            error = DAQmxSetCICountEdgesTerm(th_static[tn],counter_device.c_str(),counter_line_physical.c_str());
            if(error != 0) error_codes.push_back(error);
            
            float64 freq;
            
            if(clock_rate <= 0)
            {
                freq = 1000;
            }
            else
            {
                freq = clock_rate;
            }
            
            error = DAQmxCfgSampClkTiming(th_static[tn],clock_line_physical.c_str(),freq,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samps);
            if(error != 0) error_codes.push_back(error);
//
//                error =  DAQmxSetPauseTrigType(th_static[tn], DAQmx_Val_DigLvl );
//              if(error != 0) error_codes.push_back(error);
//
//               error = DAQmxSetDigLvlPauseTrigSrc(th_static[tn], "/PXI1Slot2/PFI2");
//                  if(error != 0) error_codes.push_back(error);
//
//                 error =  DAQmxSetDigLvlPauseTrigWhen(th_static[tn], DAQmx_Val_High );
//                  if(error != 0) error_codes.push_back(error);
//
        }
        
        
        
    }
    else if(func_name == "GetAvailableSamples" && nargs == 1)
    {
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        int tn = find_task_num(task_name);
        
        
        if(tn == -1)
        {
            //MessageBox(0,"No Task4",0,0);
            plhs[0] = mxCreateDoubleScalar(0);
            nlhs = 1;
        }
        else
        {
            uInt32 data;
            error = DAQmxGetReadAvailSampPerChan(th_static[tn],&data);
            if(error != 0) error_codes.push_back(error);
            
            plhs[0] = mxCreateDoubleScalar(data);
            nlhs = 1;
        }
        
        
    }
    else if(func_name == "ReadCounterBuffer" && nargs == 2)
    {
        
        int32 error;
        char tname[100];
        mxGetString(prhs[1],tname,100);
        std::string task_name(tname);
        
        int tn = find_task_num(task_name);
        
        uInt64 n_samps =  mxGetScalar(prhs[2]);
        
        if(tn == -1)
        {
            MessageBox(0,"No Task5",0,0);
            
        }
        else
        {
            uInt32* BufferData = new uInt32[n_samps];
            int32 samps_read;
            error = DAQmxReadCounterU32(th_static[tn],n_samps,DAQmx_Val_WaitInfinitely,BufferData,n_samps,&samps_read,NULL);
            if(error != 0) error_codes.push_back(error);
            
            mxArray* buffer_data;
            
            mwSize dims[2] = {1,n_samps};
            
            buffer_data = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
            
            double* buffer_data_ptr = mxGetPr(buffer_data);
            
            for(int i = 0; i < n_samps; i++)
            {
                buffer_data_ptr[i] = BufferData[i];
            }
            
            plhs[0] = buffer_data;
            plhs[1] = mxCreateDoubleScalar(samps_read);
            nlhs = 2;
            
            delete [] BufferData;
        }
    }
    else if(func_name == "ResetDevice" && nargs == 1)
    {
        int32 error;
        char devname[100];
        mxGetString(prhs[1],devname,100);
        std::string dev_name(devname);
        
        error = DAQmxResetDevice(dev_name.c_str());
        if(error != 0) error_codes.push_back(error);
        
    }
    else if(func_name == "test" && nargs == 1)
    {
        mxArray* buffer_data;
        int n_samps = 10;
        
        mwSize dims[2] = {1,n_samps};
        
        buffer_data = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
        
        double* buffer_data_ptr = mxGetPr(buffer_data);
        
        for(int i = 0; i < n_samps; i++)
        {
            buffer_data_ptr[i] = i;
        }
        
        plhs[0] = buffer_data;
        plhs[1] = mxCreateDoubleScalar(2);
        nlhs = 2;
    }
    else if(func_name == "GetTimeTrace" && nargs == 0)
    {
        
        TaskHandle thandle;
        DAQmxCreateTask("TimeTrace",&thandle);
        
        int n_samps = 500e3;
        
        int error = DAQmxCreateCICountEdgesChan(thandle,"/PXI1Slot2/Ctr2","",DAQmx_Val_Rising,0,DAQmx_Val_CountUp);
        if(error != 0) error_codes.push_back(error);
        
        
        error = DAQmxSetCICountEdgesTerm(thandle,"/PXI1Slot2/Ctr2","/PXI1Slot2/PFI0");
        if(error != 0) error_codes.push_back(error);
        
        
        error = DAQmxCfgSampClkTiming(thandle,"/PXI1Slot2/100kHzTimebase",100e3,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samps);
        if(error != 0)  error_codes.push_back(error);
        
        
        uInt32* BufferData = new uInt32[n_samps];
        
        
        int32 samps_read;
        
        error = DAQmxReadCounterU32(thandle,n_samps,DAQmx_Val_WaitInfinitely,BufferData,n_samps,&samps_read,NULL);
        if(error != 0) error_codes.push_back(error);
        
        
        mxArray* buffer_data;
        
        mwSize dims[2] = {1,n_samps};
        
        buffer_data = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
        
        double* buffer_data_ptr = mxGetPr(buffer_data);
        
        for(int i = 0; i < n_samps; i++)
        {
            buffer_data_ptr[i] = BufferData[i];
        }
        
        plhs[0] = buffer_data;
        plhs[1] = mxCreateDoubleScalar(samps_read);
        nlhs = 2;
        
        delete [] BufferData;
        
        DAQmxStopTask(thandle);
        DAQmxClearTask(thandle);
        
        
    }
    else if(func_name == "GetDifference" && nargs == 0)
    {
        
        if(is_diff_thr == true)
        {
            WaitForSingleObject(diff_thr,3000);
            CloseHandle(diff_thr);
            is_diff_thr = false;
            Sleep(1000);
        }
        
        is_diff_thr = true;
        diff_thr = CreateThread(NULL,0,(LPTHREAD_START_ROUTINE)&difference_thread,NULL,NULL,NULL);
        
    }
    else if(func_name == "StopDifference" && nargs == 0)
    {
        
        is_diff_thr = false;
        DAQmxTaskControl (thandle, DAQmx_Val_Task_Abort );
        
        WaitForSingleObject(diff_thr,3000);
        CloseHandle(diff_thr);
        
        TaskHandle out_handle;
        DAQmxCreateTask("Out",&out_handle);
        
        DAQmxCreateAOVoltageChan(out_handle,"PXI1Slot2/ao3","",-10,10,DAQmx_Val_Volts,NULL);
        
        float64 out[1] = {0};
        
        DAQmxWriteAnalogF64(out_handle, 1, 1, 10, DAQmx_Val_GroupByChannel , out, NULL, NULL);
        
        DAQmxStopTask(out_handle);
        DAQmxClearTask(out_handle);
        
    }
    else if(func_name == "GetCounter" && nargs == 1)
    {
        //Read counter for time specified by argument
        TaskHandle thandle;
        DAQmxCreateTask("Cntr",&thandle);
        
        double count_time = mxGetScalar(prhs[1]);
        int n_samps = (int)( (double)(count_time)*(double)(100e3));
        
        int error = DAQmxCreateCICountEdgesChan(thandle,"/PXI1Slot2/Ctr2","",DAQmx_Val_Rising,0,DAQmx_Val_CountUp);
        
        
        error = DAQmxSetCICountEdgesTerm(thandle,"/PXI1Slot2/Ctr2","/PXI1Slot2/PFI0");
        
        
        
        error = DAQmxCfgSampClkTiming(thandle,"/PXI1Slot2/100kHzTimebase",100e3,DAQmx_Val_Rising,DAQmx_Val_FiniteSamps,n_samps);
        
//              error =  DAQmxSetPauseTrigType(thandle, DAQmx_Val_DigLvl );
//              if(error != 0) error_codes.push_back(error);
//
//               error = DAQmxSetDigLvlPauseTrigSrc(thandle, "/PXI1Slot2/PFI2");
//                  if(error != 0) error_codes.push_back(error);
//
//                 error =  DAQmxSetDigLvlPauseTrigWhen(thandle, DAQmx_Val_High );
//                  if(error != 0) error_codes.push_back(error);
        
        uInt32* BufferData = new uInt32[n_samps];
        
        
        int32 samps_read;
        
        error = DAQmxReadCounterU32(thandle,n_samps,DAQmx_Val_WaitInfinitely,BufferData,n_samps,&samps_read,NULL);
        
        DAQmxWaitUntilTaskDone(thandle,DAQmx_Val_WaitInfinitely);
        DAQmxStopTask(thandle);
        
        mxArray* buffer_data;
        
        mwSize dims[2] = {1,1};
        
        buffer_data = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL);
        
        double* buffer_data_ptr = mxGetPr(buffer_data);
        
        
        buffer_data_ptr[0] = (double)(BufferData[n_samps - 1] - BufferData[0])/(double)(count_time);
        
        
        plhs[0] = buffer_data;
        
        nlhs = 1;
        
        delete [] BufferData;
        
        DAQmxStopTask(thandle);
        DAQmxClearTask(thandle);
        
    }
    else
    {
        MessageBox(0,"No functions called",0,0);
    }
    
    delete [] args;
    
    return;
}