/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;
// import "hardhat/console.sol";
contract AnimalChess {
    address admins;
    mapping (address => bool) private owners;
    mapping(string=>GameRoom) public play_list;

    enum animalType {
        animal1,
        animal2,
        animal3,
        animal4,
        animal5,
        animal6,
        animal7,
        animal8
    }

    enum winner {
        A,
        B,
        none
    }

    struct GameRoom {
        userInfo playA;
        userInfo playB;
        winner Final_Result; // 最後結果
    }

    struct userInfo {
        address player;
        uint[] aniArr;
        uint amount;
    }

    event winnerEvent(uint winnerUint);
    event roomIDEvent(string roomIDUint);
    event animalArrAEvent(uint[] animalArrA);
    event animalArrBEvent(uint[] animalArrB);

    constructor(){
        admins = msg.sender;
    }

    modifier onlyAdmins() {
        require(msg.sender == admins, "Not owner");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    modifier onlyOwners() {
        require(msg.sender == admins || owners[msg.sender], "Not owner");
        _;
    }

    function Init(string memory roomID) public payable{
        userInfo memory deplayer;
        deplayer.player = msg.sender;
        deplayer.amount = msg.value;
        if(play_list[roomID].playA.player == address(0x0)){
            play_list[roomID].playA = deplayer;
        }else{
            require(play_list[roomID].playA.player != deplayer.player," the same player");
            play_list[roomID].playB = deplayer;
        }
    }

    function addOwner(address newOwner) external onlyAdmins validAddress(newOwner){
        owners[newOwner] = true;
    }    

    function struggleAction(string memory roomID , address _addrA , uint[] memory _animalArrA , uint _amountA , address _addrB , uint[] memory _animalArrB , uint _amountB) public onlyOwners {
        require(_animalArrA.length == _animalArrB.length,"_animalArrA.length != _animalArrB.length");
        userInfo memory deplayerA;
        userInfo memory deplayerB;

        deplayerA.aniArr = _animalArrA;
        deplayerA.amount = _amountA;
        deplayerA.player = _addrA;

        deplayerB.aniArr = _animalArrB;
        deplayerB.amount = _amountB;
        deplayerB.player = _addrB;
        
        if (play_list[roomID].playA.player == deplayerA.player){
            play_list[roomID].playA = deplayerA;
            play_list[roomID].playB = deplayerB;
        } else {
            play_list[roomID].playA = deplayerB;
            play_list[roomID].playB = deplayerA;
        }

        animalStruggle(roomID);
    }

    function animalStruggle(string memory roomID) private {
        uint winA = 0;
        uint winB = 0;
        uint[] memory aniA = play_list[roomID].playA.aniArr;
        uint[] memory aniB = play_list[roomID].playB.aniArr;
        for (uint i = 0; i < aniA.length; i++) {

            if (aniA[i] > aniB[i]) {
                winA++;
            } else if (aniB[i] > aniA[i]){
                winB++;
            } 

            if (winA > aniA.length/2 || winB > aniB.length/2) {
                break;
            }

        }
        uint winnerNum;
        if (winA > winB) {
            play_list[roomID].Final_Result = winner.A;
            winnerNum = 1;
        } else if (winB > winA) {
            play_list[roomID].Final_Result = winner.B;
            winnerNum = 2;
        } else if (winA == winB) {
            play_list[roomID].Final_Result = winner.none;
            winnerNum = 0;
        }
        emit winnerEvent(winnerNum);
        emit animalArrAEvent(aniA);
        emit animalArrBEvent(aniB);
        emit roomIDEvent(roomID);
        giveMoney(roomID ,SafeMath.mul(play_list[roomID].playB.amount ,2)); 
    }

    function giveMoney(string memory roomID ,uint totalAmount) public onlyOwners {
        winner result = play_list[roomID].Final_Result;
        if (result == winner.A){
            addValue(play_list[roomID].playA.player,totalAmount);
        } else if (result == winner.B){
            addValue(play_list[roomID].playB.player,totalAmount);
        } else if (result == winner.none){
            addValue(play_list[roomID].playA.player, SafeMath.mod(totalAmount,2));
            addValue(play_list[roomID].playB.player, SafeMath.mod(totalAmount,2));
        }
    }

   function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function addValue(address _to, uint value1) public onlyOwners validAddress(_to) {
        payable(_to).transfer(value1);
    }

}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a); // underflow 
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a); // overflow

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}