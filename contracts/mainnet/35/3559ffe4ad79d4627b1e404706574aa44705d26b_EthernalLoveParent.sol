contract DigitalPadlock {
    string public message;

    function DigitalPadlock(string _m) public {
        message = _m;
    }
}

contract EthernalLoveParent {
  address owner;
  address[] public padlocks;
  event LogCreatedValentine(address padlock); // maybe listen for events

  function EthernalLoveParent() public {
    owner = msg.sender;
  }

  function createPadlock(string _m) public {
    DigitalPadlock d = new DigitalPadlock(_m);
    LogCreatedValentine(d); // emit an event
    padlocks.push(d); 
  }
}