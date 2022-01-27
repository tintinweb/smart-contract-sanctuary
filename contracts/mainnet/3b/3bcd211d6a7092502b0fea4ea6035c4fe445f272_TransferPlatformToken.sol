/*

  << Transfer Platform Token >>

*/

import "./lib/ReentrancyGuarded.sol";

pragma solidity 0.7.5;

contract TransferPlatformToken is ReentrancyGuarded {
    function transferETH(address[] calldata addrs, uint[] calldata amounts) external payable reentrancyGuard returns (bool) {
        require(addrs.length == amounts.length, "transferETH: Addresses and amounts must match in quantity");

        for (uint i = 0; i < amounts.length; i++) {
            address(uint160(addrs[i])).transfer(amounts[i]);
        }

        return true;
    }

    // important to receive ETH
    receive() payable external {}
}

/*

  Simple contract extension to provide a contract-global reentrancy guard on functions.

*/

pragma solidity 0.7.5;

/**
 * @title ReentrancyGuarded
 * @author Wyvern Protocol Developers
 */
contract ReentrancyGuarded {

    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        require(!reentrancyLock, "Reentrancy detected");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}