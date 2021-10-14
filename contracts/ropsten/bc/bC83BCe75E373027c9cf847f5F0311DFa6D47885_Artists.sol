pragma solidity ^0.4.15;

/*
  https://cryptogs.io
  --Austin Thomas Griffith for ETHDenver
  This contract is used to get Artists' work signaled to be minted to Togs
*/

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract Artists is Ownable {

  uint public priceToMint = 10000000000000000;
  uint public priceToMintStack = 40000000000000000;

  function Artists() public { }

  function setPrice(uint _priceToMint,uint _priceToMintStack) public onlyOwner returns (bool) {
    priceToMint=_priceToMint;
    priceToMintStack=_priceToMintStack;
    return true;
  }

  function mint(bytes32 image) public payable returns (bool) {
    require( msg.value >= priceToMint );
    Mint(msg.sender,image,msg.value,now);
  }
  event Mint(address indexed sender, bytes32 image, uint256 value, uint256 time);

  function mintStack(bytes32 image) public payable returns (bool) {
    require( msg.value >= priceToMintStack );
    MintStack(msg.sender,image,msg.value,now);
  }
  event MintStack(address indexed sender, bytes32 image, uint256 value, uint256 time);

  function withdraw(uint256 _amount) public onlyOwner returns (bool) {
    require(this.balance >= _amount);
    assert(owner.send(_amount));
    return true;
  }

  function withdrawToken(address _token,uint256 _amount) public onlyOwner returns (bool) {
    StandardToken token = StandardToken(_token);
    token.transfer(msg.sender,_amount);
    return true;
  }

}

contract StandardToken {
  function transfer(address _to, uint256 _value) public returns (bool) { }
}

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}