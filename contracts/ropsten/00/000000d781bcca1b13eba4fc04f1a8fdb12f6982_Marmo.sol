pragma solidity ^0.5.0;

// File: contracts/commons/SigUtils.sol

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

        return ecrecover(_hash, v, r, s);
    }
}

// File: contracts/commons/Ownable.sol

contract Ownable {
    event SetOwner(address _owner);

    address public owner;

    /**
      @dev Setup function sets initial storage of contract.
      @param _owner List of signer.
    */
    function _init(address _owner) internal {
        require(owner == address(0), "Owner already defined");
        owner = _owner;
        emit SetOwner(_owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return _owner != address(0) && owner == _owner;
    }
}

// File: contracts/Marmo.sol

contract Marmo is Ownable {
    event Relayed(
        bytes32 _id,
        bytes32[] _dependencies,
        address _to,
        uint256 _value,
        bytes _data,
        bytes32 _salt,
        address _relayer,
        bool _success
    );

    event Canceled(
        bytes32 _id
    );

    mapping(bytes32 => address) public relayerOf;
    mapping(bytes32 => bool) public isCanceled;

    function init(address _owner) external {
        _init(_owner);
    }

    function encodeTransactionData(
        bytes32[] memory _dependencies,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _minGasLimit,
        uint256 _maxGasPrice,
        bytes32 _salt
    ) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                this,
                keccak256(abi.encodePacked(_dependencies)),
                _to,
                _value,
                keccak256(_data),
                _minGasLimit,
                _maxGasPrice,
                _salt
            )
        );
    }

    function dependenciesSatisfied(bytes32[] memory _dependencies) internal view returns (bool) {
        for (uint256 i; i < _dependencies.length; i++) {
            if (relayerOf[_dependencies[i]] == address(0)) return false;
        }
        
        return true;
    }

    function relay(
        bytes32[] calldata _dependencies,
        address _to,
        uint256 _value,
        bytes calldata _data,
        uint256 _minGasLimit,
        uint256 _maxGasPrice,
        bytes32 _salt,
        bytes calldata _signature
    ) external returns (
        bool success,
        bytes memory data 
    ) {
        bytes32 id = encodeTransactionData(_dependencies, _to, _value, _data, _minGasLimit, _maxGasPrice, _salt);
        
        require(tx.gasprice <= _maxGasPrice);
        require(!isCanceled[id], "Transaction was canceled");
        require(relayerOf[id] == address(0), "Transaction already relayed");
        require(dependenciesSatisfied(_dependencies), "Parent relay not found");
        require(msg.sender == owner || msg.sender == SigUtils.ecrecover2(id, _signature), "Invalid signature");

        require(gasleft() > _minGasLimit);
        (success, data) = _to.call.value(_value)(_data);

        relayerOf[id] = msg.sender;
        
        emit Relayed(
            id,
            _dependencies,
            _to,
            _value,
            _data,
            _salt,
            msg.sender,
            success
        );
    }

    function cancel(bytes32 _hashTransaction) external {
        require(msg.sender == address(this), "Only wallet can cancel txs");
        require(relayerOf[_hashTransaction] == address(0), "Transaction was already relayed");
        isCanceled[_hashTransaction] = true;
    }
    
    function() external payable {}
}

// File: contracts/commons/Proxy.sol

/**
  @title Proxy - Generic proxy contract.
*/
contract Proxy {
    function () external payable {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)
            
            // Call the implementation.
            // out and outsize are 0 because we don&#39;t know the size yet.
            let result := delegatecall(gas, 0x000000d781bcca1b13eba4fc04f1a8fdb12f6982, 0, calldatasize, 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)
            
            if iszero(result) {
                revert(0, returndatasize)
            }
            
            return (0, returndatasize)
        }
    }
}

// File: contracts/MarmoCreator.sol

contract MarmoFactory {
    // Compiled Proxy.sol
    bytes public constant BYTECODE_1 = hex"6080604052348015600f57600080fd5b50606780601d6000396000f3fe6080604052366000803760008036600073";
    bytes public constant BYTECODE_2 = hex"5af43d6000803e8015156036573d6000fd5b3d6000f3fea165627a7a7230582033b260661546dd9894b994173484da72335f9efc37248d27e6da483f15afc1350029";
    bytes public bytecode;
    bytes32 public hash;
    
    address public marmoSource;

    constructor(address _marmo) public {
        bytecode = _concat(_concat(BYTECODE_1, abi.encodePacked(_marmo)), BYTECODE_2);
        hash = keccak256(bytecode);
        marmoSource = _marmo;
    }
    
    function _concat(bytes memory _baseBytes, bytes memory _valueBytes) internal pure returns (bytes memory _out) {
        uint256 blength = _baseBytes.length;
        uint256 vlength = _valueBytes.length;

        _out = new bytes(blength + vlength);

        uint256 i;
        uint256 j;

        for(i = 0; i < blength; i++) {
            _out[j++] = _baseBytes[i];
        }

        for(i = 0; i < vlength; i++) {
            _out[j++] = _valueBytes[i];
        }
    }
    
    function marmoOf(address _signer) external view returns (address) {
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        bytes32(uint256(_signer)),
                        hash
                    )
                )
            )
        );
    }

    function reveal(address _signer) external returns (Proxy p) {
        bytes memory proxyCode = bytecode;

        assembly {
            let nonce := mload(0x40)
            mstore(nonce, _signer)
            mstore(0x40, add(nonce, 0x20))
            p := create2(0, add(proxyCode, 0x20), mload(proxyCode), _signer)
        }

        Marmo(address(p)).init(_signer);
    }
}