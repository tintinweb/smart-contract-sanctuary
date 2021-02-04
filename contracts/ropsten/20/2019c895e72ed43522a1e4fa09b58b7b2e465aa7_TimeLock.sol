/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

pragma solidity ^0.8.0;

//FOR DEMONSTRATION ONLY, not recommended to be used on mainnet
//@dev create a simple time-lock smart escrow contract for testing purposes denominated in seconds


contract TimeLock {
    
  //escrow struct to contain basic description of underlying deal, purchase price, ultimate recipient of funds
  struct InEscrow {
      string description;
      uint256 deposit;
      address payable recipient;
  }
  
  InEscrow[] public escrows;
  address escrowAddress = address(this);
  address payable agent;
  address payable recipient;
  uint256 deposit;
  uint256 effectiveTime;
  uint256 expirationTime;
  bool isExpired;
  string description;
  //map whether an address is a party to the transaction and has authority 
  mapping(address => bool) public parties;
  mapping(address => bool) registeredAddresses;
  
  event DealExpired();
  
  //restricts to agent (creator of escrow contract) or internal calls
  modifier restricted() {
    require(registeredAddresses[msg.sender], "This may only be called by the Agent or the escrow contract itself");
    _;
  }
  
  //creator of escrow contract is agent and contributes deposit-- could be third party agent/title co. or simply the buyer
  //initiate escrow with description, deposit, assign creator as agent, and designate recipient
  constructor(string memory _description, uint256 _deposit, address payable _creator, address payable _recipient, uint256 _secsUntilExpiration) payable {
      require(msg.value >= deposit, "Submit deposit amount");
      agent = _creator;
      deposit = _deposit;
      description = _description;
      recipient = _recipient;
      parties[agent] = true;
      registeredAddresses[agent] = true;
      registeredAddresses[escrowAddress] = true;
      effectiveTime = uint256(block.timestamp);
      expirationTime = effectiveTime + _secsUntilExpiration;
      isExpired = false;
      sendEscrow(description, deposit, recipient);
  }
  
  //agent confirms recipient of escrowed funds as extra security measure
  function approveRecipient(address payable _recipient) public restricted {
      require(_recipient != recipient, "Party already designated as recipient");
      require(!isExpired, "Too late to change recipient");
      parties[_recipient] = true;
      recipient = _recipient;
  }
  
  //create new escrow contract within master structure
  function sendEscrow(string memory _description, uint256 _deposit, address payable _recipient) private restricted {
      InEscrow memory newRequest = InEscrow({
         description: _description,
         deposit: _deposit,
         recipient: _recipient
      });
      escrows.push(newRequest);
  }
  
  //check if expired, and if so, remit balance to recipient
  function checkIfExpired() public returns(bool){
        if (expirationTime <= uint256(block.timestamp)) {
            isExpired = true;
            recipient.transfer(escrowAddress.balance);
            emit DealExpired();
        } else {
            isExpired = false;
        }
        return(isExpired);
    }
}