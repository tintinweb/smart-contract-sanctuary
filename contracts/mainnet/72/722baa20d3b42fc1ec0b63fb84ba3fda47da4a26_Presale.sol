pragma solidity ^0.4.23;
/// @title ERC-165 Standard Interface Detection
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
contract ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

contract Random {
    uint256 _seed;

    function _rand() internal returns (uint256) {
        _seed = uint256(keccak256(_seed, blockhash(block.number - 1), block.coinbase, block.difficulty));
        return _seed;
    }

    function _randBySeed(uint256 _outSeed) internal view returns (uint256) {
        return uint256(keccak256(_outSeed, blockhash(block.number - 1), block.coinbase, block.difficulty));
    }
}

contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    constructor() public {
        addrAdmin = msg.sender;
    }  


    modifier onlyAdmin() {
        require(msg.sender == addrAdmin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        emit AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

contract AccessService is AccessAdmin {
    address public addrService;
    address public addrFinance;

    modifier onlyService() {
        require(msg.sender == addrService);
        _;
    }

    modifier onlyFinance() {
        require(msg.sender == addrFinance);
        _;
    }

    function setService(address _newService) external {
        require(msg.sender == addrService || msg.sender == addrAdmin);
        require(_newService != address(0));
        addrService = _newService;
    }

    function setFinance(address _newFinance) external {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_newFinance != address(0));
        addrFinance = _newFinance;
    }
}

//Ether League Hero Token
contract ELHeroToken is ERC721,AccessAdmin{
    struct Card {
        uint16 protoId;     // 0  10001-10025 Gen 0 Heroes
        uint16 hero;        // 1  1-25 hero ID
        uint16 quality;     // 2  rarities: 1 Common 2 Uncommon 3 Rare 4 Epic 5 Legendary 6 Gen 0 Heroes
        uint16 feature;     // 3  feature
        uint16 level;       // 4  level
        uint16 attrExt1;    // 5  future stat 1
        uint16 attrExt2;    // 6  future stat 2
    }
    
    /// @dev All card tokenArray (not exceeding 2^32-1)
    Card[] public cardArray;

    /// @dev Amount of tokens destroyed
    uint256 destroyCardCount;

    /// @dev Card token ID vs owner address
    mapping (uint256 => address) cardIdToOwner;

    /// @dev cards owner by the owner (array)
    mapping (address => uint256[]) ownerToCardArray;
    
    /// @dev card token ID search in owner array
    mapping (uint256 => uint256) cardIdToOwnerIndex;

    /// @dev The authorized address for each token
    mapping (uint256 => address) cardIdToApprovals;

    /// @dev The authorized operators for each address
    mapping (address => mapping (address => bool)) operatorToApprovals;

    /// @dev Trust contract
    mapping (address => bool) actionContracts;

    function setActionContract(address _actionAddr, bool _useful) external onlyAdmin {
        actionContracts[_actionAddr] = _useful;
    }

    function getActionContract(address _actionAddr) external view onlyAdmin returns(bool) {
        return actionContracts[_actionAddr];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event CreateCard(address indexed owner, uint256 tokenId, uint16 protoId, uint16 hero, uint16 quality, uint16 createType);
    event DeleteCard(address indexed owner, uint256 tokenId, uint16 deleteType);
    event ChangeCard(address indexed owner, uint256 tokenId, uint16 changeType);
    

    modifier isValidToken(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= cardArray.length);
        require(cardIdToOwner[_tokenId] != address(0)); 
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address owner = cardIdToOwner[_tokenId];
        require(msg.sender == owner || msg.sender == cardIdToApprovals[_tokenId] || operatorToApprovals[owner][msg.sender]);
        _;
    }

    // ERC721
    function supportsInterface(bytes4 _interfaceId) external view returns(bool) {
        // ERC165 || ERC721 || ERC165^ERC721
        return (_interfaceId == 0x01ffc9a7 || _interfaceId == 0x80ac58cd || _interfaceId == 0x8153916a) && (_interfaceId != 0xffffffff);
    }

    constructor() public {
        addrAdmin = msg.sender;
        cardArray.length += 1;
    }


    function name() public pure returns(string) {
        return "Ether League Hero Token";
    }

    function symbol() public pure returns(string) {
        return "ELHT";
    }

    /// @dev Search for token quantity address
    /// @param _owner Address that needs to be searched
    /// @return Returns token quantity
    function balanceOf(address _owner) external view returns (uint256){
        require(_owner != address(0));
        return ownerToCardArray[_owner].length;
    }

    /// @dev Find the owner of an ELHT
    /// @param _tokenId The tokenId of ELHT
    /// @return Give The address of the owner of this ELHT
    function ownerOf(uint256 _tokenId) external view returns (address){
        return cardIdToOwner[_tokenId];
    }

    /// @dev Transfers the ownership of an ELHT from one address to another address
    /// @param _from The current owner of the ELHT
    /// @param _to The new owner
    /// @param _tokenId The ELHT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external whenNotPaused{
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    /// @dev Transfers the ownership of an ELHT from one address to another address
    /// @param _from The current owner of the ELHT
    /// @param _to The new owner
    /// @param _tokenId The ELHT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused{
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @dev Transfer ownership of an ELHT, &#39;_to&#39; must be a vaild address, or the ELHT will lost
    /// @param _from The current owner of the ELHT
    /// @param _to The new owner
    /// @param _tokenId The ELHT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused isValidToken(_tokenId) canTransfer(_tokenId){
        address owner = cardIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner == _from);
        
        _transfer(_from, _to, _tokenId);
    }
    

    /// @dev Set or reaffirm the approved address for an ELHT
    /// @param _approved The new approved ELHT controller
    /// @param _tokenId The ELHT to approve
    function approve(address _approved, uint256 _tokenId) external whenNotPaused{
        address owner = cardIdToOwner[_tokenId];
        require(owner != address(0));
        require(msg.sender == owner || operatorToApprovals[owner][msg.sender]);

        cardIdToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /// @dev Enable or disable approval for a third party ("operator") to manage all your asset.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external whenNotPaused{
        operatorToApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @dev Get the approved address for a single ELHT
    /// @param _tokenId The ELHT to find the approved address for
    /// @return The approved address for this ELHT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address) {
        return cardIdToApprovals[_tokenId];
    }

    /// @dev Query if an address is an authorized operator for another address 查询地址是否为另一地址的授权操作者
    /// @param _owner The address that owns the ELHTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorToApprovals[_owner][_operator];
    }

    /// @dev Count ELHTs tracked by this contract
    /// @return A count of valid ELHTs tracked by this contract, where each one of them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return cardArray.length - destroyCardCount - 1;
    }

    /// @dev Actually perform the safeTransferFrom
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) internal isValidToken(_tokenId) canTransfer(_tokenId){
        address owner = cardIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner == _from);
        
        _transfer(_from, _to, _tokenId);

        // Do the callback after everything is done to avoid reentrancy attack
        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
        // bytes4(keccak256("onERC721Received(address,uint256,bytes)")) = 0xf0b9e5ba;
        require(retval == 0xf0b9e5ba);
    }

    /// @dev Do the real transfer with out any condition checking
    /// @param _from The old owner of this ELHT(If created: 0x0)
    /// @param _to The new owner of this ELHT 
    /// @param _tokenId The tokenId of the ELHT
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            uint256 indexFrom = cardIdToOwnerIndex[_tokenId];
            uint256[] storage cdArray = ownerToCardArray[_from];
            require(cdArray[indexFrom] == _tokenId);

            // If the ELHT is not the element of array, change it to with the last
            if (indexFrom != cdArray.length - 1) {
                uint256 lastTokenId = cdArray[cdArray.length - 1];
                cdArray[indexFrom] = lastTokenId; 
                cardIdToOwnerIndex[lastTokenId] = indexFrom;
            }
            cdArray.length -= 1; 
            
            if (cardIdToApprovals[_tokenId] != address(0)) {
                delete cardIdToApprovals[_tokenId];
            }      
        }

        // Give the ELHT to &#39;_to&#39;
        cardIdToOwner[_tokenId] = _to;
        ownerToCardArray[_to].push(_tokenId);
        cardIdToOwnerIndex[_tokenId] = ownerToCardArray[_to].length - 1;
        
        emit Transfer(_from != address(0) ? _from : this, _to, _tokenId);
    }



    /*----------------------------------------------------------------------------------------------------------*/


    /// @dev Card creation
    /// @param _owner Owner of the equipment created
    /// @param _attrs Attributes of the equipment created
    /// @return Token ID of the equipment created
    function createCard(address _owner, uint16[5] _attrs, uint16 _createType) external whenNotPaused returns(uint256){
        require(actionContracts[msg.sender]);
        require(_owner != address(0));
        uint256 newCardId = cardArray.length;
        require(newCardId < 4294967296);

        cardArray.length += 1;
        Card storage cd = cardArray[newCardId];
        cd.protoId = _attrs[0];
        cd.hero = _attrs[1];
        cd.quality = _attrs[2];
        cd.feature = _attrs[3];
        cd.level = _attrs[4];

        _transfer(0, _owner, newCardId);
        emit CreateCard(_owner, newCardId, _attrs[0], _attrs[1], _attrs[2], _createType);
        return newCardId;
    }

    /// @dev One specific attribute of the equipment modified
    function _changeAttrByIndex(Card storage _cd, uint16 _index, uint16 _val) internal {
        if (_index == 2) {
            _cd.quality = _val;
        } else if(_index == 3) {
            _cd.feature = _val;
        } else if(_index == 4) {
            _cd.level = _val;
        } else if(_index == 5) {
            _cd.attrExt1 = _val;
        } else if(_index == 6) {
            _cd.attrExt2 = _val;
        }
    }

    /// @dev Equiment attributes modified (max 4 stats modified)
    /// @param _tokenId Equipment Token ID
    /// @param _idxArray Stats order that must be modified
    /// @param _params Stat value that must be modified
    /// @param _changeType Modification type such as enhance, socket, etc.
    function changeCardAttr(uint256 _tokenId, uint16[5] _idxArray, uint16[5] _params, uint16 _changeType) external whenNotPaused isValidToken(_tokenId) {
        require(actionContracts[msg.sender]);

        Card storage cd = cardArray[_tokenId];
        if (_idxArray[0] > 0) _changeAttrByIndex(cd, _idxArray[0], _params[0]);
        if (_idxArray[1] > 0) _changeAttrByIndex(cd, _idxArray[1], _params[1]);
        if (_idxArray[2] > 0) _changeAttrByIndex(cd, _idxArray[2], _params[2]);
        if (_idxArray[3] > 0) _changeAttrByIndex(cd, _idxArray[3], _params[3]);
        if (_idxArray[4] > 0) _changeAttrByIndex(cd, _idxArray[4], _params[4]);
        
        emit ChangeCard(cardIdToOwner[_tokenId], _tokenId, _changeType);
    }

    /// @dev Equipment destruction
    /// @param _tokenId Equipment Token ID
    /// @param _deleteType Destruction type, such as craft
    function destroyCard(uint256 _tokenId, uint16 _deleteType) external whenNotPaused isValidToken(_tokenId) {
        require(actionContracts[msg.sender]);

        address _from = cardIdToOwner[_tokenId];
        uint256 indexFrom = cardIdToOwnerIndex[_tokenId];
        uint256[] storage cdArray = ownerToCardArray[_from]; 
        require(cdArray[indexFrom] == _tokenId);

        if (indexFrom != cdArray.length - 1) {
            uint256 lastTokenId = cdArray[cdArray.length - 1];
            cdArray[indexFrom] = lastTokenId; 
            cardIdToOwnerIndex[lastTokenId] = indexFrom;
        }
        cdArray.length -= 1; 

        cardIdToOwner[_tokenId] = address(0);
        delete cardIdToOwnerIndex[_tokenId];
        destroyCardCount += 1;

        emit Transfer(_from, 0, _tokenId);

        emit DeleteCard(_from, _tokenId, _deleteType);
    }

    /// @dev Safe transfer by trust contracts
    function safeTransferByContract(uint256 _tokenId, address _to) external whenNotPaused{
        require(actionContracts[msg.sender]);

        require(_tokenId >= 1 && _tokenId <= cardArray.length);
        address owner = cardIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner != _to);

        _transfer(owner, _to, _tokenId);
    }

    /// @dev Get fashion attrs by tokenId
    function getCard(uint256 _tokenId) external view isValidToken(_tokenId) returns (uint16[7] datas) {
        Card storage cd = cardArray[_tokenId];
        datas[0] = cd.protoId;
        datas[1] = cd.hero;
        datas[2] = cd.quality;
        datas[3] = cd.feature;
        datas[4] = cd.level;
        datas[5] = cd.attrExt1;
        datas[6] = cd.attrExt2;
    }

    /// Get tokenIds and flags by owner
    function getOwnCard(address _owner) external view returns(uint256[] tokens, uint32[] flags) {
        require(_owner != address(0));
        uint256[] storage cdArray = ownerToCardArray[_owner];
        uint256 length = cdArray.length;
        tokens = new uint256[](length);
        flags = new uint32[](length);
        for (uint256 i = 0; i < length; ++i) {
            tokens[i] = cdArray[i];
            Card storage cd = cardArray[cdArray[i]];
            flags[i] = uint32(uint32(cd.protoId) * 1000 + uint32(cd.hero) * 10 + cd.quality);
        }
    }

    /// ELHT token info returned based on Token ID transfered (64 at most)
    function getCardAttrs(uint256[] _tokens) external view returns(uint16[] attrs) {
        uint256 length = _tokens.length;
        require(length <= 64);
        attrs = new uint16[](length * 11);
        uint256 tokenId;
        uint256 index;
        for (uint256 i = 0; i < length; ++i) {
            tokenId = _tokens[i];
            if (cardIdToOwner[tokenId] != address(0)) {
                index = i * 11;
                Card storage cd = cardArray[tokenId];
                attrs[index] = cd.hero;
                attrs[index + 1] = cd.quality;
                attrs[index + 2] = cd.feature;
                attrs[index + 3] = cd.level;
                attrs[index + 4] = cd.attrExt1;
                attrs[index + 5] = cd.attrExt2;
            }   
        }
    }


}

