// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.0;

contract TokenDistribution is Ownable {

    address public token;
    address public oracle;
    
    // price format is 8 decimals precision: $1 = 100000000, $0.01 = 1000000
    uint256 public tokenPriceUSD     = 5000000; // 0.05 USD
    uint256 public minLimitUSD   = 50000000000; // 500 USD
    uint256 public maxLimitUSD = 2000000000000; // 20 000 USD

    uint256 public weiRaised;
    uint256 public notClaimedTokens;

    uint256 public presaleStartsAt;
    uint256 public presaleEndsAt;
    uint256 public claimStartsAt;

    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public preBoughtTokens;
    mapping(address => uint256) public contributionInUSD;

    event Withdraw(address indexed owner, uint256 indexed amount);
    event BuyTokens(address indexed buyer, uint256 indexed tokens, uint256 indexed pricePerToken, uint256 buyingPower);
    event PreBuyTokens(address indexed buyer, uint256 indexed tokens, uint256 indexed pricePerToken, uint256 buyingPower);
    event ClaimedTokens(address indexed buyer, uint256 indexed tokens);

    constructor(
        address _token, 
        address _oracle,
        uint256 _presaleStartsAt,
        uint256 _presaleEndsAt,
        uint256 _claimStartsAt
        ) public {

        require(_token != address(0));
        require(_oracle != address(0));
        
        require(_presaleStartsAt > block.timestamp, "Presale should start now or in the future");
        require(_presaleStartsAt < _presaleEndsAt, "Presale cannot start after end date");
        require(_presaleEndsAt < _claimStartsAt, "Presale end date cannot be after claim date");

        token = _token;
        oracle = _oracle;

        presaleStartsAt = _presaleStartsAt;
        presaleEndsAt = _presaleEndsAt;
        claimStartsAt = _claimStartsAt;
    }

    modifier isWhitelisted {
        require(whitelisted[msg.sender], "User is not whitelisted");

        _;
    }

    modifier isPresale {
        require(block.timestamp >= presaleStartsAt && block.timestamp <= presaleEndsAt, "It's not presale period");

        _;
    }

    modifier hasTokensToClaim {
        require(preBoughtTokens[msg.sender] > 0, "User has NO tokens");

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
        
        uint256 usersTokens = preBoughtTokens[msg.sender];
        preBoughtTokens[msg.sender] = 0;

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

    function buyTokens() public payable isPresale isWhitelisted {
        
        (uint256 tokens, uint256 pricePerTokenEth) = calculateNumberOfTokens(msg.value);
        require(tokens > 0, "Insufficient funds");

        uint256 tradeAmountInUSD = (tokens * tokenPriceUSD) / 10 ** 18;
        
        require(tradeAmountInUSD >= minLimitUSD, "Send amount is below min limit");
        require(tradeAmountInUSD + contributionInUSD[msg.sender] <= maxLimitUSD, "Send amount is above max limit");

        preBoughtTokens[msg.sender] += tokens;
        contributionInUSD[msg.sender] += tradeAmountInUSD;
        weiRaised += msg.value;
        notClaimedTokens += tokens;

        emit PreBuyTokens(msg.sender, tokens, pricePerTokenEth, msg.value);
    }

    function calculateNumberOfTokens(uint256 _wei) public view returns(uint256, uint256){

        uint256 pricePerTokenETH = getPriceInEthPerToken();
        uint256 numberOfTokens = divide(_wei, pricePerTokenETH, 18);
        if (numberOfTokens == 0) {
            return(0,0);
        }

        return (numberOfTokens, pricePerTokenETH);
    }

    function getPriceInEthPerToken() public view returns(uint256) {
        int oraclePriceTemp = getLatestPriceETHUSD();
        require(oraclePriceTemp > 0, "Invalid price");

        uint256 oraclePriceETHUSD = uint256(oraclePriceTemp);

        // returned value format is in 18 decimals precision
        return divide(tokenPriceUSD, oraclePriceETHUSD, 18);
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

    function getDecimalOracle() public view returns (uint8) {
        (
            uint8 decimals
        ) = AggregatorV3Interface(oracle).decimals();

        return decimals;
    }

    function divide(uint a, uint b, uint precision) private pure returns ( uint) {
        return (a * (10**precision)) / b;
    }

    function whitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

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

// SPDX-License-Identifier: MIT

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}