/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Lottery
{
    address payable public manager;
    address payable[] public players;

    constructor()
    {
        manager = payable(msg.sender);
    }

    function enter() public payable
    {
        require(msg.value > .01 ether);

        players.push(payable(msg.sender));
    }

    function pickWinner() public restricted
    {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    function random() private view returns (uint)
    {
        // Pseudo number generator 
        return uint(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty, 
                            block.timestamp, 
                            players
                        )
                    )
                );
    }

    function getPlayers() public view returns(address payable[] memory)
    {
        return players;
    }

    // function modifier is used to reducer 
    // a lot of code from the contract. A developer
    // needs to attach the name of the modifier to the function.
    // This will execute the code of the modifier in the the function that
    // references the modifier
    modifier restricted()
    {
        // simpler version of if conditional
        // if(msg.sender != manager)
        //     return;
        require(msg.sender == manager);

        // end if a modifier. Compiler takes all the code from that function that references
        // the modifier and replace the underscore with the code.
        _;
    }
}