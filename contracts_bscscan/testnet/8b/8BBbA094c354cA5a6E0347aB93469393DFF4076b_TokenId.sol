/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Ownable{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Permissions is Context, Ownable{


    mapping(address => bool) public adminAddress;

    modifier onlyOwnerOrAdminAddress() {
        require(adminAddress[_msgSender()], "permission denied");
        _;
    }

    function updateAdminAddress(address newAddress, bool flag)
        public
        onlyOwner
    {
        require(
            adminAddress[newAddress] != flag,
            "The adminAddress already has that address"
        );
        adminAddress[newAddress] = flag;
    }

    modifier onlyUse() {
        require(use, "contract not use!");
        _;
    }

    bool public use;
}

contract TokenId is Permissions {

    constructor() {
        updateAdminAddress(_msgSender(), true);
    }

    uint256 public nowId = 20000;
  
    function updateNowId() public onlyOwnerOrAdminAddress returns(uint256){
      nowId = nowId + 1;
      return nowId;
    }

    function getNowId() public view returns(uint256){
        return nowId;
    }

}