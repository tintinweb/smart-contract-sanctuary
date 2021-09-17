/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// import "./Address.sol"; 
// import "./SafeMath.sol"; 
// import "./IBEP20.sol";

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
   * @dev Emitted when `value` tokens are burned from one account.
   *
   * Note that `value` may be zero.
   */
  event Burn(address indexed burner, uint256 value);

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

abstract contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
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
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract SafeColiseum is Context, IBEP20, Ownable {

    // Contract imports 
    using SafeMath for uint256;
    using Address for address;

    // Baisc contract variable declaration 
    string private _name = "SafeColiseum";
    string private _symbol = "SCOMT5";
    uint8 private _decimals = 8;
    uint256 private _initial_total_supply = 210000000 * 10**_decimals;
    uint256 private _total_supply = 210000000 * 10**_decimals;
    address private _owner;
    uint256 private _total_holder = 0;

    // Token distribution veriables 
    uint256 private _pioneer_invester_supply = (11 * _total_supply) / 100;
    uint256 private _ifo_supply = (19 * _total_supply) / 100;
    uint256 private _pool_airdrop_supply = (3 * _total_supply) / 100;
    uint256 private _director_supply_each = (6 * _total_supply) / 100;
    uint256 private _marketing_expansion_supply = (20 * _total_supply) / 100;
    uint256 private _development_expansion_supply = (6 * _total_supply) / 100;
    uint256 private _liquidity_supply = (5 * _total_supply) / 100;
    uint256 private _future_team_supply = (10 * _total_supply) / 100;
    uint256 private _governance_supply = (4 * _total_supply) / 100;
    uint256 private _investment_parter_supply = (10 * _total_supply) / 100;

    // Burning till total of 50% supply
    uint256 private _burning_till = _total_supply / 2;
    uint256 private _burning_till_now = 0; // initial burning token count is 0

    // Whale defination 
    uint256 private _whale_per = (_total_supply / 100); // 1% of total tokans consider tobe whale 

    // fee structure defination, this will be in % ranging from 0 - 100
    uint256 private _normal_tx_fee = 2;
    uint256 private _whale_tx_fee = 5;

    // below is percentage, consider _normal_tx_fee as 100%
    uint256 private _normal_marketing_share = 25; 
    uint256 private _normal_development_share = 7; 
    uint256 private _normal_holder_share = 43; 
    uint256 private _normal_burning_share = 25;

    // below is percentage, consider _whale_tx_fee as 100%
    uint256 private _whale_marketing_share = 30; 
    uint256 private _whale_development_share = 10; 
    uint256 private _whale_holder_share = 40; 
    uint256 private _whale_burning_share = 20; 

    // antidump variables 
    uint256 private _max_sell_amount_whale = 5000 * 10**_decimals; // max for whale
    uint256 private _max_sell_amount_normal = 2000 * 10**_decimals; // max for non-whale
    uint256 private _max_concurrent_sale_day = 2;
    uint256 private _cooling_days = 1;
    uint256 private _max_sell_per_director_per_day = 10000 * 10**_decimals;
    uint256 private _inverstor_swap_lock_days = 2; // after 180 days will behave as normal purchase user.

    // Wallet specific declaration 
    // UndefinedWallet : means 0 to check there is no wallet entry in Contract
    enum type_of_wallet { 
        UndefinedWallet, 
        GenesisWallet, 
        DirectorWallet, 
        MarketingWallet, 
        DevelopmentWallet, 
        LiquidityWallet, 
        GovernanceWallet, 
        GeneralWallet, 
        FutureTeamWallet,
        PoolOrAirdropWallet,
        IfoWallet,
        SellerWallet,
        FeeDistributionWallet,
        UnsoldTokenWallet,
        ContractWallet
    }

    struct wallet_details {
        type_of_wallet wallet_type;
        uint256 balance;
        uint256 purchase;
        uint256 concurrent_sale_day_count;
        uint256 last_sale_date; 
        uint256 joining_date;
        uint256 lastday_total_sell;
        bool fee_apply;
        bool antiwhale_apply;
        bool anti_dump;
        bool is_investor;
    }

    mapping ( address => wallet_details ) private _wallets;
    address[] private _holders;
    mapping (address => bool) public _sellers;

    // SCOM Specific Wallets
    address private _director_wallet_1 = 0xd26a3AF81Eb0fd83f064b8c9f12AfCD923FA8F19;
    address private _director_wallet_2 = 0xba44b38b7b89A251A60C506915794F5Ac9156735;
    address private _marketing_wallet = 0x870d2d1af5604c265bDAf031386c1710972df625;
    address private _governance_wallet = 0x97Abe576E2f52B0D262D353Ea904892516068fb5;
    address private _liquidity_wallet = 0x08502f482FCb9FDE3A41866Ef41D796602f99281;
    address private _pool_airdrop_wallet = 0xcA4b115F0326070d9d1833d2F8DE2882C835063D;
    address private _future_team_wallet = 0x0f241406490eC9d5e292A77e6D4d405D871b4617;
    address private _ifo_wallet = 0xd0F9D1eAcDceC7737B016Fb9693AB50e007F3f04;
    address private _development_wallet = 0xbd2A6b7D5c6b8B23db9d6F5Eaa4735514Bacbb0c;
    address private _holder_fee_airdrop_wallet = 0x337e00151A0e3F796436c3121B17b6Fd5AC7b275;
    address private _unsold_token_wallet = 0xC65fF1B1304Fc6d87215B982F214B5b58ebe790A;

    constructor () {
        // initial wallet adding process on contract launch
        _initialize_default_wallet_and_rules();
        _wallets[msg.sender].balance = _total_supply;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _total_supply);
        
        // Intial Transfers 
       _transfer(msg.sender, _director_wallet_1, _director_supply_each);
       _transfer(msg.sender, _director_wallet_2, _director_supply_each);
       _transfer(msg.sender, _marketing_wallet, _marketing_expansion_supply);
       _transfer(msg.sender, _governance_wallet, _governance_supply);
       _transfer(msg.sender, _liquidity_wallet, _liquidity_supply);
       _transfer(msg.sender, _pool_airdrop_wallet, _pool_airdrop_supply);
       _transfer(msg.sender, _ifo_wallet, _ifo_supply);
       _transfer(msg.sender, _development_wallet, _development_expansion_supply);
    }

    function _create_wallet(address addr, type_of_wallet w_type, bool fee, bool whale, bool dump, bool inverstor) private {
        if ( w_type == type_of_wallet.GenesisWallet ) {
            _wallets[addr] = wallet_details( 
                w_type, _total_supply, 0, 0, block.timestamp, block.timestamp, 0, fee, whale, dump, inverstor
            );
        } else {
            _wallets[addr] = wallet_details( 
                w_type, 0, 0, 0, block.timestamp, block.timestamp, 0, fee, whale, dump, inverstor
            );
        }
        if ( w_type !=  type_of_wallet.GenesisWallet && w_type !=  type_of_wallet.IfoWallet && w_type !=  type_of_wallet.LiquidityWallet && w_type !=  type_of_wallet.MarketingWallet && w_type !=  type_of_wallet.PoolOrAirdropWallet && w_type !=  type_of_wallet.DevelopmentWallet ) {
            _total_holder+=1;
            _holders.push(addr);
        }
    }

    function _initialize_default_wallet_and_rules() private {
        _create_wallet(msg.sender, type_of_wallet.GenesisWallet, false, false, false, false);                          // Adding Ginesis wallets
        _create_wallet(_director_wallet_1, type_of_wallet.DirectorWallet, true, true, true, false);                    // Adding Directors 1 wallets
        _create_wallet(_director_wallet_2, type_of_wallet.DirectorWallet, true, true, true, false);                    // Adding Directors 2 wallets
        _create_wallet(_marketing_wallet, type_of_wallet.MarketingWallet, true, true, false, false);                 // Adding Marketing Wallets
        _create_wallet(_liquidity_wallet, type_of_wallet.LiquidityWallet, false, false, false, false);                 // Adding Liquidity Wallets
        _create_wallet(_governance_wallet, type_of_wallet.GovernanceWallet, true, true, false, false);                // Adding Governance Wallets
        _create_wallet(_pool_airdrop_wallet, type_of_wallet.PoolOrAirdropWallet, false, false, false, false);          // Adding PoolOrAirdropWallet Wallet
        _create_wallet(_future_team_wallet, type_of_wallet.FutureTeamWallet, false, false, false, false);              // Adding FutureTeamWallet Wallet
        _create_wallet(_ifo_wallet, type_of_wallet.IfoWallet, false, false, false, false);                             // Adding IFO Wallet
        _create_wallet(_development_wallet, type_of_wallet.DevelopmentWallet, true, true, false, false);             // Adding Development Wallet
        _create_wallet(_holder_fee_airdrop_wallet, type_of_wallet.FeeDistributionWallet, false, false, false, false);  // Adding Holder Fee Airdrop Wallet
        _create_wallet(_unsold_token_wallet, type_of_wallet.UnsoldTokenWallet, false, false, false, false);            // Adding Unsold Token Wallet

        // Marking default seller wallets so future transfer from this will be considered as purchase
        _sellers[msg.sender]=true;              // genesis will be seller wallet 
        _sellers[_unsold_token_wallet]=true;    // unsold token wallet is seller wallet 
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _total_supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _wallets[account].balance;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function burningTillNow() public view returns (uint256) {
        return _burning_till_now;
    }

    function addSellerWallet(address account) public onlyOwner returns (bool) {
        if ( _wallets[account].wallet_type ==  type_of_wallet.UndefinedWallet) {
            _create_wallet(account, type_of_wallet.GeneralWallet, false, false, false, false);
        } else {
            _wallets[account].fee_apply = false;
            _wallets[account].antiwhale_apply = false;
            _wallets[account].anti_dump = false;
        }
        _sellers[account]=true;
        return true;
    }

    function checkAccountIsSeller(address account) public view returns (bool) {
        return  _sellers[account];
    }

    function checkAccountPurchaseAmount(address account) public view returns (uint256) {
        return  _wallets[account].purchase;
    }

    function checkAccountLastSaleDate(address account) public view returns (uint256) {
        return  _wallets[account].last_sale_date;
    }

    function checkAccountConcurrentSaleDayCount(address account) public view returns (uint256) {
        return  _wallets[account].concurrent_sale_day_count;
    }

    function checkAccountLastDayTotalSell(address account) public view returns (uint256) {
        return  _wallets[account].lastday_total_sell;
    }

    function getAccountDetails(address account) public view returns (wallet_details memory) {
        return  _wallets[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function getAccountType(address account) public view returns (type_of_wallet) {
        return _wallets[account].wallet_type;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, recipient, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "SCOM: approve from the zero address");
        require(spender != address(0), "SCOM: approve to the zero address");
        require(_wallets[owner].wallet_type != type_of_wallet.GeneralWallet, "SCOM: Only registered wallet allowed for approval.");
        require(_wallets[owner].wallet_type != type_of_wallet.UndefinedWallet, "SCOM: Only registered wallet allowed for approval.");
        emit Approval(owner, spender, amount);
    }

    // Function to add investment partner
    function addInvestmentPartner(address partner_address) public onlyOwner returns (bool) {
        if ( _wallets[partner_address].wallet_type ==  type_of_wallet.UndefinedWallet) {
            _create_wallet(partner_address, type_of_wallet.GeneralWallet, true, true, true, true);
        } else {
            _wallets[partner_address].is_investor = true;
            _wallets[partner_address].joining_date = block.timestamp; // Changing joining date as current date today for old accounts.
        }
        return true;
    }

    function _checkrules(address sender, address recipient, uint256 amount) internal view {
        wallet_details storage sender_wallet = _wallets[sender];
        wallet_details storage recipient_wallet = _wallets[recipient];

        if (sender_wallet.wallet_type == type_of_wallet.GenesisWallet) {
            return ;
        }

        // Checking if sennder or reciver is contract or not and also registered seller or not 
        if ( recipient.isContract() && sender_wallet.wallet_type == type_of_wallet.GeneralWallet ) {
            if ( !_sellers[recipient] ) {
                revert("SCOM : You are trying to reach unregistered contract ( considered as seller ).");
            }
        }
        

        // Checking that only regular user can send token back to genesis wallet 
        // require( (recipient_wallet.wallet_type != type_of_wallet.GenesisWallet && sender_wallet.wallet_type == type_of_wallet.GeneralWallet), "SCOM : You can not send your tokens back to genesis wallet" );
        if ( recipient_wallet.wallet_type == type_of_wallet.GenesisWallet ) {
            require(sender_wallet.wallet_type != type_of_wallet.GeneralWallet, "SCOM : You can not send your tokens back to genesis wallet");
        }

        if ( sender_wallet.is_investor ) {
            require( block.timestamp > (sender_wallet.joining_date + ( _inverstor_swap_lock_days * 1 hours )), "SCOM : Investor account can perform any transfer after 180 days only");
        }

        if (_sellers[recipient]) {
            require(sender_wallet.wallet_type != type_of_wallet.FutureTeamWallet, "SCOM : You are not allowed to sell token from your wallet type");
            require(sender_wallet.wallet_type != type_of_wallet.SellerWallet, "SCOM : You are not allowed to sell token from your wallet type");
            require(sender_wallet.wallet_type != type_of_wallet.FeeDistributionWallet, "SCOM : You are not allowed to sell token from your wallet type");
            require(sender_wallet.wallet_type != type_of_wallet.UnsoldTokenWallet, "SCOM : You are not allowed to sell token from your wallet type");
            if (_sellers[sender]) {
                revert("SCOM : Inter seller exchange is not allowed.");
            }
        }

        if ( _sellers[recipient] && sender_wallet.anti_dump ) {
            // This is for anti dump for all wallet

            // Director account restriction check.
            if (sender_wallet.wallet_type == type_of_wallet.DirectorWallet) {
                if ( block.timestamp < (sender_wallet.last_sale_date + 1 hours) ) {
                    if ( sender_wallet.lastday_total_sell + amount > _max_sell_per_director_per_day ) {
                        revert("SCOM : Director can only send 10000 SCOM every 24 hours");
                    }
                }
            }

            // General account restriction check.
            if (sender_wallet.wallet_type == type_of_wallet.GeneralWallet) {
                if ( sender_wallet.concurrent_sale_day_count > _max_concurrent_sale_day ) {
                    if ( block.timestamp < (sender_wallet.last_sale_date + ( (_max_concurrent_sale_day + _cooling_days) * 1 hours )) ) {
                        revert("SCOM : Concurrent sell for more than 6 days not allowed. You can not sell for next 72 Hours");
                    }
                }
                if ( block.timestamp < (sender_wallet.last_sale_date + 1 hours) ) {
                    if (sender_wallet.balance >= _whale_per && sender_wallet.antiwhale_apply == true ) {
                        if ( sender_wallet.lastday_total_sell + amount > _max_sell_amount_whale ) {
                            revert("SCOM : You can not sell more than 5000 SCOM in past 24 hours.");
                        }
                    } else {
                        if ( sender_wallet.lastday_total_sell + amount > _max_sell_amount_normal ) {
                            revert("SCOM : You can not sell more than 2000 SCOM in past 24 hours.");
                        }
                    }  
                } 
            }
        } 
    }

    function _after_transfer_updates(address sender, address recipient, uint256 amount) internal {
        wallet_details storage sender_wallet = _wallets[sender];
        wallet_details storage recipient_wallet = _wallets[recipient];

        // For purchase Whale rule
        if ( _sellers[sender] ) {
            if (recipient_wallet.wallet_type == type_of_wallet.GeneralWallet) {
                recipient_wallet.purchase = recipient_wallet.purchase + amount;
            }
        }
        // For Antidump rule
        if ( _sellers[recipient] ) {
            // General wallet supporting entries
            if (sender_wallet.wallet_type == type_of_wallet.GeneralWallet) {
                if ( block.timestamp > (sender_wallet.last_sale_date + 1 hours) ) {
                    sender_wallet.lastday_total_sell = 0; // reseting sale at 24 hours 
                    if ( block.timestamp > (sender_wallet.last_sale_date + ( _cooling_days * 1 hours ) ) ) {
                        sender_wallet.concurrent_sale_day_count = 1;
                    } else {
                        sender_wallet.concurrent_sale_day_count = sender_wallet.concurrent_sale_day_count.add(1);
                    }
                    sender_wallet.last_sale_date = block.timestamp;
                    sender_wallet.lastday_total_sell = sender_wallet.lastday_total_sell.add(amount);
                } else {
                    sender_wallet.lastday_total_sell = sender_wallet.lastday_total_sell.add(amount);
                    if ( sender_wallet.concurrent_sale_day_count == 0 ) {
                        sender_wallet.concurrent_sale_day_count = 1;
                        sender_wallet.last_sale_date = block.timestamp;
                    }
                }
            }
            // Director wallet supporting entries
            if (sender_wallet.wallet_type == type_of_wallet.DirectorWallet) {
                if ( block.timestamp > (sender_wallet.last_sale_date + 1 hours) ) {
                    sender_wallet.lastday_total_sell = 0; // reseting director sale at 24 hours 
                    sender_wallet.last_sale_date = block.timestamp;
                    sender_wallet.lastday_total_sell = sender_wallet.lastday_total_sell.add(amount);
                } else {
                    sender_wallet.lastday_total_sell = sender_wallet.lastday_total_sell.add(amount);
                    if ( sender_wallet.concurrent_sale_day_count == 0 ) {
                        sender_wallet.concurrent_sale_day_count = 1;
                        sender_wallet.last_sale_date = block.timestamp;
                    }
                }
            }
        }
    }

    function _fees(address sender, address recipient, uint256 amount) internal virtual returns (uint256, bool){
        if ( sender == _owner || sender == address(this) ) {
            return (0, true);
        }
        wallet_details storage sender_wallet = _wallets[sender];
        wallet_details storage recipient_Wallet = _wallets[recipient];

        if ( sender_wallet.fee_apply == false ) {
            return (0, true);
        }

        uint256 total_fees = 0;
        uint256 marketing_fees = 0;
        uint256 development_fees = 0;
        uint256 holder_fees = 0;
        uint256 burn_amount = 0;

        // Calculate fees based on whale or not whale
        if (sender_wallet.balance >= _whale_per && sender_wallet.antiwhale_apply == true ) {
            total_fees = ((amount * _whale_tx_fee) / 100);
            marketing_fees = ((total_fees * _whale_marketing_share) / 100);
            development_fees = ((total_fees * _whale_development_share) / 100);
            holder_fees = ((total_fees * _whale_holder_share) / 100);
            burn_amount = ((total_fees * _whale_burning_share) / 100);
        } else {
            total_fees = ((amount * _normal_tx_fee) / 100);
            marketing_fees = ((total_fees * _normal_marketing_share) / 100);
            development_fees = ((total_fees * _normal_development_share) / 100);
            holder_fees = ((total_fees * _normal_holder_share) / 100);
            burn_amount = ((total_fees * _normal_burning_share) / 100);
        }

        // add cut to defined acounts 
        if ( _total_supply < (_initial_total_supply / 2) ) {
            total_fees = total_fees.sub(burn_amount);
            burn_amount=0;
        }

       bool sender_fee_deduct = false;

        // if contract type wallet then following condtion is default false
        if ( (sender_wallet.balance >= amount + total_fees) && (recipient_Wallet.wallet_type != type_of_wallet.ContractWallet)) {
            if (marketing_fees > 0 ) {
                _wallets[_marketing_wallet].balance = _wallets[_marketing_wallet].balance.add(marketing_fees);
                emit Transfer(sender, _marketing_wallet, marketing_fees);
            }
            
            if ( development_fees > 0 ) {
                _wallets[_development_wallet].balance = _wallets[_development_wallet].balance.add(development_fees);
                emit Transfer(sender, _development_wallet, development_fees);
            }

            if ( holder_fees > 0 ) {
                _wallets[_holder_fee_airdrop_wallet].balance = _wallets[_holder_fee_airdrop_wallet].balance.add(holder_fees);
                emit Transfer(sender, _holder_fee_airdrop_wallet, holder_fees);
            }

            if ( burn_amount > 0) {
                _total_supply = _total_supply.sub(burn_amount);
                _burning_till_now = _burning_till_now.add(burn_amount);
                emit Burn(sender, burn_amount);
                emit Transfer(sender, address(0), burn_amount); 
            }
            sender_fee_deduct = true;
        } else {
            if (marketing_fees > 0 ) {
                _wallets[_marketing_wallet].balance = _wallets[_marketing_wallet].balance.add(marketing_fees);
                emit Transfer(recipient, _marketing_wallet, marketing_fees);
            }
            
            if ( development_fees > 0 ) {
                _wallets[_development_wallet].balance = _wallets[_development_wallet].balance.add(development_fees);
                emit Transfer(recipient, _development_wallet, development_fees);
            }

            if ( holder_fees > 0 ) {
                _wallets[_holder_fee_airdrop_wallet].balance = _wallets[_holder_fee_airdrop_wallet].balance.add(holder_fees);
                emit Transfer(recipient, _holder_fee_airdrop_wallet, holder_fees);
            }

            if ( burn_amount > 0) {
                _total_supply = _total_supply.sub(burn_amount);
                _burning_till_now = _burning_till_now.add(burn_amount);
                emit Burn(recipient, burn_amount);
                emit Transfer(recipient, address(0), burn_amount); 
            }
        }

        return (total_fees, sender_fee_deduct);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "SCOM: transfer from the zero address");
        require(recipient != address(0), "SCOM: transfer to the zero address");
        require(_wallets[sender].balance >= amount, "SCOM: transfer amount exceeds balance");

        if ( _wallets[sender].wallet_type ==  type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            if ( sender.isContract() ) {
                _create_wallet(sender, type_of_wallet.ContractWallet, true, false, false, false);
            } else {
                 _create_wallet(sender, type_of_wallet.GeneralWallet, true, true, true, false);
            }
        }
        if ( _wallets[recipient].wallet_type ==  type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            if ( recipient.isContract() ) {
                _create_wallet(recipient, type_of_wallet.ContractWallet, true, false, false, false);
            } else {
                 _create_wallet(recipient, type_of_wallet.GeneralWallet, true, true, true, false);
            }
        }

        // checking SCOM rules before transfer 
        _checkrules(sender, recipient, amount);

        uint256 total_fees;
        bool sender_fee_deduct;
        (total_fees, sender_fee_deduct) = _fees(sender, recipient, amount);

        if ( sender_fee_deduct == true ) {
            uint256 r_amount = amount.add(total_fees);
            _wallets[sender].balance = _wallets[sender].balance.sub(r_amount);
            _wallets[recipient].balance = _wallets[recipient].balance.add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 r_amount = amount.sub(total_fees);
            _wallets[sender].balance = _wallets[sender].balance.sub(amount);
            _wallets[recipient].balance = _wallets[recipient].balance.add(r_amount);
            emit Transfer(sender, recipient, r_amount);
        }
        
        _after_transfer_updates(sender, recipient, amount);
    }
}