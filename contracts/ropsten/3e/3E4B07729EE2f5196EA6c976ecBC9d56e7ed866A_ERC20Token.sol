/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

//SPDX-License-Identifier: UNLICENSED
// ----------------------------------------------------------------------------
///Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
pragma solidity ^0.8.10;

interface ERC20Interface {
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (address success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ERC20Token is ERC20Interface {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public tSupply; // Total number of tokens
    string public name; // Descriptive name (i.e. For Dummies Token)
    uint8 public decimals; // How many decimals to use to display amounts
    string public symbol; // Short identifier for token (i.e. FDT)

    constructor(uint256 _initialAmount, string memory _tokenName , uint8 _decimalUnits, string memory _tokenSymbol) {
        balances[msg.sender] = _initialAmount * (10 ** _decimalUnits); // The creator owns all tokens
        tSupply = _initialAmount * (10 ** _decimalUnits); // Update total token supply
        name = _tokenName; // Token name
        decimals = _decimalUnits; // Number of decimals
        symbol = _tokenSymbol; // Token symbol
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value >= 0,"Cannot transfer negative amount.");
        require(balances[msg.sender] >= _value,"Insufficient funds.");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance_amount = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance_amount >= _value,"Insufficient funds.");
        balances[_from] -= _value;
        balances[_to] += _value;
        if (allowance_amount < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (address success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return msg.sender;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function totalSupply() public view returns (uint256 totSupp) {
        return tSupply;
    }

    function identity() view external returns(address) {
        return address(this);
    }

    function isWhitelisted(address account) external pure returns (bool) {
        require(account != address(0));
        return true;
    }
}