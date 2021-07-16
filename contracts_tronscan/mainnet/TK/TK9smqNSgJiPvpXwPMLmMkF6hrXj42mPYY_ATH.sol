//SourceUnit: ATH.sol

pragma solidity ^0.5.8;


interface cashPoolInterface{
    function cashJoin(address spender,uint256 tansAmount,address recipient, uint256 reciAmount,uint256 teamAmount) external returns(bool);
}
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    
    
    uint256 public burnRates1 = 5; //4%
    uint256 public teamRates1 = 5; // 5%
    
    uint256 public burnRates2 = 1; // 1%
    uint256 public teamRates2 = 1; // 1%
    uint256 public burnLevels1 = 10000000*1e18;//20000000 - 10000000
    uint256 public burnLevels2 = 5000000*1e18;//25000 - 10000
    bool public stopBurn = false; // true stop Burn ,false start burn;
     mapping(address => bool) public burnWhitList;
     address public cashPoolAddr;//cash Pool
    
    function _setBurnRate(uint256 level,uint256 rate,uint256 teamRate) internal{
        require(level >=1 && level <=2,"ERC20: burn level err");
        require(rate<50,"ERC20: burn level must smail 100");
        if(level == 1){
            
            burnRates1 = rate; 
            teamRates1 = teamRate;
        }else if(level == 2){
            burnRates2 = rate;
            teamRates2 = teamRate;
        }
    }
    
    function _setWhiteList(address account,bool isAdd) internal{
        require(account != address(0),"ERC20: whitlist can not be zeor");
        burnWhitList[account] = isAdd;
    }
    function _setBurnLevel(uint256 level,uint256 levelAmount) internal{
        require(level >=1 && level <=2,"ERC20: burn level err");
        if(level == 2){ //20000000 - 10000000
            require(levelAmount > burnLevels2 && levelAmount > 5000000*1e18,"ERC20: levelAmout must bigger then burnLevels2");
            burnLevels1 = levelAmount;
        }else if(level == 1){ //10000000 - 5000000
            require(levelAmount > 5000000*1e18 && levelAmount < burnLevels1,"ERC20: levelAmout must bigger then burnLevels2");
            burnLevels2 = levelAmount;
        }
    }
    
    function _setStopBurn(bool flage) internal{
        stopBurn = flage;
    }
    
    function _setCashPoolAddr(address addr) internal{
        cashPoolAddr = addr;
        burnWhitList[cashPoolAddr] = true;
    }
    
   
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        uint256 burnAmount  = calcBurn(amount,false);
        
        if(burnWhitList[sender] || burnWhitList[recipient]){
            burnAmount = 0;
        }
        if(burnAmount == 0){
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
        }else{
            uint256 teamBurnAmount = calcBurn(amount,true);
             uint256 leftAmount = amount.sub(burnAmount.add(teamBurnAmount));
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(leftAmount);
              
        
            _balances[cashPoolAddr] = _balances[cashPoolAddr].add(teamBurnAmount);
            _balances[address(0)] = _balances[address(0)].add(burnAmount);
            _totalSupply = _totalSupply.sub(burnAmount);
            
            if (cashPoolAddr != address(0)){
                cashPoolInterface(cashPoolAddr).cashJoin(sender,amount,recipient,leftAmount,teamBurnAmount);
            }
        }
        
        emit Transfer(sender, recipient, amount);
    }
    
    function calcBurn(uint256 amount,bool isTeam) internal view returns(uint256){
        if(stopBurn){
            return 0;
        }
        uint256 totalSup = _totalSupply;
        if(totalSup >= burnLevels1){
            
            if(isTeam){
                return  amount.mul(teamRates1).div(100);
            }else{
                return  amount.mul(burnRates1).div(100);
            }
            
        }else if(totalSup > burnLevels2){
            
            if(isTeam){
                return amount.mul(teamRates2).div(100);
            }else{
                return amount.mul(burnRates2).div(100);
            }
            
        }
        return 0;
        
    }
    
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ATH is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint;
  uint256 public totalSpy = 20000000e18;
  
  
  address public governance;
  mapping (address => bool) public minters;

  constructor () public ERC20Detailed("Athena", "ATH", 18) {
      governance = msg.sender;
      _mint(msg.sender, totalSpy);
      
  }

  
  function setBurnStop(bool isStop) public {
      require(msg.sender == governance);
      _setStopBurn(isStop);
  }
  
  function setCashPoolAddr(address cashAddr)  public {
      require(msg.sender == governance);
      require(cashAddr != address(0),"WSD: cashAddr can not be zero");
      _setCashPoolAddr(cashAddr);
  }
  
  function  setBRate(uint256 level,uint256 rate,uint256 teamRate) public {
       require(msg.sender == governance);
       _setBurnRate(level,rate,teamRate);
  } 
  
  function setBLevel(uint256 level,uint256 levelAmount) public {
      require(msg.sender == governance);
      _setBurnLevel(level,levelAmount);
  }
  
  function setBurnWhiteList(address account,bool isAdd) public {
      _setWhiteList(account,isAdd);
  }
 
}