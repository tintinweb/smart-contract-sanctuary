pragma solidity 0.4.19;

// File: contracts/SaleInterfaceForAllocations.sol

contract SaleInterfaceForAllocations {

    //function from Sale.sol
    function allocateTokens(address _contributor) external;

}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/TokenAllocator.sol

contract TokenAllocator is Ownable {

    SaleInterfaceForAllocations public sale;

    //constructor
    function TokenAllocator(SaleInterfaceForAllocations _sale) public {
        sale = _sale;
    }

    //allow the sale to be changed for single deployment
    function updateSale(SaleInterfaceForAllocations _sale) external onlyOwner {
        sale = _sale;
    }

    //function to allocate tokens for a set of contributors
    function allocateTokens(address[] _contributors) external {
        for (uint256 i = 0; i < _contributors.length; i++) {
            sale.allocateTokens(_contributors[i]);
        }
    }

}