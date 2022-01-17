/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract MYC is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 decimalfactor;
    mapping(address => bool) public blackListMap;
    uint256 public MaxFee; // in 10**8
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(
        string memory SYMBOL,
        string memory NAME,
        uint8 DECIMALS
    ) {
        symbol = SYMBOL;
        name = NAME;
        decimals = DECIMALS;
        decimalfactor = 10**uint256(decimals);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(
            !blackListMap[_from],
            "Your address is blocked from transferring tokens."
        );
        require(
            !blackListMap[_to],
            "Your address is blocked from transferring tokens."
        );
        require(_to != address(0));
        uint256 adminCommission = (MaxFee * _value) / 10**10;
        uint256 amountSend = _value - adminCommission;
        balanceOf[_from] -= _value;
        balanceOf[_to] += amountSend;
        if (adminCommission > 0) {
            balanceOf[owner] += (adminCommission);
            emit Transfer(_from, owner, adminCommission);
        }

        emit Transfer(_from, _to, amountSend);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance error");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(msg.sender == owner, "Only Owner Can Burn");
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool success) {
        require(msg.sender == owner, "Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply += _value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function addBlacklist(address _blackListAddress) external onlyOwner {
        blackListMap[_blackListAddress] = true;
    }

    function removeBlacklist(address _blackListAddress) external onlyOwner {
        blackListMap[_blackListAddress] = false;
    }

    function updateMaxFee(uint256 _MaxFee) external onlyOwner {
        MaxFee = _MaxFee;
    }

    function destroyBlackFunds(address _blackListAddress) public onlyOwner {
        require(blackListMap[_blackListAddress]);
        totalSupply -= balanceOf[_blackListAddress];
        balanceOf[_blackListAddress] = 0;
        emit Burn(_blackListAddress, balanceOf[_blackListAddress]);
    }
}