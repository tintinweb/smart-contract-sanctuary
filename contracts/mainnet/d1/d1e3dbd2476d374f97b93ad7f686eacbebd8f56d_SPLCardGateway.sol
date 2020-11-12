// File: contracts/roles/Roles.sol

pragma solidity ^0.5.0;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "role already has the account");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "role dosen't have the account");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        return role.bearer[account];
    }
}

// File: contracts/erc/ERC165.sol

pragma solidity ^0.5.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-165 Standard Interface Detection
/// @dev See https://eips.ethereum.org/EIPS/eip-165
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: contracts/erc/ERC173.sol

pragma solidity ^0.5.0;


/// @title ERC-173 Contract Ownership Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-173.md
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 /* is ERC165 */ {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @notice Set the address of the new owner of the contract
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

contract ERC173 is IERC173, ERC165  {
    address private _owner;

    constructor() public {
        _registerInterface(0x7f5828d0);
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "Must be owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) public onlyOwner() {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        address previousOwner = owner();
	_owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}

// File: contracts/roles/Operatable.sol

pragma solidity ^0.5.0;



contract Operatable is ERC173 {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;
    Roles.Role private operators;

    constructor() public {
        operators.add(msg.sender);
        _paused = false;
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Must be operator");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOperator() {
        _transferOwnership(_newOwner);
    }

    function isOperator(address account) public view returns (bool) {
        return operators.has(account);
    }

    function addOperator(address account) public onlyOperator() {
        operators.add(account);
        emit OperatorAdded(account);
    }

    function removeOperator(address account) public onlyOperator() {
        operators.remove(account);
        emit OperatorRemoved(account);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function pause() public onlyOperator() whenNotPaused() {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOperator() whenPaused() {
        _paused = false;
        emit Unpaused(msg.sender);
    }

}

// File: contracts/interfaces/IERC721TokenReceiver.sol

pragma solidity ^0.5.0;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns(bytes4);
}

// File: contracts/erc/ERC721Holder.sol

pragma solidity ^0.5.0;


contract ERC721Holder is IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: contracts/IERC721Gateway.sol

pragma solidity ^0.5.0;

interface AssetContract {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function isAlreadyMinted(uint256 _tokenId) external view returns (bool);
    function mintCardAsset(address _to, uint256 _tokenId) external;
}

interface IERC721Gateway {
    event Deposit(address indexed owner, uint256 tokenId);
    event Withdraw(address indexed owner, uint256 tokenId, uint256 supportEther, bytes32 eventHash);
    function isTransactedEventHash(bytes32 _eventHash) external view returns (bool);
    function setTransactedEventHash(bytes32 _eventHash, bool _desired) external;
    function deposit(uint256 _tokenId) external;
    function bulkDeposit(uint256[] calldata _tokenIds) external;
    function withdraw(address payable _to, uint256 _tokenId, uint256 _supportEther, bytes32 _eventHash) external payable;
    function bulkWithdraw(address payable[] calldata _tos, uint256[] calldata _tokenIds, uint256[] calldata _supportEther, bytes32[] calldata _eventHashes) external payable;
}

// File: contracts/SPLCardGateway.sol

pragma solidity ^0.5.0;




contract SPLCardGateway is IERC721Gateway, Operatable, ERC721Holder {
    AssetContract public assetContract;

    mapping(bytes32 => bool) private eventHashTransacted;

    constructor(address _assetContract) public {
        assetContract = AssetContract(_assetContract);
    }

    function isTransactedEventHash(bytes32 _eventHash) public view returns (bool) {
        return eventHashTransacted[_eventHash];
    }

    function setTransactedEventHash(bytes32 _eventHash, bool _desired) public onlyOperator() {
        eventHashTransacted[_eventHash] = _desired;
    }

    function deposit(uint256 _tokenId) public whenNotPaused() {
        address owner = assetContract.ownerOf(_tokenId);
        require(owner == msg.sender, "msg.sender must be _tokenId owner");
        assetContract.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Deposit(owner, _tokenId);
    }

    function bulkDeposit(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            deposit(_tokenIds[i]);
        }
    }

    function withdraw(address payable _to, uint256 _tokenId, uint256 _supportEther, bytes32 _eventHash) public payable whenNotPaused() onlyOperator() {
        require(!isTransactedEventHash(_eventHash), "_eventHash is already transacted");

        if (assetContract.isAlreadyMinted(_tokenId)) {
            assetContract.safeTransferFrom(address(this), _to, _tokenId);
        } else {
            assetContract.mintCardAsset(_to, _tokenId);
        }
        setTransactedEventHash(_eventHash, true);

        if (_supportEther != 0) {
          _to.transfer(_supportEther);
        }
        emit Withdraw(msg.sender, _tokenId, _supportEther, _eventHash);
    }

    function bulkWithdraw(
        address payable[] calldata _tos,
        uint256[] calldata _tokenIds,
        uint256[] calldata _supportEthers,
        bytes32[] calldata _eventHashes
    ) external payable {
        require(_tokenIds.length == _tos.length && _tokenIds.length == _supportEthers.length && _tokenIds.length == _eventHashes.length, "invalid length");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            withdraw(_tos[i], _tokenIds[i], _supportEthers[i], _eventHashes[i]);
        }
    }
}