/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract TestContract {
    address[3] public signAddress = [0x4D2CaA05f80996338F266E74abbb7211f81B097E,0x280712d178A4cB4Ae5d2485358Bb81BF5612FB9f,0xaA67FcCE77E5537364F3B95041bFfCf7FfA8C958];
    bool[3] public signStatus;
    string public contractContent = "Test Contract";
   
    function sign() public{
        for(uint i=0;i<3;i++){
            if(msg.sender == signAddress[i]){
                signStatus[i] = true;
            }
        }
    }
    function getStatus() public view returns (bool){
        return signStatus[0] && signStatus[1] && signStatus[2];
    }
}