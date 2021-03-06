
#include "settings.h"
#include "util.h"

std::string Settings::getINIString( const char *key ){
    return Util::getINIString(".\\RTDMan.ini", "RTDMan", key );
}
int Settings::getINIInt( const char *key ){
    return Util::getINIInt(".\\RTDMan.ini", "RTDMan", key );
}

void Settings::loadSettings(){

    rtd_server_prog_id    = getINIString("RTDServerProgID");     
    bar_period            = getINIInt   ("BarPeriod");
    csv_folder_path       = getINIString("CSVFolderPath"); 	
	is_archive			  = getINIString("Archive") == "true";
    bell_wait_time        = getINIInt   ("BellWaitTime"); 
    ab_db_path            = getINIString("AbDbPath");

    open_time             = getINIString("OpenTime");     
    close_time            = getINIString("CloseTime");
	target_client		  = getINIString("Client");

    no_of_scrips          = 0 ;    

    std::string scrip_value;
    std::string scrip_key;

/* Removed by Josh1 ----------------------------------------------------------------------------------
    if( bar_period < 1000  ){                                                // check $TICKMODE 1
        throw "Minimum Bar Interval is 1000ms";        
    }
*/
	// added by Josh1 ---------------------------------------------------------------------------
	request_refresh       = getINIInt   ("RequestRefresh");
	view_raw_data		  = getINIInt  ("ViewRawData");
	view_bar_data		  = getINIInt  ("ViewBarData");
	view_tic_data		  = getINIInt  ("ViewTicData");
	view_NT_data		  = getINIInt  ("ViewNTData");
//	view_AB_data		  = getINIInt  ("ViewABData");
	refresh_period		  = getINIInt  ("RefreshPeriod");

    if( !( (bar_period == 0  ) || (bar_period == 1000  ) || (bar_period == 60000  )) ) {              // check Barperiod
        throw "Bar Period should be 0 or 1000 or 60000 ";        
    }

	if (refresh_period < 50  || refresh_period > 1000  )  {														// Added by Josh1
        throw "Refresh period should be between 50 and 1000";        
    }    
	// end added by Josh1 ---------------------------------------------------------------------------
    	
    Util::createDirectory( csv_folder_path );								// If folder does not exist, create it    
	csv_path = csv_folder_path + "abquotes.csv";
    
    while(1){
        scrip_key    = "Scrip";  scrip_key.append( std::to_string( (long long)no_of_scrips+1 ) );
        scrip_value  = getINIString( scrip_key.c_str() ) ;

        if(scrip_value.empty()){                                             // No more Scrips left
            if( no_of_scrips == 0 ){
                throw( "Atleast one scrip needed" );
            }
            else break;
        }

        //  ScripID(mandatory);Alias(mandatory);LTP(mandatory);LTT;Todays Volume;OI;LTP Multiplier  
        std::vector<std::string>  split_strings;
        Util::splitString( scrip_value , ';', split_strings ) ;
        if(split_strings.size() < 3 ){                                       // 3 mandatory field at start
            throw( scrip_key + " Invalid" ); 
        }

        Scrip    scrip_topics;

        scrip_topics.topic_name   =  split_strings[0];     
        scrip_topics.ticker       =  split_strings[1];
        scrip_topics.topic_LTP    =  split_strings[2];

        if(split_strings.size() >=4 ){
            scrip_topics.topic_LTT       =  split_strings[3];
        }
        if(split_strings.size() >=5 ){
            scrip_topics.topic_vol_today =  split_strings[4];
        }
        if(split_strings.size() >=6 ){
            scrip_topics.topic_OI        =  split_strings[5];
        } 
		if(split_strings.size() >=7 && !split_strings[6].empty() ){ 
//            scrip_topics.ltp_multiplier  =  std::stoi( split_strings[6] );	//Changed by Josh1 to double
            scrip_topics.ltp_multiplier  =  std::stod( split_strings[6] );
        }
        else {
            scrip_topics.ltp_multiplier  =  1.00;
        }

		//Inserted by Boarders ----------------------
		if(split_strings.size() >=8 ){
            scrip_topics.topic_Bid_Rate        =  split_strings[7];
        } 
		if(split_strings.size() >=9 ){
            scrip_topics.topic_Ask_Rate        =  split_strings[8];
        } 
		if(split_strings.size() >=10 ){
            scrip_topics.topic_Bid_Qty        =  split_strings[9];
        } 
		if(split_strings.size() >=11 ){
            scrip_topics.topic_Ask_Qty        =  split_strings[10];
        } 



        scrips_array.push_back(  scrip_topics ) ;
        no_of_scrips++;
    } 
}

bool Settings::isTargetNT(){
	return target_client == "NT";
}
