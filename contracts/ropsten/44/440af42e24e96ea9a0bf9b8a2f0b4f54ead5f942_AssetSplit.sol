pragma solidity 0.4.25;
// AssetSplit contract receives fees from the CanYaCoin Token contract
// Any one can call split() to split the balance in accordance with the split amounts and distination Addresses
// The owner can update split amounts and addresses. There are 3 addresses, with a burn destination.
// The owner can transfer ownership

// CanYaCoinToken Functions used in this contract
contract CanYaCoin {
  function transferFrom (address _from, address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) constant public returns (uint256 balance);
  function burn(uint256 value) public returns (bool success);
  function transfer (address _to, uint256 _value) public returns (bool success);
}

// ERC223
interface ContractReceiver {
  function tokenFallback( address from, uint value, bytes data ) external;
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// Owned Contract
contract Owned {
  modifier onlyOwner { require(msg.sender == owner); _; }
  address public owner = msg.sender;
  event NewOwner(address indexed old, address indexed current);
  function setOwner(address _new) onlyOwner public { emit NewOwner(owner, _new); owner = _new; }
}

// AssetSplit Contract
contract AssetSplit is Owned {
    
  using SafeMath for uint256;
  
  CanYaCoin public CanYaCoinToken;

  // Public Addresses
  address public operationalAddress;
  address public daoAddress;
  address public charityAddress;

  // Splits
  uint256 public operationalSplitPercent = 30;
  uint256 public daoSplitPercent = 30;
  uint256 public charitySplitPercent = 10;
  uint256 public burnSplitPercent = 30;

  // Events
  event OperationalSplit(uint256 _split);
  event DaoSplit(uint256 _split);
  event CharitySplit(uint256 _split);
  event BurnSplit(uint256 _split);


  /// @dev Deploys the asset splitting contract
  /// @param _tokenAddress Address of the CAN token contract
  /// @param _operational Address of the operational holdings
  /// @param _dao Address of the reward holdings
  /// @param _charity Address of the charity holdings
  constructor (
    address _tokenAddress,
    address _dao,
    address _operational,
    address _charity) public {
        
    require(_tokenAddress != 0);
    require(_dao != 0);
    require(_operational != 0);
    require(_charity != 0);
    
    CanYaCoinToken = CanYaCoin(_tokenAddress);

    daoAddress = _dao;
    operationalAddress = _operational;
    charityAddress = _charity;
  }

  // Accepts ether from anyone
  function() public payable { } 

  /// @dev Splits the tokens from the owner address to the defined locations
  function split () public {
      
    // Collect current balance
    uint256 assetContractBal = CanYaCoinToken.balanceOf(this);
    
    if(assetContractBal == 0) return;           // Exit peacefully if nothing here
    
    // Get the amounts of tokens for each recipient 
    uint256 onePercentOfSplit = assetContractBal / 100;
    uint256 operationalSplitAmount = onePercentOfSplit.mul(operationalSplitPercent);
    uint256 daoSplitAmount = onePercentOfSplit.mul(daoSplitPercent);
    uint256 charitySplitAmount = onePercentOfSplit.mul(charitySplitPercent);
    uint256 burnSplitAmount = onePercentOfSplit.mul(burnSplitPercent);

    // Check that it won&#39;t send too many tokens
    require(
      operationalSplitAmount
        .add(daoSplitAmount)
        .add(charitySplitAmount)
        .add(burnSplitAmount)
      <= assetContractBal
    );

    // Requre and make the transfers
    require(CanYaCoinToken.transfer(operationalAddress, operationalSplitAmount));
    require(CanYaCoinToken.transfer(daoAddress, daoSplitAmount));
    require(CanYaCoinToken.transfer(charityAddress, charitySplitAmount));
    require(CanYaCoinToken.burn(burnSplitAmount));

    // Emit the events
    emit OperationalSplit(operationalSplitAmount);
    emit DaoSplit(daoSplitAmount);
    emit CharitySplit(charitySplitAmount);
    emit BurnSplit(burnSplitAmount);
  }

  // Update Addresses
  function updateDaoAddress (address _new) public onlyOwner {
    daoAddress = _new;
  }
  
  function updateOperationalAddress (address _new) public onlyOwner {
    operationalAddress = _new;
  }

  function updateCharityAddress (address _new) public onlyOwner {
    charityAddress = _new;
  }

  //Set split in percentages. 0 = 0%, 30=30%
  // Must sum to 100
  function updateSplits (uint256 _dao, uint256 _ope, uint256 _cha, uint256 _bur) public onlyOwner {
    require(_dao + _ope + _cha + _bur == 100);
    daoSplitPercent = _dao;
    operationalSplitPercent = _ope;
    charitySplitPercent = _cha;
    burnSplitPercent = _bur;
  }

}