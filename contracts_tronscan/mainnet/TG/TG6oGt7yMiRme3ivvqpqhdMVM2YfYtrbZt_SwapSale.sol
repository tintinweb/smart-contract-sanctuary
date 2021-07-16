//SourceUnit: SwapSale.sol

pragma solidity 0.5.10;
contract ERC20Basic {
  function totalSupply() public view returns (uint);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // Solidity only automatically asserts when dividing by 0
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
interface TRC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract _ERC20 is Context, TRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract SwapSale is _ERC20{

    constructor(address OWNER, address NUI, address BURN)
        public
    {
		OWNER_ADDR = OWNER;
		NUI_ADDR = NUI;
		BURN_ADDR = BURN;
    }

//Addresses
    address internal OWNER_ADDR;
    address public NUI_ADDR;
    address public NES_ADDR;
    address internal BURN_ADDR;

//Claim State
	bool public claimable = false;
	
//Balances
	uint256 public atCloseTotalNui = 0;
	
	uint256 public atCloseAvailableNes = 0;

	mapping(uint256 => mapping(address => uint256)) public nuiDeposits; //User deposits
	uint256 public ITERATION = 0;
	
//Deposit
    function depositNui(uint256 depositAmount)
        external
    {
		require(claimable == false, "Deposits currently closed.");
		require(depositAmount > 0, "Must deposit more than 0");
        require(depositAmount < ERC20(NUI_ADDR).balanceOf(address(msg.sender)), "Not enough NUI for this deposit.");
							
		ERC20(address(NUI_ADDR)).transferFrom(msg.sender, address(this), depositAmount);
		
		nuiDeposits[ITERATION][msg.sender] += depositAmount;
		atCloseTotalNui += depositAmount;
    }
	
//Claims
    function claimNes() 
		external
    {
		require(claimable == true, "Claiming of NES not available yet.");
		require(nuiDeposits[ITERATION][msg.sender] > 0, "No NUI deposits were made by this user.");
		
		uint256 nesEarned = _calcCurrentNesReturn(msg.sender);
		ERC20(address(NES_ADDR)).transfer(msg.sender, nesEarned);
		nuiDeposits[ITERATION][msg.sender] = 0;
    }
	
	function _calcCurrentNesReturn(address depositerAddress)
		internal
		view
		returns (uint256 payout)
	{
		if(atCloseTotalNui == 0 || _nesBalance() == 0)
			return 0;
		else
			return (atCloseAvailableNes * nuiDeposits[ITERATION][depositerAddress]) / atCloseTotalNui;
	}
	
	function calcCurrentNesReturn()
		external
		view
		returns (uint256)
	{
		return _calcCurrentNesReturn(msg.sender);
	}
	
//Balances	
	function totalUserDeposit() 
		external
		view
		returns (uint256)
	{
		return nuiDeposits[ITERATION][msg.sender];
	}
	function _nuiBalance() 
		internal 
		view
		returns (uint256)
	{
		return ERC20(NUI_ADDR).balanceOf(address(this));
	}
	function _nesBalance() 
		internal
		view
		returns (uint256)
	{
		return ERC20(NES_ADDR).balanceOf(address(this));
	}
	
	function nuiBalance() 
		external 
		view
		returns (uint256)
	{
		return _nuiBalance();
	}
	function nesBalance() 
		external
		view
		returns (uint256)
	{
		return _nesBalance();
	}
	
//Owner Only
	function canClaim(bool state)
		external
	{	
		require(msg.sender == OWNER_ADDR, "Only the contract owner can use this.");
		require(state == false || state == true, "Invalid entry.");

		if(state == true && claimable != true){
			claimable = state;
			atCloseTotalNui = _nuiBalance();
			atCloseAvailableNes = _nesBalance();
			_burnNui();
		}
		if(state == false && claimable !=false){
			claimable = state;
			ITERATION++;
			_burnNui();
			atCloseTotalNui = 0;
			atCloseAvailableNes = _nesBalance();
		}		
	}	
	
	function setNesAddress(address nesAddress)
		external
	{
		require(msg.sender == OWNER_ADDR, "Only the contract owner can use this.");
		NES_ADDR = nesAddress;
	}
	
	function depositNes(uint256 nesDeposit)
		external
	{
		require(msg.sender == OWNER_ADDR, "Only the contract owner can use this.");
		require(nesDeposit > 0, "Must deposit more than 0");
        require(nesDeposit < ERC20(NES_ADDR).balanceOf(address(msg.sender)), "Not enough NES for this deposit.");
		
		ERC20(address(NES_ADDR)).transferFrom(msg.sender, address(this), nesDeposit);
		
		atCloseAvailableNes += nesDeposit;
	}
	
	function _burnNui()
		private
	{
		require(msg.sender == OWNER_ADDR, "Only the contract owner can use this.");
		ERC20(address(NUI_ADDR)).transfer(BURN_ADDR, _nuiBalance());
	}
}