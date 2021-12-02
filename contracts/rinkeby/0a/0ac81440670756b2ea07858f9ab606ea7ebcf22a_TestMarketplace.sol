/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC721interface {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {}
}


pragma solidity >=0.6.0 <0.8.0;
/**
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract TestMarketplace is Ownable {

    using Strings for uint256;
    mapping(bytes => bool) public invalidsign;
    ERC721interface dripclubcontract;


    function updatecontract(address contractaddress) public onlyOwner {
        dripclubcontract = ERC721interface(contractaddress);
    }

    function piksltransfer(address from, address to, uint256 tokenid, uint256 listprice, uint256 expirationtimestamp, bytes memory signature) public payable {
        address signeraddress = verifysignature(from, tokenid, listprice, expirationtimestamp, signature);
        address tokenowner = dripclubcontract.ownerOf(tokenid);
        require(signeraddress == from);
        require(signeraddress == tokenowner);
        require(expirationtimestamp >= block.timestamp);
        //require(inputlistprice <= msg.value);
        require(invalidsign[signature] != true);

        dripclubcontract.safeTransferFrom(from, to, tokenid);
        invalidsign[signature] = true;
    }

    function piksltransfertest(address from, address to, uint256 tokenid) public payable {
        dripclubcontract.safeTransferFrom(from, to, tokenid);
    }

    function updateinvalidsign(bytes memory signature) public returns (bool) {
        invalidsign[signature] = true;
        return invalidsign[signature];
    }

    function verifysignature(address from, uint256 tokenid, uint256 listprice, uint256 expirationtimestamp, bytes memory signature) public pure returns(address) {
        //contr.safeTransferFrom(from, to, tokenId);
        string memory signmsg =  getmsgstring(from,tokenid,listprice,expirationtimestamp);
        bytes32 msghash = keccak256(abi.encodePacked(signmsg));
        bytes32 signedmsghash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", msghash)
            );
        return recoverSigner(signedmsghash, signature);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (r, s, v)
    }

    function getmsgstring(address from, uint256 tokenid, uint256 listprice, uint256 expirationtimestamp) internal pure returns(string memory) {
        //contr.safeTransferFrom(from, to, tokenId);
        return append("tokenid:",tokenid.toString(),",fromaddress:","0x",toAsciiString(from),",listprice:",listprice.toString(),",expirationtimestamp:",expirationtimestamp.toString());
    }

    function append(string memory a, string memory b, string memory c, string memory d, string memory e, string memory f, string memory g, string memory h, string memory i) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e, f, g, h, i));
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

}