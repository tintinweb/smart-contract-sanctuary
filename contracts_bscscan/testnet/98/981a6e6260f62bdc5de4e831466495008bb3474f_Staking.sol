/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

pragma solidity ^0.5.0;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a); // dev: overflow
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a); // dev: underflow
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b); // dev: overflow
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0); // dev: divide by zero
        c = a / b;
    }
}


pragma solidity ^0.5.0;

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Staking {

  using SafeMath for uint256;

  address public tokenAddress;

  mapping(address => uint256) stakers;

  event Stake(address staker, uint256 value);
  event Unstake(address staker, uint256 value);

  constructor(address _tokenAddress) public {
    tokenAddress = _tokenAddress;
  }

  function () external payable {
        revert();
  }

  function stakedAmount(address _staker) public view returns (uint256) {
        return stakers[_staker];
  }

  function stake(uint256 _value) public returns (bool) {
    ERC20(tokenAddress).transferFrom(msg.sender, address(this), _value);
    stakers[msg.sender] = stakers[msg.sender].add(_value);
    emit Stake(msg.sender, _value);
    return true;
  }
  
  function unstake(uint256 _value) public returns (bool) {
    require(stakers[msg.sender] >= _value, "Amount to unstake exceeds sender's staked amount");
    ERC20(tokenAddress).transfer(msg.sender, _value);
    stakers[msg.sender] = stakers[msg.sender].sub(_value);
    emit Unstake(msg.sender, _value);
    return true;
  }

}