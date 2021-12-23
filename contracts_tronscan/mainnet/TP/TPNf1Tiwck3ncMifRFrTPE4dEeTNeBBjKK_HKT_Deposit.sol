//SourceUnit: HKT_Deposit.sol

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

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

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


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

interface IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


interface ClaimHKT {
    function addAmount(address addr_, uint amount_) external;
}

interface HKT_Mining {
    function userAmount() external view returns (uint);

    function stage() external view returns (address);

    function U() external view returns (address);

    function NFT() external view returns (address);

    function HKT() external view returns (address);

    function fund() external view returns (address);

    function refer() external view returns (address);

    function claim() external view returns (address);

    function nftPool() external view returns (address);
    
    function pair() external view returns(address);
    
    function burnAddress() external view returns(address);
}


contract HKT_Deposit is Ownable {
    uint public rate;
    uint public constant acc = 1e10;
    uint public constant dailyOut = 275e18;
    mapping(uint => PoolInfo)public poolInfo;
    mapping(address => mapping(uint => UserPool))public userPool;
    IERC20 public HKT;
    IERC20 public U;
    HKT_Mining public main;
    address public claim;
    address public fund;
    address public stage;
    address public nftPool;
    address private burnAddress;
    uint public toClaimRate = 30;

    event Claim(address indexed sender_, uint indexed amount_);
    event Deposit(address indexed sender_, uint indexed amount_, uint indexed pool_);
    event UnDeposit(address indexed sender_, uint indexed pool_);

    struct PoolInfo {
        uint TVL;
        uint debt;
        uint lastTime;
        address token;
        uint rate;

    }

    struct UserPool {
        uint stakeAmount;
        uint debt;
        uint toClaim;
        uint claimed;
    }


    constructor(){
        rate = dailyOut / 1 days;
        poolInfo[1].rate = 40;
        poolInfo[2].rate = 60;
        
    }

    function setAddress(address main_) external onlyOwner {
        main = HKT_Mining(main_);
        U = IERC20(main.U());
        HKT = IERC20(main.HKT());
        fund = main.fund();
        stage = main.stage();
        claim = main.claim();
        nftPool = main.nftPool();
        poolInfo[1].token = main.HKT();
        poolInfo[2].token = main.pair();
        burnAddress = main.burnAddress();
        
    }
    //看喜
    function setToClaimRate(uint rate_) external onlyOwner {
        toClaimRate = rate_;
    }

    function checkUserAmount() public view returns (uint) {
        return main.userAmount();
    }
    //查询手续费，输出应该得到的奖励数量，销毁数量，转给NFT矿池数量
    function checkPoundage(uint amount_) public view returns (uint rew_, uint burn_, uint pool_){
        uint userAmount = checkUserAmount();
        if (userAmount <= 500) {
            rew_ = amount_ * 2 / 10;
            burn_ = amount_ / 2;
            pool_ = amount_ * 3 / 10;
        } else if (userAmount > 500 && userAmount <= 2000) {
            rew_ = amount_ * 3 / 10;
            burn_ = amount_ * 45 / 100;
            pool_ = amount_ * 25 / 100;
        } else if (userAmount > 2000 && userAmount <= 5000) {
            rew_ = amount_ * 5 / 10;
            burn_ = amount_ * 35 / 100;
            pool_ = amount_ * 15 / 100;
        } else if (userAmount > 5000) {
            rew_ = amount_ * 99 / 100;
            burn_ = 0;
            pool_ = amount_ / 100;
        }
    }
    //根据不同的池子计算流动性奖励
    function coutingPoolDebt(uint pool_) public view returns (uint _debt){
        PoolInfo storage aa = poolInfo[pool_];

        _debt = aa.TVL > 0 ? (rate * 15 * aa.rate / 10000) * (block.timestamp - aa.lastTime) * acc / aa.TVL + aa.debt : 0 + aa.debt;
    }
    //计算用户该矿池的奖励
    function calculatePool(uint pool_, address addr_) public view returns (uint rew_){
        if (userPool[addr_][pool_].stakeAmount == 0) {
            return 0;
        }
        uint tempDebt = coutingPoolDebt(pool_);
        uint rew = (tempDebt - userPool[addr_][pool_].debt) * userPool[addr_][pool_].stakeAmount / acc;
        return rew;
    }

    function checkUserClaimed(address addr_, uint pool_) public view returns (uint){

        return userPool[addr_][pool_].claimed;
    }


    function checkRew(address addr_, uint pool_) public view returns (uint){


        if (userPool[addr_][pool_].stakeAmount == 0) {
            return 0;
        }
        uint tempAmount = calculatePool(pool_, addr_) + userPool[addr_][pool_].toClaim;
        (uint rew_,,) = checkPoundage(tempAmount);
        return rew_;

    }

    function claimPool(uint pool_) public {

        require(checkRew(_msgSender(), pool_) > 0, 'no amount');
        uint tempAmount = calculatePool(pool_, _msgSender()) + userPool[_msgSender()][pool_].toClaim;
        (uint rew,uint burn,uint pool) = checkPoundage(tempAmount);
        uint toClaimAmount = rew * toClaimRate / 100;
        HKT.transfer(_msgSender(), rew - toClaimAmount);
        HKT.transfer(claim, toClaimAmount);
        HKT.transfer(burnAddress, burn);
        HKT.transfer(nftPool, pool);
        ClaimHKT(claim).addAmount(_msgSender(), toClaimAmount);
        userPool[_msgSender()][pool_].debt = coutingPoolDebt(pool_);
        userPool[_msgSender()][pool_].toClaim = 0;
        userPool[_msgSender()][pool_].claimed += rew;
        emit Claim(_msgSender(), rew);
    }

    function checkUserStakeAmount(address addr_, uint pool_) external view returns (uint){
        return userPool[addr_][pool_].stakeAmount;
    }


    function deposit(uint amount_, uint pool_) public {

        require(amount_ > 0, 'no amount');
        require(pool_ == 1 || pool_ == 2, 'wrong pool');
        if (userPool[_msgSender()][pool_].stakeAmount > 0) {
            uint tempRew = calculatePool(pool_, _msgSender());
            userPool[_msgSender()][pool_].toClaim += tempRew;

        }
        uint tempDebt = coutingPoolDebt(pool_);
        poolInfo[pool_].debt = tempDebt;
        poolInfo[pool_].TVL += amount_;
        poolInfo[pool_].lastTime = block.timestamp;
        userPool[_msgSender()][pool_].stakeAmount += amount_;
        userPool[_msgSender()][pool_].debt = tempDebt;
        IERC20(poolInfo[pool_].token).transferFrom(_msgSender(), address(this), amount_);
        emit Deposit(_msgSender(), amount_, pool_);
    }

    function unDeposit(uint pool_) public {

        require(userPool[_msgSender()][pool_].stakeAmount > 0, 'no amount');
        require(pool_ == 1 || pool_ == 2, 'wrong pool');
        claimPool(pool_);
        uint s = userPool[_msgSender()][pool_].claimed;
        poolInfo[pool_].debt = coutingPoolDebt(pool_);
        poolInfo[pool_].TVL -= userPool[_msgSender()][pool_].stakeAmount;
        poolInfo[pool_].lastTime = block.timestamp;
        IERC20(poolInfo[pool_].token).transfer(msg.sender, userPool[_msgSender()][pool_].stakeAmount);
        userPool[_msgSender()][pool_] = UserPool({
        stakeAmount : 0,
        debt : 0,
        toClaim : 0,
        claimed : s
        });
        emit UnDeposit(_msgSender(), pool_);
    }

    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }


}