/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



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
    mapping(address => mapping(address => uint256)) public stakingBalance;    //mapping token address -> staked address -> amount staked
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address [] allowedTokens;
    address [] emptyArray;
    address [] public stakers;
    address [] public newStakers;
    IERC20 public simbaToken;

    // stakeTokens - 
    // addAllowedTokens -
    // unStakeTokens 
    // IssueRewardTokens  -
    // getEthValue - 
    
    constructor(address _simbaTokenAddress) {
        simbaToken = IERC20(_simbaTokenAddress); //set default reward token
    }

    //MAIN FUNCTIONS
    function stakeTokens(uint256 _amount, address _token) public {
        //what tokens can they stake?
        //how much can they stake?
        require(_amount> 0,"Amount must be more than zero");
        require(tokenIsAllowed(_token),"Token is not allowed");
        //use transferFrom Function because we do not own the tokens. We also need the token abi from IERC20 interface
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        //add to stakers
        addUniqueTokensStaked(msg.sender, _token);
        //add to stakingBalance
        stakingBalance[_token][msg.sender] += _amount;

        // This a staker's first token, add to staker's list
        if(uniqueTokensStaked[msg.sender] == 1){
            stakers.push(msg.sender);
        }
    }

    function addAllowedToken(address _token) public onlyOwner{
        //add token to allowedTokens
        require(_token != address(0),"Token must be a valid address");
        require(!tokenIsAllowed(_token),"Token already added");
        allowedTokens.push(_token);
    }

    function issueTokens() public onlyOwner {
        // reward all stakers based on amount staked
        for(uint256 stakersIndex=0; stakersIndex<stakers.length; stakersIndex++ ){
            address recipient = stakers[stakersIndex];
            uint userTotalValue = getUserTotalValue(recipient);
            //send them their token reward
            //get their eqivalent value in simbaToken
            simbaToken.transfer(recipient, userTotalValue);
        }
    }

    function unstakeTokens(address _token) public  {
        //check if token is allowed
        require(tokenIsAllowed(_token),"Token is not allowed");
        //get amount staked
        uint256 amountStaked = stakingBalance[_token][msg.sender];
        //check if token is staked
        require(amountStaked > 0,"Token is not staked");
        //unstake tokens
        IERC20(_token).transfer(msg.sender, amountStaked);
        //remove from stakingBalance
        stakingBalance[_token][msg.sender] = 0;
        //remove from uniqueTokensStaked
        uniqueTokensStaked[msg.sender] -= 1;
        //remove from stakers
        removeStaker(msg.sender);
    }

    function fetchAllowedTokens() public view returns (address[] memory){
        return (allowedTokens);
    }
    

    // HELPER FUNCTION

    function addUniqueTokensStaked(address _user, address _token) internal{
        if(stakingBalance[_token][_user] <= 0){
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function removeStaker(address _user) internal {
        //remove from stakers if they have no tokens staked
        for(uint256 tokenIndex=0; tokenIndex<allowedTokens.length; tokenIndex++){
            if(stakingBalance[allowedTokens[tokenIndex]][_user] > 0){
                return;
            }
        }

        //if function has not returned, this means staker has no staked tokens, loop through stakers and remove _user
        for(uint256 stakerIndex=0; stakerIndex<stakers.length; stakerIndex++){
            if(stakers[stakerIndex] != _user){
                newStakers.push(stakers[stakerIndex]);
            }
        }
        stakers = newStakers;
        // empty newStakers
        newStakers = emptyArray;
    }

    function tokenIsAllowed(address _token) public returns(bool){
        for (uint256 tokenIndex=0; tokenIndex<allowedTokens.length; tokenIndex++){
            if(allowedTokens[tokenIndex] == _token){
                return true;
            }
        }
        return false;
    }

    function getUserTotalValue(address _user) public view returns(uint256){
        uint256 totalValue = 0;
        require(_user != address(0),"User must be a valid address");
        require(uniqueTokensStaked[_user] > 0,"User has no tokens staked");
        for(uint256 tokenIndex=0; tokenIndex<allowedTokens.length; tokenIndex++){
            totalValue += getUserSingleTokenUsdValue(_user, allowedTokens[tokenIndex]);
        }
        return totalValue;
    }

    function getUserSingleTokenUsdValue(address _user, address _token)
    public
    view returns (uint256){
        // Get amount in dollars user has staked
        if(uniqueTokensStaked[_user] <= 0){
            return 0;
        }
        //get token price in dollars X stakingBalance[_token][user]
        //decimals in the number of extra zeros this comes with. In this case. So we have to remove it to get the actual value
    ( uint tokenPrice, uint decimals) = getTokenPrice(_token);
    return (tokenPrice * stakingBalance[_token][_user]/10**decimals);
    }

    function getTokenPrice(address _token) public view returns(uint256,uint256) {
        //price feed address
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
         (,int price,,,) =  priceFeed.latestRoundData();
         uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price),decimals); 
    }

    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner{
        require(_token != address(0),"Token must be a valid address");
        require(_priceFeed != address(0),"Price feed must be a valid address");
        tokenPriceFeedMapping[_token] = _priceFeed;
    }   
}