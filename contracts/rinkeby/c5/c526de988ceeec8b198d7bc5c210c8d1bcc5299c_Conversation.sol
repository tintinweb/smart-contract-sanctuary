/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

//           .       .                   .       .      .     .      .
//           .    .         .    .            .     ______
//       .           .             .               ////////
//                 .    .   ________   .  .      /////////     .    .
//           .            |.____.  /\        ./////////    .
//     .                 .//      \/  |\     /////////
//       .       .    .//          \ |  \ /////////       .     .   .
//                     ||.    .    .| |  ///////// .     .
//      .    .         ||           | |//`,/////                .
//              .       \\        ./ //  /  \/   .
//   .                    \\.___./ //\` '   ,_\     .     .
//           .           .     \ //////\ , /   \                 .    .
//                       .    ///////// \|  '  |    .
//       .        .          ///////// .   \ _ /          .
//                         /////////                              .
//                  .   ./////////     .     .
//          .           --------   .                  ..             .
//   .               .        .         .                       .
//                         ________________________
// ____________------------                        -------------_________


// SPDX-License-Identifier: Unlicense

pragma solidity^0.8.7;

contract Conversation {
    event Message(string indexed message);
    
    string public lastMessage;
    address public whitelisted;
    address public owner;
    
    constructor() {
        owner = msg.sender;
        whitelisted = msg.sender;
    }
    
    function overwriteWhitelist(address respondee) public {
        require(msg.sender == owner, "You are not my father");
        whitelisted = respondee;
    }
    
    function reply(string memory message, address respondee) public {
        require(msg.sender == whitelisted, "This is not your conversation");
        lastMessage = message;
        whitelisted = respondee;
        
        emit Message(message);
    }
}