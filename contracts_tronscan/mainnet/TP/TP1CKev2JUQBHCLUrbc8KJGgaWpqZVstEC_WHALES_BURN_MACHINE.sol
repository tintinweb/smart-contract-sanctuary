//SourceUnit: WHALES_BURN_MACHINE.sol

pragma solidity 0.4.25;

contract Auth {

  address internal owner;
  address internal trigger;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(
    address _owner
  ) internal {
    owner = _owner;
  }

  modifier onlyOwner() {
    require(isOwner(), '401');
    _;
  }

  function _transferOwnership(address _newOwner) onlyOwner internal {
    require(_newOwner != address(0x0));
    owner = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

}

/**
 * @title TRC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
contract ITRC20 {
  function transfer(address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function balanceOf(address who) public view returns (uint256);

  function allowance(address owner, address spender) public view returns (uint256);

  function burn(uint _amount) public;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract WHALES_BURN_MACHINE is Auth {

  ITRC20 whalesToken = ITRC20(0x51920f822760DD05663dd0c52FD5F3581DF673C8);
  ITRC20 usdtToken = ITRC20(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);
  event Burnt(address indexed farmer, uint amount);

  constructor() public Auth(msg.sender) {}

  function burn(uint amount) public {
    require(whalesToken.allowance(msg.sender, address(this)) >= amount, 'Please approve first');
    whalesToken.transferFrom(msg.sender, address(this), amount);
    usdtToken.transfer(msg.sender, amount);
    whalesToken.burn(amount);
    emit Burnt(msg.sender, amount);
  }

  function finish() onlyOwner public {
    usdtToken.transfer(msg.sender, usdtToken.balanceOf(address(this)));
  }
}