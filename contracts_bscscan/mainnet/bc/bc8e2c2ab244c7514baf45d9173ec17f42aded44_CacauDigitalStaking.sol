/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity 0.6.2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.6.2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/zeppelin/access/Ownable.sol

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function initialize() internal{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface CAUContract{
  function multiTransfer(address[] calldata addresses, uint256[] calldata values) external;
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferDelegated(address sender, address to, uint256 fullAmount, uint256 feeAmount, string calldata message, uint nonce, bytes calldata signature) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function controllerAddresses(address _address) external returns (bool);
  function taxReceiver() external returns (address);
}

// File: contracts/CacauDigitalStaking.sol

contract CacauDigitalStaking is Ownable{
  using SafeMath for uint256;
  mapping(address => bool) public controllerAddresses;
  string public name;
  uint256 public fullStockAmount;
  uint256 public investedAmount;
  uint256 public currentInvestedAmount;
  uint256 public tokensForDistribution;
  uint256 public distributedTokens;
  uint256 public investmentsAmount;
  uint256 public currentInvestmentsAmount;
  mapping(address => bool) public hasValueInvested;
  bool public openToInvestment = false;
  CAUContract public token;

  constructor(CAUContract _token, string memory _name, uint256 _fullStockAmount, uint256 _tokensForDistribution) public{
    name = _name;
    token = _token;
    investedAmount = 0;
    investmentsAmount = 0;
    currentInvestmentsAmount = 0;
    distributedTokens = 0;
    fullStockAmount = _fullStockAmount;
    tokensForDistribution = _tokensForDistribution;
  }
  
  modifier onlyControllerOrOwner(){
    require(owner() == _msgSender() || controllerAddresses[_msgSender()] == true, "Ownable: caller is not the owner neither controller.");
    _;
  }
  
  modifier whenOpenToInvestment(){
    require(openToInvestment, "Contract is not open to investment");
    _;
  }

  function registerNewController(address newController) public onlyOwner{
    require(newController != address(0), "Invalid address");
    require(controllerAddresses[newController] == false, "Controller is already registered.");
    controllerAddresses[newController] = true;
  }

  function unregisterController(address controller) public onlyOwner{
    require(controller != address(0), "Invalid address");
    require(controllerAddresses[controller] == true, "Controller is not registered.");
    delete controllerAddresses[controller];
  }
  
  function closeContractToInvestment() public onlyControllerOrOwner{
      require(openToInvestment == true, "Contract is already closed to investment.");
      openToInvestment = false;
  }
  
  function openContractToInvestment() public onlyControllerOrOwner{
      require(openToInvestment == false, "Contract is already oppened to investment.");
      uint256 balance = token.balanceOf(address(this));
      require(tokensForDistribution > 0, "Invalid amount of tokens for distribution.");
      require(tokensForDistribution <= balance, "Invalid initial balance");
      bool isTokenController = token.controllerAddresses(address(this));
      require(isTokenController, "Contract must be token controller to initialize.");
      openToInvestment = true;
  }
  
  function realTokenBalance() public view returns (uint256){
    // Obtaining the contract token balance
    uint256 balance = token.balanceOf(address(this));
    // Removing the investors investments from contract balance
    uint256 realBalance = balance.sub(currentInvestedAmount);
    // Returning the real balance
    return realBalance;
  }
  
  function updateContractToInvestment(uint256 _fullStockAmount, uint256 _tokensForDistribution) public onlyOwner{
      // Obtaining the contract token balance
      uint256 balance = this.realTokenBalance();
      // Verifying if balance is greater than zero
      require(balance > 0, "Balance must be greater than zero.");
      // Summatory of new amount of tokens for distribution
      uint256 completeTokensForDistribution = tokensForDistribution.add(_tokensForDistribution);
      // Summatory of new amount of tokens in stock
      uint256 completeFullStockAmount = fullStockAmount.add(_fullStockAmount);
      // Verifying if the summatory is less or equal to token balance
      require(completeTokensForDistribution <= balance, "Tokens for distribution must be less or equal to token balance");
      // Updating the fullStockAmount
      fullStockAmount = completeFullStockAmount;
      // Updating the tokensForDistribution
      tokensForDistribution = completeTokensForDistribution;
      // Defining contract as open to investment
      openToInvestment = true;
  }
  
  function sumAll(uint256[] memory amounts) private pure returns (uint256 total) {
    uint256 totalAmount = 0;
    // Sum of all values
    for (uint i=0; i < amounts.length; i++) {
        totalAmount = totalAmount.add(amounts[i]);
    }
    require(totalAmount >= amounts[0], "SafeMath: addition overflow");
    
    return totalAmount;
  }
  
  function invest(address sender, uint256 fullAmount, uint256 feeAmount, string memory message, uint nonce, bytes memory signature) public onlyControllerOrOwner whenOpenToInvestment returns (uint256){
      // Certifying there are tokens for distribution
      require(tokensForDistribution > 0, "Insuficient tokens for distribution");
      // Verifying if can pay for fee
      require(feeAmount < fullAmount, "Unable to pay for fee");
      // Obtaining the amount without fee
      uint256 finalAmount = fullAmount.sub(feeAmount);
      // Verifying if the investment value is less than stock available
      require(finalAmount <= fullStockAmount, "Investment value must be less or equal to stock available.");
      // Calculating the final value invested
      uint256 finalValueInvested = fullAmount.sub(feeAmount);
      // Updating the full stock amount
      fullStockAmount = fullStockAmount.sub(finalValueInvested);
      // Updating invested amount
      investedAmount = investedAmount.add(finalValueInvested);
      // Updating current invested amount
      currentInvestedAmount = currentInvestedAmount.add(finalValueInvested);
      if(!hasValueInvested[sender]){
        // Updating investments amount
        investmentsAmount = investmentsAmount.add(1);
        // Updating current investments amount
        currentInvestmentsAmount = currentInvestmentsAmount.add(1);
        // Setting the sender as invested
        hasValueInvested[sender] = true;
      }
      // Desactivating contract for investment if fullStockAmount was reached
      if(fullStockAmount == 0){
          openToInvestment = false;
      }
      
      // Executing the transfer to this contract
      token.transferDelegated(sender, address(this), fullAmount, feeAmount, message, nonce, signature);
      // Returning the new full stock amount
      return fullStockAmount;
  }

  function multipleRedeem(address[] memory _addresses, uint256[] memory _fullAmounts, uint256[] memory _gains) public onlyControllerOrOwner returns (uint256) {
    // Getting the gains array size
    uint gainsSize = _gains.length;
    // Getting the amounts array size
    uint amountsSize = _fullAmounts.length;
    // Verifying if the length of arrays are the same
    require(amountsSize == gainsSize, "The size of _amounts and _gains lists must be the same");
    // Verifying if lists exceeds the investments amount
    require(amountsSize <= currentInvestmentsAmount, "Redeemption amount must be less or equal to investments amount.");
    // Updating investment status of all investors
    for(uint i=0; i < gainsSize; i++){
      hasValueInvested[_addresses[i]] = false;
    }
    // Updating current investments amount
    currentInvestmentsAmount = currentInvestmentsAmount.sub(amountsSize);
    // Obtaining the summatory of all gains
    uint256 allGains = sumAll(_gains);
    uint256 allAmounts = sumAll(_fullAmounts);
    uint256 amountsWithoutGains = allAmounts.sub(allGains);
    // Verifying if gains are available to transfer
    require(allGains <= tokensForDistribution, "Total gains must be less than tokens available for distribution.");
    // Updating current invested amount
    currentInvestedAmount = currentInvestedAmount.sub(amountsWithoutGains);
    // Updating tokens already distributed
    distributedTokens = distributedTokens.add(allGains);
    // Updating the amount of tokens available for distribution
    tokensForDistribution = tokensForDistribution.sub(allGains);
    if(tokensForDistribution == 0){
        openToInvestment = false;
    }
    
    // Executing the multiple transfer
    token.multiTransfer(_addresses, _fullAmounts);
    // Returning the new token distribution amount
    return tokensForDistribution;
  }

  function redeem(address _address, uint256 _fullAmount, uint256 _feeAmount, uint256 _gain) public onlyControllerOrOwner returns (uint256){
    // Verifying if the gain is less than the token available for distribution
    require(_gain <= tokensForDistribution, "Gain must be less than tokens available for distribution.");
    // Verifying if can pay for fee
    require(_fullAmount > _feeAmount, "Unable to pay for fee");
    // Verifying if there are investments to redeem
    require(hasValueInvested[_address], "All investments were redeemed.");
    // Updating investment status of investor
    hasValueInvested[_address] = false;
    // Calculating the amount without fee
    uint256 finalAmount = _fullAmount.sub(_feeAmount);
    // Obtaining the amount without the gain
    uint256 amountWithoutGain = _fullAmount.sub(_gain);
    // Updating current investments amount
    currentInvestmentsAmount = currentInvestmentsAmount.sub(1);
    // Updating current invested amount
    currentInvestedAmount = currentInvestedAmount.sub(amountWithoutGain);
    // Updating tokens already distributed
    distributedTokens = distributedTokens.add(_gain);
    // Updating the amount of tokens available for distribution
    tokensForDistribution = tokensForDistribution.sub(_gain);
    if(tokensForDistribution == 0){
        openToInvestment = false;
    }
    
    // Executing the transfer
    token.transfer(_address, finalAmount);
    address taxReceiver = token.taxReceiver();
    token.transfer(taxReceiver, _feeAmount);
    
    // Returning the new token distribution amount
    return tokensForDistribution;
  }
  
  function finishContract() public onlyControllerOrOwner{
     // Verifying if all investments were redeemed
     require(currentInvestmentsAmount == 0, "There are still open investments.");
     // Obtaining the contract token balance
     uint256 balance = token.balanceOf(address(this));
     if(balance > 0){
       // Returning to the Cacau Digital the tokens left when the contract is finalized
       token.transfer(address(token), balance);
     }
     // Reinitializing variables
     fullStockAmount = 0;
     tokensForDistribution = 0;
     openToInvestment = false;
     currentInvestedAmount = 0;
  }
}