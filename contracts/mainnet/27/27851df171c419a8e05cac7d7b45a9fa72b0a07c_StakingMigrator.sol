/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity 0.8.1;

interface ISupplyController {
	function mintIncentive(address addr) external;
	function mintableIncentive(address addr) external view returns (uint);
	function mint(address token, address owner, uint amount) external;
	function changeSupplyController(address newSupplyController) external;
}

interface IADXToken {
	function transfer(address to, uint256 amount) external returns (bool);
	function transferFrom(address from, address to, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address spender) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function totalSupply() external returns (uint);
	function supplyController() external view returns (ISupplyController);
	function changeSupplyController(address newSupplyController) external;
	function mint(address owner, uint amount) external;
}


interface IStakingPool {
	function enterTo(address recipient, uint amount) external;
}

interface ILegacyStaking {
	struct BondState {
		bool active;
		// Data type must be larger than MAX_SLASH (2**64 > 10**18)
		uint64 slashedAtStart;
		uint64 willUnlock;
	}
	function bonds(bytes32 id) external view returns (BondState calldata);
	function slashPoints(bytes32 id) external view returns (uint);
}

contract StakingMigrator {
	ILegacyStaking public constant legacyStaking = ILegacyStaking(0x4846C6837ec670Bbd1f5b485471c8f64ECB9c534);
	IADXToken public constant ADXToken = IADXToken(0xADE00C28244d5CE17D72E40330B1c318cD12B7c3);
	bytes32 public constant poolId = 0x2ce0c96383fb229d9776f33846e983a956a7d95844fac57b180ed0071d93bb28;
	IStakingPool public newStaking;

	// must be 1000 + the bonus promilles
	uint public constant WITH_BONUS_PROMILLES = 1048;
	uint public constant WHALE_BOND = 4000000e18;

	mapping(bytes32 => bool) public migratedBonds;

	event LogBondMigrated(address indexed bondOwner, bytes32 bondId);

	constructor(IStakingPool _newStaking) {
		newStaking = _newStaking;
		ADXToken.approve(address(_newStaking), type(uint256).max);
	}

	// NOTE: this works by minting the full bondAmount, which is correct if the pool never had any slashing prior
	// to the migration, which is the case for the Tom pool
	function migrate(uint bondAmount, uint nonce, address recipient, uint extraAmount) external {
		require(legacyStaking.slashPoints(poolId) == 1e18, "POOL_NOT_SLASHED");

		bytes32 id = keccak256(abi.encode(address(legacyStaking), msg.sender, bondAmount, poolId, nonce));

		require(!migratedBonds[id], "BOND_MIGRATED");
		migratedBonds[id] = true;

		ILegacyStaking.BondState memory bondState = legacyStaking.bonds(id);
		require(bondState.active, "BOND_NOT_ACTIVE");

		// willUnlock must be lower than 23 april (30 days after 24 march)
		if (bondState.willUnlock > 0 && bondState.willUnlock < 1619182800) {
			ADXToken.supplyController().mint(address(ADXToken), recipient, bondAmount);
		} else {
			uint toMint = (bondAmount > WHALE_BOND)
				? bondAmount
				: ((bondAmount * WITH_BONUS_PROMILLES) / 1000);
			ADXToken.supplyController().mint(address(ADXToken), address(this), toMint);

			// if there is an extraAmount, we expect that the staker will send it to this contract before calling this,
			// in the same txn (by using Identity)
			newStaking.enterTo(recipient, toMint + extraAmount);
		}

		emit LogBondMigrated(msg.sender, id);
	}
}