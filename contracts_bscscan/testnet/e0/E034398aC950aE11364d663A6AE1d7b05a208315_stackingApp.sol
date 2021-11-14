/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

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



contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.0;

contract stackingApp is Ownable{
    IERC20 token;
    
    uint256[] public packegeIds;
    
      struct stack {
         uint amount;
        uint releaseDate;
        bool isSet;
        bool claimed;
        uint percentageReturn;
        uint256 packegeId;
    }
    struct stacker {
        bool active;
        
        address payable stacker;
        uint totalvaluelocked;
        uint256[] stackIds;
        
    }
    mapping(address => mapping (uint256 => stack) ) public stacks;
    mapping(address => stacker) public stackers;
    
    struct package {
        string name;
        uint256 minAmount;
        uint256 time;
        uint256 rewardPercentage;
    }
    mapping(uint256 => bool) public isValidPackage;
    mapping(uint256 => package) public packages;
   
    uint256 penaltyFee;
    uint256 rewardBalance;
    uint256 availableReward;
    event packageCreated(uint256 packageId, string name ,uint256 minAmount, uint256 time, uint256 rewardPercentage );
     event packageUpdated(uint256 packageId, string name,uint256 minAmount, uint256 time, uint256 rewardPercentage );
    event stackAdded(uint256 amount , uint256 packageId, address indexed stacker);
    constructor(address _token){
        token = IERC20(_token);
    }
    function depositToken(uint256 amount) public onlyOwner{
        token.transferFrom(msg.sender , address(this) , amount);
        rewardBalance += amount;
        availableReward += amount;
    }
    function addPackage(uint256 time , string calldata name , uint256 minAmount, uint256 rewardPercentage) public onlyOwner returns(uint256){
        uint256 packageId =  packegeIds.length+1;
        isValidPackage[packageId] = true;
        packages[packageId] = package(name , minAmount , time * 1 minutes, rewardPercentage);
        packegeIds.push(packageId);
        emit packageCreated(packageId , name , minAmount ,packages[packageId].time ,rewardPercentage);  
        return packageId;
    }
    function updatePackage(uint256 packageId, uint256 time , string calldata name , uint256 minAmount, uint256 rewardPercentage) public onlyOwner {
       require(isValidPackage[packageId]  , "not a valid package ID");
        packages[packageId] = package(name , minAmount , time * 1 minutes, rewardPercentage);
        emit packageUpdated(packageId , name , minAmount ,packages[packageId].time ,rewardPercentage);  
    }
     function stacktoken(uint256 amount , uint256 packageId) public returns(uint256){
        require(isValidPackage[packageId]  , "not a valid package ID");
        require(amount > 0 && amount >=packages[packageId].minAmount , "amount below minimum stack value");
        require(rewardProcessesable(packageId , amount) , "available reward balance insufient");
        token.transferFrom(msg.sender , address(this) , amount);
        uint256 stackID = stackers[msg.sender].stackIds.length+1;
        stacks[msg.sender][stackID] =   stack(amount , block.timestamp + packages[packageId].time , true , false,packages[packageId].rewardPercentage ,packageId ); 
        stackers[msg.sender].stackIds.push(stackID);
        stackers[msg.sender].totalvaluelocked += amount;
        stackers[msg.sender].active = true;
        uint256 expectedReward  = amount * packages[packageId].rewardPercentage / 100;
        availableReward -= expectedReward;
        emit stackAdded(amount , packageId  , msg.sender);  
        return stackID;
    }
    function expectedStackReward(address account,uint256 stackId) public view returns(uint256){
        require(stacks[account][stackId].isSet && !stacks[account][stackId].claimed , "not active stack");
        return (stacks[account][stackId].amount * stacks[account][stackId].percentageReturn / 100);
        
    }
    function stackAmount(address account ,uint256 stackId) public view returns(uint256){
        return stacks[account][stackId].amount;
    }
    function totalvaluelocked(address account) public view returns(uint256){
      return stackers[account].totalvaluelocked ;
    } 
    function stackIDs(address account) public view returns(uint256[] memory){
        return stackers[account].stackIds;
    }
    function stackStatus(address account, uint256 stackId) public view returns(bool , bool , bool){
        
        return(stacks[account][stackId].isSet,stacks[account][stackId].claimed , block.timestamp > stacks[account][stackId].releaseDate);
    }
   
    function rewardProcessesable(uint256 packageId , uint256 amount) private view returns(bool){
        uint256 expectedReward = amount * packages[packageId].rewardPercentage / 100;
        if(availableReward >= expectedReward) return true;
        return false;
    }
    function unstack(uint256 stackId) public{
         require(stacks[msg.sender][stackId].isSet && !stacks[msg.sender][stackId].claimed , "not active stack");
         require(block.timestamp > stacks[msg.sender][stackId].releaseDate , "not yet time");
         uint256 reward = stacks[msg.sender][stackId].amount * stacks[msg.sender][stackId].percentageReturn / 100;
         rewardBalance -= reward;
         stacks[msg.sender][stackId].claimed = true;
         token.transfer(msg.sender ,stacks[msg.sender][stackId].amount + reward );
         stackers[msg.sender].totalvaluelocked -= stacks[msg.sender][stackId].amount;
    }
     function earlyClaim(uint256 stackId) public{
         require(stacks[msg.sender][stackId].isSet && !stacks[msg.sender][stackId].claimed , "not active stack");
         uint256 penalty = stacks[msg.sender][stackId].amount * penaltyFee / 100;
         rewardBalance += penalty;
         uint256 expectedReward  = stacks[msg.sender][stackId].amount * stacks[msg.sender][stackId].percentageReturn / 100;
         availableReward += expectedReward;
         stacks[msg.sender][stackId].claimed = true;
         token.transfer(msg.sender ,stacks[msg.sender][stackId].amount - penalty );
         stackers[msg.sender].totalvaluelocked -= stacks[msg.sender][stackId].amount;
    } 
    function setPenalty(uint256 _penalty) public onlyOwner {
        require(_penalty < 100 , "invalid percentage");
        penaltyFee = _penalty;
    }
    function getPackageIds() public view returns(uint256[] memory){
        return packegeIds;
    }
    function withdrawReward(uint256 amount) public onlyOwner {
        require(amount <= token.balanceOf(address(this)) , "insufient funds");
        token.transfer(owner() ,amount);
    }
}