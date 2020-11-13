pragma solidity 0.5.12;

// https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
  function name() external view returns (string memory); // optional method - see eip spec
  function symbol() external view returns (string memory); // optional method - see eip spec
  function decimals() external view returns (uint8); // optional method - see eip spec
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}