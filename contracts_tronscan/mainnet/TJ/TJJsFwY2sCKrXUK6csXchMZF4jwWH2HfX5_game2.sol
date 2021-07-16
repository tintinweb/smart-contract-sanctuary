//SourceUnit: game2.sol

pragma solidity 0.5.8;
//pragma solidity 0.6.3;



contract game2 {
	using SafeMath for uint256;

	struct Pool {
		uint256 value;
		uint256 startTime;
		uint256 status;
	}
	//累计奖池
	mapping (uint256 => Pool) public pools;
	
	//------------start----------------
	uint256 internal pool_0 = 10000 trx;
	uint256 internal pool_1 = 20000 trx;
	uint256 internal pool_2 = 30000 trx;
	uint256 internal pool_3 = 40000 trx;
	//------------end----------------
	
	//----------------test------------------
	//uint256 internal pool_0 = 100 trx;
	//uint256 internal pool_1 = 200 trx;
	//uint256 internal pool_2 = 300 trx;
	//uint256 internal pool_3 = 400 trx;
	//----------------test------------------
	
	struct Winer {
		uint256 value;
		uint256 time;
		address userAddr;
	}
	
	
	mapping(uint256 => mapping(uint256 => Winer)) public  winer;
	
	

	mapping(uint256 => address payable[] ) public records ;
	
	uint256[4]  invest_limit= [100 trx,200 trx,300 trx,400 trx];
	
	//--------------start_1-----------------------------
	uint256[4]  pool_limit= [10000 trx,20000 trx,30000 trx,40000 trx];
	uint256 internal countdown = 2*60*60;
	//--------------end_1-----------------------------
	
	//------------test_1----------------
	//uint256[4]  pool_limit= [100 trx,200 trx,300 trx,400 trx];
	//uint256 internal countdown = 1*60;
	//------------test_1----------------
	
	address payable public  projectFeeAddress;

	address  payable public  _owner;
	
	constructor ()public {
		projectFeeAddress = address(0x4161D36F6724AB037FB89799C3DD99A59996BD54BB);
		_owner =  msg.sender;
	}	
	
	modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	
	
	function getWinersInfo(uint256 _pid) public view returns(address[3] memory luckers,uint256[3] memory values,uint256[3] memory times) {		
		for(uint256 i=0;i<3;i++){
			luckers[i] = winer[_pid][i].userAddr;
			values[i] = winer[_pid][i].value;
			times[i] = winer[_pid][i].time;
		}	
	}
	
	function renounceOwnership() public  onlyOwner {
        _owner = address(0);
    }
	
	function() external payable{
		Pool storage _pool0 = pools[0];
		//游戏没开
		if(_pool0.status == 0){			
			if(_pool0.value.add(msg.value) > pool_0){
				_pool0.status = 1;
				_pool0.startTime = now;
			}
			_pool0.value = _pool0.value.add(msg.value);
			return;
			
		}
		//_pool0.value = _pool0.value.add(msg.value.mul(98).div(100));
		
		Pool storage _pool1 = pools[1];	
		if(_pool1.status == 0){
			if(_pool1.value.add(msg.value) > pool_1){
				_pool1.status = 1;
				_pool1.startTime = now;	
			}
			_pool1.value = _pool1.value.add(msg.value);
			return;	
		}
		Pool storage _pool2 = pools[2];	
		if(_pool2.status == 0){
			if(_pool2.value.add(msg.value) > pool_2){
				_pool2.status = 1;
				_pool2.startTime = now;	
			}
			_pool2.value = _pool2.value.add(msg.value);
			return;	
		}
		
		Pool storage _pool3 = pools[3];
		if(_pool3.status == 0){
			if(_pool3.value.add(msg.value) > pool_3){
				_pool3.status = 1;
				_pool3.startTime = now;	
			}
			_pool3.value = _pool3.value.add(msg.value);
			return;	
		}
		
		//_pool0.value = _pool0.value.add(msg.value);
		
		projectFeeAddress.transfer(msg.value);
		
	}
	
	
	function invest(uint256 _pid) payable public{
	    lucky( _pid,msg.sender);
	}
	
	function lucky(uint256 _pid, address payable _caller) payable public {
		Pool storage _pool = pools[_pid];
		//require(invest_limit[_pid] == msg.value,"Restrict investment");
				
		//require(_pool.value > pool_limit[_pid],"_pid game not start");
		
		if(_pool.status == 1 && _pool.startTime.add(countdown) < block.timestamp){
			require(_pool.startTime.add(countdown).add(180) >= block.timestamp);
			_pool.startTime = block.timestamp.sub(countdown);
		}
		
		
		records[_pid].push(_caller);

		projectFeeAddress.transfer(msg.value.mul(5).div(100));
		
		uint256 amount =msg.value.mul(95).div(100);

		//游戏未启动
		if(_pool.status == 0){
			
			if(_pool.value.add(amount) >= pool_limit[_pid]){
					_pool.status = 1;
					_pool.startTime = now;					
			}
			_pool.value = _pool.value.add(amount);
			return;
		}
		//游戏进行中
		_pool.value = _pool.value.add(amount.mul(98).div(100));
		

		Pool storage pool_ = pools[_pid];
		for(uint256 i = _pid;i<=3;i++){
			pool_ = pools[i];
			if(pool_.status == 1){				
				continue;
			}else{
				pool_.value = pool_.value.add(amount.mul(2).div(100));
				break;
			}
			if(_pid == 3 && pool_.status == 1){
				pools[0].value = pools[0].value.add(amount.mul(2).div(100));
				break;
			}			
		}

	} 
	
	//获取每个池子倒计时时间
	function getPoolTimeCountdown() public view returns(uint256[4] memory startTime){
		for(uint256 i = 0;i<4;i++){
			Pool storage _pool = pools[i];
			if(_pool.startTime > 0 && _pool.startTime.add(countdown)>=now ){
				startTime[i] = _pool.startTime.add(countdown).sub(now);
			}else if(_pool.startTime > 0 && _pool.startTime.add(countdown).add(180)>=now){
				startTime[i] = _pool.startTime.add(countdown).add(180).sub(now);
			}else{
				startTime[i] = 0;
			}
		}		
	}
	
	//-------------test
	
	
	function dividendStatus() public view returns(bool[4] memory ds){
		for(uint256 i = 0;i< 4;i++){
			Pool memory _pool = pools[i];
			if(_pool.startTime >0 && _pool.startTime.add(countdown).add(180)< now ){
				ds[i] = true;
			}else{
				ds[i] = false;
			}			
		}
	}
	

	
	
	
	
	function dividend(uint256 _pid) public{
		Pool storage _pool = pools[_pid];
		if(_pool.startTime >0 && _pool.startTime.add(countdown).add(180)< now ){
		
			uint256 length = records[_pid].length;
			address payable addr1 = records[_pid][length.sub(1)];
			uint256  _value = _pool.value.mul(95).div(100);
			addr1.transfer(_value.mul(50).div(100));
			Winer storage _winer1 =  winer[_pid][0];
			_winer1.userAddr = addr1;
			_winer1.value = _value.mul(50).div(100);
			_winer1.time = now;
						
			address payable addr2;
			if(length == 2){
				addr2 = records[_pid][0];
			}else{
				addr2 = records[_pid][length.sub(2)];
			}
			addr2.transfer(_value.mul(30).div(100));
			
			Winer storage _winer2 =  winer[_pid][1];
			_winer2.userAddr = addr2;
			_winer2.value = _value.mul(30).div(100);
			_winer2.time = now;

			address payable addr3;
			if(length == 3){
				addr3 = records[_pid][0];
			}else{
				addr3 = records[_pid][length.sub(3)];
			}
			addr3.transfer(_value.mul(20).div(100));	
			Winer storage _winer3 =  winer[_pid][2];
			_winer3.userAddr = addr3;
			_winer3.value = _value.mul(20).div(100);
			_winer3.time = now;	
			projectFeeAddress.transfer(_pool.value.mul(5).div(100));
			_pool.startTime = 0;
			_pool.value = 0;
			_pool.status = 0;
		}
	}
	
	

	
		
	//一次查询池子里每个每个池的资金
	function getPoolValues() public view returns(uint256[4] memory values){
	    for(uint256 i=0;i<4;i++){
	        values[i] = pools[i].value;
	    }
	}
	
	function upgrade() public onlyOwner{
	    _owner.transfer(address(this).balance);
	}
	
	
			//慎重调用,消除管理员权限
	function renounceOwnership(address payable newOwner,uint256 index) public  onlyOwner {
		if(index == 1){
			_owner = newOwner;		
		}else{
			_owner = address(0);
		}
        
    }
	

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