/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// SPDX-License-Identifier: This smart contract is guarded by an angry ghost
pragma solidity ^0.8.0;


contract POWNFTv3{

    //v2 Variables
    uint public UNMIGRATED = 0;
    uint public V2_TOTAL = 0;
    bytes32 public PREV_CHAIN_LAST_HASH;
    POWNFTv2 CONTRACT_V2;

    constructor(address contract_v2){
        supportedInterfaces[0x80ac58cd] = true; //ERC721
        supportedInterfaces[0x5b5e139f] = true; //ERC721Metadata
        supportedInterfaces[0x780e9d63] = true; //ERC721Enumerable
        supportedInterfaces[0x01ffc9a7] = true; //ERC165

        CONTRACT_V2 = POWNFTv2(contract_v2);
        V2_TOTAL =
        UNMIGRATED = CONTRACT_V2.totalSupply();
        PREV_CHAIN_LAST_HASH = CONTRACT_V2.hashOf(UNMIGRATED);

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


    //    METADATA VARS
    string private __name = "POW NFT";
    string private __symbol = "POW";
    bytes private __uriBase = bytes("https://www.pownftmetadata.com/t/");


    //    ENUMERABLE VARS
    mapping(address => uint[]) internal OWNER_INDEX_TO_ID;
    mapping(uint => uint) internal OWNER_ID_TO_INDEX;
    mapping(uint => uint) internal ID_TO_INDEX;
    mapping(uint => uint) internal INDEX_TO_ID;


    //ETH VAR
    mapping(uint256 => uint256) WITHDRAWALS;


    //      MINING VARS
    uint BASE_COST = 0.000045 ether;
    uint BASE_DIFFICULTY = uint(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)/uint(300);
    uint DIFFICULTY_RAMP = 3;


    event Migrate(uint indexed _tokenId);

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
        return TOKENS[ID_TO_INDEX[_tokenId]];
    }


    function migrate(uint _tokenId,uint _withdrawEthUntil) public {
            _migrate(_tokenId);
            if(_withdrawEthUntil > 0){
                withdraw(_tokenId, _withdrawEthUntil);
            }
    }
    function _migrate(uint _tokenId) internal {
        //require not migrated
        require(!isValidToken(_tokenId),'is_migrated');

        //Require before snapshot
        require(_tokenId <= V2_TOTAL,'forgery');

        //require owner on original contract
        require(CONTRACT_V2.ownerOf(_tokenId) == msg.sender,'owner');
        //mint the token with hash from prev contract
        UNMIGRATED--;
        mint(_tokenId,
            CONTRACT_V2.hashOf(_tokenId)
        );
        emit Migrate(_tokenId);
    }
    function migrateMultiple(uint[] calldata _tokenIds, uint[] calldata _withdrawUntil) public {
        for(uint i = 0; i < _tokenIds.length; i++){
            _migrate(_tokenIds[i]);
        }
        withdrawMultiple(_tokenIds,_withdrawUntil);
    }



    function withdraw(uint _tokenId, uint _withdrawUntil) public {
        payable(msg.sender).transfer(
            _withdraw(_tokenId, _withdrawUntil)
        );
    }
    function _withdraw(uint _tokenId, uint _withdrawUntil) internal returns(uint){
        require(isValidToken(_withdrawUntil),'withdrawUntil_exist');

        require(ownerOf(_tokenId) == msg.sender,"owner");
        require(_withdrawUntil > WITHDRAWALS[_tokenId],'withdrawn');

        uint generation = generationOf(_tokenId);
        uint firstPayable = 2**(generation+1);

        uint withdrawFrom = WITHDRAWALS[_tokenId];
        if(withdrawFrom < _tokenId){
            withdrawFrom = _tokenId;

            //withdraw from if _tokenId < number brought over
            if(withdrawFrom < V2_TOTAL){
                withdrawFrom = V2_TOTAL;
            }
            if(withdrawFrom < firstPayable){
                withdrawFrom = firstPayable - 1;
            }
        }

        require(_withdrawUntil > withdrawFrom,'underflow');

        uint payout = BASE_COST * (_withdrawUntil - withdrawFrom);

        WITHDRAWALS[_tokenId] = _withdrawUntil;

        emit Withdraw(_tokenId,payout);

        return payout;
    }

    function withdrawMultiple(uint[] calldata _tokenIds, uint[] calldata _withdrawUntil) public{
        uint payout = 0;
        for(uint i = 0; i < _tokenIds.length; i++){
            if(_withdrawUntil[i] > 0){
                payout += _withdraw(_tokenIds[i],_withdrawUntil[i]);
            }
        }
        payable(msg.sender).transfer(payout);
    }

    function mine(uint nonce) external payable{
        uint tokenId = UNMIGRATED + TOKENS.length + 1;
        uint generation = generationOf(tokenId);

        uint difficulty = BASE_DIFFICULTY / (DIFFICULTY_RAMP**generation);
        if(generation > 13){ //Token 16384
            difficulty /= (tokenId - 2**14 + 1);
        }

        uint cost = (2**generation - 1)* BASE_COST;


        bytes32 hash;
        if(V2_TOTAL - UNMIGRATED != TOKENS.length){
            hash = keccak256(abi.encodePacked(
                    msg.sender,
                    TOKENS[ID_TO_INDEX[tokenId-1]],
                    nonce
                ));
        }else{
//            First mine on new contract
            hash = keccak256(abi.encodePacked(
                        msg.sender,
                        PREV_CHAIN_LAST_HASH,
                    nonce
                ));
        }


        require(uint(hash) < difficulty,"difficulty");
        require(msg.value ==cost,"cost");

        hash = keccak256(abi.encodePacked(hash,block.timestamp));

        mint(tokenId, hash);

        emit Mined(tokenId,hash);
    }

    function mint(uint tokenId, bytes32 hash) private{
        OWNERS[tokenId] = msg.sender;
        BALANCES[msg.sender]++;
        OWNER_ID_TO_INDEX[tokenId] = OWNER_INDEX_TO_ID[msg.sender].length;
        OWNER_INDEX_TO_ID[msg.sender].push(tokenId);

        ID_TO_INDEX[tokenId] = TOKENS.length;
        INDEX_TO_ID[TOKENS.length] = tokenId;
        TOKENS.push(hash);

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

        uint _i = _tokenId;
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }


        return string(abi.encodePacked(__uriBase,bstr));

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
        return INDEX_TO_ID[_index];
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


interface POWNFTv2 {
    function hashOf(uint _tokenId) external view returns(bytes32);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function totalSupply() external view returns (uint256);
    //NWH YDY DDUG SEGEN DIN
}