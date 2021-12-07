/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

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

interface Old {
    function userPool(address addr_, uint pool_) external view returns (uint, uint, uint, uint);

    function poolInfo(uint pool_) external view returns (uint, uint, uint, address, uint);

    function checkRew(address addr_, uint pool_) external view returns (uint rew_);
}

contract HKT_Deposite is Ownable {
    uint public rate;
    uint public constant acc = 1e10;
    uint public constant dailyOut = 275 ether;
    mapping(uint => PoolInfo)public poolInfo;
    mapping(address => mapping(uint => UserPool))public userPool;
    uint public userAmount = 506;
    IERC20 public HKT;
    IERC20 public U;
    Old public old = Old(0xAd29a38E29f43e8376eA904B06f3d7b39101587E);
    address fund = 0x4A6C915eCC462B45B45F8a2803cbFC1D92dC403F;
    address stage = 0x3153A29A3b7c088C5b096Cc36312e1967ddf6a59;
    address nftPool = 0x9b19dA91f213fe97d1883D63A4707C545671d227;
    address private burnAddress = 0x1111111111111111111111111111111111111111;
    mapping(address => bool) public done;

    event Claim(address indexed sender_, uint indexed amount_);
    event Deposite(address indexed sender_, uint indexed amount_, uint indexed pool_);
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


    function initContrat() public onlyOwner {
        require(poolInfo[1].TVL == 0, ' inited');
        (uint amount_,uint debt,uint lastTime,address token, uint rates) = old.poolInfo(1);
        poolInfo[1] = PoolInfo({
        TVL : amount_,
        debt : debt,
        lastTime : lastTime,
        token : token,
        rate : rates
        });
        (amount_, debt, lastTime, token, rates) = old.poolInfo(2);
        poolInfo[2] = PoolInfo({
        TVL : amount_,
        debt : debt,
        lastTime : lastTime,
        token : token,
        rate : rates
        });
    }
    constructor(){
        HKT = IERC20(0x02b86CCE0aC4B29F6D97E4086192DDff70dC25dc);
        U = IERC20(0x55d398326f99059fF775485246999027B3197955);
        rate = dailyOut / 1 days;

    }

    function setUserAmount(uint amount_) public onlyOwner {
        userAmount = amount_;
    }

    function checkPoudage(uint amount_) public view returns (uint rew_, uint burn_, uint pool_){
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

    function coutingPoolDebt(uint pool_) public view returns (uint _debt){
        PoolInfo storage aa = poolInfo[pool_];

        _debt = aa.TVL > 0 ? (rate * 15 * aa.rate / 10000) * (block.timestamp - aa.lastTime) * acc / aa.TVL + aa.debt : 0 + aa.debt;
    }

    function calculatePool(uint pool_, address addr_) public view returns (uint rew_){
        if (userPool[addr_][pool_].stakeAmount == 0) {
            return 0;
        }
        uint tempDebt = coutingPoolDebt(pool_);
        uint rew = (tempDebt - userPool[addr_][pool_].debt) * userPool[addr_][pool_].stakeAmount / acc;
        return rew;
    }

    function checkUserClaimed(address addr_, uint pool_) public view returns (uint){
        (,,,uint claimed) = old.userPool(addr_, pool_);
        if (!done[addr_]) {
            return claimed;
        }
        return userPool[addr_][pool_].claimed;
    }


    function checkRew(address addr_, uint pool_) public view returns (uint){
        if (!done[addr_]) {
            return old.checkRew(addr_, pool_);
        }

        if (userPool[addr_][pool_].stakeAmount == 0) {
            return 0;
        }
        uint tempAmount = calculatePool(pool_, addr_) + userPool[addr_][pool_].toClaim;
        (uint rew_,,) = checkPoudage(tempAmount);
        return rew_;

    }

    function claimPool(uint pool_) public {
        (uint amount,uint debt,uint toClaim,uint claimed) = old.userPool(_msgSender(), pool_);
        if (!done[msg.sender]) {
            ( amount, debt, toClaim, claimed) = old.userPool(_msgSender(), 1);
            userPool[_msgSender()][1] = UserPool({
            stakeAmount : amount,
            debt : debt,
            toClaim : toClaim,
            claimed : claimed
            });
             ( amount, debt, toClaim, claimed) = old.userPool(_msgSender(), 2);
            userPool[_msgSender()][2] = UserPool({
            stakeAmount : amount,
            debt : debt,
            toClaim : toClaim,
            claimed : claimed
            });
            done[msg.sender] = true;
        }
        require(checkRew(_msgSender(), pool_) > 0, 'no amount');
        uint tempAmount = calculatePool(pool_, _msgSender()) + userPool[_msgSender()][pool_].toClaim;
        (uint rew,uint burn,uint pool) = checkPoudage(tempAmount);
        HKT.transfer(_msgSender(), rew);
        HKT.transfer(burnAddress, burn);
        HKT.transfer(nftPool, pool);
        userPool[_msgSender()][pool_].debt = coutingPoolDebt(pool_);
        userPool[_msgSender()][pool_].toClaim = 0;
        userPool[_msgSender()][pool_].claimed += rew;
        emit Claim(_msgSender(), tempAmount);
    }

    function checkUserStakeAmount(address addr_, uint pool_) external view returns (uint){
        (uint temp,,,) = old.userPool(addr_, pool_);
        if (!done[addr_]) {
            return temp;
        }
        return userPool[addr_][pool_].stakeAmount;
    }


    function deposite(uint amount_, uint pool_) public {
        (uint amount,uint debt,uint toClaim,uint claimed) = old.userPool(_msgSender(), pool_);
        if (!done[msg.sender]) {
            ( amount, debt, toClaim, claimed) = old.userPool(_msgSender(), 1);
            userPool[_msgSender()][1] = UserPool({
            stakeAmount : amount,
            debt : debt,
            toClaim : toClaim,
            claimed : claimed
            });
             ( amount, debt, toClaim, claimed) = old.userPool(_msgSender(), 2);
            userPool[_msgSender()][2] = UserPool({
            stakeAmount : amount,
            debt : debt,
            toClaim : toClaim,
            claimed : claimed
            });
            done[msg.sender] = true;
        }
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
        emit Deposite(_msgSender(), amount_, pool_);
    }

    function unDeposit(uint pool_) public {
        (uint amount,uint debt,uint toClaim,uint claimed) = old.userPool(_msgSender(), pool_);
        if (!done[msg.sender]) {
             ( amount, debt, toClaim, claimed) = old.userPool(_msgSender(), 1);
            userPool[_msgSender()][1] = UserPool({
            stakeAmount : amount,
            debt : debt,
            toClaim : toClaim,
            claimed : claimed
            });
             ( amount, debt, toClaim, claimed) = old.userPool(_msgSender(), 2);
            userPool[_msgSender()][2] = UserPool({
            stakeAmount : amount,
            debt : debt,
            toClaim : toClaim,
            claimed : claimed
            });
            done[msg.sender] = true;
        }
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
    function setAddress(address xxx,uint pool_) public onlyOwner{
        userPool[xxx][pool_] = UserPool({
            stakeAmount : 0,
            debt : 0,
            toClaim : 0,
            claimed : 0
            });
        done[xxx] = true;
    }

}