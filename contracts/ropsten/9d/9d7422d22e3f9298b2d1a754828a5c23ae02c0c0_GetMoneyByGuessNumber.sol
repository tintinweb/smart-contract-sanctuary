/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract GetMoneyByGuessNumber {
    uint[9] public board;
    uint [3][8]Combo = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
    bool win;
    // uint256 public rand;
    /*struct Combo{
        uint a1;
        uint a2;
        uint a3;
    }
    
    Combo[] combo;
    combo[0].*/
    
    
    
    
    constructor() public {
        restart();
    }
    
    /*function mylength() public view returns(uint len){
        return Combo.length;
    }*/
    
    function uint2str(uint i) internal pure returns (string c) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        c = string(bstr);
        return c;
    }

    
    function restart()  public{
        win = false;
        for(uint i = 0; i < 9;i++){
            board[i] = 0;
        }
    }
    function checkwin()  private view returns(bool playerwin){
        for(uint i = 0; i < Combo.length;i++){
            if(board[Combo[i][0]]==board[Combo[i][1]]&&board[Combo[i][0]]==board[Combo[i][2]]&&(board[Combo[i][0]] == 1||board[Combo[i][0]] == 2)){
                return true;
            }
        }
        return false;
    }
    function showBoard() public view returns(string[]){
        // string [9] strboard;
        string[] memory message_arr = new string[](9);
        for(uint i = 0;i < 9;i++){
            message_arr[i] = uint2str(board[i]);
        }
        return message_arr;
    }
    
    function findnext() private view returns(uint _next){
        if (board[4]==0){
            return 4;
        }
        uint win_m = 999;
        uint lose_m = 999;
        for(uint i = 0; i < Combo.length; i++){
            if(board[Combo[i][0]]==board[Combo[i][1]]&&board[Combo[i][0]]!=0){
                if(board[Combo[i][0]]==2&&board[Combo[i][2]]==0){
                    win_m = Combo[i][2];
                }
                else{
                    lose_m = Combo[i][2];
                }
                // return Combo[i][2];
            }
            if(board[Combo[i][0]]==board[Combo[i][2]]&&board[Combo[i][0]]!=0){
                if(board[Combo[i][0]]==2&&board[Combo[i][1]]==0){
                    win_m = Combo[i][1];
                }
                else{
                    lose_m = Combo[i][1];
                }
                // return Combo[i][1];
            }
            if(board[Combo[i][1]]==board[Combo[i][2]]&&board[Combo[i][1]]!=0){
                if(board[Combo[i][1]]==2&&board[Combo[i][0]]==0){
                    win_m = Combo[i][0];
                }
                else{
                    lose_m = Combo[i][0];
                }
                // return Combo[i][0];
            }
        }
        if(win_m!=999){
            return win_m;
        }
        if(lose_m!=999){
            return lose_m;
        }
        
        if (board[0]==0){
            return 0;
        }
        if (board[2]==0){
            return 2;
        }
        if (board[6]==0){
            return 6;
        }
        if (board[8]==0){
            return 8;
        }
        
        // find next by random
        uint rand = uint256(sha256(abi.encodePacked(block.timestamp))) % 8;
        // rand = uint256(sha256(abi.encodePacked(block.timestamp))) % 8;
        for(uint j = 0;j < 8; j++){
            if(board[(j+rand)%8]==0){
                return (j+rand)%8;
            }
        }
        // return 1;
        
    }
    function computer() private{
        uint _next;
        _next = findnext();
        board[_next] = 2;
    }
    function move(uint _position)public{
        require(board[_position] == 0);
        require(win == false);
        board[_position] = 1;
        computer();
        if(checkwin()){
            win = true;
        }
    }
    
}