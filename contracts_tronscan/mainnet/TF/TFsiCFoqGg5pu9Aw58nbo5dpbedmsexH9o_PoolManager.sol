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

//SourceUnit: PoolManager.sol

pragma solidity ^0.5.12;
import './IPoolManager.sol';

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract PoolManager is Ownable,IPoolManager {
    
    using SafeMath for uint256;

    uint256 internal constant ONE_DAY = 1 days;
    uint256 public constant ONE_MONTH = 30*ONE_DAY;
    uint256 public ANCHOR;
    uint256 public usedRate;
    uint256 internal totalRate = 80;
    
    uint256 internal constant MONTH_DURATION = 6;
    uint256[4] public stages = [3,9,36,50];
    uint256[4] public outputRates = [100000,150000,200000,100000];
    
    address public TGC;
    address public USDT;
    
    mapping(address => Pool) public poolInfos;
    mapping(bytes32 => address) public pools;
    
    mapping(address => mapping(address => bool)) private _allowances;
    
    mapping(address=>mapping(address=>uint)) public lpbalance;
    
    struct Pool {
        uint256 withdrew;
        uint256 rate;
        uint256[50] outputs;
    }
    
    event Active(address,bytes32,uint256,uint256);
    event Withdraw(address indexed,uint256,uint256);
    event Deposit(address indexed,address indexed,uint256);
    event Refund(address indexed,uint256,address);
    event RefundFrom(address indexed,address indexed,address[],uint256[]);
    event Approval(address indexed owner, address indexed spender,bool);
    event Remove(address,bytes32);
    event Move(address,address);
    
    constructor(address usdt,address tgc) public {
        start(0);
        USDT = usdt;
        TGC = tgc;
        require(IERC20(TGC).decimals()==IERC20(USDT).decimals(),"decimals must be equal");
    }
    
    modifier onlyActived(){
        require(isActived(msg.sender),"not actived");
        _;
    }
    
    function isActived(address uaddress) public view returns(bool){
        return poolInfos[uaddress].rate>0;
    }
    
    function active(uint256 rate,bytes32 name) public returns(uint256){
        require(rate>0,"error rate");
        usedRate = usedRate.add(rate);
        require(usedRate<=totalRate,"out of rate");
        require(pools[name]==address(0),"actived");
        require(poolInfos[msg.sender].rate==0,"actived too");
        uint8 stage;
        
        uint256 decimals = IERC20(TGC).decimals();
        uint256 unit = (10**decimals).mul(rate).div(totalRate);
        uint256 lastOutput;
        uint256[50] memory output;
        
        for(uint8 i;i<50;i++){
            if(i>=stages[stage]){
                stage++;
            }
            lastOutput = lastOutput.add(outputRates[stage].mul(unit));
            output[i] = lastOutput;
        }
        
        poolInfos[msg.sender].outputs = output;
       
        poolInfos[msg.sender].rate = rate;
        pools[name] = msg.sender;
        
        emit Active(msg.sender,name,rate,usedRate);
        
        return usedRate;
    }
    
    function getMonth(uint256 time) public view returns(uint256 month){
        require(time>=ANCHOR,"time error");
        month =  (time-ANCHOR)/ONE_MONTH;
        if(month>49){
            month = 49;
        }
    }
    
    function getMonthEnd(uint256 _month) internal view returns(uint256){
        return (_month+1).mul(ONE_MONTH).add(ANCHOR);
    }
    
    function getRatePerSec(address _pool,uint256 _month) internal view returns(uint256){
        uint256 lastOutput = _month==0?0:poolInfos[_pool].outputs[_month-1];
        return poolInfos[_pool].outputs[_month].sub(lastOutput).div(ONE_MONTH);
    }

    function getOutput(address paddress,uint256 start,uint256 end) public view returns(uint256 output){
        uint256 startMonth = getMonth(start);
        uint256 endMonth = getMonth(end);
        uint256 tmpTime = start;
        for(;startMonth<=endMonth;startMonth++){
            uint256 endTime = getMonthEnd(startMonth);
            if(end<endTime) endTime = end;
            output = output.add(getRatePerSec(paddress,startMonth).mul(endTime.sub(tmpTime)));
            tmpTime = endTime;
        }
    }
    
    function time() external view returns(uint256 one_day,uint256 one_month,uint256 anchor){
        return (ONE_DAY,ONE_MONTH,ANCHOR);
    }
    
    function usdt_tgc() external view returns(address, address){
        return (USDT,TGC);
    }
    
    function date() external view returns (uint256){
        return (block.timestamp-ANCHOR)/ONE_DAY;
    }

    function poolInfo(bytes32 name) public view returns (uint256,uint256){
        Pool memory pool = poolInfos[pools[name]];
        return (pool.outputs[getMonth(block.timestamp)],pool.withdrew);
    }
    
    function poolOutputs(bytes32 name) public view returns (uint256[50] memory){
        return poolInfos[pools[name]].outputs;
    }
    
    function withdraw(uint256 amount) public onlyActived returns (bool) {
        Pool storage pool = poolInfos[msg.sender];
        require(pool.outputs[getMonth(block.timestamp)].sub(pool.withdrew)>=amount,"not enought");
        pool.withdrew = pool.withdrew.add(amount);
        TransferHelper.safeTransfer(TGC,msg.sender,amount);
        
        emit Withdraw(msg.sender,amount,pool.withdrew);
        return true;
    }
    
    function deposit(address uaddress,uint256 amount,address token) public onlyActived returns(bool) {
        require(amount>0,"error amount");
        lpbalance[uaddress][token] = lpbalance[uaddress][token].add(amount);
        TransferHelper.safeTransferFrom(token,msg.sender,address(this),amount);
        emit Deposit(uaddress,token,amount);
    }
    
     function refund(uint256 amount,address token) public returns(bool){
        require(amount>0,"error amount");
        lpbalance[msg.sender][token] = lpbalance[msg.sender][token].sub(amount,"lp not enought");
        TransferHelper.safeTransfer(token,msg.sender,amount);
        emit Refund(msg.sender,amount,token);
    }
    
    function refundFrom(address owner,uint256[] memory amounts,address[] memory tokens) public onlyActived returns(bool){
        require(_allowances[owner][msg.sender],"not allowed");
        for(uint i;i<amounts.length;i++){
            lpbalance[owner][tokens[i]] = lpbalance[owner][tokens[i]].sub(amounts[i],"lp not enought");
            TransferHelper.safeTransfer(tokens[i],owner,amounts[i]);
        }
        _allowances[owner][msg.sender] = false;
        emit RefundFrom(owner,msg.sender,tokens,amounts);
    }
    
    function approve(address spender,bool _approve) public returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[msg.sender][spender] = _approve;
        emit Approval(_msgSender(), spender,_approve);
        return true;
    }


     function stage() external view returns(uint256){
        uint256 month = getMonth(block.timestamp);
        uint256 _stage = month.div(MONTH_DURATION);
        return _stage>2?2:_stage;
     }
        
    function start(uint256 offset) internal returns (uint256) {
        uint utc = block.timestamp.div(ONE_DAY).mul(ONE_DAY);
        uint ONE_HOURS = ONE_DAY.div(24);
        uint beijing = utc.sub(ONE_HOURS.mul(8));
        ANCHOR = beijing.add(offset.mul(ONE_HOURS));
    }
    
    function remove(bytes32 name) public onlyOwner returns(bool){
        address pool = pools[name];
        uint256 rate = poolInfos[pool].rate;
        delete poolInfos[pool];
        delete pools[name];
        usedRate = usedRate.sub(rate);
        emit Remove(pool,name);
        return true;
    }
    
    function move(bytes32 name,address to) public onlyOwner returns(bool){
        address pool = pools[name];
        poolInfos[to] = poolInfos[pool];
        pools[name] = to;
        delete poolInfos[pool];
        emit Move(pool,to);
    }
    
    function updateRewardRate(bytes32 name,uint256 rate) public onlyOwner returns(bool){
        address pool = pools[name];
        return RateManager(pool).updateRewardRate(rate);
    }
}