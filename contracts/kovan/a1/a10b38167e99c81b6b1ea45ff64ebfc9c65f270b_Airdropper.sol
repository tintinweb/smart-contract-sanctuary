/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity 0.4.18;


contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}


contract Airdropper is Ownable {

    function AirTransfer(address[] myAddresses, uint _values) onlyOwner public returns (bool) {
        require(myAddresses.length > 0);

        for(uint j = 0; j < myAddresses.length; j++){
            myAddresses[j].transfer(_values);
        }

        return true;
    }

    

}