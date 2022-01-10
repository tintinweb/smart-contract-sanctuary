/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IWETH is IERC20{
    function deposit() payable external;
    function withdraw(uint) external;
}

interface Ipledge{
    function  stakeWLuca(address _nodeAddr, uint256 _amount, address _sender) external returns(bool);
    function  cancleStakeWLuca(address _sender) external returns(bool);
}

interface Itrader {
    function payment(address _token, address _from, address _to, uint256 _amount) external returns(bool); 
    function withdrawFor(address _to, uint256 _amount) external;
    function suck(address _to, uint256 _amount, uint256 _lockDay) external;
}

interface Ifactory {
    function linkActive(address _user, uint256 _methodId) external;
}

interface Ifile {
    function luca() external view returns(address);
    function pledger() external view returns(address);
    function collector() external view returns(address);
    function linkLoad() external view returns (address, address, address, address, address);//luca, wluca, weth, trader, pledger
}

//Ilink.sol
interface Ilink {
    function getPledgedInfo() external view returns(bool pledgedA_, bool pledgedB_);
    function getStatus() external view returns(string memory);
    function getLinkInfo() external view returns(string memory symbol_,address token_, address userA_,address userB_, uint256 amountA_,uint256 amountB_,uint256 percentA_,uint256 totalPlan_,uint256 lockDays_, uint256 startTime_, uint256 status_, bool isAward_);
    function getCloseInfo() external view returns(address closer_, uint256 startTime_,uint256 expiredTime_,uint256 closeTime_, bool closeReqA_, bool closeReqB_);
    function getRecevabesInfo() external view returns(uint256 receivableA_, bool isExitA_, uint256 receivableB_, bool isExitB_);
    function setUserB(address _userB) external;
    function agree() external payable;
    function reject() external;
    function close() external;
    function rejectClose() external;
    function repealCloseReq() external;
    function isExpire() external view returns(bool);
    function pledge(address node) external;
    function depledge() external;
    function wtihdrawSelf() external;
}

