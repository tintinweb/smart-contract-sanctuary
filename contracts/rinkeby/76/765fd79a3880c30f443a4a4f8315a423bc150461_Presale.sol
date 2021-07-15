/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// -License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File @openzeppelin/contracts/utils/[email protected]

// -License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// -License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

// -License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File IPresale.sol

// -License-Identifier: UNLICENSED
// Author: The Defi Network
// Copyright 2021

pragma solidity ^0.8.4;

interface IPresale {
  //
  // ENUMS
  //

  //
  // VIEW FUNCTIONS
  //

  /**
   * @notice The address owning the project being presold
   * @return address The project owner address
   */
  function tokenAddress() external view returns (address);

  /**
   * @notice The amount of tokens to be pre-sold
   * @return uint256 The amount of tokens
   */
  function tokenAmount() external view returns (uint256);

  /**
   * @notice The price of tokens per ETH
   * @return uint256 The token price
   */
  function price() external view returns (uint256);

  /**
   * @notice The block when the presale begins
   * @return uint256 The block number
   */
  function startBlock() external view returns (uint256);

  /**
   * @notice The block when the presale ends
   * @return uint256 The block number
   */
  function endBlock() external view returns (uint256);

  /**
   * @notice The soft cap the project intends to hit
   * @return uint256 The amount in ETH
   */
  function softCap() external view returns (uint256);

  /**
   * @notice The hard cap the project intends to hit
   * @return uint256 The amount in ETH
   */
  function hardCap() external view returns (uint256);

  /**
   * @notice The minimum amount of ETH that could be used to buy in
   * @return uint256 The amount in ETH
   */
  function minBuy() external view returns (uint256);

  /**
   * @notice The maxmium amount of ETH that could be used to buy in
   * @return uint256 The amount in ETH
   */
  function maxBuy() external view returns (uint256);


  /**
   * @notice Returns the number of tokens bought by a wallet
   * @param _wallet The wallet address
   * @return uint256 Number of tokens
   */
  function tokensBought(address _wallet) external view returns (uint256);

  /**
   * @notice Returns the if address has claimed or not
   * @param _wallet The wallet address
   * @return bool Has wallet claimed?
   */
  function hasClaimed(address _wallet) external view returns (bool);

  //
  // FUNCTIONS
  //

  /**
   * @notice Allows a user to participate in the presale and buy the token
   * @param _tokenAmount The amount of tokens the user wants to buy
   */
  function buy(uint256 _tokenAmount) external payable;

  /**
   * @notice Allows a user to claim tokens after presale if the softcap was hit
   */
  function claimTokens() external;

  /**
   * @notice Allows a user to claim ETH if the softcap wasn't hit
   */
  function claimETH() external;

  /**
   * @notice Function to withdraw funds to the launchpad team wallet
   * @param _payee The wallet the funds are withdrawn to
   */
  function withdrawFunds(address _payee) external;

  /**
   * @notice Function to withdraw unsold tokens to the launchpad team wallet
   * @param _payee The wallet the tokens are withdrawn to
   */
  function withdrawUnsoldTokens(address _payee) external;

}


// File Presale.sol

// -License-Identifier: UNLICENSED
// Author: The Defi Network
// Copyright 2021

pragma solidity ^0.8.4;



