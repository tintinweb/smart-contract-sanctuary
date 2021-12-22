// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
// import "@openzeppelin/contracts/utils/introspection/ERC165.sol";  
// import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import './interfaces/IERC998ERC721TopDown.sol';
import './interfaces/IERC998ERC721TopDownEnumerable.sol';
import './interfaces/IERC998ERC721BottomUp.sol';

contract IconGirlNFT is ERC721, Ownable, Pausable, IERC998ERC721TopDown, IERC998ERC721TopDownEnumerable {
    // return this.rootOwnerOf.selector ^ this.rootOwnerOfChild.selector ^
    //   this.tokenOwnerOf.selector ^ this.ownerOfChild.selector;
    bytes32 constant ERC998_MAGIC_VALUE = 0x00000000000000000000000000000000000000000000000000000000cd740db5;

    uint256 tokenCount = 0;

    // tokenId => token owner
    mapping(uint256 => address) internal tokenIdToTokenOwner;

    // root token owner address => (tokenId => approved address)
    mapping(address => mapping(uint256 => address)) internal rootOwnerAndTokenIdToApprovedAddress;

    // token owner address => token count
    mapping(address => uint256) internal tokenOwnerToTokenCount;

    // token owner => (operator address => bool)
    mapping(address => mapping(address => bool)) internal tokenOwnerToOperators;
    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    // constructor(string memory baseURI)
    constructor()
        ERC721("ICGTest on rinkeby", "ICGTEST")
        Ownable()
    {
        setBaseURI("https://api.mooncat.community/traits/");
        _pause(); // Start in a paused state
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    
    function pause() public whenNotPaused onlyOwner {
        _pause();
    }
    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    function totalSupply() public view returns (uint256) {
        return tokenCount;
    }

    // wrapper on minting new 721
    function mint(address _to) public returns (uint256) {
        tokenCount++;
        uint256 tokenCount_ = tokenCount;
        tokenIdToTokenOwner[tokenCount_] = _to;
        tokenOwnerToTokenCount[_to]++;
        _mint(_to, tokenCount_);
        return tokenCount_;
    }
    //from zepellin ERC721Receiver.sol
    //old version
    bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
    //new version
    bytes4 constant ERC721_RECEIVED_NEW = 0x150b7a02;
    function convertAddressToUint(address a) internal pure returns (uint256) {
    return uint256(uint160(a));
    }
    ////////////////////////////////////////////////////////
    // ERC721 implementation
    ////////////////////////////////////////////////////////

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(_addr)}
        return size > 0;
    }

    function rootOwnerOf(uint256 _tokenId) public override view returns (bytes32 rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    // returns the owner at the top of the tree of composables
    // Use Cases handled:
    // Case 1: Token owner is this contract and token.
    // Case 2: Token owner is other top-down composable
    // Case 3: Token owner is other contract
    // Case 4: Token owner is user
    function rootOwnerOfChild(address _childContract, uint256 _childTokenId) public override view returns (bytes32 rootOwner) {
        address rootOwnerAddress;
        if (_childContract != address(0)) {
            (rootOwnerAddress, _childTokenId) = _ownerOfChild(_childContract, _childTokenId);
        }
        else {
            rootOwnerAddress = tokenIdToTokenOwner[_childTokenId];
        }
        // Case 1: Token owner is this contract and token.
        while (rootOwnerAddress == address(this)) {
            (rootOwnerAddress, _childTokenId) = _ownerOfChild(rootOwnerAddress, _childTokenId);
        }

        (bool callSuccess, bytes memory data) = rootOwnerAddress.staticcall(abi.encodeWithSelector(0xed81cdda, address(this), _childTokenId));
        if (data.length != 0) {
            rootOwner = abi.decode(data, (bytes32));
        }

        if(callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
            // Case 2: Token owner is other top-down composable
            return rootOwner;
        }
        else {
            // Case 3: Token owner is other contract
            // Or
            // Case 4: Token owner is user
            uint256 rootOwnerInt = convertAddressToUint(rootOwnerAddress);
            return (ERC998_MAGIC_VALUE << 224) | bytes32(rootOwnerInt);
        }
    }


    // returns the owner at the top of the tree of composables

    function ownerOf(uint256 _tokenId) public override view returns (address tokenOwner) {
        tokenOwner = tokenIdToTokenOwner[_tokenId];
        require(tokenOwner != address(0));
        return tokenOwner;
    }

    function balanceOf(address _tokenOwner) public override view returns (uint256) {
        require(_tokenOwner != address(0));
        return tokenOwnerToTokenCount[_tokenOwner];
    }


    function approve(address _approved, uint256 _tokenId) public override {
        address rootOwner = address(uint160(uint256(rootOwnerOf(_tokenId))));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender]);
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] = _approved;
        emit Approval(rootOwner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public override view returns (address)  {
        address rootOwner = address(uint160(uint256(rootOwnerOf(_tokenId))));
        return rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public override {
        require(_operator != address(0));
        tokenOwnerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public override view returns (bool)  {
        require(_owner != address(0));
        require(_operator != address(0));
        return tokenOwnerToOperators[_owner][_operator];
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) private {
        require(_from != address(0));
        require(tokenIdToTokenOwner[_tokenId] == _from);
        require(_to != address(0));

        if(msg.sender != _from) {
            (bool callSuccess, bytes memory data) = _from.staticcall(abi.encodeWithSelector(0xed81cdda, address(this), _tokenId));
            bytes32 rootOwner = abi.decode(data, (bytes32));

            if(callSuccess == true) {
                require(rootOwner >> 224 != ERC998_MAGIC_VALUE, "Token is child of other top down composable");
            }
            require(tokenOwnerToOperators[_from][msg.sender] ||
            rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId] == msg.sender);
        }

        // clear approval
        if (rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId] != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
            emit Approval(_from, address(0), _tokenId);
        }

        // remove and transfer token
        if (_from != _to) {
            assert(tokenOwnerToTokenCount[_from] > 0);
            tokenOwnerToTokenCount[_from]--;
            tokenIdToTokenOwner[_tokenId] = _to;
            tokenOwnerToTokenCount[_to]++;
        }
        emit Transfer(_from, _to, _tokenId);

    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        _transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
        _transferFrom(_from, _to, _tokenId);
        if (isContract(_to)) {
            bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, "");
            require(retval == ERC721_RECEIVED_OLD);
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) public override {
        _transferFrom(_from, _to, _tokenId);
        if (isContract(_to)) {
            bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == ERC721_RECEIVED_OLD || retval == ERC721_RECEIVED_NEW);
        }
    }

    ////////////////////////////////////////////////////////
    // ERC998ERC721 and ERC998ERC721Enumerable implementation
    ////////////////////////////////////////////////////////

    // tokenId => child contract
    mapping(uint256 => address[]) private childContracts;

    // tokenId => (child address => contract index+1)
    mapping(uint256 => mapping(address => uint256)) private childContractIndex;

    // tokenId => (child address => array of child tokens)
    mapping(uint256 => mapping(address => uint256[])) private childTokens;

    // tokenId => (child address => (child token => child index+1)
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) private childTokenIndex;

    // child address => childId => tokenId
    mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;

    function removeChild(uint256 _tokenId, address _childContract, uint256 _childTokenId) private {
        uint256 tokenIndex = childTokenIndex[_tokenId][_childContract][_childTokenId];
        require(tokenIndex != 0, "Child token not owned by token.");

        // remove child token
        uint256 lastTokenIndex = childTokens[_tokenId][_childContract].length - 1;
        uint256 lastToken = childTokens[_tokenId][_childContract][lastTokenIndex];
        if (_childTokenId == lastToken) {
            childTokens[_tokenId][_childContract][tokenIndex - 1] = lastToken;
            childTokenIndex[_tokenId][_childContract][lastToken] = tokenIndex;
        }
        uint totalTokens = childTokens[_tokenId][_childContract].length;
        if (totalTokens - 1 == 0) {
            delete childTokens[_tokenId][_childContract];
        } else {
            delete childTokens[_tokenId][_childContract][totalTokens - 1];
        }
        delete childTokenIndex[_tokenId][_childContract][_childTokenId];
        delete childTokenOwner[_childContract][_childTokenId];

        // remove contract
        if (lastTokenIndex == 0) {
            uint256 lastContractIndex = childContracts[_tokenId].length - 1;
            address lastContract = childContracts[_tokenId][lastContractIndex];
            if (_childContract != lastContract) {
                uint256 contractIndex = childContractIndex[_tokenId][_childContract];
                childContracts[_tokenId][contractIndex] = lastContract;
                childContractIndex[_tokenId][lastContract] = contractIndex;
            }
            delete childContracts[_tokenId];
            delete childContractIndex[_tokenId][_childContract];
        }
    }

    /**
     * @dev check permissions are correct for a transfer of a child asset
     * @param _fromTokenId the local ID of the token that is the parent
     * @param _to the address this child token is being transferred to
     * @param _childContract the address of the child asset's contract
     * @param _childTokenId the specific ID for the child asset being transferred
     */
    function _checkTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) private view {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId > 0 || childTokenIndex[tokenId][_childContract][_childTokenId] > 0);
        require(tokenId == _fromTokenId);
        require(_to != address(0));
        address rootOwner = address(uint160(uint256(rootOwnerOf(tokenId))));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender);
    }

    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external override {
        _checkTransferChild(_fromTokenId, _to, _childContract, _childTokenId);        
        removeChild(_fromTokenId, _childContract, _childTokenId);
        IERC721(_childContract).safeTransferFrom(address(this), _to, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId, bytes calldata _data) external override {
        _checkTransferChild(_fromTokenId, _to, _childContract, _childTokenId);
        removeChild(_fromTokenId, _childContract, _childTokenId);
        IERC721(_childContract).safeTransferFrom(address(this), _to, _childTokenId, _data);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    function transferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external override {
        _checkTransferChild(_fromTokenId, _to, _childContract, _childTokenId);
        removeChild(_fromTokenId, _childContract, _childTokenId);
        //this is here to be compatible with cryptokitties and other old contracts that require being owner and approved
        // before transferring.
        //does not work with current standard which does not allow approving self, so we must let it fail in that case.
        //0x095ea7b3 == "approve(address,uint256)"

        (bool success, bytes memory data) = _childContract.call(abi.encodeWithSelector(0x095ea7b3, this, _childTokenId));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'failed to approve'
        );

        IERC721(_childContract).transferFrom(address(this), _to, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    function transferChildToParent(uint256 _fromTokenId, address _toContract, uint256 _toTokenId, address _childContract, uint256 _childTokenId, bytes calldata _data) external override {
        _checkTransferChild(_fromTokenId, _toContract, _childContract, _childTokenId);
        removeChild(_fromTokenId, _childContract, _childTokenId);
        IERC998ERC721BottomUp(_childContract).transferToParent(address(this), _toContract, _toTokenId, _childTokenId, _data);
        emit TransferChild(_fromTokenId, _toContract, _childContract, _childTokenId);
    }


    // this contract has to be approved first in _childContract
    function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external override {
        receiveChild(_from, _tokenId, _childContract, _childTokenId);
        require(_from == msg.sender ||
        IERC721(_childContract).isApprovedForAll(_from, msg.sender) ||
        IERC721(_childContract).getApproved(_childTokenId) == msg.sender);
        IERC721(_childContract).transferFrom(_from, address(this), _childTokenId);

    }

    function onERC721Received(address _from, uint256 _childTokenId, bytes calldata _data) external returns (bytes4) {
        require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
        // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
        uint256 tokenId;
        assembly {tokenId := calldataload(132)}
        if (_data.length < 32) {
            tokenId = tokenId >> 256 - _data.length * 8;
        }
        receiveChild(_from, tokenId, msg.sender, _childTokenId);
        require(IERC721(msg.sender).ownerOf(_childTokenId) != address(0), "Child token not owned.");
        return ERC721_RECEIVED_OLD;
    }


    function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes calldata _data) external override returns (bytes4) {
        require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
        // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
        uint256 tokenId;
        assembly {tokenId := calldataload(164)}
        if (_data.length < 32) {
            tokenId = tokenId >> 256 - _data.length * 8;
        }
        receiveChild(_from, tokenId, msg.sender, _childTokenId);
        require(IERC721(msg.sender).ownerOf(_childTokenId) != address(0), "Child token not owned.");
        return ERC721_RECEIVED_NEW;
    }


    function receiveChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) private {
        require(tokenIdToTokenOwner[_tokenId] != address(0), "_tokenId does not exist.");
        require(childTokenIndex[_tokenId][_childContract][_childTokenId] == 0, "Cannot receive child token because it has already been received.");
        uint256 childTokensLength = childTokens[_tokenId][_childContract].length;
        if (childTokensLength == 0) {
            childContractIndex[_tokenId][_childContract] = childContracts[_tokenId].length;
            childContracts[_tokenId].push(_childContract);
        }
        childTokens[_tokenId][_childContract].push(_childTokenId);
        childTokenIndex[_tokenId][_childContract][_childTokenId] = childTokensLength + 1;
        childTokenOwner[_childContract][_childTokenId] = _tokenId;
        emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
    }

    function _ownerOfChild(address _childContract, uint256 _childTokenId) internal view returns (address parentTokenOwner, uint256 parentTokenId) {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId > 0 || childTokenIndex[parentTokenId][_childContract][_childTokenId] > 0);
        return (tokenIdToTokenOwner[parentTokenId], parentTokenId);
    }

    function ownerOfChild(address _childContract, uint256 _childTokenId)
    external
    view
    override
    returns (bytes32 parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(
        parentTokenId > 0 ||
            childTokenIndex[parentTokenId][_childContract][_childTokenId] > 0,
        "not a child"
        );
        uint256 tokenIdOwnerInt = convertAddressToUint(
        tokenIdToTokenOwner[parentTokenId]
        );
        return (
        (ERC998_MAGIC_VALUE << 224) | bytes32(tokenIdOwnerInt),
        parentTokenId
        );
    }

    function childExists(address _childContract, uint256 _childTokenId) external view returns (bool) {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        return childTokenIndex[tokenId][_childContract][_childTokenId] != 0;
    }

    function totalChildContracts(uint256 _tokenId) external override view returns (uint256) {
        return childContracts[_tokenId].length;
    }

    function childContractByIndex(uint256 _tokenId, uint256 _index) external override view returns (address childContract) {
        require(_index < childContracts[_tokenId].length, "Contract address does not exist for this token and index.");
        return childContracts[_tokenId][_index];
    }

    function totalChildTokens(uint256 _tokenId, address _childContract) external override view returns (uint256) {
        return childTokens[_tokenId][_childContract].length;
    }

    function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external override view returns (uint256 childTokenId) {
        require(_index < childTokens[_tokenId][_childContract].length, "Token does not own a child token at contract address and index.");
        return childTokens[_tokenId][_childContract][_index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

///  @dev The ERC-165 identifier for this interface is 0xa344afe4
interface IERC998ERC721TopDownEnumerable {

  /// @notice Get the total number of child contracts with tokens that are owned by tokenId.
  /// @param _tokenId The parent token of child tokens in child contracts
  /// @return uint256 The total number of child contracts with tokens owned by tokenId.
  function totalChildContracts(uint256 _tokenId) external view returns(uint256);
  
  /// @notice Get child contract by tokenId and index
  /// @param _tokenId The parent token of child tokens in child contract
  /// @param _index The index position of the child contract
  /// @return childContract The contract found at the tokenId and index.
  function childContractByIndex(
    uint256 _tokenId, 
    uint256 _index
  ) 
    external 
    view 
    returns (address childContract);
  
  /// @notice Get the total number of child tokens owned by tokenId that exist in a child contract.
  /// @param _tokenId The parent token of child tokens
  /// @param _childContract The child contract containing the child tokens
  /// @return uint256 The total number of child tokens found in child contract that are owned by tokenId.
  function totalChildTokens(
    uint256 _tokenId, 
    address _childContract
  ) 
    external 
    view 
    returns(uint256);
  
  /// @notice Get child token owned by tokenId, in child contract, at index position
  /// @param _tokenId The parent token of the child token
  /// @param _childContract The child contract of the child token
  /// @param _index The index position of the child token.
  /// @return childTokenId The child tokenId for the parent token, child token and index
  function childTokenByIndex(
    uint256 _tokenId, 
    address _childContract, 
    uint256 _index
  )
    external 
    view 
    returns (uint256 childTokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @title ERC998ERC721 Top-Down Composable Non-Fungible Token
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-998.md
///  Note: the ERC-165 identifier for this interface is 0x1efdf36a
interface IERC998ERC721TopDown {

    /// @dev This emits when a token receives a child token.
    /// @param _from The prior owner of the token.
    /// @param _toTokenId The token that receives the child token.
    event ReceivedChild(
        address indexed _from,
        uint256 indexed _toTokenId,
        address indexed _childContract,
        uint256 _childTokenId
    );

    /// @dev This emits when a child token is transferred from a token to an address.
    /// @param _fromTokenId The parent token that the child token is being transferred from.
    /// @param _to The new owner address of the child token.
    event TransferChild(
        uint256 indexed _fromTokenId,
        address indexed _to,
        address indexed _childContract,
        uint256 _childTokenId
    );

    /// @notice Get the root owner of tokenId.
    /// @param _tokenId The token to query for a root owner address
    /// @return rootOwner The root owner at the top of tree of tokens and ERC998 magic value.
    /// swithed from pubic to external
    function rootOwnerOf(
        uint256 _tokenId
    ) external view returns (
        bytes32 rootOwner
    );

    /// @notice Get the root owner of a child token.
    /// @param _childContract The contract address of the child token.
    /// @param _childTokenId The tokenId of the child.
    /// @return rootOwner The root owner at the top of tree of tokens and ERC998 magic value.
    /// swithed from pubic to external
    function rootOwnerOfChild(
        address _childContract,
        uint256 _childTokenId
    ) external view returns (
        bytes32 rootOwner
    );

    /// @notice Get the parent tokenId of a child token.
    /// @param _childContract The contract address of the child token.
    /// @param _childTokenId The tokenId of the child.
    /// @return parentTokenOwner The parent address of the parent token and ERC998 magic value
    /// @return parentTokenId The parent tokenId of _tokenId
    function ownerOfChild(
        address _childContract,
        uint256 _childTokenId
    ) external view returns (
        bytes32 parentTokenOwner,
        uint256 parentTokenId
    );

    /// @notice A token receives a child token
    /// @param _operator The address that caused the transfer.
    /// @param _from The owner of the child token.
    /// @param _childTokenId The token that is being transferred to the parent.
    /// @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId.
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _childTokenId,
        bytes calldata _data
    ) external returns(bytes4);

    /// @notice Transfer child token from top-down composable to address.
    /// @param _fromTokenId The owning token to transfer from.
    /// @param _to The address that receives the child token
    /// @param _childContract The ERC721 contract of the child token.
    /// @param _childTokenId The tokenId of the token that is being transferred.
    function transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external;

    /// @notice Transfer child token from top-down composable to address.
    /// @param _fromTokenId The owning token to transfer from.
    /// @param _to The address that receives the child token
    /// @param _childContract The ERC721 contract of the child token.
    /// @param _childTokenId The tokenId of the token that is being transferred.
    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external;

    /// @notice Transfer child token from top-down composable to address.
    /// @param _fromTokenId The owning token to transfer from.
    /// @param _to The address that receives the child token
    /// @param _childContract The ERC721 contract of the child token.
    /// @param _childTokenId The tokenId of the token that is being transferred.
    /// @param _data Additional data with no specified format
    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId,
        bytes calldata _data
    ) external;

    /// @notice Transfer bottom-up composable child token from top-down composable to other ERC721 token.
    /// @param _fromTokenId The owning token to transfer from.
    /// @param _toContract The ERC721 contract of the receiving token
    /// @param _toTokenId The receiving token
    /// @param _childContract The bottom-up composable contract of the child token.
    /// @param _childTokenId The token that is being transferred.
    /// @param _data Additional data with no specified format
    function transferChildToParent(
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        address _childContract,
        uint256 _childTokenId,
        bytes calldata _data
    ) external;

    // getChild function enables older contracts like cryptokitties to be transferred into a composable
    // The _childContract must approve this contract. Then getChild can be called.
    /// @notice Get a child token from an ERC721 contract.
    /// @param _from The address that owns the child token.
    /// @param _tokenId The token that becomes the parent owner
    /// @param _childContract The ERC721 contract of the child token
    /// @param _childTokenId The tokenId of the child token
    function getChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IERC998ERC721BottomUp {
    function transferToParent(address _from, address _toContract, uint256 _toTokenId, uint256 _tokenId, bytes calldata _data) external;
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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