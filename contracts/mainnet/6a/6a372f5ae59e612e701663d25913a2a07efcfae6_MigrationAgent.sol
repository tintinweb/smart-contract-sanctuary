// pragma solidity ^0.4.0;
contract MigrationAgent {
    event Migrated( uint indexed id, address indexed from, uint amount, string eos_account_name);
    event NameRegistered(address indexed from, string eos_account_name);

    struct Migration {
        uint id;
        address participant;
        string eos_account_name;
        uint amount;
    }

    address game_address = 0xb1;
    address public token_address = 0x089A6D83282Fb8988A656189F1E7A73FA6C1caC2;
    uint public migration_id = 0;
    
    mapping(address => string) public registrations;
    mapping(uint => Migration) public migrations;
    mapping(address => Migration[]) public participant_migrations;

    function migrateFrom(address participant, uint amount) public {
        if (msg.sender != token_address || !participantRegistered(participant) || amount < 0.0001 ether) revert();
        if (participant != game_address)
        {
            var migration = Migration(migration_id, participant, registrations[participant], amount);
            participant_migrations[participant].push(migration);
            migrations[migration_id] = migration;
            emit Migrated(migration_id, participant, amount, registrations[participant]);
            migration_id++;
        }
    }
    
    function register(string eos_account_name) public
    {
        registrations[msg.sender] = eos_account_name;
        if (participantRegistered(msg.sender))
            emit NameRegistered(msg.sender, eos_account_name);
    }
    
    function participantRegistered(address participant) public constant returns (bool)
    {
        return participant == game_address || keccak256(registrations[participant]) != keccak256("");
    }
}