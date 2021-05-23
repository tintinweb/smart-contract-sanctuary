/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Animal_Gashpon
{
    struct Animal
    {
        // dna is the unique random ID
        bytes32 dna;
        
        // star rank posibility
        // star 1 = 40%
        // star 2 = 30%
        // star 3 = 15%
        // star 4 = 10%
        // star 5 = 5%
        uint8 star;
        
        // animal type
        // 1 = fox
        // 2 = bear
        // 3 = skullcat
        // 4 = tiger
        // 5 = cat
        // 6 = dog
        uint16 animal_type;
        
        // the higher the rank is
        // the higher the health is
        // star 1 = 100
        // star 2 = 150
        // star 3 = 200
        // star 4 = 300
        // star 5 = 350
        uint256 health;
        
        // the attack and defence
        // are based on animal type
        uint256 attack;
        uint256 defence;
    }
    
    Animal[] public animals;
    string public name = "animal_name";
    string public symbol = "animal_symbol";
    
    // find the animal owner by animal ID
    mapping(uint => address) animal_to_owner;
    
    // record how many animal
    // does each owner has
    mapping(address => uint) owner_animal_count;
    
    // record each animal ID is approved
    // to send to the another owner
    mapping(uint => address) animal_approval;
    
    function GetName() external view returns(string memory)
    {
        return name;
    }
    function GetSymbol() external view returns(string memory)
    {
        return symbol;
    }
    function TotalAnimal() public view returns(uint256)
    {
        return animals.length;
    }
    function GetDna(uint index) public view returns(bytes32)
    {
        return animals[index].dna;
    }
    function GetStar(uint index) public view returns(uint8)
    {
        return animals[index].star;
    }
    function GetType(uint index) public view returns(uint16)
    {
        return animals[index].animal_type;
    }
    
    function GetHealth(uint index) public view returns(uint256)
    {
        return animals[index].health;
    }
    function GetAttack(uint index) public view returns(uint256)
    {
        return animals[index].attack;
    }
    function GetDefence(uint index) public view returns(uint256)
    {
        return animals[index].defence;
    }
    // input: specific animal ID
    // output: return the owner address of animal ID
    function GetOwner(uint index) public view returns(address)
    {
        return animal_to_owner[index];
    }
    // input: specific address
    // output: return how many animal does address has
    function GetAnimalAmount(address owner) public view returns(uint256)
    {
        return owner_animal_count[owner];
    }
    // input: list of animal ID
    //      : specific address
    // output: return whether the all animal ID
    //         are owned by the address
    function CheckAnimalOwner(uint[] memory ID, address owner) public view returns(bool)
    {
        for(uint i = 0; i < ID.length; i ++)
        {
            if(animal_to_owner[ID[i]] != owner)
            {
                return false;
            }
        }
        return true;
    }
    // input: specific address
    // output: return the animal ID list which
    //         owned by the address
    function GetAnimalByOwner(address owner) public view returns(uint[] memory)
    {
        uint[] memory result = new uint[](owner_animal_count[owner]);
        uint index = 0;
        for(uint i = 0; i < animals.length; i ++)
        {
            if(animal_to_owner[i] == owner)
            {
                result[index] = i;
                index ++;
            }
        }
        return result;
    }
    function random() private view returns(bytes32)
    {
         bytes32 result = keccak256(abi.encodePacked(block.coinbase, blockhash(block.number-1), msg.sender));
         return result;
    }
    // create a new animal
    // which own by the msg sender
    function CreateAnimal() public payable
    {
        // generate unique random ID
        bytes32 dna;
        dna = bytes32(random());
        
        // higher the star
        // the lower the chance
        // also the star is associate health
        uint8 star;
        uint rand = uint256(random()) % 100;
        uint health;
        if(rand < 40)
        {
            star = 1;
            health = 100;
        }
        else if(rand < 70)
        {
            star = 2;
            health = 150;
        }
        else if(rand < 85)
        {
            star = 3;
            health = 200;
        }
        else if(rand < 95)
        {
            star = 4;
            health = 300;
        }
        else
        {
            star = 5;
            health = 350;
        }
        
        // generate the animal type
        // also the attack and defence
        // are associate with animal type
        uint16 animal_type;
        rand = uint256(random()) % 6 + 1;
        animal_type = uint16(rand);
        uint256 attack;
        uint256 defence;
        // fox
        if(animal_type == 1)
        {
            attack = 70;
            defence = 30;
        }
        // bear
        else if(animal_type == 2)
        {
            attack = 25;
            defence = 75;
        }
        // skullcat
        else if(animal_type == 3)
        {
            attack = 90;
            defence = 10;
        }
        // tiger
        else if(animal_type == 4)
        {
            attack = 60;
            defence = 40;
        }
        // cat
        else if(animal_type == 5)
        {
            attack = 50;
            defence = 50;
        }
        // dog
        else if(animal_type == 6)
        {
            attack = 50;
            defence = 50;
        }
        
        // put new animal into animals
        animals.push(Animal(dna, uint8(star), uint8(animal_type), uint256(health), uint256(attack), uint256(defence)));
        
        uint id = animals.length - 1;
        // the owner of the new animal is the msg sender
        animal_to_owner[id] = msg.sender;
        // the amount of the owner is also increase
        owner_animal_count[msg.sender]++;
    }
    
    function TransferTo(address animal_receiver, uint256 ID) public
    {
        // the msg sender must be the owner of the animal
        require(animal_to_owner[ID] == msg.sender);
        
        // increase receiver animal amount
        // decrease sender animal amount
        // change animal owner from sender to receiver
        address animal_sender = animal_to_owner[ID];
        owner_animal_count[animal_sender] --;
        owner_animal_count[animal_receiver] ++;
        animal_to_owner[ID] = animal_receiver;
    }
    function Approve(address animal_receiver, uint256 ID) public
    {
        // the msg sender must be the owner of the animal
        require(animal_to_owner[ID] == msg.sender);
        
        // the msg sender approve to change owner to receiver
        animal_approval[ID] = animal_receiver;
    }
    function TransferFrom(uint256 ID) public
    {
        // the msg sender must be approved by the old owner
        require(animal_approval[ID] == msg.sender);
        
        // increase receiver animal amount
        // decrease sender animal amount
        // change animal owner from sender to receiver
        address animal_sender = animal_to_owner[ID];
        owner_animal_count[animal_sender] --;
        owner_animal_count[msg.sender] ++;
        animal_to_owner[ID] = msg.sender;
    }
}