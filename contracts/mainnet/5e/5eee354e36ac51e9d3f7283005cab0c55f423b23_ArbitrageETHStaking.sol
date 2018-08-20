pragma solidity ^0.4.23;

// File: contracts/Ownable.sol

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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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

// File: contracts/SafeMath.sol

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

// File: contracts/ArbitrageETHStaking.sol

/**
* @title ArbitrageETHStaking
* @dev The ArbitrageETHStaking contract staking Ether(ETH) tokens.
*      Here is stored all function and data of user stakes in contract.
*      Staking is configured for 2%.
*/
contract ArbitrageETHStaking is Ownable {

    using SafeMath for uint256;

    /*==============================
     =            EVENTS            =
     ==============================*/

    event onPurchase(
       address indexed customerAddress,
       uint256 etherIn,
       uint256 contractBal,
       uint256 poolFee,
       uint timestamp
    );

    event onWithdraw(
         address indexed customerAddress,
         uint256 etherOut,
         uint256 contractBal,
         uint timestamp
    );


    /*** STORAGE ***/

    mapping(address => uint256) internal personalFactorLedger_; // personal factor ledger
    mapping(address => uint256) internal balanceLedger_; // users balance ledger

    // Configurations
    uint256 minBuyIn = 0.001 ether; // can&#39;t buy less then 0.0001 ETH
    uint256 stakingPrecent = 2;
    uint256 internal globalFactor = 10e21; // global factor
    uint256 constant internal constantFactor = 10e21 * 10e21; // constant factor

    /// @dev Forward all Ether in buy() function
    function() external payable {
        buy();
    }

    // @dev Buy in staking pool, transfer ethereum in the contract, pay 2% fee
    function buy()
        public
        payable
    {
        address _customerAddress = msg.sender;

        require(msg.value >= minBuyIn, "should be more the 0.0001 ether sent");

        uint256 _etherBeforeBuyIn = getBalance().sub(msg.value);

        uint256 poolFee;
        // Check is not a first buy in
        if (_etherBeforeBuyIn != 0) {

            // Add 2% fee of the buy to the staking pool
            poolFee = msg.value.mul(stakingPrecent).div(100);

            // Increase amount of eth everyone else owns
            uint256 globalIncrease = globalFactor.mul(poolFee) / _etherBeforeBuyIn;
            globalFactor = globalFactor.add(globalIncrease);
        }


        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).add(msg.value).sub(poolFee);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        emit onPurchase(_customerAddress, msg.value, getBalance(), poolFee, now);
    }

    /**
     * @dev Withdraw selected amount of ethereum from the contract back to user,
     *      update the balance.
     * @param _sellEth - Amount of ethereum to withdraw from contract
     */
    function withdraw(uint256 _sellEth)
        public
    {
        address _customerAddress = msg.sender;
        // User must have enough eth and cannot sell 0
        require(_sellEth > 0, "user cant spam transactions with 0 value");
        require(_sellEth <= ethBalanceOf(_customerAddress), "user cant withdraw more then he holds ");


        // Transfer balance and update user ledgers
        _customerAddress.transfer(_sellEth);
        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).sub(_sellEth);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        emit onWithdraw(_customerAddress, _sellEth, getBalance(), now);
    }

    // @dev Withdraw all the ethereum user holds in the contract, set balance to 0
    function withdrawAll()
        public
    {
        address _customerAddress = msg.sender;
        // Set the sell amount to the user&#39;s full balance, don&#39;t sell if empty
        uint256 _sellEth = ethBalanceOf(_customerAddress);
        require(_sellEth > 0, "user cant call withdraw, when holds nothing");
        // Transfer balance and update user ledgers
        _customerAddress.transfer(_sellEth);
        balanceLedger_[_customerAddress] = 0;
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        emit onWithdraw(_customerAddress, _sellEth, getBalance(), now);
    }

    /**
    * UI Logic - View Functions
    */

    // @dev Returns contract ETH balance
    function getBalance()
        public
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    // @dev Returns user ETH tokens balance in contract
    function ethBalanceOf(address _customerAddress)
        public
        view
        returns (uint256)
    {
        // Balance ledger * personal factor * globalFactor / constantFactor
        return balanceLedger_[_customerAddress].mul(personalFactorLedger_[_customerAddress]).mul(globalFactor) / constantFactor;
    }
}