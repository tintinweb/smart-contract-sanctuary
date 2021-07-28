// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./IBEP20Metadata.sol";
import "./ISwapRouter.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./AutoStakingPool.sol";

// modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

contract Auto is Context, IBEP20, IBEP20Metadata, Ownable, ReentrancyGuard {
	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;

	address public stakingAddress;
	mapping(address => bool) private noStakeOnTransferFrom;
	mapping(address => bool) private noStakeOnTransferTo;
	ISwapRouter public swapRouter;

	mapping(address => bool) private feeWhitelist;
	uint8 public feePercent = 6;
	address public feeWallet;

	constructor(address _feeWallet, address _swapRouter) {
		_balances[_msgSender()] = 1200000e18;
		feeWallet = _feeWallet;
		swapRouter = ISwapRouter(_swapRouter);
		// no fees and no staking when sending to swap contract
		feeWhitelist[_swapRouter] = true;
		noStakeOnTransferTo[_swapRouter] = true;
	}

	function setStakingPool(address _stakingAddress) public onlyOwner {
		stakingAddress = _stakingAddress;
		feeWhitelist[_stakingAddress] = true;
		noStakeOnTransferFrom[_stakingAddress] = true;
		noStakeOnTransferTo[_stakingAddress] = true;
	}

	function name() public pure override returns (string memory) {
		return "AutoBSC";
	}

	function symbol() public pure override returns (string memory) {
		return "AUTO";
	}

	function decimals() public pure override returns (uint8) {
		return 18;
	}

	function totalSupply() public view virtual override returns (uint256) {
		return 1200000e18;
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	function transfer(address to, uint256 amount) public override returns (bool success) {
		_transfer(_msgSender(), to, amount);
		return true;
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public virtual override nonReentrant returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = _allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
		unchecked {
			_approve(sender, _msgSender(), currentAllowance - amount);
		}

		return true;
	}

	function setFeePercent(uint8 _feePercent) public onlyOwner {
		require(_feePercent < 100, "Percent must be less than 100.");
		feePercent = _feePercent;
	}

	function allowTransfersWithoutFees(address account, bool status) public onlyOwner {
		feeWhitelist[account] = status;
	}

	function allowTransferFromWithoutStake(address account, bool status) public onlyOwner {
		noStakeOnTransferFrom[account] = status;
	}

	function allowTransferToWithoutStake(address account, bool status) public onlyOwner {
		noStakeOnTransferTo[account] = status;
	}

	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
		if (!feeWhitelist[sender] && !feeWhitelist[recipient]) {
			uint256 totalFee = amount * feePercent / 100;
			uint256 liquidityFee = totalFee / 3;
			_transferForFree(sender, address(this), totalFee);
			_addLiquidity(feeWallet, liquidityFee);
			_swapTokensForETH(feeWallet, totalFee - liquidityFee);
			amount -= totalFee;
		}
		_transferForFree(sender, recipient, amount);

		if (noStakeOnTransferFrom[sender] || noStakeOnTransferTo[recipient])
			return;

		_approve(recipient, stakingAddress, _allowances[recipient][stakingAddress] + amount);
		AutoStakingPool stakingContract = AutoStakingPool(stakingAddress);
		stakingContract.stake(recipient, amount);
	}

	function _transferForFree(address sender, address recipient, uint256 amount) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
			_balances[sender] = senderBalance - amount;
		}
		_balances[recipient] += amount;

		emit Transfer(sender, recipient, amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

	function _swapTokensForETH(address to, uint256 amount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = swapRouter.WETH();

		_approve(address(this), address(swapRouter), amount);

		swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount, // amount in
			0, // amount out min
			path,
			to,
			block.timestamp // deadline
		);
	}

	function _addLiquidity(address to, uint256 amount) private {
		_approve(address(this), address(swapRouter), amount);

		swapRouter.addLiquidityETH(
			address(this),
			amount,
			0,
			0,
			to,
			block.timestamp
		);
	}
}