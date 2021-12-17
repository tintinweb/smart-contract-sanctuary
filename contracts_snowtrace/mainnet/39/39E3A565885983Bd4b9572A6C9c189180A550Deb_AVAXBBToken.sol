/**
 *Submitted for verification at snowtrace.io on 2021-12-17
*/

/**

 ________  ________  ________  ___       __   ________   _______   ________          ________  ________  ___  ________   ________  _______      
|\   ____\|\   __  \|\   __  \|\  \     |\  \|\   ___  \|\  ___ \ |\   ___ \        |\   __  \|\   __  \|\  \|\   ___  \|\   ____\|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \    \ \  \ \  \\ \  \ \   __/|\ \  \_|\ \       \ \  \|\  \ \  \|\  \ \  \ \  \\ \  \ \  \___|\ \   __/|    
 \ \  \    \ \   _  _\ \  \\\  \ \  \  __\ \  \ \  \\ \  \ \  \_|/_\ \  \ \\ \       \ \   ____\ \   _  _\ \  \ \  \\ \  \ \  \    \ \  \_|/__  
  \ \  \____\ \  \\  \\ \  \\\  \ \  \|\__\_\  \ \  \\ \  \ \  \_|\ \ \  \_\\ \       \ \  \___|\ \  \\  \\ \  \ \  \\ \  \ \  \____\ \  \_|\ \ 
   \ \_______\ \__\\ _\\ \_______\ \____________\ \__\\ \__\ \_______\ \_______\       \ \__\    \ \__\\ _\\ \__\ \__\\ \__\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|____________|\|__| \|__|\|_______|\|_______|        \|__|     \|__|\|__|\|__|\|__| \|__|\|_______|\|_______|

*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

interface IERC20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISniper {
	function setToken(address token) external returns (bool);
	function setLaunch(uint16 taxes, address pair) external;
	function checkTransfer(address sender, address recipient) external returns (bool);
	function calculateTaxes(address sender, address recipient, uint256 amount) external view returns (uint256);
	function updateTaxesAmount(uint16 amount) external;
	function isBlacklisted(address account) external view returns (bool);
	function setBlacklisted(address[] memory accounts, bool status) external;
	function isBurned(address account) external view returns (bool);
	function setBurned(address[] memory accounts, bool status) external;
}

interface IJoeFactory {
	function getPair(address tokenA, address tokenB) external view returns (address pair);
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IJoeRouter {
	function factory() external pure returns (address);
	function WAVAX() external pure returns (address);
	function addLiquidityAVAX(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountAVAXMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountAVAX, uint256 liquidity);
	function swapExactAVAXForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external payable returns (uint256[] memory amounts);
	function swapExactTokensForAVAXSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external;
}

contract AVAXBBToken is IERC20 {
	address private _owner;
	address private _operator;

	string private _name;
	string private _symbol;
	uint8 private _decimals = 9;
	uint256 private _totalSupply = 1 * 10 ** 6 * 10 ** _decimals;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _excludes;

	bool public tradingEnabled;
	uint256 public maxTxAmount;
	uint256 public maxWalletAmount;
	uint16 public taxesAmount;

	ISniper private antiSnipe;
	IJoeRouter public dexRouter;
	address public lpPair;

	bool inSwap;
	modifier lockTheSwap {
		inSwap = true;
		_;
		inSwap = false;
	}

	modifier onlyOwner() {
		require(_owner == msg.sender, "Caller =/= Owner");
		_;
	}

	modifier onlyOperator() {
		require(_operator == msg.sender, "Caller =/= Operator");
		_;
	}

	constructor(string memory _a, string memory _b, address[] memory _c, uint256 _d, uint256 _e, uint16 _f, address _g) {
		_owner = msg.sender; _operator = msg.sender; _excludes[_owner] = true; _excludes[_operator] = true;
		_name = _a; _symbol = _b; maxTxAmount = _d; maxWalletAmount = _e; taxesAmount = _f;
		for (uint256 i = 0; i < _c.length; i++) { _excludes[_c[i]] = true; }
		antiSnipe = ISniper(_g); require(antiSnipe.setToken(address(this)), "ERROR");

		address routerAddr = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; // Trader Joe Mainnet
		dexRouter = IJoeRouter(routerAddr); lpPair = IJoeFactory(dexRouter.factory()).createPair(address(this), dexRouter.WAVAX());

		_balances[address(this)] = _totalSupply;
		emit Transfer(address(0), address(this), _totalSupply);
		_allowances[address(this)][routerAddr] = type(uint256).max;
	}

	receive() external payable {}

	function recoverEth() external onlyOwner {
		payable(_owner).transfer(address(this).balance);
	}

	function recoverToken(IERC20 token) external onlyOwner {
		token.transfer(_owner, token.balanceOf(address(this)));
	}

	function name() external view returns (string memory) { return _name; }
	function symbol() external view returns (string memory) { return _symbol; }
	function decimals() external view returns (uint8) { return _decimals; }
	function totalSupply() external view returns (uint256) { return _totalSupply; }
	function balanceOf(address account) external view returns (uint256) { return _balances[account]; }
	function allowance(address owner, address spender) external view returns (uint256) { return _allowances[owner][spender]; }

	function approve(address spender, uint256 amount) external returns (bool) {
		require(spender != address(0));

		_allowances[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function transfer(address recipient, uint256 amount) external returns (bool) {
		return tokenTransfer(msg.sender, recipient, amount);
	}

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
		require(_allowances[sender][msg.sender] >= amount, "Amount > Allowance");
		return tokenTransfer(sender, recipient, amount);
	}

	function tokenTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender != address(0), "Sender == 0x0");
		require(recipient != address(0), "Recipient == 0x0");

		bool isExcludedTransfer = _excludes[sender] || _excludes[recipient];
		bool isContractTransfer = sender == address(this) || recipient == address(this);
		bool isLiquidityTransfer = (sender == lpPair && recipient == address(dexRouter)) || (sender == address(dexRouter) && recipient == lpPair);

		if (isExcludedTransfer || isContractTransfer || isLiquidityTransfer) {
			return feelessTransfer(sender, recipient, amount);
		} else if (tradingEnabled && (sender == lpPair || recipient == lpPair)) {
			require(antiSnipe.checkTransfer(sender, recipient), "Rejected/Blacklisted");
			require (amount <= _totalSupply * maxTxAmount / 10000, "Max Transfer Reject");

			if (recipient != lpPair) {
				require(_balances[recipient] + amount <= _totalSupply * maxWalletAmount / 10000, "Max Wallet Reject");
			}

			if (_balances[address(this)] >= amount && sender != lpPair && !inSwap) {
				contractSwap(amount);
			}

			uint256 contractShares = antiSnipe.calculateTaxes(sender, recipient, amount);
			uint256 taxedAmount = amount - contractShares;

			_balances[sender] = _balances[sender] - amount;
			_balances[address(this)] = _balances[address(this)] + contractShares;
			emit Transfer(sender, address(this), contractShares);
			if (taxedAmount > 0) {
				_balances[recipient] = _balances[recipient] + taxedAmount;
				emit Transfer(sender, recipient, taxedAmount);
			}

			return true;
		} else {
			revert("Transfer =/= Allow");
		}
	}

	function feelessTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(_balances[sender] >= amount, "Amount > Balance");

		_balances[sender] = _balances[sender] - amount;
		_balances[recipient] = _balances[recipient] + amount;
		emit Transfer(sender, recipient, amount);
		return true;
	}

	function contractSwap(uint256 amount) internal lockTheSwap {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = dexRouter.WAVAX();

		dexRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
			amount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

	function enableTrading() external onlyOwner {
		require(!tradingEnabled, "tradingEnabled =/= False");

		uint256 liquidityAmount = _balances[address(this)] * 9 / 10;
		dexRouter.addLiquidityAVAX{value: address(this).balance}(
			address(this),
			liquidityAmount,
			0,
			0,
			_owner,
			block.timestamp
		);

		try antiSnipe.setLaunch(taxesAmount, lpPair) {} catch {}
		tradingEnabled = true;
	}

	function buyAndBurn(uint256 amount) external onlyOperator {
		require(address(this).balance >= amount, "Amount > Balance");

		address[] memory path = new address[](2);
		path[0] = dexRouter.WAVAX();
		path[1] = address(this);

		dexRouter.swapExactAVAXForTokens{value: amount}(
			0,
			path,
			0x000000000000000000000000000000000000dEaD,
			block.timestamp
		);
	}

	function buyAndStore(uint256 amount) external onlyOperator {
		require(address(this).balance >= amount, "Amount > Balance");

		address[] memory path = new address[](2);
		path[0] = dexRouter.WAVAX();
		path[1] = address(this);

		dexRouter.swapExactAVAXForTokens{value: amount}(
			0,
			path,
			address(antiSnipe),
			block.timestamp
		);
	}

	function isExcludeed(address account) external view returns (bool) {
		return _excludes[account];
	}

	function setExcludes(address[] memory accounts, bool status) external onlyOwner {
		for (uint256 i = 0; i < accounts.length; i++) {
			_excludes[accounts[i]] = status;
		}
	}

	function doubleUpMaxes() external onlyOwner {
		maxTxAmount = maxTxAmount * 2;
		maxWalletAmount = maxWalletAmount * 2;
	}

	function updateTaxes(uint16 taxes) external onlyOwner {
		require(taxes <= 10000, "Overflow");
		taxesAmount = taxes; antiSnipe.updateTaxesAmount(taxes);
	}

	function isBlacklisted(address account) external view returns (bool) {
		return antiSnipe.isBlacklisted(account);
	}

	function setBlacklisted(address[] memory accounts, bool status) external onlyOwner {
		antiSnipe.setBlacklisted(accounts, status);
	}

	function isBurned(address account) external view returns (bool) {
		return antiSnipe.isBurned(account);
	}

	function setBurned(address[] memory accounts, bool status) external onlyOwner {
		antiSnipe.setBurned(accounts, status);
	}

	function getOwner() external view returns (address) {
		return _owner;
	}

	function getOperator() external view returns (address) {
		return _operator;
	}

	function transferOperatorship(address account) external onlyOwner {
		require(account != address(0) && account != 0x000000000000000000000000000000000000dEaD, "Account == 0/dEaD");
		_operator = account;
	}
}