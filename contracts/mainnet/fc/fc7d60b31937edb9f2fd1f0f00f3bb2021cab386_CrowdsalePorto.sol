// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract IPortoCoin{
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

contract CrowdsalePorto is Owned {
  using SafeMath for uint256;
  
  function CrowdsalePorto(address _wallet, address _tokenOwner){
      wallet = _wallet;
      owner = _tokenOwner;
  }
  // Interface takes an address of the existing contract as parameter
  IPortoCoin token = IPortoCoin(0x38286ddde65b3fcdd0c4d5acad9c7702001a6cf2);
  
  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate = 16000;

  // Amount of wei raised
  uint256 public weiRaised;
  
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);
    
    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _forwardFunds();
    
  }
  
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }
  
  function _getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
    return _weiAmount.mul(rate);
  }
  
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transferFrom(owner,_beneficiary,_tokenAmount);
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }
  
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
}