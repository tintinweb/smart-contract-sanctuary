/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
    }
}

contract Proxy is Ownable {
    address public tokenAddress;
    address public tokenDAIAddress;
    address public studentsAddress = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
    address public aggregatorETHAddress =
        0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address public aggregatorDAIAddress =
        0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF;
    address public customer = msg.sender;
    
    address payable public implementation =
        payable(0xeCBca4D3ca13acbeC790CE132b40A64359581319);
    uint256 private version = 1;

    fallback() external payable {
        (bool sucess, bytes memory _result) = implementation.delegatecall(
            msg.data
        );
    }

    function changeImplementation(
        address payable _newImplementation,
        uint256 _newVersion
    ) public onlyOwner {
        require(
            _newVersion > version,
            "New version must be greater then previous"
        );
        implementation = _newImplementation;
    }

    uint256[10] private _gap;
}