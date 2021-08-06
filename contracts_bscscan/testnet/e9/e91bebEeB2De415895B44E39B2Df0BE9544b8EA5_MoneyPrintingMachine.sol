/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

pragma solidity 0.6.9;

/*

    SPDX-License-Identifier: Apache-2.0

*/

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}


contract MoneyPrintingMachine {
    
    function clone() external returns (address proxy) {
        ICloneFactory factory = ICloneFactory(0x167eF99EB4c677405F1A4142858aCCb7c525eF8F);
        address result = factory.clone(address(0x72F528cDb840160EccaFcE8761F87A8f0322054d));
        return result;
    }
}