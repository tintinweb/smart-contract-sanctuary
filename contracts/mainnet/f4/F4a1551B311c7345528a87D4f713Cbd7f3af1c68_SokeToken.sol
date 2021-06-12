// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//
//
//                    ┌─┐       ┌─┐ + +
//                    ┌──┘ ┴───────┘ ┴──┐++
//                    │                 │
//                    │       ───       │++ + + +
//                    ███████───███████ │+
//                    │                 │+
//                    │       ─┴─       │
//                    │                 │
//                    └───┐         ┌───┘
//                    │         │
//                    │         │   + +
//                    │         │
//                    │         └──────────────┐
//                    │                        │
//                    │                        ├─┐
//                    │                        ┌─┘
//                    │                        │
//                    └─┐  ┐  ┌───────┬──┐  ┌──┘  + + + +
//                    │ ─┤ ─┤       │ ─┤ ─┤
//                    └──┴──┘       └──┴──┘  + + + +


import "./BEP20.sol";

contract SokeToken is BEP20('Soke', 'SOKE', 100000000000000000000000000) {


function getChainId() internal pure returns (uint) {
uint256 chainId;
assembly { chainId := chainid() }
return chainId;
}
}