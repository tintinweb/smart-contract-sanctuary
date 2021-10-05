// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

contract CloutArtToken is ERC20, Pausable, AccessControl {
    uint256 private constant INITIAL_SUPPLY = 100000000 ether;
    uint256 private constant MINTABLE_SUPPLY = 100000000 ether;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool private _allowNewMinters = true;

    constructor(string memory _name, string memory _symbol, address _admin) ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _mint(_admin, INITIAL_SUPPLY);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) external whenNotPaused onlyRole(MINTER_ROLE) {
        require(amount <= INITIAL_SUPPLY + MINTABLE_SUPPLY - totalSupply(), "Amount to big");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function disableNewMinters() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _allowNewMinters = false;
    }

    function grantRole(bytes32 role, address account) public virtual override {
        if (role == MINTER_ROLE)
            require(_allowNewMinters, "Granting new minters not allowed!"); 
        AccessControl.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override {
        if (role == MINTER_ROLE)
            require(_allowNewMinters, "Revoking minters not allowed!"); 
        AccessControl.revokeRole(role, account);
    }
}