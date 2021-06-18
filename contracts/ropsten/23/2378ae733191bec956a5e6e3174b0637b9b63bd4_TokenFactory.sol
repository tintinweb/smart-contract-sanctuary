// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./interfaces/ITokenFactory.sol";
import "./ERC1155ERC721Metadata.sol";
import "./ERC1155ERC721WithAdapter.sol";
import "./GSN/BaseRelayRecipient.sol";

contract TokenFactory is
    ITokenFactory,
    ERC1155ERC721Metadata,
    ERC1155ERC721WithAdapter,
    BaseRelayRecipient
{
    constructor (address _trustedForwarder) {
        trustedForwarder = _trustedForwarder;
    }

    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `_interfaceId`,
    ///  `false` otherwise
    function supportsInterface(bytes4 _interfaceId)
        public
        pure
        override(ERC1155ERC721Metadata, ERC1155ERC721)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /// @notice Queries accumulated holding time for a given owner and token
    /// @dev It throws if it's not a need-time token. The way how holding time is
    ///  calculated is by suming up (token amount) * (holding time in second)
    /// @param _owner Address to be queried
    /// @param _tokenId Token ID of the token to be queried
    /// @return Holding time
    function holdingTimeOf(
        address _owner,
        uint256 _tokenId
    )
        external
        view
        override
        returns (uint256)
    {
        require(_tokenId & NEED_TIME > 0, "Doesn't support this token");
        
        return _holdingTime[_owner][_tokenId] + _calcHoldingTime(_owner, _tokenId);
    }

    /// @notice Queries accumulated holding time for a given owner and recording token
    /// @dev It throws if it's not a need-time token. The way how holding time is
    ///  calculated is by suming up (token amount) * (holding time in second)
    /// @dev It returns zero if it doesn't have a corresponding recording token
    /// @param _owner Address to be queried
    /// @param _tokenId Token ID of the token to be queried
    /// @return Holding time
    function recordingHoldingTimeOf(
        address _owner,
        uint256 _tokenId
    )
        external
        view
        override
        returns (uint256)
    {
        return _recordingHoldingTime[_owner][_tokenId] + _calcRecordingHoldingTime(_owner, _tokenId);
    }

    /// @notice Create a token without setting uri
    /// @dev It emits `NewAdapter` if `_erc20` is true
    /// @param _supply The amount of token to create
    /// @param _receiver Address that receives minted token
    /// @param _settingOperator Address that can perform setTimeInterval
    ///  and set ERC20 Attribute
    /// @param _needTime Set to `true` if need to query holding time for token
    /// @param _erc20 Set to `true` to create a erc20 adapter for token
    /// @return Token ID
    function createToken(
        uint256 _supply,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        bool _erc20
    )
        public 
        override
        returns (uint256)
    {
        uint256 tokenId = _mint(_supply, _receiver, _settingOperator, _needTime, "");
        if (_erc20)
            _createAdapter(tokenId);
        return tokenId;
    }
    
    /// @notice Create a token with uri
    /// @param _supply The amount of token to create
    /// @param _receiver Address that receives minted token
    /// @param _settingOperator Address that can perform setTimeInterval
    ///  and set ERC20 Attribute
    /// @param _needTime Set to `true` if need to query holding time for token
    /// @param _uri URI that points to token metadata
    /// @param _erc20 Set to `true` to create a erc20 adapter for token
    /// @return Token ID
    function createToken(
        uint256 _supply,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        string calldata _uri,
        bool _erc20
    )
        external
        override
        returns (uint256)
    {
        uint256 tokenId = createToken(_supply, _receiver, _settingOperator, _needTime, _erc20);
        if (_erc20)
            _createAdapter(tokenId);
        _setTokenURI(tokenId, _uri);
        return tokenId;
    }

    /// @notice Create both normal token and recording token without setting uri
    /// @dev Recording token shares the same token ID with normal token
    /// @param _supply The amount of token to create
    /// @param _supplyOfRecording The amount of recording token to create
    /// @param _receiver Address that receives minted token
    /// @param _settingOperator Address that can perform setTimeInterval
    ///  and set ERC20 Attribute
    /// @param _needTime Set to `true` if need to query holding time for token
    /// @param _recordingOperator Address that can manage recording token
    /// @param _erc20 Set to `true` to create a erc20 adapter for token
    /// @return Token ID
    function createTokenWithRecording(
        uint256 _supply,
        uint256 _supplyOfRecording,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        address _recordingOperator,
        bool _erc20
    )
        public
        override
        returns (uint256)
    {
        uint256 tokenId = createToken(_supply, _receiver, _settingOperator, _needTime, _erc20);
        _mintCopy(tokenId, _supplyOfRecording, _recordingOperator);
        return tokenId;
    }

    /// @notice Create both normal token and recording token with uri
    /// @dev Recording token shares the same token ID with normal token
    /// @param _supply The amount of token to create
    /// @param _supplyOfRecording The amount of recording token to create
    /// @param _receiver Address that receives minted token
    /// @param _settingOperator Address that can perform setTimeInterval
    ///  and set ERC20 Attribute
    /// @param _needTime Set to `true` if need to query holding time for token
    /// @param _recordingOperator Address that can manage recording token
    /// @param _uri URI that points to token metadata
    /// @param _erc20 Set to `true` to create a erc20 adapter for token
    /// @return Token ID
    function createTokenWithRecording(
        uint256 _supply,
        uint256 _supplyOfRecording,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        address _recordingOperator,
        string calldata _uri,
        bool _erc20
    )
        external
        override
        returns (uint256)
    {
        uint256 tokenId = createToken(_supply, _receiver, _settingOperator, _needTime, _erc20);
        _mintCopy(tokenId, _supplyOfRecording, _recordingOperator);
        _setTokenURI(tokenId, _uri);
        return 0;
    }
    
    /// @notice Set starting time and ending time for token holding time calculation
    /// @dev Starting time must be greater than time at the moment
    /// @dev To save gas cost, here use uint128 to store time
    /// @param _startTime Starting time in unix time format
    /// @param _endTime Ending time in unix time format
    function setTimeInterval(
        uint256 _tokenId,
        uint128 _startTime,
        uint128 _endTime
    )
        external
        override
    {
        require(_msgSender() == _settingOperators[_tokenId], "Not authorized");
        require(_startTime >= block.timestamp, "Time smaller than now");
        require(_endTime > _startTime, "End greater than start");
        require(_timeInterval[_tokenId] == 0, "Already set");

        _setTime(_tokenId, _startTime, _endTime);
    }
    
    /// @notice Set erc20 token attribute
    /// @dev Throws if `msg.sender` is not authorized setting operator
    /// @param _tokenId Corresponding token ID with erc20 adapter
    /// @param _name Name of the token
    /// @param _symbol Symbol of the token
    /// @param _decimals Number of decimals to use
    function setERC20Attribute(
        uint256 _tokenId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        external
        override
    {
        require(_msgSender() == _settingOperators[_tokenId], "Not authorized");
        require(_adapters[_tokenId] != address(0), "No adapter found");

        _setERC20Attribute(_tokenId, _name, _symbol, _decimals);
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    )
        internal
        override(ERC1155ERC721, ERC1155ERC721WithAdapter)
    {
        super._transferFrom(_from, _to, _tokenId, _value);
    }

    function versionRecipient()
        external
        override
        virtual
        view
        returns (string memory)
    {
        return "2.1.0";
    }

    function _msgSender()
        internal
        override(Context, BaseRelayRecipient)
        view
        returns (address payable)
    {
        return BaseRelayRecipient._msgSender();
    }
    
    function _msgData()
        internal
        override(Context, BaseRelayRecipient)
        view
        returns (bytes memory)
    {
        return BaseRelayRecipient._msgData();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenFactory {
    function createToken(
        uint256 _supply,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        bool _erc20
    ) external returns(uint256);
    
    function createToken(
        uint256 _supply,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        string calldata _uri,
        bool _erc20
    ) external returns(uint256);

    function createTokenWithRecording(
        uint256 _supply,
        uint256 _supplyOfRecording,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        address _recordingOperator,
        bool _erc20
    ) external returns(uint256);

    function createTokenWithRecording(
        uint256 _supply,
        uint256 _supplyOfRecording,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        address _recordingOperator,
        string calldata _uri,
        bool _erc20
    ) external returns(uint256);
    
    function setTimeInterval(
        uint256 _tokenId,
        uint128 _startTime,
        uint128 _endTime
    ) external;

    function holdingTimeOf(
        address _owner,
        uint256 _tokenId
    ) external view returns(uint256);

    function recordingHoldingTimeOf(
        address _owner,
        uint256 _tokenId
    ) external view returns(uint256);

    function setERC20Attribute(
        uint256 _tokenId,
        string memory _name,
        string memory _symbol,
        uint8 decimals
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC1155Metadata.sol";
import "./ERC1155ERC721.sol";

/// @title A metadata extension implementation for ERC1155 and ERC721
contract ERC1155ERC721Metadata is ERC1155ERC721, IERC721Metadata, IERC1155Metadata {
    mapping(uint256 => string) internal _tokenURI;

    bytes4 constant private INTERFACE_SIGNATURE_ERC1155Metadata = 0x0e89341c;
    bytes4 constant private INTERFACE_SIGNATURE_ERC721Metadata = 0x5b5e139f;
    
    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `_interfaceId`,
    ///  `false` otherwise
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        pure
        virtual
        override
        returns (bool)
    {
        if (_interfaceId == INTERFACE_SIGNATURE_ERC1155Metadata ||
            _interfaceId == INTERFACE_SIGNATURE_ERC721Metadata) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given token.
    /// @dev URIs are defined in RFC 3986.
    /// The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
    /// @return URI string
    function uri(uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
       return _tokenURI[_tokenId]; 
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name()
        external
        pure
        override
        returns (string memory)
    {
        return "TOKEN";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol()
        external
        pure
        override
        returns (string memory)
    {
        return "TOKEN";
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(_nftOwners[_tokenId] != address(0), "Nft not exist");
        return _tokenURI[_tokenId];
    }

    function _setTokenURI(
        uint256 _tokenId,
        string memory _uri
    )
        internal
    {
        _tokenURI[_tokenId] = _uri;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./interfaces/IERC20Adapter.sol";
import "./libraries/utils/Address.sol";
import "./ERC1155ERC721.sol";

contract ERC1155ERC721WithAdapter is
    ERC1155ERC721
{
    using Address for address;

    mapping(uint256 => address) internal _adapters;
    // @dev The address of the erc20 implementation contract
    address public template;

    /// @dev MUST emit when a new erc20 adapter is created for `_tokenId`
    event NewAdapter(uint256 indexed _tokenId, address indexed _adapter);

    constructor() {
        template = address(new ERC20Adapter());
    }

    /// @notice Returns total supply of a token
    /// @param _tokenId Token ID to be queried
    /// @return Total supply of a token
    function totalSupply(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return _totalSupply[_tokenId];
    }

    /// @notice Queries the erc20 adapter contract address for a given token ID
    /// @dev Returns zero address if does not have a adapter
    /// @param _tokenId Token ID to be queried
    /// @return ERC20 adapter contract address
    function getAdapter(uint256 _tokenId)
        external
        view
        returns (address)
    {
        return _adapters[_tokenId];  
    }

    /// @notice Transfers `_value` amount of `_tokenId` from `_from` to `_to`
    /// @dev This function should only be called from erc20 adapter
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _tokenId ID of the token type
    /// @param _value   Transfer amount
    function transferByAdapter(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    )
        external
    {
        require(_adapters[_tokenId] == msg.sender, "Not adapter");

        if (_tokenId & NEED_TIME > 0) {
            _updateHoldingTime(_from, _tokenId);
            _updateHoldingTime(_to, _tokenId);
        }
        _transferFrom(_from, _to, _tokenId, _value);

        if (_to.isContract()) {
            require(
                _checkReceivable(msg.sender, _from, _to, _tokenId, _value, "", true, false),
                "Transfer rejected"
            );
        }
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    )
        internal
        virtual
        override
    {
        super._transferFrom(_from, _to, _tokenId, _value);
        address adapter = _adapters[_tokenId];
        if (adapter != address(0))
            ERC20Adapter(adapter).emitTransfer(_from, _to, _value);
    }


    function _setERC20Attribute(
        uint256 _tokenId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        internal
    {
        address adapter = _adapters[_tokenId];
        ERC20Adapter(adapter).setAttribute(_name, _symbol, _decimals);
    }

    function _createAdapter(uint256 _tokenId)
        internal
    {
        address adapter = _createClone(template);
        _adapters[_tokenId] = adapter;
        ERC20Adapter(adapter).initialize(_tokenId);
        emit NewAdapter(_tokenId, adapter);
    }

    /// @dev This is a implementation of EIP1167,
    ///  for reference: https://eips.ethereum.org/EIPS/eip-1167 
    function _createClone(address target)
        internal
        returns (address result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                result := create(0, clone, 0x37)
        }
    }
}

contract ERC20Adapter is IERC20Adapter {
    mapping(address => mapping(address => uint256)) private _allowances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public tokenId;
    ERC1155ERC721WithAdapter public entity;

    function initialize(uint256 _tokenId)
       external
    {
        require(address(entity) == address(0), "Already initialized");
        entity = ERC1155ERC721WithAdapter(msg.sender);
        tokenId = _tokenId;
    }

    function setAttribute(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals
    )
        external
    {
        require(msg.sender == address(entity), "Not entity");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function totalSupply()
       external
       view
       override
       returns (uint256)
    {
        return entity.totalSupply(tokenId);
    }

    function balanceOf(address owner)
        external
        view
        override
        returns (uint256)
    {
        return entity.balanceOf(owner, tokenId);
    }

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _value
    )
        external
        override
        returns (bool)
    {
        require(_spender != address(0), "Approve to zero address"); 
        _approve(msg.sender, _spender, _value); 
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        override
        returns (bool)
    {
        require(_to != address(0), "_to must be non-zero");

        _approve(_from, msg.sender, _allowances[_from][msg.sender] - _value);
        _transfer(_from, _to, _value);
        return true;
    }


    function transfer(
        address _to,
        uint256 _value
    )
        external
        override
        returns (bool)
    {
        require(_to != address(0), "_to must be non-zero");

        _transfer(msg.sender, _to, _value);
        return true;
    }

    function emitTransfer(
        address _from,
        address _to,
        uint256 _value
    )
        external
        override
    {
        require(msg.sender == address(entity), "Not entity");

        emit Transfer(_from, _to, _value);
    }
    
    function _approve(
        address _owner,
        address _spender,
        uint256 _value
    )
        internal
    {
        _allowances[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        entity.transferByAdapter(_from, _to, tokenId, _value);
        // Transfer event will be emitted inside `emitTransfer` function
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable no-inline-assembly
pragma solidity 0.8.1;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return payable(msg.sender);
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
interface IERC1155Metadata {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
        @return URI string
    */
    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./interfaces/IERC1155.sol";
import "./interfaces/IERC1155TokenReceiver.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC20Adapter.sol";
import "./libraries/GSN/Context.sol";
import "./libraries/utils/Address.sol";

/// @title A ERC1155 and ERC721 Implmentation
contract ERC1155ERC721 is IERC165, IERC1155, IERC721, Context {
    using Address for address;
    
    mapping(uint256 => uint256) internal _totalSupply;
    mapping(address => mapping(uint256 => uint256)) internal _ftBalances;
    mapping(address => uint256) internal _nftBalances;
    mapping(uint256 => address) internal _nftOwners;
    mapping(uint256 => address) internal _nftOperators;
    mapping(address => mapping(uint256 => uint256)) internal _recordingBalances;
    mapping(uint256 => address) internal _recordingOperators;
    mapping(address => mapping(address => bool)) internal _operatorApproval;
    mapping(uint256 => address) internal _settingOperators;
    mapping(uint256 => uint256) internal _timeInterval;
    mapping(address => mapping(uint256 => uint256)) internal _lastUpdateAt;
    mapping(address => mapping(uint256 => uint256)) internal _holdingTime;
    mapping(address => mapping(uint256  => uint256)) internal _recordingLastUpdateAt;
    mapping(address => mapping(uint256  => uint256)) internal _recordingHoldingTime;
    
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant private ERC1155_ACCEPTED = 0xf23a6e61;
    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 constant private ERC1155_BATCH_ACCEPTED = 0xbc197c81;
    bytes4 constant private ERC721_ACCEPTED = 0x150b7a02;
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155Receiver = 0x4e2312e0;
    bytes4 constant private INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;

    uint256 private constant IS_NFT = 1 << 255;
    uint256 internal constant NEED_TIME = 1 << 254;
    uint256 private idNonce;
    
    
    /// @dev Emitted when `_tokenId` token is transferred from `_from` to `_to`.
    /// @dev Not included in ERC721 interface because it causes a conflict between ERC1155 and ERC721
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev Emitted when `_owner` enables `_approved` to manage the `_tokenId` token.
    /// @dev Not included in ERC721 interface because it causes a conflict between ERC1155 and ERC721
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    
    /// @dev Emitted when `_value` amount of `_tokenId` recording token is transferred from
    /// `_from` to `_to` by `_operator`.
    event RecordingTransferSingle(address _operator, address indexed _from, address indexed _to, uint256 indexed _tokenId, uint256 _value);
    
    /// @dev Emitted when `_tokenId`'s interval of token holding time range is being set
    event TimeInterval(uint256 indexed _tokenId, uint256 _startTime, uint256 _endTime);

    modifier AuthorizedTransfer(
        address _operator,
        address _from,
        uint _tokenId
    ) {
        require(
            _from == _operator ||
            _nftOperators[_tokenId] == _operator ||
            _operatorApproval[_from][_operator],
            "Not authorized"
        );
        _;
    }

    /////////////////////////////////////////// Query //////////////////////////////////////////////
    
    /// @notice Returns the setting operator of a token
    /// @param _tokenId Token ID to be queried
    /// @return The setting operator address
    function settingOperatorOf(uint256 _tokenId)
        external
        view
        returns (address)
    {
        return _settingOperators[_tokenId];
    }

    /// @notice Returns the recording operator of a token
    /// @param _tokenId Token ID to be queried
    /// @return The recording operator address
    function recordingOperatorOf(uint256 _tokenId)
        external
        view
        returns (address)
    {
        return _recordingOperators[_tokenId];
    }

    /// @notice Returns the starting time and ending time of token holding
    /// time calculation
    /// @param _tokenId Token ID to be queried
    /// @return The starting time in unix time
    /// @return The ending time in unix time
    function timeIntervalOf(uint256 _tokenId)
        external
        view
        returns (uint256, uint256)
    {
        uint256 startTime = uint256(uint128(_timeInterval[_tokenId]));
        uint256 endTime = uint256(_timeInterval[_tokenId] >> 128);
        return (startTime, endTime);
    }

    /////////////////////////////////////////// ERC165 //////////////////////////////////////////////
    
    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `_interfaceId`,
    ///  `false` otherwise
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        pure
        virtual
        override
        returns (bool)
    {
        if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceId == INTERFACE_SIGNATURE_ERC1155 || 
            _interfaceId == INTERFACE_SIGNATURE_ERC721) {
            return true;
        }
        return false;
    }
    
    /////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    /// @notice Transfers `_value` amount of an `_tokenId` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// MUST revert if `_to` is the zero address.
    /// MUST revert if balance of holder for token `_tokenId` is lower than the `_value` sent.
    /// MUST revert on any other error.
    /// MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _tokenId     ID of the token type
    /// @param _value   Transfer amount
    /// @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value,
        bytes calldata _data
    ) 
        external
        override
        AuthorizedTransfer(_msgSender(), _from, _tokenId)
    {
        require(_to != address(0x0), "_to must be non-zero.");
        if (_tokenId & IS_NFT > 0) {
            if (_value > 0) {
                require(_value == 1, "NFT amount more than 1");
                safeTransferFrom(_from, _to, _tokenId, _data);
            }
            return;
        }

        if (_tokenId & NEED_TIME > 0) {
           _updateHoldingTime(_from, _tokenId);
           _updateHoldingTime(_to, _tokenId);
        }
        _transferFrom(_from, _to, _tokenId, _value);

        if (_to.isContract()) {
            require(_checkReceivable(_msgSender(), _from, _to, _tokenId, _value, _data, false, false),
                    "Transfer rejected");
        }
    }
    
    /// @notice Transfers `_values` amount(s) of `_tokenIds` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// MUST revert if `_to` is the zero address.
    /// MUST revert if length of `_tokenIds` is not the same as length of `_values`.
    /// MUST revert if any of the balance(s) of the holder(s) for token(s) in `_tokenIds` is lower than the respective amount(s) in `_values` sent to the recipient.
    /// MUST revert on any other error.
    /// MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// Balance changes and events MUST follow the ordering of the arrays (_tokenIds[0]/_values[0] before _tokenIds[1]/_values[1], etc).
    /// After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _tokenIds     IDs of each token type (order and length must match _values array)
    /// @param _values  Transfer amounts per token type (order and length must match _tokenIds array)
    /// @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values,
        bytes calldata _data
    )
        external
        override
    {
        require(_to != address(0x0), "_to must be non-zero.");
        require(_tokenIds.length == _values.length, "Array length must match.");
        bool authorized = _from == _msgSender() || _operatorApproval[_from][_msgSender()];
            
        _batchUpdateHoldingTime(_from, _tokenIds);
        _batchUpdateHoldingTime(_to, _tokenIds);
        _batchTransferFrom(_from, _to, _tokenIds, _values, authorized);
        
        if (_to.isContract()) {
            require(_checkBatchReceivable(_msgSender(), _from, _to, _tokenIds, _values, _data),
                    "BatchTransfer rejected");
        }
    }
    
    
    /// @notice Get the balance of an account's Tokens.
    /// @dev It accept both 
    /// @param _owner  The address of the token holder
    /// @param _tokenId     ID of the Token
    /// @return        The _owner's balance of the Token type requested
    function balanceOf(
        address _owner,
        uint256 _tokenId
    )
        public
        view
        virtual
        override
        returns (uint256) 
    {
        if (_tokenId & IS_NFT > 0) {
            if (_ownerOf(_tokenId) == _owner)
                return 1;
            else
                return 0;
        }
        return _ftBalances[_owner][_tokenId];
    }
    
    /// @notice Get the balance of multiple account/token pairs
    /// @param _owners The addresses of the token holders
    /// @param _tokenIds    ID of the Tokens
    /// @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _tokenIds
    )
        external
        view
        override
        returns (uint256[] memory)
    {
        require(_owners.length == _tokenIds.length, "Array lengths should match");

        uint256[] memory balances_ = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balanceOf(_owners[i], _tokenIds[i]);
        }

        return balances_;
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param _operator  Address to add to the set of authorized operators
    /// @param _approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
        override(IERC1155, IERC721)
    {
        _operatorApproval[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }
    
    /// @notice Queries the approval status of an operator for a given owner.
    /// @param _owner     The owner of the Tokens
    /// @param _operator  Address of authorized operator
    /// @return           True if the operator is approved, false if not
    function isApprovedForAll(
        address _owner,
        address _operator
    ) 
        external
        view
        override(IERC1155, IERC721)
        returns (bool) 
    {
        return _operatorApproval[_owner][_operator];
    }

    /////////////////////////////////////////// ERC721 //////////////////////////////////////////////

    /// @notice Count all NFTs assigned to an owner
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) 
        external
        view
        override
        returns (uint256) 
    {
        return _nftBalances[_owner];
    }
    

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address or FT token are considered invalid,
    ///  and queries about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address) 
    {
        address owner = _ownerOf(_tokenId);
        require(owner != address(0), "Not nft or not exist");
        return owner;
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) 
        external
        override
    {
        safeTransferFrom(_from, _to, _tokenId, "");
    }
    
    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        public
        override
        AuthorizedTransfer(_msgSender(), _from, _tokenId)
    {
        require(_to != address(0), "_to must be non-zero");
        require(_nftOwners[_tokenId] == _from, "Not owner or it's not nft");
        
        if (_tokenId & NEED_TIME > 0) {
           _updateHoldingTime(_from, _tokenId);
           _updateHoldingTime(_to, _tokenId);
        }
        _transferFrom(_from, _to, _tokenId, 1);
        
        if (_to.isContract()) {
            require(_checkReceivable(_msgSender(), _from, _to, _tokenId, 1, _data, true, true),
                    "Transfer rejected");
        }
    }
    
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) 
        external
        override
        AuthorizedTransfer(_msgSender(), _from, _tokenId)
    {
        require(_to != address(0), "_to must be non-zero");
        require(_nftOwners[_tokenId] == _from, "Not owner or it's not nft");
                
        if (_tokenId & NEED_TIME > 0) {
           _updateHoldingTime(_from, _tokenId);
           _updateHoldingTime(_to, _tokenId);
        }
        _transferFrom(_from, _to, _tokenId, 1);

        if (_to.isContract()) {
            require(_checkReceivable(_msgSender(), _from, _to, _tokenId, 1, "", true, false),
                    "Transfer rejected");
        }
    }
    
    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _to The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        override 
    {
        address owner = _nftOwners[_tokenId];
        require(owner == _msgSender() || _operatorApproval[owner][_msgSender()],
                "Not authorized or not a nft");
        _nftOperators[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }
    
    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) 
        external
        view
        override
        returns (address) 
    {
        require(_tokenId & IS_NFT > 0, "Not a nft");
        return _nftOperators[_tokenId];
    }

    /////////////////////////////////////////// Recording //////////////////////////////////////////////
    
    /// @notice Transfer recording token
    /// @dev If `_to` is zeroaddress or `msg.sender` is not recording operator,
    ///  it throwsa.
    /// @param _from Current owner of recording token
    /// @param _to New owner
    /// @param _tokenId The token to transfer
    /// @param _value The amount to transfer
    function recordingTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    ) 
        external
    {
        require(_msgSender() == _recordingOperators[_tokenId], "Not authorized");
        require(_to != address(0), "_to must be non-zero");

       _updateRecordingHoldingTime(_from, _tokenId);
       _updateRecordingHoldingTime(_to, _tokenId);
        _recordingTransferFrom(_from, _to, _tokenId, _value);
    }
    
    /// @notice Count all recording token assigned to an address
    /// @param _owner An address for whom to query the balance
    /// @param _tokenId The token ID to be queried
    function recordingBalanceOf(
        address _owner,
        uint256 _tokenId
    ) 
        public 
        view
        returns (uint256)
    {
        return _recordingBalances[_owner][_tokenId];
    }
    
    /////////////////////////////////////////// Holding Time //////////////////////////////////////////////

    function _updateHoldingTime(
        address _owner,
        uint256 _tokenId
    )
        internal
    {
        require(_tokenId & NEED_TIME > 0, "Doesn't support this token");

        _holdingTime[_owner][_tokenId] += _calcHoldingTime(_owner, _tokenId);
        _lastUpdateAt[_owner][_tokenId] = block.timestamp;
    }

    function _batchUpdateHoldingTime(
        address _owner,
        uint256[] memory _tokenIds
    )
        internal
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_tokenIds[i] & NEED_TIME > 0)
               _updateHoldingTime(_owner, _tokenIds[i]);
        }
    }
    
    function _updateRecordingHoldingTime(
        address _owner,
        uint256 _tokenId
    )
        internal
    {
        _recordingHoldingTime[_owner][_tokenId] += _calcRecordingHoldingTime(_owner, _tokenId);
        _recordingLastUpdateAt[_owner][_tokenId] = block.timestamp;
    }

    /////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _calcHoldingTime(
        address _owner,
        uint256 _tokenId
    )
        internal
        view
        returns (uint256)
    {
        uint256 lastTime = _lastUpdateAt[_owner][_tokenId];
        uint256 startTime = uint256(uint128(_timeInterval[_tokenId]));
        uint256 endTime = uint256(_timeInterval[_tokenId] >> 128);
        uint256 balance = balanceOf(_owner, _tokenId);

        if (balance == 0)
            return 0;
        if (startTime == 0 || startTime >= block.timestamp)
            return 0;
        if (lastTime >= endTime)
            return 0;
        if (lastTime < startTime)
            lastTime = startTime;

        if (block.timestamp > endTime)
            return balance * (endTime - lastTime);
        else
            return balance * (block.timestamp - lastTime);
    }

    function _calcRecordingHoldingTime(
        address _owner,
        uint256 _tokenId
    )
        internal
        view
        returns (uint256)
    {
        uint256 lastTime = _recordingLastUpdateAt[_owner][_tokenId];
        uint256 startTime = uint256(uint128(_timeInterval[_tokenId]));
        uint256 endTime = uint256(_timeInterval[_tokenId] >> 128);
        uint256 balance = recordingBalanceOf(_owner, _tokenId);

        if (balance == 0)
            return 0;
        if (startTime == 0 || startTime >= block.timestamp)
            return 0;
        if (lastTime >= endTime)
            return 0;
        if (lastTime < startTime)
            lastTime = startTime;

        if (block.timestamp > endTime)
            return balance * (endTime - lastTime);
        else
            return balance * (block.timestamp - lastTime);
    }

    function _setTime(
        uint256 _tokenId,
        uint128 _startTime,
        uint128 _endTime
    )
        internal
    {
        uint256 timeInterval = _startTime + (uint256(_endTime) << 128);
        _timeInterval[_tokenId] = timeInterval;

        emit TimeInterval(_tokenId, uint256(_startTime), uint256(_endTime));
    }

    function _recordingTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    )
        internal
    {
        _recordingBalances[_from][_tokenId] -= _value;
        _recordingBalances[_to][_tokenId] += _value;
        emit RecordingTransferSingle(_msgSender(), _from, _to, _tokenId, _value);
    }
    
    function _batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _values,
        bool authorized
    ) 
        internal
    {
        uint256 numNFT;
        
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_values[i] > 0) {
                if (_tokenIds[i] & IS_NFT > 0) {
                    require(_values[i] == 1, "NFT amount is not 1");
                    require(_nftOwners[_tokenIds[i]] == _from, "_from is not owner");
                    require(_nftOperators[_tokenIds[i]] == _msgSender() || authorized, "Not authorized");
                    numNFT++;
                    _nftOwners[_tokenIds[i]] = _to;
                    _nftOperators[_tokenIds[i]] = address(0);
                    emit Transfer(_from, _to, _tokenIds[i]);
                } else {
                    require(authorized, "Not authorized");
                    _ftBalances[_from][_tokenIds[i]] -= _values[i];
                    _ftBalances[_to][_tokenIds[i]] += _values[i];
                }
            }
        }
        _nftBalances[_from] -= numNFT;
        _nftBalances[_to] += numNFT;

        emit TransferBatch(_msgSender(), _from, _to, _tokenIds, _values);
    }
    
    function _mint(
        uint256 _supply,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        bytes memory _data
    )
        internal
        returns (uint256)
    {
        uint256 tokenId = ++idNonce;
        if (_needTime)
            tokenId |= NEED_TIME;

        if (_supply == 1) {
            tokenId |= IS_NFT;
            _nftBalances[_receiver]++;
            _nftOwners[tokenId] = _receiver;
            emit Transfer(address(0), _receiver, tokenId);
        } else {
            _ftBalances[_receiver][tokenId] += _supply;
        }

        _totalSupply[tokenId] += _supply;
        _settingOperators[tokenId] = _settingOperator;
        
        emit TransferSingle(_msgSender(), address(0), _receiver, tokenId, _supply);
        
        if (_receiver.isContract()) {
            require(_checkReceivable(_msgSender(), address(0), _receiver, tokenId, _supply, _data, false, false),
                    "Transfer rejected");
        }
        return tokenId;
    }
    
    function _mintCopy(
        uint256 _tokenId,
        uint256 _supply,
        address _recordingOperator
    )
        internal
    {
        _recordingBalances[_recordingOperator][_tokenId] += _supply;
        _recordingOperators[_tokenId] = _recordingOperator;
        emit RecordingTransferSingle(_msgSender(), address(0), _recordingOperator, _tokenId, _supply);
    }
    
    function _checkReceivable(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value,
        bytes memory _data,
        bool _erc721erc20,
        bool _erc721safe
    )
        internal
        returns (bool)
    {
        if (_erc721erc20 && !_checkIsERC1155Receiver(_to)) {
            if (_erc721safe)
                return _checkERC721Receivable(_operator, _from, _to, _tokenId, _data);
            else
                return true;
        }
        return _checkERC1155Receivable(_operator, _from, _to, _tokenId, _value, _data);
    }
    
    function _checkERC1155Receivable(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value,
        bytes memory _data
    )
        internal
        returns (bool)
    {
        return (IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _tokenId, _value, _data) == ERC1155_ACCEPTED);
    }
    
    function _checkERC721Receivable(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        internal
        returns (bool)
    {
        return (IERC721Receiver(_to).onERC721Received(_operator, _from, _tokenId, _data) == ERC721_ACCEPTED);
    }
    
    function _checkIsERC1155Receiver(address _to) 
        internal
        returns (bool)
    {
        (bool success, bytes memory data) = _to.call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, INTERFACE_SIGNATURE_ERC1155Receiver));
        if (!success)
            return false;
        bool result = abi.decode(data, (bool));
        return result;
    }
    
    function _checkBatchReceivable(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _values,
        bytes memory _data
    )
        internal
        returns (bool)
    {
        return (IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _tokenIds, _values, _data)
                == ERC1155_BATCH_ACCEPTED);
    }
    
    function _ownerOf(uint256 _tokenId)
        internal
        view
        returns (address)
    {
        return _nftOwners[_tokenId]; 
    }
    
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    )
        internal
        virtual
    {
        if (_tokenId & IS_NFT > 0) {
            if (_value > 0) {
                require(_value == 1, "NFT amount more than 1");
                _nftOwners[_tokenId] = _to;
                _nftBalances[_from]--;
                _nftBalances[_to]++;
                _nftOperators[_tokenId] = address(0);
                
                emit Transfer(_from, _to, _tokenId);
            }
        } else {
            if (_value > 0) {
                _ftBalances[_from][_tokenId] -= _value;
                _ftBalances[_to][_tokenId] += _value;
            }
        }
        
        emit TransferSingle(_msgSender(), _from, _to, _tokenId, _value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 /* is ERC165 */ {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_tokenId` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _tokenId, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_tokenIds` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _tokenIds) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _tokenIds, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _tokenId);

    /**
        @notice Transfers `_value` amount of an `_tokenId` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_tokenId` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _tokenId      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_tokenIds` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_tokenIds` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_tokenIds` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_tokenIds[0]/_values[0] before _tokenIds[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _tokenIds     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _tokenIds array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _tokenIds    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _tokenIds) external view returns (uint256[] memory);

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _tokenId     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _tokenId) external view returns (uint256);

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Adapter is IERC20 {
    function emitTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}