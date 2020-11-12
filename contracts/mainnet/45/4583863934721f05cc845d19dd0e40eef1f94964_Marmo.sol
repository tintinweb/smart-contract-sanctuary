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