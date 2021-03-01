/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity >=0.6.0 <0.8.0;


library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
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

    function sub(uint256 a,uint256 b, string memory errorMessage ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(  address indexed owner,  address indexed spender,   uint256 value);
}
contract Ownable {
    
     address private _owner;
      constructor() {
        _owner = msg.sender;
        //emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}

abstract contract Tokens is IERC20, Ownable
{
    uint256 public basePrice = 1000 * 10**18;            //-----| 1 ETH = 1000 Tokens |---------
     
    using SafeMath for uint256;
    uint256 public _totalSupply;
    mapping(address => uint256) balances_;
    mapping(address => uint256) ethBalances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 public unlockDuration = 1 minutes; //72 hours;                               // ----| Lock transfers for non-owner |------

   function transfer(address to, uint tokens) public virtual override  returns (bool success)
    {
        // balances[msg.sender] = safeSub(balances[msg.sender], tokens);
         balances_[to] = balances_[to].add(tokens);
        emit Transfer(owner(), to, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public virtual override  returns(bool success)
    {
        // balances_[from] = balances_[from].sub(tokens); //safeSub(balances[from],tokens);
        // allowed[from][msg.sender] = safeSub(allowed[from][msg.sender],tokens);
        // balances[to] = safeAdd(balances[to],tokens);
        emit Transfer(from,to,tokens);
        return true;
    }


    function approve(address spender, uint256 amount)  public virtual  override returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public   view virtual override returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances_[account];
    }

    function _approve( address owner,  address spender, uint256 amount ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract WebcluesInfotechToken  is Tokens
{
    using SafeMath for uint256;
     
    uint lockedEther;
    
    string public name;
    string public symbol;
    
    uint8 public decimals;

    enum Phases {none, start, end}
    
    Phases public currentPhase;
    
    uint256 startTime;

    mapping (address => mapping(address => uint)) allowed;
    
    constructor() 
    {
        name = "Webclues Infotech";
        symbol = "WDCS";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        currentPhase = Phases.none;
        balances_[owner()] = _totalSupply;
        emit Transfer(address(0),msg.sender,_totalSupply);
    }
    
    receive() external payable 
    {
        require( currentPhase == Phases.start, "Stacking not started yet");
        require(_totalSupply > 0, "Presale token limit reached");
        uint256 weiAmount = msg.value;
        lockedEther = lockedEther.add(msg.value);
        _totalSupply = _totalSupply.sub(weiAmount);
        balances_[owner()] = balances_[owner()].sub(weiAmount);
        transfer(msg.sender,msg.value);

    }
    function getRemaining() external view returns(uint256)
    {
        return _totalSupply;
    }
    
    function startPresale() public onlyOwner {
        
        startTime = block.timestamp;
        require(currentPhase != Phases.end, "The coin offering has ended");
        currentPhase = Phases.start;
    }

    function endPresale() public onlyOwner {
        require(currentPhase != Phases.end, "The presale has ended");
        currentPhase = Phases.end;
    }
    
    function withdrawContractEther() public onlyOwner {
        require(currentPhase == Phases.end, "Presale not ended yet");
        payable(owner()).transfer(lockedEther);

    }
    
    function _startTime() external view returns(uint256)
    {
        return startTime;
    }
    
}