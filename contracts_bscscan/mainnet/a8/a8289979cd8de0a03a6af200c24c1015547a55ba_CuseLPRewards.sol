/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity ^0.5.0;

/**
 * @title CuseLPRewards
**/
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address receiver) external returns(uint256);
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Util {
    uint usdtWei = 1e18;
    
    function compareStr(string memory _str, string memory str) internal pure returns(bool) {
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
            return true;
        }
        return false;
    }
}

contract Context {
    constructor() internal {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

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
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context, Ownable {
    using Roles for Roles.Role;

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelist(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelist(_msgSender()) || isOwner(), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function addWhitelist(address account) public onlyWhitelistAdmin {
        _addWhitelist(account);
    }

    function removeWhitelist(address account) public onlyOwner {
        _whitelistAdmins.remove(account);
    }
    
    function isWhitelist(address account) private view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function _addWhitelist(address account) internal {
        _whitelistAdmins.add(account);
    }

}

contract CoinTokenWrapper {
    
    using SafeMath for *;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    
    //LP
    IERC20 public coin;
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        coin.transferFrom(msg.sender, address(this), amount);
    }
    
    function withdraw(uint256 amount) public returns (bool){
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        return takeInner(msg.sender, amount);
    }
    
    //余额检查
    function isEnoughBalance(uint sendMoney) internal returns (bool, uint){
        uint _balance = coin.balanceOf(address(this));
        if (sendMoney >=  _balance) {
            return (false, _balance);
        } else {
            return (true, sendMoney);
        }
    }
    
    //取钱
    function takeInner(address payable userAddress, uint money) internal returns (bool){
        bool flag;
        uint sendMoney;
        (flag, sendMoney) = isEnoughBalance(money);
        if (sendMoney > 0) {
            coin.transfer(userAddress,sendMoney);
        }
        return (flag);
    }
    
}

contract CuseLPRewards is Util, WhitelistAdminRole,CoinTokenWrapper {
    
    string constant private name = "CuseLPRewards";
    
    struct User{
        uint id;
        string referrer;
        uint allInvest;
        uint freezeAmount;
        uint allDynamicAmount;
        uint hisDynamicAmount;
        //直推人数
        uint inviteAmount;
	    //挖矿总奖励
        uint hisCuseAward;
    }
    
    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
    }
    
    uint investMoney;
    uint public uid = 0;
    uint public pid = 0;
    uint rid = 1;
    uint poolFee = 10 * usdtWei;
    mapping (uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping (string => address) addressMapping;
    
    //==============================================================================
    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;
        
        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }
    
    event LogInvestIn(address indexed who, uint indexed uid, uint amount, uint time, string inviteCode, string referrer);
    event LogWithdrawProfit(address indexed who, uint indexed uid, uint amount, uint time);
    
    //==============================================================================
    // Constructor
    //==============================================================================
    constructor (address _coinAddress,address _ercTokenAddr) public {
        coin = IERC20(_coinAddress);
        erc = IERC20(_ercTokenAddr);
    }
    
    function () external payable {
    }
    
    //新用户加入圈子
    function join(string memory cirInviteCode)
        public
        updateReward(msg.sender)
        checkStart 
        isHuman()
    {
        User storage user = userRoundMapping[rid][msg.sender];
        if (user.id == 0) {
            require(!compareStr(cirInviteCode, ""), "empty pool invite code");
            //根据圈子码找到圈主
            address referrerAddr = getUserAddressByCode(cirInviteCode);
            require(uint(referrerAddr) != 0, "poolInviteCode not exist");
            
            uid++;
            user.id = uid;
            
            //如果是圈主则无绑定推荐人
            if(referrerAddr != msg.sender){
                user.referrer = cirInviteCode;   //圈子码
            }
            
            //给圈主的邀请人数+1
            userRoundMapping[rid][referrerAddr].inviteAmount++;
        }
    }
    
    //投资
    function investIn(string memory cirInviteCode,uint256 value)
        public
        updateReward(msg.sender)
        checkStart 
        isHuman()
    {
        //是否是新用户
        User storage user = userRoundMapping[rid][msg.sender];
        if (user.id != 0) {
            user.allInvest = user.allInvest.add(value);
            user.freezeAmount = user.freezeAmount.add(value);
        } else {
            require(!compareStr(cirInviteCode, ""), "empty pool invite code");
            //根据圈子码找到圈主
            address referrerAddr = getUserAddressByCode(cirInviteCode);
            require(uint(referrerAddr) != 0, "poolInviteCode not exist");
            
            uid++;
            user.id = uid;
            user.allInvest = value;
            user.freezeAmount = value;
            
            //如果是圈主则无绑定推荐人
            if(referrerAddr != msg.sender){
                user.referrer = cirInviteCode;   //圈子码
            }
            
            //给圈主的邀请人数+1
            userRoundMapping[rid][referrerAddr].inviteAmount++;
        }
        
        investMoney = investMoney.add(value);
	    
        //挖矿
        super.stake(value);
        emit LogInvestIn(msg.sender, user.id, value, now, "", user.referrer);
    }
    
    function isUsed(string memory code) public view returns(bool) {
        address user = getUserAddressByCode(code);
        return uint(user) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns(address) {
        return addressMapping[code];
    }
    
    function getMiningInfo(address _user) public view returns(uint[22] memory ct,string memory inviteCode, string memory referrer,address poolAddr) {
        User memory userInfo = userRoundMapping[rid][_user];
        
        uint poolInviteAmount;
        address referrerAddr;
        if (!compareStr(userInfo.referrer, "")) {   //会员
            referrerAddr = getUserAddressByCode(userInfo.referrer);
            User storage user = userRoundMapping[rid][referrerAddr];
            poolInviteAmount = user.inviteAmount;
        }else {
            //圈主
            UserGlobal storage userGlobal = userMapping[_user];
            if(userGlobal.id != 0){
                referrerAddr = _user;
                poolInviteAmount = userInfo.inviteAmount;
            }
        }
        
        uint256 earned = earned(_user);
        
        ct[0] = totalSupply();
        ct[1] = investMoney;
        ct[2] = periodFinish;
        ct[3] = initreward;
        ct[4] = status;
        
        //USER INFO
        ct[5] = userInfo.allInvest;
        ct[6] = userInfo.freezeAmount;
        ct[7] = 0;
        ct[8] = userInfo.hisCuseAward;
        ct[9] = 0;
        ct[10] = 0;
        ct[11] = 0;
        
        ct[12] = 0;
        ct[13] = poolInviteAmount;
        ct[14] = 0;
        ct[15] = turnover;
        ct[16] = earned;
        
        ct[17] = 0;
        ct[18] = 0;
        ct[19] = 0;
        ct[20] = userInfo.allDynamicAmount;
        ct[21] = userInfo.hisDynamicAmount;
        
        inviteCode = userMapping[_user].inviteCode;
        referrer = userInfo.referrer;
        poolAddr = referrerAddr;
        
        return (
            ct,
            inviteCode,
            referrer,
            poolAddr
        );
    }
    
    function cretaePool(string calldata inviteCode) external {
        require(!compareStr(inviteCode, ""), "empty invite code");
        require(!isUsed(inviteCode), "invite code is used");
        
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id == 0, "user exist");
        
        UserGlobal storage userGlobal = userMapping[msg.sender];
        require(userGlobal.id == 0, "pool exist");
        
        erc.transferFrom(msg.sender, address(this), poolFee);
        erc.transfer(0x0000000000000000000000000000000000000010,poolFee);
        registerUser(msg.sender, inviteCode, "");
        emit PoolCreate(msg.sender,inviteCode);
    }
    
    function registerUser(address user, string memory inviteCode, string memory referrer) private {
        UserGlobal storage userGlobal = userMapping[user];
        pid++;
        userGlobal.id = pid;
        userGlobal.userAddress = user;
        userGlobal.inviteCode = inviteCode;
        userGlobal.referrer = referrer;
        
        addressMapping[inviteCode] = user;
    }
    
    //------------------------------挖矿逻辑
    IERC20 erc;
    uint256 public initreward = 0;
    uint256 turnover;
    
     //为0则是头矿，为1则是正常
    uint256 status = 0;  
    //utc+8 2021-03-28 17:37:12
    uint256 public starttime = 1616924232; 
    //挖矿完成时间
    uint256 public periodFinish = 0;
    //奖励比例
    uint256 public rewardRate = 0;  
    //最后更新时间
    uint256 public lastUpdateTime;
    //每个存储的令牌奖励
    uint256 public rewardPerTokenStored;
    //每支付一个代币的用户奖励
    mapping(address => uint256) public userRewardPerTokenPaid;  
    //用户奖励
    mapping(address => uint256) public rewards; 
    
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event PoolCreate(address indexed user, string poolCode);
    event Withdrawn(address indexed user, uint256 amount);
    
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return SafeMath.min(block.timestamp, periodFinish);
    }
    
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }
    
    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }
    
    function withdraw(uint256 amount) public updateReward(msg.sender) checkStart returns (bool){
        require(amount > 0, "Cannot withdraw 0");
        bool flag = super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
        
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");
        user.freezeAmount = user.freezeAmount.sub(amount);
        return (flag);
    }
    
    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }
    
    function getReward() public updateReward(msg.sender) checkStart {
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");
        
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            uint staticReward = reward.mul(80).div(100);
            //累计用户静态挖矿收益
            user.hisCuseAward = user.hisCuseAward.add(staticReward);
            //加上推荐奖
            staticReward = staticReward.add(user.allDynamicAmount);
            //流通量
            turnover = turnover.add(staticReward);
            
            rewards[msg.sender] = 0;
            erc.transfer(msg.sender, staticReward);
            user.allDynamicAmount = 0;
            emit RewardPaid(msg.sender, staticReward);
            
            //分润
            tjUserFiveLevel(user.referrer,reward);
        }
    }
    
    //统计1级分润
    function tjUserFiveLevel(string memory referrer, uint amount) private {
        string memory tmpReferrer = referrer;
        
        for (uint i = 1; i <= 1; i++) {
            if (compareStr(tmpReferrer, "")) {
                break;
            }
            
            address tmpUserAddr = addressMapping[tmpReferrer];
            User storage calUser = userRoundMapping[rid][tmpUserAddr];
            if (calUser.id == 0) {
                break;
            }
            
            //如果用户已出局空点则无收益
            if(calUser.freezeAmount <= 0){
                tmpReferrer = calUser.referrer;
                continue;
            }
            
            //矿池奖励
           uint levelAward = amount.mul(10).div(100);
           calUser.allDynamicAmount = calUser.allDynamicAmount.add(levelAward);
           calUser.hisDynamicAmount = calUser.hisDynamicAmount.add(levelAward);
           tmpReferrer = calUser.referrer;
        }
    }
    
    modifier checkStart(){
        require(block.timestamp > starttime,"not start");
        _;
    }
    
    function notifyRewardAmount()
        external
        onlyWhitelistAdmin
        updateReward(address(0))
    {
        uint256 reward = 1000000 * 1e18;
        uint256 INIT_DURATION = 10 days;
        initreward = reward;
        
        rewardRate = reward.div(INIT_DURATION);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(INIT_DURATION);
        emit RewardAdded(reward);
    }
    
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div zero"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "lower sub bigger");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "overflow");

        return c;
    }

}