/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^ 0.6 .2;
interface IERC20 {
	function totalSupply() external view returns(uint256);

	function balanceOf(address account) external view returns(uint256);

	function transfer(address recipient, uint256 amount) external returns(bool);

	function allowance(address owner, address spender) external view returns(uint256);

	function approve(address spender, uint256 amount) external returns(bool);

	function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^ 0.6 .2;
library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;
		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns(uint256) {
		// benefit is lost if 'b' is also tested.
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns(uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}
pragma solidity ^ 0.6 .2;
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		(bool success, ) = recipient.call {
			value: amount
		}("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	function functionCall(address target, bytes memory data) internal returns(bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns(bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns(bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns(bytes memory) {
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) = target.call {
			value: weiValue
		}(data);
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
pragma solidity ^ 0.6 .2;
library SafeERC20 {
	using SafeMath
	for uint256;
	using Address
	for address;

	function safeTransfer(IERC20 token, address to, uint256 value) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}

	function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
	}

	function safeApprove(IERC20 token, address spender, uint256 value) internal {
		// or when resetting it to zero. To increase and decrease it, use
		// solhint-disable-next-line max-line-length
		require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
	}

	function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
		uint256 newAllowance = token.allowance(address(this), spender).add(value);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}

	function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
		uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}

	function _callOptionalReturn(IERC20 token, bytes memory data) private {
		// we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
		bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
		if (returndata.length > 0) { // Return data is optional
			require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
		}
	}
}
pragma solidity ^ 0.6 .2;
abstract contract Context {
	function _msgSender() internal view virtual returns(address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}
pragma solidity ^ 0.6 .2;
contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor() internal {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns(address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}


pragma solidity 0.6 .2;
contract KindGoldFarm is Ownable {
	using SafeMath
	for uint256;
	using SafeERC20
	for IERC20;
	
	
	struct UserInfo {
		uint256 amount; 
		uint256 rewardDebt;  
		uint256 release_block;
	}
	struct PoolInfo {
	    IERC20  tokenStaking;     
	 
		uint256 fee_percent_s;
		uint256 startBlock;       
		uint256 accPerShare;
		uint256 totalLP;
		uint256 rewardPerBlock;
		uint256 lastRewardBlock;
		uint256 lock_deposit_block;
	}
    IERC20 tokenRewardGlobal;
     uint256 rewardAvailable = 0;
     
    constructor(IERC20 reward ) public {
	    tokenRewardGlobal = reward;
	    UpdaterAddress    = address(msg.sender);

	}
	
	address UpdaterAddress;
	  
 
	
	PoolInfo[] public poolInfo;
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);


	function poolLength() external view returns(uint256) {
		return poolInfo.length;
	}
	
	 
		
	function RewardAvailable() external view returns(uint256) {
		return rewardAvailable;
	}
	
	function add(IERC20 _tokenStaking,uint256 _fee_percent_staking,uint256 _rewardPerBlock ,uint256 _lock_deposit) public onlyOwner {
	  
		poolInfo.push(PoolInfo({
		        tokenStaking   : _tokenStaking,
				fee_percent_s    : _fee_percent_staking,
				startBlock     : block.number,
				accPerShare    : 0,
				totalLP        : 0,
				rewardPerBlock : _rewardPerBlock,
				lastRewardBlock: 0,
				lock_deposit_block : _lock_deposit
			}));
			
		 
		
	}
	 
	function pendingReward(uint256 _pid, address _user) external view returns(uint256) {
	    
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_user];
		uint256 accPerShare   = pool.accPerShare;
		uint256 lpSupply      = pool.totalLP; 
		uint256 rPerBlock     = pool.rewardPerBlock;
		uint256 lastRewardBloc= pool.lastRewardBlock;
		uint256 curentBlock   = block.number;
		
	
		if (curentBlock > pool.lastRewardBlock && lpSupply != 0) {
			uint256 multiplier  =  curentBlock.sub(lastRewardBloc);
		    uint256 tokenReward =  multiplier.mul(rPerBlock);
		        	accPerShare =  accPerShare.add(tokenReward.mul(1e30).div(lpSupply));
		}
		
	   return user.amount.mul(accPerShare).div(1e30).sub(user.rewardDebt);
		
	} 
	
		function remainingBlock(uint256 _pid, address _user) external view returns(uint256) {
		UserInfo storage user = userInfo[_pid][_user];
		uint256 remaining = 0;
		if(user.release_block > block.number) remaining = user.release_block - block.number;
		
	    return remaining;
		
	} 
	

	function updatePool(uint256 _pid) public {
	    
		PoolInfo storage pool = poolInfo[_pid];
	    uint256 rPerBlock = pool.rewardPerBlock;
		if (block.number <= pool.lastRewardBlock) {
			return;
		}
		
		uint256 lpSupply = pool.totalLP; 
		if (lpSupply == 0) {
			pool.lastRewardBlock = block.number;
			return;
		}
		
		
	 
		uint256 lastRewardBloc = pool.lastRewardBlock;
	  	uint256 curentBlock = block.number;
	    uint256 multiplier =  curentBlock.sub(lastRewardBloc);
	    uint256 tokenReward =  multiplier.mul(rPerBlock);
	    
	 
		pool.accPerShare     = pool.accPerShare.add(tokenReward.mul(1e30).div(lpSupply));
		pool.lastRewardBlock = block.number;
	}
	
	

 
	function deposit(uint256 _pid, uint256 _amount) public {
	    
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		
		uint256 amount_after_fee = _amount;
		uint256 fee_deposit      = 0;
		if(pool.fee_percent_s>0&&_amount>0){
		   fee_deposit = _amount.mul(pool.fee_percent_s).div(100);
		   if(fee_deposit == 0 ) return;
		}
		amount_after_fee = _amount.sub(fee_deposit);
		 
		updatePool(_pid);
		
		if (user.amount > 0) {
			uint256 pending = user.amount.mul(pool.accPerShare).div(1e30).sub(user.rewardDebt);
			tokenRewardGlobal.safeTransfer(address(msg.sender), pending);
			rewardAvailable=rewardAvailable.sub(pending);
		}
		
		if (_amount > 0) {
			pool.tokenStaking.safeTransferFrom(address(msg.sender), address(this), _amount);
			user.amount  = user.amount.add(amount_after_fee);
			pool.totalLP = pool.totalLP.add(amount_after_fee);
			user.release_block = block.number.add(pool.lock_deposit_block);
		}
		
		user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e30);
		
		emit Deposit(msg.sender, _pid, _amount);
		
	}

	function withdraw(uint256 _pid, uint256 _amount) public {
	    
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		require(user.amount   >= _amount, "withdraw: not good");
		require(_amount > 0, "withdraw: Must > 0");
		
		
        
        if(_amount > 0)
        if(user.release_block <= block.number){
         
        updatePool(_pid);
		uint256 pending = user.amount.mul(pool.accPerShare).div(1e30).sub(user.rewardDebt);
		require(rewardAvailable >= pending, "Not enough reward");
		tokenRewardGlobal.safeTransfer(address(msg.sender), pending);
		rewardAvailable=rewardAvailable.sub(pending);
		
		
		user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e30);  
		user.amount     = user.amount.sub(_amount);
		pool.tokenStaking.safeTransfer(address(msg.sender), _amount);
		pool.totalLP = pool.totalLP.sub(_amount);
		emit Withdraw(msg.sender, _pid, _amount);
        }
		
		
	}


	function depositReward( uint256 _amount) public {
	
	 
		if (_amount > 0) {
		    
		 uint256 amount_after_fee = _amount.sub(_amount.div(100));
		 tokenRewardGlobal.safeTransferFrom(address(msg.sender), address(this), _amount);
		 rewardAvailable  =  rewardAvailable.add(amount_after_fee);
		   
		}
		
		emit Deposit(msg.sender, 0, _amount);
	}
	
	
	function update_RewardPerBlock( uint256 _pid,uint256 _amount) public  {
		    
		if(address(msg.sender) == UpdaterAddress ){
		PoolInfo storage pool = poolInfo[_pid];
		pool.rewardPerBlock = _amount;
		}
	 
		
	}
	
	function update_Updater(address _addr) public onlyOwner {
		 UpdaterAddress = _addr;
	    }
	
	
	
	function balanceLP(uint256 _pid, address _user) external view returns(uint256) {
	    
		UserInfo storage user = userInfo[_pid][_user];
		return user.amount;
		
	}

	function massUpdatePools() public {
	    
		uint256 length = poolInfo.length;
		for (uint256 pid = 0; pid < length; pid++) {
			updatePool(pid);
		}
		
	}
	
	function emergencyWithdraw(uint256 _pid) public {
	    
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		
		if(user.release_block <= block.number){
		 pool.tokenStaking.safeTransfer(address(msg.sender), user.amount);
		 user.amount = 0;
		 user.rewardDebt = 0;
		 emit EmergencyWithdraw(msg.sender, _pid, user.amount);
		}
		
	
		
	}
 
 
   
 
}