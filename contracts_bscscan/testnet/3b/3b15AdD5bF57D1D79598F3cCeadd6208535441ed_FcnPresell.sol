pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract FcnPresell is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Presell Basic
    uint256 private decimals = 18;
    uint256 public presellTotalCount = 0;
    uint256 public presellAmountMax = 50000000000000 * 10 ** decimals;// 50 trillion FCN : 50_0000_0000_0000
    uint256 public presellSingleAmount = 50000000000 * 10 ** decimals;// 50 billion FCN : 500_0000_0000

    // Presell Token
    ERC20 public fcnTokenContract;
    ERC20 public usdtTokenContract;
    ERC20 public bzzoneTokenContract;

    // Presell Account

    

    // ================= Initial value ===============

    constructor () public {
        fcnTokenContract = ERC20(0x3556D913A1813e5F6FCb9b4792643390FA17155b);
        usdtTokenContract = ERC20(0xd5aebC243cc1d7F25c9c71CCD572ABe28C5a8F8b);
        bzzoneTokenContract = ERC20(0x1abe45f37Ba3Eb61ceaC6D3d347e66F43FAaC95e);
    }




}