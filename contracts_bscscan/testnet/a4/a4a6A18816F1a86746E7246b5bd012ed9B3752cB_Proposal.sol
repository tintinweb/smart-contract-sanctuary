// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/Ikaka721.sol";

contract Proposal is Ownable {

    IKTA public KTA;
    bool public isOpen;
    uint public lastInsertId;
    
    mapping(uint => Vote) public voteInfo;
    struct Vote {
        bool isOpen;
        uint startTime;
        uint endTime;
        string topic;
        string description;
        mapping(uint => uint[]) tickets;
        uint options;
        uint[] count;
    }
    
    
    
    modifier isActive {
        require(isOpen, "not active");
        _;
    }
    
    
    constructor() {
        KTA = IKTA(0x3565AC59Aa2127D4C45bd050b673fBe6202cd742);
        isOpen = true;
    }
    
    
    function setKTA(address com) public onlyOwner {
        KTA = IKTA(com);
    }

    function setOpen(bool b) public onlyOwner {
        isOpen = b;
    }
    
    function checkHoldings() public isActive returns (bool) {
        if (_msgSender() == owner()) {
            return true;
        }
        
        uint totalSupply = KTA.totalSupply();
        uint balanceOf = KTA.balanceOf(_msgSender());
        return balanceOf >= totalSupply * 5 / 100 ? true : false;
    }
    
    function checkTickets(uint[][] calldata tickets_) public isActive returns (bool)  {
        uint count;
        for (uint i = 0; i < tickets_.length; i++) {
            for (uint j = 0; j < tickets_[i].length; j++) {
                require(KTA.ownerOf(tickets_[i][j]) == _msgSender(), "error card");
                count += 1;
            }
        }
        uint balanceOf = KTA.balanceOf(_msgSender());
        return count >= balanceOf ? true : false;
    }
    
    event NewProposal(address indexed sender, uint indexed id, uint indexed startTime, uint endTime);
    function newProposal(string calldata topic_, string calldata description_, uint options_, uint startTime_, uint endTime_) public isActive returns (uint) {
        require(!voteInfo[lastInsertId].isOpen, "internal error");
        require(checkHoldings(), "not allowed");
        voteInfo[lastInsertId].isOpen = true;
        voteInfo[lastInsertId].topic = topic_;
        voteInfo[lastInsertId].description = description_;
        voteInfo[lastInsertId].options = options_; 
        voteInfo[lastInsertId].startTime = startTime_;
        voteInfo[lastInsertId].endTime = endTime_;

        emit NewProposal(_msgSender(), lastInsertId, startTime_, endTime_);
        lastInsertId += 1;
        return lastInsertId;
    }
    
    
    function vote(uint id_, uint[] calldata options_, uint[][] calldata tickets_) public isActive returns (bool) {
        require(options_.length == tickets_.length, "unequal length");
        require(voteInfo[id_].isOpen, "not open");
        require(voteInfo[id_].startTime >= block.timestamp && voteInfo[id_].endTime <= block.timestamp, "error time");
        require(checkTickets(tickets_), "wrong votes");
        
        for (uint i = 0; i < tickets_.length; i++) {
            for (uint j = 0; j < tickets_[i].length; i++) {
                voteInfo[id_].tickets[i].push(tickets_[i][j]);
                voteInfo[id_].count[i] += 1;
            }
        }
        return true;
    }


}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IKTA{
    function balanceOf(address owner) external returns(uint256);
    function cardIdMap(uint) external returns(uint); // tokenId => cardId
    function cardInfoes(uint) external returns(uint cardId, string memory name, uint currentAmount, uint maxAmount, string memory _tokenURI);
    function tokenURI(uint256 tokenId_) external view returns(string memory);
    function mint(address player_, uint cardId_) external returns(uint256);
    function mintMulti(address player_, uint cardId_, uint amount_) external returns(uint256);
    function burn(uint tokenId_) external returns (bool);
    function burnMulti(uint[] calldata tokenIds_) external returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function mintWithId(address player_, uint id_, uint tokenId_, bool uriInTokenId_) external returns (bool);
    function totalSupply() external view returns (uint);
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

