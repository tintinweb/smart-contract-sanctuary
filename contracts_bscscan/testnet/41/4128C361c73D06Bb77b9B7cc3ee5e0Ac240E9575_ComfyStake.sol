/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

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

interface ICUSD {
    
    function mintCUSD(address to, uint256 amount) external;
}

contract ComfyStake is ReentrancyGuard, Ownable {
    
    struct StakeInfo {
        uint256 comfyStaked;
        uint256 lastRewardsBlock; // block number
    }
    
    struct VestInfo {
        uint256 vestedComfy;
        uint256 unlockDate;
    }
    
    mapping(address => StakeInfo) stakes;
    uint256 public totalComfyStaked;
    
    mapping(address => VestInfo) vests;
    uint256 public totalComfyVested;
    
    address[] stakeholdersList;
    uint256 public stakeholdersCount = 0;
    
    uint256 rewardsPerBlock;
    uint256 vestingPeriod = 90 days;
    uint256 public mintedCUSD = 0;
    
    
    address public comfyTokenAddress;
    IBEP20 comfyToken;
    
    address public cusdContractAddress;
    ICUSD cusdContract;
    

    event StakeComfy(address stakeholder, uint256 amount);
    event UnstakeComfy(address stakeholder,uint256 amount);
    event WithdrawVestedComfy(address stakeholder, uint256 amount);
    
    constructor() {
    }
    
    receive() external payable { }
    

    function stakeComfy(uint256 amount) public nonReentrant {
        require(amount > 0, "Can not stake 0 COMFY");
        require(comfyToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(comfyToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        if(stakes[msg.sender].comfyStaked == 0) {
            addStakeholder();
        }
        
        updateCusdRewards(msg.sender);
        stakes[msg.sender].comfyStaked += amount;
        
        totalComfyStaked += amount;
        
        emit StakeComfy(msg.sender, amount);
    }
    
    function unstakeComfy(uint256 amount) external nonReentrant {
        
        require(stakes[msg.sender].comfyStaked > 0, "You haven't staked any COMFY");
        require(amount <= stakes[msg.sender].comfyStaked);
        assert(stakes[msg.sender].comfyStaked <= totalComfyStaked);
        
        updateCusdRewards(msg.sender);

        stakes[msg.sender].comfyStaked -= amount;
        totalComfyStaked -= amount;
        
        if(stakes[msg.sender].comfyStaked == 0) {
            removeStakeholder();
        }
        
        moveStakeToVestingPool(amount);
        
        emit UnstakeComfy(msg.sender, amount);
        
    }

     function addStakeholder() internal {
        stakeholdersList.push(msg.sender);
        stakeholdersCount++;
    }
    
    function removeStakeholder() internal {
        
        uint256 stakeholderIndex = 0;
        for(uint256 i = 0; i <= stakeholdersList.length - 1; i++) {
            if(stakeholdersList[i] == msg.sender) {
                stakeholderIndex = i;
            }
        }
        
        stakeholdersList[stakeholderIndex] = stakeholdersList[stakeholdersList.length - 1];
        stakeholdersList.pop();
        
        stakeholdersCount--;
    }
    
    function moveStakeToVestingPool(uint256 amount) internal {
        vests[msg.sender].vestedComfy += amount;
        vests[msg.sender].unlockDate = block.timestamp + vestingPeriod;
        totalComfyVested += amount;
    }
    
    function moveVestedComfyToStakingPool(uint256 amount) external {
        require(vests[msg.sender].vestedComfy > 0, "You don't have any vested Comfy!");
        require(vests[msg.sender].vestedComfy >= amount, "Amount exceeds your vested Comfy!");
        
        uint256 amountToMove = amount;
        if(amount == 0) {
            amountToMove = vests[msg.sender].vestedComfy;
        }
        
        vests[msg.sender].vestedComfy -= amountToMove;
        vests[msg.sender].unlockDate = block.timestamp;
        totalComfyVested -= amount;
        stakeComfy(amountToMove);
        
    }
    function withdrawVestedComfy() external {
        require(vests[msg.sender].vestedComfy > 0, "You don't have any vested Comfy");
        require(vests[msg.sender].unlockDate < block.timestamp, "Vesting period is not over yet");
        
        uint256 amountToTransfer = vests[msg.sender].vestedComfy;
        vests[msg.sender].vestedComfy = 0;
        require(comfyToken.transfer(msg.sender, amountToTransfer), "Transfer failed");
                
        emit WithdrawVestedComfy(msg.sender, amountToTransfer);
    }
    
    
    function massUpdateUsersPendingRewards() public {
        if(stakeholdersList.length > 0) {
            for(uint64 i = 0; i <= stakeholdersList.length - 1; i++) {
                updateCusdRewards(stakeholdersList[i]);
            }
        }
    }
    
    function updateCusdRewards(address walletAddress) internal  {
        uint256 rewards = 0;
        if(stakes[walletAddress].comfyStaked > 0) {
            uint256 lastRewardsBlock = stakes[walletAddress].lastRewardsBlock;
            if(lastRewardsBlock == 0) {
                lastRewardsBlock = block.number;
                stakes[walletAddress].lastRewardsBlock = block.number;
            }
            
            uint256 multiplier = block.number - lastRewardsBlock;
            rewards = rewardsPerBlock * ((stakes[walletAddress].comfyStaked * 10**18) / totalComfyStaked) * multiplier / 10**18;
            stakes[walletAddress].lastRewardsBlock = block.number;
        } else {
            stakes[walletAddress].lastRewardsBlock = block.number;
        }
        if(rewards > 0) {
            mintCUSD(rewards);
        }
    }
    
    function mintCUSD(uint256 amountToMint) internal {
        cusdContract.mintCUSD(msg.sender, amountToMint);
        mintedCUSD += amountToMint;
    }
    
    // onlyOwner functions
    
    function setCusdAddress(address contractAddress) external onlyOwner {
        cusdContractAddress = contractAddress;
        cusdContract = ICUSD(contractAddress);
    }
    
    
    function setRewardsPerBlock(uint256 rewards) external onlyOwner {
        massUpdateUsersPendingRewards();
        rewardsPerBlock = rewards;
    }

    
    function setVestingPeriod(uint256 period) external onlyOwner {
        vestingPeriod = period;
    }
    
    function setComfyTokenAddress(address tokenAddress) external onlyOwner {
        comfyTokenAddress = tokenAddress;
        comfyToken = IBEP20(tokenAddress);
    }
    
    // Utilities function
    
    function getComfyStakedByAddress(address walletAddress) public view returns(uint256) {
        return stakes[walletAddress].comfyStaked;
    }

    function getLastBlockRewardsByWallet(address walletAddress) public view returns(uint256) {
        return stakes[walletAddress].lastRewardsBlock;
    }

    function getCurrentUserRewards(address walletAddress) public view returns(uint256) {
        uint256 lastRewardsBlock = stakes[walletAddress].lastRewardsBlock;
            if(lastRewardsBlock == 0) {
                lastRewardsBlock = block.number;
                //stakes[walletAddress].lastRewardsBlock = block.number;
            }
        uint256 multiplier = block.number - lastRewardsBlock;
        return rewardsPerBlock * ((stakes[walletAddress].comfyStaked * 10**18) / totalComfyStaked) * multiplier / 10**18;
    }
    
    
}