//SourceUnit: Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


//SourceUnit: ITRC20.sol

/// TRC20.sol -- API for the TRC20 token standard

// See <https://github.com/tronprotocol/tips/blob/master/tip-20.md>.

// This file likely does not meet the threshold of originality
// required for copyright to apply.  As a result, this is free and
// unencumbered software belonging to the public domain.

pragma solidity ^0.5.8;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: JustSwap.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./SafeMath.sol";

/**
 * @title JustSwapExchange interface
 * @dev see https://www.justswap.io/docs/justswap-interfaces_en.pdf
 */
interface IJustSwapExchange {
    function getTokenToTrxInputPrice(uint256 tokenSold) external view returns (uint256);
	function getTrxToTokenInputPrice(uint256 trxSold) external view returns (uint256);
	
	function getTokenToTrxOutputPrice(uint256 trxBought) external view returns (uint256);
}

/**
 * @title JustSwapFactory interface
 * @dev see https://www.justswap.io/docs/justswap-interfaces_en.pdf
 */
interface IJustSwapFactory {
    function getExchange(address token) external view returns (address payable);
}

contract JustSwapOracle {
    using SafeMath for uint256;
    
    // JustSwap factory, see https://www.justswap.io/docs/justswap-interfaces_en.pdf
    IJustSwapFactory factory = IJustSwapFactory(address(0x41eed9e56a5cddaa15ef0c42984884a8afcf1bdebb));
    
    function assetToTrx(address token, uint256 amountAsset)
        public view returns (uint256) {
            
        IJustSwapExchange exchange = IJustSwapExchange(factory.getExchange(token));
        return exchange.getTokenToTrxInputPrice(amountAsset);
    }
    
    function minAssetToSwap(address token)
        public view returns (uint256) {
            
        IJustSwapExchange exchange = IJustSwapExchange(factory.getExchange(token));
        return exchange.getTokenToTrxOutputPrice(10 ** 6);
    }
    
    function trxToAsset(address token, uint256 amountTrx)
        public view returns (uint256) {
        
        IJustSwapExchange exchange = IJustSwapExchange(factory.getExchange(token));
        return exchange.getTokenToTrxOutputPrice(amountTrx);
    }
}


//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier owned() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public owned {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public owned {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: PATMOrder.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./Rescuable.sol";
import "./SafeMath.sol";
import "./JustSwap.sol";

