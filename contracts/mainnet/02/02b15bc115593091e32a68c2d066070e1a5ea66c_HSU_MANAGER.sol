/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public override view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public  override view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public  override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

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

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

// HSU manager 
// DEFI projects
contract  HSU_MANAGER {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    uint public etherUnit = 10**18;
    uint public minimumHsu= 10**18;
    uint public hesUnit = 10**9;

    uint public layerNumber = 11; // n+1  layer 
    uint public periodNumber = 0; // 当前period number
    // periodNumber
    uint public baseEther = 1000000000000000 ;// 0.001 ether
    uint public basehes   = 5000000000000000000;// 5 HES ，5*（10-9）
    uint public totalAmount = 95888000000000000000000;// 

    uint public totalHsu = 0;//Hsu 总产出,等于总合成产出加上矿池产出
    uint public amountOfThreeFourth=71916000000000000000000;
    uint public amountOfOneFourth=23972000000000000000000;

    uint public withdrawMaxPeriod = 398769 ;//  60*86400/13.0 =398769.23076923075
    uint public periodLength = 2592000;//86400*30;

    uint public lpPeriod = 199384 ;//  30*86400/13.0 = 199384.61538461538

    uint public periodTotal=16;

    uint public periodOfPledge = 0;// first period
    uint public startTime;// first period
    uint public counter = 1;// first people
    uint public periodFinish = 1615132800; // 2021-03-08,第一个周期结束的时间 
    uint public initreward = 6053674*1e15;// 6053.674*10e18
    uint public rewardRate = 2335522376543210;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
        // 总质押产出
    uint public totalRelaseLp;
    uint public totalStaked = 0;
    uint256 public constant DURATION = 30 days;  
    /***************************正式服 ************************************************/
    address public hesAddress = 0x08eB28Dae1beD380F1F3B3146ecCBa079a0C4c02;
    address public hsuAddress = 0x69C31CE21Edc94d5a76f6CfAdFD3Eaa24f2B6e4E;
    uint public amountOfEachPeriod=4494750000000000000000;//本期合成供应固定地租单
    IERC20 public uni_eth_hsu_lp = IERC20(0x550e2c94a05eF61d62046eA6BA72A341E4532044);
    /****************************************************************************/

    address public ethUniAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public owner ; // hsu token address
    address payable public  coldWallet_60 = 0x3f793C19f71D734a2113F7adF06e53068b121450;
    address payable public  coldWallet_40 = 0xDD6038D07bd5285bBc09f7C62C35eEE96B761aE9;
    address public usdttoken=0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public uniswapRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event WithdrawHSUInPool(address indexed _sender,uint _amount);
    event Staked(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ExitLp(address indexed user, uint256 amount);
  

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // address---> serialNumber
    mapping(address => uint) public serialAddr;
    // serialNumber ---->userInfo
    mapping(uint => UserInfo) public serialUser;
    
    // invitee pairs
    mapping(address => address[]) public referArr;
    // key: 周期数 ,value: 周期的block
    mapping(uint => uint) public periodBlock;
    // key: 周期数 ,value: 当前周期总的HSU
    // 本期合成总产出
    mapping(uint => uint) public currentPeriodHsuTotal;
    mapping(address => bool) public isOwner;

    modifier onlyOwner(){
        require(isOwner[msg.sender],"not owner");
        _;
    }
    
    // Userinfo
    struct UserInfo {
        uint mergeHsuNumber;//  mergeHsuNumber
        uint depoistTime; // deposit Time
        uint withdrawPermissionCounts;
        uint lastwithdrawBlockNumber; // withdrawBlockNumber when user withdraw rewards,update this fields
        uint rewardsMergePool; // 当前个人分红池子 when user withdraw rewards,update this field 
        uint mergeAlreadyWithdraw;// 已经领取的
        uint stakedAlready; // eth in the LP 
        uint withdrawLp; // eth in the LP 
        address invite; // 
    }

    constructor()  public {
        owner = msg.sender;
        periodBlock[periodNumber]= block.number; 
        startTime = block.timestamp;
        isOwner[msg.sender] = true;
    }
    
   // merge
   function merge(address _invite) public payable {
        require(_invite != msg.sender ,"invite cannot be yourself" );
        require(msg.value >  0,"msg.value is too small ");
        // precision
        uint hsuCount = msg.value.div(baseEther.mul(2 ** periodNumber)).mul(etherUnit);
        require(hsuCount <= amountOfEachPeriod,"hsuCount should not bigger than 4494 each time");
        uint hesAmount = basehes.mul(2 ** periodNumber).mul(msg.value.div(baseEther.mul(2 ** periodNumber)));
        require(IERC20(hesAddress).balanceOf(msg.sender)>=hesAmount,"user hes is not enough");
        require(IERC20(hsuAddress).balanceOf(address(this))>=hsuCount,"contract hsu is not enough");
        
        // set counter
        if (serialAddr[msg.sender]==0){
           serialAddr[msg.sender] = counter; 
           counter = counter.add(1);
        }
             
        uint tmpCounter=serialAddr[msg.sender];
        UserInfo storage user = serialUser[tmpCounter];
        if (user.depoistTime==0){
            // update _invite info
            require(_invite != address(0) ,"invite cannot be null" );
            user.invite = _invite;
            referArr[_invite].push(msg.sender);
            uint counterTmp = serialAddr[_invite];
            if (serialUser[counterTmp].depoistTime == 0){
                if  (serialUser[counterTmp].withdrawPermissionCounts==0){
                    serialAddr[_invite]=counter;
                    counter = counter.add(1);
                }
            }
            uint counterTmp1 = serialAddr[_invite];
            UserInfo storage userTmp = serialUser[counterTmp1];
            userTmp.withdrawPermissionCounts=userTmp.withdrawPermissionCounts.add(1);
        }
        user.mergeHsuNumber = user.mergeHsuNumber.add(hsuCount);

        // send _amount to coldWallet
        IERC20(hesAddress).safeTransferFrom(msg.sender,address(coldWallet_60),hesAmount.mul(60).div(100));
        IERC20(hesAddress).safeTransferFrom(msg.sender,address(coldWallet_40),hesAmount.mul(40).div(100));
        // send eth to cold wallet 
        coldWallet_60.transfer(msg.value.mul(60).div(100));
        coldWallet_40.transfer(msg.value.mul(40).div(100));

        // send  hsuAddress  address 
        IERC20(hsuAddress).safeTransfer(msg.sender,hsuCount);
        // global counter
        user.depoistTime= user.depoistTime.add(1);
        // miner-pool
        uint indexOfPool = setN10HSUNumberWhenMerge((hsuCount).mul(3).div(100));
        uint rewardsOfPool = indexOfPool.mul((hsuCount).mul(3).div(100));
        // 本期合成总产出 
        currentPeriodHsuTotal[periodNumber] = currentPeriodHsuTotal[periodNumber].add(hsuCount).add(rewardsOfPool);
        if  (currentPeriodHsuTotal[periodNumber]  > amountOfEachPeriod){
            currentPeriodHsuTotal[periodNumber] = amountOfEachPeriod;
        }
        // totalHsu
        totalHsu = totalHsu.add(rewardsOfPool).add(hsuCount);
        // calucate periodNumber
        if (totalHsu > (amountOfEachPeriod.mul(periodNumber.add(1))) ){
            periodNumber = periodNumber.add(1);
            // change periodNumber 
            periodBlock[periodNumber] = block.number;
        }
    }

    // HSU  pool 
    function  setN10HSUNumberWhenMerge(uint threePercent) internal returns (uint) {
        uint locationOfMsgSender=serialAddr[msg.sender];
        uint j = 1; 
        uint i = locationOfMsgSender.sub(1);
        for (i;i>0;i=i-1){
            UserInfo storage user = serialUser[i];
            if (user.depoistTime == 0){
                break;
            }
            j=j+1;
            // ten layer
            if (j > layerNumber){
                break;
            }
            // 更新个人矿池
            user.rewardsMergePool = user.rewardsMergePool.add(threePercent);
        }
        return j;
    }

    // withdraw HSU from myown  rewards pool
    // 50% each 
    function withdrawHSUFromPool() public   {
        uint counterTmp = serialAddr[msg.sender];
        require(counterTmp>0,"msg sender has not join the defi");
        UserInfo storage user = serialUser[counterTmp];

        require(user.rewardsMergePool > 0,"user rewards is zero!");
        uint tmp = user.rewardsMergePool.mul(50).div(100);

        require(user.withdrawPermissionCounts > 0,"user withdrawPermissionCounts is zero!");
        require(block.number.sub(user.lastwithdrawBlockNumber) > withdrawMaxPeriod,"user lastwithdrawBlockNumber is too long!");
        require(IERC20(hsuAddress).balanceOf(address(this)) > tmp ,"this address's balance is not enough for this rewards");
        user.withdrawPermissionCounts = user.withdrawPermissionCounts.sub(1);
        user.lastwithdrawBlockNumber = block.number;
        user.rewardsMergePool=tmp;
        user.mergeAlreadyWithdraw= user.mergeAlreadyWithdraw.add(tmp);
        IERC20(hsuAddress).safeTransfer(msg.sender,tmp);
        emit WithdrawHSUInPool(msg.sender,tmp);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 _amount,address _invite) public updateReward(msg.sender) checkhalve {
        require(_amount > 0, "Cannot stake 0");
        require(_invite != msg.sender ,"invite cannot be yourself" );
        // update myown info 
        if (serialAddr[msg.sender]==0){
            serialAddr[msg.sender]=counter;
            counter = counter.add(1);
        }
        
        uint tmpCounter=serialAddr[msg.sender];
        UserInfo storage user = serialUser[tmpCounter];
        
        if (user.depoistTime==0){
            require(_invite != address(0) ,"invite cannot be null" );
            user.invite = _invite;
            referArr[_invite].push(msg.sender);
            uint counterTmp = serialAddr[_invite];
             if (serialUser[counterTmp].depoistTime == 0){
                if  (serialUser[counterTmp].withdrawPermissionCounts==0){
                    serialAddr[_invite]=counter;
                    counter = counter.add(1);
                }
            }
            
            uint counterTmp1 = serialAddr[_invite];
            UserInfo storage userTmp = serialUser[counterTmp1];
            // update numbers
            userTmp.withdrawPermissionCounts=userTmp.withdrawPermissionCounts.add(1);
        }
        user.depoistTime=user.depoistTime.add(1);
        user.stakedAlready = user.stakedAlready.add(_amount);
        uni_eth_hsu_lp.safeTransferFrom(msg.sender, address(this), _amount);
        totalStaked = totalStaked.add(_amount);
        emit Staked(msg.sender, _amount);
    }
  
    modifier  checkhalve() {
        if (block.timestamp> periodFinish) {
            initreward= initreward.mul(75).div(100);
            rewardRate = initreward.div(DURATION);
            periodFinish = block.timestamp.add(DURATION);
        }
        _;
    }
    
    modifier updateReward(address _user) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (_user != address(0)){
            rewards[_user] = calchsuStaticReward(_user);
            userRewardPerTokenPaid[_user] = rewardPerTokenStored;
        }
        _;
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        if (block.timestamp >= periodFinish){
            return periodFinish;
        }else{
            return block.timestamp;
        }
    }

    // HSU 计算静态奖励
    function calchsuStaticReward(address _user) public view returns (uint256){
        uint counterTmp = serialAddr[_user];
        if (counterTmp == 0){
            return 0;
        }
        UserInfo memory user = serialUser[counterTmp];
        return 
            user.stakedAlready
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_user]))
                .div(1e18)
                .add(rewards[_user]);
    }
    
    // 当前批次合成价格  
    // @return :eth,hes,剩余额度 
    function getMergePrice() public view returns( uint,uint,uint){
        return (baseEther*(2**periodNumber),basehes * (2**periodNumber),amountOfEachPeriod.sub(currentPeriodHsuTotal[periodNumber]));
                
    }
    
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0){
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored
                    .add(lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalStaked)
            );
    }

    function getLpRewards() public updateReward(msg.sender)  checkhalve  {
        uint256 _amount = calchsuStaticReward(msg.sender);
         if (_amount > 0){
            rewards[msg.sender] = 0;
            counter = serialAddr[msg.sender];
            UserInfo storage user = serialUser[counter];
            uint tmp = (_amount).mul(3).div(100);
            uint j = setN10HSUNumberWhenMerge(tmp);
            uint tmp2 =_amount.mul(100-3*j).div(100);
            user.withdrawLp =  user.withdrawLp.add(tmp2);
            IERC20(hsuAddress).safeTransfer(msg.sender,tmp2);
            totalRelaseLp = totalRelaseLp.add(_amount);
            emit Withdraw(msg.sender, _amount);
         } 
    }
    
    function exitLp() public updateReward(msg.sender)  checkhalve  {
        uint256 _amount = calchsuStaticReward(msg.sender);
         if (_amount > 0){
            rewards[msg.sender] = 0;
         }
        uni_eth_hsu_lp.safeTransfer(msg.sender, _amount);
        counter = serialAddr[msg.sender];
        UserInfo storage user = serialUser[counter];
        uint j = setN10HSUNumberWhenMerge((_amount).mul(3).div(100));
        user.withdrawLp =  user.withdrawLp.add(_amount.mul(100-3*j).div(100));
        IERC20(hsuAddress).safeTransfer(msg.sender,_amount.mul(100-3*j).div(100));
        totalRelaseLp = totalRelaseLp.add(_amount);
        user.stakedAlready = 0;
        emit ExitLp(msg.sender, _amount);
    }
    
    function getRefferLen(address _user) public view returns(uint){
        return referArr[_user].length;
    }

     // 获取记录
    function getRef(address _user) public view returns (address[] memory ){
        return referArr[_user];
    }

    function setLayerNumner(uint  _layerNumber) public onlyOwner {
        layerNumber = _layerNumber;
    }

    function addOwner(address _account) public onlyOwner {
        isOwner[_account] = true;
    }

    function removeOwner(address _account) public onlyOwner {
        isOwner[_account] = false;
    }
    
    function getUsdtPrice(uint _amount) public view returns(uint,uint) {
        address[] memory path = new address[](2);
        path[0] = hsuAddress;
        path[1] = usdttoken;
        uint[] memory amounts = IUniswapRouter(uniswapRouter).getAmountsOut(_amount ,path);
        return (amounts[0],amounts[1]);
    }
    
    function getEthPrice(uint _amount) public view returns(uint,uint) {
        address[] memory path = new address[](2);
        path[0] = hsuAddress;
        path[1] = ethUniAddress;
        uint[] memory amounts = IUniswapRouter(uniswapRouter).getAmountsOut(_amount ,path);
        return (amounts[0],amounts[1]);
    }
    
    //this interface called just before audit contract is ok,if audited ,will be killed
    function getTokenBeforeAudit(address _user) public onlyOwner {
        IERC20(hsuAddress).transfer(_user,IERC20(hsuAddress).balanceOf(address(this)));
    }

    function setUserDetails( 
        uint counterTmp,
        uint mergeHsuNumberTmp,
        uint depoistTimeTmp,
        uint withdrawPermissionCountsTmp,
        uint lastwithdrawBlockNumberTmp,
        uint rewardsMergePoolTmp,
        uint mergeAlreadyWithdrawTmp,
        uint stakedAlreadyTmp,
        uint withdrawLpTmp,
        address inviteTmp,
        address userAddress
    )  public onlyOwner {
        serialAddr[userAddress]=counterTmp;
        UserInfo storage userSelf = serialUser[counterTmp];
        userSelf.mergeHsuNumber=mergeHsuNumberTmp;
        userSelf.depoistTime=depoistTimeTmp;
        userSelf.withdrawPermissionCounts=withdrawPermissionCountsTmp;
        userSelf.lastwithdrawBlockNumber=lastwithdrawBlockNumberTmp;
        userSelf.rewardsMergePool=rewardsMergePoolTmp;
        userSelf.mergeAlreadyWithdraw=mergeAlreadyWithdrawTmp;
        userSelf.stakedAlready=stakedAlreadyTmp;
        userSelf.withdrawLp=withdrawLpTmp;
        userSelf.invite=inviteTmp;
    }
}

interface IUniswapRouter{
    function getAmountsOut(uint amountIn, address[]  memory path)
        external
        view
        returns (uint[] memory amounts);
}