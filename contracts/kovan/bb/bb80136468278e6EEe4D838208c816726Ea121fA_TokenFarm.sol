// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

/**
 * @title TokenFarm - token farm contract
 * @author jw
 *
 * Supports the following:
 *   - Stake tokens (users)
 *   - Unstake tokens (users)
 *   - Issue tokens, for rewards (admin only)
 *   - Add allowed token types (admin only)
 *   - Get the value of the staked tokens in ETH
 */

contract TokenFarm is Ownable {
    // Mapping: token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // Mapping: staker address -> number
    mapping(address => uint256) public uniqueTokensStaked;
    // Mapping: token address -> associated price feed address
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public stakers;
    address[] public allowedTokens;
    IERC20 public dappToken;

    /**
     * @dev On deployment, pass the contract the address of the Dapp Token
     * This is the token that will be used to pay rewards to stakers
     */
    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    /**
     * ADMIN ACTIONS
     */

    /**
     * @dev Admin can set the price feed associated with a particular token
     * @param _token Address of the token
     * @param _priceFeed Address of the price feed
     */
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    /**
     * @dev Admin can issue reward tokens to a contract based on how much it's staking
     * Note It's more gas efficient to have the user CLAIM rewards...
     */
    function issueTokens() public onlyOwner {
        // Loop through all stakers
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            // Grab staker from the list of stakers
            address recipient = stakers[stakersIndex];
            // Calculate their TVL
            uint256 userTotalValue = getUserTotalValue(recipient);
            // Send the TVL as a reward
            // TODO change this!!!
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    /**
     * @dev Admin can add a new token to the list of allowed tokens
     * @param _token The address of the token being checked
     */
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    /**
     * Other functions
     */

    /**
     * @dev Calculate the TVL for a user
     * @param _user Address of the user
     * @return Total value of the user
     */
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        // Loop through all the possible tokens the user might be staking
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
     * @dev Calculate the value across multiple tokens
     * @param _user User's address
     * @param _token Token address
     * @return Value a user has staked in a specific token in USD
     */
    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // Price of the token * stakingBalance[_token][user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    /**
     * @dev Gets the value of a token
     * @param _token Address of the token
     * @return Price and the number of decimals
     */
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // Address of the price feed for a token
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        // Use this address on an AggregatorV3Interface to get the price feed contract
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        // Call the price feed to get the price...
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ... and the decimals
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    /**
     * @dev Users can stake an amount of a supported token
     * @param _amount The amount of the token being staked, must be greater than 0
     * @param _token The token being staked, must be on the list of approved tokens
     */
    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be greater than 0.");
        require(tokenIsAllowed(_token), "This token is currently not allowed.");
        // Send the tokens from user to this contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // Keep track of the number of unique tokens staked
        updateUniqueTokensStaked(msg.sender, _token);
        // Keep track of the tokens
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        // Add user to the list of stakers, if this is their first staking
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    /**
     * @dev Users can unstake tokens
     * @param _token Address of the token
     */
    function unstakeTokens(address _token) public {
        // Fetch the staked balance for the user
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        // Transfer the token back to the user
        IERC20(_token).transfer(msg.sender, balance);
        // Update the balance
        stakingBalance[_token][msg.sender] = 0;
        // Update the list of unique tokens
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
        // TODO Update stakers array to remove this user
    }

    /**
     * @dev Update the number of unique tokens a user is staking
     * @param _user The contract address of the user
     * @param _token The contract address of the token we're interested in
     */
    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    /**
     * @dev Checks if a token in on a list of approved tokens
     * @param _token The address of the token being checked
     * @return Result of check, bool true/false
     */
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