/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Referral is Ownable{

    constructor(){}
    
    function formReferral(address from, address to) public pure 
        returns (bytes32)
    {
        bytes32 message = keccak256(abi.encodePacked(from, to));
        return message;
    }

    function getSigner(
        bytes32 message, 
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private pure returns (address) {
  
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Referral: invalid signature 's' value");
        require(v == 27 || v == 28, "Referral: invalid signature 'v' value");
        address signer = ecrecover(hashMessage(message), v, r, s);
        require(signer != address(0), "Referral: invalid signature");

        return signer;
    }

    function hashMessage(bytes32 message) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

    function recoverAddress(
        bytes32 message,
        bytes32 signature
    ) external pure returns (address) {
        if (signature.length != 65) {
            revert("Referral: invalid signature length");
        }
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return getSigner(message, v, r, s);
    }
}