// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/Ikaka721.sol";

contract Proposal is Ownable {
    IKTA public KTA;
    address public banker;
    bool public isOpen;
    uint public lastInsertId;
    bool public flag;

    mapping (address => uint) public userCreateTime;
    mapping(uint => Vote) public voteInfo;
    struct Vote {
        bool isOpen;
        uint startTime;
        uint endTime;
        address auth;
        string topic;
        uint mode;
        string description;
        uint maxOption;
        uint total;
        
        mapping(uint => bool) tIdIsVote;
        mapping(uint => Option) option;
    }
    struct Option {
        string description;
        mapping(uint => uint) cards;
        uint count;
    }

    modifier isActive {
        require(isOpen, "not active");
        _;
    }
    
    constructor() {
        KTA = IKTA(0x3D7bDcF5e0Bb389DE1c4D12Ee6a88B90E14c6486);
        banker = 0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954;
        isOpen = true;

        // voteInfo[lastInsertId].isOpen = true;
        // voteInfo[lastInsertId].topic = "423";
        //  voteInfo[lastInsertId].mode = 0;
        // voteInfo[lastInsertId].description = "dasd";
        // voteInfo[lastInsertId].maxOption = 2; 
        // voteInfo[lastInsertId].startTime = 111;
        // voteInfo[lastInsertId].endTime = 222;
        // voteInfo[lastInsertId].auth = _msgSender();

        // for (uint i = 0; i < 2; i++) {
        //     voteInfo[lastInsertId].option[i].description = "rtere";
        //     voteInfo[lastInsertId].option[i].count = 0;
        // }
        // lastInsertId += 1;
    }

    function setKTA(address com) public onlyOwner {
        KTA = IKTA(com);
    }

    function setOpen(bool b) public onlyOwner {
        isOpen = b;
    }

    function setFlag(bool b) public onlyOwner {
        flag = b;
    }

    function setBanker(address com) external onlyOwner {
        banker = com;
    }

    function GetVoteOpt(uint pId_, uint option_) public view returns(uint, string memory) {
        return (voteInfo[pId_].option[option_].count, voteInfo[pId_].option[option_].description);
    }

    function GetVoteOptCard(uint pId_, uint option_, uint index_) public view returns(uint) {
        return voteInfo[pId_].option[option_].cards[index_];
    }

    function GetVoteOpts(uint pId_) public view returns(uint[] memory, string[] memory)  {
        uint size = voteInfo[pId_].maxOption;
        uint[] memory counts = new uint[](size);
        string[] memory descriptions = new string[](size);
        for (uint i = 0; i < size; i++) {
            counts[i] = voteInfo[pId_].option[i].count;
            descriptions[i] = voteInfo[pId_].option[i].description;
        }   
       return (counts, descriptions);
    }

    function GetVoteOptCards(uint pId_, uint option_) public view returns(uint[] memory) {
        uint size = voteInfo[pId_].option[option_].count;
        uint[] memory res = new uint[](size);
        for (uint i = 0; i < size; i++) {
            res[i] = voteInfo[pId_].option[option_].cards[i];
        }   
        return res;
    }
    
    function cardIsVote(uint pId_, uint[] calldata tIds_) public view returns (bool[] memory) {
        require(voteInfo[pId_].isOpen, "not open");
        bool[] memory res = new bool[](tIds_.length);

        for (uint i = 0; i < tIds_.length; i++) {
            res[i]  = voteInfo[pId_].tIdIsVote[tIds_[i]] ?  false: true;
        }
        return res;
    }

 
    function checkHoldings(address account) public view isActive returns (uint) {
        if (account == owner()) {
            return 0;
        }
        if (!flag) {
            return 1;
        }

        if (userCreateTime[account] > block.timestamp) {
            return 2;
        }

        // uint totalSupply = KTA.totalSupply();
        uint totalSupply = 100;
        uint balanceOf = KTA.balanceOf(account);
        return balanceOf >= totalSupply * 5 / 100 ? 0 : 1;
    }

    function validTickets(uint pId_, uint[][] calldata tIds_) internal view  returns (bool)  {
        // require(voteInfo[pId_].isOpen, "not open");
        for (uint i = 0; i < tIds_.length; i++) {
            for (uint j = 0; j < tIds_[i].length; j++) {
                uint tId = tIds_[i][j];
                require(!voteInfo[pId_].tIdIsVote[tId], "invalid card");
                require(KTA.ownerOf(tIds_[i][j]) == _msgSender(), "wrong card");
            }
        }
        return true;
    }

    function validOptions(uint pId_, uint[] calldata options_)  internal view  returns (bool) {
        // require(voteInfo[pId_].isOpen, "not open");
        for (uint i = 0; i < options_.length; i++) {
            require(options_[i] < voteInfo[pId_].maxOption, "wrong option");
        }
        return true;
    }

    event NewProposal(address indexed sender, uint indexed id, uint indexed startTime, uint endTime);
    function newProposal(string calldata topic_, string memory description_, uint type_, uint startTime_, uint endTime_, string [] memory options_, uint expireAt_, bytes32 r, bytes32 s, uint8 v) public isActive returns (uint) {
        require(!voteInfo[lastInsertId].isOpen, "not open");
        require(checkHoldings(_msgSender()) == 0, "not allowed");

        require(block.timestamp <= expireAt_, "Signature expired");
        bytes32 hash =  keccak256(abi.encodePacked(expireAt_, _msgSender()));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "Invalid signature");

        voteInfo[lastInsertId].isOpen = true;
        voteInfo[lastInsertId].topic = topic_;
        voteInfo[lastInsertId].mode = type_;
        voteInfo[lastInsertId].description = description_;
        voteInfo[lastInsertId].maxOption = options_.length; 
        voteInfo[lastInsertId].startTime = startTime_;
        voteInfo[lastInsertId].endTime = endTime_;
        voteInfo[lastInsertId].auth = _msgSender();

        for (uint i = 0; i < options_.length; i++) {
            voteInfo[lastInsertId].option[i].description = options_[i];
        }
        userCreateTime[_msgSender()] = endTime_;
        
        emit NewProposal(_msgSender(), lastInsertId, startTime_, endTime_);
        lastInsertId += 1;
        return lastInsertId;
    }
    
    function vote(uint pId_, uint[] calldata options_, uint[][] calldata tickets_) public isActive returns (bool) {
        require(voteInfo[pId_].isOpen, "not open");
        require(options_.length == tickets_.length, "unequal length");
        // require(voteInfo[pId_].startTime >= block.timestamp && voteInfo[pId_].endTime <= block.timestamp, "wrong time");
        require(validOptions(pId_, options_));
        require(validTickets(pId_, tickets_));
        
        uint count;
        for (uint i = 0; i < tickets_.length; i++) {
            uint opt = options_[i];
            for (uint j = 0; j < tickets_[i].length; j++) {
                uint tId = tickets_[i][j];
                require(!voteInfo[pId_].tIdIsVote[tId], "duplicate card");
                uint optIdx = voteInfo[pId_].option[opt].count;

                voteInfo[pId_].option[opt].cards[optIdx] = tId;
                voteInfo[pId_].option[opt].count += 1;
                voteInfo[pId_].tIdIsVote[tId] = true;

                count += 1;
            }
        }
        voteInfo[pId_].total += count;
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IKTA{
    function balanceOf(address owner) external view returns(uint256);
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

