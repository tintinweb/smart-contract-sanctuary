pragma solidity ^0.5.0;

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable {

    event Pause(uint256 pauseTime);
    event Unpause(uint256 unpauseTime);

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "Should not pause");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "Should be pause");
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public whenNotPaused {
        paused = true;
        emit Pause(now);
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public whenPaused {
        paused = false;
        emit Unpause(now);
    }
}

contract IERC20 {

    string public name;
    string public symbol;
    uint8 public decimals;

    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    
    function allowance(address _owner, address _spender) public view returns (uint256);

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @dev 模块工厂接口
 */
contract IModuleFactory is Ownable {

    // 平台Token
    IERC20 public platformToken;
    // 设置花费
    uint256 public setupCost;
    // 使用花费
    uint256 public usageCost;
    // 月订阅花费
    uint256 public monthlySubscriptionCost;

    // 修改工厂设置费用事件
    event LogChangeFactorySetupFee(uint256 _oldSetupcost, uint256 _newSetupCost, address _moduleFactoryAddress);
    // 修改工厂使用费用事件
    event LogChangeFactoryUsageFee(uint256 _oldUsageCost, uint256 _newUsageCost, address _moduleFactoryAddress);
    // 修改工厂订阅费用事件
    event LogChangeFactorySubscriptionFee(uint256 _oldSubscriptionCost, uint256 _newMonthlySubscriptionCost, address _moduleFactoryAddress);
    // 从工厂生成模块事件
    event LogGenerateModuleFromFactory(address _moduleAddress, bytes32 indexed _moduleName, address indexed _moduleFactoryAddress, address _creator, uint256 _timestamp);

   
    /**
     * @dev 构造函数
     * @param _platformTokenAddress 平台token地址
     * @param _setupCost 设置费用
     * @param _usageCost 使用费用
     * @param _subscriptionCost 订阅费用
     */
    constructor (address _platformTokenAddress, uint256 _setupCost, uint256 _usageCost, uint256 _subscriptionCost) public {
        platformToken = IERC20(_platformTokenAddress);
        setupCost = _setupCost;
        usageCost = _usageCost;
        monthlySubscriptionCost = _subscriptionCost;
    }

    function create(bytes calldata _data) external returns(address);

    function getType() public view returns(uint8);

    function getName() public view returns(bytes32);

    function getDescription() public view returns(string memory);

    function getTitle() public view returns(string memory);

    function getInstructions() public view returns (string memory);

    function getTags() public view returns (bytes32[] memory);

    function getSig(bytes memory _data) internal pure returns (bytes32 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes32(uint(sig) + uint8(_data[i]) * (2 ** (8 * (len - 1 - i))));
        }
    }

    
    /**
     * @dev 修改设置费用
     * @param _newSetupCost 新的设置费用
     */
    function changeFactorySetupFee(uint256 _newSetupCost) public onlyOwner {
        emit LogChangeFactorySetupFee(setupCost, _newSetupCost, address(this));
        setupCost = _newSetupCost;
    }

    /**
     * @dev 修改使用费用
     * @param _newUsageCost 新的使用费用
     */
    function changeFactoryUsageFee(uint256 _newUsageCost) public onlyOwner {
        emit LogChangeFactoryUsageFee(usageCost, _newUsageCost, address(this));
        usageCost = _newUsageCost;
    }

    /**
     * @dev 修改订阅费用
     * @param _newSubscriptionCost 新的订阅费用
     */
    function changeFactorySubscriptionFee(uint256 _newSubscriptionCost) public onlyOwner {
        emit LogChangeFactorySubscriptionFee(monthlySubscriptionCost, _newSubscriptionCost, address(this));
        monthlySubscriptionCost = _newSubscriptionCost;
        
    }

}

contract IERC20Extend is IERC20 {

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool);

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool);
}

contract IERC20Detail is IERC20 {

    constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract StandardToken is IERC20,IERC20Detail,IERC20Extend {

    using SafeMath for uint256;
    

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    mapping (address => mapping (address => uint256)) internal allowed;

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address who) public view returns (uint256){
        return balances[who];
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool){

        require(to != address(0), "Invalid address");

        require(balances[msg.sender] >= value, "Insufficient tokens transferable");

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool){

        require(balances[msg.sender] >= value, "Insufficient tokens approval");

        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        require(to != address(0), "Invalid address");
        require(balances[from] >= value, "Insufficient tokens transferable");
        require(allowed[from][msg.sender] >= value, "Insufficient tokens allowable");

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, value);

        return true;
    }

    function increaseApproval(address spender, uint256 value) public returns(bool) {

        require(balances[msg.sender] >= value, "Insufficient tokens approval");

        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);

        return true;
    }

    function decreaseApproval(address spender, uint256 value) public returns(bool){

        uint256 oldApproval = allowed[msg.sender][spender];

        if(oldApproval > value){
            allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(value);
        }else {
            allowed[msg.sender][spender] = 0;
        }

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);

        return true;
    }
}

