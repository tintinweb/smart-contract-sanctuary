// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './access/Ownable.sol';
import "./interfaces/IRugZombieNft.sol";

contract NftSwapper is Ownable {
    struct NftSwapInfo {
        bool isEnabled;
        IRugZombieNft outNft;
    }

    address payable treasury;                           // The treasury address
    mapping (address => NftSwapInfo) public swapInfo;   // Mappings for the NFT swaps

    // Constructor for constructing things
    constructor (address _treasury) {
        treasury = payable(_treasury);
    }

    // Function to set the treasury address
    function setTreasury(address _treasury) public onlyOwner() {
        treasury = payable(_treasury);
    }

    // Function to set the swap info
    function setSwapInfo(address _inNft, address _outNft, bool _isEnabled) public onlyOwner() {
        swapInfo[_inNft].outNft = IRugZombieNft(_outNft);
        swapInfo[_inNft].isEnabled = _isEnabled;
    }

    // Function for setting the enabled state of a pairing
    function setIsEnabled(address _inNft, bool _isEnabled) public onlyOwner() {
        swapInfo[_inNft].isEnabled = _isEnabled;
    }

    // Function to perform the swap
    function swapNft(address _inNft, uint _tokenId) public returns (uint) {
        require(_tokenId > 0, 'NftSwapper: Must provide token ID');
        require(swapInfo[_inNft].isEnabled, 'NftSwapper: Swap is not enabled');
        IRugZombieNft inNft = IRugZombieNft(_inNft);
        inNft.transferFrom(msg.sender, treasury, _tokenId);
        require(inNft.ownerOf(_tokenId) == treasury, 'NftSwapper: In NFT transfer failed');
        uint tokenId = swapInfo[_inNft].outNft.reviveRug(msg.sender);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRugZombieNft {
    function totalSupply() external view returns (uint256);
    function reviveRug(address _to) external returns(uint);
    function transferOwnership(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    constructor()  {
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