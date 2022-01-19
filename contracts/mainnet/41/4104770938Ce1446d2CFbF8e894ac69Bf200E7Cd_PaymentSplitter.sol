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


    receive() external payable {}

    constructor() {
        _address1 = payable(0x3F984dB117DD87204A40413Daf39B67D8628653F); // C
        _address2 = payable(0x5F0B28110655c8A111072372c14dcA291C26d2b9); // R
        _address3 = payable(0x527C3b8bDe79F956DA4FE311cA08C0C9a47d576a); // J
    }

    function withdraw() external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3 
        , "Invalid admin address");

        uint256 split =  address(this).balance / 3;
        _address1.transfer(split);
        _address2.transfer(split);
        _address3.transfer(split);
    }
}