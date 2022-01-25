// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8;

import './FuturizeUV3Pair.sol';
import './interfaces/FuturizeInterfaces.sol';
import './BaseInterestRate.sol';
import 'hardhat/console.sol';

contract FuturizeFactory {
	IExternalRouter router;

	mapping(address => mapping(address => address)) public getPair;
	address[] public allPairs;

	event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

	BaseInterestRate public interestRate;

	address public futurizePairImpl;

	constructor(
		address _futurizePairImpl,
		IExternalRouter _router,
		BaseInterestRate _interestRate
	) {
		router = _router;
		interestRate = _interestRate;
		futurizePairImpl = _futurizePairImpl;
	}

	function allPairsLength() external view returns (uint256) {
		return allPairs.length;
	}

	function createPair(address tokenA, address tokenB) external returns (address pair) {
		require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
		(address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
		require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
		bytes32 salt = keccak256(abi.encodePacked(token0, token1));
		pair = cloneDeterministic(futurizePairImpl, salt);
		IFuturizePair(pair).initialize(token0, token1, router, interestRate);
		getPair[token0][token1] = pair;
		getPair[token1][token0] = pair; // populate mapping in the reverse direction
		allPairs.push(pair);
		emit PairCreated(token0, token1, pair, allPairs.length);
	}

	/**
	 * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
	 *
	 * This function uses the create2 opcode and a `salt` to deterministically deploy
	 * the clone. Using the same `implementation` and `salt` multiple time will revert, since
	 * the clones cannot be deployed twice at the same address.
	 */
	function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
		assembly {
			let ptr := mload(0x40)
			mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
			mstore(add(ptr, 0x14), shl(0x60, implementation))
			mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
			instance := create2(0, ptr, 0x37, salt)
		}
		require(instance != address(0), 'ERC1167: create2 failed');
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8;
pragma experimental ABIEncoderV2;
import './BasePool.sol';
import './UniswapV3SwapHelper.sol';
import './interfaces/FuturizeInterfaces.sol';
import './BaseInterestRate.sol';

// import 'hardhat/console.sol';

//TODO: position should be in erc721
contract FuturizeUV3Pair is BasePool {
	uint32 public constant TWAP_INTERVAL = 300;

	struct Position {
		uint112 blockOpen;
		uint112 borrowed; //how much borrowed from other token in same value of collateral
		uint112 debtShares;
		uint112 collateral;
		uint112 vault; //collateral + swapped for borrowed
		uint112 leveraged;
		address owner;
		bool isOpen;
		bool isToken0; //is the collateral token
	}

	mapping(uint256 => Position) public positions;

	uint256 public nextPositionId;

	uint256 public lastDebtUpdate;

	BaseInterestRate public interestRate;

	ISwapRouter public uniswapRouter;
	IUniswapV3Pool public uniswapPool;

	event PositionUpdated(
		bool isNew,
		uint256 indexed positionId,
		address indexed owner,
		address indexed collateralToken,
		uint256 collateral,
		uint256 amountBorrowed, //in other token
		uint256 swapResult, //borrowed swapped to collateral token
		uint32 leverage
	);

	event PositionClosed(
		uint256 indexed positionId,
		address indexed owner,
		address indexed collateralToken,
		uint256 debt, //in other token
		uint256 amountRepayed, //out of debt - actuall repayed in other token (can be less than borrowed in case of default)
		uint256 interestPayed, //out of amountRepayed
		uint256 amountEarned //in collateral token
	);

	event PositionsClosed(uint256[] ids, address liquidator, uint256 debt0Repayed, uint256 debt1Repayed);

	// called once by the factory at time of deployment
	function initialize(
		address _token0,
		address _token1,
		IExternalRouter _router,
		BaseInterestRate _model
	) external {
		require(address(0) == factory, 'Futurize: FORBIDDEN'); // sufficient check
		unlocked = 1;
		factory = msg.sender;
		token0 = _token0;
		token1 = _token1;
		interestRate = _model;
		uniswapRouter = ISwapRouter(_router);
		uniswapPool = UniswapV3SwapHelper.initializeSwapHelper(_token0, _token1, _router);
		// console.log('uv3 pool: %s', address(uniswapPool));
	}

	function open(
		uint256 collateral0,
		uint256 collateral1,
		address to,
		uint256 minReceived
	) external {
		return open(collateral0, collateral1, to, minReceived, 1);
	}

	function increase(
		uint256 positionId,
		uint256 collateral,
		uint256 minReceived,
		uint32 leverage
	) public {
		require(positions[positionId].owner == msg.sender, 'not owner');
		require(positions[positionId].isOpen, 'not open');
		require(leverage <= 1000, 'invalid leverage');

		return _updatePos(positionId, collateral, minReceived, leverage, false);
	}

	function _updatePos(
		uint256 positionId,
		uint256 collateral,
		uint256 minReceived,
		uint32 leverage,
		bool isNew
	) internal {
		// console.log('open %s %s', positionId, collateral);
		Position storage pos = positions[positionId];
		verifyOraclePriceInRange();
		bool isToken0 = pos.isToken0;
		{
			//here we verify that tokens where transfered, this is safe for fee on transfer tokens
			(uint256 totalLocked0, uint256 totalLocked1, , , ) = getReserves();
			if (isToken0)
				require(
					collateral <= IERC20(token0).balanceOf(address(this)) - totalLocked0,
					'Futurize: no collateral'
				);
			else
				require(
					collateral <= IERC20(token1).balanceOf(address(this)) - totalLocked1,
					'Futurize: no collateral'
				);
		}
		//TODO: maybe add it in more places? like mint? etc...
		updateDebt();

		//now we just virtually transfer tokens between pools

		//calculate how much collateral is worth in borrowed token without fee in spot price
		uint256 borrow = getValue(collateral * leverage, isToken0);

		//lending pool - remove borrowed amount
		//this should revert with underflow in case we dont have enough to lend
		//TODO: add unit test to verify that
		if (isToken0) {
			reserve1 -= uint112(borrow);
		} else {
			reserve0 -= uint112(borrow);
		}

		//calculate exposure of the short position
		// console.log(
		// 	'token in %s, token out %s, swap amount %s',
		// 	isToken0 ? token1 : token0,
		// 	isToken0 ? token0 : token1,
		// 	borrow
		// );

		uint256 swapResult;
		if (leverage > 0) {
			swapResult = UniswapV3SwapHelper.swapExactIn(
				uniswapRouter,
				uniswapPool.fee(),
				isToken0 ? token1 : token0,
				isToken0 ? token0 : token1,
				borrow,
				minReceived,
				address(this)
			);
			require(borrow <= type(uint112).max && swapResult <= type(uint112).max, 'Futurize: OVERFLOW');
			require(swapResult > 0, 'Futurize: swap failed');
		}
		// console.log(
		// 	'collateral worth in borrowed token: %s. swap result of borrowed token to collateral token %2',
		// 	borrow,
		// 	swapResult
		// );
		uint112 inVault = uint112(collateral + swapResult);
		//lock collateral + exposure in vault. exposure (swap) value is received when swapping the borrowed token to the collateral token
		if (isToken0) {
			reserve0Vault += inVault;
			reserve0Collateral += uint112(collateral);
		} else {
			reserve1Vault += inVault;
			reserve1Collateral += uint112(collateral);
		}

		if (leverage > 0) {
			pos.debtShares += _mintInterestDebt(pos.owner, isToken0, borrow);
			pos.borrowed += uint112(borrow);
			pos.leveraged += uint112(collateral * leverage);
		}

		pos.collateral += uint112(collateral);
		pos.vault += inVault;
		// console.log(
		// 	'vault value: collateral %s swap %s borrowed: %s',
		// 	_collateral0 + _collateral1,
		// 	swap0 + swap1,
		// 	borrow0 + borrow1
		// );

		emit PositionUpdated(
			isNew,
			positionId,
			pos.owner,
			isToken0 ? token0 : token1,
			pos.collateral,
			pos.borrowed,
			swapResult,
			leverage
		);
	}

	function open(
		uint256 _collateral0,
		uint256 _collateral1,
		address to,
		uint256 minReceived,
		uint32 leverage
	) public {
		require(_collateral0 == 0 || _collateral1 == 0, 'Futurize: one token per position');
		require(leverage <= 1000 && leverage != 0, 'invalid leverage');
		bool isToken0 = _collateral0 > _collateral1;
		uint256 collateral = isToken0 ? _collateral0 : _collateral1;
		Position storage pos = positions[nextPositionId];
		pos.isToken0 = isToken0;
		pos.blockOpen = uint112(block.number);
		pos.owner = to;
		pos.isOpen = true;

		_updatePos(nextPositionId, collateral, minReceived, leverage, true);

		nextPositionId += 1;
	}

	function close(
		uint256 positionId,
		address to,
		uint256 maxIn
	) external {
		verifyOraclePriceInRange();

		Position memory pos = positions[positionId];
		require(pos.isOpen && msg.sender == pos.owner, 'Futurize: position already closed or not owner');
		updateDebt();

		bool isToken0 = pos.isToken0;

		(uint112 token0DebtValue, uint112 token1DebtValue, , ) = _closeData(pos);

		_repayInterestDebt(pos.owner, isToken0, pos.debtShares);

		//try to repay exact debt with max whatever is locked in the position vault
		uint256 amountIn = UniswapV3SwapHelper.swapExactOut(
			uniswapRouter,
			uniswapPool.fee(),
			isToken0 ? token0 : token1,
			isToken0 ? token1 : token0,
			max(token0DebtValue, token1DebtValue),
			pos.vault,
			address(this)
		);

		//amountIn==0 is the case where swap failed cause position is not enough to cover debt.
		//protect against slippage
		require(amountIn == 0 || amountIn <= maxIn, 'Futurize: close slippage');
		uint256 toUser = 0;

		//assume user repayed his whole debt
		uint256 borrowedRepayed = max(token0DebtValue, token1DebtValue);
		//swap failed probably defaulted, we then swap everything we have in vault
		if (amountIn == 0) {
			//TODO: no slippage protection in case of default
			borrowedRepayed = UniswapV3SwapHelper.swapExactIn(
				uniswapRouter,
				uniswapPool.fee(),
				isToken0 ? token0 : token1,
				isToken0 ? token1 : token0,
				pos.vault,
				0,
				address(this)
			);
		} else {
			toUser = pos.vault - amountIn;
		}
		uint256 fees = borrowedRepayed > pos.borrowed ? borrowedRepayed - pos.borrowed : 0;

		//lending pool - return actuall repayed amount
		reserve0 += isToken0 ? 0 : uint112(borrowedRepayed); //fees accrue in regular pool
		reserve1 += isToken0 ? uint112(borrowedRepayed) : 0;

		//update total debt  - we deduct everything (ie in case of default) not just what was repayed
		reserve0Debt -= token0DebtValue;
		reserve1Debt -= token1DebtValue;

		//unlock collateral + exposure in vault. (we exchanged it to debtToken and sent the rest to user)
		reserve0Vault -= isToken0 ? pos.vault : 0;
		reserve1Vault -= isToken0 ? 0 : pos.vault;

		//TODO: unit test reserveCollateral everywhere
		reserve0Collateral -= isToken0 ? pos.collateral : 0;
		reserve1Collateral -= isToken0 ? 0 : pos.collateral;

		//6. send to user.
		if (toUser > 0) _safeTransfer(isToken0 ? token0 : token1, to, toUser);

		//7. in case of default? debt is lost.

		delete positions[positionId];

		emit PositionClosed(
			positionId,
			msg.sender,
			isToken0 ? token0 : token1,
			isToken0 ? token1DebtValue : token0DebtValue,
			borrowedRepayed,
			fees,
			toUser
		);
	}

	function liquidate(
		uint256[] calldata ids,
		uint256 minReceived0,
		uint256 minReceived1
	) public {
		verifyOraclePriceInRange();
		updateDebt();
		uint256 reserve0Repayed;
		uint256 reserve1Repayed;
		uint112 reserve0VaultReduced;
		uint112 reserve1VaultReduced;
		uint112 reserve0CollateralReduced;
		uint112 reserve1CollateralReduced;

		for (uint256 i = 0; i < ids.length; i++) {
			Position memory pos = positions[ids[i]];
			if (!pos.isOpen) continue;
			{
				(uint256 token0DebtValue, uint256 token1DebtValue, bool hasDefaulted, ) = _closeData(pos);
				//TODO: hasdefaulted checks default by current price, not by amount received by cashing out collateral
				if (hasDefaulted == false) continue;

				_repayInterestDebt(pos.owner, pos.isToken0, pos.debtShares);

				if (pos.isToken0) {
					//unlock collateral + exposure in vault. (we exchanged it to debtToken and sent the rest to user)
					reserve0VaultReduced += pos.vault;
					reserve0CollateralReduced += pos.collateral;
				} else {
					reserve1VaultReduced += pos.vault;
					reserve1CollateralReduced += pos.collateral;
				}

				//update total debt  - we deduct everything (ie in case of default) not just what was repayed
				//we can update globals here as it has no effect on swap results
				reserve0Debt -= uint112(token0DebtValue);
				reserve1Debt -= uint112(token1DebtValue);
			}
			delete positions[ids[i]];
		}

		if (reserve1VaultReduced > 0) {
			reserve1Vault -= reserve1VaultReduced;
			reserve1Collateral -= reserve1CollateralReduced;
			reserve0Repayed = UniswapV3SwapHelper.swapExactIn(
				uniswapRouter,
				uniswapPool.fee(),
				token1,
				token0,
				reserve1VaultReduced,
				minReceived0,
				address(this)
			);
			reserve0 += uint112(reserve0Repayed);
		}
		if (reserve0VaultReduced > 0) {
			reserve0Vault -= reserve0VaultReduced;
			reserve0Collateral -= reserve0CollateralReduced;
			reserve1Repayed = UniswapV3SwapHelper.swapExactIn(
				uniswapRouter,
				uniswapPool.fee(),
				token0,
				token1,
				reserve0VaultReduced,
				minReceived1,
				address(this)
			);
			reserve1 += uint112(reserve1Repayed);
		}

		//78. in case of default? debt is lost.
		emit PositionsClosed(ids, msg.sender, reserve0Repayed, reserve1Repayed);
	}

	/**
	 @dev Liquidate given position ids if they are already defaulted and it sends liquidity of msg.sender back
	 */
	function liquidateAndBurn(
		address to,
		uint256[] calldata positionIds,
		uint256 minReceived0,
		uint256 minReceived1
	) external returns (uint256 amount0, uint256 amount1) {
		liquidate(positionIds, minReceived0, minReceived1);
		(amount0, amount1) = burn(to);
	}

	//TODO: unit tests for protocolfees everywhere
	function updateDebt() public {
		uint256 blocksPassed = block.number - lastDebtUpdate;
		uint112 gain0 = reserve0Debt;
		uint112 gain1 = reserve1Debt;

		reserve0Debt = uint112((reserve0Debt * (blocksPassed * token0InterestRate() + 1e18)) / 1e18);
		reserve1Debt = uint112((reserve1Debt * (blocksPassed * token1InterestRate() + 1e18)) / 1e18);

		gain0 = reserve0Debt - gain0;
		gain1 = reserve1Debt - gain1;
		protocolFees0 += (gain0 * uint112(interestRate.reserveRate())) / 1e18;
		protocolFees1 += (gain1 * uint112(interestRate.reserveRate())) / 1e18;

		lastDebtUpdate = block.number;
	}

	//per block interest rate. rate*blocksPerYear*365/1e18 = ~APY, so if no action happened for a whole year we'll get an approximate
	//the more blocks has some action the more accurate compounding will be
	//this is similar to Compound
	//if APY is 5% then block rate = ((root 365 of 1.05) - 1) / blockPerYear * 1e18
	function token0InterestRate() public view returns (uint256) {
		return interestRate.getBorrowRate(reserve0 + reserve0Vault - reserve0Collateral, reserve0Debt, protocolFees0);
		// return 20347125892; //5% apy
	}

	function token1InterestRate() public view returns (uint256) {
		return interestRate.getBorrowRate(reserve1 + reserve1Vault - reserve1Collateral, reserve1Debt, protocolFees1);
		// return 20347125892;
	}

	function closeData(uint256 posId)
		public
		view
		returns (
			uint112 token0DebtValue,
			uint112 token1DebtValue,
			bool hasDefaulted,
			uint256 debtValueInCollateralToken
		)
	{
		return _closeData(positions[posId]);
	}

	function _closeData(Position memory pos)
		internal
		view
		returns (
			uint112 token0DebtValue,
			uint112 token1DebtValue,
			bool hasDefaulted,
			uint256 debtValueInCollateralToken
		)
	{
		(token0DebtValue, token1DebtValue) = _debtValue(
			pos.isToken0 ? 0 : pos.debtShares,
			pos.isToken0 ? pos.debtShares : 0
		);

		//1. calculate how much other token (collateral token) is required to cover tokenXDebtValue
		debtValueInCollateralToken = getValue(
			pos.isToken0 ? token1DebtValue : token0DebtValue,
			pos.isToken0 ? false : true
		);

		//2. if <= collateral + exposure then swap back some of collateral token to cover borrowed tokenXDebtvalue
		hasDefaulted = debtValueInCollateralToken >= pos.vault;
	}

	/**
	 * update borrower share of the debt + interest
	 */
	function _mintInterestDebt(
		address user,
		bool isToken0,
		uint256 borrow
	) internal returns (uint112) {
		if (isToken0 == false) {
			uint256 debtSharesToMint0;
			if (debtShares0 == 0) {
				debtSharesToMint0 = borrow;
			} else {
				debtSharesToMint0 = (borrow * debtShares0) / reserve0Debt;
			}
			uint112 debtSharesToMint0In112 = uint112(debtSharesToMint0);
			debtBalances[user][0] += debtSharesToMint0In112;
			debtShares0 += debtSharesToMint0In112;
			reserve0Debt += uint112(borrow);
			return debtSharesToMint0In112;
		} else {
			uint256 debtSharesToMint1;
			if (debtShares1 == 0) {
				debtSharesToMint1 = borrow;
			} else {
				debtSharesToMint1 = (borrow * debtShares1) / reserve1Debt;
			}
			uint112 debtSharesToMint1In112 = uint112(debtSharesToMint1);
			debtBalances[user][1] += debtSharesToMint1In112;
			debtShares1 += debtSharesToMint1In112;
			reserve1Debt += uint112(borrow);
			return debtSharesToMint1In112;
		}
	}

	function _debtValue(uint112 debtSharesOwned0, uint112 debtSharesOwned1) internal view returns (uint112, uint112) {
		uint256 debtOwnedValue0 = debtShares0 == 0
			? 0
			: (uint256(debtSharesOwned0) * uint256(reserve0Debt)) / uint256(debtShares0);
		uint256 debtOwnedValue1 = debtShares1 == 0
			? 0
			: (uint256(debtSharesOwned1) * uint256(reserve1Debt)) / uint256(debtShares1);

		return (uint112(debtOwnedValue0), uint112(debtOwnedValue1));
	}

	/**
	 * update borrower share of the debt + interest and global debt
	 */
	function _repayInterestDebt(
		address user,
		bool isToken0,
		uint112 debtSharesOwned
	) internal {
		if (isToken0) {
			debtBalances[user][1] -= debtSharesOwned;
			debtShares1 -= debtSharesOwned;
		} else {
			debtBalances[user][0] -= debtSharesOwned;
			debtShares0 -= debtSharesOwned;
		}
	}

	function isDefaulted(uint256 positionId) public view returns (bool) {
		Position memory pos = positions[positionId];
		require(pos.isOpen, 'Contango: position already closed');

		(, , bool hasDefaulted, ) = _closeData(pos);

		//case of deault
		return hasDefaulted;
	}

	/**
	 *@dev helper function that returns worth of current withdrawable liquidity for particular user for token0 and token1
	 * what is locked in the sidepool vaults is not withdrawable
	 */
	function liquidityBalance(address _user) public view returns (uint256, uint256) {
		uint256 liquidity = balanceOf[_user];
		uint256 balance0 = IERC20(token0).balanceOf(address(this));
		uint256 balance1 = IERC20(token1).balanceOf(address(this));
		uint256 _totalSupply = totalSupply; // gas savings
		uint256 amount0 = (liquidity * (balance0 - reserve0Vault - protocolFees0)) / _totalSupply; // using balances ensures pro-rata distribution
		uint256 amount1 = (liquidity * (balance1 - reserve1Vault - protocolFees1)) / _totalSupply; // using balances ensures pro-rata distribution
		return (amount0, amount1);
	}

	/**
	 *@dev helper function that returns worth of liquidity for particular user for token0 and token1 after liquidate given positions
	 */
	function liquidityBalanceAfterLiquidate(address _user, uint256[] memory _positionIds)
		public
		view
		returns (uint256, uint256)
	{
		uint256 initialreserve0Vault = reserve0Vault;
		uint256 initialreserve1Vault = reserve1Vault;
		uint112 reserve0VaultReduced;
		uint112 reserve1VaultReduced;
		for (uint256 i; i < _positionIds.length; i++) {
			Position memory pos = positions[_positionIds[i]];
			if (!pos.isOpen) continue;

			(, , bool hasDefaulted, ) = _closeData(pos);

			if (hasDefaulted == false) continue;
			if (pos.isToken0) {
				//unlock collateral + exposure in vault. (we exchanged it to debtToken and sent the rest to user)
				reserve0VaultReduced += pos.vault;
			} else {
				reserve1VaultReduced += pos.vault;
			}
		}
		initialreserve0Vault -= reserve0VaultReduced;
		initialreserve1Vault -= reserve1VaultReduced;
		uint256 liquidity = balanceOf[_user];
		uint256 balance0 = IERC20(token0).balanceOf(address(this));
		uint256 balance1 = IERC20(token1).balanceOf(address(this));
		uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
		uint256 amount0 = (liquidity * (balance0 - initialreserve0Vault - protocolFees0)) / _totalSupply; // using balances ensures pro-rata distribution
		uint256 amount1 = (liquidity * (balance1 - initialreserve1Vault - protocolFees1)) / _totalSupply; // using balances ensures pro-rata distribution
		return (amount0, amount1);
	}

	function withdrawProtocolFees(uint112 amount0, uint112 amount1) public {
		require(msg.sender == interestRate.owner(), 'not owner');
		require(amount0 <= protocolFees0 && amount1 <= protocolFees1, 'invalid amount');
		protocolFees0 -= amount0;
		protocolFees1 -= amount1;
		reserve0 -= amount0;
		reserve1 -= amount1;
		if (amount0 > 0) _safeTransfer(token0, msg.sender, amount0);
		if (amount1 > 0) _safeTransfer(token1, msg.sender, amount1);
	}

	function verifyOraclePriceInRange() public returns (bool isInRange) {
		return true;
		// uint32 twapSecondsAgo = UniswapV3SwapHelper.getOldestObservationSecondsAgo(address(uniswapPool));
		// twapSecondsAgo = twapSecondsAgo > TWAP_INTERVAL ? TWAP_INTERVAL : twapSecondsAgo;
		// //assume we need TWAP_INTERVAL/BLOCK_TIME slots to make sure we have enough observations to cover TWAP_INTERVAL
		// uniswapPool.increaseObservationCardinalityNext(uint16(TWAP_INTERVAL / 15));

		// //TODO: is this secure??
		// if (twapSecondsAgo == 0)
		// 	//no observations, we dont use oracle
		// 	return true;

		// (uint256 token0PriceTwap, , ) = UniswapV3SwapHelper.getTwapPriceAndLiquidity(
		// 	address(uniswapPool),
		// 	twapSecondsAgo
		// );
		// uint256 token0Price = UniswapV3SwapHelper.getToken0Price(address(uniswapPool));
		// uint256 diff = token0Price < token0PriceTwap
		// 	? (100 * token0Price) / token0PriceTwap
		// 	: (100 * token0PriceTwap) / token0Price;
		// require(diff >= 95, 'Futurize: invalid oracle price');
	}

	function getValue(uint256 amountIn, bool isToken0In) public view returns (uint256 amountOut) {
		amountOut =
			(amountIn *
				(
					isToken0In
						? UniswapV3SwapHelper.getToken0Price(address(uniswapPool))
						: UniswapV3SwapHelper.getToken1Price(address(uniswapPool))
				)) /
			1e18;
	}

	function max(uint256 x, uint256 y) public pure returns (uint256 z) {
		z = x < y ? y : x;
	}
}

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';
import '../BaseInterestRate.sol';

interface IExternalRouter is ISwapRouter, IPeripheryImmutableState {}

interface IFuturizePair {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast,
			uint112 debtFreeReserve0,
			uint112 debtFreeReserve1
		);

	function mint(address to) external returns (uint256 liquidity);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);

	function skim(address to) external;

	function sync() external;

	function initialize(
		address _token0,
		address _token1,
		IExternalRouter _router,
		BaseInterestRate _interestRate
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8;

// import 'hardhat/console.sol';

/**
 * @title Logic for Compound's JumpRateModel Contract V2.
 * @author Compound (modified by Dharma Labs, refactored by Arr00)
 * @notice Version 2 modifies Version 1 by enabling updateable parameters.
 */
contract BaseInterestRate {
	event NewInterestParams(
		uint256 baseRatePerBlock,
		uint256 multiplierPerBlock,
		uint256 jumpMultiplierPerBlock,
		uint256 kink,
		uint256 reserveRate
	);

	/**
	 * @notice The address of the owner, i.e. the Timelock contract, which can update parameters directly
	 */
	address public owner;

	/**
	 * @notice The approximate number of blocks per year that is assumed by the interest rate model
	 */
	uint64 public constant blocksPerYear = 2102400;

	/**
	 * @notice The multiplier of utilization rate that gives the slope of the interest rate
	 */
	uint256 public multiplierPerBlock;

	/**
	 * @notice The base interest rate which is the y-intercept when utilization rate is 0
	 */
	uint256 public baseRatePerBlock;

	/**
	 * @notice The multiplierPerBlock after hitting a specified utilization point
	 */
	uint256 public jumpMultiplierPerBlock;

	/**
	 * @notice The utilization point at which the jump multiplier is applied
	 */
	uint256 public kink;

	uint256 public reserveRate = 0.3e16;

	/**
	 * @notice Construct an interest rate model
	 * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
	 * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
	 * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
	 * @param kink_ The utilization point at which the jump multiplier is applied
	 * @param owner_ The address of the owner, i.e. the Timelock contract (which has the ability to update parameters directly)
	 */
	constructor(
		uint256 baseRatePerYear,
		uint256 multiplierPerYear,
		uint256 jumpMultiplierPerYear,
		uint256 kink_,
		address owner_
	) {
		owner = owner_;

		updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_, reserveRate);
	}

	/**
	 * @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
	 * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
	 * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
	 * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
	 * @param kink_ The utilization point at which the jump multiplier is applied
	 * @param reserveRate the protocol fee rate (diff between supply rate and borrow rate)
	 */
	function updateJumpRateModel(
		uint256 baseRatePerYear,
		uint256 multiplierPerYear,
		uint256 jumpMultiplierPerYear,
		uint256 kink_,
		uint256 reserveRate
	) external {
		require(msg.sender == owner, 'only the owner may call this function.');

		updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_, reserveRate);
	}

	/**
	 * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
	 * @param cash The amount of cash in the market
	 * @param borrows The amount of borrows in the market
	 * @param reserves The amount of reserves in the market (currently unused)
	 * @return The utilization rate as a mantissa between [0, 1e18]
	 */
	function utilizationRate(
		uint256 cash,
		uint256 borrows,
		uint256 reserves
	) public pure returns (uint256) {
		// Utilization rate is 0 when there are no borrows
		if (borrows == 0) {
			return 0;
		}

		return (borrows * 1e18) / (cash + borrows + reserves);
	}

	/**
	 * @notice Calculates the current borrow rate per block, with the error code expected by the market
	 * @param cash The amount of cash in the market
	 * @param borrows The amount of borrows in the market
	 * @param reserves The amount of reserves in the market
	 * @return rate The borrow rate percentage per block as a mantissa (scaled by 1e18)
	 */
	function getBorrowRate(
		uint256 cash,
		uint256 borrows,
		uint256 reserves
	) public view returns (uint256 rate) {
		uint256 util = utilizationRate(cash, borrows, reserves);

		if (util <= kink) {
			rate = ((util * multiplierPerBlock) / 1e18) + baseRatePerBlock;
		} else {
			uint256 normalRate = ((kink * multiplierPerBlock) / 1e18) + baseRatePerBlock;
			uint256 excessUtil = util - kink;
			rate = ((excessUtil * jumpMultiplierPerBlock) / 1e18) + normalRate;
		}
		// console.log('borrow rate: %s', rate);
	}

	/**
	 * @notice Calculates the current supply rate per block
	 * @param cash The amount of cash in the market
	 * @param borrows The amount of borrows in the market
	 * @param reserves The amount of reserves in the market
	 * @return rate The supply rate percentage per block as a mantissa (scaled by 1e18)
	 */
	function getSupplyRate(
		uint256 cash,
		uint256 borrows,
		uint256 reserves
	) public view returns (uint256 rate) {
		uint256 oneMinusReserveFactor = uint256(1e18) - reserveRate;
		uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
		uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / 1e18;
		rate = (utilizationRate(cash, borrows, reserves) * rateToPool) / 1e18;
	}

	/**
	 * @notice Internal function to update the parameters of the interest rate model
	 * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
	 * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
	 * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
	 * @param kink_ The utilization point at which the jump multiplier is applied
	 * @param reserveRate_ the protocol fee rate (diff between supply rate and borrow rate)
	 */
	function updateJumpRateModelInternal(
		uint256 baseRatePerYear,
		uint256 multiplierPerYear,
		uint256 jumpMultiplierPerYear,
		uint256 kink_,
		uint256 reserveRate_
	) internal {
		baseRatePerBlock = baseRatePerYear / blocksPerYear;
		multiplierPerBlock = (multiplierPerYear * 1e18) / (blocksPerYear * kink_);
		jumpMultiplierPerBlock = jumpMultiplierPerYear / blocksPerYear;
		kink = kink_;
		reserveRate = reserveRate;
		emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink, reserveRate);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8;

import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './interfaces/IERC20.sol';

contract BasePool is UniswapV2ERC20 {
	using SafeMath for uint256;

	uint256 public constant MINIMUM_LIQUIDITY = 10**3;
	bytes4 public constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
	address public factory;
	address public token0;
	address public token1;

	uint32 public blockTimestampLast; // uses single storage slot, accessible via getReserves

	uint256 public unlocked = 1;

	/*** Contango sidepools */
	uint112 public reserve0; // uses single storage slot, accessible via getReserves
	uint112 public reserve1; // uses single storage slot, accessible via getReserves
	uint112 public reserve0Vault; // user colateral + pool positon exposure (=colateral amount)
	uint112 public reserve1Vault; // uses single storage slot, accessible via getReserves
	uint112 public reserve0Debt; //how much debt (borrowed+fees) accrued for token0 used for interest calculations
	uint112 public reserve1Debt; //how much debt (borrowed+fees) accrued for token0 used for interest calculations
	uint112 public reserve0Collateral; // locked collateral (required to calcualte liquidity shares)
	uint112 public reserve1Collateral;
	uint112 public debtShares0; //how much fees accrued for token0 used for interest calculations
	uint112 public debtShares1; //how much fees accrued for token0 used for interest calculations
	uint112 public protocolFees0;
	uint112 public protocolFees1;
	mapping(address => uint112[2]) public debtBalances;

	/*** end Contango sidepools */

	modifier lock() {
		require(unlocked == 1, 'UniswapV2: LOCKED');
		unlocked = 0;
		_;
		unlocked = 1;
	}

	/**
	 * @dev contango addition
	 */
	function getReserves()
		public
		view
		returns (
			uint112 _reserve0,
			uint112 _reserve1,
			uint32 _blockTimestampLast,
			uint112 _debtFreeReserve0,
			uint112 _debtFreeReserve1
		)
	{
		_reserve0 = reserve0 + reserve0Vault;
		_reserve1 = reserve1 + reserve1Vault;
		_blockTimestampLast = blockTimestampLast;
		_debtFreeReserve0 = _reserve0 - reserve0Collateral;
		_debtFreeReserve1 = _reserve1 - reserve1Collateral;
	}

	function _safeTransfer(
		address token,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
	}

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(uint256 amountIn, uint256 amount0Out, uint256 amount1Out, address indexed to);
	event Sync(uint112 reserve0, uint112 reserve1);

	// update reserves and, on the first call per block, price accumulators
	function _update(uint256 balance0, uint256 balance1) private {
		require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'UniswapV2: OVERFLOW');
		uint32 blockTimestamp = uint32(block.timestamp % 2**32);

		reserve0 = uint112(balance0 - reserve0Vault);
		reserve1 = uint112(balance1 - reserve1Vault);
		blockTimestampLast = blockTimestamp;
		emit Sync(reserve0, reserve1); //contango add sidepools to event
	}

	// this low-level function should be called from a contract which performs important safety checks
	function mint(address to) external lock returns (uint256 liquidity) {
		uint256 balance0 = IERC20(token0).balanceOf(address(this));
		uint256 balance1 = IERC20(token1).balanceOf(address(this));

		(uint256 total0, uint256 total1, , uint256 totalDebtFree0, uint256 totalDebtFree1) = getReserves();
		uint256 amount0 = balance0 - total0;
		uint256 amount1 = balance1 - total1;

		uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
		if (_totalSupply == 0) {
			liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
			_mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
		} else {
			liquidity = Math.min((amount0 * _totalSupply) / totalDebtFree0, (amount1 * _totalSupply) / totalDebtFree1); //dont include collateral in totals
		}
		require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
		_mint(to, liquidity);

		_update(balance0, balance1);
		emit Mint(msg.sender, amount0, amount1);
	}

	// this low-level function should be called from a contract which performs important safety checks
	function burn(address to) public lock returns (uint256 amount0, uint256 amount1) {
		address _token0 = token0; // gas savings
		address _token1 = token1; // gas savings
		uint256 balance0 = IERC20(_token0).balanceOf(address(this));
		uint256 balance1 = IERC20(_token1).balanceOf(address(this));
		uint256 liquidity = balanceOf[address(this)];

		uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

		//contango: vault can not be withdrawn
		amount0 = (liquidity * (balance0 - reserve0Vault - protocolFees0)) / _totalSupply; // using balances ensures pro-rata distribution
		amount1 = (liquidity * (balance1 - reserve1Vault - protocolFees1)) / _totalSupply; // using balances ensures pro-rata distribution

		require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
		_burn(address(this), liquidity);
		_safeTransfer(_token0, to, amount0);
		_safeTransfer(_token1, to, amount1);
		balance0 = IERC20(_token0).balanceOf(address(this));
		balance1 = IERC20(_token1).balanceOf(address(this));

		_update(balance0, balance1); //contango: deduct actuall sidepool withdrawn amount
		emit Burn(msg.sender, amount0, amount1, to);
	}

	// force reserves to match balances
	function sync() external lock {
		_update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
	}
}

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';

