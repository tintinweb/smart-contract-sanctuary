/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

contract BalanceScanner {

  function etherBalances(address[] calldata addresses) public view returns (uint256[] memory balances) {
    balances = new uint256[](addresses.length);

    for (uint256 i = 0; i < addresses.length; i++) {
      balances[i] = addresses[i].balance;
    }
  }
  
  function tokenBalances(address[] calldata addresses, address token)
    public 
    view
    returns (uint256[] memory balances)
  {
    balances = new uint256[](addresses.length);

    for (uint256 i = 0; i < addresses.length; i++) {
      balances[i] = tokenBalance(addresses[i], token);
    }
  }

  function tokensBalances(address[] calldata addresses, address[] calldata contracts)
    public 
    view
    returns (uint256[][] memory balances)
  {
    balances = new uint256[][](addresses.length);

    for (uint256 i = 0; i < addresses.length; i++) {
      balances[i] = tokensBalance(addresses[i], contracts);
    }
  }

  function tokensBalance(address owner, address[] calldata contracts) public view returns (uint256[] memory balances) {
    balances = new uint256[](contracts.length);

    for (uint256 i = 0; i < contracts.length; i++) {
      balances[i] = tokenBalance(owner, contracts[i]);
    }
  }

  function tokenBalance(address owner, address token) private view returns (uint256 balance) {
    uint256 size = codeSize(token);

    if (size > 0) {
      (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", owner));
      if (success) {
        (balance) = abi.decode(data, (uint256));
      }
    }
  }


  function codeSize(address _address) private view returns (uint256 size) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(_address)
    }
  }
}