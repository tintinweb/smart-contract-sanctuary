/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IPancakeSwapFactory {
		event PairCreated(address indexed token0, address indexed token1, address pair, uint);

		function feeTo() external view returns (address);
		function feeToSetter() external view returns (address);

		function getPair(address tokenA, address tokenB) external view returns (address pair);
		function allPairs(uint) external view returns (address pair);
		function allPairsLength() external view returns (uint);

		function createPair(address tokenA, address tokenB) external returns (address pair);

		function setFeeTo(address) external;
		function setFeeToSetter(address) external;
}

interface IPancakeSwapPair {
		event Approval(address indexed owner, address indexed spender, uint value);
		event Transfer(address indexed from, address indexed to, uint value);

		function name() external pure returns (string memory);
		function symbol() external pure returns (string memory);
		function decimals() external pure returns (uint8);
		function totalSupply() external view returns (uint);
		function balanceOf(address owner) external view returns (uint);
		function allowance(address owner, address spender) external view returns (uint);

		function approve(address spender, uint value) external returns (bool);
		function transfer(address to, uint value) external returns (bool);
		function transferFrom(address from, address to, uint value) external returns (bool);

		function DOMAIN_SEPARATOR() external view returns (bytes32);
		function PERMIT_TYPEHASH() external pure returns (bytes32);
		function nonces(address owner) external view returns (uint);

		function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

		event Mint(address indexed sender, uint amount0, uint amount1);
		event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
		event Swap(
				address indexed sender,
				uint amount0In,
				uint amount1In,
				uint amount0Out,
				uint amount1Out,
				address indexed to
		);
		event Sync(uint112 reserve0, uint112 reserve1);

		function MINIMUM_LIQUIDITY() external pure returns (uint);
		function factory() external view returns (address);
		function token0() external view returns (address);
		function token1() external view returns (address);
		function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
		function price0CumulativeLast() external view returns (uint);
		function price1CumulativeLast() external view returns (uint);
		function kLast() external view returns (uint);

		function mint(address to) external returns (uint liquidity);
		function burn(address to) external returns (uint amount0, uint amount1);
		function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
		function skim(address to) external;
		function sync() external;

		function initialize(address, address) external;
}

interface IPancakeSwapRouter{
		function factory() external pure returns (address);
		function WETH() external pure returns (address);

		function addLiquidity(
				address tokenA,
				address tokenB,
				uint amountADesired,
				uint amountBDesired,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline
		) external returns (uint amountA, uint amountB, uint liquidity);
		function addLiquidityETH(
				address token,
				uint amountTokenDesired,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline
		) external payable returns (uint amountToken, uint amountETH, uint liquidity);
		function removeLiquidity(
				address tokenA,
				address tokenB,
				uint liquidity,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline
		) external returns (uint amountA, uint amountB);
		function removeLiquidityETH(
				address token,
				uint liquidity,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline
		) external returns (uint amountToken, uint amountETH);
		function removeLiquidityWithPermit(
				address tokenA,
				address tokenB,
				uint liquidity,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline,
				bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountA, uint amountB);
		function removeLiquidityETHWithPermit(
				address token,
				uint liquidity,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline,
				bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountToken, uint amountETH);
		function swapExactTokensForTokens(
				uint amountIn,
				uint amountOutMin,
				address[] calldata path,
				address to,
				uint deadline
		) external returns (uint[] memory amounts);
		function swapTokensForExactTokens(
				uint amountOut,
				uint amountInMax,
				address[] calldata path,
				address to,
				uint deadline
		) external returns (uint[] memory amounts);
		function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
				external
				payable
				returns (uint[] memory amounts);
		function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
				external
				returns (uint[] memory amounts);
		function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
				external
				returns (uint[] memory amounts);
		function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
				external
				payable
				returns (uint[] memory amounts);

