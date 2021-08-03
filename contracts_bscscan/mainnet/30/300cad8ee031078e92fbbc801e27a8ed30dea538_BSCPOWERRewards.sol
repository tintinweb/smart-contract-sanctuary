/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

/**
 ⚡️POWER exchange is powered by POWER TOKEN it is a secure crypto exchange with a Gaming 
platform on board that makes it easy to buy, sell and trade cryptocurrencies with deep liquidity,
low fees, and best execution prices. To earn power You can farm and stake your tokens or
use it to play Power Game to win top prizes. 
 
🔋WEB: https://bscpower.energy

🔋TG: https://t.me/bscpower

🔋MEDIUM: https://medium.com/@bscpower

🔋TWITTER: https://twitter.com/Bsc_Power

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.7.2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address trecipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
  
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
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

abstract contract ERC20Detailed is IERC20 {
    uint8 private _Tokendecimals;
    string private _Tokenname;
    string private _Tokensymbol;
    
    constructor(string memory name, string memory symbol, uint8 decimals) {
    _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
    }
    
    function name() public view returns(string memory) {
        return _Tokenname;
    }
    
    function symbol() public view returns(string memory) {
        return _Tokensymbol;
    }
    
    function decimals() public view returns(uint8) {
        return _Tokendecimals;
    }
}

contract OwnableDistributor {
    address private _owner;
    address private _distributor;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event distributorTransferred(address indexed previousDistributor, address indexed newDistributor);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
        _distributor = address(0);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setDistributor(address _address) external onlyOwner {
        require (_distributor == address(0));
        _distributor = _address;
        emit distributorTransferred(address(0), _address);
    }
    
    function rewardDistributor() public view returns (address) {
        return _distributor;
    }
    
    modifier onlyDistributor() {
        require(_distributor == msg.sender, "caller is not rewards distributor");
        _;
    }
}

contract BSCPOWERRewards is OwnableDistributor {
    using SafeMath for uint256;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    mapping (address => bool) private gamersDatabase;
    uint256 gamerRewardLimit;
    event gamerAddedToDatabase (address gamerAddress, bool isAdded);
    event gamerRemovedFromDatabase (address gamerAddress, bool isAdded);
    event rewardTransfer(address indexed from, address indexed to, uint256 value);
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        name = "BSC POWER REWARDS";
        symbol = "REWARDS";
        decimals = 9;
        gamerRewardLimit = 500000000000; //maximum amount of tokens per gamer (500) + decimals (9)
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transfer(_from, _to, _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) internal view returns (uint256) {
        return allowed[_owner][_spender];
    }
  
    function _transfer(address _from, address _to, uint256 _value) private {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        balances[_from] = balances[_from].sub(_value, "ERC20: transfer amount exceeds balance");
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function addNewGamerToDatabase(address _address) public onlyDistributor {
        gamersDatabase[_address] = true;
        emit gamerAddedToDatabase (_address, gamersDatabase[_address]);
    }

    function removeGamerFromDatabase(address _address) public onlyDistributor {
        gamersDatabase[_address] = false;
        emit gamerRemovedFromDatabase (_address, gamersDatabase[_address]);
    }
        
    function isGamerInDatabase(address _address) public view returns(bool) {
        return gamersDatabase[_address];
    }
    
    function rewardLimitPerGamer() public view returns (uint256) {
        return gamerRewardLimit.div(1*10**9);
        //return the maximum amount of tokens per gamer, devied only here by decimals (9) for better clarity
    }
    
    function sendRewardToWinner(address _address, uint256 amount) external onlyDistributor {
        require (owner() == address(0), "renouce owership required. The Owner must be zero address");
        require (gamersDatabase[_address] == true, "address is not registred in gamers database");
        require (amount <= gamerRewardLimit, "amount cannot be higher than limit");
        require (_address != address(0), "zero address not allowed");
        require (amount != 0, "amount cannot be zero");
        balances[address(this)] = balances[address(this)].sub(amount, "reward pool is empty already");
        balances[_address] = balances[_address].add(amount);
        emit rewardTransfer(address(this), _address, amount);
    }
}