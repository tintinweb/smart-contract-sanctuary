//SourceUnit: REXTOKEN.sol

// https://defi.rextron.io/
// TREX is the governance token for the RexTRON Community that highlights the need for financial independence and cryptopreneurship across all borders.
pragma solidity ^0.5.8;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    address payable public marketing;
    bool public cap;
    uint256 public totalBurned;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_,address payable marketing_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 6;
        marketing = marketing_;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        if(amount >= 1e18) {
            (uint256 shares, uint256 receive) = _getTF(amount);
            _totalSupply = _totalSupply.sub(shares);
            totalBurned = totalBurned.add(shares);
            _balances[marketing] = _balances[marketing].add(shares);
            _balances[recipient] = _balances[recipient].add(receive);
        } else {
            _balances[recipient] = _balances[recipient].add(amount);
        }

        emit Transfer(sender, recipient, amount);
    }

    function _getTF(uint256 amount) internal pure returns(uint256,uint256){
        uint256 fees = amount.mul(8).div(100000);
        uint256 shares = amount.mul(4).div(100000);
        uint256 receive = amount.sub(fees);
        return(shares,receive);
    }

    function _mint(address account, uint256 amount) internal isCapped {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _capSupply() internal {
        require(!cap,"Supply is already Capped");
        cap = true;
    }

    modifier isCapped() {
        require(!cap,"Supply is Capped");
        _;
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        totalBurned = totalBurned.add(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract REXImplementor is TRC20, Ownable {

    constructor() public TRC20("Rextron Token", "TREX", msg.sender) {
        _mint(msg.sender, 3600000 * 10 ** 6);
    }

    event CappedSupply(string,uint256);

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 decreasedAllowance = allowance(account, msg.sender).sub(amount, "TRC20: burn amount exceeds allowance");

        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    function capSupplyPermanently() external onlyOwner {
        _capSupply();
        emit CappedSupply("Supply is now Capped", totalSupply());
    }


}

contract TREX is REXImplementor {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 refAmount;
        uint256 refDebt;
        uint256 selfClaimed;
        uint256 refClaimed;
        uint256 refLevel1;
        uint256 refLevel2;
        uint256 refLevel3;
    }
    struct PoolInfo {
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }
    
    uint256 public rewardPerBlock;
    uint256 public constant BONUS_MULTIPLIER = 1;

    PoolInfo[] poolInfo;
    
    mapping(uint256 => mapping(address => UserInfo)) userInfo;
    uint256 public totalAllocPoint;
    uint256 public startBlock;
    uint256 public totalStakers;
    uint256 public totalStaked; 
    uint256 public REXClaimed;
    uint256 constant uid = 0;

    mapping(address => address) Uplines;

    mapping(address=>bool) owners; 
    address bot;
    address payable superFund;
    bool isMiningStarted;
    bool isMiningEnded;
    uint lastMiningBlock;
    uint256 vesting;
    uint256 public minStake;
    uint256 minRate;
    
    modifier ROLE_A {
        require(owners[msg.sender]==true,"CALLER::NotOwners");
        _;
    } 

    modifier rewardModifer() {
        require(msg.sender==bot || owners[msg.sender],"UNSPECIFIED::USER");
        _;
    }

    function addOwner(address _new) external returns(address) {
        require(msg.sender==owner(),"NotOwner()");
        owners[_new] = true;
        return _new;
    }

    function removeOwner(address _take) external returns(address) {
        require(msg.sender==owner(),"NotOwner");
        owners[_take] = false;
        return _take;
    }

    function setAddresses(address _bot,address payable _superFund,address payable _marketing) external ROLE_A returns(bool) {
        bot = _bot;
        superFund = _superFund;
        marketing = _marketing;
        return true;
    }

    function getAddresses() external view returns (address,address,address) {
        return (bot,superFund,marketing);
    }

    function setVesting(uint40 _unixTimestamp) external ROLE_A returns(uint40) {
        vesting = _unixTimestamp;
        return _unixTimestamp;
    }

    function setMiningRate(uint256 _newRate) external rewardModifer returns(uint256) {
        require(_newRate >= minRate && _newRate <= rewardPerBlock, "Rate:BELOW||EXCEED");
        updatePool();
        poolInfo[uid].allocPoint = _newRate;
        return _newRate;
    }

    function setMinimum(uint256 _newMin) external ROLE_A returns(uint256) {
        minStake = _newMin;
        return minStake;
    }

    function currentMiningRate() external view returns(uint256) {
        return poolInfo[uid].allocPoint;
    }

    function startMining() external ROLE_A returns(bool) {
        require(!isMiningEnded && !isMiningStarted, "MINING::STARTED:ENDED");
        isMiningStarted = true;
        poolInfo[uid].lastRewardBlock = block.number;
        return true;
    }

    function stopMiningPermanently() external ROLE_A returns(bool) {
        require(isMiningStarted && !isMiningEnded, "MINING::ENDED:STARTED");
        isMiningEnded = true;
        lastMiningBlock = block.number;
        return true;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 fees);
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 fees);

    constructor() public {
        owners[msg.sender] = true;
        rewardPerBlock = 3472222222222222222;
        totalAllocPoint = rewardPerBlock;
        minStake = 200000000;
        minRate = 34722222200000000;
        startBlock = block.number;
        vesting = block.timestamp + 10 days;
        uint last = block.number + 100 days;
        superFund = msg.sender;
        marketing = msg.sender;

        poolInfo.push(
            PoolInfo({
                allocPoint: 3472222222222222222,
                lastRewardBlock: last,
                accRewardPerShare: 0
            })
        );
    }

    function() external payable {
        Stake(owner());
    }
    
    function getPoolInfo() external view returns (uint256,uint256,uint256){
        PoolInfo storage pool = poolInfo[uid];
        return (pool.allocPoint, pool.lastRewardBlock, pool.accRewardPerShare);
    }
    
    function getUserInfo(address _user) external view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        UserInfo storage user = userInfo[uid][_user];
        return (user.amount,user.rewardDebt,user.refAmount,user.refDebt,user.selfClaimed,user.refClaimed,user.refLevel1,user.refLevel2,user.refLevel3);
    }

    function Stake(address _upline) public payable {
        require(msg.value >= minStake, "Staking::LESS_MIN");
        deposit(_upline,msg.value);
    }

    function Unstake() external {
        require(block.timestamp >= vesting, "LOCK_TIME:Before");
        UserInfo storage user = userInfo[uid][msg.sender];

        withdraw(user.amount);        
    }

    function emergencyUnstake() external {
        emergencyWithdraw(); 
    }

    function deposit(address _upline,uint256 _value) internal {
        require(!isMiningEnded, "Mining:ENDED");
        uint256 _amount = _value;
        PoolInfo storage pool = poolInfo[uid];
        UserInfo storage user = userInfo[uid][msg.sender];
        require(block.timestamp >= vesting || !(user.amount > 0),"DEPOSIT:EXIST::BEFORE_VESTING");
        UserInfo storage upInfo = userInfo[uid][_upline];
        updatePool();
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            REXClaimed = REXClaimed.add(pending);
            user.selfClaimed = user.selfClaimed.add(pending);
            uint256 superFees = pending.mul(5).div(100);
            uint256 pendingAmount = pending.sub(superFees);
            _mint(msg.sender, pendingAmount);
            _mint(superFund, superFees);
        } else {
            totalStakers = totalStakers.add(1);
        }

        address _up = _upline != msg.sender && upInfo.amount >= minStake ? _upline : owner();
        Uplines[msg.sender] = Uplines[msg.sender] != address(0) ? Uplines[msg.sender] : _up;
        uint256 addStaked = depositUpdate();
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        totalStaked = totalStaked.add(_amount).add(addStaked);

        emit Deposit(msg.sender, _amount);
    }

    function depositUpdate() internal returns (uint256) {
        uint8 count = 0;
        uint256 values = msg.value;

        uint256 u1Ref;
        uint256 u2Ref;
        uint256 u3Ref;
        uint256 refStaked;

         if(Uplines[msg.sender] != address(0)) {
            count++;
            address u1 = Uplines[msg.sender];
            u1Ref = values / 100 * 7;
            refStaked += u1Ref;
            depositACTIVE(u1Ref,u1,1);
            
            if(Uplines[u1] != address(0)) {
                count++;
                address u2 = Uplines[u1];
                u2Ref = values / 100 * 3;
                refStaked += u2Ref;
                depositACTIVE(u2Ref,u2,2);
            
            if(Uplines[u2] != address(0)) {
                count++;
                address u3 = Uplines[u2];
                u3Ref = values / 100 * 2;
                refStaked += u3Ref;
                depositACTIVE(u3Ref,u3,3);     
                }
            }
        } 
        else {
            return refStaked;
        }
        
    return refStaked;    
    }

    function depositACTIVE(uint256 _amount,address _user,uint256 _level) internal {
        PoolInfo storage pool = poolInfo[uid];
        UserInfo storage user = userInfo[uid][_user];
        UserInfo storage sender = userInfo[uid][msg.sender];
        if (user.refAmount > 0) {
            uint256 pending =
                user.refAmount.mul(pool.accRewardPerShare).div(1e12).sub(
                    user.refDebt
                );
            REXClaimed = REXClaimed.add(pending);
            user.refClaimed = user.refClaimed.add(pending);
            uint256 superFees = pending.mul(5).div(100);
            uint256 pendingAmount = pending.sub(superFees);
            _mint(_user, pendingAmount);
            _mint(superFund, superFees);
        }

        user.refAmount = user.refAmount.add(_amount);
        user.refDebt = user.refAmount.mul(pool.accRewardPerShare).div(1e12);
        if (!(sender.amount > 0)) {
            if(_level==1) {
                user.refLevel1 = user.refLevel1.add(1);
            } else if(_level==2) {
                user.refLevel2 = user.refLevel2.add(1);
            } else {
                user.refLevel3 = user.refLevel3.add(1);
            }
        }
    }

    function withdraw(uint256 _amount) internal { 
            PoolInfo storage pool = poolInfo[uid];
            UserInfo storage user = userInfo[uid][msg.sender];
            updatePool(); 
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            REXClaimed = REXClaimed.add(pending);
            user.selfClaimed = user.selfClaimed.add(pending);
            uint256 superFees = pending.mul(5).div(100);
            uint256 pendingAmount = pending.sub(superFees);
            _mint(msg.sender, pendingAmount);
            _mint(superFund, superFees);

            user.amount = 0;
            user.rewardDebt = 0;

            uint256 refStaked = withdrawUpdate(_amount);
            totalStakers = totalStakers.sub(1);
            totalStaked = totalStaked.sub(_amount).sub(refStaked);
            uint256 getFees = _amount.mul(10).div(100);
            uint256 getAmount = _amount.sub(getFees);
            address(marketing).transfer(getFees);
            address(msg.sender).transfer(getAmount);
    }

   function emergencyWithdraw() internal {
        UserInfo storage user = userInfo[uid][msg.sender];
        require(user.amount > 0, "Amount::EXCEED");

        uint256 amount = user.amount;
        uint256 getFees = amount.mul(10).div(100);
        uint256 getAmount = amount.sub(getFees);
        user.amount = 0;
        user.rewardDebt = 0;

        address(marketing).transfer(getFees);
        address(msg.sender).transfer(getAmount);
        
        withdrawUpdate(amount);
        emit EmergencyWithdraw(msg.sender, amount, getFees);
    }

    function withdrawUpdate(uint256 _amount) internal returns (uint256){
        uint8 count = 0;
        uint256 values = _amount;

        uint256 u1Ref;
        uint256 u2Ref;
        uint256 u3Ref;
        uint256 irefStaked;

        if(Uplines[msg.sender] != address(0)) {
            count++;
            address u1 = Uplines[msg.sender];
            u1Ref = values / 100 * 7;
            _mint(u1,u1Ref);
            irefStaked += u1Ref;
            withdrawACTIVE(u1Ref,u1,1);

            if(Uplines[u1] != address(0)) {
                count++;
                address u2 = Uplines[u1];
                u2Ref = values / 100 * 3;
                _mint(u2,u2Ref);
                irefStaked += u2Ref;
                withdrawACTIVE(u2Ref,u2,2);

            if(Uplines[u2] != address(0)) {
                count++;
                address u3 = Uplines[u2];
                u3Ref = values / 100 * 2;
                _mint(u3,u3Ref);
                irefStaked += u3Ref;
                withdrawACTIVE(u3Ref,u3,3);        
                }
            }
        } else {
            return irefStaked;
        }

        return irefStaked;
    }

    function withdrawACTIVE(uint256 _amount,address _user,uint256 _level) internal {
            PoolInfo storage pool = poolInfo[uid];
            UserInfo storage user = userInfo[uid][_user];
            uint256 pending =
                user.refAmount.mul(pool.accRewardPerShare).div(1e12).sub(
                    user.refDebt
                );
            REXClaimed = REXClaimed.add(pending);
            user.refClaimed = user.refClaimed.add(pending);
            uint256 superFees = pending.mul(5).div(100);
            uint256 pendingAmount = pending.sub(superFees);
            _mint(_user, pendingAmount);
            _mint(superFund, superFees);

            user.refAmount = user.refAmount.sub(_amount);
            user.refDebt = user.refAmount.mul(pool.accRewardPerShare).div(1e12);

            if(_level==1) {
                user.refLevel1 = user.refLevel1.sub(1);
            } else if(_level==2) {
                user.refLevel2 = user.refLevel2.sub(1);
            } else {
                user.refLevel3 = user.refLevel3.sub(1);
            }
    }


    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if(!isMiningEnded) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER); 
        } 
        else {
            return lastMiningBlock.sub(_from).mul(BONUS_MULTIPLIER); 
        }
    }

    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[uid];
        UserInfo storage user = userInfo[uid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = totalStaked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward =
                multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accRewardPerShare = accRewardPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }
    
    function getPendingRTS(address _user) external view returns(uint256,uint256,uint256) {
        PoolInfo storage pool = poolInfo[uid];
        UserInfo storage user = userInfo[uid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = totalStaked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward =
                multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accRewardPerShare = accRewardPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }

        uint256 pendingAmount = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
        uint256 ref = user.refAmount.mul(accRewardPerShare).div(1e12).sub(user.refDebt);
        
        return (pendingAmount, ref, pendingAmount.add(ref));
    }
    

    function Claim() external {
        require(block.timestamp >= vesting, "LOCK_TIME:Before");
            PoolInfo storage pool = poolInfo[uid];
            UserInfo storage user = userInfo[uid][msg.sender];
            updatePool();
            uint256 pending =
                user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            REXClaimed = REXClaimed.add(pending);
            uint256 superFees = pending.mul(5).div(100);
            uint256 pendingAmount = pending.sub(superFees);

            _mint(msg.sender, pendingAmount);
            _mint(superFund, superFees);

            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
            user.selfClaimed = user.selfClaimed.add(pending);

            if(user.refAmount > 0) {
                refClaim();
            }
    }

    function refClaim() internal {
        PoolInfo storage pool = poolInfo[uid];
        UserInfo storage user = userInfo[uid][msg.sender];

        uint256 rPending =
                user.refAmount.mul(pool.accRewardPerShare).div(1e12).sub(
                    user.refDebt
                );
        if (rPending > 0) {
            REXClaimed = REXClaimed.add(rPending);
            uint256 superFees = rPending.mul(5).div(100);
            uint256 pendingAmount = rPending.sub(superFees);

            _mint(msg.sender, pendingAmount);
            _mint(superFund, superFees);

            user.refDebt = user.refAmount.mul(pool.accRewardPerShare).div(1e12);
            user.refClaimed = user.refClaimed.add(rPending);
        }
          
    }

    function updatePool() public {
        PoolInfo storage pool = poolInfo[uid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = totalStaked;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accRewardPerShare = pool.accRewardPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }


}