/**
 * @title Security Token Exchange Protocol （STEP 1.0）
 */
contract ISTEP is StandardToken {

    string public tokenDetails;

    // 挖矿事件
    event LogMint(address indexed _to, uint256 _amount);

    /**
     * @notice 验证转移
     * @param _from 发送者地址
     * @param _to 接收者地址
     * @param _amount 金额
     */
    function verifyTransfer(address _from, address _to, uint256 _amount) public returns (bool);

    /**
     * @notice 挖矿
     * @param _investor 投资者地址
     * @param _amount token数量
     */
    function mint(address _investor, uint256 _amount) public returns (bool);

}

contract ISecurityToken is ISTEP, Ownable {
    
    uint8 public constant PERMISSIONMANAGER_KEY = 1;
    uint8 public constant TRANSFERMANAGER_KEY = 2;
    uint8 public constant STO_KEY = 3;
    
    // 粒度（可分割和不可分割性）
    uint256 public granularity;

    uint256 public investorCount;

    address[] public investors;

    /**
     * @notice 检查权限
     * @param _delegate 委托地址
     * @param _module 模块地址
     * @param _perm 权限符
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool);
    
    /**
     * @notice 获取模块
     * @param _moduleType 模块类型
     * @param _moduleIndex 模块索引
     */
    function getModule(uint8 _moduleType, uint _moduleIndex) public view returns (bytes32, address);

    /**
     * @notice 根据名字获取模块
     * @param _moduleType 模块类型
     * @param _name 模块名
     */
    function getModuleByName(uint8 _moduleType, bytes32 _name) public view returns (bytes32, address);

    /**
     * @notice 获取投资者人数
     */
    function getInvestorsLength() public view returns(uint256);

    
}

/**
 * @title 模块接口
 */
contract IModule {

    // 工厂地址
    address public factoryAddress;

    // ST地址
    address public securityTokenAddress;

    bytes32 public constant FEE_ADMIN = "FEE_ADMIN";

    // 平台币
    IERC20 public platformToken;

    /**
     * @notice 构造器
     */
    constructor (address _securityTokenAddress, address _platformTokenAddress) public {
        securityTokenAddress = _securityTokenAddress;
        factoryAddress = msg.sender;
        platformToken = IERC20(_platformTokenAddress);
    }

    function getInitFunction() public pure returns (bytes4);


    modifier withPerm(bytes32 _perm) {
        bool isOwner = msg.sender == ISecurityToken(securityTokenAddress).owner();
        bool isFactory = msg.sender == factoryAddress;
        require(isOwner || isFactory || ISecurityToken(securityTokenAddress).checkPermission(msg.sender, address(this), _perm), "Permission check failed");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == ISecurityToken(securityTokenAddress).owner(), "Sender is not owner");
        _;
    }

    modifier onlyFactory {
        require(msg.sender == factoryAddress, "Sender is not factory");
        _;
    }

    modifier onlyFactoryOwner {
        require(msg.sender == IModuleFactory(factoryAddress).owner(), "Sender is not factory owner");
        _;
    }

    function getPermissions() public view returns(bytes32[] memory);

    function takeFee(uint256 _amount) public withPerm(FEE_ADMIN) returns(bool) {
        require(platformToken.transferFrom(address(this), IModuleFactory(factoryAddress).owner(), _amount), "Unable to take fee");
        return true;
    }
}

/**
 * @notice STO接口
 */
