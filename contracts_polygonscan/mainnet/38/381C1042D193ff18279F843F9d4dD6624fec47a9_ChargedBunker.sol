// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./libs/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDofinChef.sol";
import { HLS_charged } from "./libs/HLS_charged.sol";

//import "./utils/ProofToken.sol";


/// @title Polygon ChargedBunker
contract ChargedBunker {

// -------------------------------------------------- public variables ---------------------------------------------------

    struct User {
        uint256 Proof_Token_Amount;
        uint256 Deposited_Token_Amount;
        uint256 Deposited_Value;
        uint256 Deposit_Block_Timestamp;
    }

    struct DofinChefStruct {
        address dofinchef_addr;
        uint256 pool_id;
    }

    HLS_charged.HLSConfig private HLSConfig;
    HLS_charged.Position private Position;
    DofinChefStruct public OwnDofinChef;

    using SafeMath for uint256;

    uint256 public total_deposit_limit; // in no decimals ex: 100 DAI => 100
    uint256 public deposit_limit; // in no decimals . ex: 10000 DAI => 10000
    uint256 private temp_free_funds; // IERC20(Position.token).balacneOf(address(this));
    uint256 public totalSupply_;
    bool public TAG = false;
    bool public PositionStatus = false;
    bool public singleFarm = true;
    address private dofin;
    address private factory;
    string public name = "Charged Proof Token";
    string public symbol = "CP";

    mapping (address => User) private users;
    event Received(address, uint);

// ----------------------------------------- config things -------------------------------------------


    function sendFees() external payable {
        emit Received(msg.sender, msg.value);
    }

    function feesBack() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        uint256 contract_balance = payable(address(this)).balance;
        payable(address(msg.sender)).transfer(contract_balance);
    }

    function checkCaller() public view returns (bool) {
        if (msg.sender == factory || msg.sender == dofin) {
            return true;
        }
        return false;
    }

    function initialize(uint256 _funds_percentage, address[10] memory _addrs, DofinChefStruct memory _DofinChefStruct) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }
        Position = HLS_charged.Position({
            token_amount: 0,
            supply_amount: 0,
            crtoken_amount: 0,
            borrowed_token_a_amount: 0,
            borrowed_token_b_amount: 0,
            token_a_amount: 0,
            token_b_amount: 0,
            lp_token_amount: 0,
            liquidity_a: 0,
            liquidity_b: 0,

            funds_percentage: _funds_percentage,
            total_debts: 0,

            token: _addrs[0],
            supply_crtoken: _addrs[1],
            borrowed_crtoken_a: _addrs[2],
            borrowed_crtoken_b: _addrs[3],
            token_a: _addrs[4],
            token_b: _addrs[5],
            lp_token: _addrs[6],
            dQuick_addr: _addrs[7],
            Quick_addr: _addrs[8],
            WMatic_addr: _addrs[9]

        });
        factory = msg.sender;
        OwnDofinChef = _DofinChefStruct;
    }
    
    function setConfig(address[8] memory _config, address _dofin, uint256[2] memory _deposit_limit, bool _singleFarm) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }
        HLSConfig.token_oracle = _config[0];
        HLSConfig.token_a_oracle = _config[1];
        HLSConfig.token_b_oracle = _config[2];
        HLSConfig.Quick_oracle = _config[3];
        HLSConfig.Matic_oracle = _config[4];
        HLSConfig.router =_config[5];
        HLSConfig.comptroller = _config[6];
        HLSConfig.staking_reward = _config[7];

        dofin = _dofin;
        deposit_limit = _deposit_limit[0];
        total_deposit_limit = _deposit_limit[1];
        singleFarm = _singleFarm ;
        // Set Tag
        setTag(true);
    }

    function setTag(bool _tag) public {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        TAG = _tag;
        if (_tag == true) {
            address[] memory crtokens = new address[] (3);
            crtokens[0] = address(0x0000000000000000000000000000000000000020);
            crtokens[1] = address(0x0000000000000000000000000000000000000001);
            crtokens[2] = Position.supply_crtoken;
            HLS_charged.enterMarkets(HLSConfig.comptroller, crtokens);
        } else {
            HLS_charged.exitMarket(HLSConfig.comptroller, Position.supply_crtoken);
        }
    }

