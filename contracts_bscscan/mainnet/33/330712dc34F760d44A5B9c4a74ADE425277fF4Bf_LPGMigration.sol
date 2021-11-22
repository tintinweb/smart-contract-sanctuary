/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract LPGMigration is Ownable{
    bool _isMigrating;
    IBEP20 oldLPG=IBEP20(0xF16e1Ad313E3Bf4E3381b58731b45fA116ECF53f);
    IBEP20 newLPG=IBEP20(0xEf2Dc08C238A062A89e0A1B4C38dC8258fbEb12B);
    uint public Deadline;


    modifier isMigrating{
        require(!_isMigrating,"already Migrating");
        _isMigrating=true;
        _;
        _isMigrating=false;
    }
    function ExtendDeadline(uint secondsUntilDeadline) public onlyOwner{
        uint newDeadline=block.timestamp+secondsUntilDeadline;
        require(newDeadline>Deadline,"Deadline needs to be extended");
        Deadline=newDeadline;
    }
    function Migrate() public isMigrating{
        uint Balance=oldLPG.balanceOf(msg.sender);
        oldLPG.transferFrom(msg.sender, owner(), Balance);
        newLPG.transfer(msg.sender, Balance);
    }
    function RemoveNewLPG() public onlyOwner{
        require(block.timestamp>Deadline,"only possible after deadline");
        newLPG.transfer(msg.sender, newLPG.balanceOf(address(this)));
    }






}