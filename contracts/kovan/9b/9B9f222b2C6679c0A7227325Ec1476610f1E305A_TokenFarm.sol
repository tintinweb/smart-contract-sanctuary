/**
*   
*   With the help of this contract we wanna to be able to:
*       addAllowedTokens      
*       setPriceFeedContract
*
*       stakeTokens <- tokenIsAllowed, updateUniqueTokensStaked
*       issueTokens <- getUserTotalValue, getUserSingleTokenValue, getTokenValue, 
*       unStakeTokens
*
**/

// contracts/TokenFarm.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


//
// IMPORTING Dependencies.
//


/**
*   
*   Contract module which provides a basic access control mechanism,
*   where there is an account (an owner) that can be granted
*   exclusive access to specific functions.
*
*   For documentation:
*   https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
*
**/
import "Ownable.sol";

/**
*
*   Interface of the ERC20 standard as defined in the EIP.
*
*   We use interface here because we do not need the whole contract.
*   
*   For documentation:
*   https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20
*
**/
import "IERC20.sol";

/**
*
*   To consume price data, your smart contract should reference AggregatorV3Interface,
*   which defines the external functions implemented by Data Feeds.
*
*   For documentation:
*   https://docs.chain.link/docs/get-the-latest-price/#solidity
*
**/
import "AggregatorV3Interface.sol";


//
// DEFINING TokenFarm Contract.
//


