/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity  0.8.0;

contract Kod  {
        
    struct Import {  
          string productid;
        string importer; // the number
        string  destination_geotag;
        string   arrival_date; // who  updates
        string vessel_information;
        uint     transit_time;
    }

    mapping(string => Import) private imports; 

 mapping(string => Import[]) private  arrayfive;
    event Imported(string indexed arrival, uint indexed duration,string indexed  vessel_information);
function addImport(string  memory _importer, uint _transit_time,string memory _destination_geotag,string  memory _productid,string memory _vessel_information,string memory _arrival_date) public {
        Import storage  importu = imports[_productid];

            importu.importer = _importer; 
            importu.transit_time = _transit_time;
            importu.destination_geotag  = _destination_geotag;
            importu.productid = _productid;
            importu.vessel_information = _vessel_information;
            importu.arrival_date = _arrival_date;
          arrayfive[_productid].push(importu);
          //kod[_productid].five.push(importu);
          emit Imported(_arrival_date,_transit_time,_vessel_information);   
    }




}