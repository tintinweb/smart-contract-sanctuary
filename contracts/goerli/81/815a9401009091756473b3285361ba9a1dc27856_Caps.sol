// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "../ERC20.sol";
import "../ContextMixin.sol";

contract Caps is ERC20, ContextMixin {
    string public constant override name     = "CAPS";
    string public constant override symbol   = "CAPS";
    uint8  public constant override decimals = 18;

    function _msgSender() internal view returns (address payable sender){
        return ContextMixin.msgSender();
    }
}