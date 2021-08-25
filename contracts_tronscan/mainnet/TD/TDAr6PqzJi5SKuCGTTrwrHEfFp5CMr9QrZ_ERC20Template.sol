//SourceUnit: DIM.sol


pragma solidity ^0.5.0;

interface TokenTransfer {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
}
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
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

contract ERC20 is IERC20 {
    
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
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
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}
contract OrderData is ERC20,owned{
    struct OrderInfo {
        address userAddress;
        address tokenAddress;
        uint256 amount;
        string remarks;
    }
    mapping(uint256 => OrderInfo) public orderInfos;
    uint256 public lastOrderId = 0;
     struct FunctionInfo {  
        address userAddress;
        string content;
    }
    mapping(uint256 => FunctionInfo) public functionInfos;
    uint256 public lastFunctionId = 0;
    
    TokenTransfer public tokenTransfers; 
    address payable public subcoinAddress = 0x03A9E9d342C7bb4befcD7E51BDd7CE5d395Bd8FE;
    address public mainAddress = 0x1000000000000000000000000000000000000000;
    address public dimAddress = 0x2000000000000000000000000000000000000000;
    
    function recharge(address _tokenAddress,uint256 amount,string calldata remarks) external payable {
        uint256 _amount = amount;
        require(amount > 0, "Recharge quantity must be greater than 0");
        if(_tokenAddress == mainAddress && msg.value>0 ){
            subcoinAddress.transfer(msg.value);
            _amount = msg.value;
        }else if(_tokenAddress == dimAddress){
           _transfer(msg.sender, subcoinAddress, amount);
        }else{
            tokenTransfers = TokenTransfer(_tokenAddress);
            tokenTransfers.transferFrom(msg.sender,subcoinAddress,amount);
        }
         OrderInfo memory orderInfo = OrderInfo({
            userAddress: msg.sender,
            tokenAddress:_tokenAddress,
            amount:_amount,
            remarks:remarks
        });
        lastOrderId = lastOrderId+1;
        orderInfos[lastOrderId] = orderInfo;
    }
    function saveFunction(string calldata content) external {
       FunctionInfo memory functionInfo = FunctionInfo({
            userAddress: msg.sender,
            content: content
        });
        lastFunctionId = lastFunctionId+1;
        functionInfos[lastFunctionId] = functionInfo;
    }
     function withdrawalCoin(address payable userAddress,address tokenAddress,uint256 amount) external onlyOwner{
        if(tokenAddress == mainAddress){
            userAddress.transfer(amount);
        }else{
            tokenTransfers = TokenTransfer(tokenAddress);
            tokenTransfers.transfer(userAddress,amount);
        }
    }
    function setSubcoinAddress(address payable _subcoinAddress) external onlyOwner{
        subcoinAddress = _subcoinAddress;
    }
     function setMainAddress(address _tokenAddress) external onlyOwner{
        mainAddress = _tokenAddress;
    }
     function setDimAddress(address _tokenAddress) external onlyOwner{
        dimAddress = _tokenAddress;
    }
    function setLastOrderId(uint256 _lastOrderId) external onlyOwner{
        lastOrderId = _lastOrderId;
    }
     function getReserves()public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
      
        return(1,1,1);
    }
    
}
contract ERC20Template is ERC20, ERC20Detailed,OrderData {
    constructor () public ERC20Detailed("Dim Token", "DIM", 18) {
        _mint(subcoinAddress, 999949311 * (10 ** uint256(decimals())));
    }
}