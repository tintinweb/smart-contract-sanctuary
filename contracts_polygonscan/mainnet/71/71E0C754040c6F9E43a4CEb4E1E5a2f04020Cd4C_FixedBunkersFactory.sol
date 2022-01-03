// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./FixedBunker.sol";

/// @title FixedBunkersFactory
contract FixedBunkersFactory {
    
    address public ownDofinChef;
    address private _owner;
    uint256 public BunkersLength;
    mapping (uint256 => address) public IdToBunker;


    constructor(address _ownDofinChef) {
        _owner = msg.sender;
        ownDofinChef = _ownDofinChef;
    }

    function setOwnDofinChef(address _ownDofinChef) external {
        require(msg.sender == _owner, "Only Owner can call this function");
        require(_ownDofinChef != address(0), 'ownDofinChef is the zero address');
        ownDofinChef = _ownDofinChef;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == _owner, "Only Owner can call this function");
        require(newOwner != address(0), 'New owner is the zero address');
        _owner = newOwner;
    }

    function createBunker (uint256 _id, uint256 _funds_percentage, address _depositing_token_addr, address _supply_crtoken_addr, uint256 _allocPoint) external returns(address) {
        require(msg.sender == _owner, "Only Owner can call this function");
        FixedBunker newBunker = new FixedBunker();
        // Create pool
        IDofinChef(ownDofinChef).add(_allocPoint, IERC20(address(newBunker)), false);
        uint256 pool_id = IDofinChef(ownDofinChef).poolLength() - 1;
        
        FixedBunker.DofinChefStruct memory DofinChefStruct = FixedBunker.DofinChefStruct({
            dofinchef_addr: ownDofinChef,
            pool_id: pool_id
        });
        newBunker.initialize(_depositing_token_addr, _supply_crtoken_addr, _funds_percentage, DofinChefStruct);
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
            FixedBunker bunker = FixedBunker(IdToBunker[_ids[i]]);
            bunker.setTag(_tag);
        }
        return true;
    }

    function setConfigBunker (uint256 _id, address _dofin, uint256[2] memory _deposit_limit) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        FixedBunker bunker = FixedBunker(IdToBunker[_id]);
        bunker.setConfig(_dofin, _deposit_limit);
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./libs/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDofinChef.sol";
import {HLS_fixed} from "./libs/HLS_fixed.sol";

