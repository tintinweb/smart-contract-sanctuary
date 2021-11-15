// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

contract Torch1 {
  address public immutable TARGET_BOT =
    0x6B650CA58d7b7F1525C362Ee1bb380df6140c766;

  /*
    Example calldata
    0xc7e8b2d1

    Block number
    0000000000000000000000000000000000000000000000000000000000cbb6e6

    amount
    0000000000000000000000000000000000000000000000005fc5c622b258bd70

    token
    00000000000000000000000038e4adb44ef08f22f5b5b76a8f0c2d0dcbe7dca1

    pair
    00000000000000000000000012d4444f96c644385d8ab355f6ddf801315b6254
  */
  function openSandwich_slYkeo(
    uint256 blockNumber,
    uint256 amount,
    address token,
    address pair
  ) public {}


  /*
    Example calldata
    0x97f8e89e
    0000000000000000000000000000000000000000000000000000000000cbb6e6
    0000000000000000000000000000000000000000000000191c5fc00c1d695f02
    00000000000000000000000038e4adb44ef08f22f5b5b76a8f0c2d0dcbe7dca1
    00000000000000000000000012d4444f96c644385d8ab355f6ddf801315b6254
  */
  function closeSandwich_YbtGMB(
    uint256 blockNumber,
    uint256 amount,
    address token,
    address pair
  ) public {}
}

