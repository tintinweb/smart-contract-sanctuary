/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.4;
pragma abicoder v2;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC721{
    function ownerOf(uint256 tokenId)external view returns (address);
    function approve(address to, uint256 tokenId)external;
    function safeTransferFrom(address from, address to, uint256 tokenId)external;
}

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

 contract NFTswap is IERC721Receiver,Ownable {
    
    address public operator;
     bool public lockStatus;
    
    constructor (address _operator) {
        operator = _operator;
    }
    
    modifier isLock() {
        require(lockStatus == false, "Witty: Contract Locked");
        _;
    }
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector ^ this.transfer.selector;
    }
    
    function setToApprove(IERC721 _toNFTaddr,address _from,uint256 _toId)internal {
        _toNFTaddr.approve(_from,_toId);
        _toNFTaddr.safeTransferFrom(address(this),_from,_toId);
    }
    
    function transfer(IERC721 _fromAddr,IERC721 _toAddr,address _from,address _to,uint256 _fromid,uint256 _toId) public {
        require(msg.sender == operator,"Not a operator");
        require(_fromAddr.ownerOf(_fromid) == _from && _toAddr.ownerOf(_toId) == _to,"Invalid id and owner");
        fromTransfer(_fromAddr,_from,_to,_fromid);
        toTransfer(_toAddr,_from,_to,_toId);
    }
    function fromTransfer(IERC721 _fromAddr,address _from, address to, uint256 tokenId) internal {
        IERC721(_fromAddr).safeTransferFrom(_from, to, tokenId);
    }
    
    function toTransfer(IERC721 _toAddr,address _from, address to, uint256 tokenId) internal {
        IERC721(_toAddr).safeTransferFrom(to, _from, tokenId);
    }
    
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

}