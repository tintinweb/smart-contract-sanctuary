/*

 This contract is provided "as is" and "with all faults." The deployer makes no representations or warranties
 of any kind concerning the safety, suitability, lack of exploits, inaccuracies, typographical errors, or other
 harmful components of this contract. There are inherent dangers in the use of any contract, and you are solely
 responsible for determining whether this contract is safe to use. You are also solely responsible for the 
 protection of your funds, and the deployer will not be liable for any damages you may suffer in connection with
 using, modifying, or distributing this contract.

*/

pragma solidity ^0.5.17;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "LBI::SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
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
    function mod(uint a, uint b) internal pure returns (uint) {
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
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface UniswapPair {
    function sync() external;
    function transferFrom(address from, address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function mint(address to) external returns (uint liquidity);
}

interface IBondingCurve {
    function calculatePurchaseReturn(uint _supply,  uint _reserveBalance, uint32 _reserveRatio, uint _depositAmount) external view returns (uint);
}

interface WETH9 {
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
}

interface Uniswap {
    function factory() external pure returns (address);
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
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface LBI {
    function approve(address spender, uint amount) external returns (bool);
}

interface RewardDistributionDelegate {
    function notifyRewardAmount(uint reward) external;
}

interface RewardDistributionFactory {
    function deploy(
        address lp_, 
        address earn_, 
        address rewardDistribution_,
        uint8 decimals_,
        string calldata name_,
        string calldata symbol_
    ) external returns (address);
}

interface GovernanceFactory {
    function deploy(address token) external returns (address);
}

contract LiquidityIncome {
    using SafeMath for uint;
    
    /* BondingCurve */
    
    uint public scale = 10**18;
    uint public reserveBalance = 1*10**14;
    uint32 public constant RATIO = 500000;
    
    WETH9 constant public WETH = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    function () external payable { mint(0); }
    
    function mint(uint min) public payable {
        require(msg.value > 0, "LBI::mint: msg.value = 0");
        uint _bought = _continuousMint(msg.value);
        require(_bought >= min, "LBI::mint: slippage");
        WETH.deposit.value(msg.value)();
        WETH.transfer(address(pool), WETH.balanceOf(address(this)));
        pool.sync();
        _mint(msg.sender, _bought, true);
    }
    
    IBondingCurve constant public CURVE = IBondingCurve(0x16F6664c16beDE5d70818654dEfef11769D40983);

    function _buy(uint _amount) internal returns (uint _bought) {
        _bought = _continuousMint(_amount);
    }

    function calculateMint(uint _amount) public view returns (uint mintAmount) {
        return CURVE.calculatePurchaseReturn(totalSupply, reserveBalance, RATIO, _amount);
    }

    function _continuousMint(uint _deposit) internal returns (uint) {
        uint amount = calculateMint(_deposit);
        reserveBalance = reserveBalance.add(_deposit);
        return amount;
    }
    
    /// @notice EIP-20 token name for this token
    string public constant name = "Liquidity Income";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "LBI";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;
    
    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0; // Initial 0
    
    /// @notice the last block the tick was applied
    uint public lastTick = 0;
    
    /// @notice the uniswap pool that will receive the rebase
    UniswapPair public pool;
    RewardDistributionDelegate public rewardDistribution;
    RewardDistributionFactory public constant REWARDFACTORY = RewardDistributionFactory(0x323B2b67Ed1a745e5208ac18625ecef187a421D0);
    GovernanceFactory public constant GOVERNANCEFACTORY = GovernanceFactory(0x4179Ef5dC359A4f73D5A14aF264f759052325bc1);
    
    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping (address => uint) internal balances;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint amount);
    
    /// @notice Tick event
    event Tick(uint block, uint minted);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    Uniswap public constant UNI = Uniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    /* Incremental system for balance increments */
    uint256 public index = 0; // previously accumulated index
    uint256 public bal = 0; // previous calculated balance of COMP

    mapping(address => uint256) public supplyIndex;
    
    function _update(bool sync) internal {
        if (totalSupply > 0) {
            uint256 _before = balances[address(this)];
            tick(sync);
            uint256 _bal = balances[address(this)];
            if (_bal > 0 && _bal > _before) {
                uint256 _diff = _bal.sub(bal, "LBI::_update: ball _diff");
                if (_diff > 0) {
                    uint256 _ratio = _diff.mul(1e18).div(totalSupply);
                    if (_ratio > 0) {
                      index = index.add(_ratio);
                      bal = _bal;
                    }
                }
            }
        }
    }
    
    mapping(address => uint) claimable;
    
    function claim() external {
        claimFor(msg.sender);
    }
    function claimFor(address recipient) public {
        _updateFor(recipient, true);
        _transferTokens(address(this), recipient, claimable[recipient]);
        claimable[recipient] = 0;
        bal = balances[address(this)];
    }
    
    function _updateFor(address recipient, bool sync) public {
        _update(sync);
        uint256 _supplied = balances[recipient];
        if (_supplied > 0) {
            uint256 _supplyIndex = supplyIndex[recipient];
            supplyIndex[recipient] = index;
            uint256 _delta = index.sub(_supplyIndex, "LBI::_claimFor: index delta");
            if (_delta > 0) {
              uint256 _share = _supplied.mul(_delta).div(1e18);
              claimable[recipient] = claimable[recipient].add(_share);
            }
        } else {
            supplyIndex[recipient] = index;
        }
    }
    
    constructor() public {
        lastTick = block.number;
    }
    
    address public governance;
    
    function setup() external payable {
        require(msg.value > 0, "LBT:(): constructor requires ETH");
        require(address(pool) == address(0x0), "LBT:(): already initialized");
        
        _mint(address(this), 10000e18, true); // init total supply
        WETH.deposit.value(msg.value)();
        
        _mint(address(this), _continuousMint(msg.value), true);
        uint _balance = WETH.balanceOf(address(this));
        require(_balance == msg.value, "LBT:(): WETH9 error");
        WETH.approve(address(UNI), _balance);
        allowances[address(this)][address(UNI)] = balances[address(this)];
        require(allowances[address(this)][address(UNI)] == balances[address(this)], "LBT:(): address(this) error");
        
        UNI.addLiquidity(address(this), address(WETH), balances[address(this)], WETH.balanceOf(address(this)), 0, 0, msg.sender, now.add(1800));
        pool = UniswapPair(Factory(UNI.factory()).getPair(address(this), address(WETH)));
        rewardDistribution = RewardDistributionDelegate(REWARDFACTORY.deploy(address(pool), address(this), address(this), 18, "Liquidity Income Delegate", "LBD"));
        _mint(address(this), 1e18, true);
        allowances[address(this)][address(rewardDistribution)] = 1e18;
        rewardDistribution.notifyRewardAmount(1e18);
        governance = GOVERNANCEFACTORY.deploy(address(rewardDistribution));
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "LBI::setGovernance: governance only");
        governance = _governance;
    }
    
    // TEST HELPER FUNCTION :: DO NOT USE
    function removeLiquidityMax() public {
        removeLiquidity(pool.balanceOf(msg.sender), 0, 0);
    }
    
    // TEST HELPER FUNCTION :: DO NOT USE
    function removeLiquidity(uint amountA, uint minA, uint minB) public {
        tick(true);
        pool.transferFrom(msg.sender, address(this), amountA);
        pool.approve(address(UNI), amountA);
        UNI.removeLiquidity(address(this), address(WETH), amountA, minA, minB, msg.sender, now.add(1800));
    }
    
    // TEST HELPER FUNCTION :: DO NOT USE
    function addLiquidityMax() public payable {
        addLiquidity(balances[msg.sender]);
    }
    
    // TEST HELPER FUNCTION :: DO NOT USE
    function addLiquidity(uint amountA) public payable {
        tick(true);
        WETH.deposit.value(msg.value)();
        WETH.transfer(address(pool), msg.value);
        _transferTokens(msg.sender, address(pool), amountA);
        pool.mint(msg.sender);
    }
    
    function _mint(address dst, uint amount, bool sync) internal {
        // mint the amount
        totalSupply = totalSupply.add(amount);

        _updateFor(dst, sync);
        // transfer the amount to the recipient
        balances[dst] = balances[dst].add(amount);
        emit Transfer(address(0), dst, amount);
    }
    
    uint public LP = 9000;
    uint public constant BASE = 10000;
    uint public DURATION = 700000;
    
    address public timelock;
    
    function setDuration(uint duration_) external {
        require(msg.sender == governance, "LBI::setDuration only governance");
        DURATION = duration_;
    }
    
    function setRatio(uint lp_) external {
        require(msg.sender == governance, "LBI::setRatio only governance");
        LP = lp_;
    }
    
    /**
     * @notice tick to increase holdings
     */
    function tick(bool sync) public {
        uint _current = block.number;
        uint _diff = _current.sub(lastTick);
        
        if (_diff > 0) {
            lastTick = _current;
            
            _diff = balances[address(pool)].mul(_diff).div(DURATION); // 1% every 7000 blocks
            uint _minting = _diff.div(2);
            if (_minting > 0) {
                _transferTokens(address(pool), address(this), _minting);
                
                // Can't call sync while in addLiquidity or removeLiquidity
                if (sync) {
                    pool.sync();
                }
                _mint(address(this), _minting, false);
                // % of tokens that go to LPs
                uint _lp = _diff.mul(LP).div(BASE);
                allowances[address(this)][address(rewardDistribution)] = _lp;
                rewardDistribution.notifyRewardAmount(_lp);
                
                emit Tick(_current, _diff);
            }
        }
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "LBI::permit: invalid signature");
        require(signatory == owner, "LBI::permit: unauthorized");
        require(now <= deadline, "LBI::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) public returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint(-1)) {
            uint newAllowance = spenderAllowance.sub(amount, "LBI::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "LBI::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "LBI::_transferTokens: cannot transfer to the zero address");
        
        bool sync = true;
        if (src == address(pool) || dst == address(pool)) {
            sync = false;
        }
        
        _updateFor(src, sync);
        _updateFor(dst, sync);
        
        balances[src] = balances[src].sub(amount, "LBI::_transferTokens: transfer amount exceeds balance");
        balances[dst] = balances[dst].add(amount, "LBI::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}