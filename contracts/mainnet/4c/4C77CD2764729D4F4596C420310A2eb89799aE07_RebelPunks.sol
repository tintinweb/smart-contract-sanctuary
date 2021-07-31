// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import './console.sol';

import './UniformRandomNumber.sol';

/**
 *   ____        _            _
 *  |  _ \  ___ | |__    ___ | |
 *  | |_) |/ _ \| '_ \  / _ \| |
 *  |  _ <|  __/| |_) ||  __/| |
 *  |_| \_\\___||_.__/  \___||_|
 *   ____                 _
 *  |  _ \  _   _  _ __  | | __ ___
 *  | |_) || | | || '_ \ | |/ // __|
 *  |  __/ | |_| || | | ||   < \__ \
 *  |_|     \__,_||_| |_||_|\_\|___/
 *
 * An NFT project from Tavatar.io
 *
 */
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC2981 is IERC165 {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface BokkyDateTime {
    function getYear(uint timestamp) external view returns (uint);
    function getMonth(uint timestamp) external view returns (uint);
    function getDay(uint timestamp) external view returns (uint);
    function getHour(uint timestamp) external view returns (uint);
    function getMinute(uint timestamp) external view returns (uint);
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) external view returns (uint timestamp);
}

interface ERC721TokenReceiver
{
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

contract RebelPunks is IERC721 {

    using SafeMath for uint256;

    /**
     * Event emitted when minting a new NFT.
     */
    event Mint(uint indexed index, address indexed minter);

    /**
     * Event emitted when the public sale begins.
     */
    event SaleBegins();

    /**
     * Event emitted when a punk rebels.
     */
    event HasRebelled(uint indexed index, address indexed to);

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint public constant TOKEN_LIMIT = 10000;
    uint public constant MAX_REBEL_PURCHASE = 20;

    mapping(bytes4 => bool) internal supportedInterfaces;

    mapping (uint256 => address) internal idToOwner;

    mapping (uint256 => address) internal idToApproval;

    mapping (address => mapping (address => bool)) internal ownerToOperators;

    mapping(address => uint256[]) internal ownerToIds;

    mapping(uint256 => uint256) internal idToOwnerIndex;

    string internal nftName = "RebelPunks";
    string internal nftSymbol = unicode"∞PUNK";

    uint internal numTokens = 0;

    address payable internal deployer;
    address payable internal beneficiary1;
    address payable internal beneficiary2;
    bool public publicSale = false;
    uint private price;
    uint public saleStartTime;

    //// Random index assignment
    uint[TOKEN_LIMIT] internal indices;

    //// Secure Minting
    string public baseURI;
    string public uriExtension;
    bool public uriLock = false;

    //// Market
    bool public marketPaused = false;
    bool public contractSealed = false;

    //// Rebellion Mechanic
    mapping(address => uint256) internal rebelLeadersCount;
    uint rebellionNonce;
    bool public rebellionLock = true;
    bool public cannotUpdateRebellionLock = false;

    //// NEW REBELLION
    uint public rebellionPointer = 0;
    uint[TOKEN_LIMIT] internal rebellionStatus;
    mapping(uint => uint) internal rebellionStatusMap;
    uint public rebellionPointerResetDate;

    //// Date Time contract
    address internal dateTime;
    BokkyDateTime internal dateTimeInstance;

    bool private reentrancyLock = false;

    /***********************************|
    |        Modifiers                  |
    |__________________________________*/
    modifier uriIsUnlocked() {
        require(uriLock == false, "URI can no longer be updated.");
        _;
    }

    /**
    * @dev This checks that rebellion() can be fired.
    * It will be up to the community to audit rebellion and choose if it should be activated or not.
    * We will default to activating it unless a glaring bug is found.
    */
    modifier rebellionIsUnlocked() {
        require(rebellionLock == true, "Rebellion is locked.");
        _;
    }

    /**
    * @dev once it's decided to keep rebellion on or off the state will be locked so there is no guessing if it will change.
    */
    modifier rebellionIsUpdateable() {
        require(cannotUpdateRebellionLock == false, "Rebellion state cannot be updated.");
        _;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], "Cannot operate.");
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender], "Cannot transfer."
        );
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "Invalid token.");
        _;
    }

    modifier onlyOnFourTwenty() {
        uint currentTime = block.timestamp;
        uint currentYear = dateTimeInstance.getYear(currentTime);
        uint begin420Timestamp = dateTimeInstance.timestampFromDateTime(currentYear,4,20,14,0,0); // 10AM EST is 2PM(14:00) UTC
        uint end420Timestamp   = dateTimeInstance.timestampFromDateTime(currentYear,4,21,4,0,0);  // 12AM EST is 4AM UTC
        require((currentTime >= begin420Timestamp && currentTime < end420Timestamp), "Yo, it's not 420. Get back to work.");
        _;
    }

    modifier saleStarted () {
        require(publicSale, "Sale not started.");
        _;
    }

    /***********************************|
    |        Constructor                |
    |__________________________________*/
    constructor(address _dateTime, address payable _beneficiary1, address payable _beneficiary2, string memory _baseURI, string memory _uriExtension) {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
        supportedInterfaces[0x2a55205a] = true; // EIP2981 Royalty
        deployer = msg.sender;
        dateTime = _dateTime;
        dateTimeInstance = BokkyDateTime(dateTime);
        beneficiary1 = _beneficiary1;
        beneficiary2 = _beneficiary2;
        baseURI = _baseURI;
        uriExtension = _uriExtension;

        _resetRebellionPointer();
    }

    /***********************************|
    |        Function                   |
    |__________________________________*/
    uint256 public basePercent = 250; //2.5%
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount){
        // _tokenId is unimportant because it's a fixed amount. I can imagine situations where it would not be a fixed amount

        uint256 roundValue = SafeMath.ceil(_salePrice, basePercent);
        console.log(roundValue);
        uint256 twoPtFivePercent = SafeMath.div(SafeMath.mul(roundValue, basePercent), 10000);

        receiver = beneficiary1;
        royaltyAmount = twoPtFivePercent;
    }

    /**
    * @dev Marks all tokens owned by a user compliant for the next 4/20
    */
    function heartBeatOwner() public {
        _heartBeatAddress(msg.sender);
    }

    /**
    * @dev Marks a specific token as compliant for the next 4/20
    * @param _token is the NFT token index
    */
    function heartBeatToken(uint _token) public validNFToken(_token) {
        _heartBeatToken(_token);
    }

    /**
    * @dev Internal function calls _heartBeatToken for each token owned by msg.sender
    * @param _to The address of msg.sender
    */
    function _heartBeatAddress(address _to) internal {
        uint tokensOwned = _getOwnerNFTCount(_to);
        for(uint m = 0; m < tokensOwned; m++) {
            uint tokenId = ownerToIds[_to][m];
            _heartBeatToken(tokenId);
        }
    }

    /**
    * @dev Internal function resets the rebellion pointer the first time _heartBeatToken is called after 4/20. rebellionPointerResetDate is set to midnight EST or 4am UTC.
    * Tokens that heartbeat are compliant until rebellionPointerResetDate.
    */
    function _resetRebellionPointer() internal {
        rebellionPointer = 0;
        uint currentTime = block.timestamp;
        uint currentYear = dateTimeInstance.getYear(currentTime);
        uint endOfRebellion = dateTimeInstance.timestampFromDateTime(currentYear,4,21,4,0,0);  // 12AM EST is 4AM UTC
        if(endOfRebellion < currentTime){
            endOfRebellion = dateTimeInstance.timestampFromDateTime(currentYear+1,4,21,4,0,0);
        }
        rebellionPointerResetDate = endOfRebellion;
    }

    /**
    * @dev for a number of optimization reasons the compliant and rebellious tokens are all stored in a 10,000 length array.  By using 2 pointers: rebellionPointer & numTokens (I know so Leetcode)
    * we're able to sort in place by moving the compliant Punks to the front half of the array.  This allows us to track compliance after each transaction or heartbeat.  Then when reassigning ownership
    * during rebellion we'll have a presorted list of rebellious and compliant punks to choose from.  This optimization allows for O(C) operations where O(N) are not feasable
    * during rebellion due to gas limitations.  Since the array can not be searched in O(C) a map of NFT index to rebellionStatus array position is continuously updated. That map is rebellionStatusMap.
    * @param _token is the NFT token index
    */
    function _heartBeatToken(uint _token) internal validNFToken(_token) {
        // Checks If Pointer Needs to Be Reset
        if(rebellionPointerResetDate < block.timestamp){
            _resetRebellionPointer();
        }
        if(rebellionPointer == TOKEN_LIMIT){
            return; //All Tokens Compliant
        }else if(rebellionStatusMap[_token] == 0 && rebellionStatus[0] != _token){ //This token has not been minted.  rebellionStatus[x] defaults to zero before being set.
            if(rebellionPointer == (numTokens-1)){ //If all are compliant and minting more tokens.
                rebellionStatus[rebellionPointer] = _token;
                rebellionStatusMap[_token] = rebellionPointer;
                rebellionPointer = rebellionPointer.add(1);
            }else{
                rebellionStatus[numTokens-1] = rebellionStatus[rebellionPointer];
                rebellionStatusMap[rebellionStatus[rebellionPointer]] = numTokens-1;
                rebellionStatus[rebellionPointer] = _token;
                rebellionStatusMap[_token] = rebellionPointer;
                rebellionPointer = rebellionPointer.add(1);
            }
        }else if(rebellionStatusMap[_token] < rebellionPointer){ //Compliant
            return;
        }else{ //Token has been minted. Post rebellion.
            //Array in place movement - Moves value in rebellion to pointer tip and moves value at pointer tip to the _tokens previous location.
            rebellionStatus[rebellionStatusMap[_token]] = rebellionStatus[rebellionPointer]; //Push current tip of in rebellion further out in the array.
            rebellionStatusMap[rebellionStatus[rebellionPointer]] = rebellionStatusMap[_token];

            rebellionStatus[rebellionPointer] = _token; //assign _token to current rebelPointer Tip.
            rebellionStatusMap[_token] = rebellionPointer;

            rebellionPointer = rebellionPointer.add(1);
        }
    }

    /**
    * @dev Internal function returns a "pseudo" random number in range 0 to (max - 1).  https://github.com/pooltogether/uniform-random-number
    * @param max is the number of values to choose between. the value returend
    */
    function random(uint max) internal returns (uint _randomNumber) {
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, rebellionNonce)));
        _randomNumber = UniformRandomNumber.uniform(randomness, max);
        rebellionNonce++;
        return _randomNumber;
    }

    /**
    * @dev transfers a rebellious NFT index to a compliant owner.  Completes this transfer by picking a random NFT index in the compliant section of of the rebellionStatus[] array
    *      and assiging the rebellious index to the owner of the selected compliant index.
    * @param indexInRebellion is the NFT index of a rebellious Punk.
    * @param maxCompliant is the number of compliant Punks to choose from for reassignment.
    */
    function _rebel(uint indexInRebellion, uint maxCompliant) private {
        address luckyRandomCompliantOwner = idToOwner[rebellionStatus[random(maxCompliant)]];//get compliant.length, get a number in that range, get the value of compliant at that number, get the address that owns that id.
        _transfer(luckyRandomCompliantOwner, indexInRebellion);
        emit HasRebelled(indexInRebellion, luckyRandomCompliantOwner);
    }

    /**
    * @dev read only function says weather an NFT index will be eligible to rebel in the upcoming 4/20.
    * @param _nftIndex is the NFT token index
    * @return _willRebelBool true == will rebel. false == will not rebel
    */
    function idWillRebel(uint _nftIndex) external view returns(bool _willRebelBool){
        return _idWillRebel(_nftIndex);
    }

    /**
    * @dev internal function calculated weather an NFT index will be eligible to rebel in the upcoming 4/20. Used within idWillRebel() and ownerWillRebel().
    * @param _nftIndex is the NFT token index
    * @return _willRebelBool true == will rebel. false == will not rebel
    */
    function _idWillRebel(uint _nftIndex) internal view returns(bool _willRebelBool){
        if(numTokens == 0){
            _willRebelBool = false;
        }else if(rebellionStatusMap[_nftIndex] < rebellionPointer){
            _willRebelBool = false;
        }else{
            _willRebelBool = true;
        }
    }

    /**
    * @dev Calculates how many of an owners NFT index tokens will be eligible to rebel in the upcoming 4/20.
    * @param _owner the address of a specific token holder
    * @return _willRebelCount the number of an owners tokens that will rebel.
    */
    function ownerWillRebel(address _owner) external view returns(uint _willRebelCount){
        uint counter = 0;
        uint tokensOwned = _getOwnerNFTCount(_owner);
        for(uint m = 0; m < tokensOwned; m++) {
            uint tokenId = ownerToIds[_owner][m];
            if(_idWillRebel(tokenId)){
                counter++;
            }
        }
        return counter;
    }

    /**
    * @dev toggles the ability to call rebellion().  This function is included so that pending public deployment the rebellion function can be turned off until a full review
    * has taken place by the community.  Pending no errors rebellion will be turned on and locked.  Should there be any potential for abuse rebellion may be locked in the off position.
    * @param _rebellionLockState true == rebellion cannot be called. false == rebellion can be called.
    */
    function toggleRebellionLock(bool _rebellionLockState) external onlyDeployer rebellionIsUpdateable {
        rebellionLock = _rebellionLockState;
    }

    /**
    * @dev Once called the rebellionLock will remain forever at its current value. Post community review rebellion() can be locked on or locked off. Either way locking rebellion()
    * removes any doubt as to wether or not the function will or will not be callable in the future.
    */
    function lockRebellionState() external onlyDeployer {
        cannotUpdateRebellionLock = true; //I dont like that this is a negative version of (false == cant update instead of locked == true)
    }

    /**
    * @dev Each year on 4/20 between 10AM-12AM EST rebellion can be called. Each call of rebellion transfers up to 20 NFT tokens from inactive wallets to active token holders.
    * Rebel Punks is a seat at the table. If you don't interact with the contract one per year you risk losing your seat at the table.
    * Those addresses who call rebellion are noted in the rebelLeadersCount map which records how many Punks they have liberated.  High scores gain street cred.
    */
    function rebellion() external saleStarted rebellionIsUnlocked onlyOnFourTwenty reentrancyGuard {
        if(rebellionPointer == 0 && numTokens != 0){ //None Compliant
            return;
        }else if(rebellionPointer == numTokens){ //All Compliant
            return;
        }else{
            uint numberInRebellion = numTokens - rebellionPointer;
            if(numberInRebellion > 20){
                numberInRebellion = 20;
            }
            for (uint z = 0; z < numberInRebellion; z++) {
                _rebel(rebellionStatus[rebellionPointer], rebellionPointer);
            }
            rebelLeadersCount[msg.sender] += numberInRebellion; //DOes this
        }
    }

    /**
    * @dev Returns the number of rebellious Punks liberated by a specific address.
    * @param _rebelLeader address
    * @return _rebelCount the number of rebellious Punks liberated by the specified address.
    */
    function getRebelLeaderCount(address _rebelLeader) external view returns (uint _rebelCount) {
        _rebelCount = rebelLeadersCount[_rebelLeader];
    }

    /**
    * @dev Makes minting available.
    * @param _price the minting cost in Wei.
    */
    function startSale(uint _price) external onlyDeployer {
        _startSale(_price);
    }

    /**
    * @dev Internal function - Makes minting available.
    * @param _price the minting cost in Wei.
    */
    function _startSale(uint _price) private {
        require(!publicSale);
        price = _price;
        saleStartTime = block.timestamp;
        publicSale = true;
        emit SaleBegins();
    }

    /**
    * @dev Pauses and unpauses the minting process.  Provided as a safe guard.
    * @param _paused true == pause, false == unpause.
    */
    function pauseMarket(bool _paused) external onlyDeployer {
        require(!contractSealed, "Contract sealed.");
        marketPaused = _paused;
    }

    /**
    * @dev Locks minting in its current paused or unpaused state.
    */
    function sealContract() external onlyDeployer {
        contractSealed = true;
    }

    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        return size > 0;
    }

    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Wrong from address.");
        require(_to != address(0), "Cannot send to 0x0.");
        _transfer(_to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner) external view override returns (uint256 _balance) {
        _balance = _getOwnerNFTCount(_owner);
    }

    function ownerOf(uint256 _tokenId) external view override returns (address _owner) {
        require(idToOwner[_tokenId] != address(0));
        _owner = idToOwner[_tokenId];
    }

    function getApproved(uint256 _tokenId) external view override validNFToken(_tokenId) returns (address _approvalAddress) {
        _approvalAddress = idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool _isApprovedForAll) {
        _isApprovedForAll = ownerToOperators[_owner][_operator];
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];

        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);
        _heartBeatToken(_tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function randomIndex() internal returns (uint) {
        uint totalSize = TOKEN_LIMIT - numTokens;
        uint index = random(totalSize);
        uint value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        // Don't allow a zero index, start counting at 1
        return value.add(1);
    }

    function getPrice() public view saleStarted returns (uint _price) {
        return price;
    }

    function mintsRemaining() external view returns (uint _remaining) {
        _remaining = TOKEN_LIMIT.sub(numTokens);
    }

    /**
    * @dev Public sale minting.
    */
    function mint(uint numberOfTokens) external payable saleStarted reentrancyGuard {
        require(numberOfTokens <= MAX_REBEL_PURCHASE, "Can only mint 20 tokens at a time.");
        require(numberOfTokens > 0, "Must mint at least 1 rebel.");
        require(!marketPaused, "Rebels have paused all operations.");
        require(numTokens.add(numberOfTokens) <= TOKEN_LIMIT, "Purchase would exceed max supply of Rebels.");
        require(price.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct.");
        if (msg.value > price.mul(numberOfTokens)) {
            msg.sender.transfer(msg.value.sub(price.mul(numberOfTokens))); //Refund Excess
        }
        beneficiary1.transfer(numberOfTokens.mul(price.mul(70)).div(100));
        beneficiary2.transfer(numberOfTokens.mul(price.mul(30)).div(100));
        for(uint i = 0; i < numberOfTokens; i++) {
            if (numTokens < TOKEN_LIMIT) {
                _mint(msg.sender);
            }
        }
    }

    function _mint(address _to) internal {
        require(_to != address(0), "Cannot mint to 0x0.");
        require(numTokens < TOKEN_LIMIT, "Token limit reached.");

        uint id = randomIndex();

        numTokens = numTokens + 1;
        _addNFToken(_to, id);
        _heartBeatToken(id);

        emit Mint(id, _to);
        emit Transfer(address(0), _to, id);
    }

    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0), "Cannot add, already owned.");
        idToOwner[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length.sub(1);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from, "Incorrect owner.");
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length.sub(1);

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    function _getOwnerNFTCount(address _owner) internal view returns (uint256 _count) {
        _count = ownerToIds[_owner].length;
    }

    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Incorrect owner.");
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    //// Enumerable

    function totalSupply() public view returns (uint256 _total) {
        _total = numTokens;
    }

    function tokenByIndex(uint256 index) public pure returns (uint256 _token) {
        require(index >= 0 && index < TOKEN_LIMIT);
        _token = index + 1;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _token) {
        require(_index < ownerToIds[_owner].length);
        _token = ownerToIds[_owner][_index];
    }

    //// Metadata

    /**
      * @dev Converts a `uint256` to its ASCII `string` representation.
      */
    function toString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

    /**
      * @dev Returns a descriptive name for a collection of NFTokens.
      * @return _name Representing name.
      */
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     * @return _symbol Representing symbol.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _tokenId Id for which we want uri.
     * @return _tokenURI URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory _tokenURI) {
        _tokenURI = string(abi.encodePacked(baseURI, toString(_tokenId), uriExtension));
    }

    /**
     * @dev For public minting uri will be a localized server, after minting uri will be updated to IFPS and locked. Note: all images are already on IFPS
     * @param _newBaseURI is the new base URI, presumable a new IPFS hash to be updated post minting.
     */
    function updateURI(string memory _newBaseURI, string memory _newUriExtension) external onlyDeployer uriIsUnlocked {
        baseURI = _newBaseURI;
        uriExtension = _newUriExtension;
    }

    /**
    * @dev Locks the URI at it's current value. Will be called post minting so that the URI perminently points to IPFS without the possibility of changing.
    */
    function lockURI() external onlyDeployer {
        uriLock = true;
    }
}