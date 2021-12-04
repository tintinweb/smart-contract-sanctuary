// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IUniswapV2Router02 } from "./interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "./interfaces/IUniswapV2Pair.sol";

// solhint-disable-next-line max-states-count
contract ABCToken is IERC20Metadata, Ownable {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name = "ABCToken";
  string private _symbol = "ABC";

  // uint256 private _minNumTokensSellToAddToLiquidity = 5000 * 10**8;

  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isPair;

  uint256 private constant TEN_POW_8 = 10**8;
  uint256 private constant MONTH = 30 days;
  address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  uint256[] public coreTeamUnlockPerMonth = [
    1_356_666_670,
    1_356_666_670 + 636_666_669,
    1_356_666_670 + 636_666_669 * 2,
    1_356_666_670 + 636_666_669 * 3,
    1_356_666_670 + 636_666_669 * 4,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 2,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 3,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 4,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 5,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 6,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 7,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 8,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 9,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 10,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 11,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 12,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 13,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 14,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 15,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 16,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 17,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 18,
    1_356_666_670 + 636_666_669 * 4 + 636_666_669 * 19
  ];
  uint256 public coreTeamUnlockedTillNow = 0;

  uint256[] public advisorsUnlockPerMonth = [
    0,
    800_000_000,
    800_000_000,
    800_000_000,
    800_000_000 * 2,
    800_000_000 * 2,
    800_000_000 * 2,
    800_000_000 * 2 + 720_000_000,
    800_000_000 * 2 + 720_000_000,
    800_000_000 * 2 + 720_000_000,
    800_000_000 * 2 + 720_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2 + 480_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2 + 480_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2 + 480_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2 + 480_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2 + 480_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2 + 480_000_000 * 2,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2 + 480_000_000 * 2 + 400_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2 + 480_000_000 * 2 + 400_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2 + 480_000_000 * 2 + 400_000_000,
    800_000_000 * 2 + 720_000_000 * 2 + 640_000_000 * 2 + 560_000_000 * 2 + 480_000_000 * 2 + 400_000_000 + 320_000_000
  ];
  uint256 public advisorsUnlockedTillNow = 0;

  uint256[] public reserveUnlockPerMonth = [
    769_230_772,
    769_230_772,
    769_230_772,
    769_230_772 + 769_230_769,
    769_230_772 + 769_230_769,
    769_230_772 + 769_230_769,
    769_230_772 + 769_230_769 * 2,
    769_230_772 + 769_230_769 * 2,
    769_230_772 + 769_230_769 * 2,
    769_230_772 + 769_230_769 * 3,
    769_230_772 + 769_230_769 * 3,
    769_230_772 + 769_230_769 * 3,
    769_230_772 + 769_230_769 * 4,
    769_230_772 + 769_230_769 * 4,
    769_230_772 + 769_230_769 * 4,
    769_230_772 + 769_230_769 * 5,
    769_230_772 + 769_230_769 * 5,
    769_230_772 + 769_230_769 * 5,
    769_230_772 + 769_230_769 * 6,
    769_230_772 + 769_230_769 * 6,
    769_230_772 + 769_230_769 * 6,
    769_230_772 + 769_230_769 * 7,
    769_230_772 + 769_230_769 * 7,
    769_230_772 + 769_230_769 * 7,
    769_230_772 + 769_230_769 * 8,
    769_230_772 + 769_230_769 * 8,
    769_230_772 + 769_230_769 * 8,
    769_230_772 + 769_230_769 * 9,
    769_230_772 + 769_230_769 * 9,
    769_230_772 + 769_230_769 * 9,
    769_230_772 + 769_230_769 * 10,
    769_230_772 + 769_230_769 * 10,
    769_230_772 + 769_230_769 * 10,
    769_230_772 + 769_230_769 * 11,
    769_230_772 + 769_230_769 * 11,
    769_230_772 + 769_230_769 * 11,
    769_230_772 + 769_230_769 * 12
  ];
  uint256 public reserveUnlockedTillNow = 0;

  uint256[] public stakingUnlockPerMonth = [
    400_000_000,
    400_000_000 * 2,
    400_000_000 * 3,
    400_000_000 * 4,
    400_000_000 * 5,
    400_000_000 * 6,
    400_000_000 * 7,
    400_000_000 * 8,
    400_000_000 * 9,
    400_000_000 * 10,
    400_000_000 * 11,
    400_000_000 * 11 + 370_000_000,
    400_000_000 * 11 + 370_000_000 * 2,
    400_000_000 * 11 + 370_000_000 * 3,
    400_000_000 * 11 + 370_000_000 * 4,
    400_000_000 * 11 + 370_000_000 * 5,
    400_000_000 * 11 + 370_000_000 * 6,
    400_000_000 * 11 + 370_000_000 * 7,
    400_000_000 * 11 + 370_000_000 * 8,
    400_000_000 * 11 + 370_000_000 * 9,
    400_000_000 * 11 + 370_000_000 * 10,
    400_000_000 * 11 + 370_000_000 * 11,
    400_000_000 * 11 + 370_000_000 * 12,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 2,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 3,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 4,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 5,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 6,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 7,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 8,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 9,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 10,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 11,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 2,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 3,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 4,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 5,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 6,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 7,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 8,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 9,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 10,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 11,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 2,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 3,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 4,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 5,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 6,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 7,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 8,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 9,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 10,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 11,
    400_000_000 * 11 + 370_000_000 * 12 + 330_000_000 * 12 + 300_000_000 * 12 * 270_000_000 * 11 + 230_000_000
  ];
  uint256 public stakingUnlockedTillNow = 0;

  uint256[] public ecosystemUnlockPerMonth = [
    0,
    2_000_000_000,
    2_000_000_000,
    2_000_000_000,
    2_000_000_000,
    2_000_000_000,
    2_000_000_000,
    2_000_000_000 + 1_500_000_000,
    2_000_000_000 + 1_500_000_000,
    2_000_000_000 + 1_500_000_000,
    2_000_000_000 + 1_500_000_000,
    2_000_000_000 + 1_500_000_000,
    2_000_000_000 + 1_500_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000 * 2,
    2_000_000_000 + 1_500_000_000 + 1_250_000_000 * 2 + 1_000_000_000 + 750_000_000 * 2 + 500_000_000
  ];
  uint256 public ecosystemUnlockedTillNow = 0;

  uint256[] public playToEarnUnlockPerMonth = [
    0,
    1_000_000_000,
    1_000_000_000,
    1_000_000_000,
    1_000_000_000 + 842_110_000,
    1_000_000_000 + 842_110_000,
    1_000_000_000 + 842_110_000,
    1_000_000_000 + 842_110_000 + 842_105_000,
    1_000_000_000 + 842_110_000 + 842_105_000,
    1_000_000_000 + 842_110_000 + 842_105_000,
    1_000_000_000 + 842_110_000 + 842_105_000 * 2,
    1_000_000_000 + 842_110_000 + 842_105_000 * 2,
    1_000_000_000 + 842_110_000 + 842_105_000 * 2,
    1_000_000_000 + 842_110_000 + 842_105_000 * 3,
    1_000_000_000 + 842_110_000 + 842_105_000 * 3,
    1_000_000_000 + 842_110_000 + 842_105_000 * 3,
    1_000_000_000 + 842_110_000 + 842_105_000 * 4,
    1_000_000_000 + 842_110_000 + 842_105_000 * 4,
    1_000_000_000 + 842_110_000 + 842_105_000 * 4,
    1_000_000_000 + 842_110_000 + 842_105_000 * 5,
    1_000_000_000 + 842_110_000 + 842_105_000 * 5,
    1_000_000_000 + 842_110_000 + 842_105_000 * 5,
    1_000_000_000 + 842_110_000 + 842_105_000 * 6,
    1_000_000_000 + 842_110_000 + 842_105_000 * 6,
    1_000_000_000 + 842_110_000 + 842_105_000 * 6,
    1_000_000_000 + 842_110_000 + 842_105_000 * 7,
    1_000_000_000 + 842_110_000 + 842_105_000 * 7,
    1_000_000_000 + 842_110_000 + 842_105_000 * 7,
    1_000_000_000 + 842_110_000 + 842_105_000 * 8,
    1_000_000_000 + 842_110_000 + 842_105_000 * 8,
    1_000_000_000 + 842_110_000 + 842_105_000 * 8,
    1_000_000_000 + 842_110_000 + 842_105_000 * 9,
    1_000_000_000 + 842_110_000 + 842_105_000 * 9,
    1_000_000_000 + 842_110_000 + 842_105_000 * 9,
    1_000_000_000 + 842_110_000 + 842_105_000 * 10,
    1_000_000_000 + 842_110_000 + 842_105_000 * 10,
    1_000_000_000 + 842_110_000 + 842_105_000 * 10,
    1_000_000_000 + 842_110_000 + 842_105_000 * 11,
    1_000_000_000 + 842_110_000 + 842_105_000 * 11,
    1_000_000_000 + 842_110_000 + 842_105_000 * 11,
    1_000_000_000 + 842_110_000 + 842_105_000 * 12,
    1_000_000_000 + 842_110_000 + 842_105_000 * 12,
    1_000_000_000 + 842_110_000 + 842_105_000 * 12,
    1_000_000_000 + 842_110_000 + 842_105_000 * 13,
    1_000_000_000 + 842_110_000 + 842_105_000 * 13,
    1_000_000_000 + 842_110_000 + 842_105_000 * 13,
    1_000_000_000 + 842_110_000 + 842_105_000 * 14,
    1_000_000_000 + 842_110_000 + 842_105_000 * 14,
    1_000_000_000 + 842_110_000 + 842_105_000 * 14,
    1_000_000_000 + 842_110_000 + 842_105_000 * 15,
    1_000_000_000 + 842_110_000 + 842_105_000 * 15,
    1_000_000_000 + 842_110_000 + 842_105_000 * 15,
    1_000_000_000 + 842_110_000 + 842_105_000 * 16,
    1_000_000_000 + 842_110_000 + 842_105_000 * 16,
    1_000_000_000 + 842_110_000 + 842_105_000 * 16,
    1_000_000_000 + 842_110_000 + 842_105_000 * 17,
    1_000_000_000 + 842_110_000 + 842_105_000 * 17,
    1_000_000_000 + 842_110_000 + 842_105_000 * 17,
    1_000_000_000 + 842_110_000 + 842_105_000 * 18
  ];
  uint256 public playToEarnUnlockedTillNow = 0;

  IUniswapV2Router02 public routerAddress = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

  address public devAddress = 0xa670a43859bBa57dA9F0A275B601A3F0AcccD41a;

  address public coreTeamAddress = 0xd6BD0AA9EC3b00a11c9b56263Ba730d3c1A82b18;
  address public advisorsAddress = 0x6148E01353EF1104bA85DDe9B60675A9D61B61A1;
  address public reserveAddress = 0x442C53578DEF2bA3e0e3D402907bA2E6CE204499;
  address public stakingAddress = 0x3Aa9c623B4f6692f1b1c710899094548Cc8fB316;
  address public ecosystemAddress = 0x1022D7d2C37281aF0AF8068639211e0f6b09271F;
  address public playToEarnAddress = 0xbf4f5CA51f777995F60e1F6a7E488787dc82C524;

  uint256 public immutable contractCreationTime;

  uint16 public devTokenFeePercent = 36;
  uint16 public devBNBFeePercent = 12;
  uint16 public buyBackFeePercent = 28;
  uint16 public liquidityFeePercent = 24;

  uint256 private _buyBackBNBCount;

  uint256 private _buyBackFeeCount;
  uint256 private _liquidityFeeCount;
  uint256 private _devBNBFeeCount;

  bool public inSwapAndLiquify;

  mapping(address => uint256) private _userLastTransactionTime;

  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
  event Burn(uint256 amount);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  constructor() {
    // Create a uniswap pair for this new token
    _isPair[IUniswapV2Factory(routerAddress.factory()).createPair(address(this), routerAddress.WETH())] = true;

    //exclude owner and this contract from fee
    _isExcludedFromFee[msg.sender] = true;
    _isExcludedFromFee[address(this)] = true;

    // initial mints
    _mint(msg.sender, 16_000_000_000 * TEN_POW_8);
    _mint(advisorsAddress, 880_000_000 * TEN_POW_8);
    _mint(stakingAddress, 400_000_000 * TEN_POW_8);
    _mint(ecosystemAddress, 3_000_000_000 * TEN_POW_8);
    _mint(playToEarnAddress, 1_000_000_000 * TEN_POW_8);

    contractCreationTime = block.timestamp;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 8;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address tokenOwner, address spender) public view virtual override returns (uint256) {
    return _allowances[tokenOwner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  /**
   * @dev Moves `amount` of tokens from `sender` to `recipient`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    if (
      !_isPair[sender] &&
      sender != address(this) &&
      sender != owner() &&
      recipient != address(this) &&
      recipient != owner()
    ) {
      require(
        block.timestamp >= _userLastTransactionTime[msg.sender] + 10,
        "time between transfers should be 10 seconds"
      );
      _userLastTransactionTime[sender] = block.timestamp;
    }

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
      _balances[recipient] += amount;

      emit Transfer(sender, recipient, amount);
    } else {
      uint256 devTokenFee = (amount * devTokenFeePercent) / 1000;
      uint256 liquidityFee = (amount * liquidityFeePercent) / 1000;
      _liquidityFeeCount += liquidityFee;
      _balances[address(this)] += liquidityFee;
      uint256 devBNBFee = 0;
      uint256 buyBackFee = 0;
      // buy
      if (_isPair[sender] && recipient != address(routerAddress)) {
        devBNBFee = (amount * devBNBFeePercent) / 1000;
        buyBackFee = (amount * buyBackFeePercent) / 1000;
        _buyBackFeeCount += buyBackFee;
        _devBNBFeeCount += devBNBFee;
      }
      // sell
      else if (_isPair[recipient]) {
        devBNBFee = (amount * devBNBFeePercent) / 1000;
        buyBackFee = (amount * buyBackFeePercent) / 1000;
        _buyBackFeeCount += buyBackFee;
        _devBNBFeeCount += devBNBFee;
        uint256 feeSum = _devBNBFeeCount + _buyBackFeeCount;
        _balances[address(this)] += feeSum;
        uint256 swappedBNB = swapTokensForEth(feeSum);
        uint256 devBNB = (swappedBNB * _devBNBFeeCount) / feeSum;
        uint256 buyBackBNB = swappedBNB - devBNB;
        Address.sendValue(payable(devAddress), devBNB);
        _buyBackBNBCount += buyBackBNB;
        _buyBackFeeCount = 0;
        _devBNBFeeCount = 0;
      } else {
        // Not buy and not sell
        if (!inSwapAndLiquify) {
          swapAndLiquify(_liquidityFeeCount);
          _liquidityFeeCount = 0;
        }
        if (_buyBackBNBCount > 0.1 ether && !inSwapAndLiquify) {
          _buyBackAndBurn(_buyBackBNBCount);
          _buyBackBNBCount = 0;
        }
      }
      uint256 recipientAmount = (amount - devTokenFee - liquidityFee - devBNBFee - buyBackFee);
      _balances[recipient] += recipientAmount;
      _balances[devAddress] += devTokenFee;
      emit Transfer(sender, devAddress, devTokenFee);
      emit Transfer(sender, recipient, recipientAmount);
    }
  }

  function _buyBackAndBurn(uint256 amount) private lockTheSwap {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = routerAddress.WETH();
    path[1] = address(this);

    uint256 initialTokenBalance = balanceOf(DEAD_ADDRESS);
    // make the swap
    routerAddress.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amount }(
      0, // accept any amount of Tokens
      path,
      DEAD_ADDRESS, // Burn address
      block.timestamp + 10
    );
    uint256 swappedTokenBalance = balanceOf(DEAD_ADDRESS) - initialTokenBalance;
    emit Burn(swappedTokenBalance);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    // split the contract balance into halves
    uint256 half = contractTokenBalance / 2;
    uint256 otherHalf = contractTokenBalance - half;

    // swap tokens for ETH
    uint256 newBalance = swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // add liquidity to uniswap
    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function swapTokensForEth(uint256 tokenAmount) private returns (uint256) {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = routerAddress.WETH();

    _approve(address(this), address(routerAddress), tokenAmount);

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // make the swap
    routerAddress.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );

    // how much ETH did we just swap into?
    return address(this).balance - initialBalance;
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(routerAddress), tokenAmount);

    // add the liquidity
    routerAddress.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner(),
      block.timestamp
    );
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address tokenOwner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(tokenOwner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[tokenOwner][spender] = amount;
    emit Approval(tokenOwner, spender, amount);
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function changeRouterAddress(IUniswapV2Router02 newRouterAddress) public onlyOwner {
    require(routerAddress != newRouterAddress, "Address already setted");
    routerAddress = newRouterAddress;
  }

  function changeDevAddress(address newDevAddress) public onlyOwner {
    require(devAddress != newDevAddress, "Address already setted");
    devAddress = newDevAddress;
  }

  function changeCoreTeamAddress(address newCoreTeamAddress) public onlyOwner {
    require(coreTeamAddress != newCoreTeamAddress, "Address already setted");
    coreTeamAddress = newCoreTeamAddress;
  }

  function changeAdvisorsAddress(address newAdvisorsAddress) public onlyOwner {
    require(advisorsAddress != newAdvisorsAddress, "Address already setted");
    advisorsAddress = newAdvisorsAddress;
  }

  function changeReserveAddress(address newReserveAddress) public onlyOwner {
    require(reserveAddress != newReserveAddress, "Address already setted");
    reserveAddress = newReserveAddress;
  }

  function changeStakingAddress(address newStakingAddress) public onlyOwner {
    require(stakingAddress != newStakingAddress, "Address already setted");
    stakingAddress = newStakingAddress;
  }

  function changeEcosystemAddress(address newEcosystemAddress) public onlyOwner {
    require(ecosystemAddress != newEcosystemAddress, "Address already setted");
    ecosystemAddress = newEcosystemAddress;
  }

  function changePlayToEarnAddress(address newPlayToEarnAddress) public onlyOwner {
    require(playToEarnAddress != newPlayToEarnAddress, "Address already setted");
    playToEarnAddress = newPlayToEarnAddress;
  }

  function changeDevTokenFeePercent(uint16 newDevTokenFeePercent) public onlyOwner {
    require(devTokenFeePercent != newDevTokenFeePercent, "fee already setted");
    devTokenFeePercent = newDevTokenFeePercent;
  }

  function changeDevBNBFeePercent(uint16 newDevBNBFeePercent) public onlyOwner {
    require(devBNBFeePercent != newDevBNBFeePercent, "fee already setted");
    devBNBFeePercent = newDevBNBFeePercent;
  }

  function changeBuyBackFeePercent(uint16 newBuyBackFeePercent) public onlyOwner {
    require(buyBackFeePercent != newBuyBackFeePercent, "fee already setted");
    buyBackFeePercent = newBuyBackFeePercent;
  }

  function changeLiquidityFeePercent(uint16 newLiquidityFeePercent) public onlyOwner {
    require(liquidityFeePercent != newLiquidityFeePercent, "fee already setted");
    liquidityFeePercent = newLiquidityFeePercent;
  }

  function addPairAddress(address pairAddress) public onlyOwner {
    require(!_isPair[pairAddress], "address is already added");
    _isPair[pairAddress] = true;
  }

  function removePairAddress(address pairAddress) public onlyOwner {
    require(_isPair[pairAddress], "address is already removed");
    _isPair[pairAddress] = false;
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function coreTeamUnlock() public {
    uint256 monthCount = (block.timestamp - contractCreationTime) / MONTH;
    require(monthCount >= 13, "it is too soon to unlock");
    if (monthCount > 36) monthCount = 36;
    uint256 unlockCount = (coreTeamUnlockPerMonth[monthCount - 13] - coreTeamUnlockedTillNow) * TEN_POW_8;
    require(unlockCount > 0, "Now there is no token to unlock");
    _mint(coreTeamAddress, unlockCount);
    coreTeamUnlockedTillNow = coreTeamUnlockPerMonth[monthCount - 13];
  }

  function advisorsUnlock() public {
    uint256 monthCount = (block.timestamp - contractCreationTime) / MONTH;
    require(monthCount >= 2, "it is too soon to unlock");
    if (monthCount > 36) monthCount = 36;
    uint256 unlockCount = (advisorsUnlockPerMonth[monthCount - 2] - advisorsUnlockedTillNow) * TEN_POW_8;
    require(unlockCount > 0, "Now there is no token to unlock");
    _mint(advisorsAddress, unlockCount);
    advisorsUnlockedTillNow = advisorsUnlockPerMonth[monthCount - 2];
  }

  function reserveUnlock() public {
    uint256 monthCount = (block.timestamp - contractCreationTime) / MONTH;
    require(monthCount >= 24, "it is too soon to unlock");
    if (monthCount > 60) monthCount = 60;
    uint256 unlockCount = (reserveUnlockPerMonth[monthCount - 24] - reserveUnlockedTillNow) * TEN_POW_8;
    require(unlockCount > 0, "Now there is no token to unlock");
    _mint(reserveAddress, unlockCount);
    reserveUnlockedTillNow = reserveUnlockPerMonth[monthCount - 24];
  }

  function stakingUnlock() public {
    uint256 monthCount = (block.timestamp - contractCreationTime) / MONTH;
    require(monthCount >= 2, "it is too soon to unlock");
    if (monthCount > 60) monthCount = 60;
    uint256 unlockCount = (stakingUnlockPerMonth[monthCount - 2] - stakingUnlockedTillNow) * TEN_POW_8;
    require(unlockCount > 0, "Now there is no token to unlock");
    _mint(stakingAddress, unlockCount);
    stakingUnlockedTillNow = stakingUnlockPerMonth[monthCount - 2];
  }

  function ecosystemUnlock() public {
    uint256 monthCount = (block.timestamp - contractCreationTime) / MONTH;
    require(monthCount >= 2, "it is too soon to unlock");
    if (monthCount > 45) monthCount = 45;
    uint256 unlockCount = (ecosystemUnlockPerMonth[monthCount - 2] - ecosystemUnlockedTillNow) * TEN_POW_8;
    require(unlockCount > 0, "Now there is no token to unlock");
    _mint(ecosystemAddress, unlockCount);
    ecosystemUnlockedTillNow = ecosystemUnlockPerMonth[monthCount - 2];
  }

  function playToEarnUnlock() public {
    uint256 monthCount = (block.timestamp - contractCreationTime) / MONTH;
    require(monthCount >= 2, "it is too soon to unlock");
    if (monthCount > 60) monthCount = 60;
    uint256 unlockCount = (playToEarnUnlockPerMonth[monthCount - 2] - playToEarnUnlockedTillNow) * TEN_POW_8;
    require(unlockCount > 0, "Now there is no token to unlock");
    _mint(playToEarnAddress, unlockCount);
    playToEarnUnlockedTillNow = playToEarnUnlockPerMonth[monthCount - 2];
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IUniswapV2Router01 } from "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  // solhint-disable-next-line func-name-mixedcase
  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  // solhint-disable-next-line func-name-mixedcase
  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}