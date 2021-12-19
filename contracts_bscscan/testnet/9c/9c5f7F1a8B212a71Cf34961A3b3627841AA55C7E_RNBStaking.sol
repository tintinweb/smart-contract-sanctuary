/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-17
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
contract RNBStaking {
    mapping (address=>uint256) pendingStakeDeposit;
    mapping (string=>address) stakeTx;
    mapping (string=>uint256) stakedFunds;
    mapping (string=>uint256) timestampForUnlock;
    mapping (address=>uint256[]) stakedFunds_frontend;
    mapping (address=>string[]) stakedFunds_txids_frontend;
    address public RNBToken = 0x7F0Cc037c24eb0ba10225B268e99051a3e8E9D95;
    address public owner=0xf31B17a2EeFC33Bff29EA506DB909D5EcEaa7303;
    address public oracle=0xa5A0039B60a91b5220E4E5Cd1CdEC02a3C1CC3ee;
    IBEP20 public RNB = IBEP20(RNBToken);
    uint256 currentlyStaked=0;
    uint256 lastDeposit=1671277938;
    uint256 txFee=100000000000000;
    uint256 lockTime=7889231;
    function modifyLastDeposit(uint256 newLastDeposit) public {
        require(msg.sender==owner);
            lastDeposit=newLastDeposit;
        
    }
    function modifyLockTime(uint256 newLockTime) public{
        require(msg.sender==owner);
            lockTime=newLockTime;
        
    }

    function modifyTxFee(uint256 newTxFee) public {
        require(msg.sender==owner);
            txFee=newTxFee;
        
    }

    event newStake(address staker, string txid);
    event requestReward (address staker);
    event stakeConfirmed (address staker, string txid);
    function readUserStakes(address staker) public view returns (uint256[] memory){
        return(stakedFunds_frontend[staker]);
    }

    function readUserTXIDs(address staker) public view returns (string[] memory){
        return(stakedFunds_txids_frontend[staker]);
    }

    function readStake(string memory txid) public view returns(uint256){
        uint256 stake=stakedFunds[txid];
        return stake;
    }

    function readTSUnlock(string memory txid) public view returns (uint256){
        uint256 ts=timestampForUnlock[txid];
        return ts;
    }

    function registerStake(string memory txid) public payable{
        require(block.timestamp<lastDeposit);
        require(msg.value>=txFee);
        uint256 fee=(msg.value);
        address payable oracleAddy=payable(oracle);
        oracleAddy.transfer(fee);
        emit newStake(msg.sender,txid);
    }



    function confirmStake(uint256 stakeAmount,string memory txid,address staker) public {
        require(msg.sender==oracle);
        stakedFunds_txids_frontend[staker].push(txid);
        stakedFunds_frontend[staker].push(stakeAmount);
        stakeTx[txid]=staker;
        stakedFunds[txid]=(stakeAmount);
        uint256 unlockDay=block.timestamp+lockTime;
        timestampForUnlock[txid]=(unlockDay);
        currentlyStaked++;
        emit stakeConfirmed(staker,txid);
        
    }



    function calculateReward(address staker,string memory txid) public view returns(uint256) {
        require(staker==stakeTx[txid],"Not owner of txid!");

        uint256 totalClaimable=0;
            if(timestampForUnlock[txid]<block.timestamp){
                totalClaimable=stakedFunds[txid];
        
        }
        return ((totalClaimable/100)*15);
    }
    function estimatedReward(address staker,string memory txid) public view returns(uint256) {
        require(staker==stakeTx[txid],"Not owner of txid!");

        uint256 totalClaimable=stakedFunds[txid];
        return ((totalClaimable/100)*15);
    }



    function getReward(string memory txid) public {
        require(msg.sender==stakeTx[txid],"Not owner of txid!");
        require(timestampForUnlock[txid]<block.timestamp,"Stake is locked! Wait for unlock day!");
        uint256 totalClaimable=stakedFunds[txid];
        
        for (uint256 i=0;i<stakedFunds_txids_frontend[msg.sender].length;i++){
            if(keccak256(abi.encodePacked(stakedFunds_txids_frontend[msg.sender][i]))==keccak256(abi.encodePacked(txid))){
                delete stakedFunds_frontend[msg.sender][i];
                delete stakedFunds_txids_frontend[msg.sender][i];
                break;
            }
        }
        currentlyStaked--;
        delete stakeTx[txid];
        delete stakedFunds[txid];
        delete timestampForUnlock[txid];
        RNB.transfer(msg.sender,((totalClaimable/100)*15));           
        
        
 
    }



    
    }