contract TokenFarm is Ownable {


    //
    // DECLARING Types and State Variables.
    //


    // EuroToken address.
    IERC20 public euroToken;
    // List of all different stakers on this platform.
    address[] public stakers;
    // List of all different allowed tokens may be staked.
    address[] public allowedTokens;
    // How much of each token each staker has staked.
    // d = {token_address: {staker_address: amount}}
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // How many different tokens each one of this addresses has actually staked.
    mapping(address => uint256) public uniqueTokensStaked;
    // Map tokens (weth, euro_token, dai) to the associated priceFeed.
    mapping(address => address) public tokenPriceFeedMapping;
    bool public tokenIsAllowedFlag;


    //
    // DECLARING Constructor.
    //
    

    /**
    *
    * Constructor.
    *
    **/
    constructor(address _euroTokenAddress) public {
        // EuroToken address.
        euroToken = IERC20 (_euroTokenAddress);
    }


    //
    // DECLARING Functions.
    //


    /**
    *
    *   Only owner of this contract can add allowed tokens to the array
    *   allowedTokens.
    *
    *   onlyOwner is the modifier for this function.
    *   Throws if called by any account other than the owner.
    *
    **/
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    /**
    *
    *   Set price feed contract associated with a token (weth, euro_token, dai).
    *
    **/
    function setPriceFeedContract(address _token, address _priceFeed)
    public
    onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    /**
    *   
    *   1
    *
    *   We will probably wanna stake some amount of some token.
    *   There is something to keep in mind:
    *   
    *   What tokens can they stake?
    *   How much can they stake?
    *
    **/
    function stakeTokens(uint256 _amount, address _token) public {
        // You can stake any amount greater than 0.
        require(_amount > 0, "Amount must be more than 0!");
        // We only want certain specific tokens can be staken on our platform.
        require(tokenIsAllowed(_token), "Token is currently not allowed!");
        /**
        *
        *   Moves amount tokens from sender to recipient using
        *   the allowance mechanism. amount is then deducted from the caller’s allowance.
        *   Returns a boolean value indicating whether the operation succeeded.
        *
        *       transfer() can be called only from the wallet who owns the tokens.
        *       If we do not own the token we have to do transferFrom(). They have to call approved first.
        *       TokenFarm contract is not the one who owns the ERC20.
        *
        *       We also have to have the ABI to actually call this transferFrom() function.
        *       So we are gonna need IERC20 interface that we are grubbing from OpenZeppelin.
        *
        *   For documentation:
        *   https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20-transferFrom-address-address-uint256-
        *
        **/
        // From who ever calls the stakeTokens() function to this TokenFarm contract address
        // send amount.
        // Recieve tokens from callers to this contract in order to allow them to stake the tokens.
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // Update unique tokens staked of user.
        updateUniqueTokensStaked(msg.sender, _token);
        // Update staking balance of user.
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;
        // Push users to the list if it is the first time they stake tokens.
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    /**
    *   
    *   Subset of: stakeTokens() 
    *   
    *   Return true if token is allowed to be staked.
    *
    *   How we gonna know what type of token is allowed?
    *   We will probably need a list with all this tokens.
    *
    *   So we loop through allowedTokens array to see if the token in there (true).
    *
    **/
    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex=0; 
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            // If token is found in the list, return true.
            if (allowedTokens[allowedTokensIndex] == _token) {
                tokenIsAllowedFlag = true;
                return tokenIsAllowedFlag;
            }
        }
        // If token is not found in the list, return false.
        tokenIsAllowedFlag = false;
        return tokenIsAllowedFlag;
    }

    /**
    * 
    *   Subset of: stakeTokens()
    *
    *   Now, when somebody stakes their tokens we gonna have to update this list.
    *   We wanna make sure that only added if they not already in the list.
    *   In order us to do this we should get an idea of how many unique tokens could user actually has.
    *   So I am gonna create a function called updateUniqueTokensStaked().
    *   What this function is gonna do it's gonna get a good idea of how many unique tokens a user has.
    *   And if a user has 1 unique token we can add them to the list. If they have more than 1,
    *   no they have already been added to the list.
    *
    *   Only this contract can call this function.
    *
    **/
    function updateUniqueTokensStaked(address _user, address _token) internal {
        // If staking balance of user is less than or equal to 0
        if (stakingBalance[_token][_user] <= 0) {
            // Increment 1 to unique token staked list.
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    /**
    *
    *   2
    *
    *   Send EuroToken as a reward based on staker's total value locked.
    *
    *   issueTokens is the reward in the for of EuroToken we giving to
    *   the users who use our platform.
    *   
    *   So we want issue some tokens based on the value of the underlying token
    *   they have given to us. So for example:
    *   
    *       If deposited 100 ETH we wanna do retio 1:1 for every 1 ETH, we give 1 EuroToken.
    *       But let's say they have 50 ETH and 50 DAI staked, and we want to give a reward
    *       of 1 EURO / 1 DAI
    *  
    *   Then we need to convert all our ETH into DAI so we know convert ratio for the
    *   EuroToken.
    *
    *
    **/
    function issueTokens() public onlyOwner {
        // So how do we actually go ahead and issue some tokens here?
        // Loop through the list of stakers that we have.
        for (
            uint256 stakersIndex = 0;       // Starting from the first staker...
            stakersIndex < stakers.length;  // For each staker in the list
            stakersIndex++                  // Go to the next staker
        ) {
            // Defining an each recipient from the stakers list.
            address recipient = stakers[stakersIndex];
            // Defining the total value of how much user has staked.
            uint256 userTotalValue = getUserTotalValue(recipient);
            // We can call transfer() here because our TokenFarm contract is gonna
            // be the contract that actually holds all this EuroToken.
            // Rewarding the user with our EuroToken.
            euroToken.transfer(recipient, userTotalValue);
        }
    }

    /**
    * 
    *  Subset of: issueTokens()
    *
    *  Get the user value across of all different staked tokens.
    *
    **/
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        // Require uniqueTokenStaked of user is greater than 0.
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        // Loop through allowed tokens to define the value of each.
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[allowedTokensIndex]);
        }
        return totalValue;
    }

    /**
    *
    *   Subset of: getUserTotalValue()
    *
    *   We wanna get the value of how much this person staked of this single token.
    *
    *   For example:
    *       if they staked 1 ETH and the price of the ETH is $2000,
    *       we wanna make sure this returns 2000.
    *       Or if they have 200 DAI staked and the price of the 200 DAI is $200,
    *       we wanne make sure this returns 200.
    *       So we getting that conversion rate, exactly how much value this
    *       person has staked in our application.
    *
    **/ 
    function getUserSingleTokenValue(address _user, address _token)
    public
    view
    returns (uint256) {
        // if the user has nothing staked.
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // we need the price of the token * staking balance[_token][_user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return (stakingBalance[_token][_user] * price / (10**decimals));
    }

    /**
    *
    *   Subset of: getUserSingleTokenValue()
    *
    *   Returning the latest price of a token in USD with 18 decimals.
    *
    **/
    function getTokenValue(address _token) public view returns (uint256, uint256) {
        // We have to acctually gonna map each token to the associated priceFeedAddress here.
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        // Doc: https://docs.chain.link/docs/get-the-latest-price/#solidity
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // How much decimals priceFeedContract has.
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    /**
    *
    *  3
    *
    *
    **/
    function unstakeTokens(address _token) public {
        // Fetching the staking balance. How much of this token does this user have?
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0!");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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