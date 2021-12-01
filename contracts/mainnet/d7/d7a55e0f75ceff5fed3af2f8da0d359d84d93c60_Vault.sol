/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: UNLICENSED

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/cryptography/ECDSA.sol

pragma solidity ^0.6.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: contracts/interfaces/IERC721.sol

pragma solidity ^0.6.1;


interface IERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

// File: contracts/interfaces/IERC721PreMinteable.sol

pragma solidity ^0.6.1;

interface IERC721PreMinteable {
    function issueToken(address beneficiary, uint256 optionId, uint256 issuedId) external;
}

// File: contracts/Vault.sol

pragma solidity ^0.6.1;








contract Vault is Ownable, Pausable {
    using Address for address;
    using ECDSA for bytes32;

    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

    mapping(address => bool) public contractWhitelist;
    mapping(address => bool) public adminWhitelist;
    mapping(address => bool) public supervisorWhitelist;
    mapping(bytes32 => bool) public messageProcessed;

    event Deposited(address indexed _owner, address indexed _contract, uint256 indexed _tokenId, bytes _userId);
    event Withdrawn(address _beneficiary, address indexed _contract, uint256 indexed _tokenId, bytes _userId);
    event Issued(
        address _beneficiary,
        address indexed _contract,
        uint256 indexed _optionId,
        uint256 indexed _issuedId,
        bytes _userId
    );

    event ContractSet(address indexed _contract, bool _allowed, address indexed _caller);
    event AdminSet(address indexed _admin, bool _allowed, address indexed _caller);
    event SupervisorSet(address indexed _supervisor, bool _allowed, address indexed _caller);


    /**
    * @dev Modifier to check whether a caller is an admin
    */
    modifier onlyAdmin() {
        require(adminWhitelist[msg.sender], "Caller is not an admin");
        _;
    }

    /**
    * @dev Modifier to check whether a caller is a supervisor
    */
    modifier onlySupervisor() {
        require(supervisorWhitelist[msg.sender], "Caller is not a supervisor");
        _;
    }

     /**
     * @dev Called by the owner to pause, triggers stopped state.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Called by the owner to unpause, returns to normal state.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @dev Add or remove an address to the supervisor whitelist
    * @param _supervisor - Address to be allowed or not
    * @param _allowed - Whether the contract will be allowed or not
    */
    function setSupervisor(address _supervisor, bool _allowed) external onlyOwner {
        if (_allowed) {
            require(!supervisorWhitelist[_supervisor], "The supervisor is already whitelisted");
        } else {
            require(supervisorWhitelist[_supervisor], "The supervisor is not whitelisted");
        }

        supervisorWhitelist[_supervisor] = _allowed;
        emit SupervisorSet(_supervisor, _allowed, msg.sender);
    }

    /**
    * @dev Add or remove a contract to the contract whitelist
    * @param _contract - Contract to be allowed or not
    * @param _allowed - Whether the contract will be allowed or not
    */
    function setContract(address _contract, bool _allowed) external onlyOwner {
        if (_allowed) {
            require(!contractWhitelist[_contract], "The contract is already whitelisted");
            require(_contract.isContract(), "The address provided is not a contract");
        } else {
            require(contractWhitelist[_contract], "The contract is not whitelisted");
            // require(_contract.balanceOf(address(this)) == 0, "The vault has tokens of this contract");
        }

        contractWhitelist[_contract] = _allowed;
        emit ContractSet(_contract, _allowed, msg.sender);
    }

    /**
    * @dev Add or remove an address to the admin whitelist
    * @param _admin - Address to be allowed or not
    * @param _allowed - Whether the contract will be allowed or not
    */
    function setAdmin(address _admin, bool _allowed) external onlyOwner {
        _setAdmin(_admin, _allowed);
    }

    /**
    * @dev Remove an address to the admin whitelist
    * @param _admin - Address to be removed
    */
    function removeAdmin(address _admin) external onlySupervisor {
        _setAdmin(_admin, false);
    }

     /**
    * @dev Add or remove an address to the admin whitelist
    * @param _admin - Address to be allowed or not
    * @param _allowed - Whether the contract will be allowed or not
    */
    function _setAdmin(address _admin, bool _allowed) internal {
        if (_allowed) {
            require(!adminWhitelist[_admin], "The admin is already whitelisted");
        } else {
            require(adminWhitelist[_admin], "The admin is not whitelisted");
        }

        adminWhitelist[_admin] = _allowed;

        emit AdminSet(_admin, _allowed, msg.sender);
    }

    /**
    * @notice Handle the receipt of an NFT
    * @dev The ERC721 smart contract calls this function on the recipient
    * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
    * otherwise the caller will revert the transaction. The selector to be
    * returned can be obtained as `this.onERC721Received.selector`. This
    * function MAY throw to revert and reject the transfer.
    * Note: the ERC721 contract address is always the message sender.
    * @param _from - The address which previously owned the token
    * @param _tokenId - The NFT identifier which is being transferred
    * @param _data - Additional data with no specified format
    * @return bytes4 - `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    */
    function onERC721Received(
        address /*_operator*/,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external whenNotPaused returns(bytes4) {
        require(contractWhitelist[msg.sender], "The contract is not whitelisted");

        emit Deposited(_from, msg.sender, _tokenId, _data);

        return ERC721_RECEIVED;
    }

    /**
    * @dev Withdraw an NFT
    * @param _beneficiary - Beneficiary's address
    * @param _contract - NFT contract' address
    * @param _tokenId - Token id
    * @param _userId - User id
    */
    function withdraw(
        address _beneficiary,
        address _contract,
        uint256 _tokenId,
        bytes calldata _userId
    ) external onlyAdmin {
        _withdraw(_beneficiary, _contract, _tokenId, _userId);
    }

    /**
    * @dev Withdraw an NFT by committing a valid signature
    * @param _beneficiary - Beneficiary's address
    * @param _contract - NFT contract' address
    * @param _tokenId - Token id
    * @param _expires - Expiration of the signature
    * @param _userId - User id
    * @param _signature - Signature
    */
    function withdraw(
        address _beneficiary,
        address  _contract,
        uint256 _tokenId,
        uint256 _expires,
        bytes calldata _userId,
        bytes calldata _signature
    ) external {
        require(_expires >= block.timestamp, "Expired signature");

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _beneficiary,
                _contract,
                _tokenId,
                _expires,
                _userId
            )
        ).toEthSignedMessageHash();

        _validateMessageAndSignature(messageHash, _signature);

        _withdraw(_beneficiary, _contract, _tokenId, _userId);
    }

    /**
    * @dev Withdraw many NFTs
    * @param _beneficiary - Beneficiary's address
    * @param _contracts - NFT contract' addresses
    * @param _tokenIds - Token ids
    * @param _userId - User id
    */
    function withdrawMany(
        address _beneficiary,
        address[] calldata _contracts,
        uint256[] calldata _tokenIds,
        bytes calldata _userId
    ) external onlyAdmin {
        require(
            _contracts.length == _tokenIds.length,
            "Contracts and token ids must have the same length"
        );

        _withdrawMany(_beneficiary, _contracts, _tokenIds, _userId);
    }

    /**
    * @dev Withdraw many NFTs by committing a valid signature
    * @param _beneficiary - Beneficiary's address
    * @param _contracts - NFT contract' addresses
    * @param _tokenIds - Token ids
    * @param _expires - Expiration of the signature
    * @param _userId - User id
    * @param _signature - Signature
    */
    function withdrawMany(
        address _beneficiary,
        address[] calldata _contracts,
        uint256[] calldata _tokenIds,
        uint256 _expires,
        bytes calldata _userId,
        bytes calldata _signature
    ) external {
        require(_expires >= block.timestamp, "Expired signature");
        require(
            _contracts.length == _tokenIds.length,
            "Contracts and token ids must have the same length"
        );

        bytes memory transferData;

        for (uint256 i = 0; i < _contracts.length; i++) {
            transferData = abi.encodePacked(
                transferData,
                abi.encode(
                    _contracts[i],
                    _tokenIds[i]
                )
            );
        }

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _beneficiary,
                transferData,
                _expires,
                _userId
            )
        )
        .toEthSignedMessageHash();

        _validateMessageAndSignature(messageHash, _signature);

        _withdrawMany(_beneficiary, _contracts, _tokenIds, _userId);
    }

    /**
    * @dev Withdraw many NFTs
    * @param _beneficiary - Beneficiary's address
    * @param _contracts - NFT contract' addresses
    * @param _tokenIds - Token ids
    * @param _userId - User id
    */
    function _withdrawMany(
        address _beneficiary,
        address[] memory _contracts,
        uint256[] memory _tokenIds,
        bytes memory _userId
    ) internal whenNotPaused {
        for (uint256 i = 0; i < _contracts.length; i++) {
            _withdraw(_beneficiary, _contracts[i], _tokenIds[i], _userId);
        }
    }

    /**
    * @dev Withdraw an NFT
    * @param _beneficiary - Beneficiary's address
    * @param _contract - NFT contract' address
    * @param _tokenId - Token id
    * @param _userId - User id
    */
    function _withdraw(
        address _beneficiary,
        address _contract,
        uint256 _tokenId,
        bytes memory _userId
    ) internal whenNotPaused {
        IERC721(_contract).transferFrom(address(this), _beneficiary, _tokenId);

        emit Withdrawn(_beneficiary, _contract, _tokenId, _userId);
    }

    /**
    * @dev Withdraw an NFT by minting it
    * @param _beneficiary - Beneficiary's address
    * @param _contract - NFT contract' address
    * @param _optionId - Option id
    * @param _issuedId - Issued id
    * @param _userId - User id
    */
    function issueToken(
        address _beneficiary,
        address _contract,
        uint256 _optionId,
        uint256 _issuedId,
        bytes calldata _userId
    ) external onlyAdmin {
        _issueToken(
            _beneficiary,
            _contract,
            _optionId,
            _issuedId,
            _userId
        );
    }

    /**
    * @dev Withdraw NFTs by minting them
    * @param _beneficiary - Beneficiary's address
    * @param _contracts - NFT contract' addresses
    * @param _optionIds - Option ids
    * @param _issuedIds - Issued ids
    * @param _userId - User id
    */
    function issueManyTokens(
        address _beneficiary,
        address[] calldata _contracts,
        uint256[] calldata _optionIds,
        uint256[] calldata _issuedIds,
        bytes calldata _userId
    ) external onlyAdmin {
        require(
            _contracts.length == _optionIds.length,
            "Contracts and option ids must have the same length"
        );
        require(
            _optionIds.length == _issuedIds.length,
            "Option ids and issued ids must have the same length"
        );

        _issueManyTokens(
            _beneficiary,
            _contracts,
            _optionIds,
            _issuedIds,
            _userId
        );
    }

    /**
    * @dev Withdraw an NFT by minting it committing a valid signature
    * @param _beneficiary - Beneficiary's address
    * @param _contract - NFT contract' address
    * @param _optionId - Option id
    * @param _issuedId - Issued id
    * @param _expires - Expiration of the signature
    * @param _userId - User id
    * @param _signature - Signature
    */
    function issueToken(
        address _beneficiary,
        address _contract,
        uint256 _optionId,
        uint256 _issuedId,
        uint256 _expires,
        bytes calldata _userId,
        bytes calldata _signature
    ) external {
        require(_expires >= block.timestamp, "Expired signature");

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _beneficiary,
                _contract,
                _optionId,
                _issuedId,
                _expires,
                _userId
            )
        ).toEthSignedMessageHash();

        _validateMessageAndSignature(messageHash, _signature);

        _issueToken(
            _beneficiary,
            _contract,
            _optionId,
            _issuedId,
            _userId
        );
    }

    /**
    * @dev Withdraw NFTs by minting them
    * @param _beneficiary - Beneficiary's address
    * @param _contracts - NFT contract' addresses
    * @param _optionIds - Option ids
    * @param _issuedIds - Issued ids
    * @param _expires - Expiration of the signature
    * @param _userId - User id
    * @param _signature - Signature
    */
    function issueManyTokens(
        address _beneficiary,
        address[] calldata _contracts,
        uint256[] calldata _optionIds,
        uint256[] calldata _issuedIds,
        uint256 _expires,
        bytes calldata _userId,
        bytes calldata _signature
    ) external {
        require(_expires >= block.timestamp, "Expired signature");
        require(
            _contracts.length == _optionIds.length,
            "Contracts and option ids must have the same length"
        );
        require(
            _optionIds.length == _issuedIds.length,
            "Option ids and issued ids must have the same length"
        );


        bytes memory mintData;

        for (uint256 i = 0; i < _contracts.length; i++) {
            mintData = abi.encodePacked(
                mintData,
                abi.encode(
                    _contracts[i],
                    _optionIds[i],
                    _issuedIds[i]
                )
            );
        }

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _beneficiary,
                mintData,
                _expires,
                _userId
            )
        )
        .toEthSignedMessageHash();

        _validateMessageAndSignature(messageHash, _signature);

        _issueManyTokens(
            _beneficiary,
            _contracts,
            _optionIds,
            _issuedIds,
            _userId
        );
    }

    /**
    * @dev Withdraw NFTs by minting them
    * @param _beneficiary - Beneficiary's address
    * @param _contracts - NFT contract' addresses
    * @param _optionIds - Option ids
    * @param _issuedIds - Issued ids
    * @param _userId - User id
    */
    function _issueManyTokens(
        address _beneficiary,
        address[] memory _contracts,
        uint256[] memory _optionIds,
        uint256[] memory _issuedIds,
        bytes memory _userId
    ) internal whenNotPaused {
        for (uint256 i = 0; i < _contracts.length; i++) {
            _issueToken(
                _beneficiary,
                _contracts[i],
                _optionIds[i],
                _issuedIds[i],
                _userId
            );
        }
    }

    /**
    * @dev Withdraw an NFT by minting it
    * @notice that the mint is based on an option and issued id.
    * The contract should implement the `issueToken` signature
    * @param _beneficiary - Beneficiary's address
    * @param _contract - NFT contract' address
    * @param _optionId - Option id
    * @param _issuedId - Issued id
    * @param _userId - User id
    */
    function _issueToken(
        address _beneficiary,
        address _contract,
        uint256 _optionId,
        uint256 _issuedId,
        bytes memory _userId
    ) internal whenNotPaused {
        IERC721PreMinteable(_contract).issueToken(_beneficiary, _optionId, _issuedId);

        emit Issued(_beneficiary, _contract, _optionId, _issuedId, _userId);
    }

    /**
    * @dev Validates that a message has not been processed, and signed by an authorized admin
    * @notice that will revert if any of the condition fails
    * @param _messageHash - Message
    * @param _signature - Signature
    */
    function _validateMessageAndSignature(bytes32 _messageHash, bytes memory _signature) internal {
        require(!messageProcessed[_messageHash], "The message has been processed");
        messageProcessed[_messageHash] = true;

        address signer = _messageHash.recover(_signature);
        require(adminWhitelist[signer], "Unauthorized admin signature");
    }
}