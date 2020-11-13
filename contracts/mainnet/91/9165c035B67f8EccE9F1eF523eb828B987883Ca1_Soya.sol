// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 < 0.7.0;

import "./ERC20.sol";
import "./MinterRole.sol";

contract Soya is ERC20, MinterRole {

    string public constant name = 'SoyaToken';
    string public constant symbol = 'SOY';
    uint8 public constant decimals = 8;

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}