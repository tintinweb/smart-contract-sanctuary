pragma solidity >=0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PolkaBridge is ERC20, ERC20Detailed, ERC20Burnable {
    constructor(uint256 initialSupply)
        public
        ERC20Detailed("PolkaBridge", "PBR", 18)
    {
        _deploy(msg.sender, initialSupply, 1615766400); //15 Mar 2021 1615766400
    }

    //withdraw contract token
    //use for someone send token to contract
    //recuse wrong user

    function withdrawErc20(IERC20 token) public {
        token.transfer(tokenOwner, token.balanceOf(address(this)));
    }
}

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./PolkaBridge.sol";

// import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract PolkaBridgeMasterFarm is Ownable {
    string public name = "PolkaBridge: Deflationary Farming";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amountLP;
        uint256 rewardDebt;
        uint256 rewardDebtAtBlock;
        uint256 rewardClaimed;
    }

    struct PoolInfo {
        IERC20 lpToken;
        IERC20 tokenA;
        IERC20 tokenB;
        uint256 multiplier;
        uint256 lastPoolReward; //history pool reward
        uint256 lastRewardBlock;
        uint256 lastLPBalance;
        uint256 accPBRPerShare;
        uint256 startBlock;
        uint256 stopBlock;
        uint256 totalRewardClaimed;
        bool isActived;
    }

    PolkaBridge public polkaBridge;
    uint256 public START_BLOCK;

    //pool Info
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public poolId1;
    // Info of each user that stakes LP tokens. pid => user address => info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    constructor(PolkaBridge _polkaBridge, uint256 _startBlock) public {
        polkaBridge = _polkaBridge;
        START_BLOCK = _startBlock;
    }

    function poolBalance() public view returns (uint256) {
        return polkaBridge.balanceOf(address(this));
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(IERC20 _lpToken,IERC20 _tokenA, IERC20 _tokenB, uint256 _multiplier, uint256 _startBlock) public onlyOwner {
        require(
            poolId1[address(_lpToken)] == 0,
            "PolkaBridgeMasterFarm::add: lp is already in pool"
        );

        uint256 _lastRewardBlock =
            block.number > START_BLOCK ? block.number : START_BLOCK;

        poolId1[address(_lpToken)] = poolInfo.length + 1;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                tokenA: _tokenA,
                tokenB: _tokenB,
                multiplier: _multiplier,
                lastRewardBlock: _lastRewardBlock,
                lastPoolReward: 0,
                lastLPBalance: 0,
                accPBRPerShare: 0,
                startBlock: _startBlock > 0 ? _startBlock : block.number,
                stopBlock: 0,
                totalRewardClaimed: 0,
                isActived: true
            })
        );

        massUpdatePools();
    }

    function getChangePoolReward(uint256 _pid, uint256 _totalMultiplier) public view returns (uint256) {
        uint256 changePoolReward;
        if (_totalMultiplier == 0) {
            changePoolReward = 0;
        }
        else {
            uint256 currentPoolBalance = poolBalance();
            uint256 totalLastPoolReward = getTotalLastPoolReward();
            changePoolReward = ((currentPoolBalance.sub(totalLastPoolReward)).mul(poolInfo[_pid].multiplier).mul(1e18)).div(_totalMultiplier);
        }

        if (changePoolReward <= 0) {
            changePoolReward = 0;
        }

        return changePoolReward;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        uint256 totalMultiplier = countTotalMultiplier();
        for (uint256 pid = 0; pid < length; pid++) {
            if (poolInfo[pid].isActived) {
                uint256 changePoolReward = getChangePoolReward(pid, totalMultiplier);
                updatePool(pid, changePoolReward, 1);
            }
        }
    }

    function getTotalLastPoolReward() public view returns (uint256) {
        uint256 total;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            if (poolInfo[pid].isActived) {
                total += poolInfo[pid].lastPoolReward;
            }
        }
        return total;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(
        uint256 _pid,
        uint256 _changePoolReward,
        uint256 flag
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock && flag==1) {
            return;
        }
        uint256 lpSupply = pool.lastLPBalance;
        if (lpSupply == 0) { // first deposit
            pool.accPBRPerShare = 0;
        } else {
            pool.accPBRPerShare = pool.accPBRPerShare.add(
                (_changePoolReward.mul(1e18).div(lpSupply))
            );
        }
        pool.lastRewardBlock = block.number;

        if (flag == 1) {
            pool.lastPoolReward += _changePoolReward;
        } else {
            pool.lastPoolReward -= _changePoolReward;
        }

        pool.lastLPBalance = pool.lpToken.balanceOf(address(this));
    }

    function pendingReward(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 temptAccPBRPerShare = pool.accPBRPerShare;
        uint256 totalMultiplier = countTotalMultiplier();

        if (block.number > pool.lastRewardBlock && lpSupply > 0) {
            temptAccPBRPerShare = pool.accPBRPerShare.add(
                (getChangePoolReward(_pid, totalMultiplier).mul(1e18).div(lpSupply))
            );
        }

        uint256 pending = (
                user.amountLP.mul(temptAccPBRPerShare).sub(
                    user.rewardDebt.mul(1e18)
                )
            ).div(1e18);

        return pending;
    }

    function claimReward(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        massUpdatePools();
        _harvest(_pid);

        user.rewardDebt = user.amountLP.mul(pool.accPBRPerShare).div(1e18);
    }

    function _harvest(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amountLP > 0) {
            uint256 pending = pendingReward(_pid, msg.sender);
            uint256 masterBal = poolBalance();

            if (pending > masterBal) {
                pending = masterBal;
            }

            if (pending > 0) {
                polkaBridge.transfer(msg.sender, pending);
                pool.lastPoolReward -= pending;
                pool.totalRewardClaimed += pending;
            }

            user.rewardDebtAtBlock = block.number;
            user.rewardClaimed += pending;
        }
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        require(
            _amount > 0,
            "PolkaBridgeMasterFarmer::deposit: amount must be greater than 0"
        );

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        massUpdatePools();
        _harvest(_pid);

        if (user.amountLP == 0) {
            user.rewardDebtAtBlock = block.number;
        }

        user.amountLP = user.amountLP.add(_amount);
        user.rewardDebt = user.amountLP.mul(pool.accPBRPerShare).div(1e18);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            user.amountLP >= _amount,
            "PolkaBridgeMasterFarmer::withdraw: not good"
        );

        if (_amount > 0) {
            massUpdatePools();
            _harvest(_pid);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lastLPBalance = pool.lpToken.balanceOf(address(this));

            // update pool
            // updatePool(_pid, 0, 1);
            user.amountLP = user.amountLP.sub(_amount);
            user.rewardDebt = user.amountLP.mul(pool.accPBRPerShare).div(1e18);
        }
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amountLP);

        user.amountLP = 0;
        user.rewardDebt = 0;
    }

    function getPoolInfo(uint256 _pid)
        public
        view
        returns (
            uint256,
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            // bool,
            uint256
        )
    //uint256
    {
        return (
            poolInfo[_pid].lastRewardBlock,
            poolInfo[_pid].multiplier,
            address(poolInfo[_pid].lpToken),
            poolInfo[_pid].lastPoolReward,
            poolInfo[_pid].startBlock,
            poolInfo[_pid].accPBRPerShare,
            // poolInfo[_pid].isActived,
            poolInfo[_pid].lpToken.balanceOf(address(this))
            //poolInfo[_pid].lastLPBalance
        );
    }

    function getUserInfo(uint256 _pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        UserInfo memory user = userInfo[_pid][msg.sender];
        return (user.amountLP, user.rewardDebt, user.rewardClaimed);
    }

    function stopPool(uint256 pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.isActived = false;
        pool.stopBlock = block.number;
    }

    function activePool(uint256 pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.isActived = true;
        pool.stopBlock = 0;
    }

    function changeMultiplier(uint256 pid, uint256 _multiplier) public onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.multiplier = _multiplier;
    }

    function countActivePool() public view returns (uint256) {
        uint256 length = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].isActived) length++;
        }
        return length;
    }

    function countTotalMultiplier() public view returns (uint256) {
        uint256 totalMultiplier = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].isActived) totalMultiplier += poolInfo[i].multiplier;
        }
        return totalMultiplier.mul(1e18);
    }

    function totalRewardClaimed(uint256 _pid) public view returns (uint256) {
        return poolInfo[_pid].totalRewardClaimed;
    }

    function avgRewardPerBlock(uint256 _pid) public view returns (uint256) {
        uint256 totalMultiplier = countTotalMultiplier();
        uint256 changePoolReward = getChangePoolReward(_pid, totalMultiplier);
        uint256 totalReward = poolInfo[_pid].totalRewardClaimed + poolInfo[_pid].lastPoolReward + changePoolReward;
        uint256 changeBlock;
        if (block.number <= poolInfo[_pid].lastRewardBlock){
            changeBlock = poolInfo[_pid].lastRewardBlock.sub(poolInfo[_pid].startBlock);
        }
        else {
            changeBlock = block.number.sub(poolInfo[_pid].startBlock);
        }

        return totalReward.div(changeBlock);
    }

    receive() external payable {}
}

