/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: TokenFarm.sol

contract TokenFarm is Ownable {
    // token address -> staker address -> amount
    // this way we can keep track of how much of each token each staker has staked
    mapping(address => mapping(address => uint256)) public stakingBalance;

    // this way we know how many different tokens each one of these address has staked
    mapping(address => uint256) public uniqueTokensStaked;

    mapping(address => address) public tokenPriceFeedMapping;

    address[] public stakers;

    address[] public allowedTokens;

    IERC20 public dappToken;

    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function getTokenValue(address _token) public view returns (uint256, uint256) {
        // here we need some price information
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (, int256 price,,,)= priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), uint256(decimals));
    }

    function getUserSingleTokenValue(address _user, address _token) public view returns(uint256) {
        // we need to get value of how much this person (_user) staked of this single token
        // for example if he staked 1 ETH and the price of 1ETH is $2000, we wanna make sure that it returns 2000
        // or if it has 200 DAI staked of the price $200, we wanna make sure it returns 200
        // so we are getting a conversion rate, how much value this person staked in our application.

        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }

        // how do we actual get the value of a single token ?
        // we need to get the staking balance but we also need the price of that token
        // so we need a price of the token and multiply that by the staking balance of the token of the user
        // formula: price of the token * stakingBalance[_token][user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);

        // we are taking the amount of the token user has staked, let's say for example 10 ETH,
        // we are taking a price of that ETH maybe we have all of our contracts all of these tokens get converted
        // back to the USD price so we have ETH/USD, let's say price is $100 per USD,
        // so this first bit is we're going to that 10ETH * $100 = 1,000 value, but we also need to divide by the decimals
        // so our staking balance is going to be in 18decimals 10 00000000 0000000000 but
        // our ETH/USD has only 8 decimals so 100 00000000
        return (stakingBalance[_token][_user] * price / 10**decimals);
    }
    function getUserTotalValue(address _user) public view returns(uint256) {
        // getUserTotalValue is a total value across all different tokens,
        require(uniqueTokensStaked[_user] > 0, "No tokens staked");

        uint256 totalValue = 0;
        for (uint256 allowedTokensIndex = 0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++) {
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[allowedTokensIndex]);
        }
        return totalValue;
    }

    // when we mark a function onlyOwner, only admin can run it.
    function issueTokens() public onlyOwner {
        // It is a reward we given to users who use our platform,
        // so we want to issue some tokens based of the value of underline tokens they given us

        // 100 ETH 1:1 for every 1 ETH, we give 1 DappToken
        // 50 ETH and 50 DAI staked, and we want to give a reward of 1 DAPP / 1 DAI

        for(uint256 stakersIndex = 0; stakersIndex < stakers.length; stakersIndex++) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);

            // 1) How much they have in total valued staked on our platform we will issue them as a reward
            // 2) send them a token reward based on their total value locked.
            // 3) we can call transfer because our TokenFarm contract is going to be the contract
            // that actually holds all these dapp tokens
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    // internal, only this contract can call this function
    function updateUniqueTokensStaked(address _user, address _token) internal {
        // if user has a balance set to 0 it means it's first operation on this token
        // adding them before issuing a balance says that it's first operation and unique
        if (stakingBalance[_token][_user] <= 0) {
            // track number of unique tokens particular user staked
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function stakeTokens(uint256 _amount, address _token) public payable {
        // what tokens can they stake ?
        // how much can they stake ?
        require(_amount > 0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently no allowed");
        // IERC20 is an ABI interface to call ERC20 methods
        // https://eips.ethereum.org/EIPS/eip-20
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;

        if(uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        // how much of this token does this user have
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
        // can this e reentrancy attacked ?

        // not the last thing we could do is we probably should actually update our stakers array
        // to remove this person if they no longer have anything staked.
        // this is a little bit sloppy we're just going to skip doing that for the time being
        // however if you want to go back and ad the functionality to remove the stakers from the stakers list
        // as they unstake please go for it, it's not a big deal if we don't actually do this because
        // our issueTokens function is actually going to see how much they actually have staked
        // if they don't have anything staked then they're not going to get sent any tokens.
    }

    // we just want to give permission to admin/owner to add new tokens
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for(uint256 allowedTokensIndex=0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++) {
            if(allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}