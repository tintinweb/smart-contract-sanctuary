/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./factoryInterface.sol";
interface Ifactory {
    event UpdatetokenConfig(string indexed _symbol, address indexed _tokenAddr, uint256 _minAmount);
    event LinkCreated(address indexed _creater, string indexed _symbol, address _link);

    // function setLUCA(address _luca) external;
    // function setWLUCA(address _wluca) external;
    function setRisk() external;
    function setOwner(address user) external;
    function isAllowedToken(string memory symbol, address addr) external returns(bool);
    function createLink(address _toUser, string memory _tokenSymbol, uint256 _amount, uint256 _percentA, uint256 _lockDays) external returns(address);
    function addToken(address _tokenAddr, uint256 _minAmount) external;
    function updateTokenConfig (string memory _symbol, address _tokenAddr, uint256 _minAmount) external;
}

//import "../common/interface/IERC20.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC20_Token is IERC20 {
    function symbol() external view returns(string memory);
}

//import "../trader/Itrader.sol";
interface Itrader {
    function balance() external returns(uint256 luca, uint256 wluca);
    function linkDeposit(uint256 _amount) external;
    function deposit(address from, uint256 amount) external;
    function withdraw(address to, uint256 amount) external;
}

//import "../common/library/SafeMath.sol";
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

//import "./linkInterface.sol";
interface Ilink {
    function getStatus() external returns(string memory);
    function initialize(address _userA, address _userB, address token, string memory _symbol,uint256 _amount, uint256 _percentA, uint256 _lockDays )external;
    function getLinkInfo() external view returns(string memory symbol_,address token_, address userA_,address userB_, uint256 amountA_,uint256 amountB_,uint256 percentA_,uint256 totalPlan_,uint256 lockDays_);
    function getCloseInfo() external view returns(address closer_,uint256 startTime_,uint256 expiredTime_,uint256 closeTime_);
    function agree() external;
    function reject() external;
    function close() external;
    function exit() external;
    function isExpire() external returns(bool);
}

//link.sol
contract Enum {
    Status internal status;
    enum Status {
        INITED,
        AGREED,
        REJECT,
        CLOSED
    }

    function _getStatus()internal view returns(string memory status_){
        if (Status.INITED == status)  status_ = "initialized";
        if (Status.AGREED == status)  status_ = "agreed";
        if (Status.REJECT == status)  status_ = "reject";
        if (Status.CLOSED == status)  status_ = "closed";
    }

    function _init() internal {
        status = Status.INITED;
    }

    function _reject() internal {
        status = Status.REJECT;
    }

    function _agree() internal {
        status = Status.AGREED;
    }

    function _close() internal {
        status = Status.CLOSED;
    }
}

contract Initialized {
    bool internal initialized;
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }

}

contract LinkInfo is Enum {
    address internal factory;
    address internal luca;
    address internal wluca;
    address internal trader;
    address internal collector;

    string   symbol;
    address  userA;
    address  userB;
    uint256  amountA;
    uint256  amountB;
    uint256  percentA;
    uint256  totalPlan;
    address  token;
    address  closer;
    uint256  lockDays;
    uint256  startTime;
    uint256  expiredTime;
    uint256  closeTime;

    uint256  receivableA;
    uint256  receivableB;
    uint256  balanceA;
    uint256  balanceB;

    function _getRecevabesInfo() internal view returns(uint256 receivableA_,uint256 balanceA_, uint256 receivableB_, uint256 balanceB_){
        return(receivableA, balanceA, receivableB, balanceB);
    }

    function _getCloseInfo() internal view returns(address closer_, uint256 startTime_,uint256 expiredTime_,uint256 closeTime_){
        return(closer, startTime,expiredTime,closeTime);
    }

    function _getLinkInfo() internal view returns(
        string memory symbol_,
        address token_,
        address userA_,
        address userB_,
        uint256 amountA_,
        uint256 amountB_,
        uint256 percentA_,
        uint256 totalPlan_,
        uint256 lockDays_
    ){
        return(symbol,token,userA,userB,amountA, amountB, percentA,totalPlan,lockDays);
    }
}

