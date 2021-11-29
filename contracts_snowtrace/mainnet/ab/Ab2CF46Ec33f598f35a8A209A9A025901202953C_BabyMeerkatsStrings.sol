// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BabyMeerkatsStrings {
    string[] public backgroundStrings = [
    "space", "sunset", "gold", "sky", "mars", "deep space", "rainbow", "lake",
    "bitcoin", "big dots", "avax", "fire", "city", "silver", "ethereum", "pinky", "dots", 
    "green cartoon", "soft blue", "gradient cartoon", "purple cartoon", "fire yellow", "pink blue", "blue leaf", "blue sand", 
    "sand", "purple", "nature", "green", "blue", "red", "half blue"];

     string[] public bodyStrings = [
     "gold","leopard",
     "cow","silver",
     "blue","red","brown",
     "classic","nature","grey"];

     string[] public hatStrings = [
     "angel","gold gentleman","green punk","unicorn",
     "painter", "crown", "orange ice cream", "santa", "blue punk", "red punk",
     "frank", "silver crown", "pirate", "headphone", "fez", "party", "wizard",
     "beanie","cowboy","none","egg", "gentleman","blue ice cream", "chef"];

     string[] public neckStrings = 
     ["devil","yellow wings", "black wings", "gold wings", "angel wings", "purple wings",
     "black devil", "bow tie", "devil wings", "blue wings", "red wings", "bat wings", "avax chain", "silver wings",
     "gold chain", "black tie", "dollar chain", "bitcoin chain", "grey chain", "iota chain", "solana chain", "black chain",
     "none"];

     string[] public eyeStrings = [
     "gold thug", "retro", "retro green", "fire", "red fire", "3d glasses",
     "blue velvet", "silver thug", "black glasses","thug", "purple rain", "green glasses", 
     "red glasses", "yellow star", "red star", "pink glass", "purple star", "green star", "turquose glasses",
     "tear", "yellow glasses", "close", "none", "blue glasses"];

     string[] public mouthStrings = ["gold pacifier", "silver pacifier", "bronze pacifier", "plastic pacifier"];

    function getBackground(uint8 i) public view returns(string memory){
        return backgroundStrings[i];
    }

        function getBody(uint8 i) public view returns(string memory){
        return bodyStrings[i];
    }

        function getHat(uint8 i) public view returns(string memory){
        return hatStrings[i];
    }

        function getEye(uint8 i) public view returns(string memory){
        return eyeStrings[i];
    }

        function getNeck(uint8 i) public view returns(string memory){
        return neckStrings[i];
    }

        function getMouth(uint8 i) public view returns(string memory){
        return mouthStrings[i];
    }
}