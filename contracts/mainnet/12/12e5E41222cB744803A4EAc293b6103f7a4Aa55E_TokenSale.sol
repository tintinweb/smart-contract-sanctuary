/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: MIT

/*
 *       $$$$$$_$$__$$__$$$$__$$$$$$
 *       ____$$_$$__$$_$$_______$$
 *       ____$$_$$__$$__$$$$____$$
 *       $$__$$_$$__$$_____$$___$$
 *       _$$$$___$$$$___$$$$____$$
 *
 *       $$__$$_$$$$$$_$$$$$__$$_____$$$$$
 *       _$$$$____$$___$$_____$$_____$$__$$
 *       __$$_____$$___$$$$___$$_____$$__$$
 *       __$$_____$$___$$_____$$_____$$__$$
 *       __$$___$$$$$$_$$$$$__$$$$$$_$$$$$
 *
 *       $$___$_$$$$$$_$$$$$$_$$__$$
 *       $$___$___$$_____$$___$$__$$
 *       $$_$_$___$$_____$$___$$$$$$
 *       $$$$$$___$$_____$$___$$__$$
 *       _$$_$$_$$$$$$___$$___$$__$$
 *
 *       $$__$$_$$$$$__$$
 *       _$$$$__$$_____$$
 *       __$$___$$$$___$$
 *       __$$___$$_____$$
 *       __$$___$$$$$__$$$$$$
 */

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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


interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}