contract Link is LinkInfo, Initialized, Ilink {
    using SafeMath for uint256;

    constructor(address _factory, address _luca, address _wluca, address _trader, address _collector){
        factory = _factory;
        luca = _luca;
        wluca = _wluca;
        trader = _trader;
        collector = _collector;
    }

    modifier onlyFactory(){
        require(msg.sender == factory, "Link: only factory");
        _;
    }

    modifier onlyEditLink(){
        require(msg.sender == userA,"only userA");
        require(userB == address(0) && percentA == 100, "Link: only Editable Link");
        _;
    }

    modifier onlyLinkUser(){
        require(msg.sender == userA || msg.sender == userB, "Link: access denied");
        _;
    }

    modifier onlyUserB(){
        require(msg.sender == userB, "Link: noly userB");
        _;
    }

    modifier onlyINITED(){
        require(status == Status.INITED, "Link: only initialized");
        _;
    }

    modifier onlyAGREED(){
        require(status == Status.AGREED, "Link: only agreed");
        _;
    }

    modifier onlyCLOSED(){
        require(status == Status.CLOSED, "Link: olny closed");
        _;
    }

    modifier unCLOSED(){
        require(status != Status.CLOSED, "Link: only unclosed");
        _;
    }



    function verifyDeposit(address _token, address _user) internal view returns(bool){
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (_user == userA) {
            if (amount == amountA) return true;
        }else{
            if (amount >= totalPlan) return true;
        }

        return false;
    }


    function initialize(address _userA, address _userB, address _token, string memory _symbol, uint256 _amount, uint256 _percentA, uint256 _lockDays)override external onlyFactory noInit{
        require(verifyDeposit(_token, _userA), "Link: userA deposit not enough");
        {
            userA = _userA;
            userB = _userB;
            token = _token;
            symbol = _symbol;
            totalPlan = _amount;
            percentA = _percentA;
            amountA = _amount.mul(_percentA).div(100);
            amountB = _amount.sub(amountA);
            lockDays = _lockDays;
        }
        if(_percentA == 100 && userB != address(0)){
            startTime = block.timestamp;
            expiredTime = startTime.add(lockDays.mul(1 days));
            _agree();
        }else{
            _init();
        }
    }

    function setUserB(address _userB) external onlyEditLink {
        require(_userB != address(0) && _userB != msg.sender, "Link: unlawful address");
        userB = _userB;
        startTime = block.timestamp;
        expiredTime = startTime.add(lockDays.mul(1 days));
        _agree();
    }

    function getRecevabesInfo() external view returns(uint256 receivableA_, uint256 balanceA_, uint256 receivableB_, uint256 balanceB_){
        return _getRecevabesInfo();
    }

    function getLinkInfo() override external view returns(
        string memory symbol_,
        address token_,
        address userA_,
        address userB_,
        uint256 amountA_,
        uint256 amountB_,
        uint256 percentA_,
        uint256 totalPlan_,
        uint256 lockDays_
    ){
        return _getLinkInfo();
    }


    function getCloseInfo() override external view returns(
        address closer_,
        uint256 startTime_,
        uint256 expiredTime_,
        uint256 closeTime_
    ){
        return _getCloseInfo();
    }

    function getStatus()override external view returns(string memory){
        return _getStatus();
    }

    function reject()override external onlyUserB onlyINITED{
        _reject();
    }

    function agree()override external onlyUserB onlyINITED{
        if (token == wluca){
            require(IERC20(luca).transferFrom(msg.sender, address(this), amountB), "Link: userB not enough allowance");
            IERC20(luca).approve(trader, amountB);
            Itrader(trader).linkDeposit(amountB);
        }else{
            require(IERC20(token).transferFrom(msg.sender, address(this), amountB), "Link: userB not enough allowance");
        }

        require(verifyDeposit(token, userB), "Link: userB deposit not enough" );
        startTime = block.timestamp;
        expiredTime = startTime.add(lockDays.mul(1 days));
        _agree();
    }


    function close()override external unCLOSED onlyLinkUser {
        //INITED or REJECT
        if (status == Status.INITED || status == Status.REJECT){
            require(msg.sender == userA,"Link: access denied");
            closer = msg.sender;
        }

        //AGREED
        if (status == Status.AGREED){
            if (closer == address(0)){
                //requist close
                closer = msg.sender;
                return;
            }else{
                //confirm close
                require(msg.sender!=closer, "Link: repeat close");
            }
        }

        //close and liquidation
        closeTime = block.timestamp;
        _liquidation();
        _close();
    }

    //withdraw
    function exit()override external onlyCLOSED onlyLinkUser{
        address to;
        uint256 amount;
        if(msg.sender == userA) {
            to = userA;
            amount = balanceA;
            balanceA = 0;
        }else{
            to = userB;
            amount = balanceB;
            balanceB = 0;
        }
        _withdraw(to, amount);
    }

    function _withdraw(address to, uint amount) internal{
        if(token == wluca){
            require(IERC20(wluca).approve(trader, amount), "Link: approve token to trader failed");
            Itrader(trader).withdraw(to, amount);
        }else{
            IERC20(token).transfer(to, amount);
        }
    }


    function _liquidation() internal{
        if (status == Status.INITED || status == Status.REJECT || isExpire()) {
            _setReceivables(100);
        }else{//AGREED
            uint256 day = (closeTime.sub(startTime)).div(1 days);
            //dayFator = {(lockDays-day)/lockDays} * 0.2 *10^4
            uint256 dayFator = (lockDays.sub(day)).mul(1000*2).div(lockDays);
            if (day == 0) {
                _setReceivables(100-20);
            }else if(dayFator < 100){   //  <0.01
                _setReceivables(99);
            }else if(dayFator > 2000){  //  >0.2
                _setReceivables(80);
            }else{                      //  0.01 - 0.2
                _setReceivables(100-(dayFator.div(100)));
            }
            uint256 fee = totalPlan.sub(balanceA.add(balanceB));
            _withdraw(collector, fee);
        }
    }

    function _setReceivables(uint256 factor) internal{
        receivableA = amountA.mul(factor).div(100);
        balanceA = receivableA;

        if (status == Status.AGREED && amountB != 0){
            receivableB = amountB.mul(factor).div(100);
            balanceB = receivableB;
        }
    }

    function isExpire()override public view returns(bool) {
        if (status == Status.INITED || expiredTime == 0){
            return false;
        }
        return (block.timestamp >= expiredTime);
    }
}

