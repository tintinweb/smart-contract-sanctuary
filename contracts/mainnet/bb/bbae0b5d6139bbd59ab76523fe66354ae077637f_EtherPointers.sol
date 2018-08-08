pragma solidity ^0.4.18;

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether there is code in the target address
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address address to check
   * @return whether there is code in the target address
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}
pragma solidity ^0.4.18;


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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
pragma solidity 0.4.21;


contract Restricted is Ownable {
    bool private isActive = true;    
    
    modifier contractIsActive() {
        require(isActive);
        _;
    }

    function pauseContract() public onlyOwner {
        isActive = false;
    }

    function activateContract() public onlyOwner {
        isActive = true;
    }

    function withdrawContract() public onlyOwner {        
        msg.sender.transfer(address(this).balance);
    }
}pragma solidity 0.4.21;



contract EtherPointers is Restricted {
    using AddressUtils for address;
    
    Pointer[15] private pointers;  
    
    uint8 private useIndex = 0;

    uint256 private expirationTime = 1 hours;
    uint256 private defaultPointerValue = 0.002 ether;

    struct Pointer {
        bytes32 url;
        byte[64] text;
        uint256 timeOfPurchase;
        address owner;
    }

    function buyPointer(bytes32 url, byte[64] text) external payable contractIsActive {  
        uint256 requiredPrice = getRequiredPrice();
        uint256 pricePaid = msg.value;
        address sender = msg.sender;

        require(!sender.isContract());
        require(isPointerExpired(useIndex));
        require(requiredPrice <= pricePaid);
        
        Pointer memory pointer = Pointer(url, text, now, msg.sender);
        pointers[useIndex] = pointer;
        setNewUseIndex();   
    }

    function getPointer(uint8 index) external view returns(bytes32, byte[64], uint256) {
        return (pointers[index].url, pointers[index].text, pointers[index].timeOfPurchase);
    }

    function getPointerOwner(uint8 index) external view returns(address) {
        return (pointers[index].owner);
    }

    function getRequiredPrice() public view returns(uint256) {
        uint8 numOfActivePointers = 0;        
        for (uint8 index = 0; index < pointers.length; index++) {
            if (!isPointerExpired(index)) {
                numOfActivePointers++;
            }                       
        }

        return defaultPointerValue + defaultPointerValue * numOfActivePointers;
    }

    function isPointerExpired(uint8 pointerIndex) public view returns(bool) { 
        uint256 expireTime = pointers[pointerIndex].timeOfPurchase + expirationTime;
        uint256 currentTime = now;
        return (expireTime < currentTime);
    }  

    function setNewUseIndex() private {
        useIndex = getNextIndex(useIndex);
    }

    function getNextIndex(uint8 fromIndex) private pure returns(uint8) {
        uint8 oldestIndex = fromIndex + 1;             
        return oldestIndex % 15;
    }    
}