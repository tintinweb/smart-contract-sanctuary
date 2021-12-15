// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract IERC721 {
    function totalSupply() virtual external returns(uint256);
    function currentTokenId() virtual external view returns(uint256);
    function mint(address _to, uint256 _tokenId, string memory _hashs) virtual external;
    function types(uint256 _boxId) virtual external view returns(string memory name, string memory hash, uint256 maxSupply, uint256 remain);
    function burn(uint256 tokenId) external virtual;
    function transferFrom(address from, address to, uint _tokenId) external virtual;
}
contract OpenBox is Ownable {
    address public signer;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    IERC721 public box;
    IERC721 public mx;
    mapping(uint => bool) id;
    event Claim(IERC721[] _nfts, string[] _hashs, address _user);
    constructor(address _signer, IERC721 _box, IERC721 _mx) {
        signer = _signer;
        box = _box;
        mx = _mx;
    }
    function getMessageHash(uint _id, address _user, uint _tokenId, IERC721[] memory _nfts, string[] memory _hashs) public pure returns (bytes32) {
        string memory hash;
        for(uint i = 0 ; i < _hashs.length; i++) {
            hash = string(abi.encodePacked(hash, _hashs[i]));
        }

        return keccak256(abi.encodePacked(_id, _user, _tokenId, _nfts, hash));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function permit(uint _id, address _user, uint _tokenId, IERC721[] memory _nfts, string[] memory _hashs, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        return ecrecover(getEthSignedMessageHash(getMessageHash(_id, _user, _tokenId, _nfts, _hashs)), v, r, s) == signer;
    }
    function currentTokenId() public view returns(uint) {
        return mx.currentTokenId();
    }
    function claim(uint _id, uint _tokenId, IERC721[] memory _nfts, string[] memory _hashs, uint8 v, bytes32 r, bytes32 s) public {
        require(permit(_id, _msgSender(), _tokenId, _nfts, _hashs, v, r, s), "OpenBox: Invalid signature");
        require(!id[_id], "OpenBox: Invalid id");
        box.transferFrom(_msgSender(), burnAddress, _tokenId);
        uint _MXtokenId = mx.currentTokenId();
        for(uint i = 0; i < _nfts.length; i++) {
            _MXtokenId = _MXtokenId + 1;
            _nfts[i].mint(_msgSender(), _MXtokenId, _hashs[i]);
            id[_id] = true;
        }

        emit Claim(_nfts, _hashs, _msgSender());
    }
    function setBox(IERC721 _box) public onlyOwner {
        box = _box;
    }
    function setMX(IERC721 _mx) public onlyOwner {
        mx = _mx;
    }
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}