pragma solidity ^0.5.5;

library SigUtils {
    /**
      @dev Recovers address who signed the message 
      @param _hash operation ethereum signed message hash
      @param _signature message `hash` signature  
    */
    function ecrecover2 (
        bytes32 _hash, 
        bytes memory _signature
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := and(mload(add(_signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(
            _hash,
            v,
            r,
            s
        );
    }
}

/*
    Marmo wallet
    It has a signer, and it accepts signed messages ´Intents´ (Meta-Txs)
    all messages are composed by an interpreter and a ´data´ field.
*/
contract Marmo {
    event Relayed(bytes32 indexed _id, address _implementation, bytes _data);
    event Canceled(bytes32 indexed _id);

    // Random Invalid signer address
    // Intents signed with this address are invalid
    address private constant INVALID_ADDRESS = address(0x9431Bab00000000000000000000000039bD955c9);

    // Random slot to store signer
    bytes32 private constant SIGNER_SLOT = keccak256("marmo.wallet.signer");

    // [1 bit (canceled) 95 bits (block) 160 bits (relayer)]
    mapping(bytes32 => bytes32) private intentReceipt;

    function() external payable {}

    // Inits the wallet, any address can Init
    // it must be called using another contract
    function init(address _signer) external payable {
        address signer;
        bytes32 signerSlot = SIGNER_SLOT;
        assembly { signer := sload(signerSlot) }
        require(signer == address(0), "Signer already defined");
        assembly { sstore(signerSlot, _signer) }
    }

    // Signer of the Marmo wallet
    // can perform transactions by signing Intents
    function signer() public view returns (address _signer) {
        bytes32 signerSlot = SIGNER_SLOT;
        assembly { _signer := sload(signerSlot) }
    } 

    // Address that relayed the `_id` intent
    // address(0) if the intent was not relayed
    function relayedBy(bytes32 _id) external view returns (address _relayer) {
        (,,_relayer) = _decodeReceipt(intentReceipt[_id]);
    }

    // Block when the intent was relayed
    // 0 if the intent was not relayed
    function relayedAt(bytes32 _id) external view returns (uint256 _block) {
        (,_block,) = _decodeReceipt(intentReceipt[_id]);
    }

    // True if the intent was canceled
    // An executed intent can't be canceled and
    // a Canceled intent can't be executed
    function isCanceled(bytes32 _id) external view returns (bool _canceled) {
        (_canceled,,) = _decodeReceipt(intentReceipt[_id]);
    }

    // Relay a signed intent
    //
    // The implementation receives data containing the id of the 'intent' and its data,
    // and it will perform all subsequent calls.
    //
    // The same _implementation and _data combination can only be relayed once
    //
    // Returns the result of the 'delegatecall' execution
    function relay(
        address _implementation,
        bytes calldata _data,
        bytes calldata _signature
    ) external payable returns (
        bytes memory result
    ) {
        // Calculate ID from
        // (this, _implementation, data)
        // Any change in _data results in a different ID
        bytes32 id = keccak256(
            abi.encodePacked(
                address(this),
                _implementation,
                keccak256(_data)
            )
        );

        // Read receipt only once
        // if the receipt is 0, the Intent was not canceled or relayed
        if (intentReceipt[id] != bytes32(0)) {
            // Decode the receipt and determine if the Intent was canceled or relayed
            (bool canceled, , address relayer) = _decodeReceipt(intentReceipt[id]);
            require(relayer == address(0), "Intent already relayed");
            require(!canceled, "Intent was canceled");
            revert("Unknown error");
        }

        // Read the signer from storage, avoid multiples 'sload' ops
        address _signer = signer();

        // The signer 'INVALID_ADDRESS' is considered invalid and it will always throw
        // this is meant to disable the wallet safely
        require(_signer != INVALID_ADDRESS, "Signer is not a valid address");

        // Validate is the msg.sender is the signer or if the provided signature is valid
        require(_signer == msg.sender || _signer == SigUtils.ecrecover2(id, _signature), "Invalid signature");

        // Save the receipt before performing any other action
        intentReceipt[id] = _encodeReceipt(false, block.number, msg.sender);

        // Emit the 'relayed' event
        emit Relayed(id, _implementation, _data);

        // Perform 'delegatecall' to _implementation, appending the id of the intent
        // to the beginning of the _data.

        bool success;
        (success, result) = _implementation.delegatecall(abi.encode(id, _data));

        // If the 'delegatecall' failed, reverts the transaction
        // forwarding the revert message
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    // Cancels a not executed Intent '_id'
    // a canceled intent can't be executed
    function cancel(bytes32 _id) external {
        require(msg.sender == address(this), "Only wallet can cancel txs");

        if (intentReceipt[_id] != bytes32(0)) {
            (bool canceled, , address relayer) = _decodeReceipt(intentReceipt[_id]);
            require(relayer == address(0), "Intent already relayed");
            require(!canceled, "Intent was canceled");
            revert("Unknown error");
        }

        emit Canceled(_id);
        intentReceipt[_id] = _encodeReceipt(true, 0, address(0));
    }

    // Encodes an Intent receipt
    // into a single bytes32
    // canceled (1 bit) + block (95 bits) + relayer (160 bits)
    // notice: Does not validate the _block length,
    // a _block overflow would not corrupt the wallet state
    function _encodeReceipt(
        bool _canceled,
        uint256 _block,
        address _relayer
    ) internal pure returns (bytes32 _receipt) {
        assembly {
            _receipt := or(shl(255, _canceled), or(shl(160, _block), _relayer))
        }
    }
    
    // Decodes an Intent receipt
    // reverse of _encodeReceipt(bool,uint256,address)
    function _decodeReceipt(bytes32 _receipt) internal pure returns (
        bool _canceled,
        uint256 _block,
        address _relayer
    ) {
        assembly {
            _canceled := shr(255, _receipt)
            _block := and(shr(160, _receipt), 0x7fffffffffffffffffffffff)
            _relayer := and(_receipt, 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    // Used to receive ERC721 tokens
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(0x150b7a02);
    }
}

// Bytes library to concat and transform
// bytes arrays
library Bytes {
    // Concadenates two bytes array
    // Author: Gonçalo Sá <goncalo.sa@consensys.net>
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_preBytes, _postBytes);
    }

    // Concatenates a bytes array and a bytes1
    function concat(bytes memory _a, bytes1 _b) internal pure returns (bytes memory _out) {
        return concat(_a, abi.encodePacked(_b));
    }

    // Concatenates 6 bytes arrays
    function concat(
        bytes memory _a,
        bytes memory _b,
        bytes memory _c,
        bytes memory _d,
        bytes memory _e,
        bytes memory _f
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _a,
            _b,
            _c,
            _d,
            _e,
            _f
        );
    }

    // Transforms a bytes1 into bytes
    function toBytes(bytes1 _a) internal pure returns (bytes memory) {
        return abi.encodePacked(_a);
    }

    // Transform a uint256 into bytes (last 8 bits)
    function toBytes1(uint256 _a) internal pure returns (bytes1 c) {
        assembly { c := shl(248, _a) }
    }

    // Adds a bytes1 and the last 8 bits of a uint256
    function plus(bytes1 _a, uint256 _b) internal pure returns (bytes1 c) {
        c = toBytes1(_b);
        assembly { c := add(_a, c) }
    }

    // Transforms a bytes into an array
    // it fails if _a has more than 20 bytes
    function toAddress(bytes memory _a) internal pure returns (address payable b) {
        require(_a.length <= 20);
        assembly {
            b := shr(mul(sub(32, mload(_a)), 8), mload(add(_a, 32)))
        }
    }

    // Returns the most significant bit of a given uint256
    function mostSignificantBit(uint256 x) internal pure returns (uint256) {        
        uint8 o = 0;
        uint8 h = 255;
        
        while (h > o) {
            uint8 m = uint8 ((uint16 (o) + uint16 (h)) >> 1);
            uint256 t = x >> m;
            if (t == 0) h = m - 1;
            else if (t > 1) o = m + 1;
            else return m;
        }
        
        return h;
    }

    // Shrinks a given address to the minimal representation in a bytes array
    function shrink(address _a) internal pure returns (bytes memory b) {
        uint256 abits = mostSignificantBit(uint256(_a)) + 1;
        uint256 abytes = abits / 8 + (abits % 8 == 0 ? 0 : 1);

        assembly {
            b := 0x0
            mstore(0x0, abytes)
            mstore(0x20, shl(mul(sub(32, abytes), 8), _a))
        }
    }
}

library MinimalProxy {
    using Bytes for bytes1;
    using Bytes for bytes;

    // Minimal proxy contract
    // by Agusx1211
    bytes constant CODE1 = hex"60"; // + <size>                                   // Copy code to memory
    bytes constant CODE2 = hex"80600b6000396000f3";                               // Return and deploy contract
    bytes constant CODE3 = hex"3660008037600080366000";   // + <pushx> + <source> // Proxy, copy calldata and start delegatecall
    bytes constant CODE4 = hex"5af43d6000803e60003d9160"; // + <return jump>      // Do delegatecall and return jump
    bytes constant CODE5 = hex"57fd5bf3";                                         // Return proxy

    bytes1 constant BASE_SIZE = 0x1d;
    bytes1 constant PUSH_1 = 0x60;
    bytes1 constant BASE_RETURN_JUMP = 0x1b;

    // Returns the Init code to create a
    // Minimal proxy pointing to a given address
    function build(address _address) internal pure returns (bytes memory initCode) {
        return build(Bytes.shrink(_address));
    }

    function build(bytes memory _address) private pure returns (bytes memory initCode) {
        require(_address.length <= 20, "Address too long");
        initCode = Bytes.concat(
            CODE1,
            BASE_SIZE.plus(_address.length).toBytes(),
            CODE2,
            CODE3.concat(PUSH_1.plus(_address.length - 1)).concat(_address),
            CODE4.concat(BASE_RETURN_JUMP.plus(_address.length)),
            CODE5
        );
    }
}

// MarmoStork creates all Marmo wallets
// every address has a designated marmo wallet
// and can send transactions by signing Meta-Tx (Intents)
//
// All wallets are proxies pointing to a single
// source contract, to make deployment costs viable
contract MarmoStork {
    // Random Invalid signer address
    // Intents signed with this address are invalid
    address private constant INVALID_ADDRESS = address(0x9431Bab00000000000000000000000039bD955c9);

    // Prefix of create2 address formula (EIP-1014)
    bytes1 private constant CREATE2_PREFIX = byte(0xff);

    // Bytecode to deploy marmo wallets
    bytes public bytecode;

    // Hash of the bytecode
    // used to calculate create2 result
    bytes32 public hash;

    // Marmo Source contract
    // all proxies point here
    address public marmo;

    // Creates a new MarmoStork (Marmo wallet Factory)
    // with wallets pointing to the _source contract reference
    constructor(address payable _source) public {
        // Generate and save wallet creator bytecode using the provided '_source'
        bytecode = MinimalProxy.build(_source);

        // Precalculate init_code hash
        hash = keccak256(bytecode);
        
        // Destroy the '_source' provided, if is not disabled
        Marmo marmoc = Marmo(_source);
        if (marmoc.signer() == address(0)) {
            marmoc.init(INVALID_ADDRESS);
        }

        // Validate, the signer of _source should be "INVALID_ADDRESS" (disabled)
        require(marmoc.signer() == INVALID_ADDRESS, "Error init Marmo source");

        // Save the _source address, casting to address (160 bits)
        marmo = address(marmoc);
    }
    
    // Calculates the Marmo wallet for a given signer
    // the wallet contract will be deployed in a deterministic manner
    function marmoOf(address _signer) external view returns (address) {
        // CREATE2 address
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        CREATE2_PREFIX,
                        address(this),
                        bytes32(uint256(_signer)),
                        hash
                    )
                )
            )
        );
    }

    // Deploys the Marmo wallet of a given _signer
    // all ETH sent will be forwarded to the wallet
    function reveal(address _signer) external payable {
        // Load init code from storage
        bytes memory proxyCode = bytecode;

        // Create wallet proxy using CREATE2
        // use _signer as salt
        Marmo p;
        assembly {
            p := create2(0, add(proxyCode, 0x20), mload(proxyCode), _signer)
        }

        // Init wallet with provided _signer
        // and forward all Ether
        p.init.value(msg.value)(_signer);
    }
}