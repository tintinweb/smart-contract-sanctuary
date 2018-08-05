// Author: Nick Mudge <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="620c0b0109221207100407011603001116100301160b0d0c114c010d0f">[email&#160;protected]</a>>
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
    /// @return `bytes4(keccak256(&quot;onERC721Received(address,uint256,bytes)&quot;))`
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
    string public defaultURIStart = &quot;https://api.mokens.io/moken/&quot;;
    string public defaultURIEnd = &quot;.json&quot;;

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
        require(msg.sender == owner, &quot;Must be the contract owner.&quot;);
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
        require(rootOwnerAddress != address(0), &quot;tokenId not found.&quot;);
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
                //0x6352211e == &quot;ownerOf(uint256)&quot;
                calldata = abi.encodeWithSelector(0x6352211e, parentTokenId);
                assembly {
                    callSuccess := staticcall(gas, rootOwnerAddress, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                    if callSuccess {
                        rootOwnerAddress := mload(calldata)
                    }
                }
                require(callSuccess, &quot;Call to ownerOf failed&quot;);

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
            require(tokenId != 0, &quot;Child token does not exist&quot;);
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
                require(tokenOwner >> 224 != ERC998_MAGIC_VALUE, &quot;Token is child of top down composable&quot;);
            }
            require(tokenOwnerToOperators[_from][msg.sender] || approvedAddress == msg.sender, &quot;msg.sender not _from/operator/approved.&quot;);
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
        require(ownedTokensIndex < MAX_OWNER_MOKENS, &quot;A token owner address cannot possess more than 65,536 mokens.&quot;);
        mokens[_tokenId].data = data & 0xffffffffffffffffffff00000000000000000000000000000000000000000000 | ownedTokensIndex << 160 | uint256(_to);
        ownedTokens[_to].push(uint32(_tokenId));

        emit Transfer(_from, _to, _tokenId);
    }

}

// Author: Nick Mudge <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="bdd3d4ded6fdcdd8cfdbd8dec9dcdfcec9cfdcdec9d4d2d3ce93ded2d0">[email&#160;protected]</a>>
// Perfect Abstractions LLC