contract ISTO is IModule, Pausable {

    using SafeMath for uint256;
    
    // 筹集资金类型
    enum FundRaiseType { ETH, PLATFORM }

    /// 筹集资金的类型（用map存储，某些情况下，一个STO可以接收多种筹集类型）
    mapping (uint8 => bool) public fundRaiseType;

    /// STO开始时间
    uint256 public startTime;
    /// STO结束时间
    uint256 public endTime;
    /// STO暂停时间
    uint256 public pausedTime;


    /**
     * @notice 获取已筹集的金额（以太币）
     */
    function getRaisedEther() public view returns (uint256);

    /**
     * @notice 获取已经筹集的金额（平台币）
     */
    function getRaisedPlatformToken() public view returns (uint256);

    /**
     * @notice 返回投资者人数
     */
    function getNumberInvestors() public view returns (uint256);

    /**
     * @notice 返回已经出售的token
     */
    function getTokensSold() public view returns (uint256);

    /**
     * @notice 暂停STO， 只有所有者能够调用
     */
    function pause() public onlyOwner {
        // 校验：此刻时间不能大于STO结束时间
        require(now < endTime, "Pause time not to less than STO endTime");
        super.pause();
    }

    /**
     * @notice 恢复STO， 只有所有者能够调用
     */
    function unpause() public onlyOwner {
        super.unpause();
    }

}

