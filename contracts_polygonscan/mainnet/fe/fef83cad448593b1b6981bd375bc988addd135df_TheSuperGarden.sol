// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

//  _ __   ___  __ _ _ __ ______ _ _ __  
// | '_ \ / _ \/ _` | '__|_  / _` | '_ \ 
// | |_) |  __/ (_| | |   / / (_| | |_) |
// | .__/ \___|\__,_|_|  /___\__,_| .__/ 
// | |                            | |    
// |_|                            |_|    

// https://pearzap.com/

// The SUPER garden : Stake 1 token, earn x tokens

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract TheSuperGarden is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    uint constant tokensMaxNumber = 20; //Define the max number of token in the SuperGarden
    uint public tokensLength;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256[tokensMaxNumber] rewardDebtTX;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 lastRewardBlock;  // Last block number that PEARs distribution occurs.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 bonusEndBlock; // The block number when REWARDTOKEN pool ends.

        // Reward token partner token list
        IBEP20[tokensMaxNumber] tokenList;
        // Accumulate reward per token
        uint256[tokensMaxNumber] accRewardXPerShare;
        // Reward tokens distributed per block.
        uint256[tokensMaxNumber] rewardPerBlockTX;
        // Reward tokens name
        string[tokensMaxNumber] rewardTokenSYMBOL;
    }    

    // PEAR token
    IBEP20 public pear;

    // Deposit burn address
    address public burnAddress;
    // Deposit fee to burn
    uint16 public depositFeeToBurn;

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // The block number when PEAR mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _pear,
        address _burnAddress,
        uint16 _depositFeeBP,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        pear = _pear;
        burnAddress = _burnAddress;
        depositFeeToBurn = _depositFeeBP;
        startBlock = _startBlock;

        // Deposit fee limited to 10% No way for contract owner to set higher deposit fee
        require(depositFeeToBurn <= 1000, "contract: invalid deposit fee basis points");

        // init staking pool
        poolInfo.lpToken = _pear;
        poolInfo.lastRewardBlock = startBlock;
        poolInfo.depositFeeBP = _depositFeeBP;
        poolInfo.bonusEndBlock = _bonusEndBlock;
    }

    function stopReward() public onlyOwner {
        poolInfo.bonusEndBlock = block.number;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= poolInfo.bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= poolInfo.bonusEndBlock) {
            return 0;
        } else {
            return poolInfo.bonusEndBlock.sub(_from);
        }
    }

    // View function to see pending Reward for all tokens on frontend.
    function pendingRewardAll(address _user) external view returns (uint256[] memory) {
        UserInfo storage user = userInfo[_user];

        uint256[] memory pendingXReward = new uint256[](tokensLength);
        
        uint256 accRewardPerShare;
        uint256 lpSupply = poolInfo.lpToken.balanceOf(address(this));
        uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, block.number);
        uint256 tokenXReward;
        for (uint256 i = 0; i < tokensLength; ++i) {
            accRewardPerShare = poolInfo.accRewardXPerShare[i];
            if (block.number > poolInfo.lastRewardBlock && lpSupply != 0) {
                tokenXReward = multiplier.mul(poolInfo.rewardPerBlockTX[i]);
                accRewardPerShare = accRewardPerShare.add(tokenXReward.mul(1e30).div(lpSupply));
            }    
            pendingXReward[i] = user.amount.mul(accRewardPerShare).div(1e30).sub(user.rewardDebtTX[i]);
        }        
        
        return pendingXReward;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 tokenXReward;
        for (uint256 i = 0; i < tokensLength; ++i) {
            tokenXReward = multiplier.mul(poolInfo.rewardPerBlockTX[i]);
            poolInfo.accRewardXPerShare[i] = poolInfo.accRewardXPerShare[i].add(tokenXReward.mul(1e30).div(lpSupply));  
        } 
        
        pool.lastRewardBlock = block.number;
    }

    // Stake PEAR tokens to TheGarden
    function deposit(uint256 _amount) public { 
        UserInfo storage user = userInfo[msg.sender];

        updatePool();
        if (user.amount > 0) {
            
            uint256 pendingTX;
            for (uint256 i = 0; i < tokensLength; ++i) {
                pendingTX = user.amount.mul(poolInfo.accRewardXPerShare[i]).div(1e30).sub(user.rewardDebtTX[i]);
                if(pendingTX > 0) {
                    poolInfo.tokenList[i].safeTransfer(address(msg.sender), pendingTX);
                }
            }
        
        }
        // Add the possibility of deposit fees sent to burn address
        if(_amount > 0) {

            // Handle any token with transfer tax
            uint256 balanceBefore = poolInfo.lpToken.balanceOf(address(this));
            poolInfo.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = poolInfo.lpToken.balanceOf(address(this)).sub(balanceBefore);

            if(poolInfo.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(poolInfo.depositFeeBP).div(10000);
                poolInfo.lpToken.safeTransfer(burnAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }   
        
        for (uint256 i = 0; i < tokensLength; ++i) {
            user.rewardDebtTX[i] = user.amount.mul(poolInfo.accRewardXPerShare[i]).div(1e30);
        } 

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw PEAR tokens from STAKING.
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();

        uint256 pendingTX;
        for (uint256 i = 0; i < tokensLength; ++i) {
            pendingTX = user.amount.mul(poolInfo.accRewardXPerShare[i]).div(1e30).sub(user.rewardDebtTX[i]);
            if(pendingTX > 0) {
                poolInfo.tokenList[i].safeTransfer(address(msg.sender), pendingTX);
            }
        }
        
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            poolInfo.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        for (uint256 i = 0; i < tokensLength; ++i) {
            user.rewardDebtTX[i] = user.amount.mul(poolInfo.accRewardXPerShare[i]).div(1e30);
        } 

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;

        for (uint256 i = 0; i < tokensMaxNumber; ++i) {
            user.rewardDebtTX[i] = 0;
        }         
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward token X. EMERGENCY ONLY.
    function emergencyRewardWithdrawTX(uint256 _amount, uint _tokenid) public onlyOwner {
        require(_amount < poolInfo.tokenList[_tokenid].balanceOf(address(this)), 'not enough token');
        poolInfo.tokenList[_tokenid].safeTransfer(address(msg.sender), _amount);
    }
    
    // Add a function to update rewardPerBlock. Can only be called by the owner.
    function updaterewardPerBlockTX(uint256 _rewardPerBlockTX, uint _tokenid) public onlyOwner {
        poolInfo.rewardPerBlockTX[_tokenid] = _rewardPerBlockTX;
        //Automatically updatePool 0
        updatePool();        
    }
    
    // Add a function to initiate tokens. Can only be called by the owner.
    function setTokenX(address _tokenAddress, uint _tokenid) public onlyOwner {
        poolInfo.tokenList[_tokenid] = IBEP20(_tokenAddress);
        //Automatically add symbol in list
        string memory symbol = poolInfo.tokenList[_tokenid].symbol();
        poolInfo.rewardTokenSYMBOL[_tokenid] = symbol;
        
        if (_tokenid + 1 > tokensLength) {
            tokensLength = _tokenid + 1;
        }
    }
    
    // Add a function to update bonusEndBlock. Can only be called by the owner.
    function updateBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        poolInfo.bonusEndBlock = _bonusEndBlock;
    }
    
    // Update the given pool's deposit fee. Can only be called by the owner.
    function updateDepositFeeBP(uint16 _depositFeeBP) public onlyOwner {
        require(_depositFeeBP <= 10000, "updateDepositFeeBP: invalid deposit fee basis points");
        poolInfo.depositFeeBP = _depositFeeBP;
        depositFeeToBurn = _depositFeeBP;
    }
    
    // Add a function to update startBlock. Can only be called by the owner.
    function updateStartBlock(uint256 _startBlock) public onlyOwner {
        //Can only be updated if the original startBlock is not minted
        require(block.number <= poolInfo.lastRewardBlock, "updateStartBlock: startblock already minted");
        poolInfo.lastRewardBlock = _startBlock;
        startBlock = _startBlock;
    }
    
    function getTokenInfo(uint _tokenid) external view returns (address,string memory,uint256,uint256) {
        address tokenAddress = address(poolInfo.tokenList[_tokenid]);
        string memory tokenSymbol = poolInfo.rewardTokenSYMBOL[_tokenid];
        uint256 rewardPerBlockTX = poolInfo.rewardPerBlockTX[_tokenid];
        uint256 accRewardXPerShare = poolInfo.accRewardXPerShare[_tokenid];
        return (tokenAddress,tokenSymbol,rewardPerBlockTX,accRewardXPerShare);
    }

    function getAllTokensInfo() external view returns (address[] memory,string[] memory,uint256[] memory,uint256[] memory) {
        address[] memory tokenAddress = new address[](tokensLength);
        uint256[] memory accRewardXPerShare = new uint256[](tokensLength);
        string[] memory tokenSymbol = new string[](tokensLength);
        uint256[] memory rewardPerBlockTX = new uint256[](tokensLength);
        
        for (uint256 i = 0; i < tokensLength; ++i) {
            tokenAddress[i] = address(poolInfo.tokenList[i]);
            tokenSymbol[i] = poolInfo.rewardTokenSYMBOL[i];
            accRewardXPerShare[i] = poolInfo.accRewardXPerShare[i];
            rewardPerBlockTX[i] = poolInfo.rewardPerBlockTX[i];
        } 
        
        return (tokenAddress,tokenSymbol,rewardPerBlockTX,accRewardXPerShare);
    }    

}