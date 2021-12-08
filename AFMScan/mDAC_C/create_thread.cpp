#include "mex.h"
#include <windows.h>
#include <stdio.h>
#include <process.h>
#include "Madlib.h"


    double _hdl_x,_hdl_y,_hdl_z,_hdl_z_offset;
double move;
    int end_thread;
     UINT_PTR timer;
     int MCL_handle;
     
     double x_pos,y_pos,z_pos;
 
   

void update_readout()
{
     mxArray* x_value;
     mxArray* y_value;
     mxArray* z_value;
     char disp_str[50];
     
     
     sprintf_s(disp_str,50,"%.3f",x_pos);
     x_value = mxCreateString(disp_str);
     
     sprintf_s(disp_str,50,"%.3f",y_pos);
     y_value = mxCreateString(disp_str);
     
     sprintf_s(disp_str,50,"%.3f",z_pos);
     z_value = mxCreateString(disp_str);

     mexSet(_hdl_x,"String",x_value);  
     mexSet(_hdl_y,"String",y_value);  
     mexSet(_hdl_z,"String",z_value);  
     
     mxDestroyArray(x_value);
     mxDestroyArray(y_value);
     mxDestroyArray(z_value);
    
}

unsigned __stdcall SecondThreadFunc( void* pArguments )
{
    
    int k = 0;
    int n_avg = 10;
    
    double x_temp = 0;
    double y_temp = 0;
    double z_temp = 0;
    
    while ( !end_thread )
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
        
        
            x_pos = x_temp/(double)n_avg;
            y_pos = y_temp/(double)n_avg;
            z_pos = z_temp/(double)n_avg;
            
            Sleep(200);
    }
    
    _endthreadex( 0 );
    return 0;
} 

void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
     
{ 
    HANDLE hThread;
    unsigned threadID;

    int status;
    
     double x_pos_new,y_pos_new,z_pos_new;
     
      mxArray* z_value;
     char disp_str[50];
   
 
    
    move = 0;
   
    end_thread = 0;

    _hdl_x = mxGetScalar(prhs[0]);
    _hdl_y = mxGetScalar(prhs[1]);
    _hdl_z = mxGetScalar(prhs[2]);
    status = mxGetScalar(prhs[3]);
    move = mxGetScalar(prhs[4]);
     _hdl_z_offset = mxGetScalar(prhs[5]);
    
   
   
    

    if(status == 1)
    {
       
        
          x_pos = 0;
        y_pos = 0;
        z_pos = 0;
    
 
    
     MCL_handle = MCL_InitHandleOrGetExisting();
    

     
        hThread = (HANDLE)_beginthreadex( NULL, 0, &SecondThreadFunc, NULL, 0, &threadID );
       SetTimer(NULL,timer,100,(TIMERPROC)update_readout);
        
    }
    else if(status == 0)
    {
         KillTimer(NULL,timer);
         
          end_thread = 1;
          WaitForSingleObject(hThread,1000);
    
        CloseHandle( hThread );
       // MCL_ReleaseHandle(MCL_handle);
        // MCL_ReleaseAllHandles();
        /* Destroy the thread object. */
     
    }
    else if(status == 2)
    {
        
        // KillTimer(NULL,timer);
        /* Destroy the thread object. */
         end_thread = 1;
        WaitForSingleObject(hThread,1000);
        
       
        // x_pos = MCL_SingleReadN(1,MCL_handle);
         
          
         
        x_pos_new = x_pos + move;
         
        MCL_SingleWriteN(x_pos_new,1,MCL_handle);
        
        
        
        end_thread = 0;
         hThread = (HANDLE)_beginthreadex( NULL, 0, &SecondThreadFunc, NULL, 0, &threadID );
        //SetTimer(NULL,timer,1,(TIMERPROC)update_readout);
       
        
        
    }
    else if(status == 3)
    {
        
        // KillTimer(NULL,timer);
        /* Destroy the thread object. */
         end_thread = 1;
        WaitForSingleObject(hThread,1000);
        
        // y_pos = MCL_SingleReadN(2,MCL_handle);
         
        y_pos_new = y_pos + move;
         
        MCL_SingleWriteN(y_pos_new,2,MCL_handle);
        
        end_thread = 0;
         hThread = (HANDLE)_beginthreadex( NULL, 0, &SecondThreadFunc, NULL, 0, &threadID );
        //SetTimer(NULL,timer,1,(TIMERPROC)update_readout);
       
        
        
    }
    else if(status == 4)
    {
        
         KillTimer(NULL,timer);
        /* Destroy the thread object. */
         end_thread = 1;
        WaitForSingleObject(hThread,1000);
        
        // z_pos = MCL_SingleReadN(3,MCL_handle);
         
         printf("move=%.3f\n",move);
         
         
        z_pos_new = z_pos + move;
        printf("z_pos_new=%.3f\n",z_pos_new);
         
        MCL_SingleWriteN(z_pos_new,3,MCL_handle);
        
        end_thread = 0;
         hThread = (HANDLE)_beginthreadex( NULL, 0, &SecondThreadFunc, NULL, 0, &threadID );
        SetTimer(NULL,timer,100,(TIMERPROC)update_readout);
       
        
        
    }

    return;
}