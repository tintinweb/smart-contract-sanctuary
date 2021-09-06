/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity ^0.5.17;

// SPDX-License-Identifier: Creative Commons
// @author: Srihari Kapu <[email protected]>
// @author-website: http://www.sriharikapu.com
// SPDX-License-Identifier: CC-BY-4.0

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

/**
 * @title IERC165
 * @dev https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol
/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
    

}

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: contracts/TORUMLOCKER.sol

contract TorumLocker is ReentrancyGuard  {
    IERC721 public NFT;
    ERC20 public LiquidToken;
    address payable public Locker;
    address public creator;
    string public name;
    bool public isLockerActive;
    
   mapping(address => uint) public values;
    
   constructor(address _NFT, address _ERC20, string memory _name) public {
        NFT = IERC721(_NFT);
        LiquidToken = ERC20(_ERC20);
        creator = msg.sender;
        name = _name;
    }
    
   function DepositStake(uint256 _id, uint256 amount) external payable {
        uint _liquidIndex = getLockerIndex(msg.sender);
        require(isLockerActive == true);
        if(_liquidIndex == 0){
            DepositNFT(_id);
            LiquidToken.transfer(Locker, amount);
            setRecord(amount, _id, true);
        } else {
            require(getRecordStatus(_liquidIndex) == false);
            require(values[msg.sender] == 0);
            DepositNFT(_id);
            LiquidToken.transfer(Locker, amount);
            setRecord(amount, _id, true);            
        }
    }
    
   function WithdrawStake() external payable {
        uint _locerIndex = getLockerIndex(msg.sender);
        require(isLockerActive == false);
        require(getRecordStatus(_locerIndex) == true);
        uint256 _PoolAmount = getRecordAmount(_locerIndex);
        LiquidToken.transferFrom(Locker, msg.sender, _PoolAmount);
        resetRecordStatus(_locerIndex);
        updateBalance(0);
   }
    
   function DepositNFTP(uint256 _id) public  {
        // require(NFT.ownerOf(_id) == msg.sender);
        // NFT.approve(Locker, _id);
        NFT.transferFrom(msg.sender, Locker, _id);
    }
    
    function ApproveNFTP(uint256 _id) public  {
        // require(NFT.ownerOf(_id) == msg.sender);
        NFT.approve(Locker, _id);
        // NFT.transferFrom(msg.sender, Locker, _id);
    }
    
    
    
   function DepostLPP(uint256 amount) public payable  {
        // require(LiquidToken.balanceOf(msg.sender) >= amount);
        LiquidToken.approve(Locker, amount);
        LiquidToken.transfer(Locker, amount);
    }
      
    function TransferLP(uint256 amount) public payable  {
        // require(LiquidToken.balanceOf(msg.sender) >= amount);
        // LiquidToken.approve(Locker, amount);
        LiquidToken.transfer(Locker, amount);
    }
    
    function DepositNFT(uint256 _id) public payable  {
        // require(NFT.ownerOf(_id) == msg.sender);
        // NFT.approve(Locker, _id);
        NFT.transferFrom(msg.sender, Locker, _id);
    }
    
    function ApproveNFT(uint256 _id) public payable {
        // require(NFT.ownerOf(_id) == msg.sender);
        NFT.approve(Locker, _id);
        // NFT.transferFrom(msg.sender, Locker, _id);
    }
    
    
    
   function DepostLP(uint256 amount) public  {
        // require(LiquidToken.balanceOf(msg.sender) >= amount);
        LiquidToken.approve(Locker, amount);
        LiquidToken.transfer(Locker, amount);
    }
    
   function updateLocker (address payable _locker) external {
        require(msg.sender == creator);
        Locker = _locker;
    }
    
   function updateBalance(uint newBalance) internal {
      values[msg.sender] = newBalance;
   }
    
   uint256 counter;
   
   mapping(address => uint) public lockerArray;
   
   struct Records { 
      uint256 _Amount;
      uint256 _NFTID;
      uint256 _index;
      bool _status;
   }
   
   Records[] records;

   function setRecord(uint256 _LPAmount,uint256 _NftId, bool status) internal {
      records.push(Records({_Amount : _LPAmount, _NFTID : _NftId, _index : counter, _status : status}));
      lockerArray[msg.sender] = counter;
      counter++;
   }
   
   function getRecordDetails(uint256 _index) public view returns (uint256, uint256, bool) {
      Records storage record = records[_index];
      return (record._Amount, record._NFTID, record._status);
   }
   
   function getRecordNftId(uint256 _index) public view returns (uint256) {
      Records storage record = records[_index];
      return  record._NFTID;
   }
   
   function getRecordAmount(uint256 _index) public view returns (uint256) {
      Records storage record = records[_index];
      return  record._Amount;
   }
   
   function getLockerIndex(address _userAddress) public view returns(uint){
       return lockerArray[_userAddress];
   }
   
   function resetRecordStatus(uint256 _index) public {
        Records storage record = records[_index];
        record._Amount = 0;
        record._NFTID = 0;
        record._status = false;
   }
   
   function getRecordStatus(uint256 _index) public view returns (bool) {
      Records storage record = records[_index];
      return (record._status);
   }

   function changeCreator(address _creator) external {
        require(msg.sender==creator);
        creator = _creator;
    }
    
   function pauseLocker() external {
      require(msg.sender==creator);
      isLockerActive = false;
    }
    
   function unpauseLocker() external {
      require(msg.sender==creator);
      isLockerActive = true;
    }
    
}