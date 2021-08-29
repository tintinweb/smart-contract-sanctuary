pragma solidity ^0.8.6;

interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
    function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


//для мета транзакций (возможности оплаты 3-ей стороной)
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Token is  Context, IERC20 {       //интерфейс по рекомендации спецификации
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances; //разрешения на передачу 
                        //токенов, от владельца к другому адресу
    address payable public owner;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
        owner = payable(msg.sender);
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;    //все токены у создателя, потом - распределяет
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    //случайные деньги - к создателю контракта
    receive() external payable {    
        owner.call{value: msg.value}; 
    }

    function name() public virtual view returns (string memory) {
        return _name;
    }

    function symbol() public virtual view  returns (string memory) {
        return _symbol;
    }

    function decimals() public virtual pure returns (uint8) {
        return 18;
    }

    function totalSupply() public virtual override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public virtual override view returns (uint256) {
        return balances[account];
    }
    
     ///от `msg.sender` отсылаются токены, вызывается tokenOwner
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), to, amount);     
        return true;
    }

    ///если tokenOwner согласен с пересылкой токенов, то происходит их пересылка конкретному адресу
    ///вызывается тем, у кого есть разрешение на пересылку
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        uint256 currentAllowance = allowances[sender][_msgSender()];
        require(currentAllowance >= amount);
        _transfer(sender, recipient, amount);
        allowances[sender][_msgSender()] -= amount;
        return true;
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) external virtual override view returns (uint256) {
        return allowances[tokenOwner][spender];
    }
    
    ///extra functions, вызываются tokenOwner
    function increaseAllowance(address spender, uint256 addValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subValue) public virtual returns (bool) {
        uint256 currentAllowance = allowances[_msgSender()][spender];
        require(currentAllowance >= subValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] - subValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(balances[sender] >= amount, "Unappropriate amount for transfer");
        balances[sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address tokenOwner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(amount <= _totalSupply, "Unappropriate amount for transfer"); 
        require(tokenOwner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}