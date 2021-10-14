// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// TODO: ROLES
// import "../Roles.sol";
import "../interfaces/IVaultRegistry.sol";

/// @title vault registry
/// @author Carl Farterson (@carlfarterson)
/// @notice Keeps track of all active _vaults and available vault factories
contract VaultRegistry is IVaultRegistry {
    mapping(address => bool) private _vaults;
    // NOTE: _approved vault factories could be for
    // Vanilla erc20 vaults, Uniswap-LP vaults, Balancer LP  vaults, etc.
    mapping(address => bool) private _approved;

    /// @inheritdoc IVaultRegistry
    function register(address _vault) external override {
        require(
            _approved[msg.sender],
            "Only vault factories can register _vaults"
        );

        // Add vault details to storage
        _vaults[_vault] = true;

        emit Register(_vault, msg.sender);
    }

    /// @inheritdoc IVaultRegistry
    function approve(address _factory) external override {
        // TODO: access control
        require(!_approved[_factory], "Factory already _approved");
        _approved[_factory] = true;
        emit Approve(_factory);
    }

    /// @inheritdoc IVaultRegistry
    function deactivate(address _vault) external override {
        // TODO: access control
        require(_vaults[_vault], "Vault not active");
        _vaults[_vault] = false;
        emit Deactivate(_vault);
    }

    /// @inheritdoc IVaultRegistry
    function unapprove(address _factory) external override {
        // TODO: access control
        require(_approved[_factory], "Factory not _approved");
        _approved[_factory] = false;
        emit Unapprove(_factory);
    }

    /// @inheritdoc IVaultRegistry
    function isActive(address _vault) external view override returns (bool) {
        return _vaults[_vault];
    }

    /// @inheritdoc IVaultRegistry
    function isApproved(address _factory)
        external
        view
        override
        returns (bool)
    {
        return _approved[_factory];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IVaultRegistry {
    event Register(address vault, address factory);
    event Deactivate(address vault);
    event Approve(address factory);
    event Unapprove(address factory);

    /// @notice add a vault to the vault registry
    /// @param _vault address of new vault
    function register(address _vault) external;

    /// @notice TODO
    /// @param _factory TODO
    function approve(address _factory) external;

    /// @notice TODO
    /// @param _factory TODO
    function unapprove(address _factory) external;

    /// @notice TODO
    /// @param _factory TODO
    /// @return TODO
    function isApproved(address _factory) external view returns (bool);

    /// @notice TODO
    /// @param _vault TODO
    function deactivate(address _vault) external;

    /// @notice TODO
    /// @param _vault TODO
    /// @return TODO
    function isActive(address _vault) external view returns (bool);
}