/// @title Polygon FixedBunker
contract FixedBunker {
    struct User {
        uint256 Proof_Token_Amount;
        uint256 Deposited_Token_Amount;
        uint256 Deposit_Block_Timestamp;
    }

    struct DofinChefStruct {
        address dofinchef_addr;
        uint256 pool_id;
    }

    HLS_fixed.Position private Position;
    DofinChefStruct public OwnDofinChef;

    using SafeMath for uint256;

    uint256 public total_deposit_limit;
    uint256 public deposit_limit;
    uint256 private temp_free_funds;
    uint256 public totalSupply_; // normalized
    bool public TAG = false;
    bool public PositionStatus = false;
    address private dofin;
    address private factory;
    string public name = "Fixed Proof Token";
    string public symbol = "FP";

    mapping(address => User) private users;
    event Received(address, uint256);

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

    function initialize(
        address _depositing_token_addr,
        address _supply_crtoken_addr,
        uint256 _funds_percentage,
        DofinChefStruct memory _DofinChefStruct
    ) external {
        if (dofin != address(0) && factory != address(0)) {
            require(
                checkCaller(),
                "Only factory or dofin can call this function"
            );
        }
        Position = HLS_fixed.Position({
            token_amount: 0,
            crtoken_amount: 0,
            supply_amount: 0,
            token: _depositing_token_addr,
            supply_crtoken: _supply_crtoken_addr,
            funds_percentage: _funds_percentage,
            total_debts: 0
        });
        factory = msg.sender;
        OwnDofinChef = _DofinChefStruct;
    }

    function setConfig(address _dofin, uint256[2] memory _deposit_limit) external{
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller(), "Only factory or dofin can call this function");
        }

        dofin = _dofin;
        deposit_limit = _deposit_limit[0];
        total_deposit_limit = _deposit_limit[1];

        // Set Tag
        TAG = true;
    }

    function setTag(bool _tag) external {
        require(checkCaller(), "Only factory or dofin can call this function");
        TAG = _tag;
    }

    function getPosition() external view returns (HLS_fixed.Position memory) {
        return Position;
    }

    function getUser(address _account) external view returns (User memory) {
        return users[_account];
    }

    function rebalance() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        _rebalance();
    }

    function _rebalance() private {
        require(TAG, "TAG ERROR");
        require(PositionStatus, "POSITIONSTATUS ERROR");
        _exit();
        _enter();
    }

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

    function enter() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        _enter();
    }

    function _enter() private {
        require(TAG, 'TAG ERROR.');
        require(!PositionStatus, 'POSITIONSTATUS ERROR');
        Position = HLS_fixed.enterPositionFixed(Position);
        temp_free_funds = IERC20(Position.token).balanceOf(address(this));
        PositionStatus = true;
    }

    function exit() external {
        require(checkCaller(), "Only factory or dofin can call this function");
        _exit();
    }

    function _exit() private {
        require(TAG, 'TAG ERROR.');
        require(PositionStatus, 'POSITIONSTATUS ERROR');
        Position = HLS_fixed.exitPositionFixed(Position);
        PositionStatus = false;
    }

    function getTotalAssets() public view returns (uint256) {
        // Free funds amount
        uint256 freeFunds = IERC20(Position.token).balanceOf(address(this));
        // Total Debts amount from Cream
        uint256 totalDebts = Position.total_debts;

        return freeFunds.add(totalDebts);
    }

    function balanceOf(address _account) external view returns (uint256) {
        // Only return totalSupply amount
        // Function name call balanceOf if because DofinChef
        return totalSupply_;
    }

    function getDepositAmountOut(uint256 _deposit_amount) public view returns (uint256) {
        require(_deposit_amount <= deposit_limit.mul(10**IERC20(Position.token).decimals()), "Deposit too much");
        require(_deposit_amount > 0, "Deposit amount must bigger than 0");
        uint256 totalAssets = getTotalAssets();
        require(total_deposit_limit.mul(10**IERC20(Position.token).decimals()) >= totalAssets.add(_deposit_amount), "Deposit get limited");
        uint256 shares;

        if (totalSupply_ > 0) {
            shares = _deposit_amount.mul(totalSupply_).div(totalAssets);
        } else {
            shares = _deposit_amount;
        }
        return shares;
    }

    function deposit(uint256 _deposit_amount) external {
        require(TAG, "TAG ERROR.");
        // Calculation of pToken amount need to mint
        uint256 shares = getDepositAmountOut(_deposit_amount);

        // Record user deposit amount
        User memory user = users[msg.sender];
        user.Proof_Token_Amount = user.Proof_Token_Amount.add(shares);
        user.Deposited_Token_Amount = user.Deposited_Token_Amount.add(_deposit_amount);
        user.Deposit_Block_Timestamp = block.timestamp;
        users[msg.sender] = user;

        // Modify total supply
        totalSupply_ += shares;
        // Transfer user token
        IERC20(Position.token).transferFrom(msg.sender, address(this), _deposit_amount);
        // Stake
        IDofinChef(OwnDofinChef.dofinchef_addr).deposit(OwnDofinChef.pool_id, shares, msg.sender);

        uint256 newFunds = checkAddNewFunds();
        if (newFunds == 1) {
            _enter();
        } else if (newFunds == 2) {
            _rebalance();
        }
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

    function withdraw() external {
        require(TAG, "TAG ERROR.");
        User memory user = users[msg.sender];
        uint256 withdraw_amount = user.Proof_Token_Amount; // normalized
        uint256 totalAssets = getTotalAssets(); // denormalized
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_); //denormalized
        require(withdraw_amount > 0, "Proof token amount insufficient");
        require(block.timestamp > user.Deposit_Block_Timestamp,"Deposit and withdraw in same block");
        // If no enough amount of free funds can transfer will trigger exit position
        if (value > IERC20(Position.token).balanceOf(address(this))) {
            _exit();
            totalAssets = IERC20(Position.token).balanceOf(address(this));
            value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        }
        // Withdraw pToken
        IDofinChef(OwnDofinChef.dofinchef_addr).withdraw(OwnDofinChef.pool_id, withdraw_amount, msg.sender);
        // Modify total supply
        totalSupply_ -= withdraw_amount;
        // Will charge 20% fees
        uint256 dofin_value;
        uint256 user_value;
        if ( value > user.Deposited_Token_Amount.add(10**IERC20(Position.token).decimals()) ) {
            dofin_value = value.sub(user.Deposited_Token_Amount).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        // Modify user state data
        user.Proof_Token_Amount = 0;
        user.Deposited_Token_Amount = 0;
        user.Deposit_Block_Timestamp = 0;
        users[msg.sender] = user;
        // Approve for withdraw
        IERC20(Position.token).approve(address(this), user_value);
        // Transfer token to user
        IERC20(Position.token).transferFrom(address(this),msg.sender,user_value);
        if (dofin_value > IERC20(Position.token).balanceOf(address(this))) {
            dofin_value = IERC20(Position.token).balanceOf(address(this));
        }
        // Transfer token to dofin
        IERC20(Position.token).transferFrom(address(this), dofin, dofin_value);
    }

    function emergencyWithdrawal() external {
        require(TAG == false, "NOT EMERGENCY");
        User memory user = users[msg.sender];
        uint256 pTokenBalance = user.Proof_Token_Amount;
        require(pTokenBalance > 0, "Incorrect quantity of Proof Token");
        require(user.Proof_Token_Amount > 0, "Not depositor");

        // Approve for withdraw
        IERC20(Position.token).approve(address(this),user.Deposited_Token_Amount);
        IERC20(Position.token).transferFrom(address(this),msg.sender,user.Deposited_Token_Amount);

        // Modify user state data
        user.Proof_Token_Amount = 0;
        user.Deposited_Token_Amount = 0;
        user.Deposit_Block_Timestamp = 0;
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