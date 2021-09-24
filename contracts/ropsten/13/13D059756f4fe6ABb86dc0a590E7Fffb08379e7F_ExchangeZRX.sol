/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/ExchangeZRX.sol

pragma solidity >= 0.6.0 < 0.7.0;



interface IWETH is IERC20 {
    function deposit() external payable;
}

contract ExchangeZRX is Ownable {

    // exchange fee in percents with base 100 (percent * 100)
    // e.g. 0.1% = 10, 1% = 100
    uint32 private constant percent100Base = 10000;
    // the fee factor in percents with base 100
    // e.g. fee is 1% = 100, feeFactor = 9900
    uint32 private _exchangeFeeFactor;
    // 0x protocol swap target contract
    address payable private _swapTarget;

    IWETH private WETH;

    event BoughtTokens(IERC20 sellToken, IERC20 buyToken, uint256 boughtAmount, address indexed buyer);
    event WithdrawFee(IERC20 token, address indexed recipient, uint256 amount);
    event ChangeFee(uint32 fee);
    event ChangeSwapTarget(address indexed swapTarget);

    constructor(uint32 fee, address payable swapTarget, IWETH weth) public {
        _exchangeFeeFactor = percent100Base - fee;
        _swapTarget = swapTarget;
        WETH = weth;
    }

    function setFee(uint32 fee) external onlyOwner {
        require(fee <= percent100Base, "!fee > 100");
        _exchangeFeeFactor = percent100Base - fee;
        emit ChangeFee(fee);
    }

    function getFee() external view returns (uint32 fee) {
        fee = percent100Base - _exchangeFeeFactor;
    }

    function setSwapTarget(address payable swapTarget) external onlyOwner {
        _swapTarget = swapTarget;
        emit ChangeSwapTarget(swapTarget);
    }

    function getSwapTarget() external view returns(address) {
        return _swapTarget;
    }

    function withdrawFee(IERC20 token, address recipient) external onlyOwner {
        // get token balance of contract
        uint256 amount = token.balanceOf(address(this));
        // transef all amount to recipient
        token.transfer(recipient, amount);

        emit WithdrawFee(token, recipient, amount);
    }

    // Transfer ETH held by this contrat to recipient
    function withdrawETH(address payable recipient)
        external
        onlyOwner
    {
        recipient.transfer(address(this).balance);
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    function _fillQuote(
        // The `sellTokenAddress` field from the API response.
        IERC20 sellToken,
        // The `buyTokenAddress` field from the API response.
        IERC20 buyToken,
        // The `allowanceTarget` field from the API response.
        address spender,
        // The `data` field from the API response.
        bytes memory swapCallData,
        // dex commition
        uint256 fee
    )
        internal
    {
        // Track our balance of the buyToken to determine how much we've bought.
        uint256 boughtAmount = buyToken.balanceOf(address(this));

        // Give `spender` an allowance to spend this contract's `sellToken`.
        if (sellToken.allowance(address(this), spender) == 0) {
            require(sellToken.approve(spender, uint(-1)), "!failed to approve sell token");
        }
        // Call the encoded swap function call
        (bool success,) = _swapTarget.call{value: fee}(swapCallData);
        require(success, '!swap failed');

        // Use our current buyToken balance to determine how much we've bought.
        boughtAmount = buyToken.balanceOf(address(this)) - boughtAmount;
        boughtAmount = (boughtAmount * _exchangeFeeFactor) / percent100Base;
        // transfer bought token
        buyToken.transfer(msg.sender, boughtAmount);

        emit BoughtTokens(sellToken, buyToken, boughtAmount, msg.sender);
    }

    // Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
    function fillQuote(
        // The `sellAmount` field from the API response.
        uint256 sellAmount,
        // The `sellTokenAddress` field from the API response.
        IERC20 sellToken,
        // The `buyTokenAddress` field from the API response.
        IERC20 buyToken,
        // The `allowanceTarget` field from the API response.
        address spender,
        // The `data` field from the API response.
        bytes calldata swapCallData
    )
        external
        payable
    {
        // Track our balance of the sellToken
        uint256 sellTokenBefore = sellToken.balanceOf(address(this));
        // deposit sell token amount to current contract
        require(sellToken.transferFrom(msg.sender,  address(this), sellAmount), "!failed to transfer sell token");
        _fillQuote(sellToken, buyToken, spender, swapCallData, msg.value);
        // check the sell token our balance to prevent to sell more, than user has
        require(sellTokenBefore <= sellToken.balanceOf(address(this)), "!invalid sell amount");
    }

    // swaps ETH->ERC20 tokens held by this contract using a 0x-API quote.
    function fillQuoteETH(
        uint256 sellAmount,
        IERC20 buyToken,
        address spender,
        bytes calldata swapCallData
    )
        external
        payable
    {
        require(msg.value >= sellAmount, "!invalid sell amount");
        uint256 balanceBefore = WETH.balanceOf((address(this)));
        // deposit ETH to WETH
        WETH.deposit{value: sellAmount}();
        _fillQuote(IERC20(WETH), buyToken, spender, swapCallData, msg.value - sellAmount);
        // check the sell token our balance to prevent to sell more, than user has
        require(balanceBefore <= WETH.balanceOf(address(this)), "!invalid sell amount");
    }
}