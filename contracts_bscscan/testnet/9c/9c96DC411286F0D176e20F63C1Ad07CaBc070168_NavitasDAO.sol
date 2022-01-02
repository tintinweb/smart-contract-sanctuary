/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBEP20 {
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

contract NavitasDAO {

    address public NavitasContract = 0x402E47f75F89CaE55C9D12E99533c5026baa35AB;
    address public owner=0x3B0F531c469758185D7263B4A12C63c71b0846eC;
    address public NavitasOracle=0x5775225D6716F1a79bf71Da5A4A831f074CD183d;
    IBEP20 public NAVITAS = IBEP20(NavitasContract);
    //STAKING
    mapping (address=>uint256) stake;
    mapping (address=>uint256) unlockedAt;
    mapping (address=>uint256) lastClaimed;


    uint256 stakers=0;
    uint256 currentlyStaked=0;
    uint256 currentCO2Concentration=41735; //417.35 ppm
    uint256 stakeLockSeconds=432000;
    uint256 rewardLimiter=43200;
 

    uint256 initialPercentFactor=200000; //increased

    function burn(uint256 amount) public {
        require(msg.sender==owner);
        NAVITAS.transfer(0x000000000000000000000000000000000000dEaD,amount);

    }


    function modifyrewardLimiter(uint256 newlimit) public {
        require(msg.sender==owner);
        rewardLimiter=newlimit;
    }    
    function modifyStakeLock(uint256 stakelock) public {
        require(msg.sender==owner);
        stakeLockSeconds=stakelock;
    }

    function updateCO2(uint256 co2) public {
        require(msg.sender==NavitasOracle,"Not oracle");
        currentCO2Concentration=co2;
    }


    function estimateReward(address staker) public view returns (uint256){
  
        uint256 rewardCalculation=(initialPercentFactor)/currentCO2Concentration;
        uint256 reward=(((stake[staker]/100)*(rewardCalculation)))*((block.timestamp-lastClaimed[staker])/rewardLimiter);
        return reward;  


    }

    function timeLeft(address staker) public view returns (uint256){
        return lastClaimed[staker]+rewardLimiter;
    
    }

    function readStake (address staker) public view returns (uint256){
        return stake[staker];
    }

    function readTotalStaked() public view returns (uint256){
        return currentlyStaked;
    }

    function getCurrentPercent() public view returns(uint256){
  
        uint256 rewardCalculation=(initialPercentFactor)/currentCO2Concentration;
        return rewardCalculation;    
        
                              
    }

    function getReward() public {
        require(block.timestamp>(lastClaimed[msg.sender]+rewardLimiter),"Claiming too often!");


        uint256 rewardCalculation=(initialPercentFactor)/currentCO2Concentration;
        uint256 reward=(((stake[msg.sender]/100)*(rewardCalculation)))*((block.timestamp-lastClaimed[msg.sender])/rewardLimiter);
        lastClaimed[msg.sender]=block.timestamp; 
        NAVITAS.transfer(msg.sender,reward);

    }

        function addStake (uint256 amount) public
    {

        NAVITAS.transferFrom(msg.sender,address(this),amount);
        NAVITAS.transfer(NavitasOracle,(amount/100)*3);
        unlockedAt[msg.sender]=block.timestamp+stakeLockSeconds;
        lastClaimed[msg.sender]=block.timestamp;
        stake[msg.sender]+=amount-((amount/100)*3);

        currentlyStaked+=amount-((amount/100)*3);
        stakers+=1;

        
    }
    
    function removeStake() public{
        require (unlockedAt[msg.sender]<block.timestamp,"Stake is locked");
        uint256 thisStake=stake[msg.sender];
        delete stake[msg.sender];
        currentlyStaked-=thisStake;
        stakers-=thisStake;        
        NAVITAS.transfer(msg.sender,thisStake);

    }


    //VOTING SYSTEM
    mapping (string=>uint256) Voters;
    mapping (string =>uint256) upVotes;
    mapping (string =>uint256) downVotes;
    mapping (string =>uint256) expiryDate;
    mapping (string=>uint256) ActivityReward;
    mapping (string=>mapping(address=>uint256)) sideOfVote;
    uint256 votingFee=100000000000000000000;



    function getUpvotes(string memory id) public view returns(uint256){
        return upVotes[id];
    }

    function getTimeLeft(string memory id) public view returns(uint256){
        return expiryDate[id];
    }

    function getOutcome (string memory id) public view returns (bool){
        require(block.timestamp>expiryDate[id],"Voting not ended!");
        if (upVotes[id]>downVotes[id]){
            return true;
        } else {
            return false;
        }
    }

    function claimVotingReward (string memory id) public {
        require(block.timestamp>expiryDate[id],"Voting not ended!");
        if (upVotes[id]>downVotes[id]){
            if(sideOfVote[id][msg.sender]==1){
                sideOfVote[id][msg.sender]=0;

                NAVITAS.transfer(msg.sender,ActivityReward[id]/upVotes[id]);
            }
        } else {
            if(sideOfVote[id][msg.sender]==2){
                sideOfVote[id][msg.sender]=0;
                NAVITAS.transfer(msg.sender,ActivityReward[id]/downVotes[id]);

            }            
        }
    }

    function getDownvotes(string memory id) public view returns(uint256){
        return downVotes[id];
    }
    function createProposal(string memory id) public {
        expiryDate[id]=block.timestamp+stakeLockSeconds;
    }


    function upvote(string memory id) public {
        require(stake[msg.sender]>0);
        require(block.timestamp<expiryDate[id]);
        NAVITAS.transferFrom(msg.sender,address(this),votingFee);
        sideOfVote[id][msg.sender]=1;
        upVotes[id]++;
    }

    function downvote(string memory id) public {
        require(stake[msg.sender]>0);
        require(block.timestamp<expiryDate[id]);
        NAVITAS.transferFrom(msg.sender,address(this),votingFee);
        sideOfVote[id][msg.sender]=2;

        downVotes[id]++;
    }
    uint256 proposedVoteFee=0;
    bool vote_votingFeeInProgress=false;
    //APPLICATION SPECIFIC VOTES
    // vote fee change: id k6HrUBZa
    function changeVoteFee(uint256 proposedFee) public {
        expiryDate["k6HrUBZa"]=block.timestamp+stakeLockSeconds;
        vote_votingFeeInProgress=true;
        proposedVoteFee=proposedFee;
    }

    function finish_changeVoteFee (string memory id) public {
        require(block.timestamp>expiryDate[id],"Voting not ended!");
        if (upVotes[id]>downVotes[id]){
            if(vote_votingFeeInProgress==true){
                 votingFee=proposedVoteFee;
            }
            if(sideOfVote[id][msg.sender]==1){

                sideOfVote[id][msg.sender]=0;
                NAVITAS.transfer(msg.sender,ActivityReward[id]/upVotes[id]);
            }
        } else {
            if(sideOfVote[id][msg.sender]==2){
                sideOfVote[id][msg.sender]=0;
                NAVITAS.transfer(msg.sender,ActivityReward[id]/downVotes[id]);

            }            
        }
    }

    
}