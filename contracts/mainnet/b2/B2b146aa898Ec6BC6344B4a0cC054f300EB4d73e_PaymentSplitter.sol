/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

/**
 //SPDX-License-Identifier: UNLICENSED
*/
pragma solidity ^0.8.4;
contract PaymentSplitter {
    address payable private _address1;
    address payable private _address2;
    address payable private _address3;
    address payable private _address4;

    receive() external payable {}

    constructor() {
        _address1 = payable(0xb3fBd34905e0faC9Cdf59fBddF9111334ACb9A5d);
        _address2 = payable(0x8a35218433917C9e53Bd9E5f01fB6a019685DFC2);
        _address3 = payable(0x5Ef82a6388458176319125780eccdDF391D4F06E);
        _address4 = payable(0x91862C658e8B024EC8c1945421FB4B8E42c91e48);    
    }

    function withdraw() external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3 
        , "Invalid admin address");

        uint256 split =  address(this).balance / 100;
        _address1.transfer(split * 30);
        _address2.transfer(split * 30);
        _address3.transfer(split * 30);
        _address4.transfer(split * 10);
    }
}