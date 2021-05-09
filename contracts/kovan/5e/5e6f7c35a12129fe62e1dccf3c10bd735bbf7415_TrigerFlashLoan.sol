/**
 *Submitted for verification at Etherscan.io on 2021-05-09
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

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function querySellQuoteToken(address dodo, uint256 amount) external view returns (uint256);
    
    function querySellBaseToken(address dodo, uint256 amount) external view returns (uint256);

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
}

interface IUni {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function token0() external view returns (address);
    function token1() external view returns (address);
}


contract TrigerFlashLoan is Ownable {
    using SafeMath for uint256;
    address public _DODO_SELL_HELPER_;

    constructor(address dodoSellHelper) public {
        _DODO_SELL_HELPER_ = dodoSellHelper;
    }
    
    function doTrade(
        uint256 poolType, //0 DVM,DSP,DPP or 1 Classical
        address dodoPool,
        address uniPool,
        uint256 token0MaxFee,
        uint256 token1MaxFee,
        uint256[] memory token0Amount,
        uint256[] memory token1Amount
    ) external {
        require(token0Amount.length == token1Amount.length);

        address token0 = IUni(uniPool).token0();
        address token1 = IUni(uniPool).token1();

        if(poolType == 1) {
            IERC20(token0).approve(dodoPool, uint256(-1));
            IERC20(token1).approve(dodoPool, uint256(-1));
        }

        uint256 originToken0Amount = IERC20(token0).balanceOf(address(this));
        uint256 originToken1Amount = IERC20(token1).balanceOf(address(this));

        for(uint256 i =0; i< token0Amount.length;i++) {
            bytes memory data = abi.encode(uniPool,dodoPool,token0,poolType);
            IUni(uniPool).swap(token0Amount[i], token1Amount[i], address(this), data);
        }

        uint256 endToken0Amount = IERC20(token0).balanceOf(address(this));
        uint256 endToken1Amount = IERC20(token1).balanceOf(address(this));
        uint256 token0Fee = originToken0Amount.sub(endToken0Amount);
        uint256 token1Fee = originToken1Amount.sub(endToken1Amount);

        require(token0Fee<= token0MaxFee);
        require(token1Fee <= token1MaxFee);
    }

    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external {
        _handleFlashLoan(sender, amount0, amount1, data);
    }


    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        _handleFlashLoan(sender, amount0, amount1, data);
    }

    function _handleFlashLoan(address sender, uint amount0, uint amount1, bytes calldata data) internal {
        (address uniPool, address dodoPool, address token0, uint256 poolType) = abi.decode(data, (address,address,address,uint256));
        require(msg.sender == uniPool);
        address baseToken = IDODO(dodoPool)._BASE_TOKEN_();
        address quoteToken = IDODO(dodoPool)._QUOTE_TOKEN_();

        uint256 baseAmount;
        uint256 quoteAmount;
        if(baseToken == token0) {
            baseAmount = amount0;
            quoteAmount = amount1;
        }else {
            baseAmount = amount1;
            quoteAmount = amount0;
        }

        if(poolType == 0) {
            IERC20(baseToken).transfer(dodoPool,baseAmount);
            IDODO(dodoPool).sellBase(sender);

            IERC20(quoteToken).transfer(dodoPool,quoteAmount);
            IDODO(dodoPool).sellQuote(sender);
        } else {
            IDODO(dodoPool).sellBaseToken(baseAmount, 0, "");
            uint256 canBuyBaseAmount = IDODO(_DODO_SELL_HELPER_).querySellQuoteToken(
                dodoPool,
                quoteAmount
            );
            IDODO(dodoPool).buyBaseToken(canBuyBaseAmount, quoteAmount, "");
        } 

        IERC20(baseToken).transfer(uniPool, baseAmount);
        IERC20(quoteToken).transfer(uniPool, quoteAmount);
    }

}