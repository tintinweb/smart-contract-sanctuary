/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

pragma solidity ^0.8.0;

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
    mapping (address => bool) authorized;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
        authorized[_msgSender()] = true; 
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
        require(owner() == _msgSender() || authorized[_msgSender()] == true , "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ShkoobyStake is Ownable {
    
    //address public tokenAddress = 0x475D3D963768Df338885671285FF1aA1c1242Ab5; // Token address
    //IBEP20 token = IBEP20(tokenAddress);
    
    struct stakePool{
        uint256 id;
        address tokenAddress;
        uint256 duration;
        uint256 rewards;
        uint256 withdrawalFee;
        uint256 unlockPenalty;
        uint256 stakedTokens;
        uint256 claimedRewards;
        //uint256 lockedBalance;
        uint256 status; //1: created, 2: active, 3: cancelled

        address creator;
        uint256 createdTime;
    }

    struct tokenPool{
        uint256[] poolIds;
    }

    struct userStake{
        uint256 id;
        uint256 stakePoolId;
	    uint stakeBalance;
    	uint totalRewards;
    	uint lastClaimedTime;
    	uint createdTime;
    }

    struct userStakeList{
        uint256[] activeStakes;
    }
    //userStakes[] = 
    mapping (uint256 => stakePool) stakePools;
    mapping (uint256 => userStake) userStakes;
    mapping (address => userStakeList) userStakeLists;
    mapping (address => tokenPool) tokenPools;
   
    function addTokenStakePool(address _tokenAddress,uint256 _duration, uint256 _rewards, uint256 _withdrawalFee, uint256 _unlockPenalty ) public returns (bool){
        //IERC20 token = IERC20(_tokenAddress);
        //require(token.getOwner() == msg.sender,'Only token Owner can create the stake');
        
        stakePool memory stakePoolDetails;
        uint256 stakePoolID = block.timestamp;
        stakePoolDetails.id = stakePoolID;
        stakePoolDetails.tokenAddress = _tokenAddress;
        stakePoolDetails.duration = _duration;
        stakePoolDetails.rewards = _rewards;
        stakePoolDetails.withdrawalFee = _withdrawalFee;
        stakePoolDetails.unlockPenalty = _unlockPenalty;
        stakePoolDetails.creator = msg.sender;
        stakePoolDetails.createdTime = block.timestamp;
        
        stakePools[stakePoolID] = stakePoolDetails;

        tokenPool storage tokenPoolDetails = tokenPools[_tokenAddress];
        tokenPoolDetails.poolIds.push(stakePoolID);

        tokenPools[_tokenAddress] = tokenPoolDetails;
        return true;
    }

    function getTokenPoolIds(address _tokenAddress) public view returns(uint256[] memory){
        tokenPool memory tokenPoolDetails = tokenPools[_tokenAddress];
        return tokenPoolDetails.poolIds;
    }

    function getStakePoolDetails(uint256 _stakePoolId) public view returns(address, address, uint256[] memory){
        stakePool memory stakePoolDetails = stakePools[_stakePoolId];
        uint [] memory stakePoolDetailsArray = new uint[](10);
        IERC20 token = IERC20(stakePoolDetails.tokenAddress);

        stakePoolDetailsArray[0] = stakePoolDetails.id;
        
        stakePoolDetailsArray[1] = stakePoolDetails.duration;
    	stakePoolDetailsArray[2] = stakePoolDetails.rewards;
    	stakePoolDetailsArray[3] = stakePoolDetails.withdrawalFee;
    	stakePoolDetailsArray[4] = stakePoolDetails.unlockPenalty;
        stakePoolDetailsArray[5] = stakePoolDetails.stakedTokens;
        stakePoolDetailsArray[6] = stakePoolDetails.claimedRewards;
        stakePoolDetailsArray[7] = token.balanceOf(address(this));
        stakePoolDetailsArray[8] = stakePoolDetails.status;
        stakePoolDetailsArray[9] = stakePoolDetails.createdTime;
        
        return (stakePoolDetails.tokenAddress, stakePoolDetails.creator,stakePoolDetailsArray);
    }

    function stake(uint256 _stakePoolId, uint256 _amount) public returns (bool){
        stakePool memory stakePoolDetails = stakePools[_stakePoolId];
    
        IERC20 token = IERC20(stakePoolDetails.tokenAddress);
        //require(token.allowance(msg.sender, address(this)) >= _amount,'Tokens not approved for transfer');
    
        token.transfer(address(this),_amount);
        bool success = token.transfer(address(this),_amount);
        require(success, "Token Transfer failed.");

        userStake memory userStakeDetails;

        uint256 userStakeid = block.timestamp;
        userStakeDetails.id = userStakeid;
        userStakeDetails.stakePoolId = _stakePoolId;
        userStakeDetails.stakePoolId = _amount;
        userStakeDetails.createdTime = block.timestamp;
    
        return true;
    }

    /*
    function getUserStakes() public view returns(uint256[] memory){
        //userStake memory userStakeDetails = userStakes[msg.sender];
        return userStakeDetails.activeStakes;
    }
    */
/*
    struct userStake{
        uint256 id;
        address tokenAddress;
        uint stakePoolId;
	    uint stakeBalance;
    	uint totalRewards;
    	uint lastClaimedTime;
    	uint createdTime;
    }
*/
    receive() external payable {
    }
}