pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPositionToken.sol";
import "./interfaces/IPosiV2Migrate.sol";

contract PosiRefund is Ownable {
    using SafeMath for uint256;
    IERC20 public posiv2 = IERC20(0x5CA42204cDaa70d5c773946e69dE942b85CA6706);
    IPosiV2Migrate public v2Migrator = IPosiV2Migrate(0x79eaa59D796aa10960bB29917c5daAA641ADDe17);
    IERC20 public busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    mapping(address => uint256) public refundAmountBusdRemaining;
    mapping(address => uint256) public boughtAmountPosi;

    constructor() public {
        refundAmountBusdRemaining[0x012AD2625bc0f2cD40D3E94AeB3B864c515C8370] = 78960924370000000000;
        refundAmountBusdRemaining[0x07969f91aacBAb9C2F48D5A69650ad6eE03c49E3] = 41864370120000000000;
        refundAmountBusdRemaining[0x090F2897ebBe153518AAf66fB0753B62636da5A5] = 299297050000000000;
        refundAmountBusdRemaining[0x0E8F793CF2176bc9879E22458070Cf310758E50F] = 282709186930000000000;
        refundAmountBusdRemaining[0x10DaC1a6B7b3fD29BFB2F1a96a322D7e42e999d7] = 25698947010000000000;
        refundAmountBusdRemaining[0x11942CB2453EE9a31742b55A59c776F5482Dd0Ba] = 55058752320000000000;
        refundAmountBusdRemaining[0x219574ABeF52f0407b598DBCd8E8c6aFB5677777] = 38905196330000000000;
        refundAmountBusdRemaining[0x22ABA39BDD0D01701F934445C9e0f79e7Dd39c26] = 88086389040000000000;
        refundAmountBusdRemaining[0x2728f8dFeEcA7C0Dea02DE4A201D0BD513388160] = 62785736590000000000;
        refundAmountBusdRemaining[0x2944fF2BE95A28Af6f2AE912BDB321472dC5AF73] = 93644460280000000000;
        refundAmountBusdRemaining[0x2a133438f7E2630FfD4E1A5b5b3556BeE8bFCeDF] = 298995727800000000000;
        refundAmountBusdRemaining[0x2C17100548aDD626738E3227533b0A4E2410701d] = 5972095380000000000;
        refundAmountBusdRemaining[0x2D786aB859b806efC3f8a8647c60c54d7eA1Da35] = 89694523060000000000;
        refundAmountBusdRemaining[0x2e2ed5Fdc9Bc87ab2cb7015a4B4285b87F0688Cc] = 119706933210000000000;
        refundAmountBusdRemaining[0x34aA659b30c3497Bf520db691B2F5C139a6A58De] = 29919425560000000000;
        refundAmountBusdRemaining[0x3511748c00b6B2dD9f77c1141ceC9C0BD7ADA5bE] = 30000000000000000000;
        refundAmountBusdRemaining[0x370e01C941915Bcf9F3f1d19012986dc5f999AdC] = 44886160040000000000;
        refundAmountBusdRemaining[0x388146509f956a3834BA35C6Cf233644d95Af2DA] = 59219539800000000000;
        refundAmountBusdRemaining[0x388eA7189e68F6b84ccA08642303E08eF13F71db] = 1929200000000000000000;
        refundAmountBusdRemaining[0x4B084364E6A641c75D589fDC211a94236188d06C] = 134372433990000000000;
        refundAmountBusdRemaining[0x4cA6D4ADDcbF6B0677DA930d5cA76B9dE1276C4f] = 79000000000000000000;
        refundAmountBusdRemaining[0x4EE7290a442bE8Ba264538F4cD12d4cd8125c1b1] = 5000000000000000000;
        refundAmountBusdRemaining[0x523Cdf3AD03b7000c4D7DEcA898d0e94424A737D] = 14949157290000000000;
        refundAmountBusdRemaining[0x59e94A5ff14cBeeFf1E4C4D656417E7F06f46865] = 5193942050000000000;
        refundAmountBusdRemaining[0x685C5C7817a27c2e65Aa8383514eDECB898C8888] = 303458181890000000000;
        refundAmountBusdRemaining[0x6C096cAC52Ddefd7A6996f9030DCf3083f366F2b] = 29924390200000000000;
        refundAmountBusdRemaining[0x6c50686cb8024C23F76d723b533110580DC629eE] = 1688795916010000000000;
        refundAmountBusdRemaining[0x705aE65c473A02ab044238DEAd6813e37B0f1d22] = 69141116310000000000;
        refundAmountBusdRemaining[0x7291cE2484664D71933bc89f58a03F5428fa4d38] = 16730454810000000000;
        refundAmountBusdRemaining[0x735DAef846D060f674B1f66fa58f7041b8943a38] = 1961379045280000000000;
        refundAmountBusdRemaining[0x82420FC757d5bd13273f0495cb221270145EE1e1] = 50126533190000000000;
        refundAmountBusdRemaining[0x83b68758DAB7b7bF657d7108530942726196edB1] = 14633213800000000000;
        refundAmountBusdRemaining[0x89Bb80B57a27fd30F00B47071c8344D9fCA781e9] = 136288576570000000000;
        refundAmountBusdRemaining[0x8Dc07aD4d08260891E25516fC62af44301dd2B24] = 299296193330000000000;
        refundAmountBusdRemaining[0x8eDB39eFEA3a24e109FCf939C397368DFAf7Dc89] = 59721586320000000000;
        refundAmountBusdRemaining[0x9702b4a8C71bcf385D622949b5D2acc4b2B93926] = 90933447290000000000;
        refundAmountBusdRemaining[0x99d0315bC4a3f1F3d43f6d14235293bD81bd9577] = 4124910240000000000;
        refundAmountBusdRemaining[0x9DE26201F3Be0a7d600F3676eC6bb4c09fe35F7C] = 2991944400000000000;
        refundAmountBusdRemaining[0xA20CeabdCd3f1B6c83F76B4d015B64E1B7EF2C15] = 2292729440000000000;
        refundAmountBusdRemaining[0xA56b686eF814aFA3a2E4c7bFD231B143F18DF607] = 195772000000000000000;
        refundAmountBusdRemaining[0xAae90FF872B812dE063ae23a6386c12A88Fee494] = 29928119260000000000;
        refundAmountBusdRemaining[0xb0c8EA92d6C02c64D752c692017AdEE1A9aa9E87] = 2067947490000000000;
        refundAmountBusdRemaining[0xb668CbAd3b1446c63e0c30F6fF7F450888C7Aa2c] = 9876281900000000000;
        refundAmountBusdRemaining[0xbb69288c0E1796280C6718F250D80C2E01a24449] = 14962234980000000000;
        refundAmountBusdRemaining[0xBC64c54676BfAf58300580bE06ABf82D39B5a7f0] = 3124388390000000000;
        refundAmountBusdRemaining[0xC295002BDb3dFA68dA5f5eE4D0a72D65EED09afd] = 2500000000000000000;
        refundAmountBusdRemaining[0xC4CaA965702B707b8f0d79eec761754d47fb1704] = 5082857960000000000;
        refundAmountBusdRemaining[0xC5f2A9725Debfe1c556b55AE373333D44f9A3771] = 8958197140000000000;
        refundAmountBusdRemaining[0xC7B762C33D4811f75800852130260A5a599815a2] = 50000000000000000000;
        refundAmountBusdRemaining[0xC9e0b6eF103AE7869fC3deA94422937c90d9d278] = 14962221760000000000;
        refundAmountBusdRemaining[0xCB0De7454f74D014BfdFF8aB311B053Eb6cF503A] = 2950173040000000000;
        refundAmountBusdRemaining[0xdA615ED924F355De9616015Fca640Be60c81473B] = 504758935060000000000;
        refundAmountBusdRemaining[0xDA618A97d9F97c3e3CcD2aC9c6e4AB4419434A08] = 59702706290000000000;
        refundAmountBusdRemaining[0xE6C67E7541b04Ab965284cC2c694dda7E6840AB4] = 300000000000000000000;
        refundAmountBusdRemaining[0xe951dB6ca544164E131c271993368103FD76796A] = 3170681290000000000;
        refundAmountBusdRemaining[0xEcfaFa726ae5eAD74Fc55CC0D4eD16429D3c205A] = 11099600000000000000;
        refundAmountBusdRemaining[0xf001B02B38f887C3F90eC8a502Fe5E970A5f027F] = 11945445260000000000;
        refundAmountBusdRemaining[0xFe65bd3Ee84B175CEF44ADa06e2d985FF04a2958] = 11827459090000000000; 
        boughtAmountPosi[0x012AD2625bc0f2cD40D3E94AeB3B864c515C8370] = 297000000000000000000;
        boughtAmountPosi[0x07969f91aacBAb9C2F48D5A69650ad6eE03c49E3] = 152027559420000000000;
        boughtAmountPosi[0x090F2897ebBe153518AAf66fB0753B62636da5A5] = 1375525270000000000;
        boughtAmountPosi[0x0E8F793CF2176bc9879E22458070Cf310758E50F] = 1197025625750000000000;
        boughtAmountPosi[0x10DaC1a6B7b3fD29BFB2F1a96a322D7e42e999d7] = 98372164740000000000;
        boughtAmountPosi[0x11942CB2453EE9a31742b55A59c776F5482Dd0Ba] = 198000000000000000000;
        boughtAmountPosi[0x219574ABeF52f0407b598DBCd8E8c6aFB5677777] = 167852908250000000000;
        boughtAmountPosi[0x22ABA39BDD0D01701F934445C9e0f79e7Dd39c26] = 373230990000000000000;
        boughtAmountPosi[0x2728f8dFeEcA7C0Dea02DE4A201D0BD513388160] = 223257491270000000000;
        boughtAmountPosi[0x2944fF2BE95A28Af6f2AE912BDB321472dC5AF73] = 357864654050000000000;
        boughtAmountPosi[0x2a133438f7E2630FfD4E1A5b5b3556BeE8bFCeDF] = 1082667998690000000000;
        boughtAmountPosi[0x2C17100548aDD626738E3227533b0A4E2410701d] = 21774303990000000000;
        boughtAmountPosi[0x2D786aB859b806efC3f8a8647c60c54d7eA1Da35] = 319834703740000000000;
        boughtAmountPosi[0x2e2ed5Fdc9Bc87ab2cb7015a4B4285b87F0688Cc] = 508655768330000000000;
        boughtAmountPosi[0x34aA659b30c3497Bf520db691B2F5C139a6A58De] = 118763015460000000000;
        boughtAmountPosi[0x3511748c00b6B2dD9f77c1141ceC9C0BD7ADA5bE] = 134752168960000000000;
        boughtAmountPosi[0x370e01C941915Bcf9F3f1d19012986dc5f999AdC] = 188810805010000000000;
        boughtAmountPosi[0x388146509f956a3834BA35C6Cf233644d95Af2DA] = 247500000000000000000;
        boughtAmountPosi[0x388eA7189e68F6b84ccA08642303E08eF13F71db] = 8327828455000000000000;
        boughtAmountPosi[0x4B084364E6A641c75D589fDC211a94236188d06C] = 492320399110000000000;
        boughtAmountPosi[0x4cA6D4ADDcbF6B0677DA930d5cA76B9dE1276C4f] = 283396268550000000000;
        boughtAmountPosi[0x4EE7290a442bE8Ba264538F4cD12d4cd8125c1b1] = 20832936150000000000;
        boughtAmountPosi[0x523Cdf3AD03b7000c4D7DEcA898d0e94424A737D] = 53534322330000000000;
        boughtAmountPosi[0x59e94A5ff14cBeeFf1E4C4D656417E7F06f46865] = 20631003360000000000;
        boughtAmountPosi[0x685C5C7817a27c2e65Aa8383514eDECB898C8888] = 1366840749920000000000;
        boughtAmountPosi[0x6C096cAC52Ddefd7A6996f9030DCf3083f366F2b] = 124843372730000000000;
        boughtAmountPosi[0x6c50686cb8024C23F76d723b533110580DC629eE] = 6368729367500000000000;
        boughtAmountPosi[0x705aE65c473A02ab044238DEAd6813e37B0f1d22] = 271216880220000000000;
        boughtAmountPosi[0x7291cE2484664D71933bc89f58a03F5428fa4d38] = 59768234480000000000;
        boughtAmountPosi[0x735DAef846D060f674B1f66fa58f7041b8943a38] = 9967141008330000000000;
        boughtAmountPosi[0x82420FC757d5bd13273f0495cb221270145EE1e1] = 179293350060000000000;
        boughtAmountPosi[0x83b68758DAB7b7bF657d7108530942726196edB1] = 61480606170000000000;
        boughtAmountPosi[0x89Bb80B57a27fd30F00B47071c8344D9fCA781e9] = 1815743270070000000000;
        boughtAmountPosi[0x8Dc07aD4d08260891E25516fC62af44301dd2B24] = 1281887757920000000000;
        boughtAmountPosi[0x8eDB39eFEA3a24e109FCf939C397368DFAf7Dc89] = 235789880240000000000;
        boughtAmountPosi[0x9702b4a8C71bcf385D622949b5D2acc4b2B93926] = 360066137410000000000;
        boughtAmountPosi[0x99d0315bC4a3f1F3d43f6d14235293bD81bd9577] = 14850000000000000000;
        boughtAmountPosi[0x9DE26201F3Be0a7d600F3676eC6bb4c09fe35F7C] = 11868614600000000000;
        boughtAmountPosi[0xA20CeabdCd3f1B6c83F76B4d015B64E1B7EF2C15] = 9900000000000000000;
        boughtAmountPosi[0xA56b686eF814aFA3a2E4c7bFD231B143F18DF607] = 880583804470000000000;
        boughtAmountPosi[0xAae90FF872B812dE063ae23a6386c12A88Fee494] = 129313856560000000000;
        boughtAmountPosi[0xb0c8EA92d6C02c64D752c692017AdEE1A9aa9E87] = 7920000000000000000;
        boughtAmountPosi[0xb668CbAd3b1446c63e0c30F6fF7F450888C7Aa2c] = 42707926030000000000;
        boughtAmountPosi[0xbb69288c0E1796280C6718F250D80C2E01a24449] = 62366191710000000000;
        boughtAmountPosi[0xBC64c54676BfAf58300580bE06ABf82D39B5a7f0] = 11096373230000000000;
        boughtAmountPosi[0xC295002BDb3dFA68dA5f5eE4D0a72D65EED09afd] = 96201745480000000000;
        boughtAmountPosi[0xC4CaA965702B707b8f0d79eec761754d47fb1704] = 18301794010000000000;
        boughtAmountPosi[0xC5f2A9725Debfe1c556b55AE373333D44f9A3771] = 32184839930000000000;
        boughtAmountPosi[0xC7B762C33D4811f75800852130260A5a599815a2] = 182565289320000000000;
        boughtAmountPosi[0xC9e0b6eF103AE7869fC3deA94422937c90d9d278] = 62328637140000000000;
        boughtAmountPosi[0xCB0De7454f74D014BfdFF8aB311B053Eb6cF503A] = 113430898020000000000;
        boughtAmountPosi[0xdA615ED924F355De9616015Fca640Be60c81473B] = 1920298230490000000000;
        boughtAmountPosi[0xDA618A97d9F97c3e3CcD2aC9c6e4AB4419434A08] = 223710862720000000000;
        boughtAmountPosi[0xE6C67E7541b04Ab965284cC2c694dda7E6840AB4] = 1065534284980000000000;
        boughtAmountPosi[0xe951dB6ca544164E131c271993368103FD76796A] = 13385867300000000000;
        boughtAmountPosi[0xEcfaFa726ae5eAD74Fc55CC0D4eD16429D3c205A] = 40482050470000000000;
        boughtAmountPosi[0xf001B02B38f887C3F90eC8a502Fe5E970A5f027F] = 42975844870000000000;
        boughtAmountPosi[0xFe65bd3Ee84B175CEF44ADa06e2d985FF04a2958] = 42570000000000000000;
    }

    function refund(bool isReceivePosi) public {
        uint amount = refundAmountBusdRemaining[msg.sender];
        require(amount > 0, "invalid amount");
        if(isReceivePosi){
            amount = amount.mul(2); // RATE: 1 POSI = 0.5 BUSD
        }
        if(v2Migrator.isMigrated(msg.sender)){
            uint posiAmount = boughtAmountPosi[msg.sender].mul(10**18).div(v2Migrator.convertRate());
            posiv2.transferFrom(msg.sender, address(this), posiAmount);
        }else{
            v2Migrator.setIsMigrated(msg.sender, true);
        }
        if(isReceivePosi){
            posiv2.transfer(msg.sender, amount);
        }else{
            busd.transfer(msg.sender, amount);
        }
        refundAmountBusdRemaining[msg.sender] = 0;
    }

    function changeRefundAmount(address account, uint256 amountBUSD, uint256 amountPOSI) public onlyOwner {
        refundAmountBusdRemaining[account] = amountBUSD;
        boughtAmountPosi[account] = amountPOSI;
    }
    
    function transferOut(IERC20 token, address recipient, uint256 amount) public onlyOwner {
        token.transfer(recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

pragma solidity ^0.8.0;

interface IPositionToken {
    function BASE_MINT() external view returns (uint256);
    function mint(address receiver, uint256 amount) external;
    function burn(uint amount) external;
    function treasuryTransfer(address[] memory recipients, uint256[] memory amounts) external;
    function treasuryTransfer(address recipient, uint256 amount) external;
    function transferTaxRate() external view returns (uint16) ;
    function balanceOf(address account) external view returns (uint256) ;
    function transfer(address to, uint value) external returns (bool);
    function isGenesisAddress(address account) external view returns (bool);
}

interface IPosiV2Migrate {
    function isMigrated(address account) external view returns (bool);
    function convertRate() external view returns (uint256);
    function setIsMigrated(address account, bool value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

