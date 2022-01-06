/**
 *Submitted for verification at FtmScan.com on 2022-01-06
*/

// SPDX-License-Identifier: None

/**

██████   █████  ██████  ██   ██     ███████  ██████  ██    ██ ██      ███████
██   ██ ██   ██ ██   ██ ██  ██      ██      ██    ██ ██    ██ ██      ██
██   ██ ███████ ██████  █████       ███████ ██    ██ ██    ██ ██      ███████
██   ██ ██   ██ ██   ██ ██  ██           ██ ██    ██ ██    ██ ██           ██
██████  ██   ██ ██   ██ ██   ██     ███████  ██████   ██████  ███████ ███████

*/

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

interface IDarkSniper {
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

interface IFactory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract DarkSouls is IERC20 {
	address private _owner;

	string private _name = "DarkSouls";
	string private _symbol = "DS";
	uint8 private _decimals = 9;
	uint256 private _totalSupply = 666 * 6 ** 6 * 10 ** _decimals;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;

	bool public tradingEnabled;
	uint16 public maxTxAmount = 100;
	uint16 public maxWalletAmount = 200;

	struct feesStruct { uint16 marketing; uint16 liquidity; uint16 development; }
	feesStruct public salesTaxes = feesStruct({
		marketing: 600,
		liquidity: 400,
		development: 200
	});

	address private marketWallet;
	address private developWallet;
	IDarkSniper private antiSnipe;
	IRouter public dexRouter;
	address public lpPair;

	bool public swapEnabled;
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

	constructor(address _marketing, address _development, address _initializer) {
		_owner = msg.sender; marketWallet = _marketing; developWallet = _development;
		antiSnipe = IDarkSniper(_initializer); require(antiSnipe.setToken(address(this)), "ERROR"); swapEnabled = true;

		address routerAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
		dexRouter = IRouter(routerAddress); lpPair = IFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());

		_balances[address(this)] = _totalSupply;
		emit Transfer(address(0), address(this), _totalSupply);
		_allowances[address(this)][routerAddress] = type(uint256).max;
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
		return _transfer(msg.sender, recipient, amount);
	}

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
		require(_allowances[sender][msg.sender] >= amount, "Amount > Allowance");
		return _transfer(sender, recipient, amount);
	}

	function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(sender != address(0) && recipient != address(0), "Sender/Recipient == 0x0");
		require(_balances[sender] >= amount, "Amount > Balance");

		bool ownerTransfer = sender == _owner || recipient == _owner;
		bool contractTransfer = sender == address(this) || recipient == address(this);
		bool liquidityTransfer = (sender == lpPair && recipient == address(dexRouter)) || (sender == address(dexRouter) && recipient == lpPair);

		if (ownerTransfer || contractTransfer || liquidityTransfer) {
			_balances[sender] = _balances[sender] - amount;
			_balances[recipient] = _balances[recipient] + amount;
			emit Transfer(sender, recipient, amount);
			return true;
		} else if (tradingEnabled) {
			require(antiSnipe.checkTransfer(sender, recipient), "Rejected/Blacklisted");
			require(amount <= _totalSupply * maxTxAmount / 10000, "Max Transfer Reject");

			if (recipient != lpPair) {
				require(_balances[recipient] + amount <= _totalSupply * maxWalletAmount / 10000, "Max Wallet Reject");
			}

			if (_balances[address(this)] >= amount && sender != lpPair && !inSwap && swapEnabled) {
				uint256 marketingShare = amount * salesTaxes.marketing / getTotalTaxes();
				contractSwap(marketingShare, marketWallet);

				uint256 liquidityShare = amount * salesTaxes.liquidity / getTotalTaxes();
				uint256 firstHalf = liquidityShare / 2;
				uint256 secondHalf = liquidityShare - firstHalf;
				uint256 beforeBalance = address(this).balance;
				contractSwap(firstHalf, address(this));
				uint256 addedBalance = address(this).balance - beforeBalance;
				addLiquidity(secondHalf, addedBalance);

				uint256 developmentShare = amount * salesTaxes.development / getTotalTaxes();
				contractSwap(developmentShare, developWallet);
			}

			uint256 contractShare = antiSnipe.calculateTaxes(sender, recipient, amount);
			uint256 taxedAmount = amount - contractShare;
			_balances[sender] = _balances[sender] - amount;
			_balances[address(this)] = _balances[address(this)] + contractShare;
			emit Transfer(sender, address(this), contractShare);
			_balances[recipient] = _balances[recipient] + taxedAmount;
			emit Transfer(sender, recipient, taxedAmount);

			return true;
		} else {
			revert();
		}
	}

	function contractSwap(uint256 amount, address to) internal lockTheSwap {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = dexRouter.WETH();

		dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			0,
			path,
			to,
			block.timestamp
		);
	}

	function addLiquidity(uint256 token, uint256 eth) internal {
		dexRouter.addLiquidityETH{value: eth}(
			address(this),
			token,
			0,
			0,
			_owner,
			block.timestamp
		);
	}

	function enableTrading() external onlyOwner {
		require(!tradingEnabled, "tradingEnabled =/= False");

		addLiquidity(_balances[address(this)] * 9 / 10, address(this).balance);
		try antiSnipe.setLaunch(getTotalTaxes(), lpPair) {} catch {}
		tradingEnabled = true;
	}

	function getTotalTaxes() public view returns (uint16) {
		return salesTaxes.marketing + salesTaxes.liquidity + salesTaxes.development;
	}

	function setMaxesSetting(uint16 _tx, uint16 _wallet) external onlyOwner {
		require(_tx <= 10000 && _wallet <= 10000, "Overflow");

		maxTxAmount = _tx;
		maxWalletAmount = _wallet;
	}

	function setSalesTaxes(uint16 _marketing, uint16 _liquidity, uint16 _development) external onlyOwner {
		uint16 totalTaxes = _marketing + _liquidity + _development;
		require(totalTaxes <= 10000, "Overflow");

		salesTaxes.marketing = _marketing;
		salesTaxes.liquidity = _liquidity;
		salesTaxes.development = _development;
		antiSnipe.updateTaxesAmount(totalTaxes);
	}

	function setContractSwap(bool _status) external onlyOwner {
		swapEnabled = _status;
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
}