// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract YouWho is
    Context,
    AccessControlEnumerable,
    ERC20Burnable,
    ERC20Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CAP_ROLE = keccak256("CAP_ROLE");
    uint256 private _cap;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(address _1, address _2, address _3, address _4, address _5) ERC20("YouWho", "UHU") {
        _cap = 133700009 * (10**uint256(decimals()));
        _mint(_1, _cap * 15 / 100 );
        _mint(_2, _cap * 11 / 100 );
        _mint(_3, _cap * 11 / 100 );
        _mint(_4, _cap * 11 / 100 );
        _mint(_5, _cap * 11 / 100 );
        _setupRole(DEFAULT_ADMIN_ROLE, _1);
        _setupRole(MINTER_ROLE, _1);
        _setupRole(PAUSER_ROLE, _1);
        _setupRole(CAP_ROLE, _1);
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function changeCap(uint256 newCap) external {
        require(hasRole(CAP_ROLE, _msgSender()),"Error Cap: You must have cap role to change cap");
        require(ERC20.totalSupply() <= newCap,"Error Cap: New cap cant be less than current total supply");        
        _cap = newCap;
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
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()),"Error Mint: You must have minter role to mint");
        require(ERC20.totalSupply() + amount <= cap(),"Error Cap: You have reached the supply cap. Increase cap to continue minting.");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()),"Error Pause: You must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()),"Error Unpause: You must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from,address to,uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}