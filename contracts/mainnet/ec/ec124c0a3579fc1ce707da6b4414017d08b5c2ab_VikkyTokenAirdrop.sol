pragma solidity ^0.4.18;

contract token {
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public{
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract VikkyTokenAirdrop is Ownable {
  uint public numDrops;
  uint public dropAmount;
  token myToken;

  function VikkyTokenAirdrop(address dropper, address tokenContractAddress) public {
    myToken = token(tokenContractAddress);
    transferOwnership(dropper);
  }

  event TokenDrop( address receiver, uint amount );

  function airDrop( address[] recipients, uint amount) onlyOwner public{
    require( amount > 0);

    for( uint i = 0 ; i < recipients.length ; i++ ) {
        myToken.transfer( recipients[i], amount);
        emit TokenDrop( recipients[i], amount );
    }

    numDrops += recipients.length;
    dropAmount += recipients.length * amount;
  }


  function emergencyDrain( uint amount ) onlyOwner public{
      myToken.transfer( owner, amount );
  }
}