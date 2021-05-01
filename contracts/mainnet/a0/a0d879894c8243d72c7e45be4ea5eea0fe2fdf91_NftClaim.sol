/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 value, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns(uint256);
}

interface IERC20 {
    function balanceOf(address _who) external returns (uint256);
}

library Math {
    function add(uint a, uint b) internal pure returns (uint c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint a, uint b) internal pure returns (uint c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint a, uint b) internal pure returns (uint c) {require(a == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
}


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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor () internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract NftClaim is Ownable {
    using Math for uint256;

    address public seller;
    IERC1155 public nft;
    uint256[]  public ids;
    mapping(address => bool) public claimants; // key is address, value is boolean where true means they can claim
    
    event Claim(address claimant);

    constructor() public {
        nft = IERC1155(0x13bAb10a88fc5F6c77b87878d71c9F1707D2688A);
        seller = address(0x15884D7a5567725E0306A90262ee120aD8452d58);
        ids = [71];
    }
    
    function addClaimants(address[] memory _claimants) public onlyOwner {
        for (uint i=0; i < _claimants.length; i++) { 
            claimants[_claimants[i]] = true;
        }
    }

    function claim() public {
        require(claimants[msg.sender], "cannot claim");
        
        for (uint i = 0; i < ids.length; i++) {
            nft.safeTransferFrom(address(this), msg.sender, ids[i], 1, new bytes(0x0));
        }
        
        claimants[msg.sender] = false;
        emit Claim(msg.sender);
    }
    
    function supply(uint256 id) public view returns(uint256) {
        return nft.balanceOf(address(this), id);
    }
    
    function pull() public onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            uint256 remainingSupply = supply(ids[i]);
            nft.safeTransferFrom(address(this), seller, ids[i], remainingSupply, new bytes(0x0));
        }
    }
    
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

}