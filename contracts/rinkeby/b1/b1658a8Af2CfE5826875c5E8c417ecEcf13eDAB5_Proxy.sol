/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Ownable {
    address internal owner;

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
    address private aggregatorETHAddress =
        0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address private aggregatorDAIAddress =
        0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF;
    address private customer = msg.sender;
    
    address payable public implementation =
        payable(0x0572a6af7Dd21A0f56082C461A8201705125a5B0);
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