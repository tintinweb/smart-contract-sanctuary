// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../OpenZeppelin/Interfaces/IHelper.sol";

contract Helper is IHelper {

    address public owner;
    address public token;
    bool private isHelperEnabled = true;

    event WhitelistAdded(address _address);

    event BlacklistAdded(address _address);
    
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

     function helperEnabled() public override view returns (bool)  {
         return isHelperEnabled;
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
   
    function addWhitelist(address[] memory _addresses) public override onlyOwner {
        for(uint i = 0; i < _addresses.length; i++ ) {
            address _address = _addresses[i];
            if (!whitelisted[_address]) {
                require(_address != address(0), "Zero address not allowed");
                whitelisted[_address] = true;
                emit WhitelistAdded(_address);
            }
        }
    }

    function addBlacklist(address[] memory _addresses) public onlyOwner {
        for(uint i = 0; i < _addresses.length; i++ ){
            address _address = _addresses[i];
            if (!blacklisted[_address]) {
                require(_address != address(0), "Zero address not allowed");
                blacklisted[_address] = true;
                emit BlacklistAdded(_address);
            }
        }
    }

    function helperDisabled() public onlyOwner {
        isHelperEnabled = false;
    }
    
    function removeWhitelist(address _address) public onlyOwner {
        require(_address != address(0), "Zero address not allowed");
        delete whitelisted[_address];
    }

    function removeBlacklist(address _address) public onlyOwner {
        require(_address != address(0), "Zero address not allowed");
        delete blacklisted[_address];
    }

    function setToken(address _token) public onlyOwner {
        token = _token;
    }




}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHelper {

    
    function isContract(address _address) external returns (bool);

    function isWhitelisted(address _address) external  returns (bool);

    function isBlacklisted(address _address) external returns(bool);

    function isOwner() external returns(bool);

    function addWhitelist(address[] memory _addresses) external;
    
    function helperEnabled() external returns(bool);

    


}