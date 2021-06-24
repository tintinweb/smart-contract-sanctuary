/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.5.1;

contract Earth {

    // Look again at that dot. That's here. That's home. That's us.
    // On it everyone you love, everyone you know, everyone you ever
    // heard of, every human being who ever was, lived out their lives.
    // The aggregate of our joy and suffering, thousands of confident
    // religions, ideologies, and economic doctrines, every hunter and
    // forager, every hero and coward, every creator and destroyer of
    // civilization, every king and peasant, every young couple in love,
    // every mother and father, hopeful child, inventor and explorer,
    // every teacher of morals, every corrupt politician, every "superstar",
    // every "supreme leader", every saint and sinner in the history of
    // our species lived there — on a mote of dust suspended in a sunbeam.
    // — Carl Sagan


    constructor() public {}

    event CreateID(
        bytes32 indexed name,
        address primary,
        address recovery,
        uint64 number
    );

    event SetPrimary(
        bytes32 indexed name,
        address primary
    );

    event SetRecovery(
        bytes32 indexed name,
        address recovery
    );

    event Recover(
        bytes32 indexed name,
        address primary,
        address recovery
    );

    struct ID {
        address primary;
        address recovery;
        uint64 joined;
        uint64 number;
    }


    /*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */
    

    mapping(address => bytes32) public associate;

    mapping(address => bytes32) public directory;

    mapping(uint64 => bytes32) public index;

    mapping(bytes32 => ID) public citizens;

    uint64 public population;


    /*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */


    function getPrimary(bytes32 name) public view returns (address) {
        return citizens[name].primary;
    }

    function getRecovery(bytes32 name) public view returns (address) {
        return citizens[name].recovery;
    }

    function getJoined(bytes32 name) public view returns (uint64) {
        return citizens[name].joined;
    }

    function getNumber(bytes32 name) public view returns (uint64) {
        return citizens[name].number;
    }

    function addressAvailable(address addr) public view returns (bool) {
        return associate[addr] == bytes32(0x0);
    }

    function nameAvailable(bytes32 name) public view returns (bool) {
        return getPrimary(name) == address(0x0);
    }

    function lookupNumber(uint64 number) public view returns (address, address, uint64, bytes32) {
        bytes32 name = index[number];
        ID storage id = citizens[name];
        return (id.primary, id.recovery, id.joined, name);
    }

    function authorize() public view returns (bytes32) {

        // Get the name linked to the sender address
        bytes32 name = directory[msg.sender];

        // Revert if not linked to any name
        require(name != bytes32(0x0));

        // Return authorized name
        return name;
    }


    /*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */
    

    function createID(bytes32 name, address recovery) public {
        
        // Ensure that name was provided
        require(name != bytes32(0x0));

        // Ensure that name is available
        require(nameAvailable(name));

        // Ensure sender has never been linked
        require(addressAvailable(msg.sender));

        // Primary and recovery cannot be the same
        require(recovery != msg.sender);

        // If a valid recovery address was provided,
        // check available and associate with name
        if (recovery != address(0x0)) { 
            require(addressAvailable(recovery));
            associate[recovery] = name;
        }

        // Associate sender address with name
        // and create new directory entry
        associate[msg.sender] = name;
        directory[msg.sender] = name;

        // Increment the population size
        population += 1;

        // Create the ID model
        citizens[name] = ID({
            primary: msg.sender,
            recovery: recovery,
            joined: uint64(now),
            number: population
        });

        // Map number to name
        index[population] = name;

        emit CreateID(name, msg.sender, recovery, population);
    }

    function setPrimary(bytes32 name, address primary) public {
        
        // Get the ID model
        ID storage id = citizens[name];

        // Ensure id belongs to sender
        require(id.primary == msg.sender);

        // Ensure new address provided
        require(primary != address(0x0));

        // Ensure new address available
        require(addressAvailable(primary));

        // Associate new address with name
        // and create new directory entry
        associate[primary] = name;
        directory[primary] = name;

        // Old address no longer points to name
        directory[msg.sender] = bytes32(0x0);

        // Update ID model
        id.primary = primary;
        
        emit SetPrimary(name, primary);
    }

    function setRecovery(bytes32 name, address recovery) public {
        
        // Get the ID model
        ID storage id = citizens[name];
        
        // Ensure ID belongs to sender
        require(id.primary == msg.sender);

        // Ensure recovery address provided
        require(recovery != address(0x0));
        
        // Ensure recovery not already set
        require(id.recovery == address(0x0));

        // Ensure recovery address available
        require(addressAvailable(recovery));
        
        // Associate recovery with name
        associate[recovery] = name;
        
        // Update ID model
        id.recovery = recovery;

        emit SetRecovery(name, recovery);
    }

    function recover(bytes32 name, address newRecovery) public {

        // Get the ID model
        ID storage id = citizens[name];

        // Ensure recovery address is sender
        require(id.recovery == msg.sender);
        
        // If a new recovery address was provided
        // and is available, associate with name
        if (newRecovery != address(0x0)) {
            require(addressAvailable(newRecovery));
            associate[newRecovery] = name;
        }

        // Set new recovery address (may be zero)
        id.recovery = newRecovery;

        // Existing primary no longer points to anything
        directory[id.primary] = bytes32(0x0);

        // Current recovery address now points to
        // name, replacing former primary address
        directory[msg.sender] = name;
        id.primary = msg.sender;

        emit Recover(name, msg.sender, newRecovery);
    }
}