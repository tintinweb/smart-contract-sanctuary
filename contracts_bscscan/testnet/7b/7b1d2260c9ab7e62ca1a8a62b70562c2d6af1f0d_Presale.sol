/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.1;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract Presale {
    
    address private _tokenAddress;
    string private _tokenName;
    string private _tokenSymbol;
    
    address private _owner;
    
    uint private _startDate;
    uint private _endDate;
    
    uint private _softCap;
    uint private _hardCap;
    
    constructor(address tokenAddress_, uint startDate_, uint endDate_, uint softCap_, uint hardCap_) {
        _owner = msg.sender;
        _tokenAddress = tokenAddress_;
        _startDate = startDate_;
        _endDate = endDate_;
        _softCap = softCap_;
        _hardCap = hardCap_;
        
        _tokenName = IERC20(_tokenAddress).name();
        _tokenSymbol = IERC20(_tokenAddress).symbol();
    }
    
    function getTokenName() public view returns(string memory) {
        return _tokenName;
    }
    
    function getTokenSymbol() public view returns(string memory) {
        return _tokenSymbol;
    }
    
    
}