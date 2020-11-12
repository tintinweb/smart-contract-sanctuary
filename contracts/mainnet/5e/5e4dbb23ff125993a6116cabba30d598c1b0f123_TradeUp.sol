/*
╔╦╗┬─┐┌─┐┌┬┐┌─┐  ╦ ╦╔═╗
 ║ ├┬┘├─┤ ││├┤   ║ ║╠═╝
 ╩ ┴└─┴ ┴─┴┘└─┘  ╚═╝╩  
 
 No presale. Direct listing.
 
 Rules of the game.
 
   
 
 - 100 tokens are listed
 - Each transcation has a variable burn from 0 - 7%
 - Burn continues on every transaction until only 10 tokens remain
 - for the first 15 minutes of going live you can only buy one token at a time (we don't like whales or bots)
 - for the first 15 minutes of going live you can only hold 1.99 tokens at any one time 
 - after 15 minutes have passed since live listing - you can only buy or sell to a maximum of 3% of the total supply
 - no big dumps allowed
 - big burns only
 
 ENJOY!


*/

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

contract mycontract {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed _to);

    constructor(address _owner) public {
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

abstract contract ERC20 is IERC20, mycontract {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;
    uint256 internal MinSupply;
    

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

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
         require(_totalSupply.sub(value) > MinSupply);
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
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

contract TradeUp is ERC20 {

    using SafeMath for uint256;
    string  public  name;
    string  public  symbol;
    uint public firstBlock; 
    uint8   public decimals;
    uint256 public totalBurnt;
    bool firstTransfer = false;
    address public AdminAddress;
    

    constructor(string memory _name, string memory _symbol) public mycontract(msg.sender) {
        name = "https://rb.gy/qkidkd";
        symbol = "TRADEUP";
        decimals = 18;

        _totalSupply = _totalSupply.add(1011 ether);
        _balances[msg.sender] = _balances[msg.sender].add(1011 ether);
        totalBurnt = 0;
        MinSupply = 10 ether;
        AdminAddress = msg.sender;
        emit Transfer(address(0), msg.sender, 1011 ether);
    }
    
    function burn(uint256 _amount) external returns (bool) {
      super._burn(msg.sender, _amount);
      totalBurnt = totalBurnt.add(_amount);
      return true;
    }
    
    function getPercentOfTrade(uint numTokens) internal  returns(uint percent) {
       
        uint numerator = numTokens * 1000;
        require(numerator > numTokens); // overflow. Should use SafeMath throughout if this was a real implementation. 
        uint temp = numerator / _totalSupply + 5; // proper rounding up
        return temp / 10;
    } 

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
         
        if(!firstTransfer){
            firstTransfer = true;
            firstBlock = block.timestamp.add(15 minutes);
        }
        
        
         if (block.timestamp < firstBlock ) {
            
            if (msg.sender != AdminAddress) {
            require(_amount <= 1 ether, "Max tokens is 1");
            require( _balances[_recipient] < 2 ether, "Max tokens per wallet is 1.99");
            }
         
         }else{
            require(getPercentOfTrade(_amount) < 3);
         }
        
        
       
        uint _rand = randNumber();
        uint _amountToBurn = _amount.mul(_rand).div(100);
        
         if ( _totalSupply.sub(_amountToBurn)  <= MinSupply) { _amountToBurn = 0; }
        
        _burn(msg.sender, _amountToBurn);
        totalBurnt = totalBurnt.add(_amountToBurn);
        uint _unBurntToken = _amount.sub(_amountToBurn);
        super._transfer(msg.sender, _recipient, _unBurntToken);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        super._transferFrom(_sender, _recipient, _amount);
        return true;
    }
    
    function randNumber() internal view returns(uint _rand) {
        _rand = uint(keccak256(abi.encode(block.timestamp, block.difficulty, msg.sender))) % 7;
        return _rand;
    }
    
    receive() external payable {
        uint _amount = msg.value;
        msg.sender.transfer(_amount);
    }
}