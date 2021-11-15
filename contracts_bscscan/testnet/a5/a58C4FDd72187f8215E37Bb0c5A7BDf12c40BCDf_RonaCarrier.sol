// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './contexts/OwnableContext.sol';
import './interfaces/IBEP20.sol';
import './libraries/SafeMath.sol';

contract RonaCarrier is OwnableContext {

    using SafeMath for uint256;


    IBEP20 private _carrierToken;

    IBEP20 private _claimableToken;

    uint256 private _carrierTokenDecimalFactor;
    uint256 private _liquidityTokenDecimalFactor;


    uint256 private _maxPurchaseRate;
    
    // Enable or Disable Purchase, Liquify, and Claim
    bool private _purchaseIsOpen;
    bool private _liquidationIsOpen;
    bool private _claimIsOpen;
    

    // Fee Percentages
    uint256 private _feeServicePercentage = 1;
    uint256 private _feeCharityPercentage = 3;
    uint256 private _feeLiquidityPoolPercentage = 3;
    uint256 private _feeHoldersPercentage = 3;


    // Fee Recievers
    address private _serviceFeeReciever;
    address private _charityFeeReciever;

    
    // Blocked Distributions
    uint256 private _reflectionPoolHoldings = 0;
    uint256 private _reflectionsTotalCount = 0;
    mapping(address => uint256) private _reflectionsTotalCountUsed;
    uint256 private _reflectionsTotalNumberRecievers = 0;



    constructor(address carrierTokenAddress, uint256 initialMaxPurchaseRate, address claimableTokenAddress) {

        _carrierToken = IBEP20(carrierTokenAddress);
        _carrierTokenDecimalFactor = 10**_carrierToken.decimals();

        _liquidityTokenDecimalFactor = 10**(18);

        // initialize max purchase rate
        _maxPurchaseRate = initialMaxPurchaseRate*_liquidityTokenDecimalFactor;


        _serviceFeeReciever = _msgSender();
        _charityFeeReciever = _msgSender();

        // initialize purchase and liquidation
        _purchaseIsOpen = false;
        _liquidationIsOpen = false;

        // initialize claim
        _claimableToken = IBEP20(claimableTokenAddress);
        _claimIsOpen = false;
        
    }



    // ----- LIQUIDITY INJECTION ----- //

    function injectLiquidity() public payable returns (bool) {
        emit LiquidityInject(_msgSender(), msg.value);
        return true;
    }

    event LiquidityInject(address from, uint256 amount);

    // ------------------------------- //



    // ----- REFLECTION FUNCTIONS ----- //

    function _reflect(uint256 tokenToReflect, address reflectTo) internal {
        _reflectionPoolHoldings = _reflectionPoolHoldings.add(tokenToReflect);
        _reflectionsTotalCount = _reflectionsTotalCount.add(tokenToReflect);

       if(_reflectionsTotalCountUsed[reflectTo] == 0) {
           _reflectionsTotalCountUsed[reflectTo] = _reflectionsTotalCount;
           _reflectionsTotalNumberRecievers = _reflectionsTotalNumberRecievers.add(1);

       } else if(_carrierToken.balanceOf(reflectTo) > 0) {
           uint256 owed = _reflectionsTotalCount.sub(_reflectionsTotalCountUsed[reflectTo]).div(_reflectionsTotalNumberRecievers);
           if(owed > 0) {
               _carrierToken.transfer(reflectTo, owed);
               _reflectionPoolHoldings = _reflectionPoolHoldings.sub(owed);
               _reflectionsTotalCountUsed[reflectTo] = _reflectionsTotalCount;
           }
       } else {
           _reflectionsTotalCountUsed[reflectTo] = 0;
           _reflectionsTotalNumberRecievers = _reflectionsTotalNumberRecievers.sub(1);
       }
    }

    // -------------------------------- //



    // ----- CARRY ----- //

    function carrierToken() public view returns (address) {
        return address(_carrierToken);
    }

    function carry(address from, address to, uint256 amount) external returns (bool) {
        require(_msgSender() == address(_carrierToken), "Carry: carry method muct be called by carrier token");

        uint256 serviceFeeAmount = amount.mul(_feeServicePercentage).div(100);
        uint256 charityFeeAmount = amount.mul(_feeCharityPercentage).div(100);
        uint256 holdersFeeAmount = amount.mul(_feeHoldersPercentage).div(100);
        uint256 liquidityPoolFeeAmount = amount.mul(_feeLiquidityPoolPercentage).div(100);

        _carrierToken.transfer(to, amount - (serviceFeeAmount + charityFeeAmount + holdersFeeAmount + liquidityPoolFeeAmount));

        _liquidateInternal(payable(_serviceFeeReciever), serviceFeeAmount, amount);
        _carrierToken.transfer(_charityFeeReciever, charityFeeAmount);
        _reflect(holdersFeeAmount, from);

        return true;
    }
    
    // ----------------- //



    // ----- PURCHASE ----- //

    function purchaseIsOpen() public view returns (bool) {
        return _purchaseIsOpen;
    }

    function purchaseRate() public view returns (uint256) {
        return _purchaseRate();
    }

    function purchaseFeePercentage() public view returns (uint256) {
        return _feeServicePercentage + _feeCharityPercentage + _feeLiquidityPoolPercentage + _feeHoldersPercentage;
    }

    function purchaseRateMax() public view returns (uint256) {
        return _maxPurchaseRate;
    }

    function purchase() public payable returns (bool) {
        require(_purchaseIsOpen, "Purchase: purchase is not open");

        uint256 serviceFeeAmount = msg.value.mul(_feeServicePercentage).div(100);
        uint256 liquidityPoolFeeAmount = msg.value.mul(_feeLiquidityPoolPercentage).div(100);

        uint256 owed = msg.value.sub(serviceFeeAmount + liquidityPoolFeeAmount).mul(_purchaseRateDeducted(msg.value)).div(_liquidityTokenDecimalFactor);


        uint256 charityFeeAmount = owed.mul(_feeCharityPercentage).div(100);
        uint256 holdersFeeAmount = owed.mul(_feeHoldersPercentage).div(100);

        _carrierToken.transfer(_msgSender(), owed - (charityFeeAmount + holdersFeeAmount));
        _carrierToken.transfer(_charityFeeReciever, charityFeeAmount);

        _reflect(holdersFeeAmount, _msgSender());

        payable(_serviceFeeReciever).transfer(serviceFeeAmount);

        emit Purchase(_msgSender(), msg.value, owed - (charityFeeAmount + holdersFeeAmount));

        return true;
    }

    function _purchaseRate() internal view returns (uint256) {
        uint256 currentPurchaseRate = _carrierToken.balanceOf(address(this)).sub(_reflectionPoolHoldings).mul(_liquidityTokenDecimalFactor).div(address(this).balance);
        if(currentPurchaseRate > _maxPurchaseRate){
            return _maxPurchaseRate;
        } else {
            return currentPurchaseRate;
        }
    }

    function _purchaseRateDeducted(uint256 deduction) internal view returns (uint256) {
        uint256 currentPurchaseRate = _carrierToken.balanceOf(address(this)).sub(_reflectionPoolHoldings).mul(_liquidityTokenDecimalFactor).div(address(this).balance.sub(deduction));
        if(currentPurchaseRate > _maxPurchaseRate){
            return _maxPurchaseRate;
        } else {
            return currentPurchaseRate;
        }
    }
    
    function updatePurchaseIsOpen(bool isPurchaseOpen) public onlyOwner returns (bool) {
        _purchaseIsOpen = isPurchaseOpen;
        return true;
    }

    function updatePurchaseRateMax(uint256 newPurchaseRateMax) public onlyOwner returns (bool) {
        _maxPurchaseRate = newPurchaseRateMax;
        return true;
    }

    event Purchase(address buyer, uint256 liquiditySpent, uint256 tokensRecieved);

    // -------------------- //



    // ----- LIQUIDATE ----- //

    function liquidationIsOpen() public view returns (bool) {
        return _liquidationIsOpen;
    }

    function liquidationRate() public view returns (uint256) {
        return _liquidationRate();
    }

    function liquidationFeePercentage() public view returns(uint256) {
        return _liquidationFeeCurrentServicePercentage() + _liquidationFeeCurrentCharityPercentage() + _liquidationFeeCurrentHoldersPercentage() + _liquidationFeeCurrentLiquidityPoolPercentage();
    }

    function liquidate(uint256 tokensToLiquidate) public returns (bool) {
        require(_liquidationIsOpen, "Liquidate: liquidation is not open");

        uint256 allowance = _carrierToken.allowance(_msgSender(), address(this));

        require(allowance >= tokensToLiquidate, "Liquidate: not enough carried token allowance provided");


        uint256 charityFeeAmount = tokensToLiquidate.mul(_liquidationFeeCurrentCharityPercentage()).div(100);
        uint256 holdersFeeAmount = tokensToLiquidate.mul(_liquidationFeeCurrentHoldersPercentage()).div(100);

        uint256 owed = tokensToLiquidate.sub(charityFeeAmount + holdersFeeAmount).mul(_liquidationRate()).div(_carrierTokenDecimalFactor); // as tokens to liquidate have not yet been transfered to the contract yet the stardard _liquidationRate() method call can be used

        uint256 serviceFeeAmount = owed.mul(_liquidationFeeCurrentServicePercentage()).div(100);
        uint256 liquidityPoolFeeAmount = owed.mul(_liquidationFeeCurrentLiquidityPoolPercentage()).div(100);

        payable(_msgSender()).transfer(owed - (serviceFeeAmount + liquidityPoolFeeAmount));
        _carrierToken.transferFrom(_msgSender(), address(this), tokensToLiquidate);

        _carrierToken.transfer(_charityFeeReciever, charityFeeAmount);
        payable(_serviceFeeReciever).transfer(serviceFeeAmount);

        _reflect(holdersFeeAmount, _msgSender());

        emit Liquidation(_msgSender(), tokensToLiquidate, owed - (serviceFeeAmount + liquidityPoolFeeAmount));

        return true;
    }

    function _liquidateInternal(address payable recipiant, uint256 tokensToLiquidate, uint256 deduction) internal {
        uint256 owed = tokensToLiquidate.mul(_liquidationRateDeducted(deduction)).div(_carrierTokenDecimalFactor);

        recipiant.transfer(owed);

        emit Liquidation(recipiant, tokensToLiquidate, owed);
    }

    function _liquidationRate() internal view returns (uint256) {
        return address(this).balance.mul(_carrierTokenDecimalFactor).div(_carrierToken.totalSupply().sub(_carrierToken.balanceOf(address(this)).sub(_reflectionPoolHoldings)));
    }

    function _liquidationRateDeducted(uint256 deduction) internal view returns (uint256) {
        return address(this).balance.mul(_carrierTokenDecimalFactor).div(_carrierToken.totalSupply().sub(_carrierToken.balanceOf(address(this)).sub(_reflectionPoolHoldings).add(deduction)));
    }

    function _liquidationFeeCurrentServicePercentage() internal view returns (uint256) {
        uint256 liquidityPoolHoldings = address(this).balance;

        if(liquidityPoolHoldings < 3500*_liquidityTokenDecimalFactor) {
            return _feeServicePercentage.mul(10);
        }

        return _feeServicePercentage;
    }

    function _liquidationFeeCurrentCharityPercentage() internal view returns (uint256) {
        uint256 liquidityPoolHoldings = address(this).balance;

        if(liquidityPoolHoldings < 3500*_liquidityTokenDecimalFactor) {
            return 0;
        } 
        
        return _feeCharityPercentage;
    }

    function _liquidationFeeCurrentHoldersPercentage() internal view returns (uint256) {
        uint256 liquidityPoolHoldings = address(this).balance;

        if(liquidityPoolHoldings < 3500*_liquidityTokenDecimalFactor) {
            return _feeHoldersPercentage.mul(10);
        }

        return _feeHoldersPercentage;
    }

    function _liquidationFeeCurrentLiquidityPoolPercentage() internal view returns (uint256) {
        uint256 liquidityPoolHoldings = address(this).balance;

        if(liquidityPoolHoldings < 3500*_liquidityTokenDecimalFactor) {
            return _feeLiquidityPoolPercentage.mul(20);
        }

        return _feeLiquidityPoolPercentage;
    }

    function updateLiquidationIsOpen(bool isLiquidationOpen) public onlyOwner returns (bool) {
        _liquidationIsOpen = isLiquidationOpen;
        return true;
    }

    event Liquidation(address seller, uint256 tokensLiquidated, uint256 liquidityRecieved);

    // --------------------- //



    // ----- CLAIM ----- //

    function claimableToken() public view returns (address) {
        return address(_claimableToken);
    }

    function claimIsOpen() public view returns (bool) {
        return _claimIsOpen;
    }

    function claim(uint256 tokensToClaim) public returns (bool) {
        require(_claimIsOpen, "Claim: claim is not open");

        uint256 allowance = _claimableToken.allowance(_msgSender(), address(this));

        // both tokens have 9 decimals so no conversion required for 1-1 claim

        require(allowance >= tokensToClaim, "Claim: not enough token allowance provided");

        _claimableToken.transferFrom(_msgSender(), address(this), tokensToClaim);
        _carrierToken.transfer(_msgSender(), tokensToClaim);

        emit Claim(_msgSender(), tokensToClaim);

        return true;
    }

    function updateClaimIsOpen(bool isClaimOpen) public onlyOwner returns (bool) {
        _claimIsOpen = isClaimOpen;
        return true;
    }

    event Claim(address claimer, uint256 tokensClaimed);

    // ------------------//



    // ----- FEES ----- //
    // ---------------- //

    function feeTotalPercentage() public view returns (uint256) {
        return _feeServicePercentage + _feeCharityPercentage + _feeLiquidityPoolPercentage + _feeHoldersPercentage;
    }

    function feeServicePercentage() public view returns (uint256) {
        return _feeServicePercentage;
    }

    function feeCharityPercentage() public view returns (uint256) {
        return _feeCharityPercentage;
    }

    function feeHoldersPercentage() public view returns (uint256) {
        return _feeHoldersPercentage;
    }

    function feeLiquidityPoolPercentage() public view returns (uint256) {
        return _feeLiquidityPoolPercentage;
    }

    function feeServiceReciever() public view returns (address) {
        return _serviceFeeReciever;
    }

    function feeCharityReciever() public view returns (address) {
        return _charityFeeReciever;
    }

    function updateFeeServicePercentage(uint256 newFeeServicePercentage) public onlyOwner returns (bool){
        require((newFeeServicePercentage + _feeCharityPercentage + _feeHoldersPercentage + _feeLiquidityPoolPercentage) <= 100, "Update fee service percentage: total fee cannot exceed 100");

        _feeServicePercentage = newFeeServicePercentage;

        return true;
    }

    function updateFeeCharityPercentage(uint256 newFeeCharityPercentage) public onlyOwner returns (bool) {
        require((newFeeCharityPercentage + _feeServicePercentage + _feeHoldersPercentage + _feeLiquidityPoolPercentage) <= 100, "Update fee charity percentage: total fee cannot exceed 100");

        _feeCharityPercentage = newFeeCharityPercentage;

        return true;
    }

    function updateFeeHoldersPercentage(uint256 newFeeHoldersPercentage) public onlyOwner returns (bool) {
        require((newFeeHoldersPercentage + _feeServicePercentage + _feeCharityPercentage + _feeLiquidityPoolPercentage) <= 100, "Update fee holders percentage: total fee cannot exceed 100");

        _feeHoldersPercentage = newFeeHoldersPercentage;

        return true;
    }

    function updateFeeLiquidityPoolPercentage(uint256 newFeeLiquidityPoolPercentage) public onlyOwner returns (bool) {
        require((newFeeLiquidityPoolPercentage + _feeServicePercentage + _feeCharityPercentage + _feeHoldersPercentage) <= 100, "Update fee liquidity pool percentage: total fee cannot exceed 100");

        _feeLiquidityPoolPercentage = newFeeLiquidityPoolPercentage;

        return true;
    }

    function updateFeeServiceReciever(address newFeeServiceReciever) public onlyOwner returns (bool) {
        require(newFeeServiceReciever != address(0), "Update service fee reciever: service fee reciever cannot be the 0 address");

        _serviceFeeReciever = newFeeServiceReciever;

        return true;
    }

    function updateFeeCharityReciever(address newFeeCharityReciever) public onlyOwner returns (bool) {
        require(newFeeCharityReciever != address(0), "Update charity fee reciever: charity fee reciever cannot be the 0 address");

        _charityFeeReciever = newFeeCharityReciever;

        return true;
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

import './CallableContext.sol';

contract OwnableContext is CallableContext {

    address internal _owner;


    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }


    modifier onlyOwner() {
        require(_msgSender() == _owner, "Only Owner: caller is not context owner");
        _;
    }


    event OwnershipTransferred(address previousOwner, address newOwner);


    function owner() external view returns (address) {
        return _owner;
    }


    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != _owner, "Transfer Ownership: new owner is already owner");
        require(newOwner != address(0), "Transfer Ownership: new owner cannot be the 0 address");

        address previousOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(previousOwner, _owner);
    }

    function renounceOwnership() external onlyOwner {
        _renounceOwnership();
    }

    function _renounceOwnership() internal {
        address previousOwner = _owner;
        _owner = address(0);

        emit OwnershipTransferred(previousOwner, _owner);
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

