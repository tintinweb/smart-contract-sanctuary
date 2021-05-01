/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.5;



// Part: ISimulacra

interface ISimulacra {
    function totalSupply() external view returns(uint256);
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: MetadataDirectory.sol

contract MetadataDirectory is Ownable {

    uint8 public constant VERSION = 1;
    string public constant IPFS_PUBLIC_GATEWAY = "https://ipfs.io/ipfs/";
    string public constant IPFS_URI_SCHEME = "ipfs://";
    bytes2 public constant IPFS_CIDv0_PREFIX_Qm = 0x516D;

    ISimulacra public simulacra;
    uint256 public immutable size;
    string public directoryCID;

    constructor(ISimulacra _simulacra, string memory _directoryCID){
        bytes memory cid = bytes(_directoryCID);
        require(cid.length == 46, "Bad CID length");
        require(cid[0] == IPFS_CIDv0_PREFIX_Qm[0] && cid[1] == IPFS_CIDv0_PREFIX_Qm[1],
                "CID doesn't start with Qm");

        simulacra = _simulacra;
        size = _simulacra.totalSupply();
        directoryCID = _directoryCID;
    }

    /*
     IPFS CIDs and URIs
    */

    function ipfsCIDfromTokenID(uint256 _tokenID) public view returns(string memory){
        return string(abi.encodePacked(directoryCID, "/", uint2str(_tokenID), ".json"));
    }

    function ipfsTokenURI(uint256 _tokenID) external view returns(string memory){
        require(_tokenID < size, "No metadata for this _tokenID");
        string memory ipfsCID = ipfsCIDfromTokenID(_tokenID);
        return string(abi.encodePacked(IPFS_URI_SCHEME, ipfsCID));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}