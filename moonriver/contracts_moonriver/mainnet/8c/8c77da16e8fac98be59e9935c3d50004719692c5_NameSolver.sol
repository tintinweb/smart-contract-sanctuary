/**
 *Submitted for verification at moonriver.moonscan.io on 2022-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
Repo: https://github.com/ismaventuras/Mooncase
Concept of a name resolver for ERC721 tokens.
Users can create a name that is assigned to a contract address and a token id, then it can be retrieved on any frontend to resolve the NFT.
This contract is a proof of concept for a hackathon and a production version is being coded.
*/
contract NameSolver{    
    
    event NewName (bytes32 indexed name, address indexed creator, address indexed contract_address, uint256 token_id);
        
    mapping(bytes32 => Name) public savedNames; // mapping where the key is the custom name and the value the nft info

    // struct to track each name link to each token
    struct Name{
        address contract_address; // NFT Contract address
        uint256 token_id; // NFT token id
        uint256 chain_id; // chain where the nft is stored
        bool isValid;  // boolean to check if the record exists
        address creator; // who created it 
    }

    constructor () {}

    /// adds a new new to the mapping
    // reverts if name is already saved
    function add(address _contract_address, uint256 _token_id, uint256 _chain_id, bytes32 _name) public{
        bool _isValid = savedNames[_name].isValid;
        require(!_isValid, "name already saved");

        savedNames[_name] = Name(_contract_address,_token_id,_chain_id,true, msg.sender);
        emit NewName(_name, msg.sender,_contract_address, _token_id);
    }


}