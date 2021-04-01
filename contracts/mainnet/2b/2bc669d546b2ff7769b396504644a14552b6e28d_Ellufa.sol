/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity 0.5.10;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

   

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining);

    function decimals() public view returns (uint256 digits);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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



contract Ellufa {
    struct User {
        uint256 cycle;
        uint256 total_deposits;
        uint256 max_earnings;
        uint256 earnings_left;
        uint256 total_withdrawl;
        uint256 profitpayout;
        uint256 total_profitpayout;
        uint256 stakingpayout;
        uint256 total_stakingpayout;
        uint8 leader_status;
    }

    struct Merchant {
        uint256 total_payout;
        uint8 status;
    }

    struct Package {
        uint8 status;
        uint8 maxPayout;
    }

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address payable public owner;
    address payable public companyaddress;
    address payable public usdt_address;

    address public node_address;
    address public exchange_address;
    
    uint256 public total_depositcount = 0;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_exchange_credit;
    uint256 public total_payout;
    uint256 public total_profit;
    uint256 public current_profit;
    uint256 public total_staked;
    uint256 public current_staked;
    uint8 public phaseversion;
    uint8 public tokendebit; // If disable its wont debit 20%
    uint256 public min_withdrawal; // Before live change to 6 digit
    uint8 public staking_status;
    uint8 public merchant_status;
    uint256 public multiplier;
    address public elft_address;
    uint8 public token_transfer_status;
    uint256 public token_price;
    uint8 public token_share;

    mapping(address => User) public users;

    mapping(address => Merchant) public merchants;

    mapping(uint256 => Package) public packages;

    event NewDeposit(address indexed addr, uint256 amount);
    event PayoutEvent(address indexed addr, uint256 payout, uint256 staking);
    event WithdrawEvent(address indexed addr, uint256 amount, uint256 service);
    event StakingEvent(address indexed addr, uint256 amount);
    event MerchantEvent(address indexed addr, uint256 amount);
    event ELFTTranEvent(address indexed addr, uint256 amount);
    event ExchangeDebit(address indexed addr, uint256 amount);
    event ExchangeCredit(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;

        multiplier = 1000000;

        companyaddress = 0xFE31Bf2345A531dD2A8E6c5444070248698171BF;

        usdt_address = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

        phaseversion = 1;

        tokendebit = 1;

        min_withdrawal = 100 * multiplier;

        staking_status = 0;

        merchant_status = 0;

        token_share = 20;

        packages[1000 * multiplier].status = 1;
        packages[1000 * multiplier].maxPayout = 2;
    }

    function initDeposit() external {
        
        
        IERC20 tc = IERC20(usdt_address);

        require(users[msg.sender].earnings_left == 0, "MAX CAP NOT REACHED");

        require(
            tc.allowance(msg.sender, address(this)) > 0,
            "USDT APPROVAL FAILED"
        );

        uint256 _amount = tc.allowance(msg.sender, address(this));

        
        tc.safeTransferFrom(msg.sender, address(this), _amount);
           
        
    
        uint256 company_fee = _amount.div(100).mul(10);

        tc.safeTransfer(companyaddress, company_fee);

        uint256 token_fee = _amount.div(100).mul(token_share);

        if (tokendebit == 1) {
            tc.safeTransfer(companyaddress, token_fee);
        } else {
            //Phase 2 Added to staking
            users[msg.sender].stakingpayout = users[msg.sender]
                .stakingpayout
                .add(token_fee);

            users[msg.sender].total_stakingpayout = users[msg.sender]
                .total_stakingpayout
                .add(token_fee);

            total_staked = total_staked.add(token_fee);
            current_staked = current_staked.add(token_fee);
        }

        uint256 mxpayout = maxPayoutof(_amount);

        users[msg.sender].cycle++;
        total_depositcount++;
        total_deposited += _amount;
        users[msg.sender].total_deposits += _amount;
        users[msg.sender].max_earnings += mxpayout;
        users[msg.sender].earnings_left += mxpayout;

        emit NewDeposit(msg.sender, _amount);

        
    }

    function maxPayoutof(uint256 _amount) private view returns (uint256) {
        uint8 maxtimes = packages[_amount].maxPayout;

        return _amount * maxtimes;
    }

    function addNodeAddress(address _addr) external {
        require(msg.sender == owner, "OWNER ONLY");

        node_address = _addr;
    }

    function addPayout(address _addr, uint256 amount) external {
        require(
            msg.sender == owner || msg.sender == node_address,
            "PRIVILAGED USER ONLY"
        );

        if (users[_addr].leader_status == 0)
            require(users[_addr].earnings_left >= amount, "MAX PAYOUT REACHED");

        total_payout = total_payout.add(amount);

        uint256 _profit = amount.div(100).mul(80);

        uint256 _staked = amount.div(100).mul(20);

        total_profit = total_profit.add(_profit);
        current_profit = current_profit.add(_profit);

        total_staked = total_staked.add(_staked);
        current_staked = current_staked.add(_staked);

        if (users[_addr].leader_status == 0)
            users[_addr].earnings_left -= amount;

        users[_addr].profitpayout += _profit;
        users[_addr].total_profitpayout += _profit;
        users[_addr].stakingpayout += _staked;
        users[_addr].total_stakingpayout += _staked;

        emit PayoutEvent(
            _addr,
            amount.div(100).mul(80),
            amount.div(100).mul(20)
        );
    }

    function withdraw(uint256 _amount) external {
        require(
            users[msg.sender].profitpayout >= min_withdrawal,
            "MIN 100 USDT"
        );

        require(users[msg.sender].profitpayout >= _amount, "NOT ENOUGH MONEY");

        require(_amount >= min_withdrawal, "MIN 100 USDT");

        IERC20 tc = IERC20(usdt_address);

        tc.safeTransfer(msg.sender, _amount.div(100).mul(95));
        tc.safeTransfer(companyaddress, _amount.div(100).mul(5));

        users[msg.sender].total_withdrawl = users[msg.sender]
            .total_withdrawl
            .add(_amount);

        total_withdraw = total_withdraw.add(_amount);

        current_profit = current_profit.sub(_amount);

        emit WithdrawEvent(
            msg.sender,
            _amount.div(100).mul(95),
            _amount.div(100).mul(5)
        );

        users[msg.sender].profitpayout = users[msg.sender].profitpayout.sub(
            _amount
        );
    }

    function investStaking(uint256 amount) external {
        require(staking_status == 1, "STAKING NOT ENABLED");

        require(
            users[msg.sender].stakingpayout >= amount,
            "NOT ENOUGH STAKING AMOUNT"
        );

        current_staked = current_staked.sub(amount);
        users[msg.sender].stakingpayout = users[msg.sender].stakingpayout.sub(
            amount
        );

        IERC20 tc = IERC20(usdt_address);
        tc.safeTransfer(companyaddress, amount);

        emit StakingEvent(msg.sender, amount);

        if (token_transfer_status == 1) {
            IERC20 elft = IERC20(elft_address);

            uint256 return_token = amount.div(token_price).mul(multiplier);

            elft.safeTransfer(msg.sender, return_token);

            emit ELFTTranEvent(msg.sender, amount);
        }
    }

    function addMerchant(address _addr) external {
        require(msg.sender == owner, "OWNER ONLY");

        merchants[_addr].status = 1;
    }

    function payMerchant(address _addr, uint256 _amount) external {
        require(merchant_status == 1, "MERCHANT NOT ENABLED");

        require(merchants[_addr].status == 1, "ADDRESS NOT AVAILABLE");

        require(
            users[msg.sender].stakingpayout >= _amount,
            "NOT ENOUGH BALANCE"
        );

        current_staked = current_staked.sub(_amount);
        users[msg.sender].stakingpayout = users[msg.sender].stakingpayout.sub(
            _amount
        );

        merchants[_addr].total_payout = merchants[_addr].total_payout.add(
            _amount
        );

        IERC20 tc = IERC20(usdt_address);
        tc.safeTransfer(_addr, _amount);

        emit MerchantEvent(msg.sender, _amount);
    }

    function addPackage(uint256 _amount, uint8 _maxpayout) public {
        require(msg.sender == owner, "OWNER ONLY");

        require(_maxpayout >= 2, "MINIMUM 2 TIMES RETURN");

        packages[_amount * multiplier].status = 1;
        packages[_amount * multiplier].maxPayout = _maxpayout;
    }

    function addLeaderAddress(address _address) public {
        require(msg.sender == owner, "OWNER ONLY");

        users[_address].leader_status = 1;
    }

    function addELFTAddress(address _address) public {
        require(msg.sender == owner, "OWNER ONLY");

        require(_address != address(0), "VALUID ADDRESS REQUIRED");

        elft_address = _address;

        token_transfer_status = 1;
    }
    
    function addExchangeAddress(address _address) public {
        require(msg.sender == owner, "OWNER ONLY");

        require(_address != address(0), "VALUID ADDRESS REQUIRED");

        exchange_address = _address;
    }
    
    function debitStaking(address _address,uint256 _amount) public {
        require(
            msg.sender == owner || msg.sender == exchange_address,
            "PRIVILAGED USER ONLY"
        );
        
        require(
            users[_address].stakingpayout >= _amount,
            "NOT ENOUGH BALANCE"
        );
        
        current_staked = current_staked.sub(_amount);
        users[_address].stakingpayout = users[_address].stakingpayout.sub(
            _amount
        );
    
        emit ExchangeDebit(_address,_amount);

    }
    
    function creditPayout(address _address,uint256 _amount) public {
        
        require(
            msg.sender == owner || msg.sender == exchange_address,
            "PRIVILAGED USER ONLY"
        );
        
        total_profit = total_profit.add(_amount);
        current_profit = current_profit.add(_amount);
        total_exchange_credit = total_exchange_credit.add(_amount);
        
        users[_address].profitpayout = users[_address].profitpayout.add(_amount);
        users[_address].total_profitpayout = users[_address].total_profitpayout.add(_amount);
        
        emit ExchangeCredit(_address,_amount);
        
    }

    function addTokenPrice(uint256 _value) public {
        //6 Decimal
        require(
            msg.sender == owner || msg.sender == node_address,
            "PRIVILAGED USER ONLY"
        );

        token_price = _value;
    }

    function updateTokenShares(uint8 _value) public {
        require(msg.sender == owner, "OWNER ONLY");

        require(_value >= 0, "MUST HIGHER THAN 0");

        token_share = _value;
    }

    function enablePhase2() public {
        require(msg.sender == owner, "OWNER ONLY");

        phaseversion = 2;

        tokendebit = 2;

        staking_status = 1;

        merchant_status = 1;
    }
}