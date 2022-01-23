/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract launchpad is Ownable {
    struct UserStake {
        address user;
        uint256 amount;
        uint64 stakeTime;
        uint64 lockedfor;
        bool unstakecomp;
        bool rewardClaimed;
    }
    // struct UserTiers {
    //     address user;
    //     uint256 amount;
    //     uint256 tierTevel;
    // }
    UserStake[] userStake;  // Can make this public to unpublic
    // uint transferBackIDOAddress[10];
    address[] public transferBackIDOAddress;
    // UserTiers[] userTiers;  
    uint64 public lockperiod = 3 minutes;
    IERC20 public stakedToken;
    IERC20 public rewardToken;
    // IERC20 public launchpadAddress = IERC20(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    // address public launchpadAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    IERC20 public idoToken;
    uint256 public totalStaked;
    uint256 public aprPer;
    uint256 public minStake = 0;
    uint256 public maxStake = 100000000000 * 1e18 * 1e18;
    uint256 public idoMulti = 1;
    uint256 public tier1 = 200000;
    uint256 public tier2 = 500000;
    uint256 public tier3 = 1000000;


    
    mapping(address => uint) public Userstaked;
    mapping(address => uint) public idoBalance;
    mapping(address => uint) public idoTransfer;
    mapping(address => uint) public tierLevel;
    
    constructor(IERC20 _rewardToken, IERC20 _stakedToken, IERC20 _idoToken) {
        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
        idoToken = _idoToken;
    }


    function stake(uint256 _amount) external {
        require(minStake < _amount && maxStake >= _amount, "Could not stake this amount");
        userStake.push(UserStake(msg.sender, _amount,uint64(block.timestamp),lockperiod, false, false));
        stakedToken.transferFrom(msg.sender, address(this), _amount);
        Userstaked[msg.sender] = Userstaked[msg.sender] + _amount;
        idoBalance[msg.sender] = idoBalance[msg.sender] + (_amount * idoMulti);
        totalStaked = totalStaked + _amount;
    }

    function unStake(uint256 _amount) external {
        require(checkUserValid(msg.sender) != 0, "Not a Valid User");
        require(_amount > 0, "Can't Unstake 0");
        require(idoBalance[msg.sender] >= (_amount * idoMulti), "Unstake failed! User dont haveSUFFICIENT IDO Token");
        require(checkUserValid(msg.sender) != 0, "Not a Valid User");
        uint256 tempwithdraw = 0;
        uint256 checkwithdraw = 0;
        address _user = msg.sender;
        
        for(uint256 i = 0; i < userStake.length; i++) {
            if (checkwithdraw < _amount) {
                if (userStake[i].user == _user && userStake[i].unstakecomp == false) {          
                    if (userStake[i].stakeTime + userStake[i].lockedfor <= block.timestamp) {           // Normal Unstake without Penalty
                       if(userStake[i].amount >= _amount) {
                           tempwithdraw = tempwithdraw + _amount;
                           userStake[i].amount = userStake[i].amount - _amount;
                           idoBalance[msg.sender] = idoBalance[msg.sender] - (_amount * idoMulti); 
                           checkwithdraw = tempwithdraw;
                           if (userStake[i].amount == 0) {
                               userStake[i].unstakecomp = true;
                           }
                        }  
                    } else {                                                            // This part of code get executed when user unstake before unlock
                        if(userStake[i].amount >= _amount) {
                            // For the user with penalty for withdrwaing before unlock
                            // amount 1000000000000000000000 * 2500000000000000000 / 100
                            // 1000 * 2.5 / 100
                            uint256 penalty = _amount * 2500000000000000000 / 100000000000000000000; 
                            uint256 tempamout = _amount - penalty;
                            tempwithdraw = tempwithdraw + tempamout;
                            userStake[i].amount = userStake[i].amount - _amount;
                            idoBalance[msg.sender] = idoBalance[msg.sender] - (_amount * idoMulti);
                            if (userStake[i].amount == 0) {
                                userStake[i].unstakecomp = true;
                            }
                            checkwithdraw = checkwithdraw + _amount;
                        }
                    }
                }
            }
        }
        require(tempwithdraw > 0, "Nothing to unstake");
        stakedToken.transfer(msg.sender, tempwithdraw);
        Userstaked[msg.sender] = Userstaked[msg.sender] - _amount;
        totalStaked = totalStaked - _amount;
    }

    function getUnstake(address _user) external view returns (uint256) {
        uint256 userStakeable = 0;
        for(uint256 i = 0; i < userStake.length; i++) {
            if (userStake[i].user == _user && userStake[i].unstakecomp == false) {
                if (userStake[i].stakeTime + userStake[i].lockedfor <= block.timestamp) {
                    userStakeable = userStakeable + userStake[i].amount;
                }
            }
        }
        return userStakeable;
    }

    function getStakeValue(address _user) internal returns (uint256) {
        uint256 userClaimable = 0;
        for(uint256 i = 0; i < userStake.length; i++) {
            if (userStake[i].user == _user && userStake[i].rewardClaimed == false) {
                userClaimable = userClaimable + userStake[i].amount;
            }
        }
        return userClaimable;
    }
    // function getStakeValues(address _user) public view returns (uint256) {
    //     uint256 userClaimable = 0;
    //     for(uint256 i = 0; i < userStake.length; i++) {
    //         if (userStake[i].user == _user && userStake[i].unstakecomp == false) {
    //             userClaimable = userClaimable + userStake[i].amount;
    //         }
    //     }
    //     return userClaimable;
    // }
    // function getStakeTime(address _user) internal returns (uint64) {
    //     uint64 userTime = 0;
    //     for(uint256 i = 0; i < userStake.length; i++) {
    //         if (userStake[i].user == _user && userStake[i].unstakecomp == false) {
    //             userTime = userStake[i].stakeTime;
    //         }
    //     }
    //     return userTime;
    // }
    function checkUserValid(address _user) internal returns (uint256) {
        uint256 count = 0;
            for(uint256 i = 0; i < userStake.length; i++) {
                if (userStake[i].user == _user && userStake[i].unstakecomp == false) {
                    count = count + 1;
                }
            }
        return count;
    }

    function updateClaimed(address _user) internal {
        for(uint256 i = 0; i < userStake.length; i++) {
            if (userStake[i].user == _user && userStake[i].unstakecomp == false) {
                 userStake[i].rewardClaimed = true;
            }
        }
    }

    function claim() external {
        // require(checkUserValid(msg.sender) != 0;)
        require(checkUserValid(msg.sender) != 0, "Not a Valid User");
        uint256 userStakedIn = 0;
        uint256 claimReward = 0;
        uint256 rewardInContract = 0;
        // uint64 userStakedTime = 0;
        userStakedIn = getStakeValue(msg.sender);  // We can use direct the userstaked mapping also
        // userStakedTime = getStakeTime(msg.sender);
        // userStakedIn = getRewardValue(Userstaked[msg.sender]);
        claimReward = getRewardValue(userStakedIn);
        require(claimReward != 0, "No Rewards to Claim");
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (rewardToken == stakedToken){
            rewardInContract = rewardTokenBalance - totalStaked;
        }
        require(rewardInContract >= claimReward, "INSUFFICIENT Token to Transfer");
        require(rewardToken.transfer(msg.sender, claimReward), "Transfer Failed");
        updateClaimed(msg.sender);


    }

    function getRewardValue(uint _amount) public returns(uint256) {  // Has to make this function internal for testing made in public
        require(_amount != 0, "No Rewards");
        uint256 multiplier = 0;
        uint256 reward = 0;
        multiplier = aprPer / 12;
        multiplier = multiplier * 1e18;
        reward = _amount * multiplier / 100000000000000000000; 
        return reward;

    }

    function transferIDOToken(uint256 _amount) external {
        require(checkUserValid(msg.sender) != 0, "Not a Valid User");
        require(idoBalance[msg.sender] >= _amount, "Transfering more than you have");
        require(idoToken.transfer(address(this), _amount), "Transfer failed");
        idoTransfer[msg.sender] = idoTransfer[msg.sender] + _amount;
        idoBalance[msg.sender] = idoBalance[msg.sender] - (_amount);
        updateTier();
        
    }

    function transferBackIDOToken(uint256 _pool, uint256 _amount) external {
        // uint256 backIDO = transferBackIDOAddress[_pool].getIDOTransfereds(msg.sender);  // for fetching token from staking contract
        uint256 backIDO = getIDOTransfered(msg.sender);
        require(backIDO >= _amount, "No sufficient tokens");
        require(idoToken.transfer(transferBackIDOAddress[_pool], _amount), "Transfer Failed");
        idoTransfer[msg.sender] = idoTransfer[msg.sender] - _amount;

    }

    // function getIDOTransfereds(address _user) internal returns (uint256) {
    //     return idoTransfer[msg.sender];
    // }
    function getIDOTransfered(address _user) public view returns (uint256) {
        return idoTransfer[msg.sender];
    }

    function updateTier() public {
        require(idoTransfer[msg.sender] >= 0, "INSUFFICIENT IDO Tokens");
        if (idoTransfer[msg.sender] >= tier1) {
            tierLevel[msg.sender] = tier1;
        } 
        if (idoTransfer[msg.sender] >= tier2) {
            tierLevel[msg.sender] = tier2;
        }
        if (idoTransfer[msg.sender] >= tier3) {
            tierLevel[msg.sender] = tier3;
        }
    }
    // function updateUserTier() external {
    //     require(idoTransfer[msg.sender] >= 0, "INSUFFICIENT IDO Tokens");
    //     if (idoBalance[msg.sender] >= tier1) {
    //         tierLevel[msg.sender] = tier1;
    //     } else if (idoBalance[msg.sender] >= tier2) {
    //         tierLevel[msg.sender] = tier2;
    //     } else if (idoBalance[msg.sender] >= tier3) {
    //         tierLevel[msg.sender] = tier3;
    //     } else {
    //         tierLevel[msg.sender] = 0;
    //     }

    // }

    function setAPR(uint256 _aprPer) external onlyOwner {
        require(_aprPer != 0, "APR can't set as ZERO");
        aprPer = _aprPer;
    }

    function setIDORatio(uint256 _idoratio) external onlyOwner {
        require(_idoratio != 0, "IDORatio can't set as ZERO");
        idoMulti = _idoratio;
    }

    function changRewardToken(IERC20 _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    } 

    function updateMax(uint _max) external onlyOwner {
        maxStake = _max; 
    }

    function updateMin(uint _min) external onlyOwner {
        minStake = _min; 
    }
    function updateTier1(uint _tier1) external onlyOwner {
        tier1 = _tier1; 
    }
    function updateTier2(uint _tier2) external onlyOwner {
        tier2 = _tier2; 
    }
    function updateTier3(uint _tier3) external onlyOwner {
        tier3 = _tier3; 
    }

    function updateTransferBackAddress(uint256 _poolId, address _pooladdress) external onlyOwner {
        if (transferBackIDOAddress[_poolId] ==  address(0)) {
           transferBackIDOAddress.push(_pooladdress); 
        } else {
            transferBackIDOAddress[_poolId] = _pooladdress;
        }
    }


}