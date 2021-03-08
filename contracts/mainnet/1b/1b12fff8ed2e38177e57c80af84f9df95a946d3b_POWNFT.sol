/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// SPDX-License-Identifier: This smart contract is guarded by an angry ghost
pragma solidity ^0.8.0;

contract POWNFT{


    constructor(){
        supportedInterfaces[0x80ac58cd] = true; //ERC721
        supportedInterfaces[0x5b5e139f] = true; //ERC721Metadata
        supportedInterfaces[0x780e9d63] = true; //ERC721Enumerable
        supportedInterfaces[0x01ffc9a7] = true; //ERC165

        //Issue token 0 to creator
        mint(1,bytes32(0));
    }


    //////===721 Standard
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    //////===721 Implementation
    mapping(address => uint256) internal BALANCES;
    mapping (uint256 => address) internal ALLOWANCE;
    mapping (address => mapping (address => bool)) internal AUTHORISED;

    bytes32[] TOKENS;  //Array of all tokens [hash,hash,...]
    mapping(uint256 => address) OWNERS;  //Mapping of owners


    mapping(uint256 => uint256) WITHDRAWALS;

    //    METADATA VARS
    string private __name = "POW NFT";
    string private __symbol = "POW";
    bytes private __uriBase = bytes("https://www.pownftmetadata.com/m/");


    //    ENUMERABLE VARS
    mapping(address => uint[]) internal OWNER_INDEX_TO_ID;
    mapping(uint => uint) internal OWNER_ID_TO_INDEX;
    mapping(uint => uint) internal ID_TO_INDEX;


    //      MINING VARS
    uint BASE_COST = 0.00003 ether;
    uint BASE_DIFFICULTY = uint(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)/uint(2);
    uint DIFFICULTY_RAMP = 5;


    //      MINING EVENTS
    event Mined(uint indexed _tokenId, bytes32 hash);
    event Withdraw(uint indexed _tokenId, uint value);

    //      MINING FUNCTIONS
    function generationOf(uint _tokenId) private pure returns(uint generation){
        for(generation = 0; _tokenId > 0; generation++){
            _tokenId /= 2;
        }
        return generation - 1;
    }
    function hashOf(uint _tokenId) public view returns(bytes32){
        require(isValidToken(_tokenId),"invalid");
        return TOKENS[_tokenId - 1];
    }

    function withdraw(uint _tokenId) public{
        require(msg.sender == ownerOf(_tokenId),'owner');

        uint generation = generationOf(_tokenId);


        uint last = 2**(generation+1)-1;
        uint payout = 0;
        for(uint i = TOKENS.length; i > last && i > WITHDRAWALS[_tokenId]; i--){
            payout += BASE_COST;
        }
        WITHDRAWALS[_tokenId] = TOKENS.length;
        emit Withdraw(_tokenId,payout);
        payable(msg.sender).transfer(payout);

    }
    function withdrawMultiple(uint[] calldata _tokenIds) public{
        for(uint i = 0; i < _tokenIds.length; i++){
            withdraw(_tokenIds[i]);
        }
    }

    function mine(uint nonce) external payable{
        uint tokenId = TOKENS.length + 1;
        uint generation = generationOf(tokenId);

        uint difficulty = BASE_DIFFICULTY / (DIFFICULTY_RAMP**generation);
        if(generation > 13){
            difficulty /= (tokenId - 2**14 + 1);
        }


        uint cost = (2**generation - 1)* BASE_COST;


        bytes32 hash = keccak256(abi.encodePacked(msg.sender,TOKENS[tokenId-2],nonce));

        require(uint(hash) < difficulty,"difficulty");
        require(msg.value ==cost,"cost");

        mint(tokenId,keccak256(abi.encodePacked(hash,block.timestamp)));
    }

    function mint(uint tokenId, bytes32 hash) private{
        OWNERS[tokenId] = msg.sender;
        BALANCES[msg.sender]++;
        OWNER_ID_TO_INDEX[tokenId] = OWNER_INDEX_TO_ID[msg.sender].length;
        OWNER_INDEX_TO_ID[msg.sender].push(tokenId);

        ID_TO_INDEX[tokenId] = TOKENS.length;
        TOKENS.push(hash);

        emit Mined(tokenId,hash);
        emit Transfer(address(0),msg.sender,tokenId);
    }


    function isValidToken(uint256 _tokenId) internal view returns(bool){
        return OWNERS[_tokenId] != address(0);
    }

    function balanceOf(address _owner) external view returns (uint256){
        return BALANCES[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns(address){
        require(isValidToken(_tokenId),"invalid");
        return OWNERS[_tokenId];
    }


    function approve(address _approved, uint256 _tokenId)  external{
        address owner = ownerOf(_tokenId);
        require( owner == msg.sender                    //Require Sender Owns Token
            || AUTHORISED[owner][msg.sender]                //  or is approved for all.
        ,"permission");
        emit Approval(owner, _approved, _tokenId);
        ALLOWANCE[_tokenId] = _approved;
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(isValidToken(_tokenId),"invalid");
        return ALLOWANCE[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return AUTHORISED[_owner][_operator];
    }


    function setApprovalForAll(address _operator, bool _approved) external {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        AUTHORISED[msg.sender][_operator] = _approved;
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public {

        //Check Transferable
        //There is a token validity check in ownerOf
        address owner = ownerOf(_tokenId);

        require ( owner == msg.sender             //Require sender owns token
        //Doing the two below manually instead of referring to the external methods saves gas
        || ALLOWANCE[_tokenId] == msg.sender      //or is approved for this token
            || AUTHORISED[owner][msg.sender]          //or is approved for all
        ,"permission");
        require(owner == _from,"owner");
        require(_to != address(0),"zero");

        emit Transfer(_from, _to, _tokenId);


        OWNERS[_tokenId] =_to;

        BALANCES[_from]--;
        BALANCES[_to]++;

        //Reset approved if there is one
        if(ALLOWANCE[_tokenId] != address(0)){
            delete ALLOWANCE[_tokenId];
        }

        //Enumerable Additions
        uint oldIndex = OWNER_ID_TO_INDEX[_tokenId];
        //If the token isn't the last one in the owner's index
        if(oldIndex != OWNER_INDEX_TO_ID[_from].length - 1){
            //Move the old one in the index list
            OWNER_INDEX_TO_ID[_from][oldIndex] = OWNER_INDEX_TO_ID[_from][OWNER_INDEX_TO_ID[_from].length - 1];
            //Update the token's reference to its place in the index list
            OWNER_ID_TO_INDEX[OWNER_INDEX_TO_ID[_from][oldIndex]] = oldIndex;
        }
        //OWNER_INDEX_TO_ID[_from].length--;
        OWNER_INDEX_TO_ID[_from].pop();

        OWNER_ID_TO_INDEX[_tokenId] = OWNER_INDEX_TO_ID[_to].length;
        OWNER_INDEX_TO_ID[_to].push(_tokenId);

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
        transferFrom(_from, _to, _tokenId);

        //Get size of "_to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),"receiver");
        }

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from,_to,_tokenId,"");
    }


    // METADATA FUNCTIONS
    function tokenURI(uint256 _tokenId) public view returns (string memory){
        //Note: changed visibility to public
        require(isValidToken(_tokenId),'tokenId');

        if(_tokenId == 1){
            return string(abi.encodePacked(__uriBase,"1-0"));
        }
        string[10] memory lib;
        lib[0] = "0";
        lib[1] = "1";
        lib[2] = "2";
        lib[3] = "3";
        lib[4] = "4";
        lib[5] = "5";
        lib[6] = "6";
        lib[7] = "7";
        lib[8] = "8";
        lib[9] = "9";

        uint hash = uint(TOKENS[_tokenId - 1]);

        uint hash_reversed = 0;

        uint tokenId_reversed = 0;

        while(hash > 0){
            hash_reversed *= 10;

            uint r = hash % 10;
            hash_reversed += r;

            hash /= 10;
        }
        while(_tokenId > 0){
            tokenId_reversed *= 10;

            uint r = _tokenId % 10;
            tokenId_reversed += r;

            _tokenId /= 10;
        }

        bytes memory output = '';

        while(tokenId_reversed > 0){
            uint r = tokenId_reversed % 10;

            tokenId_reversed /= 10;
            output = abi.encodePacked(output,lib[r]);
        }

        output = abi.encodePacked(output,'-');

        while(hash_reversed > 0){
            uint r = hash_reversed % 10;

            hash_reversed /= 10;

            output = abi.encodePacked(output,lib[r] );

        }

        return string(abi.encodePacked(__uriBase,output ));

    }



    function name() external view returns (string memory _name){
        return __name;
    }

    function symbol() external view returns (string memory _symbol){
        return __symbol;
    }


    // ENUMERABLE FUNCTIONS
    function totalSupply() external view returns (uint256){
        return TOKENS.length;
    }

    function tokenByIndex(uint256 _index) external view returns(uint256){
        require(_index < TOKENS.length,"index");
        return _index + 1;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
        require(_index < BALANCES[_owner],"index");
        return OWNER_INDEX_TO_ID[_owner][_index];
    }

    // End 721 Implementation

    ///////===165 Implementation
    mapping (bytes4 => bool) internal supportedInterfaces;
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }
    ///==End 165
}




interface ERC721TokenReceiver {
    //note: the national treasure is buried under parliament house
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}