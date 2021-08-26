/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// File: contracts/ERC721/ERC721ReceiverDraft.sol

pragma solidity ^0.5.10;


/// @title ERC721ReceiverDraft
/// @dev Interface for any contract that wants to support safeTransfers from
///  ERC721 asset contracts.
/// @dev Note: this is the interface defined from 
///  https://github.com/ethereum/EIPs/commit/2bddd126def7c046e1e62408dc2b51bdd9e57f0f
///  to https://github.com/ethereum/EIPs/commit/27788131d5975daacbab607076f2ee04624f9dbb 
///  and is not the final interface.
///  Due to the extended period of time this revision was specified in the draft,
///  we are supporting both this and the newer (final) interface in order to be 
///  compatible with any ERC721 implementations that may have used this interface.
contract ERC721ReceiverDraft {

    /// @dev Magic value to be returned upon successful reception of an NFT
    ///  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
    ///  which can be also obtained as `ERC721ReceiverDraft(0).onERC721Received.selector`
    /// @dev see https://github.com/ethereum/EIPs/commit/2bddd126def7c046e1e62408dc2b51bdd9e57f0f
    bytes4 internal constant ERC721_RECEIVED_DRAFT = 0xf0b9e5ba;

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address 
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _from, uint256 _tokenId, bytes calldata data) external returns(bytes4);
}

// File: contracts/ERC721/ERC721ReceiverFinal.sol

pragma solidity ^0.5.10;


/// @title ERC721ReceiverFinal
/// @notice Interface for any contract that wants to support safeTransfers from
///  ERC721 asset contracts.
///  @dev Note: this is the final interface as defined at http://erc721.org
contract ERC721ReceiverFinal {

    /// @dev Magic value to be returned upon successful reception of an NFT
    ///  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
    ///  which can be also obtained as `ERC721ReceiverFinal(0).onERC721Received.selector`
    /// @dev see https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v1.12.0/contracts/token/ERC721/ERC721Receiver.sol
    bytes4 internal constant ERC721_RECEIVED_FINAL = 0x150b7a02;

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    /// after a `safetransfer`. This function MAY throw to revert and reject the
    /// transfer. Return of other than the magic value MUST result in the
    /// transaction being reverted.
    /// Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    )
    public
        returns (bytes4);
}

// File: contracts/ERC721/ERC721Receivable.sol

pragma solidity ^0.5.10;



/// @title ERC721Receivable handles the reception of ERC721 tokens
///  See ERC721 specification
/// @author Christopher Scott
/// @dev These functions are public, and could be called by anyone, even in the case
///  where no NFTs have been transferred. Since it's not a reliable source of
///  truth about ERC721 tokens being transferred, we save the gas and don't
///  bother emitting a (potentially spurious) event as found in 
///  https://github.com/OpenZeppelin/openzeppelin-solidity/blob/5471fc808a17342d738853d7bf3e9e5ef3108074/contracts/mocks/ERC721ReceiverMock.sol
contract ERC721Receivable is ERC721ReceiverDraft, ERC721ReceiverFinal {

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address 
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _from, uint256 _tokenId, bytes calldata data) external returns(bytes4) {
        _from;
        _tokenId;
        data;

        // emit ERC721Received(_operator, _from, _tokenId, _data, gasleft());

        return ERC721_RECEIVED_DRAFT;
    }

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    /// after a `safetransfer`. This function MAY throw to revert and reject the
    /// transfer. Return of other than the magic value MUST result in the
    /// transaction being reverted.
    /// Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    )
        public
        returns(bytes4)
    {
        _operator;
        _from;
        _tokenId;
        _data;

        // emit ERC721Received(_operator, _from, _tokenId, _data, gasleft());

        return ERC721_RECEIVED_FINAL;
    }

}

// File: contracts/ERC223/ERC223Receiver.sol

pragma solidity ^0.5.10;


/// @title ERC223Receiver ensures we are ERC223 compatible
/// @author Christopher Scott
contract ERC223Receiver {
    
    bytes4 public constant ERC223_ID = 0xc0ee0b8a;

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    /// @notice tokenFallback is called from an ERC223 compatible contract
    /// @param _from the address from which the token was sent
    /// @param _value the amount of tokens sent
    /// @param _data the data sent with the transaction
    function tokenFallback(address _from, uint _value, bytes memory _data) public pure {
        _from;
        _value;
        _data;
    //   TKN memory tkn;
    //   tkn.sender = _from;
    //   tkn.value = _value;
    //   tkn.data = _data;
    //   uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
    //   tkn.sig = bytes4(u);
      
      /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */

    }
}

// File: contracts/ERC1155/ERC1155TokenReceiver.sol

pragma solidity ^0.5.10;

contract ERC1155TokenReceiver {
    /// @dev `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^
    /// bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    bytes4 internal constant ERC1155_TOKEN_RECIEVER = 0x4e2312e0;

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
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external pure returns (bytes4) {
        _operator;
        _from;
        _id;
        _value;
        _data;

        return 0xf23a6e61;
    }

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
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external pure returns (bytes4) {
        _operator;
        _from;
        _ids;
        _values;
        _data;

        return 0xbc197c81;
    }
}

// File: contracts/ERC1271/ERC1271.sol

pragma solidity ^0.5.10;

contract ERC1271 {

    /// @dev bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant ERC1271_VALIDSIGNATURE = 0x1626ba7e;

    /// @dev Should return whether the signature provided is valid for the provided data
    /// @param hash 32-byte hash of the data that is signed
    /// @param _signature Signature byte array associated with _data
    ///  MUST return the bytes4 magic value 0x1626ba7e when function passes.
    ///  MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    ///  MUST allow external calls
    function isValidSignature(
        bytes32 hash, 
        bytes calldata _signature)
        external
        view 
        returns (bytes4);
}

// File: contracts/ECDSA.sol

pragma solidity ^0.5.10;


/// @title ECDSA is a library that contains useful methods for working with ECDSA signatures
library ECDSA {

    /// @notice Extracts the r, s, and v components from the `sigData` field starting from the `offset`
    /// @dev Note: does not do any bounds checking on the arguments!
    /// @param sigData the signature data; could be 1 or more packed signatures.
    /// @param offset the offset in sigData from which to start unpacking the signature components.
    function extractSignature(bytes memory sigData, uint256 offset) internal pure returns  (bytes32 r, bytes32 s, uint8 v) {
        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
             let dataPointer := add(sigData, offset)
             r := mload(add(dataPointer, 0x20))
             s := mload(add(dataPointer, 0x40))
             v := byte(0, mload(add(dataPointer, 0x60)))
        }
    
        return (r, s, v);
    }
}

// File: contracts/Wallet/CoreWallet.sol

pragma solidity ^0.5.10;







