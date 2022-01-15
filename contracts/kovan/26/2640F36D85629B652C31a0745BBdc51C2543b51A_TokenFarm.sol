/*
What do I want this contract to do?
    1. Stake tokens
    2. Unstake tokens
    3. Issue token rewards (will need to mint from our shitcoin contract to do so). Set this up so only protocol can mint
    4. Add allowed tokens (track allowable tokens)
    5. Get value of tokens in ETH

*/
// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol"; // Notice for import we don't have to pull down the interface, save it to our brownie file, etc.
import "AggregatorV3Interface.sol";

// import above represents ABI. Remember, we need ABI + address
contract TokenFarm is Ownable {
    //mapping(address => bool) allowedTokens;
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public allowedTokens;
    address[] public stakers; // List of people who staked a token; any token at all? Yes, we will calculate what tokens staked later.
    IERC20 public shitCoinToken;

    // Need constructor so protocol knows the location of the reward token
    constructor(address _shitCoinTokenAddress) public {
        shitCoinToken = IERC20(_shitCoinTokenAddress);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        // Stake X amount of token at Y address
        require(_amount > 0, "Must deposit more than 0 coins");
        //require(allowedTokens(_token)); // 12;59:22 course has a different methodology. I think mine will work, going with chainlin implementation
        require(isTokenAllowed(_token), "Token cannot be staked");

        // Call transfer from on ERC20. But don't we have to allow first? We want to transfer from token contract to our contract.
        // We'll call transferFrom (transferFrom function is on ERC20 contract),
        // Do I need the wETH token? Or can I just use and ERC20 contract? I can use the base contract and pass the correct address
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Only add staker to address if not already owning a token.
        // We are also going to keep track of how many unique tokens a user has. If this number is one, we'll add them to 'stakers' address

        updateUniqueTokensStaked(msg.sender, _token);

        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        // Fetch token balance
        uint256 stakedBalance = stakingBalance[_token][msg.sender];
        require(stakedBalance > 0, "Staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, stakedBalance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
        // Will we need to call this function when allowing a token?
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            // update unique tokens stake. Notice in our stakeTokens function this is called BEFORE we update the stakingBalance mapping
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function isTokenAllowed(address _token) public returns (bool) {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (allowedTokens[index] == _token) {
                return true;
            }
        }
        return false;
    }

    function issueTokens() public onlyOwner {
        // we want to issue tokens based on the underlying value of the tokens they've staked.
        // we want this function to issue to ALL stakers, then calculate how much they get based on their holdings.
        for (uint256 index = 0; index < stakers.length; index++) {
            address recipient = stakers[index];
            uint256 userTotalValue = getUserTotalValue(recipient);
            shitCoinToken.transfer(recipient, userTotalValue);
            // send token reward from ShitCoin based on total locked in. What is our reward token? ShitCoin token
            // How do we send a reward from ERC20? Do we call mint function?
            // We have to reward them with shitcoins owned by the defi protocol.
            // shitCoin.transfer(recipient)
        }
    }

    function getUserTotalValue(address _user) public returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        // Calculate value of allowed tokens. For each allowed token, find out how much they have
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            // number of tokens
            // do conversion math
            address token = allowedTokens[index];
            totalValue = totalValue + getUserSingleTokenValue(_user, token);
            // add conversion to total value.
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        // Return value in $USD. If ETH is 2k, then 1 ETH will return 2000
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        uint256 numOfTokens = stakingBalance[_token][_user];

        // price of the token (in USD) * stakingBalance[_token][user] (# of tokens)
        (uint256 price, uint256 decimals) = getTokenValue(_token); // Returns price of token

        // Calculate token value, keeping in mind the decimals configured by price
        // 10 ETH ( with 18 decimals)
        // ETH/USD -> 100 (with 8 decimals) So we need to do some math to keep dcimals consistent. Multiple eth/usd by 10^10?
        // 10 * 100 = $1,000 USD
        return (numOfTokens * price) / (10**decimals);
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256 price, uint256 decimals)
    {
        // Need pricing information.
        address tokenPriceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface tokenPriceFeed = AggregatorV3Interface(
            tokenPriceFeedAddress
        );
        (, int256 price, , , ) = tokenPriceFeed.latestRoundData(); //
        uint256 decimals = tokenPriceFeed.decimals();
        return (uint256(price), uint256(decimals));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        return msg.data;
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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