pragma solidity ^0.4.19;

// ----------------------------------------------------------------------------
//
// Funds Gateway contract
//
// ----------------------------------------------------------------------------

contract Owned {

  address public owner;
  address public newOwner;


  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferConfirmed(address indexed _from, address indexed _to);


  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }


  function Owned() public{
    owner = msg.sender;
  }


  function transferOwnership(address _newOwner) onlyOwner public{
    require(_newOwner != owner);
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }


  function confirmOwnership() public{
    assert(msg.sender == newOwner);
    OwnershipTransferConfirmed(owner, newOwner);
    owner = newOwner;
  }

}


contract Gateway is Owned{

  address public targetWallet;
  address public whitelistWallet;


  bool public gatewayOpened = false;


  mapping(address => bool) public whitelist;


  event TargetWalletUpdated(address _newWallet);
  event WhitelistWalletUpdated(address _newWhitelistWallet);
  event GatewayStatusUpdated(bool _status);
  event WhitelistUpdated(address indexed _participant, bool _status);
  event PassedGateway(address _participant, uint _value);


  function Gateway() public{
    targetWallet = owner;
    whitelistWallet = owner;
    newOwner = address(0x0);
  }


  function () payable public{
    passGateway();
  }


  function addToWhitelist(address _participant) external{
    require(msg.sender == whitelistWallet || msg.sender == owner);
    whitelist[_participant] = true;
    WhitelistUpdated(_participant, true);
  }


  function addToWhitelistMultiple(address[] _participants) external{
    require(msg.sender == whitelistWallet || msg.sender == owner);
    for (uint i = 0; i < _participants.length; i++) {
      whitelist[_participants[i]] = true;
      WhitelistUpdated(_participants[i], true);
    }
  }


  function removeFromWhitelist(address _participant) external{
    require(msg.sender == whitelistWallet || msg.sender == owner);
    whitelist[_participant] = false;
    WhitelistUpdated(_participant, false);
  }


  function removeFromWhitelistMultiple(address[] _participants) external{
    require(msg.sender == whitelistWallet || msg.sender == owner);
    for (uint i = 0; i < _participants.length; i++) {
      whitelist[_participants[i]] = false;
      WhitelistUpdated(_participants[i], false);
    }
  }


  function setTargetWallet(address _wallet) onlyOwner external{
    require(_wallet != address(0x0));
    targetWallet = _wallet;
    TargetWalletUpdated(_wallet);
  }


  function setWhitelistWallet(address _wallet) onlyOwner external{
    whitelistWallet = _wallet;
    WhitelistWalletUpdated(_wallet);
  }


  function openGateway() onlyOwner external{
    require(!gatewayOpened);
    gatewayOpened = true;

    GatewayStatusUpdated(true);
  }


  function closeGateway() onlyOwner external{
    require(gatewayOpened);
    gatewayOpened = false;

    GatewayStatusUpdated(false);
  }


  function passGateway() private{

    require(gatewayOpened);
    require(whitelist[msg.sender]);

	  // sends Eth forward; covers edge case of mining/selfdestructing Eth to the contract address
    targetWallet.transfer(this.balance);

    // log event
    PassedGateway(msg.sender, msg.value);
  }

}