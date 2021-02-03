pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Owned {

  address payable public owner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address payable _newOwner) public onlyOwner {
    owner = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}


contract Presale is Owned {

  using SafeMath for uint256;

  bool public isPresaleOpen;

  IERC20 public token;
  uint256 public constant TOKEN_DECIMALS = 18;
  uint256 public constant tokenRatePerEth = 400;
  uint256 public constant minEthLimit = 0.1 ether;
  uint256 public constant maxEthLimit = 1.5 ether;
  uint256 public constant maxEthLimitTotal = 10 ether;
  uint256 private constant RATE = 10 ** (18 - TOKEN_DECIMALS);

  mapping(address => uint256) public usersInvestments;
  uint256 public investmentsTotal;

  constructor(address _tokenAddress) public {
    owner = msg.sender;
    token = IERC20(_tokenAddress);
  }

  function startPresale() external onlyOwner {
    require(!isPresaleOpen, "Open");
    isPresaleOpen = true;
  }

  function closePresale() external onlyOwner {
    require(isPresaleOpen, "Closed");
    isPresaleOpen = false;
  }

  function drainUnsoldTokens() external onlyOwner {
    require(!isPresaleOpen, "Not until its closed");
    uint256 balance = token.balanceOf(address(this));
    token.transfer(owner, balance);
  }

  function getTokensPerEth(uint256 amount) public pure returns (uint256) {
    return amount.mul(tokenRatePerEth).div(RATE);
  }

  function purchase() external payable {
    require(isPresaleOpen, "Presale closed.");
    require(
      usersInvestments[msg.sender].add(msg.value) <= maxEthLimit
      && usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
      "User limit!"
    );
    require(
      investmentsTotal.add(msg.value) <= maxEthLimitTotal,
      "Total limit!"
    );
    
    uint256 tokenAmount = getTokensPerEth(msg.value);

    usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);
    investmentsTotal = investmentsTotal.add(msg.value);

    require(token.transfer(msg.sender, tokenAmount), "Tokens transfer failed!");

    (bool success, ) = owner.call{ value: msg.value }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }
}