/// @title Core Wallet
/// @notice A basic smart contract wallet with cosigner functionality. The notion of "cosigner" is
///  the simplest possible multisig solution, a two-of-two signature scheme. It devolves nicely
///  to "one-of-one" (i.e. singlesig) by simply having the cosigner set to the same value as
///  the main signer.
/// 
///  Most "advanced" functionality (deadman's switch, multiday recovery flows, blacklisting, etc)
///  can be implemented externally to this smart contract, either as an additional smart contract
///  (which can be tracked as a signer without cosigner, or as a cosigner) or as an off-chain flow
///  using a public/private key pair as cosigner. Of course, the basic cosigning functionality could
///  also be implemented in this way, but (A) the complexity and gas cost of two-of-two multisig (as
///  implemented here) is negligable even if you don't need the cosigner functionality, and
///  (B) two-of-two multisig (as implemented here) handles a lot of really common use cases, most
///  notably third-party gas payment and off-chain blacklisting and fraud detection.
contract CoreWallet is ERC721Receivable, ERC223Receiver, ERC1271, ERC1155TokenReceiver {

    using ECDSA for bytes;

    /// @notice We require that presigned transactions use the EIP-191 signing format.
    ///  See that EIP for more info: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-191.md
    byte public constant EIP191_VERSION_DATA = byte(0);
    byte public constant EIP191_PREFIX = byte(0x19);

    /// @notice This is the version of the contract.
    string public constant VERSION = "1.1.0";

    /// @notice This is a sentinel value used to determine when a delegate is set to expose 
    ///  support for an interface containing more than a single function. See `delegates` and
    ///  `setDelegate` for more information.
    address public constant COMPOSITE_PLACEHOLDER = address(1);

    /// @notice A pre-shifted "1", used to increment the authVersion, so we can "prepend"
    ///  the authVersion to an address (for lookups in the authorizations mapping)
    ///  by using the '+' operator (which is cheaper than a shift and a mask). See the
    ///  comment on the `authorizations` variable for how this is used.
    uint256 public constant AUTH_VERSION_INCREMENTOR = (1 << 160);
    
    /// @notice The pre-shifted authVersion (to get the current authVersion as an integer,
    ///  shift this value right by 160 bits). Starts as `1 << 160` (`AUTH_VERSION_INCREMENTOR`)
    ///  See the comment on the `authorizations` variable for how this is used.
    uint256 public authVersion;

    /// @notice A mapping containing all of the addresses that are currently authorized to manage
    ///  the assets owned by this wallet.
    ///
    ///  The keys in this mapping are authorized addresses with a version number prepended,
    ///  like so: (authVersion,96)(address,160). The current authVersion MUST BE included
    ///  for each look-up; this allows us to effectively clear the entire mapping of its
    ///  contents merely by incrementing the authVersion variable. (This is important for
    ///  the emergencyRecovery() method.) Inspired by https://ethereum.stackexchange.com/a/42540
    ///
    ///  The values in this mapping are 256bit words, whose lower 20 bytes constitute "cosigners"
    ///  for each address. If an address maps to itself, then that address is said to have no cosigner.
    ///
    ///  The upper 12 bytes are reserved for future meta-data purposes.  The meta-data could refer
    ///  to the key (authorized address) or the value (cosigner) of the mapping.
    ///
    ///  Addresses that map to a non-zero cosigner in the current authVersion are called
    ///  "authorized addresses".
    mapping(uint256 => uint256) public authorizations;

    /// @notice A per-key nonce value, incremented each time a transaction is processed with that key.
    ///  Used for replay prevention. The nonce value in the transaction must exactly equal the current
    ///  nonce value in the wallet for that key. (This mirrors the way Ethereum's transaction nonce works.)
    mapping(address => uint256) public nonces;

    /// @notice A mapping tracking dynamically supported interfaces and their corresponding
    ///  implementation contracts. Keys are interface IDs and values are addresses of
    ///  contracts that are responsible for implementing the function corresponding to the
    ///  interface.
    ///  
    ///  Delegates are added (or removed) via the `setDelegate` method after the contract is
    ///  deployed, allowing support for new interfaces to be dynamically added after deployment.
    ///  When a delegate is added, its interface ID is considered "supported" under EIP165. 
    ///
    ///  For cases where an interface composed of more than a single function must be
    ///  supported, it is necessary to manually add the composite interface ID with 
    ///  `setDelegate(interfaceId, COMPOSITE_PLACEHOLDER)`. Interface IDs added with the
    ///  COMPOSITE_PLACEHOLDER address are ignored when called and are only used to specify
    ///  supported interfaces.
    mapping(bytes4 => address) public delegates;

    /// @notice A special address that is authorized to call `emergencyRecovery()`. That function
    ///  resets ALL authorization for this wallet, and must therefore be treated with utmost security.
    ///  Reasonable choices for recoveryAddress include:
    ///       - the address of a private key in cold storage
    ///       - a physically secured hardware wallet
    ///       - a multisig smart contract, possibly with a time-delayed challenge period
    ///       - the zero address, if you like performing without a safety net ;-)
    address public recoveryAddress;

    /// @notice Used to track whether or not this contract instance has been initialized. This
    ///  is necessary since it is common for this wallet smart contract to be used as the "library
    ///  code" for an clone contract. See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    ///  for more information about clone contracts.
    bool public initialized;
    
    /// @notice Used to decorate methods that can only be called directly by the recovery address.
    modifier onlyRecoveryAddress() {
        require(msg.sender == recoveryAddress, "sender must be recovery address");
        _;
    }

    /// @notice Used to decorate the `init` function so this can only be called one time. Necessary
    ///  since this contract will often be used as a "clone". (See above.)
    modifier onlyOnce() {
        require(!initialized, "must not already be initialized");
        initialized = true;
        _;
    }
    
    /// @notice Used to decorate methods that can only be called indirectly via an `invoke()` method.
    ///  In practice, it means that those methods can only be called by a signer/cosigner
    ///  pair that is currently authorized. Theoretically, we could factor out the
    ///  signer/cosigner verification code and use it explicitly in this modifier, but that
    ///  would either result in duplicated code, or additional overhead in the invoke()
    ///  calls (due to the stack manipulation for calling into the shared verification function).
    ///  Doing it this way makes calling the administration functions more expensive (since they
    ///  go through a explicit call() instead of just branching within the contract), but it
    ///  makes invoke() more efficient. We assume that invoke() will be used much, much more often
    ///  than any of the administration functions.
    modifier onlyInvoked() {
        require(msg.sender == address(this), "must be called from `invoke()`");
        _;
    }
    
    /// @notice Emitted when an authorized address is added, removed, or modified. When an
    ///  authorized address is removed ("deauthorized"), cosigner will be address(0) in
    ///  this event.
    ///  
    ///  NOTE: When emergencyRecovery() is called, all existing addresses are deauthorized
    ///  WITHOUT Authorized(addr, 0) being emitted. If you are keeping an off-chain mirror of
    ///  authorized addresses, you must also watch for EmergencyRecovery events.
    /// @dev hash is 0xf5a7f4fb8a92356e8c8c4ae7ac3589908381450500a7e2fd08c95600021ee889
    /// @param authorizedAddress the address to authorize or unauthorize
    /// @param cosigner the 2-of-2 signatory (optional).
    event Authorized(address authorizedAddress, uint256 cosigner);
    
    /// @notice Emitted when an emergency recovery has been performed. If this event is fired,
    ///  ALL previously authorized addresses have been deauthorized and the only authorized
    ///  address is the authorizedAddress indicated in this event.
    /// @dev hash is 0xe12d0bbeb1d06d7a728031056557140afac35616f594ef4be227b5b172a604b5
    /// @param authorizedAddress the new authorized address
    /// @param cosigner the cosigning address for `authorizedAddress`
    event EmergencyRecovery(address authorizedAddress, uint256 cosigner);

    /// @notice Emitted when the recovery address changes. Either (but not both) of the
    ///  parameters may be zero.
    /// @dev hash is 0x568ab3dedd6121f0385e007e641e74e1f49d0fa69cab2957b0b07c4c7de5abb6
    /// @param previousRecoveryAddress the previous recovery address
    /// @param newRecoveryAddress the new recovery address
    event RecoveryAddressChanged(address previousRecoveryAddress, address newRecoveryAddress);

    /// @dev Emitted when this contract receives a non-zero amount ether via the fallback function
    ///  (i.e. This event is not fired if the contract receives ether as part of a method invocation)
    /// @param from the address which sent you ether
    /// @param value the amount of ether sent
    event Received(address from, uint value);

    /// @notice Emitted whenever a transaction is processed successfully from this wallet. Includes
    ///  both simple send ether transactions, as well as other smart contract invocations.
    /// @dev hash is 0x101214446435ebbb29893f3348e3aae5ea070b63037a3df346d09d3396a34aee
    /// @param hash The hash of the entire operation set. 0 is returned when emitted from `invoke0()`.
    /// @param result A bitfield of the results of the operations. A bit of 0 means success, and 1 means failure.
    /// @param numOperations A count of the number of operations processed
    event InvocationSuccess(
        bytes32 hash,
        uint256 result,
        uint256 numOperations
    );

    /// @notice Emitted when a delegate is added or removed.
    /// @param interfaceId The interface ID as specified by EIP165
    /// @param delegate The address of the contract implementing the given function. If this is
    ///  COMPOSITE_PLACEHOLDER, we are indicating support for a composite interface.
    event DelegateUpdated(bytes4 interfaceId, address delegate);

    /// @notice The shared initialization code used to setup the contract state regardless of whether or
    ///  not the clone pattern is being used.
    /// @param _authorizedAddress the initial authorized address, must not be zero!
    /// @param _cosigner the initial cosigning address for `_authorizedAddress`, can be equal to `_authorizedAddress`
    /// @param _recoveryAddress the initial recovery address for the wallet, can be address(0)
    function init(address _authorizedAddress, uint256 _cosigner, address _recoveryAddress) public onlyOnce {
        require(_authorizedAddress != _recoveryAddress, "Do not use the recovery address as an authorized address.");
        require(address(_cosigner) != _recoveryAddress, "Do not use the recovery address as a cosigner.");
        require(_authorizedAddress != address(0), "Authorized addresses must not be zero.");
        require(address(_cosigner) != address(0), "Initial cosigner must not be zero.");
        
        recoveryAddress = _recoveryAddress;
        // set initial authorization value
        authVersion = AUTH_VERSION_INCREMENTOR;
        // add initial authorized address
        authorizations[authVersion + uint256(_authorizedAddress)] = _cosigner;
        
        emit Authorized(_authorizedAddress, _cosigner);
    }

    function bytesToAddresses(bytes memory bys) private pure returns (address[] memory addresses) {
            addresses = new address[](bys.length/20);
            for (uint i=0; i < bys.length; i+=20) {
                address addr;
                uint end = i+20;
                assembly {
                  addr := mload(add(bys,end))
                }
                addresses[i/20] = addr;
            }
        }

    function init2(bytes memory _authorizedAddresses, uint256 _cosigner, address _recoveryAddress) public onlyOnce {
        address[] memory addresses = bytesToAddresses(_authorizedAddresses);
        for (uint i=0; i < addresses.length; i++) {
            address _authorizedAddress = addresses[i];
            require(_authorizedAddress != _recoveryAddress, "Do not use the recovery address as an authorized address.");
            require(address(_cosigner) != _recoveryAddress, "Do not use the recovery address as a cosigner.");
            require(_authorizedAddress != address(0), "Authorized addresses must not be zero.");
            require(address(_cosigner) != address(0), "Initial cosigner must not be zero.");

            recoveryAddress = _recoveryAddress;
            // set initial authorization value
            authVersion = AUTH_VERSION_INCREMENTOR;
            // add initial authorized address
            authorizations[authVersion + uint256(_authorizedAddress)] = _cosigner;

            emit Authorized(_authorizedAddress, _cosigner);
        }
    }

    /// @notice The fallback function, invoked whenever we receive a transaction that doesn't call any of our
    ///  named functions. In particular, this method is called when we are the target of a simple send
    ///  transaction, when someone calls a method we have dynamically added a delegate for, or when someone
    ///  tries to call a function we don't implement, either statically or dynamically.
    ///
    ///  A correct invocation of this method occurs in two cases:
    ///  - someone transfers ETH to this wallet (`msg.data.length` is  0)
    ///  - someone calls a delegated function (`msg.data.length` is greater than 0 and
    ///    `delegates[msg.sig]` is set) 
    ///  In all other cases, this function will revert.
    ///
    ///  NOTE: Some smart contracts send 0 eth as part of a more complex operation
    ///  (-cough- CryptoKitties -cough-); ideally, we'd `require(msg.value > 0)` here when
    ///  `msg.data.length == 0`, but to work with those kinds of smart contracts, we accept zero sends
    ///  and just skip logging in that case.
    function() external payable {
        if (msg.value > 0) {
            emit Received(msg.sender, msg.value);
        }
        if (msg.data.length > 0) {
            address delegate = delegates[msg.sig]; 
            require(delegate > COMPOSITE_PLACEHOLDER, "Invalid transaction");

            // We have found a delegate contract that is responsible for the method signature of
            // this call. Now, pass along the calldata of this CALL to the delegate contract.  
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := staticcall(gas, delegate, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())

                // If the delegate reverts, we revert. If the delegate does not revert, we return the data
                // returned by the delegate to the original caller.
                switch result 
                case 0 {
                    revert(0, returndatasize())
                } 
                default {
                    return(0, returndatasize())
                }
            } 
        }    
    }

    /// @notice Adds or removes dynamic support for an interface. Can be used in 3 ways:
    ///   - Add a contract "delegate" that implements a single function
    ///   - Remove delegate for a function
    ///   - Specify that an interface ID is "supported", without adding a delegate. This is
    ///     used for composite interfaces when the interface ID is not a single method ID.
    /// @dev Must be called through `invoke`
    /// @param _interfaceId The ID of the interface we are adding support for
    /// @param _delegate Either:
    ///    - the address of a contract that implements the function specified by `_interfaceId`
    ///      for adding an implementation for a single function
    ///    - 0 for removing an existing delegate
    ///    - COMPOSITE_PLACEHOLDER for specifying support for a composite interface
    function setDelegate(bytes4 _interfaceId, address _delegate) external onlyInvoked {
        delegates[_interfaceId] = _delegate;
        emit DelegateUpdated(_interfaceId, _delegate);
    }
    
    /// @notice Configures an authorizable address. Can be used in four ways:
    ///   - Add a new signer/cosigner pair (cosigner must be non-zero)
    ///   - Set or change the cosigner for an existing signer (if authorizedAddress != cosigner)
    ///   - Remove the cosigning requirement for a signer (if authorizedAddress == cosigner)
    ///   - Remove a signer (if cosigner == address(0))
    /// @dev Must be called through `invoke()`
    /// @param _authorizedAddress the address to configure authorization
    /// @param _cosigner the corresponding cosigning address
    function setAuthorized(address _authorizedAddress, uint256 _cosigner) external onlyInvoked {
        // TODO: Allowing a signer to remove itself is actually pretty terrible; it could result in the user
        //  removing their only available authorized key. Unfortunately, due to how the invocation forwarding
        //  works, we don't actually _know_ which signer was used to call this method, so there's no easy way
        //  to prevent this.
        
        // TODO: Allowing the backup key to be set as an authorized address bypasses the recovery mechanisms.
        //  Dapper can prevent this with offchain logic and the cosigner, but it would be nice to have 
        //  this enforced by the smart contract logic itself.
        
        require(_authorizedAddress != address(0), "Authorized addresses must not be zero.");
        require(_authorizedAddress != recoveryAddress, "Do not use the recovery address as an authorized address.");
        require(address(_cosigner) == address(0) || address(_cosigner) != recoveryAddress, "Do not use the recovery address as a cosigner.");
 
        authorizations[authVersion + uint256(_authorizedAddress)] = _cosigner;
        emit Authorized(_authorizedAddress, _cosigner);
    }
    
    /// @notice Performs an emergency recovery operation, removing all existing authorizations and setting
    ///  a sole new authorized address with optional cosigner. THIS IS A SCORCHED EARTH SOLUTION, and great
    ///  care should be taken to ensure that this method is never called unless it is a last resort. See the
    ///  comments above about the proper kinds of addresses to use as the recoveryAddress to ensure this method
    ///  is not trivially abused.
    /// @param _authorizedAddress the new and sole authorized address
    /// @param _cosigner the corresponding cosigner address, can be equal to _authorizedAddress
    function emergencyRecovery(address _authorizedAddress, uint256 _cosigner) external onlyRecoveryAddress {
        require(_authorizedAddress != address(0), "Authorized addresses must not be zero.");
        require(_authorizedAddress != recoveryAddress, "Do not use the recovery address as an authorized address.");
        require(address(_cosigner) != address(0), "The cosigner must not be zero.");

        // Incrementing the authVersion number effectively erases the authorizations mapping. See the comments
        // on the authorizations variable (above) for more information.
        authVersion += AUTH_VERSION_INCREMENTOR;

        // Store the new signer/cosigner pair as the only remaining authorized address
        authorizations[authVersion + uint256(_authorizedAddress)] = _cosigner;
        emit EmergencyRecovery(_authorizedAddress, _cosigner);
    }

    function emergencyRecovery2(address _authorizedAddress, uint256 _cosigner, address _recoveryAddress) external onlyRecoveryAddress {
            require(_authorizedAddress != address(0), "Authorized addresses must not be zero.");
            require(_authorizedAddress != _recoveryAddress, "Do not use the recovery address as an authorized address.");
            require(address(_cosigner) != address(0), "The cosigner must not be zero.");

            // Incrementing the authVersion number effectively erases the authorizations mapping. See the comments
            // on the authorizations variable (above) for more information.
            authVersion += AUTH_VERSION_INCREMENTOR;

            // Store the new signer/cosigner pair as the only remaining authorized address
            authorizations[authVersion + uint256(_authorizedAddress)] = _cosigner;

            // set new recovery address
            address previous = recoveryAddress;
            recoveryAddress = _recoveryAddress;

            emit RecoveryAddressChanged(previous, recoveryAddress);
            emit EmergencyRecovery(_authorizedAddress, _cosigner);
     }

    /// @notice Sets the recovery address, which can be zero (indicating that no recovery is possible)
    ///  Can be updated by any authorized address. This address should be set with GREAT CARE. See the
    ///  comments above about the proper kinds of addresses to use as the recoveryAddress to ensure this
    ///  mechanism is not trivially abused.
    /// @dev Must be called through `invoke()`
    /// @param _recoveryAddress the new recovery address
    function setRecoveryAddress(address _recoveryAddress) external onlyInvoked {
        require(
            address(authorizations[authVersion + uint256(_recoveryAddress)]) == address(0),
            "Do not use an authorized address as the recovery address."
        );
 
        address previous = recoveryAddress;
        recoveryAddress = _recoveryAddress;

        emit RecoveryAddressChanged(previous, recoveryAddress);
    }

    /// @notice Allows ANY caller to recover gas by way of deleting old authorization keys after
    ///  a recovery operation. Anyone can call this method to delete the old unused storage and
    ///  get themselves a bit of gas refund in the bargin.
    /// @dev keys must be known to caller or else nothing is refunded
    /// @param _version the version of the mapping which you want to delete (unshifted)
    /// @param _keys the authorization keys to delete 
    function recoverGas(uint256 _version, address[] calldata _keys) external {
        // TODO: should this be 0xffffffffffffffffffffffff ?
        require(_version > 0 && _version < 0xffffffff, "Invalid version number.");
        
        uint256 shiftedVersion = _version << 160;

        require(shiftedVersion < authVersion, "You can only recover gas from expired authVersions.");

        for (uint256 i = 0; i < _keys.length; ++i) {
            delete(authorizations[shiftedVersion + uint256(_keys[i])]);
        }
    }

    /// @notice Should return whether the signature provided is valid for the provided data
    ///  See https://github.com/ethereum/EIPs/issues/1271
    /// @dev This function meets the following conditions as per the EIP:
    ///  MUST return the bytes4 magic value `0x1626ba7e` when function passes.
    ///  MUST NOT modify state (using `STATICCALL` for solc < 0.5, `view` modifier for solc > 0.5)
    ///  MUST allow external calls
    /// @param hash A 32 byte hash of the signed data.  The actual hash that is hashed however is the
    ///  the following tightly packed arguments: `0x19,0x0,wallet_address,hash`
    /// @param _signature Signature byte array associated with `_data`
    /// @return Magic value `0x1626ba7e` upon success, 0 otherwise.
    function isValidSignature(bytes32 hash, bytes calldata _signature) external view returns (bytes4) {
        
        // We 'hash the hash' for the following reasons:
        // 1. `hash` is not the hash of an Ethereum transaction
        // 2. signature must target this wallet to avoid replaying the signature for another wallet
        // with the same key
        // 3. Gnosis does something similar: 
        // https://github.com/gnosis/safe-contracts/blob/102e632d051650b7c4b0a822123f449beaf95aed/contracts/GnosisSafe.sol
        bytes32 operationHash = keccak256(
            abi.encodePacked(
            EIP191_PREFIX,
            EIP191_VERSION_DATA,
            this,
            hash));

        bytes32[2] memory r;
        bytes32[2] memory s;
        uint8[2] memory v;
        address signer;
        address cosigner;

        // extract 1 or 2 signatures depending on length
        if (_signature.length == 65) {
            (r[0], s[0], v[0]) = _signature.extractSignature(0);
            signer = ecrecover(operationHash, v[0], r[0], s[0]);
            cosigner = signer;
        } else if (_signature.length == 130) {
            (r[0], s[0], v[0]) = _signature.extractSignature(0);
            (r[1], s[1], v[1]) = _signature.extractSignature(65);
            signer = ecrecover(operationHash, v[0], r[0], s[0]);
            cosigner = ecrecover(operationHash, v[1], r[1], s[1]);
        } else {
            return 0;
        }
            
        // check for valid signature
        if (signer == address(0)) {
            return 0;
        }

        // check for valid signature
        if (cosigner == address(0)) {
            return 0;
        }

        // check to see if this is an authorized key
        if (address(authorizations[authVersion + uint256(signer)]) != cosigner) {
            return 0;
        }

        return ERC1271_VALIDSIGNATURE;
    }

    /// @notice Query if this contract implements an interface. This function takes into account
    ///  interfaces we implement dynamically through delegates. For interfaces that are just a
    ///  single method, using `setDelegate` will result in that method's ID returning true from 
    ///  `supportsInterface`. For composite interfaces that are composed of multiple functions, it is
    ///  necessary to add the interface ID manually with `setDelegate(interfaceID,
    ///  COMPOSITE_PLACEHOLDER)`
    ///  IN ADDITION to adding each function of the interface as usual.
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        // First check if the ID matches one of the interfaces we support statically.
        if (
            interfaceID == this.supportsInterface.selector || // ERC165
            interfaceID == ERC721_RECEIVED_FINAL || // ERC721 Final
            interfaceID == ERC721_RECEIVED_DRAFT || // ERC721 Draft
            interfaceID == ERC223_ID || // ERC223
            interfaceID == ERC1155_TOKEN_RECIEVER || // ERC1155 Token Reciever
            interfaceID == ERC1271_VALIDSIGNATURE // ERC1271
        ) {
            return true;
        }
        // If we don't support the interface statically, check whether we have added
        // dynamic support for it.
        return uint256(delegates[interfaceID]) > 0;
    }

    /// @notice A version of `invoke()` that has no explicit signatures, and uses msg.sender
    ///  as both the signer and cosigner. Will only succeed if `msg.sender` is an authorized
    ///  signer for this wallet, with no cosigner, saving transaction size and gas in that case.
    /// @param data The data containing the transactions to be invoked; see internalInvoke for details.
    function invoke0(bytes calldata data) external {
        // The nonce doesn't need to be incremented for transactions that don't include explicit signatures;
        // the built-in nonce of the native ethereum transaction will protect against replay attacks, and we
        // can save the gas that would be spent updating the nonce variable

        // The operation should be approved if the signer address has no cosigner (i.e. signer == cosigner)
        require(address(authorizations[authVersion + uint256(msg.sender)]) == msg.sender, "Invalid authorization.");

        internalInvoke(0, data);
    }

    /// @notice A version of `invoke()` that has one explicit signature which is used to derive the authorized
    ///  address. Uses `msg.sender` as the cosigner.
    /// @param v the v value for the signature; see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
    /// @param r the r value for the signature
    /// @param s the s value for the signature
    /// @param nonce the nonce value for the signature
    /// @param authorizedAddress the address of the authorization key; this is used here so that cosigner signatures are interchangeable
    ///  between this function and `invoke2()`
    /// @param data The data containing the transactions to be invoked; see internalInvoke for details.
    function invoke1CosignerSends(uint8 v, bytes32 r, bytes32 s, uint256 nonce, address authorizedAddress, bytes calldata data) external {
        // check signature version
        require(v == 27 || v == 28, "Invalid signature version.");

        // calculate hash
        bytes32 operationHash = keccak256(
            abi.encodePacked(
            EIP191_PREFIX,
            EIP191_VERSION_DATA,
            this,
            nonce,
            authorizedAddress,
            data));
 
        // recover signer
        address signer = ecrecover(operationHash, v, r, s);

        // check for valid signature
        require(signer != address(0), "Invalid signature.");

        // check nonce
        require(nonce > nonces[signer], "must use valid nonce for signer");

        // check signer
        require(signer == authorizedAddress, "authorized addresses must be equal");

        // Get cosigner
        address requiredCosigner = address(authorizations[authVersion + uint256(signer)]);
        
        // The operation should be approved if the signer address has no cosigner (i.e. signer == cosigner) or
        // if the actual cosigner matches the required cosigner.
        require(requiredCosigner == signer || requiredCosigner == msg.sender, "Invalid authorization.");

        // increment nonce to prevent replay attacks
        nonces[signer] = nonce;

        // call internal function
        internalInvoke(operationHash, data);
    }

    /// @notice A version of `invoke()` that has one explicit signature which is used to derive the cosigning
    ///  address. Uses `msg.sender` as the authorized address.
    /// @param v the v value for the signature; see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
    /// @param r the r value for the signature
    /// @param s the s value for the signature
    /// @param data The data containing the transactions to be invoked; see internalInvoke for details.
    function invoke1SignerSends(uint8 v, bytes32 r, bytes32 s, bytes calldata data) external {
        // check signature version
        // `ecrecover` will in fact return 0 if given invalid
        // so perhaps this check is redundant
        require(v == 27 || v == 28, "Invalid signature version.");
        
        uint256 nonce = nonces[msg.sender];

        // calculate hash
        bytes32 operationHash = keccak256(
            abi.encodePacked(
            EIP191_PREFIX,
            EIP191_VERSION_DATA,
            this,
            nonce,
            msg.sender,
            data));
 
        // recover cosigner
        address cosigner = ecrecover(operationHash, v, r, s);
        
        // check for valid signature
        require(cosigner != address(0), "Invalid signature.");

        // Get required cosigner
        address requiredCosigner = address(authorizations[authVersion + uint256(msg.sender)]);
        
        // The operation should be approved if the signer address has no cosigner (i.e. signer == cosigner) or
        // if the actual cosigner matches the required cosigner.
        require(requiredCosigner == cosigner || requiredCosigner == msg.sender, "Invalid authorization.");

        // increment nonce to prevent replay attacks
        nonces[msg.sender] = nonce + 1;
 
        internalInvoke(operationHash, data);
    }

    /// @notice A version of `invoke()` that has two explicit signatures, the first is used to derive the authorized
    ///  address, the second to derive the cosigner. The value of `msg.sender` is ignored.
    /// @param v the v values for the signatures
    /// @param r the r values for the signatures
    /// @param s the s values for the signatures
    /// @param nonce the nonce value for the signature
    /// @param authorizedAddress the address of the signer; forces the signature to be unique and tied to the signers nonce 
    /// @param data The data containing the transactions to be invoked; see internalInvoke for details.
    function invoke2(uint8[2] calldata v, bytes32[2] calldata r, bytes32[2] calldata s, uint256 nonce, address authorizedAddress, bytes calldata data) external {
        // check signature versions
        // `ecrecover` will infact return 0 if given invalid
        // so perhaps these checks are redundant
        require(v[0] == 27 || v[0] == 28, "invalid signature version v[0]");
        require(v[1] == 27 || v[1] == 28, "invalid signature version v[1]");
 
        bytes32 operationHash = keccak256(
            abi.encodePacked(
            EIP191_PREFIX,
            EIP191_VERSION_DATA,
            this,
            nonce,
            authorizedAddress,
            data));
 
        // recover signer and cosigner
        address signer = ecrecover(operationHash, v[0], r[0], s[0]);
        address cosigner = ecrecover(operationHash, v[1], r[1], s[1]);

        // check for valid signatures
        require(signer != address(0), "Invalid signature for signer.");
        require(cosigner != address(0), "Invalid signature for cosigner.");

        // check signer address
        require(signer == authorizedAddress, "authorized addresses must be equal");

        // check nonces
        require(nonce > nonces[signer], "must use valid nonce for signer");

        // Get Mapping
        address requiredCosigner = address(authorizations[authVersion + uint256(signer)]);
        
        // The operation should be approved if the signer address has no cosigner (i.e. signer == cosigner) or
        // if the actual cosigner matches the required cosigner.
        require(requiredCosigner == signer || requiredCosigner == cosigner, "Invalid authorization.");

        // increment nonce to prevent replay attacks
        nonces[signer] = nonce;

        internalInvoke(operationHash, data);
    }

    /// @dev Internal invoke call, 
    /// @param operationHash The hash of the operation
    /// @param data The data to send to the `call()` operation
    ///  The data is prefixed with a global 1 byte revert flag
    ///  If revert is 1, then any revert from a `call()` operation is rethrown.
    ///  Otherwise, the error is recorded in the `result` field of the `InvocationSuccess` event.
    ///  Immediately following the revert byte (no padding), the data format is then is a series
    ///  of 1 or more tightly packed tuples:
    ///  `<target(20),amount(32),datalength(32),data>`
    ///  If `datalength == 0`, the data field must be omitted
    function internalInvoke(bytes32 operationHash, bytes memory data) internal {
        // keep track of the number of operations processed
        uint256 numOps;
        // keep track of the result of each operation as a bit
        uint256 result;

        // We need to store a reference to this string as a variable so we can use it as an argument to
        // the revert call from assembly.
        string memory invalidLengthMessage = "Data field too short";
        string memory callFailed = "Call failed";

        // At an absolute minimum, the data field must be at least 85 bytes
        // <revert(1), to_address(20), value(32), data_length(32)>
        require(data.length >= 85, invalidLengthMessage);

        // Forward the call onto its actual target. Note that the target address can be `self` here, which is
        // actually the required flow for modifying the configuration of the authorized keys and recovery address.
        //
        // The assembly code below loads data directly from memory, so the enclosing function must be marked `internal`
        assembly {
            // A cursor pointing to the revert flag, starts after the length field of the data object
            let memPtr := add(data, 32)

            // The revert flag is the leftmost byte from memPtr
            let revertFlag := byte(0, mload(memPtr))

            // A pointer to the end of the data object
            let endPtr := add(memPtr, mload(data))

            // Now, memPtr is a cursor pointing to the beginning of the current sub-operation
            memPtr := add(memPtr, 1)

            // Loop through data, parsing out the various sub-operations
            for { } lt(memPtr, endPtr) { } {
                // Load the length of the call data of the current operation
                // 52 = to(20) + value(32)
                let len := mload(add(memPtr, 52))
                
                // Compute a pointer to the end of the current operation
                // 84 = to(20) + value(32) + size(32)
                let opEnd := add(len, add(memPtr, 84))

                // Bail if the current operation's data overruns the end of the enclosing data buffer
                // NOTE: Comment out this bit of code and uncomment the next section if you want
                // the solidity-coverage tool to work.
                // See https://github.com/sc-forks/solidity-coverage/issues/287
                if gt(opEnd, endPtr) {
                    // The computed end of this operation goes past the end of the data buffer. Not good!
                    revert(add(invalidLengthMessage, 32), mload(invalidLengthMessage))
                }
                // NOTE: Code that is compatible with solidity-coverage
                // switch gt(opEnd, endPtr)
                // case 1 {
                //     revert(add(invalidLengthMessage, 32), mload(invalidLengthMessage))
                // }

                // This line of code packs in a lot of functionality!
                //  - load the target address from memPtr, the address is only 20-bytes but mload always grabs 32-bytes,
                //    so we have to shr by 12 bytes.
                //  - load the value field, stored at memPtr+20
                //  - pass a pointer to the call data, stored at memPtr+84
                //  - use the previously loaded len field as the size of the call data
                //  - make the call (passing all remaining gas to the child call)
                //  - check the result (0 == reverted)
                if eq(0, call(gas, shr(96, mload(memPtr)), mload(add(memPtr, 20)), add(memPtr, 84), len, 0, 0)) {
                    switch revertFlag
                    case 1 {
                        revert(add(callFailed, 32), mload(callFailed))
                    }
                    default {
                        // mark this operation as failed
                        // create the appropriate bit, 'or' with previous
                        result := or(result, exp(2, numOps))
                    }
                }

                // increment our counter
                numOps := add(numOps, 1)
             
                // Update mem pointer to point to the next sub-operation
                memPtr := opEnd
            }
        }

        // emit single event upon success
        emit InvocationSuccess(operationHash, result, numOps);
    }
}

