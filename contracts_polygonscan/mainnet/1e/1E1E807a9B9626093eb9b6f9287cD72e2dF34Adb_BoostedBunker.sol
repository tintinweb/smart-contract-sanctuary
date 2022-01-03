// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./libs/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDofinChef.sol";
import { HLS_boosted } from "./libs/HLS_boosted.sol";

/// @title Polygon BoostedBunker
contract BoostedBunker {
    struct User {
        uint256 Proof_Token_Amount;
        uint256 Token_A_Amount;
        uint256 Token_B_Amount;
        uint256 Lp_Equiv_Amount;
        uint256 Block_Timestamp;
    }

    struct DofinChefStruct {
        address dofinchef_addr;
        uint256 pool_id;
    }

    HLS_boosted.HLSConfig private HLSConfig;
    HLS_boosted.Position private Position;
    DofinChefStruct public OwnDofinChef;

    using SafeMath for uint256;

    uint256 public total_deposit_limit_a; // upper bound of tokenA amount in this bunker, ex: 500000 USDC.
    uint256 public total_deposit_limit_b; // upper bound of tokenB amount in this bunker, ex: 500000 DAI.
    uint256 public deposit_limit_a; // upper bound of tokenA for single depositing , ex: 100 USDC. 
    uint256 public deposit_limit_b; // upper bound of tokenB for single depositing , ex: 100 DAI.
    uint256 private temp_free_fund_a;// updated after each enterposition/exitposition used to check need rebalance or not
    uint256 private temp_free_fund_b;
    uint256 public totalSupply_;
    bool public TAG = false;
    bool public PositionStatus = false;
    bool public singleFarm = true;
    address private ownDofinChef;
    address private dofin;
    address private factory;
    string public name = "Boosted Proof Token";
    string public symbol = "BP";
    
    mapping (address => User) private users;
    event Received(address, uint);


// ------------------------- config things -------------------------- //
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

    function initialize(uint256 _funds_percentage, address[3] memory _addrs, DofinChefStruct memory _DofinChefStruct ) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller(), "Only factory or dofin can call this function");
        }
        Position = HLS_boosted.Position({
            token_a_amount: 0,
            token_b_amount: 0,
            lp_token_amount: 0,
            liquidity_a: 0,
            liquidity_b: 0,
            token_a: _addrs[0],
            token_b: _addrs[1],
            lp_token: _addrs[2],
            funds_percentage: _funds_percentage,
            total_debts: 0
        });
        factory = msg.sender;
        OwnDofinChef = _DofinChefStruct ;
    }
    
    function setConfig(address[3] memory _config, address _dofin, uint256[4] memory _deposit_limit, bool _singleFarm) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller(), "Only factory or dofin can call this function");
        }
        HLSConfig.router = _config[0];
        HLSConfig.staking_reward = _config[1];
        HLSConfig.dQuick_addr = _config[2];

        dofin = _dofin;
        deposit_limit_a = _deposit_limit[0];
        deposit_limit_b = _deposit_limit[1];
        total_deposit_limit_a = _deposit_limit[2];
        total_deposit_limit_b = _deposit_limit[3];
        singleFarm = _singleFarm ;

        // Set Tag
        TAG = true ;
    }

    function setTag(bool _tag) external {
        require(checkCaller(), "Only factory or dofin can call this function");
        TAG = _tag;
    }