contract MokensDelegate is AbstractMokens {


    //Events
    event MintPriceConfigurationChange(
        uint256 mintPrice,
        uint256 mintStepPrice,
        uint256 mintPriceOffset,
        uint256 mintPriceBuffer
    );
    event MintPriceChange(
        uint256 mintPrice
    );

    event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 _tokenId);
    event TransferFromParent(address indexed _fromContract, uint256 indexed _fromTokenId, uint256 _tokenId);


    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Contract Management ***********************************************************/

    function withdraw(address _sendTo, uint256 _amount) external onlyOwner {
        address mokensContract = address(this);
        require(_amount <= mokensContract.balance, &quot;Amount is greater than balance.&quot;);
        _sendTo.transfer(_amount);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), &quot;_newOwner cannot be 0 address.&quot;);
        owner = _newOwner;
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* authentication **************************************************/





    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* LinkHash **************************************************/

    event LinkHashChange(
        uint256 indexed tokenId,
        bytes32 linkHash
    );

    // changes the link hash of a moken
    // this enables metadata/content data to be changed for mokens.
    function updateLinkHash(uint256 _tokenId, bytes32 _linkHash) external {
        address rootOwner = address(rootOwnerOf(_tokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender, &quot;msg.sender not rootOwner/operator/approved.&quot;);
        uint256 data = mokens[_tokenId].data & MOKEN_DATA_MASK | uint256(_linkHash) & MOKEN_LINK_HASH_MASK;
        mokens[_tokenId].data = data;
        emit LinkHashChange(_tokenId, bytes32(data));
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC721MetadataImpl Token URL **************************************************/

    function setDefaultURIStart(string _defaultURIStart) external onlyOwner {
        defaultURIStart = _defaultURIStart;
    }

    function setDefaultURIEnd(string _defaultURIEnd) external onlyOwner {
        defaultURIEnd = _defaultURIEnd;
    }

    function tokenURI(uint256 _tokenId) external view returns (string tokenURIString) {
        require(_tokenId < mokensLength, &quot;_tokenId does not exist.&quot;);
        return makeIntString(defaultURIStart, _tokenId, defaultURIEnd);
    }

    // creates a string made from an integer between two strings
    function makeIntString(string startString, uint256 v, string endString) private pure returns (string) {
        uint256 maxlength = 10;
        bytes memory reversed = new bytes(maxlength);
        uint256 numDigits = 0;
        if (v == 0) {
            numDigits = 1;
            reversed[0] = byte(48);
        }
        else {
            while (v != 0) {
                uint256 remainder = v % 10;
                v = v / 10;
                reversed[numDigits++] = byte(48 + remainder);
            }
        }
        bytes memory startStringBytes = bytes(startString);
        bytes memory endStringBytes = bytes(endString);
        uint256 startStringLength = startStringBytes.length;
        uint256 endStringLength = endStringBytes.length;
        bytes memory newStringBytes = new bytes(startStringLength + numDigits + endStringLength);
        uint256 i;
        for (i = 0; i < startStringLength; i++) {
            newStringBytes[i] = startStringBytes[i];
        }
        for (i = 0; i < numDigits; i++) {
            newStringBytes[i + startStringLength] = reversed[numDigits - 1 - i];
        }
        for (i = 0; i < endStringLength; i++) {
            newStringBytes[i + startStringLength + numDigits] = endStringBytes[i];
        }
        return string(newStringBytes);
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Eras  **************************************************/

    event NewEra(
        uint256 index,
        bytes32 name,
        uint256 startTokenId
    );


    function startNextEra_(bytes32 _eraName) private returns (uint256 index, uint256 startTokenId) {
        require(_eraName != 0, &quot;eraName is empty string.&quot;);
        require(eraIndex[_eraName] == 0, &quot;Era name already exists.&quot;);
        startTokenId = mokensLength;
        index = eraLength++;
        eras[index] = _eraName;
        eraIndex[_eraName] = index + 1;
        emit NewEra(index, _eraName, startTokenId);
        return (index, startTokenId);
    }

    // It is predicted that often a new era comes with a mint price change
    function startNextEra(bytes32 _eraName, uint256 _mintStepPrice, uint256 _mintPriceOffset, uint256 _mintPriceBuffer) external onlyOwner
    returns (uint256 index, uint256 startTokenId, uint256 mintPrice) {
        require(_mintStepPrice < 10000 ether, &quot;mintStepPrice must be less than 10,000 ether.&quot;);
        mintStepPrice = _mintStepPrice;
        mintPriceOffset = _mintPriceOffset;
        mintPriceBuffer = _mintPriceBuffer;
        uint256 totalStepPrice = mokensLength * _mintStepPrice;
        require(totalStepPrice >= _mintPriceOffset, &quot;(mokensLength * mintStepPrice) must be greater than or equal to mintPriceOffset.&quot;);
        mintPrice = totalStepPrice - _mintPriceOffset;
        emit MintPriceConfigurationChange(mintPrice, _mintStepPrice, _mintPriceOffset, _mintPriceBuffer);
        emit MintPriceChange(mintPrice);
        (index, startTokenId) = startNextEra_(_eraName);
        return (index, startTokenId, mintPrice);
    }

    function startNextEra(bytes32 _eraName) external onlyOwner returns (uint256 index, uint256 startTokenId) {
        return startNextEra_(_eraName);
    }

    function setMintPrice(uint256 _mintStepPrice, uint256 _mintPriceOffset, uint256 _mintPriceBuffer) external onlyOwner returns (uint256 mintPrice) {
        require(_mintStepPrice < 10000 ether, &quot;mintStepPrice must be less than 10,000 ether.&quot;);
        mintStepPrice = _mintStepPrice;
        mintPriceOffset = _mintPriceOffset;
        mintPriceBuffer = _mintPriceBuffer;
        uint256 totalStepPrice = mokensLength * _mintStepPrice;
        require(totalStepPrice >= _mintPriceOffset, &quot;(mokensLength * mintStepPrice) must be greater than or equal to mintPriceOffset.&quot;);
        mintPrice = totalStepPrice - _mintPriceOffset;
        emit MintPriceConfigurationChange(mintPrice, _mintStepPrice, _mintPriceOffset, _mintPriceBuffer);
        emit MintPriceChange(mintPrice);
        return mintPrice;
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Minting  **************************************************/
    // add contract to list of contracts that can mint mokens
    function addMintContract(address _contract) external onlyOwner {
        require(isContract(_contract), &quot;Address is not a contract.&quot;);
        require(mintContractIndex[_contract] == 0, &quot;Contract already added.&quot;);
        mintContracts.push(_contract);
        mintContractIndex[_contract] = mintContracts.length;
    }

    function removeMintContract(address _contract) external onlyOwner {
        uint256 index = mintContractIndex[_contract];
        require(index != 0, &quot;Mint contract was not added.&quot;);
        uint256 lastIndex = mintContracts.length - 1;
        address lastMintContract = mintContracts[lastIndex];
        mintContracts[index - 1] = lastMintContract;
        mintContractIndex[lastMintContract] = index;
        delete mintContractIndex[_contract];
        mintContracts.length--;
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC998ERC721 Top Down Composable  **************************************************/

    function removeChild(uint256 _fromTokenId, address _childContract, uint256 _childTokenId) private {
        // remove child token
        uint256 lastTokenIndex = childTokens[_fromTokenId][_childContract].length - 1;
        uint256 lastToken = childTokens[_fromTokenId][_childContract][lastTokenIndex];
        if (_childTokenId != lastToken) {
            uint256 tokenIndex = childTokenIndex[_fromTokenId][_childContract][_childTokenId];
            childTokens[_fromTokenId][_childContract][tokenIndex] = lastToken;
            childTokenIndex[_fromTokenId][_childContract][lastToken] = tokenIndex;
        }
        childTokens[_fromTokenId][_childContract].length--;
        delete childTokenIndex[_fromTokenId][_childContract][_childTokenId];
        delete childTokenOwner[_childContract][_childTokenId];

        // remove contract
        if (lastTokenIndex == 0) {
            uint256 lastContractIndex = childContracts[_fromTokenId].length - 1;
            address lastContract = childContracts[_fromTokenId][lastContractIndex];
            if (_childContract != lastContract) {
                uint256 contractIndex = childContractIndex[_fromTokenId][_childContract];
                childContracts[_fromTokenId][contractIndex] = lastContract;
                childContractIndex[_fromTokenId][lastContract] = contractIndex;
            }
            childContracts[_fromTokenId].length--;
            delete childContractIndex[_fromTokenId][_childContract];
        }
    }


    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId != 0, &quot;Child token does not exist&quot;);
        require(_fromTokenId == tokenId - 1, &quot;_fromTokenId does not own the child token.&quot;);
        require(_to != address(0), &quot;_to cannot be 0 address.&quot;);
        address rootOwner = address(rootOwnerOf(_fromTokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_fromTokenId] == msg.sender, &quot;msg.sender not rootOwner/operator/approved.&quot;);
        removeChild(_fromTokenId, _childContract, _childTokenId);
        ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId, bytes _data) external {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId != 0, &quot;Child token does not exist&quot;);
        require(_fromTokenId == tokenId - 1, &quot;_fromTokenId does not own the child token.&quot;);
        require(_to != address(0), &quot;_to cannot be 0 address.&quot;);
        address rootOwner = address(rootOwnerOf(_fromTokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_fromTokenId] == msg.sender, &quot;msg.sender not rootOwner/operator/approved.&quot;);
        removeChild(_fromTokenId, _childContract, _childTokenId);
        ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId, _data);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    function transferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId != 0, &quot;Child token does not exist&quot;);
        require(_fromTokenId == tokenId - 1, &quot;_fromTokenId does not own the child token.&quot;);
        require(_to != address(0), &quot;_to cannot be 0 address.&quot;);
        address rootOwner = address(rootOwnerOf(_fromTokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_fromTokenId] == msg.sender, &quot;msg.sender not rootOwner/operator/approved.&quot;);
        removeChild(_fromTokenId, _childContract, _childTokenId);
        //this is here to be compatible with cryptokitties and other old contracts that require being owner and approved
        // before transferring.
        //It is not required by current standard , so we let it fail if it fails
        //0x095ea7b3 == &quot;approve(address,uint256)&quot;
        bytes memory calldata = abi.encodeWithSelector(0x095ea7b3, this, _childTokenId);
        assembly {
            let success := call(gas, _childContract, 0, add(calldata, 0x20), mload(calldata), calldata, 0)
        }
        ERC721(_childContract).transferFrom(this, _to, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    function transferChildToParent(uint256 _fromTokenId, address _toContract, uint256 _toTokenId, address _childContract, uint256 _childTokenId, bytes _data) external {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId != 0, &quot;Child token does not exist&quot;);
        require(_fromTokenId == tokenId - 1, &quot;_fromTokenId does not own the child token.&quot;);
        require(_toContract != address(0), &quot;_toContract cannot be 0 address.&quot;);
        address rootOwner = address(rootOwnerOf(_fromTokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_fromTokenId] == msg.sender, &quot;msg.sender not rootOwner/operator/approved.&quot;);
        removeChild(_fromTokenId, _childContract, _childTokenId);
        ERC998ERC721BottomUp(_childContract).transferToParent(address(this), _toContract, _toTokenId, _childTokenId, _data);
        emit TransferChild(_fromTokenId, _toContract, _childContract, _childTokenId);
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC998ERC20 Top Down Composable  **************************************************/
    function removeERC20(uint256 _tokenId, address _erc20Contract, uint256 _value) private {
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        require(erc20Balance >= _value, &quot;Not enough token available to transfer.&quot;);
        uint256 newERC20Balance = erc20Balance - _value;
        erc20Balances[_tokenId][_erc20Contract] = newERC20Balance;
        if (newERC20Balance == 0) {
            uint256 lastContractIndex = erc20Contracts[_tokenId].length - 1;
            address lastContract = erc20Contracts[_tokenId][lastContractIndex];
            if (_erc20Contract != lastContract) {
                uint256 contractIndex = erc20ContractIndex[_tokenId][_erc20Contract];
                erc20Contracts[_tokenId][contractIndex] = lastContract;
                erc20ContractIndex[_tokenId][lastContract] = contractIndex;
            }
            erc20Contracts[_tokenId].length--;
            delete erc20ContractIndex[_tokenId][_erc20Contract];
        }
    }


    function transferERC20(uint256 _tokenId, address _to, address _erc20Contract, uint256 _value) external {
        address rootOwner = address(rootOwnerOf(_tokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender, &quot;msg.sender not rootOwner/operator/approved.&quot;);
        require(_to != address(0), &quot;_to cannot be 0 address&quot;);
        removeERC20(_tokenId, _erc20Contract, _value);
        require(ERC20AndERC223(_erc20Contract).transfer(_to, _value), &quot;ERC20 transfer failed.&quot;);
        emit TransferERC20(_tokenId, _to, _erc20Contract, _value);
    }

    // implementation of ERC 223
    function transferERC223(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value, bytes _data) external {
        address rootOwner = address(rootOwnerOf(_tokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender, &quot;msg.sender not rootOwner/operator/approved.&quot;);
        require(_to != address(0), &quot;_to cannot be 0 address&quot;);
        removeERC20(_tokenId, _erc223Contract, _value);
        require(ERC20AndERC223(_erc223Contract).transfer(_to, _value, _data), &quot;ERC223 transfer failed.&quot;);
        emit TransferERC20(_tokenId, _to, _erc223Contract, _value);
    }

    // this contract has to be approved first by _erc20Contract
    function getERC20(address _from, uint256 _tokenId, address _erc20Contract, uint256 _value) public {
        bool allowed = _from == msg.sender;
        if (!allowed) {
            uint256 remaining;
            // 0xdd62ed3e == allowance(address,address)
            bytes memory calldata = abi.encodeWithSelector(0xdd62ed3e, _from, msg.sender);
            bool callSuccess;
            assembly {
                callSuccess := staticcall(gas, _erc20Contract, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                if callSuccess {
                    remaining := mload(calldata)
                }
            }
            require(callSuccess, &quot;call to allowance failed&quot;);
            require(remaining >= _value, &quot;Value greater than remaining&quot;);
            allowed = true;
        }
        require(allowed, &quot;msg.sender not _from and has no allowance.&quot;);
        erc20Received(_from, _tokenId, _erc20Contract, _value);
        require(ERC20AndERC223(_erc20Contract).transferFrom(_from, this, _value), &quot;ERC20 transfer failed.&quot;);
    }

    function erc20Received(address _from, uint256 _tokenId, address _erc20Contract, uint256 _value) private {
        require(address(mokens[_tokenId].data) != address(0), &quot;_tokenId does not exist.&quot;);
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        if (erc20Balance == 0) {
            erc20ContractIndex[_tokenId][_erc20Contract] = erc20Contracts[_tokenId].length;
            erc20Contracts[_tokenId].push(_erc20Contract);
        }
        erc20Balances[_tokenId][_erc20Contract] += _value;
        emit ReceivedERC20(_from, _tokenId, _erc20Contract, _value);
    }

    // used by ERC 223
    function tokenFallback(address _from, uint256 _value, bytes _data) external {
        require(_data.length > 0, &quot;_data must contain the uint256 tokenId to transfer the token to.&quot;);
        require(isContract(msg.sender), &quot;msg.sender is not a contract&quot;);
        // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
        uint256 tokenId;
        assembly {
            tokenId := calldataload(132)
        }
        if (_data.length < 32) {
            tokenId = tokenId >> 256 - _data.length * 8;
        }
        //END TODO
        erc20Received(_from, tokenId, msg.sender, _value);
    }



    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC998ERC721 Bottom Up Composable  **************************************************/

    function removeBottomUpChild(address _fromContract, uint256 _fromTokenId, uint256 _tokenId) internal {
        uint256 lastChildTokenIndex = parentToChildTokenIds[_fromContract][_fromTokenId].length - 1;
        uint256 lastChildTokenId = parentToChildTokenIds[_fromContract][_fromTokenId][lastChildTokenIndex];

        if (_tokenId != lastChildTokenId) {
            uint256 currentChildTokenIndex = tokenIdToChildTokenIdsIndex[_tokenId];
            parentToChildTokenIds[_fromContract][_fromTokenId][currentChildTokenIndex] = uint32(lastChildTokenId);
            tokenIdToChildTokenIdsIndex[lastChildTokenId] = currentChildTokenIndex;
        }
        parentToChildTokenIds[_fromContract][_fromTokenId].length--;
    }

    function transferFromParent(address _fromContract, uint256 _fromTokenId, address _to, uint256 _tokenId, bytes _data) external {
        require(_fromContract != address(0), &quot;_fromContract cannot be the 0 address.&quot;);
        require(_to != address(0), &quot;_to cannot be the 0 address.&quot;);
        uint256 data = mokens[_tokenId].data;
        require(address(data) == _fromContract, &quot;The tokenId is not owned by _fromContract.&quot;);
        uint256 parentTokenId = mokens[_tokenId].parentTokenId;
        require(parentTokenId != 0, &quot;Token does not have a parent token.&quot;);
        require(parentTokenId - 1 == _fromTokenId, &quot;tokenId not owned by _fromTokenId&quot;);

        address rootOwner = address(rootOwnerOf(_tokenId));
        address approvedAddress = rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        approvedAddress == msg.sender, &quot;msg.sender not rootOwner/operator/approved.&quot;);

        if (approvedAddress != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
            emit Approval(rootOwner, address(0), _tokenId);
        }

        mokens[_tokenId].parentTokenId = 0;

        removeBottomUpChild(_fromContract, _fromTokenId, _tokenId);
        delete tokenIdToChildTokenIdsIndex[_tokenId];

        _transferFrom(data, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _fromContract, _tokenId, _data);
            require(retval == ERC721_RECEIVED_NEW, &quot;Contract cannot receive ERC721 token.&quot;);
        }

        emit TransferFromParent(_fromContract, _fromTokenId, _tokenId);

    }

    function transferToParent(address _from, address _toContract, uint256 _toTokenId, uint256 _tokenId, bytes _data) external {
        require(_from != address(0), &quot;_from cannot be the 0 address.&quot;);
        require(_toContract != address(0), &quot;toContract cannot be 0&quot;);
        uint256 data = mokens[_tokenId].data;
        require(address(data) == _from, &quot;The tokenId is not owned by _from.&quot;);
        require(mokens[_tokenId].parentTokenId == 0, &quot;Cannot transfer from address when owned by a token.&quot;);

        childApproved(_from, _tokenId);

        uint256 parentTokenId = _toTokenId + 1;
        assert(parentTokenId > _toTokenId);
        mokens[_tokenId].parentTokenId = parentTokenId;

        uint256 index = parentToChildTokenIds[_toContract][_toTokenId].length;
        parentToChildTokenIds[_toContract][_toTokenId].push(uint32(_tokenId));
        tokenIdToChildTokenIdsIndex[_tokenId] = index;

        _transferFrom(data, _toContract, _tokenId);

        require(ERC721(_toContract).ownerOf(_toTokenId) != address(0), &quot;_toTokenId does not exist&quot;);
        emit TransferToParent(_toContract, _toTokenId, _tokenId);
    }

    function transferAsChild(address _fromContract, uint256 _fromTokenId, address _toContract, uint256 _toTokenId, uint256 _tokenId, bytes _data) external {
        require(_fromContract != address(0), &quot;_fromContract cannot be the 0 address.&quot;);
        require(_toContract != address(0), &quot;_toContract cannot be the 0 address.&quot;);
        uint256 data = mokens[_tokenId].data;
        require(address(data) == _fromContract, &quot;The tokenId is not owned by _fromContract.&quot;);
        uint256 parentTokenId = mokens[_tokenId].parentTokenId;
        require(parentTokenId != 0, &quot;Token does not have a parent token.&quot;);
        require(parentTokenId - 1 == _fromTokenId, &quot;tokenId not owned by _fromTokenId&quot;);

        address rootOwner = address(rootOwnerOf(_tokenId));
        address approvedAddress = rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        approvedAddress == msg.sender, &quot;msg.sender not rootOwner/operator/approved.&quot;);

        if (approvedAddress != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
            emit Approval(rootOwner, address(0), _tokenId);
        }

        removeBottomUpChild(_fromContract, _fromTokenId, _tokenId);

        parentTokenId = _toTokenId + 1;
        assert(parentTokenId > _toTokenId);
        mokens[_tokenId].parentTokenId = parentTokenId;

        uint256 index = parentToChildTokenIds[_toContract][_toTokenId].length;
        parentToChildTokenIds[_toContract][_toTokenId].push(uint32(_tokenId));
        tokenIdToChildTokenIdsIndex[_tokenId] = index;

        _transferFrom(data, _toContract, _tokenId);

        require(ERC721(_toContract).ownerOf(_toTokenId) != address(0), &quot;_toTokenId does not exist&quot;);

        emit Transfer(_fromContract, _toContract, _tokenId);
        emit TransferFromParent(_fromContract, _fromTokenId, _tokenId);
        emit TransferToParent(_toContract, _toTokenId, _tokenId);

    }

    function getStateHash(uint256 _tokenId) public view returns (bytes32 stateHash) {
        address[] memory childContracts_ = childContracts[_tokenId];
        stateHash = keccak256(childContracts_);
        uint256 length = childContracts_.length;
        uint256 i;
        for (i = 0; i < length; i++) {
            stateHash = keccak256(stateHash, childTokens[_tokenId][childContracts_[i]]);
        }

        address[] memory erc20Contracts_ = erc20Contracts[_tokenId];
        stateHash = keccak256(erc20Contracts_);
        length = erc20Contracts_.length;
        for (i = 0; i < length; i++) {
            stateHash = keccak256(stateHash, erc20Balances[_tokenId][erc20Contracts_[i]]);
        }

        uint256 linkHash = mokens[_tokenId].data & MOKEN_LINK_HASH_MASK;
        return keccak256(stateHash, linkHash);
    }

}