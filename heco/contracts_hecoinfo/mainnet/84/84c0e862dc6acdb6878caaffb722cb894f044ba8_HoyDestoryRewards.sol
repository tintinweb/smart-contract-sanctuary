/**
 *Submitted for verification at hecoinfo.com on 2022-06-02
*/

pragma solidity ^0.6.12;

//SPDX-License-Identifier: MIT

/**
 * @title HoyDestory
**/
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address receiver) external returns(uint256);
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }

}

contract HoyDestoryRewards is Util, WhitelistAdminRole,CoinTokenWrapper {
    
    string constant private name = "HoyDestoryRewards";
    
    struct User{
        uint id;
        string referrer;
        uint allInvest;
        uint freezeAmount;
        uint allDynamicAmount;
        uint hisDynamicAmount;
        uint inviteAmount;
        uint hisHoyAward;
    }
    
    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
    }
    
    uint investMoney;
    uint uid = 0;
    uint rid = 1;
    mapping (uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping (string => address) addressMapping;

    IUniswapV2Router02 public immutable uniswapV2Router;

    mapping(address => bool) supportTokenMapping;   //支持的token列表
    mapping(address => uint) tokenMultihopMapping; //合约是否多跳
    
    mapping(address => uint) tokenDestoryMapping;   //token总销毁
    mapping(address => mapping(uint => uint)) tokenEarningsMapping; //每个token用户的销毁

    mapping(address => mapping(uint => uint)) tokenUsdtMapping; //每个token用户的算力

    mapping(address=> bool) public bannedUser;
    
    //==============================================================================
    address destroyAddr = 0x000000000000000000000000000000000000dEaD;
    //正式的usdt
    address usdtAddr = 0xa71EdC38d189767582C38A3145b5873052c3e47a;
    IERC20 usdtToken = IERC20(usdtAddr);
    //分红地址
    address dividendTracker = 0xf8FE0d9283a54AF523c13014d262ea7709d009bb;
    
    //HBY
    IERC20 hbyToken = IERC20(0x5c0A02cCBc5eb09eeF6773A161c6ccbe746fD29B);
    //CHE
    IERC20 cheToken = IERC20(0x6f8460476BaCB3125d4726B7670b65A69900948C);
    //HOY
    IERC20 hoyToken = IERC20(0x7dD66d79bC2f1410c29E6c2c13cc21417CAddb77);
    //单账户最大不能超过1500U
    uint limitMaxInvest = 1500 * usdtWei;
    
    event LogInvestIn(address indexed who, uint indexed uid, uint amount, uint time, address token, uint usdtValue);
    event LogWithdrawProfit(address indexed who, uint indexed uid, uint amount, uint time);
    
    //==============================================================================
    // Constructor
    //==============================================================================
    constructor () public {
        address _ercTokenAddr = address(hoyToken);
        erc = IERC20(_ercTokenAddr);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xED7d5F38C79115ca12fe6C0041abb22F0A06C300);
        uniswapV2Router = _uniswapV2Router;

        //init suport token
        supportTokenMapping[address(hbyToken)] = true;
        tokenMultihopMapping[address(hbyToken)] = 1;
        
        supportTokenMapping[address(cheToken)] = true;
        tokenMultihopMapping[address(cheToken)] = 0;

        supportTokenMapping[address(hoyToken)] = true;
        tokenMultihopMapping[address(hoyToken)] = 0;
    }

    receive() external payable{}

    function getTokenPrice(address token1,address token2, uint amt) public view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        uint256[] memory result = uniswapV2Router.getAmountsOut(amt, path);
        return result[1];
    }

    function getTokenPriceMultihop(address token1,address token2, uint amt) public view returns(uint256) {
        address wht = 0x5545153CCFcA01fbd7Dd11C0b23ba694D9509A6F;
        
        address[] memory path = new address[](3);
        path[0] = token1;
        path[1] = wht;
        path[2] = token2;
        uint256[] memory result = uniswapV2Router.getAmountsOut(amt, path);
        return result[2];
    }
    
    //投资-传入的是算力
    function investIn(address token,uint256 value)
        public
        updateReward(msg.sender)
        checkStart 
    {
        require(supportTokenMapping[token], "Unsupported token");
        // require(value >= 100 * usdtWei, "The minimum bet is 100 USDT");
        
        //根据销毁的算力，计算出需要销毁的HBY数量，然后将HBY直接销毁
        uint256 destroyToken;
        if(tokenMultihopMapping[token] >= 1){
            destroyToken = getTokenPriceMultihop(usdtAddr,token,value);
        }else{
            destroyToken = getTokenPrice(usdtAddr,token,value);
        }
        //IERC20(token).transferFrom(msg.sender,destroyAddr,destroyToken);
        
        //是否是新用户
        User storage user = userRoundMapping[rid][msg.sender];
        if (user.id != 0) {
            user.allInvest = user.allInvest.add(value);
            
            //累计用户销毁的Token
            tokenEarningsMapping[token][user.id] += destroyToken;
            tokenUsdtMapping[token][user.id] += value;
        } else {
            uid++;
            user.id = uid;
            user.allInvest = value;
            
            //累计用户销毁的Token
            tokenEarningsMapping[token][user.id] += destroyToken;
            tokenUsdtMapping[token][user.id] += value;
        }
        
        //单账户算力限制（打散大户机制）
        require(tokenUsdtMapping[token][user.id] <= limitMaxInvest, "Exceeding maximum limit");
        
        //全网总算力
        investMoney = investMoney.add(value);
        
        //token累计总销毁
        tokenDestoryMapping[token] += destroyToken;
	    
        //放大四倍算力
        uint newLimitAmount = value.mul(4);   
        //挖矿
        super.stake(newLimitAmount);
        
        emit LogInvestIn(msg.sender, user.id, value, now, token, destroyToken);
    }

    function destroyHoy() public updateReward(msg.sender) checkStart {
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");

        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            uint staticReward = reward.mul(88).div(100);

            //提现手续费12%用于分红
            uint withdrawFee = reward.mul(12).div(100);
            //hoyToken.transfer(dividendTracker, withdrawFee);
            emit RewardDividend(dividendTracker, withdrawFee);
            
            //累计用户静态挖矿收益
            user.hisHoyAward = user.hisHoyAward.add(staticReward);
            
            rewards[msg.sender] = 0;
            //hoyToken.transfer(destroyAddr, staticReward);
            
            //HBY总销毁数增加
            tokenDestoryMapping[address(hoyToken)] += staticReward;
            
            //计算U本位
            uint256 tokenValueUsdt = getTokenPrice(address(hoyToken),usdtAddr,staticReward);
            uint doubleHash =  tokenValueUsdt.mul(2);
            
            //挖矿算力增加
            super.stake(doubleHash);
            emit RewardPaid(msg.sender, doubleHash);
        }
    }
    
    function getMiningInfo(address _user) public view returns(uint[20] memory ct,string memory inviteCode, string memory referrer) {
        User memory userInfo = userRoundMapping[rid][_user];
        
        uint256 earned = earned(_user);
        
        ct[0] = totalSupply();
        ct[1] = investMoney;
        ct[2] = periodFinish;
        ct[3] = initreward;
        ct[4] = turnover;
        
        //USER INFO
        ct[5] = userInfo.allInvest;
        ct[6] = userInfo.freezeAmount;
        ct[7] = userInfo.hisHoyAward;
        ct[8] = earned;
        ct[9] = tokenEarningsMapping[address(hbyToken)][userInfo.id];
        ct[10] = tokenEarningsMapping[address(cheToken)][userInfo.id];
        ct[11] = tokenDestoryMapping[address(hbyToken)];
        ct[12] = tokenDestoryMapping[address(cheToken)];
        ct[13] = balanceOf(_user);
        ct[14] = tokenDestoryMapping[address(hoyToken)];
        ct[15] = tokenEarningsMapping[address(hoyToken)][userInfo.id];
        ct[16] = limitMaxInvest;
        ct[17] = tokenUsdtMapping[address(hbyToken)][userInfo.id];
        ct[18] = tokenUsdtMapping[address(cheToken)][userInfo.id];
        ct[19] = tokenUsdtMapping[address(hoyToken)][userInfo.id];
        
        inviteCode = userMapping[_user].inviteCode;
        referrer = userInfo.referrer;
        
        return (
            ct,
            inviteCode,
            referrer
        );
    }

    function getTokenInfo(address _token,address _user) public view returns (uint[4] memory ct,bool _support)
    {
        User memory userInfo = userRoundMapping[rid][_user];

        //全网销毁总量
        ct[0] = tokenDestoryMapping[_token];
        //我的HOY销毁总量
        ct[1] = tokenEarningsMapping[_token][userInfo.id];
        //是否支持跳价
        ct[2] = tokenMultihopMapping[_token];
        //我的算力额度
        ct[3] = tokenUsdtMapping[_token][userInfo.id];
        
        return (ct,supportTokenMapping[_token]);
    }

    function addToken(address _token,bool _support,uint _isMultihop) public onlyWhitelistAdmin
    {
        supportTokenMapping[_token] = _support;
        tokenMultihopMapping[_token] = _isMultihop;
    }
    
    //------------------------------挖矿逻辑
    IERC20 erc;
    uint256 initreward = 0;
    uint256 turnover = 0;
    
    //utc+8 2022-6-1 10:10:00
    uint256 public starttime = 1654048800; 
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
    event RewardDividend(address indexed user, uint256 reward);
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
    
    function getReward() public updateReward(msg.sender) checkStart {
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");
        
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            uint staticReward = reward.mul(88).div(100);

            //提现手续费12%用于分红
            uint withdrawFee = reward.mul(12).div(100);
            //hoyToken.transfer(dividendTracker, withdrawFee);
            emit RewardDividend(dividendTracker, withdrawFee);
            
            //累计用户静态挖矿收益
            user.hisHoyAward = user.hisHoyAward.add(staticReward);
            //流通量
            turnover = turnover.add(staticReward);
            
            rewards[msg.sender] = 0;
            //hoyToken.transfer(msg.sender, staticReward);

            user.allDynamicAmount = 0;
            emit RewardPaid(msg.sender, staticReward);
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
        uint256 reward = 55233 * 1e18;
        changeRewardAmount(reward);
    }
    
    function activeStartTime(uint _starttime) external onlyWhitelistAdmin
    {
        starttime = _starttime;
    }

    function changeRewardAmount(uint256 reward) public onlyWhitelistAdmin {
        uint256 INIT_DURATION = 1825 days;
        initreward = reward;
        
        rewardRate = reward.div(INIT_DURATION);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(INIT_DURATION);
        emit RewardAdded(reward);
    }
    
    function saveStuckedToken(address _token, address _to,uint amt) public onlyWhitelistAdmin {
        IERC20(_token).transfer(_to, amt);
    }

    //设置单账户最大投资限制
    function setLimitMaxInvest(uint val) external onlyWhitelistAdmin {
        limitMaxInvest = val * usdtWei;
    }
    
    function sweep() external onlyWhitelistAdmin {
        msg.sender.transfer(address(this).balance);
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