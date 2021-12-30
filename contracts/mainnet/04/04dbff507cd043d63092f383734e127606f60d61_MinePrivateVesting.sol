/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the decimals places of the token.
     */
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MinePrivateVesting {

    using SafeMath for uint256;

    IERC20 public token;

    uint256 public startDate = 1640995201; // 2022-01-01 00:00:01

    uint256 public endDate =   1659312001; // 2022-08-01 00:00:01
    
    uint256 public unlockAmountTotal;
    
    uint256 public tokenDecimals;
    
    uint256 public maxUnlockTimes;

    address msgSender;
    
    mapping(address => UserVestingInfo) public UserVesting;

    struct UserVestingInfo {
        uint256 totalAmount;
        uint256 firstAmount;
        uint256 unlockAmount;
        uint256 secondUnlock;
        uint256 lastUnlockTime;
    }

    event FirstBySenderEvent(address indexed sender, uint256 amount);

    event UnlockBySenderEvent(address indexed sender, uint256 amount);

    constructor(address _token) public {
        msgSender = msg.sender;
        token = IERC20(_token);
        tokenDecimals = token.decimals();
        maxUnlockTimes = endDate.sub(startDate);
        //add user vesting
        addUserVestingInfo(0x046a5A1FA5986767ec460B998cC78F59c6ee03Ef, 593_750);
        addUserVestingInfo(0x05404219D412C7B5A986Be58BC3a4ee3cE56d6ca, 3_437_500);
        addUserVestingInfo(0x105167FD4edF441cc39113eD43E2169E27687C0F, 593_750);
        addUserVestingInfo(0x11EfF19DC599ee676b6D65bae0A60479a87e889A, 593_750);
        addUserVestingInfo(0x15943509d0C216a9aa36fbFe0095948065433df7, 593_750);
        addUserVestingInfo(0x16E110beD33c0445BE68B957cbbef5cd7e1BBD4f, 1_187_500);
        addUserVestingInfo(0x1cAD40D5c7302249f4cd76B8C6cdaB1d059AcfF1, 1_187_500);
        addUserVestingInfo(0x21d426655A41c0874048DD0a3E29B1cFF5Ec5FB6, 2_375_000);
        addUserVestingInfo(0x2286aa3d41aAd0f901cb94B6e158C86CcCeEcaa1, 875_000);
        addUserVestingInfo(0x29958CbFbE4c73bF3f97fa40cdC9C75290E382db, 2_000_000);
        addUserVestingInfo(0x299ea82E5C48160A623AaBa870Cd9D6E1552B991, 6_250_000);
        addUserVestingInfo(0x2d946C881d2D28b005857658DE1D3a6D48438c3B, 2_968_750);
        addUserVestingInfo(0x2EbD34Bd6E0fB0672B81cB6F721856Fc4145DD68, 1_250_000);
        addUserVestingInfo(0x30A15B722DE7Fb242a54a8497D0Fc84528d3f156, 2_000_000);
        addUserVestingInfo(0x30b8A82c7014454Be3bF67bb172F6312e2639b63, 1_543_750);
        addUserVestingInfo(0x38ADfcfF7ed4496362ba8FdBDBE07b7C0E756537, 593_750);
        addUserVestingInfo(0x38dF87028C451AD521B2FB1576732e9637A66e6f, 1_250_000);
        addUserVestingInfo(0x3904eFc39b16e9CE6483E8bEAC623fca370286D1, 3_750_000);
        addUserVestingInfo(0x3940eb694f814Ddb6C3593C8D35CC61B26904b2B, 1_250_000);
        addUserVestingInfo(0x43BC45bE9cba81F2dc29700D79704cAd69f28b9F, 2_500_000);
        addUserVestingInfo(0x43f4759153292Ac675ec7ff56439c60065ACbC51, 1_187_500);
        addUserVestingInfo(0x440631dbdC0753E45241569C6d63552eAC8E3130, 1_781_250);
        addUserVestingInfo(0x464F0f0842c419001F99cd97a3349e14269e8AF6, 593_750);
        addUserVestingInfo(0x466822e78F979f6285aa40F978cC55A499965dC0, 593_750);
        addUserVestingInfo(0x4B9dC74F34635556eF99Aafb101AF5a6ADCC59B9, 500_000);
        addUserVestingInfo(0x4c59E1B80ca11215c2a53b39651825663048a7ED, 1_781_250);
        addUserVestingInfo(0x4D904df422Ec729d627A289D6913c34D8c347b1D, 1_875_000);
        addUserVestingInfo(0x57ef2a07b9e70cE289e3E6754fcf20512C8403b4, 593_750);
        addUserVestingInfo(0x588384e142E5e1a841137B3d4E73b16E3858450d, 1_781_250);
        addUserVestingInfo(0x58a252cc4073daCC7eaE81e7Ea193FAA13099849, 14_093_750);
        addUserVestingInfo(0x66c109f9A10627D0ac0068b272Da01F61DAB2b25, 1_250_000);
        addUserVestingInfo(0x6Aa80bCA0e8047eac7AF3D47c6983a6611F0DB4C, 2_462_500);
        addUserVestingInfo(0x6cb8e395D1F7c7B00D6594deD6Aa03C5f7cA13C8, 593_750);
        addUserVestingInfo(0x6CDB0A4902C81E9C63De8c486F31e8d5DDc0A9f7, 593_750);
        addUserVestingInfo(0x71d1f0a05F82c0EBd02b8704E3d2337b517a6B3A, 1_625_000);
        addUserVestingInfo(0x72540C9142cd326d2b60a464801D99c04D361dCF, 593_750);
        addUserVestingInfo(0x7a6D0261da79ACa3564E7D6da146774C14259e1d, 1_250_000);
        addUserVestingInfo(0x7cd50d621dE372a92f324b5D62173F4Ba344CE50, 593_750);
        addUserVestingInfo(0x7fCBf5cb2a9dD1BD1e148bF0aa9b049cC0a9e938, 2_137_500);
        addUserVestingInfo(0x82Ba7508f7F1995AB1623258D66Cb4E2B2b8F467, 593_750);
        addUserVestingInfo(0x8317Ff8a1B35F331046395f84B5f6A3eC511a8c1, 296_875);
        addUserVestingInfo(0x84dcCfB3F3e044229fa00e216E2829725579D97f, 2_375_000);
        addUserVestingInfo(0x8522ABD5E2c17722bF046A6d0af75B60ed579546, 500_000);
        addUserVestingInfo(0x8663381606Edfc0F2d5136f7e763b91A6d76ed22, 593_750);
        addUserVestingInfo(0x8937E56f926C04205C27DCe54e273C0dd171Aa36, 593_750);
        addUserVestingInfo(0x8B6Bbd8e858CC515352E5846a9E5b607Ad43826F, 1_187_500);
        addUserVestingInfo(0x8bB948CE8D46ffAc5712247B4a501E874cB9c468, 1_187_500);
        addUserVestingInfo(0x8E2A75e4a07149149C1787d3a55a1736A0c8DDEb, 375_000);
        addUserVestingInfo(0x91406B5d57893E307f042D71C91e223a7058Eb72, 593_750);
        addUserVestingInfo(0x9773d0dA32f0Ef40F3346dFD02f9BAF9f945BbA0, 593_750);
        addUserVestingInfo(0x99DC041D9aDbe5b183efE17586049fa3848df311, 6_250_000);
        addUserVestingInfo(0x9c2D043aAd476515da882DaA28e70C0dc7A63d67, 593_750);
        addUserVestingInfo(0x9E6d8980BC9fc98c5d2db48c46237d12d9873ab0, 950_000);
        addUserVestingInfo(0x9Edc3668e4e990F23663341d0a667EFFdd6F1f56, 593_750);
        addUserVestingInfo(0xa69303D076dFb54d50589C4D018205a409Aa4293, 831_250);
        addUserVestingInfo(0xb1e8fd06A5406262e420662bb22e3B9Bb6daD1a6, 2_937_500);
        addUserVestingInfo(0xb5018Bc174321fFE9e0A38d262e9A448FBD21cdb, 593_750);
        addUserVestingInfo(0xb72D959a9670b546a5759a9d50E8CdB59187F1b5, 1_781_250);
        addUserVestingInfo(0xB7adC067507e9485345C96d1f92ECD9fC9345253, 625_000);
        addUserVestingInfo(0xBA3d570535360bc9383B28691C872959d4A34061, 1_250_000);
        addUserVestingInfo(0xbCd4cB80Ba69376E10082427D6b50a181abCd307, 1_843_750);
        addUserVestingInfo(0xc89F9Ba72752b9d9AC33220dBce309f38316730D, 2_500_000);
        addUserVestingInfo(0xd1B8aD0Dbc972AfC88e68902320100f52bFCF8d8, 593_750);
        addUserVestingInfo(0xD22108e8681D20227DdAaF5722E5C76B34f62c8B, 7_312_500);
        addUserVestingInfo(0xD58E6A2B3Baca952D1f937a4C0F1e88Aa92e4772, 1_562_500);
        addUserVestingInfo(0xDC0D74171B31051d4BFA88de496Ba5Dc700614D1, 593_750);
        addUserVestingInfo(0xe4bcbFD6E636B15eaff352c867b33603a126ADae, 3_562_500);
        addUserVestingInfo(0xe585A1A683214A2504Ef36350f72E8E613048660, 593_750);
        addUserVestingInfo(0xE58Ea0ceD4417f0551Fb82ddF4F6477072DFb430, 1_781_250);
        addUserVestingInfo(0xe5ab3737Ea9214428A3a3320fFc4C3a1Ed0810c8, 375_000);
        addUserVestingInfo(0xE816c2932724655782A81009CAb64BC45446afB0, 1_068_750);
        addUserVestingInfo(0xF1D5f83cAdFB8527E1Ec32bD934FCa87d288de7C, 593_750);
        addUserVestingInfo(0xf41399aAc0D78cC955108E12916204d90FAff875, 7_500_000);
        addUserVestingInfo(0xF5f6a4A2a3466b26C7f161258fc47Ff5800c0116, 5_000_000);
        addUserVestingInfo(0xF76dbc5d9A7465EcEc49700054bF27f88cf9ad05, 1_187_500);
        addUserVestingInfo(0xF789C8fb4349Ba8762b159Ecd29Ac1b65E327bD3, 1_250_000);
        addUserVestingInfo(0xf7B496c0178b1Ee935ea3307188B5b1FbB0cDa59, 890_625);
        addUserVestingInfo(0xfCD1c642a8f73866EbF8526b470a72B31A7e9404, 11_250_000);
        addUserVestingInfo(0xFDa4723b9b4E7ebaa08E38C64Ea7d73A8E0AAc9B, 593_750);
        addUserVestingInfo(0xa5013Bce0182E74FfEf440B3B5dd7173ddCb52cE, 500_000);
    }

    function addUserVestingInfo(address _address, uint256 _totalAmount) public {
        require(msgSender == msg.sender, "You do not have permission to operate");
        require(_address != address(0), "The lock address cannot be a black hole address");
        UserVestingInfo storage _userVestingInfo = UserVesting[_address];
        require(_totalAmount > 0, "Lock up amount cannot be 0");
        require(_userVestingInfo.totalAmount == 0, "Lock has been added");
        _userVestingInfo.totalAmount = _totalAmount.mul(10 ** tokenDecimals);
        _userVestingInfo.firstAmount = _userVestingInfo.totalAmount.mul(125).div(1000); //12.5%
        _userVestingInfo.secondUnlock = _userVestingInfo.totalAmount.sub(_userVestingInfo.firstAmount).div(maxUnlockTimes);
        unlockAmountTotal = unlockAmountTotal.add(_userVestingInfo.totalAmount);
    }

    function blockTimestamp() public virtual view returns(uint256) {
        return block.timestamp;
    }

    function getUnlockTimes() public virtual view returns(uint256) {
        if(blockTimestamp() > startDate) {
            return blockTimestamp().sub(startDate);
        } else {
            return 0;
        }
    }

    function unlockFirstBySender() public {
        UserVestingInfo storage _userVestingInfo = UserVesting[msg.sender];
        require(_userVestingInfo.totalAmount > 0, "The user has no lock record");
        require(_userVestingInfo.firstAmount > 0, "The user has unlocked the first token");
        require(_userVestingInfo.totalAmount > _userVestingInfo.unlockAmount, "The user has unlocked the first token");
        require(blockTimestamp() > startDate, "It's not time to lock and unlock");
        _safeTransfer(msg.sender, _userVestingInfo.firstAmount);
        _userVestingInfo.unlockAmount = _userVestingInfo.unlockAmount.add(_userVestingInfo.firstAmount);

        emit FirstBySenderEvent(msg.sender, _userVestingInfo.firstAmount);
        _userVestingInfo.firstAmount = 0;
    }

    function unlockBySender() public {
        UserVestingInfo storage _userVestingInfo = UserVesting[msg.sender];
        require(_userVestingInfo.totalAmount > 0, "The user has no lock record");
        uint256 unlockAmount = 0;
        if(blockTimestamp() > endDate) {
            require(_userVestingInfo.totalAmount > _userVestingInfo.unlockAmount, "The user has no unlocked quota");
            unlockAmount = _userVestingInfo.totalAmount.sub(_userVestingInfo.unlockAmount);
        } else {
            uint256 unlockTimes = getUnlockTimes();
            require(unlockTimes > _userVestingInfo.lastUnlockTime, "The user has no lock record");
            unlockAmount = unlockTimes.sub(_userVestingInfo.lastUnlockTime).mul(_userVestingInfo.secondUnlock);
            _userVestingInfo.lastUnlockTime = unlockTimes;
        }
        _safeTransfer(msg.sender, unlockAmount);
        _userVestingInfo.unlockAmount = _userVestingInfo.unlockAmount.add(unlockAmount);

        emit UnlockBySenderEvent(msg.sender, unlockAmount);
    }

    function _safeTransfer(address _unlockAddress, uint256 _unlockToken) private {
        require(balanceOf() >= _unlockToken, "Insufficient available balance for transfer");
        token.transfer(_unlockAddress, _unlockToken);
    }

    function balanceOf() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function balanceOfBySender() public view returns(uint256) {
        return token.balanceOf(msg.sender);
    }

    function balanceOfByAddress(address _address) public view returns(uint256) {
        return token.balanceOf(_address);
    }
}