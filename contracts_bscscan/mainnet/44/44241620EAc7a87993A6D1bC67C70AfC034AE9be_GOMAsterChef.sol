/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

/** 

      /$$$$$$   /$$$$$$  /$$      /$$  /$$$$$$              /$$                          /$$$$$$  /$$                  /$$$$$$ 
     /$$__  $$ /$$__  $$| $$$    /$$$ /$$__  $$            | $$                         /$$__  $$| $$                 /$$__  $$
    | $$  \__/| $$  \ $$| $$$$  /$$$$| $$  \ $$  /$$$$$$$ /$$$$$$    /$$$$$$   /$$$$$$ | $$  \__/| $$$$$$$   /$$$$$$ | $$  \__/
    | $$ /$$$$| $$  | $$| $$ $$/$$ $$| $$$$$$$$ /$$_____/|_  $$_/   /$$__  $$ /$$__  $$| $$      | $$__  $$ /$$__  $$| $$$$    
    | $$|_  $$| $$  | $$| $$  $$$| $$| $$__  $$|  $$$$$$   | $$    | $$$$$$$$| $$  \__/| $$      | $$  \ $$| $$$$$$$$| $$_/    
    | $$  \ $$| $$  | $$| $$\  $ | $$| $$  | $$ \____  $$  | $$ /$$| $$_____/| $$      | $$    $$| $$  | $$| $$_____/| $$      
    |  $$$$$$/|  $$$$$$/| $$ \/  | $$| $$  | $$ /$$$$$$$/  |  $$$$/|  $$$$$$$| $$      |  $$$$$$/| $$  | $$|  $$$$$$$| $$      
     \______/  \______/ |__/     |__/|__/  |__/|_______/    \___/   \_______/|__/       \______/ |__/  |__/ \_______/|__/     
     
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
}

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

contract GOMAsterChef is Ownable {
    using SafeBEP20 for IBEP20;
    
    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt; 
    }

    uint256 public lastRewardTimestamp;
    uint256 public accRewardTokensPerShare;
    uint256 public claimedRewardTokens;

    IBEP20 public immutable rewardToken;
    IBEP20 public immutable stakedToken;
    address private immutable stakedTokenOwner;
    uint256 public stakedTokenDeposied;

    uint256 public immutable minTokensPerSecond;
    uint256 public immutable maxTokensPerSecond;
    uint256 public tokensPerSecond;
    uint256 public minDepositAmount;
	
    uint256 private immutable taxPercent;
    	
    mapping (address => UserInfo) public userInfo;
    
    uint256 public immutable startTimestamp;
    uint256 public pausedTimestamp;
    bool public productionMode = false;
    uint256 public reflectionMultiplier;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
	event Supply(address indexed user, uint256 amount);
	
    constructor() {
        stakedToken = IBEP20(0xAb14952d2902343fde7c65D7dC095e5c8bE86920); // GOMA
        rewardToken = IBEP20(0x6ffBc66A1A6f6a96cc4345db0729451D0F05E0ad); // AGR
        stakedTokenOwner = 0x21eFFbef01c8f269D9BAA6e0151A54D793113b45;
        
        minTokensPerSecond = 100000000000000;
        maxTokensPerSecond = 1000000000000000000000;
        tokensPerSecond =    100000000000000000;
        
        startTimestamp = blockTimestamp();
        lastRewardTimestamp = blockTimestamp();
        
        taxPercent = 800; // 8%
        
        minDepositAmount = 1000000000 * 10**9; // 1000000000000000000
        reflectionMultiplier = 1e18; // 1000000000000000000
    }

    
    //
    function setRewardTokensPerSecond(uint256 _tokensPerSecond) external onlyOwner {
        require(pausedTimestamp == 0, "setTokensPerSecond: you can't set while paused!");        
        require(_tokensPerSecond >= minTokensPerSecond, "setTokensPerSecond: too low tokens, see minTokensPerSecond!");
		require(_tokensPerSecond <= maxTokensPerSecond, "setTokensPerSecond: too many tokens, see maxTokensPerSecond!");

        _updatePool(); 

        tokensPerSecond = _tokensPerSecond;
    }
    
    // 
    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        require(_minDepositAmount >= 1000000000000000000, "setMinDepositAmount: 1000000000000000000 is minimum!");

        minDepositAmount = _minDepositAmount;
    }

	// 
    function pauseOn() external onlyOwner {
		require(pausedTimestamp == 0, "pause: already paused!");		
		pausedTimestamp = blockTimestamp();
    }

	// 
    function pauseOff() external onlyOwner {
		require(pausedTimestamp != 0, "resume: not paused!");
		_updatePool();
		pausedTimestamp = 0;	
    }

    // Return reward multiplier over the given _from to _to block Timestamp
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
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
    
    // 
    function getMultiplierNow() public view returns (uint256) {
        return getMultiplier(lastRewardTimestamp, blockTimestamp());
    }
    
    // 
    function pendingRewardsOfSender() public view returns (uint256, uint256) {
        return pendingRewardsOfUser(msg.sender);
    }

    // 
    function pendingRewardsOfUser(address _user) public view returns (uint256 real, uint256 reflection) {
        UserInfo storage user = userInfo[_user];
        uint256 _mul = getMultiplierNow();
        if (_mul == 0) {
            _mul = 1;
        } 
                
		if (stakedTokenDeposied != 0 && user.amount != 0) {
            uint256 _accRewardTokensPerShare = accRewardTokensPerShare + (_mul * tokensPerSecond * reflectionMultiplier);
            reflection = user.amount * _accRewardTokensPerShare / stakedTokenDeposied;
            if (reflection >= user.rewardDebt) {
                reflection = reflection - user.rewardDebt;
            } else {
                reflection = 0;
            }
            real = reflection / reflectionMultiplier;            
		}
        
        return (real, reflection);            
    }

    //
    function pendingRewardsAll() public view returns (uint256) {
        if (stakedTokenDeposied != 0) {
            uint256 _mul = getMultiplierNow();
            if (_mul == 0) {
                _mul = 1;
            }             
            return (accRewardTokensPerShare / reflectionMultiplier + (_mul * tokensPerSecond)) - claimedRewardTokens;
        }
        return 0;
    }

    //
    function getPending(UserInfo storage user) internal view returns (uint256) {
        uint256 pendingReflection = user.amount * accRewardTokensPerShare / stakedTokenDeposied;
        if (pendingReflection >= user.rewardDebt) {
            pendingReflection = pendingReflection - user.rewardDebt;
        } else {
            pendingReflection = 0;
        }

        return pendingReflection / reflectionMultiplier;
    }

    //   
    function userInfoOfSender() public view returns (uint256, uint256) {
		return (
            userInfo[msg.sender].amount, 
            userInfo[msg.sender].rewardDebt
        );
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        require(pausedTimestamp == 0, "updatePool: you can't update while paused!");
        _updatePool();
    }
    
    // Update reward variables of the given pool to be up-to-date.
    function _updatePool() internal {        
        if (blockTimestamp() <= lastRewardTimestamp) {
            return;
        }
        
		if (stakedTokenDeposied == 0) {
            lastRewardTimestamp = blockTimestamp();
            return;
        }

        accRewardTokensPerShare = accRewardTokensPerShare + (getMultiplierNow() * tokensPerSecond * reflectionMultiplier);
        lastRewardTimestamp = blockTimestamp();
    }

    // 
    function deposit(uint256 _amount) public {
		require(pausedTimestamp == 0, "deposit: you can't deposit while paused!");
        require(_amount >= minDepositAmount, "deposit: you can't deposit less than minDepositAmount of wei!");

        UserInfo storage user = userInfo[msg.sender];

        _updatePool();
                
        if (stakedTokenDeposied !=0) {
            uint256 pending = getPending(user);
            if (pending != 0) {
                claimedRewardTokens = claimedRewardTokens + pending;
                safeRewardTransfer(msg.sender, pending);
            }
        }
                
        uint256 finalAmount;
        if (msg.sender == stakedTokenOwner) {
            finalAmount = _amount;    
        } else {
            finalAmount = _amount - (_amount * taxPercent / 10000);
        }

        stakedTokenDeposied = stakedTokenDeposied + finalAmount;
        
        user.amount = user.amount + finalAmount;
        user.rewardDebt = user.amount * accRewardTokensPerShare / stakedTokenDeposied;
        
        stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, finalAmount);
    }

    // Withdraw staked tokens
    function withdraw(uint256 _amount) public {  
		require(pausedTimestamp == 0, "withdraw: you can't withdraw while paused!");
        require(_amount != 0, "withdraw: you can't withdraw 0!");
        
        UserInfo storage user = userInfo[msg.sender];
        
        require(user.amount >= _amount, "withdraw: not enough funds");

        _updatePool();

        uint256 pending = getPending(user);
        if (pending != 0) {
            claimedRewardTokens = claimedRewardTokens + pending;
            safeRewardTransfer(msg.sender, pending);
        }

        stakedTokenDeposied = stakedTokenDeposied - _amount;
        
        user.amount = user.amount - _amount;     
        
        if (stakedTokenDeposied != 0) {            
            user.rewardDebt = user.amount * accRewardTokensPerShare / stakedTokenDeposied;
        } else {
            user.rewardDebt = 0;
        }
        
        stakedToken.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }
    
    // Withdraw reward tokens
    function claim() public {  
		require(pausedTimestamp == 0, "claim: you can't claim while paused!");

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount != 0, "claim: user deposited 0");
        
        _updatePool();
        
        uint256 pending = getPending(user); 
        require(pending != 0, "claim: nothing to claim");

        user.rewardDebt = user.amount * accRewardTokensPerShare / stakedTokenDeposied;

        claimedRewardTokens = claimedRewardTokens + pending;
        safeRewardTransfer(msg.sender, pending);
        emit Claim(msg.sender, pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function withdrawEmergency() public {
        UserInfo storage user = userInfo[msg.sender];

        uint256 userAmount = user.amount;
        require(userAmount != 0, "emergencyWithdraw: nothing to withdraw");
        
        user.amount = 0;
        user.rewardDebt = 0;

        stakedToken.safeTransfer(msg.sender, userAmount);
        
        stakedTokenDeposied = stakedTokenDeposied - userAmount;
        
        emit EmergencyWithdraw(msg.sender, userAmount);
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
    
    // 
    function supplyRewardTokens(uint256 _amount) public {
		rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Supply(msg.sender, _amount);
    }
    
    // 
    function supplyStakedTokens(uint256 _amount) public {
		stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Supply(msg.sender, _amount);
    }
        
    // only in test mode
    function startProductionMode() external onlyOwner {
        require(productionMode == false, "startProductionMode: already stared");
        productionMode = true;
        _updatePool();
		pausedTimestamp = 0;
    }
        
    // only in test mode
    function withdrawAllStakedTokens() external onlyOwner {
        require(productionMode == false, "withdrawAllStakedTokens: allowed only in test mode");
        require(balanceOfStakedToken() != 0, "withdrawAllStakedTokens: nothing to withdraw");
        stakedToken.safeTransfer(msg.sender, balanceOfStakedToken());
    }
    
    // 
    function withdrawStakedRewards() external onlyOwner {
        require(balanceOfStakedToken() > stakedTokenDeposied, "withdrawStakedRewards: nothing to withdraw");
        uint256 amount = balanceOfStakedToken() - stakedTokenDeposied;
        stakedToken.safeTransfer(msg.sender, amount);
    }

    // 
    function withdrawRewardTokens(uint256 _amount) external onlyOwner {
        require(balanceOfRewardToken() >= _amount, "withdrawRewardTokens: nothing to withdraw");
        safeRewardTransfer(msg.sender, _amount);
    }
    
    //
    function balanceOfRewardToken() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
    
    //
    function balanceOfStakedToken() public view returns (uint256) {
        return stakedToken.balanceOf(address(this));
    }
    
    //
    function blockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
     
}