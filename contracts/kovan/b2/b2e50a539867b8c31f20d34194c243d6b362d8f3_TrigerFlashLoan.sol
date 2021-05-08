/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// File: contracts/lib/Ownable.sol

/*
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;

contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/intf/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
}

// File: contracts/lib/SafeMath.sol


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/DecimalMath.sol


library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).divCeil(target);
    }
}

// File: contracts/TrigerFlashLoan.sol


interface IDODO {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function sellBase(address to) external returns (uint256);

    function sellQuote(address to) external returns (uint256);

    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);

    function querySellQuoteToken(address dodo, uint256 amount) external view returns (uint256);
    
    function querySellBaseToken(address dodo, uint256 amount) external view returns (uint256);
}


contract TrigerFlashLoan is Ownable {
    using SafeMath for uint256;

    address public _DODO_SELL_HELPER_;

    constructor(address dodoSellHelper) public {
        _DODO_SELL_HELPER_ = dodoSellHelper;
    }
    
    //Classical
    function trigerV1FlashLoan(
        address pool,
        uint256 tolerateRate,
        uint256[] memory amount,
        uint256[] memory direction
    ) external {
        require(amount.length == direction.length);

        address baseToken = IDODO(pool)._BASE_TOKEN_();
        address quoteToken = IDODO(pool)._QUOTE_TOKEN_();

        IERC20(baseToken).approve(pool, uint256(-1));
        IERC20(quoteToken).approve(pool, uint256(-1));

        bytes memory data = abi.encode(tolerateRate);

        for(uint256 i =0; i< amount.length;i++) {
            if(direction[i] == 0) {
                IDODO(pool).sellBaseToken(amount[i],0, data);
            }else {
                IDODO(pool).buyBaseToken(amount[i],0, data);
            }
        }
    }

    function dodoCall(
        bool isSellBase,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        (uint256 tolerateRate) = abi.decode(data, (uint256));
        if(isSellBase) {
            uint256 receiveQuote = IDODO(msg.sender).sellBaseToken(baseAmount, 0, "");
            uint256 quoteFee = quoteAmount.sub(receiveQuote);
            require(DecimalMath.divFloor(quoteFee,quoteAmount) <= tolerateRate);
        } else {
            uint256 canBuyBaseAmount = IDODO(_DODO_SELL_HELPER_).querySellQuoteToken(
                    msg.sender,
                    quoteAmount
                );
            uint256 receiveBase = IDODO(msg.sender).buyBaseToken(canBuyBaseAmount, quoteAmount, "");
            uint256 baseFee = baseAmount.sub(receiveBase);
            require(DecimalMath.divFloor(baseFee,baseAmount) <= tolerateRate); 
        }
    }

    //DVM、DSP、DPP
    function trigerFlashLoan(
        address pool,
        uint256 tolerateRate,
        uint256[] memory baseAmount,
        uint256[] memory quoteAmount
    ) external {
        require(baseAmount.length == quoteAmount.length);
        for(uint256 i =0; i< baseAmount.length;i++) {
            bytes memory data = abi.encode(pool,tolerateRate);
            IDODO(pool).flashLoan(baseAmount[i], quoteAmount[i], address(this), data);
        }
    }

    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _doFlashLoan(sender,baseAmount,quoteAmount,data);
    }

    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _doFlashLoan(sender,baseAmount,quoteAmount,data);
    }

    function DSPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _doFlashLoan(sender,baseAmount,quoteAmount,data);
    }

    function _doFlashLoan(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) internal {
        require(sender == address(this));
        (address pool,uint256 tolerateRate) = abi.decode(data, (address,uint256));
        
        address baseToken = IDODO(pool)._BASE_TOKEN_();
        address quoteToken = IDODO(pool)._QUOTE_TOKEN_();

        IERC20(baseToken).transfer(pool, baseAmount);
        uint256 receiveQuoteAmount = IDODO(pool).sellBase(address(this));


        IERC20(quoteToken).transfer(pool, quoteAmount);
        uint256 receiveBaseAmount = IDODO(pool).sellQuote(address(this));

        uint256 baseFee = baseAmount.sub(receiveBaseAmount);
        uint256 quoteFee = quoteAmount.sub(receiveQuoteAmount);

        require(DecimalMath.divFloor(baseFee,baseAmount) <= tolerateRate);
        require(DecimalMath.divFloor(quoteFee,quoteAmount) <= tolerateRate);

        IERC20(baseToken).transfer(pool,baseAmount);
        IERC20(quoteToken).transfer(pool,quoteAmount);
    }
}