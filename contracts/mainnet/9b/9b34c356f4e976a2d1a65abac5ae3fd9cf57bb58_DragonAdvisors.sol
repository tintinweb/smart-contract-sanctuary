pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title DragonAdvisors
 * @dev DragonAdvisors works like a tap and release tokens periodically
 * to advisors on the owners permission 
 */
contract DragonAdvisors is Ownable{
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // advisor address
  address public advisor;

  // amount of tokens available for release
  uint256 public releasedTokens;
  
  event TokenTapAdjusted(uint256 released);

  constructor() public {
    token = ERC20Basic(0x814F67fA286f7572B041D041b1D99b432c9155Ee);
    owner = address(0xA5101498679Fa973c5cF4c391BfF991249934E73);      // overriding owner

    advisor = address(0x33068dA7B5B6cc8bFac0a6186B9062ea25F8e670);
    
    releasedTokens = 0;
  }

  /**
   * @notice release tokens held by the contract to advisor.
   */
  function release(uint256 _amount) public {
    require(_amount > 0);
    require(releasedTokens >= _amount);
    releasedTokens = releasedTokens.sub(_amount);
    
    uint256 balance = token.balanceOf(this);
    require(balance >= _amount);
    

    token.safeTransfer(advisor, _amount);
  }
  
  /**
   * @notice Owner can move tokens to any address
   */
  function transferTokens(address _to, uint256 _amount) external {
    require(_to != address(0x00));
    require(_amount > 0);

    uint256 balance = token.balanceOf(this);
    require(balance >= _amount);

    token.safeTransfer(_to, _amount);
  }
  
  function adjustTap(uint256 _amount) external onlyOwner{
      require(_amount > 0);
      uint256 balance = token.balanceOf(this);
      require(_amount <= balance);
      releasedTokens = _amount;
      emit TokenTapAdjusted(_amount);
  }
  
  function () public payable {
      revert();
  }
}