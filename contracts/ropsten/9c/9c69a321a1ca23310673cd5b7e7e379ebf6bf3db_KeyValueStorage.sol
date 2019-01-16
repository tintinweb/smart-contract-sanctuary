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