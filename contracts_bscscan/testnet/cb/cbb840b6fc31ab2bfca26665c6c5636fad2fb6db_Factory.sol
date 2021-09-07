/**
 *Submitted for verification at BscScan.com on 2021-09-07
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

interface Itrader {
    function payment(address _token, address _from, address _to, uint256 _amount) external returns(bool); 
}

interface Isymbol {
    function symbol() external view returns(string memory);
}

interface Ifactory {
    event LinkCreated(address indexed _creater, string indexed _symbol, address _link);
    event LinkActive(address _link, address _user, uint256 _methodId);
    
    function setRisk() external;
    function setOwner(address _user) external;
    function setPledger(address _user) external;
    function setCollector(address _user) external;
    function setLinkOrigin(address _linkOrigin) external;
    function getCollector() external view returns(address);
    function isLink(address _link) external view returns(bool);
    function isAllowedToken(string memory _symbol, address _addr) external returns(bool);
    function createLink(address _toUser, string memory _tokenSymbol, uint256 _amount, uint256 _percentA, uint256 _lockDays) payable external returns(address);
    function addToken(address _tokenAddr, uint256 _minAmount) external;
    function updateTokenConfig (string memory _symbol, address _tokenAddr, uint256 _minAmount) external;
    function linkActive(address _user, uint256 _methodId) external;
}

interface Ilink {
     function setEnv(address _luca, address _wluca, address _trader, address _weth, address _pledger) external;
     function initialize( address _userA, address _userB, address _token, string memory _symbol, uint256 _amount, uint256 _percentA, uint256 _lockDays) external;
}

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
    address internal linkOrigin;
    
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

contract CloneFactory {
  function _clone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

}

contract Factory is Ifactory, FactoryStorage, CloneFactory{
    using SafeMath for uint256;
    address private constant ETH = address(0);
    
    modifier onlyOwner() {
        require(msg.sender == owner,"Factory: only owner");
        _;
    }
    
    modifier checkRisk() {
        require(!risk, "Factory: Danger!");
        _;
    }

    function initialize(address _linkOrigin, address _luca, address _wluca, address _trader, address _weth, address _collector, address _pledger) external noInit{
        owner = msg.sender;
        linkOrigin = _linkOrigin;
        luca = _luca;
        wluca = _wluca;
        weth = _weth;
        trader = _trader;
        collector = _collector;
        pledger = _pledger;
        
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
    
    function setLinkOrigin(address _linkOrigin) external override onlyOwner{
        linkOrigin = _linkOrigin;
    }
    
    function isLink(address _link) override external view returns(bool){
        return linkMap[_link];
    }
    
    function isAllowedToken(string memory _symbol, address _addr) override external view returns(bool) {
        return tokenMap[_symbol].addr == _addr;
    }
    
    function addToken(address _tokenAddr, uint256 _minAmount) override external onlyOwner {
        string memory symbol = Isymbol(_tokenAddr).symbol();
        require(bytes(symbol).length >= 0 , "Factory: not available ERC20 Token");
        require(!tokenMap[symbol].isActive, "Factory: token exist" );
        _addTokenMap(symbol, _tokenAddr, _minAmount);
    }
    
    function _addTokenMap(string memory _symbol, address _tokenAddr, uint256 _minAmount) internal {
        tokenMap[_symbol]=tokenConfig(_tokenAddr, _minAmount, true);
    }
    
    function updateTokenConfig(string  memory _symbol, address _tokenAddr, uint256 _minAmount) override external onlyOwner {
        require(tokenMap[_symbol].isActive, "Factory: token not exist" );
        tokenMap[_symbol]=tokenConfig(_tokenAddr, _minAmount, true);
    }
    
    function createLink(address _userB, string memory _symbol, uint256 _totalPlan, uint256 _percentA, uint256 _lockDays) override external payable  checkRisk returns(address){   
        //check args
        require(_userB != msg.sender, "Factory: userB is self");
        require(_percentA>=1 && _percentA<=100,"Factory: percentA need between 1 and 100");
        require(_lockDays>=1 && _lockDays<=1825,"Factory: lockDays need between 1 and 1825");
        
        //check token astrict
        tokenConfig memory config = tokenMap[_symbol];
        require(config.isActive, "Factory: token not exist");
        require(_totalPlan >= config.minAmount, "Factory: totalPlan too small");
        
        //create contract
        Ilink link = Ilink(_clone(linkOrigin));
        link.setEnv(luca, wluca, trader, weth, pledger);
        totalLink++;
        linkMap[address(link)] = true;
        
        //payment amountA to link
        uint256 amountA = _totalPlan.mul(_percentA).div(100);
        if (config.addr == ETH){
            require(msg.value == amountA, "Factory: wrong amount of ETH");
            IWETH(weth).deposit{value: msg.value}();
            IWETH(weth).transfer(address(link), msg.value);
        }else{
            Itrader(trader).payment(config.addr, msg.sender, address(link), amountA);
        }
        
        //init link 
        link.initialize(msg.sender, _userB, config.addr, _symbol, _totalPlan, _percentA, _lockDays);
        
        emit LinkCreated(msg.sender, _symbol, address(link));
        return address(link);
    }
    
    function linkActive(address _user, uint256 _methodId) override external{
        require(linkMap[msg.sender], "Link: only Link");
        emit LinkActive(msg.sender, _user, _methodId);
    }
}