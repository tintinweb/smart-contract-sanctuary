/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: GasEating.sol

contract GasEater {
    uint256 constant MIN_COMMIT = 21000 + 396; // TX cost + initial gas spent reaching assignment of token_amt
    uint256 constant MIN_FINAL = 1110; // Required gas for finalizing mint
    uint256 constant MIN_WITH_NON_ZERO = 5000 + MIN_FINAL;
    uint256 constant MIN_WITH_ZERO = 20000 + MIN_FINAL;

    mapping(address => uint256) public _balances;

    function burn(uint256 start, uint256 end) internal {
        while (gasleft() <= start && gasleft() > end) {}
    }

    function mint() public returns (uint256) {
        uint256 token_amt = gasleft() + MIN_COMMIT;
        burn(
            token_amt,
            (_balances[msg.sender] == 0 ? MIN_WITH_ZERO : MIN_WITH_NON_ZERO)
        );
        _balances[msg.sender] += token_amt;

        return token_amt;
    }
}