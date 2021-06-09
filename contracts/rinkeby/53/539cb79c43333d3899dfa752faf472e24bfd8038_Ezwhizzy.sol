/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;
contract Ezwhizzy {
    
    string[] myArray;

     struct Package {
        uint256 package_id;
        uint256 buyer_id;
        uint256 seller_id;
        uint256 driver_id;
        uint256 transaction_id;
        string cost;        
        string[] logs;
        
    }
    
    Package[] public packages;

    function add_package(uint256 package_id, uint256 buyer_id , uint256 seller_id , uint256 driver_id , uint256 transaction_id , string cost) public {
        packages.push(Package({
                package_id: package_id,
                buyer_id: buyer_id,
                seller_id: seller_id,
                driver_id: 0,
                transaction_id: transaction_id,
                cost: cost,
                logs: myArray
            }));
    }
    

    function add_driver(uint256 package_id , uint256 driver_id){
        for (uint p = 0; p < packages.length; p++) {
            if(keccak256(packages[p].package_id) == keccak256(package_id)){
                packages[p].driver_id = driver_id;
                break;
            }
        }
        
    }
    
    function getPackage(uint256 package_id) public returns (uint256 buyer_id, uint256 seller_id ,  uint256 driver_id, string[] logs){
        for (uint p = 0; p < packages.length; p++) {
            if(keccak256(packages[p].package_id) == keccak256(package_id)){
                Package memory q = packages[package_id];
                return (q.buyer_id, q.seller_id , q.driver_id ,q.logs);
                break;
                
            }
        }

    }
    
    
    function add_transaction(string package_id , string _value){
        for (uint p = 0; p < packages.length; p++) {
            if(keccak256(packages[p].package_id) == keccak256(package_id)){
                packages[p].logs.push(_value);
                break;
            }
        }
    }
    
    function retrieve_transactions(string package_id) public view returns (string[] memory){
        for (uint p = 0; p < packages.length; p++) {
            if(keccak256(packages[p].package_id) == keccak256(package_id)){
                return packages[p].logs;
                break;
            }
        }
    }

}