contract Presale is AccessService, Random {
    ELHeroToken tokenContract;
    mapping (uint16 => uint16) public cardPresaleCounter;
    mapping (address => uint16[]) OwnerToPresale;
    uint256 public jackpotBalance;

    event CardPreSelled(address indexed buyer, uint16 protoId);
    event Jackpot(address indexed _winner, uint256 _value, uint16 _type);

    constructor(address _nftAddr) public {
        addrAdmin = msg.sender;
        addrService = msg.sender;
        addrFinance = msg.sender;

        tokenContract = ELHeroToken(_nftAddr);

        cardPresaleCounter[1] = 20; //Human Fighter
        cardPresaleCounter[2] = 20; //Human Tank
        cardPresaleCounter[3] = 20; //Human Marksman
        cardPresaleCounter[4] = 20; //Human Mage
        cardPresaleCounter[5] = 20; //Human Support
        cardPresaleCounter[6] = 20; //Elf Fighter
        cardPresaleCounter[7] = 20; //Elf Tank
        cardPresaleCounter[8] = 20; //...
        cardPresaleCounter[9] = 20;
        cardPresaleCounter[10] = 20;
        cardPresaleCounter[11] = 20;//Orc
        cardPresaleCounter[12] = 20;
        cardPresaleCounter[13] = 20;
        cardPresaleCounter[14] = 20;
        cardPresaleCounter[15] = 20;
        cardPresaleCounter[16] = 20;//Undead
        cardPresaleCounter[17] = 20;
        cardPresaleCounter[18] = 20;
        cardPresaleCounter[19] = 20;
        cardPresaleCounter[20] = 20;
        cardPresaleCounter[21] = 20;//Spirit
        cardPresaleCounter[22] = 20;
        cardPresaleCounter[23] = 20;
        cardPresaleCounter[24] = 20;
        cardPresaleCounter[25] = 20;
    }

    function() external payable {
        require(msg.value > 0);
        jackpotBalance += msg.value;
    }

    function setELHeroTokenAddr(address _nftAddr) external onlyAdmin {
        tokenContract = ELHeroToken(_nftAddr);

    }

    function cardPresale(uint16 _protoId) external payable whenNotPaused{
        uint16 curSupply = cardPresaleCounter[_protoId];
        require(curSupply > 0);
        require(msg.value == 0.25 ether);
        uint16[] storage buyArray = OwnerToPresale[msg.sender];
        uint16[5] memory param = [10000 + _protoId, _protoId, 6, 0, 1];
        tokenContract.createCard(msg.sender, param, 1);
        buyArray.push(_protoId);
        cardPresaleCounter[_protoId] = curSupply - 1;
        emit CardPreSelled(msg.sender, _protoId);

        jackpotBalance += msg.value * 2 / 10;
        addrFinance.transfer(address(this).balance - jackpotBalance);
        //1%
        uint256 seed = _rand();
        if(seed % 100 == 99){
            emit Jackpot(msg.sender, jackpotBalance, 2);
            msg.sender.transfer(jackpotBalance);
        }
    }

    function withdraw() external {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        addrFinance.transfer(address(this).balance);
    }

    function getCardCanPresaleCount() external view returns (uint16[25] cntArray) {
        cntArray[0] = cardPresaleCounter[1];
        cntArray[1] = cardPresaleCounter[2];
        cntArray[2] = cardPresaleCounter[3];
        cntArray[3] = cardPresaleCounter[4];
        cntArray[4] = cardPresaleCounter[5];
        cntArray[5] = cardPresaleCounter[6];
        cntArray[6] = cardPresaleCounter[7];
        cntArray[7] = cardPresaleCounter[8];
        cntArray[8] = cardPresaleCounter[9];
        cntArray[9] = cardPresaleCounter[10];
        cntArray[10] = cardPresaleCounter[11];
        cntArray[11] = cardPresaleCounter[12];
        cntArray[12] = cardPresaleCounter[13];
        cntArray[13] = cardPresaleCounter[14];
        cntArray[14] = cardPresaleCounter[15];
        cntArray[15] = cardPresaleCounter[16];
        cntArray[16] = cardPresaleCounter[17];
        cntArray[17] = cardPresaleCounter[18];
        cntArray[18] = cardPresaleCounter[19];
        cntArray[19] = cardPresaleCounter[20];
        cntArray[20] = cardPresaleCounter[21];
        cntArray[21] = cardPresaleCounter[22];
        cntArray[22] = cardPresaleCounter[23];
        cntArray[23] = cardPresaleCounter[24];
        cntArray[24] = cardPresaleCounter[25];
    }

    function getBuyCount(address _owner) external view returns (uint32) {
        return uint32(OwnerToPresale[_owner].length);
    }

    function getBuyArray(address _owner) external view returns (uint16[]) {
        uint16[] storage buyArray = OwnerToPresale[_owner];
        return buyArray;
    }

    function eventPirze(address _addr, uint8 _id) public onlyAdmin{
        require(_id == 20 || _id == 21);
        uint16 curSupply = cardPresaleCounter[_id];
        require(curSupply > 0);
        uint16[] storage buyArray = OwnerToPresale[_addr];
        uint16[5] memory param = [10000 + _id, _id, 6, 0, 1];
        tokenContract.createCard(_addr, param, 1);
        buyArray.push(_id);
        cardPresaleCounter[_id] = curSupply - 1;
    }
}