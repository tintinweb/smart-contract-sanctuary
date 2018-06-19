// 0.4.21+commit.dfe3193c.Emscripten.clang
pragma solidity ^0.4.21;

// assume ERC20 or compatible token
interface ERC20 {
  function transfer( address to, uint256 value ) external;
}

contract Airdropper {

  // NOTE: be careful about array size and block gas limit. check ethstats.net
  function airdrop( address tokAddr,
                    address[] dests,
                    uint[] quantities ) public returns (uint) {

    for (uint ii = 0; ii < dests.length; ii++) {
      ERC20(tokAddr).transfer( dests[ii], quantities[ii] );
    }

    return ii;
  }
}