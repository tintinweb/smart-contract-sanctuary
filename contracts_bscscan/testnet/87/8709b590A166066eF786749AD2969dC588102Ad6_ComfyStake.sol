/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;

// ReentrancyGuard (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// Context (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol) 
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

// Ownable (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol)

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

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ComfyStake is ReentrancyGuard, Ownable {
    

    struct StakeInfo {
        uint256 comfyStaked;
        uint256 unlockTime;
        mapping(address => uint256) pendingRewards; // token address => amount
        mapping(address => uint256) lastRewardsBlockUpdate; // token address => block number
    }
    
    struct Pool {
        uint64 nDays;
        uint64 rate;
        uint256 totalComfyStaked;
        uint64 penaltyFee;
    }
    
    
    struct Token {
        uint64 index;
        bool isActive;
        uint256 rewardsPerBlock;
        uint256 sinceBlockNumber;
    }
    
    
    mapping (uint64 => Pool) pools;
    Pool[] poolsList;
    mapping(address => mapping(uint64 => StakeInfo)) stakeholders; // wallet address => poolId => StakeInfo
    address[] stakeholdersList;
    mapping(address => bool) isStakeholder; 
    
    address[] tokens;
    mapping (address => Token) tokensTracker; // token address => Token
    uint256 stakeFee = 0;
    uint256 unstakeFee = 0;
    bool isEmergencyOn = false;
    
    address public comfyTokenAddress;
    IBEP20 comfyToken;
    
    event StakeComfy(address stakeholder, uint64 poolId, uint256 amount);
    event UnstakeComfy(address stakeholder, uint64 poolId, uint256 amount);
    event WithdrawRewards(address stakeholder, uint64 poolId, address tokenAddress, uint256 amount);
    event ClaimSpecificRewards(address stakeholder, uint64 poolId, address tokenAddress, uint256 amount);
    event ModifyPoolSettings(uint64 poolId, uint64 nDays, uint64 rate, uint64 penaltyFee);
    event EmergencyUnstakeComfy(address stakeholder, uint64 poolId, uint256 amount);
    event EmergencyWithdrawal(address to, uint256 amount);
    
    constructor() {
        initPools();
    }
    
    function initPools() internal {
        pools[0] = Pool(0, 7, 0, 0);
        pools[1] = Pool(7, 13, 0, 15);
        pools[2] = Pool(30, 28, 0, 25);
        pools[3] = Pool(90, 52, 0, 45);
        
        poolsList.push(pools[0]);
        poolsList.push(pools[1]);
        poolsList.push(pools[2]);
        poolsList.push(pools[3]);
    }
    
    
    function stakeComfy(uint256 amount, uint64 poolId) external nonReentrant {
        require(amount > 0, "Can not stake 0 COMFY");
        require(comfyToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(comfyToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        
        uint256 fee = calculateStakeFee(amount);
        uint256 netAmount = amount - fee;
        Pool memory pool = pools[poolId];
        uint256 unlockTime = block.timestamp + (pool.nDays * 1 days);
        
        
        if(isStakeholder[msg.sender]) {
            updateUsersPendingRewards(poolId);
            withdrawRewards(poolId);
            
            stakeholders[msg.sender][poolId].comfyStaked = stakeholders[msg.sender][poolId].comfyStaked + netAmount;
            stakeholders[msg.sender][poolId].unlockTime = unlockTime;
            
            
        } else {
            addStakeholder(netAmount, unlockTime, poolId);
            updateUsersPendingRewards(poolId);
        }
        
        pools[poolId].totalComfyStaked = pools[poolId].totalComfyStaked + netAmount;
        
        emit StakeComfy(msg.sender, poolId, netAmount);
    }
    
    
    function addStakeholder(uint256 amount, uint256 unlockTime, uint64 poolId) internal {
        
        stakeholders[msg.sender][poolId].comfyStaked = amount;
        stakeholders[msg.sender][poolId].unlockTime = unlockTime;
        stakeholdersList.push(msg.sender);
        isStakeholder[msg.sender] = true;
    }
    
    function removeStakeholder() internal {
        isStakeholder[msg.sender] = false;
        uint256 stakeholderIndex = 0;
        for(uint256 i = 0; i <= stakeholdersList.length - 1; i++) {
            if(stakeholdersList[i] == msg.sender) {
                stakeholderIndex = i;
            }
        }
        
        stakeholdersList[stakeholderIndex] = stakeholdersList[stakeholdersList.length - 1];
        stakeholdersList.pop();
    }
    
    function unstakeComfy(uint256 amount, uint64 poolId) external nonReentrant {
        
        require(stakeholders[msg.sender][poolId].comfyStaked > 0, "You haven't staked any COMFY");
        require(amount <= stakeholders[msg.sender][poolId].comfyStaked);
        assert(stakeholders[msg.sender][poolId].comfyStaked <= pools[poolId].totalComfyStaked);
        
        updateUsersPendingRewards(poolId);
        withdrawRewards(poolId);
        uint256 fee = calculateUnstakeFee(amount);
        if(stakeholders[msg.sender][poolId].unlockTime > block.timestamp) {
            fee = pools[poolId].penaltyFee;
        }
        uint256 amountToUnstake = amount - (amount * fee / 100);
        
        stakeholders[msg.sender][poolId].comfyStaked = stakeholders[msg.sender][poolId].comfyStaked - amount;
        pools[poolId].totalComfyStaked = pools[poolId].totalComfyStaked - amount;
        require(comfyToken.transfer(msg.sender, amountToUnstake), "Transfer failed");
        
        bool shouldRemoveStakeholder = true;
        for (uint64 i = 0; i <= poolsList.length - 1; i++) {
            if(stakeholders[msg.sender][i].comfyStaked > 0) {
                shouldRemoveStakeholder = false;
            }
        }
        
        if(shouldRemoveStakeholder) {
            removeStakeholder();
        }
        
        emit UnstakeComfy(msg.sender, poolId, amount);
        
    }
    
    function emergencyUnstakeComfy(uint64 poolId) external nonReentrant {
        require(isEmergencyOn, "Contract is not in an emergency situation!");
        
        withdrawRewards(poolId);
       
        uint256 amountToUnstake = stakeholders[msg.sender][poolId].comfyStaked;
        if(amountToUnstake > comfyToken.balanceOf(address(this))) {
            amountToUnstake = comfyToken.balanceOf(address(this));
        }
        
        
        stakeholders[msg.sender][poolId].comfyStaked = 0;
        pools[poolId].totalComfyStaked = pools[poolId].totalComfyStaked - amountToUnstake;
        require(comfyToken.transfer(msg.sender, amountToUnstake), "Transfer failed");
        
        bool shouldRemoveStakeholder = true;
        for (uint64 i = 0; i <= poolsList.length - 1; i++) {
            if(stakeholders[msg.sender][i].comfyStaked > 0) {
                shouldRemoveStakeholder = false;
            }
        }
        
        if(shouldRemoveStakeholder) {
            isStakeholder[msg.sender] = false;
        }
        
        emit EmergencyUnstakeComfy(msg.sender, poolId, amountToUnstake);
    }
    
    function emergencyWithdrawal(address tokenAddress) external onlyOwner {
        require(isEmergencyOn, "Contract is not in an emergency situation!");
        
        IBEP20 token = IBEP20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        
        require(token.transfer(msg.sender, tokenBalance), "Transfer failed");
        
        emit EmergencyWithdrawal(msg.sender, tokenBalance);
    }
    
    function withdrawRewards(uint64 poolId) public {
        require(isStakeholder[msg.sender], "You are not a stakeholder");
        updateUsersPendingRewards(poolId);
         for(uint64 i = 0; i <= tokens.length - 1; i++) {
            address currentTokenAddress = tokens[i];
            if(tokensTracker[currentTokenAddress].isActive) {
                uint256 userRewards = 0;
                IBEP20 currentToken = IBEP20(currentTokenAddress);
                uint256 currentTokenBalance = currentToken.balanceOf(address(this));
                userRewards = stakeholders[msg.sender][poolId].pendingRewards[currentTokenAddress];
                if(currentTokenBalance > 0 && userRewards > 0) {
                    
                    if(userRewards > currentTokenBalance) {
                        userRewards = currentTokenBalance;
                    }
                        
                stakeholders[msg.sender][poolId].pendingRewards[currentTokenAddress] = 0;
                require(currentToken.transfer(msg.sender, userRewards), "Transfer failed");
                
                emit WithdrawRewards(msg.sender, poolId, currentTokenAddress, userRewards);
                    
                }
            } 
        }
    }
    
    function massUpdateUsersPendingRewards() public {
        for(uint64 i = 0; i <= poolsList.length - 1; i++) {
            updateUsersPendingRewards(i);
        }
    }
    
    function updateUsersPendingRewards(uint64 poolId) public {
        if(stakeholdersList.length > 0) {
            for(uint256 i = 0; i <= stakeholdersList.length - 1; i++) {
                if(tokens.length > 0) {
                    for(uint64 j = 0; j<= tokens.length - 1; j++) {
                        stakeholders[stakeholdersList[i]][poolId].pendingRewards[tokens[j]] += calculateUserRewards(stakeholdersList[i], tokens[j], poolId);
                    }
                }
            }
            
            for(uint64 i = 0; i <= tokens.length - 1; i++) {
                stakeholders[msg.sender][poolId].lastRewardsBlockUpdate[tokens[i]] = block.number;
            }
            
        }
    }
    
    function calculateUserRewards(address walletAddress, address tokenAddress, uint64 poolId) internal returns(uint256) {
        
        
        Pool memory pool = pools[poolId];
        uint256 tokenRewards = 0;
        if(pool.totalComfyStaked > 0) {
            uint256 lastRewardsBlock = stakeholders[walletAddress][poolId].lastRewardsBlockUpdate[tokenAddress];
            if(lastRewardsBlock == 0) {
                lastRewardsBlock = tokensTracker[tokenAddress].sinceBlockNumber;
            }
            require(lastRewardsBlock != 0, "Token not added yet!");
            uint256 multiplier = block.number - lastRewardsBlock;
            uint256 rewardsPerBlock = tokensTracker[tokenAddress].rewardsPerBlock;
            tokenRewards = (rewardsPerBlock * pool.rate) * ((stakeholders[walletAddress][poolId].comfyStaked * 10**18) / pool.totalComfyStaked) * multiplier / 10 ** 18;
            stakeholders[walletAddress][poolId].lastRewardsBlockUpdate[tokenAddress] = block.number;
        }
        return tokenRewards;
    }
    
    
    function claimSpecificRewards(uint64 poolId, address tokenAddress) public nonReentrant {
        
        require(tokensTracker[tokenAddress].isActive, "Token rewards not active");
        
        updateUsersPendingRewards(poolId);
        uint256 userRewards = 0;
        IBEP20 token = IBEP20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        userRewards = stakeholders[msg.sender][poolId].pendingRewards[tokenAddress];
        if(tokenBalance > 0 && userRewards > 0) {
            
            if(userRewards > tokenBalance) {
                userRewards = tokenBalance;
            }
                       
            stakeholders[msg.sender][poolId].pendingRewards[tokenAddress] = 0; 
            require(token.transfer(msg.sender, userRewards), "Transfer failed");
            
                    
            emit ClaimSpecificRewards(msg.sender, poolId, tokenAddress, userRewards);
                
        }
    }
    
    
    
    function calculateStakeFee(uint256 amount) internal view returns(uint256) {
        return amount * stakeFee / 100;
    }
    
    function calculateUnstakeFee(uint256 amount) internal view returns(uint256) {
        return amount * unstakeFee / 100;
    }
    
    
    // onlyOwner functions
    
    function approveComfy() public onlyOwner {
        comfyToken.approve(comfyTokenAddress, ~uint256(0));
    }
    
    
    function setRewardsPerBlock(address tokenAddress, uint256 rewards) external onlyOwner {
        tokensTracker[tokenAddress].rewardsPerBlock = rewards;
    }
    
    
    function modifyPoolSettings(uint64 poolId, uint64 nDays, uint64 rate, uint64 penaltyFee) external onlyOwner {
        require(rate <= 100, "Maximum rate is 100");
        pools[poolId].nDays = nDays;
        pools[poolId].rate = rate;
        pools[poolId].penaltyFee = penaltyFee;
        
        emit ModifyPoolSettings(poolId, nDays, rate, penaltyFee);
    }
    
    function addToken(address tokenAddress, uint256 rewardsPerBlock) external onlyOwner {
        if(tokens.length > 0) {
            address tokenFound = tokens[tokensTracker[tokenAddress].index];
            require(tokenAddress != tokenFound, "Token already added!");
        }
        tokens.push(tokenAddress);
        tokensTracker[tokenAddress].index = uint64(tokens.length - 1);
        tokensTracker[tokenAddress].isActive = true;
        tokensTracker[tokenAddress].rewardsPerBlock = rewardsPerBlock;
        tokensTracker[tokenAddress].sinceBlockNumber = block.number;
    }
    
    function setTokenRewardsStatus(address tokenAddress, bool active) external onlyOwner {
        tokensTracker[tokenAddress].isActive = active;
    }
    
    
    function setComfyTokenAddress(address tokenAddress) external onlyOwner {
        comfyTokenAddress = tokenAddress;
        comfyToken = IBEP20(tokenAddress);
    }
    
    function setStakeFee(uint256 fee) external onlyOwner {
        stakeFee = fee;
    }
    
    function setUnstakeFee(uint256 fee) external onlyOwner {
        unstakeFee = fee;
    }
    
    function setPenaltyFee(uint64 poolId, uint64 fee) external onlyOwner {
        require(fee <= 100, "Maximum penalty fee value is 100");
        pools[poolId].penaltyFee = fee;
    }
    
    
    function setIsEmergencyOn(bool isOn) external onlyOwner {
        isEmergencyOn = isOn;
    }
    
    // Utilities function
    
    function getTotalComfyInPool(uint64 poolId) public view returns (uint256) {
        return pools[poolId].totalComfyStaked;
    }
    
    function getComfyStakedByAddress(address walletAddress, uint64 poolId) public view returns(uint256) {
        return stakeholders[walletAddress][poolId].comfyStaked;
    }
    
    function getCurrentUserRewards(address walletAddress, address tokenAddress, uint64 poolId) public view returns(uint256) {
        return stakeholders[walletAddress][poolId].pendingRewards[tokenAddress];
    }
    
    function getPenaltyFee(uint64 poolId) public view returns(uint64) {
        return pools[poolId].penaltyFee;
    }
    
    function isTokenRewardsActive(address tokenAddress) public view returns(bool) {
        return tokensTracker[tokenAddress].isActive;
    }
    
    function getWhenTokenWasAdded(address tokenAddress) public view returns(uint256) {
        return tokensTracker[tokenAddress].sinceBlockNumber;
    }
    
    function getTokenAtIndex(uint64 tokenIndex) public view returns(address) {
        return tokens[tokenIndex];
    }
    
    function totalTokens() public view returns(uint256) {
        return tokens.length;
    }
    
    function getBalanceOfToken(address tokenAddress) public view returns(uint256) {
        IBEP20 token = IBEP20(tokenAddress);
        return token.balanceOf(address(this));
    }
    
    function getIsEmergencyOn() public view returns(bool) {
        return isEmergencyOn;
    }
    
    
    
}