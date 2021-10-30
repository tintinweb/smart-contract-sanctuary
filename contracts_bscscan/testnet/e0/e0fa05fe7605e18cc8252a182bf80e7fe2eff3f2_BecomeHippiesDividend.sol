/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract BecomeHippiesDividend {
    
    struct Presale {
        uint price;
        uint supply;
        uint sponsorship;
    }
    
    struct Sponsorship {
        address user;
        bool value;
    }
    
    mapping (address => bool) private _addresses;
    mapping (address => uint) private _balances;
    mapping (address => Sponsorship) private _sponsorships;
    mapping (address => mapping (address => uint)) private _allowances;
    
    address[] private _beneficiaries;
    bytes32[] private _dividends;
    
    uint public totalSupply = 0;
    uint public decimals = 18;
    
    address public owner;
    string public name = "Become Hippies Dividend";
    string public symbol = "BHD";
    
    bool public isPresale = true;
    uint8 private _presaleIndex = 0;
    uint8 public presaleRounds = 3;
    Presale[] public presales;
    
    event Approval(address indexed owner, address indexed sender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor () {
        for (uint i = 0; i < presaleRounds; i++) {
            presales.push(Presale(2 * 10 ** 15, 12000 * 10 ** decimals, 3000 * 10 ** 18));
        }
        owner = msg.sender;
    }
    
    receive() external payable {
        if (isPresale) {
            _presale(msg.value, msg.sender);
        } else {
            _dividend(msg.value);
        }
    }
    
    function _dividend(uint value) private {
        require(value > 0, "Value is empty");
        require(!isPresale, "Is Presale");
        for (uint i = 0; i < _beneficiaries.length; i++) {
            address user = _beneficiaries[i];
            uint amount = value * _balances[user] / totalSupply;
            payable(user).transfer(amount);
        }
        _dividends.push(blockhash(block.number));
    }
    
    function _presale(uint value, address sender) private {
        require(value > 0, "Value is empty");
        require(isPresale, "Presale is finish");
        require(msg.value <= maxPresaleAmount(), "Amount exceeded");
        uint amount = _setPresale(value, sender);
        totalSupply += amount;
        _setBalance(sender, amount);
    }
    
    function closePresale() public returns(bool) {
        require(_isOwner(), "Only owner");
        require(isPresale, "Presale closed");
        isPresale = false;
        uint amount = totalSupply * 3 / 10;
        _setBalance(owner, amount);
        totalSupply += amount;
        return withdraw();
    }
    
    function withdraw() public returns(bool) {
        require(_isOwner(), "Only owner");
        uint balance = address(this).balance;
        require(balance > 0, "Contract balance is empty");
        payable(owner).transfer(balance);
        return true;
    }
    
    function balanceOf(address data) public view returns (uint) {
        return _balances[data];
    }
    
    function dividends() public view returns (bytes32[] memory) {
        return _dividends;
    }
    
    function hasSponsorship(address user) public view returns (bool) {
        return _sponsorships[user].value;
    }
    
    function addSponsorship(address sender, address user) public {
        _sponsorships[user] = Sponsorship(sender, true);
    }
    
    function presaleSupply() public view returns (uint) {
        return presales[_presaleIndex].supply;
    }
    
    function presalePrice() public view returns (uint) {
        return presales[_presaleIndex].price;
    }
    
    function presaleSponsorship() public view returns (uint) {
        return presales[_presaleIndex].sponsorship;
    }
    
    function presaleRound() public view returns (uint) {
        return _presaleIndex + 1;
    }
    
    function presaleAmout(uint value) public view returns (uint) {
        return isPresale ? _presaleAmount(value, _presaleIndex) : 0;
    }
    
    function maxPresaleAmount() public view returns (uint) {
        uint amount = 0;
        for (uint8 i = _presaleIndex; i < presaleRounds; i++) {
            amount += _presaleSupply(i) * _presalePrice(i);
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
    
    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(allowance(from, msg.sender) >= value, "Insufficient allowance");
        require(balanceOf(from) >= value, "Insufficient balance");
        _balances[from] -= value;
        if (from != owner) {
            uint amount = value * 20 / 100;
            value -= amount;
            for (uint i = 0; i < _beneficiaries.length; i++) {
                address user = _beneficiaries[i];
                if (user != from) {
                    _balances[user] += amount * _balances[user] / totalSupply;
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
    
    function _isOwner() private view returns (bool) {
        return msg.sender == owner;
    }
    
    function _sponsorship(uint amount, address user) private {
        uint max = presaleSponsorship();
        amount = amount * 20 / 100;
        if (max < amount) {
            amount = max;
        }
        presales[_presaleIndex].sponsorship -= amount;
        _balances[user] += amount;
    }
    
    function _setPresale(uint value, address sender) private returns (uint) {
        uint price = presalePrice();
        uint supply = presaleSupply();
        uint amount = (value / price) * 10 ** decimals;
        Sponsorship memory sponsor = _sponsorships[sender];
        Presale storage sale = presales[_presaleIndex];
        if (amount <= supply) {
            if (sponsor.value) {
                _sponsorship(amount, sponsor.user);
            }
            sale.supply -= amount;
            return amount;
        }
        sale.supply -= supply;
        if (sponsor.value) {
            _sponsorship(supply, sponsor.user);
        }
        if (_presaleIndex > 1) {
            isPresale = false;
            return supply;
        }
        value = (amount - supply) * price;
        _presaleIndex++;
        return supply + _setPresale(value, sender);
    }
    
    function _presaleSupply(uint8 index) private view returns (uint) {
        return presales[index].supply;
    }
    
    function _presalePrice(uint8 index) private view returns (uint) {
        return presales[index].price;
    }
    
    function _presaleSponsorship(uint8 index) private view returns (uint) {
        return presales[index].sponsorship;
    }
    
    function _presaleAmount(uint value, uint8 index) private view returns (uint) {
        uint price = _presalePrice(index);
        uint supply = _presaleSupply(index);
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
    
    function _setBalance(address to, uint value) private {
        _balances[to] += value;
         if (!_addresses[to] && !_isContract(to)) {
            _addresses[to] = true;
            _beneficiaries.push(to);
        }
    }
}