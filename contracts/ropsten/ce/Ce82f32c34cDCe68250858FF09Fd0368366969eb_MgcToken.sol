// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC20Pausable.sol";
import "./ERC20.sol";

contract MgcToken is ERC20, Pausable, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    address minter = msg.sender;
    address burner = msg.sender;

    uint public INITIAL_SUPPLY = 21000000;

    constructor() ERC20("MGC TOKEN", "MGCT"){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, INITIAL_SUPPLY * 10 ** (uint(decimals())));
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE){
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE){
        _burn(from, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}