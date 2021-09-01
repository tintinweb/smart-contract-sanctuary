/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

pragma solidity ^0.8.0;

contract MarketPlace{
    //Mapping tokenid to owner
    mapping (uint256 => address) _ownertoken;
    
    event list(address from, uint256 tokenid_);
    
    function  onTranferCall(address from, uint256 tokenid_) public returns (bool) {
        _ownertoken[tokenid_] = from;
        emit list(from,tokenid_);
        return true;
    }
    
    function getOwner(uint256 tokenid_) public view returns (address){
        return _ownertoken[tokenid_];
    }
}