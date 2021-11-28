/**
 *Submitted for verification at BscScan.com on 2021-11-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}

interface IStakeable{
    function getStakedAmount(address user) external view returns(uint);
    function isStaker(address user) external view returns(bool);
    function getTotalParticipants() external view returns(uint256);
    function getParticipantsByTierId(uint tierId) external view returns(uint256);
    function isAllocationEligible(uint participationEndTime) external view returns(bool);
    function getTierIdFromUser(address sender) external view returns(uint);
}
contract ClaimableContract{
    //staking contract
    IStakeable public stakingContract;
    IERC20Metadata public appToken;
    uint public totalSupply;
    uint public totalSoldToken;
    uint public tokenBalance;
    uint TGEListingTime;
    uint totalParticipants;
    uint participationEndTime;
    uint roundOneStartTime;
    uint roundOneEndTime;
    uint FCFSStartTime;
    uint FCFSEndTime;
    uint256 vestingTime;
    uint256 numberOfSlots;
    bool isAllocationEnd;
    bool isFCFSAllocationEnd;
    bool isCompleted;
    address admin;
   

    struct TierDetail{
        uint256 poolWeight;
        uint256 allocatedAmount;
        uint256 participants;
    }

    mapping(uint => TierDetail) public tierDetails;

    event TokenBought(address user,uint tierId,uint amount);
    event TokenWithdrawn(address user,uint tierId,uint amount);
    event participationCompleted(uint endTime);
    event BuyingCompleted();
    event Participate(address user,uint tierid);
    event AllocationRoundOneEnds(uint allocationEndTime);
    event AllocationRoundTwoEnds(uint tokenBalance);

    struct userDetail{
        uint totalAmountBought;
        uint balanceCanBeBought;
        uint balanceNeedtoSend;
        uint nextVestingTime;
    }
   

    mapping(address => userDetail) userDetails;

    constructor(IStakeable _stakingContract,IERC20Metadata _appToken,uint _totalsupply,uint[] memory poolWeights,uint _TGEListingTime,uint _numberOfSlots,uint _vestingTime, uint _roundOneStartTime,uint _roundOneEndTime,uint _FCFSStartTime){
        admin = msg.sender;        
        stakingContract = _stakingContract;
        appToken = _appToken;
        totalSupply = _totalsupply * 10 ** appToken.decimals();
        uint i;
        for(i=1;i<7;i++){
            tierDetails[i].poolWeight = poolWeights[i-1];
        }
        TGEListingTime = block.timestamp + _TGEListingTime * 3600;
        roundOneStartTime = block.timestamp + _roundOneStartTime * 3600;
        roundOneEndTime = block.timestamp + _roundOneEndTime * 3600;
        FCFSStartTime = block.timestamp + _FCFSStartTime * 3600;
        numberOfSlots = _numberOfSlots;
        vestingTime = _vestingTime;
    }

    modifier _onlyOwner{
        require(msg.sender==admin,"only owner can implement this method");
        _;
    }

    function getTierAllocatedAmount(uint tierId) public view returns(uint,uint){
        return (tierDetails[tierId].participants,tierDetails[tierId].allocatedAmount);
    }


    function allocation() public _onlyOwner{
        require(!isAllocationEnd,"allocation cannot happen before after the participation ends");
        uint8 i;
        totalParticipants = stakingContract.getTotalParticipants();
        require(totalParticipants != 0,"allocation cant happen if there is no participants");
        //uint totalAllocToken = totalSupply/totalParticipants;
        for(i=1;i<7;i++){
            tierDetails[i].participants = stakingContract.getParticipantsByTierId(i);
            if(tierDetails[i].participants == 0){
                tierDetails[i].allocatedAmount = 0;
            }
            else{
                tierDetails[i].allocatedAmount = (totalSupply *  tierDetails[i].poolWeight)/100;
                tierDetails[i].allocatedAmount = tierDetails[i].allocatedAmount/tierDetails[i].participants;
            }
        }
        isAllocationEnd = true;
        participationEndTime = block.timestamp;
        emit AllocationRoundOneEnds(block.timestamp);
    }

    function allocationRoundTwo() public _onlyOwner{   
        require(block.timestamp >= roundOneEndTime,"allocation cannot happen before after the participation ends");
        require(!isFCFSAllocationEnd,"allocation cannot happen before after the participation ends");
        tokenBalance = totalSupply - totalSoldToken;
        isFCFSAllocationEnd = true;
        emit AllocationRoundTwoEnds(tokenBalance);
    }

    function getAllocation() view public returns(uint){
        require(stakingContract.isAllocationEligible(participationEndTime),"not eligible");
        return tierDetails[stakingContract.getTierIdFromUser(msg.sender)].allocatedAmount;
    }

     function getUserDetails(address sender) public view returns(uint,uint){
        return (userDetails[sender].totalAmountBought,userDetails[sender].balanceNeedtoSend);
    }

    function buyToken(uint amount) public{
        require(stakingContract.isStaker(msg.sender),"you must stake first to buy tokens");
        require(!isCompleted,"No token to buy");
        require(block.timestamp >= roundOneStartTime,"round one not yet started");
        uint tierId = stakingContract.getTierIdFromUser(msg.sender);
        if(block.timestamp <= roundOneEndTime){
            //get clarification whether it is for any particular tier
            if(userDetails[msg.sender].totalAmountBought == 0){
                userDetails[msg.sender].balanceCanBeBought = tierDetails[tierId].allocatedAmount;
            }
            //return (userDetails[msg.sender].balanceCanBeBought);
            require(amount <= userDetails[msg.sender].balanceCanBeBought,"amount should be lesser than alloc amount");
            userDetails[msg.sender].balanceCanBeBought -= amount;
            totalSoldToken += amount;
            userDetails[msg.sender].totalAmountBought += amount;
            userDetails[msg.sender].balanceNeedtoSend += amount;
        }
        else{
            require(block.timestamp <= FCFSEndTime,"cannot buy after fcfs end");
            require(amount <= tokenBalance,"amount should be lesser than allocated amount");
            totalSoldToken += amount;
            tokenBalance -= amount;
            if(tokenBalance == 0){
                isCompleted = true;
            }
            userDetails[msg.sender].totalAmountBought += amount;
            userDetails[msg.sender].balanceNeedtoSend += amount;
            
            //return (userDetails[msg.sender].totalAmountBought);
        }
        emit TokenBought(msg.sender, tierId, amount);
    }

    function claimToken() public{
        uint tierId = stakingContract.getTierIdFromUser(msg.sender);
        require(block.timestamp >= TGEListingTime,"cannot claim before listing time");
        require(userDetails[msg.sender].balanceNeedtoSend > 0,"amount should be greater than zero");
        if(userDetails[msg.sender].balanceNeedtoSend == userDetails[msg.sender].totalAmountBought){
            userDetails[msg.sender].nextVestingTime = TGEListingTime;
        }
        require(block.timestamp >= userDetails[msg.sender].nextVestingTime,"cannot be vested now");
        uint amountToBeSend = userDetails[msg.sender].totalAmountBought/numberOfSlots;
        appToken.transferFrom(admin, msg.sender, amountToBeSend);
        userDetails[msg.sender].balanceNeedtoSend -= amountToBeSend;
        userDetails[msg.sender].nextVestingTime = block.timestamp + vestingTime * 3600;
        emit TokenWithdrawn(msg.sender, tierId, amountToBeSend);
    }

    
    //function setTGEListingTime(uint time) public _onlyOwner{
    //    TGEListingTime = time;
    //}    
}