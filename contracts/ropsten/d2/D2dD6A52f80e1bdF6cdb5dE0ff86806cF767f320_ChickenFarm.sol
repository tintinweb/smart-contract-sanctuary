/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

pragma solidity >=0.5.0 <0.6.0;

contract ChickenFarm {

  function checkStatus() public pure returns (string memory) {
    return 'Farm is working';
  }

  mapping(uint => Chicken) chickens;
  uint public counter = 0;

  struct Chicken {
    uint id;
    string name;
  }

  function addChicken(string memory name) public {
    counter += 1;
    chickens[counter] = Chicken(counter, name);
  }

  function getChicken(uint id) public view returns (uint chickenId, string memory name) {
    return (chickens[id].id, chickens[id].name);
  }
}