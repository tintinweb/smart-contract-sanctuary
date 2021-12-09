/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
// ----------------------------------------------- Context --------------------------------------------------
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// ----------------------------------------------- Ownable --------------------------------------------------
contract Ownable is Context {
    address _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
// ----------------------------------------------- IBEP20 ---------------------------------------------------
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
    function mintTo(address recipient, uint256 amount) external;
}
// ----------------------------------------------- Address --------------------------------------------------
library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
   
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
	
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
// --------------------------------------------- SafeBEP20 --------------------------------------------------
library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}
// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------- Staker ---------------------------------------------------
// ----------------------------------------------------------------------------------------------------------
contract Staker is Ownable {
    using SafeBEP20 for IBEP20;
    
    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt; 
    }

    uint256 public lastRewardTimestamp;
    uint256 public accRewardTokensPerShare;
    uint256 public claimedRewardTokens;

    IBEP20 public rewardToken;
    IBEP20 public immutable stakedToken;
    
    uint256 public stakedTokenDeposied;

    uint256 public immutable minTokensPerSecond;
    uint256 public immutable maxTokensPerSecond;
    uint256 public tokensPerSecond;
    uint256 public minDepositAmount;
	
    uint256 public taxPercent;
    address public taxWallet;
    	
    mapping (address => UserInfo) public userInfo;
    mapping (address => bool) public taxExcludedList;
    
    uint256 public startTimestamp;
    uint256 public pausedTimestamp;
    bool public productionMode;
    bool public mintingRewardTokensEnabled;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
	event Supply(address indexed user, uint256 amount);

    modifier onlyStarted() {
        require(startTimestamp != 0, 'Staker: not started');
        _;
    }
	
    constructor() {
        stakedToken = IBEP20(0x1600429B8F8c037521fed986C8FfA88685Cf28FA); // INFE
        rewardToken = IBEP20(0xb2D088DC162F2036289b3FE6884b690FC6cDC57E); // DNATE 
        
        minTokensPerSecond = 1000000000;
        maxTokensPerSecond = 100000000000000000000; 
        tokensPerSecond = 25000000000000000;
                
        taxPercent = 100; // 1% 
        
        minDepositAmount = 100; 
        
        productionMode = false;
        mintingRewardTokensEnabled = true;
        
        _owner = msg.sender;
        taxExcludedList[_owner] = true;
        taxWallet = _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
   	    _owner = newOwner;
		taxExcludedList[_owner] = true;
		taxWallet = _owner;
		
        _transferOwnership(newOwner);
    }
    
    function getData() public view returns (
        uint256, // stakedTokenDeposied
        uint256, // tokensPerSecond
        uint256, // taxPercent
        uint256, // minDepositAmount
        uint256, // startTimestamp
        uint256, // pausedTimestamp
        address, // address(stakedToken)
        uint8, // stakedToken.decimals()
        string memory,  // stakedToken.symbol()
        address, // address(rewardToken)
        uint8, // rewardToken.decimals()
        string memory  // rewardToken.symbol()
        ){
		return ( 
		    stakedTokenDeposied,  
		    tokensPerSecond,  
		    taxPercent, 
		    minDepositAmount,
		    startTimestamp, 
		    pausedTimestamp, 
		    address(stakedToken),
		    stakedToken.decimals(),  
		    stakedToken.symbol(),  
		    address(rewardToken),
		    rewardToken.decimals(),
		    rewardToken.symbol()  
		);
    }
    
    function getUserData(address account) public view returns (        
        uint256,  // pendingRewards
        uint256,  // depositedAmount
        uint256,  // balance of stake tokens
        uint256,  // allowance of stake tokens
        uint256   // balance of reward tokens
        ){
        (uint256 pendingRewards,) = pendingRewardsOfUser(account);
		return ( 
		    pendingRewards, 
		    userInfo[account].amount,
		    stakedToken.balanceOf(account),
		    stakedToken.allowance(account, address(this)),
		    rewardToken.balanceOf(account)
		);
    }
    
    function setRewardTokensPerSecond(uint256 _tokensPerSecond) external onlyOwner {
        require(pausedTimestamp == 0, "Staker setTokensPerSecond: you can't set while paused!");        
		require(_tokensPerSecond <= maxTokensPerSecond, "Staker setTokensPerSecond: too many tokens, see maxTokensPerSecond!");

        _updatePool(); 

        tokensPerSecond = _tokensPerSecond;
    }
    
    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        require(_minDepositAmount >= 100, "Staker setMinDepositAmount: 1000000000000000 wei is minimum!");
        minDepositAmount = _minDepositAmount;
    }

	function pauseOn() external onlyOwner onlyStarted{
		require(pausedTimestamp == 0, "Staker pause: already paused!");		
		pausedTimestamp = blockTimestamp();
    }

	function pauseOff() external onlyOwner onlyStarted{
		require(pausedTimestamp != 0, "Staker resume: not paused!");
		_updatePool();
		pausedTimestamp = 0;	
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
		if (startTimestamp == 0) return 0;

        _from = _from > startTimestamp ? _from : startTimestamp;
        if (_to < startTimestamp) {
            return 0;
        }

		if (pausedTimestamp != 0) {
			return _to - (_from + blockTimestamp() - pausedTimestamp);      
		} else {
			return _to - _from;
		}        
    }
    
    function getMultiplierNow() public view returns (uint256) {
        return getMultiplier(lastRewardTimestamp, blockTimestamp());
    }
    
    function pendingRewardsOfSender() public view returns (uint256, uint256) {
        return pendingRewardsOfUser(msg.sender);
    }

    function pendingRewardsOfUser(address _user) public view returns (uint256 real, uint256 reflection) { // reflection - legasy (
        UserInfo storage user = userInfo[_user];       
        uint256 _accRewardTokensPerShare = accRewardTokensPerShare;      
		
		if (stakedTokenDeposied != 0 && user.amount != 0 && blockTimestamp() > lastRewardTimestamp) {
            _accRewardTokensPerShare = accRewardTokensPerShare + ((getMultiplierNow() * tokensPerSecond) * 1e12 / stakedTokenDeposied);
        }

        uint256 pending = (user.amount * _accRewardTokensPerShare) / 1e12;
        if (pending > user.rewardDebt) {
            real = pending - user.rewardDebt;
        } else {
            real = 0;
        }
		        
        return (real, reflection); 
    }

    function getPending(UserInfo storage user) internal view returns (uint256) {
        uint256 pending = ((user.amount * accRewardTokensPerShare) / 1e12);
        if (pending > user.rewardDebt) {
            return pending - user.rewardDebt;
        } else {
            return 0;
        }
    }

    function userInfoOfSender() public view returns (uint256, uint256) {
		return (
            userInfo[msg.sender].amount, 
            userInfo[msg.sender].rewardDebt
        );
    }

    function updatePool() public onlyStarted {
        require(pausedTimestamp == 0, "Staker updatePool: you can't update while paused!");
        _updatePool();
    }
    
    function _updatePool() internal {        
        if (blockTimestamp() <= lastRewardTimestamp) {
            return;
        }
        
		if (stakedTokenDeposied == 0) {
            lastRewardTimestamp = blockTimestamp();
            return;
        }
        
        uint256 tokensReward = getMultiplierNow() * tokensPerSecond;
        
        if (mintingRewardTokensEnabled) {
            rewardToken.mintTo(address(this), tokensReward);
        }
        
        accRewardTokensPerShare = accRewardTokensPerShare + (tokensReward * 1e12 / stakedTokenDeposied);
        lastRewardTimestamp = blockTimestamp();
    }

    function deposit(uint256 _amount) public onlyStarted {
		require(pausedTimestamp == 0, "Staker deposit: you can't deposit while paused!");
        require(_amount>=minDepositAmount*18,"Amount Less Than Minimum Deposite Amount");
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();
                
        if (stakedTokenDeposied !=0) {
            uint256 pending = getPending(user);
            if (pending != 0) {
                claimedRewardTokens = claimedRewardTokens + pending;
                safeRewardTransfer(msg.sender, pending);
            }
        }
        
        stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
                
        uint256 finalAmount = _amount;
        if (taxPercent != 0 && !taxExcludedList[msg.sender]) {
            uint256 taxAmount = _amount * taxPercent / 10000;
            finalAmount = _amount - taxAmount;
            
            stakedToken.safeTransfer(taxWallet, taxAmount);
        }

        stakedTokenDeposied = stakedTokenDeposied + finalAmount;
        
        user.amount = user.amount + finalAmount;
        user.rewardDebt = (user.amount * accRewardTokensPerShare) / 1e12;
        
        emit Deposit(msg.sender, finalAmount);
    }

    function start() external onlyOwner {		
        require(startTimestamp == 0, "Staker start: already started");
        startTimestamp = blockTimestamp();
        lastRewardTimestamp = blockTimestamp();
    }

    function migrateUsers(address[] memory users, uint256[] memory amounts) external onlyOwner {
        uint8 cnt = uint8(users.length);
        require(cnt > 0 && cnt <= 255, 'Staker migrateUsers: number or recipients must be more then 0 and not much than 255');
        require(users.length == amounts.length, 'Staker migrateUsers: number or recipients must be equal to number of amounts');
        for ( uint i = 0; i < cnt; i++ ){
			userInfo[users[i]].amount = userInfo[users[i]].amount + amounts[i];
            stakedTokenDeposied = stakedTokenDeposied + amounts[i];
        }
    }

    // Withdraw staked tokens
    function withdraw(uint256 _amount) public onlyStarted {          
		require(pausedTimestamp == 0, "Staker withdraw: you can't withdraw while paused!");
        require(_amount != 0, "Staker withdraw: you can't withdraw 0!");
                
        UserInfo storage user = userInfo[msg.sender];        
        require(user.amount >= _amount, "Staker withdraw: not enough funds");
        
        _updatePool();

        uint256 pending = getPending(user);
        if (pending != 0) {
            claimedRewardTokens = claimedRewardTokens + pending;
            safeRewardTransfer(msg.sender, pending);
        }
        
        uint256 finalAmount = _amount;

        if ((user.amount - _amount) < minDepositAmount) {
            finalAmount = user.amount;
            user.amount = 0;
            user.rewardDebt = 0;
        } else {
            user.amount = user.amount - _amount;
            user.rewardDebt = (user.amount * accRewardTokensPerShare) / 1e12;
        } 
        
        stakedTokenDeposied = stakedTokenDeposied - finalAmount; 

        stakedToken.safeTransfer(msg.sender, finalAmount);
        emit Withdraw(msg.sender, finalAmount);
    }
    
    // Withdraw reward tokens
    function claim() public onlyStarted{  
		require(pausedTimestamp == 0, "Staker claim: you can't claim while paused!");

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount != 0, "Staker claim: user deposited 0");
        
        _updatePool();
        
        uint256 pending = getPending(user); 
        require(pending != 0, "Staker claim: nothing to claim");

        user.rewardDebt = (user.amount * accRewardTokensPerShare) / 1e12;

        claimedRewardTokens = claimedRewardTokens + pending;
        safeRewardTransfer(msg.sender, pending);
        emit Claim(msg.sender, pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function withdrawEmergency() public onlyStarted{
        UserInfo storage user = userInfo[msg.sender];

        uint256 userAmount = user.amount;
        require(userAmount != 0, "Staker emergencyWithdraw: nothing to withdraw");
        
        user.amount = 0;
        user.rewardDebt = 0;

        stakedToken.safeTransfer(msg.sender, userAmount);
        
        stakedTokenDeposied = stakedTokenDeposied - userAmount;
        
        emit EmergencyWithdraw(msg.sender, userAmount);
    }
    
    function setTaxPercent(uint256 newTaxPercent) external onlyOwner {
		require(newTaxPercent <= 1000, 'Staker: tax can`t be more than 1000 (10%)');
		taxPercent = newTaxPercent;	
	}
	
	function setTaxWallet(address account) external onlyOwner returns (bool) {
		taxExcludedList[account] = !taxExcludedList[account];	
		return taxExcludedList[account];
	}
	
	function toggleTaxExcluded(address account) external onlyOwner returns (bool) {
		taxExcludedList[account] = !taxExcludedList[account];	
		return taxExcludedList[account];
	}
	
	function toggleMintingRewardTokensEnabled() external onlyOwner returns (bool) {
		mintingRewardTokensEnabled = !mintingRewardTokensEnabled;	
		return mintingRewardTokensEnabled;
	}
	
    // Safe rewardToken transfer function.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = balanceOfRewardToken();
        if (_amount > tokenBal) {
            rewardToken.transfer(_to, tokenBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }
    
    function supplyRewardTokens(uint256 _amount) public {
		rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Supply(msg.sender, _amount);
    }
    
    function supplyStakedTokens(uint256 _amount) public {
		stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Supply(msg.sender, _amount);
    }
        
    function startProductionMode() external onlyOwner onlyStarted{
        require(productionMode == false, "Staker startProductionMode: already stared");
        productionMode = true;
        _updatePool();
		pausedTimestamp = 0;
    }

    function setRewardToken(address newRewardToken) external onlyOwner{
        require(pausedTimestamp != 0, "Staker setRewardToken: you can't change reward token when not paused");
        rewardToken = IBEP20(newRewardToken); 
    }
        
    function withdrawStakedTokens(uint256 _amount) external onlyOwner {
        require(!productionMode, "Staker withdrawAllStakedTokens: not allowed in production mode");
        require(balanceOfStakedToken() >= _amount, "Staker withdrawAllStakedTokens: no enough funds");
        stakedToken.safeTransfer(msg.sender, _amount);
    }
    
    function withdrawStakedRewards(uint256 _amount) external onlyOwner {
        require(balanceOfStakedToken() > stakedTokenDeposied, "Staker withdrawStakedRewards: nothing to withdraw");
        uint256 amount = balanceOfStakedToken() - stakedTokenDeposied;
        require(_amount <= amount, "Staker withdrawStakedRewards: no enough funds");
        stakedToken.safeTransfer(msg.sender, _amount);
    }

    function recoverTokens(address token, uint256 amount) external onlyOwner {
        if (productionMode) {
            require(token != address(stakedToken), "Staker recoverTokens: can't recover staked token");
            require(token != address(rewardToken), "Staker recoverTokens: can't recover reward token");
        }
        IBEP20(token).safeTransfer(msg.sender, amount);        
    }

    function withdrawRewardTokens(uint256 _amount) external onlyOwner {
        require(balanceOfRewardToken() >= _amount, "Staker withdrawRewardTokens: nothing to withdraw");
        safeRewardTransfer(msg.sender, _amount);
    }
    
    function balanceOfRewardToken() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
    
    function balanceOfStakedToken() public view returns (uint256) {
        return stakedToken.balanceOf(address(this));
    }
    
    function blockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
     
}