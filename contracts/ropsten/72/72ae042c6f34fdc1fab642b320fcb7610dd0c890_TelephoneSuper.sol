pragma solidity ^0.4.18;

contract Telephone {

  address public owner;

  function Telephone() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}

contract TelephoneSuper {
    Telephone public phone;

    constructor (address _phoneOwner){
        phone = Telephone(_phoneOwner);
    }

    function changeTelephone(address _newPhoneContract) public {
        phone = Telephone(_newPhoneContract);
    }


    function changeTelephoneOwner(address _newOwner) public {
        phone.changeOwner(_newOwner);
    }

}