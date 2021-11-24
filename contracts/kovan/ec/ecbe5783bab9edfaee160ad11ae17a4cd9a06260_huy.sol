/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity ^0.8.10;

contract huy {

    address[] public whitelist;
    uint256 public a;

    function WLLength() external view returns(uint256) {
        return whitelist.length;
    }

    function setWhitelist(address[] calldata _whitelist) external {
        whitelist = _whitelist;
    }

    function buy() external returns(bool){
        a++;
        for (uint256 i; i < whitelist.length; i++) {
            if(whitelist[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }
}