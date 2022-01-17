pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol"; // ERC contract interface
import "AggregatorV3Interface.sol"; // for price feed

contract TokenFarm is Ownable {
    // stake token
    // unstake token
    // issue reward token
    // add allowed token
    // get the value

    address[] public allowedTokens;
    // mappping token address --> stake address --> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    address[] public stakers; // register all user address how stakes
    mapping(address => uint256) public uniqueTokensStaked; // how many unique token type a user has
    IERC20 public dappToken;
    mapping(address => address) public tokenPriceFeedMapping; //mapping each token to price feed address

    // need to know: address of Dapp token
    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    function this_address() public returns (address) {
        return address(this);
    }

    function stakeToken(uint256 _amount, address _token) public {
        // what token can they stake?
        // how much can they stake --> >0

        require(_amount > 0, "Amount must be mstakeore than 0");
        require(tokenIsAllowed(_token), "Token is not allowed");

        // https://eips.ethereum.org/EIPS/eip-20
        // transferFrom(address sender, address recipient, uint256 amount)
        // transfer function: call from wallet who owns token
        // transferFrom: transfer from wallet even one doesn't own it. but will validate first
        IERC20(_token).transferFrom(msg.sender, address(this), _amount); // address(this) is contract address
        // address(this) refers to the address of the instance of the contract where the call is being made.
        // msg.sender refers to the address where the contract is being called from.
        // Therefore, address(this) and msg.sender are two unique addresses, the first referring to the address of the contract instance and the second referring to the address where the contract call originated from.

        // track all staked token types a user has
        updateUniqueTokensStaked(msg.sender, _token);

        // track who owns what token and how much
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;

        // register staker
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        // only this contract can call this function
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    // only token from the listed is allowed to stake
    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }

    // issue token as reward
    // ETH: 1:1 for every 1 ETH, we give 1 DappToken
    function issueToken() public onlyOwner {
        // only contract owner can call
        for (
            uint256 stakerIndex = 0;
            stakerIndex < stakers.length;
            stakerIndex++
        ) {
            address recipient = stakers[stakerIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            // send token reward
            // based on total value staked
            dappToken.transfer(recipient, userTotalValue); // can call transfer, as this contract holds all dapp tokens
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        // would be much more gas efficient to ask user claim the tokens via some method
        // instead owner issuing which would be gas expensive

        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No token staked for this user");
        for (
            uint256 allowedTokenIndex = 0;
            allowedTokenIndex < allowedTokens.length;
            allowedTokenIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokenIndex]
                );
        }
        return totalValue;
    }

    // find how much value for each token type a user stake
    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0; // return to 0 if user stakes nothing
        }

        // price of the token * stakeing balancing[_token][user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);

        // 10 eth, eth/usd = 100
        // 10*100 = $10,000
        return ((stakingBalance[_token][_user] * price) / (10**decimals)); // as comma is returned
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // price feed address
        // mapping each token to price feed address: https://docs.chain.link/docs/ethereum-addresses/
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );

        (, int256 price, , , ) = priceFeed.latestRoundData(); //https://docs.chain.link/docs/get-the-latest-price/
        uint256 decimals = uint256(priceFeed.decimals()); // decimals is int8

        return (uint256(price), decimals);
    }

    // done in python deploy.py script
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        // only owner can update the price feed
        // mapping each token to price feed address
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function unStakeTokens(address _token) public {
        // fetch stake balance
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance must be greater than 0");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;

        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
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