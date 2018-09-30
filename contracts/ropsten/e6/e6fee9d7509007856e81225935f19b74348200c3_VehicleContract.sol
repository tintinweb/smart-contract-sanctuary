pragma solidity ^0.4.0;
contract VehicleContract {
     uint count = 0;
    struct vehicle {
        address beneficiary;
        string jobreference;
            string vin;
		    string year;
		    string model;
		    string make;
		    string vehicleOwner;
            
    }
     
     mapping (uint => vehicle) veh;       
    
    function addvehicles(address receiver,string vehjobref,string vehvin, string vehyear,string vehmodel, string vehmake, string ownername) public{
        veh[count] = vehicle(receiver,vehjobref, vehvin, vehyear, vehmodel, vehmake,ownername);
        count++;
        
    }
    function getvalues(uint index) public constant  returns (address receiver,string vehjobref,string vehvin, string vehyear,string vehmodel, string vehmake, string ownername) {
        receiver=veh[index].beneficiary;
        vehjobref=veh[index].jobreference;
        vehvin=veh[index].vin;
        vehyear=veh[index].year;
        vehmodel=veh[index].model;
        vehmake=veh[index].make;
        ownername=veh[index].vehicleOwner;
        
    }
    
    
function Transfer(address receiver, uint index) public{
		vehicle storage  t = veh[index];
		require (t.beneficiary != msg.sender) ;
		t.beneficiary = receiver;
} 
}