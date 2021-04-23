/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract ElectricityContract {

    address[3] public signAddress = [0x4D2CaA05f80996338F266E74abbb7211f81B097E,0x280712d178A4cB4Ae5d2485358Bb81BF5612FB9f,0xaA67FcCE77E5537364F3B95041bFfCf7FfA8C958];
    bool[3] public signStatus;
    string public contractContent = unicode"国家电网有限公司以0.29元每千瓦时的价格购买国电华北电力有限公司1000万千瓦时";
   
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