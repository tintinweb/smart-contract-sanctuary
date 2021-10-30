// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./lib/OwnerManagable.sol";

contract MintAuthorization is OwnerManagable {
    address public immutable layer2;

    constructor(
        address _owner,
        address _layer2,
        address[] memory _initialMinters,
        address[] memory _initialUpdaters
    ) {
        // Initially allow the deploying account to add minters/updaters
        owner = msg.sender;

        layer2 = _layer2;

        for (uint256 i = 0; i < _initialMinters.length; i++) {
            addActiveMinter(_initialMinters[i]);
        }

        for (uint256 i = 0; i < _initialUpdaters.length; i++) {
            addUpdater(_initialUpdaters[i]);
        }

        // From now on, only the specified owner can add/remove minters/updaters
        owner = _owner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./AddressSet.sol";
import "./Claimable.sol";

contract OwnerManagable is Claimable, AddressSet {
    bytes32 internal constant MINTER = keccak256("__MINTERS__");
    bytes32 internal constant RETIREDMINTER = keccak256("__RETIREDMINTERS__");
    bytes32 internal constant UPDATER = keccak256("__UPDATER__");

    event MinterAdded(address indexed minter);
    event MinterRetired(address indexed minter);
    event UpdaterAdded(address indexed updater);
    event UpdaterRemoved(address indexed updater);

    // All address that are currently authorized to mint NFTs on L2.
    function activeMinters() public view returns (address[] memory) {
        return addressesInSet(MINTER);
    }

    // All address that were previously authorized to mint NFTs on L2.
    function retiredMinters() public view returns (address[] memory) {
        return addressesInSet(RETIREDMINTER);
    }

    // All address that are authorized to add new collections.
    function updaters() public view returns (address[] memory) {
        return addressesInSet(UPDATER);
    }

    function numActiveMinters() public view returns (uint256) {
        return numAddressesInSet(MINTER);
    }

    function numRetiredMinters() public view returns (uint256) {
        return numAddressesInSet(RETIREDMINTER);
    }

    function numUpdaters() public view returns (uint256) {
        return numAddressesInSet(UPDATER);
    }

    function isActiveMinter(address addr) public view returns (bool) {
        return isAddressInSet(MINTER, addr);
    }

    function isRetiredMinter(address addr) public view returns (bool) {
        return isAddressInSet(RETIREDMINTER, addr);
    }

    function isUpdater(address addr) public view returns (bool) {
        return isAddressInSet(UPDATER, addr);
    }

    function addActiveMinter(address minter) public virtual onlyOwner {
        addAddressToSet(MINTER, minter, true);
        if (isRetiredMinter(minter)) {
            removeAddressFromSet(RETIREDMINTER, minter);
        }
        emit MinterAdded(minter);
    }

    function addUpdater(address updater) public virtual onlyOwner {
        addAddressToSet(UPDATER, updater, true);
        emit UpdaterAdded(updater);
    }

    function removeUpdater(address updater) public virtual onlyOwner {
        removeAddressFromSet(UPDATER, updater);
        emit UpdaterRemoved(updater);
    }

    function retireMinter(address minter) public virtual onlyOwner {
        removeAddressFromSet(MINTER, minter);
        addAddressToSet(RETIREDMINTER, minter, true);
        emit MinterRetired(minter);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract AddressSet {
    struct Set {
        address[] addresses;
        mapping(address => uint256) positions;
        uint256 count;
    }
    mapping(bytes32 => Set) private sets;

    function addAddressToSet(
        bytes32 key,
        address addr,
        bool maintainList
    ) internal {
        Set storage set = sets[key];
        require(set.positions[addr] == 0, "ALREADY_IN_SET");

        if (maintainList) {
            require(
                set.addresses.length == set.count,
                "PREVIOUSLY_NOT_MAINTAILED"
            );
            set.addresses.push(addr);
        } else {
            require(set.addresses.length == 0, "MUST_MAINTAIN");
        }

        set.count += 1;
        set.positions[addr] = set.count;
    }

    function removeAddressFromSet(bytes32 key, address addr) internal {
        Set storage set = sets[key];
        uint256 pos = set.positions[addr];
        require(pos != 0, "NOT_IN_SET");

        delete set.positions[addr];
        set.count -= 1;

        if (set.addresses.length > 0) {
            address lastAddr = set.addresses[set.count];
            if (lastAddr != addr) {
                set.addresses[pos - 1] = lastAddr;
                set.positions[lastAddr] = pos;
            }
            set.addresses.pop();
        }
    }

    function isAddressInSet(bytes32 key, address addr)
        internal
        view
        returns (bool)
    {
        return sets[key].positions[addr] != 0;
    }

    function numAddressesInSet(bytes32 key) internal view returns (uint256) {
        Set storage set = sets[key];
        return set.count;
    }

    function addressesInSet(bytes32 key)
        internal
        view
        returns (address[] memory)
    {
        Set storage set = sets[key];
        require(set.count == set.addresses.length, "NOT_MAINTAINED");
        return sets[key].addresses;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./Ownable.sol";

// Extension for the Ownable contract, where the ownership needs
// to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable {
    address public pendingOwner;

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

// The Ownable contract has an owner address, and provides basic
// authorization control functions, this simplifies the implementation of
// "user permissions". Subclasses are responsible for initializing the
// `owner` property (it is not done in a constructor to faciliate use of
// a factory proxy pattern).
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}