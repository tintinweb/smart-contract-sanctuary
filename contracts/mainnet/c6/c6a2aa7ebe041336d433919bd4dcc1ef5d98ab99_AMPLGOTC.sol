// SPDX-License-Identifier: MIT

/* 

    _    __  __ ____  _     _____ ____       _     _       _       
   / \  |  \/  |  _ \| |   | ____/ ___| ___ | | __| |     (_) ___  
  / _ \ | |\/| | |_) | |   |  _|| |  _ / _ \| |/ _` |     | |/ _ \ 
 / ___ \| |  | |  __/| |___| |__| |_| | (_) | | (_| |  _  | | (_) |
/_/   \_\_|  |_|_|   |_____|_____\____|\___/|_|\__,_| (_) |_|\___/ 
                                                                                                

    Ample Gold $AMPLG is a goldpegged defi protocol that is based on Ampleforths elastic tokensupply model. 
    AMPLG is designed to maintain its base price target of 0.01g of Gold with a progammed inflation adjustment (rebase).
    
    Forked from Ampleforth: https://github.com/ampleforth/uFragments (Credits to Ampleforth team for implementation of rebasing on the ethereum network)
    
    GPL 3.0 license
    
    AMPLG_OTC.sol - AMPLG OTC
  
*/

pragma solidity ^0.4.24;

contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  function isConstructor() private view returns (bool) {
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  uint256[50] private ______gap;
}

contract Ownable is Initializable {

  address private _owner;
  uint256 private _ownershipLocked;

  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  function initialize(address sender) internal initializer {
    _owner = sender;
  _ownershipLocked = 0;
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  
  // Set _ownershipLocked flag to lock contract owner forever
  function lockOwnership() public onlyOwner {
  require(_ownershipLocked == 0);
  emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private ______gap;
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {

    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}


interface IAMPLG {
    function totalSupply() external view returns (uint256);
    function rebaseMonetary(uint256 epoch, int256 supplyDelta) external returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}


contract AMPLGOTC is Ownable {
    
    using SafeMath for uint256;
    using SafeMathInt for int256;


  IAMPLG public token;
  address public wallet;
  uint256 public rate;
  uint256 public weiRaised;
  
  bool public isFunding;

  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  constructor(uint256 _rate, address _wallet, IAMPLG _amplg) public {
    Ownable.initialize(msg.sender);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_amplg != address(0));
    rate = _rate;
    wallet = _wallet;
    token = _amplg;
    isFunding = true;
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {
      require(isFunding);
      uint256 weiAmount = msg.value; 
      _preValidatePurchase(_beneficiary, weiAmount);
      uint256 tokens = _getTokenAmount(weiAmount);
      weiRaised = weiRaised.add(weiAmount);
      _processPurchase(_beneficiary, tokens);
      emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        _updatePurchasingState(_beneficiary, weiAmount);
        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal { 
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokenDecimals = 9;
        uint256 etherDecimals = 18;

        if (tokenDecimals < etherDecimals) {
            return _weiAmount.mul(rate).div(10 ** (etherDecimals.sub(tokenDecimals)));
        }

        if (tokenDecimals > etherDecimals) {
            return _weiAmount.mul(rate).mul(10 ** (tokenDecimals.sub(etherDecimals)));
        }

        return _weiAmount.mul(rate);
  }
  
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
  function getBalance() public view returns (uint256) {
      address _address = this;
      return token.balanceOf(_address);
      
  }
  
   function setStatusOTC(bool _status) 
   external 
   onlyOwner 
   {
      require(msg.sender == Ownable.owner());
      isFunding = _status;
    }
  
  function setRate(uint256 _rate) 
   external 
   onlyOwner 
   {
      require(msg.sender == Ownable.owner());
      rate = _rate;
    }
  
  function collectUnsoldAfterOTC() 
  external
  onlyOwner
  {
        isFunding = false;
        uint256 remaining = token.balanceOf(this);
        token.transfer(msg.sender, remaining);
  }
    
    
  function burnTokens(address _tokenAddress, uint _amount) 
  external
  onlyOwner
  {
        isFunding = false;
        token.transfer(_tokenAddress, _amount);
  }
    
}