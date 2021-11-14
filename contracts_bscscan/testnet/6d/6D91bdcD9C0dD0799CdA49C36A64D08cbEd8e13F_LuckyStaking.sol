/**
 *Submitted for verification at BscScan.com on 2021-11-14
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

contract LuckyStaking {
    mapping (address=>uint256) stake;
    mapping (address=>uint256) poolShare;
    mapping (address=>uint256) lastClaimed;
    mapping (address=>uint256) blockSinceDeposit;
    
    
    
    
    uint256[] depositHistory;
    uint256[] removeStakeHistory;
    uint256[] claimDividendsHistory;
    uint256[] reinvestDividendsHistory;
    
    address[] reinvestDividendsHistoryAddress;
    address[] depositHistoryAddress;
    address[] removeStakeHistoryAddress;
    address[] claimDividendsHistoryAddress;
    
    uint256[] reinvestDividendsHistoryTS;
    uint256[] depositHistoryTS;
    uint256[] removeStakeHistoryTS;
    uint256[] claimDividendsHistoryTS;    
    
    uint256 totalDeposits;
    uint256 stakers;
    uint256 waitBlocks=28800;
    uint256 divideByDays=10;
    
    uint256 depositFee=0;
    uint256 withdrawalFee=0;   
    uint256 dividendFee=2;
    uint256 ownerFee=2;
    
    address public CNRContract = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    address public owner=0x97B4B22f10E998b0771970Bc4536d4F4588ca58e;
    IBEP20 public CNR = IBEP20(CNRContract);
    
     // START Modify Variables
   
    function modifyOwner(address newOwner) public {
        if(msg.sender==owner){
            owner=newOwner;
        }
    }
    
    function modifyWaitBlock(uint256 newWaitBlocks) public {
        if(msg.sender==owner){
            waitBlocks=newWaitBlocks;
        }
    }
    
    function modifyDivideByDays(uint256 newDays) public{
        if(msg.sender==owner){
            divideByDays=newDays;
        }
    }
    
    function modifyDepositFee(uint256 newDepositFee) public{
        if(msg.sender==owner){
            depositFee=newDepositFee;
        }
    }
    
    function modifyWithdrawalFee(uint256 newWithdrawalFee) public{
        if(msg.sender==owner){
            withdrawalFee=newWithdrawalFee;
        }
    }
    
    function modifyDividendFee(uint256 newDividendFee) public {
        if(msg.sender==owner){
            dividendFee=newDividendFee;
        }
    }
    
    function modifyOwnerFee(uint256 newOwnerFee) public {
        if(msg.sender==owner){
            ownerFee=newOwnerFee;
        }
    }
     // END Modify Variables
    
    // START Retrieve Data
    function getShareOfPool(address user) public view returns (uint256){
            return stake[user]/(totalDeposits/10000);
    }
    
    function getEstimatedPayout(address user) public view returns (uint256){
            uint256 reward=(1*(((CNR.balanceOf(address(this))-totalDeposits)*poolShare[user])/divideByDays))/10000;
            uint256 rewardPostFees=reward-((reward/100)*(ownerFee+dividendFee));
            return rewardPostFees;
    }
    
    function blocksLeftUntilPayout(address user) public view returns (uint256){
        uint256 blocksLeft=(lastClaimed[user]+waitBlocks)-block.number;
        return blocksLeft;
    }

    function userStake(address user) public view returns (uint256){
        return stake[user];
    }
    
    function totalStakers() public view returns (uint256){
        return stakers;
    }
    

    function currentClaimableDividends (address user) public view returns (uint256){
            uint256 daysPassed=((block.number-lastClaimed[user])/28800);
            uint256 reward=(daysPassed*(((CNR.balanceOf(address(this))-totalDeposits)*poolShare[msg.sender])/divideByDays))/10000;
            uint256 rewardPostFees=reward-((reward/100)*(ownerFee+dividendFee));
            return rewardPostFees;
    }
    function smartContractBalance() public view returns (uint256){
        return CNR.balanceOf(address(this));
    }
    function totalDividends() public view returns (uint256){
        uint256 totaldividends=(CNR.balanceOf(address(this))-totalDeposits);
        return totaldividends;
    }
    function dailyDividendsAvailable() public view returns (uint256){
        uint256 dailydivs=(CNR.balanceOf(address(this))-totalDeposits)/10;
        return dailydivs;

    }
    function totalStakedInEscrow() public view returns (uint256){
        return totalDeposits;
    }
    
    // END Retrieve Data
    
    
    // START Activity History
    function sendDepositHistory() public view returns (uint256[] memory){
        return depositHistory;
    }
    function sendDepositHistoryTS() public view returns (uint256[] memory){
        return depositHistoryTS;
    }    
    function sendDepositHistoryAddress() public view returns (address[] memory){
        return depositHistoryAddress;
    }    
    
    function sendWithdrawalHistory() public view returns (uint256[] memory){
        return removeStakeHistory;
    }
    
    function sendWithdrawalHistoryAddress() public view returns (address[] memory){
        return removeStakeHistoryAddress;
    } 
    
    function sendWithdrawalHistoryTS() public view returns (uint256[] memory){
        return removeStakeHistoryTS;
    }    
    
    function sendClaimDividendsHistory() public view returns (uint256[] memory){
        return claimDividendsHistory;
    }
    function sendClaimDividendsHistoryAddress() public view returns (address[] memory){
        return claimDividendsHistoryAddress;
    }
    function sendClaimDividendsHistoryTS() public view returns (uint256[] memory){
        return claimDividendsHistoryTS;
    }   
    
    function sendReinvestDividendsHistory ()public view returns (uint256[] memory){
        return reinvestDividendsHistory;
    }
    function sendReinvestDividendsHistoryAddress ()public view returns (address[] memory){
        return reinvestDividendsHistoryAddress;
    }    
    function sendReinvestDividendsHistoryTS ()public view returns (uint256[] memory){
        return reinvestDividendsHistoryTS;
    }
    // END Activity History
    
    
       // START Contract Functinality
  
    function claimDividends() public{
        if((lastClaimed[msg.sender]+28800)<block.number){
            uint256 daysPassed=((block.number-lastClaimed[msg.sender])/28800);
            uint256 reward=(daysPassed*(((CNR.balanceOf(address(this))-totalDeposits)*poolShare[msg.sender])/divideByDays))/10000;
            uint256 rewardPostFees=reward-((reward/100)*(ownerFee+dividendFee));
            uint256 devFee=((reward/100)*ownerFee);
            CNR.transfer(owner,devFee);
            CNR.transfer(msg.sender,rewardPostFees);
            claimDividendsHistory.push(reward);
            claimDividendsHistoryAddress.push(msg.sender);
            claimDividendsHistoryTS.push(block.number);

        }
    }
    
    function reinvestDividends() public {
             if((lastClaimed[msg.sender]+waitBlocks)<block.number){
            uint256 daysPassed=((block.number-lastClaimed[msg.sender])/waitBlocks);
            uint256 reward=(daysPassed*((CNR.balanceOf(address(this))-totalDeposits)*poolShare[msg.sender]))/10000;
            totalDeposits+=reward;
            stake[msg.sender]+=reward;
            poolShare[msg.sender]=stake[msg.sender]/(totalDeposits/10000);
            lastClaimed[msg.sender]=block.number;
            reinvestDividendsHistory.push(reward);
            reinvestDividendsHistoryAddress.push(msg.sender);
            reinvestDividendsHistoryTS.push(block.number);
        }   
    }

    function deposit (uint amount) public
    {
        depositHistory.push(amount);
        depositHistoryAddress.push(msg.sender);
        depositHistoryTS.push(block.number);
        CNR.transferFrom(msg.sender,address(this),amount);
        lastClaimed[msg.sender]=block.number;
        blockSinceDeposit[msg.sender]=block.number;
        stakers+=1;
        stake[msg.sender]+=amount;
        totalDeposits+=amount;
        poolShare[msg.sender]=stake[msg.sender]/(totalDeposits/10000);
        
    }
    
    function removeStake() public{

        
        removeStakeHistory.push(stake[msg.sender]);
        removeStakeHistoryAddress.push(msg.sender);
        removeStakeHistoryTS.push(block.number);
        uint256 amountToRemovePostFees=stake[msg.sender]-((stake[msg.sender]/100)*(ownerFee+dividendFee));
        uint256 devFee=((stake[msg.sender]/100)*ownerFee);
        CNR.transfer(owner,devFee);
        CNR.transfer(msg.sender,amountToRemovePostFees);
        totalDeposits-=stake[msg.sender];
        stake[msg.sender]=0;
        poolShare[msg.sender]=stake[msg.sender]/(totalDeposits/10000);

    }
    
        // END Contract Functinality
   
    
    



    
}