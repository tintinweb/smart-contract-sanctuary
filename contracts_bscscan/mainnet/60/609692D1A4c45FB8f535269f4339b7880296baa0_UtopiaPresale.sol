/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

interface IERC20 {

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function decimals() external view returns (uint8);

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



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract UtopiaPresale {
  using SafeMath for uint256;

  // The token being sold
  IERC20 public token;

  // How many token units a buyer gets per wei
  uint256 public bnbUtopiaRate;

  // Amount of wei raised
  uint256 public weiRaised;

  // Admin address
  address payable private admin;

  // Map of purchase states
  mapping(address => uint256) public purchasedBnb;

  // List of Token purchasers
  address[] public purchaserList;

  // Maximum amount of BNB each account is allowed to buy
  mapping (address => uint256) private bnbAllowanceForUser;

  // Finalization state
  bool public finalized;

  uint256 public openingTime;

  uint256 public tokensAlreadyPurchased;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param bnbValue weis paid for purchase
   * @param tokens amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 bnbValue,
    uint256 tokens
  );

  /**
   * Event for token withdrawal
   * @param withdrawer who withdrew the tokens
   * @param tokens amount of tokens purchased
   */
  event TokenWithdrawal(
    address indexed withdrawer,
    uint256 tokens
  );

  event CrowdsaleFinalized();