pragma solidity ^0.6.0;


contract Context {
  
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    struct PoolAddress{
        address poolReward;
        bool isActive;
        bool isExist;

    }

    struct WhitelistTransfer{
        address waddress;
        bool isActived;
        string name;

    }
    mapping (address => uint256) private _balances;

    mapping (address => WhitelistTransfer) public whitelistTransfer;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address[] rewardPool;
    mapping(address=>PoolAddress) mapRewardPool;
   
    address internal tokenOwner;
    uint256 internal beginFarming;

    function addRewardPool(address add) public {
        require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
        require(!mapRewardPool[add].isExist,"Pool already exist");
        mapRewardPool[add].poolReward=add;
        mapRewardPool[add].isActive=true;
        mapRewardPool[add].isExist=true;
        rewardPool.push(add);
    }

    function addWhitelistTransfer(address add, string memory name) public{
         require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
         whitelistTransfer[add].waddress=add;
        whitelistTransfer[add].isActived=true;
        whitelistTransfer[add].name=name;

    }

     function removeWhitelistTransfer(address add) public{
         require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
        
        whitelistTransfer[add].isActived=false;
        

    }



    function removeRewardPool(address add) public {
        require(_msgSender() == tokenOwner, "ERC20: Only owner can init");
        mapRewardPool[add].isActive=false;
       
        
    }

    function countActiveRewardPool() public  view returns (uint256){
        uint length=0;
     for(uint i=0;i<rewardPool.length;i++){
         if(mapRewardPool[rewardPool[i]].isActive){
             length++;
         }
     }
      return  length;
    }
   function getRewardPool(uint index) public view  returns (address){
    
        return rewardPool[index];
    }

   
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(whitelistTransfer[recipient].isActived || whitelistTransfer[_msgSender()].isActived){//withdraw from exchange will not effect
            _transferWithoutDeflationary(_msgSender(), recipient, amount);
        }
        else{
            _transfer(_msgSender(), recipient, amount);
        }
        
        return true;
    }
 function transferWithoutDeflationary(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWithoutDeflationary(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 burnAmount;
        uint256 rewardAmount;
         uint totalActivePool=countActiveRewardPool();
         if (block.timestamp > beginFarming && totalActivePool>0) {
            (burnAmount,rewardAmount)=_caculateExtractAmount(amount);

        }     
        //div reward
        if(rewardAmount>0){
           
            uint eachPoolShare=rewardAmount.div(totalActivePool);
            for(uint i=0;i<rewardPool.length;i++){
                 if(mapRewardPool[rewardPool[i]].isActive){
                    _balances[rewardPool[i]] = _balances[rewardPool[i]].add(eachPoolShare);
                    emit Transfer(sender, rewardPool[i], eachPoolShare);

                 }
                
       
            }
        }


        //burn token
        if(burnAmount>0){
          _burn(sender,burnAmount);
            _balances[sender] = _balances[sender].add(burnAmount);//because sender balance already sub in burn

        }
      
        
        uint256 newAmount=amount-burnAmount-rewardAmount;

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
      
        _balances[recipient] = _balances[recipient].add(newAmount);
        emit Transfer(sender, recipient, newAmount);

        
        
    }
    
 function _transferWithoutDeflationary(address sender, address recipient, uint256 amount) internal virtual {
          require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        
    }
    
    function _deploy(address account, uint256 amount,uint256 beginFarmingDate) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        tokenOwner = account;
        beginFarming=beginFarmingDate;

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    
    function _caculateExtractAmount(uint256 amount)
        internal
        
        returns (uint256, uint256)
    {
       
            uint256 extractAmount = (amount * 5) / 1000;

            uint256 burnAmount = (extractAmount * 10) / 100;
            uint256 rewardAmount = (extractAmount * 90) / 100;

            return (burnAmount, rewardAmount);
      
    }

    function setBeginDeflationFarming(uint256 beginDate) public {
        require(msg.sender == tokenOwner, "ERC20: Only owner can call");
        beginFarming = beginDate;
    }

    function getBeginDeflationary() public view returns (uint256) {
        return beginFarming;
    }

    

}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";


contract ERC20Burnable is Context, ERC20 {
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

  
    function burnFrom(address account, uint256 amount) public virtual {
        _burnFrom(account, amount);
    }
}

pragma solidity ^0.6.0;

import "./IERC20.sol";


abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

   
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.6.0;


interface IERC20 {
   
    function totalSupply() external view returns (uint256);

  
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferWithoutDeflationary(address recipient, uint256 amount) external returns (bool) ;
   
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}