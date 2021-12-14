pragma solidity ^0.4.24;

/**
 * @title MultiSig
 * @dev Simple MultiSig using off-chain signing.
 * @author Julien Niset - <[email protected]>
 */
contract MultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 10;

    // Incrementing counter to prevent replay attacks
    uint256 public nonce;   
    // The threshold           
    uint256 public threshold; 
    // The number of owners
    uint256 public ownersCount;
    // Mapping to check if an address is an owner
    mapping (address => bool) public isOwner; 

    // Events
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ThresholdChanged(uint256 indexed newThreshold);
    event Executed(address indexed destination, uint256 indexed value, bytes data);
    event Received(uint256 indexed value, address indexed from);

    /**
     * @dev Throws is the calling account is not the multisig.
     */
    modifier onlyWallet() {
        require(msg.sender == address(this), "MSW: Calling account is not wallet");
        _;
    }

    /**
     * @dev Constructor.
     * @param _threshold The threshold of the multisig.
     * @param _owners The owners of the multisig.
     */
    constructor(uint256 _threshold, address[] _owners) public {
        require(_owners.length > 0 && _owners.length <= MAX_OWNER_COUNT, "MSW: Not enough or too many owners");
        require(_threshold > 0 && _threshold <= _owners.length, "MSW: Invalid threshold");
        ownersCount = _owners.length;
        threshold = _threshold;
        for(uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
            emit OwnerAdded(_owners[i]);
        }
        emit ThresholdChanged(_threshold);
    }

    /**
     * @dev Only entry point of the multisig. The method will execute any transaction provided that it 
     * receieved enough signatures from the wallet owners.  
     * @param _to The destination address for the transaction to execute.
     * @param _value The value parameter for the transaction to execute.
     * @param _data The data parameter for the transaction to execute.
     * @param _signatures Concatenated signatures ordered based on increasing signer's address.
     */
    function execute(address _to, uint _value, bytes _data, bytes _signatures) public {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 count = _signatures.length / 65;
        require(count >= threshold, "MSW: Not enough signatures");
        bytes32 txHash = keccak256(abi.encodePacked(byte(0x19), byte(0), address(this), _to, _value, _data, nonce));
        nonce += 1;
        uint256 valid;
        address lastSigner = 0;
        for(uint256 i = 0; i < count; i++) {
            (v,r,s) = splitSignature(_signatures, i);
            address recovered = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",txHash)), v, r, s);
            require(recovered > lastSigner, "MSW: Badly ordered signatures"); // make sure signers are different
            lastSigner = recovered;
            if(isOwner[recovered]) {
                valid += 1;
                if(valid >= threshold) {
                    require(_to.call.value(_value)(_data), "MSW: External call failed");
                    emit Executed(_to, _value, _data);
                    return;
                }
            }
        }
        // If we reach that point then the transaction is not executed
        revert("MSW: Not enough valid signatures");
    }

    /**
     * @dev Adds an owner to the multisig. This method can only be called by the multisig itself 
     * (i.e. it must go through the execute method and be confirmed by the owners).
     * @param _owner The address of the new owner.
     */
    function addOwner(address _owner) public onlyWallet {
        require(ownersCount < MAX_OWNER_COUNT, "MSW: MAX_OWNER_COUNT reached");
        require(isOwner[_owner] == false, "MSW: Already owner");
        ownersCount += 1;
        isOwner[_owner] = true;
        emit OwnerAdded(_owner);
    }

    /**
     * @dev Removes an owner from the multisig. This method can only be called by the multisig itself 
     * (i.e. it must go through the execute method and be confirmed by the owners).
     * @param _owner The address of the removed owner.
     */
    function removeOwner(address _owner) public onlyWallet {
        require(ownersCount > threshold, "MSW: Too few owners left");
        require(isOwner[_owner] == true, "MSW: Not an owner");
        ownersCount -= 1;
        delete isOwner[_owner];
        emit OwnerRemoved(_owner);
    }

    /**
     * @dev Changes the threshold of the multisig. This method can only be called by the multisig itself 
     * (i.e. it must go through the execute method and be confirmed by the owners).
     * @param _newThreshold The new threshold.
     */
    function changeThreshold(uint256 _newThreshold) public onlyWallet {
        require(_newThreshold > 0 && _newThreshold <= ownersCount, "MSW: Invalid new threshold");
        threshold = _newThreshold;
        emit ThresholdChanged(_newThreshold);
    }

    /**
     * @dev Makes it possible for the multisig to receive ETH.
     */
    function () external payable {
        emit Received(msg.value, msg.sender);        
    }

        /**
     * @dev Parses the signatures and extract (r, s, v) for a signature at a given index.
     * A signature is {bytes32 r}{bytes32 s}{uint8 v} in compact form and signatures are concatenated.
     * @param _signatures concatenated signatures
     * @param _index which signature to read (0, 1, 2, ...)
     */
    function splitSignature(bytes _signatures, uint256 _index) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) tehn apply a mask
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28, "MSW: Invalid v"); 
    }

}