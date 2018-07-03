pragma solidity ^0.4.21;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ADXProxy is ERC20 {
  ERC20 private adx;

  function ADXProxy() public {
  	adx = ERC20(0x4470BB87d77b963A013DB939BE332f927f2b992e);
  }

  function totalSupply() public view returns (uint256) {
 	// 100 million * 10000
    return 1000000000000;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    adx.transfer(_to, _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return adx.balanceOf(_owner);
  }

  function allowance(address _owner, address _spender)
    public view returns (uint256)
  {
    return adx.allowance(_owner, _spender);
  }


  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool)
  {
  	adx.transferFrom(_from, _to, _value);
  	emit Transfer(_from, _to, _value);
  	return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    adx.approve(_spender, _value);
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
}