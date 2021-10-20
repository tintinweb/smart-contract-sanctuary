// SPDX-License-Identifier: MIT


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  █████   ███   █████          ████                                                 █████████   █████                                                               //
// ░░███   ░███  ░░███          ░░███                                                ███░░░░░███ ░░███                                                                //
//  ░███   ░███   ░███   ██████  ░███   ██████   ██████  █████████████    ██████    ░███    ░░░  ███████   ████████   ██████   ████████    ███████  ██████  ████████  //
//  ░███   ░███   ░███  ███░░███ ░███  ███░░███ ███░░███░░███░░███░░███  ███░░███   ░░█████████ ░░░███░   ░░███░░███ ░░░░░███ ░░███░░███  ███░░███ ███░░███░░███░░███ //
//  ░░███  █████  ███  ░███████  ░███ ░███ ░░░ ░███ ░███ ░███ ░███ ░███ ░███████     ░░░░░░░░███  ░███     ░███ ░░░   ███████  ░███ ░███ ░███ ░███░███████  ░███ ░░░  //
//   ░░░█████░█████░   ░███░░░   ░███ ░███  ███░███ ░███ ░███ ░███ ░███ ░███░░░      ███    ░███  ░███ ███ ░███      ███░░███  ░███ ░███ ░███ ░███░███░░░   ░███      //
//     ░░███ ░░███     ░░██████  █████░░██████ ░░██████  █████░███ █████░░██████    ░░█████████   ░░█████  █████    ░░████████ ████ █████░░███████░░██████  █████     //
//      ░░░   ░░░       ░░░░░░  ░░░░░  ░░░░░░   ░░░░░░  ░░░░░ ░░░ ░░░░░  ░░░░░░      ░░░░░░░░░     ░░░░░  ░░░░░      ░░░░░░░░ ░░░░ ░░░░░  ░░░░░███ ░░░░░░  ░░░░░      //
//                                                                                                                                        ███ ░███                    //
//                                                                                                                                       ░░██████                     //
//                                                                                                                                        ░░░░░░                      //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./EscrowManagement.sol";
import "./SignedMessages.sol";
import "./TokenSegments.sol";

