/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface ERC20Interface {
    
    function totalSupply()  external view returns (uint256);

    function balanceOf(address tokenOwner)  external view returns (uint balance);

    function allowance(address tokenOwner, address spender)  external view returns (uint remaining);
    function approve(address spender, uint tokens)  external returns (bool success);

    function transfer(address to, uint tokens)  external returns (bool success);
    function transferFrom(address from, address to, uint tokens)  external returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract erc20 is ERC20Interface{
    
    string public name;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    uint256  public _totalSupply;
    
    /*构造函数*/
    constructor(string memory _name)  {
       name = _name;  // "UpChain";
       _totalSupply = 1000000;
       _balances[msg.sender] = _totalSupply;
    }
    
    /*接口方法*/
    function totalSupply() public override view returns (uint256) {
      return _totalSupply;
    }
    function balanceOf(address owner)  external override view returns (uint balance){
        balance = _balances[owner];
    }
    
    function transfer(address to, uint value)  external override returns (bool success){
      require(to != address(0));
      require(_balances[msg.sender] >= value);
      require(_balances[to] + value >= _balances[to]);   // 防止溢出


      _balances[msg.sender] -= value;
      _balances[to] += value;

      // 发送事件
      emit Transfer(msg.sender, to, value);

      return true;
    }
    
    function transferFrom(address _from, address _to, uint _value)external override returns (bool success){
        require(_to != address(0));
      require(_allowed[_from][msg.sender] >= _value);
      require(_balances[_from] >= _value);
      require(_balances[ _to] + _value >= _balances[ _to]);

      _balances[_from] -= _value;
      _balances[_to] += _value;

      _allowed[_from][msg.sender] -= _value;

      emit Transfer(msg.sender, _to, _value);
      return true;
    }

    function allowance(address tokenOwner, address spender)external override view returns (uint remaining){
      return _allowed[tokenOwner][spender];
    }
    function approve(address spender, uint _value)  external override returns (bool success){
      _allowed[msg.sender][spender] = _value;

      emit Approval(msg.sender, spender, _value);
      return true;
    }

}