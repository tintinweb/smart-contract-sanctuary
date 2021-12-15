// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Character {
    string public name;
    string public race;
    string public class;
    address public owner;
    uint8 public health;

    function setHealth(uint8 damage) external virtual {
        health = health > damage ? health - damage : 0;
    }
}