// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./libs/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDofinChef.sol";
import { HLS_charged } from "./libs/HLS_charged.sol";

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
    uint256 public getTotalAssets;
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
            require(checkCaller(), "Only factory or dofin can call this function");
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
            require(checkCaller(), "Only factory or dofin can call this function");
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
        
        setTag(true);
    }

    function setTag(bool _tag) public {
        require(checkCaller(), "Only factory or dofin can call this function");
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

    function changePositionStatus(bool _positionStatus) external {
        require(checkCaller(), "Only factory or dofin can call this function");
        PositionStatus = _positionStatus;
    }

// ---------------------------------------- getters & check ------------------------------------------
    
    function checkAddNewFunds() public view returns (uint256) {
        uint256 free_funds = IERC20(Position.token).balanceOf(address(this));
        if (free_funds > temp_free_funds) {
            if (PositionStatus == false) {
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
        // Function name called balanceOf because of DofinChef
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

    function getWithdrawAmount() external returns (uint256) {
        User memory user = users[msg.sender];
        uint256 withdraw_amount = user.Proof_Token_Amount;
        uint256 totalAssets = _getTotalAssets();
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
    
    /// @dev input "_deposit_amount" in deNormalized decimal. return "shares","norm_deposit_value" is in decimals==18
    function getDepositAmountOut(uint256 _deposit_amount) public returns (uint256, uint256) {
        require(_deposit_amount <= deposit_limit.mul(10**IERC20(Position.token).decimals()), "Deposit too much!");
        require(_deposit_amount > 0, "Deposit amount must be larger than 0.");

        (uint256 norm_deposit_amt, uint256 norm_total_deposit_limit_amt) = HLS_charged.getNormalizedAmount(Position.token, Position.token, _deposit_amount, total_deposit_limit.mul(10**IERC20(Position.token).decimals()));
        (uint256 norm_deposit_value, uint256 norm_total_deposit_limit_value) = HLS_charged.getValueFromNormAmount(HLSConfig.token_oracle, HLSConfig.token_oracle, norm_deposit_amt, norm_total_deposit_limit_amt);
        uint256 totalAssets = _getTotalAssets();
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
    function _getTotalAssets() private returns (uint256) {

        // Free fund amount -> norm_amount -> norm_value
        uint256 freeFund_value = HLS_charged.getTokenValueFromDeNormAmount(Position.token, HLSConfig.token_oracle, IERC20(Position.token).balanceOf(address(this)));

        // Total Debts amount from Cream, Quickswap
        uint256 totalDebts = HLS_charged.getTotalDebts(HLSConfig, Position, singleFarm);
        getTotalAssets = freeFund_value.add(totalDebts);
        return getTotalAssets;
    }


// -------------------------------------- manipulative functions -------------------------------------

    function rebalance() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        _rebalance();
    }

    function _rebalance() private {
        require(TAG, 'TAG ERROR.');
        _exit(1);
        _enter(1);
    }
    
    function rebalanceWithRepay() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        require(TAG, 'TAG ERROR.');
        _exit(2);
        _enter(2);
    }
    
    function rebalanceWithoutRepay() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        require(TAG, 'TAG ERROR.');
        _exit(3);
        _enter(3);
    }
    
    function autoCompound(uint256 _amountIn, address[] calldata _path, uint256 _wrapType) external {
        require(checkCaller(), "Only factory or dofin can call this function");
        require(TAG, 'TAG ERROR.');
        HLS_charged.autoCompound(HLSConfig.router, _amountIn, _path, _wrapType);
        Position.token_amount = IERC20(Position.token).balanceOf(address(this));
        Position.token_a_amount = IERC20(Position.token_a).balanceOf(address(this));
        Position.token_b_amount = IERC20(Position.token_b).balanceOf(address(this));
        Position.total_debts = HLS_charged.getTotalDebts(HLSConfig, Position, singleFarm);

    }

    function claimReward() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        require(TAG, 'TAG ERROR.');
        HLS_charged.claimReward(HLSConfig, Position, singleFarm);
    }
    
    function enter(uint256 _type) external {
        require(checkCaller(), "Only factory or dofin can call this function");
        _enter(_type);
    }
    
    function _enter(uint256 _type) private {
        require(TAG, 'TAG ERROR.');
        require(!PositionStatus, 'POSITIONSTATUS ERROR');
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
        require(TAG, 'TAG ERROR.');
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
        Position.token_amount = IERC20(Position.token).balanceOf(address(this));
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
        uint256 totalAssets = _getTotalAssets();
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
        Position.token_amount = IERC20(Position.token).balanceOf(address(this));

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
        Position.token_amount = IERC20(Position.token).balanceOf(address(this));

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

        address router; // Address of Quickswap router contract
        address comptroller; // Address of cream comptroller contract.

        address staking_reward ;
    }
    
    // Position
    struct Position {
        uint256 token_amount;
        uint256 supply_amount; // the token amont supplied from bunkerto Cream , deNormalized
        uint256 crtoken_amount; // balanceOf(supply_crtoken)
        uint256 borrowed_token_a_amount;
        uint256 borrowed_token_b_amount;
        uint256 token_a_amount; // deNormalized
        uint256 token_b_amount; // deNormalized
        uint256 lp_token_amount;
        uint256 liquidity_a;
        uint256 liquidity_b;

        uint256 funds_percentage;
        uint256 total_debts; // total value outside bunker

        address token; // token that user deposit into charged bunker, ex: USDC
        address supply_crtoken; // crToken address to supply() and withdraw(), ex: crUSDC
        address borrowed_crtoken_a; // crToken address to borrow() and repay() , ex: crWETH_addr
        address borrowed_crtoken_b; // crToken address to borrow() and repay() , ex: crUSDT_addr
        address token_a; // after supplying to Cream, the token borrowed form borrowed_crtoken_a, ex: WETH_addr
        address token_b; // after supplying to Cream, the token borrowed form borrowed_crtoken_b, ex: USDT_addr
        address lp_token; // after adding liq into Quickswap , get lp_token, that is quick-pair's address, ex: WETH_USDT pair

        address dQuick_addr ; // reward of singleFarm
        address Quick_addr ; // need to transform dQuick to Quick in order to calculate Value.
        address WMatic_addr ; // reward of singleFarm and dualFarm

    }

// ---------------------------------------- charged buncker manipulative function ---------------------------------------
    
    
    function enterPosition(HLSConfig memory self, Position memory _position, uint256 _type, bool _singleFarm) external returns (Position memory) { 
        // Supply Position.token to Cream
        if (_type == 1) { _position = _supplyCream(_position); }
        
        // Borrow Position.token_a, Position.token_b from Cream
        if (_type == 1 || _type == 2) { _position = _borrowCream(self, _position); }
        
        // Add liquidity and stake
        if (_type == 1 || _type == 2 || _type == 3) {
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
        (Quick_reward , WMatic_reward) = getValueFromNormAmount(self.Quick_oracle, self.Matic_oracle, Quick_reward, WMatic_reward);

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
        uint256 current_a_balance = IERC20(_position.token_a).balanceOf(address(this));
        uint256 borrowed_a = CErc20Delegator(_position.borrowed_crtoken_a).borrowBalanceCurrent(address(this));
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

        uint256 max_available_staking_a = IERC20(_position.token_a).balanceOf(address(this));
        uint256 max_available_staking_b = IERC20(_position.token_b).balanceOf(address(this));
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

        // Approve for Quickswap removeliquidity
        IERC20(_position.lp_token).approve(self.router, _position.lp_token_amount);

        IQuickRouter02(self.router).removeLiquidity(_position.token_a, _position.token_b, _position.lp_token_amount, 0, 0, address(this), block.timestamp);

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
        // Quickswap reward (claim them into bunker). Normalized Value.
        uint256 reward_value = claimReward(self, _position, _singleFarm);
        // Cream borrowed amount->norm_amt
        (uint256 crtoken_a_debt, uint256 crtoken_b_debt) = getTotalBorrowAmount(_position.borrowed_crtoken_a, _position.borrowed_crtoken_b);
        (crtoken_a_debt, crtoken_b_debt) = getNormalizedAmount(_position.token_a, _position.token_b, crtoken_a_debt, crtoken_b_debt) ;
        // Quickswap staked amount->norm_amt
        (uint256 staked_token_a_amt, uint256 staked_token_b_amt) = getStakedTokenDeNormAmount(_position.lp_token, _position.lp_token_amount);
        (staked_token_a_amt, staked_token_b_amt) = getNormalizedAmount(_position.token_a, _position.token_b, staked_token_a_amt, staked_token_b_amt);
        // check if we have remaining tokens after repaying cream
        uint256 token_a_value = staked_token_a_amt < crtoken_a_debt ? 0:1 ;
        uint256 token_b_value = staked_token_b_amt < crtoken_b_debt ? 0:1 ;
        if (token_a_value != 0 && token_b_value != 0) {
            (token_a_value, token_b_value) = getValueFromNormAmount(self.token_a_oracle, self.token_b_oracle, staked_token_a_amt.sub(crtoken_a_debt), staked_token_b_amt.sub(crtoken_b_debt));
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
    function getValueFromNormAmount(address token_a_oracle, address token_b_oracle, uint256 _a_amount, uint256 _b_amount) public view returns (uint256 token_a_value, uint256 token_b_value) {

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

        /* example
        a:
        value 800*10**18
        price 20*10**6
        amount 800*10**24/20*10**6 == 40*10**18

        b:
        value 600*10**18
        price 30*10**18
        amount 600*10**36/30*10**18 == 20*10**18
        */
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./ChargedBunker.sol";

/// @title ChargedBunkersFactory
contract ChargedBunkersFactory {
    
    address public ownDofinChef;
    address private _owner;
    uint256 public BunkersLength;
    mapping (uint256 => address) public IdToBunker;
    event Received(address, uint);

    constructor(address _ownDofinChef) {
        _owner = msg.sender;
        ownDofinChef = _ownDofinChef;
    }

    function setOwnIDofinChef(address _ownDofinChef) external {
        require(msg.sender == _owner, "Only Owner can call this function");
        require(_ownDofinChef != address(0), 'ownDofinChef is the zero address');
        ownDofinChef = _ownDofinChef;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == _owner, "Only Owner can call this function");
        require(newOwner != address(0), 'New owner is the zero address');
        _owner = newOwner;
    }

    function createBunker (uint256 _id, uint256 _funds_percentage, address[10] memory _addrs, uint256 _allocPoint) external returns(address) {
        require(msg.sender == _owner, "Only Owner can call this function");
        ChargedBunker newBunker = new ChargedBunker();
        // Create pool
        IDofinChef(ownDofinChef).add(_allocPoint, IERC20(address(newBunker)), false);
        uint256 pool_id = IDofinChef(ownDofinChef).poolLength() - 1;
        
        ChargedBunker.DofinChefStruct memory DofinChefStruct = ChargedBunker.DofinChefStruct({
            dofinchef_addr: ownDofinChef,
            pool_id: pool_id
        });
        newBunker.initialize(_funds_percentage, _addrs, DofinChefStruct);
        if (IdToBunker[_id] == address(0)) {
            BunkersLength++;
        }
        IdToBunker[_id] = address(newBunker);
        return address(newBunker);
    }

    function delBunker (uint256 _id) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        BunkersLength = BunkersLength - 1;
        delete IdToBunker[_id];
        return true;
    }

    function setTagBunkers (uint256[] memory _ids, bool _tag) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        for (uint i = 0; i < _ids.length; i++) {
            ChargedBunker bunker = ChargedBunker(IdToBunker[_ids[i]]);
            bunker.setTag(_tag);
        }
        return true;
    }

    function setConfigBunker (uint256 _id, address[8] memory _config, address _dofin, uint256[2] memory _deposit_limit, bool _singleFarm) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        ChargedBunker bunker = ChargedBunker(IdToBunker[_id]);
        bunker.setConfig(_config, _dofin, _deposit_limit, _singleFarm);
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";

import "../interfaces/quickswap/IQuickRouter02.sol";
import "../interfaces/quickswap/IDquick.sol";
import "../interfaces/quickswap/IQuickPair.sol";

import "../interfaces/quickswap/IQuickSingleStakingReward.sol";
import "../interfaces/quickswap/IQuickDualStakingReward.sol";


/// @title High level system for boosted bunker
library HLS_boosted {    

// ------------------------------------------------- public variables ---------------------------------------------------

    using SafeMath for uint256;

    // HighLevelSystem config
    struct HLSConfig {
        address router; // Address of Quickswap router contract : 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        address staking_reward ; // Determined by bool singleFarm, if true=> single staking reward, if falee=> dual staking reward
        address dQuick_addr ;
    }
    
    // Position
    struct Position {

        address token_a; // user deposit into boost
        address token_b; // user deposit into boost
        address lp_token; // after adding liq into pancake , get lp_token, 就是pancake pair address

        uint256 token_a_amount; // deNormalized
        uint256 token_b_amount; // deNormalized
        uint256 lp_token_amount;
        uint256 liquidity_a;
        uint256 liquidity_b;

        uint256 funds_percentage; // 從cashbox離開的錢的百分比
        uint256 total_debts; // 所有在buncker外面的錢
    }

// ------------------ boosted buncker manipulative function -------------------

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
    function _stake(HLSConfig memory self, Position memory _position, bool _single) private {

        uint256 stake_amount = IERC20(_position.lp_token).balanceOf(address(this));
        IERC20(_position.lp_token).approve(self.staking_reward, stake_amount);

        if (_single==true) {
            
            IQuickSingleStakingReward(self.staking_reward).stake(stake_amount);
        }
        else if (_single==false){
            IQuickDualStakingReward(self.staking_reward).stake(stake_amount);
        }

    }

    function _removeLiquidity(HLSConfig memory self, Position memory _position) private returns (Position memory) {
        uint256 token_a_amnt = 0;
        uint256 token_b_amnt = 0;

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

    /// @dev Main entry function to stake and enter a given position.
    function enterPositionBoosted(HLSConfig memory self, Position memory _position, bool _singleFarm) external returns (Position memory) {
        
        _position = _addLiquidity(self, _position);

        _stake(self, _position, _singleFarm);
        
        _position.total_debts = getTotalDebtsBoosted(_position);

        return _position;
    }

    /// @dev Main exit function to exit and unstake a given position.
    function exitPositionBoosted(HLSConfig memory self, Position memory _position, bool _singleFarm) external returns (Position memory) {
        
        _position = _unstake(self, _position, _singleFarm);

        _position = _removeLiquidity(self, _position);

        _position.total_debts = getTotalDebtsBoosted(_position);

        return _position;
    }

    /// @dev Auto swap "Quick" or WMATIC back to some token desird.
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

    /// @dev claim dQuick (and WMATIC, if it's dual farm) , transfer dQUick into Quick
    function claimReward(address _staking_reward, address _dQuick, bool _singleFarm) external {

        if ( _singleFarm == true ) {
            IQuickSingleStakingReward(_staking_reward).getReward() ;
        }

        else if ( _singleFarm == false) {  
            IQuickDualStakingReward(_staking_reward).getReward() ;
        }

        uint256 dQuick_balance = IDquick(_dQuick).balanceOf(address(this));
        IDquick(_dQuick).leave(dQuick_balance);

    }


// --------------------- boosted buncker getter function ---------------------

    /// @dev Get Free Funds in bunker , or get the amount needed to enter position
    function getFreeFunds(address token_a, address token_b, uint256 _enterPercentage, bool _getAll, bool _getNormalized) public view returns(uint256, uint256){

        if( _getNormalized == true ) {
            uint256 _a_amt = IERC20(token_a).balanceOf(address(this)) ;
            uint256 _b_amt = IERC20(token_b).balanceOf(address(this));
            uint256 a_norm_amt = _a_amt.mul(10**18).div(10**IERC20(token_a).decimals());
            uint256 b_norm_amt = _b_amt.mul(10**18).div(10**IERC20(token_b).decimals());

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

    /// @dev Get total value outside of boosted bunker.
    function getTotalDebtsBoosted(Position memory _position) public view returns (uint256) {
        // PancakeSwap staked amount
        (uint256 token_a_amount, uint256 token_b_amount) = getStakedTokenAmount(_position);
        uint256 lp_token_amount = getLpTokenAmountOut(_position.lp_token, token_a_amount, token_b_amount);
        return lp_token_amount;
    }

    //// @dev Get total token "deNormalized" amount that has been added into Quickswap's liquidity pool 
    function getStakedTokenAmount(Position memory _position) private view returns (uint256, uint256) {

        (uint256 reserve0, uint256 reserve1, ) = IQuickPair(_position.lp_token).getReserves();
        uint256 total_supply = IQuickPair(_position.lp_token).totalSupply();
        uint256 token_a_amnt = reserve0.mul(_position.lp_token_amount).div(total_supply);
        uint256 token_b_amnt = reserve1.mul(_position.lp_token_amount).div(total_supply);

        return (token_a_amnt, token_b_amnt);

    }

    /** @dev when called from script, given one of the deNormalized input amount, get the other deNormalized input amount needed, and get Normalized total Value of these two inputs.
        @dev when called from this contract, amounts are the same as the inputs, and get Normalized total Value of these two inputs.
        @param _a_amt: deNormalized
        @param _b_amt: deNormalized
        @return _token_a_amount: deNormalized
        @return _token_b_amount: deNormalized
     */
    function getUpdatedAmount(HLSConfig memory self, Position memory _position, uint256 _a_amt, uint256 _b_amt) external view returns (uint256 , uint256 , uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IQuickPair(_position.lp_token).getReserves();
        if (_a_amt == 0 && _b_amt > 0) {
            _a_amt = IQuickRouter02(self.router).quote(_b_amt, reserve1, reserve0);
        } else if (_a_amt > 0 && _b_amt == 0) {
            _b_amt = IQuickRouter02(self.router).quote(_a_amt, reserve0, reserve1);            
        } else {
            revert("Input amount incorrect");
        }

        uint256 lp_token_amount = getLpTokenAmountOut(_position.lp_token, _a_amt, _b_amt);

        return (_a_amt, _b_amt, lp_token_amount);
    }

    /// @param _lp_token Quickswap LP token address.
    /// @param _token_a_amount Quickswap pair token a amount.
    /// @param _token_b_amount Quickswap pair token b amount.
    /// @dev Return LP token amount, in Normalized amount.
    function getLpTokenAmountOut(address _lp_token, uint256 _token_a_amount, uint256 _token_b_amount) public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IQuickPair(_lp_token).getReserves();
        uint256 totalSupply = IQuickPair(_lp_token).totalSupply();
        uint256 token_a_lp_amount = _token_a_amount.mul(totalSupply).div(reserve0);
        uint256 token_b_lp_amount = _token_b_amount.mul(totalSupply).div(reserve1);
        uint256 lp_token_amount = token_a_lp_amount.min(token_b_lp_amount);
        
        return lp_token_amount;
    }

    /// @param _lp_token PancakeSwap LP token address.
    /// @param _lp_token_amount PancakeSwap LP token amount.
    /// @dev Return Pair tokens amount, in deNormalized amount.
    function getLpTokenAmountIn(address _lp_token, uint256 _lp_token_amount) public view returns (uint256, uint256) {
        address token_a = IQuickPair(_lp_token).token0();
        address token_b = IQuickPair(_lp_token).token1();
        uint256 balance_a = IERC20(token_a).balanceOf(_lp_token);
        uint256 balance_b = IERC20(token_b).balanceOf(_lp_token);
        uint256 totalSupply = IQuickPair(_lp_token).totalSupply();
        
        return (_lp_token_amount.mul(balance_a).div(totalSupply), _lp_token_amount.mul(balance_b).div(totalSupply));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "../libs/SafeMath.sol";

/// @title ProofToken
/// @author Andrew FU
contract ProofToken {
    
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal totalSupply_;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    function initializeToken(string memory _name, string memory _symbol, uint8 _decimals) internal {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        
        return totalSupply_;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        
        return allowed[owner][spender];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function mint(address account, uint256 amount) internal returns (bool) {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply_ += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);

        return true;
    }
    
    function burn(address account, uint256 amount) internal returns (bool) {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = accountBalance - amount;
        }
        totalSupply_ -= amount;
        emit Transfer(account, address(0), amount);

        return true;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./SafeMath.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/cream/CErc20Delegator.sol";

/// @title High level system for fixed bunker
library HLS_fixed {

// ------------------------------------------------- public variables ---------------------------------------------------

    using SafeMath for uint256;

    // Position
    struct Position {
        uint256 token_amount;
        uint256 crtoken_amount; // balanceOf(supply_crtoken)
        uint256 supply_amount; // 紀錄supply給cream多少

        address token; // user deposit into charge ,  在boost時用來當作計算token_a,token_b的價值基準
        address supply_crtoken; // 類似我們的cashbox address
        
        uint256 funds_percentage; // 從cashbox離開的錢的百分比
        uint256 total_debts; // 所有在buncker外面的錢
    }

// --------------------------------------------------- fixed buncker ----------------------------------------------------


    /// @dev Supplies 'amount' worth of tokens to cream.
    function _supplyCream(Position memory _position) private returns(Position memory) {
        uint256 supply_amount = IERC20(_position.token).balanceOf(address(this)).mul(_position.funds_percentage).div(100);
        
        // Approve for Cream borrow 
        IERC20(_position.token).approve(_position.supply_crtoken, supply_amount);
        require(CErc20Delegator(_position.supply_crtoken).mint(supply_amount) == 0, "Supply not work");

        // Update posititon amount data
        _position.token_amount = IERC20(_position.token).balanceOf(address(this));
        _position.crtoken_amount = IERC20(_position.supply_crtoken).balanceOf(address(this));
        _position.supply_amount = supply_amount;

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

    /// @dev Main entry function to borrow and enter a given position.
    function enterPositionFixed(Position memory _position) external returns (Position memory) { 
        // Supply position
        _position = _supplyCream(_position);
        _position.total_debts = getTotalDebtsFixed(_position);

        return _position;
    }

    /// @dev Main exit function to exit and repay a given position.
    function exitPositionFixed(Position memory _position) external returns (Position memory) {
        // Redeem
        _position = _redeemCream(_position);
        _position.total_debts = getTotalDebtsFixed(_position);

        return _position;
    }


    /// @dev Return total debts for fixed bunker.
    function getTotalDebtsFixed(Position memory _position) private pure returns (uint256) {
        
        return _position.supply_amount;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "../interfaces/IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

import "./IERC20.sol";

interface IMigratorChef {

    function migrate(IERC20 token) external returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IFinVerseToken {

    function mint(address _to, uint256 _amount) external;

    function burn(address _from ,uint256 _amount) external;

    function balanceOf(address account) view external returns (uint256);

    function transfer(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view override(IERC20) returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view override(IERC20) returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view override(IERC20) returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "../interfaces/IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override(IERC20, IERC20Metadata) returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override(IERC20, IERC20Metadata) returns (string memory) {
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
    function decimals() public view virtual override(IERC20, IERC20Metadata) returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override(IERC20) returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override(IERC20) returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override(IERC20) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override(IERC20) returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override(IERC20) returns (bool) {
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
    ) public virtual override(IERC20) returns (bool) {
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

import "./Context.sol";

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
    address private _dever;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DevershipTransferred(address indexed previousDever, address indexed newDever);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _transferDevership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function dever() public view virtual returns (address) {
        return _dever;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner() != _msgSender() && dever() != _msgSender()) {
            revert("Ownable: caller is not the owner or dever");
        }
        // require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    function renounceDevership() public virtual onlyOwner {
        _transferDevership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function transferDevership(address newDever) public virtual onlyOwner {
        require(newDever != address(0), "Ownable: new dever is the zero address");
        _transferDevership(newDever);
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

    function _transferDevership(address newDever) internal virtual {
        address oldDever = _dever;
        _dever = newDever;
        emit DevershipTransferred(oldDever, newDever);
    }
}