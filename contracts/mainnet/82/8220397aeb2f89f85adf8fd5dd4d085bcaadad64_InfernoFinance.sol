// --------------------------------
// Smart Contract for Inferno Finance
// 
// No Dev Share. No Team Tokens. No Marketing Fund. 
// No Airdrop. No Private Sale. No BS.
// All tokens community owned.
// 
// Incremental Burn every day up to 35%
// Anti Whale Feature - Only 2% of the total supply can be traded at a time
// 
// Telegram: https://t.me/inferno_finance
// Website: https://infernofinance.com
// Email: info@infernofinance.com
// Medium: infernofinance.medium.com
// --------------------------------

pragma solidity ^0.6.0;

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) 
    {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) 
    {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

// Owner is granted exclusive access to specific functions
// Deployer account is by default owner account
// Can be changed with transferOwnership

contract Ownable is Context 
{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	// Initializes contract setting deployer as initial owner
    constructor () internal 
	{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

	// Returns address of current owner
    function owner() public view returns (address) 
	{
        return _owner;
    }

	// Throw if called by any other account other than owner
    modifier onlyOwner() 
	{
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

	// Renounce ownership
    function renounceOwnership() public virtual onlyOwner 
	{
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

	// Transfer ownership
    function transferOwnership(address newOwner) public virtual onlyOwner 
	{
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;

interface IERC20 
{
	// Amount of tokens in existence
    function totalSupply() external view returns (uint256);

	// Amount of tokens owned by account
    function balanceOf(address account) external view returns (uint256);

	// Move amount tokens from caller to recipient, returns boolean and emits Transfer event
    function transfer(address recipient, uint256 amount) external returns (bool);

	// Returns remaining number of tokens that spender is allowed to spend on behalf of owner via transferFrom function
    function allowance(address owner, address spender) external view returns (uint256);

	// Sets amount as allowance of spender over caller's tokens, returns boolean and emits Approval event
    function approve(address spender, uint256 amount) external returns (bool);

	// Moves amount tokens from sender to recipient using allowance mechanism, amount is then deducted from caller's allowance
	// Returns boolean and emits Transfer event
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	// Emitted when value of tokens are moved from one account to another
    event Transfer(address indexed from, address indexed to, uint256 value);

	// Emitted when allowance of spender for an owner is set by a call to approve
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.0;

library SafeMath 
{
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
	{
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
	{
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
	{
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
	{
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) 
		{
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
	{
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
	{
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
	{
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
	{
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) 
    {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

pragma solidity ^0.6.2;

library Address 
{
    // Returns true if account is a contract
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal 
	{
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) 
	{
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) 
	{
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) 
	{
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) 
	{
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) 
	{
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) 
		{
            return returndata;
        } 
		
		else 
		{
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) 
			{
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly 
				{
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } 
			
			else 
			{
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.6.0;

contract ERC20 is Context, IERC20 
{
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public 
	{
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

	// Returns token name
    function name() public view returns (string memory) 
	{
        return _name;
    }

	// Returns token symbol
    function symbol() public view returns (string memory) 
	{
        return _symbol;
    }

	// Returns decimal
    function decimals() public view returns (uint8) 
	{
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) 
	{
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) 
	{
        return _balances[account];
    }

	// Recipient cannot be zero address, caller must have balance of at least amount
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) 
	{
        return _allowances[owner][spender];
    }

	// Spender cannot be zero address
    function approve(address spender, uint256 amount) public virtual override returns (bool) 
	{
        _approve(_msgSender(), spender, amount);
        return true;
    }

	// Emits Approval event indicating updated allowance, (sender and recipient cannot be zero address), sender must have balance of 
	// at least amount and caller must have allowance for sender's tokens of at least amount
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
	{
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

	// Automatically increase allowance granted to spender by caller
	// Emits Approval eent indicating updated allowance
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) 
	{
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

	// Automatically decrease allowance granted to spender by caller
	// Emits Approval event indicating updated allowance
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) 
	{
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

	// Move tokens from sender to recipient
    function _transfer(address sender, address recipient, uint256 amount) internal virtual 
	{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

	// Mint tokens
    function _mint(address account, uint256 amount) internal virtual 
	{
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

	// Burn tokens
    function _burn(address account, uint256 amount) internal virtual
	{
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual 
	{
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal 
	{
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// --------------------------------
// Inferno Finance
// --------------------------------
pragma solidity ^0.6.2;
contract InfernoFinance is ERC20, Ownable 
{
	// Token Details
	string constant tokenName = "Inferno Finance";
	string constant tokenSymbol = "INFNO";
	uint8  constant tokenDecimals = 18;
    uint256 private _totalSupply = 1000 * (10 ** 18);
	uint256 public basePercent = 100;

	constructor() public ERC20(tokenName, tokenSymbol) 
	{
		_mint(msg.sender, _totalSupply);
	}

	// Transfer Fee
	event TransferFeeChanged(uint256 newFee);
	event FeeRecipientChange(address account);
	event AddFeeException(address account);
	event RemoveFeeException(address account);

	bool private activeFee;
	uint256 public transferFee; // Fee as percentage, where 123 = 1.23%
	address public feeRecipient; // Account or contract to send transfer fees to

	// Exception to transfer fees, for example for Uniswap contracts.
	mapping (address => bool) public feeException;

	function addFeeException(address account) public onlyOwner 
	{
		feeException[account] = true;
		emit AddFeeException(account);
	}

	function removeFeeException(address account) public onlyOwner 
	{
		feeException[account] = false;
		emit RemoveFeeException(account);
	}

	function setTransferFee(uint256 fee) public onlyOwner 
	{
		// Maximum Possible Fee is 35%
		require(fee <= 3500, "Fee cannot be greater than 35%");
		if (fee == 0) 
		{
			activeFee = false;
		} 
		
		else 
		{
			activeFee = true;
		}
		
		transferFee = fee;
		emit TransferFeeChanged(fee);
	}

	function setTransferFeeRecipient(address account) public onlyOwner 
	{
		feeRecipient = account;
		emit FeeRecipientChange(account);
	}
	
	// Get 2%
	function percentSupply(uint256 value) public view returns (uint256)  
	{
		uint256 roundValue = value.ceil(basePercent);
		uint256 onePercent = roundValue.mul(basePercent).div(5000);
		return onePercent;
	}

	// Transfer recipient recives amount - fee
	function transfer(address recipient, uint256 amount) public override returns (bool) 
	{
		if (activeFee && feeException[_msgSender()] == false) 
		{
			uint256 twoPercent = percentSupply(_totalSupply);
		
			// Max transactable amount of 2% of total supply
			require (amount <= twoPercent);
		
			uint256 fee = transferFee.mul(amount).div(10000);
			uint amountLessFee = amount.sub(fee);
			_transfer(_msgSender(), recipient, amountLessFee);
			_transfer(_msgSender(), feeRecipient, fee);
		} 
		
		else 
		{
            _transfer(_msgSender(), recipient, amount);
        }
		
		return true;
	}

	// TransferFrom recipient recives amount, sender's account is debited amount + fee
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) 
	{
		if (activeFee && feeException[recipient] == false)
		{ 
		    uint256 twoPercent = percentSupply(_totalSupply);
		
			// Max transactable amount of 2% of total supply
			require (amount <= twoPercent);
		    
			_transfer(sender, recipient, amount);
			_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		}
	    
	     _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	
		return true;
	}
}