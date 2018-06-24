pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
    
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract MintTokensInterface {
    
  function mint(address _to, uint256 _amount) public returns (bool);
    
}

contract TokenDistributor is Ownable {

  using SafeMath for uint256;

  bool public stopContract = false;
    
  MintTokensInterface public crowdsale = MintTokensInterface(0x2D3E7D4870a51b918919E7B851FE19983E4c38d5);
  
  mapping(address => bool) public authorized;

  mapping(address => uint) public balances;

  address[] public rewardHolders;

  event RewardTransfer(address indexed to, uint amount);

  modifier onlyAuthorized() {
    require(msg.sender == owner || authorized[msg.sender]);
    _;
  }
  
  function setStopContract(bool newStopContract) public onlyOwner {
    stopContract = newStopContract;
  }
  
  function addAuthorized(address to) public onlyOwner {
    authorized[to] = true;
  }
  
  function removeAuthorized(address to) public onlyOwner {
    authorized[to] = false;
  }
    
  function mintBatch(address[] wallets, uint[] tokens) public onlyOwner {
    for(uint i=0; i<wallets.length; i++) crowdsale.mint(wallets[i], tokens[i]);
  }

  function mintAuthorizedBatch(address[] wallets, uint[] tokens) public onlyAuthorized {
    for(uint i=0; i<wallets.length; i++) crowdsale.mint(wallets[i], tokens[i]);
  }

  function isContract(address addr) public view returns(bool) {
    uint codeLength;
    assembly {
      // Retrieve the size of the code on target address, this needs assembly .
      codeLength := extcodesize(addr)
    }
    return codeLength > 0;
  }
  
  function mintAuthorizedBatchWithBalances(address[] wallets, uint[] tokens) public onlyAuthorized {
    address wallet;
    uint reward;
    bool isItContract;
    for(uint i=0; i<wallets.length; i++) {
      wallet = wallets[i];
      isItContract = isContract(wallet);
      if(!isItContract || (isItContract && !stopContract)) {
        reward = tokens[i];
        crowdsale.mint(wallet, reward);
        if(balances[wallet] == 0) {
          rewardHolders.push(wallet);
        }
        balances[wallet] = balances[wallet].add(reward);
        emit RewardTransfer(wallet, reward);
      }
    }
  }
    
}