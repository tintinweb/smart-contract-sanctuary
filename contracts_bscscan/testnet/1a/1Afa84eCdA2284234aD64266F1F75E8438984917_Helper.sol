// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../OpenZeppelin/Interfaces/IHelper.sol";

contract Helper is IHelper {
    address public owner;
   
    mapping(address => bool)  private whitelisted;

    mapping(address => bool) private  blacklisted;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Not an admin");
        _;
    }

    function isOwner() public override view returns (bool) {
        return owner == tx.origin || owner == msg.sender;
     }

    function isContract(address _address) external override view returns (bool) {
        uint size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }

    function isWhitelisted(address _address) public override view returns (bool) {
        return whitelisted[_address];
    }

    function isBlacklisted(address _address) public override view returns (bool) {
        return blacklisted[_address];
    }

   
    function addWhitelist(address[] memory _addresses) public onlyOwner {

        for(uint i = 0; i < _addresses.length; i++ ){
            address _address = _addresses[i];
           
            if (!whitelisted[_address]) {
                require(_address != address(0), "Zero address not allowed");
                whitelisted[_address] = true;
            }
           
        }
    }

    function addBlacklist(address[] memory _addresses) public onlyOwner {
       
        for(uint i = 0; i < _addresses.length; i++ ){
            address _address = _addresses[i];
            if (!blacklisted[_address]) {
                require(_address != address(0), "Zero address not allowed");
                blacklisted[_address] = true;
            }
           
        }
        
    }

    function removeWhitelist(address _address) public onlyOwner {
        require(_address != address(0), "Zero address not allowed");
        delete whitelisted[_address];
    }

    function removeBlacklist(address _address) public onlyOwner {
        require(_address != address(0), "Zero address not allowed");
        delete blacklisted[_address];
    }




}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHelper {


    function isContract(address _address) external returns (bool);

    function isWhitelisted(address _address) external  returns (bool);

    function isBlacklisted(address _address) external returns(bool);

    function isOwner() external returns(bool);

    


}