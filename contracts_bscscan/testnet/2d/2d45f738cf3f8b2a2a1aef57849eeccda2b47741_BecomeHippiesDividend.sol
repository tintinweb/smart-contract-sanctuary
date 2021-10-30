/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract BecomeHippiesDividend {
    
    struct Dividend {
        uint amount;
        DividendBeneficiary[] beneficiaries;
        mapping (address => bytes32) transactions;
    }
    
    struct DividendBeneficiary {
        address to;
        uint amount;
    }
    
    mapping (bytes32 => Dividend) private _dividends;
    mapping (address => uint) private _balances;
    mapping (address => bool) private _addresses;
    mapping (address => mapping (address => uint)) private _allowances;
    
    address[] private beneficiaries;
    
    uint public totalSupply = 60000;
    uint public decimals = 18;
    
    address public owner;
    string public name = "Become Hippies Dividend";
    string public symbol = "BHD";
    
    bool public isPresale = true;
    uint8 private _presaleIndex = 0;
    uint[] private _presalePrice = [2000000000000000, 4000000000000000, 6000000000000000];
    uint[] private _presaleSupply = [12000, 12000, 12000];
    
    event Approval(address indexed owner, address indexed sender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor () {
        totalSupply *= 10 ** decimals;
        uint amount = totalSupply;
        for (uint i = 0; i < _presaleSupply.length; i++) {
            _presaleSupply[i] *= 10 ** decimals;
            amount -= _presaleSupply[i];
        }
        owner = msg.sender;
        _balances[msg.sender] = amount;
    }
    
    receive() external payable {
        require(isPresale, "Presale is finish");
        require(msg.value <= maxPresaleAmount(), "Amount exceeded");
        uint amount = _presale(msg.value);
        //require(amount > 10 * 10 ** 18);
        _setBalance(msg.sender, amount);
    }
    
    function balanceOf(address data) public view returns (uint) {
        return _balances[data];
    }
    
    function getBeneficiaries(bytes32 hash) public view returns (DividendBeneficiary[] memory) {
        return _dividends[hash].beneficiaries;
    }
    
    function addDividend(bytes32 hash, uint amount) public returns (bool) {
        if (!_isOwner(msg.sender)) {
           return false; 
        }
        Dividend storage dividend = _dividends[hash];
        for (uint i = 0; i < beneficiaries.length; i++) {
            address user = beneficiaries[i];
            dividend.beneficiaries.push(DividendBeneficiary(user, amount * _balances[user] / totalSupply));
        }
        return true;
    }
    
    function addTransaction(bytes32 hash, address beneficiary, bytes32 transaction) public returns (bool) {
        if (!_isOwner(msg.sender)) {
            return false;
        }
        _dividends[hash].transactions[beneficiary] = transaction;
        return true;
    }
    
    function presaleSupply() public view returns (uint) {
        return _presaleSupply[_presaleIndex];
    }
    
    function presalePrice() public view returns (uint) {
        return _presalePrice[_presaleIndex];
    }
    
    function presaleAmout(uint value) public view returns (uint) {
        return _presaleAmount(value, _presaleIndex);
    }
    
    function maxPresaleAmount() public view returns (uint) {
        uint amount = 0;
        for (uint8 i = _presaleIndex; i < _presalePrice.length; i++) {
            uint price = _presalePrice[i];
            uint supply = _presaleSupply[i];
            amount += supply * price;
        }
        return amount;
    }
    
    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        _setBalance(to, value);
        _balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function _setBalance(address to, uint value) private {
        _balances[to] += value;
         if (!_isOwner(to) && !_addresses[to] && !_isContract(to)) {
            _addresses[to] = true;
            beneficiaries.push(to);
        }
    }
    
    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(allowance(from, msg.sender) >= value, "Insufficient allowance");
        require(balanceOf(from) >= value, "Insufficient balance");
        _balances[from] -= value;
        if (!_isOwner(from)) {
            uint amount = value * 20 / 100;
            value -= amount;
            uint supply = 0;
            for (uint i = 0; i < beneficiaries.length; i++) {
                address user = beneficiaries[i];
                if (user != from) {
                    supply += _balances[beneficiaries[i]];
                }
            }
            for (uint i = 0; i < beneficiaries.length; i++) {
                address user = beneficiaries[i];
                if (user != from) {
                    _balances[user] += amount * _balances[user] / supply;
                }
            }
        }
        _balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address sender, uint value) public returns (bool) {
        _allowances[msg.sender][sender] = value;
        emit Approval(msg.sender, sender, value);
        return true;
    }
    
    function allowance(address data, address sender) public view returns (uint256) {
        return _allowances[data][sender];
    }
    
    function _isContract(address value) private view returns (bool){
        uint32 size;
        assembly { size := extcodesize(value) }
        return size > 0;
    }
    
    function _isOwner(address sender) private view returns (bool) {
        return sender == owner;
    }
    
    function _presale(uint value) private returns (uint) {
        uint price = presalePrice();
        uint supply = presaleSupply();
        uint amount = (value / price) * 10 ** decimals;
        if (amount <= supply) {
            _presaleSupply[_presaleIndex] -= amount;
            return amount;
        }
        _presaleSupply[_presaleIndex] -= supply;
        if (_presaleIndex > 1) {
            isPresale = false;
            return supply;
        }
        value = (amount - supply) * price;
        _presaleIndex++;
        return supply + _presale(value);
    }
    
    
    
    function _presaleAmount(uint value, uint8 index) private view returns (uint) {
        uint price = _presalePrice[index];
        uint supply = _presaleSupply[index];
        uint amount = value / price;
        if (amount <= supply) {
            return amount;
        }
        if (index > 1) {
            return supply;
        }
        value = (amount - supply) * price;
        return supply + _presaleAmount(value, index + 1);
    }
}