// we whitelist OpenSea so that minters can save on gas and spend it on NFTs
contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ConjuredLands is ReentrancyGuard, EscrowManagement, ERC721, ERC721Enumerable, Ownable, SignedMessages, TokenSegments  {
    using Strings for uint256; 
    address proxyRegistryAddress;
    mapping (address => bool) private airdroppers;
    mapping(address => uint256[]) private burnedTokensByOwners;
    uint8 public maxNumberOfTokens = 30;
    address[] public ownersThatBurned;
    address[20] public premiumOwners;
    uint256 public tokenPrice = 0.0555 ether;
    uint256 public premiumTokenPrice = 5.55 ether;
    uint256 public constant maxSupply = 10888;
    uint256 public constant maxIndex = 10887;
    mapping (uint256 => uint256) private tokenCreationBlocknumber;
    bool public mintingActive = true;
    bool public burningActive = false;
    uint8 public premiumMintingSlots = 22;
    // that's October 19th 2021 folks!
    uint256 public salesStartTime = 1634839200; 
    mapping (address => uint256) mintingBlockByOwners;
    mapping(address => uint256) public highestAmountOfMintedTokensByOwners;
    string private __baseURI;
    bool baseURIfrozen = false;
    
    // generate random index
    uint256 internal nonce = 19831594194915648;
    mapping(int8 => uint256[maxSupply]) private alignmentIndices;
    // the good, the evil and the neutral https://www.youtube.com/watch?v=WCN5JJY_wiA
    uint16[3] public alignmentMaxSupply;
    uint16[3] public alignmentTotalSupply;
    uint16[3] public alignmentFirstIndex;
    // these are URIs for the custom part, single URLs and segmented baseURIs
    mapping(uint256 => string) specialTokenURIs;

    constructor(string memory _name, string memory _symbol, address[] memory _teamMembers, uint8[] memory _splits, address _proxyRegistryAddress)
    ERC721(_name, _symbol)
    {
        // set the team members
        require(_teamMembers.length == _splits.length, "Wrong team lengths");
        if (_teamMembers.length > 0) {
            uint8 totalSplit = 0;
            for (uint8 i = 0; i < _teamMembers.length; i++) {
                EscrowManagement._addTeamMemberSplit(_teamMembers[i], _splits[i]);
                totalSplit += _splits[i];
            }
            require(totalSplit == 100, "Total split not 100");
        }
        alignmentMaxSupply[0] = 3000; // good
        alignmentMaxSupply[1] = 3000; // evil
        alignmentMaxSupply[2] = 4000; // neutral
        alignmentFirstIndex[0] = 888; // the indexes 0- 887 are reserved for the giveaways
        alignmentFirstIndex[1] = alignmentFirstIndex[0] + alignmentMaxSupply[0];
        alignmentFirstIndex[2] = alignmentFirstIndex[1] + alignmentMaxSupply[1];
        // set the deployer of this contract as an issuer of signed messages
        SignedMessages.setIssuer(msg.sender, true);
        __baseURI = "ipfs://QmamCw1tks7fpFyDCfGYVQyMkSwtJ39BRGxuA2D37hFME1/";
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function _baseURI() internal view override returns(string memory) {
        return __baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner(){
        require(!baseURIfrozen, "BaseURI frozen");
        __baseURI = newBaseURI;
    }
    
    function baseURI() public view returns(string memory){
        return __baseURI;
    }

    // calling this function locks the possibility to change the baseURI forever
    function freezeBaseURI() public onlyOwner(){
        baseURIfrozen = true;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // check if token is in a special segment
        int256 segmentId = TokenSegments.getSegmentId(tokenId);
        if (segmentId != -1) {
            // found a segment, get the URI, only return if it is set
            string memory segmentURI = TokenSegments.getBaseURIBySegmentId(segmentId);
            if (bytes(segmentURI).length > 0) {
                return string(abi.encodePacked(segmentURI,tokenId.toString()));
            }
        }
        // check if a special tokenURI is set, otherwise fallback to standard
        if (bytes(specialTokenURIs[tokenId]).length ==  0){
            return ERC721.tokenURI(tokenId);
        } else {
            // special tokenURI is set
            return specialTokenURIs[tokenId];
        }
    }

    function setSpecialTokenURI(uint256 tokenId, string memory newTokenURI) public onlyOwner(){
        require(getAlignmentByIndex(tokenId) == -1, "No special token");
        specialTokenURIs[tokenId] = newTokenURI;
    }

    function setSegmentBaseTokenURIs(uint256 startingIndex, uint256 endingIndex, string memory _URI) public onlyOwner(){
        TokenSegments._setSegmentBaseTokenURIs(startingIndex, endingIndex, _URI);
    }

    function setBaseURIBySegmentId(int256 pointer, string memory _URI) public onlyOwner(){
        TokenSegments._setBaseURIBySegmentId(pointer, _URI);
    }

    /**
        * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns(bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    // use this to update the registry address, if a wrong one was passed with the constructor
    function setProxyRegistryAddress(address _proxyRegistryAddress) public onlyOwner(){
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function approveAirdropperContract(address contractAddress, bool approval) public onlyOwner(){
        airdroppers[contractAddress] = approval;
    }

    function airdropper_allowedCaller(address caller) public view returns(bool){
        // only team members can airdrop
        return (EscrowManagement.teamMembersSplit[caller] > 0);
    }

    // used by the external airdropper
    function airdropper_allowedToken(uint256 tokenId) public view returns(bool){
        // only tokens in the giveaway section are allowed for airdrops
        return (getAlignmentByIndex(tokenId) == -1);
    }

    function airdropper_mint(address to, uint256 tokenId) public{
        // protect this call - only the airdropper contract can can call this
        require(airdroppers[msg.sender], "Not an airdropper");
        _internalMintById(to, tokenId);
    }

    function setIssuerForSignedMessages(address issuer, bool status) public onlyOwner(){
        SignedMessages.setIssuer(issuer, status);
    }


    function getAlignmentByIndex(uint256 _index) public view returns(int8){
        // we take the last one, and loop
        int8 alignment = -1;
        // check the boundaries - lower than the first or higher than the last
        if ((_index < alignmentFirstIndex[0]) ||
            ((_index > alignmentFirstIndex[alignmentFirstIndex.length - 1] + alignmentMaxSupply[alignmentMaxSupply.length - 1] - 1))) {
            return -1;
        }
        for (uint8 ix = 0; ix < alignmentFirstIndex.length; ix++) {
            if (alignmentFirstIndex[ix] <= _index) {
                alignment = int8(ix);
            }
        }
        return alignment;
    }
    
    function addTeamMemberSplit(address teamMember, uint8 split) public onlyOwner(){
        EscrowManagement._addTeamMemberSplit(teamMember, split);
    }
    
    function getTeamMembers() public onlyOwner view returns(address[] memory){
        return EscrowManagement._getTeamMembers();
    }
    
    function remainingSupply() public view returns(uint256){
        // returns the total remainingSupply
        return maxSupply - totalSupply();
    }

    function remainingSupply(uint8 alignment) public view returns(uint16){
        return alignmentMaxSupply[alignment] - alignmentTotalSupply[alignment];
    }
    
    function salesStarted() public view returns (bool) {
        return block.timestamp >= salesStartTime;
    }
    
    // set the time from which the sales will be started
    function setSalesStartTime(uint256 _salesStartTime) public onlyOwner(){
        salesStartTime = _salesStartTime;
    }
    
    function flipMintingState() public onlyOwner(){
        mintingActive = !mintingActive;
    }
   
    function flipBurningState() public onlyOwner(){
        burningActive = !burningActive;
    }
    
    // change the prices for minting
    function setTokenPrice(uint256 newPrice) public onlyOwner(){
        tokenPrice = newPrice;
    }
    
    function setPremiumTokenPrice(uint256 newPremiumPrice) public onlyOwner(){
        premiumTokenPrice = newPremiumPrice;
    }
    
    function getRandomId(uint256 _presetIndex, uint8 _alignment) internal returns(uint256){
        uint256 totalSize = remainingSupply(_alignment);
        int8 alignment = int8(_alignment);
        // allow the caller to preset an index
        uint256 index;
        if (_presetIndex == 0) {
            index = alignmentFirstIndex[uint8(alignment)] + uint256(keccak256(abi.encodePacked(nonce, "ourSaltAndPepper", blockhash(block.number), msg.sender, block.difficulty, block.timestamp, gasleft()))) % totalSize;
        } else {
            index = _presetIndex;
            alignment = getAlignmentByIndex(index);
        }
        if (alignment == -1) {
            // if the index is out of bounds, then exit
            return 0;
        }
        uint256 value = 0;
        // the indices holds the value for unused index positions
        // so you never get a collision
        if (alignmentIndices[alignment][index] != 0) {
            value = alignmentIndices[alignment][index];
        } else {
            value = index;
        }

        // Move last value to the actual position, so if it get taken, you can give back the free one
        if (alignmentIndices[alignment][totalSize - 1] == 0) {
            // Array position not initialized, so use that position
            alignmentIndices[alignment][index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            alignmentIndices[alignment][index] = alignmentIndices[alignment][totalSize - 1];
        }
        nonce++;
        return value;
    }
    
    // team members can always mint out of the giveaway section
    function membersMint(address to, uint256 tokenId) onlyTeamMembers() public{
        // can only mint in the non public section
        require(getAlignmentByIndex(tokenId) == -1, "Token in public section");
        _internalMintById(to, tokenId);
    }

    // internal minting function by id, can flexibly be called by the external controllers
    function _internalMintById(address to, uint256 tokenId) internal{
        require(tokenId <= maxIndex, "Token out of index");
        _safeMint(to, tokenId);
        getRandomId(tokenId, 0);
        // consume the index in the alignment, if it was part of the open section
        int8 alignment = getAlignmentByIndex(tokenId);
        if (alignment != -1) {
            alignmentTotalSupply[uint8(alignment)]++;
        }
    }

    // internal minting function via random index, can flexibly be called by the external controllers
    function _internalMintRandom(address to, uint256 numberOfTokens, uint8 alignment) internal{
        require(numberOfTokens <= maxNumberOfTokens, "Max amount exceeded");
        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = getRandomId(0, alignment);
            if (alignmentTotalSupply[alignment] < alignmentMaxSupply[alignment]) {
                _safeMint(to, mintIndex);
                alignmentTotalSupply[alignment]++;
            }
        }

        if (numberOfTokens > 0) {
            // this is for preventing getting the id in the same transaction (semaphore)
            mintingBlockByOwners[msg.sender] = block.number;
            // keep track of the minting amounts (even is something has been transferred or burned)
            highestAmountOfMintedTokensByOwners[msg.sender] += numberOfTokens;
            emit FundsReceived(msg.sender, msg.value, "payment by minting sale");
        }
    }
    
    function mint(uint256 numberOfTokens, uint8 alignment) public payable nonReentrant{
        require(mintingActive && salesStarted(), "Minting is not active");
        require((tokenPrice * numberOfTokens) == msg.value, "Wrong payment");
        require(numberOfTokens <= remainingSupply(alignment), "Purchase amount exceeds max supply");
        _internalMintRandom(msg.sender, numberOfTokens, alignment);
    }
    
    function premiumMint(uint8 alignment) public payable nonReentrant{
        require(mintingActive && salesStarted(), "Minting is not active");
        require(premiumMintingSlots>0, "No more premium minting slots");
        require(totalSupply()<= maxSupply, "Maximum supply reached");
        require(msg.value == premiumTokenPrice, "Wrong payment");
        premiumOwners[premiumMintingSlots -1] = msg.sender;
        premiumMintingSlots--;
        _internalMintRandom(msg.sender, 1, alignment);
    }
    
    function burn(uint256 tokenId) public nonReentrant{
        require(burningActive, "Burning not active.");
        super._burn(tokenId);
        // keep track of burners
        if (burnedTokensByOwners[msg.sender].length == 0){
            // first time they burn, add the caller to the list
            ownersThatBurned.push(msg.sender);
        }
        burnedTokensByOwners[msg.sender].push(tokenId);
    }
    
    function getBurnedTokensByOwner(address owner) public view returns(uint256[] memory){
        return burnedTokensByOwners[owner];
    }
    
    event FundsReceived(address from, uint256 amount, string description);
    // accounting purposes: we need to be able to split the incoming funds between sales and royalty
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value, "direct payment, no sale");
    }
    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value, "direct payment, no sale");
    }

    /*
     *  Functions for handling signed messages
     * 
     * */

    function mintById_SignedMessage(uint256 _tokenId, uint256 _setPrice, uint256 expirationTimestamp, uint256 _nonce, bytes memory _sig) public payable{
        // check validity and execute
        require(expirationTimestamp <= block.timestamp, "Expired");
        bytes32 message = SignedMessages.prefixed(keccak256(abi.encodePacked(msg.sender, _tokenId, _setPrice, expirationTimestamp, _nonce)));
        require(msg.value == _setPrice, "Wrong payment");
        require(SignedMessages.consumePass(message, _sig, _nonce), "Error in signed msg");
        _internalMintById(msg.sender, _tokenId);
        if (msg.value > 0) {
            emit FundsReceived(msg.sender, msg.value, "payment by minting sale");
        }
    }

    //DAppJS.addSignatureCall('test', 'address', 'uint8', 'uint256', 'uint256', 'uint256','uint256', 'bytes memory');
    function mintByAlignment_SignedMessage(uint8 _alignment, uint256 _numberOfTokens, uint256 _maxAmountOfTokens, uint256 _setPrice, uint256 expirationTimestamp, uint256 _nonce, bytes memory _sig) public payable{
        // check validity and execute
        require(expirationTimestamp <= block.timestamp, "Expired");
        require(_numberOfTokens <= _maxAmountOfTokens, "Amount too big");
        bytes32 message = SignedMessages.prefixed(keccak256(abi.encodePacked(msg.sender, _alignment, _maxAmountOfTokens, _setPrice, expirationTimestamp, _nonce)));
        require(msg.value == _setPrice * _numberOfTokens, "Wrong payment");
        require(SignedMessages.consumePass(message, _sig, _nonce), "Error in signed msg");
        _internalMintRandom(msg.sender, _numberOfTokens, _alignment);
        if (msg.value > 0) {
            emit FundsReceived(msg.sender, msg.value, "payment by minting sale");
        }
    }

    function mintAnyAlignment_SignedMessage(uint8 _alignment, uint256 _numberOfTokens, uint256 _maxAmountOfTokens, uint256 _setPrice, uint256 expirationTimestamp, uint256 _nonce, bytes memory _sig) public payable{
        // check validity and execute
        require(expirationTimestamp <= block.timestamp, "Expired");
        require(_numberOfTokens <= _maxAmountOfTokens, "Amount too big");
        bytes32 message = SignedMessages.prefixed(keccak256(abi.encodePacked(msg.sender, _maxAmountOfTokens, _setPrice, expirationTimestamp, _nonce)));
        require(msg.value == _setPrice * _numberOfTokens, "Wrong payment");
        require(SignedMessages.consumePass(message, _sig, _nonce), "Error in signed msg");
        _internalMintRandom(msg.sender, _numberOfTokens, _alignment);
        if (msg.value > 0) {
            emit FundsReceived(msg.sender, msg.value, "payment by minting sale");
        }
    }
    
    /*
     * Withdrawal functions
    */
    function withdrawToOwner() public onlyOwner(){
        EscrowManagement._withdrawToOwner(owner());
    }
    
    // these functions are meant to help retrieve ERC721, ERC1155 and ERC20 tokens that have been sent to this contract
    function withdrawERC721(address _contract, uint256 id, address to) public onlyOwner(){
        EscrowManagement._withdrawERC721(_contract, id, to);
    }
    
    function withdrawERC1155(address _contract, uint256[] memory ids, uint256[] memory amounts, address to) public onlyOwner(){
        // withdraw a 1155 token
        EscrowManagement._withdrawERC1155(_contract, ids, amounts, to);
    }
    
    function withdrawERC20(address _contract, address to, uint256 amount) public onlyOwner(){
        // withdraw a 20 token
        EscrowManagement._withdrawERC20(_contract, to, amount);
    }
    
    function balanceOf(address owner) public view override(ERC721) returns (uint256) {
        return super.balanceOf(owner);
    }

    function transferSplitByOwner(address from, address to, uint8 split) public onlyOwner(){
        // allow the contract owner to change the split, if anything with withdrawals goes wrong, or a team member loses access to their EOA
        EscrowManagement._transferSplit(from, to, split);
    }
        
    function tokensOfOwner(address owner) public view returns (uint256[] memory){
        // allow this function only after the minting has happened for passed owner
        require(block.number > mintingBlockByOwners[owner], "Hello @0xnietzsche");
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // The address has no tokens
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;

/*
 * Manage different baseURIs per tokenSegments.
 * A segment is defined by a starting and and ending index.
 * The last added segment that fits a passed ID wins over previous ones.
 * A segment can be changed back to an empty string.
 * A segment can be determined by passing a tokenId
 * */

contract TokenSegments{
    string[] segmentBaseURIs;
    uint256[] tokenSegmentsStartingIndex;
    uint256[] tokenSegmentsEndingIndex;

    function _setSegmentBaseTokenURIs(uint256 startingIndex, uint256 endingIndex, string memory _URI) internal{
        tokenSegmentsStartingIndex.push(startingIndex);
        tokenSegmentsEndingIndex.push(endingIndex);
        segmentBaseURIs.push(_URI);
    }

    function getSegmentId(uint256 pointer) public view returns(int256){
        // go backwards, so that segments can be overwritten by adding them
        if (tokenSegmentsStartingIndex.length == 0) {
            return -1;
        }
        for (int256 i = int256(tokenSegmentsStartingIndex.length - 1); i >= 0; i--) {
            if ((tokenSegmentsStartingIndex[uint256(i)] <= pointer) && (tokenSegmentsEndingIndex[uint256(i)] >= pointer)) {
                return i;
            }
        }
        return -1;
    }

    function getSegmentBaseURI(uint256 tokenId) public view returns(string memory){
        int256 segmentId = getSegmentId(tokenId);
        if (segmentId == -1) {
            return "";
        }
        return segmentBaseURIs[uint256(segmentId)];
    }

    function getBaseURIBySegmentId(int256 pointer) public view returns(string memory){
        return segmentBaseURIs[uint256(pointer)];
    }

    function _setBaseURIBySegmentId(int256 pointer, string memory _URI) internal{
        segmentBaseURIs[uint256(pointer)] = _URI;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// handles the signed messages
contract SignedMessages{
    mapping(uint256 => bool) internal nonces;
    mapping(address => bool) internal issuers;

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function consumePass(bytes32 message, bytes memory sig, uint256 nonce) internal returns(bool){
        // check the nonce first
        if (nonces[nonce]) {
            return false;
        }
        // check the issuer
        if (!issuers[recoverSigner(message, sig)]) {
            return false;
        }
        // consume the nonce if it is safe
        nonces[nonce] = true;
        return true;
    }

    function validateNonce(uint256 _nonce) public view returns(bool){
        return nonces[_nonce];
    }

    function setIssuer(address issuer, bool status) internal{
        issuers[issuer] = status;
    }

    function getIssuerStatus(address issuer) public view returns(bool){
        return issuers[issuer];
    }

    function recoverSigner(bytes32 _message, bytes memory sig) internal pure returns(address){
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(_message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns(uint8, bytes32, bytes32){
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r:= mload(add(sig, 32))
            // second 32 bytes
            s:= mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v:= byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

abstract contract ERC1155Interface{
	function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data) public virtual;
}

abstract contract ERC721Interface{
    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual;
}

abstract contract ERC20Interface{
    function transfer(address recipient, uint256 amount) public virtual returns(bool);
}

contract EscrowManagement is ReentrancyGuard, ERC721Holder, ERC1155Holder{
    address[] internal teamMembers;
    mapping (address => uint8) internal teamMembersSplit;
    
    modifier onlyTeamMembers(){
        require(teamMembersSplit[msg.sender] > 0, "No team member");
        _;
    }
    function _getTeamMembers() internal view returns(address[] memory){
        return teamMembers;
    }
    
    function getTeamMemberSplit(address teamMember) public view returns(uint8){
        return teamMembersSplit[teamMember];
    }
    /*
    *   Escrow and withdrawal functions for decentral team members
    */
    function _addTeamMemberSplit(address teamMember, uint8 split) internal{
        require(teamMembersSplit[teamMember] == 0, "Team member already added");
        require(split<101, "Split too big");
        teamMembers.push(teamMember);
        teamMembersSplit[teamMember] = split;
    }

    function _transferSplit(address from, address to, uint8 split) internal{
        // transfer split from one member to another
        // the caller has to be a team member
        require(split <= teamMembersSplit[from], "Split too big");
        if (teamMembersSplit[to] == 0) {
            // if to was not yet a team member, then welcome
            teamMembers.push(to);
        }
        teamMembersSplit[from] = teamMembersSplit[from] - split;
        teamMembersSplit[to] = teamMembersSplit[to] + split;
    }

    function transferSplit(address from, address to, uint8 split) public nonReentrant onlyTeamMembers(){
        // the from has the be the caller for team members
        require(msg.sender == from, "Not the sender");
        _transferSplit(from, to, split);
    }
    
	// withdraw - pays out the team members by the defined distribution
	// every call pays out the actual balance to all team members
    // this function can be called by anyone
    function withdraw() public nonReentrant{
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");
        uint256 amountOfTeamMembers = teamMembers.length;
        require(amountOfTeamMembers >0, "0 team members found");
        // in order to distribute everything and take care of rests due to the division, the first team members gets the rest
        // i=1 -> we start with the second member, the first goes after the for
        bool success;
        for (uint256 i=1;  i<amountOfTeamMembers; i++) {
            uint256 payoutAmount = balance /100 * teamMembersSplit[teamMembers[i]];
            // only payout if amount is positive
            if (payoutAmount > 0){
                (success, ) = (payable(teamMembers[i])).call{value:payoutAmount}("");
                //(payable(teamMembers[i])).transfer(payoutAmount);
                require(success, "Withdraw failed");
            }
        }
        // payout the rest to first team member
        (success, ) = (payable(teamMembers[0])).call{value:address(this).balance}("");
        //(payable(teamMembers[0])).transfer(address(this).balance);
        require(success, "Withdraw failed-0");
    }
    
    // this function is for safety, if no team members have been defined
    function _withdrawToOwner(address owner) internal{
        require(teamMembers.length == 0, "Team members are defined");
        (bool success, ) = (payable(owner)).call{value:address(this).balance}("");
        //(payable(owner)).transfer(address(this).balance);
        require(success, "Withdraw failed.");
    }
    
    // these functions are meant to help retrieve ERC721, ERC1155 and ERC20 tokens that have been sent to this contract
    function _withdrawERC721(address _contract, uint256 id, address to) internal{
        // withdraw a 721 token
        ERC721Interface ERC721Contract = ERC721Interface(_contract);
        // transfer ownership from this contract to the specified address
        ERC721Contract.safeTransferFrom(address(this), to,id);
    }
    
    function _withdrawERC1155(address _contract, uint256[] memory ids, uint256[] memory amounts, address to) internal{
        // withdraw a 1155 token
        ERC1155Interface ERC1155Contract = ERC1155Interface(_contract);
        // transfer ownership from this contract to the specified address
        ERC1155Contract.safeBatchTransferFrom(address(this),to,ids,amounts,'');
    }
    
    function _withdrawERC20(address _contract, address to, uint256 amount) internal{
        // withdraw a 20 token
        ERC20Interface ERC20Contract = ERC20Interface(_contract);
        // transfer ownership from this contract to the specified address
        ERC20Contract.transfer(to, amount);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}