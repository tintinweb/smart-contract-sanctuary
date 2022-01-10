// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./interfaces/IDepoAuthority.sol";

import "./types/DepoAccessControlled.sol";

contract DepoAuthority is IDepoAuthority, DepoAccessControlled {
    /* ========== STATE VARIABLES ========== */

    address public override guardian;

    address public override policy;

    address public override vault;

    address public newGuardian;

    address public newPolicy;

    address public newVault;

    /* ========== Constructor ========== */

    constructor(
        address _guardian,
        address _policy,
        address _vault
    ) DepoAccessControlled(IDepoAuthority(address(this))) {
        guardian = _guardian;
        emit GuardianPushed(address(0), guardian, true);
        policy = _policy;
        emit PolicyPushed(address(0), policy, true);
        vault = _vault;
        emit VaultPushed(address(0), vault, true);
    }

    /* ========== GOV ONLY ========== */

    function pushGuardian(address _newGuardian, bool _effectiveImmediately)
        external
        onlyGuardian
    {
        if (_effectiveImmediately) guardian = _newGuardian;
        newGuardian = _newGuardian;
        emit GuardianPushed(guardian, newGuardian, _effectiveImmediately);
    }

    function pushPolicy(address _newPolicy, bool _effectiveImmediately)
        external
        onlyGuardian
    {
        if (_effectiveImmediately) policy = _newPolicy;
        newPolicy = _newPolicy;
        emit PolicyPushed(policy, newPolicy, _effectiveImmediately);
    }

    function pushVault(address _newVault, bool _effectiveImmediately)
        external
        onlyGuardian
    {
        if (_effectiveImmediately) vault = _newVault;
        newVault = _newVault;
        emit VaultPushed(vault, newVault, _effectiveImmediately);
    }

    /* ========== PENDING ROLE ONLY ========== */

    function pullGuardian() external {
        require(msg.sender == newGuardian, "!newGuard");
        emit GuardianPulled(guardian, newGuardian);
        guardian = newGuardian;
    }

    function pullPolicy() external {
        require(msg.sender == newPolicy, "!newPolicy");
        emit PolicyPulled(policy, newPolicy);
        policy = newPolicy;
    }

    function pullVault() external {
        require(msg.sender == newVault, "!newVault");
        emit VaultPulled(vault, newVault);
        vault = newVault;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

interface IDepoAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event GuardianPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event PolicyPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event VaultPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IDepoAuthority.sol";

abstract contract DepoAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IDepoAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IDepoAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IDepoAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IDepoAuthority _newAuthority) external onlyGuardian {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}