contract TokenSale is Ownable {
    address public token;
    address public oracle;
    uint256 public threshold; // with 1e18

    uint256 public initialPrice; // with 1e18
    uint256 public tokenPriceUSD; // with 1e18

    uint256 public weiRaised; // with 1e18
    uint256 public notClaimedTokens; // with 1e18

    uint256 public presaleStartsAt;
    uint256 public presaleEndsAt;
    uint256 public claimStartsAt;

    mapping(address => uint256) public contributionInWei;
    mapping(address => uint256) public contributionInUSD;

    event Withdraw(address indexed owner, uint256 indexed amount);
    event BuyTokens(address indexed buyer, uint256 indexed tokens, uint256 indexed pricePerToken, uint256 buyingPower);
    event PreBuyTokens(address indexed buyer, uint256 indexed tokens, uint256 indexed pricePerToken, uint256 buyingPower);
    event ClaimedTokens(address indexed buyer, uint256 indexed tokens);

    constructor(
        address _token,
        address _oracle,
        uint256 _initialPrice,
        uint256 _threshold,
        uint256 _presaleStartsAt,
        uint256 _presaleEndsAt,
        uint256 _claimStartsAt
        ) public {

        require(_token != address(0));
        require(_oracle != address(0));

        require(_initialPrice > 0, "Price should be bigger than 0");
        require(_threshold > 0, "Threshold should be bigger than 0");
        require(_presaleStartsAt > block.timestamp, "Presale should start now or in the future");
        require(_presaleStartsAt < _presaleEndsAt, "Presale cannot start after end date");
        require(_presaleEndsAt < _claimStartsAt, "Presale end date cannot be after claim date");

        token = _token;
        oracle = _oracle;

        threshold = _threshold * 1e18;
        initialPrice = _initialPrice;
        tokenPriceUSD = _initialPrice;
        presaleStartsAt = _presaleStartsAt;
        presaleEndsAt = _presaleEndsAt;
        claimStartsAt = _claimStartsAt;
    }


    modifier isPresale {
        require(block.timestamp >= presaleStartsAt && block.timestamp <= presaleEndsAt, "It's not presale period");

        _;
    }

    modifier hasTokensToClaim {
        require(contributionInWei[msg.sender] > 0, "User has NO tokens");

        _;
    }

    modifier claimStart {
        require(block.timestamp >= claimStartsAt, "Claim period not started");

        _;
    }

    receive() external payable {
        buyTokens();
    }

    function claimTokens() public claimStart hasTokensToClaim {
        uint256 userWeis = contributionInWei[msg.sender];
        contributionInWei[msg.sender] = 0;
        uint256 _priceInWeiPerToken = getPriceInWeiPerToken(tokenPriceUSD);
        uint256 usersTokens = 1e18 * userWeis / _priceInWeiPerToken;

        notClaimedTokens -= usersTokens;

        IERC20(token).transfer(msg.sender, usersTokens);
        emit ClaimedTokens(msg.sender, usersTokens);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        address payable ownerPayable = payable(msg.sender);
        ownerPayable.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function withdrawTokens() external onlyOwner claimStart {
        uint256 unsoldTokens = IERC20(token).balanceOf(address(this));

        IERC20(token).transfer(msg.sender, unsoldTokens - notClaimedTokens);
    }

    function buyTokens() public payable isPresale {
        uint256 maxTokenPriceUSD = initialPrice * 2**4;
        uint256 _priceInWeiPerToken = getPriceInWeiPerToken(tokenPriceUSD);
        uint256 tokens = 1e18 * msg.value / _priceInWeiPerToken;
        uint256 tokensByMaxPrice = tokens / (maxTokenPriceUSD/tokenPriceUSD);
        require(tokens > 0, "Insufficient funds");

        uint256 buyLimitTokens = remainingTokensByMaxPrice();
        require(buyLimitTokens > tokensByMaxPrice, "There is no more tokens to sell");

        uint256 tradeAmountInUSD = tokens * tokenPriceUSD / 1e36; // in USD

        contributionInWei[msg.sender] += msg.value;
        contributionInUSD[msg.sender] += tradeAmountInUSD;
        weiRaised += msg.value;
        notClaimedTokens += tokens;

        updateTokenPrice(_priceInWeiPerToken);

        emit PreBuyTokens(msg.sender, tokens, _priceInWeiPerToken, msg.value);
    }

    function remainingTokensByMaxPrice() internal returns(uint256) {
        uint256 maxTokenPriceUSD = initialPrice * 2**4;
        uint256 _priceInWeiPerToken = getPriceInWeiPerToken(maxTokenPriceUSD);
        uint256 purchesedTokensByMaxPrice = 1e18 * weiRaised / _priceInWeiPerToken;

        return threshold - purchesedTokensByMaxPrice;
    }

    function remainingTokensByCurrentPrice() public view returns(uint256) {
        uint256 _priceInWeiPerToken = getPriceInWeiPerToken(tokenPriceUSD);
        uint256 purchesedTokens = 1e18 * weiRaised / _priceInWeiPerToken;

        return threshold - purchesedTokens;
    }

    function updateTokenPrice(uint256 _priceInWeiPerToken) internal {
        uint256 purchesedTokens = 1e18 * weiRaised / _priceInWeiPerToken;
        while (purchesedTokens > threshold && tokenPriceUSD / initialPrice < 16) {
            tokenPriceUSD = tokenPriceUSD * 2;
            notClaimedTokens = notClaimedTokens / 2;
            purchesedTokens = 1e18 * weiRaised / getPriceInWeiPerToken(tokenPriceUSD);
        }
    }

    function balanceOf(address adr) public view returns(uint256) {
        uint256 userWeis = contributionInWei[adr];
        uint256 _priceInWeiPerToken = getPriceInWeiPerToken(tokenPriceUSD);
        uint256 tokens = 1e18 * userWeis / _priceInWeiPerToken;
        return tokens;
    }

    function getPriceInWeiPerToken(uint256 _tokenPriceUSD) public view returns(uint256) {
        int oraclePriceTemp = getLatestPriceETHUSD(); // with 10**getDecimalsOracle()
        require(oraclePriceTemp > 0, "Invalid price");

        return _tokenPriceUSD * 10**getDecimalsOracle() / uint256(oraclePriceTemp); // result with 1e18
    }

    function getPriceInWeiPerToken() public view returns(uint256) {
        return getPriceInWeiPerToken(tokenPriceUSD);
    }

    function getLatestPriceETHUSD() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(oracle).latestRoundData();

        return price;
    }

    function getDecimalsOracle() public view returns (uint8) {
        (
            uint8 decimals
        ) = AggregatorV3Interface(oracle).decimals();

        return decimals;
    }

}