/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



contract CryptoMarriage {

    // Persons
    struct Person {
       address addr;
       string  name;
       bool ido;
    } 

    // Witnesses
    struct Witness {
        address addr;
        string name;
        uint blockNumber;
    }

    // Persons (to be married)
    Person[2] public persons;

    // Witnesses
    mapping (address => Witness) public witnesses;

    // State
    bool public married = false;
    uint public witnessBlocks;
    bool private divorced = false;
    uint private marriageBlock = 0;

    // Events
    event Marriage(address addr1, string name1, address addr2, string name2);
    event Witnessing(address addr1, string name1, address addr2, string name2, address witnessAddr, string witnessName);
    event Divorce(address addr1, string name1, address addr2, string name2);
    
    // Constructor
    constructor(address _addr1, string memory _name1, address _addr2, string memory _name2, uint _witnessBlocks) {
        persons[0] = Person(_addr1, _name1, false);
        persons[1] = Person(_addr2, _name2, false);
        witnessBlocks = _witnessBlocks;
    }

    modifier onlyPersons {
        require(
            msg.sender == persons[0].addr || msg.sender == persons[1].addr, 
            "Only bride and groom can call this."
        );
        _;
    }

    modifier onlyIfMarried {
        require(married, "The parties are not married.");
        _;
    }

    modifier onlyIfNotMarried {
        require(!married, "The parties are already married.");
        _;
    }

    modifier onlyIfNotDivorced {
        require(!divorced, "The parties previously divorced, instantiate a new contract.");
        _;
    }

    modifier onlyInWitnessingWindow {
        require(marriageBlock > 0 && block.number < marriageBlock + witnessBlocks, "You are outside the witnessing window.");
        _;
    }

    // I do
    function ido() public onlyPersons onlyIfNotMarried onlyIfNotDivorced {        
        if (msg.sender == persons[0].addr) {
            persons[0].ido = true;
        } else {
            persons[1].ido = true;
        }
        // check marriage
        if (marriageBlock == 0 && persons[0].ido && persons[1].ido) {
            married = true;
            marriageBlock = block.number;
            emit Marriage(persons[0].addr, persons[0].name, persons[1].addr, persons[1].name);
        }
    }

    // Divorce
    function divorce() public onlyPersons {
        if (msg.sender == persons[0].addr) {
            persons[0].ido = false;
        } else {
            persons[1].ido = false;
        }

        // emit only once
        if (married) {
            emit Divorce(persons[0].addr, persons[0].name, persons[1].addr, persons[1].name);
        }

        married = false;
        divorced = true;
    }

    // Witness
    function witness(string memory name) public onlyIfMarried onlyInWitnessingWindow {
        witnesses[msg.sender] = Witness(msg.sender, name, block.number);
        emit Witnessing(persons[0].addr, persons[0].name, persons[1].addr, persons[1].name, msg.sender, name);
    }

}