contract PATMOrderV2 is JustSwapOracle, Rescuable {
    using SafeMath for uint256;
    
    // PATM token
    ITRC20 public PATM;
    
    function setPATM(address patm_) external owned {
        PATM = ITRC20(patm_);
    }
    
    // Token allowance
    mapping (address => bool) public allowedTokens;
    
    function setTokenAllowance(address token, bool status) external owned {
        allowedTokens[token] = status;
    }
    
    // Batch info
    struct OrderInfo {
        bool exists;
        uint256 pricePerATMInTrx;
        uint256 totalATMAmount;
        uint256 soldATMAmount;
    }
    
    mapping (string => OrderInfo) public batches;
    
    function setBatch(string calldata batch, uint256 price, uint256 amount, uint256 sold) external owned {
        batches[batch] = OrderInfo({
            exists: true,
            pricePerATMInTrx: price,
            totalATMAmount: amount,
            soldATMAmount: sold
        });
    }
    
    function batchInfo(string memory batch) internal view returns (OrderInfo storage) {
        OrderInfo storage info = batches[batch];
        require(info.exists, "exists");
        return info;
    }
    
    // Buy
    function buy(string memory batch) public payable returns (uint256 shouldBought, uint256 actualBought) {
        uint256 amountTrx = msg.value;
        
        // Caculate the wanted amount to buy
        shouldBought = buyAmountByTrx(batch, amountTrx);
        require(shouldBought > 0, "too-few");
        
        // Caculate the available amount to buy
        uint256 available = availableAmount(batch);
        require(available > 0, "sold-out");
        actualBought = shouldBought > available ? available : shouldBought;
        
        // Transfer out the PATM
        PATM.safeTransfer(msg.sender, actualBought.mul(10 ** 6));
        
        // Transfer back the remaining TRX
        if (shouldBought > available) {
            uint256 cost = buyPriceInTrx(batch, actualBought);
            uint256 remaining = amountTrx.sub(cost);
            msg.sender.transfer(remaining);
        }
        
        // Update the sold amount
        OrderInfo storage info = batchInfo(batch);
        info.soldATMAmount = info.soldATMAmount.add(actualBought);
        
        return (shouldBought, actualBought);
    }
    
    function buy(string memory batch, address token, uint256 amountToken) public returns (uint256 shouldBought, uint256 actualBought) {
        require(allowedTokens[token], "token-not-allowed");
        
        // Caculate the wanted amount to buy
        shouldBought = buyAmountByToken(batch, token, amountToken);
        require(shouldBought > 0, "too-few");
        
        // Caculate the available amount to buy
        uint256 available = availableAmount(batch);
        require(available > 0, "sold-out");
        actualBought = shouldBought > available ? available : shouldBought;
        
        // Transfer out the PATM
        PATM.safeTransfer(msg.sender, actualBought.mul(10 ** 6));
        
        // Transfer in the cost token
        uint256 cost = buyPriceInToken(batch, token, actualBought);
        ITRC20(token).safeTransferFrom(msg.sender, address(this), cost);
        
        // Update the sold amount
        OrderInfo storage info = batchInfo(batch);
        info.soldATMAmount = info.soldATMAmount.add(actualBought);
        
        return (shouldBought, actualBought);
    }
    
    // Buy amount
    function buyAmountByTrx(string memory batch, uint256 amountTrx) public view returns (uint256) {
        return amountTrx.div(batchInfo(batch).pricePerATMInTrx);
    }
    
    function buyAmountByToken(string memory batch, address token, uint256 amountToken) public view returns (uint256) {
        return amountToken.div(pricePerInToken(batch, token));
    }
    
    // Buy price
    function buyPriceInTrx(string memory batch, uint256 amountATM) public view returns (uint256) {
        return amountATM.mul(batchInfo(batch).pricePerATMInTrx);
    }
    
    function buyPriceInToken(string memory batch, address token, uint256 amountATM) public view returns (uint256) {
        uint256 priceInToken = pricePerInToken(batch, token);
        return amountATM.mul(priceInToken);
    }
    
    // Per price
    function pricePerInTrx(string memory batch) public view returns (uint256) {
        return batchInfo(batch).pricePerATMInTrx;
    }
    
    function pricePerInToken(string memory batch, address token) public view returns (uint256) {
        uint256 priceInToken = trxToAsset(token, pricePerInTrx(batch));
        return priceInToken == 0 ? 1 : priceInToken;
    }
    
    // Amount
    function totalAmount(string memory batch) public view returns (uint256) {
        return batchInfo(batch).totalATMAmount;
    }
    
    function soldAmount(string memory batch) public view returns (uint256) {
        return batchInfo(batch).soldATMAmount;
    }
    
    function availableAmount(string memory batch) public view returns (uint256) {
        OrderInfo memory info = batchInfo(batch);
        return info.totalATMAmount.sub(info.soldATMAmount);
    }
}


//SourceUnit: Rescuable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./Ownable.sol";
import "./SafeTRC20.sol";
import "./ITRC20.sol";

contract Rescuable is Ownable {
    using SafeTRC20 for ITRC20;
    
    event Rescue(address indexed to, uint256 amount);
    event Rescue(address indexed to, address indexed token, uint256 amount);

    function rescue(address payable to, uint256 amount) external owned {
        require(to != address(0), "zeroaddr");
        require(amount > 0, "nonzero");

        to.transfer(amount);
        emit Rescue(to, amount);
    }
    
    function rescue(ITRC20 token, address to, uint256 amount) external owned {
        require(to != address(0), "zeroaddr");
        require(amount > 0, "nonzero");

        token.safeTransfer(to, amount);
        emit Rescue(to, address(token), amount);
    }
}


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

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

//SourceUnit: SafeTRC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./SafeMath.sol";
import "./Address.sol";
import "./ITRC20.sol";

library SafeTRC20 {
    address internal constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        if (address(token) == USDTAddr) {
            (bool success, ) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success, "SafeTRC20: low-level call failed");
        } else {
            callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeTRC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeTRC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
}