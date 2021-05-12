/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-03-22
*/

pragma solidity =0.6.6;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Pausable is Context {

    event Paused(address account);


    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }


    function paused() public view returns (bool) {
        return _paused;
    }


    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }


    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }


    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }


    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

abstract contract ERC20Pausable is ERC20, Pausable {
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

contract SaltedFish is ERC20Pausable {
    event TransferLog(address recipient, uint256 amount, uint256 realAmount); //转账事件
    event TransferFromLog(address sender, address recipient,uint256 amount, uint256 realAmount); //转账事件

    address factory;
    address _operator;
    address _pauser;
    uint256 private constant _totalSupply = 100000000000 * 1e18;     //总量100000000000枚
    uint256 private constant _preSupply = 10000000 * 1e18;     //总量100000000000枚
    uint256 private _totalPart = 100000; //总份额
    uint256 public _feePart = 3000; //手续费比例
    address public _feeAddress = 0x980f9dC46Ecf3Fc0fA972f1Cf0B02442C05A4f2D;
    uint256 public _blackHolePart = 2000; //黑洞比例
    uint256 public _liquidityPart = 5000; //流动性比例
    address public _liquidityAddress=0x96187B32ded805179376D517dbAB1F0986310b2A;
    mapping (address => bool) public IsWithoutFeeAccount;//账户是否排除手续费

    constructor(address operator,address pauser) public ERC20("Salted Fish","FISH") {
        _operator = operator;
        _pauser=pauser;
        _setupDecimals(18);
        factory=msg.sender;
        _mint(msg.sender, _preSupply);
    }


    modifier onlyFactory(){
        require(msg.sender==factory,"only Factory");
        _;
    }
    modifier onlyOperator(){
        require(msg.sender == _operator,"not allowed");
        _;
    }
    modifier onlyPauser(){
        require(msg.sender == _pauser,"not allowed");
        _;
    }

    function pause() public  onlyPauser{
        _pause();
    }

    function unpause() public  onlyPauser{
        _unpause();
    }

    function changeUser(address new_operator, address new_pauser) public onlyFactory{
        _pauser=new_pauser;
        _operator=new_operator;
    }

    function mint(address account, uint256 amount) public whenNotPaused onlyOperator {
        require(amount.add(totalSupply()) <= _totalSupply,"Over total circulation");
        _mint(account, amount);
    }

    function burn(address account , uint256 amount) public whenNotPaused onlyOperator {
        _burn(account,amount);
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (IsWithoutFeeAccount[_msgSender()]){
            super.transfer(recipient, amount);
            emit TransferLog(recipient, amount, amount);
            return true;
        }
        require(balanceOf(_msgSender())>=amount,"Home Token: transfer amount exceeds balance");
        uint256 feeAmout=amount.mul(_feePart).div(_totalPart);
        uint256 blackHoleAmout=amount.mul(_blackHolePart).div(_totalPart);
        uint256 liquidityAmout=amount.mul(_liquidityPart).div(_totalPart);
        uint256 realPart=_totalPart.sub(_feePart).sub(_blackHolePart).sub(_liquidityPart);
        uint256 realAmount=amount.mul(realPart).div(_totalPart);
        super.transfer(_feeAddress, feeAmout);
        _burn(_msgSender(), blackHoleAmout);
        super.transfer(_liquidityAddress, liquidityAmout);
        super.transfer(recipient, realAmount);
        emit TransferLog(recipient, amount, realAmount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
         if (IsWithoutFeeAccount[_msgSender()]){
            super.transfer(recipient, amount);
            emit TransferFromLog(sender, recipient, amount, amount); 
            return true;
        }
        require(balanceOf(sender)>=amount,"Home Token: transfer amount exceeds balance");
        uint256 feeAmout=amount.mul(_feePart).div(_totalPart);
        uint256 blackHoleAmout=amount.mul(_blackHolePart).div(_totalPart);
        uint256 liquidityAmout=amount.mul(_liquidityPart).div(_totalPart);
        uint256 realPart=_totalPart.sub(_feePart).sub(_blackHolePart).sub(_liquidityPart);
        uint256 realAmount=amount.mul(realPart).div(_totalPart);
        super.transferFrom(sender,_feeAddress, feeAmout);
        _burn(_msgSender(), blackHoleAmout);
        super.transferFrom(sender,_liquidityAddress, liquidityAmout);
        super.transferFrom(sender,recipient,realAmount);
        emit TransferFromLog(sender, recipient, amount, realAmount); 
        return true;
    }

    /**
    * @dev 设置手续费比例
    *
    */
    function setFeePart(uint256 feePart,uint256 blackHolePart,uint256 liquidityPart) public onlyOperator {
        uint256 totalFeePart=feePart.add(blackHolePart).add(liquidityPart);
        require(_totalPart>totalFeePart, "Home Token: Set fee part error");
        _feePart = feePart;
        _blackHolePart = blackHolePart;
        _liquidityPart-liquidityPart;
    }

    /**
    * @dev 设置地址
    *
    */
    function setFeePart(address feeAddress,address liquidityAddress) public onlyOperator {
        _feeAddress=feeAddress;
        _liquidityAddress=liquidityAddress;
    }

    /**
    * @dev 设置地址
    *
    */
    function setWithoutFeeAccount(address account,bool withoutFee) public onlyOperator {
       IsWithoutFeeAccount[account]=withoutFee;
    }

}