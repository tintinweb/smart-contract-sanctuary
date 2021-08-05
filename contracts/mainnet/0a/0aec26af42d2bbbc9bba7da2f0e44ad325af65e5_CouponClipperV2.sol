/**
 *Submitted for verification at Etherscan.io on 2020-11-14
*/

pragma solidity 0.7.4;
// SPDX-License-Identifier: MIT

// deployed on mainnet at: 0xd1A2e3AEdB842Fab85A4cF73bE07770DEcE14fa4

interface IESDS {
    function redeemCoupons(uint256 _epoch, uint256 _couponAmount) external;
    function transferCoupons(address _sender, address _recipient, uint256 _epoch, uint256 _amount) external;
    function totalRedeemable() external view returns (uint256);
    function epoch() external view returns (uint256);
    function balanceOfCoupons(address _account, uint256 _epoch) external view returns (uint256);
    function advance() external;
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ICHI {
    function freeFromUpTo(address _addr, uint256 _amount) external returns (uint256);
}

// @notice Lets anybody trustlessly redeem coupons on anyone else's behalf for a fee (minimum fee is 2%).
//    Requires that the coupon holder has previously approved this contract via the ESDS `approveCoupons` function.
// @dev Bots should scan for the `CouponApproval` event emitted by the ESDS `approveCoupons` function to find out which 
//    users have approved this contract to redeem their coupons.
// @dev This contract's API should be backwards compatible with CouponClipper V1.
contract CouponClipperV2 {
    using SafeMath for uint256;

    IERC20 constant private ESD = IERC20(0x36F3FD68E7325a35EB768F1AedaAe9EA0689d723);
    IESDS constant private ESDS = IESDS(0x443D2f2755DB5942601fa062Cc248aAA153313D3);
    ICHI  constant private CHI = ICHI(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    uint256 constant private HOUSE_RATE = 100; // 100 basis points (1%) -- fee taken by the house
    
    address public house = 0x7Fb471734271b732FbEEd4B6073F401983a406e1; // collector of house take
    
    event SetOffer(address indexed user, uint256 offer);
    
    // frees CHI from msg.sender to reduce gas costs
    // requires that msg.sender has approved this contract to use their CHI
    modifier useCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + (16 * msg.data.length);
        CHI.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    // The basis points offered by coupon holders to have their coupons redeemed -- default is 200 bps (2%)
    // E.g., offers[_user] = 500 indicates that _user will pay 500 basis points (5%) to the caller
    mapping(address => uint256) private offers;

    // @notice Gets the number of basis points the _user is offering the bots
    // @dev The default value is 100 basis points (2%).
    //   That is, `offers[_user] = 0` is interpretted as 2%.
    //   This way users who are comfortable with the default 2% offer don't have to make any additional contract calls.
    // @param _user The account whose offer we're looking up.
    // @return The number of basis points the account is offering to have their coupons redeemed
    function getOffer(address _user) public view returns (uint256) {
        uint256 offer = offers[_user];
        return offer < 200 ? 200 : offer;
    }

    // @notice Allows msg.sender to change the number of basis points they are offering.
    // @dev _newOffer must be at least 200 (2%) and no more than 10_000 (100%)
    // @dev A user's offer cannot be *decreased* during the 15 minutes before the epoch advance (frontrun protection)
    // @param _offer The number of basis points msg.sender wants to offer to have their coupons redeemed.
    function setOffer(uint256 _newOffer) external {
        require(_newOffer <= 10_000, "Offer exceeds 100%.");
        require(_newOffer >= 200, "Minimum offer is 2%.");
        uint256 oldOffer = offers[msg.sender];
        if (_newOffer < oldOffer) {
            uint256 nextEpoch = ESDS.epoch() + 1;
            uint256 nextEpochStartTIme = getEpochStartTime(nextEpoch);
            uint256 timeUntilNextEpoch = nextEpochStartTIme.sub(block.timestamp);
            require(timeUntilNextEpoch > 15 minutes, "You cannot reduce your offer within 15 minutes of the next epoch");
        }
        
        offers[msg.sender] = _newOffer;
        
        emit SetOffer(msg.sender, _newOffer);
    }
    
    // @notice Internal logic used to redeem coupons on the coupon holder's bahalf
    // @param _user Address of the user holding the coupons (and who has approved this contract)
    // @param _epoch The epoch in which the _user purchased the coupons
    // @param _couponAmount The number of coupons to redeem (18 decimals)
    function _redeem(address _user, uint256 _epoch, uint256 _couponAmount) internal {
        
        // pull user's coupons into this contract (requires that the user has approved this contract)
        ESDS.transferCoupons(_user, address(this), _epoch, _couponAmount); // @audit-info : reverts on failure
        
        // redeem the coupons for ESD
        ESDS.redeemCoupons(_epoch, _couponAmount); // @audit-info : reverts on failure
        
        // pay the fees
        uint256 botFeeRate = getOffer(_user).sub(HOUSE_RATE);
        uint256 botFee = _couponAmount.mul(botFeeRate).div(10_000);
        uint256 houseFee = _couponAmount.mul(HOUSE_RATE).div(10_000);
        ESD.transfer(house, houseFee); // @audit-info : reverts on failure
        ESD.transfer(msg.sender, botFee); // @audit-info : reverts on failure
        
        // send the ESD to the user
        ESD.transfer(_user, _couponAmount.sub(houseFee).sub(botFee)); // @audit-info : reverts on failure
    }
    
    // @notice Allows anyone to redeem coupons for ESD on the coupon-holder's bahalf
    // @dev Backwards compatible with CouponClipper V1.
    function redeem(address _user, uint256 _epoch, uint256 _couponAmount) external {
        _redeem(_user, _epoch, _couponAmount);
    }
    
    // @notice Advances the epoch (if needed) and redeems the max amount of coupons possible
    //    Also frees CHI tokens to save on gas (requires that msg.sender has CHI tokens in their
    //    account and has approved this contract to spend their CHI).
    // @param _user The user whose coupons will attempt to be redeemed
    // @param _epoch The epoch in which the coupons were created
    // @param _targetEpoch The epoch that is about to be advanced _to_.
    //    E.g., if the current epoch is 220 and we are about to advance to to epoch 221, then _targetEpoch
    //    would be set to 221. The _targetEpoch is the epoch in which the coupon redemption will be attempted.
    function advanceAndRedeemMax(address _user, uint256 _epoch, uint256 _targetEpoch) external useCHI {
        // End execution early if tx is mined too early
        uint256 targetEpochStartTime = getEpochStartTime(_targetEpoch);
        if (block.timestamp < targetEpochStartTime) { return; }
        
        // advance epoch if it has not already been advanced 
        if (ESDS.epoch() != _targetEpoch) { ESDS.advance(); }
        
        // get max redeemable amount
        uint256 totalRedeemable = ESDS.totalRedeemable();
        if (totalRedeemable == 0) { return; } // no coupons to redeem
        uint256 userBalance = ESDS.balanceOfCoupons(_user, _epoch);
        if (userBalance == 0) { return; } // no coupons to redeem
        uint256 maxRedeemableAmount = totalRedeemable < userBalance ? totalRedeemable : userBalance;
        
        // attempt to redeem coupons
        _redeem(_user, _epoch, maxRedeemableAmount);
    }

    
    // @notice Returns the timestamp at which the _targetEpoch starts
    function getEpochStartTime(uint256 _targetEpoch) public pure returns (uint256) {
        return _targetEpoch.sub(106).mul(28800).add(1602201600);
    }
    
    // @notice Allows house address to change the house address
    function changeHouseAddress(address _newAddress) external {
        require(msg.sender == house);
        house = _newAddress;
    }
}



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