  /**
   * @param _bnbUtopiaRate Number of token units a buyer gets per wei
   * @param _token Address of the token being sold
   */
  constructor(uint256 _bnbUtopiaRate, IERC20 _token, uint256 _openingTime) public {
    // Rate should be 350 billion UTP = 600 BNB
    require(_bnbUtopiaRate > 0);
    require(_token != IERC20(address(0)));

    bnbUtopiaRate = _bnbUtopiaRate;
    token = _token;
    admin = msg.sender;
    finalized = false;
    openingTime = _openingTime;

    bnbAllowanceForUser[0x8aC129cb9F87ce4208F4AeB639d223f9E87aedC4] = 2000000000000000000;
    bnbAllowanceForUser[0xAD854532e2a57382C39DBfF65C1E77cfff7a0b23] = 2000000000000000000;
    bnbAllowanceForUser[0xcCB3514dDD0A01dE08cE8edB1Be50f5ca9c5d279] = 2000000000000000000;
    bnbAllowanceForUser[0x3ff72E1c9125Dc0f689b505Db245664D8bc53de5] = 2000000000000000000;
    bnbAllowanceForUser[0xaF2FEE49F1f2b37aE67edCb2344A71F8EF119b20] = 2000000000000000000;
    bnbAllowanceForUser[0xc4bE03BF0919975871cee2613B18771b6AD2AdB4] = 2000000000000000000;
    bnbAllowanceForUser[0x960529a501b3981a972E55FC0b47880Cde04116c] = 2000000000000000000;
    bnbAllowanceForUser[0xe025914c34933ad4D506c16d453bFD3D2bBfbe04] = 2000000000000000000;
    bnbAllowanceForUser[0x316a2e3ED5Dc30E66eA66a6Dad78C3140269F69D] = 2000000000000000000;
    bnbAllowanceForUser[0x957BD103C6788DBfd4597797A6ab0Ec3cA366BF9] = 2000000000000000000;
    bnbAllowanceForUser[0x9f8bB7FB2581141DA6aE31fE0826929Be2f0f35a] = 2000000000000000000;
    bnbAllowanceForUser[0x2FFFf4B662440F8076EFfD6385A44EdBaB1A7f93] = 2000000000000000000;
    bnbAllowanceForUser[0x1e8ec7449DECA331e6d30AB18F607A34d1987dA7] = 2000000000000000000;
    bnbAllowanceForUser[0xdd6F6642Ff30E0850A4FF69AD17E54fbF87DB37B] = 2000000000000000000;
    bnbAllowanceForUser[0x029bC0357E9Fffdd9f832F5e460d4830Eac74044] = 2000000000000000000;
    bnbAllowanceForUser[0x668CB66e452C3380959dB7c5861B297F68DcCB4C] = 2000000000000000000;
    bnbAllowanceForUser[0x6365CC4e49F2803749b36AF23A3C09Bf3dE1e59D] = 2000000000000000000;
    bnbAllowanceForUser[0x96dFcfD671e5E68c89bA31cBB128AA1F3B307963] = 2000000000000000000;
    bnbAllowanceForUser[0xC22f8A2DA31e2444D97A3422d85bAcf5d96198EB] = 2000000000000000000;
    bnbAllowanceForUser[0x55A0bd60a0858f05fB73eeFd9DB9E805394777E9] = 2000000000000000000;
    bnbAllowanceForUser[0x5EdC4f203FD1E0b1F5450FBA5dC90DAc87df09Df] = 2000000000000000000;
    bnbAllowanceForUser[0x5A56c5163B7674A936A59aa292B7CC90920FC117] = 2000000000000000000;
    bnbAllowanceForUser[0x2D23b731e5F04996A2Dfdbe434c7D922aFdb5E00] = 2000000000000000000;
    bnbAllowanceForUser[0xbd96B01A8d8BD30917b31d8BbB83c1786854F95B] = 2000000000000000000;
    bnbAllowanceForUser[0x02BDa79D6243B938d2Be5486Ed8ca9627dabf0c1] = 2000000000000000000;
    bnbAllowanceForUser[0xcA7C095c60831CCbFA481B5671eBB073bc485CDa] = 2000000000000000000;
    bnbAllowanceForUser[0xBdD243c081f3C5CEC78D2114517B3903D0fC9Cbd] = 2000000000000000000;
    bnbAllowanceForUser[0x109AB66eC2bF2916a8727F6e3b4af8750aB5de87] = 2000000000000000000;
    bnbAllowanceForUser[0x627C70dfa5De161a5BcE830F304CAc0685250714] = 2000000000000000000;
    bnbAllowanceForUser[0x0E7C4ca879ec97aB01707578f7D3414643bc58B7] = 2000000000000000000;
    bnbAllowanceForUser[0xd6225096fF3D34d305F680a99E7e85a684c21996] = 2000000000000000000;
    bnbAllowanceForUser[0x88d5aaf9ebDEA2b79f644948d60E2C25971A91d1] = 2000000000000000000;
    bnbAllowanceForUser[0x4E918885404909a1206C54316aF628B6654dC419] = 2000000000000000000;
    bnbAllowanceForUser[0x3adfbbe85e8F5a32076a3D89F2613482EAC3AC6e] = 2000000000000000000;
    bnbAllowanceForUser[0x151BeA96E4AeD5F6a22Aa8d4d52CA4A703E68754] = 2000000000000000000;
    bnbAllowanceForUser[0x3382655720937A94C9928263c0f09F025FcDED59] = 2000000000000000000;
    bnbAllowanceForUser[0x551AacBfB25a0448a72045d64673f38E06E6E65a] = 2000000000000000000;
    bnbAllowanceForUser[0x5CddE5b4Ec3Eca937236e641eB58819Dbc48187B] = 2000000000000000000;
    bnbAllowanceForUser[0x9226C35C9d5B79D93aF3A81081bB4E899e42362C] = 2000000000000000000;
    bnbAllowanceForUser[0x6AcBc82335643731ee735f579A5cEE21646a6874] = 2000000000000000000;
    bnbAllowanceForUser[0x22DDeADaB8068B9AD92F514d6BE4b39a11efc650] = 2000000000000000000;
    bnbAllowanceForUser[0x24240de0b4EB3D3ae6A2d6bAFA1AaB88D8E9cD79] = 2000000000000000000;
    bnbAllowanceForUser[0xC526a7407B30b116A4F217D13BC6Bc0f2462bF5D] = 2000000000000000000;
    bnbAllowanceForUser[0xBF4cF99167d00805B77C41BdeA38230d0Ffad3E8] = 2000000000000000000;
    bnbAllowanceForUser[0xf6cF3C2B03DA04bC81aaC206E12eba42e40c0b3A] = 2000000000000000000;
    bnbAllowanceForUser[0x6D458efE37DE587a4A6A22818c22EA63C77b10d5] = 2000000000000000000;
    bnbAllowanceForUser[0x00dED6dDa1643E9b88C9Eb939DDc0f5e2fbAc021] = 2000000000000000000;
    bnbAllowanceForUser[0x83F0Ef4381Fc2490c0d1C9Fc2165E2252e2bCC7a] = 2000000000000000000;
    bnbAllowanceForUser[0x715556C8B35f05d98Ef5081E2c92b884Eb879E25] = 2000000000000000000;
    bnbAllowanceForUser[0x110642964B2a90b102E0b1b03349b01Df0bBC854] = 2000000000000000000;
    bnbAllowanceForUser[0xC65D8f41fA754308F99944c2d313cC6F993bCb6C] = 2000000000000000000;
    bnbAllowanceForUser[0x965335F50ddb0d7Adf8189b4D4a7bfD1AE4275B4] = 2000000000000000000;
    bnbAllowanceForUser[0x68933829b633036EECEE06fa19f6e4539f2A15A2] = 2000000000000000000;
    bnbAllowanceForUser[0x69523d6FC0625E605a620340bFfE7FE0eD867c81] = 2000000000000000000;
    bnbAllowanceForUser[0xD365752F06e0Afc9E665260d9B264Ac347743020] = 2000000000000000000;
    bnbAllowanceForUser[0x0d87b7A8ADF76387A030787a4B5ffe4deC5a1F87] = 2000000000000000000;
    bnbAllowanceForUser[0x9D6D09Ff99707b8D5be69920B868DF365B6dBeb3] = 2000000000000000000;
    bnbAllowanceForUser[0x0ee2Ee5e0513A9Bb22f64976e19df8E658900279] = 2000000000000000000;
    bnbAllowanceForUser[0x313F8F7396AC2BaA0D9a56A56B1F0fEbd4BeE546] = 2000000000000000000;
    bnbAllowanceForUser[0x80DDfCE09A41D2DAce3355307323Ec31E4f8A011] = 2000000000000000000;
    bnbAllowanceForUser[0x468362aE52c1bF2CFbB3b98f8859dF5c14423Cab] = 2000000000000000000;
    bnbAllowanceForUser[0x2fb5a0D020F516F44996848911E3C30A2B399E33] = 2000000000000000000;
    bnbAllowanceForUser[0xb7a6eBA398A7F45B0382B5eC6E3Dbd2E757427E6] = 2000000000000000000;
    bnbAllowanceForUser[0x4a09D4CaA2784DA525BB0335F0f2E4b767cE05a3] = 2000000000000000000;
    bnbAllowanceForUser[0x6357859d53073d8861b83f9f6ef13f8D828d16cE] = 2000000000000000000;
    bnbAllowanceForUser[0x5cd82E9f83963652304E7F43Be7c785D2c8AfB6D] = 2000000000000000000;
    bnbAllowanceForUser[0x3caA9204C1bA8C098788388E1f18F2D40cfb88B8] = 2000000000000000000;
    bnbAllowanceForUser[0x1c4B924E3c3a0F908DB5852A4E16ac166165CF64] = 2000000000000000000;
    bnbAllowanceForUser[0x2a4d7651c9A68CfD1bff794F1064dF581528362d] = 2000000000000000000;
    bnbAllowanceForUser[0x8176A62865AF60874eab7e8e345Ee0e9d1640448 ] = 2000000000000000000;
    bnbAllowanceForUser[0x681C1DE8666215264C03749f22c8168da63A532a] = 2000000000000000000;
    bnbAllowanceForUser[0x9d17E542eA5F543c0e06F1BCBAC8c17dFA7D32D7] = 2000000000000000000;
    bnbAllowanceForUser[0xF7F42714B0Dc546A7aAc4a037A479ce0f307fc25] = 2000000000000000000;
    bnbAllowanceForUser[0xeDDB6cB02E0bc3c8f3413c065E5cf327C3776573] = 2000000000000000000;
    bnbAllowanceForUser[0x0AE4fEB4aBa6e353055469b7211f7843D80D7519] = 2000000000000000000;
    bnbAllowanceForUser[0x6Cf115c9c6EF5a8ceF7666744CAcEDe78ED95C4a] = 2000000000000000000;
    bnbAllowanceForUser[0x182E40B86Cd7c3a914873147CDf9ff5472eB2B5d] = 2000000000000000000;
    bnbAllowanceForUser[0x2a4d7651c9A68CfD1bff794F1064dF581528362d] = 2000000000000000000;
    bnbAllowanceForUser[0x82267959e68EB59D4f5aA2bE05b96A4425744D38] = 2000000000000000000;
    bnbAllowanceForUser[0x063441E1ca2b01AD6389f4dEa876863e5A16a675] = 2000000000000000000;
    bnbAllowanceForUser[0x86f83AfD5dFC9C78DDE8499dbB17Fb925fBb419d] = 2000000000000000000;
    bnbAllowanceForUser[0x9268537eA78b64E07D12faf120ef215d4B708d59] = 2000000000000000000;
    bnbAllowanceForUser[0x72b4E070D325992b2AbE9b582Ba07606A7d04f29] = 2000000000000000000;
    bnbAllowanceForUser[0x04ca2C4161CFDDA1c11F90c8b3B31af366009983] = 2000000000000000000;
    bnbAllowanceForUser[0x876a69bfce38C957E7436397EbDB1250C3CCaC4f] = 2000000000000000000;
    bnbAllowanceForUser[0x2E2AcA121a8C6389Af4c42ab43aC1C5BEB9E8512] = 2000000000000000000;
    bnbAllowanceForUser[0xF4E4231E93cC815871e059F8999a3CabD68284Bd] = 2000000000000000000;
    bnbAllowanceForUser[0x7f27C34eC3CAC4baE99690D70aca7F9E49a401E0] = 2000000000000000000;
    bnbAllowanceForUser[0xa770c5F508dd2d5905e0fAB37D30fa724c1B8A2c] = 2000000000000000000;
    bnbAllowanceForUser[0x02a3407dA1b7ec2b775869b59B8E59bA95326158] = 2000000000000000000;
    bnbAllowanceForUser[0xC24aC8BE75B0247332aB8be17730941332801A39] = 2000000000000000000;
    bnbAllowanceForUser[0xAf278975af7341f600be86A507D94911Bc61C628] = 2000000000000000000;
    bnbAllowanceForUser[0xe875A8d0885F40E132Ff48E9485106d08fDC7bA5] = 2000000000000000000;
    bnbAllowanceForUser[0x4b3aF8f7B0Fffaccd79D42aD7826404a0f7bdC80] = 2000000000000000000;
    bnbAllowanceForUser[0x5D031Ba9B74e0F249CE2039295e0cce0608A501b] = 2000000000000000000;
    bnbAllowanceForUser[0xfc1d08f3C74Bdb6ee5aFFfdAbD8a86b2C6065D52] = 2000000000000000000;
    bnbAllowanceForUser[0x61AFEB68eb87b762562934E26050d703e5f5aC5d] = 2000000000000000000;
    bnbAllowanceForUser[0x3A1595Ac39b17973D7bC6A69c0385876B8C20ac1] = 2000000000000000000;
    bnbAllowanceForUser[0x7C7cAe7a908D3C8156Bb6Ce8FC0c92916bBA1324] = 1000000000000000000;
    bnbAllowanceForUser[0x77699C32a30662DA113a3d79dC664605fE2e3CBA] = 1000000000000000000;
    bnbAllowanceForUser[0x6Af96a04037D75d9F23212F5cAd8E0597A45f01F] = 1000000000000000000;
    bnbAllowanceForUser[0x6AB2afBD6126F53bB4B4f5b7395b3CD3189F302D] = 1000000000000000000;
    bnbAllowanceForUser[0x2087a5af7fAb8EB38C5b50FdD752fe37510a13bb] = 1000000000000000000;
    bnbAllowanceForUser[0x2d31aA092d63b8f7C8A0aCAe50017d809f9F4C4e] = 1000000000000000000;
    bnbAllowanceForUser[0xa9DF17C231E938F16540ef75ECD8733460b9Fc4B] = 1000000000000000000;
    bnbAllowanceForUser[0x064161cEa881eA764A9356133B9c6E73B3b3299D] = 1000000000000000000;
    bnbAllowanceForUser[0x6fD40AE5626847d4Ac0FF4d2D8b41EB53Bb03A74] = 1000000000000000000;
    bnbAllowanceForUser[0xeB068E281aa8C5512c023424b5C1DEE0569B6B97] = 1000000000000000000;
    bnbAllowanceForUser[0xF9f57E6e6d26692EeD673b357a897bC9f3fC2ADe] = 1000000000000000000;
    bnbAllowanceForUser[0xcbBF92074b8DD7987e30859161eE1b78450035eA] = 1000000000000000000;
    bnbAllowanceForUser[0xeE916c7ac85b3313C153042Ef58F228ebd51ca40] = 1000000000000000000;
    bnbAllowanceForUser[0x2a4d7651c9A68CfD1bff794F1064dF581528362d] = 1000000000000000000;
    bnbAllowanceForUser[0x035AEa40df83EB8Cf6EF4e82ac3D13Aa16434719] = 1000000000000000000;
    bnbAllowanceForUser[0x24BC7357362cE96a0D38eC64f3216147A5AF8E54] = 1000000000000000000;
    bnbAllowanceForUser[0x50Aa04b64296ADE23DdB4Fa3aEE6e0f3Aa23E497] = 1000000000000000000;
    bnbAllowanceForUser[0x4CA55136d943CF0245F0147bD29291807CEA8412] = 1000000000000000000;
    bnbAllowanceForUser[0x3dE9AAa1c942b32900ab892558D4c0a463a6138C] = 1000000000000000000;
    bnbAllowanceForUser[0x36c3fa0Bd49635aFCc4Ed3115B19d4d38edDa456] = 1000000000000000000;
    bnbAllowanceForUser[0x8CAc449b052EBB35A3cFAb552709571Ab4c9E81B] = 1000000000000000000;
    bnbAllowanceForUser[0x40D5a0AB1F94F561f37f72731055F30d1fcD9cfa] = 1000000000000000000;
    bnbAllowanceForUser[0xB4DA1673dB21f42DaDD74Df3E02A85868A6da520] = 1000000000000000000;
    bnbAllowanceForUser[0xcBC4025B8d8063cbD931e4cf6836FdeCd0eBf96c] = 1000000000000000000;
    bnbAllowanceForUser[0x7d3eDa39Baa6FA9ddE62a05ab8ab6a34E861c775] = 1000000000000000000;
    // bnbAllowanceForUser[0xdc5d3dbf92af83f9c0081e0d543d673cc5d84354] = 1000000000000000000;
    bnbAllowanceForUser[0x9984128A70C8Ad5e14490D02f118671684b93578] = 1000000000000000000;
    bnbAllowanceForUser[0x46f93aF853aEb249cC2aC39f7BA76E2F3E68c4Bf] = 1000000000000000000;
    bnbAllowanceForUser[0xCA7B40786894aA3886fcb932709B533587f9E0E6] = 1000000000000000000;
    bnbAllowanceForUser[0x672f84b121119A2d5F3840d5b76b7dAb7361982C] = 1000000000000000000;
    bnbAllowanceForUser[0xAc7ce448e5C4d71535593825A17b0C91455d74AC] = 1000000000000000000;
    bnbAllowanceForUser[0xdc24dCEa38A3b810e6606689aE3FC25A32567c75] = 1000000000000000000;
    bnbAllowanceForUser[0x261867ac2ed1fffCf29ab60D1020065388a73EC3] = 1000000000000000000;
    bnbAllowanceForUser[0x2570946F3982f6082BFAB83AbCd6Cf7a9a2Aa975] = 1000000000000000000;
    bnbAllowanceForUser[0x1ABf00d4DF7d5894e7879CE23560981D3A68dFda] = 1000000000000000000;
    bnbAllowanceForUser[0x8c8E26934663ffE6BF4acB18C341C837c4D57c08] = 1000000000000000000;
    bnbAllowanceForUser[0x512e76E4A2e5ED31e9F4f4eEF05cd210832A53e4] = 1000000000000000000;
    bnbAllowanceForUser[0x388098aD0DcE41226A0Db6F5D6403693cf7700Db] = 1000000000000000000;
    bnbAllowanceForUser[0x4Af06c8F65454f11350f1638527b59455F5B9B22] = 1000000000000000000;
    bnbAllowanceForUser[0xBc528f1ab0D8D027b51302e61352EE0f737Ebc60] = 1000000000000000000;
    bnbAllowanceForUser[0xc0b2139dfDFc24AA8C184B6580071736cE3A0c8E] = 1000000000000000000;
    bnbAllowanceForUser[0x6750AB03c5C66513731aee42bB76d1772542E0bf] = 1000000000000000000;
    bnbAllowanceForUser[0xf3d08683e9A205Cd0b89CbCC566cB498A26B4c75] = 1000000000000000000;
    bnbAllowanceForUser[0x79c118c196BE792e77E3b537E491c8494799031A] = 1000000000000000000;
    bnbAllowanceForUser[0x7192A2238cea420586a4C0967aBeE3C1935AB360] = 1000000000000000000;
    bnbAllowanceForUser[0x99cAa47532C0f7428AA475D21e7dE9c6CCD9df51] = 1000000000000000000;
    bnbAllowanceForUser[0x7C95E4711Ec88b63fb7eDbD2878fe1EFC5755790] = 1000000000000000000;
    bnbAllowanceForUser[0x6913e16DCB3833b51dBf4D861A0c2B40346b8579 ] = 1000000000000000000;
    bnbAllowanceForUser[0x4b40B61b6585F017f313A65662Cf38204664Dc84] = 1000000000000000000;
    bnbAllowanceForUser[0x468dFe4B9AcA9cCE636969a9370487E9C17402e6] = 1000000000000000000;
    bnbAllowanceForUser[0x9246f44F04E4Ca00011361BcBA8eFE614f3C928a ] = 1000000000000000000;
    bnbAllowanceForUser[0x09FA5e2ADcF0d5269853Ca69C06e176a9953d458 ] = 1000000000000000000;
    bnbAllowanceForUser[0x4C43982770fc7Ad8295B40465f10b189ee2F5C42] = 1000000000000000000;
    bnbAllowanceForUser[0x41e8c84e31ed7Ef33d534576629945AC4d508523 ] = 1000000000000000000;
    bnbAllowanceForUser[0xCfeDd64518328eDB2d9C514fE0CBA14B9E2f1C96] = 1000000000000000000;
    bnbAllowanceForUser[0x78eE2EeeD14ad86282Dd203E486C8436cdbB3f01] = 1000000000000000000;
    bnbAllowanceForUser[0x77E20047Bb3010E775dde3703874E8feE4029466] = 1000000000000000000;
    bnbAllowanceForUser[0x850c835e64Fd4Bc5Fbb16208d800A4Db72c5f0D4] = 1000000000000000000;
    bnbAllowanceForUser[0x62e185b1C13728d9802380D8518762b9a2AE4227 ] = 1000000000000000000;
    bnbAllowanceForUser[0xe1DA75603121F80c1aDA305720FfB74cD931b7aD] = 1000000000000000000;
    bnbAllowanceForUser[0x929b27729cd6fA230c6C9c18127B2987A1d8970c] = 1000000000000000000;
    bnbAllowanceForUser[0xF5B8143c4D4275A419D4280caE5f8f3Cf2566149 ] = 1000000000000000000;
    bnbAllowanceForUser[0xF25C948e27E5333982A5057B22f33BcC17987EAa] = 1000000000000000000;
    bnbAllowanceForUser[0x4D52699CeaD9F18b3cC3c2801D59A9CE63f81234] = 1000000000000000000;
    bnbAllowanceForUser[0x1b5E879b5b7C8533fB6056126a55723c6d258fe2] = 1000000000000000000;
    bnbAllowanceForUser[0xF760df1971a3E567a8EA7b875A3d61B9677b885f] = 1000000000000000000;
    bnbAllowanceForUser[0x9531e1a282A0b4E2dDED8CEe9f86055c9532D7BB] = 1000000000000000000;
    bnbAllowanceForUser[0x4ee43cb0E7CEf2d12BC50F0a84120DF6eaD5888E] = 1000000000000000000;
    bnbAllowanceForUser[0xE09e0204F26f0fD8A04FE578BBe244451b536112] = 1000000000000000000;
    bnbAllowanceForUser[0xb283b2f158c6f676b99b91C477aB82f059f76471] = 1000000000000000000;
    bnbAllowanceForUser[0x5d10EbBDDd54885154Ac67A769F330da51E63DFE] = 1000000000000000000;
    bnbAllowanceForUser[0x3C6814Cc94bC866E8c2A4279412c8d6E10BF02F1] = 1000000000000000000;
    bnbAllowanceForUser[0x0878bF5E076a1b5152EEd0E9A52f3F1e901E7920] = 1000000000000000000;
    bnbAllowanceForUser[0xB26Aeae8f8318251F638Ff0DDcEee31cB51EE194] = 1000000000000000000;
    bnbAllowanceForUser[0x7cc9eB72058bf1C7Bb26914415deBdc43Fc1804a] = 1000000000000000000;
    bnbAllowanceForUser[0xe8CE85b8015aE78BB1Cac9aCf5bA883DF7086755] = 1000000000000000000;
    bnbAllowanceForUser[0x9f1f12E9B4721180342E3BA774648622B430BA57] = 1000000000000000000;
    bnbAllowanceForUser[0xb0579459793Eede0700151c1d649e3eB01853743] = 1000000000000000000;
    bnbAllowanceForUser[0x031457952397B3189A03bd7fc0a43D6815E117B1] = 1000000000000000000;
    bnbAllowanceForUser[0x40CBE823A580E53797d2124682F3b399CA6A8F9f] = 1000000000000000000;
    bnbAllowanceForUser[0xfc1d08f3C74Bdb6ee5aFFfdAbD8a86b2C6065D52] = 1000000000000000000;
    bnbAllowanceForUser[0xEe318DE1649D38734B0CE76985E97b58a89a64c3] = 1000000000000000000;
    bnbAllowanceForUser[0x54c1ef1a2ff3DaBba0eB8fD7e88Fd83AFE8DF97e] = 1000000000000000000;
    bnbAllowanceForUser[0xa3f52856C0BFE9bc5fc32eEC1137423Aa4924A65] = 1000000000000000000;
    bnbAllowanceForUser[0xDBf82646dDFa745D835cBbCCf9e8F54C8218AE57] = 1000000000000000000;
    bnbAllowanceForUser[0x24bF349846132235fD41eE11848AE893FE0B8b45] = 1000000000000000000;
    bnbAllowanceForUser[0x61F48723C19396da6461054da5443b6f41fd08E8] = 1000000000000000000;
    bnbAllowanceForUser[0x15473cf6D06578c82764e11Dcd0Ee7329f45ed13] = 1000000000000000000;
    bnbAllowanceForUser[0x4f502C3AA7110Afd52cc3f91F5227e9354fD318a] = 1000000000000000000;
    bnbAllowanceForUser[0xefB54162fa40442C8C6C9F52E33a6Ef7348E0f4E] = 1000000000000000000;
    bnbAllowanceForUser[0x3A1595Ac39b17973D7bC6A69c0385876B8C20ac1] = 1000000000000000000;
    bnbAllowanceForUser[0xd1B74D7AFB63649b51B6493684084C590B02E9eF] = 1000000000000000000;
    bnbAllowanceForUser[0xFBD5fcAFF3E413D1A7A61769aE61e3e5Cd57c316] = 1000000000000000000;
    bnbAllowanceForUser[0x5682FE4269688e77Cb1997d79edA0dAd92699b37] = 1000000000000000000;
    bnbAllowanceForUser[0x5354F6dF616d2a178A394c3A3097BB11Ca675010] = 1000000000000000000;
    bnbAllowanceForUser[0xB1C13DC4FF505Eb1Ecc009A2b1D58E259d4D775a] = 1000000000000000000;
    bnbAllowanceForUser[0xF4595C9863258992305FA01AC465d1A71049b832] = 1000000000000000000;
    bnbAllowanceForUser[0x409DfEe05D128595291fE3c8DFE20C44029C4148] = 1000000000000000000;
    bnbAllowanceForUser[0x8ca5e546D7a668261a1322438652f45012c23236] = 1000000000000000000;
    bnbAllowanceForUser[0xF94995B9368daf8D314eEfc450bD021e70d6b492] = 1000000000000000000;
    bnbAllowanceForUser[0x1AA3219f2e8b6EDB62228A30b81Ccfb6CC4318AE] = 1000000000000000000;
    bnbAllowanceForUser[0xd5015953BC4E24f9DAc96cACF60f348115077f4C] = 1000000000000000000;
    bnbAllowanceForUser[0x157a43774fc1699647C3d0Ed74d22961df3AE15E] = 1000000000000000000;
    bnbAllowanceForUser[0x291499B885Fc77055cb6393Bd8b4d69034A0719C] = 1000000000000000000;
    bnbAllowanceForUser[0x61AFEB68eb87b762562934E26050d703e5f5aC5d] = 1000000000000000000;
    bnbAllowanceForUser[0x04aC514225a9bAA5cfCbF7179A6848dB0A7E8f1c] = 1000000000000000000;
    bnbAllowanceForUser[0xD11EEC3C914C767Ce156d1f2A5A6dfF110d3aff8] = 1000000000000000000;
    bnbAllowanceForUser[0xbfd1a0f2d91cc682F83e00A400d45Fee17Eb15d3] = 1000000000000000000;
    bnbAllowanceForUser[0x5BF5CC5c5C806b69F18FaAdD961647a62D4362C2] = 1000000000000000000;
    bnbAllowanceForUser[0x0d8c8d9619d631D3c2F1E17c0F2B646Cefe6e430] = 1000000000000000000;
    bnbAllowanceForUser[0xF0b9dFE2970653147A694eFBdd4bC970d8411191] = 1000000000000000000;
    bnbAllowanceForUser[0x7caC8bf1E90248e8432228DBc60048CAf547cdf8] = 1000000000000000000;
    bnbAllowanceForUser[0x670Ba4dE9feff422e37a65EF0877494775201840] = 1000000000000000000;
    bnbAllowanceForUser[0x2E010f74439173d0a74ac45F3891F73B07B8F901] = 1000000000000000000;
    bnbAllowanceForUser[0xb8f6bE82647053298B60546Ce0e612EACbCC8E0F] = 1000000000000000000;
    bnbAllowanceForUser[0xF5E75dB60E35B68C805EE10bE08C566857B7F080] = 1000000000000000000;
    bnbAllowanceForUser[0x59983C5b39C105620e2Ca4EEdB095A2e1B416AD5] = 1000000000000000000;
    bnbAllowanceForUser[0x002f7CFfa90913f0BCd1f7B718a2e95900b131e8] = 1000000000000000000;
    bnbAllowanceForUser[0x01fFAB303A68FCCd8580Cc79A3887517B02ac3a7] = 1000000000000000000;
    bnbAllowanceForUser[0x0Fd1fB869Af1019BA16355830f6d4a28b2d8c35A] = 1000000000000000000;
    bnbAllowanceForUser[0x120F1C68Ed11E18a44D3eb5861A99B4565Dd7e71] = 1000000000000000000;
    bnbAllowanceForUser[0x13E022c966936d19Ae2504c1c835fF3a29c69Aa6] = 1000000000000000000;
    bnbAllowanceForUser[0x16C3D7aa6EB8Cf44CfBF5803560738d213C2a26B] = 1000000000000000000;
    bnbAllowanceForUser[0x194E4e0bd7e4f9ecf6818127Cd5EE686774897Ee] = 1000000000000000000;
    bnbAllowanceForUser[0x1c2EbFEa9a447b7653895b9DB65A0E3501d6529e] = 1000000000000000000;
    bnbAllowanceForUser[0x248409EB4Da6D773fce4f5dcbA63bcfB17aA118F] = 1000000000000000000;
    bnbAllowanceForUser[0x286886458ba8fCF9b3fbF2c997A4bE53B1d1afcc] = 1000000000000000000;
    bnbAllowanceForUser[0x2A67B3C9B9392ca241b38D03BD3502937C024B07] = 1000000000000000000;
    bnbAllowanceForUser[0x3316edd85999a16155A1c6C0Cb3594d512Fe7639] = 1000000000000000000;
    bnbAllowanceForUser[0x3d8bBDbd15830705efCd531fE8230961267A3818] = 1000000000000000000;
    bnbAllowanceForUser[0x55483fC316Ee8a717d51718A98564907D4Cfb466] = 1000000000000000000;
    bnbAllowanceForUser[0x5d10EbBDDd54885154Ac67A769F330da51E63DFE] = 1000000000000000000;
    bnbAllowanceForUser[0x605d7a88D980D8Ee3E61E6B001195693706F8dF5] = 1000000000000000000;
    bnbAllowanceForUser[0x627E55336f56a0C75c143B36609aa884a93680Da] = 1000000000000000000;
    bnbAllowanceForUser[0x74e52fACa4eC9CF7E0A51407837B6F3406894998] = 1000000000000000000;
    bnbAllowanceForUser[0x7875c17D90D63C723D18be135Ad5F03d834aa2E5] = 1000000000000000000;
    bnbAllowanceForUser[0x7970e47D2cedc940d6B92227ad10A12020431E3F] = 1000000000000000000;
    bnbAllowanceForUser[0x83F82B46651FFE97DbcF122402b93b8327Ed87e3] = 1000000000000000000;
    bnbAllowanceForUser[0x876a69bfce38C957E7436397EbDB1250C3CCaC4f] = 1000000000000000000;
    bnbAllowanceForUser[0x89526587E8ebafcb965013Ba768317644FE8d7c4] = 1000000000000000000;
    bnbAllowanceForUser[0x8Dc5BaE11E4295F98B2a69425dcdda9E2c41815c] = 1000000000000000000;
    bnbAllowanceForUser[0xA9fE10d5928Aae6ab0a89e7a1399b3142D539865] = 1000000000000000000;
    bnbAllowanceForUser[0xBADD98Bf32da9A33037Fb9761e1d90538cb12B82] = 1000000000000000000;
    bnbAllowanceForUser[0xc49503e703e290E6De06ecb335dA38065B45550A] = 1000000000000000000;
    bnbAllowanceForUser[0xd8d415806d20a7D1d28758C6BD73285ef2657888] = 1000000000000000000;
    bnbAllowanceForUser[0xdD5c34f3280f8360a5d367730cF4Bc2d1c60bbb6] = 1000000000000000000;
    bnbAllowanceForUser[0xf2d4Df257363d8C8085214f36E0cE52F8d0F0c60] = 1000000000000000000;
    bnbAllowanceForUser[0xb5Aa9eDdAab45F7220F30f475922a50A0200D07b] = 1000000000000000000;
    bnbAllowanceForUser[0x1A5D6E78a77F2Ccf94e9A6887c0D3546ce5B170c] = 1000000000000000000;
    bnbAllowanceForUser[0x79765Bf91101e8b5354DC3031247c19845B5fA04] = 1000000000000000000;
    bnbAllowanceForUser[0x6357859d53073d8861b83f9f6ef13f8D828d16cE] = 1000000000000000000;
    bnbAllowanceForUser[0xd785eCbdA7dD57af36820c6EA97aA9d0CCc0A9E3] = 1000000000000000000;
    bnbAllowanceForUser[0x2316362D538e6c5E48fCA8448040e8A289CF6255] = 1000000000000000000;
    bnbAllowanceForUser[0x668CB66e452C3380959dB7c5861B297F68DcCB4C] = 1000000000000000000;
    bnbAllowanceForUser[0x024b6a7359aC5009523a8C1C26c7a99415f902d4] = 1000000000000000000;
    bnbAllowanceForUser[0xC95d638c7502DF49D7f69DB931f9d9cf5D79b924] = 1000000000000000000;
    bnbAllowanceForUser[0x10a20d707d55E3D7c30B2cf120884Dd8eb45E970] = 1000000000000000000;
    bnbAllowanceForUser[0x075dfBc0Bc11d9b35B5756873529d0ce88F0DF8c] = 1000000000000000000;
    bnbAllowanceForUser[0xC2Dd50A4649E1c47Af293C72ad1B7D72A3e9a9E7] = 1000000000000000000;
    bnbAllowanceForUser[0xfCC0a2303321aa6DF9122B81F8Ce7DE6984d77CC] = 1000000000000000000;
    bnbAllowanceForUser[0xC7Cd8c3b5B3849716D981dF949231a496e6f8A33] = 1000000000000000000;
    bnbAllowanceForUser[0xA48479dBedCB3f756084296a3B94caF4AE756ce7] = 1000000000000000000;
    bnbAllowanceForUser[0x44F19a4f8af3F88fFE0532B55b76F4d99D8Dc234] = 1000000000000000000;
    bnbAllowanceForUser[0x4A6a3C1E99D1D79E9E68C1DC54297e51d734F57C] = 1000000000000000000;
    bnbAllowanceForUser[0x029F13F37Aa6aaa46A51dE0bfdc08B8D070CA98c] = 1000000000000000000;
    bnbAllowanceForUser[0x23F9c241A00b0Af4914DaC9E23D4aB099B4f3156] = 1000000000000000000;
    bnbAllowanceForUser[0xe2E4F1cd9fcea30599867B97fBd769E5A161c110] = 1000000000000000000;
    bnbAllowanceForUser[0x666dD1cFAebb3f187936A439f5757149D41E440e] = 1000000000000000000;
    bnbAllowanceForUser[0xAFc839A410eC10559BfA3159351e270D552512F4] = 1000000000000000000;
    bnbAllowanceForUser[0xd641Fb4D44107Fe227A4137105d30f2e33eD1211] = 1000000000000000000;
    bnbAllowanceForUser[0xFd286634Fa9107846734E6155336eD040EAcB024] = 1000000000000000000;
    bnbAllowanceForUser[0xF59aa04693aA2f250AfEBe1D7743bc8a76EF1d06] = 1000000000000000000;
    bnbAllowanceForUser[0x596febd5A3e868c73386037a514821DF4F79294b] = 1000000000000000000;
    bnbAllowanceForUser[0xBbDcc5dE07c5d7202a20267b132Fe5256B5676D1] = 1000000000000000000;
    bnbAllowanceForUser[0xaA5CaAcfD7a79A3A3B7d99D0c35DB90AF8C27676] = 1000000000000000000;
    bnbAllowanceForUser[0x60b6911A364E7F3862cA96d152c87da230C79583] = 1000000000000000000;
    bnbAllowanceForUser[0x10E726e164635D9Bcb0b123e0D130F279103F395] = 1000000000000000000;
    bnbAllowanceForUser[0x2eb9Ea49E45B9F0275F5Aa3008723E6f23b03200] = 1000000000000000000;
    bnbAllowanceForUser[0x641ceB4227e88E1C8f2b68D0dD2A7Bb515fb2e3b] = 1000000000000000000;
    bnbAllowanceForUser[0xCe85DeC8D1590075a264A6742C6D246d6b34EEdc] = 1000000000000000000;
    bnbAllowanceForUser[0x750e63b08fabCf7f3F4B989920a57425388Fae0b] = 1000000000000000000;
    bnbAllowanceForUser[0xfe3Ad8aC1377dF727Eb987275aF229a4c447A29F] = 1000000000000000000;
    bnbAllowanceForUser[0x847c1B4F34E93D2ae81B9D099c3E52F53d9aBEa2] = 1000000000000000000;
    bnbAllowanceForUser[0x15E490aC098e9b6f1B2006983C98F5E6Fb332E98] = 1000000000000000000;
    bnbAllowanceForUser[0x7fB1FD4D3705da5e8AbC92508EC19C99085Bef69] = 1000000000000000000;
    bnbAllowanceForUser[0x8686066dEbB0b1e4D1D369e5B8CECBAd8E91De76] = 1000000000000000000;
    bnbAllowanceForUser[0xFB31b6746478B80402eB055f3F55Fea6df204610] = 1000000000000000000;
    bnbAllowanceForUser[0xEc988281Be4814F9cfc41c46D1CE1b3f676539Bb] = 1000000000000000000;
    bnbAllowanceForUser[0x28b76958c260A3055f681A37D38BC00Cfa1d88E4] = 1000000000000000000;
    bnbAllowanceForUser[0xF82F3B4F64cA9D4187ef45A64abD1c397Bbe620A] = 1000000000000000000;
    bnbAllowanceForUser[0x1874194b030A8807644a59b5315b94A522340DfF] = 1000000000000000000;
    bnbAllowanceForUser[0x6863AFe7C78cA8f2B0dF00E3892fF987A96505Fc] = 1000000000000000000;
    bnbAllowanceForUser[0x7764e0181DE771Bd839762e12cADB5B9C7ED6738] = 1000000000000000000;
    bnbAllowanceForUser[0xAf278975af7341f600be86A507D94911Bc61C628] = 1000000000000000000;
    bnbAllowanceForUser[0x44d1eE20021Eb180557B7F4a4be2773545b2a64B] = 1000000000000000000;
    bnbAllowanceForUser[0x15460b74f77545289b9Bf340288CFBB02D65a800] = 1000000000000000000;
    bnbAllowanceForUser[0xa3468726029A51FB47f4A7c5A232517B3469c098] = 1000000000000000000;
    bnbAllowanceForUser[0xfD5f7c8950F368547E39F98ECf36E603b0106Ca8] = 1000000000000000000;
    bnbAllowanceForUser[0xAf0B9c1aab47Cd96E7e2A12091d03A5061bFc9C1] = 1000000000000000000;
    bnbAllowanceForUser[0x1971594F88DF957015cC8590D9e33cC127859A58] = 1000000000000000000;
    bnbAllowanceForUser[0xCB53Af2AC8DD9ed085B1F4102405cFB2Eb5785b8] = 1000000000000000000;
    bnbAllowanceForUser[0x89428cb2CC3Ec12751080F1Da8D86801b5D97e75] = 1000000000000000000;
    bnbAllowanceForUser[0xE1fc8F78fdA663D6c3a3C2c7D81C34BCcD54D52A] = 1000000000000000000;
    bnbAllowanceForUser[0xe8dbdeD8AC0b3AFb03C4140Dc6bc96CA96Dc2AbC] = 1000000000000000000;
    bnbAllowanceForUser[0x18b0C7862579B7f4166ada594815FF8C1b070b66] = 1000000000000000000;
    bnbAllowanceForUser[0xC4Df46BB8FbB85eF865A98731e82E3569ec5e32B] = 1000000000000000000;
    bnbAllowanceForUser[0xeC8575B7F4ab420CdB7b33Acc37fc229d671CDd5] = 1000000000000000000;
    bnbAllowanceForUser[0x9fc1b672Fcb07B43AaCD8b239F9Fc55cCE512125] = 1000000000000000000;
    bnbAllowanceForUser[0xC00c45Cd705eF2B73110A088e7af6F5f81b7e240] = 1000000000000000000;
    bnbAllowanceForUser[0xa4eE63Cd08970A92889aAAe0255D8859A4d8780A] = 1000000000000000000;
    bnbAllowanceForUser[0xEb43101a882Cf89633cd861A8a3f6c6aB5E0916B] = 1000000000000000000;
    bnbAllowanceForUser[0x482d60aD9C35e6B8f19fdA9e772FD0B1B9B5B417] = 1000000000000000000;
    bnbAllowanceForUser[0x6fD40AE5626847d4Ac0FF4d2D8b41EB53Bb03A74] = 1000000000000000000;
    bnbAllowanceForUser[0xDebD8B3E951D9a9f7e17B71c84277603B8988340] = 1000000000000000000;
    bnbAllowanceForUser[0x32842323ed2f5ccF7c1f5e17bfd4cafC97C9032A] = 1000000000000000000;
    bnbAllowanceForUser[0x073bC201B77f1D3ca9a50804be794dd9081759D5] = 1000000000000000000;
    bnbAllowanceForUser[0x2b24939aB21D42149A07D3D4667bb54B21543BE8] = 1000000000000000000;
    bnbAllowanceForUser[0x035AEa40df83EB8Cf6EF4e82ac3D13Aa16434719] = 1000000000000000000;
    bnbAllowanceForUser[0x553C66175E206DB1213D688C78C24EFD4b8b609B] = 1000000000000000000;
    bnbAllowanceForUser[0x45e627E895f621000459dB1fD57F172C87F41a18] = 1000000000000000000;
    bnbAllowanceForUser[0xd1DA7ffdb313e5Dd6Bc56A5079B3E78163BcE32F] = 1000000000000000000;
    bnbAllowanceForUser[0x9dAec75d02B228F5415BE63439150dAc408E842E] = 1000000000000000000;
    bnbAllowanceForUser[0x6853285716a92aF6DD07F2F6aeBCA23E5b13f8f6] = 1000000000000000000;
    bnbAllowanceForUser[0xAb0415cFB4a6772bDB93b80825276053a632128d] = 1000000000000000000;
    bnbAllowanceForUser[0xB9a0c9D0200A08aF16b4A149b3b9d45758ad29Df] = 1000000000000000000;
    bnbAllowanceForUser[0x3f88Ac3dF2d1Bb5C70E89b0B2d69e9FCF648C7d0] = 1000000000000000000;
    bnbAllowanceForUser[0x4E62cB7592dAc4980bc1aDf38ADAaefeD3aE7957] = 1000000000000000000;
    bnbAllowanceForUser[0xCFCa26696CD12D7591f0b6CCcA83FE0C87b30584] = 1000000000000000000;
    bnbAllowanceForUser[0x8C94dC818D4C54Bb645E46d810D849aA6bAACab4] = 1000000000000000000;
    bnbAllowanceForUser[0xbDc6a9e3E6fc94a5FFA5a1ecB46eD67fA84A9815] = 1000000000000000000;
    bnbAllowanceForUser[0x61AFEB68eb87b762562934E26050d703e5f5aC5d] = 1000000000000000000;
    bnbAllowanceForUser[0x6BbFDfE29a105C3e2D9ffe43ab86357Ea249fd3c] = 1000000000000000000;
    bnbAllowanceForUser[0x5b8e4B73D78F048d17E937943d1348D4d016ae5D] = 1000000000000000000;
    bnbAllowanceForUser[0x5BE2539BaA7622865FDc401bA26adB636d78f5Bf] = 1000000000000000000;
    // bnbAllowanceForUser[0x3c97c372b45cc96fe73814721ebbe6db02c9d88e] = 1000000000000000000;
    bnbAllowanceForUser[0xaeA7E17020D042Fc7a63c9Eb145dc3401c64e59a] = 1000000000000000000;
    bnbAllowanceForUser[0x468826e31E7E4668A3d0793673464A8640e2a09E] = 1000000000000000000;
    bnbAllowanceForUser[0x29c2eF45159ccAC6934CD80455c45F312d4f56ca] = 1000000000000000000;
    bnbAllowanceForUser[0x5fc0a0Dd075c96125b6A5e03E8032a1C0870f19A] = 1000000000000000000;
    bnbAllowanceForUser[0x5f5B31464388ec01d2Ab959fB7e0311C297cA06C] = 1000000000000000000;
    bnbAllowanceForUser[0x69f5f853D7241ccf77E5306F736cA2a10CfFA7E7] = 1000000000000000000;
    bnbAllowanceForUser[0x16EB9fBa32A999F6bCa704f63eeE13FfA3149692] = 1000000000000000000;
    bnbAllowanceForUser[0x772308A6baf2aEeE106b88BE66cBd3efF7c6a064] = 1000000000000000000;
    bnbAllowanceForUser[0x6da2817e21b6EcDF4814a1eCB2720Ef6ed47D29C] = 1000000000000000000;
    bnbAllowanceForUser[0xac8748D57ce4467728f830c324A458f584f9B696] = 1000000000000000000;
    bnbAllowanceForUser[0x32e158e3aa5B1199c9179DC5dd33d3f9D3080c2C] = 1000000000000000000;
    bnbAllowanceForUser[0x6C3081DE599e651298da358738D67Af93e1C5D43] = 1000000000000000000;
    bnbAllowanceForUser[0x30cc10F0e9a62f1E6b43D7c3b29A2e5418580C03] = 1000000000000000000;
    bnbAllowanceForUser[0xc9ac41b0B3417Bcb9A7E93d6e820ff6CFcdc88a7] = 1000000000000000000;
    bnbAllowanceForUser[0x0B8243D82Fa4B85e5739E083054C7f80709e4e14] = 1000000000000000000;
    bnbAllowanceForUser[0x208356db82a6E90bf102ec21E453765E037087AC] = 1000000000000000000;
    bnbAllowanceForUser[0xdae241EF93354C50006808fC17dA1f4EDFF1BE6F] = 1000000000000000000;
    bnbAllowanceForUser[0x67723f0f405B28574685169B5D04056349068Db1] = 1000000000000000000;
    bnbAllowanceForUser[0xBca2dFAaD57261ACC74951B32f991286B6Fcc64b] = 1000000000000000000;
    bnbAllowanceForUser[0x571a008207Ae3B4F196578278CCa65e056E081A0] = 1000000000000000000;
    bnbAllowanceForUser[0x2F588660aE8cD5Fc6130e4279e6E55f15E0e1EDc] = 1000000000000000000;
    bnbAllowanceForUser[0x3BD2ffE9D083e53e6CfdC629a387154596A98A49] = 1000000000000000000;
    bnbAllowanceForUser[0xBE35EBC27Bd7c53A071b136c5d4DDD5945B2B18d] = 1000000000000000000;
    bnbAllowanceForUser[0x10Eb9cE266ce1dC7b420408576aCc762bbc72b4D] = 1000000000000000000;
    bnbAllowanceForUser[0x00825531c08bA5c09809234cA3D52E3eE9907AbF] = 1000000000000000000;
    bnbAllowanceForUser[0xeB068E281aa8C5512c023424b5C1DEE0569B6B97] = 1000000000000000000;
    bnbAllowanceForUser[0x1916277964DFe7c87dC2a1AfC8a0862848F0A9bB] = 1000000000000000000;
    bnbAllowanceForUser[0x9460Dc43b0DA2898AC0ddc34d34A3e1C8eC68096] = 1000000000000000000;
    bnbAllowanceForUser[0x2E6391DdCaeBf3f4A7c38EEbE57c49bda08168CD] = 1000000000000000000;
    bnbAllowanceForUser[0xe4b2D4BC2a7aD4CAD4cbA6Ac9268fE9272255FB1] = 1000000000000000000;
    bnbAllowanceForUser[0x695c6fEC65ad3D0c08f58f647Ed12e8de6919096] = 1000000000000000000;
    bnbAllowanceForUser[0xB88522c60eE58aFa19e65aa1e3EE33d7a65B83f8] = 1000000000000000000;
    bnbAllowanceForUser[0x3e5Fb56D29802E601cBe447AE58502E4939d1f2A] = 1000000000000000000;
    bnbAllowanceForUser[0x3498950ec1cC074c0672f433ff0596585ba49c06] = 1000000000000000000;
    bnbAllowanceForUser[0x81E33284f5Bd4Fe8f8497335703eb1777A551D7B] = 1000000000000000000;
    bnbAllowanceForUser[0xd7668f2D5303C4c5202A405C32B1df28051e56Ca] = 1000000000000000000;
    bnbAllowanceForUser[0xD2B08a1f50580e41534D7Ee808DdDbB8759f7334] = 1000000000000000000;
    bnbAllowanceForUser[0x820a85c194f7Ef60943264AD5bc2F2Ce52efd5A5] = 1000000000000000000;
    bnbAllowanceForUser[0x9984128A70C8Ad5e14490D02f118671684b93578] = 1000000000000000000;
    bnbAllowanceForUser[0x0E84376b865Dbb59720d0462Dcc51D19cF262db9] = 1000000000000000000;
    bnbAllowanceForUser[0xb9C0a68423FBe7D5e28ede45C7948Ee46086963e] = 1000000000000000000;
    bnbAllowanceForUser[0xdfADbDa39C122b5b4D22aD9D91927d305c787e36] = 1000000000000000000;
    bnbAllowanceForUser[0xFBE21b2c323219a79b5FEe7dD4d6f5cA8a92BAE8] = 1000000000000000000;
    bnbAllowanceForUser[0xebd9cAa3Bac8d50f3390DEF50254e3b642ab38cE] = 1000000000000000000;
    bnbAllowanceForUser[0x0bf07A0615b37eC22354d5bF0922aEE5B2c21216] = 1000000000000000000;
    bnbAllowanceForUser[0x5891cd783224B7e4C590441280C973F2986785ED] = 1000000000000000000;
    bnbAllowanceForUser[0xf588E581B565c1af5F9D5f4F1BAf298265FC2380] = 1000000000000000000;
    bnbAllowanceForUser[0x5E61896b8Ac3D1d5902a2D7Fe9647a29829ce3ad] = 1000000000000000000;
    bnbAllowanceForUser[0x64Cb7FB5199c83A96210911653ed60dFe5F85Fa6] = 1000000000000000000;
    bnbAllowanceForUser[0xE2399Ca724d4a32bB55Fa52bBa403eFA7F08CD7A] = 1000000000000000000;
    bnbAllowanceForUser[0x8cD3aeDa2156644fb37477E575Ffe4c297125eE6] = 1000000000000000000;
    bnbAllowanceForUser[0x7FF015E79e88CFa16B0b81952195ffBbf3Fa6802] = 1000000000000000000;
    bnbAllowanceForUser[0xb8049BFc133438B63001f056B51128689235b14f] = 1000000000000000000;
    bnbAllowanceForUser[0x89adDAc0892DD7C7818B9fB8E47B856Da2553b03] = 1000000000000000000;
    bnbAllowanceForUser[0xc126970Ee6DA8A795730A92f63C7f1E04392D37D] = 1000000000000000000;
    bnbAllowanceForUser[0x1ff0b864408167E0d271698e0920E079627B94D5] = 1000000000000000000;
    bnbAllowanceForUser[0xCd5164185abadbD8aB36a242F2D4954bbDe14c61] = 1000000000000000000;
    bnbAllowanceForUser[0x1dDf58e187A4cC7cFDA46400a02Ca9A5f997abcB] = 1000000000000000000;
    bnbAllowanceForUser[0x1a577c778CA0ba9872C9Bdb2CF3d4000b1410902] = 1000000000000000000;
    bnbAllowanceForUser[0xEdfac19CCD2aEB28916f2a17281343735883552d] = 1000000000000000000;
    bnbAllowanceForUser[0x6fEf8643798c8034cbAE18764b52bBffDdE4c3A9] = 1000000000000000000;
    bnbAllowanceForUser[0xE42926c4169Caf2F84164b006F9a840058D7d055] = 1000000000000000000;
    bnbAllowanceForUser[0x777c97cE5d89A135F42ec499E95F75c3402226E5] = 1000000000000000000;
    bnbAllowanceForUser[0x2bB432d33cA6231A86Bc8717F6d4EE35dc3fc897] = 1000000000000000000;
    bnbAllowanceForUser[0x8eb9c9678Af808A3B5BAfD4D719548e9e57E5f79] = 1000000000000000000;
    bnbAllowanceForUser[0x42015090C599e7c2727305C280FF4CDbE7cC828b] = 1000000000000000000;
    bnbAllowanceForUser[0x20aE5c23626D2533CF885799FF1132a2f73bCC0D] = 1000000000000000000;
    bnbAllowanceForUser[0xC2DcD47010BF75fdE9b9f232f2b87fD0Df52B93F] = 1000000000000000000;
    bnbAllowanceForUser[0x3f65caf56e57a24ce16969ac50df229b37069411] = 1000000000000000000;
    bnbAllowanceForUser[0x8dF3af6c59D1D41519998215D537436D5f47CC54] = 1000000000000000000;
    bnbAllowanceForUser[0x384A655a2B538f8A7556A9c935C2645c7e715Cb1] = 1000000000000000000;
    bnbAllowanceForUser[0x40a5DDBD38d938FA9Da88625E97C0613F2EB2d24] = 1000000000000000000;
    bnbAllowanceForUser[0x5d5A6d0a8edf9716Ce8e6e8F25F2fa690C85c14A] = 1000000000000000000;
    bnbAllowanceForUser[0x9e1976F59d36cE69E2FC266938d352030D83e585] = 1000000000000000000;
    bnbAllowanceForUser[0xAda7D8d3509c227588681D969367731E11E03028] = 1000000000000000000;
    bnbAllowanceForUser[0x9c43258a7dF43255Db871b6237Fe6F03318d4770] = 1000000000000000000;
    bnbAllowanceForUser[0x821d426Ad819141c0Ab6715f90719486bDeC386e] = 1000000000000000000;
    bnbAllowanceForUser[0x6841c5993504cdE3327EC060D2d64b2C841B540B] = 1000000000000000000;
    bnbAllowanceForUser[0x6A7e1e324B7477EC0d02641CE21bA5bfBbC375BB] = 1000000000000000000;
    bnbAllowanceForUser[0xEF0ca105dcFaC7CD99d56814593439057e9394f9] = 1000000000000000000;
    bnbAllowanceForUser[0x017ae40d8bc879EcE401f67E14f8EfFc028887A3] = 1000000000000000000;
    bnbAllowanceForUser[0x005b9d42D0cf87CA9F4C425842735c180eE31B18] = 1000000000000000000;
    bnbAllowanceForUser[0x14D96838195B12f7fAC8762cdF12053A2552f361] = 1000000000000000000;
    bnbAllowanceForUser[0x118c83dC8152EAB8E197f971d7B041e266aBC965] = 1000000000000000000;
    bnbAllowanceForUser[0x496d415D26f6631B3baBc76D354B0086d15D0134] = 1000000000000000000;
    bnbAllowanceForUser[0xBE9e15cBb56DB5E86FD55f1b79Ac56c654ab2697] = 1000000000000000000;
    bnbAllowanceForUser[0x6ab1910a485CAb49Cb73D9b198a7C97e057a23d8] = 1000000000000000000;
    bnbAllowanceForUser[0xbB18e3F73860bEb9BCe9d326db3d7c50a01d019c] = 1000000000000000000;
    bnbAllowanceForUser[0x31a13C1582BcbDA57F278a39bBD6d8EE23172bfE] = 1000000000000000000;
    bnbAllowanceForUser[0x57Ca52B8bE3B25b5092d498a3b0e55a0c5Bc4012] = 1000000000000000000;
    bnbAllowanceForUser[0x75808c69ab8FEfd2F23f56176bb485F4Ad132107] = 1000000000000000000;
    bnbAllowanceForUser[0x543255f8c4B7759807C48b739ff9dB8CFd7F779b] = 1000000000000000000;
    bnbAllowanceForUser[0x868Eef1A8409fE79050d0f5B5257A3ae67C30B91] = 1000000000000000000;
    bnbAllowanceForUser[0x094D3999Ef0DB181328E944e275Ee232DBC25bB7] = 1000000000000000000;
    bnbAllowanceForUser[0x0C565D71Cd336561De88c11D6CDd60f7a861d82d] = 1000000000000000000;
    bnbAllowanceForUser[0xcB2A0ba4DA5F8Eca0B12C91DF0F435DaDD7B14Ed] = 1000000000000000000;
    bnbAllowanceForUser[0x2472990eB08884a19Cb22a0AF13ff9Cb0268829B] = 1000000000000000000;
    bnbAllowanceForUser[0xdeD521EeEE25C3CF34E9609373c536F38CeCd57a] = 1000000000000000000;
    bnbAllowanceForUser[0xeD6A2983bFfC60Cc565f37673f4981992F7bd9E4] = 1000000000000000000;
    bnbAllowanceForUser[0xa2B3A0674e8092AD6Be8634a8525AfB887B03a41] = 1000000000000000000;
    bnbAllowanceForUser[0xb150B53A0a444eB153d1823C67d22795A3735DDa] = 1000000000000000000;
    bnbAllowanceForUser[0x112Fa4958398840fE38cF0991d1648E15E194fac] = 1000000000000000000;
    bnbAllowanceForUser[0x1872bc710DfFbD69B69d3c12Ea9d6D69Bcf6d096] = 1000000000000000000;
    bnbAllowanceForUser[0x4d9B1D85c752c2dceD632Cd8C05F2CE4A30192B5] = 1000000000000000000;
    bnbAllowanceForUser[0x7eD6Cc83D42fbD7C8079b05376c5352134D0082a] = 1000000000000000000;
    bnbAllowanceForUser[0xAbf66b500B1C8027eFB51910dBda297A88d35972] = 1000000000000000000;
    bnbAllowanceForUser[0x4264935811966d14cB8686F412D6Aa0e380327eE] = 1000000000000000000;
    bnbAllowanceForUser[0xbcF82cf61ec69805Fb72288dC374c7AD1A942c7b] = 1000000000000000000;
    bnbAllowanceForUser[0xc690e2F703C541251D0BA1aEDb00993ca29C54FB] = 1000000000000000000;
    bnbAllowanceForUser[0x1ff0b864408167E0d271698e0920E079627B94D5] = 1000000000000000000;
    bnbAllowanceForUser[0xE8cB65155Df1609801bdc640E2032CF86108b5c1] = 1000000000000000000;
    bnbAllowanceForUser[0xA789B08C4cbc20c48aB5a96C541063c6782B1ad9] = 1000000000000000000;


    



    
  }

