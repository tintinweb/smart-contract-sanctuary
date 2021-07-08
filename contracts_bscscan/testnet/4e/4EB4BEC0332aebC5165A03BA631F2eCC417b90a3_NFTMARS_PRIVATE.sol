// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";

abstract contract ERC20Interface {
    function balanceOf(address whom) virtual view public returns (uint);
}

contract NFTMARS_PRIVATE {
    using SafeMath for uint256;

    address payable public bscsDevAddress; // address of contract dev
    
    //Presale token
    bytes32 public token_round = "PRIVATE Round";
    IERC20 public token; // token that will be sold
    uint256 public token_decimals = 9;
    bytes32 public token_name = "NFTMARS";
    bytes32 public token_symbol = "MARS";
    
    address public unsoldTokensDumpAddress; // address where unsold tokens will be transferred to
    mapping(address => uint256) public investments; // total wei invested per address
    mapping(address => bool) public whitelistedAddresses; // addresses eligible in presale
    mapping(address => uint256) public claimed; // if claimed=1, first period is claimed, claimed=2, second period is claimed, claimed=0, nothing claimed.

    uint256 public totalInvestorsCount; // total investors count
    uint256 public totalCollectedWei; // total wei collected
    uint256 public totalTokens; // total tokens to be sold
    uint256 public tokensLeft = 0; // available tokens to be sold
    uint256 public tokenPriceInWei; // token presale wei price per 1 token
    uint256 public hardCapInWei; // maximum wei amount that can be invested in presale
    uint256 public softCapInWei; // minimum wei amount to invest in presale, if not met, invested wei will be returned
    uint256 public maxInvestInWei; // maximum wei amount that can be invested per wallet address
    uint256 public minInvestInWei; // minimum wei amount that can be invested per wallet address
    uint256 public openTime; // time when presale starts, investing is allowed
    uint256 public closeTime; // time when presale closes, investing is not allowed
    uint256 public cakeLiquidityAddingTime; // time when adding of liquidity in PancakeSwap starts, investors can claim their tokens afterwards

    uint256 public claimCycle = 30 days;

    bool public presaleCancelled = false; // if true, investing will not be allowed, investors can withdraw, presale creator can withdraw their tokens
    bool public refundAllowed = false; // if true, investor can get refund his investment.
    bool public claimAllowed = false; // if true, investory can claim tokens.
    bytes32 public linkTelegram;
    bytes32 public linkTwitter;
    bytes32 public linkWebsite;
    bytes32 public linkLogo;
    bytes32 public linkMedium;

    constructor(address _bscsDevAddress, address _tokenAddress) public {
        require(_tokenAddress != address(0), "error set token address");
        require(_bscsDevAddress != address(0), "error set bscsdev address");
        
        token = IERC20(_tokenAddress);
        bscsDevAddress = payable(_bscsDevAddress);
        
    }

    modifier onlyBscsDev() {
        require(bscsDevAddress == msg.sender);
        _;
    }

    modifier whitelistedAddressOnly() {
        require(
            whitelistedAddresses[msg.sender],
            "Address not whitelisted"
        );
        _;
    }

    modifier presaleIsNotCancelled() {
        require(!presaleCancelled, "Cancelled");
        _;
    }

    modifier investorOnly() {
        require(investments[msg.sender] > 0, "Not an investor");
        _;
    }

    modifier isValidClaimPeriod() {
        uint256 currentPeriod = 0;
        if (
            now >= cakeLiquidityAddingTime &&
            now < cakeLiquidityAddingTime + claimCycle
        ) {
            currentPeriod = 1; //60%
        }
        if (
            now >= cakeLiquidityAddingTime + claimCycle &&
            now < cakeLiquidityAddingTime + claimCycle * 2
        ) {
            currentPeriod = 2;//20*
        }
        if (
            now >= cakeLiquidityAddingTime + claimCycle * 2
        ) {
            currentPeriod = 3;//20*
        }
        
       
        require(currentPeriod > 0, "Listing not started");

        require(
            claimed[msg.sender] < currentPeriod,
            "Already claimed or refunded"
        );
        _;
    }

    modifier onlyRefundAllowed() {
        require(refundAllowed, "Refund is disallowed");
        _;
    }

    modifier onlyClaimAllowed() {
        require(claimAllowed, "Claim is disallowed");
        _;
    }

    function setAddressInfo(
        address _unsoldTokensDumpAddress
    ) external onlyBscsDev {
        
        require(_unsoldTokensDumpAddress != address(0));
        unsoldTokensDumpAddress = _unsoldTokensDumpAddress;
    }

    function setGeneralInfo(
        uint256 _totalTokens,
        uint256 _tokenPriceInWei,
        uint256 _hardCapInWei,
        uint256 _softCapInWei,
        uint256 _maxInvestInWei,
        uint256 _minInvestInWei,
        uint256 _openTime,
        uint256 _closeTime
    ) external onlyBscsDev {
        require(_totalTokens > 0);
        require(_tokenPriceInWei > 0);
        require(_openTime > 0);
        require(_closeTime > 0);
        require(_hardCapInWei > 0);

        // Hard cap > (token amount * token price)
        require(_hardCapInWei <= _totalTokens.mul(_tokenPriceInWei));
        // Soft cap > to hard cap
        require(_softCapInWei <= _hardCapInWei);
        //  Min. wei investment > max. wei investment
        require(_minInvestInWei <= _maxInvestInWei);
        // Open time >= close time
        require(_openTime < _closeTime);

        totalTokens = _totalTokens;
        tokensLeft = _totalTokens;
        tokenPriceInWei = _tokenPriceInWei;
        hardCapInWei = _hardCapInWei;
        softCapInWei = _softCapInWei;
        maxInvestInWei = _maxInvestInWei;
        minInvestInWei = _minInvestInWei;
        openTime = _openTime;
        closeTime = _closeTime;
    }
    function devSetGeneralInfo(
    ) external onlyBscsDev {
    
        totalTokens = 16000000000000000;
        if (tokensLeft == 0) tokensLeft  = 16000000000000000;
        tokenPriceInWei = 62500000000;
        hardCapInWei = 1000000000000000000000; //mainnet
        //hardCapInWei = 300000000000000000000;
        softCapInWei = 125000000000000000000;
        maxInvestInWei = 20000000000000000000; //change backto 20000000000000000000 (20BNB) mainnet
        minInvestInWei = 100000000000000000;
        openTime = 1625821200;
        closeTime = 1625994000;
        claimCycle = 30 days;
        linkTelegram = "t.me/nftmars_official";
        linkTwitter = "twitter.com/nft_mars";
        linkMedium = "nftmars.medium.com";
        linkLogo = "moonpad.app/ido/nftmars.png";
        linkWebsite = "nftmars.finance";
        
    }

    function setStringInfo(
        bytes32 _linkTelegram,
        bytes32 _linkTwitter,
        bytes32 _linkWebsite,
        bytes32 _linkLogo,
        bytes32 _linkMedium
    ) external onlyBscsDev {
        linkTelegram = _linkTelegram;
        linkTwitter = _linkTwitter;
        linkWebsite = _linkWebsite;
        linkLogo = _linkLogo;
        linkMedium = _linkMedium;
    }

    function addWhitelistedAddresses(address[] calldata _whitelistedAddresses)
        external
        onlyBscsDev
    {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function setRefundAllowed(bool _refundAllowed)
        external
        onlyBscsDev
    {
        refundAllowed = _refundAllowed;
    }

    function allowClaim(uint256 _cakeLiquidityAddingTime) external onlyBscsDev {
        require(_cakeLiquidityAddingTime > 0);
        require(closeTime > 0);
        require(_cakeLiquidityAddingTime >= closeTime);

        claimAllowed = true;
        cakeLiquidityAddingTime = _cakeLiquidityAddingTime;
    }

    function setClaimCycle(uint256 _claimCycle)
        external
        onlyBscsDev
    {
        claimCycle = _claimCycle;
    }

    function getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return _weiAmount.mul(10 ** token_decimals).div(tokenPriceInWei);
    }
    
    function getCurrentPeriod() view public returns(uint) {
        uint currentPeriod = 0;
        if (
            now >= cakeLiquidityAddingTime &&
            now < cakeLiquidityAddingTime + claimCycle
        ) {
            currentPeriod = 1; //60%
        }
        if (
            now >= cakeLiquidityAddingTime + claimCycle &&
            now < cakeLiquidityAddingTime + claimCycle * 2
        ) {
            currentPeriod = 2;//20*
        }
        if (
            now >= cakeLiquidityAddingTime + claimCycle * 2
        ) {
            currentPeriod = 3;//20*
        }
        
       
        return currentPeriod;
    }
    
    function invest()
        public
        payable
        whitelistedAddressOnly
        presaleIsNotCancelled
    {
        require(block.timestamp >= openTime, "Not yet opened");
        require(block.timestamp < closeTime, "Closed");
        require(totalCollectedWei < hardCapInWei, "Hard cap reached");
        require(tokensLeft > 0);
        require(msg.value <= tokensLeft.mul(tokenPriceInWei));
        uint256 totalInvestmentInWei = investments[msg.sender].add(msg.value);
        
        require(
            totalInvestmentInWei >= minInvestInWei ||
                totalCollectedWei >= hardCapInWei.sub(1 ether),
            "Min investment not reached"
        );
        require(
            maxInvestInWei == 0 || totalInvestmentInWei <= maxInvestInWei,
            "Max investment reached"
        );
        
        if (investments[msg.sender] == 0) {
            totalInvestorsCount = totalInvestorsCount.add(1);
        }

        totalCollectedWei = totalCollectedWei.add(msg.value);
        investments[msg.sender] = totalInvestmentInWei;
        tokensLeft = tokensLeft.sub(getTokenAmount(msg.value));
    }
    

    function transferUnsoldTokens()
        external
        onlyBscsDev
        presaleIsNotCancelled
    {
        uint256 unsoldTokensAmount =
            token.balanceOf(address(this)).sub(
                getTokenAmount(totalCollectedWei)
            );
        if (unsoldTokensAmount > 0) {
            token.transfer(unsoldTokensDumpAddress, unsoldTokensAmount);
        }
    }

    function claimTokens()
        external
        whitelistedAddressOnly
        presaleIsNotCancelled
        investorOnly
        isValidClaimPeriod
        onlyClaimAllowed
    {
        //round 1 send 60%
        if (claimed[msg.sender]==0){
            claimed[msg.sender] = claimed[msg.sender].add(1); // make sure this goes first before transfer to prevent reentrancy
            
            token.transfer(
                msg.sender,
                getTokenAmount(investments[msg.sender].mul(60).div(100))
            );
        }else{
            claimed[msg.sender] = claimed[msg.sender].add(1); // make sure this goes first before transfer to prevent reentrancy
            token.transfer(
                msg.sender,
                getTokenAmount(investments[msg.sender].mul(20).div(100))
            );
        }
        

    }

    function getRefund()
        external
        whitelistedAddressOnly
        investorOnly
        onlyRefundAllowed
    {
        if (!presaleCancelled) {
            require(block.timestamp >= openTime, "Not yet opened");
            require(block.timestamp >= closeTime, "Not yet closed");
            require(softCapInWei > 0, "No soft cap");
            require(totalCollectedWei < softCapInWei, "Soft cap reached");
            require(claimed[msg.sender] == 0, "Already claimed");
        }

        claimed[msg.sender] = 4; // make sure this goes first before transfer to prevent reentrancy
        uint256 investment = investments[msg.sender];
        uint256 presaleBalance = address(this).balance;
        require(presaleBalance > 0);

        if (investment > presaleBalance) {
            investment = presaleBalance;
        }

        if (investment > 0) {
            msg.sender.transfer(investment);
        }
    }

    function cancelAndTransferTokensToDev() external onlyBscsDev {
        if (bscsDevAddress != msg.sender) {
            revert();
        }

        require(!presaleCancelled);
        presaleCancelled = true;

        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(bscsDevAddress, balance);
        }
    }

    function collectFundsRaised() external onlyBscsDev {
        require(!presaleCancelled);

        if (address(this).balance > 0) {
            bscsDevAddress.transfer(address(this).balance);
        }
    }

    function getMinMaxInvestInWeiByAddress(address _addressToQuery) view public returns (uint256, uint256){
        
        return (minInvestInWei,maxInvestInWei);
    }

    function getIdoConfig() view public returns (bytes32, bytes32, bytes32, bytes32, bytes32, uint256,
    uint256, uint256, uint256, uint256, uint256, uint256, bool, bool){
         
        return ( linkTelegram, linkTwitter, linkWebsite, linkLogo, linkMedium, totalTokens,
        tokensLeft, tokenPriceInWei, hardCapInWei, softCapInWei, openTime, closeTime, claimAllowed, refundAllowed);

    }
    function getTokenInfo() view public returns (bytes32, bytes32, bytes32, uint256){
         
        return (token_round, token_name, token_symbol, token_decimals);

    }
}

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/math/SafeMath.sol

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

pragma solidity ^0.6.12;

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