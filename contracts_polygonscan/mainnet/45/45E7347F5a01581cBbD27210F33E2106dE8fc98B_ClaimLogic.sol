// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveIncentives {
	function REWARD_TOKEN() external view returns (address);

	function getRewardsBalance(address[] calldata assets, address user)
		external
		view
		returns (uint256);

	function getUserUnclaimedRewards(address _user)
		external
		view
		returns (uint256);

	function claimRewards(
		address[] calldata assets,
		uint256 amount,
		address to
	) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDistributionFactory {
	function stakingRewardsInfoByStakingToken(address erc20)
		external
		view
		returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProtocolDistribution {
	function stake(uint256 amount) external;

	function withdraw(uint256 amount) external;

	function getReward(address user) external;

	function earned(address user) external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RegistryInterface Interface
 */
interface IRegistry {
	function logic(address logicAddr) external view returns (bool);

	function implementation(bytes32 key) external view returns (address);

	function notAllowed(address erc20) external view returns (bool);

	function deployWallet() external returns (address);

	function wallets(address user) external view returns (address);

	function getFee() external view returns (uint256);

	function feeRecipient() external view returns (address);

	function memoryAddr() external view returns (address);

	function distributionContract(address token)
		external
		view
		returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWallet {
	event LogMint(address indexed erc20, uint256 tokenAmt);
	event LogRedeem(address indexed erc20, uint256 tokenAmt);
	event LogBorrow(address indexed erc20, uint256 tokenAmt);
	event LogPayback(address indexed erc20, uint256 tokenAmt);
	event LogDeposit(address indexed erc20, uint256 tokenAmt);
	event LogWithdraw(address indexed erc20, uint256 tokenAmt);
	event LogSwap(address indexed src, address indexed dest, uint256 amount);
	event LogLiquidityAdd(
		address indexed tokenA,
		address indexed tokenB,
		uint256 amountA,
		uint256 amountB
	);
	event LogLiquidityRemove(
		address indexed tokenA,
		address indexed tokenB,
		uint256 amountA,
		uint256 amountB
	);
	event VaultDeposit(address indexed erc20, uint256 tokenAmt);
	event VaultWithdraw(address indexed erc20, uint256 tokenAmt);
	event VaultClaim(address indexed erc20, uint256 tokenAmt);
	event DelegateAdded(address delegate);
	event DelegateRemoved(address delegate);

	function executeMetaTransaction(bytes memory sign, bytes memory data)
		external;

	function execute(address[] calldata targets, bytes[] calldata datas)
		external
		payable;

	function owner() external view returns (address);

	function registry() external view returns (address);

	function DELEGATE_ROLE() external view returns (bytes32);

	function hasRole(bytes32, address) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IProtocolDistribution.sol";
import "../interfaces/IDistributionFactory.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IWallet.sol";
import "../interfaces/IAaveIncentives.sol";

/**
 * @title Claim ETHA rewards for interacting with Lending Protocols
 */
contract ClaimLogic {
	/**
	 * @dev get vault distribution factory address
	 */
	function getVaultDistributionFactory() public pure returns (address) {
		return 0xdB05A386810c809aD5a77422eb189D36c7f24402;
	}

	/**
	 * @dev get Aave MATIC incentives distribution contract
	 */
	function getAaveIncentivesAddress() public pure returns (address) {
		return 0x357D51124f59836DeD84c8a1730D72B749d8BC23;
	}

	/**
	 * @dev get lending distribution contract address
	 */
	function getLendingDistributionAddress(address token)
		public
		view
		returns (address)
	{
		return
			IRegistry(IWallet(address(this)).registry()).distributionContract(
				token
			);
	}

	/**
	 * @notice read aave rewards in MATIC
	 */
	function getRewardsAave(address[] memory tokens)
		external
		view
		returns (uint256)
	{
		return
			IAaveIncentives(getAaveIncentivesAddress()).getRewardsBalance(
				tokens,
				address(this)
			);
	}

	/**
	 * @notice read lending rewards in ETHA
	 */
	function getRewardsLending(address erc20) external view returns (uint256) {
		return
			IProtocolDistribution(getLendingDistributionAddress(erc20)).earned(
				address(this)
			);
	}

	/**
	 * @notice read vaults rewards in ETHA
	 */
	function getRewardsVaults(address erc20) external view returns (uint256) {
		address dist = IDistributionFactory(getVaultDistributionFactory())
		.stakingRewardsInfoByStakingToken(erc20);

		return IProtocolDistribution(dist).earned(address(this));
	}

	/**
	 * @notice claim vault ETHA rewards
	 */
	function claimRewardsVaults(address erc20) external {
		address dist = IDistributionFactory(getVaultDistributionFactory())
		.stakingRewardsInfoByStakingToken(erc20);

		IProtocolDistribution(dist).getReward(address(this));
	}

	/**
	 * @notice claim lending ETHA rewards
	 */
	function claimRewardsLending(address erc20) external {
		IProtocolDistribution(getLendingDistributionAddress(erc20)).getReward(
			address(this)
		);
	}

	/**
	 * @notice claim Aave MATIC rewards
	 */
	function claimAaveRewards(address[] calldata tokens, uint256 amount)
		external
	{
		IAaveIncentives(getAaveIncentivesAddress()).claimRewards(
			tokens,
			amount,
			address(this)
		);
	}
}