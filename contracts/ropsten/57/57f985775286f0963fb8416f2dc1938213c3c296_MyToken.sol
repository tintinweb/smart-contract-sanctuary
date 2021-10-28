pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * @title MyToken
 * @dev ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract MyToken is ERC20 {

    uint256 private _minimumSupply = 2000 * (10 ** 18);

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20("RICBRN", "RCB") {
        _mint(msg.sender, 2000000000 * (10 ** uint256(decimals())));
    }

    function transfer(address to, uint256 amount) override public returns (bool) {
        return super.transfer(to, _partialBurn(amount));
    }

    function transferFrom(address from, address to, uint256 amount) override public returns (bool) {
        return super.transferFrom(from, to, _partialBurn(amount));
    }

    function _partialBurn(uint256 amount) internal returns (uint256) {
        uint256 burnAmount = _calculateBurnAmount(amount);

        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
        }

        return amount-burnAmount;
    }

    function _calculateBurnAmount(uint256 amount) internal view returns (uint256) {
        uint256 burnAmount = 0;

        // burn amount calculations
        if (totalSupply() > _minimumSupply) {
            burnAmount = amount/100000;
            uint256 availableBurn = totalSupply()-_minimumSupply;
            if (burnAmount > availableBurn) {
                burnAmount = availableBurn;
            }
        }

        return burnAmount;
    }
}