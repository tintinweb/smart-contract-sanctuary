/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

// SPDX-License-Identifier: The MIT License

pragma solidity ^0.8.0;

/**
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

contract Presale is Ownable {
    IERC20 public token; // token that will be sold

    mapping(address => uint256) public investments; // total wei invested per address
    mapping(address => uint256) public claimed; // if claimed=1, first period is claimed, claimed=0, nothing claimed.
    mapping(address => uint256) public tokenToClaim; // Total Token to be claimed per address

    uint256 public totalInvestorsCount; // total investors count
    uint256 public totalCollectedWei; // total wei collected
    uint256 public totalTokens; // total tokens to be sold
    uint256 public tokensLeft; // available tokens to be sold
    uint256 public tokenPriceInWei; // token presale wei price per 1 token
    uint256 public hardCapInWei; // maximum wei amount that can be invested in presale
    uint256 public softCapInWei; // minimum wei amount to invest in presale, if not met, invested wei will be returned
    uint256 public maxInvestInWei; // maximum wei amount that can be invested per wallet address
    uint256 public minInvestInWei; // minimum wei amount that can be invested per wallet address
    uint256 public openTime; // time when presale starts, investing is allowed
    uint256 public closeTime; // time when presale closes, investing is not allowed

    uint256 private constant _CLAIM_PASSIVE = 0;
    uint256 private constant _CLAIM_ACTIVE = 1;
    uint256 private claimStatus;

    /**
    * @param _token Token to be sold
    * @param _totalTokens Total Token amount to be sold
    * @param _tokenPrice 1 Token price in wei ex: 0.00000067 ETH/BNB = 670000000000 wei
    * @param _softCap Soft cap amount ex: 100 ETH/BNB
    * @param _hardCap Hasrd cap amount ex: 500 ETH/BNB
    * @param _minInvest Minimum investment per wallet ex: 0.1 ETH/BNB = 100000000000000000 wei
    * @param _maxInvest Maximum investment per wallet ex: 10 ETH/BNB = 10000000000000000000 wei
    * @param _openTime Start time for presale EPOC ex: 1609459200 - Friday, 1 January 2021 00:00:00
    * @param _endTime End time for presale EPOC ex: 1609459200 - Friday, 1 January 2021 00:00:00
    */ 
    constructor(
        IERC20 _token,
        uint256 _totalTokens,
        uint256 _tokenPrice,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minInvest,
        uint256 _maxInvest,
        uint256 _openTime,
        uint256 _endTime
    ) {
        token = _token;

        totalTokens = _totalTokens * (10**18);
        tokensLeft = _totalTokens * (10**18);
        tokenPriceInWei = _tokenPrice;
        softCapInWei = _softCap * (10**18);
        hardCapInWei = _hardCap * (10**18);
        minInvestInWei = _minInvest;
        maxInvestInWei = _maxInvest;
        openTime  = _openTime;
        closeTime = _endTime;

        claimStatus = _CLAIM_PASSIVE;
    }

    modifier investorOnly() {
        require(investments[msg.sender] > 0, "Not an investor");
        _;
    }

    modifier calimActiveOnly() {
        require(claimStatus == _CLAIM_ACTIVE, "Claim Token is not active yet!");
        _;
    }

    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return (_weiAmount * 1e18) / tokenPriceInWei;
    }

    receive() external payable {
        invest();
    }

    function invest() public payable {
        require(block.timestamp >= openTime, "Not yet opened");
        require(block.timestamp < closeTime, "Closed");
        require(totalCollectedWei < hardCapInWei, "Hard cap reached");
        require(tokensLeft > 0);
        require(msg.value <= tokensLeft * tokenPriceInWei);

        uint256 totalInvestmentInWei = investments[msg.sender] + msg.value;
        require(totalInvestmentInWei >= minInvestInWei || totalCollectedWei >= hardCapInWei - 1 ether, "Min investment not reached");
        require(maxInvestInWei == 0 || totalInvestmentInWei <= maxInvestInWei, "Max investment reached");

        if (investments[msg.sender] == 0) {
            totalInvestorsCount = totalInvestorsCount + 1;
        }

        totalCollectedWei = totalCollectedWei + msg.value;
        investments[msg.sender] = totalInvestmentInWei;
        tokenToClaim[msg.sender] = getTokenAmount(totalInvestmentInWei);
        tokensLeft = tokensLeft - getTokenAmount(totalInvestmentInWei);
    }

    function transferUnsoldTokens() external onlyOwner {
        require(block.timestamp > closeTime, "Not yet closed");

        if (totalCollectedWei < softCapInWei) {
            uint256 unsoldTokensAmount = token.balanceOf(address(this));
            if (unsoldTokensAmount > 0) {
                token.transfer(msg.sender, unsoldTokensAmount);
            }
        } else {
            uint256 unsoldTokensAmount = token.balanceOf(address(this)) - getTokenAmount(totalCollectedWei);
            if (unsoldTokensAmount > 0) {
                token.transfer(msg.sender, unsoldTokensAmount);
            }
        }
    }

    function claimTokens() external investorOnly calimActiveOnly{
        require(totalCollectedWei >= softCapInWei, "Soft cap not reached");
        require(block.timestamp > closeTime, "Not yet closed");
        require(claimed[msg.sender] == 0, "Already claimed");
        
        claimed[msg.sender] = 1; // make sure this goes first before transfer to prevent reentrancy
        token.transfer(msg.sender, getTokenAmount(investments[msg.sender]));
    }

    function getRefund() external investorOnly {
        require(block.timestamp > closeTime, "Not yet closed");
        require(softCapInWei > 0, "No soft cap");
        require(totalCollectedWei < softCapInWei, "Soft cap reached");
        require(claimed[msg.sender] == 0, "Already claimed");

        claimed[msg.sender] = 1; // make sure this goes first before transfer to prevent reentrancy
        uint256 investment = investments[msg.sender];
        uint256 presaleBalance = address(this).balance;
        require(presaleBalance > 0);

        if (investment > presaleBalance) {
            investment = presaleBalance;
        }

        if (investment > 0) {
            payable(msg.sender).transfer(investment);
        }
    }

    function collectFundsRaised() external onlyOwner {
        require(totalCollectedWei >= softCapInWei, "Soft cap not reached");
        require(block.timestamp > closeTime, "Not yet closed");

        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function activateClaim() external onlyOwner {
        require(block.timestamp > closeTime, "Not yet closed");
        claimStatus = _CLAIM_ACTIVE;
    }
}