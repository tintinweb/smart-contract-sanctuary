/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
// contract to manage the Bitgreen-Bridge
pragma solidity ^0.8.11;
contract BitgreenBridge {
    // settings storage
    address [10] keepers;
    address [3] watchdogs;
    address [3] watchcats;
    uint8 threshold;
    // address of the owner of the contract (the one allowed to change the settings)
    address payable public owner;
    // lockdown 
    bool public lockdown;
    // transaction queue structure
    struct transactionqueue {
        address payable recipient;      // recipient of the transaction
        uint amount;                    // amount of the transaction
        uint8 cnt;                      // counter of votes received from keepers
        address erc20;                  // address of the ERC20 contract (optional)
    }
    mapping( bytes32 => transactionqueue ) public txqueue;
    // % of withdrawal fees (18 decimals)
    uint256 public withdrawalfees;
    // minimum amount of withdrawal fees (18 decimals)
    uint256 public minimumwithdrawalfees;
    // balance of withdrawal fees
    uint256 public balancewithdrawalfees;
    // voting transaction logs of keepers activity
    mapping( bytes32 => mapping(address => bool)) public txvotes;


    // set the owner to the creator of the contract, ownership can be changed calling transferOwnership()
    constructor() payable {
          owner = payable(msg.sender);
          lockdown=false;
    }
     
    /**
     * @dev store configuration  for Keepers
     * @param Keepers is an array of address of the allowed keepers of the bridge transactions
     */
    function setKeepers(address [10] memory Keepers) public {
        require(msg.sender == owner,"Function accessible only to owner");
        require(lockdown==false,"contract in lockdown, please try later");
        uint i=0;
        // store state
        for(i=0;i<10;i++){
            if(Keepers[i]==address(0)){
                break;
            }
            keepers[i]=Keepers[i];
        }
    }
    /**
     * @dev store configuration for Watchdogs
     * @param Watchdogs is an array of address of the accounts allowed to lockdown the bridge when a transaction arrives
     */
    function setWatchdogs(address [3] memory Watchdogs) public {
        require(msg.sender == owner,"Function accessible only to owner");
        require(lockdown==false,"contract in lockdown, please try later");
        uint i=0;
        // store state
        for(i=0;i<3;i++){
            if(Watchdogs[i]==address(0)){
                break;
            }
            watchdogs[i]=Watchdogs[i];
        }
    }
    /**
     * @dev store configuration for Watchcats
     * @param Watchcats is an array of address of the accounts allowed to lockdown the bridge when a transaction is in the pool mem
     */
    function setWatchcats(address [3] memory Watchcats) public {
        require(msg.sender == owner,"Function accessible only to owner");
        require(lockdown==false,"contract in lockdown, please try later");
        uint i=0;
        // store state
        for(i=0;i<3;i++){
            if(Watchcats[i]==address(0)){
                break;
            }
            watchcats[i]=Watchcats[i];
        }
    }
    /**
     * @dev store configuration of the minimum threshold to reach a consensus on the transaction
     * @param Threshold is the minimum number of "votes" from Keepers to execute a transaction
     */
    function setThreshold(uint8 Threshold) public {
        require(msg.sender == owner,"Function accessible only to owner");
        threshold=Threshold;
    }
    /**
     * @dev store configuration of the  withdrawal fees
     * @param Withdrawalfees is the minimum number of "votes" from Keepers to execute a transaction
     */
    function setWithDrawalFews(uint256 Withdrawalfees) public {
        require(msg.sender == owner,"Function accessible only to owner");
        withdrawalfees=Withdrawalfees;
    }
    /**
     * @dev store configuration of the minimum withdrawal fees
     * @param Minimumwithdrawalfees is the minimum number of "votes" from Keepers to execute a transaction
     */
    function setMinimumWithDrawalFees(uint256 Minimumwithdrawalfees) public {
        require(msg.sender == owner,"Function accessible only to owner");
        minimumwithdrawalfees=Minimumwithdrawalfees;
    }
    /**
     * @dev transfer ownership
     * @param newOwner is the address wished as new owner
     */
    function transferOwnership(address payable newOwner) public {
        require(msg.sender == owner);
        require(lockdown==false,"contract in lockdown, please try later");
        owner = newOwner;
    }
    // functiont to receive deposit of native token
    function deposit() public payable {}

    //function to send back the balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    /**
     * @dev transfer native tokens to a recipient
      * @param txid is the transaction id, it should be unique
     * @param recipient is a payable address
     * @param amount is a payable address
     * @param erc20 is the address of the erc20 contract (optional)
     */
    function transfer(bytes32 txid,address payable recipient, uint amount,address payable erc20) public {
        // check for lockdown
        require(lockdown==false,"contract in lockdown, please try later");
        require(txqueue[txid].cnt<threshold,"Transction already executed");    // save gas fees once the consensus is reached
        bool execute=false;
        uint8 i;
        // check for keepers
        for(i=0;i<10;i++) {
            if(keepers[i]==msg.sender){
                execute=true;
                break;
            }
        }
        require(execute==true,"Only Keepers account can access this function");
        // check for duplicated voting from the same Keepers
        require(txvotes[txid][msg.sender]==false,"D0001 - Transaction already voted from the same keepers - Possible ATTACK");
        // check for matching data of the transaction
        require(txid.length>0,"tx id is required");
        require(txqueue[txid].recipient==address(0) || txqueue[txid].recipient==recipient,"D0002 - Recipient is wrong - Possible ATTACK");
        require(recipient!=address(0),"Recipient cannot be empty");
        require(amount>0,"Amount cannot be zero");
        uint256 wdf=0;
        if(withdrawalfees>0){
            wdf=amount*withdrawalfees/100000000000000000000;
            if (wdf<minimumwithdrawalfees) {
                wdf=minimumwithdrawalfees;
            }
            //reduce the amount of withdrawalfees
            amount=amount-wdf;
        }
        // update the queue
        if(txqueue[txid].recipient==address(0)){
            // increase balance of the withdrawalfees
            if(wdf>0){
                balancewithdrawalfees=balancewithdrawalfees+wdf;
            }
            txqueue[txid].recipient=recipient;
            txqueue[txid].amount=amount;
            txqueue[txid].erc20=erc20;
        }else{
            // check for matching data inside the queue
            require(txqueue[txid].amount==amount,"D0003 - Amount is not matching - Possible ATTACK");
            require(txqueue[txid].erc20==erc20,"D0004 - Erc20 address is not matching - Possible ATTACK");
        }
        txqueue[txid].cnt++;
        // update txvote log
        txvotes[txid][msg.sender]==true;
        // make the transaction
        if(txqueue[txid].cnt==threshold) {
            // native token
            if(erc20==address(0)){
                (bool success, ) =recipient.call{value: amount}("");
                require(success, "Failed to send native tokens");
            }else {
                  // erc20 token
                  IERC20(erc20).transferFrom(owner, recipient, amount);
            }
        }
    }
    /**
     * @dev set lockdown of the operation, enabled for watchdogs, watchcats and owner
     */
    function setLockdown() public {
        bool execute=false;
        // check for owner
        if (msg.sender == owner){
            execute=true;
        }
        uint8 i;
        // check for watchdogs
        for(i=0;i<3;i++) {
            if(watchdogs[i]==msg.sender){
                execute=true;
            }
        }
        // check for watchcats
        for(i=0;i<3;i++) {
            if(watchcats[i]==msg.sender){
                execute=true;
            }
        }
        require(execute==true,"Function accessible only to owner, watchdogs and watchcats");
        lockdown=true;
    }
    /**
     * @dev unset lockdown of the operation, enabled for owner only
     */
    function unsetLockdown() public {
        // check for owner
        require (msg.sender == owner,"Function accessible only to owner");
        // unset the lockdown 
        lockdown=false;
    }
    /**
     * @dev return the status of the lookdown true/false
     */
    function getLockdown() public view returns(bool){
        return lockdown;
    }
    /**
     * @dev return the threshold configured for the voting of the transactions
     */
    function getThreshold() public view returns(uint8){
        return threshold;
    }
    /**
     * @dev return the Keepers Addresses configured
     */
    function getKeepers() public view returns(address[10] memory){
        return keepers ;
    }
    /**
     * @dev return the Watchdogs Addressesconfigured
     */
    function getWatchdogs() public view returns(address[3] memory){
        return watchdogs ;
    }
    /**
     * @dev return the Watchdogs Addressesconfigured
     */
    function getWatchcats() public view returns(address[3] memory){
        return watchcats ;
    }
    /**
     * @dev return the configured withdrawalfees
     */
    function getWithdrawalFees() public view returns(uint256){
        return withdrawalfees;
    }
    /**
     * @dev return the configured minimumwithdrawalfees
     */
    function getMinimumWithdrawalFees() public view returns(uint256){
        return minimumwithdrawalfees;
    }
    /**
     * @dev return the configured minimumwithdrawalfees
     */
    function getBalanceWithdrawalFees() public view returns(uint256){
        return balancewithdrawalfees;
    }

}
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