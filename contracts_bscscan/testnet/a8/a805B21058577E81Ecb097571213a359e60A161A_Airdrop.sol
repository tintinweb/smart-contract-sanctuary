/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity 0.5.3;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ERC20 Airdrop dapp smart contract
 */
contract Airdrop {
  IERC20 public token = IERC20(0x61C2eB49F801390f2E86f237Fd109cefECeb3401);

  /**
   * @dev doAirdrop is the main method for distribution
   * @param addresses address[] addresses to airdrop
   * @param values address[] values for each address
   */
  function doAirdrop(address[] calldata addresses, uint256 [] calldata values) external returns (uint256) {
    uint256 i = 0;

    while (i < addresses.length) {
      token.transferFrom(msg.sender, addresses[i], values[i]);
      i += 1;
    }

    return i;
  }
}