//link.sol
contract Initialized {
    bool internal initialized;
    
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract Enum {
    Status internal status;
    enum Status {INITED, AGREED, CLOSED, PLEDGED}
    enum MethodId {setUserB, agree, reject, pledge, depledge, close, repealCloseReq, rejectClose, wtihdrawSelf}
    
    function _init() internal {status = Status.INITED;}

    function _agree() internal {status = Status.AGREED;}

    function _close() internal {status = Status.CLOSED;}
    
    function _pledge() internal {status = Status.PLEDGED;}
}

contract LinkInfo is Enum {
    address internal file;
    address internal factory;
    bool    internal closeReqA;
    bool    internal closeReqB;
    bool    internal pledgedA;
    bool    internal pledgedB;
    
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
    bool     isExitA;
    bool     isExitB;
    
    
    modifier onlyLuca(){
        require(token == Ifile(file).luca(), "Link: only luca");
        _;
    }
    
    modifier onlyEditLink(){
        require(msg.sender == userA, "Link: only userA");
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

    modifier unCLOSED(){
        require(status != Status.CLOSED, "Link: only unclosed");
        _;
    }
    
    modifier onlyPLEDGED(){
        require(status == Status.PLEDGED, "Link: only pledged");
        _;
    }
    
    modifier unPLEDGED(){
        require(status != Status.PLEDGED, "Link: only unpledged");
        _;
    }
}

contract Link is LinkInfo, Initialized, Ilink {
    using SafeMath for uint256;
    address constant ETH = address(0);
    fallback() payable external{}
    receive() payable external{}
    
    function _linkActive(MethodId _methodId) internal{
        Ifactory(factory).linkActive(msg.sender, uint256(_methodId));
    }
    
    function initialize( address _file, address _userA, address _userB, address _token, string memory _symbol, uint256 _amount, uint256 _percentA, uint256 _lockDays) external noInit{
        (factory, file, userA, userB, token, symbol) = (msg.sender, _file, _userA, _userB, _token, _symbol);
        (totalPlan, percentA, amountA, amountB, lockDays) = (_amount, _percentA, _amount.mul(_percentA).div(100), _amount.mul(100 - _percentA).div(100), _lockDays);
        
        if(_percentA == 100 && userB != address(0)){
            startTime = block.timestamp;
            expiredTime = startTime.add(lockDays.mul(1 days));
            _agree();
        }else{
            _init();
        }
    }

    function setUserB(address _userB) override external onlyEditLink {
        require(_userB != address(0) && _userB != msg.sender, "Link: unlawful address");
        _linkActive(MethodId.setUserB);
        userB = _userB;
        startTime = block.timestamp;
        expiredTime = startTime.add(lockDays.mul(1 days));
        _agree();
        
        (address luca,,,address trader,) = Ifile(file).linkLoad();
        //airdrop gta 
        if(token == luca){
            Itrader(trader).suck(userA, amountA, lockDays);
            Itrader(trader).suck(userB, amountB, lockDays);
        }
    }

    function reject() override external onlyUserB onlyINITED{
        _linkActive(MethodId.reject);
        _exit();
    }

    function agree() override payable external onlyUserB onlyINITED{
        _linkActive(MethodId.agree);
        // (luca, wluca, weth, trader, pledger)
        (address luca,,address weth, address trader,) = Ifile(file).linkLoad();
        if (token == ETH){
            
            require(msg.value == amountB, "Link: wrong amount of ETH");
            IWETH(weth).deposit{value: msg.value}();
            IWETH(weth).transfer(address(this), msg.value);
        }else{
            Itrader(trader).payment(token, userB, address(this), amountB);
        }
        
        //require(_verifyDeposit(token, userB), "Link: deposit not enough" );
        startTime = block.timestamp;
        expiredTime = startTime.add(lockDays.mul(1 days));
        _agree();
        
        //airdrop gta 
        if(token == luca){
            Itrader(trader).suck(userA, amountA, lockDays);
            Itrader(trader).suck(userB, amountB, lockDays);
        }
    }
    
    //pledge
    function pledge(address node) override external onlyLuca onlyLinkUser {
        require(status == Status.PLEDGED || status == Status.AGREED, "Link: access denied");
        require(!isExpire(), "Link: link expire");
        require(!closeReqA && !closeReqB, "Link: please handle the closing process first");
        
        _linkActive(MethodId.pledge);
        
        uint256 amount;
        if (msg.sender == userA){
             require(!pledgedA, "Link: repledge");
             pledgedA = true;
             amount = amountA;
        }else{
             require(!pledgedB, "Link: repledge");
             pledgedB= true;
             amount = amountB;
        }
        
        require(amount > 0, "Link: 0 amount");
        _pledge();
        Ipledge(Ifile(file).pledger()).stakeWLuca(node, amount, msg.sender);
    }
    
    function depledge() override external onlyLuca onlyPLEDGED onlyLinkUser{
        if (msg.sender == userA){
             require(pledgedA, "Link: no pledged");
             pledgedA = false;
        }else{
             require(pledgedB, "Link: no pledged");
             pledgedB= false;
        }
        
        _linkActive(MethodId.depledge);
         
        Ipledge(Ifile(file).pledger()).cancleStakeWLuca(msg.sender);
       
        
        //other exited
        if (isExitA || isExitB){ 
            closer = msg.sender;
            closeTime = block.timestamp;
            _exitSelf();
            _close();
            return;
        }
        
        if (!pledgedA && !pledgedB) _agree();
    }
    
    function wtihdrawSelf() override external onlyLuca onlyPLEDGED onlyLinkUser{
         require(isExpire(),"Link: only Expire");
         _linkActive(MethodId.wtihdrawSelf);
         _setReceivables(100);
         _exitSelf();
    }
    
    //Link renew
    function close() override external unCLOSED unPLEDGED onlyLinkUser {
        _linkActive(MethodId.close);
        
        //Expire 
        if (isExpire()){
            _exit();
        }
        
        //INITED
        if (status == Status.INITED){
            require(msg.sender == userA,"Link: access denied");
            _exit();
        }

        //AGREED
        if (status == Status.AGREED){
            if (msg.sender == userA) {
                closeReqA = true;
            }else{
                closeReqB = true;
            }
            
            if (closeReqA && closeReqB){
                _exit();
            }
        }
    }
    
    function repealCloseReq() override external onlyAGREED onlyLinkUser { 
        _linkActive(MethodId.repealCloseReq);
        
        if (msg.sender == userA) {
            closeReqA = false;
        }else{
            closeReqB = false;
        }
    }
    
    function rejectClose() override external onlyAGREED onlyLinkUser{
        _linkActive(MethodId.rejectClose);
        
        if (msg.sender == userB) {
            closeReqA = false;
        }else{
            closeReqB = false;
        }
    }
    
    //Link query
    function isExpire() override public view returns(bool) {
        if (status == Status.INITED || expiredTime == 0){
            return false;
        }
        return (block.timestamp >= expiredTime);
    }
    
    function getPledgedInfo() override external view returns(bool pledgedA_, bool pledgedB_){
        return(pledgedA, pledgedB);
    }
    
    function getCloseInfo() override external view returns(address closer_, uint256 startTime_,uint256 expiredTime_,uint256 closeTime_, bool closeReqA_, bool closeReqB_){
        return(closer, startTime, expiredTime, closeTime, closeReqA, closeReqB);
    }

    function getStatus() override external view returns(string memory status_){
        if (Status.INITED == status)  return "initialized";
        if (Status.AGREED == status)  return "agreed";
        if (Status.PLEDGED == status) return "pledged";
        if (Status.CLOSED == status)  return "closed";
    }
    
    function getRecevabesInfo() override external view returns(uint256 receivableA_, bool isExitA_, uint256 receivableB_, bool isExitB_){
        return(receivableA, isExitA, receivableB, isExitB);
    }

    function getLinkInfo() override external view returns(string memory symbol_,address token_,address userA_, address userB_, uint256 amountA_, uint256 amountB_,uint256 percentA_,uint256 totalPlan_,uint256 lockDays_,uint256 startTime_,uint256 status_, bool isAward_){
        bool isAward;
        if ((status == Status.AGREED) || ((status == Status.PLEDGED) && (!isExitA && !isExitB))) {
            isAward = true;
        }
        
        return(symbol, token, userA, userB, amountA, amountB, percentA, totalPlan, lockDays, startTime, uint256(status), isAward);
    }
    
    function _exit() internal{
        closer = msg.sender;
        closeTime = block.timestamp;
        _liquidation();
        _close();
    }
    
    function _exitSelf() internal{
        if (msg.sender == userA){
            //userA unpledge and notExit
            require(!pledgedA && !isExitA, "Link: access denied ");
            isExitA = true;
            _withdraw(userA, receivableA);
        }else{
            //userB unpledge and notExit
            require(!pledgedB && !isExitB, "Link: access denied ");
            isExitB = true;
            _withdraw(userB, receivableB);
        }
    }

    function _liquidation() internal{
        if (status == Status.INITED || isExpire()) {
            _setReceivables(100);
        }else{
            //AGREED
            uint256 day = (closeTime.sub(startTime)).div(1 days);
            //dayFator = (lockDays-day)*10^4  / lockDays 
            uint256 dayFator = (lockDays.sub(day)).mul(10000).div(lockDays);
            
            if(dayFator <= 100){         //  <1% * 10000
                _setReceivables(99);
            }else if(dayFator >= 1500){  // >15% * 10000
                _setReceivables(85);
            }else{                       // 1% ~ 15%
               _setReceivables((10000 - dayFator).div(100)); 
            }
            
            uint256 fee = totalPlan.sub(receivableA.add(receivableB));
            _withdraw(Ifile(file).collector(), fee);
        }
        
        isExitA = true;
        isExitB = true;
        _withdraw(userA, receivableA);
        if (receivableB > 0) _withdraw(userB, receivableB);
    }
    
  
    function _withdraw(address to, uint amount) internal{
        (address luca, address wluca, address weth, address trader,) = Ifile(file).linkLoad();
        if (token == ETH){
             IWETH(weth).withdraw(amount);
             payable(to).transfer(amount);
        }else if(token == luca){
            IERC20(wluca).approve(trader, amount);
            Itrader(trader).withdrawFor(to, amount);
        }else{
            IERC20(token).transfer(to, amount);
        }
    }
    
    function _setReceivables(uint256 factor) internal{
        receivableA = amountA.mul(factor).div(100);

        if (status == Status.AGREED && amountB != 0){
            receivableB = amountB.mul(factor).div(100);
        }
    }
}