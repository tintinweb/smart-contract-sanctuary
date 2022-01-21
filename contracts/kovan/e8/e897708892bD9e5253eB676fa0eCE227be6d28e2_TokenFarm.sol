// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
//ERC20 standard interface
import "IERC20.sol";
//price feed
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    // mapping token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // mapping user address -> num tokens staked
    mapping(address => uint256) public uniqueTokensStaked;
    //token address -> priceFeed address
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public stakers;
    address[] public allowedTokens;
    //our ERC20 token
    IERC20 public dappToken;

    constructor(address _dappTokenAddress) public {
        //our contract token
        dappToken = IERC20(_dappTokenAddress);
    }

    /**
     * sets the mapping of the priceFeed address to the token address
     * Only the owner has access to this function
     */
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    /**
     * Issues reward tokens to users who have stake
     * Only the owner has access to this function
     *
     * 100 ETH 1:1 for every 1 ETH, we give 1 DappToken
     * 50 ETH and 50 DAI staked, and we want to give a reward of 1 DAPP / 1 DAI
     */
    function issueTokens() public {
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            //transfer some of our tokens to the staked holder - able to use transfer instead
            //of transferFrom b/c we own the token we are transferring => transferring 1:1 for
            //demo but can do some math if want less or more
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    /**
     * gets user's total staked token value
     * @param _user The user address calculating total staked token value
     * @return number value of the user's staked tokens
     */
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "User has no tokens staked!");
        //loop through the available tokens and calculate how much the user has for the token
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    /**
     * gets user's single token value
     * @param _user The user address want to look up
     * @param _token The token address want to loop up for the user
     * @return  token value of a single token for the user
     */
    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            //no tokens staked means 0 value
            return 0;
        }
        // price of the token * stakingBalance[_token][user] -> need current price of tokens
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        // 10000000000000000000 ETH
        // ETH/USD -> 10000000000
        // 10 * 100 = 1,000
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    /**
     * gets a token's current price using AggregatorV3
     * @param _token The token address want to get the current price
     * @return The current price of the token
     * @return The number of decimals the price feed outputs
     */
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        //get token latest price
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    /**
     * @notice Stakes a token if the token is available to be staked and if
     * there is enough of it
     * @param _amount The amount user wants to stake
     * @param _token The token address the user wants to stake
     */
    function stakeTokens(uint256 _amount, address _token) public {
        // how much can be staked? => any amnt over 0
        require(_amount > 0, "Amount must be more than 0.");
        // what tokens can be staked?
        require(
            tokenIsAllowed(_token),
            "Token is currently not available to be staked."
        );
        // send user token amount to this contract address - calling transferFrom instead of transfer
        // because the users calling this function don't own the tokens that are being used
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        //keep track of how many tokens the user is staking
        updateUniqueTokensStaked(msg.sender, _token);
        //add the staked amount for the user and their token
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        //add user to the list of stakers if its their first time - check for 1 don't add more than
        //that, if they go back down to 1, we can check if theyre in the list and not add
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    /**
     * unstakes all the staked tokens for a user and specified token
     * @param _token The token address the user wants to unstake
     */
    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0.");
        //transfer staked token back to user - send all
        IERC20(_token).transfer(msg.sender, balance);
        //reset staking balance of user
        stakingBalance[_token][msg.sender] = 0;
        //decrease number of tokens the user is staking in data
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    /**
     * @notice keeps track of how many tokens a user is staking - makes it
     * easier for issuing tokens to stakers
     * @param _user The user address needed to update the uniqueTokens mapping
     * @param _token The token address needed to connect the user's mapping
     */
    function updateUniqueTokensStaked(address _user, address _token) internal {
        // If the stakingBalance of the user for the token is <= 0, then we can
        // add to the number of tokens the user is staking
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    /**
     * @notice Can add a new token to the available tokens for the application to use
     * Only the owner has access to this function
     * @param _token The token address owner wants to add to the application
     */
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    /**
     * @notice Checks if a token is on the list to be used
     * @param _token The token address that the user wants to check is in the availibility list
     * @return bool value on if the given token is in the list
     */
    function tokenIsAllowed(address _token) public view returns (bool) {
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