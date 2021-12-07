/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.4.16 <0.9.0;

contract Kai {
}

contract Hitomi{
}

contract Defi_Aman_Japan is Kai,Hitomi{
    uint storedData;
    address private _contractowner;

    function set(uint x) public {
        storedData = x;
        _contractowner = msg.sender;
    }

    function get() public view returns (uint) {
        return storedData;
    }

    function whoisowner() public view returns(address){
        return _contractowner;
    } 

}
contract Thangaraj{
}