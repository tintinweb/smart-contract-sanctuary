pragma solidity ^0.4.24;


contract testMe {
    uint public storeMe;
    
    function getMe() view returns (uint256) {
        return storeMe;
    } 
    
    function setMe(uint256 _setMe) public {
        storeMe = _setMe;
    }

}