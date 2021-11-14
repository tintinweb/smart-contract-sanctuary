//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable{
    //mapping for token addr -> staker addr -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    //mapping to track how many unique tokens each addr has
    mapping(address => uint256) public uniqueTokensStaked;
    //mapping for token address to price feed address
    mapping(address => address) public tokenPriceFeedMapping;
    //list of all our stakers since we cant loop through a mapping
    address[] public stakers;
    //address array list of allowed token addresses (mapping is better but we will use a list for simplicity)
    address[] public allowedTokens;
    //make our token addr a global variable
    IERC20 public dappToken;

//stakeTokens
//unStakeTokens
//issueTokens - issue tokens based off value of under lying tokens deposited
//addAllowedTokens - to add more tokens to be staked on our contract
//getEthValue - get underlying value of tokens in Eth

    //constructor for when contract is launched to we know addr of our token
    constructor (address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    //function to map token addr to priceFeed addr
    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        //issue tokens to all stakers by looping thru list
        for (uint256 stakersIndex = 0; stakersIndex < stakers.length; stakersIndex++) {
            address recipient = stakers[stakersIndex];
            //send our token based on total value locked
            uint256 userTotalValue = getUserTotalValue(recipient);
            //now we have total value of usd user has locked we can transfer
            //the amount of tokens they have in total value
            dappToken.transfer(recipient,userTotalValue);

        }
    }

    //get total value of all users tokens
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked");
        for (uint256 allowedTokensIndex = 0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++) {
            //this will get the total val of 1 token so we call this function 
            //to get the value of the other tokens so we can get the sum
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[allowedTokensIndex]);
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token) public view returns (uint256) {
        //get conversion rate for token -> usd
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        //get token price and multiply by staking balance of the token of the user
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        //return staking balance of the token of that user
        //eth has 18 decimals so we the divide by the decimals of price feed contract
        return (stakingBalance[_token][_user] * price / (10**decimals));
    }

    function getTokenValue(address _token) public view returns (uint256, uint256) {
        //we use chainlink price feeds to get real time price
        //so we must map each token with there associated price feed address
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        //get priceFeed contract
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int256 price,,,) = priceFeed.latestRoundData();
        //we need to know how many decimal the priceFeed contract has so we can match up our numbers
        uint256 decimals = priceFeed.decimals();
        //we wrap both in uint256
        return (uint256(price), decimals);
    }

    //when staking we want the amount being staked and what token
    function stakeTokens(uint256 _amount, address _token) public {
        //they can stake any amount above zero
        require(_amount > 0, "Amount must be more than 0");
        //we only want certain tokens to be able to be staked
        require(tokenIsAllowed(_token), "Token is not currently allowed");
        //call transfer from function on the ERC-20
        //we use transferFrom because transfer() requires us to own the tokens to use
        // get ABI by wrapping this addr as an erc-20 token
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        //check how many unique tokens a user has to determine if they need
        //to be added to the list or they already are added
        updateUniqueTokensStaked(msg.sender, _token);
        //here we say staking balance of this token from this sender is now equal
        //to whatever balance they had before plus amount
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;
        // check if user is already on list before pushing to list
        //If they have 1 tokens that means its there first so we add them to the list
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    //to unstaker users tokens
    function unstakeTokens(address _token) public {
        //first we must get there staking balance
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        //now we do a transfer of the token
        IERC20(_token).transfer(msg.sender, balance);
        //update user balance to zero after unstaking all tokens
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] -1;
        //we should update our staker to remove the addr be we will skip that for now

    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        //if we want to add a new token we just push it onto the array
        allowedTokens.push(_token);
    }

    //function to only allow certain tokens, return true or false if allowed
    function tokenIsAllowed(address _token) public returns (bool) {
        //loop through array list and check if the allowed token is there
        for(uint256 allowedTokensIndex=0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
            return false;
        }
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