// File: contracts/Wallet/CloneableWallet.sol

pragma solidity ^0.5.10;



/// @title Cloneable Wallet
/// @notice This contract represents a complete but non working wallet.  
///  It is meant to be deployed and serve as the contract that you clone
///  in an EIP 1167 clone setup.
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
/// @dev Currently, we are seeing approximatley 933 gas overhead for using
///  the clone wallet; use `FullWallet` if you think users will overtake
///  the transaction threshold over the lifetime of the wallet.
contract CloneableWallet is CoreWallet {

    /// @dev An empty constructor that deploys a NON-FUNCTIONAL version
    ///  of `CoreWallet`
    constructor () public {
        initialized = true;
    }
}

// File: contracts/Ownership/Ownable.sol

pragma solidity ^0.5.10;


/// @title Ownable is for contracts that can be owned.
/// @dev The Ownable contract keeps track of an owner address,
///  and provides basic authorization functions.
contract Ownable {

    /// @dev the owner of the contract
    address public owner;

    /// @dev Fired when the owner to renounce ownership, leaving no one
    ///  as the owner.
    /// @param previousOwner The previous `owner` of this contract
    event OwnershipRenounced(address indexed previousOwner);
    
    /// @dev Fired when the owner to changes ownership
    /// @param previousOwner The previous `owner`
    /// @param newOwner The new `owner`
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev sets the `owner` to `msg.sender`
    constructor() public {
        owner = msg.sender;
    }

    /// @dev Throws if the `msg.sender` is not the current `owner`
    modifier onlyOwner() {
        require(msg.sender == owner, "must be owner");
        _;
    }

    /// @dev Allows the current `owner` to renounce ownership
    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /// @dev Allows the current `owner` to transfer ownership
    /// @param _newOwner The new `owner`
    function transferOwnership(address _newOwner) external onlyOwner {
        _transferOwnership(_newOwner);
    }

    /// @dev Internal version of `transferOwnership`
    /// @param _newOwner The new `owner`
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "cannot renounce ownership");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// File: contracts/Ownership/HasNoEther.sol

