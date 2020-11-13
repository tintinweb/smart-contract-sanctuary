/*
 
HTTPS://QBURN.CASH
HTTPS://T.ME/QUICKBURN
----------------------------------------------
Community driven project
----------------------------------------------
 _______  ______            _______  _       
(  ___  )(  ___ \ |\     /|(  ____ )( (    /|
| (   ) || (   ) )| )   ( || (    )||  \  ( |
| |   | || (__/ / | |   | || (____)||   \ | |
| |   | ||  __ (  | |   | ||     __)| (\ \) |
| | /\| || (  \ \ | |   | || (\ (   | | \   |
| (_\ \ || )___) )| (___) || ) \ \__| )  \  |
(____\/_)|/ \___/ (_______)|/   \__/|/    )_)
                                             
QUICKBURN - Deflationary & Fast eco system
----------------------------------------------
- 20% Penalty when claiming rewards < 4 days
- 100% Truly Decentralized
----------------------------------------------
 
*/
// SPDX-License-Identifier: MIT


pragma solidity ^0.7.2;
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
 
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
 
        return c;
    }
 
}
 
contract Owned {
    address public owner;
    address public newOwner;
 
    event OwnershipTransferred(address indexed from, address indexed _to);
 
    constructor(address _owner) {
        owner = _owner;
    }
 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
 
    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
 
abstract contract Pausable is Owned {
    event Pause();
    event Unpause();
 
    bool public paused = false;
 
    modifier whenNotPaused() {
      require(!paused, "all transaction has been paused");
      _;
    }
 
    modifier whenPaused() {
      require(paused, "transaction is current opened");
      _;
    }
 
    function pause() onlyOwner whenNotPaused external {
      paused = true;
      emit Pause();
    }
 
    function unpause() onlyOwner whenPaused external {
      paused = false;
      emit Unpause();
    }
}
 
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
 
abstract contract ERC20 is IERC20, Pausable {
    using SafeMath for uint256;
 
    mapping (address => uint256) private _balances;
 
    mapping (address => mapping (address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }
 
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
 
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
 
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
 
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
 
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
 
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
 
    function _transferFrom(address sender, address recipient, uint256 amount) internal whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
 
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
 
}
 
contract qburnToken is ERC20 {
 
    using SafeMath for uint256;
    IERC20 private qburnAddress;
    string  public  name;
    string  public  symbol;
    uint8   public decimals;
    uint private setTime;
    uint public maxValue;
 
 
    uint256 public totalMinted;
    uint256 public totalBurnt;
 
    mapping(address => uint256) private time;
 
    constructor(IERC20 _qburnAddress, string memory _name, string memory _symbol) Owned(msg.sender) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        _mint(msg.sender, 1200 ether);
        totalMinted = totalSupply();
        totalBurnt = 0;
 
        qburnAddress = _qburnAddress;
        setTime = 0;
        maxValue = 300 ether;
    }
 
 
    modifier validateMint(uint _mint) {
        require(_mint >= maxValue, "Amount is above treshold of 300 Ether max.");
        require(qburnAddress.balanceOf(msg.sender) >= _mint, "Must meet required conditions to activate mint");
        _;
    }
    
    function burn(uint256 _amount) external whenNotPaused returns (bool) {
       super._burn(msg.sender, _amount);
       totalBurnt = totalBurnt.add(_amount);
       return true;
   }
 
    function transfer(address _recipient, uint256 _amount) public override whenNotPaused returns (bool) {
        if(totalSupply() <= 300 ether) {
            super._transfer(msg.sender, _recipient, _amount);
            return true;
        }
        
        uint _amountToBurn = _amount.mul(3).div(100);
        _burn(msg.sender, _amountToBurn);
        totalBurnt = totalBurnt.add(_amountToBurn);
        uint _unBurntToken = _amount.sub(_amountToBurn);
        super._transfer(msg.sender, _recipient, _unBurntToken);
        return true;
    }
 
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override whenNotPaused returns (bool) {
        super._transferFrom(_sender, _recipient, _amount);
        return true;
    }
    
    function approvedTokenBalance(address _sender) public view returns(uint) {
        return qburnAddress.allowance(_sender, address(this));
    }
    
    
    function mint(address _account, uint _amount, uint _mint) external validateMint(_mint) { //validateMint checks if treshold is below 300 Ethers else call reverted
        totalMinted = totalMinted.add(_amount);
        super._mint(_account, _amount);
    }
    
    receive() external payable {
        uint _amount = msg.value;
        msg.sender.transfer(_amount);
    }
}