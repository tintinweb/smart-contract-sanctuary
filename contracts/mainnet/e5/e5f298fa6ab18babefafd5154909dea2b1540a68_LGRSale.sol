// GYM Ledger Token Sale Contract - Project website: www.gymledger.com

// GYM Reward, LLC

pragma solidity ^0.4.25;

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
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Valid address is required");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface TokenContract {
  function mintTo(address _to, uint256 _amount) external;
}

contract LGRSale is Ownable {
  using SafeMath for uint256;

  address public walletAddress;
  TokenContract public tkn;
  uint256[3] public pricePerToken = [1400 szabo, 1500 szabo, 2000 szabo];
  uint256[3] public levelEndDate = [1539648000, 1541030400, 1546300740];
  uint8 public currentLevel;
  uint256 public tokensSold;
  uint256 public ethRised;

  constructor() public {
    currentLevel = 0;
    tokensSold = 0;
    ethRised = 0;
    walletAddress = 0xE38cc3F48b4F98Cb3577aC75bB96DBBc87bc57d6;
    tkn = TokenContract(0x7172433857c83A68F6Dc98EdE4391c49785feD0B);
  }

  function() public payable {
    
    if (levelEndDate[currentLevel] < now) {
      currentLevel += 1;
      if (currentLevel > 2) {
        msg.sender.transfer(msg.value);
      } else {
        executeSell();
      }
    } else {
      executeSell();
    }
  }
  
  function executeSell() private {
    uint256 tokensToSell;
    require(msg.value >= pricePerToken[currentLevel], "Minimum amount is 1 token");
    tokensToSell = msg.value.div(pricePerToken[currentLevel]) * 1 ether;
    tkn.mintTo(msg.sender, tokensToSell);
    tokensSold = tokensSold.add(tokensToSell);
    ethRised = ethRised.add(msg.value);
    walletAddress.transfer(msg.value);
  }

  function killContract(bool _kill) public onlyOwner {
    if (_kill == true) {
      selfdestruct(owner);
    }
  }

  function setWallet(address _wallet) public onlyOwner {
    walletAddress = _wallet;
  }

  function setLevelEndDate(uint256 _level, uint256 _date) public onlyOwner {
    levelEndDate[_level] = _date;
  }

}