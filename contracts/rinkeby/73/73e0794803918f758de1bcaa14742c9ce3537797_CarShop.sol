/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract CarShop is Ownable {
  struct Car {
    uint256 price;
    // available quantity for sale
    uint256 quantity;

    // sold quantity
    uint256 sold;

    // total income
    uint256 soldAmount;
  }

  // Mapping of car address to car entity
  mapping(address => Car) public inventory;

  // all cars address list
  address[] public allCars;

  // available cars address list to purchase
  address[] public availableCars;

  // Mapping of user address to car addresses purchased
  mapping(address => address[]) public balances;

  event NewCarAdded(address indexed _car, uint256 _price, uint256 _quantity);
  event CarAddedForSale(address indexed _car, uint256 _quantity);

  event Sold(address indexed _car, uint256 _quantity);

  // register new car
  function registerNewCar(address _car, uint256 _price, uint256 _quantity) external onlyOwner {
    require(inventory[_car].price == 0, "Already added");
    require(_price > 0, "Invalid price");

    inventory[_car] = Car(_price, _quantity, 0, 0);

    allCars.push(_car);
    emit NewCarAdded(_car, _price, _quantity);

    if (_quantity > 0) {
      availableCars.push(_car);
      emit CarAddedForSale(_car, _quantity);
    }
  }

  // Add more cars into existing car's inventory
  function addNewCar(address _car, uint256 _quantity) external onlyOwner {
    require(inventory[_car].price > 0, "Not registered car");
    require(_quantity > 0, "Invalid quantity");

    Car storage car = inventory[_car];
    uint256 _oldQuantity = car.quantity;

    car.quantity += _quantity;

    // it was not available to purchase, so add it again into available lists
    if (_oldQuantity == 0) {
      availableCars.push(_car);
    }

    emit CarAddedForSale(_car, _quantity);
  }

  // purchase car from the user
  function purchase(address _car, uint256 _quantity) payable external {
    require(inventory[_car].price > 0, "Not registered car");
    Car storage car = inventory[_car];
    require(car.quantity > 0, "Not able to purchase the car");
    // check if requested to purchase more than existing
    uint256 purchaseQuantity = _quantity;
    if (purchaseQuantity > car.quantity) {
      purchaseQuantity = car.quantity;
    }
    // check paid amount
    require(msg.value >= car.price * purchaseQuantity, "Not enough payment");

    car.quantity -= purchaseQuantity;
    car.sold += purchaseQuantity;
    car.soldAmount += car.price * purchaseQuantity;

    address[] storage _balance = balances[_msgSender()];
    uint256 i;
    for (i = 0; i < purchaseQuantity; i++) {
      _balance.push(_car);
    }

    if (car.quantity == 0) {
      // remove from available cars list
      uint256 _indexAtAvailables;
      for (i = 0; i < availableCars.length; i++) {
        if (availableCars[i] == _car) {
          _indexAtAvailables = i;
          break;
        }
      }
      for (i = _indexAtAvailables; i < availableCars.length - 1; i++) {
        availableCars[i] = availableCars[i+1];
      }
      availableCars.pop();
    }

    // if paid more, then refund
    uint256 remaining = msg.value - car.price * purchaseQuantity;
    if (remaining > 0) {
      (bool success, ) = msg.sender.call{value: remaining}("");
      require(success);
    }

    emit Sold(_car, purchaseQuantity);
  }
}