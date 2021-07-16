//SourceUnit: HashPool.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.12;
import './IPoolManager.sol';

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
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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
}

//算力挖矿
contract HashPool {
    
    using SafeMath for uint256;
    using Instance for IPoolManager;

    struct User {
        uint id;
        uint refsCount;
        uint teamCount;
        uint teamMass;
        uint teamMax;
        uint vip;
        uint withdrew;
        uint deposited;
        uint rateUsed;
        uint deep;
        address referrer;
        uint256[5] vipCounts;
        bool[5] blocked;
	    address[] referrals;
    }
    
    uint256 internal constant SHARE_RATE = 30;
    uint256 internal constant MAX_REF = 10;
    uint256 internal constant U = 1e6;
    uint256 internal constant VIP1_MASS = 20000*U;
    uint256[5] internal VIP_SILL = [0,1000*U,5000*U,5000*U,5000*U];
    uint256[5] internal VIP_RATE = [0,5,4,3,3];
    uint256[5] internal VIP_SHARE = [0,20,35,45,55];
    
    uint256 internal constant F_SHARE = 10;
    uint256 internal constant S_SHARE = 20;
    
    uint256 public userCounter;

    uint256 public lastUpdateTime;

    //vip全球会员数
    uint256[5] public vipGlobals;
    //vip当前全球收益率
    uint256[5] public rateGlobals;
    
    mapping (uint => address ) public userIds;
    mapping (address => User ) public users;
    
    mapping( address => uint256[3]) public earns;
    uint256[3] public gaven;
    uint256[3] public ABS_RATE = [30,55,15];
   
    address public USDT;
    address public TGC;
    
    IPoolManager public manager;
    
    bytes32 public name;
    
    address internal DEF_T4 = 0xAe9666c079D9Cf71E9D466c051b4AF1aF030008e;
    
    event Stake(address indexed,address indexed,uint256 amount);
    event Reap(address indexed,uint256);
    event Upgrade(address indexed,uint256);
    event Registration(address indexed,address indexed);
    event Withdraw(address indexed,uint256);

    constructor(address root,address _manager) public {
        registration(root,address(0));
        manager = IPoolManager(_manager);
        name = keccak256(abi.encode(SHARE_RATE,"HashPool"));
        manager.active(SHARE_RATE,name);
        (USDT,TGC) = manager.usdt_tgc();
        (,,lastUpdateTime) = manager.time();
    }
    
    modifier checkRegister(address uaddress){
        require(isUserExists(uaddress),"Please register first");
        _;
    }
    
    modifier onlyStakePool(){
        require(manager.getStakehAddr()==msg.sender,"not allowed");
        _;
    }
    
    function stake(address uaddress,uint256 amount) external onlyStakePool checkRegister(uaddress) returns (bool) {
        require(amount>0,"error amount");
        updateRateGlobals();
        users[uaddress].deposited=users[uaddress].deposited.add(amount);
        updateTeamMass(uaddress,amount);
        
        emit Stake(msg.sender,uaddress,amount);
    }
    
    function reap(uint256 amount,address uaddress) public onlyStakePool returns(uint256){
        address f_ = users[uaddress].referrer;
        if(f_!=address(0)){
            earns[f_][0] = earns[f_][0].add(actualGive(amount.mul(F_SHARE)/100,0));
            address s_ = users[f_].referrer;
            uint256 sc_ = users[s_].refsCount;
            if(s_!=address(0)&&sc_>2){
                earns[s_][0] = earns[s_][0].add(actualGive(amount.mul(S_SHARE)/100,0));
            }
        }
        
        address up = uaddress;
        uint256 lvip = users[uaddress].vip;
        while(true){
            (address lup,uint256 uvip) = findLatest(up);
            if(lup==address(0)) break;
            earns[lup][1] = earns[lup][1].add(actualGive(amount.mul(VIP_SHARE[uvip].sub(VIP_SHARE[lvip]))/100,1));
            up = lup;
            lvip = uvip;
        }
        
        emit Reap(msg.sender,amount);
    }
    
    function actualGive(uint256 amount,uint256 kind) internal returns(uint256 actualOut){
        (uint256 _output,) = manager.poolInfo(name);
        uint256 supply = _output.mul(ABS_RATE[kind])/100;
        if(gaven[kind].add(amount)>supply){
            actualOut = gaven[kind]>supply?0:supply-gaven[kind];
        }else{
            actualOut = amount;
        }
        gaven[kind] = gaven[kind].add(actualOut);
    }
    
    function findLatest(address uaddress) public view returns(address,uint256){
        address up = users[uaddress].referrer;
        uint256 vip = users[uaddress].vip;
        if(vip<4){
            while(true){
                if(up==address(0)) break;
                if(users[up].vip>vip){
                    return (up,users[up].vip);
                }
                up = users[up].referrer;
            }
        }
    }
    
    function withdraw() public returns(uint256 uamount){
        updateRateGlobals();
        uint256[3] memory _earns = earns[msg.sender];
        for(uint i;i<3;i++){
            uamount = uamount.add(_earns[i]);
        }
        uamount = uamount.add(rateGlobals[users[msg.sender].vip].sub(users[msg.sender].rateUsed));
        require(uamount>0,"No income");
        manager.withdraw(uamount);
        delete earns[msg.sender];
        users[msg.sender].withdrew = users[msg.sender].withdrew.add(uamount);
        users[msg.sender].rateUsed = rateGlobals[users[msg.sender].vip];
        TransferHelper.safeTransfer(TGC,msg.sender,uamount);
        
        emit Withdraw(msg.sender,uamount);
    }

    function updateRateGlobals() public {
        if(lastUpdateTime!=0){
            uint256 output = manager.getOutput(address(this),lastUpdateTime,now);
            uint256 shareOutput = output.mul(ABS_RATE[2])/100;
            for(uint8 i=1;i<rateGlobals.length;i++){
                uint256 vipOutput = vipGlobals[i]==0?0:shareOutput.mul(VIP_RATE[i]).div(15).div(vipGlobals[i]);
                rateGlobals[i] = rateGlobals[i].add(vipOutput);
            }
        }
        lastUpdateTime = now;
    }
    
    function checkUpgradeVIP(address uaddress,uint8 vip) internal view returns (bool){
        if(users[uaddress].vip<vip){
            if(users[uaddress].deposited>=VIP_SILL[vip]){
                if(vip==1){
                    if(users[uaddress].teamMax>=VIP1_MASS){
                        if(users[uaddress].teamMass.sub(users[uaddress].deposited).sub(users[uaddress].teamMax)>=VIP1_MASS){
                            return true;
                        }
                    }
                }else{
                    if(users[uaddress].vipCounts[vip-1]>=3){
                        return true;
                    }
                }
            }
        }
    }
    
    function updateTeamMass(address uaddress,uint256 uamount) internal {
        
        uint256 down = users[uaddress].teamMax;
        address up = uaddress;
        bool[5] memory vipUp;
        
        while(true){
            if(up==address(0)) break;
            if(down>users[up].teamMax){
                users[up].teamMax = down;
            }
            users[up].teamMass = users[up].teamMass.add(uamount);
            for(uint8 i=1;i<5;i++){
                if(vipUp[i]){
                    if(users[up].blocked[i]){
                        vipUp[i] = false;
                    } else {
                        users[up].blocked[i] = true;
                    }
		            users[up].vipCounts[i]++;
                }
                
                if(checkUpgradeVIP(up,i)){
                    upgrade(up,i);
                    if(!users[up].blocked[i]){
                        vipUp[i] = true;
			            users[up].blocked[i] = true;
                    }
                }
            }
            down = users[up].teamMass;
            up = users[up].referrer;
        }
    }
    
    function upgrade(address uaddress,uint256 vip) internal returns(uint256 reward) {
        uint256 lastVip = users[uaddress].vip;
        reward = rateGlobals[lastVip].sub(users[uaddress].rateUsed);
        users[uaddress].vip = vip;
        users[uaddress].rateUsed = rateGlobals[vip];
        earns[uaddress][2] = earns[uaddress][2].add(actualGive(reward,2));
        if(vipGlobals[lastVip]>0){
            vipGlobals[lastVip]--;
        }
        vipGlobals[vip]++;
        emit Upgrade(uaddress,vip);
    }
    
    function register(address raddress) public  {
        require(!Address.isContract(msg.sender), "cannot be a contract");
        require(!isUserExists(msg.sender),"exist");
        require(isUserExists(raddress),"ref not register");
        require(users[raddress].deep<MAX_REF,"too deep");
        registration(msg.sender,raddress);
    }
    
    function registration(address uaddress,address raddress) internal {
        users[uaddress] = createUser(uaddress,raddress,users[raddress].deep);
        users[raddress].refsCount++;
	    users[raddress].referrals.push(uaddress);
        address ref = raddress;
        for(uint8 i;i<MAX_REF;i++){
            if(ref==address(0)) break;
            users[ref].teamCount++;
            ref = users[ref].referrer;
        }
        emit Registration(uaddress,raddress);
    }

    function isUserExists(address uaddress) public view returns(bool) {
        return users[uaddress].id!=0;
    }
    
    function createUser(address uaddress, address raddress,uint256 deep) internal returns(User memory user) {
        userCounter++;
        userIds[userCounter] = uaddress;
        uint256[5] memory vipCounts;
        bool[5] memory blocked;
	    address[] memory referrals;
        user = User({
            id: userCounter,
            refsCount: 0,
            teamCount: 1,
            teamMass: 0,
            teamMax: 0,
            vip: 0,
            withdrew: 0,
            deposited: 0,
            rateUsed: 0,
            deep: deep.add(1),
            referrer: raddress,
            vipCounts: vipCounts,
            blocked: blocked,
	        referrals: referrals
        });
    }
    
    function getStats(address uaddress) public view returns(uint256[8] memory stats){
        uint256 output = manager.getOutput(address(this),lastUpdateTime,now);
        uint256 shareOutput = output*ABS_RATE[2]/100;
        uint256 vip = users[uaddress].vip;
        uint256 vipOutput = vipGlobals[vip]==0?0:shareOutput.mul(VIP_RATE[vip]).div(15).div(vipGlobals[vip]);
        
        stats[0] = users[uaddress].withdrew;
        stats[2] = earns[uaddress][0];
        stats[3] = earns[uaddress][1];
        stats[4] = vip==0?0:earns[uaddress][2]+vipOutput.add(rateGlobals[vip]).sub(users[uaddress].rateUsed);
        stats[5] = users[uaddress].id;
        stats[6] = users[uaddress].vip;
    }
    
    function getPersonalStats(address uaddress) public view returns (uint256[3] memory stats){
        stats[0] = users[uaddress].deposited;
        stats[1] = users[uaddress].teamMass;
	    stats[2] = users[uaddress].refsCount;
    }
    
    function getReferrals(address uaddress) public view  returns (address[] memory stats,uint256[] memory stats2){
        uint256 refsCount = users[uaddress].refsCount;
        if(refsCount>10){
            stats = new address[](10);
            stats2 = new uint256[](10);
        }else{
            stats = new address[](refsCount);
            stats2 = new uint256[](refsCount);
        }
        for(uint256 i;i<stats.length;i++){
            stats[i] = users[uaddress].referrals[i];
            stats2[i] = users[stats[i]].teamMass;
        }
    }
    
    function getTeamMass(address uaddress) public view returns (uint256){
        return users[uaddress].teamMass-users[uaddress].deposited;
    }
    
    function getAllReferrals(address uaddress) public view returns(address[] memory){
        return users[uaddress].referrals;
    }
    
    function getOneReferrals(address uaddress,uint256 i) public view returns(address){
        return users[uaddress].referrals[i];
    }
    
    function getUserVipCounts(address uaddress) public view returns (uint256[5] memory,bool[5] memory){
        return (users[uaddress].vipCounts,users[uaddress].blocked);
    }
    
    function upT4() public {
        if(users[DEF_T4].vip<4){
            updateRateGlobals();
            upgrade(DEF_T4,4);
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