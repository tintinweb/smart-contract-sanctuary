/**
 * 響
 * ひびき
 * /çibʲikʲi/
 * 
 * The sound of money in your pocket. The echoes of the cries of those who didn't buy. The reverberation of the rocket going to the moon.
 *
 * Multichain tools and blockchain games.
 * https://hibiki.finance https://t.me/hibikifinance 
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Auth.sol";
import "./IBEP20.sol";
import "./IDexRouter.sol";
import "./IDexFactory.sol";

contract Hibiki is IBEP20, Auth {

	address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

	string constant _name = "Hibiki.finance";
    string constant _symbol = "HIBIKI";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 10_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 100;
	uint256 public _maxWalletAmount = _totalSupply / 100;

	mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

	// Fees. Some may be completely inactive at all times.
	uint256 liquidityFee = 30;
    uint256 burnFee = 0;
	uint256 stakingFee = 20;
	uint256 nftStakingFee = 0;
    uint256 feeDenominator = 1000;
	bool public feeOnNonTrade = false;

	uint256 public stakingPrizePool = 0;
	bool public stakingRewardsActive = false;
	address public stakingRewardsContract;
	uint256 public nftStakingPrizePool = 0;
	bool public nftStakingRewardsActive = false;
	address public nftStakingRewardsContract;

	address public autoLiquidityReceiver;

	IDexRouter public router;
    address pcs2BNBPair;
    address[] public pairs;

	bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000;
    bool inSwap;
    modifier swapping() {
		inSwap = true;
		_;
		inSwap = false;
	}

	uint256 public launchedAt = 0;
	uint256 private antiSniperBlocks = 3;
	uint256 private antiSniperGasLimit = 30 gwei;
	bool private gasLimitActive = true;

	event AutoLiquifyEnabled(bool enabledOrNot);
	event AutoLiquify(uint256 amountBNB, uint256 autoBuybackAmount);
	event StakingRewards(bool activate);
	event NFTStakingRewards(bool active);

	constructor() Auth(msg.sender) {
		router = IDexRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
		//router = IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pcs2BNBPair = IDexFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

		isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
		isTxLimitExempt[msg.sender] = true;
		isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

		autoLiquidityReceiver = msg.sender;
		pairs.push(pcs2BNBPair);
		_balances[msg.sender] = _totalSupply;

		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	receive() external payable {}
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
			require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

	function _isStakingReward(address sender, address recipient) internal view returns (bool) {
		return sender == stakingRewardsContract
			|| sender == nftStakingRewardsContract
			|| recipient == stakingRewardsContract
			|| recipient == nftStakingRewardsContract;
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(amount > 0);
        if (inSwap || _isStakingReward(sender, recipient)) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkTxLimit(sender, recipient, amount);

        if (shouldSwapBack()) {
            liquify();
        }

        if (!launched() && recipient == pcs2BNBPair) {
            require(_balances[sender] > 0);
            require(sender == owner, "Only the owner can be the first to add liquidity.");
            launch();
        }

		require(amount <= _balances[sender], "Insufficient Balance");
        _balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] += amountReceived;

		// Update staking pool, if active.
		// Update of the pool can be deactivated for launch and staking contract migration.
		if (stakingRewardsActive) {
			sendToStakingPool();
		}
		if (nftStakingRewardsActive) {
			sendToNftStakingPool();
		}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

	function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(amount <= _balances[sender], "Insufficient Balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

	function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient] && sender == pcs2BNBPair, "TX Limit Exceeded");
		// Max wallet check.
		if (sender != owner
            && recipient != owner
            && !isTxLimitExempt[recipient]
            && recipient != ZERO 
            && recipient != DEAD 
            && recipient != pcs2BNBPair 
            && recipient != address(this)
        ) {
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount, "Exceeds max wallet.");
        }
    }

	// Decides whether this trade should take a fee.
	// Trades with pairs are always taxed, unless sender or receiver is exempted.
	// Non trades, like wallet to wallet, are configured, untaxed by default.
	function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) {
			return false;
		}

        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) {
				return true;
			}
        }

        return feeOnNonTrade;
    }

	function setAntisniperBlocks(uint256 blocks) external authorized {
		antiSniperBlocks = blocks;
	}

	function setAntisniperGas(bool active, uint256 quantity) external authorized {
		require(!active || quantity >= 1 gwei, "Needs to be at least 1 gwei.");
		gasLimitActive = active;
		antiSniperGasLimit = quantity;
	}

	function takeFee(address sender, uint256 amount) internal returns (uint256) {
		if (!launched()) {
			return amount;
		}
		uint256 liqFee = 0;
		uint256 bf = 0;
		uint256 steak = 0;
		uint256 nftStake = 0;
		if (block.number - launchedAt <= antiSniperBlocks || gasLimitActive && tx.gasprice >= antiSniperGasLimit) {
			liqFee = amount * feeDenominator - 1 / feeDenominator;
            _balances[address(this)] += liqFee;
			amount -= liqFee;
			emit Transfer(sender, address(this), liqFee);
        } else {
			// If there is a liquidity tax active for autoliq, the contract keeps it.
			if (liquidityFee > 0) {
				liqFee = amount * liquidityFee / feeDenominator;
				_balances[address(this)] += liqFee;
				emit Transfer(sender, address(this), liqFee);
			}
			// If there is an active burn fee, burn a percentage and give it to dead address.
			if (burnFee > 0) {
				bf = amount * burnFee / feeDenominator;
				_balances[DEAD] += bf;
				emit Transfer(sender, DEAD, bf);
			}
			// If staking tax is active, it is stored on ZERO address.
			// If staking payout itself is active, it is later moved from ZERO to the appropriate staking address.
			if (stakingFee > 0) {
				steak = amount * stakingFee / feeDenominator;
				_balances[ZERO] += steak;
				stakingPrizePool += steak;
				emit Transfer(sender, ZERO, steak);
			}
			if (nftStakingFee > 0) {
				nftStake = amount * nftStakingFee / feeDenominator;
				_balances[ZERO] += nftStake;
				nftStakingPrizePool += nftStake;
				emit Transfer(sender, ZERO, nftStake);
			}
		}

        return amount - liqFee - bf - steak - nftStake;
    }

	function sendToStakingPool() internal {
		_balances[ZERO] -= stakingPrizePool;
		_balances[stakingRewardsContract] += stakingPrizePool;
		emit Transfer(ZERO, stakingRewardsContract, stakingPrizePool);
		stakingPrizePool = 0;
	}

	function sendToNftStakingPool() internal {
		_balances[ZERO] -= nftStakingPrizePool;
		_balances[nftStakingRewardsContract] += nftStakingPrizePool;
		emit Transfer(ZERO, nftStakingRewardsContract, nftStakingPrizePool);
		nftStakingPrizePool = 0;
	}

	function setStakingRewardsAddress(address addy) external authorized {
		stakingRewardsContract = addy;
		isFeeExempt[addy] = true;
		isTxLimitExempt[addy] = true;
	}

	function setNftStakingRewardsAddress(address addy) external authorized {
		nftStakingRewardsContract = addy;
		isFeeExempt[addy] = true;
		isTxLimitExempt[addy] = true;
	}

    function shouldSwapBack() internal view returns (bool) {
        return launched()
			&& msg.sender != pcs2BNBPair
            && !inSwap
            && swapEnabled
            && _balances[address(this)] >= swapThreshold;
    }

	function setSwapEnabled(bool set) external authorized {
		swapEnabled = set;
		emit AutoLiquifyEnabled(set);
	}

	function liquify() internal swapping {
        uint256 amountToLiquify = swapThreshold / 2;
		uint256 balanceBefore = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToLiquify,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance - balanceBefore;
        uint256 amountBNBLiquidity = amountBNB / 2;

		router.addLiquidityETH{value: amountBNBLiquidity}(
			address(this),
			amountToLiquify,
			0,
			0,
			autoLiquidityReceiver,
			block.timestamp
		);
		emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
    }

	function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

	function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

	function setMaxWallet(uint256 amount) external authorized {
		require(amount >= _totalSupply / 1000);
		_maxWalletAmount = amount;
	}

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _burnFee, uint256 _stakingFee, uint256 _nftStakingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        burnFee = _burnFee;
		stakingFee = _stakingFee;
		nftStakingFee = _nftStakingFee;
        feeDenominator = _feeDenominator;
		uint256 totalFee = _liquidityFee + _burnFee + _stakingFee + _nftStakingFee;
        require(totalFee < feeDenominator / 5, "Maximum allowed taxation on this contract is 20%.");
    }

    function setLiquidityReceiver(address _autoLiquidityReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
    }

	function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO) + stakingPrizePool + nftStakingPrizePool;
    }

	// Recover any BNB sent to the contract by mistake.
	function rescue() external {
        payable(owner).transfer(address(this).balance);
    }

	function setStakingRewardsActive(bool active) external authorized {
		stakingRewardsActive = active;
		emit StakingRewards(active);
	}

	function setNftStakingRewardsActive(bool active) external authorized {
		nftStakingRewardsActive = active;
		emit NFTStakingRewards(active);
	}

	function addPair(address pair) external authorized {
        pairs.push(pair);
    }
    
    function removeLastPair() external authorized {
        pairs.pop();
    }
}