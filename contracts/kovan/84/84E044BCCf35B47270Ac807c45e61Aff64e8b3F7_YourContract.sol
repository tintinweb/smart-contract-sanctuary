pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
//import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract {

  event SetPurpose(address sender, string purpose);

  string public purpose = "hello";

  address payable public owner = payable(0xD75b0609ed51307E13bae0F9394b5f63A7f8b6A1);

  constructor() {
    // what should we do on deploy?
  }

  function setPurpose(string memory newPurpose) public payable {
      require(msg.value >= 0.001 ether, " NOT ENOUGH " );
      purpose = newPurpose;
      //console.log(msg.sender,"set purpose to",purpose);
      emit SetPurpose(msg.sender, purpose);
  }

  function withdraw() public {
    require(msg.sender == owner, " NOT THE OWNER " );
    owner.transfer(address(this).balance);
  }
}

