/**
 *Submitted for verification at BscScan.com on 2021-09-22
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

interface Ifile{
    function factoryLoad() external view returns (address, address, address, address, uint256, uint256);
    function active() external view returns(bool);
}

interface IERC20 {
    function symbol() external view returns(string memory);
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
    function payment(address token, address from, address to, uint256 amount) external returns(bool); 
    function suck(address user, uint256 amount, uint256 lockDays) external;
}

interface Isymbol {
    function symbol() external view returns(string memory);
}

interface Ilink {
     function setEnv(address _luca, address _wluca, address _trader, address _weth, address _pledger) external;
     function initialize( address file, address _userA, address _userB, address _token, string memory _symbol, uint256 _amount, uint256 _percentA, uint256 _lockDays) external;
}

interface Ifactory {
    function isLink(address) external view returns(bool);
   // function setLockDay(uint256, uint256) external;
    function addToken(address, uint256) external;
    function updateTokenConfig (string memory, address, uint256) external;
    function createLink(address, string memory, uint256, uint256, uint256) payable external returns(address);
    function linkActive(address, uint256) external;
    
    event LinkCreated(address indexed _creater, string indexed _symbol, address _link);
    event LinkActive(address _link, address _user, uint256 _methodId);
}

contract Initialize {
    bool internal initialized;
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
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

contract Factory is Initialize, CloneFactory, Ifactory{
    using SafeMath for uint256;
    address public file;
    uint256 public totalLink;
    
    struct token {
        address addr;       
        uint256 minAmount;   
        bool    isActive;    
    }
    
    struct linkArgs {
        address userB;
        string  symbol;
        uint256 totalPlan;
        uint256 percentA;
        uint256 lockDays;
    }
    
    struct fileArgs {
         address luca;
         address weth;
         address trader;
         address linkTemp;
         uint256 minLockDay;
         uint256 maxLockDay;
    }
    
    mapping(address => bool) internal linkMap;
    mapping(string => token) public tokenMap;
    address private constant ETH = address(0);
    
    modifier onlyFile() {
        require(msg.sender == file, "only file");
        _;
    }

    function initialize(string memory _network, address _file) external noInit{
        file = _file;
        _addToken(_network, ETH, 100);
    }
    
    function isLink(address _link) override external view returns(bool){
        return linkMap[_link];
    }
    
    function addToken(address _token, uint256 _min) override external onlyFile {
        string memory symbol = IERC20(_token).symbol();
        require(bytes(symbol).length >= 0 , "Factory: not available ERC20 Token");
        require(!tokenMap[symbol].isActive, "Factory: token exist" );
        _addToken(symbol, _token, _min);
    }
    
    function _addToken(string memory _symbol, address _token, uint256 _min) internal {
        tokenMap[_symbol] = token(_token, _min, true);
    }
    
    function updateTokenConfig(string  memory _symbol, address _token, uint256 _min) override external onlyFile {
        require(tokenMap[_symbol].isActive, "Factory: token not exist" );
        tokenMap[_symbol] = token(_token, _min, true);
    }
    
    function createLink(address _userB, string memory _symbol, uint256 _totalPlan, uint256 _percentA, uint256 _lockDays) override external payable returns(address){ 
        require(Ifile(file).active());
        fileArgs memory f;
        {
          (address luca, address weth, address trader, address linkTemp, uint256 minLockDay, uint256 maxLockDay) = Ifile(file).factoryLoad();
          f = fileArgs(luca, weth, trader, linkTemp, minLockDay, maxLockDay);
        }
        
        //check args
        require(_userB != msg.sender, "Factory: userB is self");
        require(_percentA >=1 && _percentA <= 100,"Factory: percentA need between 1 and 100");
        require(_lockDays >= f.minLockDay && _lockDays <= f.maxLockDay,"Factory: lockDays out of set");
        
        //check token astrict
        token memory t = tokenMap[_symbol];
        require(t.isActive, "Factory: token not exist");
        require(_totalPlan >= t.minAmount, "Factory: totalPlan too small");
        
        //create contract
        Ilink link = Ilink(_clone(f.linkTemp));
    
        totalLink++;
        linkMap[address(link)] = true;
        
        //payment amountA to link
        uint256 amountA = _totalPlan.mul(_percentA).div(100);
        if (t.addr == ETH){
            require(msg.value == amountA, "Factory: wrong amount value");
            IWETH(f.weth).deposit{value: msg.value}();
            IWETH(f.weth).transfer(address(link), msg.value);
        }else{
            Itrader(f.trader).payment(t.addr, msg.sender, address(link), amountA);
        }
        
        //init link 
        link.initialize(file, msg.sender, _userB, t.addr, _symbol, _totalPlan, _percentA, _lockDays);
        emit LinkCreated(msg.sender, _symbol, address(link));
        
        //mint agt
        if (t.addr == f.luca && _percentA == 100){
            Itrader(f.trader).suck(msg.sender, amountA, _lockDays);
        }
        
        return address(link);
    }
    
    function linkActive(address _user, uint256 _methodId) override external{
        require(linkMap[msg.sender], "Factory: only Link");
        emit LinkActive(msg.sender, _user, _methodId);
    }
}