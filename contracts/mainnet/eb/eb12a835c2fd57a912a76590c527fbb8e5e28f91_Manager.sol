pragma solidity >=0.4.22 <0.7.0;

/**
 * website: https://govm.net
 * be owner of contract 0xaC5d7dFF150B195C97Fca77001f8AD596eda1761
 * fix the burn bug of WGOVM
*/
contract WGOVM {
    function transferFrom(address _from,address _to,uint256 _value) public  returns (bool) ;
    function mint(address _to, uint256 _amount, bytes32 _trans) public returns (bool);
    function burn(uint256 _value, bytes memory _addr) public;
    function transferOwnership(address newOwner) public;
    function allowance(address _owner, address _spender)public view returns (uint256);
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
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
        
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
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

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}



contract Manager {
    using ECDSA for bytes32;
    address public owner;
    address public app = 0xaC5d7dFF150B195C97Fca77001f8AD596eda1761;
    WGOVM govm = WGOVM(app);
    
    event NeedApprove(address indexed from, address indexed to, uint256 value);

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function relayMint(
        address _to,
        uint256 _amount,
        bytes32 _trans,
        bytes memory approvalData
    ) public returns (bool) {
        bytes memory blob = abi.encodePacked(_to, _amount, _trans);
        address who = keccak256(blob).toEthSignedMessageHash().recover(approvalData);
        require(who == owner);
        return govm.mint(_to, _amount, _trans);
    }
    
    function burn(uint256 _value, bytes memory _addr) public returns (bool) {
        require(_value > 0);
        if (govm.allowance(msg.sender,address(this)) < _value){
            emit NeedApprove(msg.sender,address(this),_value);
            return false;
        }
        govm.transferFrom(msg.sender,address(this),_value);
        govm.burn(_value, _addr);
        return true;
    }
    
    function mint(address _to,uint256 _amount, bytes32 _trans)public onlyOwner returns (bool){
        return govm.mint(_to, _amount, _trans);
    }
 
    function transferAppOwnership() public onlyOwner {
        govm.transferOwnership(owner);
    }
}