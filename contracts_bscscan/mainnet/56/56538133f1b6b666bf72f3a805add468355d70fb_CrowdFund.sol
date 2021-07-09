/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: contracts/CappedCrowdsale.sol

pragma solidity ^0.4.23;


/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;
  uint256 public weiRaised;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  // function _preValidatePurchase(
  //   address _beneficiary,
  //   uint256 _weiAmount
  // )
  //   internal
  // {
  //   super._preValidatePurchase(_beneficiary, _weiAmount);
  //   require(weiRaised.add(_weiAmount) <= cap);
  // }

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.23;


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

// File: contracts/WhitelistedCrowdsale.sol

pragma solidity ^0.4.23;


/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistedCrowdsale is Ownable {

  mapping(address => bool) public whitelist;

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    isWhitelisted(_beneficiary)
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

}

// File: contracts/CrowdFund.sol

pragma solidity 0.4.24;

// import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";




contract CrowdFund is WhitelistedCrowdsale, CappedCrowdsale {
    using SafeMath for uint256;

    uint256 internal constant investorHardCap = 50 * 1e18; // 50 BNB
    uint256 public constant maxBuy = 1e18; // 1 BNB
    mapping(address => uint256) public contributions;

    event DepositFunds(
        address indexed _sender,
        address indexed _beneficiary,
        uint256 _weiAmount
    );
    event FundsWithdraw(uint256 _amount);

    constructor() public CappedCrowdsale(investorHardCap) {}

    function() external payable {
        depositFunds(msg.sender);
    }

    /**
     * @param _beneficiary Address performing the deposit funds
     */
    function depositFunds(address _beneficiary) public payable {
        uint256 _weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, _weiAmount);
        // update state
        weiRaised = weiRaised.add(_weiAmount);
        emit DepositFunds(msg.sender, _beneficiary, _weiAmount);
    }

    function withdrawFunds() external onlyOwner {
        uint256 _balance = address(this).balance;
        owner.transfer(_balance);
        emit FundsWithdraw(_balance);
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(weiRaised.add(_weiAmount) <= cap);
        uint256 _existingContribution = contributions[_beneficiary];
        uint256 _newContribution = _existingContribution.add(_weiAmount);
        require(_newContribution <= maxBuy, "Invalid investment");
        contributions[_beneficiary] = _newContribution;
    }
}