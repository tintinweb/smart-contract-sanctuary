pragma solidity ^0.4.0;
pragma solidity ^0.4.0;
contract VehicleContract {
    
    struct vehicle {
        string jobreference;
            string vin;
		    string year;
		    string model;
		    string make;
		    string vehicleOwner;
            
    }
    vehicle public veh;
            
    
    function setvalues(string jobref,string v, string y,string mod, string mak, string owner) public{
        veh.jobreference = jobref;
        veh.vin = v;
        veh.year = y;
        veh.model=mod;
        veh.make=mak;
        veh.vehicleOwner=owner;
        
        
        
    }
    function getvalues() public constant  returns (string ,string , string ,string , string , string ) {
        return(veh.jobreference,veh.vin,veh.year,veh.model,veh.make,veh.vehicleOwner);
    }
}