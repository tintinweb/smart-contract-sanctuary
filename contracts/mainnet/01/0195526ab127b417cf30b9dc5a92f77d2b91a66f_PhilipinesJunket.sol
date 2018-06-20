pragma solidity ^0.4.20;

library SafeMath {

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }
}

/**
 * @title JunketLockup
 * @dev JunketLockup is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract PhilipinesJunket {
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  uint256 public previousWithdrawal = 0;
  
  uint256 public year = 365 days; // equivalent to one year

  constructor() public {
    token = ERC20Basic(0x814F67fA286f7572B041D041b1D99b432c9155Ee);
    beneficiary = address(0x8CBE4C9a921A19d8F074d9722815cD42a450f849);
    
    releaseTime = now + year;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    if(previousWithdrawal == 0){
        // calculate 50% of existing amount
        amount = amount.div(2);
    }else{
        assert(now >= releaseTime);
    }
    
    previousWithdrawal = amount;
    
    token.safeTransfer(beneficiary, amount);
    
  }
  
  function balanceOf() external view returns(uint256){
      return token.balanceOf(address(this));
  }
  
  function currentTime() external view returns(uint256){
      return now;
  }
}