// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

//     ___                         __ 
//    /   |  _____________  ____  / /_
//   / /| | / ___/ ___/ _ \/ __ \/ __/
//  / ___ |(__  |__  )  __/ / / / /_  
// /_/  |_/____/____/\___/_/ /_/\__/  
// 
// 2022 - Assent Protocol
// Code based on OlympusDAO development

import './SafeMath.sol';
import './ERC20.sol';
import './ERC20Permit.sol';
import './VaultOwned.sol';

contract ASNTToken is ERC20Permit, VaultOwned {

    using SafeMath for uint256;

    // Max supply fixed to 100M ASNT
    uint256 constant MAXCAPSUPPLY = 100_000_000 * (10 ** 9);

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, 9, MAXCAPSUPPLY) {
    }

    function mint(address account_, uint256 amount_) external onlyVault() {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
     
    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }

    function maxSupply() public view returns (uint256) {
        return _maxCapSupply;
    }

}