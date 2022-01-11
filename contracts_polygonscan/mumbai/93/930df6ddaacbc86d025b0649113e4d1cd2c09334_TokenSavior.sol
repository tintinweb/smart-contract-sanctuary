/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

//SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

interface PartialERC721{
    function setApprovalForAll(address operator, bool _approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract TokenSavior{
    //In case something goes wrong.
    address _validator;
    bool functionality = true;

    //Maintain the address' of the approved receivers
    mapping(address => address) approved_receivers;

    constructor(){
        _validator = msg.sender;
    }
    
    // @param old_account The account with the tokens at risk
    // @return The receiver address connected to the old_account
    function findReceiver(address old_account) public view onlyLive returns(address){
        return approved_receivers[old_account];
    }

    function removeReceiver() public onlyLive{
        delete approved_receivers[msg.sender];
    }
    // @param old_account The account with the tokens at risk
    // @param _contract The address of the smart contract of the NFTs you are trying to save
    // @return Returns a number representing the state of the potential transaction. (must be called from receiving address) 0 = Ready to save tokens, 1 = Contract is not approved for transferring your tokens, 2 = Receiver has not been set or is invalid.
    function isReadyToSave(address old_account, address _contract) public view onlyLive returns(uint){
        if(!PartialERC721(_contract).isApprovedForAll(old_account, address(this))){
            return 1;
        }
        if(!(approved_receivers[old_account] == msg.sender)){
            return 2;
        }
        return 0;
        
    }  
    
    // @param receiver The address that will pay the gas fee to receive the NFTs "lost" in the sender's account.
    function setReceiver(address receiver) public onlyLive{
        //On success we can know for sure that the msg.sender owns the NFTs in question
        approved_receivers[msg.sender] = receiver;
    }
    
    // @param old_account The account that contains the NFTs to be transferred.
    // @param contract The smart contract of the NFTs to be transferred.
    // @param token_ids The token ids to be transferred. 
    function batchRetrieve(address old_account, address _contract, uint[] memory token_ids) public onlyLive{
        require(msg.sender == approved_receivers[old_account], "Receiver not verified.");
        require(PartialERC721(_contract).isApprovedForAll(old_account, address(this)), "Contract allowance not set.");
        for(uint i = 0; i < token_ids.length; i++){
            PartialERC721(_contract).transferFrom(old_account, msg.sender, token_ids[i]);
        }
    }

    // @param old_account The account that contains the NFT to be transferred.
    // @param contract The smart contract of the NFT to be transferred.
    // @param token_ids The token id to be transferred. 
    function retrieve(address old_account, address _contract, uint token_id) public onlyLive{
        require(msg.sender == approved_receivers[old_account], "Receiver not verified.");
        require(PartialERC721(_contract).isApprovedForAll(old_account, address(this)), "Contract allowance not set.");
        PartialERC721(_contract).transferFrom(old_account, msg.sender, token_id);
    }
    
    function toggle() public onlyValidator {
        functionality = !functionality;
    }

    modifier onlyLive() {
        require(functionality);
        _;
    }

    modifier onlyValidator() {
        require(_validator == msg.sender);
        _;
    }
}