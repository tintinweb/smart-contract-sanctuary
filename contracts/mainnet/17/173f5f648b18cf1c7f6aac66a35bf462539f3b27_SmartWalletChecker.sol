// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

contract SmartWalletChecker {
    
    address constant public yearn = address(0xF147b8125d2ef93FB6965Db97D6746952a133934);
    
    function check(address _wallet) external pure returns (bool) {
        return _wallet == yearn;
    }
}