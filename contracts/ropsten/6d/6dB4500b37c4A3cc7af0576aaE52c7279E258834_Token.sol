/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed currentOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Ownable : Function called by unauthorized user."
        );
        _;
    }

    function owner() external view returns (address ownerAddress) {
        ownerAddress = _owner;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
        returns (bool success)
    {
        require(newOwner != address(0), "Ownable/transferOwnership : cannot transfer ownership to zero address");
        success = _transferOwnership(newOwner);
    }

    function renounceOwnership() external onlyOwner returns (bool success) {
        success = _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal returns (bool success) {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        success = true;
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
}interface IERC20Metadata is IERC20 {
    /**
     * @dev  Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev  Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev  Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
abstract contract ERC20 is Context, IERC20
{
	uint256 internal _totalSupply;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    constructor () {
		
    }
	
	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
	
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }	
	
    function _mint(address _to, uint256 _amount) internal virtual
    {
        _totalSupply = _totalSupply + _amount;
        _balances[_to] = _balances[_to] + _amount;
        emit Transfer(address(0), _to, _amount);
    }
	
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
	
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
}







contract Token is
	IERC20Metadata
	,ERC20
{
    string private _name;
    string private _symbol;
	uint8  private _decimals;
	
	
			constructor (uint256 initial_supply_, uint8 decimals_,string memory name_, string memory symbol_)
			{
		_name     = name_;
		_symbol   = symbol_;
		_decimals = decimals_; 
		
					_balances[_msgSender()] = initial_supply_; 
			_totalSupply            = initial_supply_;
			
			emit Transfer(address(0), _msgSender(), _totalSupply);			
			}
		
	

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }    

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function transfer(address recipient, uint256 amount) public 
				virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public 
				virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
	
    
}