// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./ISimpleToken.sol";

// Adapted from @openzeppelin/contracts-ethereum-package/contracts/presets/ERC20PresetMinterBurner.sol

/**
 * Simple token that will be used for wTokens and bTokens in the Siren system.
 * Name and symbol are created with an "Initialize" call before the token is set up.
 * Mint and Burn are allowed by the owner.
 * Can be destroyed by owner
 */
contract SimpleToken is
    Initializable,
    AccessControlUpgradeable,
    ERC20BurnableUpgradeable,
    ISimpleToken
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /** Emitted when contract is destroyed */
    event TokenDestroyed();

    /// @dev the number of decimals for this ERC20's human readable numeric
    uint8 internal numDecimals;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `BURNER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public override {
        __ERC20PresetMinterBurner_init(_name, _symbol, _decimals);
    }

    function __ERC20PresetMinterBurner_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal initializer {
        __AccessControl_init();
        __ERC20_init_unchained(_name, _symbol);
        __ERC20Burnable_init_unchained();
        __ERC20PresetMinterBurner_init_unchained();

        numDecimals = _decimals;
    }

    function __ERC20PresetMinterBurner_init_unchained() internal initializer {
        address deployer = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, deployer);

        _setupRole(MINTER_ROLE, deployer);
        _setupRole(BURNER_ROLE, deployer);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual override {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC20PresetMinterBurner: must have minter role to mint"
        );
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from any account.
     *
     * Requirements:
     *
     * - the caller must have the `BURNER_ROLE`.
     * - target account must have the balance to burn
     */
    function burn(address account, uint256 amount) public virtual override {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "ERC20PresetMinterBurner: must have burner role to admin burn"
        );
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public view override(ERC20Upgradeable) returns (uint8) {
        return numDecimals;
    }

    function totalSupply()
        public
        view
        override(ERC20Upgradeable)
        returns (uint256)
    {
        return super.totalSupply();
    }
}