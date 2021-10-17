/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

pragma solidity ^0.6.12;

contract Test {
    
    address public devAddress;
    address public feeAddress;

    uint256 public balance;
    
    constructor(address _devAddress, address _feeAddress) public {
        devAddress = _devAddress;
        feeAddress = _feeAddress;
    }

    function setBalance(uint256 _bal) public {
        balance = _bal;
    } 
}