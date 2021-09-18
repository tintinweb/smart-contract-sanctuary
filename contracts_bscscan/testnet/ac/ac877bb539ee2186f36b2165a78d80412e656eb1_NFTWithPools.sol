/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

library EnumerableSet {
    struct UintSet {
        uint256[] _values;
        mapping (uint256 => uint256) _indexes;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        if (contains(set, value)) {
            return false;
        }

        set._values.push(value);
        set._indexes[value] = set._values.length;
        return true;
    }


    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            uint256 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            set._values.pop();
            delete set._indexes[value];

            return true;
        } 
        else {
            return false;
        }
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    function values(UintSet storage set) internal view returns (uint256[] memory _vals) {
        return set._values;
    }
}

library Errors {
    string constant NOT_OWNER = 'Only owner';
    string constant INVALID_TOKEN_ID = 'Invalid token id';
    string constant MINTING_DISABLED = 'Minting disabled';
    string constant TRANSFER_NOT_APPROVED = 'Transfer not approved by owner';
    string constant OPERATION_NOT_APPROVED = 'Operations with token not approved';
    string constant ZERO_ADDRESS = 'Address can not be 0x0';
    string constant ALL_MINTED = "All tokens are minted";
    string constant NOT_ENOUGH_TOKENS = "Insufficient funds to purchase";
    string constant WRONG_FROM = "The 'from' address does not own the token";
    string constant REENTRANCY_LOCKED = 'Reentrancy is locked';
    string constant RANDOM_FAIL = 'Random generation failed';
    string constant NOTHING_ON_SALE = 'There are no tokens on sale';
    string constant INDEX_INCORRECT = 'Incorrect index for array';
    string constant MINTING_IS_NOT_FINISHED = 'Minting is not finished yet';
    string constant CALLER_IS_NOT_MINTER = 'You cannot use functions for minter role';
    string constant CALLER_IS_NOT_WITHDRAWAL = 'You cannot use functions for token claimer role';
    string constant USER_IS_NOT_HOLDER = 'You are not holder';
}

library Utils {
    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
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
        return string(bstr);
    }
    
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }
}


interface ITRC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in TRC-165
    /// @dev Interface identification is specified in TRC-165. This function
    ///  uses less than 30,000 energy.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

}

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;
    function getApproved(uint256 _tokenId) external view returns (address);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

/**
 * Interface for verifying ownership during Community Grant.
 */
interface IERC721TokenReceiver {
    function onTRC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

interface IERC721Metadata {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    //Returns the URI of the external file corresponding to ‘_tokenId’. External resource files need to include names, descriptions and pictures. 
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}


interface IERC721Enumerable {
    //Return the total supply of NFT
    function totalSupply() external view returns (uint256);

    //Return the corresponding ‘tokenId’ through ‘_index’
    function tokenByIndex(uint256 _index) external view returns (uint256);

