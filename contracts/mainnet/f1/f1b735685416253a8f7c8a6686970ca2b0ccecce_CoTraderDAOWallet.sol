/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

pragma solidity ^0.6.0;


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
interface IConvertPortal {
  function isConvertibleToCOT(address _token, uint256 _amount)
  external
  view
  returns(uint256);

  function isConvertibleToETH(address _token, uint256 _amount)
  external
  view
  returns(uint256);

  function convertTokenToCOT(address _token, uint256 _amount)
  external
  returns (uint256 cotAmount);

  function convertETHToCOT(uint256 _amount)
  external
  payable
  returns (uint256 cotAmount);

  function convertTokenToCOTViaETHHelp(address _token, uint256 _amount)
  external
  returns (uint256 cotAmount);
}
interface IStake {
  function notifyRewardAmount(uint256 reward) external;
}
/**
* This contract get platform % from CoTrader managers profit and then distributes assets
* to burn, stake and platform
*
* NOTE: 51% CoTrader token holders can change owner of this contract
*/







// SPDX-License-Identifier: MIT



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}





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


contract CoTraderDAOWallet is Ownable{
  using SafeMath for uint256;
  // COT address
  IERC20 public COT;
  // exchange portal for convert tokens to COT
  IConvertPortal public convertPortal;
  // stake contract
  IStake public stake;
  // array of voters
  address[] public voters;
  // voter => candidate
  mapping(address => address) public candidatesMap;
  // voter => register status
  mapping(address => bool) public votersMap;
  // this contract recognize ETH by this address
  IERC20 constant private ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
  // burn address
  address public deadAddress = address(0x000000000000000000000000000000000000dEaD);
  // destribution percents
  uint256 public burnPercent = 50;
  uint256 public stakePercent = 10;
  uint256 public withdrawPercent = 40;


  /**
  * @dev contructor
  *
  * @param _COT                           address of CoTrader ERC20
  * @param _stake                         address of Stake contract
  * @param _convertPortal                 address of exchange contract
  */
  constructor(address _COT, address _stake, address _convertPortal) public {
    COT = IERC20(_COT);
    stake = IStake(_stake);
    convertPortal = IConvertPortal(_convertPortal);
  }

  // send assets to burn address
  function _burn(IERC20 _token, uint256 _amount) private {
    uint256 cotAmount = (_token == COT)
    ? _amount
    : convertTokenToCOT(address(_token), _amount);

    if(cotAmount > 0)
      COT.transfer(deadAddress, cotAmount);
  }

  // send assets to stake contract
  function _stake(IERC20 _token, uint256 _amount) private {
    uint256 cotAmount = (_token == COT)
    ? _amount
    : convertTokenToCOT(address(_token), _amount);

    if(cotAmount > 0){
      COT.transfer(address(stake), cotAmount);
      stake.notifyRewardAmount(cotAmount);
    }
  }

  // send assets to owner
  function _withdraw(IERC20 _token, uint256 _amount) private {
    if(_amount > 0)
      if(_token == ETH_TOKEN_ADDRESS){
        payable(owner).transfer(_amount);
      }else{
        _token.transfer(owner, _amount);
      }
  }

  /**
  * @dev destribute assest from this contract to stake, burn, and owner of this contract
  *
  * @param tokens                          array of token addresses for destribute
  */
  function destribute(IERC20[] memory tokens) external {
   for(uint i = 0; i < tokens.length; i++){
      // get current token balance
      uint256 curentTokenTotalBalance = getTokenBalance(tokens[i]);

      // get destribution percent
      uint256 burnAmount = curentTokenTotalBalance.div(100).mul(burnPercent);
      uint256 stakeAmount = curentTokenTotalBalance.div(100).mul(stakePercent);
      uint256 managerAmount = curentTokenTotalBalance.div(100).mul(withdrawPercent);

      // destribute
      _burn(tokens[i], burnAmount);
      _stake(tokens[i], stakeAmount);
      _withdraw(tokens[i], managerAmount);
    }
  }

  // return balance of ERC20 or ETH for this contract
  function getTokenBalance(IERC20 _token) public view returns(uint256){
    if(_token == ETH_TOKEN_ADDRESS){
      return address(this).balance;
    }else{
      return _token.balanceOf(address(this));
    }
  }

  /**
  * @dev Owner can withdraw non convertible token if this token,
  * can't be converted to COT directly or to COT via ETH
  *
  *
  * @param _token                          address of token
  * @param _amount                         amount of token
  */
  function withdrawNonConvertibleERC(address _token, uint256 _amount) external onlyOwner {
    uint256 cotReturnAmount = convertPortal.isConvertibleToCOT(_token, _amount);
    uint256 ethReturnAmount = convertPortal.isConvertibleToETH(_token, _amount);

    require(IERC20(_token) != ETH_TOKEN_ADDRESS, "token can not be a ETH");
    require(cotReturnAmount == 0, "token can not be converted to COT");
    require(ethReturnAmount == 0, "token can not be converted to ETH");

    IERC20(_token).transfer(owner, _amount);
  }

  /**
  * Owner can update total destribution percent
  *
  *
  * @param _stakePercent          percent to stake
  * @param _burnPercent           percent to burn
  * @param _withdrawPercent       percent to withdraw
  */
  function updateDestributionPercent(
    uint256 _stakePercent,
    uint256 _burnPercent,
    uint256 _withdrawPercent
  )
   external
   onlyOwner
  {
    require(_withdrawPercent <= 40, "Too big for withdraw");

    stakePercent = _stakePercent;
    burnPercent = _burnPercent;
    withdrawPercent = _withdrawPercent;

    uint256 total = _stakePercent.add(_burnPercent).add(_withdrawPercent);
    require(total == 100, "Wrong total");
  }

  /**
  * @dev this function try convert token to COT via DEXs which has COT in circulation
  * if there are no such pair on this COT supporting DEXs, function try convert to COT on another DEXs
  * via convert ERC20 input to ETH, and then ETH to COT on COT supporting DEXs.
  * If such a conversion is not possible return 0 for cotAmount
  *
  *
  * @param _token                          address of token
  * @param _amount                         amount of token
  */
  function convertTokenToCOT(address _token, uint256 _amount)
    private
    returns(uint256 cotAmount)
  {
    // try convert current token to COT directly
    uint256 cotReturnAmount = convertPortal.isConvertibleToCOT(_token, _amount);
    if(cotReturnAmount > 0) {
      // Convert via ETH directly
      if(IERC20(_token) == ETH_TOKEN_ADDRESS){
        cotAmount = convertPortal.convertETHToCOT.value(_amount)(_amount);
      }
      // Convert via COT directly
      else{
        IERC20(_token).approve(address(convertPortal), _amount);
        cotAmount = convertPortal.convertTokenToCOT(address(_token), _amount);
      }
    }
    // Convert current token to COT via ETH help
    else {
      // Try convert token to cot via eth help
      uint256 ethReturnAmount = convertPortal.isConvertibleToETH(_token, _amount);
      if(ethReturnAmount > 0) {
        IERC20(_token).approve(address(convertPortal), _amount);
        cotAmount = convertPortal.convertTokenToCOTViaETHHelp(address(_token), _amount);
      }
      // there are no way convert token to COT
      else{
        cotAmount = 0;
      }
    }
  }

  // owner can change version of exchange portal contract
  function changeConvertPortal(address _newConvertPortal)
   external
   onlyOwner
  {
    convertPortal = IConvertPortal(_newConvertPortal);
  }

  // owner can set new stake address for case if previos stake progarm finished
  function updateStakeAddress(address _newStake) external onlyOwner {
    stake = IStake(_newStake);
  }


  /*
  ** VOTE LOGIC
  *
  *  users can change owner if total COT balance of all voters for a certain candidate
  *  more than 50% of COT total supply
  *
  */

  // register a new vote wallet
  function voterRegister() external {
    require(!votersMap[msg.sender], "not allowed register the same wallet twice");
    // register a new wallet
    voters.push(msg.sender);
    votersMap[msg.sender] = true;
  }

  // vote for a certain candidate address
  function vote(address _candidate) external {
    require(votersMap[msg.sender], "wallet must be registered to vote");
    // vote for a certain candidate
    candidatesMap[msg.sender] = _candidate;
  }

  // return half of (total supply - burned balance)
  function calculateCOTHalfSupply() public view returns(uint256){
    uint256 supply = COT.totalSupply();
    uint256 burned = COT.balanceOf(deadAddress);
    return supply.sub(burned).div(2);
  }

  // calculate all vote subscribers for a certain candidate
  // return balance of COT of all voters of a certain candidate
  function calculateVoters(address _candidate) public view returns(uint256){
    uint256 count;
    for(uint i = 0; i<voters.length; i++){
      // take into account current voter balance
      // if this user voted for current candidate
      if(_candidate == candidatesMap[voters[i]]){
          count = count.add(COT.balanceOf(voters[i]));
      }
    }
    return count;
  }

  // Any user can change owner with a certain candidate
  // if this candidate address have 51% voters
  function changeOwner(address _newOwner) external {
    // get vote data
    uint256 totalVotersBalance = calculateVoters(_newOwner);
    // get half of COT supply in market circulation
    uint256 totalCOT = calculateCOTHalfSupply();
    // require 51% COT on voters balance
    require(totalVotersBalance > totalCOT);
    // change owner
    _transferOwnership(_newOwner);
  }

  // fallback payable function to receive ether from other contract addresses
  fallback() external payable {}
}