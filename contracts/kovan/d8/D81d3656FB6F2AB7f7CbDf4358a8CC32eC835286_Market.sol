//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IPets.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Market is Ownable{
    //Battle order types
    uint private ORDER_TYPE_ASK = 1;
    uint private ORDER_TYPE_BID = 2;
    uint private ORDER_TYPE_ASK_RENT = 11;
    uint private ORDER_TYPE_BID_RENT = 12;
    uint private ORDER_TYPE_RENTING = 10;

    uint256 lastOrderId;

    struct Orders{
        uint256 id;
        address user;
        uint256 orderType;
        uint256 pet_id;
        address new_owner;
        uint256 placed_at;
        uint256 ends_at;
        uint256 transfer_ends_at;
        uint256 value;
    }

    Orders[] public orders;

    IPets public pet;

    constructor(address _petAddress) {
        pet = IPets(_petAddress);
    }

    function updatePetAddress(address _petAddress) public onlyOwner{
        pet = IPets(_petAddress);
    }

    function newId() internal returns(uint256) {
        lastOrderId++;
        require(lastOrderId > 0, "_next_id overflow detected");
        //_update_pet_config(pc);
        return lastOrderId;
    }
    function findOrder(uint _id) internal view returns(bool, uint){
        for(uint i =0; i < orders.length; i++){
            if(orders[i].pet_id == _id){
                return(true, i);
            }
        }
        return(false, 0);    
    }

    function orderAsk(uint256 _petId, address _newOwner, uint256 _amount, uint256 _until) public payable{
        IPets.Pet memory pets = pet.getPets(_petId);
        require(pets.id != 0, "Pet not found or invalid pet");

        require(pets.owner != _newOwner, "new owner must be different than current owner");
        require(_amount >= 0, "amount cannot be negative");



        uint placedAt = block.timestamp;

        (bool isOrder, uint ix) = findOrder(_petId);

        uint256 _orderType;
        if (_until > 0) {
            require(_until > placedAt, "End of temporary transfer must be in the future");
            _orderType = ORDER_TYPE_ASK_RENT; // temporary transfer
        } else {
            _orderType = ORDER_TYPE_ASK; // indefinite transfer
        }

        if (isOrder) {
            Orders storage order = orders[ix];

            require(order.orderType != ORDER_TYPE_RENTING, "order can't be updated during temporary transfers");
            order.value = _amount;
            order.new_owner = _newOwner;
            order.orderType = _orderType;
            order.placed_at = placedAt;
            order.transfer_ends_at = _until;
        } else {
            Orders memory order = Orders({
                id:newId(),
                user: pets.owner,
                new_owner: _newOwner,
                pet_id: pets.id,
                orderType: _orderType,
                value: _amount,
                placed_at: placedAt,
                ends_at: 0,
                transfer_ends_at: _until
            });

            orders.push(order);
        }
    } 

    function removeAsk(uint256 _orderID) public {
    
        (bool isOrder, uint index) = getOrder(_orderID);
        require(isOrder, "Order not found or invalid order");
        require(orders[index].user == _msgSender(), "order can only be removed by owner of order");

        require(orders[index].orderType != ORDER_TYPE_RENTING, "orders can't be removed during temporary transfers");

        delete(orders[index]);
    }

    function getOrder(uint _id) internal view returns(bool, uint){
        for(uint i =0; i < orders.length; i++){
            if(orders[i].id == _id){
                return(true, i);
            }
        }
        return(false, 0);
    }

    uint public id;

    function claimPet(address _oldOwner, uint _petId, address _claimer) public {

        IPets.Pet memory pets = pet.getPets(_petId);
        require(pets.id != 0, "Pet not found or invalid pet");
        (bool isFindorder, uint i) = findOrder(_petId);
        require(isFindorder, "Order not found or invalid order");
        
        require(_claimer == orders[i].new_owner || orders[i].new_owner != address(0), "E404|Invalid claimer");

        require(_oldOwner == pets.owner, "Pet already transferred");

        require(orders[i].orderType != ORDER_TYPE_RENTING || orders[i].transfer_ends_at < block.timestamp, "E404|Temporary transfer not yet over");
        require(orders[i].value == 0, "orders requires value transfer");

        // Transfer Pet to claimer 
      
        pet.transferFromPet(_petId, _msgSender(), _claimer);

        // pet.transferPet(_petId, _claimer);

        if (orders[i].transfer_ends_at > 0) {
            if (orders[i].orderType == ORDER_TYPE_ASK_RENT) {
                orders[i].user = _claimer;
                orders[i].new_owner = _oldOwner;
                orders[i].value = 0;
                orders[i].orderType = ORDER_TYPE_RENTING;
            } else if (orders[i].orderType == ORDER_TYPE_RENTING) {
                delete(orders[i]);
            }
        } // else {
            //delete(orders[i]);
        //}
    }

    function bidPet(uint256 _petId, address _bidder, uint256 _amount, uint256 _until) public payable{
        IPets.Pet memory pets = pet.getPets(_petId);
        require(pets.id != 0, "Pet not found or invalid pet"); 

        (bool isFindorder, uint ix) = findOrder(_petId);

        require(pets.owner != _bidder, "bidder must be different than current owner");

        // validate eos
        require(_amount >= 0, "amount cannot be negative");

        uint order_type ;
        if (_until > 0) {
            order_type = ORDER_TYPE_BID_RENT; // temporary transfer
        } else {
            order_type = ORDER_TYPE_BID; // indefinite transfer
        }

        uint placedAt = block.timestamp;
        if (isFindorder) {
            orders[ix].value = _amount;
            orders[ix].placed_at = placedAt;
            orders[ix].transfer_ends_at = _until;
        } else {
            
            Orders memory order = Orders({
                id:newId(),
                user: _bidder,
                new_owner: _bidder,
                pet_id: pets.id,
                orderType: order_type,
                value: _amount,
                placed_at: placedAt,
                ends_at: 0,
                transfer_ends_at: _until
            });

            orders.push(order);
        }
    }

    function removeBid(uint orderId) public {
        (bool isOrder, uint index) = getOrder(orderId);
        require(isOrder, "Order not found or invalid order");

        require(orders[index].user != _msgSender(), "bids can only be removed by owner of bid");

        delete(orders[index]);
    }
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: Unlicense

interface IPets {

    struct Pet{
      uint256 id;
      address owner;
      string name;
      uint256 petType;
      uint256 created_at;
      uint256 death_at;
      uint256 last_fed_at;
      uint256 last_bed_at;
      uint256 last_awake_at;
      uint256 last_play_at;
      uint256 last_shower_at;
    }

    struct PetConfig{
      uint32 battle_idle_tolerance;
      uint8  attack_min_factor;
      uint8  attack_max_factor;
      uint16 battle_max_arenas;
      uint16 battle_busy_arenas;
    }

    function config() external returns(PetConfig memory);

    function getPets(uint id) external returns(Pet memory);

    function transferFromPet(uint petId, address sender, address claimer) external;

    function random(uint num) external returns(uint);

    function isAlive(uint256 last_fed_at) external returns(bool);

    function isSleeping(uint256 last_fed_at, uint last_awake_at) external returns(bool);

    function hasEnergy(uint256 last_awake_at, uint minEnergy) external returns(bool);

    function setApprovalForAll(address recipients, bool approve) external;

    function transferFrom(address sender, address receiver, uint petId) external;
    
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}