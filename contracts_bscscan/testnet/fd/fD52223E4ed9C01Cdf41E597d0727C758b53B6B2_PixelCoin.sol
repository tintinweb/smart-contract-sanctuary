// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "contracts/utils/AntiWhale.sol";
import "contracts/PBoneSwap.sol";

/**
    @title PixelCoin Token
    @author 🧢🕶 (🎋)
    @notice A deflationary contract that manages a AutoBuyBack, AntiWhale System and PBone Swap
 */

contract PixelCoin is PBoneSwap, AntiWhale {

    using SafeMath for uint256;

    constructor (address router_, address wbnb_) OAuth(msg.sender) {

        router = IDEXRouter(router_);
        WBNB = wbnb_;
        PixelCoinBase._allowances[address(this)][address(router)] = PixelCoinBase._totalSupply;

        Deflation._initializeDeflation();
        PBoneSwap._initializePBoneSwap(2000, 1800);
        AntiWhale._initializeAntiWhale(
            PixelCoinBase._totalSupply,
            PixelCoinBase.rewardPool,
            PixelCoinBase.treasuryPool
        );
        
        approve(router_, PixelCoinBase._totalSupply);
        PixelCoinBase._balances[msg.sender] = PixelCoinBase._totalSupply;
        emit Transfer(address(0), msg.sender, PixelCoinBase._totalSupply);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function approveMax(address spender) public returns (bool) {
        return approve(spender, PixelCoinBase._totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(PixelCoinBase._allowances[sender][msg.sender] != PixelCoinBase._totalSupply){
            PixelCoinBase._allowances[sender][msg.sender] = PixelCoinBase._allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        if(AntiWhale.isCooldownEnabled) { AntiWhale._checkBuyCooldownTime(sender, recipient); }
        if(AntiWhale.isTxLimitEnabled) { AntiWhale._checkTransactionLimit(sender, recipient, amount); }
        if(AutoBuyBack._shouldSwapTokensForETH(sender)){ _triggerSwapTokensForETH(); }
        if(AutoBuyBack._shouldSwapETHForTokensAndBurn(sender)){ _triggerSwapETHForTokensAndBurn(); }
        
        PixelCoinBase._balances[sender] = PixelCoinBase._balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = !AutoBuyBack._isFeeExempt[sender] ? _handleFee(sender, recipient, amount) : amount;

        if(amount != amountReceived) {
            uint256 feeAmount = amount.sub(amountReceived);
            Deflation._distributeFees(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        PixelCoinBase._balances[recipient] = PixelCoinBase._balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _handleFee(address sender, address receiver, uint256 amount) internal view returns (uint256) {
        
        uint256 feeAmount;

        if(AutoBuyBack._isLiquidityPool[sender] == true) { //buy
            feeAmount = amount.mul(Deflation._transferBuyFee).div(100);
        
        } else if(AutoBuyBack._isLiquidityPool[receiver] == true) { //sell
            feeAmount = amount.mul(Deflation._transferSellFee).div(100);
        } else if(
            sender == PixelCoinBase.rewardPool 
            || receiver == PixelCoinBase.rewardPool
            || sender == PixelCoinBase.treasuryPool
            || receiver == PixelCoinBase.treasuryPool
        ) {
            feeAmount = 0;
        } else { // normal trade
            feeAmount = 0;
        }

        return amount.sub(feeAmount);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/utils/AutoBuyBack.sol";
import "contracts/extensions/OAuth.sol";

abstract contract AntiWhale is OAuth, AutoBuyBack {

    using SafeMath for uint256;

    uint256 public maxTxAmount;
    uint256 public maxSellAmount;
    uint256 public maxBuyAmount;

    bool public isTxLimitEnabled;
    bool public isCooldownEnabled;

    uint8 public cooldownTimerInterval;

    mapping (address => uint) internal _cooldownTimer;
    mapping (address => bool) internal _isTxLimitExempt;
    mapping (address => bool) internal _isCooldownExempt;

    event UpdateAntiWhaleConfig(bool txLimit, bool cooldown, uint8 cooldownTime);
    event UpdateAntiWhaleBuyAndSellMaxLimit(uint256 maxTxAmountLimit, uint256 maxSellAmountLimit, uint256 maxBuyAmountLimit);
    
    function _initializeAntiWhale(
        uint256 totalSupply,
        address rewardPool,
        address treasuryPool
    ) internal {
        maxTxAmount = totalSupply.div(400); // 0.25%
        maxSellAmount = totalSupply.div(5000); // 0.03%
        maxBuyAmount = totalSupply.div(4000); // 0.05%

        cooldownTimerInterval = 60;
        isCooldownEnabled = true;
        isTxLimitEnabled = true;

        _isTxLimitExempt[msg.sender] = true;
        _isTxLimitExempt[rewardPool] = true;
        _isTxLimitExempt[treasuryPool] = true;

        _isCooldownExempt[msg.sender] = true;
        _isCooldownExempt[rewardPool] = true;
        _isCooldownExempt[treasuryPool] = true;

        AutoBuyBack._swapThreshold = totalSupply.div(5000);
    }

    /**
     * @notice This method is a middleware to handle Transfer transaction limits
     * @param sender Addres of the sender
     * @param receiver Address of the token receiver
     * @param amount Token amount in wei format
     */
    function _checkTransactionLimit(address sender, address receiver, uint256 amount) internal view {
        require(amount <= maxTxAmount || _isTxLimitExempt[sender], "PCoin: TX Limit Exceeded");

        if(AutoBuyBack._isLiquidityPool[sender] == true)
            require(amount <= maxBuyAmount || _isTxLimitExempt[sender], "PCoin: Buy TX Limit Exceeded");

        if(AutoBuyBack._isLiquidityPool[receiver] == true)
            require(amount <= maxSellAmount || _isTxLimitExempt[sender], "PCoin: Sell TX Limit Exceeded");
    }

    /**
     * @notice This methods allow to change the max transaction limits
     * @dev Values used to limit selling, buying and the maximum amount that can be traded per transaction
     * @param mTxAmount Maximum value of tokens that can be traded per transaction
     * @param mSellAmount Maximum value of tokens that can be sold per transaction
     * @param mBuyAmount Maximum value of tokens that can be purchased per transaction
     */
    function setTransactionLimitAmount(uint256 mTxAmount, uint256 mSellAmount, uint256 mBuyAmount) public authorized {
        maxTxAmount = mTxAmount;
        maxSellAmount = mSellAmount;
        maxBuyAmount = mBuyAmount;
        emit UpdateAntiWhaleBuyAndSellMaxLimit(mTxAmount, maxSellAmount, maxBuyAmount);
    }
    
    /**
     * @notice Function used to track address buy cooldown
     * @param sender Address that send the transaction
     * @param recipient Address that is going to receive the transaction amount
     */
    function _checkBuyCooldownTime(address sender, address recipient) internal {
        if (AutoBuyBack._isLiquidityPool[sender] == true && isCooldownEnabled) {
            if(_cooldownTimer[recipient] < block.timestamp) {
                _cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
            } else {
                revert(
                    string(
                        abi.encodePacked(
                            "PCoin: please wait ",
                            Strings.toString(cooldownTimerInterval),
                            " secs between two buys"
                        )
                    )
                );
            }
        }
    }

    /**
     * @notice This method allow the authorized addres to change
     *         the anti-whale status
     * @param txState Transaction limit
     * @param cooldownState Cooldown state
     * @param cooldownInterval Cooldown interval in seconds | Default: 60
     */
    function setAntiWhaleConfig(bool txState, bool cooldownState, uint8 cooldownInterval) public authorized {
        isTxLimitEnabled = txState;
        isCooldownEnabled = cooldownState;
        cooldownTimerInterval = cooldownInterval;
        emit UpdateAntiWhaleConfig(txState, cooldownState, cooldownInterval);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "contracts/utils/Deflation.sol";
import "contracts/utils/AutoBuyBack.sol";
import "contracts/PixelCoinBase.sol";

abstract contract PBoneSwap is PixelCoinBase, AutoBuyBack, Deflation {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public pbonesContract;
    uint16 public pboneSellPrice;
    uint16 public pboneBuyPrice;

    event UpdatePBonesContract(address newContract);
    event UpdatePBoneSwapSettings(uint256 newSwapBuyPrice, uint256 newSwapSellPrice);

    function _initializePBoneSwap(uint16 sell, uint16 buy) internal {
        pboneSellPrice = sell;
        pboneBuyPrice = buy;
    }

    /**
     * @notice This method update the exchange price of the PBone token for PCoin Token
     *         and viceversa
     * @dev Update buy and sell price of exchangeable functions (swap~)
     * @param buy 1 Pcoin = X
     * @param sell X = 1 PCoin
     */
    function updatePboneSwapSettings(uint16 buy, uint16 sell) public authorized returns (bool) {
        pboneSellPrice = sell;
        pboneBuyPrice = buy;
        emit UpdatePBoneSwapSettings(buy, sell);
        return true;
    }

    /**
     * @param adr Addres of the PBones Contract
     */
    function setPboneContract(address adr) public authorized {
        pbonesContract = adr;
        emit UpdatePBonesContract(adr);
    }

    /**
     * @notice This method allow the address sender to swap PC -> PB
     * @dev input value is used to create the swap transaction, at the same
     *      the input is used to compute the deflation distribution
     * @param amount Amount of PCoins to be Swapped for PBones
     */
    function swapPcoinForPbones(uint256 amount) public returns (bool) {
        require(pbonesContract != address(0), "PCoin: contract not defined");
        require(
            IERC20(pbonesContract).allowance(msg.sender, address(this)) >=
                amount,
            "PCoin: First grant allowance"
        );
        require(amount >= 1, "PCoin: incorrect amount");

        uint256 calculatedAmount = amount.mul(pboneBuyPrice);

        // remove pcoin from the sender balance ## REF
        _balances[msg.sender] = _balances[msg.sender].sub(amount, "Insufficient balance");

        Deflation._distributeFees(amount);

        // add pbones to the sender balance
        IERC20(pbonesContract).safeTransfer(msg.sender, calculatedAmount);
        return true;
    }

    /**
     * @notice This method allow the address sender to swap PB -> PC
     * @param amount Amount of PBones to be Swapped for PCoins
     */
    function swapPbonesForPcoins(uint256 amount) public returns (bool) {
        require(pbonesContract != address(0), "PCoin: contract not defined");
        require(
            IERC20(pbonesContract).allowance(msg.sender, address(this)) >=
                amount,
            "PCoin: First grant allowance"
        );
        require(amount >= pboneSellPrice, "PCoin: incorrect amount");

        uint256 calculatedAmount = amount.div(pboneSellPrice);

        require(_balances[PixelCoinBase.rewardPool] >= calculatedAmount, "PCoin: reward pool empty");

        // remove pbones from sender address and save it on contract
        IERC20(pbonesContract).safeTransferFrom(msg.sender, address(this), amount);
        // send pcoin to the sender balance from the reward pool balance
        _transfer(PixelCoinBase.rewardPool, msg.sender, calculatedAmount);

        emit Transfer(msg.sender, address(this), calculatedAmount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "contracts/PixelCoinBase.sol";
import "contracts/interfaces/IDexRouter.sol";
import "contracts/interfaces/IDexFactory.sol";
import "contracts/extensions/OAuth.sol";

abstract contract AutoBuyBack is OAuth, PixelCoinBase {

    using SafeMath for uint256;

    IDEXRouter public router;
    address public WBNB;

    bool public _autoBuybackEnabled = false;
    uint256 internal _autoBuybackCap;
    uint256 internal _autoBuybackAccumulator;
    uint256 internal _autoBuybackThresholdAmount; // ETH Treshold
    uint256 internal _autoBuybackBlockPeriod;
    uint256 internal _autoBuybackLastBlock;

    bool internal _swapEnabled = true;
    uint256 internal _swapThreshold; // Tokens Treshold
    bool internal _inSwapping;

    mapping (address => bool) internal _isFeeExempt;
    mapping(address => bool) internal _isLiquidityPool;

    modifier swapping() { require(!_inSwapping, "Swapping in progress"); _inSwapping = true; _; _inSwapping = false; }

    event UpdateSwapSettings(bool swapState, uint256 thresholdAmount);
    event UpdateAutoBuyBackSettings(bool autoBuyBackState, uint256 thresholdAmount, uint256 blockPeriod);
    event UpdateLiquidityPoolStatus(address adr, bool status);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);

    /**
     * @notice This method shows all the information about the AutoBuyBack configuration
     */
    function showAutoBuyBackInfo() public view returns(
        bool swapStatus,
        bool autoBuyBackStatus,
        uint256 swapThreshold,
        uint256 autoBuyBackThreshold,
        uint256 autoBuyBackBlockPeriod,
        uint256 autoBuyBackLastTransactionBlock
    ) {
        swapStatus = _swapEnabled;
        swapThreshold = _swapThreshold;
        autoBuyBackStatus = _autoBuybackEnabled;
        autoBuyBackThreshold = _autoBuybackThresholdAmount;
        autoBuyBackBlockPeriod = _autoBuybackBlockPeriod;
        autoBuyBackLastTransactionBlock = _autoBuybackLastBlock;
    }

    function addLiquidityPoolToList(address adr) public authorized virtual {
        _isLiquidityPool[adr] = true;
        emit UpdateLiquidityPoolStatus(adr, true);
    }

    function removeLiquidityPoolFromList(address adr) public authorized virtual {
        delete _isLiquidityPool[adr];
        emit UpdateLiquidityPoolStatus(adr, false);
    }

    function setSwapSettings(bool state, uint256 amount) public authorized virtual {
        _swapEnabled = state;
        _swapThreshold = amount;
        emit UpdateSwapSettings(state, amount);
    }

    function setAutoBuybackSettings(bool state, uint256 amount, uint256 period) public authorized virtual {
        _autoBuybackEnabled = state;
        _autoBuybackThresholdAmount = amount;
        _autoBuybackBlockPeriod = period;
        _autoBuybackLastBlock = block.number;
        emit UpdateAutoBuyBackSettings(state, amount, period);
    }

    /**
     * @notice This method is an middleware to detect if the contract meets 
     *         the requirements to perform the swap ETH (WBNB) for Tokens.
     * @dev Compare _swapThreshold with actual balance balance and detect booleans
     * @param sender Transaction sender address
     */
    function _shouldSwapTokensForETH(address sender) internal virtual view returns (bool) {
        return _isLiquidityPool[sender] == false
        && _swapEnabled
        && !_inSwapping
        && PixelCoinBase._balances[address(this)] >= _swapThreshold;
    }

    /**
     * @notice This method is an middleware to detect if the contract meets 
     *         the requirements to perform the swap Tokens for ETH (WBNB).
     * @dev Compare block.number, balance and detect booleans
     * @param sender Transaction sender address
     */
    function _shouldSwapETHForTokensAndBurn(address sender) internal virtual view returns (bool) {
        return _isLiquidityPool[sender] == false
        && _autoBuybackEnabled
        && !_inSwapping
        && _autoBuybackLastBlock.add(_autoBuybackBlockPeriod) <= block.number // After N blocks from last buyback
        && address(this).balance >= _autoBuybackThresholdAmount;
    }

    function _triggerSwapTokensForETH() internal {
        AutoBuyBack._swapTokensForETHNoFee(address(this), _autoBuybackThresholdAmount);
    }

    function _triggerSwapETHForTokensAndBurn() internal {
        AutoBuyBack._swapETHForTokensNoFee(PixelCoinBase._DEAD, _autoBuybackThresholdAmount);
        _autoBuybackLastBlock = block.number;
        _autoBuybackAccumulator = _autoBuybackAccumulator.add(_autoBuybackThresholdAmount);
    }

    function _swapTokensForETHNoFee(
        address toAddress,
        uint256 amount
    ) internal swapping  {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        router.swapExactTokensForETH(
            amount,
            0, // accept any amount of ETH
            path,
            toAddress, // The contract
            block.timestamp.add(300)
        );
        emit SwapTokensForETH(amount, path);
    }  
    
    // EXCHANGE BNB FOR TOKENS
    function _swapETHForTokensNoFee(
        address toAddress,
        uint256 amount
    ) internal swapping returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        uint256[] memory amounts = router.swapExactETHForTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            toAddress, // The contract
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
        return amounts[1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract OAuth {

    address internal _owner;
    mapping (address => bool) internal _authorizations;

    event OwnershipTransferred(address owner);

    constructor(address owner) {
        _owner = owner;
        _authorizations[owner] = true;
    }

    /**
     * @notice Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "OAuth: only owner"); _;
    }

    /**
     * @notice Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "OAuth: you're not authorized"); _;
    }

    /**
     * @notice Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        _authorizations[adr] = true;
    }

    /**
     * @notice Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        _authorizations[adr] = false;
    }

    /**
     * @notice Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    /**
     * @notice Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return _authorizations[adr];
    }

    /**
     * @notice Transfer ownership to new address. Caller must be owner. 
     *         Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        _owner = adr;
        _authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "contracts/extensions/OAuth.sol";

abstract contract PixelCoinBase is IERC20, OAuth {

    using SafeMath for uint256;

    address internal constant _DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal constant _ZERO = 0x0000000000000000000000000000000000000000;

    address public rewardPool;
    address public treasuryPool;

    string private _name = "PixelCoin";
    string private _symbol = "PCoin";
    uint8 private _decimals = 18; 
    uint256 internal _totalSupply = 200e6 * (10 ** _decimals);
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    event UpdateRewardAddresses(address _rewardPool, address _treasuryPool);

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external view returns (uint8) { return _decimals; }
    function symbol() external view returns (string memory) { return _symbol; }
    function name() external view returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return _owner; }
    function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    /**
     * @notice This method was created to look at the actual supply in circulation, 
     *         the circulating supply is the total number of tokens that are not 
     *         burned yet
     *
     * @return uint256 Total circulating supply
     */
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(this.balanceOf(_DEAD)).sub(this.balanceOf(_ZERO));
    }

    /**
     * @notice This method allows to the authorized addres to change the addresses
     *         that handle the reward tokens and the treasury tokens
     *
     * @param _rewardPool   Address of the reward pool
     * @param _treasuryPool Address of the treasury pool
     */
    function updatePools(address _rewardPool, address _treasuryPool) public authorized returns (bool) {
        rewardPool = _rewardPool;
        treasuryPool = _treasuryPool;
        emit UpdateRewardAddresses(_rewardPool, _treasuryPool);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "contracts/utils/AutoBuyBack.sol";
import "contracts/extensions/OAuth.sol";

abstract contract Deflation is OAuth, AutoBuyBack {

    using SafeMath for uint256;
    
    uint256 internal _transferBuyFee;
    uint256 internal _transferSellFee;

    struct FeeStruct {
        uint256 burn;
        uint256 buyback;
        uint256 rewardPool;
        uint256 treasuryPool;
    }

    FeeStruct public feeStructure;

    event UpdateFeeStructure(FeeStruct values);

    function _initializeDeflation() internal {
        _transferBuyFee = 200;
        _transferSellFee = 300;
        feeStructure = FeeStruct({
            burn: 50,
            buyback: 25,
            rewardPool: 15,
            treasuryPool: 10
        });
    }

    /**
     * @notice Generate the feeStructure calculation
     * @dev Receive input uint256 and returns tupple
     * @param amount Input value to be computed in percents
     */
    function _computeDistributionFees(uint256 amount) internal view returns (
        uint256 burn,
        uint256 buyback,
        uint256 rewardPool,
        uint256 treasuryPool
    ) {
        burn = amount.mul(feeStructure.burn).div(100);
        buyback = amount.mul(feeStructure.buyback).div(100);
        rewardPool = amount.mul(feeStructure.rewardPool).div(100);
        treasuryPool = amount.mul(feeStructure.treasuryPool).div(100);
    }
    
    /**
     * @notice This function trigger the fee distribution under the treasury pool,
     *         reward pool, burn address and this contract to handle AutoBuyBack later
     * @dev Input value in wei format to disperse the fee through balance mapping
     *
     * @param amount Amount in wei to be compute
     */
    function _distributeFees(uint256 amount) internal returns (bool) {
        (uint256 burn, uint256 buyback, uint256 rewardPool, uint256 treasuryPool) = _computeDistributionFees(amount);

        PixelCoinBase._balances[PixelCoinBase._DEAD] = PixelCoinBase._balances[PixelCoinBase._DEAD].add(burn);
        PixelCoinBase._balances[address(this)] = PixelCoinBase._balances[address(this)].add(buyback);
        PixelCoinBase._balances[PixelCoinBase.rewardPool] = PixelCoinBase._balances[PixelCoinBase.rewardPool].add(rewardPool);
        PixelCoinBase._balances[PixelCoinBase.treasuryPool] = PixelCoinBase._balances[PixelCoinBase.treasuryPool].add(treasuryPool);
        
        // Amount to be swapped
        AutoBuyBack._autoBuybackThresholdAmount = AutoBuyBack._autoBuybackThresholdAmount.add(buyback);
        return true;
    }

    /**
     * @notice Update the fee structure deducted from the input amount
     * @dev Update values used to handle fees, total inputs cannot be more than 100 percent
     */
    function updateFeeStructure(
        uint256 burnPercentage,
        uint256 buybackPercentage, 
        uint256 rewardPoolPercentage, 
        uint256 treasuryPoolPercentage
    ) public authorized {
        require(
            burnPercentage + 
            buybackPercentage + 
            rewardPoolPercentage + 
            treasuryPoolPercentage == 100, "PCoin: total count should be 100"
        );
        feeStructure = FeeStruct({
            burn: burnPercentage,
            buyback: buybackPercentage,
            rewardPool: rewardPoolPercentage,
            treasuryPool: treasuryPoolPercentage
        }); 
        emit UpdateFeeStructure(feeStructure);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}