//factory.sol
contract FactoryStorage {
    bool    internal initialized;
    bool    internal risk;
    address internal luca;
    address internal wluca;
    address internal trader;
    address internal collector;
    uint256 internal totalLink;

    address public owner;
    mapping(string => tokenConfig) internal tokenMap;
    struct tokenConfig {
        address addr;
        uint256 minAmount;
        bool    isActive;
    }
}

//Factory need support upgrad
contract Factory is Ifactory,  FactoryStorage{
    using SafeMath for uint256;
    uint256 constant MIN_LOCK_DAYS = 1;
    uint256 constant MAX_LOCK_DAYS = 1825;

    modifier onlyInitialize(){
        require(!initialized,"Factory: contract was initialized" );
        _;
        initialized = true;
    }

    // valid user is owner
    modifier checkRisk() {
        require(!risk, "Factory: !Danger, at height risk");
        _;
    }

    // valid user is owner
    modifier onlyOwner() {
        require(msg.sender == owner,'Factory:only owner can operate!');
        _;
    }

    // valid percentlimt is range of 1-100
    modifier validPercent(uint256 _percent) {
        require(_percent>=1 && _percent<=100,'Factory: percent need between 1 and 100');
        _;
    }

    // valid lockdays is range of 1-1825
    modifier validLockDays(uint256 _lockTime) {
        require(_lockTime>=MIN_LOCK_DAYS && _lockTime<=MAX_LOCK_DAYS,'Factory:  locktime need between 1 and 1825');
        _;
    }

    modifier validConfig(string memory _tokenSymbol, uint256 _amount, uint256 _percent) {
        tokenConfig memory config = tokenMap[_tokenSymbol];
        require(config.isActive, 'Factory: The token is not added to the consensus link');
        require(_amount.mul(_percent).div(100) >= config.minAmount,'Factory:The token lock min amount is not allowed.');
        _;
    }

    function initialize(address _luca, address _wluca, address _trader, address _collector) external onlyInitialize{
        owner = msg.sender;
        luca = _luca;
        wluca = _wluca;
        trader = _trader;
        collector = _collector;
    }

    function setOwner(address _user)  override external onlyOwner {
        owner = _user;
    }

    function setRisk() external override onlyOwner {
        risk = !risk;
    }

    function isAllowedToken(string memory _symbol, address _addr) override external view returns(bool) {
        if (tokenMap[_symbol].addr == _addr){
            return true;
        }
        return false;
    }

    //token manage
    function addToken(address _tokenAddr, uint256 _minAmount) override external  onlyOwner {
        string memory tokenSymbol = ERC20_Token(_tokenAddr).symbol();
        require(bytes(tokenSymbol).length >= 0 , "Factory: not available ERC20 Token");
        require(tokenMap[tokenSymbol].addr == address(0), "Factory: token exist" );
        tokenConfig memory tf;
        tf.addr = _tokenAddr;
        tf.minAmount = _minAmount;
        tf.isActive = true;
        tokenMap[tokenSymbol]=tf;
    }

    function updateTokenConfig(string  memory _symbol, address _tokenAddr, uint256 _minAmount) override external onlyOwner {
        require(tokenMap[_symbol].isActive, "Factory: token not exist" );
        tokenConfig memory tf;
        tf.addr = _tokenAddr;
        tf.minAmount = _minAmount;
        tf.isActive = true;
        tokenMap[_symbol]=tf;
        emit UpdatetokenConfig( _symbol, _tokenAddr, _minAmount);
    }

    function createLink(address _userB, string memory _symbol, uint256 _tatalPlan, uint256 _percentA, uint256 _lockDays) override external
    validPercent(_percentA)
    validLockDays(_lockDays)
    checkRisk()
    returns(address)
    {
        //verify addressA
        require(_userB != msg.sender, 'Factory: to account is self.');
        //verify token
        tokenConfig memory config = tokenMap[_symbol];
        require(config.isActive, "Factory: token not exist");
        require(_tatalPlan.mul(_percentA).div(100) >= config.minAmount,'Factory: amount need big than minAmount');
        Link link = new Link(address(this), luca, wluca, trader, collector);
        totalLink++;
        uint256 amountA = _tatalPlan.mul(_percentA).div(100);
        if(config.addr == luca){
            // require(ERC20_Token(luca).transferFrom(msg.sender, address(this), amountA), "Factory: transferFrom Fail" );
            // require(ERC20_Token(luca).approve(trader, amountA), "Factory: approve token to trader failed");
            require(ERC20_Token(luca).transferFrom(msg.sender, trader, amountA), "Factory: transferFrom Fail" );
            Itrader(trader).deposit(address(link), amountA);
            link.initialize(msg.sender, _userB, wluca, ERC20_Token(wluca).symbol(), _tatalPlan, _percentA, _lockDays);
        }else{
            require(ERC20_Token(config.addr).transferFrom(msg.sender, address(link), amountA), "Factory: transferFrom Fail" );
            link.initialize(msg.sender, _userB, config.addr, _symbol, _tatalPlan, _percentA, _lockDays);
        }

        emit LinkCreated(msg.sender, _symbol, address(link));
        return address(link);
    }
}