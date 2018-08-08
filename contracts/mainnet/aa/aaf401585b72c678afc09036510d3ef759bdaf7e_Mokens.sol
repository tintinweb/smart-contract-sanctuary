// Author: Nick Mudge <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="8ae4e3e9e1cafaeff8ecefe9feebe8f9fef8ebe9fee3e5e4f9a4e9e5e7">[email&#160;protected]</a>>
// Perfect Abstractions LLC

pragma solidity 0.4.24;

interface ERC721TokenReceiver {


    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `safetransfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns (bytes4);
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */
interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _tokenOwner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _tokenOwner, address indexed _operator, bool _approved);

    function balanceOf(address _tokenOwner) external view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) external view returns (address _tokenOwner);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function approve(address _to, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address _operator);

    function isApprovedForAll(address _tokenOwner, address _operator) external view returns (bool);
}

interface ERC20AndERC223 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function transfer(address to, uint value) external returns (bool success);
    function transfer(address to, uint value, bytes data) external returns (bool success);
}


interface ERC998ERC721BottomUp {
    function transferToParent(address _from, address _toContract, uint256 _toTokenId, uint256 _tokenId, bytes _data) external;

}

contract AbstractMokens {
    address public owner;

    struct Moken {
        string name;
        uint256 data;
        uint256 parentTokenId;
    }

    //tokenId to moken
    mapping(uint256 => Moken) internal mokens;
    uint256 internal mokensLength = 0;

    // tokenId => token API URL
    string public defaultURIStart = "https://api.mokens.io/moken/";
    string public defaultURIEnd = ".json";

    // the block number Mokens is deployed in
    uint256 public blockNum;

    // index to era
    mapping(uint256 => bytes32) internal eras;
    uint256 internal eraLength = 0;
    // era to index+1
    mapping(bytes32 => uint256) internal eraIndex;

    uint256 public mintPriceOffset = 0 szabo;
    uint256 public mintStepPrice = 500 szabo;
    uint256 public mintPriceBuffer = 5000 szabo;

    /// @dev Magic value to be returned upon successful reception of an NFT
    bytes4 constant ERC721_RECEIVED_NEW = 0x150b7a02;
    bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
    bytes32 constant ERC998_MAGIC_VALUE = 0xcd740db5;

    uint256 constant UINT16_MASK = 0x000000000000000000000000000000000000000000000000000000000000ffff;
    uint256 constant MOKEN_LINK_HASH_MASK = 0xffffffffffffffff000000000000000000000000000000000000000000000000;
    uint256 constant MOKEN_DATA_MASK = 0x0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant MAX_MOKENS = 4294967296;
    uint256 constant MAX_OWNER_MOKENS = 65536;

    // root token owner address => (tokenId => approved address)
    mapping(address => mapping(uint256 => address)) internal rootOwnerAndTokenIdToApprovedAddress;

    // token owner => (operator address => bool)
    mapping(address => mapping(address => bool)) internal tokenOwnerToOperators;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint32[]) internal ownedTokens;

    // child address => child tokenId => tokenId+1
    mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;

    // tokenId => (child address => array of child tokens)
    mapping(uint256 => mapping(address => uint256[])) internal childTokens;

    // tokenId => (child address => (child token => child index)
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal childTokenIndex;

    // tokenId => (child address => contract index)
    mapping(uint256 => mapping(address => uint256)) internal childContractIndex;

    // tokenId => child contract
    mapping(uint256 => address[]) internal childContracts;

    // tokenId => token contract
    mapping(uint256 => address[]) internal erc20Contracts;

    // tokenId => (token contract => balance)
    mapping(uint256 => mapping(address => uint256)) internal erc20Balances;

    // parent address => (parent tokenId => array of child tokenIds)
    mapping(address => mapping(uint256 => uint32[])) internal parentToChildTokenIds;

    // tokenId => position in childTokens array
    mapping(uint256 => uint256) internal tokenIdToChildTokenIdsIndex;

    address[] internal mintContracts;
    mapping(address => uint256) internal mintContractIndex;

    //moken name to tokenId+1
    mapping(string => uint256) internal tokenByName_;

    // tokenId => (token contract => token contract index)
    mapping(uint256 => mapping(address => uint256)) erc20ContractIndex;

    // contract that contains other functions needed
    address public delegate;

    mapping(bytes4 => bool) internal supportedInterfaces;


    // Events
    // ERC721
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _tokenOwner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _tokenOwner, address indexed _operator, bool _approved);
    //ERC998ERC721TopDown
    event ReceivedChild(address indexed _from, uint256 indexed _tokenId, address indexed _childContract, uint256 _childTokenId);
    event TransferChild(uint256 indexed tokenId, address indexed _to, address indexed _childContract, uint256 _childTokenId);
    //ERC998ERC20TopDown
    event ReceivedERC20(address indexed _from, uint256 indexed _tokenId, address indexed _erc20Contract, uint256 _value);
    event TransferERC20(uint256 indexed _tokenId, address indexed _to, address indexed _erc20Contract, uint256 _value);

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Must be the contract owner.");
        _;
    }

    /*
    function getSize() external view returns (uint256) {
        uint256 size;
        address addr = address(this);
        assembly {size := extcodesize(addr)}
        return size;
    }
    */

    // Use Cases handled:
    // Case 1: Token owner is this contract and token
    // Case 2: Token owner is this contract and top-down composable.
    // Case 3: Token owner is top-down composable
    // Case 4: Token owner is an unknown contract
    // Case 5: Token owner is a user
    // Case 6: Token owner is a bottom-up composable
    // Case 7: Token owner is ERC721 token owned by top-down token
    // Case 8: Token owner is ERC721 token owned by unknown contract
    // Case 9: Token owner is ERC721 token owned by user
    function rootOwnerOf(uint256 _tokenId) public view returns (bytes32 rootOwner) {
        address rootOwnerAddress = address(mokens[_tokenId].data);
        require(rootOwnerAddress != address(0), "tokenId not found.");
        uint256 parentTokenId;
        bool isParent;

        while (rootOwnerAddress == address(this)) {
            parentTokenId = mokens[_tokenId].parentTokenId;
            isParent = parentTokenId > 0;
            if(isParent) {
                // Case 1: Token owner is this contract and token
                _tokenId = parentTokenId - 1;
            }
            else {
                // Case 2: Token owner is this contract and top-down composable.
                _tokenId = childTokenOwner[rootOwnerAddress][_tokenId]-1;
            }
            rootOwnerAddress = address(mokens[_tokenId].data);
        }

        parentTokenId = mokens[_tokenId].parentTokenId;
        isParent = parentTokenId > 0;
        if(isParent) {
            parentTokenId--;
        }

        bytes memory calldata;
        bool callSuccess;

        if (isParent == false) {

            // success if this token is owned by a top-down token
            // 0xed81cdda == rootOwnerOfChild(address,uint256)
            calldata = abi.encodeWithSelector(0xed81cdda, address(this), _tokenId);
            assembly {
                callSuccess := staticcall(gas, rootOwnerAddress, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                if callSuccess {
                    rootOwner := mload(calldata)
                }
            }
            if (callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
                // Case 3: Token owner is top-down composable
                return rootOwner;
            }
            else {
                // Case 4: Token owner is an unknown contract
                // Or
                // Case 5: Token owner is a user
                return ERC998_MAGIC_VALUE << 224 | bytes32(rootOwnerAddress);
            }
        }
        else {

            // 0x43a61a8e == rootOwnerOf(uint256)
            calldata = abi.encodeWithSelector(0x43a61a8e, parentTokenId);
            assembly {
                callSuccess := staticcall(gas, rootOwnerAddress, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                if callSuccess {
                    rootOwner := mload(calldata)
                }
            }
            if (callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
                // Case 6: Token owner is a bottom-up composable
                // Or
                // Case 2: Token owner is top-down composable
                return rootOwner;
            }
            else {
                // token owner is ERC721
                address childContract = rootOwnerAddress;
                //0x6352211e == "ownerOf(uint256)"
                calldata = abi.encodeWithSelector(0x6352211e, parentTokenId);
                assembly {
                    callSuccess := staticcall(gas, rootOwnerAddress, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                    if callSuccess {
                        rootOwnerAddress := mload(calldata)
                    }
                }
                require(callSuccess, "Call to ownerOf failed");

                // 0xed81cdda == rootOwnerOfChild(address,uint256)
                calldata = abi.encodeWithSelector(0xed81cdda, childContract, parentTokenId);
                assembly {
                    callSuccess := staticcall(gas, rootOwnerAddress, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                    if callSuccess {
                        rootOwner := mload(calldata)
                    }
                }
                if (callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
                    // Case 7: Token owner is ERC721 token owned by top-down token
                    return rootOwner;
                }
                else {
                    // Case 8: Token owner is ERC721 token owned by unknown contract
                    // Or
                    // Case 9: Token owner is ERC721 token owned by user
                    return ERC998_MAGIC_VALUE << 224 | bytes32(rootOwnerAddress);
                }
            }
        }
    }

    // returns the owner at the top of the tree of composables
    function rootOwnerOfChild(address _childContract, uint256 _childTokenId) public view returns (bytes32 rootOwner) {
        uint256 tokenId;
        if (_childContract != address(0)) {
            tokenId = childTokenOwner[_childContract][_childTokenId];
            require(tokenId != 0, "Child token does not exist");
            tokenId--;
        }
        else {
            tokenId = _childTokenId;
        }
        return rootOwnerOf(tokenId);
    }


    function childApproved(address _from, uint256 _tokenId) internal {
        address approvedAddress = rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
        if(msg.sender != _from) {
            bytes32 tokenOwner;
            bool callSuccess;
            // 0xeadb80b8 == ownerOfChild(address,uint256)
            bytes memory calldata = abi.encodeWithSelector(0xed81cdda, address(this), _tokenId);
            assembly {
                callSuccess := staticcall(gas, _from, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                if callSuccess {
                    tokenOwner := mload(calldata)
                }
            }
            if(callSuccess == true) {
                require(tokenOwner >> 224 != ERC998_MAGIC_VALUE, "Token is child of top down composable");
            }
            require(tokenOwnerToOperators[_from][msg.sender] || approvedAddress == msg.sender, "msg.sender not _from/operator/approved.");
        }
        if (approvedAddress != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
            emit Approval(_from, address(0), _tokenId);
        }
    }

    function _transferFrom(uint256 data, address _to, uint256 _tokenId) internal {
        address _from = address(data);
        //removing the tokenId
        // 1. We replace _tokenId in ownedTokens[_from] with the last token id
        //    in ownedTokens[_from]
        uint256 lastTokenIndex = ownedTokens[_from].length - 1;
        uint256 lastTokenId = ownedTokens[_from][lastTokenIndex];
        if (lastTokenId != _tokenId) {
            uint256 tokenIndex = data >> 160 & UINT16_MASK;
            ownedTokens[_from][tokenIndex] = uint32(lastTokenId);
            // 2. We set lastTokeId to point to its new position in ownedTokens[_from]
            mokens[lastTokenId].data = mokens[lastTokenId].data & 0xffffffffffffffffffff0000ffffffffffffffffffffffffffffffffffffffff | tokenIndex << 160;
        }
        // 3. We remove lastTokenId from the end of ownedTokens[_from]
        ownedTokens[_from].length--;

        //adding the tokenId
        uint256 ownedTokensIndex = ownedTokens[_to].length;
        // prevents 16 bit overflow
        require(ownedTokensIndex < MAX_OWNER_MOKENS, "A token owner address cannot possess more than 65,536 mokens.");
        mokens[_tokenId].data = data & 0xffffffffffffffffffff00000000000000000000000000000000000000000000 | ownedTokensIndex << 160 | uint256(_to);
        ownedTokens[_to].push(uint32(_tokenId));

        emit Transfer(_from, _to, _tokenId);
    }

}

// Author: Nick Mudge <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a1cfc8c2cae1d1c4d3c7c4c2d5c0c3d2d5d3c0c2d5c8cecfd28fc2cecc">[email&#160;protected]</a>>
// Perfect Abstractions LLC

contract Mokens is AbstractMokens {

    constructor(address _delegate) public {
        delegate = _delegate;
        blockNum = block.number;
        owner = msg.sender;
        bytes32 startingEra = "Genesis";
        bytes memory calldata = abi.encodeWithSignature("startNextEra(bytes32)", startingEra);
        bool callSuccess;
        assembly {
            callSuccess := delegatecall(gas, _delegate, add(calldata, 0x20), mload(calldata), 0, 0)
        }
        require(callSuccess);

        //ERC165
        supportedInterfaces[0x01ffc9a7] = true;
        //ERC721
        supportedInterfaces[0x80ac58cd] = true;
        //ERC721Metadata
        supportedInterfaces[0x5b5e139f] = true;
        //ERC721Enumerable
        supportedInterfaces[0x780e9d63] = true;
        //onERC721Received new
        supportedInterfaces[0x150b7a02] = true;
        //onERC721Received old
        supportedInterfaces[0xf0b9e5ba] = true;
        //ERC998ERC721TopDown
        supportedInterfaces[0x1efdf36a] = true;
        //ERC998ERC721TopDownEnumerable
        supportedInterfaces[0xa344afe4] = true;
        //ERC998ERC20TopDown
        supportedInterfaces[0x7294ffed] = true;
        //ERC998ERC20TopDownEnumerable
        supportedInterfaces[0xc5fd96cd] = true;
        //ERC998ERC721BottomUp
        supportedInterfaces[0xa1b23002] = true;
        //ERC998ERC721BottomUpEnumerable
        supportedInterfaces[0x8318b539] = true;
    }


    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC165Impl ***********************************************************/
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }


    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC721Impl  & ERC998 Authentication ****************************************/

    function balanceOf(address _tokenOwner) external view returns (uint256 totalMokensOwned) {
        require(_tokenOwner != address(0), "Moken owner cannot be the 0 address.");
        return ownedTokens[_tokenOwner].length;
    }

    function ownerOf(uint256 _tokenId) external view returns (address tokenOwner) {
        tokenOwner = address(mokens[_tokenId].data);
        require(tokenOwner != address(0), "The tokenId does not exist.");
        return tokenOwner;
    }

    function approve(address _approved, uint256 _tokenId) external {
        address rootOwner = address(rootOwnerOf(_tokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender], "Must be rootOwner or operator.");
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] = _approved;
        emit Approval(rootOwner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) external view returns (address approvedAddress) {
        address rootOwner = address(rootOwnerOf(_tokenId));
        return rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }


    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0), "Operator cannot be 0 address.");
        tokenOwnerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _tokenOwner, address _operator) external view returns (bool approved) {
        return tokenOwnerToOperators[_tokenOwner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(_from != address(0), "_from cannot be the 0 address.");
        require(_to != address(0), "_to cannot be the 0 address.");
        uint256 data = mokens[_tokenId].data;
        require(address(data) == _from, "The tokenId is not owned by _from.");
        require(_to != address(this), "Cannot transfer to this contract.");
        require(mokens[_tokenId].parentTokenId == 0, "Cannot transfer from an address when owned by a token.");
        childApproved(_from, _tokenId);
        _transferFrom(data, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        require(_from != address(0), "_from cannot be the 0 address.");
        require(_to != address(0), "_to cannot be the 0 address.");
        uint256 data = mokens[_tokenId].data;
        require(address(data) == _from, "The tokenId is not owned by _from.");
        require(mokens[_tokenId].parentTokenId == 0, "Cannot transfer from an address when owned by a token.");
        childApproved(_from, _tokenId);
        _transferFrom(data, _to, _tokenId);
        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "");
            require(retval == ERC721_RECEIVED_NEW, "_to contract cannot receive ERC721 tokens.");
        }

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        require(_from != address(0), "_from cannot be the 0 address.");
        require(_to != address(0), "_to cannot be the 0 address.");
        uint256 data = mokens[_tokenId].data;
        require(address(data) == _from, "The tokenId is not owned by _from.");
        require(mokens[_tokenId].parentTokenId == 0, "Cannot transfer from an address when owned by a token.");
        childApproved(_from, _tokenId);
        _transferFrom(data, _to, _tokenId);

        if (_to == address(this)) {
            require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the token to.");
            uint256 toTokenId;
            assembly {toTokenId := calldataload(164)}
            if (_data.length < 32) {
                toTokenId = toTokenId >> 256 - _data.length * 8;
            }
            receiveChild(_from, toTokenId, _to, _tokenId);
        }
        else {
            if (isContract(_to)) {
                bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
                require(retval == ERC721_RECEIVED_NEW, "_to contract cannot receive ERC721 tokens.");
            }
        }

    }




    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC721EnumerableImpl **************************************************/

    function exists(uint256 _tokenId) external view returns (bool) {
        return _tokenId < mokensLength;
    }

    function tokenOfOwnerByIndex(address _tokenOwner, uint256 _index) external view returns (uint256 tokenId) {
        require(_index < ownedTokens[_tokenOwner].length, "_tokenOwner does not own a moken at this index.");
        return ownedTokens[_tokenOwner][_index];
    }

    function totalSupply() external view returns (uint256 totalMokens) {
        return mokensLength;
    }

    function tokenByIndex(uint256 _index) external view returns (uint256 tokenId) {
        require(_index < mokensLength, "A tokenId at index does not exist.");
        return _index;
    }
    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC721MetadataImpl **************************************************/

    function name() external pure returns (string) {
        return "Mokens";
    }

    function symbol() external pure returns (string) {
        return "MKN";
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Eras  **************************************************/


    function eraByIndex(uint256 _index) external view returns (bytes32 era) {
        require(_index < eraLength, "No era at this index.");
        return eras[_index];
    }


    function eraByName(bytes32 _eraName) external view returns (uint256 indexOfEra) {
        uint256 index = eraIndex[_eraName];
        require(index != 0, "No era exists with this name.");
        return index - 1;
    }

    function currentEra() external view returns (bytes32 era) {
        return eras[eraLength - 1];
    }

    function currentEraIndex() external view returns (uint256 indexOfEra) {
        return eraLength - 1;
    }

    function eraExists(bytes32 _eraName) external view returns (bool) {
        return eraIndex[_eraName] != 0;
    }

    function totalEras() external view returns (uint256 totalEras_) {
        return eraLength;
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Minting  **************************************************/
    event Mint(
        address indexed mintContract,
        address indexed owner,
        bytes32 indexed era,
        string mokenName,
        bytes32 data,
        uint256 tokenId,
        bytes32 currencyName,
        uint256 price
    );


    event MintPriceChange(
        uint256 mintPrice
    );

    function mintData() external view returns (uint256 mokensLength_, uint256 mintStepPrice_, uint256 mintPriceOffset_) {
        return (mokensLength, mintStepPrice, mintPriceOffset);
    }

    function mintPrice() external view returns (uint256) {
        return (mokensLength * mintStepPrice) - mintPriceOffset;
    }


    function mint(address _tokenOwner, string _mokenName, bytes32 _linkHash) external payable returns (uint256 tokenId) {

        require(_tokenOwner != address(0), "Owner cannot be the 0 address.");

        tokenId = mokensLength++;
        // prevents 32 bit overflow
        require(tokenId < MAX_MOKENS, "Only 4,294,967,296 mokens can be created.");
        uint256 mintStepPrice_ = mintStepPrice;
        uint256 mintPriceBuffer_ = mintPriceBuffer;

        //Was enough ether passed in?
        uint256 currentMintPrice = (tokenId * mintStepPrice_) - mintPriceOffset;
        uint256 pricePaid = currentMintPrice;
        if (msg.value < currentMintPrice) {
            require(mintPriceBuffer_ > currentMintPrice || msg.value > currentMintPrice - mintPriceBuffer_, "Paid ether is lower than mint price.");
            pricePaid = msg.value;
        }

        string memory lowerMokenName = validateAndLower(_mokenName);
        require(tokenByName_[lowerMokenName] == 0, "Moken name already exists.");

        uint256 eraIndex_ = eraLength - 1;
        uint256 ownedTokensIndex = ownedTokens[_tokenOwner].length;
        // prevents 16 bit overflow
        require(ownedTokensIndex < MAX_OWNER_MOKENS, "An single owner address cannot possess more than 65,536 mokens.");

        // adding the current era index, ownedTokenIndex and owner address to data
        // this saves gas for each mint.
        uint256 data = uint256(_linkHash) & MOKEN_LINK_HASH_MASK | eraIndex_ << 176 | ownedTokensIndex << 160 | uint160(_tokenOwner);

        // create moken
        mokens[tokenId].name = _mokenName;
        mokens[tokenId].data = data;
        tokenByName_[lowerMokenName] = tokenId + 1;

        //add moken to the specific owner
        ownedTokens[_tokenOwner].push(uint32(tokenId));

        //emit events
        emit Transfer(address(0), _tokenOwner, tokenId);
        emit Mint(this, _tokenOwner, eras[eraIndex_], _mokenName, bytes32(data), tokenId, "Ether", pricePaid);
        emit MintPriceChange(currentMintPrice + mintStepPrice_);

        //send minter the change if any
        if (msg.value > currentMintPrice) {
            msg.sender.transfer(msg.value - currentMintPrice);
        }

        return tokenId;
    }

    function isMintContract(address _contract) public view returns (bool) {
        return mintContractIndex[_contract] != 0;
    }

    function totalMintContracts() external view returns (uint256 totalMintContracts_) {
        return mintContracts.length;
    }

    function mintContractByIndex(uint256 index) external view returns (address contract_) {
        require(index < mintContracts.length, "Contract index does not exist.");
        return mintContracts[index];
    }

    // enables third-party contracts to mint mokens.
    // enables the ability to accept other currency/tokens for payment.
    function contractMint(address _tokenOwner, string _mokenName, bytes32 _linkHash, bytes32 _currencyName, uint256 _pricePaid) external returns (uint256 tokenId) {

        require(_tokenOwner != address(0), "Token owner cannot be the 0 address.");
        require(isMintContract(msg.sender), "Not an approved mint contract.");

        tokenId = mokensLength++;
        uint256 mokensLength_ = tokenId + 1;
        // prevents 32 bit overflow
        require(tokenId < MAX_MOKENS, "Only 4,294,967,296 mokens can be created.");

        string memory lowerMokenName = validateAndLower(_mokenName);
        require(tokenByName_[lowerMokenName] == 0, "Moken name already exists.");

        uint256 eraIndex_ = eraLength - 1;
        uint256 ownedTokensIndex = ownedTokens[_tokenOwner].length;
        // prevents 16 bit overflow
        require(ownedTokensIndex < MAX_OWNER_MOKENS, "An single token owner address cannot possess more than 65,536 mokens.");

        // adding the current era index, ownedTokenIndex and owner address to data
        // this saves gas for each mint.
        uint256 data = uint256(_linkHash) & MOKEN_LINK_HASH_MASK | eraIndex_ << 176 | ownedTokensIndex << 160 | uint160(_tokenOwner);

        // create moken
        mokens[tokenId].name = _mokenName;
        mokens[tokenId].data = data;
        tokenByName_[lowerMokenName] = mokensLength_;

        //add moken to the specific owner
        ownedTokens[_tokenOwner].push(uint32(tokenId));

        emit Transfer(address(0), _tokenOwner, tokenId);
        emit Mint(msg.sender, _tokenOwner, eras[eraIndex_], _mokenName, bytes32(data), tokenId, _currencyName, _pricePaid);
        emit MintPriceChange((mokensLength_ * mintStepPrice) - mintPriceOffset);

        return tokenId;
    }


    function validateAndLower(string _s) private pure returns (string mokenName) {
        assembly {
        // get length of _s
            let len := mload(_s)
        // get position of _s
            let p := add(_s, 0x20)
        // _s cannot be 0 characters
            if eq(len, 0) {
                revert(0, 0)
            }
        // _s cannot be more than 100 characters
            if gt(len, 100) {
                revert(0, 0)
            }
        // get first character
            let b := byte(0, mload(add(_s, 0x20)))
        // first character cannot be whitespace/unprintable
            if lt(b, 0x21) {
                revert(0, 0)
            }
        // get last character
            b := byte(0, mload(add(p, sub(len, 1))))
        // last character cannot be whitespace/unprintable
            if lt(b, 0x21) {
                revert(0, 0)
            }
        // loop through _s and lowercase uppercase characters
            for {let end := add(p, len)}
            lt(p, end)
            {p := add(p, 1)}
            {
                b := byte(0, mload(p))
                if lt(b, 0x5b) {
                    if gt(b, 0x40) {
                        mstore8(p, add(b, 32))
                    }
                }
            }
        }
        return _s;
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Mokens  **************************************************/

    function mokenNameExists(string _mokenName) external view returns (bool) {
        return tokenByName_[validateAndLower(_mokenName)] != 0;
    }

    function mokenId(string _mokenName) external view returns (uint256 tokenId) {
        tokenId = tokenByName_[validateAndLower(_mokenName)];
        require(tokenId != 0, "No moken exists with this name.");
        return tokenId - 1;
    }

    function mokenData(uint256 _tokenId) external view returns (bytes32 data) {
        data = bytes32(mokens[_tokenId].data);
        require(data != 0, "The tokenId does not exist.");
        return data;
    }

    function eraFromMokenData(bytes32 _data) public view returns (bytes32 era) {
        return eras[uint256(_data) >> 176 & UINT16_MASK];
    }

    function eraFromMokenData(uint256 _data) public view returns (bytes32 era) {
        return eras[_data >> 176 & UINT16_MASK];
    }

    function mokenEra(uint256 _tokenId) external view returns (bytes32 era) {
        uint256 data = mokens[_tokenId].data;
        require(data != 0, "The tokenId does not exist.");
        return eraFromMokenData(data);
    }

    function moken(uint256 _tokenId) external view
    returns (string memory mokenName, bytes32 era, bytes32 data, address tokenOwner) {
        data = bytes32(mokens[_tokenId].data);
        require(data != 0, "The tokenId does not exist.");
        return (
        mokens[_tokenId].name,
        eraFromMokenData(data),
        data,
        address(data)
        );
    }

    function mokenBytes32(uint256 _tokenId) external view
    returns (bytes32 mokenNameBytes32, bytes32 era, bytes32 data, address tokenOwner) {
        data = bytes32(mokens[_tokenId].data);
        require(data != 0, "The tokenId does not exist.");
        bytes memory mokenNameBytes = bytes(mokens[_tokenId].name);
        require(mokenNameBytes.length != 0, "The tokenId does not exist.");
        assembly {
            mokenNameBytes32 := mload(add(mokenNameBytes, 32))
        }
        return (
        mokenNameBytes32,
        eraFromMokenData(data),
        data,
        address(data)
        );
    }


    function mokenNoName(uint256 _tokenId) external view
    returns (bytes32 era, bytes32 data, address tokenOwner) {
        data = bytes32(mokens[_tokenId].data);
        require(data != 0, "The tokenId does not exist.");
        return (
        eraFromMokenData(data),
        data,
        address(data)
        );
    }

    function mokenName(uint256 _tokenId) external view returns (string memory mokenName_) {
        mokenName_ = mokens[_tokenId].name;
        require(bytes(mokenName_).length != 0, "The tokenId does not exist.");
        return mokenName_;
    }

    function mokenNameBytes32(uint256 _tokenId) external view returns (bytes32 mokenNameBytes32_) {
        bytes memory mokenNameBytes = bytes(mokens[_tokenId].name);
        require(mokenNameBytes.length != 0, "The tokenId does not exist.");
        assembly {
            mokenNameBytes32_ := mload(add(mokenNameBytes, 32))
        }
        return mokenNameBytes32_;
    }


    function() external {
        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(gas, sload(delegate_slot), add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }

    // functions added here to reduce gas cost

    //////////////////////////////////////////////////////////
    //ERC721 top down

    function receiveChild(address _from, uint256 _toTokenId, address _childContract, uint256 _childTokenId) internal {
        require(address(mokens[_toTokenId].data) != address(0), "_tokenId does not exist.");
        require(childTokenOwner[_childContract][_childTokenId] == 0, "Child token already received.");
        uint256 childTokensLength = childTokens[_toTokenId][_childContract].length;
        if (childTokensLength == 0) {
            childContractIndex[_toTokenId][_childContract] = childContracts[_toTokenId].length;
            childContracts[_toTokenId].push(_childContract);
        }
        childTokenIndex[_toTokenId][_childContract][_childTokenId] = childTokensLength;
        childTokens[_toTokenId][_childContract].push(_childTokenId);
        childTokenOwner[_childContract][_childTokenId] = _toTokenId + 1;
        emit ReceivedChild(_from, _toTokenId, _childContract, _childTokenId);
    }

    // this contract has to be approved first in _childContract
    function getChild(address _from, uint256 _toTokenId, address _childContract, uint256 _childTokenId) external {
        receiveChild(_from, _toTokenId, _childContract, _childTokenId);
        require(_from == msg.sender ||
        ERC721(_childContract).getApproved(_childTokenId) == msg.sender ||
        ERC721(_childContract).isApprovedForAll(_from, msg.sender), "msg.sender is not owner/operator/approved for child token.");
        ERC721(_childContract).transferFrom(_from, this, _childTokenId);
    }

    function onERC721Received(address _from, uint256 _childTokenId, bytes _data) external returns (bytes4) {
        require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
        // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
        uint256 toTokenId;
        assembly {toTokenId := calldataload(132)}
        if (_data.length < 32) {
            toTokenId = toTokenId >> 256 - _data.length * 8;
        }
        receiveChild(_from, toTokenId, msg.sender, _childTokenId);
        require(ERC721(msg.sender).ownerOf(_childTokenId) != address(0), "Child token not owned.");
        return ERC721_RECEIVED_OLD;
    }


    function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes _data) external returns (bytes4) {
        require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
        // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
        uint256 toTokenId;
        assembly {toTokenId := calldataload(164)}
        if (_data.length < 32) {
            toTokenId = toTokenId >> 256 - _data.length * 8;
        }
        receiveChild(_from, toTokenId, msg.sender, _childTokenId);
        require(ERC721(msg.sender).ownerOf(_childTokenId) != address(0), "Child token not owned.");
        return ERC721_RECEIVED_NEW;
    }

    function ownerOfChild(address _childContract, uint256 _childTokenId) external view returns (bytes32 parentTokenOwner, uint256 parentTokenId) {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId != 0, "ERC721 token is not a child in this contract.");
        parentTokenId--;
        return (ERC998_MAGIC_VALUE << 224 | bytes32(address(mokens[parentTokenId].data)), parentTokenId);
    }

    function childExists(address _childContract, uint256 _childTokenId) external view returns (bool) {
        return childTokenOwner[_childContract][_childTokenId] != 0;
    }

    function totalChildContracts(uint256 _tokenId) external view returns (uint256) {
        return childContracts[_tokenId].length;
    }

    function childContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address childContract) {
        require(_index < childContracts[_tokenId].length, "Contract address does not exist for this token and index.");
        return childContracts[_tokenId][_index];
    }

    function totalChildTokens(uint256 _tokenId, address _childContract) external view returns (uint256) {
        return childTokens[_tokenId][_childContract].length;
    }

    function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external view returns (uint256 childTokenId) {
        require(_index < childTokens[_tokenId][_childContract].length, "Token does not own a child token at contract address and index.");
        return childTokens[_tokenId][_childContract][_index];
    }


    //////////////////////////////////////////////////////////
    //ERC20 top down
    function balanceOfERC20(uint256 _tokenId, address _erc20Contract) external view returns (uint256) {
        return erc20Balances[_tokenId][_erc20Contract];
    }

    function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address) {
        require(_index < erc20Contracts[_tokenId].length, "Contract address does not exist for this token and index.");
        return erc20Contracts[_tokenId][_index];
    }

    function totalERC20Contracts(uint256 _tokenId) external view returns (uint256) {
        return erc20Contracts[_tokenId].length;
    }

    //////////////////////////////////////////////////////////
    //ERC721 bottom up

    function tokenOwnerOf(uint256 _tokenId) external view returns (bytes32 tokenOwner, uint256 parentTokenId, bool isParent) {
        address tokenOwnerAddress = address(mokens[_tokenId].data);
        require(tokenOwnerAddress != address(0), "tokenId not found.");
        parentTokenId = mokens[_tokenId].parentTokenId;
        isParent = parentTokenId > 0;
        if (isParent) {
            parentTokenId--;
        }
        return (ERC998_MAGIC_VALUE << 224 | bytes32(tokenOwnerAddress), parentTokenId, isParent);
    }


    function totalChildTokens(address _parentContract, uint256 _parentTokenId) public view returns (uint256) {
        return parentToChildTokenIds[_parentContract][_parentTokenId].length;
    }

    function childTokenByIndex(address _parentContract, uint256 _parentTokenId, uint256 _index) public view returns (uint256) {
        require(parentToChildTokenIds[_parentContract][_parentTokenId].length > _index, "Child not found at index.");
        return parentToChildTokenIds[_parentContract][_parentTokenId][_index];
    }
}