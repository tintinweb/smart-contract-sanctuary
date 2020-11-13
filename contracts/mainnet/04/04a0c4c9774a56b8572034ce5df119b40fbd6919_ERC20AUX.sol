pragma solidity ^0.5.7;

import "./ContactCoinToken.sol";
import "./IERC20.sol";

/**
 * @title Advanced ERC20 token which complements the main token
 *
 * @dev Implementation of the basic standard token plus mint and burn public functions.
 */
contract ERC20AUX is ContactCoinToken, ERC20Burnable, ERC20Mintable, Pausable {

    // maximum capital, if defined > 0
    uint256 private _cap;

    constructor (
        address initialAccount, string memory _tokenSymbol, string memory _tokenName, uint256 initialBalance, uint256 cap,
        bool _burnableOption, bool _mintableOption, bool _pausableOption
    ) public 
        ContactCoinToken(initialAccount, _tokenSymbol, _tokenName, initialBalance) {

        // we must add customer account as the first minter
        addMinter(initialAccount);

        // and this contract must renounce minter role
        renounceMinter();

        // same with pauser
        addPauser(initialAccount);
        renouncePauser();

        if (cap > 0) {
            _cap = cap; // maximum capitalization limited
        } else {
            _cap = 0; // unlimited capitalization
        }
    
        // activate or deactivate options
        _setBurnableActive(_burnableOption);
        _setMintableActive(_mintableOption);
        _setPausableActive(_pausableOption);

    }

    /**
     * @return the cap for the token minting.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * limit the mint to a maximum cap only if cap is defined
     */
    function _mint(address account, uint256 value) internal {
        if (_cap > 0) {
            require(totalSupply().add(value) <= _cap);
        }
        super._mint(account, value);
    }

    /**
     * Pausable options
     */
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from,address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

}