/**
 * @title Helps contracts guard agains reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a4d6c1c9c7cbe496">[email&#160;protected]</a>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

    /**
      * @dev We use a single lock for the whole contract.
      */
    bool private reentrancyLock = false;

    /**
      * @dev Prevents a contract from calling itself, directly or indirectly.
      * @notice If you mark a function `nonReentrant`, you should also
      * mark it `external`. Calling one nonReentrant function from
      * another is not supported. Instead, you can implement a
      * `private` function doing the actual work, and a `external`
      * wrapper marked as `nonReentrant`.
      */
    modifier nonReentrant() {
        require(!reentrancyLock, "Invlid status");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

/**
 * @notice Capped STO （STO一种类型）
 */
contract CappedSTO is ISTO, ReentrancyGuard {

    using SafeMath for uint256;

    /// STO期间，接收筹集资金的地址
    address payable public wallet;

    /// 换算比例
    uint256 public rate;

    /// 已筹集的资金
    uint256 public fundsRaised;

    /// 投资者的人数
    uint256 public investorCount;

    /// 已出售的token数量
    uint256 public tokensSold;

    /// token总量
    uint256 public cap;

    /// 投资者Map（投资者地址 -》 已购买token数量）
    mapping (address => uint256) public investors;

    /// token购买事件
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /// 构造器（发行者ST地址，平台币地址）
    constructor (address _securityTokenAddress, address _platformTokenAddress) public
    IModule(_securityTokenAddress, _platformTokenAddress)
    {
    }

    /**
    * @notice 回退函数（匿名函数，无名，无返回值）
    */
    function () external payable {
        /// 购买token
        buyTokens(msg.sender);
    }

    /**
     * @notice 参数设置（只有工厂才能调用）
     * @param _startTime STO开始时间（时间戳）
     * @param _endTime STO结束时间（时间戳）
     * @param _cap 总token数量
     * @param _rate 换算比例
     * @param _fundRaiseType 资金的筹集类型
     * @param _fundsReceiver 筹集资金的接受者
     */
    function setData(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _cap,
        uint256 _rate,
        uint8 _fundRaiseType,
        address payable _fundsReceiver
    )
    public
    onlyFactory
    {
        /// 校验：换算比例大于0
        require(_rate > 0, "Rate of token should be greater than 0");
        /// 校验：筹集资金接受者地址不能为0
        require(_fundsReceiver != address(0), "Zero address is not permitted");
        /// 校验：STO开始时间必须大于等于此刻，且结束时间大于开始时间
        require(_startTime >= now && _endTime > _startTime, "Date parameters are not valid");
        /// 校验：总的token数量大于0
        require(_cap > 0, "Cap should be greater than 0");

        startTime = _startTime;
        endTime = _endTime;
        cap = _cap;
        rate = _rate;
        wallet = _fundsReceiver;
        /// 校验筹集资金的类型
        _check(_fundRaiseType);
    }

    /**
     * @notice 获取setData函数签名
     */
    function getInitFunction() public pure returns (bytes4) {
        return bytes4(keccak256("setData(uint256,uint256,uint256,uint256,uint8,address)"));
    }

    /**
     * @notice 购买token
     * @param _beneficiary token购买者
     */
    function buyTokens(address _beneficiary) public payable nonReentrant {

        /// 校验：STO未暂停
        require(!paused, "STO should not paused");
        /// 校验：筹集资金的类型为ETH
        require(fundRaiseType[uint8(FundRaiseType.ETH)], "ETH should be the mode of investment");

        /// 接收传入的ETH
        uint256 weiAmount = msg.value;

        /// 处理交易
        _processTx(_beneficiary, weiAmount);

        /// 发送资金(将合约接收到的金额转移到接收者上)
        _forwardFunds();

        /// 购买校验（后置）
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    /**
     * @notice 使用平台币购买Token
     * @param _investedPlatformToken 购买的平台币金额
     */
    function buyTokensWithPlatform(uint256 _investedPlatformToken) public nonReentrant{
        // 校验： STO未暂停
        require(!paused, "STO should not paused");
        // 校验： 筹集的资金类型为 平台币
        require(fundRaiseType[uint8(FundRaiseType.PLATFORM)], "Platform token should be the mode of investment");
        // 校验：
        // require(verifyInvestment(msg.sender, _investedPOLY), "Not valid Investment");

        // 处理交易
        _processTx(msg.sender, _investedPlatformToken);

        // 转移平台币
        _forwardPoly(msg.sender, wallet, _investedPlatformToken);
    
        // 购买后置校验
        _postValidatePurchase(msg.sender, _investedPlatformToken);
    }

    /**
     * @notice 判断已售出token数是否达到最大token数
     */
    function capReached() public view returns (bool) {
        return tokensSold >= cap;
    }

    /**
     * @notice 获取已筹集的金额（以太币）
     */
    function getRaisedEther() public view returns (uint256) {
        if (fundRaiseType[uint8(FundRaiseType.ETH)])
            return fundsRaised;
        else
            return 0;
    }

    /**
     * @notice 获取已经筹集的金额（平台币）
     */
    function getRaisedPlatformToken() public view returns (uint256) {
        if (fundRaiseType[uint8(FundRaiseType.PLATFORM)])
            return fundsRaised;
        else
            return 0;
    }

    /**
     * @notice 获取已投资的人数
     */
    function getNumberInvestors() public view returns (uint256) {
        return investorCount;
    }

    /**
     * @notice 获取已经售出的token数
     */
    function getTokensSold() public view returns (uint256) {
        return tokensSold;
    }

    /**
     * @notice 获取STO的权限符
     */
    function getPermissions() public view returns(bytes32[] memory) {
        bytes32[] memory allPermissions = new bytes32[](0);
        return allPermissions;
    }

    /**
     * @notice 获取STO详情
     * @return STO开始时间
     * @return STO结束时间
     * @return STO总token发行量
     * @return 换算比例
     * @return 已筹集的资金
     * @return 已投资的投资人数
     * @return 已售出的token数量
     * @return STO的资金筹集类型是否为平台币
     */
    function getSTODetails() public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (
            startTime,
            endTime,
            cap,
            rate,
            fundsRaised,
            investorCount,
            tokensSold,
            (fundRaiseType[uint8(FundRaiseType.PLATFORM)])
        );
    }

    /**
     * @notice 处理交易
     * @param _beneficiary token购买者
     * @param _investedAmount 购买金额
     */
    function _processTx(address _beneficiary, uint256 _investedAmount) internal {

        // 购买校验（前置）
        _preValidatePurchase(_beneficiary, _investedAmount);

        // 换算出要购买的token数量
        uint256 tokens = _getTokenAmount(_investedAmount);

        // 更改STO的状态（已经筹集的金额，已售出的token量）
        fundsRaised = fundsRaised.add(_investedAmount);
        tokensSold = tokensSold.add(tokens);

        // 处理购买
        _processPurchase(_beneficiary, tokens);

        // 发出 token购买事件
        emit TokenPurchase(msg.sender, _beneficiary, _investedAmount, tokens);

        // 更新购买状态
        _updatePurchasingState(_beneficiary, _investedAmount);
    }

    /**
     * @notice 购买校验（前置）
     * @param _beneficiary 购买者地址
     * @param _investedAmount 购买金额
     */
    function _preValidatePurchase(address _beneficiary, uint256 _investedAmount) internal view {
        /// 校验：购买者地址不能为0
        require(_beneficiary != address(0), "Beneficiary address should not be 0x");
        /// 校验：购买金额不能为0
        require(_investedAmount != 0, "Amount invested should not be equal to 0");
        /// 校验：将购买金额根据比例换算成token数量， 在已售出token数量上加上将要购买的token数量不能大于 总token发行量
        require(tokensSold.add(_getTokenAmount(_investedAmount)) <= cap, "Investment more than cap is not allowed");
        /// 校验： 现在的时间要大于STO开始时间，切小于STO结束时间
        require(now >= startTime && now <= endTime, "Offering is closed/Not yet started");
    }

    function _postValidatePurchase(address /*_beneficiary*/, uint256 /*_investedAmount*/) internal pure {
       // TODO 
    }

    /**
     * @notice 处理购买
     * @param _beneficiary 购买者地址
     * @param _tokenAmount 购买token数
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {

        // 如果投资人map中不存在该购买者，将投资人人数+1
        if (investors[_beneficiary] == 0) {
            investorCount = investorCount + 1;
        }

        // 如果该购买者是二次购买，则直接加上购买的token数
        investors[_beneficiary] = investors[_beneficiary].add(_tokenAmount);

        // 分发token
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @notice 分发token
     * @param _beneficiary 购买者地址
     * @param _tokenAmount token数量
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        // 调用 mint 进行挖矿
        require(ISTEP(securityTokenAddress).mint(_beneficiary, _tokenAmount), "Error in minting the tokens");
    }

    function _updatePurchasingState(address /*_beneficiary*/, uint256 /*_investedAmount*/) internal pure {
        // TODO
    }


    /**
     * @notice 将购买的金额换成的token的数量
     * @param _investedAmount 购买的金额
     */
    function _getTokenAmount(uint256 _investedAmount) internal view returns (uint256) {
        return _investedAmount.mul(rate);
    }

    /**
     * @notice 校验筹集资金的类型
     */
    function _check(uint8 _fundRaiseType) internal {

        /// 校验：筹集的资金类型为0-ETH 或 1-PLATFORM
        require(_fundRaiseType == 0 || _fundRaiseType == 1, "Not a valid fundraise type");
        /// 设置改STO的资金筹集类型
        fundRaiseType[_fundRaiseType] = true;
        /// 如果资金筹集类型为平台币，要求平台币的地址不能为0
        if (_fundRaiseType == uint8(FundRaiseType.PLATFORM)) {
            require(address(platformToken) != address(0), "Address of the polyToken should not be 0x");
        }
    }

    /**
     * @notice 转移资金
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    /**
    * @notice 转移平台币
    * @param _beneficiary 购买者地址
    * @param _to STO接收者地址
    * @param _fundsAmount 金额
    */
    function _forwardPoly(address _beneficiary, address _to, uint256 _fundsAmount) internal {
        platformToken.transferFrom(_beneficiary, _to, _fundsAmount);
    }

}