// ------------------------- getters & check ------------------------ //

    function getConfig() external view returns(HLS_boosted.HLSConfig memory) {
        
        return HLSConfig;
    }

    function getPosition() external view returns(HLS_boosted.Position memory) {
     
        return Position;
    }

    function getUser(address _account) external view returns (User memory) {
        
        return users[_account];
    }

    function getWithdrawAmount() external view returns (uint256, uint256){
        User memory user = users[msg.sender];
        uint256 withdraw_amount = user.Proof_Token_Amount;
        uint256 totalAssets = getTotalAssets();
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        if (withdraw_amount > user.Proof_Token_Amount) {
            return (0, 0);
        }
        uint256 dofin_value;
        uint256 user_value;
        if (value > user.Lp_Equiv_Amount.add(10**IERC20(Position.lp_token).decimals())) {
            dofin_value = (value.sub(user.Lp_Equiv_Amount)).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        
        return HLS_boosted.getLpTokenAmountIn(Position.lp_token, user_value);

    }

    function getTotalAssets() public view returns (uint256) {

        uint256 tokenAfreeFunds = IERC20(Position.token_a).balanceOf(address(this));
        uint256 tokenBfreeFunds = IERC20(Position.token_b).balanceOf(address(this));
        uint256 lp_token_amount = HLS_boosted.getLpTokenAmountOut(Position.lp_token, tokenAfreeFunds, tokenBfreeFunds);

        // Total Debts amount from QuickSwap
        uint256 totalDebts = HLS_boosted.getTotalDebtsBoosted(Position);
        
        return lp_token_amount.add(totalDebts);
    }

    function getDepositAmountOut(uint256 _token_a_amount, uint256 _token_b_amount) public view returns (uint256, uint256, uint256, uint256) {
        
        uint256 totalAssets = getTotalAssets();
        uint256 lp_token_amount;

        (_token_a_amount, _token_b_amount, lp_token_amount) = HLS_boosted.getUpdatedAmount(HLSConfig, Position, _token_a_amount, _token_b_amount);
        
        require(_token_a_amount <= deposit_limit_a.mul(10**IERC20(Position.token_a).decimals()), "Deposit too much token a!");
        require(_token_b_amount <= deposit_limit_b.mul(10**IERC20(Position.token_b).decimals()), "Deposit too much token b!");

        uint256 total_deposit_limit_lp = HLS_boosted.getLpTokenAmountOut(Position.lp_token, total_deposit_limit_a.mul(10**IERC20(Position.token_a).decimals()), total_deposit_limit_b.mul(10**IERC20(Position.token_b).decimals()));

        require(total_deposit_limit_lp >= totalAssets.add(lp_token_amount), "Deposit get limited");

        uint256 shares;
        if (totalSupply_ > 0) {
            shares = lp_token_amount.mul(totalSupply_).div(totalAssets);
        } else {
            shares = lp_token_amount;
        }
        return (_token_a_amount, _token_b_amount, lp_token_amount, shares);

    }

    function getFreeFunds(bool _getAll, bool _getNormalized) public view returns (uint256,uint256,uint256,uint256){
        
        ( uint256 a_free_fund , uint256 b_free_fund ) = HLS_boosted.getFreeFunds(Position.token_a, Position.token_b, Position.funds_percentage, _getAll, _getNormalized);
        
        return (a_free_fund, b_free_fund, temp_free_fund_a, temp_free_fund_b) ;
    }

    function balanceOf(address _account) external view returns (uint256) {
        // Only return totalSupply amount
        // Function name call balanceOf if because DofinChef
        return totalSupply_;
    }

    function checkAddNewFunds() public view returns (uint256) {
        uint256 free_fund_a = IERC20(Position.token_a).balanceOf(address(this));
        uint256 free_fund_b = IERC20(Position.token_b).balanceOf(address(this));

        if (free_fund_a > temp_free_fund_a || free_fund_b > temp_free_fund_b) {
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


// --------------------- manipulative functions ----------------------- //
    function rebalanceWithoutRepay() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        _rebalanceWithoutRepay();
    }

    function _rebalanceWithoutRepay() public {
        require(TAG == true, 'TAG ERROR.');
        require(PositionStatus == true, 'POSITIONSTATUS ERROR');
        _exit();
        _enter();
    }

    function _exit() private {
        require(TAG == true, 'TAG ERROR.');
        Position = HLS_boosted.exitPositionBoosted(HLSConfig, Position, singleFarm);
        PositionStatus = false;
    }

    function _enter() private {
        require(TAG == true, 'TAG ERROR.');
        require(!PositionStatus, 'POSITIONSTATUS ERROR');
        Position = HLS_boosted.enterPositionBoosted(HLSConfig, Position, singleFarm);
        temp_free_fund_a = IERC20(Position.token_a).balanceOf(address(this));
        temp_free_fund_b = IERC20(Position.token_b).balanceOf(address(this));
        PositionStatus = true;
    }
    
    function enter() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        _enter();
    }

    function exit() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        _exit();
    } 
    
    function autoCompound(uint256 _amountIn, address[] calldata _path, uint256 _wrapType) external {
        require(checkCaller(), "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        HLS_boosted.autoCompound(HLSConfig.router, _amountIn, _path, _wrapType);
        Position.token_a_amount = IERC20(Position.token_a).balanceOf(address(this));
        Position.token_b_amount = IERC20(Position.token_b).balanceOf(address(this));
        Position.total_debts = HLS_boosted.getTotalDebtsBoosted(Position);
    }

    function claimReward() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        HLS_boosted.claimReward(HLSConfig.staking_reward, HLSConfig.dQuick_addr, singleFarm);
    }

    /** @dev User's deposit function
        @param _token_a_amount : deNormalized amount
        @param _token_b_amount : deNormalized amount
     */
    function deposit(uint256 _token_a_amount, uint256 _token_b_amount) external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        // Calculation of pToken amount need to mint
         uint256 lp_token_amount;
         uint256 shares;
        (_token_a_amount, _token_b_amount, lp_token_amount, shares) = getDepositAmountOut(_token_a_amount, _token_b_amount);

        // Record user deposit amount
        User memory user = users[msg.sender];
        user.Proof_Token_Amount = user.Proof_Token_Amount.add(shares);  //Norm
        user.Token_A_Amount = user.Token_A_Amount.add(_token_a_amount); //deNorm
        user.Token_B_Amount = user.Token_B_Amount.add(_token_b_amount); //deNorm
        user.Lp_Equiv_Amount = user.Lp_Equiv_Amount.add(lp_token_amount);// pair lp decimal==18
        user.Block_Timestamp = block.timestamp;
        users[msg.sender] = user;

        // Modify total supply
        totalSupply_ += shares;
        // Transfer user token
        IERC20(Position.token_a).transferFrom(msg.sender, address(this), _token_a_amount);
        IERC20(Position.token_b).transferFrom(msg.sender, address(this), _token_b_amount);
        // Stake
        IDofinChef(OwnDofinChef.dofinchef_addr).deposit(OwnDofinChef.pool_id, shares, msg.sender);
    
        uint256 newFunds = checkAddNewFunds();
        if (newFunds == 1) {
            _enter();
        } else if (newFunds == 2) {
            _rebalanceWithoutRepay();
        }
        
        return true;

    }
    
    function withdraw() external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        User memory user = users[msg.sender];
        uint256 withdraw_amount = user.Proof_Token_Amount;
        uint256 totalAssets = getTotalAssets();
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        require(withdraw_amount > 0, "Proof token amount insufficient");
        require(block.timestamp > user.Block_Timestamp, "Deposit and withdraw in same block");
        // If no enough amount of free funds can transfer will trigger exit position
        (uint256 value_a, uint256 value_b) = HLS_boosted.getLpTokenAmountIn(Position.lp_token, value);

        if ( value_a > IERC20(Position.token_a).balanceOf(address(this)) || value_b > IERC20(Position.token_b).balanceOf(address(this)) ) {
            _exit();
            totalAssets = getTotalAssets();
            value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        }
        // Withdraw pToken
        IDofinChef(OwnDofinChef.dofinchef_addr).withdraw(OwnDofinChef.pool_id, withdraw_amount, msg.sender);
        // Modify total supply
        totalSupply_ -= withdraw_amount;
        // Will charge 20% fees
        uint256 dofin_value;
        uint256 user_value;

        if (value > user.Lp_Equiv_Amount.add(10**IERC20(Position.lp_token).decimals())) {
            dofin_value = (value.sub(user.Lp_Equiv_Amount)).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }

        // Modify user state data
        user.Proof_Token_Amount = 0;
        user.Token_A_Amount = 0;
        user.Token_B_Amount = 0;
        user.Lp_Equiv_Amount = 0;
        user.Block_Timestamp = 0;
        users[msg.sender] = user;

        (uint256 user_value_a, uint256 user_value_b) = HLS_boosted.getLpTokenAmountIn(Position.lp_token, user_value);
        (uint256 dofin_value_a, uint256 dofin_value_b) = HLS_boosted.getLpTokenAmountIn(Position.lp_token, dofin_value);

        // Approve for withdraw
        IERC20(Position.token_a).approve(address(this), user_value_a + dofin_value_a);
        IERC20(Position.token_b).approve(address(this), user_value_b + dofin_value_b);
        // Transfer token to user
        IERC20(Position.token_a).transferFrom(address(this), msg.sender, user_value_a);
        IERC20(Position.token_b).transferFrom(address(this), msg.sender, user_value_b);
        if (dofin_value_a > IERC20(Position.token_a).balanceOf(address(this))) {
            dofin_value_a = IERC20(Position.token_a).balanceOf(address(this));
        }

        if (dofin_value_b > IERC20(Position.token_b).balanceOf(address(this))) {
            dofin_value_b = IERC20(Position.token_b).balanceOf(address(this));
        }
        
        // Transfer token to dofin
        IERC20(Position.token_a).transferFrom(address(this), dofin, dofin_value_a);
        IERC20(Position.token_b).transferFrom(address(this), dofin, dofin_value_b);
        
        return true;

    }

    function emergencyWithdrawal() external returns (bool) {
        require(TAG == false, 'NOT EMERGENCY');
        User memory user = users[msg.sender];
        uint256 pTokenBalance = user.Proof_Token_Amount;
        require(pTokenBalance > 0,  "Incorrect quantity of Proof Token");
        require(user.Proof_Token_Amount > 0, "Not depositor");

        // Approve for withdraw
        IERC20(Position.token_a).approve(address(this), user.Token_A_Amount);
        IERC20(Position.token_b).approve(address(this), user.Token_B_Amount); 
        IERC20(Position.token_a).transferFrom(address(this), msg.sender, user.Token_A_Amount);
        IERC20(Position.token_b).transferFrom(address(this), msg.sender, user.Token_B_Amount); 
        
        // Modify user state data
        user.Proof_Token_Amount = 0;
        user.Token_A_Amount = 0;
        user.Token_B_Amount = 0;
        user.Lp_Equiv_Amount = 0;
        user.Block_Timestamp = 0;
        users[msg.sender] = user;
        
        return true;
    }
    


// ------------------------ ending of bunker ----------------------- //



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