/**
 *Submitted for verification at polygonscan.com on 2021-12-15
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


contract Artefact {
    function mint(address addr, uint256 tokenId, uint256 amount) external {}
    function burn(address addr, uint256 tokenId, uint256 amount) external {}
    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {}
    function transferOwnership(address newOwner) public virtual {}
}

contract Grant is Ownable {
    Artefact private artefact;
    uint256 private grantTokenId;
    bool private isGrantTokenFixed;
    uint256 private verificationTokenId;
    
    mapping(address => uint256) private verifiedAddresses;
    mapping(address => uint256) private grants;

    uint256 public totalAddresses;
    uint256 public totalDeposit;    
    uint256 public verificationAmount; // 20000000000000000 = 0.02ETH

    event GrantOne(
        address indexed tokenContract, 
        address indexed to, 
        uint256 id, 
        uint256 amount
    );
    event GrantTwo(
        address indexed tokenContract, 
        address indexed to, 
        uint256 burntId, 
        uint256 id, 
        uint256 amount
    );

    function isVerifiedAddress(
        address addr
    ) public view returns (
        uint256
    ) {
        return verifiedAddresses[addr];
    }

    function grantedAmount(
        address addr
    ) external view returns (
        uint256
    ) {
        return grants[addr];
    }
    
    function deposit(
    ) external payable {
        totalDeposit += msg.value;
    }
    
    function setContract(
        address addr
    ) external {
        artefact = Artefact(addr);
    }
    
    function setVerificationAmount(
        uint256 _amount
    ) external {
        verificationAmount = _amount;
    }
    
    function setVerificationTokenId(
        uint256 tokenId,
        bool isFixed
    ) external {
        verificationTokenId = tokenId;
        isGrantTokenFixed = isFixed;
    }
    
    function setGrantTokenId(
        uint256 tokenId
    ) external {
        grantTokenId = tokenId;
    }

    function mintDelegate(
        address addr,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        artefact.mint(addr, tokenId, amount);
    }
    
    function mintVerify(
        address addr
    ) external onlyOwner {
        require(
            isVerifiedAddress(addr) == 0, 
            "Already participated!"
        );
        require(
            address(this).balance > verificationAmount, 
            "Out of funds!"
        );
        artefact.mint(addr, verificationTokenId, 1);
        verifiedAddresses[addr] += 1;
        totalAddresses += 1;
        payable(_msgSender()).transfer(verificationAmount);

        emit GrantOne(
            address(artefact), 
            addr, 
            verificationTokenId, 
            verificationAmount
        );
    }
    
    function mintAndGrant(
    ) external {
        require(
            artefact.balanceOf(_msgSender(), verificationTokenId) > 1, 
            "You don't have the Artefact!"
        );
        uint256 amount = randomAmount();
        require(
            address(this).balance > amount, 
            "Out of funds!"
        );
        artefact.burn(_msgSender(), verificationTokenId, 1);
        payable(_msgSender()).transfer(amount);
        grants[_msgSender()] += amount;
        artefact.mint(_msgSender(), grantTokenId, 1);
        if (isGrantTokenFixed == false){
            grantTokenId += 1;
        }

        emit GrantTwo(
            address(artefact), 
            _msgSender(), 
            verificationTokenId,
            grantTokenId, 
            amount
        );
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
    
    function randomAmount(
    ) private view returns (
        uint256
    ) {
        uint256 _amount = random() % 1000 + 1;
        if (_amount < 900){
            // 90% -> 0.01ETH to 0.1ETH
            _amount = ((_amount % 100) + 1) * 1000000000000000;
        } else {
            // 10% -> 0.1ETH to 1ETH
            _amount = ((_amount % 100) + 1) * 10000000000000000;
        }
        return _amount;
    } 

    function random(
    ) private view returns (
        uint256
    ) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), block.difficulty)));
    }
}