/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// File: contracts/VerifiedUsers.sol



pragma solidity >=0.7.0 <0.9.0;

contract VerifiedUsers {
    mapping (address => bool) public verifiedUsers;  
    address owner = address(0);  
    constructor(){
        owner = msg.sender;
    }




    function _isOwner(address _address) internal view returns (bool) {
        return owner == _address;
    }

     /**
     * @dev Throws if called by any account other than the owner or their proxy
     */
    modifier onlyOwner() {
        require (
            _isOwner(msg.sender),
            "CALLER_IS_NOT_OWNER"
        );
        _;
    }






     function addVerifiedUser(address _address) public onlyOwner {
        verifiedUsers[_address] = true;
    }


    function isUserVarified(address _address) public view returns (bool) {
        return verifiedUsers[_address];
    }

}