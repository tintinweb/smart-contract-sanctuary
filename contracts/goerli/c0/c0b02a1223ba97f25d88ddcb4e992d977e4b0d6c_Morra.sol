/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// Smart contract address: 
// 17CS30026
// Praagy Rastogi

pragma solidity >=0.7.0 <0.9.0;

contract Morra {

    uint256 constant MIN_BET = 1e15; // 1e15 gwei = 10^-3 ether
    address payable player1;
    address payable player2;
    uint initState;
    uint256 betAmount; 
    bytes32 hash1;
    bytes32 hash2;
    uint p1commit;
    uint p2commit;
    int move1=-1;
    int move2=-1;
    

    function initialize() public payable returns (uint){
        
        if (msg.value <= MIN_BET) {
            payback();
            return 0;
        }
        
        if (initState == 0) { // contract is in reset state
            player1 = payable(msg.sender);
            betAmount += msg.value;
            initState = 1;
            return 1;
        }
        else if (initState == 1) { // player1 has already initialized
            if (msg.sender == player1 || msg.value < betAmount) {
                payback();
                return 0;
            }
            player2 = payable(msg.sender);
            betAmount += msg.value;
            initState = 2;
            return 2;
        }
        else{ // both players have initialized
            payback();
            return 0;
        }
    }

    function commitmove(bytes32 hashMove) public returns (bool){
        
        if (initState != 2) return false;
        
        if (msg.sender == player1) {
            if (p1commit == 1) return false;
            hash1 = hashMove;
            p1commit = 1;
            return true;
        }
        else if (msg.sender == player2) {
            if (p2commit == 1) return false;
            hash2 = hashMove;
            p2commit = 1;
            return true;
        }
        else return false;
    }
    
    function revealmove(string memory revealedMove) public returns (int) {
        
        if(p1commit != 1 || p2commit != 1) return -1;
        
        if (msg.sender == player1) {
            if (move1 != -1) return -1; // already revealed
            if (sha256(bytes(revealedMove)) != hash1) return -1; // compare sha256 hash
            move1 = getFirstChar(revealedMove);
            if (move1 == -1) return -1;
            
            if (move2 != -1) processBet(); // both players have revealed moves, process bet and reset
            
            return move1;
        }
        else if (msg.sender == player2) {
            if (move2 != -1) return -1; // already revealed
            if (sha256(bytes(revealedMove)) != hash2) return -1; // compare sha256 hash
            move2 = getFirstChar(revealedMove);
            if (move2 == -1) return -1;
            
            if (move1 != -1) processBet(); // both players have revealed moves, process bet and reset
            
            return move2;
        }
        else return -1;
    }

    function getPlayerId() public view returns (uint){
        if (msg.sender == player1) return 1;
        else if (msg.sender == player2) return 2;
        else return 0;
    }

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }
    
    function processBet() private {
        if (move1 == move2) {
            // player 2 wins
            player2.transfer(betAmount);
        }
        else {
            // player 1 wins
            player1.transfer(betAmount);
        }
        
        reset(); // deinitialize state
    }
    
    function payback() private {
        payable(msg.sender).transfer(msg.value);
    }
    
    function getFirstChar(string memory str) private pure returns (int) {
        if (bytes(str)[0] == 0x30) {
            return 0;
        } 
        else if (bytes(str)[0] == 0x31) {
            return 1;
        } 
        else if (bytes(str)[0] == 0x32) {
            return 2;
        } 
        else if (bytes(str)[0] == 0x33) {
            return 3;
        } 
        else if (bytes(str)[0] == 0x34) {
            return 4;
        } 
        else if (bytes(str)[0] == 0x35) {
            return 5;
        } 
        else {
            return -1;
        }
    }
    
    function reset() private {
        delete player1;
        delete player2;
        initState = 0;
        betAmount = 0;
        delete hash1;
        delete hash2;
        p1commit = 0;
        p2commit = 0;
        move1 = -1;
        move2 = -1;
    }

}