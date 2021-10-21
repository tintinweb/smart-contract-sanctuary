contract NumberOne {
 uint public someData = 256;
}

contract NumberTwo {

  NumberOne numberOneContract;

  function initNumberOne(address _address) public {
    numberOneContract = NumberOne(_address);            
  }

  function getSomeData() view public returns (uint256) {
    return numberOneContract.someData();
  }

}