     //Return the ‘tokenId’ corresponding to the index in the NFT list owned by the ‘_owner'
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


contract NFTWithPools is IERC721, ITRC165, IERC721Metadata, IERC721Enumerable {
    using EnumerableSet for EnumerableSet.UintSet;

    string internal _name = "NFTWithPools";
    string internal _symbol = "PM";

    uint256 internal totalMinted = 0;

    uint256 public constant MINTING_LIMIT = 10000;

    uint256 public mintingPrice = 1000000;

    //Service:
    bool internal isReentrancyLock = false;
    address internal contractOwner;
    address internal addressZero = address(0);
    uint8 constant MAXIMUM_MINT_LIMIT = 20;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onTRC721Received.selector`
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    // Random
    uint256 internal nonce = 0;
    uint256[MINTING_LIMIT] internal indices;

    // Supported interfaces
    mapping(bytes4 => bool) internal supportedInterfaces;

    // storage
    mapping (uint256 => address) internal tokenToOwner;
    mapping (address => EnumerableSet.UintSet) internal ownerToTokensSet;
    mapping (uint256 => address) internal tokenToApproval;

    mapping (address => mapping (address => bool)) internal ownerToOperators;

    bool public isMintingEnabled = false;
    
    string public uri;

    /*************************************************************************** */

    bool withdrawPossible;

    uint256 firstStagePool;
    uint256 secondStagePool;

    uint256 firstStageHolders;
    uint256 secondStageHolders;

    uint256 firstStageAmount;
    uint256 secondStageAmount;

    uint256 public firstStage = 30;
    uint256 public secondStage = 150;

    uint256 public firstStageNom = 3;
    uint256 public firstStageDenom = 100;

    uint256 public secondStageNom = 7;
    uint256 public secondStageDenom = 100;

    struct UserStructure {
        bool exists;
        bool withdrawPerformed;
        uint256 mintAmount;
        uint256 level;
        address wallet;
    }

    mapping(address => UserStructure) users;

    /*************************************************************************** */
    //                             Roles

    mapping(address => bool) minters;
    mapping(address => bool) tokenClaimer;
 
    /*************************************************************************** */
    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x150b7a02] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata

        contractOwner = msg.sender;
    }

    /*************************************************************************** */




    /*************************************************************************** */
    //                             IERC721Metadata: 

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function setTokenURI(string memory uri_) external onlyContractOwner {
        uri = uri_;
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(uri, Utils.uintToString(_tokenId)));
    }

    /*************************************************************************** */




    /*************************************************************************** */
    //                             Enumerable: 

    function totalSupply() public view override returns(uint256) {
        return totalMinted;
    }

    function tokenByIndex(uint256 _index) external pure override returns (uint256) {
        require(_index >= 0 && _index < MINTING_LIMIT);
        return _index + 1;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view override returns (uint256 _tokenId) {
        require(_index < ownerToTokensSet[_owner].values().length, Errors.INDEX_INCORRECT);
        return ownerToTokensSet[_owner].values()[_index];
    }

    function getNotMintedAmount() external view returns(uint256) {
        return MINTING_LIMIT - totalMinted;
    }

    /*************************************************************************** */




    /*************************************************************************** */
    //                             IERC165: 
    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    /*************************************************************************** */




    /*************************************************************************** */
    //                             ERC-721: 

    function balanceOf(address _owner) external view override returns (uint256) {
        return ownerToTokensSet[_owner].values().length;
    }

    function ownerOf(uint256 _tokenId) external view override returns (address) {
        return tokenToOwner[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) 
        external override payable 
    {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) 
        external payable override
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable override
        transferApproved(_tokenId)
        validTokenId(_tokenId) 
        notZeroAddress(_to)
    {
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override payable
        validTokenId(_tokenId)
        canOperate(_tokenId)
    {
        address tokenOwner = tokenToOwner[_tokenId];
        if (_approved != tokenOwner) {
            tokenToApproval[_tokenId] = _approved;
            emit Approval(tokenOwner, _approved, _tokenId);
        }
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view override validTokenId(_tokenId)
        returns (address) 
    {
        return tokenToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    /*************************************************************************** */




    /*************************************************************************** */
    //                             

    function getUserTokens(address _user) external view returns (uint256[] memory) {
        return ownerToTokensSet[_user].values();
    }

    /*************************************************************************** */




    /*************************************************************************** */
    //                             Mint:
    function mint() external payable reentrancyGuard mintingEnabled returns (uint256[MAXIMUM_MINT_LIMIT] memory) {
        require(msg.value >= mintingPrice, Errors.NOT_ENOUGH_TOKENS);
        uint256[MAXIMUM_MINT_LIMIT] memory mintedIndexes;
        uint256 amountOfitemsToMint = Utils.min(MAXIMUM_MINT_LIMIT, Utils.min(msg.value/mintingPrice, (MINTING_LIMIT - totalMinted)));
        uint256 totalMintPrice = mintingPrice * amountOfitemsToMint;
        
        if (msg.value > totalMintPrice) {
            payable(msg.sender).transfer(msg.value - totalMintPrice);
        }

        for (uint itemsIndex = 0; itemsIndex < amountOfitemsToMint; itemsIndex++) {
            mintedIndexes[itemsIndex] = _mint(msg.sender);
        }
        
        return mintedIndexes;
    }

    function mintTo(address _tokenReceiver, uint256 amountToMint) external payable reentrancyGuard mintingEnabled onlyMinter returns(uint256[MAXIMUM_MINT_LIMIT] memory) {
        require(amountToMint <= MAXIMUM_MINT_LIMIT);
        uint256[MAXIMUM_MINT_LIMIT] memory mintedIndexes;
        uint256 amountOfitemsToMint = Utils.min(MAXIMUM_MINT_LIMIT, Utils.min(msg.value/mintingPrice, (MINTING_LIMIT - totalMinted)));
        uint256 totalMintPrice = mintingPrice * amountOfitemsToMint;
        
        if (msg.value > totalMintPrice) {
            payable(msg.sender).transfer(msg.value - totalMintPrice);
        }

        for (uint itemsIndex = 0; itemsIndex < amountOfitemsToMint; itemsIndex++) {
            mintedIndexes[itemsIndex] = _mint(msg.sender);
            _transfer(msg.sender, _tokenReceiver, mintedIndexes[itemsIndex]);
        }
    
        return mintedIndexes;
    }

    /*************************************************************************** */




    /*************************************************************************** */
    //                             Internal functions:

    function _mint(address _to) internal notZeroAddress(_to) returns (uint256 _mintedTokenId) {
        require(totalMinted < MINTING_LIMIT, Errors.ALL_MINTED);
        uint randomId = _generateRandomId();
        totalMinted++;
        
        _addToken(_to, randomId);

        if (users[_to].exists) {
            users[_to].mintAmount += 1;
            
            if (users[_to].mintAmount >= firstStage && users[_to].level < 1) {
                users[_to].level = 1;
                firstStageHolders += 1;
            } else if (users[_to].mintAmount >= secondStage && users[_to].level < 2) {
                users[_to].level = 2;
                secondStageHolders += 1;
            }

            if (users[_to].level == 1) {
                firstStageAmount += 1;
                firstStagePool += (mintingPrice * firstStageNom)/firstStageDenom;
            }

            if (users[_to].level == 2) {
                secondStageAmount += 1;
                secondStagePool += (mintingPrice * secondStageNom)/secondStageDenom;
            }

        } else {
            UserStructure memory us = UserStructure({
                exists: true,
                withdrawPerformed: false,
                mintAmount: 1,
                level: 0,
                wallet: _to
            });
            
            users[_to] = us;
        }

        emit Mint(randomId, msg.sender, _to);
        emit Transfer(addressZero, _to, randomId);

        return randomId;
    }
    

    function _addToken(address _to, uint256 _tokenId) private notZeroAddress(_to) {
        tokenToOwner[_tokenId] = _to;
        ownerToTokensSet[_to].add(_tokenId);
    }
    

    function _removeToken(address _from, uint256 _tokenId) private {
        if (tokenToOwner[_tokenId] != _from)
            return;
        
        if (tokenToApproval[_tokenId] != addressZero)
            delete tokenToApproval[_tokenId];
        
        delete tokenToOwner[_tokenId];
        ownerToTokensSet[_from].remove(_tokenId);
    }


    function _transfer(address _from, address _to, uint256 _tokenId) private {
        require(tokenToOwner[_tokenId] == _from, Errors.WRONG_FROM);
        _removeToken(_from, _tokenId);
        _addToken(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private 
        transferApproved(_tokenId) 
        validTokenId(_tokenId) 
        notZeroAddress(_to)
    {
        _transfer(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = IERC721TokenReceiver(_to).onTRC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    /*************************************************************************** */
    //                             Withdraw functionality:

    function withdrawHolderPart() external mintingFinished {
        address receiver = msg.sender;
        require(
            (users[receiver].exists == true) ||
            (users[receiver].level > 0),
            Errors.USER_IS_NOT_HOLDER
        );
        uint256 toPayout = 0;
        
        if (users[receiver].level == 1) {
            toPayout = firstStagePool/firstStageHolders;
        }

        if (users[receiver].level == 2) {
            toPayout = secondStagePool/secondStageHolders + firstStagePool/firstStageHolders;
        }

        payable(msg.sender).transfer(toPayout);
    }



    /*************************************************************************** */
    //                             Admin functions: 

    function _enableMinting() external onlyContractOwner {
        if (!isMintingEnabled) {
            isMintingEnabled = true;
            emit MintingEnabled();
        }
    }

    function _disableMinting() external onlyContractOwner {
        if (isMintingEnabled) {
            isMintingEnabled = false;
            emit MintingDisabled();
        }
    }

    function _setMintingPrice(uint256 newPrice) external onlyContractOwner {
        mintingPrice = newPrice;
    }

    function _claimTokens(uint256 amount) external onlyTokenClaimer {
        require(amount <= address(this).balance);
        payable(contractOwner).transfer(amount);
    }

    function withdraw() external onlyContractOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*************************************************************************** */




    /*************************************************************************** */
    //                             Roles:

    function addMinter(address _minter) external onlyContractOwner {
        minters[_minter] = true;
    }

    function removeMinter(address _minter) external onlyContractOwner {
        minters[_minter] = false;
    }

    function addBalanceWithdrawal(address _tokenClaimer) external onlyContractOwner {
        tokenClaimer[_tokenClaimer] = true;
    }

    function removeBalanceWithdrawal(address _tokenClaimer) external onlyContractOwner {
        tokenClaimer[_tokenClaimer] = false;
    }

    modifier onlyMinter() {
        require(
            (msg.sender == contractOwner) ||
            (minters[msg.sender] == true),
            Errors.CALLER_IS_NOT_MINTER
        );
        _;
    }

    modifier onlyTokenClaimer() {
        require(
            (msg.sender == contractOwner) ||
            (tokenClaimer[msg.sender] == true),
            Errors.CALLER_IS_NOT_WITHDRAWAL
        );
        _;
    }


    /*************************************************************************** */
    



    /*************************************************************************** */
    //                             Service:
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }


    function _generateRandomId() private returns (uint256) {
        uint256 totalSize = MINTING_LIMIT - totalMinted;
        uint256 index = uint256(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint256 value = 0;

        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            indices[index] = totalSize - 1;    // Array position not initialized, so use position
        } else { 
            indices[index] = indices[totalSize - 1];   // Array position holds a value so use that
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value + 1;
    }

    /*************************************************************************** */




    /*************************************************************************** */
    //                             Modifiers: 

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, Errors.NOT_OWNER);
        _;
    }

    modifier reentrancyGuard {
        if (isReentrancyLock) {
            require(!isReentrancyLock, Errors.REENTRANCY_LOCKED);
        }
        isReentrancyLock = true;
        _;
        isReentrancyLock = false;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(tokenToOwner[_tokenId] != addressZero, Errors.INVALID_TOKEN_ID);
        _;
    }

    modifier mintingEnabled() {
        require(isMintingEnabled, Errors.MINTING_DISABLED);
        _;
    }

    modifier transferApproved(uint256 _tokenId) {
        address tokenOwner = tokenToOwner[_tokenId];
        require(
            tokenOwner == msg.sender  || 
            tokenToApproval[_tokenId] == msg.sender || 
            ((ownerToOperators[tokenOwner][msg.sender] == true) && tokenOwner != addressZero), 
            Errors.TRANSFER_NOT_APPROVED
        );
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = tokenToOwner[_tokenId];
        require(
            tokenOwner == msg.sender || 
            ((ownerToOperators[tokenOwner][msg.sender] == true) && tokenOwner != addressZero), 
            Errors.OPERATION_NOT_APPROVED
        );
        _;
    }

    modifier notZeroAddress(address _addr) {
        require(_addr != addressZero, Errors.ZERO_ADDRESS);
        _;
    }

    modifier mintingFinished() {
        require(MINTING_LIMIT == totalMinted, Errors.MINTING_IS_NOT_FINISHED);
        _;
    }

    /*************************************************************************** */



    /*************************************************************************** */
    //                             Events: 

    // NFT minted
    event Mint(uint indexed tokenId, address indexed mintedBy, address indexed mintedTo);
     // TOKENS is deposited into the contract.
    event Deposit(address indexed account, uint amount);
    //TOKENS is withdrawn from the contract.
    event Withdraw(address indexed account, uint amount);

    event MintingEnabled();
    event MintingDisabled();
}