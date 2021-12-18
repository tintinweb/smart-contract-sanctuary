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
    
    address public RNBToken = 0x7F0Cc037c24eb0ba10225B268e99051a3e8E9D95;
    address public owner=0x020Ea6F53B4301A782DC8F658e35694cDda4d721;
    address public oracle=0xC611Aeb171402Fbc2382C32eE9B9Cd65dDC88e6a;
    IBEP20 public RNB = IBEP20(RNBToken);
    uint256 lastDeposit=1671277938;
    uint256 txFee=0;
    uint256 lockTime=7889231;
    function modifyLastDeposit(uint256 newLastDeposit) public {
        if(msg.sender==owner){
            lastDeposit=newLastDeposit;
        }
    }
    function modifyLockTime(uint256 newLockTime) public{
        if(msg.sender==owner){
            lockTime=newLockTime;
        }
    }

    function modifyTxFee(uint256 newTxFee) public {
        if (msg.sender==owner){
            txFee=newTxFee;
        }
    }

    event newStake(address staker, string txid);
    event requestReward (address staker);

    function readStake(string memory txid) public view returns(uint256){
        uint256 stake=stakedFunds[txid];
        return stake;
    }

    function readTSUnlock(string memory txid) public view returns (uint256){
        uint256 ts=timestampForUnlock[txid];
        return ts;
    }

    function registerStake(string memory txid) public payable{
        require(msg.value>=txFee);
        uint256 fee=(msg.value);
        address payable oracleAddy=payable(oracle);
        oracleAddy.transfer(fee);
        emit newStake(msg.sender,txid);
    }



    function confirmStake(uint256 stakeAmount,string memory txid,address staker) public {
    if(msg.sender==oracle){
        stakeTx[txid]=staker;
        stakedFunds[txid]=(stakeAmount);
        uint256 unlockDay=block.timestamp+lockTime;
        timestampForUnlock[txid]=(unlockDay);
        }
    }



    function calculateReward(address staker,string memory txid) public view returns(uint256) {
        uint256 totalClaimable=0;
        if(staker==stakeTx[txid]){
            if(timestampForUnlock[txid]<block.timestamp){
                totalClaimable+=stakedFunds[txid];
        }
        }
        return ((totalClaimable/100)*15);
    }
    function estimatedReward(address staker,string memory txid) public view returns(uint256) {
        uint256 totalClaimable=0;
        if(staker==stakeTx[txid]){
            totalClaimable+=stakedFunds[txid];
        }
        return ((totalClaimable/100)*15);
    }


    function getReward(string memory txid) public {
        uint256 totalClaimable=0;
        if(msg.sender==stakeTx[txid]){
            if(timestampForUnlock[txid]<block.timestamp){
                totalClaimable+=stakedFunds[txid];
        }
        }

        delete stakeTx[txid];
        delete stakedFunds[txid];
        delete timestampForUnlock[txid];
        RNB.transfer(msg.sender,((totalClaimable/100)*15));    
    }



    
    }