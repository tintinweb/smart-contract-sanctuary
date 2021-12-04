/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SmartFaucet {

  mapping (address => bool) public beneficiaries;
  address owner; // owner can change the claim amount, within certain limits
  uint claimAmount = 1_000_000_000;
  IERC20 token;

  constructor(address _token) public{
    owner = msg.sender;
    token = IERC20(_token);
  }

  function claim() public{
    require(token.balanceOf(msg.sender) == 0, "Requester already owns the token.");
    require(!beneficiaries[msg.sender], "Requester has already been paid before.");
    token.transfer(msg.sender, claimAmount);
    beneficiaries[msg.sender] = true;
  }

  function setClaimAmount(uint _value) public {
    require(msg.sender == owner, "Unauthorized");
    require(_value <= 1_000_000_000_000000000, "Claim amount too high"); // claim can't be greater than one billion
    claimAmount = _value;
  }

  function getClaimAmount() public view returns (uint) {
    return claimAmount;
  }

}