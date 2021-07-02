 if( mNIDAQ('NumErrors') ~= 0)
      mNIDAQ('NumErrors')
                      ErrorString =  mNIDAQ('CheckErrorStatus');
                       warning(['NIDAQ_Driver Error!! -- ',datestr(now),char(13),ErrorString]);
                   end