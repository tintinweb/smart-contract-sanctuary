/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <=0.8.0;
pragma experimental ABIEncoderV2;


   
contract TravelAgency {
  
  
  //define the flight attributs
  struct  Flight{
      
      uint256 Flight_NB;
      string Flight_name;
      uint256 Flight_Price;
      string Flight_status;
      string Flight_type;
      address CL;
      
  }
  
    mapping (uint => Flight)  public Flights; 
       uint256  Flight_counter;
       
    
    // define some data in the contractor
  constructor ()  public {
      
     createFlights(1, "A210",100 ,"Dispo", "Business",0x0000000000000000000000000000000000000000);
       createFlights(2, "A211",25 ,"Dispo", "Economy",0x0000000000000000000000000000000000000000);
        createFlights(3, "A10",605 ,"Dispo", "Business",0x0000000000000000000000000000000000000000);
        createFlights(4, "A665",48 , "Full","Economy",0x0000000000000000000000000000000000000000);
        createFlights(5, "A487",32 , "Dispo","Economy",0x0000000000000000000000000000000000000000);
        createFlights(6, "A310",55 ,"Full", "Business",0x0000000000000000000000000000000000000000);
    }
    
    
// create a flight with a certain attribute
    function createFlights(uint256 F_nb, string memory F_name, uint256 F_price, string memory F_status,string memory F_type, address F_client) private{
        
       
        Flights[Flight_counter]= Flight(F_nb, F_name, F_price,F_status, F_type,F_client);
        Flight_counter ++;
    }
    
  

    
    // search the minimal flights price   and return it;
    function Search_flight_PRICE(uint256 Total_Price) external   view  returns(uint256){
        require(Total_Price >0,"Price should be greater than 0");
        
       uint Pminflights= Flights[0].Flight_Price;
      for(uint i=0; i <= Flight_counter; i++){
         
         if(Flights[i].Flight_Price < Pminflights && keccak256(abi.encodePacked((Flights[i].Flight_status))) == keccak256(abi.encodePacked(("Dispo")))){
              Pminflights = Flights[i].Flight_Price ;
             // idd = Flights[i].Flight_NB;
             }
      }

        if(Total_Price> Pminflights){    
            
         return(Pminflights);     
         
        }else   { 
          //  revert(" No flights for the price you entered, please increase it ") ;
            return (Pminflights);
            }
            
}

    function Search_flight_ID(uint256 Total_Price) external  view  returns( uint256 ){
        require(Total_Price >0,"Price should be greater than 0");
        
       uint Pminflights= Flights[0].Flight_Price;
       uint256 idd= Flights[0].Flight_NB;
      for(uint i=0; i <= Flight_counter; i++){
         
         if(Flights[i].Flight_Price < Pminflights && keccak256(abi.encodePacked((Flights[i].Flight_status))) == keccak256(abi.encodePacked(("Dispo")))){
              Pminflights = Flights[i].Flight_Price ;
              idd = Flights[i].Flight_NB;
             }
      }

        if(Total_Price> Pminflights){    
              
         return (idd);     
         
        }else   { 
          //  revert(" No flights for the price you entered, please increase it ") ;
            return (idd);
            }
            
}

    

// get infos about a specific flight according to the ID
function getFlight_by_ID(uint id) internal  view returns(Flight memory){
  require(id>0,"ID incorrect");
   
   for(uint i=0;i< Flight_counter;i++){
       if(Flights[i].Flight_NB == id){
            return Flights[id-1];
           
       }
   }
}

// get all flighs details
function getFlights() private view returns (uint[] memory, string[] memory,uint[] memory, string[] memory){
    
     uint[] memory id= new uint[](Flight_counter);
    
     string[] memory name =new string[](Flight_counter);
     uint[] memory priceF= new uint[](Flight_counter);
     string[] memory typeF =new string[](Flight_counter);
    
    for(uint i=0;i< Flight_counter;i++){
        Flight storage flight =Flights[i];
       
        id[i]= flight.Flight_NB;
        name[i]=flight.Flight_name;
        priceF[i]=flight.Flight_Price;
        typeF[i]=flight.Flight_type;
        
    } 
    return (id,name,priceF,typeF);
}
function selectflight (uint256 id) external view returns (uint F1_nb,address add, string memory F1_name,string memory F1_status, uint256  F1_Price, string memory F1_type){
 
 
 require(id>0,"ID incorrect");
  for(uint j=0; j < Flight_counter ; j++){

        if(Flights[j].Flight_NB == id ){
            add= msg.sender;
            F1_nb=Flights[j].Flight_NB;
           F1_name= Flights[j].Flight_name;
           
          //  Flights[j].Flight_status= "Reserved";
            F1_status= Flights[j].Flight_status;
            
            F1_Price=Flights[j].Flight_Price;
           
            F1_type= Flights[j].Flight_type;
            
        return(F1_nb,add,F1_name,F1_status,F1_Price,F1_type);
        
        }
 
  }
    
}

function Book_FLIGHT (uint256  _id) external    {
    
    
    require(_id>0,"ID incorrect");
   
   
   for(uint i=0;i< Flight_counter;i++){
       if(Flights[i].Flight_NB == _id  && keccak256(abi.encodePacked((Flights[i].Flight_status))) == keccak256(abi.encodePacked(("Dispo")))){
            Flights[i].Flight_status= "reserved";
            Flights[i].CL=msg.sender;
            
       }
    
    
}}
  

function get_status (uint256 id) external view  returns (uint256 F1_nb, string memory F1_st){
 
 
 require(id>0,"ID incorrect");
  for(uint j=0; j < Flight_counter ; j++){

        if(Flights[j].Flight_NB == id ){
            
            F1_st=Flights[j].Flight_status;
            F1_nb= Flights[j].Flight_NB;
            
        return(F1_nb,F1_st);
        
        }
 
     }
    
}
    
}