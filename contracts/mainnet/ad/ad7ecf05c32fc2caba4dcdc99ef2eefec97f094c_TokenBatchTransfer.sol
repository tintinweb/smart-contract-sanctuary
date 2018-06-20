pragma solidity ^0.4.23;


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

contract ERC20Basic {
  // events
  event Transfer(address indexed from, address indexed to, uint256 value);

  // public functions
  function totalSupply() public view returns (uint256);
  function balanceOf(address addr) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

contract ERC20 is ERC20Basic {
  // events
  event Approval(address indexed owner, address indexed agent, uint256 value);

  // public functions
  function allowance(address owner, address agent) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address agent, uint256 value) public returns (bool);

}

library SafeERC20 {

  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

contract Ownable {

  // public variables
  address public owner;

  // internal variables

  // events
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // public functions
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

  // internal functions
}


contract TokenBatchTransfer is Ownable {
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

  // public variables
  ERC20Basic public ERC20Token;

  // internal variables
  uint256 _totalSupply;

  // events

  // public functions
  constructor (
    ERC20Basic token
  )
    public
  {
    ERC20Token = ERC20Basic(token);
  }

  function amountOf() public view returns (uint256 amount) {
    return ERC20Token.balanceOf(address(this));
  }

  function safeTransfer(address funder, uint256 amount) public onlyOwner {
    ERC20Token.safeTransfer(funder, amount);
  }

  function changeToken(ERC20Basic token) public onlyOwner {
    ERC20Token = ERC20Basic(token);
  }

  function batchTransfer(address[] funders, uint256[] amounts) public onlyOwner {
    require(funders.length > 0 && funders.length == amounts.length);

    uint256 total = ERC20Token.balanceOf(this);
    require(total > 0);

    uint256 fundersTotal = 0;
    for (uint i = 0; i < amounts.length; i++) {
      fundersTotal = fundersTotal.add(amounts[i]);
    }
    require(total >= fundersTotal);

    for (uint j = 0; j < funders.length; j++) {
      ERC20Token.safeTransfer(funders[j], amounts[j]);
    }
  }
}