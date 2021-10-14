pragma solidity ^0.5.14;

import "./BEP20.sol";
import "./MinterRole.sol";

/**
 * @title BEP20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * 
 *
 * Example inherits from basic BEP20 implementation but can be modified to
 * extend from other IBEP20-based tokens:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1536
 */
contract MYRA is BEP20, MinterRole {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalsupply;

    constructor (string memory name, string memory symbol, uint8 decimals, uint256 totalsupply, address _maddress) public {
	owner = msg.sender;
	minter = _maddress;
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalsupply = totalsupply;

    }



    event Deposit(address useraddr, uint256 amount, uint256 time);
    event Withdraw(address useraddr, uint256 amount, uint256 time);
    event Freeze(address useraddr, uint256 amount, uint256 time);
    event UnFreeze(address useraddr, uint256 amount, uint256 time);

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol_ of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
    * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The address which you want to send tokens from
     * @param value uint256 The amount of token to be burned
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
    
}