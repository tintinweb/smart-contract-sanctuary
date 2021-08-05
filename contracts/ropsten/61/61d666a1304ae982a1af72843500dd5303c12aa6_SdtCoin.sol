/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract SdtCoin is ERC20, Ownable
{
    string private _name = "ISDA Sports Data Token";
    string private _symbol = "SDT";
    uint8 private _decimals = 18;

    event TransferableChanged(bool indexed value);

    /**
     * @dev initialize QRC20(ERC20)
     *
     * all token will deposit into the vault
     *
     * @param _owner  owner address
     */
    constructor (address _owner) {

        owner = _owner;

        // initially all coins to the vault
        uint totalSupply_ = 1000000000 * (10 ** uint(decimals()));
        _mint(owner, totalSupply_);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function burnToken(uint _value) public {
        _burn(msg.sender, _value);
    }

    function setTransferable(bool _value) public onlyOwner {
        isTransferable = _value;
        emit TransferableChanged(_value);
    }
}