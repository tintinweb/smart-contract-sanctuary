/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.4.99;

contract Bet{

    uint256 public minimumBet;

    address private constant house = 0x2A1Db54C108b6889aAadcBA62eD5E65b90C70bC6;

    uint256 public comission;

    struct Player{
        uint256 amountBet;
        uint16 teamSelected;
        uint256 roomId;
    }
    address payable[] public players;

    mapping(address => Player) public playerInfo;

    constructor(){
        minimumBet=10000000000000000;
        comission=1000000000000000;
        
    }
    function checkPlayerExists(address player) public view returns(bool) {
        for(uint256 i = 0; i < players.length; i++){
            if(players[i] == player) return true;
        }
        return false;
    }
    function bet(uint8  _teamSelected,uint256 _roomId) public payable {
        require(!checkPlayerExists(msg.sender));
        require(msg.value == minimumBet);
        playerInfo[msg.sender].teamSelected = _teamSelected;
        playerInfo[msg.sender].amountBet=msg.value;
        playerInfo[msg.sender].roomId=_roomId;
        players.push(payable(msg.sender));
    }
    function getRoomFunds(uint16 teamWinner,uint256 roomId) public payable{
        require(checkPlayerExists(msg.sender));
        address payable playerAddress;
        for(uint256 i = 0; i < players.length; i++){
            playerAddress = players[i];
            
            if(playerInfo[playerAddress].roomId==roomId)
            {
                if(playerInfo[playerAddress].teamSelected==teamWinner)
                {
                    if(playerAddress==msg.sender)
                    {
                        playerAddress.transfer((minimumBet*2)-(comission*2));
                        payable(house).transfer(comission*2);
                        delete playerInfo[playerAddress];
                        delete players[i];
                    }
                }else{
                    delete playerInfo[playerAddress];
                    delete players[i];
                }

            }
         
        }
        
        
    }
}