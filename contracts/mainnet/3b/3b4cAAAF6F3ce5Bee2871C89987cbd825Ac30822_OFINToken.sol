// SPDX-License-Identifier: Copyright@ofin.io
/**
 * ░▄▀▄▒█▀░█░█▄░█░░░▀█▀░▄▀▄░█▄▀▒██▀░█▄░█
 * ░▀▄▀░█▀░█░█▒▀█▒░░▒█▒░▀▄▀░█▒█░█▄▄░█▒▀█
 * 
 * URL: https://ofin.io/
 * Symbol: ON
 * 
 */
 
pragma solidity 0.6.12;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";


/**
 * @dev {ERC20} token, including:
 *
 *  - a pauser role that allows to stop all token transfers, minting and burning
 *  - a minter role that allows for token minting (creation)
 *  - ability for holders to burn (destroy) their tokens
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted pauser, minter and burner
 * roles, as well as the default admin role, which can be reallocated to a different address
 * 
 */
contract OFINToken is ERC20, ERC20Capped, ERC20Pausable, ERC20Burnable, AccessControl {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    using SafeMath for uint256;
    
    constructor() ERC20("OFIN TOKEN", "ON") ERC20Capped(7777777*10**18) public {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

    //    _mint(_msgSender(),1944447*10**18);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Capped, ERC20Pausable) {

        if( !(from == address(0) || to == address(0)) ) {
            require(!paused(), "ERC20Pausable: token transfer while paused");
            super._beforeTokenTransfer(from, to, amount);
        } else {
            ERC20Capped._beforeTokenTransfer(from, to, amount);
        }

    }
    
    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE` and only admin can mint to self.
     * - Supply should not exceed max allowed token supply
     */
    function mint(address to, uint256 amount) public virtual {

        require(hasRole(MINTER_ROLE, _msgSender()), "OFINToken: must have minter role to mint");
        
        if (to == _msgSender()) {
            require(hasRole(MINTER_ROLE, _msgSender()), "OFINToken: must have minter role to mint to self");
        }
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers, minting and burning.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "OFINToken: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers, minting and burning.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "OFINToken: must have pauser role to unpause");
        _unpause();
    }

    /**
     * @dev Override burnFrom for minter only.
     *
     *
     * Requirements:
     *
     * - the caller must have the `BURNER_ROLE`.
     */
    function burnFrom(address account, uint256 amount) public virtual override {
        require(hasRole(BURNER_ROLE, _msgSender()), "OFINToken: must have burner role to burnFrom");
        super.burnFrom(account, amount);
    }

    /**
     * @dev Grant minter role.
     *
     *
     * Requirements:
     *
     * - the caller must have the admin role.
     */
    function grantMinterRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "OFINToken: sender must be an admin to grant");
        grantRole(MINTER_ROLE, account);
    }

    /**
     * @dev Grant burner role.
     *
     *
     * Requirements:
     *
     * - the caller must have the admin role.
     */
    function grantBurnerRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "OFINToken: sender must be an admin to grant");
        super.grantRole(BURNER_ROLE, account);
    }

    /**
     * @dev Grant pauser role.
     *
     * Requirements:
     *
     * - the caller must have the admin role.
     */
    function grantPauserRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "OFINToken: sender must be an admin to grant");
        grantRole(PAUSER_ROLE, account);
    }
}