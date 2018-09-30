pragma solidity ^0.4.0;
pragma solidity ^0.4.0;
contract VehicleContract {
            string jobreference;
            string vin;
		    string year;
		    string model;
		    string make;
		    string vehicleOwner;
    
    function setvalues(string jobref,string v, string y,string mod, string mak, string owner) public{
        jobreference = jobref;
        vin = v;
        year = y;
        model=mod;
        make=mak;
        vehicleOwner=owner;
        
        
        
    }
    function getvalues() public constant returns (string jobref,string v, string y,string mod, string mak, string owner) {
        jobref=jobreference;
        v=vin ;
        y=year;
        mod=model;
        mak=make;
        owner=vehicleOwner;
    }
}