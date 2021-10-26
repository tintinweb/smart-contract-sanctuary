// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./ERC20.sol";

contract RunwayPoints is ERC20, Ownable {
    address private _acquisitionRoyale;

    constructor(address _newAcquisitionRoyale)
        ERC20(string("Runway Points (prePO Acquisition Royale)"), string("RP"))
    {
        _acquisitionRoyale = _newAcquisitionRoyale;
        transferOwnership(_newAcquisitionRoyale);
        _mint(msg.sender, 1e24);
    }

    /// @dev this is not part of the ERC20 standard, so we can just make this an onlyOwner function for simplicity.
    function mint(address _recipient, uint256 _amount) external onlyOwner {
        _mint(_recipient, _amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (_msgSender() != owner()) {
            super.transferFrom(sender, recipient, amount);
        } else {
            _transfer(sender, recipient, amount);
        }
        return true;
    }

    /// @dev this is not part of the ERC20 standard, so we can just make this an onlyOwner function for simplicity.
    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}