// ---------------------------------------- getters & check ------------------------------------------
    
    function checkAddNewFunds() public view returns (uint256) {
        uint256 free_funds = IERC20(Position.token).balanceOf(address(this));
        if (free_funds > temp_free_funds) {
            if (Position.token_a_amount == 0 && Position.token_b_amount == 0) {
                // Need to enter
                return 1;
            } else {
                // Need to rebalance
                return 2;
            }
        }
        return 0;
    }

    function balanceOf(address _account) external view returns (uint256) {
        // Only return totalSupply amount
        // Function name call balanceOf if because DofinChef
        return totalSupply_;
    }

    function getConfig() external view returns(HLS_charged.HLSConfig memory) {
        
        return HLSConfig;
    }
    
    function getPosition() external view returns(HLS_charged.Position memory) {
        
        return Position;
    }

    function getUser(address _account) external view returns (User memory) {
        
        return users[_account];
    }

    function getWithdrawAmount() external view returns (uint256) {
        User memory user = users[msg.sender];
        uint256 withdraw_amount = user.Proof_Token_Amount;
        uint256 totalAssets = getTotalAssets();
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        if (withdraw_amount > user.Proof_Token_Amount) {
            return 0;
        }
        uint256 dofin_value;
        uint256 user_value;
        if (value > user.Deposited_Token_Amount) {
            dofin_value = value.sub(user.Deposited_Token_Amount).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        
        return user_value;
    }
    
    /// @dev input "_deposit_amount" in deNormalized decimal. return "shares" is in decimals==18
    function getDepositAmountOut(uint256 _deposit_amount) public view returns (uint256, uint256) {
        require(_deposit_amount <= deposit_limit.mul(10**IERC20(Position.token).decimals()), "Deposit too much!");
        require(_deposit_amount > 0, "Deposit amount must be larger than 0.");

        (uint256 norm_deposit_amt, uint256 norm_total_deposit_limit_amt) = HLS_charged.getNormalizedAmount(Position.token, Position.token, _deposit_amount, total_deposit_limit.mul(10**IERC20(Position.token).decimals()));
        (uint256 norm_deposit_value, uint256 norm_total_deposit_limit_value) = HLS_charged.getValueFromAmount(HLSConfig.token_oracle, HLSConfig.token_oracle, norm_deposit_amt, norm_total_deposit_limit_amt);
        uint256 totalAssets = getTotalAssets();
        require(norm_total_deposit_limit_value >= totalAssets.add(norm_deposit_value), "Deposit get limited");

        uint256 shares;

        if (totalSupply_ > 0) {
            shares = norm_deposit_value.mul(totalSupply_).div(totalAssets);
        } else {
            shares = norm_deposit_value;
        }
        return (shares,norm_deposit_value);
    }

    /// @dev In Normalized Value
    function getTotalAssets() public view returns (uint256) {

        // Free fund amount -> norm_amount -> norm_value
        uint256 freeFund_value = HLS_charged.getTokenValueFromDeNormAmount(Position.token, HLSConfig.token_oracle, IERC20(Position.token).balanceOf(address(this)));

        // Total Debts amount from Cream, Quickswap
        uint256 totalDebts = Position.total_debts;
        
        return freeFund_value.add(totalDebts);
    }


// -------------------------------------- manipulative functions -------------------------------------

    function rebalance() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        _rebalance();
    }

    function _rebalance() private {
        require(TAG == true, 'TAG ERROR.');
        require(PositionStatus, "POSITIONSTATUS ERROR");
        _exit(1);
        _enter(1);
    }
    
    function rebalanceWithRepay() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        require(PositionStatus, "POSITIONSTATUS ERROR");
        _exit(2);
        _enter(2);
    }
    
    function rebalanceWithoutRepay() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        require(PositionStatus, "POSITIONSTATUS ERROR");
        _exit(3);
        _enter(3);
    }
    
    function autoCompound(uint256 _amountIn, address[] calldata _path, uint256 _wrapType) external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        HLS_charged.autoCompound(HLSConfig.router, _amountIn, _path, _wrapType);
        Position.token_amount = IERC20(Position.token).balanceOf(address(this));
        Position.token_a_amount = IERC20(Position.token_a).balanceOf(address(this));
        Position.token_b_amount = IERC20(Position.token_b).balanceOf(address(this));
        Position.total_debts = HLS_charged.getTotalDebts(HLSConfig, Position, singleFarm);

    }
    
    function enter(uint256 _type) external {
        require(checkCaller(), "Only factory or dofin can call this function");
        _enter(_type);
    }
    
    function _enter(uint256 _type) private {
        require(TAG, 'TAG ERROR.');
        require(!PositionStatus, 'POSITIONSTATUS ERROR');
        // Position = HLS_charged.enterPosition(HLSConfig, Position, _type, singleFarm);
        Position = HLS_charged.enterPosition(HLSConfig, Position, _type, singleFarm);
        temp_free_funds = IERC20(Position.token).balanceOf(address(this));
        PositionStatus = true;
    }
    
    function exit(uint256 _type) external {
        require(checkCaller(), "Only factory or dofin can call this function");
        _exit(_type);        
    }
    
    function _exit(uint256 _type) private {
        require(TAG, 'TAG ERROR.');
        require(PositionStatus, 'POSITIONSTATUS ERROR');
        Position = HLS_charged.exitPosition(HLSConfig, Position, _type, singleFarm);
        PositionStatus = false;
    }
    
    function deposit(uint256 _deposit_amount) external {
        require(TAG ==  true, 'TAG ERROR.');
        // Calculation of bunker proof Token amount
        (uint256 shares, uint256 deposited_value) = getDepositAmountOut(_deposit_amount);
        
        // Record user deposit amount
        User memory user = users[msg.sender];
        user.Proof_Token_Amount = user.Proof_Token_Amount.add(shares);
        user.Deposited_Token_Amount = user.Deposited_Token_Amount.add(_deposit_amount);
        user.Deposited_Value = user.Deposited_Value.add(deposited_value);
        user.Deposit_Block_Timestamp = block.timestamp;
        users[msg.sender] = user;

        // Modify total supply
        totalSupply_ += shares;
        // Transfer user's token to bunker
        IERC20(Position.token).transferFrom(msg.sender, address(this), _deposit_amount);
        // Stake
        IDofinChef(OwnDofinChef.dofinchef_addr).deposit(OwnDofinChef.pool_id, shares, msg.sender);

        uint256 newFunds = checkAddNewFunds();
        if (newFunds == 1) {
            _enter(1);
        } else if (newFunds == 2) {
            _rebalance();
        }
    }
    
    function withdraw() external {
        require(TAG == true, 'TAG ERROR.');
        User memory user = users[msg.sender];
        uint256 withdraw_amount = user.Proof_Token_Amount;
        uint256 totalAssets = getTotalAssets();
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        require(withdraw_amount > 0, "Proof token amount insufficient");
        require(block.timestamp > user.Deposit_Block_Timestamp, "Deposit and withdraw in same block");
        // If no enough amount of free funds can transfer will trigger exit position
        uint256 free_fund_value = HLS_charged.getTokenValueFromDeNormAmount(Position.token, HLSConfig.token_oracle, IERC20(Position.token).balanceOf(address(this)));
        if (value > free_fund_value) {
            _exit(1);
            totalAssets = HLS_charged.getTokenValueFromDeNormAmount(Position.token, HLSConfig.token_oracle, IERC20(Position.token).balanceOf(address(this)));
            value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        }
        // Withdraw pToken
        IDofinChef(OwnDofinChef.dofinchef_addr).withdraw(OwnDofinChef.pool_id, withdraw_amount, msg.sender);
        // Modify total supply
        totalSupply_ -= withdraw_amount;
        // Will charge 20% fees
        uint256 dofin_value;
        uint256 user_value;
        if (value > user.Deposited_Value.add(10**IERC20(Position.token).decimals())) {
            dofin_value = value.sub(user.Deposited_Value).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        // Modify user state data
        user.Proof_Token_Amount = 0;
        user.Deposited_Token_Amount = 0;
        user.Deposited_Value = 0;
        user.Deposit_Block_Timestamp = 0;
        users[msg.sender] = user;
        // transform from Normalized Value to DeNormalized Amount
        (uint256 user_amount, uint256 dofin_amount) = HLS_charged.getAmountFromValue(HLSConfig.token_oracle, HLSConfig.token_oracle, user_value, dofin_value);
        (user_amount, dofin_amount) = HLS_charged.getDeNormalizedAmount(Position.token, Position.token, user_amount, dofin_amount);
        // Approve for withdraw
        IERC20(Position.token).approve(address(this), user_amount);
        // Transfer token to user
        IERC20(Position.token).transferFrom(address(this), msg.sender, user_amount);
        if (dofin_amount > IERC20(Position.token).balanceOf(address(this))) {
            dofin_amount = IERC20(Position.token).balanceOf(address(this));
        }
        // Transfer token to dofin
        IERC20(Position.token).approve(address(this), dofin_amount);
        IERC20(Position.token).transferFrom(address(this), dofin, dofin_amount);

    }
    
    function emergencyWithdrawal() external {
        require(TAG == false, 'NOT EMERGENCY');
        User memory user = users[msg.sender];
        uint256 pTokenBalance = user.Proof_Token_Amount;
        require(pTokenBalance > 0,  "Incorrect quantity of Proof Token");
        require(user.Proof_Token_Amount > 0, "Not depositor");

        // Approve for withdraw
        IERC20(Position.token).approve(address(this), user.Deposited_Token_Amount);
        IERC20(Position.token).transferFrom(address(this), msg.sender, user.Deposited_Token_Amount);
        
        // Modify user state data
        user.Proof_Token_Amount = 0;
        user.Deposited_Token_Amount = 0;
        user.Deposit_Block_Timestamp = 0;
        user.Deposited_Value = 0;
        users[msg.sender] = user;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/math/SafeMath.sol)

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
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

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

pragma solidity >=0.4.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);
    
    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);
    
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
pragma solidity >=0.5.0;

