/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Cryptomons {
    // Cryptomons aka creatures, familiars, etc
    // 151 different Cryptomon species implemented and saved in the following enum variable.
     enum Species { 
         BULBASAUR, 
         IVYSAUR, 
         VENUSAUR, 
         
         CHARMANDER, 
         CHARMELEON, 
         CHARIZARD, 
         
         SQUIRTLE, 
         WARTORTLE, 
         BLASTOISE, 

         CATERPIE,
         METAPOD, 
         BUTTERFREE,       
         WEEDLE, 
         KAKUNA, 
         BEEDRILL, 

         PIDGEY, 
         PIDGEOTTO, 
         PIDGEOT,       
         RATTATA, 
         RATICATE, 
         SPEAROW, 
         FEAROW, 
         
         EKANS,
         ARBOK, 
         
         PIKACHU, 
         RAICHU, 
         
         SANDSHREW, 
         SANDSLASH, 
         
         NIDORAN_F, 
         NIDORINA, 
         NIDOQUEEN, 
         NIDORAN_M, 
         NIDORINO, 
         NIDOKING, 
         CLEFAIRY,
         CLEFABLE, 
         
         VULPIX, 
         NINETALES, 
         
         JIGGLYPUFF, 
         WIGGLYTUFF, 
         
         ZUBAT, 
         GOLBAT, 
         
         ODDISH, 
         GLOOM, 
         VILEPLUME, 
         
         PARAS, 
         PARASECT, 
         VENONAT,
         VENOMOTH, 
         
         DIGLETT, 
         DUGTRIO, 
         
         MEOWTH, 
         PERSIAN, 
         
         PSYDUCK, 
         GOLDUCK, 
         
         MANKEY, 
         PRIMEAPE, 
         
         GROWLITHE, 
         ARCANINE, 
         
         POLIWAG, 
         POLIWHIRL,
         POLIWRATH, 
         
         ABRA, 
         KADABRA, 
         ALAKAZAM, 
         
         MACHOP, 
         MACHOKE, 
         MACHAMP, 
         
         BELLSPROUT, 
         WEEPINBELL, 
         VICTREEBEL, 
         
         TENTACOOL, 
         TENTACRUEL,

         GEODUDE, 
         GRAVELER, 
         GOLEM, 
         
         PONYTA, 
         RAPIDASH, 
         
         SLOWPOKE, 
         SLOWBRO, 
         
         MAGNEMITE, 
         MAGNETON, 
         
         FARFETCH_D, 
         DODUO, 
         DODRIO, 
         
         SEEL,
         DEWGONG, 
         
         GRIMER, 
         MUK, 

         SHELLDER, 
         CLOYSTER, 
         
         GASTLY, 
         HAUNTER, 
         GENGAR, 
         
         ONIX, 
         
         DROWZEE, 
         HYPNO, 
         
         KRABBY, 
         KINGLER, 
         
         VOLTORB,
         ELECTRODE, 
         
         EXEGGCUTE, 
         EXEGGUTOR, 
         
         CUBONE,
         MAROWAK, 

         HITMONLEE, 
         HITMONCHAN, 
         LICKITUNG, 
         
         KOFFING, 
         WEEZING, 
         
         RHYHORN, 
         RHYDON,

         CHANSEY, 
        
         TANGELA, 
         
         KANGASKHAN, 

         HORSEA, 
         SEADRA, 
         
         GOLDEEN, 
         SEAKING, 
         
         STARYU, 
         STARMIE, 

         MR_MIME, 
         
         SCYTHER, 
         
         JYNX, 

         ELECTABUZZ,
         
         MAGMAR, 
         
         PINSIR, 
         
         TAUROS, 

         MAGIKARP, 
         GYARADOS, 
         LAPRAS, 
         
         DITTO, 
         
         EEVEE, 

         VAPOREON, 
         
         JOLTEON, 
         
         FLAREON, 
         
         PORYGON, 

         OMANYTE, 
         OMASTAR,
         KABUTO, 
         KABUTOPS, 
         
         AERODACTYL, 
         SNORLAX, 
         
         ARTICUNO, 

         ZAPDOS, 
         
         MOLTRES, 
         
         DRATINI, 
         DRAGONAIR, 
         DRAGONITE, 
         MEWTWO, 
         MEW 
    }
    
    // All 151 species types. Numbering follows this convention:
    //0(plant), 1(fire), 2(water), 3(bug), 4(normal), 5(poison), 6(thunder), 7(earth), 8(psychic), 9(ditto), 10(eevee)
    uint8[151] private monTypes = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 5, 5, 6,
    6, 7, 7, 4, 4, 4, 4, 4, 4, 4, 4, 1, 1, 4, 4, 5, 5, 0, 0, 0, 3, 3, 3, 3, 7, 7, 4, 4, 2, 2, 4, 4, 1,
    1, 2, 2, 2, 8, 8, 8, 4, 4, 4, 0, 0, 0, 2, 2, 7, 7, 7, 1, 1, 2, 2, 6, 6, 4, 4, 4, 2, 2, 5, 5, 2, 2,
    8, 8, 8, 7, 8, 8, 2, 2, 6, 6, 8, 8, 7, 7, 4, 4, 4, 5, 5, 7, 7, 4, 0, 4, 2, 2, 2, 2, 2, 2, 4, 3, 8,
    6, 1, 3, 4, 2, 2, 2, 9, 10, 2, 6, 1, 4, 2, 2, 2, 2, 4, 4, 2, 6, 1, 8, 8, 8, 8, 8];
    
    // Array keeping which Cryptomon species can evolve to the next one through breeding.
    bool[151] evolves = [true, true, false, true, true, false, true, true, false, true, true, false,
    true, true, false, true, true, false, true, false, true, false, true, false, true, false, true,
    false, true, true, false, true, true, false, true, false, true, false, true, false, true, false,
    true, true, false, true, false, true, false, true, false, true, false, true, false, true, false,
    true, false, true, true, false, true, true, false, true, true, false, true, true, false, true,
    false, true, true, false, true, false, true, false, true, false, false, true, false, true, false,
    true, false, true, false, true, true, false, false, true, false, true, false, true, false, true,
    false, true, false, true, false, false, true, false, true, false, false, false, false, true, false,
    true, false, true, false, false, false, false, false, false, false, false, true, false, false,
    false, false, false, false, false, false, true, false, true, false, false, false, false, false,
    false, true, true, false, true, false];
        
    // Structure of 1 Cryptomon
    struct Mon {
        uint id;
        address payable owner;
        Species species;
        uint price;
        bool forSale;
        
        uint8 monType;  // Used for breeding
        bool evolve;    // Used for breeding
        
        uint8 hp;       // Used for fighting
        uint8 atk;      // Used for fighting
        uint8 def;      // Used for fighting
        uint8 speed;    // Used for fighting
        
        address sharedTo; // Used for sharing
    }
    
    address public manager;             // Manager of the contract
    mapping(uint => Mon) public mons;   // Holds all created Cryptomons
    uint public totalMons = 0;          // Number of created Cryptomons
    uint private max = 2**256 - 1;      // Max number of Cryptomons
    
    uint private nonce = 0;             // Number used for guessable pseudo-random generated number.
    
    constructor() public {
        manager = msg.sender;
        
        // Add initial cryptomons on contract deployment to start game
        createMon(Species(1),0, false);
        createMon(Species(1),0, false);
        createMon(Species(3),0, false);
        createMon(Species(6),0, false);
        createMon(Species(9),0, false);
        createMon(Species(15),0, false);
        createMon(Species(22),0, false);
        createMon(Species(24),0, false);
        createMon(Species(26),0, false);
        createMon(Species(62),0, false);
        createMon(Species(132),0, false);
        createMon(Species(132),0, false);
        createMon(Species(131),0, false);
        createMon(Species(131),0, false);
    }
    
    modifier onlyManager() { // Modifier
        require(
            msg.sender == manager,
            "Only manager can call this."
        );
        _;
    }
    
    function createMon(Species species, uint price, bool forSale) public onlyManager {
        assert(totalMons <  max);
        
        Mon storage mon = mons[totalMons];
        mon.id = totalMons;
        mon.owner = msg.sender;
        mon.species = species;
        mon.price = price;
        mon.forSale = forSale;
        
        mon.monType = monTypes[uint8(species)];    // Assign the type of the cryptomon
        mon.evolve = evolves[uint8(species)];      // Keep whether this cryptomon can evolve
        
        // Assign stats of the cryptomon
        mon.hp = 100 + randomGen(41);
        mon.atk = 100 + randomGen(41);
        mon.def = 100 + randomGen(41);
        mon.speed = 100 + randomGen(41);
        
        mon.sharedTo = msg.sender;
        
        totalMons++;
    }
    
    function buyMon(uint id) public payable {
        assert(id < totalMons);
        require(msg.value > mons[id].price);    // Must send enough money to buy
        require(mons[id].forSale == true);      // Cryptomon must be for sale
        address payable seller = mons[id].owner;
        mons[id].owner = msg.sender;
        mons[id].sharedTo = msg.sender;         // Stop sharing since owner changed
        mons[id].forSale = false;
        seller.transfer(msg.value);
    }
    
    function addForSale(uint id, uint price) public {
        assert(id < totalMons);
        require(mons[id].owner == msg.sender);  // Only owner can add it to sale
        mons[id].forSale = true;
        mons[id].sharedTo = msg.sender;         // Stop sharing since you sell this
        mons[id].price = price;
    }
    
    function removeFromSale(uint id) public {
        assert(id < totalMons);
        require(mons[id].owner == msg.sender);  // Only owner can remove it from sale
        mons[id].forSale = false;
    }
    
    // Function that defines the resulting egg species from breeding
    function findEggSpecies(uint id1, uint id2) private returns (Species){
        
        // Seperation of some Cryptomon species by types. These arrays are used for
        // breeding into random unevolved Cryptomon of the same type
        uint8[5] memory plant = [0, 42, 59, 68, 113];
        uint8[6] memory fire = [3, 36, 57, 76, 125, 145];
        uint8[16] memory water = [6, 53, 59, 71, 78, 85, 89, 97, 115, 117, 119, 128, 130, 137, 139, 143];
        uint8[6] memory bug = [9, 12, 45, 47, 122, 126];
        uint8[19] memory normal = [15, 18, 20, 28, 31, 34, 38, 51, 55, 65, 82, 83, 105, 107, 112, 127, 136, 141, 142];
        uint8[4] memory poison = [22, 40, 87, 108];
        uint8[5] memory thunder = [24, 80, 99, 124, 144];
        uint8[7] memory earth = [26, 49, 73, 94, 103, 110, 114];
        uint8[8] memory psychic = [62, 91, 95, 101, 121, 123, 146, 149];
        
        Species s;

        if (mons[id2].monType == 9) {           // If species 2 is DITTO
            s = mons[id1].species;              // Replicate species 1
        } else if (mons[id1].monType == 9) {    // If species 1 is DITTO
            s = mons[id2].species;              // Replicate species 2
        }
        
        else if (mons[id1].monType == 10) {         // If species 1 is EEVEE
            if (mons[id2].monType == 1) {           // Breed with fire
                s = Species(135);                   // result FLAREON
            } else if (mons[id2].monType == 2) {    // Breed with water
                s = Species(133);                   // result VAPOREON
            } else if (mons[id2].monType == 6) {    // Breed with thunder
                s = Species(134);                   // result JOLTEON
            } else {                                // Breed with other type
                s = Species(132);                   // result EEVEE
            }
        }
        
        else if (mons[id2].monType == 10) {         // If species 2 is EEVEE
            if (mons[id1].monType == 1) {           // Breed with fire
                s = Species(135);                   // result FLAREON
            } else if (mons[id1].monType == 2) {    // Breed with water
                s = Species(133);                   // result VAPOREON
            } else if (mons[id1].monType == 6) {    // Breed with thunder
                s = Species(134);                   // result JOLTEON
            } else {                                // Breed with other type
                s = Species(132);                   // result EEVEE
            }
        }
        
        else if (mons[id1].monType == mons[id2].monType) {      // Only Cryptomons of the same type can breed into evolved type
            if (mons[id1].species == mons[id2].species) {       // If they are the same species
                if (mons[id1].evolve){                          // If they are able to evolve
                    s = Species(uint(mons[id1].species) + 1);   // Produce evolution species
                } else {                                        // If they are not able to evolve
                    s = mons[id1].species;                      // Produce the same species
                }
            } else {
                // If Cryptomons of the same type but different species then
                // produce a random unevolved Mon of the same type
                if(mons[id1].monType == 0) s = Species(plant[randomGen(5)]);
                else if(mons[id1].monType == 1) s = Species(fire[randomGen(6)]);
                else if(mons[id1].monType == 2) s = Species(water[randomGen(16)]);
                else if(mons[id1].monType == 3) s = Species(bug[randomGen(6)]);
                else if(mons[id1].monType == 4) s = Species(normal[randomGen(19)]);
                else if(mons[id1].monType == 5) s = Species(poison[randomGen(4)]);
                else if(mons[id1].monType == 6) s = Species(thunder[randomGen(5)]);
                else if(mons[id1].monType == 7) s = Species(earth[randomGen(7)]);
                else if(mons[id1].monType == 8) s = Species(psychic[randomGen(8)]);
            }
        }
        
        else {
            s = Species(128);       // result MAGIKARP in every other case
        }
        
        return s;
    }
    
    function breedMons(uint id1, uint id2) public {
        assert(id1 < totalMons);
        assert(id2 < totalMons);
        assert(totalMons <  max);           // Not reached maximum number of mons allowed
        
        require(mons[id1].owner == msg.sender);                     // Only owner can breed a monster
        require(mons[id1].owner == mons[id2].owner && id1!=id2);    // Must both belong to the same person and be distinct mons
        require(!(mons[id1].forSale || mons[id1].forSale));         // Breeding mons can't be for sale.
        
        Mon storage mon = mons[totalMons];
        mon.id = totalMons;
        mon.owner = msg.sender;
        mon.species = findEggSpecies(id1, id2);
        mon.price = 0;
        mon.forSale = false;
        
        mon.monType = monTypes[uint8(mon.species)];    // Assign the type of the cryptomon
        mon.evolve = evolves[uint8(mon.species)];      // Keep whether this cryptomon can evolve
        
        mon.hp = 100 + randomGen(41);
        mon.atk = 100 + randomGen(41);
        mon.def = 100 + randomGen(41);
        mon.speed = 100 + randomGen(41);
        
        mon.sharedTo = msg.sender;
        
        totalMons++;
    }
    
    function damage(uint id1, uint id2) private view returns (uint8) {
        return (mons[id1].atk > mons[id2].def) ? 10 : 5 ;
    }
    
    function fight(uint id1, uint id2) public view returns (uint, uint8){
        assert(id1 < totalMons);
        assert(id2 < totalMons);
        // require(id1 != id2);        // A mon can't fight with itself
        require(mons[id1].owner == msg.sender || mons[id1].sharedTo == msg.sender);    // Only owner can fight with a mon or if the mon is shared to sender
        require(!(mons[id1].forSale || mons[id2].forSale)); // Fighting mons can't be for sale.
        uint8 hp1 = mons[id1].hp;
        uint8 hp2 = mons[id2].hp;
        
        uint winnerId = 0;
        uint8 round = 0;
        
        do {
            round++;
            if (mons[id1].speed > mons[id2].speed) {
                if (hp2 < damage(id1, id2)){
                    winnerId = id1;
                    hp2 = 0;
                    break;
                }
                hp2 = hp2 - damage(id1, id2);
                
                if (hp1 < damage(id2, id1)){
                    winnerId = id2;
                    hp1 = 0;
                    break;
                }
                hp1 = hp1 - damage(id2, id1);
                
            } else {
                if (hp1 < damage(id2, id1)) {
                    winnerId = id2;
                    hp1 = 0;
                    break;
                }
                hp1 = hp1 - damage(id2, id1);
                if (hp2 < damage(id1, id2)) {
                    winnerId = id1;
                    hp2 = 0;
                    break;
                }
                hp2 = hp2 - damage(id1, id2);
            }
        } while (hp1 > 0 && hp2>0);
        return (winnerId, round);
    }
    
    function startSharing(uint id, address addr) public {
        assert(id < totalMons);
        require(!mons[id].forSale); // Sharing mon can't be for sale.
        require(mons[id].owner == msg.sender); // Only owner can share a mon
        mons[id].sharedTo = addr;
    }
    
    function stopSharing(uint id) public {
        assert(id < totalMons);
        require(mons[id].owner == msg.sender || mons[id].sharedTo == msg.sender);    // Only owner or the address that it is shared to can terminate the sharing of a mon 
        mons[id].sharedTo = mons[id].owner;
    }
    
    // function that generates pseudorandom numbers
    function randomGen(uint i) private returns (uint8) {
        uint8 x = uint8(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % i);
        nonce++;
        return x;
    }
    
}