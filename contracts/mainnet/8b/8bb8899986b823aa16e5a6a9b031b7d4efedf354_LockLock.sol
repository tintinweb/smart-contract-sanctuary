/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

pragma solidity ^0.5.16;

library SafeMath {
    
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract TokenVestingPools {
    using SafeMath for uint256;

    struct UserInfo{
        uint256 lockedAmount;
        uint256 withdrawn;
    }

    struct PoolInfo{
        uint256 startReleasingTime;
        uint256 batchPeriod;
        uint256 batchCount;
        uint256 totalLocked;
        uint8 index;
        string name;
    }
    
    IERC20 public lockedToken;
    
    PoolInfo[] public lockPools;
    
    mapping (uint8 => mapping (address => UserInfo)) internal userInfo;

    event Claim(uint8 pid, address indexed beneficiary, uint value);


    constructor(address _token) internal{
        lockedToken = IERC20(_token);
    }

    function _addVestingPool(string memory _name, uint256 _startReleasingTime, uint256 _batchCount,  uint256 _batchPeriod) internal returns(uint8){
        
        lockPools.push(PoolInfo({
            name: _name,
            startReleasingTime: _startReleasingTime,
            batchPeriod: _batchPeriod,
            batchCount: _batchCount,
            totalLocked:0,
            index:(uint8)(lockPools.length)
        }));

        return (uint8)(lockPools.length) -1;
    }

    function _addBeneficiary(uint8 _pid, address _beneficiary, uint256 _lockedTokensCount) internal{

        require(_pid < lockPools.length, "non existing pool");
        require(userInfo[_pid][_beneficiary].lockedAmount == 0, "existing beneficiary"); //can add Beneficiary only once to a pool

        userInfo[_pid][_beneficiary].lockedAmount = _lockedTokensCount * 1e18;
        lockPools[_pid].totalLocked = lockPools[_pid].totalLocked.add(userInfo[_pid][_beneficiary].lockedAmount);
    }

     function claim(uint8 _pid) public returns(uint256 amount){

        // require(_pid < LockPoolsCount, "Can not claim from non existing pool"); // no need since getReleasableAmount will return 0

        amount = getReleasableAmount(_pid, msg.sender);
        require (amount > 0, "can not claimed 0 amount");

        userInfo[_pid][msg.sender].withdrawn = userInfo[_pid][msg.sender].withdrawn.add(amount);

        lockedToken.transfer(msg.sender,amount);
        
        emit Claim(_pid, msg.sender, amount);
    }
    
    function claim2(uint8 _pid) public returns(uint256 amount){

        // require(_pid < LockPoolsCount, "Can not claim from non existing pool"); // no need since getReleasableAmount will return 0

        amount = getReleasableAmount(_pid, msg.sender);
        require (amount > 0, "can not claimed 0 amount");

        userInfo[_pid][msg.sender].withdrawn = userInfo[_pid][msg.sender].withdrawn.add(amount);

        lockedToken.transfer(msg.sender,amount);
        
       
    }

    function getReleasableAmount(uint8 _pid, address _beneficiary) public  view returns(uint256){
        return getVestedAmount(_pid, _beneficiary, getCurrentTime()).sub(userInfo[_pid][_beneficiary].withdrawn);
    }


    function getVestedAmount(uint8 _pid, address _beneficiary, uint256 _time) public  view returns(uint256){

        if (_pid >= lockPools.length){
            return 0;
        }

        // if time < StartReleasingTime: then return 0
        if(_time < lockPools[_pid].startReleasingTime){
            return 0;
        }

        uint256 lockedAmount = userInfo[_pid][_beneficiary].lockedAmount;

        // if locked amount 0 return 0
        if (lockedAmount == 0){
            return 0;
        }

        // elapsedBatchCount = ((time - startReleasingTime) / batchPeriod) + 1
        uint256 elapsedBatchCount =
                    _time.sub(lockPools[_pid].startReleasingTime)
                    .div(lockPools[_pid].batchPeriod)
                    .add(1);

        // vestedAmount = lockedAmount  * elapsedBatchCount / batchCount
        uint256  vestedAmount =
                    lockedAmount
                    .mul(elapsedBatchCount)
                    .div(lockPools[_pid].batchCount);

        if(vestedAmount > lockedAmount){
            vestedAmount = lockedAmount;
        }

        return vestedAmount;
    }

    function getBeneficiaryInfo(uint8 _pid, address _beneficiary) public view 
        returns(address beneficiary, 
                uint256 totalLocked, 
                uint256 withdrawn, 
                uint256 releasableAmount, 
                uint256 nextBatchTime, 
                uint256 currentTime){

        beneficiary = _beneficiary;
        currentTime = getCurrentTime();
        if(_pid < lockPools.length){
            totalLocked = userInfo[_pid][_beneficiary].lockedAmount;
            withdrawn = userInfo[_pid][_beneficiary].withdrawn;
            releasableAmount = getReleasableAmount(_pid, _beneficiary);
            nextBatchTime = getNextBatchTime(_pid, _beneficiary, currentTime);
        }
    }

    function getSenderInfo(uint8 _pid) external view returns(address beneficiary, uint256 totalLocked, uint256 withdrawaned, uint256 releasableAmount, uint256 nextBatchTime, uint256 currentTime){
        return getBeneficiaryInfo(_pid, msg.sender);
    }

    function getNextBatchTime(uint8 _pid, address _beneficiary, uint256 _time) public view returns(uint256){

        // if total vested equal to total locked then return 0
        if(getVestedAmount(_pid, _beneficiary, _time) == userInfo[_pid][_beneficiary].lockedAmount){
            return 0;
        }

        // if time less than startReleasingTime: then return sartReleasingTime
        if(_time <= lockPools[_pid].startReleasingTime){
            return lockPools[_pid].startReleasingTime;
        }

        // find the next batch time
         uint256 elapsedBatchCount =
                    _time.sub(lockPools[_pid].startReleasingTime)
                    .div(lockPools[_pid].batchPeriod)
                    .add(1);

        uint256 nextBatchTime =
                    elapsedBatchCount
                    .mul(lockPools[_pid].batchPeriod)
                    .add(lockPools[_pid].startReleasingTime);

        return nextBatchTime;

    }

    function getPoolsCount() external view returns(uint256 poolsCount){
        return lockPools.length;
    }

    function getPoolInfo(uint8 _pid) external view returns(
                string memory name,
                uint256 totalLocked,
                uint256  startReleasingTime,
                uint256  batchCount,
                uint256  batchPeriodInDays){
                    
        if(_pid < lockPools.length){
            name = lockPools[_pid].name;
            totalLocked = lockPools[_pid].totalLocked;
            startReleasingTime = lockPools[_pid].startReleasingTime;
            batchCount = lockPools[_pid].batchCount;
            batchPeriodInDays = lockPools[_pid].batchPeriod.div(1 days);
        }
    }

    function getTotalLocked() external view returns(uint256 totalLocked){
        totalLocked =0;

        for(uint8 i=0; i<lockPools.length; i++){
            totalLocked = totalLocked.add(lockPools[i].totalLocked);
        }
    }

    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
}


contract LockLock is TokenVestingPools{

    constructor () public TokenVestingPools(0xE76CF1f9401079B8ddA4F98D914e0521846C2756){

	   // check https://www.epochconverter.com/ for timestamp

	   
	   uint8 pool_0 = _addVestingPool("pool0" , 1640995200, 4, 90 days); 

	  
	   _addBeneficiary(pool_0, 0xc06A06CeCB585Bb5247e1CC2a96263f59fC34613,1333333); // 1,333,333 Tokens
	   
	    uint8 pool_1 = _addVestingPool("pool1" , 1640995200, 4, 90 days); 

	  
	   _addBeneficiary(pool_1, 0xc06A06CeCB585Bb5247e1CC2a96263f59fC34613,1333333); // 1,333,333 Tokens
    }
	
}