pragma solidity ^0.4.24;

contract TajaMatejWedding3 {
    string bride = "Taja";
    string groom = "Matej";
    string date = "29 July 2017";
    
    function getWeddingData() returns (string) {
        return string(abi.encodePacked(bride, " & ", groom, ", happily married on ", date, ". :)"));
    }
    
    function myWishes() returns (string) {
        return "I wish you the best marriage ever!";
    }
}