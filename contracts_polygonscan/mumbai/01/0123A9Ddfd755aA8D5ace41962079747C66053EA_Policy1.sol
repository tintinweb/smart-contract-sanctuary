// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interface/IPolicy.sol";
import "../common/libs/Curve.sol";
import "../common/registry/UsingRegistry.sol";

contract Policy1 is IPolicy, Ownable, Curve, UsingRegistry {
	uint256 public override marketVotingSeconds = 86400 * 5;
	uint256 public override policyVotingSeconds = 86400 * 5;
	uint256 public mintPerSecondAndAsset;
	uint256 public presumptiveAssets;

	constructor(
		address _registry,
		uint256 _maxMintPerSecondAndAsset,
		uint256 _presumptiveAssets
	) UsingRegistry(_registry) {
		mintPerSecondAndAsset = _maxMintPerSecondAndAsset;
		presumptiveAssets = _presumptiveAssets;
	}

	function rewards(uint256 _lockups, uint256 _assets)
		external
		view
		virtual
		override
		returns (uint256)
	{
		uint256 totalSupply = IERC20(registry().registries("Dev"))
			.totalSupply();
		uint256 assets = _assets > presumptiveAssets
			? _assets
			: presumptiveAssets;
		return
			curveRewards(_lockups, assets, totalSupply, mintPerSecondAndAsset);
	}

	function holdersShare(uint256 _reward, uint256 _lockups)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _lockups > 0 ? (_reward * 51) / 100 : _reward;
	}

	function authenticationFee(uint256 _assets, uint256 _propertyAssets)
		external
		view
		virtual
		override
		returns (uint256)
	{
		uint256 a = _assets / 10000;
		uint256 b = _propertyAssets / 100000000000000000000000;
		if (a <= b) {
			return 0;
		}
		return a - b;
	}

	function shareOfTreasury(uint256 _supply)
		external
		pure
		override
		returns (uint256)
	{
		return (_supply / 100) * 5;
	}
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

import "../../../interface/IAddressRegistry.sol";

/**
 * Module for using AddressRegistry contracts.
 */
abstract contract UsingRegistry {
	address private _registry;

	/**
	 * Initialize the argument as AddressRegistry address.
	 */
	constructor(address _addressRegistry) {
		_registry = _addressRegistry;
	}

	/**
	 * Returns the latest AddressRegistry instance.
	 */
	function registry() internal view returns (IAddressRegistry) {
		return IAddressRegistry(_registry);
	}

	/**
	 * Returns the AddressRegistry address.
	 */
	function registryAddress() external view returns (address) {
		return _registry;
	}
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

contract Curve {
	uint256 private constant BASIS = 10000000000000000000000000;
	uint256 private constant POWER_BASIS = 10000000000;

	/**
	 * @dev From the passed variables, calculate the amount of reward reduced along the curve.
	 * @param _lockups Total number of locked up tokens.
	 * @param _assets Total number of authenticated assets.
	 * @param _totalSupply Total supply the token.
	 * @param _mintPerBlockAndAseet Maximum number of reward per block per asset.
	 * @return Calculated reward amount per block per asset.
	 */
	function curveRewards(
		uint256 _lockups,
		uint256 _assets,
		uint256 _totalSupply,
		uint256 _mintPerBlockAndAseet
	) internal pure returns (uint256) {
		uint256 t = _totalSupply;
		uint256 s = (_lockups * BASIS) / t;
		uint256 assets = _assets * (BASIS - s);
		uint256 max = assets * _mintPerBlockAndAseet;
		uint256 _d = BASIS - s;
		uint256 _p = ((POWER_BASIS * 12) - (s / (BASIS / (POWER_BASIS * 10)))) /
			2;
		uint256 p = _p / POWER_BASIS;
		uint256 rp = p + 1;
		uint256 f = _p - (p * POWER_BASIS);
		uint256 d1 = _d;
		uint256 d2 = _d;
		for (uint256 i = 0; i < p; i++) {
			d1 = (d1 * _d) / BASIS;
		}
		for (uint256 i = 0; i < rp; i++) {
			d2 = (d2 * _d) / BASIS;
		}
		uint256 g = ((d1 - d2) * f) / POWER_BASIS;
		uint256 d = d1 - g;
		uint256 mint = max * d;
		mint = mint / BASIS / BASIS;
		return mint;
	}
}

// SPDX-License-Identifier: MPL-2.0
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

interface IPolicy {
	function rewards(uint256 _lockups, uint256 _assets)
		external
		view
		returns (uint256);

	function holdersShare(uint256 _amount, uint256 _lockups)
		external
		view
		returns (uint256);

	function authenticationFee(uint256 _assets, uint256 _propertyAssets)
		external
		view
		returns (uint256);

	function marketVotingSeconds() external view returns (uint256);

	function policyVotingSeconds() external view returns (uint256);

	function shareOfTreasury(uint256 _supply) external view returns (uint256);
}

// SPDX-License-Identifier: MPL-2.0
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

interface IAddressRegistry {
	function setRegistry(string memory _key, address _addr) external;

	function registries(string memory _key) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}