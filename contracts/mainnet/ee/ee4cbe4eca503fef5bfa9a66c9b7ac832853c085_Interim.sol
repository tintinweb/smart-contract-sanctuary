pragma solidity ^0.4.21;
contract BLInterface {
    function setPrimaryAccount(address newMainAddress) public;
    function withdraw() public;
}
contract CSInterface {
    function goalReached() public;
    function goal() public returns (uint);
    function hasClosed() public returns(bool);
    function weiRaised() public returns (uint);
}
contract StorageInterface {
    function getUInt(bytes32 record) public constant returns (uint);
}
contract Interim {
    // Define DS, Bubbled and Token Sale addresses
    address public owner; // DS wallet
    address public bubbled; // bubbled dwallet
    BLInterface internal BL; // Blocklord Contract Interface
    CSInterface internal CS; // Crowdsale contract interface
    StorageInterface internal s; // Eternal Storage Interface
    uint public rate; // ETH to GBP rate
    function Interim() public {
        // Setup owner DS
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyBubbled() {
        require(msg.sender == bubbled);
        _;
    }
    modifier onlyMembers() {
        require(msg.sender == owner || msg.sender == bubbled);
        _;
    }
    // Setup the interface to the Blocklord contract
    function setBLInterface(address newAddress) public onlyOwner {
        BL = BLInterface(newAddress);
    }
    // Setup the interface to the storage contract
    function setStorageInterface(address newAddress) public onlyOwner {
        s = StorageInterface(newAddress);
    }
    // Setup the interface to the Blocklord contract
    function setCSInterface(address newAddress) public onlyOwner {
        CS = CSInterface(newAddress);
    }
    // Setup the interface to the Bubbled multisig contract
    function setBubbled(address newAddress) public onlyMembers {
        bubbled = newAddress;
    }
    // Setup the interface to the DS Personal address
    function setDS(address newAddress) public onlyOwner {
        owner = newAddress;
    }

    function setRate(uint _rate) public onlyOwner {
      rate = _rate;
    }

    // we can call this function to check the status of both crowdsale and blocklord
    function checkStatus () public returns(uint raisedBL, uint raisedCS, uint total, uint required, bool goalReached){
      raisedBL = s.getUInt(keccak256(address(this), "balance"));
      raisedCS = CS.weiRaised();
      total = raisedBL + raisedCS;
      required = CS.goal();
      goalReached = total >= required;
    }

    function completeContract (bool toSplit) public payable {
    //   require(CS.hasClosed()); // fail if crowdsale has not closed
    bool goalReached;
    (,,,goalReached) = checkStatus();
    if (goalReached) require(toSplit == false);
      uint feeDue;
      if (toSplit == false) {
        feeDue = 20000 / rate * 1000000000000000000; // fee due in Wei
        require(msg.value >= feeDue);
      }
      BL.withdraw(); // withdraw ETH from Blocklord contract to Interim contract
       if (goalReached) { // if goal reached
         BL.setPrimaryAccount(bubbled); // Transfer Blocklord contract and payment to be maade offline
         owner.transfer(feeDue);
         bubbled.transfer(this.balance);
       } else { // if goal not reached
         if (toSplit) { // if Bubbled decides to split
           BL.setPrimaryAccount(owner); //set ownership to DS
           uint balance = this.balance;
           bubbled.transfer(balance / 2);
           owner.transfer(balance / 2);
         } else {
           // Bubbled decides to keep blocklord
           BL.setPrimaryAccount(bubbled);
           owner.transfer(feeDue);
           bubbled.transfer(this.balance);
         }
       }
    }
    // receive ether from blocklord contract
    function () public payable {
    }
}