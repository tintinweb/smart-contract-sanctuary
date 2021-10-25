/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// File: RockHelper.sol

pragma solidity ^0.8.0;

abstract contract EtherRock {
    function buyRock (uint rockNumber) virtual public payable;
    function sellRock (uint rockNumber, uint price) virtual public;
    function giftRock (uint rockNumber, address receiver) virtual public;
    function rocks(uint rockNumber) virtual public view returns (address, bool, uint, uint);
}

abstract contract Wrapper {
    function wrap(uint256 id) virtual public;
    function createWarden() virtual public;
    function wardens(address owner) virtual public view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) public virtual;
}

contract RockHelper {
  EtherRock rocks = EtherRock(0x37504AE0282f5f334ED29b4548646f887977b7cC);
  Wrapper wrapper = Wrapper(0x39b780E8062CE299ab60ed3D48F447e97511a2eD);
  address public warden;
  
  mapping (uint256 => address) public owners;
  
  constructor() {
    wrapper.createWarden(); 
    warden = wrapper.wardens(address(this));
  }
  
  function register(uint256 id) public {
    (address owner,,,) = rocks.rocks(id);
    require(id > 99 && id < 10000);
    require(owner != warden);
    require(owner != address(wrapper));
    owners[id] = owner;
  }
  
  function registerMany(uint256[] memory ids) public {
    for (uint256 i = 0; i < ids.length; i++) {
      register(ids[i]); 
    }
  }
  
  function wrap(uint256 id) public {
    address owner = owners[id];
    require(owner != address(0));
    wrapper.wrap(id);
    wrapper.transferFrom(address(this), owner, id);
  }
  
  function wrapMany(uint256[] memory ids) public {
    for (uint256 i = 0; i < ids.length; i++) {
      wrap(ids[i]); 
    }
  }
}