pragma solidity ^0.5.10;



/// @title HasNoEther is for contracts that should not own Ether
contract HasNoEther is Ownable {

    /// @dev This contructor rejects incoming Ether
    constructor() public payable {
        require(msg.value == 0, "must not send Ether");
    }

    /// @dev Disallows direct send by default function not being `payable`
    function() external {}

    /// @dev Transfers all Ether held by this contract to the owner.
    function reclaimEther() external onlyOwner {
        msg.sender.transfer(address(this).balance); 
    }
}

// File: contracts/WalletFactory/CloneFactory.sol

pragma solidity ^0.5.10;


/// @title CloneFactory - a contract that creates clones
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
/// @dev See https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
contract CloneFactory {
    event CloneCreated(address indexed target, address clone);

    function createClone(address target) internal returns (address payable result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function createClone2(address target, bytes32 salt) internal returns (address payable result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create2(0, clone, 0x37, salt)
        }
    }
}

// File: contracts/WalletFactory/FullWalletByteCode.sol

pragma solidity ^0.5.10;

/// @title FullWalletByteCode
/// @dev A contract containing the FullWallet bytecode, for use in deployment.
contract FullWalletByteCode {
    /// @notice This is the raw bytecode of the full wallet. It is encoded here as a raw byte
    ///  array to support deployment with CREATE2, as Solidity's 'new' constructor system does
    ///  not support CREATE2 yet.
    ///
    ///  NOTE: Be sure to update this whenever the wallet bytecode changes!
    ///  Simply run `npm run build` and then copy the `"bytecode"`
    ///  portion from the `build/contracts/FullWallet.json` file to here,
    ///  then append 64x3 0's.
    bytes constant fullWalletBytecode = hex'60806040523480156200001157600080fd5b50604051620033a7380380620033a7833981810160405260608110156200003757600080fd5b50805160208201516040909201519091906200005e8383836001600160e01b036200006716565b5050506200033b565b60045474010000000000000000000000000000000000000000900460ff1615620000f257604080517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601f60248201527f6d757374206e6f7420616c726561647920626520696e697469616c697a656400604482015290519081900360640190fd5b6004805460ff60a01b1916740100000000000000000000000000000000000000001790556001600160a01b0383811690821614156200017d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401808060200182810382526039815260200180620033406039913960400191505060405180910390fd5b806001600160a01b0316826001600160a01b03161415620001ea576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252602e81526020018062003379602e913960400191505060405180910390fd5b6001600160a01b0383166200024b576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401808060200182810382526026815260200180620032f86026913960400191505060405180910390fd5b6001600160a01b038216620002ac576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260228152602001806200331e6022913960400191505060405180910390fd5b600480546001600160a01b0319166001600160a01b03838116919091179091557401000000000000000000000000000000000000000060008181559185169081018252600160209081526040928390208590558251918252810184905281517fb39b5f240c7440b58c1c6cfd328b09ff9aa18b3c8ef4b829774e4f5bad039416929181900390910190a1505050565b612fad806200034b6000396000f3fe6080604052600436106101d85760003560e01c80637ecebe0011610102578063bc197c8111610095578063ef009e4211610064578063ef009e4214610c68578063f0b9e5ba14610cea578063f23a6e6114610d7a578063ffa1ad7414610e1a576101d8565b8063bc197c8114610a20578063bf4fb0c014610b54578063c0ee0b8a14610b8d578063ce2d4f9614610c53576101d8565b80639105d9c4116100d15780639105d9c4146108b657806391aeeedc146108cb578063a0a2daf014610971578063a3c89c4f146109a5576101d8565b80637ecebe00146107e857806388fb06e71461081b5780638bf788741461085e5780638fd45d1a14610873576101d8565b8063210d66f81161017a57806357e61e291161014957806357e61e29146106d8578063710eb26c14610769578063727b7acf1461079a57806375857eba146107d3576101d8565b8063210d66f8146105865780632698c20c146105c257806343fc00b81461066257806349efe5ae146106a5576101d8565b8063157ca6e4116101b6578063157ca6e4146103fe578063158ef93e146104bd5780631626ba7e146104d25780631cd61bad14610554576101d8565b806301ffc9a7146102b357806308405166146102fb578063150b7a021461032d575b3415610219576040805133815234602082015281517f88a5966d370b9919b20f3e2c13ff65706f196a4e32cc2c12bf57088f88525874929181900390910190a15b36156102b157600080356001600160e01b0319168152600360205260409020546001600160a01b03166001811161028d576040805162461bcd60e51b815260206004820152601360248201527224b73b30b634b2103a3930b739b0b1ba34b7b760691b604482015290519081900360640190fd5b3660008037600080366000845afa3d6000803e8080156102ac573d6000f35b3d6000fd5b005b3480156102bf57600080fd5b506102e7600480360360208110156102d657600080fd5b50356001600160e01b031916610ea4565b604080519115158252519081900360200190f35b34801561030757600080fd5b50610310610f7a565b604080516001600160e01b03199092168252519081900360200190f35b34801561033957600080fd5b506103106004803603608081101561035057600080fd5b6001600160a01b03823581169260208101359091169160408201359190810190608081016060820135600160201b81111561038a57600080fd5b82018360208201111561039c57600080fd5b803590602001918460018302840111600160201b831117156103bd57600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250929550610f85945050505050565b34801561040a57600080fd5b506102b16004803603606081101561042157600080fd5b810190602081018135600160201b81111561043b57600080fd5b82018360208201111561044d57600080fd5b803590602001918460018302840111600160201b8311171561046e57600080fd5b91908080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525092955050823593505050602001356001600160a01b0316610f95565b3480156104c957600080fd5b506102e76111ed565b3480156104de57600080fd5b50610310600480360360408110156104f557600080fd5b81359190810190604081016020820135600160201b81111561051657600080fd5b82018360208201111561052857600080fd5b803590602001918460018302840111600160201b8311171561054957600080fd5b5090925090506111fd565b34801561056057600080fd5b5061056961156a565b604080516001600160f81b03199092168252519081900360200190f35b34801561059257600080fd5b506105b0600480360360208110156105a957600080fd5b503561156f565b60408051918252519081900360200190f35b3480156105ce57600080fd5b506102b160048036036101208110156105e657600080fd5b6040820190608083019060c0840135906001600160a01b0360e086013516908501856101208101610100820135600160201b81111561062457600080fd5b82018360208201111561063657600080fd5b803590602001918460018302840111600160201b8311171561065757600080fd5b509092509050611581565b34801561066e57600080fd5b506102b16004803603606081101561068557600080fd5b506001600160a01b03813581169160208101359160409091013516611a30565b3480156106b157600080fd5b506102b1600480360360208110156106c857600080fd5b50356001600160a01b0316611c46565b3480156106e457600080fd5b506102b1600480360360808110156106fb57600080fd5b60ff8235169160208101359160408201359190810190608081016060820135600160201b81111561072b57600080fd5b82018360208201111561073d57600080fd5b803590602001918460018302840111600160201b8311171561075e57600080fd5b509092509050611d58565b34801561077557600080fd5b5061077e611fd5565b604080516001600160a01b039092168252519081900360200190f35b3480156107a657600080fd5b506102b1600480360360408110156107bd57600080fd5b506001600160a01b038135169060200135611fe4565b3480156107df57600080fd5b506105b0612199565b3480156107f457600080fd5b506105b06004803603602081101561080b57600080fd5b50356001600160a01b03166121a1565b34801561082757600080fd5b506102b16004803603604081101561083e57600080fd5b5080356001600160e01b03191690602001356001600160a01b03166121b3565b34801561086a57600080fd5b506105b0612279565b34801561087f57600080fd5b506102b16004803603606081101561089657600080fd5b506001600160a01b0381358116916020810135916040909101351661227f565b3480156108c257600080fd5b5061077e61249e565b3480156108d757600080fd5b506102b1600480360360c08110156108ee57600080fd5b60ff823516916020810135916040820135916060810135916001600160a01b03608083013516919081019060c0810160a0820135600160201b81111561093357600080fd5b82018360208201111561094557600080fd5b803590602001918460018302840111600160201b8311171561096657600080fd5b5090925090506124a3565b34801561097d57600080fd5b5061077e6004803603602081101561099457600080fd5b50356001600160e01b0319166127e6565b3480156109b157600080fd5b506102b1600480360360208110156109c857600080fd5b810190602081018135600160201b8111156109e257600080fd5b8201836020820111156109f457600080fd5b803590602001918460018302840111600160201b83111715610a1557600080fd5b509092509050612801565b348015610a2c57600080fd5b50610310600480360360a0811015610a4357600080fd5b6001600160a01b038235811692602081013590911691810190606081016040820135600160201b811115610a7657600080fd5b820183602082011115610a8857600080fd5b803590602001918460208302840111600160201b83111715610aa957600080fd5b919390929091602081019035600160201b811115610ac657600080fd5b820183602082011115610ad857600080fd5b803590602001918460208302840111600160201b83111715610af957600080fd5b919390929091602081019035600160201b811115610b1657600080fd5b820183602082011115610b2857600080fd5b803590602001918460018302840111600160201b83111715610b4957600080fd5b5090925090506128b1565b348015610b6057600080fd5b506102b160048036036040811015610b7757600080fd5b506001600160a01b0381351690602001356128c5565b348015610b9957600080fd5b506102b160048036036060811015610bb057600080fd5b6001600160a01b0382351691602081013591810190606081016040820135600160201b811115610bdf57600080fd5b820183602082011115610bf157600080fd5b803590602001918460018302840111600160201b83111715610c1257600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250929550612a68945050505050565b348015610c5f57600080fd5b50610569612a6d565b348015610c7457600080fd5b506102b160048036036040811015610c8b57600080fd5b81359190810190604081016020820135600160201b811115610cac57600080fd5b820183602082011115610cbe57600080fd5b803590602001918460208302840111600160201b83111715610cdf57600080fd5b509092509050612a75565b348015610cf657600080fd5b5061031060048036036060811015610d0d57600080fd5b6001600160a01b0382351691602081013591810190606081016040820135600160201b811115610d3c57600080fd5b820183602082011115610d4e57600080fd5b803590602001918460018302840111600160201b83111715610d6f57600080fd5b509092509050612b72565b348015610d8657600080fd5b50610310600480360360a0811015610d9d57600080fd5b6001600160a01b03823581169260208101359091169160408201359160608101359181019060a081016080820135600160201b811115610ddc57600080fd5b820183602082011115610dee57600080fd5b803590602001918460018302840111600160201b83111715610e0f57600080fd5b509092509050612b82565b348015610e2657600080fd5b50610e2f612b94565b6040805160208082528351818301528351919283929083019185019080838360005b83811015610e69578181015183820152602001610e51565b50505050905090810190601f168015610e965780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b60006001600160e01b031982166301ffc9a760e01b1480610ed557506001600160e01b03198216630a85bd0160e11b145b80610ef057506001600160e01b0319821663785cf2dd60e11b145b80610f0b57506001600160e01b0319821663607705c560e11b145b80610f2657506001600160e01b03198216630271189760e51b145b80610f4157506001600160e01b03198216630b135d3f60e11b145b15610f4e57506001610f75565b506001600160e01b031981166000908152600360205260409020546001600160a01b031615155b919050565b63607705c560e11b81565b630a85bd0160e11b949350505050565b600454600160a01b900460ff1615610ff4576040805162461bcd60e51b815260206004820152601f60248201527f6d757374206e6f7420616c726561647920626520696e697469616c697a656400604482015290519081900360640190fd5b6004805460ff60a01b1916600160a01b179055606061101284612bb5565b905060005b81518110156111e657600082828151811061102e57fe5b60200260200101519050836001600160a01b0316816001600160a01b031614156110895760405162461bcd60e51b8152600401808060200182810382526039815260200180612ef06039913960400191505060405180910390fd5b836001600160a01b0316856001600160a01b031614156110da5760405162461bcd60e51b815260040180806020018281038252602e815260200180612f29602e913960400191505060405180910390fd5b6001600160a01b03811661111f5760405162461bcd60e51b8152600401808060200182810382526026815260200180612ea86026913960400191505060405180910390fd5b6001600160a01b0385166111645760405162461bcd60e51b8152600401808060200182810382526022815260200180612ece6022913960400191505060405180910390fd5b600480546001600160a01b0319166001600160a01b0386811691909117909155600160a01b60008181559183169081018252600160209081526040928390208890558251918252810187905281517fb39b5f240c7440b58c1c6cfd328b09ff9aa18b3c8ef4b829774e4f5bad039416929181900390910190a150600101611017565b5050505050565b600454600160a01b900460ff1681565b60408051601960f81b6020808301919091526000602183018190523060601b602284015260368084018890528451808503909101815260569093019093528151910120611248612e1d565b611250612e1d565b611258612e1d565b6000806041881415611329576112ae60008a8a8080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250929392505063ffffffff612c49169050565b60ff908116865290865281875284518651604080516000815260208181018084528d9052939094168482015260608401949094526080830152915160019260a0808401939192601f1981019281900390910190855afa158015611315573d6000803e3d6000fd5b5050506020604051035191508190506114cd565b60828814156114bd5761137c60008a8a8080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250929392505063ffffffff612c49169050565b60ff16855285528552604080516020601f8b018190048102820181019092528981526113cf91604191908c908c9081908401838280828437600092019190915250929392505063ffffffff612c49169050565b60ff908116602087810191909152878101929092528188019290925284518751875160408051600081528086018083528d9052939095168386015260608301919091526080820152915160019260a08082019392601f1981019281900390910190855afa158015611444573d6000803e3d6000fd5b505060408051601f19808201516020808901518b8201518b830151600087528387018089528f905260ff909216868801526060860152608085015293519096506001945060a08084019493928201928290030190855afa1580156114ac573d6000803e3d6000fd5b5050506020604051035190506114cd565b5060009550611563945050505050565b6001600160a01b0382166114eb575060009550611563945050505050565b6001600160a01b038116611509575060009550611563945050505050565b806001600160a01b031660016000846001600160a01b0316600054018152602001908152602001600020546001600160a01b031614611552575060009550611563945050505050565b50630b135d3f60e11b955050505050505b9392505050565b600081565b60016020526000908152604090205481565b601b60ff88351614806115985750601c60ff883516145b6115e9576040805162461bcd60e51b815260206004820152601e60248201527f696e76616c6964207369676e61747572652076657273696f6e20765b305d0000604482015290519081900360640190fd5b601b60ff60208901351614806116065750601c60ff602089013516145b611657576040805162461bcd60e51b815260206004820152601e60248201527f696e76616c6964207369676e61747572652076657273696f6e20765b315d0000604482015290519081900360640190fd5b604051601960f81b6020820181815260006021840181905230606081811b6022870152603686018a905288901b6bffffffffffffffffffffffff1916605686015290938492899189918991899190606a018383808284378083019250505097505050505050505060405160208183030381529060405280519060200120905060006001828a6000600281106116e857fe5b602002013560ff168a6000600281106116fd57fe5b604080516000815260208181018084529690965260ff90941684820152908402919091013560608301528a3560808301525160a08083019392601f198301929081900390910190855afa158015611758573d6000803e3d6000fd5b505060408051601f1980820151600080845260208085018087528990528f81013560ff16858701528e81013560608601528d81013560808601529451919650945060019360a0808501949193830192918290030190855afa1580156117c1573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b038216611829576040805162461bcd60e51b815260206004820152601d60248201527f496e76616c6964207369676e617475726520666f72207369676e65722e000000604482015290519081900360640190fd5b6001600160a01b038116611884576040805162461bcd60e51b815260206004820152601f60248201527f496e76616c6964207369676e617475726520666f7220636f7369676e65722e00604482015290519081900360640190fd5b856001600160a01b0316826001600160a01b0316146118d45760405162461bcd60e51b8152600401808060200182810382526022815260200180612f576022913960400191505060405180910390fd5b6001600160a01b0382166000908152600260205260409020548711611940576040805162461bcd60e51b815260206004820152601f60248201527f6d757374207573652076616c6964206e6f6e636520666f72207369676e657200604482015290519081900360640190fd5b600080546001600160a01b0380851691820183526001602052604090922054918216148061197f5750816001600160a01b0316816001600160a01b0316145b6119c9576040805162461bcd60e51b815260206004820152601660248201527524b73b30b634b21030baba3437b934bd30ba34b7b71760511b604482015290519081900360640190fd5b6001600160a01b0383166000908152600260209081526040918290208a90558151601f8801829004820281018201909252868252611a239186918990899081908401838280828437600092019190915250612c6592505050565b5050505050505050505050565b600454600160a01b900460ff1615611a8f576040805162461bcd60e51b815260206004820152601f60248201527f6d757374206e6f7420616c726561647920626520696e697469616c697a656400604482015290519081900360640190fd5b6004805460ff60a01b1916600160a01b1790556001600160a01b038381169082161415611aed5760405162461bcd60e51b8152600401808060200182810382526039815260200180612ef06039913960400191505060405180910390fd5b806001600160a01b0316826001600160a01b03161415611b3e5760405162461bcd60e51b815260040180806020018281038252602e815260200180612f29602e913960400191505060405180910390fd5b6001600160a01b038316611b835760405162461bcd60e51b8152600401808060200182810382526026815260200180612ea86026913960400191505060405180910390fd5b6001600160a01b038216611bc85760405162461bcd60e51b8152600401808060200182810382526022815260200180612ece6022913960400191505060405180910390fd5b600480546001600160a01b0319166001600160a01b0383811691909117909155600160a01b60008181559185169081018252600160209081526040928390208590558251918252810184905281517fb39b5f240c7440b58c1c6cfd328b09ff9aa18b3c8ef4b829774e4f5bad039416929181900390910190a1505050565b333014611c9a576040805162461bcd60e51b815260206004820152601e60248201527f6d7573742062652063616c6c65642066726f6d2060696e766f6b652829600000604482015290519081900360640190fd5b600080546001600160a01b03838116909101825260016020526040909120541615611cf65760405162461bcd60e51b8152600401808060200182810382526039815260200180612e3c6039913960400191505060405180910390fd5b600480546001600160a01b038381166001600160a01b0319831617928390556040805192821680845293909116602083015280517f568ab3dedd6121f0385e007e641e74e1f49d0fa69cab2957b0b07c4c7de5abb69281900390910190a15050565b8460ff16601b1480611d6d57508460ff16601c145b611dbe576040805162461bcd60e51b815260206004820152601a60248201527f496e76616c6964207369676e61747572652076657273696f6e2e000000000000604482015290519081900360640190fd5b336000818152600260209081526040808320549051601960f81b9281018381526021820185905230606081811b60228501526036840185905287901b6056840152929585939287928a918a9190606a0183838082843780830192505050975050505050505050604051602081830303815290604052805190602001209050600060018289898960405160008152602001604052604051808581526020018460ff1660ff1681526020018381526020018281526020019450505050506020604051602081039080840390855afa158015611e9b573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b038116611ef8576040805162461bcd60e51b815260206004820152601260248201527124b73b30b634b21039b4b3b730ba3ab9329760711b604482015290519081900360640190fd5b6000805433018152600160205260409020546001600160a01b038181169083161480611f2c57506001600160a01b03811633145b611f76576040805162461bcd60e51b815260206004820152601660248201527524b73b30b634b21030baba3437b934bd30ba34b7b71760511b604482015290519081900360640190fd5b336000908152600260209081526040918290206001870190558151601f8801829004820281018201909252868252611fca9185918990899081908401838280828437600092019190915250612c6592505050565b505050505050505050565b6004546001600160a01b031681565b6004546001600160a01b03163314612043576040805162461bcd60e51b815260206004820152601f60248201527f73656e646572206d757374206265207265636f76657279206164647265737300604482015290519081900360640190fd5b6001600160a01b0382166120885760405162461bcd60e51b8152600401808060200182810382526026815260200180612ea86026913960400191505060405180910390fd5b6004546001600160a01b03838116911614156120d55760405162461bcd60e51b8152600401808060200182810382526039815260200180612ef06039913960400191505060405180910390fd5b6001600160a01b038116612130576040805162461bcd60e51b815260206004820152601e60248201527f54686520636f7369676e6572206d757374206e6f74206265207a65726f2e0000604482015290519081900360640190fd5b60008054600160a01b81810183556001600160a01b038516918201018252600160209081526040928390208490558251918252810183905281517fa9364fb2836862098c2b593d2d3f46759b4c6d5b054300f96172b0394430008a929181900390910190a15050565b600160a01b81565b60026020526000908152604090205481565b333014612207576040805162461bcd60e51b815260206004820152601e60248201527f6d7573742062652063616c6c65642066726f6d2060696e766f6b652829600000604482015290519081900360640190fd5b6001600160e01b0319821660008181526003602090815260409182902080546001600160a01b0319166001600160a01b03861690811790915582519384529083015280517fd09b01a1a877e1a97b048725e0697d9be07bb94320c536e72b976c81016891fb9281900390910190a15050565b60005481565b6004546001600160a01b031633146122de576040805162461bcd60e51b815260206004820152601f60248201527f73656e646572206d757374206265207265636f76657279206164647265737300604482015290519081900360640190fd5b6001600160a01b0383166123235760405162461bcd60e51b8152600401808060200182810382526026815260200180612ea86026913960400191505060405180910390fd5b806001600160a01b0316836001600160a01b031614156123745760405162461bcd60e51b8152600401808060200182810382526039815260200180612ef06039913960400191505060405180910390fd5b6001600160a01b0382166123cf576040805162461bcd60e51b815260206004820152601e60248201527f54686520636f7369676e6572206d757374206e6f74206265207a65726f2e0000604482015290519081900360640190fd5b60008054600160a01b81810183556001600160a01b0380871690920101825260016020908152604092839020859055600480548584166001600160a01b03198216179182905584519084168082529190931691830191909152825190927f568ab3dedd6121f0385e007e641e74e1f49d0fa69cab2957b0b07c4c7de5abb6928290030190a1604080516001600160a01b03861681526020810185905281517fa9364fb2836862098c2b593d2d3f46759b4c6d5b054300f96172b0394430008a929181900390910190a150505050565b600181565b8660ff16601b14806124b857508660ff16601c145b612509576040805162461bcd60e51b815260206004820152601a60248201527f496e76616c6964207369676e61747572652076657273696f6e2e000000000000604482015290519081900360640190fd5b604051601960f81b6020820181815260006021840181905230606081811b6022870152603686018a905288901b6bffffffffffffffffffffffff1916605686015290938492899189918991899190606a018383808284378083019250505097505050505050505060405160208183030381529060405280519060200120905060006001828a8a8a60405160008152602001604052604051808581526020018460ff1660ff1681526020018381526020018281526020019450505050506020604051602081039080840390855afa1580156125e7573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b038116612644576040805162461bcd60e51b815260206004820152601260248201527124b73b30b634b21039b4b3b730ba3ab9329760711b604482015290519081900360640190fd5b6001600160a01b03811660009081526002602052604090205486116126b0576040805162461bcd60e51b815260206004820152601f60248201527f6d757374207573652076616c6964206e6f6e636520666f72207369676e657200604482015290519081900360640190fd5b846001600160a01b0316816001600160a01b0316146127005760405162461bcd60e51b8152600401808060200182810382526022815260200180612f576022913960400191505060405180910390fd5b600080546001600160a01b0380841691820183526001602052604090922054918216148061273657506001600160a01b03811633145b612780576040805162461bcd60e51b815260206004820152601660248201527524b73b30b634b21030baba3437b934bd30ba34b7b71760511b604482015290519081900360640190fd5b6001600160a01b0382166000908152600260209081526040918290208990558151601f87018290048202810182019092528582526127da9185918890889081908401838280828437600092019190915250612c6592505050565b50505050505050505050565b6003602052600090815260409020546001600160a01b031681565b6000805433908101825260016020526040909120546001600160a01b03161461286a576040805162461bcd60e51b815260206004820152601660248201527524b73b30b634b21030baba3437b934bd30ba34b7b71760511b604482015290519081900360640190fd5b6128ad6000801b83838080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250612c6592505050565b5050565b63bc197c8160e01b98975050505050505050565b333014612919576040805162461bcd60e51b815260206004820152601e60248201527f6d7573742062652063616c6c65642066726f6d2060696e766f6b652829600000604482015290519081900360640190fd5b6001600160a01b03821661295e5760405162461bcd60e51b8152600401808060200182810382526026815260200180612ea86026913960400191505060405180910390fd5b6004546001600160a01b03838116911614156129ab5760405162461bcd60e51b8152600401808060200182810382526039815260200180612ef06039913960400191505060405180910390fd5b6001600160a01b03811615806129cf57506004546001600160a01b03828116911614155b612a0a5760405162461bcd60e51b815260040180806020018281038252602e815260200180612f29602e913960400191505060405180910390fd5b600080546001600160a01b0384169081018252600160209081526040928390208490558251918252810183905281517fb39b5f240c7440b58c1c6cfd328b09ff9aa18b3c8ef4b829774e4f5bad039416929181900390910190a15050565b505050565b601960f81b81565b600083118015612a88575063ffffffff83105b612ad9576040805162461bcd60e51b815260206004820152601760248201527f496e76616c69642076657273696f6e206e756d6265722e000000000000000000604482015290519081900360640190fd5b60005460a084901b908110612b1f5760405162461bcd60e51b8152600401808060200182810382526033815260200180612e756033913960400191505060405180910390fd5b60005b828110156111e65760016000858584818110612b3a57fe5b905060200201356001600160a01b03166001600160a01b03168401815260200190815260200160002060009055806001019050612b22565b63785cf2dd60e11b949350505050565b63f23a6e6160e01b9695505050505050565b604051806040016040528060058152602001640312e312e360dc1b81525081565b60606014825181612bc257fe5b04604051908082528060200260200182016040528015612bec578160200160208202803883390190505b50905060005b8251811015612c4357600080826014019050808501519150818460148581612c1657fe5b0481518110612c2157fe5b6001600160a01b03909216602092830291909101909101525050601401612bf2565b50919050565b0160208101516040820151606090920151909260009190911a90565b60008060606040518060400160405280601481526020017311185d1848199a595b19081d1bdbc81cda1bdc9d60621b815250905060606040518060400160405280600b81526020016a10d85b1b0819985a5b195960aa1b81525090506055855110158290612d515760405162461bcd60e51b81526004018080602001828103825283818151815260200191508051906020019080838360005b83811015612d16578181015183820152602001612cfe565b50505050905090810190601f168015612d435780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b5060208501805160001a865182016001830192505b80831015612dd157603483015160548401810182811115612d8957865160208801fd5b60008083605488016014890151895160601c5af1612dc1578360018114612db7578960020a89179850612dbf565b865160208801fd5b505b6001890198508094505050612d66565b5050604080518881526020810186905280820187905290517f101214446435ebbb29893f3348e3aae5ea070b63037a3df346d09d3396a34aee92509081900360600190a1505050505050565b6040518060400160405280600290602082028038833950919291505056fe446f206e6f742075736520616e20617574686f72697a6564206164647265737320617320746865207265636f7665727920616464726573732e596f752063616e206f6e6c79207265636f766572206761732066726f6d2065787069726564206175746856657273696f6e732e417574686f72697a656420616464726573736573206d757374206e6f74206265207a65726f2e496e697469616c20636f7369676e6572206d757374206e6f74206265207a65726f2e446f206e6f742075736520746865207265636f76657279206164647265737320617320616e20617574686f72697a656420616464726573732e446f206e6f742075736520746865207265636f766572792061646472657373206173206120636f7369676e65722e617574686f72697a656420616464726573736573206d75737420626520657175616ca265627a7a723058202bf5771700693f16c2ca90585279bc0b2313fd2ebde70ff6d3e41bd74a5838a964736f6c634300050a0032417574686f72697a656420616464726573736573206d757374206e6f74206265207a65726f2e496e697469616c20636f7369676e6572206d757374206e6f74206265207a65726f2e446f206e6f742075736520746865207265636f76657279206164647265737320617320616e20617574686f72697a656420616464726573732e446f206e6f742075736520746865207265636f766572792061646472657373206173206120636f7369676e65722e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
}

