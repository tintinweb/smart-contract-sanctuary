/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity ^0.7.0;

contract TheDudes {
    address owner;

    string public name = "thedudes";
    string public symbol = "D";
    uint8 public decimals = 0;
    uint256 public totalSupply = 10;

    uint public nextAvailableIndex = 0;

    uint totalHealth = 10;
    bool isEnabled = false;
    uint c = 0.5 ether;

    struct TheDude {
        address owner;
        bool originalOwner;
        uint health;
    }

    mapping (uint => TheDude) public theDudes;
    mapping (address => uint256) public balanceOf;

    constructor () {
        owner = msg.sender;
        nextAvailableIndex = 0;
    }

    function setAvailability(bool enabled) public {
        require(msg.sender == owner);
        isEnabled = enabled;
    }

    function isTheDudeOwned(address by, uint index) public view returns(bool owned) {
        return theDudes[index].owner == by;
    }

    function claimTheDude() public {
        require(isEnabled);
        require(nextAvailableIndex < totalSupply);
        require(!isTheDudeOwned(msg.sender, nextAvailableIndex));

        theDudes[nextAvailableIndex].owner = msg.sender;
        theDudes[nextAvailableIndex].originalOwner = true;
        theDudes[nextAvailableIndex].health = totalHealth;

        balanceOf[msg.sender]++;
        nextAvailableIndex++;
    }

    function transferDude(address to, uint theDudeIndex) public {
        require(isEnabled);
        require(nextAvailableIndex >= totalSupply);
        require(isTheDudeOwned(msg.sender, theDudeIndex));

        theDudes[theDudeIndex].owner = to;
        theDudes[theDudeIndex].originalOwner = false;
        if (theDudes[theDudeIndex].health > 0) {
            theDudes[theDudeIndex].health--;
        }

        balanceOf[msg.sender]--;
        balanceOf[to]++;
    }
}