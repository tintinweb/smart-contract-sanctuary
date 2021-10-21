/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract ABCtec {
    string  public name = "ABC tec";
    string  public symbol = "At";
    uint256 public totalSupply = 100000000000;
    uint8   public decimals = 8;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    event TokensPurchased(
        address account,
        address token,
        uint amount
  );

    event TokensSold(
        address account,
        address token,
        uint amount
        );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function buyTokens() public payable {
    uint tokenAmount = msg.value;
    require(balanceOf[msg.sender] >= tokenAmount);

    transfer(msg.sender, tokenAmount);

    emit TokensPurchased(msg.sender, address(this), tokenAmount);
  }

  function sellTokens(uint _amount) public {
    uint etherAmount = _amount;
    
    require(balanceOf[msg.sender] >= _amount);
    require(address(this).balance >= etherAmount);

    transferFrom(msg.sender, address(this), _amount);
    transfer(msg.sender, etherAmount);


    emit TokensSold(msg.sender, address(this), _amount);
  }

}