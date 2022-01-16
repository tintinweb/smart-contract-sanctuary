// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Ownable.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable{
    // stake tokens
    // unstake tokens
    // issue tokens
    address[] public allowedTokens;
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    address[] public stakers;
    IERC20 public dappToken;
    mapping(address => address) public tokenToPriceFeedMapping;
    uint256 public tokenToPriceFeedMappingLength;

    constructor(address _token) {
        dappToken = IERC20(_token);
    }

    function setTokenPriceFeedContract(address token, address priceFeedAddress) public onlyOwner{
        tokenToPriceFeedMapping[token] = priceFeedAddress;
        tokenToPriceFeedMappingLength++;
    }

    function stakeTokens(address _token_address, uint256 amount) public{
        /*
        Make sure that the user has enough ether in his account
        Make sure that the user is not staking 0 token
        Make sure that this token is part of that token that can be staked
        transfer the token to user

        reward the user for staking some tokens.
        Keep track of all the tokens staked by user
        keep track of all the users that staked some tokens

        token_address: {user_address, amount}
         */
        IERC20 token = IERC20(_token_address);
        require(token.balanceOf(msg.sender) >= amount);
        require(amount > 0);
        require(tokenIsAllowed(_token_address), "Token cannot be staked");

        token.transferFrom(msg.sender, address(this), amount);

        updateUniqueTokensStaked(msg.sender, _token_address);

        if (uniqueTokensStaked[msg.sender] == 1){
            stakers.push(msg.sender);
        }

        stakingBalance[_token_address][msg.sender] += amount;
    }

    function updateUniqueTokensStaked(address _user, address _token) public {
        if (stakingBalance[_token][_user] <= 0){
            uniqueTokensStaked[_user] += 1;
        }
    }

    function issueToken() public onlyOwner{
        /*
        Issue tokens to stakers.
         */
         for (uint256 index = 0; index < stakers.length; index++){
             address staker = stakers[index];
             uint256 totalValue = getTotalValue(staker);
             dappToken.transfer(staker, totalValue);

         }
    }

    function unstakeTokens(address token) public {
        uint256 tokenBalance = stakingBalance[token][msg.sender];
        require(tokenBalance > 0, "Token balance should be greater than 0");
        IERC20(token).transfer(msg.sender, tokenBalance);

        stakingBalance[token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] -= 1;

    }
    function getTotalValue(address staker) public returns (uint256){
        uint256 totalValue = 0;
        require(uniqueTokensStaked[staker] >= 0, "No token staked by user");

        for (uint256 index = 0; index < allowedTokens.length; index++){
            address eachToken = allowedTokens[index];
            totalValue += getEachTokenValue(eachToken, staker);
        }

        return totalValue;
    }

    function getEachTokenValue(address token, address user) public view returns(uint256) {
        if (uniqueTokensStaked[user] <= 0){
            return 0;
        }
        (uint256 price, uint256 decimals) = getTokenValue(token);
        
        uint256 amountOfTokenStaked = stakingBalance[token][user];

        uint256 eachTokenValue = (price  * amountOfTokenStaked) / 10**decimals;

        return eachTokenValue;


        
    }

    function getTokenValue(address token) public view returns (uint256, uint256){
        address priceFeedAddress = tokenToPriceFeedMapping[token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (, int256 price, , ,) = priceFeed.latestRoundData();

        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function addAllowedTokens(address _token_address) public onlyOwner{
        allowedTokens.push(_token_address);
    }

    function tokenIsAllowed(address _token_address) public returns (bool){
        for(uint256 i = 0; i < allowedTokens.length; i++){
                address eachAllowedToken = allowedTokens[i];
                if (eachAllowedToken == _token_address){
                    return true;
                }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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