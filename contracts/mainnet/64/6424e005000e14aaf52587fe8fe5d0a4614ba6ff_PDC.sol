/**
 *Submitted for verification at Etherscan.io on 2020-06-27
*/

pragma solidity ^0.6.1;

      contract PDC {
          string  public name = "Pin Duo Coin";
          string  public symbol = "PDC";
          uint8 public decimals = 8;
          uint256 public totalSupply;

          event Transfer(address indexed _from, address indexed _to, uint256 _value);
          event Approval(address indexed _owner, address indexed _spender, uint256 _value);

          mapping(address => uint256) public balanceOf;
          mapping(address => mapping(address => uint256)) public allowance;

          constructor() public {
            totalSupply = 1000000000 * 10 ** uint(decimals);
            balanceOf[msg.sender] = totalSupply;
          }

          function balances(address _owner) public view returns (uint256 balance) {
              return balanceOf[_owner];
          }

          function ERCME (uint256 _initialSupply) public {
              balanceOf[msg.sender] = _initialSupply;
              totalSupply = _initialSupply;
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
      }