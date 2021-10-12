/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity ^0.8.0;

abstract contract EtherRock {
    function buyRock (uint rockNumber) virtual public payable;
    function sellRock (uint rockNumber, uint price) virtual public;
    function giftRock (uint rockNumber, address receiver) virtual public;
    function rocks(uint rockNumber) virtual public view returns (address, bool, uint, uint);
}

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

contract RockEx is Ownable {
  EtherRock rocks = EtherRock(0x37504AE0282f5f334ED29b4548646f887977b7cC);
  
  function buy(uint256 id) public payable {
    (uint256 price, uint256 fee, uint256 total) = getPrice(id);
    require(msg.value == total);
    
    // collect fee
    (bool success,) = owner().call{value: fee}("");
    require(success);
    
    // purchase rock
    rocks.buyRock{value: price}(id);
    
    // set rock as not-for-sale
    rocks.sellRock(id, type(uint256).max);
    
    // send rock to purchaser
    rocks.giftRock(id, _msgSender());
  }
  
  function getPrice(uint256 id) public view returns (uint256, uint256, uint256) {
    (,,uint256 price,) = rocks.rocks(id);
    uint256 fee = price * 200 / 10000; // 2% fee
    uint256 total = price + fee;
    return (price, fee, total);
  }
}