pragma solidity ^0.4.0;
contract VehicleContract {
     uint count = 0;
    struct vehicle {
        string jobreference;
            string vin;
		    string year;
		    string model;
		    string make;
		    string vehicleOwner;
            
    }
     
     mapping (uint => vehicle) veh;       
    
    function setvalues(string jobref,string v, string y,string mod, string mak, string owner) public{
        veh[count] = vehicle(jobref, v, y, mod, mak,owner);
        count++;
        
    }
    function getvalues(uint index) public constant  returns (string jobref ,string v, string y ,string mod, string  mak, string owner) {
        jobref=veh[index].jobreference;
        v=veh[index].vin;
        y=veh[index].year;
        mod=veh[index].model;
        mak=veh[index].make;
        owner=veh[index].vehicleOwner;
        
    }
}