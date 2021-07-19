//SourceUnit: IPoolManager.sol

pragma solidity ^0.5.12;

interface IPoolManager {
    function pools(bytes32 name) external view returns (address);
    function withdraw(uint256 amount) external returns (bool);
    function active(uint256 rate,bytes32 name) external returns(uint256);
    function getOutput(address paddress,uint256 start,uint256 end) external view returns(uint256);
    
    function deposit(address uaddress,uint256 amount,address token) external returns(bool);
    function refundFrom(address owner,uint256[] calldata amounts,address[] calldata tokens) external returns(bool);
    
    function stage() external view returns(uint256);
    function poolInfo(bytes32 name) external view returns (uint256,uint256);
    function usdt_tgc() external view returns(address usdt,address tgc);
    function time() external view returns(uint256 one_day,uint256 one_month,uint256 anchor);
    function isActived(address uaddress) external view returns(bool);
}

interface IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external ;

}

interface IHashPool {
    function stake(address uaddress, uint256 amount) external returns (bool);
    function reap(uint256 amount,address uaddress) external returns(uint256);
    function isUserExists(address uaddress) external view returns(bool);
}

interface RateManager {
    function updateRewardRate(uint256 rate) external returns(bool);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

    function safeTransferTRX(address to, uint value) internal {
        (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: TRX_TRANSFER_FAILED');
    }
}


library Instance {
    
    bytes32 public constant HASH_POOL = 0x1c6dfba747ab25b21fb9dfaff2e98f57fbf832663b318aa96cee943c77c573bb;
    bytes32 public constant STAKE_POOL = 0x1d46245a2e1d3bafb7c1a0b7fe0260dbed37069a2ed9dc5bb73abb1a68eb6cde;
    bytes32 public constant FLUIDITY_POOL = 0x5fc256176fd4b89d399558397250a86b19e0923ba2bcfe49e3e661ad344bb00c;
    bytes32 public constant CONTRACT_POOL = 0x708d57fd23a95b3a27929a95cf119f5d613e7af4fd5399b088bf635936bd74f5;

    function instanceHash(IPoolManager manager) internal view returns(IHashPool pool){
        return IHashPool(manager.pools(HASH_POOL));
    }

    function getHashAddr(IPoolManager manager) internal view returns(address){
        return manager.pools(HASH_POOL);
    }
    
    function getStakehAddr(IPoolManager manager) internal view returns(address){
        return manager.pools(STAKE_POOL);
    }
    
    function getFluidityAddr(IPoolManager manager) internal view returns(address){
        return manager.pools(FLUIDITY_POOL);
    }
    
    function getContractAddr(IPoolManager manager) internal view returns(address){
        return manager.pools(CONTRACT_POOL);
    }
}

//SourceUnit: StakePool.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.12;
import './IPoolManager.sol';

contract StakePool {
    
    using SafeMath for uint256;
    using Instance for IPoolManager;
    constructor(address _manager,address developer) public {
        manager = IPoolManager(_manager);
        name = keccak256(abi.encode(SHARE_RATE,"StakePool"));
        manager.active(SHARE_RATE,name);
        (ONE_DAY,,ANCHOR) = manager.time();
        (USDT,TGC) = manager.usdt_tgc();
        tokens = [[USDT,USDT],[TGC,USDT],[TGC,TGC]];
        lastUpdateTime = ANCHOR;
        DEVELOPER = developer;
        uint256 decimals = IERC20(TGC).decimals()+2;
        unit = (10**decimals).div(2);
    }

    uint256 public unit;
    uint256 internal constant SHARE_RATE = 20;
    uint256 internal constant MAX_INPUT = 2000e6;
    uint256 internal constant DAY_INPUT = 10000e6;
    uint256 public rewardRate = 100;
    uint256 public lastUpdateTime;
    uint256 public perTokenStored;
    uint256 public balance;
    uint256 public burned;
    
    uint256 public ANCHOR;
    uint256 public ONE_DAY;
    
    mapping(address => uint256) public perTokenPaid;
    mapping(address => uint256) public rewards;
    
    mapping( address => uint256[3] ) public stakes;
    mapping(address=>uint256) public reaped;
    
    
    mapping(uint256=>DayInput) public dayInputs;
    
    address[2][3] public tokens;
    uint256[2][3] public scales =[[1,1],[1,2],[1,1]];
    
    address public USDT;
    address public TGC;
    
    address public DEVELOPER;
    
    IPoolManager public manager;
    bytes32 public name;
    Fuse public fuse;
    
    event Stake(address indexed,uint256,uint256);
    event Reap(address indexed,uint256);
    event Withdraw(address indexed,uint256);
    event UpdateRewardRate(uint256,uint256);
    
    struct DayInput{
        uint256 performance;
        uint256 maxInput;
    }
    
    struct Fuse{
        bool open;
        uint256 date;
    }
    
    modifier updateOutput(address uaddress){
        perTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (uaddress != address(0)) {
            rewards[uaddress] = earned(uaddress);
            perTokenPaid[uaddress] = perTokenStored;
        }
        _;
    }
    
    modifier onlyManager(){
        require(msg.sender==address(manager),"only manager");
        _;
    }
    
    modifier updateFuse(){
        uint256 curdate = date(block.timestamp);
        if(curdate>fuse.date){
            fuse.open = checkOpen(curdate-1);
            fuse.date = curdate;
        }
        _;
        if(fuse.open){
            fuse.open = checkOpen(curdate);
        }
    }
    
    function checkOpen(uint256 idate) public view returns(bool){
        return dayInputs[idate].performance<MAX_INPUT&&dayInputs[idate].maxInput<DAY_INPUT;
    }
    
    
    function rewardPerToken() public view returns (uint256) {
        if(balance==0) return perTokenStored;
        uint256 endTime = block.timestamp;
        
        if(samedate(lastUpdateTime,block.timestamp)){
            endTime = fuse.open?lastUpdateTime:block.timestamp;
        }else{
            endTime = checkOpen(date(lastUpdateTime))?(fuse.open?lastUpdateTime:date(lastUpdateTime).add(1).mul(ONE_DAY).add(ANCHOR)):block.timestamp;
        }
        
        uint256 output = manager.getOutput(address(this),lastUpdateTime,endTime);
        return perTokenStored.add(output.mul(rewardRate).div(100).mul(1e12).div(balance));
    }
    
    function earned(address uaddress) public view returns (uint256){
        return findUserAmount(uaddress).mul(rewardPerToken().sub(perTokenPaid[uaddress])).div(1e12).add(rewards[uaddress]);
    }
    
    function findUserAmount(address uaddress) public view returns(uint256 uamount){
        uint256[3] memory _stakes = stakes[uaddress];
        for(uint i;i<3;i++){
            uamount = uamount.add(_stakes[i]);
        }
    }
    
    function stake(uint256 amount,uint256 stage) public updateOutput(msg.sender) updateFuse {
        require(manager.stage()==stage,"error stage");
        IHashPool hashPool = manager.instanceHash();
        
        uint256 amount0 = amount.mul(scales[stage][0]);
        uint256 amount1 = amount.mul(scales[stage][1]);
        
        address token0 = tokens[stage][0];
        address token1 = tokens[stage][1];
        
        require(amount>=unit,"to small");
        require(amount.mod(unit)==0,"not allowed type");
        
        uint256 total = amount0.add(amount1);
        
        TransferHelper.safeTransferFrom(token0,msg.sender,address(this),amount0);
        TransferHelper.safeTransferFrom(token1,msg.sender,address(this),amount1);
        
        TransferHelper.safeApprove(token0,address(manager),amount0);
        manager.deposit(msg.sender,amount0,token0);
        
        if(token1==USDT){
            TransferHelper.safeTransfer(USDT,DEVELOPER,amount1);
        }else{
            IERC20(TGC).burn(amount1);
            burned = burned.add(amount1);
        }
        
        hashPool.stake(msg.sender,total);
        stakes[msg.sender][stage] = stakes[msg.sender][stage].add(total);
        balance = balance.add(total);
        uint256 curdate = date(block.timestamp);
        dayInputs[curdate].performance = dayInputs[curdate].performance.add(total);
        
        if(total>dayInputs[curdate].maxInput) dayInputs[curdate].maxInput = total;
        
        emit Stake(msg.sender,total,stage);
    }
    
    
    function reap() public updateOutput(msg.sender) updateFuse returns(uint256 reward){
         reward = earned(msg.sender);
         if (reward > 0) {
            IHashPool hashPool = manager.instanceHash();
            hashPool.reap(reward,msg.sender);
            rewards[msg.sender] = 0;
            manager.withdraw(reward);
            TransferHelper.safeTransfer(TGC,msg.sender,reward);
        }
        
        reaped[msg.sender] = reaped[msg.sender].add(reward);
        emit Reap(msg.sender,reward);
    }
    
    function withdraw() internal {
        uint256[3] memory _stakes = stakes[msg.sender];
        
        uint256 uamount = _stakes[0]/2;
        uint256 tamount = (_stakes[1]/3).add(_stakes[2]/2);
        uint256 total = _stakes[0].add(_stakes[1]).add(_stakes[2]);
        
        require(total>0,"no money");
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = uamount;
        amounts[1] = tamount;
        address[] memory tokes = new address[](2);
        tokes[0] = USDT;
        tokes[1] = TGC;
        
        manager.refundFrom(msg.sender,amounts,tokes);
        balance = balance.sub(total);
        delete stakes[msg.sender];
        emit Withdraw(msg.sender,total);
    }
    
    //退本
    function exit() public returns(uint256){
        reap();
        withdraw();
    }
    
    function getStats(address uaddress) public view returns(uint256[9] memory stats){

        uint256 output = manager.getOutput(address(this),lastUpdateTime,now);
        stats[0] = manager.stage();
        stats[1] = burned;
        stats[2] = earned(uaddress);
        stats[3] = date(block.timestamp);
        stats[4] = balance==0?0:findUserAmount(uaddress).mul(output.mul(ONE_DAY).div(24)).div(now.sub(lastUpdateTime)).div(balance);
        if(fuse.open){
            stats[4] = 0;
        }
        stats[5] = balance;
        stats[6] = (stakes[uaddress][1]/3).add(stakes[uaddress][2]);
        stats[7] = (stakes[uaddress][0]).add(stakes[uaddress][1].mul(2).div(3));
        stats[8] = reaped[uaddress];
    }
    
    function date(uint256 time) internal view returns (uint256){
        return (time-ANCHOR)/ONE_DAY;
    }
    
    function samedate(uint256 time1,uint256 time2) internal view returns(bool){
        require(time1<=time2,"time1 must less than time2");
        return date(time1)==date(time2);
    }
    
    function updateRewardRate(uint256 rate) external onlyManager updateFuse updateOutput(address(0)) returns(bool){
        require(rate<=100,"error rate");
        emit UpdateRewardRate(rewardRate,rate);
        rewardRate = rate;
    }

}