  /**
     * @return the crowdsale opening time.
     */
    function getOpeningTime() public view returns (uint256) {
        return openingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= openingTime;
    }


  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  fallback () external payable {
    revert();    
  }
  
  receive () external payable {
    revert();
  }


  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    require(bnbAllowanceForUser[_beneficiary] > 0, "Beneficiary does not have any Bnb allowance left");

    uint256 maxBnbAmount = maxBnb(_beneficiary);
    uint256 weiAmountForPurchase = msg.value > maxBnbAmount ? maxBnbAmount : msg.value;

    weiAmountForPurchase = _preValidatePurchase(_beneficiary, weiAmountForPurchase);

    if (weiAmountForPurchase > 0) {
      // calculate token amount that will be purchased
      uint256 tokens = _getTokenAmount(weiAmountForPurchase);

      // update state
      weiRaised = weiRaised.add(weiAmountForPurchase);
      emit TokenPurchase(
        msg.sender,
        _beneficiary,
        weiAmountForPurchase,
        tokens
      );
      _updatePurchasingState(_beneficiary, weiAmountForPurchase);
    }

    

    if (msg.value > weiAmountForPurchase) {
      uint256 refundAmount = msg.value.sub(weiAmountForPurchase);
      msg.sender.transfer(refundAmount);
    }
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmountForPurchase Value in wei involved in the purchase
   * @return Number of weis which can actually be used for purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmountForPurchase
  )
    public view returns (uint256)
  {
    require(_beneficiary != address(0));
    require(_weiAmountForPurchase != 0);

    uint256 tokensToBePurchased = _getTokenAmount(_weiAmountForPurchase);

    if (token.balanceOf(address(this)) >= tokensToBePurchased.add(tokensAlreadyPurchased)) {
      return _weiAmountForPurchase;
    } else {
      tokensToBePurchased = token.balanceOf(address(this)).sub(tokensAlreadyPurchased);
      return tokensToBePurchased.mul(1e9).div(bnbUtopiaRate);
    }
  }

  

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmountForPurchase Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmountForPurchase
  )
    internal
  {
    if (purchasedBnb[_beneficiary] == 0) {
      purchaserList.push(_beneficiary);
    }
    purchasedBnb[_beneficiary] = purchasedBnb[_beneficiary].add(_weiAmountForPurchase);
    bnbAllowanceForUser[_beneficiary] = bnbAllowanceForUser[_beneficiary].sub(_weiAmountForPurchase);
    tokensAlreadyPurchased = tokensAlreadyPurchased.add(_getTokenAmount(_weiAmountForPurchase));
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmountForPurchase Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmountForPurchase
   */
  function _getTokenAmount(uint256 _weiAmountForPurchase)
    public view returns (uint256)
  {
    return _weiAmountForPurchase.mul(bnbUtopiaRate).div(1e9);
  }

  /**
   * @dev Determines how BNB is stored/forwarded on purchases.
   */
  function forwardFunds() external {
    require(admin == msg.sender, "not admin!");
    admin.transfer(address(this).balance);
  }

  function maxBnb(address _beneficiary) public view returns (uint256) {
    return bnbAllowanceForUser[_beneficiary].sub(purchasedBnb[_beneficiary]);
  }

  function numberOfPurchasers() public view returns (uint256) {
    return purchaserList.length;
  }

  /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
  function finalize() public {
      require(admin == msg.sender, "not admin!");
      require(!finalized, "Crowdsale already finalized");

      finalized = true;

      emit CrowdsaleFinalized();
  }

  function withdrawTokens() public {
      // calculate token amount to send for each purchaser and sends it
      require(finalized, "Crowdsale not finalized");
      uint256 tokens =  _getTokenAmount(purchasedBnb[msg.sender]);
      require(tokens > 0, "No tokens left to be withdrawn");
      
      token.transfer(msg.sender, tokens);
      purchasedBnb[msg.sender] = 0;

      emit TokenWithdrawal(msg.sender, tokens);
  }


  function transferAnyERC20Token(address tokenAddress, uint256 tokens) external {
    require(admin == msg.sender, "not admin!");
    IERC20(tokenAddress).transfer(admin, tokens);
  }

  function setBnbAllowanceForUser(address _address, uint256 weiAllowed) public {
    require(admin == msg.sender, "not admin!");
    bnbAllowanceForUser[_address] = weiAllowed;
    // Default should be 1000000000000000000 wei (1 BNB)
  }

  function viewBnbAllowanceForUser(address _address) public view returns (uint256) {
    return bnbAllowanceForUser[_address];
  }
}