		function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
		function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
		function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
		function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
		function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
		function removeLiquidityETHSupportingFeeOnTransferTokens(
			address token,
			uint liquidity,
			uint amountTokenMin,
			uint amountETHMin,
			address to,
			uint deadline
		) external returns (uint amountETH);
		function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
			address token,
			uint liquidity,
			uint amountTokenMin,
			uint amountETHMin,
			address to,
			uint deadline,
			bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountETH);
	
		function swapExactTokensForTokensSupportingFeeOnTransferTokens(
			uint amountIn,
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external;
		function swapExactETHForTokensSupportingFeeOnTransferTokens(
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external payable;
		function swapExactTokensForETHSupportingFeeOnTransferTokens(
			uint amountIn,
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external;
}

contract Context {
	// Empty internal constructor, to prevent people from mistakenly deploying
	// an instance of this contract, which should be used via inheritance.
	constructor () internal { }

	function _msgSender() internal view returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}
    /* --------- Access Control --------- */
contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	* @dev Initializes the contract setting the deployer as the initial owner.
	*/
	constructor () internal {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	/**
	* @dev Returns the address of the current owner.
	*/
	function owner() public view returns (address) {
		return _owner;
	}

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	/**
	* @dev Leaves the contract without owner. It will not be possible to call
	* `onlyOwner` functions anymore. Can only be called by the current owner.
	*
	* NOTE: Renouncing ownership will leave the contract without an owner,
	* thereby removing any functionality that is only available to the owner.
	*/
	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	/**
	* @dev Transfers ownership of the contract to a new account (`newOwner`).
	* Can only be called by the current owner.
	*/
	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	/**
	* @dev Transfers ownership of the contract to a new account (`newOwner`).
	*/
	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

    /* --------- safe math --------- */
library SafeMath {
	/**
	* @dev Returns the addition of two unsigned integers, reverting on
	* overflow.
	*
	* Counterpart to Solidity's `+` operator.
	*
	* Requirements:
	* - Addition cannot overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	/**
	* @dev Returns the subtraction of two unsigned integers, reverting on
	* overflow (when the result is negative).
	*
	* Counterpart to Solidity's `-` operator.
	*
	* Requirements:
	* - Subtraction cannot overflow.
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	/**
	* @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	* overflow (when the result is negative).
	*
	* Counterpart to Solidity's `-` operator.
	*
	* Requirements:
	* - Subtraction cannot overflow.
	*/
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

	/**
	* @dev Returns the multiplication of two unsigned integers, reverting on
	* overflow.
	*
	* Counterpart to Solidity's `*` operator.
	*
	* Requirements:
	* - Multiplication cannot overflow.
	*/
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

	/**
	* @dev Returns the integer division of two unsigned integers. Reverts on
	* division by zero. The result is rounded towards zero.
	*
	* Counterpart to Solidity's `/` operator. Note: this function uses a
	* `revert` opcode (which leaves remaining gas untouched) while Solidity
	* uses an invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	/**
	* @dev Returns the integer division of two unsigned integers. Reverts with custom message on
	* division by zero. The result is rounded towards zero.
	*
	* Counterpart to Solidity's `/` operator. Note: this function uses a
	* `revert` opcode (which leaves remaining gas untouched) while Solidity
	* uses an invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	* @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	* Reverts when dividing by zero.
	*
	* Counterpart to Solidity's `%` operator. This function uses a `revert`
	* opcode (which leaves remaining gas untouched) while Solidity uses an
	* invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	/**
	* @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	* Reverts with custom message when dividing by zero.
	*
	* Counterpart to Solidity's `%` operator. This function uses a `revert`
	* opcode (which leaves remaining gas untouched) while Solidity uses an
	* invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

contract LambSwapToken is  Context, Ownable  {
	using SafeMath for uint256;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) _isExcludeFromFee;
    mapping(address => bool) isBlackList;
    mapping(address => bool) isDeveloper;
    mapping(address => bool) isMinter;
    mapping(address => address) _delegates;
	mapping(address => uint32) public numCheckpoints;
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
    mapping(address => uint256) public nonces;

	uint256 private _totalSupply;
	uint256 public _maxSupply = 500e9 * 1e9; // maximum supply: 500,000,000,000
	uint8 private _decimals;
	string private _symbol;
	string private _name;

	//////////////////////////////////////////////
    /* ----------- special features ----------- */
	//////////////////////////////////////////////

    event SetWhiteList(address user, bool isWhiteList);
    event SetBlackList(address user, bool isBlackList);
    event SetDeveloper(address user, bool isDeveloper);
    event SetSellFee(Fees sellFees);
    event SetBuyFee(Fees buyFees);
	event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );
	event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

	struct Fees {
		uint burn;
		uint marketing;
		uint LP;
		uint buyback;
        uint totalFee;
	}
	struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

	bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
        
    /* --------- special address info --------- */
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
	address public marketingAddress = 0x8B2057A12503b7270A50955909445cE7287CBa1a;
	address public LPAddress = 0x63E69DE92628b05802f5887d88a3D640be8A7bca;

    /* --------- exchange info --------- */
	IPancakeSwapRouter public PancakeSwapRouter;
	address public PancakeSwapV2Pair;

	bool inSwapAndLiquify;
	bool public swapAndLiquifyEnabled = true;

	modifier lockTheSwap {
		inSwapAndLiquify = true;
		_;
		inSwapAndLiquify = false;
	}

	modifier onlyMinter() {
        require(
            isMinter[msg.sender],
            "LST::onlyMinter: caller is not the minter"
        );
        _;
    }

    /* --------- buyFees info --------- */
    Fees public sellFees;
    Fees public buyFees;

    /* --------- max tx info --------- */
	uint public _limitTxAmount = 500e9 * 1e9; // transaction limit: 500,000,000,000
	uint public numTokensSellToAddToLiquidity = 39e2 * 1e9; // swap token amount: 3900

	function getOwner() external view returns (address) {
		return owner();
	}

	function decimals() external view returns (uint8) {
		return _decimals;
	}

	function symbol() external view returns (string memory) {
		return _symbol;
	}

	function name() external view returns (string memory) {
		return _name;
	}

	function totalSupply() external view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) external returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) external view returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) external returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "LST::transferFrom: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "LST::decreaseAllowance: decreased allowance below zero"));
		return true;
	}

	function burn(uint256 amount) external {
		_burn(msg.sender,amount);
	}

	function _mint(address account, uint256 amount) internal {
		require(account != address(0), "LST::_mint: mint to the zero address");
		require(
            _maxSupply >= _totalSupply.add(amount),
            "LST::_mint: The total supply has exceeded the max supply."
        );
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "LST::_burn: burn from the zero address");

		_balances[account] = _balances[account].sub(amount, "LST::_burn: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, burnAddress, amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal {
		require(owner != address(0), "LST::_approve approve from the zero address");
		require(spender != address(0), "LST::_approve approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
 
	function _burnFrom(address account, uint256 amount) internal {
		_burn(account, amount);
		_approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "LST::_burnFrom: burn amount exceeds allowance"));
	}

    ////////////////////////////////////////////////
    /* --------- General Implementation --------- */
    ////////////////////////////////////////////////

    constructor (address _RouterAddress) public {
        _name = "LambSwapToken";
        _symbol = "LST";
        _decimals = 9;
        _totalSupply = 39e9*1e9; /// initial supply 39,000,000,000
        _balances[msg.sender] = _totalSupply;

        buyFees.burn = 10;
		buyFees.LP = 10;
        buyFees.marketing = 5;
		buyFees.buyback = 5;
        buyFees.totalFee = 20;

        sellFees.burn = 10;
		sellFees.LP = 20;
        sellFees.marketing = 10;
		sellFees.buyback = 10;
		sellFees.totalFee = 40;

        IPancakeSwapRouter _PancakeSwapRouter = IPancakeSwapRouter(_RouterAddress);
		PancakeSwapRouter = _PancakeSwapRouter;
		PancakeSwapV2Pair = IPancakeSwapFactory(_PancakeSwapRouter.factory()).createPair(address(this), _PancakeSwapRouter.WETH()); //MD vs USDT pair
        
        _isExcludeFromFee[owner()] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
        emit SetBuyFee(buyFees);
        emit SetSellFee(sellFees);
    }

	function mint(uint256 _amount) external onlyMinter returns (bool) {
        _mint(_msgSender(), _amount);
        return true;
    }

    function mint(address _to, uint256 _amount)
        external
        onlyMinter
        returns (bool)
    {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
        return true;
    }

    /* --------- set token parameters--------- */

	function setInitialAddresses(address _RouterAddress) external onlyOwner {
        IPancakeSwapRouter _PancakeSwapRouter = IPancakeSwapRouter(_RouterAddress);
		PancakeSwapRouter = _PancakeSwapRouter;
		PancakeSwapV2Pair = IPancakeSwapFactory(_PancakeSwapRouter.factory()).createPair(address(this), _PancakeSwapRouter.WETH()); //LST vs USDT pair
	}

	function setFeeAddresses( address _marketingAddress, address _LPAddress) external onlyOwner {
		marketingAddress = _marketingAddress;		
		LPAddress = _LPAddress;
	}

	function setLimitTxAmount(uint limitTxAmount) external onlyOwner {
		_limitTxAmount = limitTxAmount;
	}

	function setNumTokensSellToAddToLiquidity(uint _numTokensSellToAddToLiquidity) external onlyOwner {
		numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
	}
    
    function setbuyFee(uint256 _burnFee, uint256 _LPFee, uint256 _marketingFee, uint256 _buybackFee) external onlyOwner {
		buyFees.burn = _burnFee;
		buyFees.LP = _LPFee;
        buyFees.marketing = _marketingFee;
		buyFees.buyback = _buybackFee;
        buyFees.totalFee = _LPFee + _marketingFee + _buybackFee;
        emit SetBuyFee(buyFees);
    }

	function setsellFee(uint256 _burnFee, uint256 _LPFee, uint256 _marketingFee, uint256 _buybackFee) external onlyOwner {
		sellFees.burn = _burnFee;
		sellFees.LP = _LPFee;
        sellFees.marketing = _marketingFee;
		sellFees.buyback = _buybackFee;
        sellFees.totalFee = _LPFee + _marketingFee + _buybackFee;
        emit SetSellFee(sellFees);
    }

	function getTotalSellFee() public view returns (uint) {
		return sellFees.totalFee;
	}
	
	function getTotalBuyFee() public view returns (uint) {
		return buyFees.totalFee;
	}

    /* --------- exclude address from buyFees--------- */

	function setBlackList(address account, bool _isBlackList) external onlyOwner {
        require(
            isBlackList[account] != _isBlackList,
            "LST::setBlackList: Account is already the value of that"
        );
        isBlackList[account] = _isBlackList;

        emit SetBlackList(account, _isBlackList);
    }

    function excludeFromFee(address account) external onlyOwner {
        require(
            _isExcludeFromFee[account] != true,
            "LST::excludeFromFee: Account in list already."
        );
        _isExcludeFromFee[account] = true;

        emit SetWhiteList(account, true);
    }

    function includeInFee(address account) external onlyOwner {
        require(
            _isExcludeFromFee[account] == true,
            "LST::includeInFee: Account not in list."
        );
        _isExcludeFromFee[account] = false;

        emit SetWhiteList(account, false);
    }

	function setDeveloper(address account, bool _isDeveloper) external onlyOwner {
        require(
            isDeveloper[account] != _isDeveloper,
            "LST::setDeveloper: Account is already the value of that"
        );
        isDeveloper[account] = _isDeveloper;

        emit SetDeveloper(account, _isDeveloper);
    }

	function setMinter(address _minterAddress, bool _isMinter) external onlyOwner {
        require(
            isMinter[_minterAddress] != _isMinter,
            "LST::setMinter: Account is already the value of that"
        );
        isMinter[_minterAddress] = _isMinter;
    }

    /* --------- transfer --------- */

	function _transfer(address sender, address recipient, uint256 amount) internal {
		require(sender != address(0), "LST::_transfer: transfer from the zero address");
		require(recipient != address(0), "LST::_transfer: transfer to the zero address");
		require(!isBlackList[sender], "LST::_transfer: Sender is backlisted");
		require(!isBlackList[recipient], "LST::_transfer: Recipient is backlisted");

		// transfer 
		if((sender == PancakeSwapV2Pair || recipient == PancakeSwapV2Pair )&& !_isExcludeFromFee[sender])
			require(_limitTxAmount>=amount,"LST::_transfer: transfer amount exceeds max transfer amount");

		_balances[sender] = _balances[sender].sub(amount, "LST::_transfer: transfer amount exceeds balance");

		uint recieveAmount = amount;

		uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _limitTxAmount)
        {
            contractTokenBalance = _limitTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;

		if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != PancakeSwapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

		if(!_isExcludeFromFee[sender]) {
			if(sender == PancakeSwapV2Pair){
				// buy fee
				recieveAmount = recieveAmount.mul(1000-getTotalBuyFee()).div(1000);
                _burn(sender,amount.mul(buyFees.burn).div(1000));
				_balances[marketingAddress] += amount.mul(buyFees.marketing).div(1000);
				_balances[LPAddress] += amount.mul(buyFees.LP).div(1000);
				_balances[address(this)] += amount.mul(buyFees.buyback).div(1000);
				
				emit Transfer(sender, marketingAddress, amount.mul(buyFees.marketing).div(1000));
				emit Transfer(sender, LPAddress, amount.mul(buyFees.LP).div(1000));
				emit Transfer(sender, address(this), amount.mul(buyFees.buyback).div(1000));
			}
			else if(recipient == PancakeSwapV2Pair){
				// sell fee
				recieveAmount = recieveAmount.mul(1000-getTotalSellFee()).div(1000);	
                _burn(sender,amount.mul(sellFees.burn).div(1000));
				_balances[marketingAddress] += amount.mul(sellFees.marketing).div(1000);
				_balances[LPAddress] += amount.mul(sellFees.LP).div(1000);
				_balances[address(this)] += amount.mul(sellFees.buyback).div(1000);

				emit Transfer(sender, marketingAddress, amount.mul(sellFees.marketing).div(1000));
				emit Transfer(sender, LPAddress, amount.mul(sellFees.LP).div(1000));
				emit Transfer(sender, address(this), amount.mul(sellFees.buyback).div(1000));
			}
		}

		_balances[recipient] = _balances[recipient].add(recieveAmount);

		emit Transfer(sender, recipient, recieveAmount);
	}

	function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half); 

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

	function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeSwapRouter.WETH();

        _approve(address(this), address(PancakeSwapRouter), tokenAmount);

        PancakeSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(PancakeSwapRouter), tokenAmount);

        PancakeSwapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function removeLiquidity(uint256 LPAmount) external {
        _approve(address(this), address(PancakeSwapRouter), LPAmount);

        PancakeSwapRouter.removeLiquidityETH(
            address(this),
            LPAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

	receive() external payable {
	}

	function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "LST::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(_name)),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "LST::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "LST::delegateBySig: invalid nonce"
        );
        require(
            block.timestamp <= expiry,
            "LST::delegateBySig: signature expired"
        );
        return _delegate(signatory, delegatee);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

	function withdrawStuckBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}