import './IERC20.sol';

interface IDofinChef {

    function poolLength() external view returns (uint256);

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external;

    // Deposit LP tokens to MasterChef by Bunker for FinV allocation.
    function deposit(uint256 _pid, uint256 _amount, address _sender) external;

    // Withdraw LP tokens from MasterChef to Bunker.
    function withdraw(uint256 _pid, uint256 _amount, address _sender) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";

import "../interfaces/chainlink/LinkOracle.sol";

import "../interfaces/cream/CErc20Delegator.sol";
import "../interfaces/cream/ComptrollerInterface.sol";

import "../interfaces/quickswap/IQuickRouter02.sol";
import "../interfaces/quickswap/IDquick.sol";
import "../interfaces/quickswap/IQuickPair.sol";
import "../interfaces/quickswap/IQuickSingleStakingReward.sol";
import "../interfaces/quickswap/IQuickDualStakingReward.sol";

/// @title High level system for charged bunker
library HLS_charged {


// ------------------------------------------------- public variables ---------------------------------------------------

    using SafeMath for uint256;

    // HighLevelSystem config
    struct HLSConfig {
        address token_oracle; // link oracle of token that user deposit into our bunker
        address token_a_oracle; // link oralce of token a that we borrowed out from cream
        address token_b_oracle; // link oracle of token b that we borrowed out from cream
        address Quick_oracle ;
        address Matic_oracle ;

        address router; // Address of Quickswap router contract : 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        // address factory;// Address of Quickswap factory contract: 
        address comptroller; // Address of cream comptroller contract.

        address staking_reward ;
    }
    
    // Position
    struct Position {
        uint256 token_amount;
        uint256 supply_amount; // 紀錄supply給cream多少 , deNormalized
        uint256 crtoken_amount; // balanceOf(supply_crtoken)
        uint256 borrowed_token_a_amount;
        uint256 borrowed_token_b_amount;
        uint256 token_a_amount; // deNormalized
        uint256 token_b_amount; // deNormalized
        uint256 lp_token_amount;
        uint256 liquidity_a;
        uint256 liquidity_b;

        uint256 funds_percentage; // 從cashbox離開的錢的百分比
        uint256 total_debts; // 所有在buncker外面的錢

        address token; // token that user deposit into charged bunker, ex: USDC
        address supply_crtoken; // 要supply跟withdraw的address, ex: crUSDC
        address borrowed_crtoken_a; // the address to borrow from and repay to , ex: crUSDT_addr
        address borrowed_crtoken_b; // the address to borrow from and repay to , ex: crWETH_addr
        address token_a; // after supplying to Cream, the token borrowed form borrowed_crtoken_a, ex: USDT_addr
        address token_b; // after supplying to Cream, the token borrowed form borrowed_crtoken_b, ex: WETH_addr
        address lp_token; // after adding liq into pancake , get lp_token, that is quick-pair's address, ex: WETH_USDT pair

        address dQuick_addr ; // reward of singleFarm
        address Quick_addr ; // need to transform dQuick to Quick in order to calculate Value.
        address WMatic_addr ; // reward of singleFarm and dualFarm

    }

// ---------------------------------------- charged buncker manipulative function ---------------------------------------
    
    
    /// @dev Main entry function to borrow and enter a given position.
    // function enterPosition(HLSConfig memory self, Position memory _position, uint256 _type, bool _singleFarm) external returns (Position memory) { 
    //     // Supply Position.token to Cream
    //     if (_type == 1) { _position = _supplyCream(_position); }
        
    //     // Borrow Position.token_a, Position.token_b from Cream
    //     if (_type == 1 || _type == 2) { _position = _borrowCream(self, _position); }
        
    //     // Add liquidity and stake
    //     if (_type == 1 || _type == 2 || _type == 3) {
    //         _position = _addLiquidity(self, _position);
    //         _stake(self, _position, _singleFarm);
    //     }
        
    //     _position.total_debts = getTotalDebts(self, _position, _singleFarm);

    //     return _position;
    // }


    /// @dev test another form of _type 1, 2, 3
    function enterPosition(HLSConfig memory self, Position memory _position, uint256 _type, bool _singleFarm) external returns (Position memory) { 
        
        if (_type == 1) { 
            _position = _supplyCream(_position); 
            _position = _borrowCream(self, _position);
            _position = _addLiquidity(self, _position);
            _stake(self, _position, _singleFarm);
         }
        
        else if ( _type == 2) {
            _position = _borrowCream(self, _position);
            _position = _addLiquidity(self, _position);
            _stake(self, _position, _singleFarm);
        }

        else if ( _type == 3) {
            _position = _addLiquidity(self, _position);
            _stake(self, _position, _singleFarm);
        }
        
        _position.total_debts = getTotalDebts(self, _position, _singleFarm);

        return _position;
    }

    /// @dev Main exit function to exit and repay a given position.
    function exitPosition(HLSConfig memory self, Position memory _position, uint256 _type, bool _singleFarm) external returns (Position memory) {
        
        // Unstake
        if (_type == 1 || _type == 2 || _type == 3) {
            _position = _unstake(self, _position, _singleFarm);
            _position = _removeLiquidity(self, _position);
        }
        // Repay
        if (_type == 1 || _type == 2) { 
            _position  = _repay(self, _position); 
        }
        // Redeem
        if (_type == 1) { _position = _redeemCream(_position); }

        _position.total_debts = getTotalDebts(self, _position, _singleFarm);

        return (_position);
    }
    
    /// @dev claim dQuick (and WMATIC/NewToken, if it's dual farm) , transfer dQUick into Quick (since Link doesn't have dQuick oracle)
    function claimReward(HLSConfig memory self, Position memory _position, bool _singleFarm) public returns(uint256) {

        if ( _singleFarm == true ) {
            IQuickSingleStakingReward(self.staking_reward).getReward() ;
        }

        else if ( _singleFarm == false) {  
            IQuickDualStakingReward(self.staking_reward).getReward() ;
        }

        uint256 dQuick_balance = IDquick(_position.dQuick_addr).balanceOf(address(this));
        IDquick(_position.dQuick_addr).leave(dQuick_balance);

        uint256 Quick_reward = IERC20(_position.Quick_addr).balanceOf(address(this)) ; // amount, in Normalized deciamls
        uint256 WMatic_reward = IERC20(_position.WMatic_addr).balanceOf(address(this)) ;// amount, in Normalized deciamls
        (Quick_reward , WMatic_reward) = getValueFromAmount(self.Quick_oracle, self.Matic_oracle, Quick_reward, WMatic_reward);

        return Quick_reward.add(WMatic_reward);

    }
    
    /// @dev Auto swap "Quick" or WMATIC back to some token we want.
    function autoCompound(address _router , uint256 _amountIn, address[] calldata _path, uint256 _wrapType) external {
        uint256 amountInSlippage = _amountIn.mul(98).div(100);
        uint256[] memory amountOutMinArray = IQuickRouter02(_router).getAmountsOut(amountInSlippage, _path);
        uint256 amountOutMin = amountOutMinArray[amountOutMinArray.length - 1];
        address token = _path[0];
        if (_wrapType == 1) {

            IERC20(token).approve(_router, _amountIn);
            
            IQuickRouter02(_router).swapExactTokensForTokens(_amountIn, amountOutMin, _path, address(this), block.timestamp);    

        } else if (_wrapType == 2) {

            IERC20(token).approve(_router, _amountIn);

            IQuickRouter02(_router).swapExactTokensForETH(_amountIn, amountOutMin, _path, address(this), block.timestamp);

        } else if (_wrapType == 3) {

            IQuickRouter02(_router).swapExactETHForTokens{value: _amountIn}(amountOutMin, _path, address(this), block.timestamp);

        }
    }

// ----------- cream manipulative function ------------


    /// @dev Supplies 'amount' worth of tokens, deNormalized, to cream.
    function _supplyCream(Position memory _position) private returns(Position memory) {
        uint256 supply_amount = IERC20(_position.token).balanceOf(address(this)).mul(_position.funds_percentage).div(100);
        
        // Approve for supplying to Cream 
        IERC20(_position.token).approve(_position.supply_crtoken, supply_amount);
        require(CErc20Delegator(_position.supply_crtoken).mint(supply_amount) == 0, "Supply not work");

        // Update posititon amount data
        _position.token_amount = IERC20(_position.token).balanceOf(address(this));
        _position.crtoken_amount = IERC20(_position.supply_crtoken).balanceOf(address(this));
        _position.supply_amount = supply_amount;

        return _position;
    }

    /// @dev Borrow the required tokens (for a given pool of Quickswap) from Cream.
    function _borrowCream(HLSConfig memory self, Position memory _position) private returns(Position memory) {

        uint256 amt = _position.supply_amount.mul(75).div(100); // only borrow 75% worth of supplied token's value
        uint256 norm_amt = amt.mul(10**18).div(10**IERC20(_position.token).decimals()); // normalize
        uint256 token_price = uint256(LinkOracle(self.token_oracle).latestAnswer());
        uint256 norm_desired_total_value = norm_amt.mul(token_price).div(10**LinkOracle(self.token_oracle).decimals()); // get Normalized Value
        uint256 value_a_desired = norm_desired_total_value.div(2);
        uint256 value_b_desired = norm_desired_total_value.sub(value_a_desired);

        (uint256 token_a_borrow_amount, uint256 token_b_borrow_amount) = getAmountFromValue(self.token_a_oracle, self.token_b_oracle, value_a_desired, value_b_desired);
        (token_a_borrow_amount, token_b_borrow_amount) = getDeNormalizedAmount(_position.token_a, _position.token_b, token_a_borrow_amount, token_b_borrow_amount);

        require(CErc20Delegator(_position.borrowed_crtoken_a).borrow(token_a_borrow_amount) == 0, "Borrow token a not work");
        require(CErc20Delegator(_position.borrowed_crtoken_b).borrow(token_b_borrow_amount) == 0, "Borrow token b not work");

        // Update posititon amount data
        _position.borrowed_token_a_amount = token_a_borrow_amount;
        _position.borrowed_token_b_amount = token_b_borrow_amount;
        _position.token_a_amount = IERC20(_position.token_a).balanceOf(address(this));
        _position.token_b_amount = IERC20(_position.token_b).balanceOf(address(this));

        return _position;
    }
    
    /// @dev Redeem amount worth of crtokens back.
    function _redeemCream(Position memory _position) private returns (Position memory) {
        uint256 redeem_amount = IERC20(_position.supply_crtoken).balanceOf(address(this));

        // Approve for Cream redeem
        IERC20(_position.supply_crtoken).approve(_position.supply_crtoken, redeem_amount);
        require(CErc20Delegator(_position.supply_crtoken).redeem(redeem_amount) == 0, "Redeem not work");

        // Update posititon amount data
        _position.token_amount = IERC20(_position.token).balanceOf(address(this));
        _position.crtoken_amount = IERC20(_position.supply_crtoken).balanceOf(address(this));
        _position.supply_amount = 0;

        return _position;
    }

    /// @dev Swap for repay.
    function _repaySwap(HLSConfig memory self, uint256 _amountOut, address _token) private {
        address[] memory path = new address[](2);
        path[0] = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        path[1] = _token;
        uint256[] memory amountInMaxArray = IQuickRouter02(self.router).getAmountsIn(_amountOut, path);
        uint256 WMatic = amountInMaxArray[0];
        IQuickRouter02(self.router).swapETHForExactTokens{value: WMatic}(_amountOut, path, address(this), block.timestamp);
    }

    /// @dev Repay the tokens borrowed from cream.
    function _repay(HLSConfig memory self, Position memory _position) private returns (Position memory) {
        uint256 borrowed_a = CErc20Delegator(_position.borrowed_crtoken_a).borrowBalanceCurrent(address(this));
        uint256 current_a_balance = IERC20(_position.token_a).balanceOf(address(this));
        if (borrowed_a > current_a_balance) {
            _repaySwap(self, borrowed_a.sub(current_a_balance), _position.token_a);
        }

        uint256 borrowed_b = CErc20Delegator(_position.borrowed_crtoken_b).borrowBalanceCurrent(address(this));
        uint256 current_b_balance = IERC20(_position.token_b).balanceOf(address(this));
        if (borrowed_b > current_b_balance) {
            _repaySwap(self, borrowed_b.sub(current_b_balance), _position.token_b);
        }

        // Approve for Cream repay
        IERC20(_position.token_a).approve(_position.borrowed_crtoken_a, borrowed_a);
        IERC20(_position.token_b).approve(_position.borrowed_crtoken_b, borrowed_b);
        require(CErc20Delegator(_position.borrowed_crtoken_a).repayBorrow(borrowed_a) == 0, "Repay token a not work");
        require(CErc20Delegator(_position.borrowed_crtoken_b).repayBorrow(borrowed_b) == 0, "Repay token b not work");
        
        // Update posititon amount data
        _position.borrowed_token_a_amount = CErc20Delegator(_position.borrowed_crtoken_a).borrowBalanceCurrent(address(this));
        _position.borrowed_token_b_amount = CErc20Delegator(_position.borrowed_crtoken_b).borrowBalanceCurrent(address(this));
        _position.token_a_amount = IERC20(_position.token_a).balanceOf(address(this));
        _position.token_b_amount = IERC20(_position.token_b).balanceOf(address(this));  

        return (_position);
    }

    /// @dev Need to enter market first then borrow.
    function enterMarkets(address _comptroller, address[] memory _crtokens) external {
        
        ComptrollerInterface(_comptroller).enterMarkets(_crtokens);
    }

    /// @dev Exit market to stop bunker borrow on Cream.
    function exitMarket(address _comptroller, address _crtoken) external {
        
        ComptrollerInterface(_comptroller).exitMarket(_crtoken);
    }


// --------- quickswap manipulative function ----------


    function _addLiquidity(HLSConfig memory self, Position memory _position) private returns (Position memory) {


        (uint256 max_available_staking_a, uint256 max_available_staking_b) = getFreeFunds(_position.token_a, _position.token_b, _position.funds_percentage, false, false);
        
        uint256 max_available_staking_a_slippage = max_available_staking_a.mul(98).div(100);
        uint256 max_available_staking_b_slippage = max_available_staking_b.mul(98).div(100);

        (uint256 reserves0, uint256 reserves1, ) = IQuickPair(_position.lp_token).getReserves();
        uint256 min_a_amnt = IQuickRouter02(self.router).quote(max_available_staking_b_slippage, reserves1, reserves0);
        uint256 min_b_amnt = IQuickRouter02(self.router).quote(max_available_staking_a_slippage, reserves0, reserves1);

        min_a_amnt = max_available_staking_a_slippage.min(min_a_amnt);
        min_b_amnt = max_available_staking_b_slippage.min(min_b_amnt);

        // Approve for PancakeSwap addliquidity
        IERC20(_position.token_a).approve(self.router, max_available_staking_a);
        IERC20(_position.token_b).approve(self.router, max_available_staking_b);
        (uint256 liquidity_a, uint256 liquidity_b, ) = IQuickRouter02(self.router).addLiquidity(_position.token_a, _position.token_b, max_available_staking_a, max_available_staking_b, min_a_amnt, min_b_amnt, address(this), block.timestamp);
        
        // Update posititon amount data
        _position.liquidity_a = liquidity_a;
        _position.liquidity_b = liquidity_b;
        _position.lp_token_amount = IERC20(_position.lp_token).balanceOf(address(this));
        _position.token_a_amount = IERC20(_position.token_a).balanceOf(address(this));
        _position.token_b_amount = IERC20(_position.token_b).balanceOf(address(this));

        return _position;
    }

    /// @dev Stakes LP tokens into a farm.
    function _stake(HLSConfig memory self, Position memory _position, bool _sngleFarm) private {

        uint256 stake_amount = IERC20(_position.lp_token).balanceOf(address(this));
        IERC20(_position.lp_token).approve(self.staking_reward, stake_amount);

        if (_sngleFarm==true) {
            IQuickSingleStakingReward(self.staking_reward).stake(stake_amount);
        }
        else if (_sngleFarm==false){
            IQuickDualStakingReward(self.staking_reward).stake(stake_amount);
        }

    }

    function _removeLiquidity(HLSConfig memory self, Position memory _position) private returns (Position memory) {
        (uint256 reserve0, uint256 reserve1, ) = IQuickPair(_position.lp_token).getReserves();
        uint256 total_supply = IQuickPair(_position.lp_token).totalSupply();
        uint256 token_a_amnt = (reserve0.mul(_position.lp_token_amount).div(total_supply)).mul(995).div(1000);
        uint256 token_b_amnt = (reserve1.mul(_position.lp_token_amount).div(total_supply)).mul(995).div(1000);

        // Approve for Quickswap removeliquidity
        IERC20(_position.lp_token).approve(self.router, _position.lp_token_amount);

        IQuickRouter02(self.router).removeLiquidity(_position.token_a, _position.token_b, _position.lp_token_amount, token_a_amnt, token_b_amnt, address(this), block.timestamp);


        // Update posititon amount data
        _position.liquidity_a = 0;
        _position.liquidity_b = 0;
        _position.lp_token_amount = IERC20(_position.lp_token).balanceOf(address(this));
        _position.token_a_amount = IERC20(_position.token_a).balanceOf(address(this));
        _position.token_b_amount = IERC20(_position.token_b).balanceOf(address(this));

        return _position;
    }

    /// @dev Removes liquidity from a given farm.
    function _unstake(HLSConfig memory self, Position memory _position, bool _single) private returns (Position memory) {
        
        uint256 unstake_amount;

        if (_single==true) {
            unstake_amount = IQuickSingleStakingReward(self.staking_reward).balanceOf(address(this));
            IQuickSingleStakingReward(self.staking_reward).withdraw(unstake_amount);
        }
        else if (_single==false){
            unstake_amount = IQuickDualStakingReward(self.staking_reward).balanceOf(address(this));
            IQuickDualStakingReward(self.staking_reward).withdraw(unstake_amount);
        }

        // Update posititon amount data
        _position.lp_token_amount = IERC20(_position.lp_token).balanceOf(address(this));

        return _position;
    }


// ------------------------------------------- charged buncker getter function ------------------------------------------


    /// @dev Return total debts for charged bunker. In Normalized Value. Will claim pending reward when calling this function
    function getTotalDebts(HLSConfig memory self, Position memory _position, bool _singleFarm) public returns (uint256) {

        // Cream supplied amount->norm_amt->norm_value from bunker
        uint256 cream_total_supplied = _position.supply_amount;
        cream_total_supplied = cream_total_supplied.mul(10**18).div(10**IERC20(_position.token).decimals()) ;
        uint256 token_price = uint256(LinkOracle(self.token_oracle).latestAnswer());
        cream_total_supplied = cream_total_supplied.mul(token_price).div(10**LinkOracle(self.token_oracle).decimals());

        // Quickswap reward (already in bunker). Normalized Value.
        uint256 reward_value = claimReward(self, _position, _singleFarm);

        // Cream borrowed amount->norm_amt
        (uint256 crtoken_a_debt, uint256 crtoken_b_debt) = getTotalBorrowAmount(_position.borrowed_crtoken_a, _position.borrowed_crtoken_b);
        (crtoken_a_debt, crtoken_b_debt) = getNormalizedAmount(_position.borrowed_crtoken_a, _position.borrowed_crtoken_b, crtoken_a_debt, crtoken_b_debt) ;
        // Quickswap staked amount->norm_amt
        (uint256 staked_token_a_amt, uint256 staked_token_b_amt) = getStakedTokenDeNormAmount(_position.lp_token, _position.lp_token_amount);
        (staked_token_a_amt, staked_token_b_amt) = getNormalizedAmount(_position.token_a, _position.token_b, staked_token_a_amt, staked_token_b_amt);
        // check if we have remaining tokens after repaying cream
        uint256 token_a_value = staked_token_a_amt < crtoken_a_debt ? 0:1 ;
        uint256 token_b_value = staked_token_b_amt < crtoken_b_debt ? 0:1 ;
        if (token_a_value != 0 && token_b_value != 0) {
            (token_a_value, token_b_value) = getValueFromAmount(self.token_a_oracle, self.token_b_oracle, staked_token_a_amt.sub(crtoken_a_debt), staked_token_b_amt.sub(crtoken_b_debt));
        }
        else if (token_a_value != 0 && token_b_value == 0) {
            uint256 token_a_price = uint256(LinkOracle(self.token_a_oracle).latestAnswer());
            token_a_value = (staked_token_a_amt.sub(crtoken_a_debt)).mul(token_a_price).div(10**LinkOracle(self.token_a_oracle).decimals());
        }
        else if (token_a_value == 0 && token_b_value != 0) {
            uint256 token_b_price = uint256(LinkOracle(self.token_b_oracle).latestAnswer());
            token_b_value = (staked_token_b_amt.sub(crtoken_b_debt)).mul(token_b_price).div(10**LinkOracle(self.token_b_oracle).decimals());
        }

        return cream_total_supplied.add(reward_value).add(token_a_value).add(token_b_value);
    }

    /// @dev Returns total amount that bunker borrowed from Cream. In deNormalized decimals.
    function getTotalBorrowAmount(address _crtoken_a, address _crtoken_b) public view returns (uint256, uint256) {    
        uint256 crtoken_a_borrow_amount = CErc20Delegator(_crtoken_a).borrowBalanceStored(address(this));
        uint256 crtoken_b_borrow_amount = CErc20Delegator(_crtoken_b).borrowBalanceStored(address(this));
        return (crtoken_a_borrow_amount, crtoken_b_borrow_amount);
    }

    /// @dev Get total token "deNormalized" amount that has been added into Quickswap's liquidity pool    
    function getStakedTokenDeNormAmount(address _lpToken, uint256 _lpTokenAmount) public view returns (uint256, uint256) {

        (uint256 reserve0, uint256 reserve1, ) = IQuickPair(_lpToken).getReserves();
        uint256 total_supply = IQuickPair(_lpToken).totalSupply();
        uint256 token_a_amnt = reserve0.mul(_lpTokenAmount).div(total_supply);
        uint256 token_b_amnt = reserve1.mul(_lpTokenAmount).div(total_supply);

        return (token_a_amnt, token_b_amnt);

    }

    /// @dev Get two tokens' separate Normalized Value, given two tokens' separate Normalized Amount.  
    function getValueFromAmount(address token_a_oracle, address token_b_oracle, uint256 _a_amount, uint256 _b_amount) public view returns (uint256 token_a_value, uint256 token_b_value) {

        uint256 token_a_price = uint256(LinkOracle(token_a_oracle).latestAnswer());
        uint256 token_b_price = uint256(LinkOracle(token_b_oracle).latestAnswer());
        token_a_value = _a_amount.mul(token_a_price).div(10**LinkOracle(token_a_oracle).decimals());
        token_b_value = _b_amount.mul(token_b_price).div(10**LinkOracle(token_b_oracle).decimals());

        return (token_a_value, token_b_value) ;

        /* example
        a:
        amount 40*10**18
        price 20*10**6
        value 800*10**18

        b:
        amount 20*10**18
        price 30*10**18
        value 600*10**18
        */

    }   

    /// @dev Get two tokens' separate Normalized Amount, given two tokens' separate Normalized Value.
    function getAmountFromValue(address token_a_oracle, address token_b_oracle, uint256 _a_value, uint256 _b_value) public view returns (uint256 token_a_amount, uint256 token_b_amount) {

        uint256 token_a_price = uint256(LinkOracle(token_a_oracle).latestAnswer());
        uint256 token_b_price = uint256(LinkOracle(token_b_oracle).latestAnswer());
        token_a_amount = _a_value.mul(10**LinkOracle(token_a_oracle).decimals()).div(token_a_price);
        token_b_amount = _b_value.mul(10**LinkOracle(token_b_oracle).decimals()).div(token_b_price);
        return (token_a_amount, token_b_amount) ;

        // example
        // a:
        // value 800*10**18
        // price 20*10**6
        // amount 800*10**24/20*10**6 == 40*10**18

        // b:
        // value 600*10**18
        // price 30*10**18
        // amount 600*10**36/30*10**18 == 20*10**18
        
    }

    /// @dev Get Free Funds in bunker , or get the amount needed to enter position
    function getFreeFunds(address token_a, address token_b, uint256 _enterPercentage, bool _getAll, bool _getNormalized) public view returns(uint256, uint256){

        if( _getNormalized == true ) {
            
            (uint256 a_norm_amt, uint256 b_norm_amt) = 
            getNormalizedAmount(token_a, token_b, IERC20(token_a).balanceOf(address(this)), IERC20(token_b).balanceOf(address(this))) ;

            if( _getAll == true ) {
                // return all FreeFunds in cashbox
                return ( a_norm_amt , b_norm_amt );
            }

            else if( _getAll == false ) {
                // return enter_amounts needed to add liquidity
                    return ( a_norm_amt.mul(_enterPercentage).div(100) , b_norm_amt.mul(_enterPercentage).div(100) ) ;
            }

        }

        if( _getNormalized == false ) {
            if( _getAll == true ) {
                // return all FreeFunds in cashbox
                return (
                    IERC20(token_a).balanceOf(address(this)),
                    IERC20(token_b).balanceOf(address(this))
                );
            }

            else if( _getAll == false ) {
                // return enter_amounts needed to add liquidity
                    return (
                        (IERC20(token_a).balanceOf(address(this))).mul(_enterPercentage).div(100),
                        (IERC20(token_b).balanceOf(address(this))).mul(_enterPercentage).div(100)
                    );
            }
        }

    }

    /// @dev Get Normalized Value of Position.token, given deNormalized Amount of Position.token
    function getTokenValueFromDeNormAmount(address _token, address _token_oracle, uint256 _amount) public view returns(uint256 norm_value){
        uint256 norm_amount = _amount.mul(10**18).div(10**IERC20(_token).decimals());
        uint256 token_price = uint256(LinkOracle(_token_oracle).latestAnswer());
        norm_value = norm_amount.mul(token_price).div(10**LinkOracle(_token_oracle).decimals());
    }

    /// @dev Get two tokens' separate deNormalized Amount, given two tokens' separate Normalized Amount.
    function getDeNormalizedAmount(address token_a, address token_b, uint256 _a_amt, uint256 _b_amt) public view returns(uint256 a_norm_amt, uint256 b_norm_amt) {
        
        a_norm_amt = _a_amt.mul(10**IERC20(token_a).decimals()).div(10**18);
        b_norm_amt = _b_amt.mul(10**IERC20(token_b).decimals()).div(10**18);
    }

    /// @dev Get two tokens' separate Normalized Amount, given two tokens' separate deNormalized Amount.
    function getNormalizedAmount(address token_a, address token_b, uint256 _a_amt, uint256 _b_amt) public view returns(uint256 a_norm_amt, uint256 b_norm_amt) {
        
        a_norm_amt = _a_amt.mul(10**18).div(10**IERC20(token_a).decimals());
        b_norm_amt = _b_amt.mul(10**18).div(10**IERC20(token_b).decimals());
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface LinkOracle {
  function latestAnswer() external view returns (int256);
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface CErc20Delegator {

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) external;

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint256 mintAmount) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrow(uint256 borrowAmount) external returns (uint256);

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint256 repayAmount) external returns (uint256);

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external returns (uint256);

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external returns (uint256);

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get cash balance of this cToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256);

