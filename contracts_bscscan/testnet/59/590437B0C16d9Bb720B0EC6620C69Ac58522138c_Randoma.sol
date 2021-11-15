// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

contract Randoma {

    function randModa() public view returns (uint)
    {
        return uint(keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender,
                    block.gaslimit,
                    block.number
                )
            )) % 100;
    }
}