contract Presale is IPresale, Ownable {
  using SafeMath for uint256;

  //
  // GLOBAL VARS
  //
  
  // The token getting pre-sold
  address public override tokenAddress;
  // The amount of tokens getting pre-sold
  uint256 public override tokenAmount;
  // The price per ETH at presale
  uint256 public override price;
  // The starting block of the presale
  uint256 public override startBlock;
  // The ending block of the presale
  uint256 public override endBlock;
  // The softcap the project intends to hit
  uint256 public override softCap;
  // The hard cap the project intends to hit
  uint256 public override hardCap;
  // The minimum amount that could be used to buy in
  uint256 public override minBuy;
  // The maximum amount that could be used to buy in
  uint256 public override maxBuy;
  // 
  // MAPPINGS
  //

  /**
   * @notice Mapping for tokens bought by the address
   */
  mapping(address => uint256) public override tokensBought;

  /**
   * @notice Mapping for address if it has claimed or not
   */
  mapping(address => bool) public override hasClaimed;


  //
  // FUNCTIONS
  //

  /**
   * @notice Initialize a Presale contract
   * @param _tokenAddress The token getting pre-sold
   * @param _tokenAmount The amount of tokens getting pre-sold
   * @param _price The price per ETH at presale
   * @param _startBlock The starting block of the presale
   * @param _endBlock The ending block of the presale
   * @param _softCap The soft cap the project intends to hit
   * @param _hardCap The hard cap the project intends to hit
   * @param _minBuy The minimum amount that could be used to buy in
   * @param _maxBuy The maxmium amount that could be used to buy in
   */
  constructor( 
    address _tokenAddress, uint256 _tokenAmount, uint256 _price, 
    uint256 _startBlock, uint256 _endBlock, uint256 _softCap, uint256 _hardCap, 
    uint256 _minBuy, uint256 _maxBuy
  ) {
    // Initalize presale variables
    tokenAddress = _tokenAddress;
    tokenAmount = _tokenAmount;
    price = _price;
    startBlock = _startBlock;
    endBlock = _endBlock;
    softCap = _softCap;
    hardCap = _hardCap;
    minBuy = _minBuy;
    maxBuy = _maxBuy;
  }
  
  /**
   * @notice Allows a user to participate in the presale and buy the token
   * @param _tokenAmount The amount of tokens the user wants to buy
   */
  function buy(uint256 _tokenAmount) external override payable {
    // Check if presale has began
    require(block.number >= startBlock, "Presale::buy: Presale hasn't started");
    // Check if presale has ended
    require(block.number < endBlock, "Presale::buy: Presale has ended");

    // Check if correct amount of ETH is sent
    require(msg.value == _tokenAmount.mul(price),
      "Presale::buy: Wrong amount of ETH sent");
    // Check if hardcap is hit
    require(address(this).balance.add(msg.value) < hardCap, 
      "Presale::buy: Hardcap has been hit");

    // Add to the tokens bought by the user
    tokensBought[_msgSender()] = tokensBought[_msgSender()].add(_tokenAmount);

    // Check if token amount is atleast as much as min buy
    require(tokensBought[_msgSender()] >= minBuy.mul(price), 
      "Presale::buy: Tokens bought should exceed mininum amount");
    // Check if token amount is atmost as much as max buy
    require(tokensBought[_msgSender()] <= maxBuy.mul(price), 
      "Presale::buy: Tokens bought should exceed mininum amount");
  }

  /**
   * @notice Allows a user to claim tokens after presale if the softcap was hit
   */
  function claimTokens() external override {
    require(block.number > endBlock, 
      "Presale::claimTokens: Presale hasn't ended yet");
    require(address(this).balance >= softCap, 
      "Presale::claimTokens: Soft cap wasn't hit");
    require(hasClaimed[_msgSender()] , 
      "Presale::claimTokens: Address has already claimed tokens");
    
    // Transfer the tokens bought
    IERC20(tokenAddress).transfer(_msgSender(), tokensBought[_msgSender()]);
    // User has now claimed
    hasClaimed[_msgSender()] = true;
  }

  /**
   * @notice Allows a user to claim ETH after presale if the softcap wasn't hit
   */
  function claimETH() external override {
    require(block.number >= endBlock, 
      "Presale::claimETH: Presale hasn't ended yet");
    require(address(this).balance < softCap, 
      "Presale::claimETH: Soft cap was hit");
    require(hasClaimed[_msgSender()] , 
      "Presale::claimETH: Address has already claimed stable");

    // Transfer the ETH sent
    payable(_msgSender()).transfer(tokensBought[_msgSender()].mul(price));
    // User has now claimed
    hasClaimed[_msgSender()] = true;
  }

  /**
   * @notice Function to withdraw funds to the launchpad team wallet
   * @param _payee The wallet the funds are withdrawn to
   */
  function withdrawFunds(address _payee) external override onlyOwner {
    require(block.number >= endBlock, 
      "Presale::withdrawFunds: Presale hasn't ended yet");
    require(address(this).balance >= softCap, 
      "Presale::withdrawFunds: Soft cap wasn't hit");
    require(address(this).balance > 0, 
      "Presale::withdrawFunds: No ETH in contract");
    
    // Transfer the ETH sent
    payable(_payee).transfer(address(this).balance);
  }

  /**
   * @notice Function to withdraw unsold tokens to the launchpad team wallet
   * @param _payee The wallet the funds are withdrawn to
   */
  function withdrawUnsoldTokens(address _payee) external override onlyOwner {
    require(block.number >= endBlock, 
      "Presale::withdrawUnsoldTokens: Presale hasn't ended yet");
    require(IERC20(tokenAddress).balanceOf(address(this)) > 0, 
      "Presale::withdrawUnsoldTokens: No Unsold tokens in contract");
    
    IERC20(tokenAddress).transfer(
      _payee, IERC20(tokenAddress).balanceOf(address(this)));
  }

  receive() payable external {}
}