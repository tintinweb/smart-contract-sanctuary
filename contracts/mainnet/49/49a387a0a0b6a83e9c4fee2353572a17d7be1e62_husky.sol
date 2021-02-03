pragma solidity ^0.6.6;

import "./ERC20.sol";

contract husky is ERC20 {

    constructor () public ERC20("husky", "husky") {
        _mint(msg.sender, 777777 * (10 ** uint256(decimals())));
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return super.transfer(to, _partialBurn(amount));
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        return super.transferFrom(from, to, _partialBurnTransferFrom(from, amount));
    }

    function _partialBurn(uint256 amount) internal returns (uint256) {
        uint256 burnAmount = amount.div(13);

        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
        }

        return amount.sub(burnAmount);
    }

    function _partialBurnTransferFrom(address _originalSender, uint256 amount) internal returns (uint256) {
        uint256 burnAmount = amount.div(8);

        if (burnAmount > 0) {
            _burn(_originalSender, burnAmount);
        }

        return amount.sub(burnAmount);
    }

}