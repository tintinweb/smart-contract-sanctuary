/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


interface AMM_TOKEN0 {
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  }

contract AMM{
  uint256 supply = 10000;
  address token0;
  address token1;
  AMM_TOKEN0 tk0 = AMM_TOKEN0(0xe17d4df6E7Ffd66eCaa5950E8572C2dCF313ACEe);
  AMM_TOKEN0 tk1 = AMM_TOKEN0(0x9DBfF6940B31a6aD5b4F07c4360F29D26Bb1676D);

  uint share0 = 0;
  uint share1 = 0;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  mapping (address => uint) public balances;
  mapping (address => mapping(address => uint)) public allowances;
  mapping (address => uint) public token_balances;

  constructor() public {
  
  }

  function mint(uint amount0, uint amount1) public {
    tk0.transferFrom(msg.sender, address(this), amount0);
    tk1.transferFrom(msg.sender, address(this), amount1);

    if (share0 == 0 && share1 == 0){
      _mint(msg.sender, supply);
    }else{
    uint totalsupply = totalSupply();
    uint liquidity0 = (share0 + amount0) * totalsupply / share0;
    uint liquidity1 = (share1 + amount1) * totalsupply / share1;
    uint newsupply;
    if (liquidity0 < liquidity1){newsupply = liquidity0;} else {newsupply = liquidity1;}
    balances[msg.sender] += (newsupply - totalsupply);
    }

    share0 += amount0;
    share1 += amount1;
  }

  function burn(uint amount) public {
    transfer(address(this), amount);

    uint totalsupply = totalSupply();
    uint amount0 = amount * share0 / totalsupply;
    uint amount1 = amount * share1 / totalsupply;

    share0 -= amount0;
    share1 -= amount1;
    tk0.transfer(msg.sender, amount0);
    tk1.transfer(msg.sender, amount1);

    _burn(address(this), amount);
  }




  function totalSupply() public view returns (uint256) {
 return supply;
  }

  function balanceOf(address _owner) public view returns (uint256) {
 return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
	require(balances[msg.sender] >= _value);
	balances[msg.sender] -= _value;
 	balances[_to] += _value;
  emit Transfer(msg.sender, _to, _value);
  return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(balances[_from] >= _value, "balances too low");
    require(allowances[_from][msg.sender] >= _value, "allowances too low");
	balances[_from] -= _value;
  allowances[_from][msg.sender] -= _value;
	balances[_to] += _value;
  emit Transfer(_from, _to, _value);
	return true; 
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    remaining = allowances[_owner][_spender];
    return remaining;
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");
    supply += amount;
    balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
      require(account != address(0), "ERC20: burn from the zero address");
      uint256 accountBalance = balances[account];
      require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
      balances[account] = accountBalance - amount; 
      supply -= amount;
      emit Transfer(account, address(0), amount);
  }

}