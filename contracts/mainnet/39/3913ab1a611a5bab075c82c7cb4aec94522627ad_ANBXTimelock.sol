pragma solidity ^0.4.24;


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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


/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract ANBXTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public firstReleaseTime;
  uint256 public secondReleaseTime;

  constructor(
    address _token,
    address _beneficiary,
    uint256 _firstLockupInDays,
    uint256 _secondLockupInDays
  )
    public
  {
    // solium-disable-next-line security/no-block-members
    require(_firstLockupInDays > 0);
    require(_secondLockupInDays > 0);
    token = ERC20Basic(_token);
    beneficiary = _beneficiary;
    firstReleaseTime = now + _firstLockupInDays * 1 days;
    secondReleaseTime = now + _secondLockupInDays * 1 days;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    uint256 amount;
    // solium-disable-next-line security/no-block-members
    if (secondReleaseTime != 0 && block.timestamp >= secondReleaseTime) {
      amount = token.balanceOf(this);
      require(amount > 0);
      token.safeTransfer(beneficiary, amount);
      secondReleaseTime = 0;
    } else if (firstReleaseTime != 0 && block.timestamp >= firstReleaseTime) {
      amount = token.balanceOf(this);
      require(amount > 0);
      token.safeTransfer(beneficiary, amount / 2);
      firstReleaseTime = 0;
    }
  }
}