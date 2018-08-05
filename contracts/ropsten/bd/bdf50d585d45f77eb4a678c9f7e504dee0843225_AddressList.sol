/**
 * MonetaryCoin AddressList Smart contract
 * For full details see: https://github.com/Monetary-Foundation/MonetaryCoin
 *
 */

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}



/**
 * @title AddressList
 * @dev AddressList
 * Simple storage for addresses that can participate in the distribution
 */
contract AddressList is Ownable {

  /**
  * @dev Map of addresses that have been whitelisted (and passed KYC).
  * Whitelist value > 0 indicates the address has been whitelisted.
  */
  mapping(address => uint8) public whitelist;
  
  address operator_;

  /**
  * @dev init the contract and the operator address
  */
  constructor(address _operator) public{
    require(_operator != address(0));
    operator_ = _operator;
  }

  /**
  * @dev Modifier Throws if called by any account other than the operator_ or owner.
  */
  modifier onlyOps() {
    require((msg.sender == operator_) || (msg.sender == owner));
    _;
  }

  event OperatorTransferred(address indexed newOperator);

  /**
  * @dev Allows the current Owner to transfer control to a newOperator.
  * @param newOperator The address to transfer operator to.
  */
  function transferOperator(address newOperator) public onlyOwner {
    operator_ = newOperator;
    emit OperatorTransferred(operator_);
  }

  /**
  * @dev get operator
  * @return the address of the operator
  */
  function operator() public view returns (address) {
    return operator_;
  }


  event WhitelistUpdated(address indexed account, uint8 phase);

  /**
  * @dev Allows ops to add accounts to the whitelist.
  * Only those accounts will be allowed to contribute during the distribution.
  * _phase > 0: Can contribute
  * _phase = 0: Cannot contribute at all (not whitelisted).
  * @return true
  */
  function updateWhitelist(address _account, uint8 _phase) external onlyOps returns (bool) {
    require(_account != address(0));
    require(_phase <= 2);

    whitelist[_account] = _phase;

    emit WhitelistUpdated(_account, _phase);

    return true;
  }

}