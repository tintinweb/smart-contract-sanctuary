//
//                    %(/************/#&
//               (**,                 ,**/#
//            %/*,                        **(&
//          (*,                              //%
//        %*,                                  /(
//       (*      ,************************/      /*%
//      //         /(                  (/,        ,/%
//     (*           //(               //            /%
//    //             */%             //             //
//    /*         (((((///(((( ((((((//(((((,         /(
//    /           ,/%   //        (/    /*           //
//    /             //   //(    %//   (/*            ,/
//    /              //   ,/%   //   (/,             (/
//    /             %(//%   / //    ///(             //
//    //          %(/, ,/(   /   %//  //(           /(
//    (/         (//     /#      (/,     //(        (/
//     ((     %(/,        (/    (/,        //(      /,
//      ((    /,           *(*#(/            /*   %/,
//      /((                 /*((                 ((/
//        *(%                                  #(
//          ((%                              #(,
//            *((%                        #((,
//               (((%                   ((/
//                   *(((###*#&%###((((*
//
//
//                       ROULETTE.GORGONA.IO
//
// Win 120% with 80% chance!
//
//
// HOW TO TAKE PLAY
// Just send 1 ETH to the contract.
// When there are 5 players, a rally will be made, 4 lucky players will receive 1.2 ETH each!
//
//
// For more information visit https://roulette.gorgona.io/
//
// Telegram chat (ru): https://t.me/gorgona_io
// Telegram chat (en): https://t.me/gorgona_io_en
//
// For support and requests telegram: @alex_gorgona_io


pragma solidity ^0.4.24;

contract Roulette {

    event newRound(uint number);
    event newPlayer(address addr, uint roundNumber);
    event playerWin(address indexed addr);
    event playerLose(address indexed addr, uint8 num);

    uint public roundNumber = 1;
    address public feeAddr;

    address[] public players;

    constructor() public
    {
        feeAddr = msg.sender;
    }

    function() payable public
    {
        require(msg.value == 1 ether, "Enter price 1 ETH");
        // save player
        players.push(msg.sender);

        emit newPlayer(msg.sender, roundNumber);

        // if we have all players
        if (players.length == 5) {
            distributeFunds();
            return;
        }
    }

    function countPlayers() public view returns (uint256)
    {
        return players.length;
    }

    // Send ETH to winners
    function distributeFunds() internal
    {
        // determine who is lose
        uint8 loser = uint8(getRandom() % players.length + 1);

        for (uint i = 0; i <= players.length - 1; i++) {
            // if it is loser - skip
            if (loser == i + 1) {
                emit playerLose(players[i], loser);
                continue;
            }

            // pay prize
            if (players[i].send(1200 finney)) {
                emit playerWin(players[i]);
            }
        }

        // gorgona fee
        feeAddr.transfer(address(this).balance);

        players.length = 0;
        roundNumber ++;

        emit newRound(roundNumber);
    }

    function getRandom() internal view returns (uint256)
    {
        uint256 num = uint256(keccak256(abi.encodePacked(blockhash(block.number - players.length), address(this))));

        for (uint i = 0; i <= players.length - 1; i++)
        {
            num ^= uint256(keccak256(abi.encodePacked(blockhash(block.number - i), players[i])));
        }

        return num;
    }
}