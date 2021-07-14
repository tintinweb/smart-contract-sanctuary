// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Link} from "./platy_link.sol";

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

//import "../trader/Itrader.sol";
interface Itrader {
    function balance() external returns(uint256 luca, uint256 wluca);
    function deposit(uint256 _amount) external returns(bool);
    function withdraw(uint256 _amount) external returns(bool);
    function payment(address _token, address _from, address _to, uint256 _amount) external returns(bool); 
    function withdrawFor(address _to, uint256 _amount) external;
    function addWhiteList(address _addr) external;
}

//import "./Ifactory.sol";
interface Ifactory {
    event UpdatetokenConfig(string indexed _symbol, address indexed _tokenAddr, uint256 _minAmount);
    event LinkCreated(address indexed _creater, string indexed _symbol, address _link);
    
    function setRisk() external;
    function setOwner(address _user) external;
    function setPledger(address _user) external;
    function setCollector(address _user) external;
    function getCollector() external view returns(address);
    function isLink(address _link) external view returns(bool);
    function isAllowedToken(string memory _symbol, address _addr) external returns(bool);
    function createLink(address _toUser, string memory _tokenSymbol, uint256 _amount, uint256 _percentA, uint256 _lockDays) payable external returns(address);
    function addToken(address _tokenAddr, uint256 _minAmount) external;
    function updateTokenConfig (string memory _symbol, address _tokenAddr, uint256 _minAmount) external;
}

interface ERC20_Token is IERC20 {
    function symbol() external view returns(string memory);
}

interface IWETH is IERC20{
    function deposit() payable external;
    function withdraw(uint) external;
}

//factory.sol
contract Initialize {
    bool internal initialized;
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract FactoryStorage is Initialize {
    bool    internal risk;     
    address internal luca;
    address internal wluca;
    address internal weth;
    address internal trader;
    address internal collector;
    address internal pledger;
    address internal ETH;
    
    address public owner;
    uint256 public totalLink;
   
    mapping(address => bool) internal linkMap;
    mapping(string => tokenConfig) internal tokenMap;
    
    struct tokenConfig {
        address addr;       
        uint256 minAmount;   
        bool    isActive;    
    }
}

//Factory need support upgrad
contract Factory is Ifactory, FactoryStorage{
    using SafeMath for uint256;
    uint256 constant MIN_LOCK_DAYS = 1;   
    uint256 constant MAX_LOCK_DAYS = 1825;
    
    // valid user is owner
    modifier checkRisk() {
        require(!risk, "Factory: Danger!");
        _;
    }
    
    // valid user is owner
    modifier onlyOwner() {
        require(msg.sender == owner,'Factory: only owner');
        _;
    }
    
    // valid percentlimt is range of 1-100
    modifier validPercent(uint256 _percent) {
        require(_percent>=1 && _percent<=100,'Factory: percent need between 1 and 100');
        _;
    }

    // valid lockdays is range of 1-1825
    modifier validLockDays(uint256 _lockTime) {
        require(_lockTime>=MIN_LOCK_DAYS && _lockTime <= MAX_LOCK_DAYS,'Factory:  locktime need between 1 and 1825');
        _;
    }
    
    modifier validConfig(string memory _tokenSymbol, uint256 _amount, uint256 _percent) {
        tokenConfig memory config = tokenMap[_tokenSymbol];
        require(config.isActive, 'Factory: not allowed token');
        require(_amount.mul(_percent).div(100) >= config.minAmount,'Factory: lock amount too small');
        _;
    }
    
    function initialize(address _luca, address _wluca, address _trader, address _weth, address _collector, address _pledger) external noInit{
       owner = msg.sender;
       luca = _luca;
       wluca = _wluca;
       weth =_weth;
       trader = _trader;
       collector = _collector;
       pledger = _pledger;
       ETH = address(0);
       
       _addTokenMap("LUCA", _luca, 1);
       _addTokenMap("ETH", ETH, 1);
    }
    
    function setOwner(address _user)  override external onlyOwner {
        owner = _user;
    }
    
    function setPledger(address _user)  override external onlyOwner {
        pledger = _user;
    }
    
    function setCollector(address _user) override external onlyOwner {
        collector = _user;
    }
    
    function getCollector() override external view returns(address){
        return collector;
    }
    
    function setRisk() external override onlyOwner {
        risk = !risk;
    }
    
    function isLink(address _link) override external view returns(bool){
        return linkMap[_link];
    }
    
    function isAllowedToken(string memory _symbol, address _addr) override external view returns(bool) {
        if (tokenMap[_symbol].addr == _addr){
            return true;
        }
        return false;
    }
    
    function addToken(address _tokenAddr, uint256 _minAmount) override external onlyOwner {
       string memory tokenSymbol = ERC20_Token(_tokenAddr).symbol();
       require(bytes(tokenSymbol).length >= 0 , "Factory: not available Token");
       require(!tokenMap[tokenSymbol].isActive, "Factory: token exist" );
       _addTokenMap(tokenSymbol, _tokenAddr, _minAmount);
    }
    
    function _addTokenMap(string memory _symbol, address _tokenAddr, uint256 _minAmount) internal {
       tokenConfig memory tf;
       tf.addr = _tokenAddr;
       tf.minAmount = _minAmount;
       tf.isActive = true;
       tokenMap[_symbol]=tf;
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
    
    function createLink(address _userB, string memory _symbol, uint256 _tatalPlan, uint256 _percentA, uint256 _lockDays) payable override external
        validPercent(_percentA)
        validLockDays(_lockDays)
        checkRisk()
        returns(address)
        {   
            require(_userB != msg.sender, "Factory: to account is self.");
            tokenConfig memory config = tokenMap[_symbol];
            require(config.isActive, "Factory: token not exist");
            require(_tatalPlan.mul(_percentA).div(100) >= config.minAmount, "Factory: amount too small");
            uint256 amountA = _tatalPlan.mul(_percentA).div(100);
            Link link = _createLink();
            if (config.addr == ETH){
                require(msg.value >= amountA, "not enough ETH");
                IWETH(weth).deposit{value: msg.value}();
                IWETH(weth).transfer(address(link), msg.value);
            }else{
                //payment and linitualize
                require(Itrader(trader).payment(config.addr, msg.sender, address(link), amountA));
            }
            
            link.initialize(msg.sender, _userB, config.addr, _symbol, _tatalPlan, _percentA, _lockDays);
            emit LinkCreated(msg.sender, _symbol, address(link));
            return address(link);
    }
    
    function _createLink() internal returns(Link){
         Link link = new Link(address(this), luca, wluca, trader, weth, pledger);
         totalLink++;
         linkMap[address(link)] = true;
         return link;
    }
}