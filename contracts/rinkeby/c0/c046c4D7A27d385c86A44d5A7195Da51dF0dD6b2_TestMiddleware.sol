pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';

contract MintABI {
    function mint(address to, uint256 tokenId) public virtual {}

}

contract Withdrawal {
    function safeTransfer(address operator, address from, address to, uint256 tokenId) public virtual {}
    function ownerOf(uint256 tokenId) public view virtual returns (address){}
    function getApproved(uint256 tokenId) public view virtual returns (address) {}
}

contract TestMiddleware is IERC721Receiver, Ownable{

    event TokenDeposit (address indexed from, uint256 indexed tokenId);
    event TokenWithDraw (address indexed to, uint256 indexed tokenId);

    MintABI private tokenMinter;
    Withdrawal private nftContract;

    mapping(uint256 => bool) private depositedItems;
    string public brand;

    function setMintABI(address _contractAddress) public onlyOwner{
        tokenMinter = MintABI(_contractAddress);
    }

    function getMintABI() public view returns(address) {
        return address(tokenMinter);
    }

    function setNftContract(address _contractAddress) public onlyOwner{
        nftContract = Withdrawal(_contractAddress);
    }

    function getNftContract() public view returns(address) {
        return address(nftContract);
    }


    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override external returns (bytes4){
        require(address(nftContract) == msg.sender,"Item from unknown contract");        
        depositedItems[tokenId] = true;
        emit TokenDeposit(from,tokenId);
        return this.onERC721Received.selector;
    }


    function withdrawItem(address to, uint256 tokenId) public {
        require(msg.sender == address(tokenMinter),"Withdraw: call from unknown address");
        require(nftContract.ownerOf(tokenId) != address(0),"Item does not exist on closed contract");
        require(depositedItems[tokenId] == true,"Withdraw: Item does not deposited in middleware");
        
        nftContract.safeTransfer(address(this),address(this),to,tokenId);
        depositedItems[tokenId] = false;
        emit TokenWithDraw(to,tokenId);
    }


    function safeTransferFrom(address from, uint256 tokenId, string memory _brand) public {
		address nftOwner = nftContract.ownerOf(tokenId);
        address approved = nftContract.getApproved(tokenId);
        require(nftOwner == msg.sender || approved == msg.sender,"Item does not owned/approved");
        nftContract.safeTransfer(msg.sender, from, address(this), tokenId);
        brand = _brand;
        tokenMinter.mint(from,tokenId);        
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}