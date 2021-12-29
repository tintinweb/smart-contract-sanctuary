/**
 *Submitted for verification at FtmScan.com on 2021-12-29
*/

pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

contract ModelFactory {
    // function convert(uint16 amount) external;

    bytes public model; 
    address public aModel;

    function encoder(address _model) external {
        model = abi.encode(_model);
    }

    function init(bytes calldata data) external {
        aModel = abi.decode(data, (address)); 
    }

}