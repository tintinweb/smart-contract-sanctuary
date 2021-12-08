/**
 *Submitted for verification at Etherscan.io on 2021-12-08
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
    // mapping token address -> staker address -> amount:
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokenStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public stakers;
    address[] public allowedTokens;
    IERC20 public dappToken;

    // stakeTokens
    // unstakeTokens
    // issueTokens
    // addAllowedTokens
    // getEthValue

    constructor (address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner 
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // Issue tokens to all stakers
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex ++
        ) {
            // get the recipient of the rewards for staking tokens address;
            address recipient = stakers[stakersIndex];
            // get the recipients total value staked;
            uint256 userTotalValue = getUserTotalValue(recipient);
            // transfer to the recipient the reward in out dappToken = ISSUING the new token in ratio 1:1
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        // get user total value of staked tokens, i.e. allowed staked tokens;
        // if an user does not staked any allowed tokens, do not continue further (see the require part);
        uint256 totalValue = 0;
        require(uniqueTokenStaked[_user] > 0);
        for (
            uint256 allowedTokenIndex = 0;
            allowedTokenIndex < allowedTokens.length;
            allowedTokenIndex ++
        ) {
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[allowedTokenIndex]);
        }
        return totalValue;

    }

    function getUserSingleTokenValue(address _user, address _token) public view returns (uint256) {
        // get a value of _token which _user stakes;
        if (uniqueTokenStaked[_user] <= 0) {
            return 0;
        }
        // token price * amount of the token
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return(
            // Amount of user tokens multiplied by price which both are in decimals, thus we need
            // devided them by those decimals, for example:
            // Amount = 10 ETH (it is actualy 10 * (10**18) = 18 decimals)
            // Price = 4500 ETH/USD (it might be actually 4500 * (10**8) = 8 decimals)
            stakingBalance[_token][_user] * price / (10**decimals)
            );
    }

    function getTokenValue(address _token) public view returns (uint256, uint256) {
        // get the token stored in token price mapping:
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        // create a variable AggregatorV3Interface called priceFeed and assign to it 
        // AggregatorV3Interface of priceFeedAddress
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int256 price,,,) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }
    
    function stakeTokens(address _token, uint256 _amount) public {
        // stake tokens if the amount to be staked is > 0 and token is allowed to be staked
        require(_amount > 0, "Amount must be more than 0!");
        require(tokenIsAllowed(_token), "Token is not allowed to be staked!");
        // wrap _token to ERC20 interface and send tokens to this contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // update the sender's number of unique tokens staked
        updateUniqueTokensStaked(msg.sender, _token);
        // increase the staking balance of the msg.sender by the amount staked
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;
        // if this is the user's first token staked, add user to list of stakers
        stakers.push(msg.sender);
    }

    function unstakeTokens(address _token, uint256 _amount) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        // check if the staking balance is non zero;
        require(balance > 0, "Staking balance cannot be zero.");
        // check if the amount to be unstaked is equal or less than balance staked;
        require(balance <= _amount, "You do not have this amount of token staked.");
        // transfer the token from the contract to the msg.sender;
        IERC20(_token).transfer(msg.sender, _amount);
        // update staking balance
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] - _amount;
        // if staking balanace is zero, then update uniqueTokenStaked and remove the msg.sender
        // from the stakers' array
        if (stakingBalance[_token][msg.sender] == 0) {
            uniqueTokenStaked[msg.sender] = uniqueTokenStaked[msg.sender] - 1;
            // removeStaker function increases gas used and it is not necessary to delete it as issue function
            // checks if a staker does have any token staked and how much;
            removeStaker(msg.sender);
        }
    }

    function removeStaker(address _staker) internal {
        // removing a staker from the stakers array 
        for (uint256 i; i < stakers.length; i++) {
            if (_staker == stakers[i]) {
                stakers[i] = stakers[stakers.length - 1];
                delete stakers[stakers.length - 1];
                break;
            }
        }
    }

    // find out if an user already stakes and how many tokens; 
    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokenStaked[_user] = uniqueTokenStaked[_user] + 1;
        }
    }

    // add token to allowed tokens list by Owner
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    // check if a token is allowed to be staked
    function tokenIsAllowed(address _token) public returns (bool) {
        for (uint256 allowedTokensIndex=0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex ++) {
                if (allowedTokens[allowedTokensIndex] == _token) {
                    return true;
                }
            }
        return false;
    }
}