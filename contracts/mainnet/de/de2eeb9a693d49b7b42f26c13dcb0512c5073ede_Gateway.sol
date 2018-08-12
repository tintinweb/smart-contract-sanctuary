pragma solidity ^0.4.24;

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


  constructor() public{
    owner = msg.sender;
  }


  function transferOwnership(address _newOwner) onlyOwner public{
    require(_newOwner != owner);
    emit OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }


  function confirmOwnership() public{
    assert(msg.sender == newOwner);
    emit OwnershipTransferConfirmed(owner, newOwner);
    owner = newOwner;
  }

}


  //from ERC20 standard
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract Gateway is Owned {

  address public targetWallet;
  address public whitelistWallet;


  bool public gatewayOpened = false;

    
  mapping(address => bool) public whitelist;

  
  event TargetWalletUpdated(address _newWallet);
  event WhitelistWalletUpdated(address _newWhitelistWallet);
  event GatewayStatusUpdated(bool _status);
  event WhitelistUpdated(address indexed _participant, bool _status);
  event PassedGateway(address _participant, uint _value);
  

  constructor() public{
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
    emit WhitelistUpdated(_participant, true);
  }  


  function addToWhitelistMultiple(address[] _participants) external{
    require(msg.sender == whitelistWallet || msg.sender == owner);
    for (uint i = 0; i < _participants.length; i++) {
      whitelist[_participants[i]] = true;
      emit WhitelistUpdated(_participants[i], true);
    }
  }


  function removeFromWhitelist(address _participant) external{
    require(msg.sender == whitelistWallet || msg.sender == owner);
    whitelist[_participant] = false;
    emit WhitelistUpdated(_participant, false);
  }  


  function removeFromWhitelistMultiple(address[] _participants) external{
    require(msg.sender == whitelistWallet || msg.sender == owner);
    for (uint i = 0; i < _participants.length; i++) {
      whitelist[_participants[i]] = false;
      emit WhitelistUpdated(_participants[i], false);
    }
  }


  function setTargetWallet(address _wallet) onlyOwner external{
    require(_wallet != address(0x0));
    targetWallet = _wallet;
    emit TargetWalletUpdated(_wallet);
  }
  

  function setWhitelistWallet(address _wallet) onlyOwner external{
    whitelistWallet = _wallet;
    emit WhitelistWalletUpdated(_wallet);
  }


  function openGateway() onlyOwner external{
    require(!gatewayOpened);
    gatewayOpened = true;
    
    emit GatewayStatusUpdated(true);
  }


  function closeGateway() onlyOwner external{
    require(gatewayOpened);
    gatewayOpened = false;
    
    emit GatewayStatusUpdated(false);
  }


  function passGateway() private{

    require(gatewayOpened);
    require(whitelist[msg.sender]);

	  // sends Eth forward; covers edge case of mining/selfdestructing Eth to the contract address
	  // note: address uses a different "transfer" than ERC20.
    address(targetWallet).transfer(address(this).balance);

    // log event
    emit PassedGateway(msg.sender, msg.value);
  }
  
  
  
      
  //from ERC20 standard
  //Used if someone sends tokens to the bouncer contract.
  function transferAnyERC20Token(
    address tokenAddress,
    uint256 tokens
  )
    public
    onlyOwner
    returns (bool success)
  {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
  
}