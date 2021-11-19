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

contract WalkyTalky {
    event Message(string indexed message);
    
    struct Messages {
        address sender;
        string message;
    }
    
    string public lastMessage;
    address public over;
    address public owner;
    Messages[] public messages;
    
    constructor() {
        owner = msg.sender;
        over = msg.sender;
    }
    
    function respond(string memory message, address respondee) public {
        require(msg.sender == over, "This is not your conversation");
        messages.push(Messages(msg.sender, message));
        lastMessage = message;
        over = respondee;
        
        emit Message(message);
    }
    
    function overwriteRespondee(address newRespondee) public {
        require(msg.sender == owner, "You are not my father");
        over = newRespondee;
    }
}