pragma solidity ^0.4.24;

contract ERC20Basic {
    function balanceOf(address _who) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

/**
 * Identity contract containing funds and accessors (ethereum public keys or contract addresses)
 * It can hold eth and any ERC20 token
 * The goal is to be able to give various permissions to your own keys
 * or to contracts similar to ZincAccessor by providing a fixed interface
 */

contract Identity {

    enum Purposes {
        NONE,             // 0b0000
        READ_ONLY,        // 0b0001
        WRITE_ONLY,       // 0b0010
        ___,
        KEY_MANAGEMENT,   // 0b0100
        _____,
        ______,
        _______,
        FUNDS_MANAGEMENT, // 0b1000
        _________,
        __________,
        ___________,
        ____________,
        _____________,
        ______________,
        ALL_PURPOSES      // 0b1111
    }

    event AccessorAdded(address indexed key, uint8 indexed purpose);
    event AccessorRemoved(address indexed key, uint8 indexed purpose);
    event AccessorUpdated(address indexed key, uint8 indexed oldPurpose, uint8 indexed newPurpose);

    mapping(address => uint8) accessorMap;

    /**
    * Constructs an Identity contract
    * @param _initialAccessors The initial accessors array
    * @param _purposes The initial purposes for each accessor
    * Emits AccessorAdded for each accessor
    */
    constructor(address[] _initialAccessors, uint8[] _purposes) public {
        uint arrayLength = _initialAccessors.length;
        require(arrayLength == _purposes.length, "Arrays must be of the same size");
        for(uint i = 0; i < arrayLength; i++) {
            accessorMap[_initialAccessors[i]] = _purposes[i];
            emit AccessorAdded(_initialAccessors[i], _purposes[i]);
        }
    }

    modifier allowedByPurpose(Purposes _purpose) {
        require(accessorMap[msg.sender] & uint8(_purpose) != 0, "Not authorized");
        _;
    }

    modifier checkPurpose(uint8 _purpose) {
        require(_purpose > uint8(Purposes.NONE) && _purpose <= uint8(Purposes.ALL_PURPOSES), "Invalid purpose");
        _;
    }

    /**
     * Returns the purpose for an accessor, 0 if accessor isn&#39;t registered
     */
    function getAccessorPurpose(address _key) public view returns(uint8) {
        return accessorMap[_key];
    }

    /**
     * Adds an accessor with purpose
     * @param _key Eth public key or contract address
     * @param _purpose Purpose for accessor
     * Requires KEY_MANAGEMENT purpose for msg.sender
     * Emits AccessorUpdated or AccessorAdded
     */
    function addAccessor(address _key, uint8 _purpose) public allowedByPurpose(Purposes.KEY_MANAGEMENT) checkPurpose(_purpose) {
        uint8 oldPurpose = accessorMap[_key];
        accessorMap[_key] = _purpose;
        if (oldPurpose != 0) {
            emit AccessorUpdated(_key, oldPurpose, _purpose);
        } else {
            emit AccessorAdded(_key, _purpose);
        }
    }

    /**
     * Remove an accessor
     * @param _key Eth public key or contract address
     * Requires KEY_MANAGEMENT purpose for msg.sender
     * Emits AccessorRemoved
     */
    function removeAccessor(address _key) public allowedByPurpose(Purposes.KEY_MANAGEMENT) {
        uint8 purpose = accessorMap[_key];
        delete accessorMap[_key];
        emit AccessorRemoved(_key, purpose);
    }

    /**
     * Send all ether to msg.sender
     * Requires FUNDS_MANAGEMENT purpose for msg.sender
     */
    function withdraw() public allowedByPurpose(Purposes.FUNDS_MANAGEMENT) {
        msg.sender.transfer(address(this).balance);
    }

    /**
     * Transfer ether to _account
     * @param _amount amount to transfer in wei
     * @param _account recepient
     * Requires FUNDS_MANAGEMENT purpose for msg.sender
     */
    function transferEth(uint _amount, address _account) allowedByPurpose(Purposes.FUNDS_MANAGEMENT) public {
        require(_amount <= address(this).balance, "Amount should be less than total balance of the contract");
        require(_account != address(0), "must be valid address");
        _account.transfer(_amount);
    }

    /**
     * Returns contract eth balance
     */
    function getBalance() public view returns(uint)  {
        return address(this).balance;
    }

    /**
     * Returns ERC20 token balance for _token
     * @param _token token address
     */
    function getTokenBalance(address _token) public view returns (uint) {
        return ERC20Basic(_token).balanceOf(this);
    }

    /**
     * Send all tokens for _token to msg.sender
     * @param _token ERC20 contract address
     * Requires FUNDS_MANAGEMENT purpose for msg.sender
     */
    function withdrawTokens(address _token) public allowedByPurpose(Purposes.FUNDS_MANAGEMENT) {
        require(_token != address(0));
        ERC20Basic token = ERC20Basic(_token);
        uint balance = token.balanceOf(this);
        // token returns true on successful transfer
        assert(token.transfer(msg.sender, balance));
    }

    /**
     * Send tokens for _token to _to
     * @param _token ERC20 contract address
     * @param _to recepient
     * @param _amount amount in 
     * Requires FUNDS_MANAGEMENT purpose for msg.sender
     */
    function transferTokens(address _token, address _to, uint _amount) public allowedByPurpose(Purposes.FUNDS_MANAGEMENT) {
        require(_token != address(0));
        require(_to != address(0));
        ERC20Basic token = ERC20Basic(_token);
        uint balance = token.balanceOf(this);
        require(_amount <= balance);
        assert(token.transfer(_to, _amount));
    }

    function () public payable {}
}

contract Encoder {

    function uintToChar(uint8 _uint) internal pure returns(string) {
        byte b = "\x30"; // ASCII code for 0
        if (_uint > 9) {
            b = "\x60";  // ASCII code for the char before a
            _uint -= 9;
        }
        bytes memory bs = new bytes(1);
        bs[0] = b | byte(_uint);
        return string(bs);
    }

    /**
     *  Encodes the string representation of a uint8 into bytes
     */
    function encodeUInt(uint8 _uint) public pure returns(bytes memory) {
        uint8 high = uint8(_uint >> 4);
        uint8 low = uint8(_uint) & 15;
        if (high > 0) {
            return abi.encodePacked(uintToChar(high), uintToChar(low));
        } else {
            return abi.encodePacked(uintToChar(low));
        }
    }

    /**
     *  Encodes the string representation of an address into bytes
     */
    function encodeAddress(address _address) public pure returns (bytes memory res) {
        for (uint i = 0; i < 20; i++) {
            // get each byte of the address
            byte b = byte(uint8(uint(_address) / (2**(8*(19 - i)))));

            // split it into two
            uint8 high = uint8(b >> 4);
            uint8 low = uint8(b) & 15;

            // and encode them as chars
            res = abi.encodePacked(res, uintToChar(high), uintToChar(low));
        }
        return res;
    }

    /**
     *  Encodes a string into bytes
     */
    function encodeString(string _str) public pure returns (bytes memory) {
        return abi.encodePacked(_str);
    }
}

contract SignatureValidator {

    function doHash(string _message1, uint32 _message2, string _header1, string _header2)
     pure internal returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                    keccak256(abi.encodePacked(_header1, _header2)),
                    keccak256(abi.encodePacked(_message1, _message2)))
        );
    }

    /**
     * Returns address of signer for a signed message
     * @param _message1 message that was signed
     * @param _nonce nonce that was part of the signed message
     * @param _header1 header for the message (ex: "string Message")
     * @param _header2 header for the nonce (ex: "uint32 nonce")
     * @param _r r from ECDSA
     * @param _s s from ECDSA
     * @param _v recovery id
     */
    function checkSignature(string _message1, uint32 _nonce, string _header1, string _header2, bytes32 _r, bytes32 _s, uint8 _v)
     public pure returns (address) {
        bytes32 hash = doHash(_message1, _nonce, _header1, _header2);
        return ecrecover(hash, _v, _r, _s);
    }

}

