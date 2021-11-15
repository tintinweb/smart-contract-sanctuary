// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './contexts/BuildableContext.sol';
import './interfaces/IBEP20.sol';
import './interfaces/ICarrier.sol';
import './libraries/SafeMath.sol';

contract TokenCarrier is BuildableContext {

    using SafeMath for uint256;

    IBEP20 private _carrierToken;
    uint256 private _carrierTokenDecimalFactor;

    uint256 private _liquidityTokenDecimalFactor;

    uint256 private _maxPurchaseRate;

    constructor(address carrierToken) {
        _carrierToken = IBEP20(carrierToken);
        _carrierTokenDecimalFactor = 10**_carrierToken.decimals();

        _liquidityTokenDecimalFactor = 10**(18);

        _maxPurchaseRate = 1000 * _liquidityTokenDecimalFactor;
    }

    // ----- TOKEN CARRIER FUNCTIONS ----- //
    // ----------------------------------- //

    function carrierToken() public view returns (address) {
        return address(_carrierToken);
    }

    function carry(address from, address to, uint256 amount) external returns (bool) {
        require(_msgSender() == address(_carrierToken), "Carry: carry method muct be called by calliable token");

        _carrierToken.transfer(to, amount);

        return true;
    }
    
    // @dev function injectLiquidity() - public payable method used to inject liquidity without recieving tokens
    function injectLiquidity() public payable returns (bool) {
        return true;
    }
    // ----- PURCHASE FUNCTIONS ----- //
    // ------------------------------- //

    // function purchaseRate() - returns the raw number of carrier tokerns given per liquidity token
    function purchaseRate() public view returns (uint256) {
        return _purchaseRate();
    }

    function purchaseRateMax() public view returns (uint256) {
        return _maxPurchaseRate;
    }

    function _purchaseRate() internal view returns (uint256) {
        uint256 currentPurchaseRate = _carrierToken.totalSupply().mul(_liquidityTokenDecimalFactor).div(address(this).balance.mul(_carrierTokenDecimalFactor));
        if(currentPurchaseRate > _maxPurchaseRate){
            return _maxPurchaseRate;
        } else {
            return currentPurchaseRate;
        }
    }

    // @dev function purchase() - public function for purchasing carrier tokens with liquidity tokens; liquidity token allowance must be provided first
    function purchase() public payable returns (bool) {
        uint256 avalible = _carrierToken.balanceOf(address(this));
        uint256 owed = msg.value.mul(_purchaseRate()).div(_liquidityTokenDecimalFactor);

        require(avalible >= owed, "Purchase: not enough carrier token avalible");

        _carrierToken.transfer(_msgSender(), owed);

        return true;
    }

    

    function setPurchaseRateMax(uint256 purchaseRateMax) external onlyFactory returns (bool) {
        _maxPurchaseRate = purchaseRateMax;
        return true;
    }

    // ----- LIQUIDATE FUNCTIONS ----- //
    // ------------------------------- //

    // @dev function liquidationRate() - returns the raw number of liquidity tokens given per carrier token 
    function liquidationRate() public view returns (uint256) {
        return _liquidationRate();
    }

    function _liquidationRate() internal view returns (uint256) {
        return address(this).balance.mul(_carrierTokenDecimalFactor).div(_carrierToken.totalSupply().mul(_liquidityTokenDecimalFactor));
    }

    // @dev function liquidate() - public function for liquidating carrier tokens for liquidity tokens; carried token allowance must be provided first
    function liquidate(uint256 carriedToSwap) public returns (bool) {
        uint256 allowance = _carrierToken.allowance(_msgSender(), address(this));
        uint256 avalible = address(this).balance;

        require(allowance >= carriedToSwap, "Liquidate: not enough carried token allowance provided");

        uint256 owed = carriedToSwap.mul(_liquidationRate()).div(_carrierTokenDecimalFactor);

        require(avalible >= owed, "Purchase: not enough carrier liquidity avalible");

        payable(_msgSender()).transfer(owed);
        _carrierToken.transferFrom(_msgSender(), address(this), carriedToSwap);

        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './CallableContext.sol';

contract BuildableContext is CallableContext {

    address internal _factory;


    constructor() {
        _factory = _msgSender();
    }


    modifier onlyFactory() {
        require(_msgSender() == _factory, "Only Factory: caller is not context factory");
        _;
    }


    function factory() external view returns (address){
        return _factory;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract CallableContext {

    function _context() internal view returns (address) {
        return address(this);
    }
    

    function _msgSender() internal view returns (address) {
        return address(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }

    function _msgTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IBEP20 {

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ICarrier {

    function carry(address from, address to, uint256 amount) external returns (bool);

}

pragma solidity ^0.8.6;
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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
  
}

