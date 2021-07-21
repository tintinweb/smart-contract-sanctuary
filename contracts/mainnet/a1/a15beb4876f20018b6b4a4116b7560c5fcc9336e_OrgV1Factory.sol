// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./OrgV1.sol";

interface SafeFactory {
    function createProxy(address masterCopy, bytes memory data) external returns (Safe);
}

interface Safe {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    function getThreshold() external returns (uint256);
    function isOwner(address owner) external returns (bool);
}

/// Factory for orgs.
contract OrgV1Factory {
    SafeFactory immutable safeFactory;
    address immutable safeMasterCopy;

    /// An org was created. Includes the org and safe address.
    event OrgCreated(address org, address safe);

    constructor(
        address _safeFactory,
        address _safeMasterCopy
    ) {
        safeFactory = SafeFactory(_safeFactory);
        safeMasterCopy = _safeMasterCopy;
    }

    /// Create an org with a specified owner.
    function createOrg(address owner) public returns (OrgV1 org) {
        org = new OrgV1(address(owner));
        emit OrgCreated(address(org), address(owner));
    }

    /// Create an org with multiple owners, via a multi-sig contract. The threshold specifies
    /// how many signatures are required to transact.
    function createOrg(address[] memory owners, uint256 threshold) public returns (OrgV1 org) {
        require(owners.length > 0, "OrgFactory: owners must not be empty");
        require(threshold > 0, "OrgFactory: threshold must be greater than zero");
        require(threshold <= owners.length, "OrgFactory: threshold must be lesser than or equal to owner count");

        // Deploy safe.
        Safe safe = safeFactory.createProxy(safeMasterCopy, new bytes(0));
        safe.setup(owners, threshold, address(0), new bytes(0), address(0), address(0), 0, payable(address(0)));

        // Deploy org
        org = new OrgV1(address(safe));
        emit OrgCreated(address(org), address(safe));
    }
}