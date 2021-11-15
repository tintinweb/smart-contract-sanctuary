//what it needs to do: 
//0. work
//1. staking
//2. rewarding  (issue?)
//3. unstake
//4. allow addresses?

pragma solidity ^0.6.6;

//import the interface IERC20 allows us to easily interact with ERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable{
    string public name = "Go_d Token Farm";
    IERC20 public go_dToken;
    address[] public stakers;
    //allow tokens, push in there
    // mapping(address => bool) public allowedTokens;
    address[] allowedTokens;
    //^ upgrade this to mapping but just go with it for now
    //stakingBalance is the "ledger" of approved tokens mapped to a mapping
    //token address => mapping of user addresses -> amounts
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    
    constructor(address _go_dTokenAddress) public {
        //allows us to say "hey this is an erc20"
        go_dToken = IERC20(_go_dTokenAddress);
    }

    //how to let the users stake (without rewards)
    function stakeTokens(uint256 _amount, address token) public {
        //stake a certain amout of a token
        require(_amount > 0, "amount cannot be zero");
        //think about do we want them to stake any and all tokens?
        //how to assess value?  need price feed
        //create new function tokenIsAllowed
        if (isTokenAllowed(token)) {
            //unlock this
            updateUniqueTokensStake(msg.sender, token);
            //here the contract is actually doing the transferring, approve that this contract can do
            //send from user to THIS CONTRACT, because the user owns the tokens and the contract moves
            IERC20(token).transferFrom(msg.sender, address(this), _amount);
            //keep track (add the new amount)
            stakingBalance[token][msg.sender] = stakingBalance[token][msg.sender] + _amount;
            //only update if a unique token has been staked
            //if first token
            if (uniqueTokensStaked[msg.sender] == 1){
                stakers.push(msg.sender);
            } 
        }
    }
    //this is a dangerous function!!! why?
    function updateUniqueTokensStake(address user, address token) internal {
        if(stakingBalance[token][user] <= 0){
            uniqueTokensStaked[user] = uniqueTokensStaked[user] + 1;
        }
    }

    function isTokenAllowed(address token) public returns(bool){
        //we need a mapping or array, loop around it
        for(
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++) {
                if (allowedTokens[allowedTokensIndex] == token){
                    return true;
                }
            }
            return false;
    }
    //need a token manager, such as governance DAO or onlyOwner
    function addAllowedTokens(address token) public onlyOwner {
        allowedTokens.push(token);
        // allowedTokens[token] = true;
    }

    function unstakeTokens(address token) public {
        uint256 balance = stakingBalance[token][msg.sender];
        require(balance > 0, "Staking balance cannot be zero!");
        //notice transfer vs transferFrom
        //we use transfer when the contract owns the tokens AND is moving the tokens
        IERC20(token).transfer(msg.sender, balance);
        stakingBalance[token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    //liquidity farming stuff!
    function issueTokens() public onlyOwner {
        //we want an idea of who the stakers are
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++){
                address recipient = stakers[stakersIndex];
                go_dToken.transfer(recipient, getUserTotalValue(recipient));
            }
    }

    function getUserTotalValue(address user) public view returns(uint256){
        uint256 totalValue = 0;
        if (uniqueTokensStaked[user] > 0){
        //loop through all the tokens they have staked and get the ethereum value
            //a mapping would be suck
            for(
                uint256 allowedTokensIndex=0;
                allowedTokensIndex < allowedTokens.length;
                allowedTokensIndex++
            ){
                //get the value of the user and the tokens 
                totalValue = 
                    totalValue + 
                    getUserStakingBalanceEthValue(
                        user,
                        allowedTokens[allowedTokensIndex]
                );
            }
        }
    }

    function getUserStakingBalanceEthValue(address user, address token) public view returns (uint256){
        if(uniqueTokensStaked[user] <= 0){
            return 0;
        } //you don't any tokens, bub, beat it! https://youtu.be/Zuyfy9wz5Ww?list=PLVP9aGDn-X0Shwzuvw12srE-O6WKsGvY_&t=3529 
        return (stakingBalance[token][user] * getTokenEthPrice(token)) / (10**18); //divide by precision
    }

    function setPriceFeedContract(address token, address priceFeed) public onlyOwner {
        tokenPriceFeedMapping[token] = priceFeed;
    }

    function getTokenEthPrice(address token) public view returns(uint256){
        address priceFeedAddress = tokenPriceFeedMapping[token];
        //https://docs.chain.link/docs/get-the-latest-price/
        AggregatorV3Interface priceFeed = AggregatorV3Interface (priceFeedAddress);
         (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

