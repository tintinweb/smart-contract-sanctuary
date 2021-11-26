/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /* @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /* @dev Returns the amount of tokens owned by account.
     */
    function balanceOf(address account) external view returns (uint256);

    /* @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /* @dev Returns the remaining number of tokens that spender will be
     * allowed to spend on behalf of owner through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /* @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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

    /* @dev Moves amount tokens from sender to recipient using the
     * allowance mechanism. amount is then deducted from the caller's
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

    /* @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* @dev Emitted when the allowance of a spender for an owner is set by
     * a call to {approve}. value is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

  }
  
  contract TimeLock{
    
    mapping(address => uint256) LockAmount;
    mapping(address => uint256) LockTime;
    
    bool IsLocked;
    
    address LockedToken;
    
    address public owner;
    
    constructor() {
        // sets owner to msg.sender
        owner = msg.sender;
        
    }
    
    // to know if the one using the contract is the owner
    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }
    
   
    // lock tokens function is used to lock tokens. first parameter is the token which you want to lock the second parameter is the amount of time the tokens should be locked for and the third parameter is the amount of tokens to lock
    
    function LockTokens(address TokenAddress, uint256 Time,uint256 AmountToLock) public onlyOwner returns(bool){
        
        
        if(IsLocked){
            
            require(LockedToken == TokenAddress,"TimeLock: Can't lock different token");
         
            uint256 NowBalance = IERC20(TokenAddress).balanceOf(address(this));
            
            TransferHelper.safeTransferFrom(TokenAddress,msg.sender,address(this),AmountToLock);
            
            uint256 TheAmountThisContractGot = IERC20(TokenAddress).balanceOf(address(this)) - NowBalance;
            
            LockAmount[msg.sender] += TheAmountThisContractGot;
            
            LockTime[msg.sender] += Time;
            
            return(true);
        } else {
          
          uint256 BalanceNow = IERC20(TokenAddress).balanceOf(address(this));
          
          TransferHelper.safeTransferFrom(TokenAddress,msg.sender,address(this),AmountToLock);

          uint256 TheAmountThisContractGot = IERC20(TokenAddress).balanceOf(address(this)) - BalanceNow;
          
          LockTime[msg.sender] = block.timestamp + Time;
          
          LockAmount[msg.sender] = TheAmountThisContractGot;
          
          IsLocked = true;
          
          LockedToken = TokenAddress;
          
          return(true);
          
            
        }
        
        
        
    }
    
    // withdraw locked tokens if current time is greater than locked time
    
    function WithDraw() public onlyOwner{
        
        require(IsLocked,"Timelock: No Tokens are currently locked");
        
        uint256 LockedOn = LockTime[msg.sender];
        
        uint256 Now = block.timestamp;
        
        require(Now >= LockedOn,"Timelock: Not Yet");
        
        TransferHelper.safeTransfer(LockedToken,msg.sender,IERC20(LockedToken).balanceOf(address(this)));
            
        LockTime[msg.sender] = 0 ;
        
        LockAmount[msg.sender] = 0;
            
        IsLocked = false;
            
        LockedToken = address(0);
            
            
            
            
        
        
        
        
        
    }
    
    // View the time which tokens gets unlocked;
    function UnlockesOn() public view returns(uint256){
        
        return(LockTime[owner]);

    }
    
    // View the amount locked by owner
    function LockedAmount() public view returns(uint256){
        
        return(LockAmount[owner]);
        
    }
    
    
}