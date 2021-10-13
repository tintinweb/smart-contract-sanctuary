// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./token/BEP20/IBEP20.sol";
import "./math/SafeMath.sol";
import "./utils/BasicContract.sol";
import { HighLevelSystem } from "./libs/HighLevelSystem.sol";

/// @title CashBox
/// @author Andrew FU
/// @dev All functions haven't finished unit test
contract CashBox is BasicContract {
    
    // Link
    // address private link_oracle;
    
    // Cream
    // address private constant cream_oracle = 0xab548FFf4Db8693c999e98551C756E6C2948C408;
    // address private constant cream_troller = 0x589DE0F0Ccf905477646599bb3E5C622C84cC0BA;
    
    // PancakeSwap
    // address private constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // address private constant FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    // address private constant MASTERCHEF = 0x73feaa1eE314F8c655E354234017bE2193C9E24E;
    
    // Cream token
    // address private constant crWBNB = 0x15CC701370cb8ADA2a2B6f4226eC5CF6AA93bC67;
    // address private constant crBNB = 0x1Ffe17B99b439bE0aFC831239dDECda2A790fF3A;
    // address private constant crUSDC = 0xD83C88DB3A6cA4a32FFf1603b0f7DDce01F5f727;
    
    // StableCoin
    // address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    // address private constant BNB = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    // address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    // address private constant TUSD = 0x14016E85a25aeb13065688cAFB43044C2ef86784;
    // address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    // address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    
    HighLevelSystem.HLSConfig private HLSConfig;
    HighLevelSystem.CreamToken private CreamToken;
    HighLevelSystem.StableCoin private StableCoin;
    HighLevelSystem.Position private position;
    
    using SafeMath for uint;
    using SafeMath for uint256;
    string public constant name = "Proof token";
    string public constant symbol = "pToken";
    uint8 public constant decimals = 18;
    uint256 private totalSupply_;
    
    bool public activable;
    address private dofin;
    uint private deposit_limit;
    uint private add_funds_condition;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    mapping(address => uint256) private balances;
    mapping(address => mapping (address => uint256)) private allowed;

    constructor(uint[] memory _uints, address[] memory _addrs, address _dofin, uint _deposit_limit, uint _add_funds_condition) {
        position = HighLevelSystem.Position({
            pool_id: _uints[0],
            token_amount: 0,
            token_a_amount: 0,
            token_b_amount: 0,
            lp_token_amount: 0,
            crtoken_amount: 0,
            supply_crtoken_amount: 0,
            token: _addrs[0],
            token_a: _addrs[1],
            token_b: _addrs[2],
            lp_token: _addrs[3],
            supply_crtoken: _addrs[4],
            borrowed_crtoken_a: _addrs[5],
            borrowed_crtoken_b: _addrs[6],
            max_amount_per_position: _uints[1],
            supply_funds_percentage: _uints[2]
        });
        
        activable = true;
        dofin = _dofin;
        deposit_limit = _deposit_limit;
        add_funds_condition = add_funds_condition;
    }

    modifier checkActivable() {
        require(activable == true, 'CashBox is not activable.');
        _;
    }
    
    function setConfig(address[] memory _config) public onlyOwner {
        HLSConfig.LinkConfig.oracle = _config[0];
        HLSConfig.CreamConfig.oracle = _config[1];
        HLSConfig.PancakeSwapConfig.router = _config[2];
        HLSConfig.PancakeSwapConfig.factory = _config[3];
        HLSConfig.PancakeSwapConfig.masterchef = _config[4];
    }
    
    function setCreamTokens(address[] memory _creamtokens) public onlyOwner {
        CreamToken.crWBNB = _creamtokens[0];
        CreamToken.crBNB = _creamtokens[1];
        CreamToken.crUSDC = _creamtokens[2];
    }
    
    function setStableCoins(address[] memory _stablecoins) public onlyOwner {
        StableCoin.WBNB = _stablecoins[0];
        StableCoin.BNB = _stablecoins[1];
        StableCoin.USDT = _stablecoins[2];
        StableCoin.TUSD = _stablecoins[3];
        StableCoin.BUSD = _stablecoins[4];
        StableCoin.USDC = _stablecoins[5];
    }

    function setActivable(bool _activable) public onlyOwner {
        
        activable = _activable;
    }
    
    function getPosition() public onlyOwner view returns(HighLevelSystem.Position memory) {
        
        return position;
    }
    
    function reblanceWithRepay() public onlyOwner checkActivable {
        HighLevelSystem.exitPosition(HLSConfig, CreamToken, StableCoin, position, 3);
        position = HighLevelSystem.enterPosition(HLSConfig, CreamToken, StableCoin, position, 3);
    }
    
    function reblanceWithoutRepay() public onlyOwner checkActivable {
        HighLevelSystem.exitPosition(HLSConfig, CreamToken, StableCoin, position, 2);
        position = HighLevelSystem.enterPosition(HLSConfig, CreamToken, StableCoin, position, 2);
    }
    
    function reblance() public onlyOwner checkActivable  {
        HighLevelSystem.exitPosition(HLSConfig, CreamToken, StableCoin, position, 1);
        position = HighLevelSystem.enterPosition(HLSConfig, CreamToken, StableCoin, position, 1);
    }
    
    function checkAddNewFunds() public onlyOwner checkActivable {
        uint free_funds = IBEP20(position.token).balanceOf(address(this));
        uint condition = SafeMath.mul(add_funds_condition, 10**IBEP20(position.token).decimals());
        if (free_funds >= condition) {
            if (position.token_a_amount == 0 && position.token_b_amount == 0) {
                checkEntry();
            } else {
                reblance();
            }
        }
    }
    
    function checkEntry() public onlyOwner checkActivable {
        
        position = HighLevelSystem.checkEntry(HLSConfig, CreamToken, StableCoin, position);
    }

    function exit(uint _type) public onlyOwner checkActivable {
        
        HighLevelSystem.exitPosition(HLSConfig, CreamToken, StableCoin, position, _type);
    }
    
    function checkCurrentBorrowLimit() onlyOwner public returns (uint) {
        
        return HighLevelSystem.checkCurrentBorrowLimit(HLSConfig, CreamToken, StableCoin, position);
    }
    
    function totalSupply() public view returns (uint256) {
        
        return totalSupply_;
    }
    
    function balanceOf(address account) public view returns (uint) {
        
        return balances[account];
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        
        return allowed[owner][spender];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
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
    
    function getTotalAssets() public view returns (uint) {
        // Cream borrowed amount
        (uint crtoken_a_debt, uint crtoken_b_debt) = HighLevelSystem.getTotalBorrowAmount(CreamToken, position.borrowed_crtoken_a, position.borrowed_crtoken_b);
        // PancakeSwap pending cake amount
        uint pending_cake_amount = HighLevelSystem.getTotalCakePendingRewards(HLSConfig, position.pool_id);
        // PancakeSwap staked amount
        (uint token_a_amount, uint token_b_amount) = HighLevelSystem.getStakedTokens(HLSConfig, position);
        
        uint total_assets = SafeMath.sub(SafeMath.add(token_a_amount, token_b_amount), SafeMath.add(crtoken_a_debt, crtoken_b_debt));
        total_assets = SafeMath.add(total_assets, pending_cake_amount);
        total_assets = SafeMath.add(total_assets, IBEP20(position.token).balanceOf(address(this)));
        return total_assets;
    }

    function getDepositAmountOut(uint _deposit_amount) public view returns (uint) {
        uint totalAssets = getTotalAssets();
        uint shares;
        if (totalSupply_ > 0) {
            shares = SafeMath.div(SafeMath.mul(_deposit_amount, totalSupply_), totalAssets);
        } else {
            shares = _deposit_amount;
        }
        return shares;
    }
    
    function deposit(address _token, uint _deposit_amount) public checkActivable returns (bool) {
        require(_deposit_amount <= SafeMath.mul(deposit_limit, 10**IBEP20(position.token).decimals()), "Deposit too much!");
        require(_token == position.token, "Wrong token to deposit.");
        require(_deposit_amount > 0, "Deposit amount must bigger than 0.");
        
        // Calculation of pToken amount need to mint
        uint shares = getDepositAmountOut(_deposit_amount);
        
        // Mint pToken and transfer Token to cashbox
        mint(msg.sender, shares);
        IBEP20(position.token).transferFrom(msg.sender, address(this), _deposit_amount);
        
        // Check need to supply or not.
        // checkAddNewFunds();
        
        return true;
    }
    
    function getWithdrawAmount(uint _ptoken_amount) public view returns (uint) {
        uint totalAssets = getTotalAssets();
        uint value = SafeMath.div(SafeMath.mul(_ptoken_amount, totalAssets), totalSupply_);
        uint user_value = SafeMath.div(SafeMath.mul(80, value), 100);
        
        return user_value;
    }
    
    function withdraw(uint _withdraw_amount) public checkActivable returns (bool) {
        require(_withdraw_amount <= balanceOf(msg.sender), "Wrong amount to withdraw.");
        
        uint freeFunds = IBEP20(position.token).balanceOf(address(this));
        uint totalAssets = getTotalAssets();
        uint value = SafeMath.div(SafeMath.mul(_withdraw_amount, totalAssets), totalSupply_);
        bool need_rebalance = false;
        // If no enough amount of free funds can transfer will trigger exit position
        if (value > freeFunds) {
            HighLevelSystem.exitPosition(HLSConfig, CreamToken, StableCoin, position, 1);
            need_rebalance = true;
        }
        
        // Will charge 20% fees
        burn(msg.sender, _withdraw_amount);
        uint dofin_value = SafeMath.div(SafeMath.mul(20, value), 100);
        uint user_value = SafeMath.div(SafeMath.mul(80, value), 100);
        IBEP20(position.token).transferFrom(address(this), dofin, dofin_value);
        IBEP20(position.token).transferFrom(address(this), msg.sender, user_value);
        
        if (need_rebalance == true) {
            HighLevelSystem.enterPosition(HLSConfig, CreamToken, StableCoin, position, 1);
        }
        
        return true;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "../token/BEP20/IBEP20.sol";
import "../access/Ownable.sol";

contract BasicContract is Ownable {
    
    event IntLog(string message, uint val);
    event StrLog(string message, string val);
    event AddrLog(string message, address val);
    
    function checkBalance(address _token, address _address) external view returns (uint) {
        return IBEP20(_token).balanceOf(_address);
    }
    
    function approveForContract(address _token, address _spender, uint _amount) private onlyOwner {
        IBEP20(_token).approve(_spender, _amount);
    }
    
    function checkAllowance(address _token, address _owner, address _spender) external view returns (uint) {
        return IBEP20(_token).allowance(_owner, _spender);
    }
    
    function transferBack(address _token, uint _amount) external onlyOwner {
        IBEP20(_token).approve(address(this), _amount);
        IBEP20(_token).transferFrom(address(this), msg.sender, _amount);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
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
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../token/BEP20/IBEP20.sol";
import "../math/SafeMath.sol";
import "../interfaces/pancakeswap/IPancakePair.sol";
import "../interfaces/pancakeswap/IPancakeFactory.sol";
import "../interfaces/pancakeswap/MasterChef.sol";
import "../interfaces/pancakeswap/IPancakeRouter02.sol";

/// @title PancakeSwap execution
/// @author Andrew FU
/// @dev All functions haven't finished unit test
library PancakeSwapExecution {
    
    // Addresss of PancakeSwap.
    struct PancakeSwapConfig {
        address router; // Address of PancakeSwap router contract.
        address factory; // Address of PancakeSwap factory contract.
        address masterchef; // Address of PancakeSwap masterchef contract.
    }
    
    // Info of each pool.
    struct PoolInfo {
        address lpToken;           // Address of LP token contract.
        uint allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }
    
    function getBalanceBNB(address wallet_address, address BNB_address) public view returns (uint) {
        
        return IBEP20(BNB_address).balanceOf(wallet_address);
    }
    
    function getLPBalance(address lp_token) public view returns (uint) {
        
        return IPancakePair(lp_token).balanceOf(address(this));
    }
    
    /// @param lp_token_address PancakeSwap LPtoken address.
    /// @dev Gets the token0 and token1 addresses from LPtoken.
    /// @return token0, token1.
    function getLPTokenAddresses(address lp_token_address) public view returns (address, address) {
        
        return (IPancakePair(lp_token_address).token0(), IPancakePair(lp_token_address).token1());
    }
    
    /// @param lp_token_address PancakeSwap LPtoken address.
    /// @dev Gets the token0 and token1 symbol name from LPtoken.
    /// @return token0, token1.
    function getLPTokenSymbols(address lp_token_address) public view returns (string memory, string memory) {
        (address token0, address token1) = getLPTokenAddresses(lp_token_address);
        return (IBEP20(token0).symbol(), IBEP20(token1).symbol());
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @dev Gets pool info from the masterchef contract and stores results in an array.
    /// @return pooInfo.
    function getPoolInfo(PancakeSwapConfig memory self, uint pool_id) public view returns (address, uint256, uint256, uint256) {
        
        return MasterChef(self.masterchef).poolInfo(pool_id);
    }
    
    function getReserves(address lp_token_address) public view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        
        return IPancakePair(lp_token_address).getReserves();
    }

    /// @param self config of PancakeSwap.
    /// @param token_a_addr BEP20 token address.
    /// @param token_b_addr BEP20 token address.
    /// @dev Returns the LP token address for the token pairs.
    /// @return pair address.
    function getPair(PancakeSwapConfig memory self, address token_a_addr, address token_b_addr) public view returns (address) {
        
        return IPancakeFactory(self.factory).getPair(token_a_addr, token_b_addr);
    }
    
    /// @dev Will line up our assumption with the contracts.
    function lineUpPairs(address token_a_address, address token_b_address, uint data_a, uint data_b, address lp_token_address) public view returns (uint, uint) {
        address contract_token_0_address = IPancakePair(lp_token_address).token0();
        address contract_token_1_address = IPancakePair(lp_token_address).token1();
        
        if (token_a_address == contract_token_0_address && token_b_address == contract_token_1_address) {
            return (data_a, data_b);
        } else if (token_b_address == contract_token_0_address && token_a_address == contract_token_1_address) {
            return (data_b, data_a);
        } else {
            revert("No this pair");
        }
    }
    
    /// @param lp_token_amnt The LP token amount.
    /// @param lp_token_addr address of the LP token.
    /// @dev Returns the amount of token0, token1s the specified number of LP token represents.
    function getLPConstituients(uint lp_token_amnt, address lp_token_addr) public view returns (uint, uint) {
        (uint reserve0, uint reserve1, uint blockTimestampLast) = IPancakePair(lp_token_addr).getReserves();
        uint total_supply = IPancakePair(lp_token_addr).totalSupply();
        
        uint token_a_amnt = SafeMath.div(SafeMath.mul(reserve0, lp_token_amnt), total_supply);
        uint token_b_amnt = SafeMath.div(SafeMath.mul(reserve1, lp_token_amnt), total_supply);
        return (token_a_amnt, token_b_amnt);
    }
    
    /// @param self config of PancakeSwap.
    function getPendingStakedCake(PancakeSwapConfig memory self, uint pool_id) public view returns (uint) {
        
        return MasterChef(self.masterchef).pendingCake(pool_id, address(this));
    }
    
    /// @param self config of PancakeSwap.
    /// @param token_addr address of the BEP20 token.
    /// @param token_amnt amount of token to add.
    /// @param eth_amnt amount of BNB to add.
    /// @dev Adds a pair of tokens into a liquidity pool.
    function addLiquidityETH(PancakeSwapConfig memory self, address token_addr, address eth_addr, uint token_amnt, uint eth_amnt) public returns (uint) {
        IBEP20(token_addr).approve(self.router, token_amnt);
        (uint reserves0, uint reserves1, uint blockTimestampLast) = IPancakePair(IPancakeFactory(self.factory).getPair(token_addr, eth_addr)).getReserves();
        
        uint min_token_amnt = IPancakeRouter02(self.router).quote(token_amnt, reserves0, reserves1);
        uint min_eth_amnt = IPancakeRouter02(self.router).quote(eth_amnt, reserves1, reserves0);
        (uint amountToken, uint amountETH, uint amountLP) = IPancakeRouter02(self.router).addLiquidityETH{value: eth_amnt}(token_addr, token_amnt, min_token_amnt, min_eth_amnt, address(this), block.timestamp);
        
        return amountLP;
    }
    
    /// @param self config of PancakeSwap.
    /// @param token_a_addr address of the BEP20 token.
    /// @param token_b_addr address of the BEP20 token.
    /// @param a_amnt amount of token a to add.
    /// @param b_amnt amount of token b to add.
    /// @dev Adds a pair of tokens into a liquidity pool.
    function addLiquidity(PancakeSwapConfig memory self, address token_a_addr, address token_b_addr, uint a_amnt, uint b_amnt) public returns (uint){
        
        IBEP20(token_a_addr).approve(self.router, a_amnt);
        IBEP20(token_b_addr).approve(self.router, b_amnt);
        address pair = IPancakeFactory(self.factory).getPair(token_a_addr, token_b_addr);
        (uint reserves0, uint reserves1, uint blockTimestampLast) = IPancakePair(pair).getReserves();
    
        uint min_a_amnt = IPancakeRouter02(self.router).quote(a_amnt, reserves0, reserves1);
        uint min_b_amnt = IPancakeRouter02(self.router).quote(b_amnt, reserves1, reserves0);
        (uint amountA, uint amountB, uint amountLP) = IPancakeRouter02(self.router).addLiquidity(token_a_addr, token_b_addr, a_amnt, b_amnt, min_a_amnt, min_b_amnt, address(this), block.timestamp);
        
        return amountLP;
    }
    
    /// @param self config of PancakeSwap.
    /// @param lp_contract_addr address of the BEP20 token.
    /// @param token_a_addr address of the BEP20 token.
    /// @param token_b_addr address of the BEP20 token.
    /// @param liquidity amount of LP tokens to be removed.
    /// @param a_amnt amount of token a to remove.
    /// @param b_amnt amount of token b to remove.
    /// @dev Removes a pair of tokens from a liquidity pool.
    function removeLiquidity(PancakeSwapConfig memory self, address lp_contract_addr, address token_a_addr, address token_b_addr, uint liquidity, uint a_amnt, uint b_amnt) public {
        
        IBEP20(lp_contract_addr).approve(self.router, liquidity);
        IPancakeRouter02(self.router).removeLiquidity(token_a_addr, token_b_addr, liquidity, a_amnt, b_amnt, address(this), block.timestamp);
    }
    
    /// @param self config of PancakeSwap.
    /// @param lp_contract_addr address of the BEP20 token.
    /// @param token_addr address of the BEP20 token.
    /// @param liquidity amount of LP tokens to be removed.
    /// @param a_amnt amount of token a to remove.
    /// @param b_amnt amount of BNB to remove.
    /// @dev Removes a pair of tokens from a liquidity pool.
    function removeLiquidityETH(PancakeSwapConfig memory self, address lp_contract_addr, address token_addr, uint liquidity, uint a_amnt, uint b_amnt) public {
        
        IBEP20(lp_contract_addr).approve(self.router, liquidity);
        IPancakeRouter02(self.router).removeLiquidityETH(token_addr, liquidity, a_amnt, b_amnt, address(this), block.timestamp);
    }
    
    /// @param self config of PancakeSwap.
    function getAmountsOut(PancakeSwapConfig memory self, address token_a_address, address token_b_address) public view returns (uint) {
        uint token_a_decimals = IBEP20(token_a_address).decimals();
        uint min_amountIn = SafeMath.mul(1, 10**token_a_decimals);
        address pair = IPancakeFactory(self.factory).getPair(token_a_address, token_b_address);
        (uint reserve0, uint reserve1, uint blockTimestampLast) = IPancakePair(pair).getReserves();
        uint price = IPancakeRouter02(self.router).getAmountOut(min_amountIn, reserve0, reserve1);
        
        return price;
    }
    
    /// @param lp_token_address address of the LP token.
    /// @dev Gets the current price for a pair.
    function getPairPrice(address lp_token_address) public view returns (uint) {
        (uint reserve0, uint reserve1, uint blockTimestampLast) = IPancakePair(lp_token_address).getReserves();
        return reserve0 + reserve1;
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @dev Gets the current number of LP tokens staked in the pool.
    function getStakedLP(PancakeSwapConfig memory self, uint pool_id) public view returns (uint) {
        (uint amount, uint rewardDebt) = MasterChef(self.masterchef).userInfo(pool_id, address(this));
        return amount;
    }

    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @dev Gets the pending CAKE amount for a partictular pool_id.
    function getPendingFarmRewards(PancakeSwapConfig memory self, uint pool_id) public view returns (uint) {
        
        return MasterChef(self.masterchef).pendingCake(pool_id, address(this));
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @param unstake_amount amount of LP tokens to unstake.
    /// @dev Removes 'unstake_amount' of LP tokens from 'pool_id'.
    function unstakeLP(PancakeSwapConfig memory self, uint pool_id, uint unstake_amount) public returns (bool) {
        MasterChef(self.masterchef).withdraw(pool_id, unstake_amount);
        return true;
    }
    
    /// @param self config of PancakeSwap.
    /// @param token_address address of BEP20 token.
    /// @param USDT_address address of USDT token.
    /// @dev Returns the USD price for a particular BEP20 token.
    function getTokenPriceUSD(PancakeSwapConfig memory self, address token_address, address USDT_address) public view returns (uint) {
        uint token_decimals = IBEP20(token_address).decimals();
        uint min_amountIn = SafeMath.mul(1, 10**token_decimals);
        address pair = IPancakeFactory(self.factory).getPair(token_address, USDT_address);
        (uint reserve0, uint reserve1, uint blockTimestampLast) = IPancakePair(pair).getReserves();
        uint price = IPancakeRouter02(self.router).getAmountOut(min_amountIn, reserve0, reserve1);
        return price;
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @param stake_amount amount of LP tokens to stake.
    /// @dev Gets pending reward for the user from the specific pool_id.
    function stakeLP(PancakeSwapConfig memory self, uint pool_id, uint stake_amount) public returns (bool) {
        MasterChef(self.masterchef).deposit(pool_id, stake_amount);
        return true;
    }
    
    /// @param token_addr address of BEP20 token.
    /// @param stake_contract_addr address of PancakeSwap masterchef.
    /// @param amount amount of CAKE tokens to stake.
    /// @dev Enables a syrup staking pool on PancakeSwap.
    function enablePool(address token_addr, address stake_contract_addr, uint amount) public returns (bool) {
        IBEP20(token_addr).approve(stake_contract_addr, amount);
        return true;
    }
    
    /// @param lp_token_address address of PancakeSwap LPtoken.
    /// @dev Enables a syrup staking pool on PancakeSwap.
    function enableFarm(address lp_token_address) public returns (bool) {
        IBEP20(lp_token_address).approve(0x73feaa1eE314F8c655E354234017bE2193C9E24E, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        return true;
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @dev Get the number of tokens staked into the pool.
    function getStakedPoolTokens(PancakeSwapConfig memory self, uint pool_id) public view returns (uint) {
        (uint amount, uint rewardDebt) = MasterChef(self.masterchef).userInfo(pool_id, address(this));
        return amount;
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @dev Gets pending reward for the syrup pool.
    function getPendingPoolRewards(PancakeSwapConfig memory self, uint pool_id) public view returns (uint) {
        
        return MasterChef(self.masterchef).pendingCake(pool_id, address(this));
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @param stake_amount amount of CAKE tokens to stake.
    /// @dev Adds 'stake_amount' of coins into the syrup pools.
    function stakePool(PancakeSwapConfig memory self, uint pool_id, uint stake_amount) public returns (bool) {
        MasterChef(self.masterchef).deposit(pool_id, stake_amount);
        return true;
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @param unstake_amount amount of CAKE tokens to unstake.
    /// @dev Removes 'unstake_amount' of coins into the syrup pools.
    function unstakePool(PancakeSwapConfig memory self, uint pool_id, uint unstake_amount) public returns (bool) {
        MasterChef(self.masterchef).withdraw(pool_id, unstake_amount);
        return true;
    }

    function splitTokensEvenly(uint token_a_bal, uint token_b_bal, uint pair_price, uint price_decimals) public pure returns (uint, uint) {
        uint temp = SafeMath.mul(1, 10**price_decimals);
        uint a_amount_required = SafeMath.div(SafeMath.mul(token_b_bal, temp), pair_price);
        uint b_amount_required = SafeMath.div(SafeMath.mul(token_a_bal, temp), pair_price);
        if (token_a_bal > a_amount_required) {
            return (a_amount_required, token_b_bal);
        } else if (token_b_bal > b_amount_required) {
            return (token_a_bal, b_amount_required);
        } else {
            return (0, 0);
        }
    }

    function getPairDecimals(address pair_address) public pure returns (uint) {
        
        return IPancakePair(pair_address).decimals();
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../interfaces/chainlink/AggregatorInterface.sol";

library LinkBSCOracle {
    
    // Addresss of Link.
    struct LinkConfig {
        address oracle; // Address of Link oracle contract.
    }
    
    function getPrice(LinkConfig memory self) public view returns(int256) {
        
        return AggregatorInterface(self.oracle).latestAnswer();
    }
    
    function getDecimals(LinkConfig memory self) public view returns(uint8) {
        
        return AggregatorInterface(self.oracle).decimals();
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../token/BEP20/IBEP20.sol";
import "../math/SafeMath.sol";
import { PancakeSwapExecution } from "./PancakeSwapExecution.sol";
import { CreamExecution } from "./CreamExecution.sol";
import { LinkBSCOracle } from "./LinkBSCOracle.sol";

/// @title High level system execution
/// @author Andrew FU
/// @dev All functions haven't finished unit test
library HighLevelSystem {
    // Chainlink
    using LinkBSCOracle for LinkBSCOracle.LinkConfig;
    // address private link_oracle;

    // Cream
    using CreamExecution for CreamExecution.CreamConfig;

    // PancakeSwap
    using PancakeSwapExecution for PancakeSwapExecution.PancakeSwapConfig;
    
    // HighLevelSystem config
    struct HLSConfig {
        LinkBSCOracle.LinkConfig LinkConfig;
        CreamExecution.CreamConfig CreamConfig;
        PancakeSwapExecution.PancakeSwapConfig PancakeSwapConfig;
    }
    
    // Cream token required
    struct CreamToken {
        address crWBNB;
        address crBNB;
        address crUSDC;
    }
    
    // StableCoin required
    struct StableCoin {
        address WBNB;
        address BNB;
        address USDT;
        address TUSD;
        address BUSD;
        address USDC;
    }
    
    // Position
    struct Position {
        uint pool_id;
        uint token_amount;
        uint token_a_amount;
        uint token_b_amount;
        uint lp_token_amount;
        uint crtoken_amount;
        uint supply_crtoken_amount;
        address token;
        address token_a;
        address token_b;
        address lp_token;
        address supply_crtoken;
        address borrowed_crtoken_a;
        address borrowed_crtoken_b;
        uint max_amount_per_position;
        uint supply_funds_percentage;
    }
    
    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Helper function to enter => addLiquidity + stakeLP.
    function enter(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position) public returns (bool) {
        // add liquidity
        addLiquidity(self, _crtokens, _stablecoins, _position);
        
        // stake
        stakeLP(self, _position);

        return true;
    }
    
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _token BEP20 token address.
    /// @dev Checks whether a token is a stable coin or not.
    function isStableCoin(StableCoin memory _stablecoins, address _token) public pure returns (bool) {
        if (_token == _stablecoins.USDT) {
            return true;
        }
        else if (_token == _stablecoins.TUSD) {
            return true;
        }
        else if (_token == _stablecoins.BUSD) {
            return true;
        }
        else if (_token == _stablecoins.USDC) {
            return true;
        }
        else {
            return false;
        }
    }
    
    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _token_a BEP20 token address.
    /// @param _token_b BEP20 token address.
    /// @param _crtoken_a Cream crToken address.
    /// @param _crtoken_b Cream crToken address.
    /// @dev Get the price for two tokens, from LINK if possible, else => straight from router.
    function getPrice(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, address _token_a, address _token_b, address _crtoken_a, address _crtoken_b) public view returns (uint) {
        address WBNB = _stablecoins.WBNB;
        address BNB = _stablecoins.BNB;
        address USDC = _stablecoins.USDC;
        address crUSDC = _crtokens.crUSDC;
        CreamExecution.CreamConfig memory CreamConfig = self.CreamConfig;
        
        if (_token_a == WBNB) {
            _token_a = BNB;
        }
        if (_token_b == WBNB) {
            _token_b = BNB;
        }
        if (isStableCoin(_stablecoins, _token_a) && isStableCoin(_stablecoins, _token_b)) {
            return 1;
        }

        // check if we can get data from chainlink
        uint price;
        if (self.LinkConfig.oracle != address(0)) {
            price = uint(LinkBSCOracle.getPrice(self.LinkConfig));
            return price;
        }

        // check if we can get data from cream
        if (_crtoken_a != address(0) && _crtoken_b != address(0)) {
            uint price_a = CreamExecution.getUSDPrice(CreamConfig, _crtoken_a, crUSDC, USDC);
            uint price_b = CreamExecution.getUSDPrice(CreamConfig, _crtoken_b, crUSDC, USDC);
            return SafeMath.div(price_a, price_b);
        }

        // check if we can get data from pancake
        price = PancakeSwapExecution.getAmountsOut(self.PancakeSwapConfig, _token_a, _token_b);
        return price;
    }

    /// @param _position refer Position struct on the top.
    /// @dev Checks if there is sufficient borrow liquidity on cream. Only borrow if there is 2x more liquidty than our borrow amount.
    function checkBorrowLiquidity(Position memory _position) public view returns (bool) {
        uint available_a = CreamExecution.getAvailableBorrow(_position.borrowed_crtoken_a);
        uint available_b = CreamExecution.getAvailableBorrow(_position.borrowed_crtoken_b);

        if (available_a > _position.token_a_amount && available_b > _position.token_b_amount) {
            return true;
        } else {
            return false;
        }
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param lp_constituient_0 The LP token amount.
    /// @param lp_constituient_1 The LP token amount.
    /// @param _lp_token address of the LP token.
    /// @param _crtoken_a address of the Cream token.
    /// @param _crtoken_b address of the Cream token.
    /// @dev Function returns the amount of token0, token1s the specified number of LP token represents.
    function getLPUSDValue(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, uint lp_constituient_0, uint lp_constituient_1, address _lp_token, address _crtoken_a, address _crtoken_b) public view returns (uint) {
        (address token_0, address token_1) = PancakeSwapExecution.getLPTokenAddresses(_lp_token);
        address USDC = _stablecoins.USDC;
        address crUSDC = _crtokens.crUSDC;

        uint token_0_exch_rate = getPrice(self, _crtokens, _stablecoins, token_0, USDC, _crtoken_a, crUSDC);
        uint token_1_exch_rate = getPrice(self, _crtokens, _stablecoins, token_1, USDC, _crtoken_b, crUSDC);

        uint usd_value_0 = SafeMath.mul(token_0_exch_rate, lp_constituient_0);
        uint usd_value_1 = SafeMath.mul(token_1_exch_rate, lp_constituient_1);

        return usd_value_0 + usd_value_1;
    }
    
    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Enters positions based on the opportunity.
    function checkEntry(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position) public returns (Position memory) {
        bool signal = checkBorrowLiquidity(_position);
        if (signal == true) {
            Position memory update_position = enterPosition(self, _crtokens, _stablecoins, _position, 1);
            return update_position;
        }

        return _position;
    }
    
    /// @param self refer HLSConfig struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Helper function to exit => removeLiquidity + unstakeLP.
    function exit(HLSConfig memory self, StableCoin memory _stablecoins, Position memory _position) public returns (bool) {
        // unstake
        unstakeLP(self, _position);

        // remove liquidity
        removeLiquidity(self, _stablecoins, _position);
        
        return true;
    }

    /// @param _crtokens refer CreamToken struct on the top.
    /// @dev Returns a map of <crtoken_address, borrow_amount> of all the borrowed coins.
    function getTotalBorrowAmount(CreamToken memory _crtokens, address _crtoken_a, address _crtoken_b) public view returns (uint, uint) {
        uint crtoken_a_borrow_amount = CreamExecution.getBorrowAmount(_crtoken_a, _crtokens.crWBNB);
        uint crtoken_b_borrow_amount = CreamExecution.getBorrowAmount(_crtoken_b, _crtokens.crWBNB);
        return (crtoken_a_borrow_amount, crtoken_b_borrow_amount);
    }

    /// @param self refer HLSConfig struct on the top.
    /// @dev Returns pending cake rewards for all the positions we are in.
    function getTotalCakePendingRewards(HLSConfig memory self, uint _pool_id) public view returns (uint) {
        uint cake_amnt = PancakeSwapExecution.getPendingFarmRewards(self.PancakeSwapConfig, _pool_id);
        return cake_amnt;
    }

    /// @param _crtoken Cream crToken address.
    /// @param _amount amount of tokens to supply.
    /// @dev Supplies 'amount' worth of tokens to cream.
    function supplyCream(address _crtoken, uint _amount) public returns (uint) {
        uint exchange_rate = CreamExecution.getExchangeRate(_crtoken);
        uint crtoken_amount = SafeMath.div(_amount, exchange_rate);
        return CreamExecution.supply(_crtoken, crtoken_amount);
    }
    
    /// @param _crtoken Cream crToken address.
    /// @param _amount amount of tokens to redeem.
    /// @dev Redeem amount worth of crtokens back.
    function redeemCream(address _crtoken, uint _amount) public returns (uint) {
        
        return CreamExecution.redeemUnderlying(_crtoken, _amount);
    }

    /// @param _crtokens refer CreamToken struct on the top.
    /// @dev check how much free cash we have left (whatever we can borrow up to 75% will be regarded as free cash) => after > 75% free cash would be negative.
    function getFreeCash(CreamToken memory _crtokens, address _crtoken_a, address _crtoken_b) public returns (uint) {
        address crWBNB = _crtokens.crWBNB;
        uint current_supply_amount = CreamExecution.getUserTotalSupply(_crtokens.crUSDC);
        uint position_a_amnt = CreamExecution.getBorrowAmount(_crtoken_a, crWBNB);
        uint position_b_amnt = CreamExecution.getBorrowAmount(_crtoken_b, crWBNB);
        uint current_borrow_amount = SafeMath.add(position_a_amnt, position_b_amnt);
        // 75% of current_supply_amount
        current_supply_amount = SafeMath.div(SafeMath.mul(current_supply_amount, 75), 100);
        uint free_cash = SafeMath.sub(current_supply_amount, current_borrow_amount);

        return free_cash;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Given a dollar amount, find out how many units of a and b can we get.
    function splitUnits(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position, uint dollar_amount) public view returns (uint, uint) {
        uint half_amount = SafeMath.div(dollar_amount, 2);
        address USDT = _stablecoins.USDT;
        address crUSDC = _crtokens.crUSDC;
        
        uint price_a = getPrice(self, _crtokens, _stablecoins, _position.token_a, USDT, _position.borrowed_crtoken_a, crUSDC);
        uint price_b = getPrice(self, _crtokens, _stablecoins, _position.token_b, USDT, _position.borrowed_crtoken_b, crUSDC);
        
        uint units_a = SafeMath.div(half_amount, price_a);
        uint units_b = SafeMath.div(half_amount, price_b);

        return (units_a, units_b);
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Given an opportunity object, calculate the position sizes based on current margin levels.
    function calculateEntryAmounts(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position) public returns (uint, uint) {
        (uint max_position_size_a, uint max_position_size_b) = splitUnits(self, _crtokens, _stablecoins, _position, _position.max_amount_per_position);
        uint max_borrow_limit = checkPotentialBorrowLimit(self, _crtokens, _stablecoins, _position, max_position_size_a, max_position_size_b);
        max_borrow_limit = SafeMath.mul(max_borrow_limit, 100);
        // TODO need to < 0.75
        if (max_borrow_limit < 75) {
            return (max_position_size_a, max_position_size_b);
        }

        uint free_cash = getFreeCash(_crtokens, _position.borrowed_crtoken_a, _position.borrowed_crtoken_b);
        (uint min_position_size_a, uint min_position_size_b) = splitUnits(self, _crtokens, _stablecoins, _position, free_cash);
        uint min_borrow_limit = checkPotentialBorrowLimit(self, _crtokens, _stablecoins, _position, max_position_size_a, max_position_size_b);
        min_borrow_limit = SafeMath.mul(min_borrow_limit, 100);
        // TODO need to < 0.75
        if (min_borrow_limit < 75) {
            return (min_position_size_a, min_position_size_b);
        }

        // cannot enter position
        return (0, 0);
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev use a greedy apporach to allocate the cash.
    function generatePosition(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position) public returns (Position memory) {
        (uint a_amount, uint b_amount) = calculateEntryAmounts(self, _crtokens, _stablecoins, _position);
        _position.token_a_amount = a_amount;
        _position.token_b_amount = b_amount;
        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Main entry function to borrow and enter a given position.
    function enterPosition(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position, uint _type) public returns (Position memory) {
        
        if (_type == 1) {
            // Supply position
            uint token_balance = IBEP20(_position.token).balanceOf(address(this));
            uint enter_amount = SafeMath.div(SafeMath.mul(token_balance, _position.supply_funds_percentage), 100);
            supplyCream(_position.supply_crtoken, enter_amount);
            _position.token_amount = IBEP20(_position.token).balanceOf(address(this));
            _position.crtoken_amount = IBEP20(_position.supply_crtoken).balanceOf(address(this));
        }
        
        if (_type == 1 || _type == 2) {
            // Borrowing position
            borrowPosition(_position);
            _position.token_a_amount = IBEP20(_position.token_a).balanceOf(address(this));
            _position.token_b_amount = IBEP20(_position.token_b).balanceOf(address(this));
        }
        
        if (_type == 1 || _type == 2 || _type == 3) {
            // Entering position
            enter(self, _crtokens, _stablecoins, _position); 
            _position.lp_token_amount = IBEP20(_position.lp_token).balanceOf(address(this));
            _position.token_a_amount = IBEP20(_position.token_a).balanceOf(address(this));
            _position.token_b_amount = IBEP20(_position.token_b).balanceOf(address(this));
        }
        
        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Main exit function to exit and repay a given position.
    function exitPosition(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position, uint _type) public returns (Position memory) {
        
        if (_type == 1 || _type == 2 || _type == 3) {
            // Exiting position
            exit(self, _stablecoins, _position);
            _position.lp_token_amount = IBEP20(_position.lp_token).balanceOf(address(this));
            _position.token_a_amount = IBEP20(_position.token_a).balanceOf(address(this));
            _position.token_b_amount = IBEP20(_position.token_b).balanceOf(address(this));
        }
        
        if (_type == 1 || _type == 2) {
            // Returning borrow
            returnBorrow(_crtokens, _stablecoins, _position);
            _position.supply_crtoken_amount = IBEP20(_position.supply_crtoken).balanceOf(address(this));
            _position.token_a_amount = IBEP20(_position.token_a).balanceOf(address(this));
            _position.token_b_amount = IBEP20(_position.token_b).balanceOf(address(this));
        }
        
        if (_type == 1) {
            // Redeem position
            uint exit_amount_a = IBEP20(_position.token_a).balanceOf(address(this));
            uint exit_amount_b = IBEP20(_position.token_b).balanceOf(address(this));
            redeemCream(_position.borrowed_crtoken_a, exit_amount_a);
            redeemCream(_position.borrowed_crtoken_b, exit_amount_b);
            _position.token_amount = IBEP20(_position.token).balanceOf(address(this));
            _position.crtoken_amount = IBEP20(_position.supply_crtoken).balanceOf(address(this));
            _position.token_a_amount = IBEP20(_position.token_a).balanceOf(address(this));
            _position.token_b_amount = IBEP20(_position.token_b).balanceOf(address(this));
        }

        return _position;
    }

    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Repay the tokens borrowed from cream.
    function returnBorrow(CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position) public {
        uint borrowed_a = CreamExecution.getBorrowAmount(_position.borrowed_crtoken_a, _crtokens.crWBNB);
        uint borrowed_b = CreamExecution.getBorrowAmount(_position.borrowed_crtoken_b, _crtokens.crWBNB);

        uint current_a_balance = CreamExecution.getTokenBalance(_position.borrowed_crtoken_a);
        uint current_b_balance = CreamExecution.getTokenBalance(_position.borrowed_crtoken_b);

        uint a_repay_amount;
        uint b_repay_amount;

        if (borrowed_a < current_a_balance) {
            a_repay_amount = borrowed_a;
        } else {
            a_repay_amount = current_a_balance;
        }
        if (borrowed_b < current_b_balance) {
            b_repay_amount = borrowed_b;
        } else {
            b_repay_amount = current_b_balance;
        }

        // CrTokenAddress issue
        uint _isWBNB = isWBNB(_stablecoins, _position.token_a, _position.token_b);
        if (_isWBNB == 2) {
            CreamExecution.repay(_position.borrowed_crtoken_a, a_repay_amount);
            CreamExecution.repay(_position.borrowed_crtoken_b, b_repay_amount);
        } else if (_isWBNB == 1) {
            CreamExecution.repayETH(_position.borrowed_crtoken_a, a_repay_amount);
            CreamExecution.repay(_position.borrowed_crtoken_b, b_repay_amount);
        } else if (_isWBNB == 0)  {
            CreamExecution.repay(_position.borrowed_crtoken_a, a_repay_amount);
            CreamExecution.repayETH(_position.borrowed_crtoken_b, b_repay_amount);
        }

    }

    /// @param _position refer Position struct on the top.
    /// @dev Borrow the required tokens for a given position on CREAM.
    function borrowPosition(Position memory _position) public {
        CreamExecution.borrow(_position.borrowed_crtoken_a, _position.token_a_amount);
        CreamExecution.borrow(_position.borrowed_crtoken_b, _position.token_b_amount);
    }

    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _token_a BEP20 token address.
    /// @param _token_b BEP20 token address.
    /// @dev Checks if either token address is WBNB.
    function isWBNB(StableCoin memory _stablecoins, address _token_a, address _token_b) public pure returns (uint) {
        if (_token_a == _stablecoins.WBNB && _token_b == _stablecoins.WBNB) {
            return 2;
        } else if (_token_a == _stablecoins.WBNB) {
            return 1;
        } else if (_token_b == _stablecoins.WBNB) {
            return 0;
        } else {
            return 2;
        }
    }

    /// @param _crtoken_a Cream crToken address..
    /// @param _crtoken_b Cream crToken address..
    /// @dev Gets an array of all the cream tokens that have been borrowed.
    function getBorrowedCreamTokens(address _crtoken_a, address _crtoken_b) public pure returns (address, address) {
        
        return (_crtoken_a, _crtoken_b);
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @param self refer HLSConfig struct on the top.
    /// @dev Gets the total borrow limit for all positions on cream.
    function checkCurrentBorrowLimit(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position) public returns (uint) {
        uint crtoken_a_supply_amount = CreamExecution.getUserTotalSupply(_position.borrowed_crtoken_a);
        uint crtoken_a_borrow_amount = CreamExecution.getBorrowAmount(_position.borrowed_crtoken_a, _crtokens.crWBNB);
        uint crtoken_a_limit = CreamExecution.getBorrowLimit(self.CreamConfig, _position.borrowed_crtoken_a, _crtokens.crUSDC, _stablecoins.USDC, crtoken_a_supply_amount, crtoken_a_borrow_amount);

        uint crtoken_b_supply_amount = CreamExecution.getUserTotalSupply(_position.borrowed_crtoken_b);
        uint crtoken_b_borrow_amount = CreamExecution.getBorrowAmount(_position.borrowed_crtoken_b, _crtokens.crWBNB);
        uint crtoken_b_limit = CreamExecution.getBorrowLimit(self.CreamConfig, _position.borrowed_crtoken_b, _crtokens.crUSDC, _stablecoins.USDC, crtoken_b_supply_amount, crtoken_b_borrow_amount);
        return crtoken_a_limit + crtoken_b_limit;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @param new_amount_a amount of token a.
    /// @param new_amount_b amount of token b.
    /// @dev Check if entering this new position will violate any borrow/lending limits.
    function checkPotentialBorrowLimit(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position, uint new_amount_a, uint new_amount_b) public returns (uint) {
        uint current_borrow_limit = checkCurrentBorrowLimit(self, _crtokens, _stablecoins, _position);

        uint crtoken_a_supply_amount = CreamExecution.getUserTotalSupply(_position.borrowed_crtoken_a);
        uint borrow_limit_a = CreamExecution.getBorrowLimit(self.CreamConfig, _position.borrowed_crtoken_a, _crtokens.crUSDC, _stablecoins.USDC, crtoken_a_supply_amount, new_amount_a);
        
        uint crtoken_b_supply_amount = CreamExecution.getUserTotalSupply(_position.borrowed_crtoken_b);
        uint borrow_limit_b = CreamExecution.getBorrowLimit(self.CreamConfig, _position.borrowed_crtoken_b, _crtokens.crUSDC, _stablecoins.USDC, crtoken_b_supply_amount, new_amount_b);

        return current_borrow_limit + borrow_limit_a + borrow_limit_b;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _crtokens refer CreamToken struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Adds liquidity to a given pool.
    function addLiquidity(HLSConfig memory self, CreamToken memory _crtokens, StableCoin memory _stablecoins, Position memory _position) public returns (uint) {
        uint pair_price = getPrice(self, _crtokens, _stablecoins, _position.token_a, _position.token_b, _position.borrowed_crtoken_a, _position.borrowed_crtoken_b);
        uint price_decimals = PancakeSwapExecution.getPairDecimals(PancakeSwapExecution.getPair(self.PancakeSwapConfig, _position.token_a, _position.token_b));

        // make sure if one of the tokens is WBNB => have a minimum of 0.3 BNB in the wallet at all times
        // get a 50:50 split of the tokens in USD and make sure the two tokens are in correct order
        (uint max_available_staking_a, uint max_available_staking_b) = PancakeSwapExecution.splitTokensEvenly(_position.token_a_amount, _position.token_b_amount, pair_price, price_decimals);

        // todo check the lineups => amount for tokens a and tokens b is off
        (max_available_staking_a, max_available_staking_b) = PancakeSwapExecution.lineUpPairs(_position.token_a, _position.token_b, max_available_staking_a, max_available_staking_b, _position.lp_token);
        (address token_a, address token_b) = PancakeSwapExecution.getLPTokenAddresses(_position.lp_token);

        uint bnb_check = isWBNB(_stablecoins, token_a, token_b);
        if (bnb_check != 2) {
            if (bnb_check == 1) {
                return PancakeSwapExecution.addLiquidityETH(self.PancakeSwapConfig, token_a, _stablecoins.WBNB, max_available_staking_b, max_available_staking_a);
            } else {
                return PancakeSwapExecution.addLiquidityETH(self.PancakeSwapConfig, token_b, _stablecoins.WBNB, max_available_staking_a, max_available_staking_b);
            }
        } else {
            return PancakeSwapExecution.addLiquidity(self.PancakeSwapConfig, token_a, token_b, max_available_staking_a, max_available_staking_b);
        }
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _stablecoins refer StableCoin struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Removes liquidity from a given pool.
    function removeLiquidity(HLSConfig memory self, StableCoin memory _stablecoins, Position memory _position) public returns (bool) {
        // check how much (token0 and token1) we have in the current farm
        //this function already sorts the token orders according to the contract
        uint lp_balance = PancakeSwapExecution.getLPBalance(_position.lp_token);
        (uint token_a_amnt, uint token_b_amnt) = PancakeSwapExecution.getLPConstituients(lp_balance, _position.lp_token);

        (address token_a, address token_b) = PancakeSwapExecution.getLPTokenAddresses(_position.lp_token);
        uint bnb_check = isWBNB(_stablecoins, token_a, token_b);

        if (bnb_check != 2) {
            if (bnb_check == 1) {
                PancakeSwapExecution.removeLiquidityETH(self.PancakeSwapConfig, _position.lp_token, token_a, lp_balance, token_a_amnt, token_b_amnt);
            } else {
                PancakeSwapExecution.removeLiquidityETH(self.PancakeSwapConfig, _position.lp_token, token_b, lp_balance, token_b_amnt, token_a_amnt);
            }
        } else {
            PancakeSwapExecution.removeLiquidity(self.PancakeSwapConfig, _position.lp_token, token_a, token_b, lp_balance, token_a_amnt, token_b_amnt);
        }

        return true;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Stakes LP tokens into a farm.
    function stakeLP(HLSConfig memory self, Position memory _position) public returns (bool) {
        uint lp_balance = PancakeSwapExecution.getLPBalance(_position.lp_token);
        return PancakeSwapExecution.stakeLP(self.PancakeSwapConfig, _position.pool_id, lp_balance);
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Removes liquidity from a given farm.
    function unstakeLP(HLSConfig memory self, Position memory _position) public returns (bool) {
        uint lp_balance = PancakeSwapExecution.getStakedLP(self.PancakeSwapConfig, _position.pool_id);
        return PancakeSwapExecution.unstakeLP(self.PancakeSwapConfig, _position.pool_id, lp_balance);
    }
    
    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Return staked tokens.
    function getStakedTokens(HLSConfig memory self, Position memory _position) public view returns (uint, uint) {
        uint lp_balance = PancakeSwapExecution.getStakedLP(self.PancakeSwapConfig, _position.pool_id);
        (uint token_a_amnt, uint token_b_amnt) = PancakeSwapExecution.getLPConstituients(lp_balance, _position.lp_token);
        return (token_a_amnt, token_b_amnt);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../token/BEP20/IBEP20.sol";
import "../math/SafeMath.sol";
import "../interfaces/cream/CErc20Delegator.sol";
import "../interfaces/cream/InterestRateModel.sol";
import "../interfaces/cream/PriceOracleProxy.sol";

/// @title Cream execution
/// @author Andrew FU
/// @dev All functions haven't finished unit test
library CreamExecution {
    
    // Addresss of Cream.
    struct CreamConfig {
        address oracle; // Address of Cream oracle contract.
    }
    
    /// @param crtoken_address Cream crToken address.
    function getAvailableBorrow(address crtoken_address) public view returns (uint) {
        
        return CErc20Delegator(crtoken_address).getCash();
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the current borrow rate for the underlying token.
    function getBorrowRate(address crtoken_address) public view returns (uint) {
        uint cash = CErc20Delegator(crtoken_address).getCash();
        uint borrows = CErc20Delegator(crtoken_address).totalBorrows();
        uint reserves = CErc20Delegator(crtoken_address).totalReserves();
        uint decimals = CErc20Delegator(crtoken_address).decimals();
        
        address interest_rate_address = CErc20Delegator(crtoken_address).interestRateModel();
        
        uint borrowRate = InterestRateModel(interest_rate_address).getBorrowRate(cash, borrows, reserves);
        
        return SafeMath.div(borrowRate, 10**(decimals + 1));
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the current borrow rate for a token.
    function getSupplyRate(address crtoken_address) public view returns (uint) {
        uint cash = CErc20Delegator(crtoken_address).getCash();
        uint borrows = CErc20Delegator(crtoken_address).totalBorrows();
        uint reserves = CErc20Delegator(crtoken_address).totalReserves();
        uint mantissa = CErc20Delegator(crtoken_address).reserveFactorMantissa();
        uint decimals = CErc20Delegator(crtoken_address).decimals();
        
        address interest_rate_address = CErc20Delegator(crtoken_address).interestRateModel();
        
        uint supplyRate = InterestRateModel(interest_rate_address).getSupplyRate(cash, borrows, reserves, mantissa);
        
        return SafeMath.div(supplyRate, 10**(decimals + 1));
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @param crWBNB_address Cream crWBNB address.
    /// @dev Gets the borrowed amount for a particular token.
    /// @return crToken amount
    function getBorrowAmount(address crtoken_address, address crWBNB_address) public view returns (uint) {
        if (crtoken_address == crWBNB_address) {
            revert("we never use WBNB (insufficient liquidity), so just use BNB instead");
        }
        return CErc20Delegator(crtoken_address).borrowBalanceStored(address(this));
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the borrowed amount for a particular token.
    /// @return crToken amount.
    function getUserTotalSupply(address crtoken_address) public returns (uint) {
        
        return CErc20Delegator(crtoken_address).balanceOfUnderlying(address(this));
    }
    
    /// @dev Gets the USDCBNB price.
    function getUSDCBNBPrice(CreamConfig memory self, address crUSDC_address) public view returns (uint) {
        
        return PriceOracleProxy(self.oracle).getUnderlyingPrice(crUSDC_address);
    }
    
    /// @dev Gets the bnb amount.
    function getCrTokenBalance(CreamConfig memory self, address crtoken_address) public view returns (uint) {
        
        return PriceOracleProxy(self.oracle).getUnderlyingPrice(crtoken_address);
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the crtoken/BNB price.
    function getTokenPrice(CreamConfig memory self, address crtoken_address) public view returns (uint) {
        
        return PriceOracleProxy(self.oracle).getUnderlyingPrice(crtoken_address);
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the current exchange rate for a ctoken.
    function getExchangeRate(address crtoken_address) public view returns (uint) {
        
        return CErc20Delegator(crtoken_address).exchangeRateStored();
    }
    
    /// @return the current borrow limit on the platform.
    function getBorrowLimit(CreamConfig memory self, address borrow_crtoken_address, address crUSDC_address, address USDC_address, uint supply_amount, uint borrow_amount) public view returns (uint) {
        uint borrow_token_price = getTokenPrice(self, borrow_crtoken_address);
        uint usdc_bnb_price = getTokenPrice(self, crUSDC_address);
        uint usdc_decimals = IBEP20(USDC_address).decimals();
        uint one_unit_of_usdc = SafeMath.mul(1, 10**usdc_decimals);
        
        uint token_price = SafeMath.div(SafeMath.mul(borrow_token_price, one_unit_of_usdc), usdc_bnb_price);
        uint borrow_usdc_value = SafeMath.mul(token_price, borrow_amount);
        
        supply_amount = SafeMath.mul(supply_amount, 100);
        supply_amount = SafeMath.div(supply_amount, 75);
        
        return SafeMath.div(borrow_usdc_value, supply_amount);
    }
    
    /// @return the amount in the wallet for a given token.
    function getWalletAmount(address crtoken_address) public view returns (uint) {
        
        return CErc20Delegator(crtoken_address).balanceOf(address(this));
    }
    
    function borrow(address crtoken_address, uint borrow_amount) public returns (uint) {
        // TODO make sure don't borrow more than the limit
        return CErc20Delegator(crtoken_address).borrow(borrow_amount);
    }

    function getUnderlyingAddress(address crtoken_address) public view returns (address) {
        
        return CErc20Delegator(crtoken_address).underlying();
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Get the token/BNB price.
    function getUSDPrice(CreamConfig memory self, address crtoken_address, address crUSDC_address, address USDC_address) public view returns (uint) {
        uint token_bnb_price = getTokenPrice(self, crtoken_address);
        uint usd_bnb_price = getUSDCBNBPrice(self, crUSDC_address);
        
        uint usdc_decimals = IBEP20(USDC_address).decimals();
        uint one_unit_of_usdc = SafeMath.mul(1, 10**usdc_decimals);
        return SafeMath.div(SafeMath.mul(token_bnb_price, one_unit_of_usdc), usd_bnb_price);
    }
    
    function repay(address crtoken_address, uint repay_amount) public returns (uint) {
        address underlying_address = getUnderlyingAddress(crtoken_address);
        IBEP20(underlying_address).approve(crtoken_address, repay_amount);
        return CErc20Delegator(crtoken_address).repayBorrow(repay_amount);
    }
    
    function repayETH(address crBNB_address, uint repay_amount) public returns (uint) {
        
        return CErc20Delegator(crBNB_address).repayBorrow(repay_amount);
    }
    
    // TODO Johnny need to confirm this function again.
    function repayAll(address token_addr, address crtoken_address, address crWBNB_address) public returns (bool) {
        uint current_wallet_amount = getWalletAmount(token_addr);
        uint borrow_amount = getBorrowAmount(crtoken_address, crWBNB_address);
        
        require(current_wallet_amount >= borrow_amount, "Not enough funds in the wallet for the transaction");
        repay(crtoken_address, borrow_amount);
        
        return true;
    }

    /// @param crtoken_address Cream crToken address
    /// @param amount amount of tokens to mint.
    /// @dev Supplies amount worth of crtokens into cream.
    function supply(address crtoken_address, uint amount) public returns (uint) {
        address underlying_address = getUnderlyingAddress(crtoken_address);
        IBEP20(underlying_address).approve(crtoken_address, amount);
        return CErc20Delegator(crtoken_address).mint(amount);
    }
    
    /// @param crtoken_address Cream crToken address
    /// @param amount amount of crtokens to redeem.
    /// @dev Redeem amount worth of crtokens back.
    function redeemUnderlying(address crtoken_address, uint amount) public returns (uint) {
        IBEP20(crtoken_address).approve(crtoken_address, amount);
        return CErc20Delegator(crtoken_address).redeemUnderlying(amount);
    }
    
    function getTokenBalance(address token_address) public view returns (uint) {
        
        return IBEP20(token_address).balanceOf(address(this));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface MasterChef {

    function poolLength() external view returns (uint256);

    function updateStakingPool() external;

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) external;

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external;


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) external;

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external;

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;

    // Safe cake transfer function, just in case if rounding error causes pool to not have enough CAKEs.
    function safeCakeTransfer(address _to, uint256 _amount) external;

    // Update dev address by the previous dev.
    function dev(address _devaddr) external;
    
    function poolInfo(uint256) external view returns (address, uint256, uint256, uint256);
    
    function userInfo(uint256, address) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
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
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface PriceOracleProxy {

    function getUnderlyingPrice(address cToken) external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface InterestRateModel {

    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
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

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);
  function decimals() external view returns (uint8);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // Unit test need to comment this line.
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        // require(_owner != address(0), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() public {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}