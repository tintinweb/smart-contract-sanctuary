/**
 *Submitted for verification at polygonscan.com on 2021-12-11
*/

// SPDX-License-Identifier: MIT
// File: openzeppelin-solidity/contracts/utils/Context.sol



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

// File: openzeppelin-solidity/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: contracts/Grant.sol


pragma solidity ^0.8.0;


contract Grant is Ownable {
     
    Artefact private artefact;
    uint256 private mintTokenId;
    uint256 private burnTokenId;
    
    mapping(address => uint256) private airdrops;

    uint256 public totalDeposit;
    uint256 public dropOneAmount = 20000000000000000;
    
    function setContract(
        address addr
    ) external {
        artefact = Artefact(addr);
    }
    
    function setDropOneAmount(
        uint256 _amount
    ) external {
        dropOneAmount = _amount;
    }

    function airdropped(
        address addr
    ) public view returns (
        uint256
    ) {
        return airdrops[addr];
    } 
    
    function deposit(
    ) external payable {
        totalDeposit += msg.value;
    }
    
    function setMintTokenId(
        uint256 _mintTokenId
    ) external {
        mintTokenId = _mintTokenId;
    }
    
    function setBurnTokenId(
        uint256 _burnTokenId
    ) external {
        burnTokenId = _burnTokenId;
    }
    
    function mintAndGrant(
    ) external {
        require(
            artefact.balanceOf(_msgSender(), burnTokenId) > 1, 
            "You don't have the Artefact!"
        );
        uint256 amount = randomAmount();
        require(
            address(this).balance > amount, 
            "Out of funds!"
        );
        artefact.burn(_msgSender(), burnTokenId, 1);
        payable(_msgSender()).transfer(amount);
        artefact.mint(_msgSender(), mintTokenId, 1);
        mintTokenId += 1;
    }
    
    function mintBurnable(
        address addr
    ) external onlyOwner{
        require(
            airdropped(addr) == 0, 
            "Already participated!"
        );
        require(
            address(this).balance > dropOneAmount, 
            "Out of funds!"
        );
        artefact.mint(addr, burnTokenId, 1);
        airdrops[addr] += 1;
        payable(_msgSender()).transfer(dropOneAmount);
    }
    
    function withdrawAmount(
        uint256 amount
    ) external onlyOwner {
        payable(_msgSender()).transfer(amount);
    }
    
    function transferArtefactOwnership(
        address addr
    ) external onlyOwner {
        artefact.transferOwnership(addr);
    }
 
    // 90% -> 0.01ETH to 0.1ETH
    // 10% -> 0.1ETH to 1ETH
    function randomAmount(
    ) private view returns (
        uint256
    ) {
        uint256 _random = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), block.difficulty))) % 1000 + 1;
        if (_random < 900){
            _random *= (_random % 100) * 1000000000000000;
        } else {
            _random *= (_random % 100) * 10000000000000000;
        }
        return _random;
    } 
}

contract Artefact {
    function mint(address addr, uint256 tokenId, uint256 amount) external {}
    function burn(address addr, uint256 tokenId, uint256 amount) external {}
    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {}
    function transferOwnership(address newOwner) public virtual {}
}