import './libraries/TickMathV3.sol';
import './interfaces/IERC20.sol';

pragma solidity >=0.8.0;

library UniswapV3SwapHelper {
	// IUniswapV3Pool pool;
	// ISwapRouter router;
	// uint24 poolFee = 3000;

	function initializeSwapHelper(
		address _token0,
		address _token1,
		ISwapRouter _router
	) public returns (IUniswapV3Pool pool) {
		// router = _router;
		pool = _findPoolWithMostLiquidity(_token0, _token1, _router);
		safeApprove(_token0, address(_router), type(uint256).max);
		safeApprove(_token1, address(_router), type(uint256).max);
		return pool;
	}

	//TODO: this needs to be tested. also this could be manipulated, so maybe using the liquidity oracle is a solution.
	//when using an oralce this could be ran to find the best pool every once in a while
	function _findPoolWithMostLiquidity(
		address _token0,
		address _token1,
		ISwapRouter _router
	) public returns (IUniswapV3Pool _pool) {
		uint24[3] memory fees = [uint24(1000), uint24(3000), uint24(10000)];
		uint128 liquidity;
		IUniswapV3PoolState tmpPool;
		for (uint256 i; i < 3; i++) {
			tmpPool = IUniswapV3PoolState(
				IUniswapV3Factory(IPeripheryImmutableState(address(_router)).factory()).getPool(
					_token0,
					_token1,
					fees[i]
				)
			);
			if (address(tmpPool) == address(0)) continue;
			uint128 tmpLiquidity = tmpPool.liquidity();
			if (tmpLiquidity > liquidity) {
				_pool = IUniswapV3Pool(address(tmpPool));
				liquidity = tmpLiquidity;
			}
		}
	}

	function getToken0Price(address pool) public view returns (uint256 price) {
		(uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
		return ((uint256(sqrtPriceX96)**2) >> (96 * 2)) * 1e18;
	}

	function getToken1Price(address pool) public view returns (uint256 price) {
		(uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
		return (2**192 * 1e18) / (uint256(sqrtPriceX96)**2);
	}

	function getTwapPriceAndLiquidity(address pool, uint32 secondsAgo)
		public
		view
		returns (
			uint256 token0Price,
			uint256 token1Price,
			uint128 harmonicMeanLiquidity
		)
	{
		require(secondsAgo != 0, 'BP');

		uint32[] memory secondsAgos = new uint32[](2);
		secondsAgos[0] = secondsAgo;
		secondsAgos[1] = secondsAgo < 60 ? 0 : 60;

		(int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) = IUniswapV3Pool(pool)
			.observe(secondsAgos);

		int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
		uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[1] -
			secondsPerLiquidityCumulativeX128s[0];

		int24 arithmeticMeanTick = int24(tickCumulativesDelta / int32(secondsAgo));
		// Always round to negative infinity
		if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int32(secondsAgo) != 0)) arithmeticMeanTick--;

		// We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
		uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
		harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
		uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);
		token0Price = (uint256(sqrtRatioX96) * uint256(sqrtRatioX96) * 1e18) >> (96 * 2);
		token1Price = (2**192 * 1e18) / (uint256(sqrtRatioX96)**2);
	}

	/// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
	/// @param pool Address of Uniswap V3 pool that we want to observe
	/// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
	function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
		(, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
		require(observationCardinality > 0, 'NI');

		(uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(pool).observations(
			(observationIndex + 1) % observationCardinality
		);

		// The next index might not be initialized if the cardinality is in the process of increasing
		// In this case the oldest observation is always in index 0
		if (!initialized) {
			(observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
		}

		secondsAgo = uint32(block.timestamp) - observationTimestamp;
	}

	function getTokenPricesFromSqrtPriceX96(uint160 sqrtPriceX96)
		public
		pure
		returns (uint256 token0Price, uint256 token1Price)
	{
		token0Price = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * 1e18) >> (96 * 2);
		token1Price = (2**192 * 1e18) / (uint256(sqrtPriceX96)**2);
	}

	function swapExactIn(
		ISwapRouter router,
		uint24 poolFee,
		address _tokenIn,
		address _tokenOut,
		uint256 _amountIn,
		uint256 _minOut,
		address _to
	) public returns (uint256 amountOut) {
		ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
			tokenIn: _tokenIn,
			tokenOut: _tokenOut,
			fee: poolFee,
			recipient: _to,
			deadline: block.timestamp,
			amountIn: _amountIn,
			amountOutMinimum: _minOut,
			sqrtPriceLimitX96: 0
		});

		amountOut = router.exactInputSingle(params);
	}

	function swapExactOut(
		ISwapRouter router,
		uint24 poolFee,
		address _tokenIn,
		address _tokenOut,
		uint256 _amountOut,
		uint256 _maxIn,
		address _to
	) public returns (uint256 amountIn) {
		ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
			tokenIn: _tokenIn,
			tokenOut: _tokenOut,
			fee: poolFee,
			recipient: _to,
			deadline: block.timestamp,
			amountOut: _amountOut,
			amountInMaximum: _maxIn,
			sqrtPriceLimitX96: 0
		});

		// Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
		try router.exactOutputSingle(params) returns (uint256 amountIn) {
			return amountIn;
		} catch {
			return 0;
		}
	}

	/// @notice Approves the stipulated contract to spend the given allowance in the given token
	/// @dev Errors with 'SA' if transfer fails
	/// @param token The contract address of the token to be approved
	/// @param to The target of the approval
	/// @param value The amount of the given token the target will be allowed to spend
	function safeApprove(
		address token,
		address to,
		uint256 value
	) public {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/SafeMath.sol';

contract UniswapV2ERC20 {
	using SafeMath for uint256;

	string public constant name = 'Futurize V1';
	string public constant symbol = 'FTZ-V1';
	uint8 public constant decimals = 18;
	uint256 public totalSupply;
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	bytes32 public DOMAIN_SEPARATOR;
	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
	mapping(address => uint256) public nonces;
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	constructor() {
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
				keccak256(bytes(name)),
				keccak256(bytes('1')),
				block.chainid,
				address(this)
			)
		);
	}

	function _mint(address to, uint256 value) internal {
		totalSupply = totalSupply + value;
		balanceOf[to] = balanceOf[to] + value;
		emit Transfer(address(0), to, value);
	}

	function _burn(address from, uint256 value) internal {
		balanceOf[from] = balanceOf[from] - value;
		totalSupply = totalSupply - value;
		emit Transfer(from, address(0), value);
	}

	function _approve(
		address owner,
		address spender,
		uint256 value
	) private {
		allowance[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

	function _transfer(
		address from,
		address to,
		uint256 value
	) private {
		balanceOf[from] = balanceOf[from] - value;
		balanceOf[to] = balanceOf[to] + value;
		emit Transfer(from, to, value);
	}

	function approve(address spender, uint256 value) external returns (bool) {
		_approve(msg.sender, spender, value);
		return true;
	}

	function transfer(address to, uint256 value) external returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool) {
		if (allowance[from][msg.sender] != type(uint256).max) {
			allowance[from][msg.sender] = allowance[from][msg.sender] - value;
		}
		_transfer(from, to, value);
		return true;
	}

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR,
				keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
			)
		);
		address recoveredAddress = ecrecover(digest, v, r, s);
		require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
		_approve(owner, spender, value);
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8;

