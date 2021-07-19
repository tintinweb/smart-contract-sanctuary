//SourceUnit: ContractPool.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.12;
import './IPoolManager.sol';

contract ContractPool {
    using SafeMath for uint256;
    using Instance for IPoolManager;
    uint256 internal constant SHARE_RATE = 20;
    
    uint256 internal constant STAKE_MAX = 10;
    
    uint256[4] internal REWARD_RATE = [3,5,7,10];
    uint256[4] internal DURATIONS = [1,3,6,12];
    
    IPoolManager public manager;
    
    bytes32 public name;
    address public TGC;

    struct Order {
        uint256 freezeTime;
        uint256 amount;
        uint256 kind;
        uint256 rate;
    }
    
    uint256 public unit;
    uint256 public ONE_MONTH;
    uint256 public ONE_DAY;
    uint256 public AHCHOR;
    uint256 public burned;
    uint256 public balance;
    mapping(address=>Order[]) public orders;
    mapping(address=>uint) public staked;
    mapping(address=>uint) public rates;
    
    event Stake(address indexed,uint,uint);
    event Withdraw(address indexed,uint);
    
    constructor(address _manager) public {
        manager = IPoolManager(_manager);
        name = keccak256(abi.encode(SHARE_RATE,"ContractPool"));
        manager.active(SHARE_RATE,name);
        (ONE_DAY,ONE_MONTH,AHCHOR) = manager.time();
        (,TGC) = manager.usdt_tgc();
        uint256 decimals = IERC20(TGC).decimals();
        unit = 10**(decimals.add(2));
    }
    
    
    function stake(uint256 amount,uint256 kind) public returns(bool){
        IHashPool hashPool = manager.instanceHash();
        require(hashPool.isUserExists(msg.sender),"regist first");
        require(kind<4,"error type");
        require(amount>=unit,"to small");
        require(amount.mod(unit)==0,"not allowed type");
        IERC20(TGC).burnFrom(msg.sender,amount);
        burned = burned.add(amount);
        balance = balance.add(amount);
        staked[msg.sender] = staked[msg.sender].add(amount);
        
        uint256 preoutput = amount.mul(
            (DURATIONS[kind].mul(REWARD_RATE[kind])).add(100)
            ).div(100);
        uint256 prerate = preoutput.mul(ONE_DAY).div(DURATIONS[kind]).div(ONE_MONTH).div(24);
        rates[msg.sender] = rates[msg.sender].add(prerate);
        orders[msg.sender].push(
            Order({
                freezeTime: block.timestamp,
                amount: amount,
                kind: kind,
                rate: prerate
            })
        );
        emit Stake(msg.sender,amount,kind);
    }
    
     function withdraw(uint id) public returns(uint256){
        uint256 ordersize = orders[msg.sender].length;
        require(id<ordersize,"out of bounds");
        Order memory order = orders[msg.sender][id];
        uint256 kind = order.kind;
        require(order.freezeTime.add(DURATIONS[kind].mul(ONE_MONTH))<block.timestamp,"not allow now");
        uint256 output = order.amount.mul(
            DURATIONS[kind].mul(REWARD_RATE[kind]).add(100)
            ).div(100);
        manager.withdraw(output);
        TransferHelper.safeTransfer(TGC,msg.sender,output);
        balance=balance>order.amount?balance-order.amount:0;
        staked[msg.sender]=staked[msg.sender]>order.amount?staked[msg.sender]-order.amount:0;
        if (id < ordersize.sub(1)) {
           orders[msg.sender][id] = orders[msg.sender][ordersize.sub(1)];
        }
        orders[msg.sender].pop(); 
        rates[msg.sender] =  rates[msg.sender]>order.rate?rates[msg.sender]-order.rate:0;
        
        emit Withdraw(msg.sender,output);
    }
    
    
    function getStats(address uaddress) public view returns(uint256[8] memory stats){
        //User memory user = users[uaddress];
        stats[0] = orders[uaddress].length;
        stats[1] = burned;
        stats[3] = (block.timestamp.sub(AHCHOR)).div(ONE_DAY);
        stats[4] = rates[uaddress];
        stats[5] = balance;
        stats[6] = staked[uaddress];
        
    }
    
    function getOrders(address uaddress,uint page,uint size) public view returns(uint[] memory ids,uint[] memory freezeTimes,uint[] memory amounts,uint[] memory kinds){
        ids = new uint[](size);
        freezeTimes = new uint[](size);
        amounts = new uint[](size);
        kinds = new uint[](size);
        uint start = page.mul(size);
        uint end = start.add(size);
        uint count = start;
        if(end>orders[uaddress].length){
            end = orders[uaddress].length;
        }
        for(;count<end;count++){
            uint location = count.sub(start);
            ids[location] = count;
            freezeTimes[location] = orders[uaddress][count].freezeTime;
            amounts[location] = orders[uaddress][count].amount;
            kinds[location] = orders[uaddress][count].kind;
        }
    }
}


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