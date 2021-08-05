/**
 *Submitted for verification at Etherscan.io on 2020-05-22
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-11
*/

pragma solidity ^0.6.8;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

abstract contract ERC20Token {
  function approve(address spender, uint256 value) public virtual returns (bool);
  function transferFrom (address from, address to, uint value) public virtual returns (bool);
}

contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    constructor() public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}

contract WrappedBOMB is Ownable {
   
    using SafeMath for uint256;
  
    string public name     = "Wrapped BOMB";
    string public symbol   = "WBOMB";
    uint8  public decimals = 0;
    
    address BOMB_CONTRACT = 0x1C95b093d6C236d3EF7c796fE33f9CC6b8606714;
    
    uint256 public _totalSupply = 0;
    uint256 basePercent = 100;
    
    event Approval(address indexed src, address indexed guy, uint256 amount);
    event Transfer(address indexed src, address indexed to, uint256 amount);
    event Deposit(address indexed to, uint256 amount);
    event Withdrawal(address indexed src, uint256 amount);
    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);
    

    mapping (address => uint256)                       public  balanceOf;
    mapping (address => mapping (address => uint256))  public  allowance;
    
 
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;

    fallback()  external payable {
        revert();
    }
    
    function _isWhitelisted(address _from, address _to) internal view returns (bool) {
        return whitelistFrom[_from]||whitelistTo[_to];
    }

    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }

    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }
    
    function deposit(uint256 amount) public returns(uint256){ //deposit burn is intrinsic to BOMB
    
        require(ERC20Token(BOMB_CONTRACT).transferFrom(address(msg.sender),address(this),amount),"TransferFailed");
            
        //calc actual deposit amount due to BOMB burn
        uint256 tokensToBurn = findOnePercent(amount);
        uint256 actual = amount.sub(tokensToBurn);
        
        balanceOf[msg.sender] += actual;
        _totalSupply += actual;
        emit Deposit(msg.sender, amount);
        emit Transfer(address(this), address(msg.sender), actual);
        return actual;
        
        
    }
    
    function withdraw(uint256 amount) public returns(uint256){ //
        require(balanceOf[msg.sender] >= amount,"NotEnoughBalance");
        balanceOf[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Withdrawal(msg.sender, amount);
        emit Transfer(address(msg.sender), address(this), amount);
        ERC20Token(BOMB_CONTRACT).approve(address(this),amount);
        ERC20Token(BOMB_CONTRACT).transferFrom(address(this),address(msg.sender),amount);
        return amount;
        
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function approve(address guy, uint256 amount) public returns (bool) {
        allowance[msg.sender][guy] = amount;
        emit Approval(msg.sender, guy, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) { //unibombs
        return transferFrom(msg.sender, to, amount);
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }
    
    function findOnePercent(uint256 value) public view returns (uint256)  {
        uint256 roundValue = value.ceil(basePercent);
        uint256 onePercent = roundValue.mul(basePercent).div(10000);
        return onePercent;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balanceOf[from],"NotEnoughBalance");

        if (from != msg.sender && allowance[from][msg.sender] != uint(-1)) {
            require(allowance[from][msg.sender] >= value);
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        
        balanceOf[from] = balanceOf[from].sub(value);

        if(!_isWhitelisted(from, to)){
            uint256 tokensToBurn = findOnePercent(value);
            uint256 tokensToTransfer = value.sub(tokensToBurn);

            balanceOf[to] = balanceOf[to].add(tokensToTransfer);
            _totalSupply = _totalSupply.sub(tokensToBurn);

            emit Transfer(from, to, tokensToTransfer);
            emit Transfer(from, address(0), tokensToBurn);
            ERC20Token(BOMB_CONTRACT).approve(address(this),value);
            ERC20Token(BOMB_CONTRACT).transferFrom(address(this),address(this),value); //burn
            //
            }
        
        else{
          //  uint256 tokensToTransfer = .sub(tokensToBurn);

            balanceOf[to] = balanceOf[to].add(value);
            
            emit Transfer(from, to, value);
       }
        return true;
    }
    
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = (allowance[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = (allowance[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(amount != 0);
        require(amount <= balanceOf[account]);
        _totalSupply = _totalSupply.sub(amount);
        balanceOf[account] = balanceOf[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(amount <= allowance[account][msg.sender]);
        allowance[account][msg.sender] = allowance[account][msg.sender].sub(amount);
        _burn(account, amount);
    }

}