// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Proxiable.sol";
import "./ISeriesVault.sol";

/// @title ISeriesVault
/// @author The Siren Devs
/// @notice Interface to interact with a SeriesVault
/// @dev The SeriesVault can store multiple SeriesController's tokens
/// @dev Never send ERC20 tokens directly to this contract with ERC20.safeTransfer*.
/// Always use the SeriesController.transfer*In/transfer*Out functions
/// @dev EIP-1155 functions are OK to use as is, because no 2 Series trade the same wToken,
/// whereas multiple Series trade the same ERC20 (see the warning above)
/// @dev The SeriesController should be the only contract interacting with the SeriesVault
contract SeriesVault is
    ISeriesVault,
    ERC1155HolderUpgradeable,
    Proxiable,
    OwnableUpgradeable
{
    /** Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20Upgradeable for IERC20;

    /// @dev The addresses of the SeriesController contract which will be approved
    /// with an allowance of MAX_UINT for all tokens held in the SeriesVault
    address internal controller;

    ///////////////////// EVENTS /////////////////////

    /// @notice Emitted when the SeriesVault is initialized
    event SeriesVaultInitialized(address controller);

    ///////////////////// MODIFIER FUNCTIONS /////////////////////

    /// @notice Check if the msg.sender is the privileged SeriesController contract address
    modifier onlySeriesController() {
        require(
            msg.sender == controller,
            "SeriesVault: Sender must be the seriesController"
        );

        _;
    }

    ///////////////////// MUTATING FUNCTIONS /////////////////////

    /// @notice Perform inherited contracts' initializations
    function __SeriesVault_init(address _seriesController)
        external
        initializer
    {
        __ERC1155Holder_init();
        __Ownable_init_unchained();

        require(
            _seriesController != address(0x0),
            "SeriesVault: _seriesController cannot be the 0x0 address"
        );

        controller = _seriesController;

        emit SeriesVaultInitialized(_seriesController);
    }

    /// @notice Allow the SeriesController to transfer MAX_UINT of the given ERC20 token from the SeriesVault
    /// @dev Can only be called by the seriesController
    /// @param erc20Token An ERC20-compatible token
    function setERC20ApprovalForController(address erc20Token)
        external
        override
        onlySeriesController
    {
        // try to save some gas by only using an SSTORE if the allowance has not
        // already been set
        if (IERC20(erc20Token).allowance(address(this), controller) == 0) {
            // the allowance hasn't been, so let's set it
            IERC20(erc20Token).approve(controller, type(uint256).max);
        }
    }

    /// @notice Allow the SeriesController to transfer any number of ERC1155 tokens from the SeriesVault
    /// @dev Can only be called by the seriesController
    /// @dev The ERC1155 tokens will be minted and burned by the ERC1155Controller contract
    function setERC1155ApprovalForController(address erc1155Contract)
        external
        override
        onlySeriesController
        returns (bool)
    {
        IERC1155Upgradeable(erc1155Contract).setApprovalForAll(
            controller,
            true
        );
    }

    /// @notice update the logic contract for this proxy contract
    /// @param _newImplementation the address of the new SeriesVault implementation
    /// @dev only the admin address may call this function
    function updateImplementation(address _newImplementation)
        external
        onlyOwner
    {
        _updateCodeAddress(_newImplementation);
    }
}