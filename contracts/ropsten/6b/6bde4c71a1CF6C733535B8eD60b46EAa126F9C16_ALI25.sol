/**
 *Submitted for verification at Etherscan.io on 2021-07-15
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


contract ALI25 is IERC20,Owner {

    string public constant name = "ALI25";
    string public constant symbol = "ALI00";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping (address => bool) private _isBlackListed;
    mapping (address => bool) private _isWhiteListed;
    uint256 public _maxTxAmount;
    

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total,uint256 maxTxPercent,address addr1,address addr2,address addr3) public {
    totalSupply_ = total;
  
    balances[addr1]=totalSupply_.div(3);
     balances[addr2]=totalSupply_.div(3);
      balances[addr3]=totalSupply_.div(3);
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
        require(!_isBlackListed[msg.sender], "You have no power here!");
        require(!_isBlackListed[receiver], "You have no power here!");
          if (!_isWhiteListed[msg.sender]) {
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


    function addToBlackList(address account) external onlyOwner() {
        require(account != address(this));
        require(!_isBlackListed[account], "Account is already blacklisted");
        _isBlackListed[account] = true;
    }

    function removeFromBlackList(address account) external onlyOwner() {
        require(_isBlackListed[account], "Account is not blacklisted");
                _isBlackListed[account] = false;
    }

  function addToWhiteList(address account) external onlyOwner() {
        require(account != address(this));
        require(!_isWhiteListed[account], "Account is already blacklisted");
        _isWhiteListed[account] = true;
    }

    function removeFromWhiteList(address account) external onlyOwner() {
        require(_isWhiteListed[account], "Account is not blacklisted");
                _isWhiteListed[account] = false;
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
        require(!_isBlackListed[owner], "You have no power here!");
        require(!_isBlackListed[buyer], "You have no power here!");
        if (!_isWhiteListed[owner]) {
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