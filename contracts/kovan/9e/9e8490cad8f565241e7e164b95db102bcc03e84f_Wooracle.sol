/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-19
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

contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

contract Wooracle is InitializableOwnable{

    address private _quoteAddress_;

    struct Quote{
        uint256 price;
        uint256 timestamp;
        bool isValid;
    }

    mapping(address => Quote) private mapQuotes_;

    constructor(address quoteAddr) public{
        initOwner(msg.sender);
        _quoteAddress_ = quoteAddr;
    }

    function getQuoteToken() public view returns (string memory)
    {
        return getTokenSymbol_(_quoteAddress_);
    }

    function getQuote() public view returns (address)
    {
        return _quoteAddress_;
    }

    function postPrice(address base,uint256 newPrice)
        public onlyOwner
        returns (bool)
    {
        mapQuotes_[base].price = newPrice;
        mapQuotes_[base].timestamp = block.timestamp;
        mapQuotes_[base].isValid = true;
        return true;
    }

    function postPriceList(address[] memory bases,uint256[] memory newPrices)
        public onlyOwner
        returns (bool)
    {
        if (bases.length != newPrices.length) return false;
        uint length = bases.length;

        for (uint i =0; i< length; i ++)
        {
            mapQuotes_[bases[i]].price = newPrices[i];
            mapQuotes_[bases[i]].timestamp = block.timestamp;
            mapQuotes_[bases[i]].isValid = true;
        }
        return true;
    }

    function postInvalid(address base)
        public onlyOwner
        returns (bool)
    {
        mapQuotes_[base].isValid = false;
        return true;
    }

        function postInvalidList(address[] memory bases)
        public onlyOwner
        returns (bool)
    {
        uint length = bases.length;
        for(uint i =0; i < length; i++)
        {
            mapQuotes_[bases[i]].isValid = false;
        }

        return true;
    }

    function getPrice(address base)
        public view
        returns (string memory baseSymbol,uint256 latestPrice,bool isValid,bool isStale,uint256 timestamp)
    {
        baseSymbol = getTokenSymbol_(base);
        latestPrice = mapQuotes_[base].price;
        timestamp = mapQuotes_[base].timestamp;
        isValid = mapQuotes_[base].isValid;
        isStale = isPriceStaleNow_(base);
    }

    function validate_(string memory apikey) private pure returns (bool isValid)
    {
        if(keccak256(bytes(apikey)) == keccak256(bytes("Wootrade"))) return true;

        return false;

    }

    function getPriceAdvanced(address base, string memory apikey)
        public view
        returns (string memory baseSymbol,uint256 latestPrice,bool isValid,bool isStale,uint256 timestamp)
    {
        if (validate_(apikey)) return getPrice(base);

        baseSymbol = getQuoteToken();
        latestPrice = 10**18;
        isValid = false;
        isStale = true;
        timestamp = block.timestamp;
    }

    function getTokenSymbol_(address token) private view returns (string memory)
    {
        return IERC20(token).symbol();
    }

    function isPriceStaleNow_(address base)
        private view returns (bool)
    {
        if (block.timestamp > mapQuotes_[base].timestamp + 5 minutes)
        {
            return true;
        }
        else
        {
            return false;
        }
    }
}