/**
 * @title Capped STO工厂
 */
contract CappedSTOFactory is IModuleFactory {

    /**
     * @notice 构造器
     */
    constructor (address _platformTokenAddress, uint256 _setupCost, uint256 _usageCost, uint256 _subscriptionCost) public
      IModuleFactory(_platformTokenAddress, _setupCost, _usageCost, _subscriptionCost)
    {

    }

    /**
     * @notice 创建CappedSTO
     */
    function create(bytes calldata _data) external returns(address) {
        // 如果设置了创建STO的费用，则先进行扣减
        if(setupCost > 0) {
            // owner 为 工厂合约的部署者
            require(platformToken.transferFrom(msg.sender, owner, setupCost), "Failed transferFrom because of sufficent Allowance is not provided");
        }

        // 实例化一个Capped STO
        CappedSTO cappedSTO = new CappedSTO(msg.sender, address(platformToken));

        require(getSig(_data) == cappedSTO.getInitFunction(), "Provided data is not valid");

        (bool success, ) = address(cappedSTO).call(_data);

        require(success, "Un-successfull call");

        // 发出 创建模块事件
        emit LogGenerateModuleFromFactory(address(cappedSTO), getName(), address(this), msg.sender, now);

        return address(cappedSTO);
    }

   
    function getType() public view returns(uint8) {
        return 3;
    }

    
    function getName() public view returns(bytes32) {
        return "CappedSTO";
    }

    
    function getDescription() public view returns(string memory) {
        return "Capped STO";
    }

    
    function getTitle() public view returns(string memory) {
        return "Capped STO";
    }

    
    function getInstructions() public view returns(string memory) {
        return "Initialises a capped STO. Init parameters are _startTime (time STO starts), _endTime (time STO ends), _cap (cap in tokens for STO), _rate (POLY/ETH to token rate), _fundRaiseType (whether you are raising in POLY or ETH), _polyToken (address of POLY token), _fundsReceiver (address which will receive funds)";
    }

    
    function getTags() public view returns(bytes32[] memory) {
        bytes32[] memory availableTags = new bytes32[](4);
        availableTags[0] = "Capped";
        availableTags[1] = "Non-refundable";
        availableTags[2] = "PLATFORM";
        availableTags[3] = "ETH";
        return availableTags;
    }

}