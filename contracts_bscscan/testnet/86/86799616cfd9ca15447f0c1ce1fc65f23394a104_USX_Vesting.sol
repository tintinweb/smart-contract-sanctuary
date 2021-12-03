/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/[email protected]/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/[email protected]/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: usx_vesting.sol


pragma solidity ^0.8.2;




//Vesting for overall except (Swap / ICO / Private Sale)
contract USX_Vesting is Ownable{
    using SafeMath for uint256;
    IERC20 token;
    //uint vestingLock = 12; //months
    uint vestingLockDays = 30; //
    uint256 daytimestamp = 86400;
    uint256 vestBalance;
    uint8 deployed = 0;

    struct vestingBox {
        uint256 totalBalance;
        uint256 remainingBalance;
        uint256 monthsLock;
        uint lastRelease;
        uint8 counter;
        uint8 temporaryCounter;
        uint8 flag;
    }

    //address[] vestaddr = [0x2071cE76a864e31773aCd24AD4f57d43111ed767,0x66c77825cA44CfAcD427a1dA304046CE7446bd0D,0xF4Ec2db1F22067979D0A9c3babfFE5B5A7Cecc15,0x261b31729ADc8469BCE9b33DD687F9D529bcbC11,0xc9044AD8BC368c3C10357f21445e6C0b50bac40D,0x98515AF79c2765120d132eD55451055650e1a8D9,0x82B0E27AA88a21703D6283366DeFA0cC4aC3B65D,0x6262876f527293E6c6e4f137876F9f960F8e1438,0x14637d58bb711486fA33CA2C1BdF08B9BefAF14F,0x72215bAFcd3923FF2B7862081fBe42D8f6876924,0x7225c2cd533BcEc5411Dcdaa8Af24AcF535fFaCa,0xfb13849735DEF26592Ce4C30B58Ec929dC6E1475,0xB9a9908ad90CBf38ad5679AD63E1C96EdEC4927d,0x4280c50c9Cc620dfa9ccEd5F493F3560451F17Df,0xb908c667446b3335a290aAa2E28365F6203a9882,0x646E604Db1195696107fFd05A3a2051f84cCdDd8,0x7609090eD61034F75e9175783b5312b9122bCE6e,0x648a898DD5a23026551419fE33EF96196B6552Ca,0x9295d080c14660AD927b80D908C56382CC506eC0,0x7c9CB90a2B7DC70dCe5633E288cf6Cc504103bE3,0x32067f43F1fCF439aa05D2Ce5fe651095207403B,0x672bF2613B54f9C95d0fd50f37Ff7189FE27cb67,0xEB1a799769fc69E84440F9D162D12B196e6E369c,0x21263c1AAEebAc5901027Fa74e58D6147639eFf8,0x74aA8EA34142234Ac9B722F49C26946F344Be57A,0x28dd1de2b098A0e8e9860b644eDC55931fa4Bb90,0xdC791fb1816ec606C9fc4D0C43d76233f837f6Df,0xE9Fe5dD43aEeD2EB9511bBB9a59e174F46B6BDc6,0x00fe5c3562b5efFCaD125756cCc528bEC9579e89,0x38a71224d389EE04120ea249Eff531C2aEBA9be8,0xAE329e960b03f02487d5D8DEFC6F12daB1AB728c,0xA4063903d578BD479b9a05f23e8d21381523AB33,0x9cBe94b48B3AefD04e98b119890Da1B143814b2a,0x14Bbf973FB6058Bb5471016896563a9BC4E74443,0xE10b61e265A953074c5F3d54cF61F5717694b623,0x735764Ef28973039B639835Ea0768F1b79bA0c40,0xf770d398Df3A55066ff373C613E9507c4680Ba54,0x098B0a07A01F65087faF320b1f0e2ee13529e15C,0x05D09F9569Ff8f6f1538F90849a82c13328F6494,0x8fADfE756bEE48bE880f3D9102A19363e18d130C,0xCda30Dff2D8d98790678AEcC6852Eb1A8AbFff9E,0x43A276fD389a024548cF876cb8B94F33e8768A90,0x6d36f4336239035256AFBade222232eAf2FAD6E5,0xbca179D0b6bC42A7620381597178773Aff5E0e20,0x674026dD5e3710dD35902Bd2B39DAec8848fF2EB,0xBAA2Fac30e43031d9d181aB1D45970c1f7Ac1B38,0x0d5979223FDBb1A3d710609d8E8bCA76EA5e9038,0xF997AF8f01BDCbba53278437c20116171D0f8d0e,0x465eA6352cE6c8199A22ddC9d4D0f7A8912C9413,0x448241D1119307edD65584ad495cD3141Dd93c93,0x875dE99D5EEB7089c04BBd61d3C2f7B9bE247b8a,0xdd40228017a4b134cE02e6aD1D2265Ded0a52Ef6,0xBC546B51ADe9b9aC8ebD682D655Ce54f9D98364a,0xb94312Df35E7CEbaA86038539d2a3302611B7F73,0x5e31707D924913a074baed2332219ab2972de673,0xDd3a475E82f28fAa72916946A64E0dEDa789dBED,0xD697b1e1Af0136C9A9bA151c039D4877D0752775,0x048AE74532030e6c6D7569Aca97e01412708e466,0x2b4DA64299Ac3739115e6C5055018D70A221D667,0xDbD77dAFF623c72f6cA6463e326E7d2e796fc819,0x299141ce6Ba224Aa4FA358669Cb0729c088729Fd,0x0DC84cD4c8E5b8177D7FD2A39dC660A080BEC905,0xd48E7064F1abCfB690Dc5A79940B2ae45b238349,0x17dCFcd0c8D9c3Fca3B593ab47d9Bd88E9F9fa6E,0x84b9304c24b27c71473f9B4024b74D364F0A6906,0xECbE5CaBB18775a0812956824B1B9De96c750bc3,0x00cFAAC300006Bca5879c779101af143D3D31574,0x8a317eDFD29d469d1Beb7e7f515Ea8f5cf542ee6,0x8C98c42E7D39085E71A8F468b0D16C67C9D1813E,0x2D64F2e5A68DDF67deF33112943F47e5AAA49f96,0x8aC7499D13B30d640247f7300E9f2cB8f6755fA8,0x405629239D997e85E0415932c11388a089F30CD2,0x3bEd7AF11D81cA1C39Fa5A1278078E60BFd40857,0xBd1816566a3d9A94f971f4Fc0fF9d3ebceBd0726,0x80F9DD6b03E4d038162Ef6C04B17f7FDEd3dC128,0x9b70c33Df81ea6998970Ca7B3124feD574f0676A,0x679782316318B6B665754f06cD65866dAB30920C,0x3956a5D00DCf0058b6d4A49D1799fe11Ce6d1118,0xE0711d16187408305Dc2288F09C1C7E0005EF664,0xb37794F77852EedF7db5Fc4Dc30475a190583bD6,0x89c7A872700175ACd4b7860aA66FDAb7e64499dc,0x0dde8A135452B560B531288615fAEdF4A4575A4c,0x3fbfC32b97F133C08c1157c3C12b2693C8A74533,0xA2812c8Ced2D8DD94f7473af3F2DCE48029c854E,0x3b59C9285dF686E6Ca7d1A7EF67a78B952d3E760,0x7Ad9e2a5B52dE87ED6E72B7a4d1d34aB58007904,0x5295A007A54303B1FB20eF8Be895cE2Ec2Aa3208,0xa34556343Db7D2f83688d9831D62Df212a7fda45,0x7900eE97A7E36D4cdE2B36be47B070D66b385485,0x15cfc2C5FcD05b1A60FC4039Ff104BD0Ba098d57,0x7e43c9EA2e3813f5F0413B394B70dBeecf66b0fD,0xba0aD7dCffAe400Dae4e8F5c627857F1c8F4113b,0x0653E2733354AB2a8Ad608b8b857486bE5f4A39B,0xF4dedB1553ee4910BDBFe8a9488B52ab3cA4C47b,0x7B77B5B64F2C129d05400C9fBcC0F1C00B647047,0xa136544888069b040419D56A57CFe0225EE06B98,0x66C99A6F1FFD53796357CeD6A54e007F38e2565E,0xe92e88F0e14485FE4F08D3582aF9082ac4dAe766,0x9A45FDFeF07CCaE32D316243b9E37b642E863849,0x7CfD258259997DC771bBCda9DD629308F0594359,0x7a485f78cC76F8EE48603989ECB59711aa04a3CD,0xdaC494959c95a93345b1385a26C1C0360a62c071,0x413d7C6048c2A6b36698260a476AD1AF1956c31b,0x21C66F57d58fcB3DBDd62629b44D36AB181fc369,0x2F162BFf3A3073cd37d224e14f4D41FFeB82962f,0x6A2A111Dec5e9b01Caa84Fe3aEBCBA41D0d39890,0xc33a0E89B7000DF6e43a66c238926Fd44393ce65,0xE37a8Aa9414eFCb49Bc706fB4f1843a17BD575C9,0x71b94078a1dDc671bE572697a286cff1434C7467,0xaFb6c5cF0db97a01bd3392C8687351b76a86f766]; 
    //uint256[] vestamount = [1350000000000,638462341890,84074000000,1526257000000,1287361811958,3270320200000,20644400000,1008400000000,512000000000,30520600000,1200020000000,7478999600,263409035098,615630480000,167600000000,372733399999,35200000000,148591200000,47804711685,9425653999,4198950925,12952000000,94020000000,822715000000,794834000,10146032000,116691594800,794834000,1015598000,9930326360,2385914800000,799387954,343118600000,699580094000,992391444440,4000000000,5206872400000,443600000000,573309400000,1572600000,40000000000,328546309670,2534788988,1100918000,56676400000,36044400000,3935294430,9670600000,32301553999,702148948,9415464010,2896090000,15385400000,93414559520,11300600000,37725350800,7122200000,109340202548,205193923894,800394706,2125127200000,58286130000,7205760899,240304688050,5497261790,5794340000,8514770,74400000000,535348840039,313454030630,1000000000,121926000000,1089000000,57577683180,51383633000,43118000000,49041800000,1289000000,1157662820400,39803216800,126909200000,794833960,748513528000,291267600000,2794834000,799175536550,486047568230,168045804170,152537754908,3100000000,982165000000,21296600000,298851079070,794834000,232940000000,13029000000,40026787288,6141717650,794800000,15168131050,3110600000,10000936000,2526000000000,1800000000000,10717600000,32800000000,6558175400,39040000000,2443229000000,3497000000]; 
    //uint256[] vestlockMonths = [12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12]; 
    address[] vestaddr = [0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0x66c77825cA44CfAcD427a1dA304046CE7446bd0D,0xF4Ec2db1F22067979D0A9c3babfFE5B5A7Cecc15,0xc9044AD8BC368c3C10357f21445e6C0b50bac40D];
    uint256[] vestamount = [1350000000000,638462341890,84074000000,1526257000000];
    uint256[] vestlockMonths = [12,12,12,12];

    mapping(address => vestingBox) private vestingBoxes;

    constructor(address tokenContract) {
        token = IERC20(tokenContract);
        distributeTokens();
    }

    function _fixAmount(uint256 amount) private pure returns (uint256){
        return amount * 10 ** 12;
    }

    function contractTokenBalance() public view returns (uint256){
        return IERC20(token).balanceOf(address(this));
    }

    function showRemainingBalance() public view returns (uint256){
        if(vestingBoxes[msg.sender].flag==1){
            return vestingBoxes[msg.sender].remainingBalance;
        }
        return 0;
    }

    function nextReleaseToken() public view returns(uint256){
        return (block.timestamp-vestingBoxes[msg.sender].lastRelease) * 100000;
    }

    function showClaimable() public view returns(uint256){
        //require(vestingBoxes[msg.sender].flag==1,"Address not in vesting schedule.");
        if(vestingBoxes[msg.sender].flag==1){
            //require(vestingBoxes[msg.sender].counter<=vestingLock,"Address already claimed vesting.");
            if(vestingBoxes[msg.sender].counter<=vestingBoxes[msg.sender].monthsLock){
                uint temporaryCounter = 0;
                uint256 totalAmount = vestingBoxes[msg.sender].totalBalance;
                uint256 tokenPerMonth = totalAmount.div(vestingBoxes[msg.sender].monthsLock);
                uint256 claimedToken = totalAmount - vestingBoxes[msg.sender].remainingBalance;
                uint256 claimable;
                uint256 beneficiaryTime = (block.timestamp-vestingBoxes[msg.sender].lastRelease) * 100000;
                //uint256 claimtimes = (beneficiaryTime / (daytimestamp * vestingLockDays));
                uint256 claimtimes = (beneficiaryTime / (daytimestamp));
                if(claimtimes>=100){
                    do {
                        if(claimedToken<=totalAmount && claimable<=totalAmount){
                            temporaryCounter += 1;
                            if((temporaryCounter+vestingBoxes[msg.sender].counter)<=vestingBoxes[msg.sender].monthsLock){
                               claimable = claimable.add(tokenPerMonth);
                            }
                            claimtimes -= 100;
                        }else{
                            break;
                        }
                    } while(claimtimes>=100);
                    return claimable;
                }
            }
        }
        return 0;
    }

    function claimableToken() public returns(uint256){
        //require(vestingBoxes[msg.sender].flag==1,"Address not in vesting schedule.");
        if(vestingBoxes[msg.sender].flag==1){
            //require(vestingBoxes[msg.sender].counter<=vestingLock,"Address already claimed vesting.");
            if(vestingBoxes[msg.sender].counter<=vestingBoxes[msg.sender].monthsLock){
                vestingBoxes[msg.sender].temporaryCounter = 0;
                uint256 totalAmount = vestingBoxes[msg.sender].totalBalance;
                uint256 tokenPerMonth = totalAmount.div(vestingBoxes[msg.sender].monthsLock);
                uint256 claimedToken = totalAmount - vestingBoxes[msg.sender].remainingBalance;
                uint256 claimable;
                uint256 beneficiaryTime = (block.timestamp-vestingBoxes[msg.sender].lastRelease) * 100;
                uint256 claimtimes = (beneficiaryTime / (daytimestamp * vestingLockDays));
                if(claimtimes>=100){
                    do {
                        if(claimedToken<=totalAmount && claimable<=totalAmount){
                            vestingBoxes[msg.sender].temporaryCounter += 1;
                            if((vestingBoxes[msg.sender].temporaryCounter+vestingBoxes[msg.sender].counter)<=vestingBoxes[msg.sender].monthsLock){
                               claimable = claimable.add(tokenPerMonth);
                            }
                            claimtimes -= 100;
                        }else{
                            break;
                        }
                    } while(claimtimes>=100);
                    return claimable;
                }
            }
        }
        return 0;
    }

    function tokenLastRelease() public view returns(uint){
        if(vestingBoxes[msg.sender].flag==1){
            return vestingBoxes[msg.sender].lastRelease;
        }
        return 0;
    }

    function claimVesting() public payable{
        uint256 claimable = claimableToken();
        if(claimable>0){
            //check if balance is has greater than the claimable;
            require(IERC20(token).balanceOf(address(this))>claimable,"Contract don't have enough balance to cover the transaction.");
            IERC20(token).transfer(msg.sender,claimable);
            vestingBoxes[msg.sender].lastRelease = block.timestamp;
            vestingBoxes[msg.sender].counter += vestingBoxes[msg.sender].temporaryCounter;
            vestingBoxes[msg.sender].remainingBalance -= claimable;
        }
    }

    function distributeTokens() public payable onlyOwner{
        require(deployed==0,"Vesting to address has already been deployed.");
        for(uint i=0; i<=vestaddr.length-1; i++){
            uint256 amount = _fixAmount(vestamount[i]);
            uint256 vestingLock = vestlockMonths[i];
            addVB(vestaddr[i], amount, amount, block.timestamp, vestingLock);
        }
        deployed = 1;
    }

    function addVB(address addr, uint256 amount, uint256 _rBalance, uint lastRelease, uint256 vestingLock) private{
        vestingBox storage vbox = vestingBoxes[addr];
        vbox.totalBalance = amount;
        vbox.remainingBalance = _rBalance;
        vbox.monthsLock = vestingLock;
        vbox.lastRelease = lastRelease;
        vbox.counter = 0;
        vbox.temporaryCounter = 0;
        vbox.flag = 1;
    }
    

}