// File: contracts/WalletFactory/WalletFactory.sol

pragma solidity ^0.5.10;






/// @title WalletFactory
/// @dev A contract for creating wallets. 
contract WalletFactory is FullWalletByteCode, HasNoEther, CloneFactory {

    /// @dev Pointer to a pre-deployed instance of the Wallet contract. This
    ///  deployment contains all the Wallet code.
    address public cloneWalletAddress;

    /// @notice Emitted whenever a wallet is created
    /// @param wallet The address of the wallet created
    /// @param authorizedAddress The initial authorized address of the wallet
    /// @param full `true` if the deployed wallet was a full, self
    ///  contained wallet; `false` if the wallet is a clone wallet
    event WalletCreated(address wallet, address authorizedAddress, bool full);

    constructor(address _cloneWalletAddress) public {
        cloneWalletAddress = _cloneWalletAddress;
    }

    /// @notice Used to deploy a wallet clone
    /// @dev Reasonably cheap to run (~100K gas)
    /// @param _recoveryAddress the initial recovery address for the wallet
    /// @param _authorizedAddress an initial authorized address for the wallet
    /// @param _cosigner the cosigning address for the initial `_authorizedAddress`
    function deployCloneWallet(
        address _recoveryAddress,
        address _authorizedAddress,
        uint256 _cosigner
    )
        public 
    {
        // create the clone
        address payable clone = createClone(cloneWalletAddress);
        // init the clone
        CloneableWallet(clone).init(_authorizedAddress, _cosigner, _recoveryAddress);
        // emit event
        emit WalletCreated(clone, _authorizedAddress, false);
    }

    /// @notice Used to deploy a wallet clone
    /// @dev Reasonably cheap to run (~100K gas)
    /// @dev The clone does not require `onlyOwner` as we avoid front-running
    ///  attacks by hashing the salt combined with the call arguments and using
    ///  that as the salt we provide to `create2`. Given this constraint, a 
    ///  front-runner would need to use the same `_recoveryAddress`, `_authorizedAddress`,
    ///  and `_cosigner` parameters as the original deployer, so the original deployer
    ///  would have control of the wallet even if the transaction was front-run.
    /// @param _recoveryAddress the initial recovery address for the wallet
    /// @param _authorizedAddress an initial authorized address for the wallet
    /// @param _cosigner the cosigning address for the initial `_authorizedAddress`
    /// @param _salt the salt for the `create2` instruction
    function deployCloneWallet2(
        address _recoveryAddress,
        address _authorizedAddress,
        uint256 _cosigner,
        bytes32 _salt
    )
        public
    {
        // calculate our own salt based off of args
        bytes32 salt = keccak256(abi.encodePacked(_salt, _authorizedAddress, _cosigner, _recoveryAddress));
        // create the clone counterfactually
        address payable clone = createClone2(cloneWalletAddress, salt);
        // ensure we get an address
        require(clone != address(0), "wallet must have address");

        // check size
        uint256 size;
        // note this takes an additional 700 gas
        assembly {
            size := extcodesize(clone)
        }

        require(size > 0, "wallet must have code");

        // init the clone
        CloneableWallet(clone).init(_authorizedAddress, _cosigner, _recoveryAddress);
        // emit event
        emit WalletCreated(clone, _authorizedAddress, false);   
    }

    function deployCloneWallet2WithMultiAuthorizedAddress(
            address _recoveryAddress,
            bytes memory _authorizedAddresses,
            uint256 _cosigner,
            bytes32 _salt
        )
            public
        {
            require(_authorizedAddresses.length / 20 > 0 && _authorizedAddresses.length % 20 == 0, "invalid address byte array");
            address[] memory addresses = bytesToAddresses(_authorizedAddresses);

            // calculate our own salt based off of args
            bytes32 salt = keccak256(abi.encodePacked(_salt, addresses[0], _cosigner, _recoveryAddress));
            // create the clone counterfactually
            address payable clone = createClone2(cloneWalletAddress, salt);
            // ensure we get an address
            require(clone != address(0), "wallet must have address");

            // check size
            uint256 size;
            // note this takes an additional 700 gas
            assembly {
                size := extcodesize(clone)
            }

            require(size > 0, "wallet must have code");

            // init the clone
            CloneableWallet(clone).init2(_authorizedAddresses, _cosigner, _recoveryAddress);
            // emit event
            emit WalletCreated(clone, addresses[0], false);
        }

    function bytesToAddresses(bytes memory bys) private pure returns (address[] memory addresses) {
        addresses = new address[](bys.length/20);
        for (uint i=0; i < bys.length; i+=20) {
            address addr;
            uint end = i+20;
            assembly {
              addr := mload(add(bys,end))
            }
            addresses[i/20] = addr;
        }
    }

    /// @notice Used to deploy a full wallet
    /// @dev This is potentially very gas intensive!
    /// @param _recoveryAddress The initial recovery address for the wallet
    /// @param _authorizedAddress An initial authorized address for the wallet
    /// @param _cosigner The cosigning address for the initial `_authorizedAddress`
    function deployFullWallet(
        address _recoveryAddress,
        address _authorizedAddress,
        uint256 _cosigner
    )
        public 
    {
        // Copy the bytecode of the full wallet to memory.
        bytes memory fullWallet = fullWalletBytecode;

        address full;
        assembly {
            // get start of wallet buffer
            let startPtr := add(fullWallet, 0x20)
            // get start of arguments
            let endPtr := sub(add(startPtr, mload(fullWallet)), 0x60)
            // copy constructor parameters to memory
            mstore(endPtr, _authorizedAddress)
            mstore(add(endPtr, 0x20), _cosigner)
            mstore(add(endPtr, 0x40), _recoveryAddress)
            // create the contract
            full := create(0, startPtr, mload(fullWallet))
        }
        
        // check address
        require(full != address(0), "wallet must have address");

        // check size
        uint256 size;
        // note this takes an additional 700 gas, 
        // which is a relatively small amount in this case
        assembly {
            size := extcodesize(full)
        }

        require(size > 0, "wallet must have code");

        emit WalletCreated(full, _authorizedAddress, true);
    }

    /// @notice Used to deploy a full wallet counterfactually
    /// @dev This is potentially very gas intensive!
    /// @dev As the arguments are appended to the end of the bytecode and
    ///  then included in the `create2` call, we are safe from front running
    ///  attacks and do not need to restrict the caller of this function.
    /// @param _recoveryAddress The initial recovery address for the wallet
    /// @param _authorizedAddress An initial authorized address for the wallet
    /// @param _cosigner The cosigning address for the initial `_authorizedAddress`
    /// @param _salt The salt for the `create2` instruction
    function deployFullWallet2(
        address _recoveryAddress,
        address _authorizedAddress,
        uint256 _cosigner,
        bytes32 _salt
    )
        public
    {
        // Note: Be sure to update this whenever the wallet bytecode changes!
        // Simply run `yarn run build` and then copy the `"bytecode"`
        // portion from the `build/contracts/FullWallet.json` file to here,
        // then append 64x3 0's.
        //
        // Note: By not passing in the code as an argument, we save 600,000 gas.
        // An alternative would be to use `extcodecopy`, but again we save
        // gas by not having to call `extcodecopy`.
        bytes memory fullWallet = fullWalletBytecode;

        address full;
        assembly {
            // get start of wallet buffer
            let startPtr := add(fullWallet, 0x20)
            // get start of arguments
            let endPtr := sub(add(startPtr, mload(fullWallet)), 0x60)
            // copy constructor parameters to memory
            mstore(endPtr, _authorizedAddress)
            mstore(add(endPtr, 0x20), _cosigner)
            mstore(add(endPtr, 0x40), _recoveryAddress)
            // create the contract using create2
            full := create2(0, startPtr, mload(fullWallet), _salt)
        }
        
        // check address
        require(full != address(0), "wallet must have address");

        // check size
        uint256 size;
        // note this takes an additional 700 gas, 
        // which is a relatively small amount in this case
        assembly {
            size := extcodesize(full)
        }

        require(size > 0, "wallet must have code");

        emit WalletCreated(full, _authorizedAddress, true);
    }
}