//SourceUnit: Distribution.sol

pragma solidity ^0.4.25;

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = address(0x4172bee2cf43f658f3edf5f4e08bab03b5f777fa0a);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract EXCH {
    function buyFor(address, address) public payable returns (uint256);
}

contract Distribution is Ownable {

  event onDistribute(
      address indexed customerAddress,
      uint256 price
  );

  EXCH exchange;

  constructor() public {
    exchange = EXCH(address(0x411b2ea6c8331515ff03796bda83217d393ef5f486));
  }

  function() payable public {
  }

  function toTewkenaire() public {
    uint256 balance = address(this).balance;

    if (balance >= 4) {
      exchange.buyFor.value(balance/4)(address(0x41b46d7b70aeB2fC63661d2FF32eC23637AFd629Ec), owner); // Trevon
      exchange.buyFor.value(balance/4)(address(0x415c992820271B1577014c9944C2D6e7132766c2F5), owner); // Craig
      exchange.buyFor.value(balance/4)(address(0x419541eBF4b0A5018F65434f73d7fCa97A12F838EB), owner); // Nomad
      exchange.buyFor.value(balance/4)(address(0x419fc61d95e128ed69f61789a7dc1116506c88b2ff), owner); // Giddy
      emit onDistribute(msg.sender, balance);
    }
  }

}