    /**
     * @notice Applies accrued interest to total borrows and reserves.
     * @dev This calculates interest accrued from the last checkpointed block
     *      up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() external returns (uint256);

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another cToken during the process of liquidation.
     *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of cTokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);
    
    function interestRateModel() external view returns (address);
    
    function totalBorrows() external view returns (uint256);
    
    function totalReserves() external view returns (uint256);
    
    function decimals() external view returns (uint8);
    
    function reserveFactorMantissa() external view returns (uint256);

    function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ComptrollerInterface {

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);

    function exitMarket(address cToken) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import './IQuickRouter01.sol';

/** 
 * @dev Interface for Sushiswap router contract.
 */

interface IQuickRouter02 is IQuickRouter01 {
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IDquick {
    function leave(uint256 _dQuickAmount) external;
    function balanceOf(address account) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IQuickPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external ;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IQuickSingleStakingReward {
    function stakeWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external ;
    function stake(uint256 amount) external ;
    function balanceOf(address account) external view returns (uint256);
    function withdraw(uint256 amount) external ;
    function getReward() external ;
    function earned(address account) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IQuickDualStakingReward {
    function stake(uint256 amount) external ;
    function balanceOf(address account) external view returns (uint256);
    function withdraw(uint256 amount) external ;
    function getReward() external ;
    function earnedA(address account) external view returns(uint256);
    function earnedB(address account) external view returns(uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity  >=0.5.0;

/** 
 * @dev Interface for Quickswap router contract.
 */

interface IQuickRouter01 {
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns(uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);


    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable returns(uint256[] memory amounts);

}