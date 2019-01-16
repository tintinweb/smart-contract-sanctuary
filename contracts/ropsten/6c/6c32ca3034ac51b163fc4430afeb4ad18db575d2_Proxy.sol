pragma solidity ^0.4.25;


contract Accessibility {
  enum AccessRank { None, One, Two, Three }
  mapping(address => AccessRank) public admins;
  modifier onlyAdmin(AccessRank  r) {
    require(
      admins[msg.sender] == r || admins[msg.sender] == AccessRank.Three,
      "access denied"
    );
    _;
  }
  event LogProvideAccess(address indexed whom, AccessRank rank, uint when);

  constructor() public {
    admins[msg.sender] = AccessRank.Three;
    emit LogProvideAccess(msg.sender, AccessRank.Three, now);
  }

  function provideAccess(address addr, AccessRank rank) public onlyAdmin(AccessRank.Three) {
    if (admins[addr] != rank) {
      admins[addr] = rank;
      emit LogProvideAccess(addr, rank, now);
    }
  }
}

contract StorageState {
    KeyValueStorage _storage; 
}


contract KeyValueStorage {
  struct Invoice {
        uint id;
        bool isOut;
        string released;
        string received;
        string date;
        string agreed;
  }

  mapping(address => mapping(bytes32 => Invoice)) _invoiceStorage;
  
  event LogInvoice( bytes32 indexed key, 
      uint id, 
      bool isOut, 
      string released,
      string received,
      string date,
      string agreed);

  /**** Get Methods ***********/

  function getInvoice(address addr, bytes32 key) public view returns (
    uint id, 
    bool isOut, 
    string released,
    string received,
    string date,
    string agreed
  ) {
   Invoice storage i = _invoiceStorage[addr][key];
    return (i.id, i.isOut, i.released, i.received, i.date, i.agreed);
  }

  /**** Set Methods ***********/

  function setInvoice(
      bytes32 key, 
      uint id, 
      bool isOut, 
      string released,
      string received,
      string date,
      string agreed
    ) public {
    Invoice storage i = _invoiceStorage[msg.sender][key];
    i.id = id;
    i.isOut = isOut;
    i.released = released;
    i.received = received;
    i.date = date;
    i.agreed = agreed;
    emit LogInvoice(key, 
      id, 
      isOut, 
      released,
      received,
      date,
      agreed);
  }

  /**** Delete Methods ***********/

  function deleteInvoice(bytes32 key) public {
    delete _invoiceStorage[msg.sender][key];
  }

}



contract Proxy is StorageState, Accessibility {
  address public implementation;
  event LogUpgrade(address indexed implementation);
  
  constructor() public {}


  function upgradeTo(address impl) public onlyAdmin(AccessRank.Three) {
    require(implementation != impl);
    implementation = impl;
    emit LogUpgrade(impl);
  }

  function storageAddress() public view returns(address) {
    return address(_storage);
  }
  
  function setStorage(address strage_) public onlyAdmin(AccessRank.Three) {
    require(address(_storage) != address(strage_) );
    _storage = KeyValueStorage(strage_);
  }
 
  function () payable public {
    address _impl = implementation;
    require(_impl != address(0));
    bytes memory data = msg.data;

    assembly {
      let result := delegatecall(gas, _impl, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)
      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

}