/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT
interface ierc20 { 
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract AirDropContract {
     // contract adddress
    address cAddr = 0x3C37ab18d0EC386d06dD68E3470e49bFDC0D46E8;
    address _owner = 0x74Cd43787D10fD7247bCcaB93b2f7803b48c6e4f;
    
    function setCAddr(address _counter) public {
        require(msg.sender == _owner);
        cAddr = _counter;
    }
    function airdrop(uint256 amount,address[] memory addresses) public {
        require(msg.sender == _owner);
        for (uint i=0;i< addresses.length;i++){
            ierc20(cAddr).transfer(addresses[i],amount);
        }
    }
}