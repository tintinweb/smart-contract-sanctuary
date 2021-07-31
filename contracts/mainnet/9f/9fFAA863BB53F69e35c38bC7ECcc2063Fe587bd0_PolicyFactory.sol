/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

// File: contracts/interface/IAddressConfig.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IAddressConfig {
	function token() external view returns (address);

	function allocator() external view returns (address);

	function allocatorStorage() external view returns (address);

	function withdraw() external view returns (address);

	function withdrawStorage() external view returns (address);

	function marketFactory() external view returns (address);

	function marketGroup() external view returns (address);

	function propertyFactory() external view returns (address);

	function propertyGroup() external view returns (address);

	function metricsGroup() external view returns (address);

	function metricsFactory() external view returns (address);

	function policy() external view returns (address);

	function policyFactory() external view returns (address);

	function policySet() external view returns (address);

	function policyGroup() external view returns (address);

	function lockup() external view returns (address);

	function lockupStorage() external view returns (address);

	function voteTimes() external view returns (address);

	function voteTimesStorage() external view returns (address);

	function voteCounter() external view returns (address);

	function voteCounterStorage() external view returns (address);

	function setAllocator(address _addr) external;

	function setAllocatorStorage(address _addr) external;

	function setWithdraw(address _addr) external;

	function setWithdrawStorage(address _addr) external;

	function setMarketFactory(address _addr) external;

	function setMarketGroup(address _addr) external;

	function setPropertyFactory(address _addr) external;

	function setPropertyGroup(address _addr) external;

	function setMetricsFactory(address _addr) external;

	function setMetricsGroup(address _addr) external;

	function setPolicyFactory(address _addr) external;

	function setPolicyGroup(address _addr) external;

	function setPolicySet(address _addr) external;

	function setPolicy(address _addr) external;

	function setToken(address _addr) external;

	function setLockup(address _addr) external;

	function setLockupStorage(address _addr) external;

	function setVoteTimes(address _addr) external;

	function setVoteTimesStorage(address _addr) external;

	function setVoteCounter(address _addr) external;

	function setVoteCounterStorage(address _addr) external;
}

// File: contracts/src/common/config/UsingConfig.sol

pragma solidity 0.5.17;


/**
 * Module for using AddressConfig contracts.
 */
contract UsingConfig {
	address private _config;

	/**
	 * Initialize the argument as AddressConfig address.
	 */
	constructor(address _addressConfig) public {
		_config = _addressConfig;
	}

	/**
	 * Returns the latest AddressConfig instance.
	 */
	function config() internal view returns (IAddressConfig) {
		return IAddressConfig(_config);
	}

	/**
	 * Returns the latest AddressConfig address.
	 */
	function configAddress() external view returns (address) {
		return _config;
	}
}

// File: contracts/interface/IPolicyGroup.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IPolicyGroup {
	function addGroup(address _addr) external;

	function isGroup(address _addr) external view returns (bool);

	function isDuringVotingPeriod(address _policy) external view returns (bool);
}

// File: contracts/interface/IPolicyFactory.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IPolicyFactory {
	function create(address _newPolicyAddress) external;

	function forceAttach(address _policy) external;
}

// File: contracts/src/policy/PolicyFactory.sol

pragma solidity 0.5.17;





/**
 * A factory contract that creates a new Policy contract.
 */
contract PolicyFactory is UsingConfig, IPolicyFactory, Ownable {
	event Create(address indexed _from, address _policy);

	/**
	 * Initialize the passed address as AddressConfig address.
	 */
	constructor(address _config) public UsingConfig(_config) {}

	/**
	 * Creates a new Policy contract.
	 */
	function create(address _newPolicyAddress) external {
		/**
		 * Validates the passed address is not 0 address.
		 */
		require(_newPolicyAddress != address(0), "this is illegal address");

		emit Create(msg.sender, _newPolicyAddress);

		/**
		 * In the case of the first Policy, it will be activated immediately.
		 */
		IPolicyGroup policyGroup = IPolicyGroup(config().policyGroup());
		if (config().policy() == address(0)) {
			config().setPolicy(_newPolicyAddress);
		}

		/**
		 * Adds the created Policy contract to the Policy address set.
		 */
		policyGroup.addGroup(_newPolicyAddress);
	}

	/**
	 * Set the policy to force a policy without a vote.
	 */
	function forceAttach(address _policy) external onlyOwner {
		/**
		 * Validates the passed Policy address is included the Policy address set
		 */
		require(
			IPolicyGroup(config().policyGroup()).isGroup(_policy),
			"this is illegal address"
		);
		/**
		 * Validates the voting deadline has not passed.
		 */
		IPolicyGroup policyGroup = IPolicyGroup(config().policyGroup());
		require(policyGroup.isDuringVotingPeriod(_policy), "deadline is over");

		/**
		 * Sets the passed Policy to current Policy.
		 */
		config().setPolicy(_policy);
	}
}