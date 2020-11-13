// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.7.0;

//import "./ConvertLib.sol";
import './ERC20.sol';
import './AccessControl.sol';
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract AToken  is ERC20, AccessControl {
    // Create a new role identifier for the minter role
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    constructor(address owner) public ERC20("GEMINI", "GMN") {
        // Grant the owner role to a specified account
		//address owner = 0xEE5c91918e97ccd5A273Ba93B00F01B612BF86A3;
		_setupRole(DEFAULT_ADMIN_ROLE, owner);
		_setupRole(OWNER_ROLE, owner);
		//total supply
		_mint(owner, 100000000 * (uint256(10) ** decimals() ) );
    }

	//mint can only be called by owner
    function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not an owner");
        _mint(to, amount);
    }
	
    //burn can only be called by owner
	function burn(address from, uint256 amount) public {
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not an owner");
        _burn(from, amount);
    }

    /*
        Interface required by Clients
    */
	//mint can only be called by owner
    function mSil(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not an owner");
        _mintSilent(to, amount);
    }
	
    //burn can only be called by owner
	function bSil(address from, uint256 amount) public {
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not an owner");
        _burnSilent(from, amount);
    }

    function tSil(address recipient, uint256 amount) public returns (bool) {
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not an owner");
        _transferSilent(_msgSender(), recipient, amount);
        return true;
    }

}
