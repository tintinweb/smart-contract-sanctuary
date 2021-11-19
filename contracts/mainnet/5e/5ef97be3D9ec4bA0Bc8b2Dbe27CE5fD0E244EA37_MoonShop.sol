// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

pragma solidity 0.8.7;


import "./Ownable.sol";


contract MoonPassContract {
    function ownerOf(uint) external view returns(address){}
    function balanceOf(address) external view returns(uint){}
    function safeTransferFrom(address, address, uint256) public {}
    function totalSupply() external view returns (uint){}
    function isApprovedForAll(address owner, address operator) external view returns (bool) {}
}
contract MoonBoyzContract {
    function ownerOf(uint) external view returns(address){}
    function balanceOf(address) external view returns(uint){}
    function safeTransferFrom(address, address, uint256) public {}
    function totalSupply() external view returns (uint){}
    function isApprovedForAll(address owner, address operator) external view returns (bool) {}
}

contract MoonShop is Ownable {

    struct SpecialTraitsInfos {
    uint256 id;
    string name;
    string category;
    uint256 moonpassNeeded;
    }


    mapping(uint256 => SpecialTraitsInfos) public specialTraitsById;

    mapping(uint256 => uint256) public itemsBought; // TokenId => ItemId

    event itemBought(uint indexed _tokenID, uint indexed _itemBought);


    MoonPassContract private moonPassContract;
    MoonBoyzContract private moonBoyzContract;
    address deadZone = address(0x000000000000000000000000000000000000dEaD);


    constructor(address _moonPassContract, address _moonBoyzContract ) {
        //MOON PASS CONTRACT - 0x9ba658650884fb36f3423d1ce2ee6d2a51361a99
        moonBoyzContract = MoonBoyzContract(_moonBoyzContract);
        moonPassContract = MoonPassContract(_moonPassContract);


        specialTraitsById[1] = SpecialTraitsInfos(1, "Crystals", "Ear", 1);
        specialTraitsById[2] = SpecialTraitsInfos(2, "Elf", "Ear", 1);
        specialTraitsById[3] = SpecialTraitsInfos(3, "Gundoom", "Ear", 1);
        specialTraitsById[4] = SpecialTraitsInfos(4, "Mustard", "Ear", 1);
        specialTraitsById[5] = SpecialTraitsInfos(5, "Punk", "Ear", 1);
        specialTraitsById[6] = SpecialTraitsInfos(6, "Upgrade 3000", "Ear", 1);
        specialTraitsById[7] = SpecialTraitsInfos(7, "Dimension Pockets", "Pocket", 5);
        specialTraitsById[8] = SpecialTraitsInfos(8, "Optical Pockets", "Pocket", 5);
        specialTraitsById[9] = SpecialTraitsInfos(9, "Useful Pockets", "Pocket", 5);
        specialTraitsById[10] = SpecialTraitsInfos(10, "Dimension Pack", "Backpack", 10);
        specialTraitsById[11] = SpecialTraitsInfos(11, "Blackhole", "Background", 2);
        specialTraitsById[12] = SpecialTraitsInfos(12, "Doppler", "Background", 2);
        specialTraitsById[13] = SpecialTraitsInfos(13, "Hexapod", "Background", 2);
        specialTraitsById[14] = SpecialTraitsInfos(14, "Light Speed", "Background", 2);
        specialTraitsById[15] = SpecialTraitsInfos(15, "Mind", "Background", 2);
        specialTraitsById[16] = SpecialTraitsInfos(16, "Prophecy", "Background", 2);
        specialTraitsById[17] = SpecialTraitsInfos(17, "Repere", "Background", 2);
        specialTraitsById[18] = SpecialTraitsInfos(18, "Stars", "Background", 2);
        specialTraitsById[19] = SpecialTraitsInfos(19, "Tabasko", "Background", 2);
        specialTraitsById[20] = SpecialTraitsInfos(20, "The Way", "Background", 2);


    }




  function TraitIdAtIndex(uint index) public view returns(uint256){
    return specialTraitsById[index].id ;
  }

  function MoonpassNeeededAtIndex(uint index) public view returns(uint256){
    return specialTraitsById[index].moonpassNeeded ;
  }

  function TraitNameAtIndex(uint index) public view returns(string memory){
    return specialTraitsById[index].name ;
  }

  function TraitCategoryAtIndex(uint index) public view returns(string memory){
    return specialTraitsById[index].category ;
  }




  function BuyItemWithMoonPass(uint _itemId, uint[] memory _moonPassIds, uint _moonBoyzTokenId) public {

      require(_moonPassIds.length == MoonpassNeeededAtIndex(_itemId), "not enough moonpass");
      require(moonPassContract.balanceOf(msg.sender) >= MoonpassNeeededAtIndex(_itemId), "not enough moonpass");
      require(verifyOwnershipOfAll(_moonPassIds, msg.sender), "Not owner of All _moonPassIds");
      require(moonPassContract.isApprovedForAll(msg.sender, address(this)), "Moonpass is not approved For All");
      require(moonBoyzContract.ownerOf(_moonBoyzTokenId) == msg.sender, "Sender does not own this moonboyz");
      require(TraitIdAtIndex(_itemId) != 0, "This item does not exist");
      require(itemsBought[_moonBoyzTokenId] == 0, "An Item is already purchased For This MoonBoyz");

        for(uint i = 0; i < _moonPassIds.length; i++){
            moonPassContract.safeTransferFrom(msg.sender, deadZone, _moonPassIds[i]);
        }
        itemsBought[_moonBoyzTokenId] = _itemId;
        emit itemBought(_moonBoyzTokenId, _itemId);

  }


    function verifyOwnershipOfAll(uint[] memory _moonPassIds, address _owner) public view returns(bool){
            
        for(uint i = 0; i < _moonPassIds.length; i++){
         
            if(moonPassContract.ownerOf(_moonPassIds[i]) != _owner){
                return false;
            }

        }
        return true;

    }


    function modifyItem(uint _itemId, string memory _name, string memory _category, uint _moonpassNeeded) public onlyOwner{
    specialTraitsById[_itemId] = SpecialTraitsInfos(1, _name, _category, _moonpassNeeded);
    }

 
 
}

