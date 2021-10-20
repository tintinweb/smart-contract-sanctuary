/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

//import {SafeMath} from "./SafeMath.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//import {DataAggregator} from "./DataAggregator.sol";
//import {Tokens} from "./Tokens.sol";
//import {Users} from "./Users.sol";

/*
 * @dev 
 * This library is required to manage flipss on ToshiFlip
 * dataAggregator is used to create random address and to create commitment
 *
 * The declaration of the variable is on "ToshiFlip.sol"
 * Only players of ToshiFlip can execute functions
 */
library IterableFlips {
    //using SafeMath for uint256;
    //using Tokens for Tokens.Token;
    //using Users for Users.User;

    struct Flip{
        address key;
        //Users.User player1;
        address player1;
        //Users.User player2;
        address player2;
        address commitment1;
        address commitment2;
        //Tokens.Token token;
        address token;
        uint256 amount;
        uint256 expiration;
        
        address winner;
        bool available;
        uint256 dateCreated;
        uint256 dateFinished;
    }
    
    struct Flips{
        //DataAggregator dataAggregator;
        uint nFlips;
        uint nNonces;
        //uint nbCommitment;
        address[] keys;
        mapping(address => Flip) flips;
        mapping(address => address) nonces;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Flips storage flips, address key) external view returns(Flip memory flip){
        if( !flips.inserted[key] ){
            return Flip(address(0), address(0), address(0), address(0), address(0), address(0), 0, 0, address(0), false, 0, 0);
        }
        return flips.flips[key];
    }
    function getAll(Flips storage flips) external view returns(Flip[] memory all){
        uint nFlips = flips.keys.length;
        Flip[] memory flipArray = new Flip[](nFlips);
        for(uint i=0; i < nFlips; i++ ){
            flipArray[i] = flips.flips[flips.keys[i]];
        }
        return flipArray;
    }
    function getAvailables(Flips storage flips) external view returns(Flip[] memory availables){
        uint nFlips = flips.keys.length;
        uint nFlipsReal = 0;
        address[] memory flipAddressArray = new address[](nFlips);
        for(uint i=0; i < nFlips; i++ ){
            if( flips.flips[flips.keys[i]].available ){
                flipAddressArray[i] = flips.keys[i];
                nFlipsReal++;
            }
        }

        Flip[] memory flipArray = new Flip[](nFlipsReal);
        for(uint i=0; i < nFlipsReal; i++ ){
            flipArray[i] = flips.flips[flipAddressArray[i]];
        }
        return flipArray;
    }
    
    function getPlayerFlips(Flips storage flips, address player) external view returns(Flip[] memory playerFlips){
        uint nFlips = flips.keys.length;
        uint nFlipsReal = 0;
        address[] memory flipAddressArray = new address[](nFlips);
        for(uint i=0; i < nFlips; i++ ){
            if( flips.flips[flips.keys[i]].player1 == player || flips.flips[flips.keys[i]].player2 == player ){
                flipAddressArray[i] = flips.keys[i];
                nFlipsReal++;
            }
        }
        if( nFlipsReal == 0 ){
            return new Flip[](nFlipsReal);
        }
        
        Flip[] memory flipArray = new Flip[](nFlipsReal);
        for(uint i=0; i < nFlipsReal; i++ ){
            flipArray[i] = flips.flips[flipAddressArray[i]];
        }
        return flipArray;
    }
    function isFlip(Flips storage flips, address key) external view returns(bool _isFlip){
        return flips.inserted[key];
    }

    function add(Flips storage flips, address player1, address token, uint256 amount, bool choice, uint256 expiration) external returns(address flipAddress){
        flips.nFlips++;
        address key = address(uint160(uint(keccak256(abi.encodePacked(flips.nFlips, player1, token, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        //address key = flips.dataAggregator.createRandomAddress(token.key, amount);
        while( flips.inserted[key] ){
            flips.nFlips++;
            key = address(uint160(uint(keccak256(abi.encodePacked(flips.nFlips, player1, token, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        }
        
        flips.nNonces++;
        address nonce = address(uint160(uint(keccak256(abi.encodePacked(flips.nNonces, player1, token, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        flips.nonces[key] = nonce;
        
        address commitment1 = address(uint160(uint(keccak256(abi.encodePacked(nonce, choice, address(this))))));
        
        //uint lastIndex = flips.keys.length - 1;
        flips.keys.push(key);
        //flips.keys[lastIndex] = key;
        flips.flips[key] = Flip(key, player1, address(0), commitment1, address(0), token, amount, expiration, address(0), true, block.timestamp, 0);
        flips.indexOf[key] = flips.keys.length - 1;
        flips.inserted[key] = true;
        return key;
    }
    /*
    function _addFlip(Flips storage flips, Users.User memory player1, Tokens.Token memory token, uint256 amount, bool choice, uint256 expiration) public returns(address flipAddress){
        flips.nFlips++;
        address key = address(uint160(uint(keccak256(abi.encodePacked(flips.nFlips, player1.key, token.key, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        //address key = flips.dataAggregator.createRandomAddress(token.key, amount);
        while( flips.inserted[key] ){
            flips.nFlips++;
            key = address(uint160(uint(keccak256(abi.encodePacked(flips.nFlips, player1.key, token.key, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        }
        
        flips.nNonces++;
        address nonce = address(uint160(uint(keccak256(abi.encodePacked(flips.nNonces, player1.key, token.key, address(this), block.timestamp, blockhash(block.number), block.difficulty, msg.sender)))));
        flips.nonces[key] = nonce;
        
        address commitment1 = address(uint160(uint(keccak256(abi.encodePacked(nonce, choice, address(this))))));
        
        flips.keys.push(key);
        flips.flips[key] = Flip(key, player1, Users.User(address(0), 0, 0, true), commitment1, address(0), token, amount, expiration, address(0), true, block.timestamp, 0);
        flips.indexOf[key] = flips.keys.length;
        flips.inserted[key] = true;
        return key;
    }
    */
    function join(Flips storage flips, address key, address player2, bool choice) external returns(bool joined){
        if( !flips.inserted[key] ){
            return false;
        }
        
        address nonce = flips.nonces[key];
        flips.flips[key].player2 = player2;
        flips.flips[key].commitment2 = address(uint160(uint(keccak256(abi.encodePacked(nonce, choice, address(this))))));
        return true;
    }
    
    function pickWinner(Flips storage flips, address key) external returns(address winner){
        if( !flips.inserted[key] ){
            return address(0);
        }
        Flip memory flip = flips.flips[key];
        flip.winner = flip.commitment1 == flip.commitment2 ? flip.player2 : flip.player1;
        flip.available = false;
        flip.dateFinished = block.timestamp;
        flips.flips[key] = flip;
        
        delete flips.nonces[key];
        return flip.winner;
    }
    
    function remove(Flips storage flips, address key) external returns (bool removed){
        if (!flips.inserted[key]) {
            return false;
        }
        flips.nFlips--;
        flips.nNonces--;
        
        delete flips.nonces[key];
        delete flips.inserted[key];
        delete flips.flips[key];
        uint index = flips.indexOf[key];
        uint lastIndex = flips.keys.length - 1;
        address lastKey = flips.keys[lastIndex];
        flips.indexOf[lastKey] = index;
        flips.keys[index] = lastKey;
        delete flips.indexOf[key];
        flips.keys.pop();
        return true;
    }
    


    function getIndexOfKey(Flips storage flips, address key) external view returns (int index) {
        if(!flips.inserted[key]) {
            return -1;
        }
        return int(flips.indexOf[key]);
    }
    function getKeyAtIndex(Flips storage flips, uint index) external view returns (address flipAddress) {
        return flips.keys[index];
    }
    
    function size(Flips storage flips) external view returns (uint length) {
        return flips.keys.length;
    }
}