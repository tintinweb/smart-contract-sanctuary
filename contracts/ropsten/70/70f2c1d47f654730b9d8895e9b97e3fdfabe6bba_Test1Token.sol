// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Ownable.sol";


contract Test1Token is ERC20, AccessControl, Ownable {

    uint public INITIAL_SUPPLY = 100000;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    address minter = msg.sender;
    address burner = msg.sender;

    constructor() public ERC20("TEST1TOKEN", "TTK"){
        _mint(msg.sender, INITIAL_SUPPLY * 10 ** (uint(decimals())));
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
 
    function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        _mint(to, amount);
    } 

    function burn(address from, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        _burn(from,amount);
    }

}