/**
 * ZincAccesor contract used for constructing and managing Identity contracts
 * Access control is based on signed messages
 * This contract can be used as a trustless entity that creates an Identity contract and is used to manage it.
 * It operates as a proxy in order to allow users to interact with it based on signed messages and not spend any gas
 * It can be upgraded with the user consent by adding a instance of a new version and removing the old one.
 */

contract ZincAccessor is SignatureValidator, Encoder {

    uint256 public nonce = 0;

    event UserIdentityCreated(address indexed userAddress, address indexed identityContractAddress);
    event AccessorAdded(address indexed identityContractAddress, address indexed keyAddress, uint8 indexed purpose);
    event AccessorRemoved(address indexed identityContractAddress, address indexed keyAddress, uint8 indexed purpose);

    function checkUserSignature(
        address _userAddress,
        string _message1,
        uint32 _nonce,
        string _header1,
        string _header2,
        bytes32 _r,
        bytes32 _s,
        uint8 _v) 
    pure internal returns (bool) {
        require(
            checkSignature(_message1, _nonce, _header1, _header2, _r, _s, _v) == _userAddress,
            "User signature must be the same as signed message");
        return true;
    }

    modifier checknonce(uint _nonce) {
        require(++nonce == _nonce, "Wrong nonce");
        _;
    }

    /**
     * Constructs an Identity contract and returns its address
     * Requires a signed message to verify the identity of the initial user address
     * @param _userAddress user address
     * @param _message1 message that was signed
     * @param _nonce nonce that was part of the signed message
     * @param _header1 header for the message (ex: "string Message")
     * @param _header2 header for the nonce (ex: "uint32 nonce")
     * @param _r r from ECDSA
     * @param _s s from ECDSA
     * @param _v recovery id
     */
    function constructUserIdentity(
        address _userAddress,
        string _message1,
        uint32 _nonce,
        string _header1,
        string _header2,
        bytes32 _r,
        bytes32 _s,
        uint8 _v)
    public
     returns (address)  {
        require(
            checkUserSignature(_userAddress, _message1, _nonce, _header1, _header2, _r, _s, _v),
            "User Signature does not match");

        address[] memory adresses = new address[](2);
        adresses[0] = _userAddress;
        adresses[1] = address(this);

        uint8[] memory permissions = new uint8[](2);
        permissions[0] = uint8(Identity.Purposes.ALL_PURPOSES);
        permissions[1] = uint8(Identity.Purposes.KEY_MANAGEMENT);

        Identity id = new Identity(adresses, permissions);

        emit UserIdentityCreated(_userAddress, address(id));

        return address(id);
    }

    /**
     * Adds an accessor to an Identity contract
     * Requires a signed message to verify the identity of the initial user address
     * Requires _userAddress to have KEY_MANAGEMENT purpose on the Identity contract
     * Emits AccessorAdded
     * @param _key key to add to Identity
     * @param _purpose purpose for _key
     * @param _idContract address if Identity contract
     * @param _userAddress user address
     * @param _message1 message that was signed of the form "Add {_key} to {_idContract} with purpose {_purpose}"
     * @param _nonce nonce that was part of the signed message
     * @param _header1 header for the message (ex: "string Message")
     * @param _header2 header for the nonce (ex: "uint32 nonce")
     * @param _r r from ECDSA
     * @param _s s from ECDSA
     * @param _v recovery id
     */
    function addAccessor(
        address _key,
        address _idContract,
        uint8 _purpose,
        address _userAddress,
        string _message1,
        uint32 _nonce,
        string _header1,
        string _header2,
        bytes32 _r,
        bytes32 _s,
        uint8 _v)
    public checknonce(_nonce) returns (bool) {
        require(checkUserSignature(_userAddress, _message1, _nonce, _header1, _header2, _r, _s, _v));
        require(
            keccak256(abi.encodePacked("Add 0x", encodeAddress(_key), " to 0x", encodeAddress(_idContract), " with purpose ", encodeUInt(_purpose))) == 
            keccak256(encodeString(_message1)), "Message incorrect");

        Identity id = Identity(_idContract);
        require(id.getAccessorPurpose(_userAddress) & uint8(Identity.Purposes.KEY_MANAGEMENT) != 0);

        id.addAccessor(_key, _purpose);
        emit AccessorAdded(_idContract, _key, _purpose);
        return true;
    }

    /**
     * Remove an accessor from Identity contract
     * Requires a signed message to verify the identity of the initial user address
     * Requires _userAddress to have KEY_MANAGEMENT purpose on the Identity contract
     * Emits AccessorRemoved
     * @param _key key to add to Identity
     * @param _idContract address if Identity contract
     * @param _userAddress user address
     * @param _message1 message that was signed of the form "Remove {_key} from {_idContract}"
     * @param _nonce nonce that was part of the signed message
     * @param _header1 header for the message (ex: "string Message")
     * @param _header2 header for the nonce (ex: "uint32 nonce")
     * @param _r r from ECDSA
     * @param _s s from ECDSA
     * @param _v recovery id
     */
    function removeAccessor(
        address _key,
        address _idContract,
        address _userAddress,
        string _message1,
        uint32 _nonce,
        string _header1,
        string _header2,
        bytes32 _r,
        bytes32 _s,
        uint8 _v)
    public checknonce(_nonce) returns (bool) {
        require(checkUserSignature(_userAddress, _message1, _nonce, _header1, _header2, _r, _s, _v));
        require(
            keccak256(abi.encodePacked("Remove 0x", encodeAddress(_key), " from 0x", encodeAddress(_idContract))) ==
            keccak256(encodeString(_message1)), "Message incorrect");

        Identity id = Identity(_idContract);
        require(id.getAccessorPurpose(_userAddress) & uint8(Identity.Purposes.KEY_MANAGEMENT) != 0);

        uint8 acessorPurpose = id.getAccessorPurpose(_key);
        id.removeAccessor(_key);
        emit AccessorRemoved(_idContract, _key, acessorPurpose);
        return true;
    }

}