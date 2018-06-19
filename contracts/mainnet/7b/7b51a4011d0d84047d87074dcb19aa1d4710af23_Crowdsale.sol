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

contract IVenaCoin{
    function buyToken(address to, uint tokens) public returns (bool success);
}

contract Crowdsale {
  using SafeMath for uint256;
  // Interface takes an address of the existing contract as parameter
  IVenaCoin token = IVenaCoin(0xb12ff864749a8eef9a93246ae883bdf37e49a068); 
  //VenaCoin token =  VenaCoin (0x8c1ed7e19abaa9f23c476da86dc1577f1ef401f5);
  // Address where funds are collected
  address public wallet = 0xd2a60240df3133b48d23e358a09efa8eb8de91a0;

  // How many token units a buyer gets per wei
  uint256 public rate = 518;

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
    token.buyToken(_beneficiary, _tokenAmount);
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }
  
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
}