/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

/*

    Copyright 2020 WooTrade.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

contract Wooracle is InitializableOwnable {
    mapping(address => uint256) public price;
    mapping(address => uint128) public coeff;
    mapping(address => uint64) public spread;
    mapping(address => bool) public isValid;

    uint256 public timestamp;
    uint256 public staleDuration;

    address public quoteAddr;

    constructor() public {
        initOwner(msg.sender);
        staleDuration = uint256(300);
    }

    function setQuoteAddr(address newQuoteAddr) external onlyOwner {
        quoteAddr = newQuoteAddr;
    }

    function setStaleDuration(uint256 newStaleDuration) external onlyOwner {
        staleDuration = newStaleDuration;
    }

    function postPrice(address base, uint256 newPrice) external onlyOwner {
        if (newPrice == uint256(0)) {
            isValid[base] = false;
        } else {
            price[base] = newPrice;
            isValid[base] = true;
        }
        timestamp = block.timestamp;
    }

    function postPriceList(
        address[] calldata bases,
        uint256[] calldata newPrices
    ) external onlyOwner {
        uint256 length = bases.length;
        require(length == newPrices.length);

        for (uint256 i = 0; i < length; i++) {
            if (newPrices[i] == uint256(0)) {
                isValid[bases[i]] = false;
            } else {
                price[bases[i]] = newPrices[i];
                isValid[bases[i]] = true;
            }
        }

        timestamp = block.timestamp;
    }

    function postSpread(address base, uint64 newSpread) external onlyOwner {
        spread[base] = newSpread;
        timestamp = block.timestamp;
    }

    function postSpreadList(
        address[] calldata bases,
        uint64[] calldata newSpreads
    ) external onlyOwner {
        uint256 length = bases.length;
        require(length == newSpreads.length);

        for (uint256 i = 0; i < length; i++) {
            spread[bases[i]] = newSpreads[i];
        }

        timestamp = block.timestamp;
    }

    function postState(
        address base,
        uint256 newPrice,
        uint64 newSpread,
        uint128 newCoeff
    ) external onlyOwner {
        if (newPrice == uint256(0)) {
            isValid[base] = false;
        } else {
            price[base] = newPrice;
            spread[base] = newSpread;
            coeff[base] = newCoeff;
            isValid[base] = true;
        }

        timestamp = block.timestamp;
    }

    function postStateList(
        address[] calldata bases,
        uint256[] calldata newPrices,
        uint64[] calldata newSpreads,
        uint128[] calldata newCoeffs
    ) external onlyOwner {
        uint256 length = bases.length;
        require(
            length == newPrices.length &&
                length == newSpreads.length &&
                length == newCoeffs.length
        );

        for (uint256 i = 0; i < length; i++) {
            if (newPrices[i] == uint256(0)) {
                isValid[bases[i]] = false;
            } else {
                price[bases[i]] = newPrices[i];
                spread[bases[i]] = newSpreads[i];
                coeff[bases[i]] = newCoeffs[i];
                isValid[bases[i]] = true;
            }
        }

        timestamp = block.timestamp;
    }

    function getPrice(address base)
        external
        view
        returns (uint256 priceNow, bool feasible)
    {
        priceNow = price[base];
        feasible = isFeasible(base);
    }

    function getState(address base)
        external
        view
        returns (
            uint256 priceNow,
            uint64 spreadNow,
            uint128 coeffNow,
            bool feasible
        )
    {
        priceNow = price[base];
        spreadNow = spread[base];
        coeffNow = coeff[base];
        feasible = isFeasible(base);
    }

    function isStale() public view returns (bool) {
        return block.timestamp > timestamp + staleDuration * 1 seconds;
    }

    function isFeasible(address base) public view returns (bool) {
        return isValid[base] && !isStale();
    }
}