pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";



interface iFeed {
    function feed (uint256) external ;
    function BattleAttack (uint256) external returns(uint256) ;
     function Attack (uint256, uint256) external returns(uint256) ;
     function _levelUp(uint256) external;
     function _levelDown(uint256) external;
     function ownerOf(uint256) external;
     function AFighter ( address addr, uint256 _tokenId) external returns (uint256);
}

contract dogpound{

    address public addy;
    address private addr;
    address public Owner = msg.sender;
    mapping(address => uint256) public DogeFighter;
    address fighterAddy;
    

    modifier onlyOwner(){
        require(msg.sender == Owner);
        _;
    }
    
    function feed(uint256 _tokenId) external payable {
        iFeed(addy).feed(_tokenId);
    
    
    }

    function withdraw() public payable onlyOwner{
       require (payable(msg.sender).send(address(this).balance));
   }

   function setAddy(address _addy)public onlyOwner returns(address){
           addy = _addy;
           return addy;


   }

   function BattleAttack(uint256 _tokenId) external {
       iFeed(addy).BattleAttack(_tokenId);

   }

   function Attack(uint256 tokenId, uint256 _tokenId) external{
       iFeed(addy).Attack(tokenId , _tokenId);
   }

    function AFighter (uint256 _tokenId) public returns (uint256){
        iFeed(addy).AFighter(msg.sender,_tokenId);
      

   }
   /** 

   function getAFighter(address addy) public view returns(uint256){
       return DogeFighter[addy];
   }

   */

   

   
    
    
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

