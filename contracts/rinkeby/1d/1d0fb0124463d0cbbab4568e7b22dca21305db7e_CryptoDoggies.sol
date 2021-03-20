/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.4.18;


contract CryptoDoggies {
    
    uint age = 10;
    uint maxAge = age * 5;
    uint minAge = age - 5;
    uint ultraAge = age ** 2;
    uint modAge = age % 2;

    string name = "Doug";
   string name2 = "Karl";

    struct Doggy {
        uint age;
        string name;
        bytes5 dna;
    }

    Doggy [] doggies;

    mapping (uint256 => address) private doggyIdToOwner;
    mapping (address => uint256) private numOfDoggies;

    event DoggyCreated(uint256 _id, string _name, uint _age, bytes5 _dna);
    
    Doggy doggy1 = Doggy ({
        age: age,
        name: name,
        dna: bytes5(0x000000000)
   });

    Doggy doggy2 = Doggy({
        age: maxAge,
        name: name2,
        dna: bytes5(0xffffffffff)
    });

    function createDoggy(uint _age, string _name, bytes5 _dna) public {
        Doggy memory _doggy = Doggy({
            age: _age,
            name: _name,
            dna: _dna
        });
        uint256 newDoggyId = doggies.push (_doggy) - 1;
        doggyIdToOwner[newDoggyId] = msg.sender;
        numOfDoggies [msg.sender] = numOfDoggies [msg.sender] +1;

        DoggyCreated (newDoggyId, _name, _age, _dna);
        }
        
    }