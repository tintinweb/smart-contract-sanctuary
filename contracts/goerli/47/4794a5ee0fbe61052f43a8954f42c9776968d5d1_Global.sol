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

      
contract Hotel1  {
    
    
    struct  Hotel{
      
      uint256 Hotel_nb;
      string Hotel_name;
      uint256 Hotel_Price;
      string Hotel_status;
      string Hotel_type;
      address CL;
  }
    mapping (uint=>  Hotel) public  Hotels; 
    
  constructor ()  public{
      createHotels(1, "Lagona Hotel",100 , "Dispo","Suite room",0x0000000000000000000000000000000000000000);
       createHotels(2, "Rotana Hotel",75 ,"Dispo", "suite room",0x0000000000000000000000000000000000000000);
        createHotels(3, "Moulin vert Hotel",30 ,"rented" ,"Room",0x0000000000000000000000000000000000000000);
        createHotels(4, " Hilton Hotel",19 ,"Dispo", "Room",0x0000000000000000000000000000000000000000);
        createHotels(5, "Phenicia Hotel",55 ,"Dispo", "Suite room",0x0000000000000000000000000000000000000000);
        createHotels(6, "699 Hotel",36 , "Dispo","Room",0x0000000000000000000000000000000000000000);
    } 
   uint256 Hotel_counter =0;

    function createHotels(uint256 H_nb, string memory H_name, uint256 H_price,string memory H_dispo ,string memory H_type, address H_client) private{
        
       
        Hotels[Hotel_counter]= Hotel(H_nb, H_name, H_price,H_dispo, H_type,H_client);
        Hotel_counter ++;
    }
    


    
    function Search_Hotel(uint256 Total_Price1) external  view  returns(  uint256 Price_min_hotel  ){
               
               require(Total_Price1 >0,"Price should be greater than 0");

       uint Pminhotel=Hotels[0].Hotel_Price;
      
      for(uint i=0; i<Hotel_counter; i++){
         
         if(Hotels[i].Hotel_Price < Pminhotel && keccak256(abi.encodePacked((Hotels[i].Hotel_status))) == keccak256(abi.encodePacked(("Dispo")))){
              Pminhotel =Hotels[i].Hotel_Price;
             }
         
      }
        
        if(Total_Price1 > Pminhotel){    
          
        return(Pminhotel);     
         
        } else {return (Pminhotel);
            
           // revert("No hotels for the price you entered, please increase it"); 
           }
}

   function Search_Hotel1(uint256 Total_Price1) external  view  returns(  uint256 idd  ){
               
               require(Total_Price1 >0,"Price should be greater than 0");

       uint Pminhotel=Hotels[0].Hotel_Price;
      
      for(uint i=0; i< Hotel_counter; i++){
         
         if(Hotels[i].Hotel_Price < Pminhotel && keccak256(abi.encodePacked((Hotels[i].Hotel_status))) == keccak256(abi.encodePacked(("Dispo")))){
              Pminhotel =Hotels[i].Hotel_Price;
              idd=Hotels[i].Hotel_nb;
             }
         
      }
        
        if(Total_Price1 > Pminhotel){    
          
        return idd;     
         
        
}}
function gethotels() private view returns (uint[] memory, string[] memory,uint[] memory, string[] memory){
    
     uint[] memory id= new uint[](Hotel_counter);
    
     string[] memory name =new string[](Hotel_counter);
     uint[] memory priceF= new uint[](Hotel_counter);
     string[] memory typeF =new string[](Hotel_counter);
    
    for(uint i=0;i< Hotel_counter;i++){
        Hotel storage Hotel =Hotels[i];
       
        id[i]= Hotel.Hotel_nb;
        name[i]=Hotel.Hotel_name;
        priceF[i]=Hotel.Hotel_Price;
        typeF[i]=Hotel.Hotel_type;
        
    } 
    return (id,name,priceF,typeF);
}


function getHotel_by_ID(uint _id) private view returns(Hotel memory){
  require(_id>0,"ID incorrect");
   
   for(uint i=0;i< Hotel_counter;i++){
       if(Hotels[i].Hotel_nb == _id){
            return Hotels[_id-1];
           
       }
   }
}


function Book_HOTEL (uint256  _id) external   {
    
    
    require(_id>0,"ID incorrect");
    
   
   for(uint i=0;i< Hotel_counter;i++){
       if(Hotels[i].Hotel_nb == _id && keccak256(abi.encodePacked((Hotels[i].Hotel_status))) == keccak256(abi.encodePacked(("Dispo")))){
            Hotels[i].Hotel_status= "reserved";
            Hotels[i].CL=msg.sender;
       }
    
    
}}
    
}



    
contract Car  {
    
    
    
    struct  car{
      
      uint256 car_nb;
      string car_name;
      uint256 car_Rent_Price;
      string car_status;
      string car_type;
      address CL;
  }
    mapping (uint=>  car)  public cars; 
    
  constructor () public {
      createcars(1, "Toyota yaris",10 ,"Dispo", "classic",0x0000000000000000000000000000000000000000);
       createcars(2, "yukon",75 , "Dispo","4*4",0x0000000000000000000000000000000000000000);
        createcars(3, "bugatti",300 ,"Dispo", "super car",0x0000000000000000000000000000000000000000);
        createcars(4, " ferrari",250 , "Dispo","super car",0x0000000000000000000000000000000000000000);
        createcars(5, " Renault",8 , "Dispo","classic",0x0000000000000000000000000000000000000000);
        createcars(6, "G36 class ",190 , "Dispo","4*4",0x0000000000000000000000000000000000000000);
    } 
   uint256 car_counter =0;

    function createcars(uint256 C_nb, string memory C_name, uint256 C_price, string memory C_status, string memory C_type, address C_client) private{
        
       
        cars[car_counter]= car(C_nb, C_name, C_price,C_status, C_type,C_client);
         //cars[car_counter].push((car(C_nb, C_name, C_price,C_status, C_type)));
       car_counter ++;
    }

    function Search_Car(uint256 Total_Price2) external  view  returns( uint256 Price_min_car){
       require(Total_Price2 >0,"Price should be greater than 0");
       uint256 Pmincar= cars[0].car_Rent_Price;
    
      for(uint i=0; i<car_counter; i++){
         
         if(cars[i].car_Rent_Price < Pmincar){
              Pmincar = cars[i].car_Rent_Price;
             }
      }
        
        if(Total_Price2 > Pmincar){    
            
        return(Pmincar);     
         
        }else {return (Pmincar);
           // revert("No cars for the price you entered, please increase it"); 
            
        }
}
     function Search_Car1(uint256 Total_Price2) external  view  returns( uint256 idd){
       require(Total_Price2 >0,"Price should be greater than 0");
       uint256 Pmincar= cars[0].car_Rent_Price;
    
      for(uint i=0; i<car_counter; i++){
         
         if(cars[i].car_Rent_Price < Pmincar){
             Pmincar = cars[i].car_Rent_Price;
              idd= cars[i].car_nb;
             }
      }
        
        if(Total_Price2 > Pmincar){    
            
        return(idd);     
         
        }else {return (idd);
           // revert("No cars for the price you entered, please increase it"); 
            
        }
}
    
    
    
    function getCars() private view returns (uint[] memory, string[] memory,uint[] memory, string[] memory){
    
     uint[] memory id= new uint[](car_counter);
    
     string[] memory name =new string[](car_counter);
     uint[] memory priceF= new uint[](car_counter);
     string[] memory typeF =new string[](car_counter);
    
    for(uint i=0;i< car_counter;i++){
        car storage car =cars[i];
       
        id[i]= car.car_nb;
        name[i]=car.car_name;
        priceF[i]=car.car_Rent_Price;
        typeF[i]=car.car_type;
        
    } 
    return (id,name,priceF,typeF);
}


function getCar_by_ID(uint _id) private view returns(car memory ){
  require(_id>0,"ID incorrect");
   
   for(uint i=0;i< car_counter;i++){
       if(cars[i].car_nb == _id){
            return cars[_id-1];
           
       }
   }
}

function Book_CAR (uint256  _id) external   {
    
    
    require(_id>0,"ID incorrect");
   
   for(uint i=0;i< car_counter;i++){
       if(cars[i].car_nb == _id && keccak256(abi.encodePacked((cars[i].car_status))) == keccak256(abi.encodePacked(("Dispo")))){
            cars[i].car_status= "reserved";
            cars[i].CL= msg.sender;

       }
    
    
}}
    
    
}
    

    
    contract Global {
        
        Hotel1 H = new Hotel1(); 
        Car CAR =  new Car();
        TravelAgency TA = new TravelAgency();
        
        
        function getlist (uint256 Price) external view returns( uint256 Flight_Price, uint256 Flight_id, uint256 hotel_Price,uint256 hotel_id, uint256 car_price, uint256 car_id ){
          
        require(Price >0," the price must be grater than 0 ");
      
       
         uint256 idh;
        uint256  PF;
        uint256 newPF;
        uint256 PC;
         uint256  idc;
        uint256 idf= TA.Search_flight_ID(Price);
        PF = TA.Search_flight_PRICE(Price);
     
    
     if( Price > PF && PF>0 ){
    
        newPF= Price - PF;
        
         
         uint256 PH;
          
        PH = H.Search_Hotel(newPF);
        idh= H.Search_Hotel1(newPF);
        
               if( newPF > PH  && PH >0 ){
              uint256 newPH= newPF - PH;
              
              PC=CAR.Search_Car(newPH);
              
              idc= CAR.Search_Car1(newPH);
                             if(newPH> PC && PC >0){
                                               uint256 newPC=  newPH- PC;
                                               
                                               
                                        
                                                return(PF,idf,PH,idh,PC,idc);
                                                
                                          }else { 
                                              
                                              
                                            uint   PC1=CAR.Search_Car(newPH);
                                              
                                              
                                              return(0,0,0,0,PC1,0); 
                                          
                                          
                                          }
                                          
               }else {
                   uint PH1 = H.Search_Hotel(newPF);
                   
                   return(0,0,PH1,0,0,0); }
                    
         
     }else  {      
                        

         return(PF,0,0,0,0,0); 

         
                 }
          }
  
   
   
   
   function getlist_with_price (uint256 Price) external view returns(string memory, uint256 Total_Trip_Price, uint256 Flight_Price, uint256 Hotel_Price, uint256 Car_Price,uint256 Entered_price, uint256 Remaining_price ){
          
        require(Price >0," the price must be grater than 0 ");
      
        uint256 P= Price;
        
     uint256  PF;
     
   uint256 newPF;
     PF = TA.Search_flight_PRICE(Price);
    
     if( Price > PF && PF>0 ){
    
        newPF= Price - PF;
         uint256 PH=0;
          
         PH = H.Search_Hotel(newPF);

        
               if( newPF > PH  && PH >0 ){
              uint256 newPH= newPF - PH;
              uint256 PC=CAR.Search_Car(newPH);
              
              
                             if(newPH> PC && PC >0){
                                               uint256 newPC=  newPH- PC;
                                               uint256 TotalTrip_Price= PF + PH +PC ;
                                             uint256  R_price= P - TotalTrip_Price;
                                               
                                                return("Trip is found ",TotalTrip_Price,PF,PH,PC,P,R_price);
                                                
                                          }else { 
                                              
                                              
                                            uint   PC1=CAR.Search_Car(newPH);
                                              
                                              
                                              return("Trip is  not found, No cars for your entered price, please increase it, ",0,0,PC1,0,P,0); 
                                          
                                          
                                          }
                                          
               }else {
                   uint PH1 = H.Search_Hotel(newPF);
                   
                   return("Trip is  not found, No hotels for  your entered price , please increase it ",0,PH1,0,0,P,0); }
                    
         
     }else  {      
                         require(0==0,"No flights for the price you entered, please increase it");

         return("Trip is  not found, No flights for your entered price, please increase it  ",0,TA.Search_flight_PRICE(Price),0,0,P,0); 
         //revert("No cars for the price you entered, please increase it");
         
         
                 }
          }
   
    }