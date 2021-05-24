/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity 0.6.0;

//provides abillity to call ParkCryption.transferFrom function
interface ParkCryption {
    function transferFrom(address from, address to, uint256 value) external;
}

//provides a buy tokens event reentrancy guard check
contract ReentrancyGuard {

  uint32 private _guardCounter;

  constructor() internal {
    _guardCounter = 1;
  }

  modifier nonReentrant() {
    _guardCounter += 1;
    uint32 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

contract GetPARKtokens is ReentrancyGuard{
  //global variables
  address payable owner;
  uint256 private tokenRate;
  ParkCryption public parkToken;
  
  //generate a blockchain event to broadcast tokens donated
  event FundTransfer(address donator, uint256 amount);
  
  //create an association with ParkCryption token to be able to call transfer function 
  constructor(address addressOfToken) public {
    tokenRate = 10000000000000000000000;
    owner = msg.sender;
    parkToken = ParkCryption(addressOfToken);
  }
  
  //provide ability for project participants to acquire PARK tokens
  // Function to receive Ether. msg.data must be empty
  receive() external nonReentrant payable {
    preValidatePurchase(msg.sender, msg.value);
    uint256 usertokens = getTokenAmount(msg.value);
    processPurchase(address(this), msg.sender, usertokens);
    forwardFunds(msg.value);
    emit FundTransfer(msg.sender, usertokens);
  }
  
  //check input data
  function preValidatePurchase(address beneficiary, uint256 weiAmount)
    internal
    pure
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
    //require((weiRaised + weiAmount) <= TokenCap);
  }
  
  //calculate token amount based on token rate
  function getTokenAmount(uint256 weiAmount)
    internal 
    view 
    returns (uint256)
  {
    return weiAmount * tokenRate;
  }
  
  //call ParkCryption transferFrom function
  function processPurchase(address thisContract, address beneficiary, uint256 tokenAmount)
    internal
  {
    parkToken.transferFrom(thisContract, beneficiary, tokenAmount);
  }
  
  //forward ETH
  function forwardFunds(uint256 weiAmount) 
    internal 
  {
    (bool success, ) = owner.call.value(weiAmount)("");
    require(success, "Failed to send Ether");
  }
  
}