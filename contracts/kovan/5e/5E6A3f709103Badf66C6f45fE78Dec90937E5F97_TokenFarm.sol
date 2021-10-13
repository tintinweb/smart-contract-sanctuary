/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



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
    // What are the things that we want our farm to achieve?
    // 1. Allow user to stake token
    // 2. Unstake Tokens
    // 3. Issue tokens (rewards given to the users for staking in our farm)
    // 4. Add more tokens in future
    // 5. getEthValue

    // How do we decide how much DAPP token to give based on what they staked?
    // for e.g. if they staked 100 ETH => 100 DAPP, what if they staked 50 ETH and 50 DAI? How much DAPP should be given?
    // in this case first convert any other token to ETH, so 50 DAI => ? ETH. and then provide (50 + ?) DAPP Tokens

    // we need to take into account the total no. of tokens being staked by a user (need some mapping)
    // tokenAddress => (userAddress => tokenAmount)
    mapping(address => mapping(address => uint256)) public stakingBalance;

    address[] public allowedTokens;

    address[] public stakers;

    mapping(address => uint256) public uniqueTokenStaked;

    IERC20 public dappToken;

    mapping(address => address) public tokenPriceFeedMapping;

    constructor(address _dappTokenAddress) public {
        // we are fetching the contract of our reward token that we'll be giving to the users
        dappToken = IERC20(_dappTokenAddress);
    }

    function setTokenPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        for (uint256 index = 0; index < stakers.length; index++) {
            address recipients = stakers[index];
            uint256 userTotalValue = getUserTotalValue(recipients);
            // send them token rewards, based on how much token have they staked (TVL)
            // we are using transfer() instead of transferFrom() because dappToken is owned by this farm
            dappToken.transfer(recipients, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;

        require(uniqueTokenStaked[_user] > 0, "No token staked!");

        for (uint256 index = 0; index < allowedTokens.length; index++) {
            totalValue += getUserSingleTokenValue(_user, allowedTokens[index]);
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        // basically we are converting the token to its dollar value
        // so 100 USDT -> $ 100
        // or 1 ETH -> $ 3000

        if (uniqueTokenStaked[_user] <= 0) {
            return 0;
        }

        (uint256 price, uint256 decimals) = getTokenValue(_token);

        // amount of token user has staked * USD equivalent
        // e.g. 10 ETH , priceFeed -> ETH/USD -> 100 $
        // 10 * 100 => 1000
        // staking balance is in decimals (18)
        return (stakingBalance[_token][_user] * price) / 10**decimals;
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // we need chainlinks help, to convert the token to its dollar equivalent
        // we need priceFeedAddresses
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );

        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());

        return (uint256(price), decimals);
    }

    function stakeToken(uint256 _amount, address _token) public {
        // 1. What kind of tokens they can stake?
        // 2. How much can we stake?
        require(_amount > 0, "Please stake more than 0");
        // we also need to check whether the provided token is valid or is allowed
        require(isTokenAllowed(_token), "This token is not allowed!");
        // if things are looking good, then we need to transfer the token from their wallet to farm
        // to do that we need to call the ERC20 transferFrom()
        // grab the ABI, and transfer
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // we need to store this information somewhere, so that when its time to unstake, we can return them what they staked

        // we also need to maintain total unique stakers as well
        if (uniqueTokenStaked[msg.sender] <= 0) {
            // the user is new, as they have no tokens staked
            stakers.push(msg.sender);
        }

        // we also need to maintain a count of how many unique tokens the user has staked
        updateUniqueTokenStaked(msg.sender, _token);
        // update the staking balance
        stakingBalance[_token][msg.sender] += _amount;
    }

    function unstakeToken(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "You can't unstake what you haven't staked!");
        IERC20(_token).transfer(msg.sender, balance);

        stakingBalance[_token][msg.sender] = 0;
        // is this vulnerable to reentrancy attack?
        uniqueTokenStaked[msg.sender] -= 1;
    }

    function updateUniqueTokenStaked(address _user, address _token) internal {
        // check if the user is staking a totally unique token or is staking more to an already staked token
        if (stakingBalance[_token][_user] <= 0) {
            // if there is no staked balance for the mentioned token, it means it is totally unique
            // we update a new mapping unique token staked, this will let us know, how many unique token has this user staked
            uniqueTokenStaked[_user] += 1;
        }
    }

    function addTokens(address _token) public onlyOwner {
        // we only want admin to add tokens
        allowedTokens.push(_token);
    }

    function isTokenAllowed(address _token) public returns (bool) {
        // loop through allowedTokens list to see if the token is valid and allowed
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (allowedTokens[index] == _token) {
                return true;
            }
        }
        return false;
    }
}