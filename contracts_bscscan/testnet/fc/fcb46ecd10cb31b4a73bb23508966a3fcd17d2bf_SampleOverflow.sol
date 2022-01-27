/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SampleOverflow is Ownable{
  string private statictext = "HelloStackOverFlow";
  bytes32 private byteText = "ByteHelloStackOverFlow";
  uint private x;

  function  getString() public view returns (string memory){
    return statictext;
  }

  function  getByte() public view returns (bytes32){
    return byteText;
  }

  function setString(string memory _newStr) public payable returns (bool) {
      statictext = _newStr;
      return true;
  }

  function setBytes32(bytes32 _newbytes32) public returns (bool) {
      byteText = _newbytes32;
      return true;
  }

  function Bytes32ToString() public view returns(string memory){
      return string(abi.encodePacked(byteText));
  }

  function String2Bytes32() public view returns(bytes32){
      return bytes32(abi.encodePacked(statictext));
  }

  function wittdraw() public onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
  }
}