// a library for performing various math operations

library Math {
	function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = x < y ? x : y;
	}

	// babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
	function sqrt(uint256 y) internal pure returns (uint256 z) {
		if (y > 3) {
			z = y;
			uint256 x = y / 2 + 1;
			while (x < z) {
				z = x;
				x = (y / x + x) / 2;
			}
		} else if (y != 0) {
			z = 1;
		}
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8;

interface IERC20 {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8;

interface IUniswapV2ERC20 {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
	function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
		require((z = x + y) >= x, 'ds-math-add-overflow');
	}

	function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
		require((z = x - y) <= x, 'ds-math-sub-underflow');
	}

	function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
	/// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
	int24 internal constant MIN_TICK = -887272;
	/// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
	int24 internal constant MAX_TICK = -MIN_TICK;

	/// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
	uint160 internal constant MIN_SQRT_RATIO = 4295128739;
	/// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
	uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

	/// @notice Calculates sqrt(1.0001^tick) * 2^96
	/// @dev Throws if |tick| > max tick
	/// @param tick The input tick for the above formula
	/// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
	/// at the given tick
	function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
		uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
		require(absTick <= uint256(uint24(MAX_TICK)), 'T');

		uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
		if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
		if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
		if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
		if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
		if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
		if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
		if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
		if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
		if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
		if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
		if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
		if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
		if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
		if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
		if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
		if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
		if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
		if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
		if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

		if (tick > 0) ratio = type(uint256).max / ratio;

		// this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
		// we then downcast because we know the result always fits within 160 bits due to our tick input constraint
		// we round up in the division so getTickAtSqrtRatio of the output price is always consistent
		sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
	}

	/// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
	/// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
	/// ever return.
	/// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
	/// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
	function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
		// second inequality must be < because the price can never reach the price at the max tick
		require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
		uint256 ratio = uint256(sqrtPriceX96) << 32;

		uint256 r = ratio;
		uint256 msb = 0;

		assembly {
			let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(5, gt(r, 0xFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(4, gt(r, 0xFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(3, gt(r, 0xFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(2, gt(r, 0xF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(1, gt(r, 0x3))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := gt(r, 0x1)
			msb := or(msb, f)
		}

		if (msb >= 128) r = ratio >> (msb - 127);
		else r = ratio << (127 - msb);

		int256 log_2 = (int256(msb) - 128) << 64;

		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(63, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(62, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(61, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(60, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(59, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(58, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(57, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(56, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(55, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(54, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(53, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(52, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(51, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(50, f))
		}

		int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

		int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
		int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

		tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}