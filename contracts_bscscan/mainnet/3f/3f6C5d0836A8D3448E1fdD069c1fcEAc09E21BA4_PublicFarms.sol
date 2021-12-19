/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

pragma solidity ^ 0.6.2;
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
 
 
 
abstract contract Context {
	function _msgSender() internal view virtual returns(address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}
 

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


interface PANCAKEFACTORY {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


 
contract PublicFarms is Ownable {
	using SafeMath
	for uint256;
 
	 
	struct UserInfo {
		uint256 amount; 
		uint256 rewardDebt;  
		uint256 release_block;
	}
	struct PoolInfo {
	    address tokenStaking;
        address tokenContract;
        address pairContract;
        address rewardContract;   
		uint256 accPerShare;
		uint256 totalLP;
		uint256 rewardPerBlock;
		uint256 lastRewardBlock;
		uint256 lock_deposit_block;
        uint256 rewardAvailable;
	}
     
    constructor() public {
	 
	}
	

    uint256 public  MinimumRewardFarm = 1000 * 10**18;
	  
    address BUSD   = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address WBNB   = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address USDT   = 0x55d398326f99059fF775485246999027B3197955;
    address FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address KIND   = 0x7805E593FAAf00aE6870bc8e810c68d76F311B8e;
        
	PoolInfo[] public poolInfo;
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);


	function poolLength() external view returns(uint256) {
		return poolInfo.length;
	}

    function upfeecreatefarm(uint256 _amount) external  onlyOwner  {
		 MinimumRewardFarm = _amount;
	}
	
     
	 
	//Create public Farms
	function create(address tokenContract,uint256 p, uint256 amountReward ) public  {
	   address market = WBNB;

       if(MinimumRewardFarm>amountReward) return;
       if(p==0) return;
       if(p==2)market = USDT;
       if(p==3)market = BUSD;
 
        address pair   = PANCAKEFACTORY(FACTORY).getPair(tokenContract,market);
        if(pair==address(0)) return;
        //fee is 10%
        //1% is transaction tax 
        //9% is for burned
        uint256 netAmount = amountReward.sub(amountReward.div(10));
        IERC20(KIND).transferFrom(address(msg.sender), address(this),amountReward );
        IERC20(KIND).transfer(address(0),amountReward.div(100).mul(9));
        

		poolInfo.push(PoolInfo({
		  tokenStaking:pair,
          tokenContract:tokenContract,
          pairContract:market,
          rewardContract:KIND,
		  accPerShare:0,
		  totalLP:0,
		  rewardPerBlock:netAmount.div(1000000),
		  lastRewardBlock:0,
		  lock_deposit_block:100,
          rewardAvailable : netAmount

		 }));

          
			
		 
		
	}
	 
	function pendingReward(uint256 _pid, address _user) public view returns(uint256) {
	     
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
		uint256 debt = user.rewardDebt;
        uint256 rew = user.amount.mul(accPerShare).div(1e30);
        uint256 pend = 0;
        if(rew>debt) pend = rew.sub(debt);
	    return pend;
		
	} 
	

	function timelock(uint256 _pid, address _user) public view returns(uint256) {
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
        pool.rewardPerBlock = pool.rewardAvailable.div(1000000);
		uint256 lastRewardBloc = pool.lastRewardBlock;
	  	uint256 curentBlock = block.number;
	    uint256 multiplier =  curentBlock.sub(lastRewardBloc);
	    uint256 tokenReward =  multiplier.mul(rPerBlock);
		pool.accPerShare     = pool.accPerShare.add(tokenReward.mul(1e30).div(lpSupply));
		pool.lastRewardBlock = block.number;
	}
	
	

    //deposit LP
	function deposit(uint256 _pid, uint256 _amount) public {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][address(msg.sender)];
		 
         if(pool.totalLP==0){
			pool.lastRewardBlock = block.number; 
		}
	
		if (user.amount > 0) {
			uint256 pending   = pendingReward(_pid,address(msg.sender));
            uint256 remaining = timelock(_pid,address(msg.sender));
            if(pending>0&&remaining==0) {
			IERC20(pool.rewardContract).transfer(address(msg.sender), pending);
            pool.rewardAvailable=pool.rewardAvailable.sub(pending);
            user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e30);
            }
		}
		
		if (_amount > 0) {
			IERC20(pool.tokenStaking).transferFrom(address(msg.sender), address(this), _amount);
			user.amount  = user.amount.add(_amount);
			pool.totalLP = pool.totalLP.add(_amount);
			user.release_block = block.number.add(pool.lock_deposit_block);
		}


		
        updatePool(_pid);
		uint256 rew = user.amount.mul(pool.accPerShare).div(1e30);
        uint256 debt = user.rewardDebt;
        if(debt>rew) user.rewardDebt = rew;
		emit Deposit(msg.sender, _pid, _amount);
		
	}

	function withdraw(uint256 _pid, uint256 _amount) public {
	    
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][address(msg.sender)];
		require(user.amount   >= _amount, "withdraw: not good");
		require(_amount > 0, "withdraw: Must > 0");
        if(user.release_block <= block.number){
		uint256 pending = pendingReward(_pid,address(msg.sender));
	    uint256 safepending = 0;
        if(pending<=pool.rewardAvailable) safepending = pending;
        if(safepending>0){
		IERC20(pool.rewardContract).transfer(address(msg.sender), pending);
		pool.rewardAvailable=pool.rewardAvailable.sub(pending);
        }
		user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e30);  
		user.amount     = user.amount.sub(_amount);
		IERC20(pool.tokenStaking).transfer(address(msg.sender), _amount);
		pool.totalLP = pool.totalLP.sub(_amount);
		emit Withdraw(msg.sender, _pid, _amount);
        }

        updatePool(_pid);
        uint256 rew = user.amount.mul(pool.accPerShare).div(1e30);
        uint256 debt = user.rewardDebt;
        if(debt>rew) user.rewardDebt = rew;
		
		
	}


	function depositReward(uint256 _pid, uint256 amountReward) public {
        PoolInfo storage pool = poolInfo[_pid];
	    if (amountReward > 0) {
		uint256 netAmount = amountReward.sub(amountReward.div(10));
        IERC20(pool.rewardContract).transferFrom(address(msg.sender), address(this),amountReward );
        IERC20(pool.rewardContract).transfer(address(0),amountReward.div(100).mul(9));
		pool.rewardAvailable  =  pool.rewardAvailable.add(netAmount);
		   
		}
	 
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
		UserInfo storage user = userInfo[_pid][address(msg.sender)];
		if(user.release_block <= block.number){
		 IERC20(pool.tokenStaking).transfer(address(msg.sender), user.amount);
         pool.totalLP = pool.totalLP.sub(user.amount);
         user.amount = 0;
		 user.rewardDebt = 0;
		 emit EmergencyWithdraw(msg.sender, _pid, user.amount);
         updatePool(_pid);
		}
		
	
		
	}
 
 
   
 
}