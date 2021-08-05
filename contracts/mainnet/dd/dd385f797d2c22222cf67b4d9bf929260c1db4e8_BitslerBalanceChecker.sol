/**
 *Submitted for verification at Etherscan.io on 2020-04-17
*/

pragma solidity ^0.6.0;

abstract contract Token {
  function balanceOf(address) public virtual view returns (uint);
}

contract BitslerBalanceChecker {
  /* Fallback function, don't accept any ETH */
  fallback() external {}
  function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
  function tokenBalance(address user, address token) internal view returns (uint) {
    if(!isContract(token)) {
        return 0;
    }
    return Token(token).balanceOf(user);
  }

  function balances(address[] calldata users, address tokens) external view returns (uint[] memory) {
    uint[] memory addrBalances = new uint[](users.length);
    require(users.length < 1000, "Limit addresses to 1000 per call");
    for(uint i = 0; i < users.length; i++) {
        uint addrIdx = i;
        if (address(tokens) != address(0x0)) { 
          addrBalances[addrIdx] = tokenBalance(address(users[i]), address(tokens));
        } else {
          addrBalances[addrIdx] = address(users[i]).balance; // ETH balance    
        }
    }
    return addrBalances;
  }
}