pragma solidity >=0.8.7;

contract Character{
    address public owner;
    string public name;
    string public race;
    string public class;
    uint8 public health;

    function setHealth(uint8 damage) virtual external {
        if (damage > health){
            health = 0;
        }
        else{
            health -= damage;
        }
    }
}