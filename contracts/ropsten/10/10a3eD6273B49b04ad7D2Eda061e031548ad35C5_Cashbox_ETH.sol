// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./token/ERC20/IERC20.sol";
import "./math/SafeMath.sol";
import "./utils/BasicContract.sol";
//import "./utils/Initializable.sol";
import "./utils/SafeERC20.sol";
import { HighLevelSystemExecution_ETH } from "./libs/HighLevelSystemExecution_ETH.sol";
import { SafeERC20 } from "./utils/SafeERC20.sol";

/**
This is master branch of Eth

1.token存進來後，需要累積？還是直接deposit+stake？
2.-done- rebalance, restake
3.當DAI不夠提領時，要做把賺到的CRV swap成DAI？
4.review andrew's code change
5.add different tokens


 */

contract Cashbox_ETH is BasicContract {

    HighLevelSystemExecution_ETH.HLSConfig private HLSConfig ;
    HighLevelSystemExecution_ETH.StableCoins private StableCoins ;
    HighLevelSystemExecution_ETH.Position private position;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    string public constant name = "Proof token of Ypool DAI";
    string public constant symbol = "pDAI_yPool";
    uint8 public constant decimals = 18;
    uint256 private totalSupply_ ; // 使用者存錢到cashbox後，return給使用者的proof Token的總供給量

    bool public activable;
    address private dofin;
    uint private deposit_limit;   
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    mapping(address => uint256) private balances;
    mapping(address => mapping (address => uint256)) private allowed;

    constructor(
        uint  _supplyFund_percentage, 
        address[] memory _addrs, 
        address _dofin, 
        uint _deposit_limit
    ){
        position = HighLevelSystemExecution_ETH.Position({
            a_amount: 0, // DAI amount
            LP_token_amount:0, // yCRv amount
            token_a: _addrs[0], // DAI token address
            LP_token: _addrs[1],// yCrv token address
            supplyFund_percentage: _supplyFund_percentage// ex:如果有75%要進入策略，那這個變數就會是75
        });
        
        activable = true;
        dofin = _dofin;
        deposit_limit = _deposit_limit;

    }

    modifier checkActivable(){
        require(activable == true, 'CashBox is not Activable');
        _;
    }

    function setConfig(address[] memory _config) public  {
        /* TODO 如果沒有deposit contract的pool怎麼辦？ */
        HLSConfig.CurveConfig.curveFi_Swap = _config[0];//Base Pool StableSwap Contract
        HLSConfig.CurveConfig.curveFi_Gauge = _config[1];//Liquidity Gauge Contract
        HLSConfig.CurveConfig.curveFi_Deposit = _config[2];//Base Pool Deposit Contract, not necessary, don't always exist for every pool
        HLSConfig.CurveConfig.curveFi_LPToken = _config[3];
        HLSConfig.CurveConfig.curveFi_CRVToken = _config[4];
        HLSConfig.CurveConfig.curveFi_CRVMinter = _config[5];
        HLSConfig.LinkConfig.CRV_USD = _config[6];
        HLSConfig.LinkConfig.DAI_USD = _config[7];

    }

    // function setStableCoins(address[] memory _stablecoins) public onlyOwner {
    //     //StableCoins.WBNB = _stablecoins[0];
    //     //StableCoins.CAKE = _stablecoins[1];
    //     StableCoins.DAI = _stablecoins[0];
    //     StableCoins.USDC = _stablecoins[1];
    //     StableCoins.USDT = _stablecoins[2];
    //     StableCoins.TUSD = _stablecoins[3];
    // }

    function setActivable(bool _activable) public  {
        activable = _activable;
    }

    function getPosition() public  view returns(HighLevelSystemExecution_ETH.Position memory) {
        return position;
    }

    // User deposits DAI to this cashbox, we return proofToken to the user.
    function userDepositToCashbox(address _token, uint _deposit_amount) public checkActivable returns(bool) {

        require(_deposit_amount <= SafeMath.mul(deposit_limit, 10**IERC20(position.token_a).decimals()), "Deposit too much!");
        require(_token == position.token_a, "Wrong token to deposit.Require DAI in this cashbox");
        require(_deposit_amount > 0, "Deposit amount must be larger than 0.");

        // Calculation of pToken amount need to mint
        uint shares = getDepositAmountOut(_deposit_amount); // 根據user存入的DAI數量跟總DAI資產數量的比例，來決定user這次存入的DAI可以得到多少proofToken
        
        // Mint proofToken 
        mint(msg.sender, shares);
        // Transfer DAI from user to cashbox
        IERC20(position.token_a).transferFrom(msg.sender, address(this),  _deposit_amount);
        
        //如果存完錢，cashbox的錢比最低要求數量還高，就把錢存進curve
        //checkAddNewFunds();

        return true ;
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

    // pending crv   ( in gauge )         , == pendingCrvAmount * Crv price  => getCrvPrice?
    // claimed crv   ( in this contract ) , == 0 , 何時要swap crv for dai?    => 不留crv，都換成dai再redeposit
    // staked lp     ( in gauge )         , == getStakedAmount * yCrv price  => getyCrvPrice?
    // not staked lp ( in cashbox? )      , == 0 , always stake all lp
    // free funds    ( in cashbox )       , TODO what is free funds lower bound?
    function getTotalAssets() public view returns (uint) {

        uint pendingCRVAmount = HighLevelSystemExecution_ETH.getPendingCRV(HLSConfig);//單位？wei,decimal？ // test pendingCRVAmount = 10
        int CRVPrice = HighLevelSystemExecution_ETH.getCRVPrice(HLSConfig.LinkConfig); // CRV/USD // test CRVPrice = 10
        
        uint CRVValueInUSD = SafeMath.mul( pendingCRVAmount , uint(CRVPrice) ) ; // test CRVValueInUSD = 100
        // Toekn == DAI
        int stableCoinPrice = HighLevelSystemExecution_ETH.getStableCoinPrice(HLSConfig.LinkConfig); // test stableCoinPrice = 10
        uint256 CRV_EquivalentAmount_InStableCoin = SafeMath.div( CRVValueInUSD , uint(stableCoinPrice) );//pendingCRV相當於多少DAI // test CRV_EquivalentAmount_InStableCoin = 10


        uint totalLPBalance = HighLevelSystemExecution_ETH.curveLPTokenBalance(HLSConfig); // test totalLPBalance = 20 ;
        uint LP_EquivalentAmount_InStableCoin = HighLevelSystemExecution_ETH.curveLPTokenEquivalence(HLSConfig, totalLPBalance, 0); // test LP_EquivalentAmount_InStableCoin = 10 
        // 第三個參數設為0：表示要找yCrv對DAI(ypool第0個token)的equivalence
        

        uint cashboxFreeFunds =  IERC20(position.token_a).balanceOf(address(this)) ; // test cashboxFreeFunds = 10

        uint total_assets = SafeMath.add( SafeMath.add( CRV_EquivalentAmount_InStableCoin , LP_EquivalentAmount_InStableCoin) , cashboxFreeFunds ) ;//以DAI為計算基準

        return total_assets; // test total_assets = 30 ;
    }

    // TODO 什麼時候rebalance,什麼時候checkEntry
    // TODO position.a_amount 表示的是 ? => 讓position.a_amount表示的是已經有多少錢deposit
    function checkAddNewFunds() public view  checkActivable returns(uint) {
        uint free_funds = IERC20(position.token_a).balanceOf(address(this));
        // 這個contract現在裡面有的DAI
        uint strategy_balance = getTotalAssets();
        // 現在已經在策略裡面跑的DAI
        uint previous_free_funds = SafeMath.div(SafeMath.mul(strategy_balance, 100), position.supplyFund_percentage);
        // 上一次rebalance,supply之前，contract裡面的DAI
        uint condition = SafeMath.div(SafeMath.mul(previous_free_funds, SafeMath.sub(100, position.supplyFund_percentage)), 100);
        // 上一次rebalance,supply時，預設rebalance,supply後要留在contract裡面的DAI

        if (free_funds > condition ) {
            if( position.a_amount == 0 ){ 
                // 本來沒有已經deposit的錢，user存完一次錢進cashbox後，free_funds大於condition
                // Need to enter
                return 1 ; // 開始把錢存進curve
            }
            else{
                // 本來已經有deposit錢，要做的是deposit多出的這些錢(free_funds-condition) 進curve
                // Need to rebalance 
                return 2 ;
            }
        }
        return 0 ;
    }

    function enter(uint _type) public  checkActivable {
        position = HighLevelSystemExecution_ETH.enterPosition(HLSConfig, position, _type);
    }

    function exit(uint _type) public  checkActivable {
        position = HighLevelSystemExecution_ETH.exitPosition(HLSConfig, position, _type);
    }

    // TODO rebalance ( = unstake + withdraw + deposit + stake)
    // TODO 在checkAddNewFunds()中要的功能：本來已經有deposit錢，要做的是deposit多出的這些錢(free_funds-condition) 進curve
    function rebalance() public  checkActivable {
        position = HighLevelSystemExecution_ETH.exitPosition(HLSConfig, position, 1);
        position = HighLevelSystemExecution_ETH.enterPosition(HLSConfig, position, 1);
    }
    
    // TODO restake ( = unstake + stake )
    function restake() public  checkActivable {
        position = HighLevelSystemExecution_ETH.exitPosition( HLSConfig, position, 2);
        position = HighLevelSystemExecution_ETH.enterPosition( HLSConfig, position, 2);
    }
    
    // TODO - done - 把withdraw改成user從cahsbox提出錢
    // TODO enterposition, exitposition 的position設定
    function userWithdrawFromCashbox(uint proofToken_withdraw_amount) public checkActivable returns (bool) {

        require(proofToken_withdraw_amount <= balanceOf(msg.sender), "Wrong amount to withdraw."); 
        // 使用者輸入想用多少proofToken來提領存入的DAI，這個proofToken的數量須小於使用者所擁有的proofToken數量
        
        uint free_funds = IERC20(position.token_a).balanceOf(address(this));
        uint totalAssets = getTotalAssets();
        uint withdraw_funds = SafeMath.div(SafeMath.mul(proofToken_withdraw_amount, totalAssets), totalSupply_);///換算後要提出的DAI的量
        bool need_rebalance = false;
        // If no enough amount of free_funds can transfer will trigger exit position
        if ( withdraw_funds > free_funds ) {
            HighLevelSystemExecution_ETH.exitPosition(HLSConfig, position, 1);
            need_rebalance = true;
        }

        // TODO 如果withdraw完，DAI不夠使用者提領，就要做swap CRV to DAI
        // implement swap?

        
        // Will charge 20% fees
        burn(msg.sender, proofToken_withdraw_amount);
        uint  dofin_value = SafeMath.div(SafeMath.mul(20, withdraw_funds), 100);
        uint  user_value = SafeMath.div(SafeMath.mul(80, withdraw_funds), 100);
        IERC20(position.token_a).transferFrom(address(this), dofin, dofin_value);
        IERC20(position.token_a).transferFrom(address(this), msg.sender, user_value);
        
        if (need_rebalance == true) {
            HighLevelSystemExecution_ETH.enterPosition(HLSConfig, position, 1);
        }
        
        return true;

    }
    
    function getWithdrawAmount(uint _ptoken_amount) public view returns (uint) {
        uint totalAssets = getTotalAssets(); // test 30 ;
        uint value = SafeMath.div(SafeMath.mul(_ptoken_amount, totalAssets), totalSupply_); // 30
        uint user_value = SafeMath.div(SafeMath.mul(80, value), 100); // 24
        
        return user_value;
    }


//-----以下for pToken(proof toekn) -----


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

//-----以上for pToken(proof toekn) -----


//-----以下for getting information from cashbox, necessary? ----
    
    // // @notice Get amount of CurveFi LP tokens staked in the Gauge
    // function checkStakedToken() public view returns(uint256) { 
    //     HighLevelSystemExecution_ETH.curveLPTokenStaked(HLSConfig);
    // }

    // // @notice Get amount of unstaked CurveFi LP tokens (which lay on this contract)
    // function checkUnstakedLpToken() public view returns(uint256) { 
    //     HighLevelSystemExecution_ETH.curveLPTokenUnstaked(HLSConfig);
    // }

    // //@notice Get full amount of Curve LP tokens available for this contract
    // function checkTotalLpTokenBalance() public view returns(uint256) { 
    //     HighLevelSystemExecution_ETH.curveLPTokenBalance(HLSConfig); 
    // }
    
    // // TODO 注意struct的傳遞流程是否有中斷？
    // function claimCrvToken() internal {
    //     HighLevelSystemExecution_ETH.claimCRVReward(HLSConfig);
    // }


    // //@notice Balances of stablecoins available for withdraw normalized to 18 decimals
    // function getNormalizedBalance() public view returns(uint256){
    //     HighLevelSystemExecution_ETH.normalizedBalance(HLSConfig); // will call HighLevelSystemExecution_ETH.normalzie() inside HighLevelSystemExecution_ETH.normalizedBalance();
    // }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "./Address.sol";

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
pragma solidity ^0.8;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "../token/ERC20/IERC20.sol";
import "../access/Ownable.sol";

contract BasicContract is Ownable {
    
    event IntLog(string message, uint val);
    event StrLog(string message, string val);
    event AddrLog(string message, address val);
    
    function checkBalance(address _token, address _address) external view returns (uint) {
        return IERC20(_token).balanceOf(_address);
    }
    
    function approveForContract(address _token, address _spender, uint _amount) private onlyOwner {
        IERC20(_token).approve(_spender, _amount);
    }
    
    function checkAllowance(address _token, address _owner, address _spender) external view returns (uint) {
        return IERC20(_token).allowance(_owner, _spender);
    }
    
    function transferBack(address _token, uint _amount) external onlyOwner {
        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(address(this), msg.sender, _amount);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
import "../token/ERC20/IERC20.sol";
import "../math/SafeMath.sol";
import "./CurveExecution_ETH.sol";
import "../interfaces/chainlink/AggregatorV3Interface.sol";
//import { LinkEthOracle } from "./LinkEthOracle.sol";
import { CurveExecution_ETH} from "./CurveExecution_ETH.sol";
import { CreamExecution } from "./CreamExecution.sol";

// TODO IERC的檔案要用哪一個？safeTransfer, safeApprove..等的
library HighLevelSystemExecution_ETH {
    
    struct LinkConfig{
        address CRV_USD ;
        address DAI_USD ;
        address USDC_USD ;
        address USDT_USD ;
        address TUSD_USD ;
    }

    struct HLSConfig{
        LinkConfig LinkConfig ;
        CurveExecution_ETH.CurveConfig CurveConfig ;
        CreamExecution.CreamConfig CreamConfig;
    }

    struct CreamToken {
        address crWBNB;
        address crBNB;
        address crUSDC;
    }
    
    struct StableCoins {
        address DAI ;
        address USDC;
        address USDT;
        address TUSD;
    }
    
    struct Position {
        uint a_amount;
        uint LP_token_amount ;
        address token_a ;
        address LP_token ;
        uint supplyFund_percentage;
    }

    //輸入參數要加memory?
    // function setupCurveAddress(HLSConfig memory self) public view {
    //     CurveExecution_ETH.setupOtherCurveAddress(self.CurveConfig);
    // }

    // TODO 本來沒有已經deposit的錢，存完錢，cashbox的錢比最低要求數量還高，要把錢存進curve，
    // TODO 之後有什麼東西要檢查的？把要檢查的東西的回傳值放進signal
    // TODO cashbox.checkEntry跟cashbox.rebalance之都會call enterPosition，但一個有透過checkEntry，差異是？
    // TODO 現在先不做checkBorrowLiquidity(_position);之類的檢查，直接進入存錢part
    // function checkEntry(HLSConfig memory self, Position memory _position) public returns (Position memory) {
    //     bool signal = true ;
    //     if( signal == true ){
    //         Position memory updated_position = enterPosition(self, _position, 1);
    //         return updated_position ;
    //     }
    //     return _position ;
    // }

    // TODO if (_type==3) { lock ? }
    // TODO LP Token / CRV Token 等，有需要存進position回傳嗎？ => 要，getTotalAssets會用到position裡面的已經deposit的amount
    function enterPosition(HLSConfig memory self, Position memory _position, uint _type) public returns(Position memory) {
        
        if( _type == 1 ){
            // deposit into curve pool
            uint  free_funds = IERC20(_position.token_a).balanceOf(address(this)); // test free_funds = 10
            uint  enter_amount_a = SafeMath.div ( SafeMath.mul (free_funds, _position.supplyFund_percentage) , 100 ); // test enter_amount_a = 1

            depositIntoCurve(self, enter_amount_a, _position.token_a); // test _enter_amount_a = 1, _position.token_a = FakeIERC20.address
            _position.a_amount = enter_amount_a ; // 目前假設為存DAI, _position.a_amount就是存進去的DAI amount // test _position.a_amount = 1 ;
            _position.LP_token_amount = IERC20(_position.LP_token).balanceOf(address(this)); // // test _position.LP_token_amount = 10

        }
        if ( _type == 1 || _type == 2 ) {
            // stake into curve Gauge
            stakeCurveLpTokenIntoGauge(self);
        }

        return _position;

    }

    // TODO - done - deposit要改成輸入uint256[4] _amount
    // TODO 處理enter_token_a相關的struct,approve
    // test _enter_amount_a = 1, _enter_token_a = FakeIERC20.address
    function depositIntoCurve(HLSConfig memory self, uint _enter_amount_a, address _enter_token_a) public {
        IERC20(_enter_token_a).approve(self.CurveConfig.curveFi_Deposit, _enter_amount_a);
        uint256[4] memory depositAmount ;
        depositAmount[0] = _enter_amount_a ;
        depositAmount[1] = 0 ;
        depositAmount[2] = 0 ;
        depositAmount[3] = 0 ;
        CurveExecution_ETH.deposit(self.CurveConfig, depositAmount);
    }

    function stakeCurveLpTokenIntoGauge(HLSConfig memory self) public {
        uint256  curveLP_to_stake = curveLPTokenUnstaked(self);
        IERC20(self.CurveConfig.curveFi_LPToken).approve(self.CurveConfig.curveFi_Gauge, curveLP_to_stake);
        CurveExecution_ETH.stakeAll( self.CurveConfig , curveLP_to_stake );
    }

    // 還沒處理position struct相關的更新，把exit function 放到exit，exitposition處理position更新
    function exitPosition(HLSConfig memory self, Position memory _position, uint _type) public returns (Position memory) {
        
        if (_type == 1 || _type == 2) {
            // unstake all
            uint256 Shares_to_unstake = curveLPTokenStaked(self) ;
            CurveExecution_ETH.unstakeAllLPFromGauge(self.CurveConfig, Shares_to_unstake);
        }
        
        if (_type == 1) {
            // withdraw all
            uint256 LPAmount_to_withdraw = curveLPTokenBalance(self) ;
            uint256 equivalentValue = CurveExecution_ETH.calc_withdraw_one_coin(self.CurveConfig, LPAmount_to_withdraw, 0);// 這些LPAmount_to_withdraw相對應的DAI的量
            uint256[4] memory withdraw_amounts ;                         
            withdraw_amounts[0] = equivalentValue ; // 把LPAmount_to_withdraw全部用DAI來領出
            withdraw_amounts[1] = 0 ;
            withdraw_amounts[2] = 0 ;
            withdraw_amounts[3] = 0 ;
            CurveExecution_ETH.withdrawFromDeposit(self.CurveConfig, withdraw_amounts, LPAmount_to_withdraw);
        }

        return _position;
    }

    // TODO 在哪裡call這個function?
    function claimCRVReward(HLSConfig memory self) public {
        CurveExecution_ETH.mint(self.CurveConfig);
    }

    // TODO 在哪裡call這個function?
    function getCRVbalance(HLSConfig memory self) public view returns(uint256) {
        return IERC20(self.CurveConfig.curveFi_CRVToken).balanceOf(address(this));
    }

    function getPendingCRV(HLSConfig memory self) public view returns(uint256) {
        uint256 pendingCRV = CurveExecution_ETH.getPendingCRV(self.CurveConfig);
        return pendingCRV ;
    }

    function getCRVPrice(LinkConfig memory self) public view returns(int) {
        if ( self.CRV_USD != address(0) ){ 
            (
                uint80 roundID, 
                int price,
                uint startedAt,
                uint timeStamp,
                uint80 answeredInRound
            ) = AggregatorV3Interface(self.CRV_USD).latestRoundData();
            return price;
        }
        return 0 ;
    }

    // now only deal with DAI price
    function getStableCoinPrice(LinkConfig memory self) public view returns(int) {

        if (self.DAI_USD != address(0)){
            (
                uint80 roundID, 
                int price,
                uint startedAt,
                uint timeStamp,
                uint80 answeredInRound
            ) = AggregatorV3Interface(self.DAI_USD).latestRoundData();
            return price;
        }
        return 0 ;
    }

    /**
     * @notice Get amount of unstaked CurveFi LP tokens (which lay on this contract)
     */
    function curveLPTokenUnstaked(HLSConfig memory self) public view returns(uint256) {
        return IERC20(self.CurveConfig.curveFi_LPToken).balanceOf(address(this));
    }

    /**
     * @notice Get amount of CurveFi LP tokens staked in the Gauge
     */
    function curveLPTokenStaked(HLSConfig memory self) public view returns(uint256) {
        return CurveExecution_ETH.getCurveStakedLPToken(self.CurveConfig);
    }

    /**
     *  * @notice Get full amount of Curve LP tokens available for this contract
     */
    function curveLPTokenBalance(HLSConfig memory self) public view returns(uint256) {
        uint256 staked = curveLPTokenStaked(self);
        uint256 unstaked = curveLPTokenUnstaked(self);
        return SafeMath.add(staked , unstaked);
    }

    // caculate the equivalent value of _token_amount of LP token (in DAI/USDC/...)
    function curveLPTokenEquivalence(HLSConfig memory self, uint256 _LPtoken_amount, int128 i) public view returns(uint256){
        return CurveExecution_ETH.calc_withdraw_one_coin(self.CurveConfig, _LPtoken_amount, i); 
    }

    /**
     * @notice Util to normalize balance up to 18 decimals
     */
    function normalize(address coin, uint256 amount) internal view returns(uint256) {
        uint8 decimals = IERC20(coin).decimals();
        if (decimals == 18) {
            return amount;
        } else if (decimals > 18) {
            return SafeMath.div(amount , uint256(10)**(decimals-18));
        } else if (decimals < 18) {
            return SafeMath.mul(amount , uint256(10)**(18 - decimals));
        }
    }

    // /**
    //  * @notice Calculate shared part of this contract in LP token distriution
    //  * @param normalizedWithdraw amount of stablecoins to withdraw normalized to 18 decimals
    //  */    
    // function calculateShares(HLSConfig memory self, uint256 normalizedWithdraw) internal view returns(uint256) {
    //     uint256 nBalance = normalizedBalance(self);
    //     uint256 poolShares = curveLPTokenBalance(self);
    //     return SafeMath.div(SafeMath.mul(poolShares , normalizedWithdraw) , nBalance);
    // }

    /**
     * @notice Balances of stablecoins available for withdraw normalized to 18 decimals
     * @notice Summed over all four coins
     */
    //  // TODO getStableCoins跟balanceOfAll的變數( HLSConfig.CurveConfig )這樣傳對嗎？
    // function normalizedBalance(HLSConfig memory self) public view returns(uint256) {
    //     address[4] memory stablecoins = CurveExecution_ETH.getStableCoins(self.CurveConfig);
    //     uint256[4] memory balances = balanceOfAll( self );

    //     uint256 summ;
    //     for (uint256 i=0; i < stablecoins.length; i++){
    //         summ = SafeMath.add(summ , normalize(stablecoins[i], balances[i]));
    //     }
    //     return summ;
    // }

    /**
     * @notice Balances of stablecoins available for withdraw
     */
    // function balanceOfAll(HLSConfig memory self) public view returns(uint256[4] memory balances) {

    //     address[4] memory stablecoins = CurveExecution_ETH.getStableCoins(self.CurveConfig);
    //     //uint256[4] memory balances;
    //     uint256 curveLPBalance = curveLPTokenBalance(self); //20
    //     uint256 curveLPTokenSupply = CurveExecution_ETH.getLPSupply(self.CurveConfig); //10

    //     require(curveLPTokenSupply > 0, "No Curve LP tokens minted");

    //     for (uint256 i = 0; i < stablecoins.length; i++) {
    //         int128 j ;
    //         if(i==0) { j =0 ;}
    //         if(i==1) { j =1 ;}
    //         if(i==2) { j =2 ;}
    //         if(i==3) { j =3 ;}
    //         //if(i==4) {int128 j =4 ;}

    //         //Get Y-tokens balance

    //         // swap contract裡面的coins(i)可以read第i種token的address，如yDAI,yUSDC...等
    //         address yCoin = CurveExecution_ETH.getSwapContractCoinAddress(self.CurveConfig, j ) ; //都是ierc20 address
           
    //         // swap contract裡面的balances(i)表示的是對於每種token，這份swap contract擁有多少個(wei)
    //         uint256 yLPTokenBalance = CurveExecution_ETH.getSwapContractCoinBalance(self.CurveConfig, j) ; //都是10

    //         //Calculate user's shares in y-tokens
    //         // 用user有的LP/總供給的LP 來得到可以提領的比例，比例*swap contract裡面的balance就是可以提領的量
    //         // 所以可以提領的量會被swap contract裡面的token總量決定？？？ 如果swap contract裡面的token變少，一樣的LPtoken可以提的量就變少？
    //         uint256 yShares = SafeMath.div( SafeMath.mul( yLPTokenBalance , curveLPBalance ) ,curveLPTokenSupply ) ; //都是20
    //         //Get y-token price for underlying coin
    //         uint256 yPrice = IYERC20(yCoin).getPricePerFullShare();
    //         //Re-calculate available stablecoins balance by y-tokens shares. 啥？
    //         balances[i] = SafeMath.div( SafeMath.mul( yPrice  , yShares ) , 1e18 ) ;

    //     }
    // }



    /**
     * TODO - Done - 細讀multiStepWithdraw的每個function
     * @notice Withdraws 4 stablecoins (registered in Curve.Fi Y pool)
     * @param _amounts Array of amounts for CurveFI stablecoins in pool (denormalized to token decimals)
    //  */
    // function multiStepWithdraw(HLSConfig memory self, uint256[4] memory _amounts) public {
    //     address[4] memory stablecoins = CurveExecution_ETH.getStableCoins(self.CurveConfig);

    //     //Step 1 - Calculate amount of Curve LP-tokens to unstake
    //     uint256 nWithdraw;
    //     uint256 i;
    //     for (i = 0; i < stablecoins.length; i++) {
    //         nWithdraw = SafeMath.add(nWithdraw,normalize(stablecoins[i], _amounts[i]));
    //     }

    //     uint256 withdrawShares = calculateShares(self, nWithdraw); 
    //     // = [ nWithdraw  / normalizedBalance() ] * curveLPTokenBalance()
    //     // = [ 使用者想提領的stable coins總和 / 使用者所擁有的stable coins總和 ] * 使用者擁有的LPtoken 數量
    //     // = 使用者輸入一個stable coins[4]數量後，總共需要的LPtoken的數量，(要這些數量才能withdraw那麼多stable coin)

    //     // Check if you can re-use unstaked LP tokens. 啥？
    //     uint256 notStaked = curveLPTokenUnstaked(self);
    //     if (notStaked > 0) {
    //         withdrawShares = SafeMath.sub(withdrawShares,notStaked);
    //         // 需要unstake的LPtoken數量 = 總共需要的數量 - 本來就已經在使用者address(cashbox contract address)上面的數量
    //     }

    //     //Step 2 - Unstake Curve LP tokens from Gauge
    //     CurveExecution_ETH.unstakeAllLPFromGauge(self.CurveConfig, withdrawShares);
    
    //     //Step 3 - Withdraw stablecoins from CurveDeposit
    //     CurveExecution_ETH.withdrawFromDeposit(self.CurveConfig, _amounts, withdrawShares);
        
    //     //Step 4 - Send stablecoins to the requestor
    //     // 應該不用這一步，直接把錢放在contracnt裡面就好
    //     // for (i = 0; i <  stablecoins.length; i++){
    //     //     IERC20 stablecoin = IERC20(stablecoins[i]);
    //     //     uint256 balance = stablecoin.balanceOf(address(this));
    //     //     uint256 amount = (balance <= _amounts[i]) ? balance : _amounts[i]; //Safepoint for rounding
    //     //     stablecoin.safeTransfer(msg.sender, amount);
    //     // }
    // }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../utils/Initializable.sol";
import "../utils/BasicContract.sol";
import "../token/ERC20/IERC20.sol";
import "../utils/SafeERC20.sol";
import "../math/SafeMath.sol";

import "../interfaces/curve/yPool/ICurveFi_DepositY.sol";
import "../interfaces/curve/yPool/ICurveFi_GaugeY.sol";
import "../interfaces/curve/yPool/ICurveFi_Minter.sol";
import "../interfaces/curve/yPool/ICurveFi_SwapY.sol";
import "../interfaces/curve/IYERC20.sol";

library CurveExecution_ETH {

     // HighLevelSystemExecution_ETH config
    struct CurveConfig {
        address curveFi_Swap;
        address curveFi_Gauge;
        address curveFi_Deposit;
        address curveFi_LPToken;
        address curveFi_CRVToken;
        address curveFi_CRVMinter;
    }
    
    // function setupOtherCurveAddress(CurveConfig memory self) public view {
    //     //StableSwapY.vy
    //     self.curveFi_Swap = ICurveFi_DepositY(self.curveFi_Deposit).curve();
    //     //CurveToken.vy
    //     self.curveFi_LPToken = ICurveFi_DepositY(self.curveFi_Deposit).token();
    //     require(ICurveFi_GaugeY(self.curveFi_Gauge).lp_token() == address(self.curveFi_LPToken), "CurveFi LP tokens do not match");        
    //     self.curveFi_CRVToken = ICurveFi_GaugeY(self.curveFi_Gauge).crv_token();
    // }
        
    // TODO - done - add_liquidity可以傳uint嗎？還是一定要傳uint[4]? => 不行。要傳uint[4]
    // TODO - done - 如何接收add_liquidity後回傳的lptoken? => 不用，沒有回傳值
    function deposit(CurveConfig memory self, uint256[4] memory _amount) public {
        ICurveFi_DepositY(self.curveFi_Deposit).add_liquidity(_amount, 0);
    }

    function stakeAll(CurveConfig memory self, uint256 _stakeAmount) public {
        ICurveFi_GaugeY(self.curveFi_Gauge).deposit(_stakeAmount);
    }

    // TODO - done - remove_liquidity_imbalance跟remove_liquidity的差異是？
    // TODO - done - 什麼是remove_liquidiy_imbalance的max_burn_amount?(第二個輸入參數)
    function withdrawFromDeposit(CurveConfig memory self, uint256[4] memory _uamounts, uint256 _max_burn_amount) public {
        IERC20(self.curveFi_LPToken).approve(self.curveFi_Deposit, _max_burn_amount);
        ICurveFi_DepositY(self.curveFi_Deposit).remove_liquidity_imbalance(_uamounts, _max_burn_amount);
        // 在DepositY中，
        // remove_liquidity_imbalance:給定要提出的dai,usdc,usdt,tusd&最大容許燒毀的lptoken -> 會呼叫SwapY的remove_liduiqidity_imbalance
        // remove_liquidiy_onecoin:只提出一種幣 -> 會呼叫yswap的remove_liduiqidity_imbalance
        // remove_liquidiy:一次提出四種幣 -> 會呼叫yswap的remove_liduiqidity
    }

    function unstakeAllLPFromGauge(CurveConfig memory self, uint256 _unstakeShares) public {
        ICurveFi_GaugeY(self.curveFi_Gauge).withdraw(_unstakeShares);
    }

    function getStableCoins(CurveConfig memory self) public view returns(address[4] memory ){

        address[4] memory stableCoins ;
        // TODO - done - 可直接寫下面這樣嗎？=>可，看deposit的interface，有定義ㄑ
        stableCoins = ICurveFi_DepositY(self.curveFi_Deposit).underlying_coins();

        return stableCoins ;
    }
    
    function getPendingCRV(CurveConfig memory self) public view returns(uint256) {
        uint256 pendingCRV = ICurveFi_GaugeY(self.curveFi_Gauge).claimable_tokens(address(this));
        return pendingCRV ;
    }

    // notice that when i==0 || i==3 , decimal == 18 ( DAI & TUSD )
    // notice that when i==1 || i==2 , decimal == 6  ( USDC & USDT )
    function calc_withdraw_one_coin(CurveConfig memory self, uint256 _token_amount, int128 i)public view returns(uint256){
        uint256 equivalentValue = ICurveFi_DepositY(self.curveFi_Deposit).calc_withdraw_one_coin(_token_amount, i);
        return equivalentValue ;
    }

    function getLPSupply(CurveConfig memory self) public view returns(uint256) {
        return IERC20(self.curveFi_LPToken).totalSupply();
    }
    
    function getCurveStakedLPToken(CurveConfig memory self) public view returns(uint256) {
        return ICurveFi_GaugeY(self.curveFi_Gauge).balanceOf(address(this));
    }

    // swap contract裡面的function coins(i)可以read第i種token的address，如yDAI,yUSDC...等
    function getSwapContractCoinAddress(CurveConfig memory self, int128 i) public view returns(address) {
        return ICurveFi_SwapY(self.curveFi_Swap).coins(i);
    }
            
    // swap contract裡面的balances(i)表示的是對於每種token，這份swap contract擁有多少個(wei)
    function getSwapContractCoinBalance(CurveConfig memory self, int128 i) public view returns(uint256) {
        return ICurveFi_SwapY(self.curveFi_Swap).balances(i);
    }

    //就是example的crvTokenClaim
    function mint(CurveConfig memory self) public {
        ICurveFi_Minter(self.curveFi_CRVMinter).mint(self.curveFi_Gauge);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../token/ERC20/IERC20.sol";
import "../math/SafeMath.sol";
import "../interfaces/cream/CErc20Delegator.sol";
import "../interfaces/cream/InterestRateModel.sol";
import "../interfaces/cream/PriceOracleProxy.sol";
import "../interfaces/cream/Unitroller.sol";

/// @title Cream execution
/// @author Andrew FU
/// @dev All functions haven't finished unit test
library CreamExecution {
    
    // Addresss of Cream.
    struct CreamConfig {
        address oracle; // Address of Cream oracle contract.
        address troller; // Address of Cream troller contract.
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
    /* /// @param crWETH_address Cream crWETH address. */
    /// @dev Gets the borrowed amount for a particular token.
    /// @notice In Etherum, we don't need to handle crWETH issue.
    /// @return crToken amount
    function getBorrowAmount(address crtoken_address  /* , address crWETH_address*/ ) public view returns (uint) {
        // if (crtoken_address == crWETH_address) {
        //     revert("we never use WETH (insufficient liquidity), so just use ETH instead");
        // }
        return CErc20Delegator(crtoken_address).borrowBalanceStored(address(this));
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the borrowed amount for a particular token.
    /// @return crToken amount.
    function getUserTotalSupply(address crtoken_address) public returns (uint) {
        
        return CErc20Delegator(crtoken_address).balanceOfUnderlying(address(this));
    }
    
    /// @dev Gets the USDCETH price.
    function getUSDCETHPrice(CreamConfig memory self, address crUSDC_address) public view returns (uint) {
        
        return PriceOracleProxy(self.oracle).getUnderlyingPrice(crUSDC_address);
    }
    
    /// @dev Gets the eth amount.
    function getCrTokenBalance(CreamConfig memory self, address crtoken_address) public view returns (uint) {
        
        return PriceOracleProxy(self.oracle).getUnderlyingPrice(crtoken_address);
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the crtoken/ETH price.
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
        uint usdc_eth_price = getTokenPrice(self, crUSDC_address);
        uint usdc_decimals = IERC20(USDC_address).decimals();
        uint one_unit_of_usdc = SafeMath.mul(1, 10**usdc_decimals);
        
        uint token_price = SafeMath.div(SafeMath.mul(borrow_token_price, one_unit_of_usdc), usdc_eth_price);
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

    /// @param token_address Address of the underlying ERC-20 token .
    /// @dev Gets the address of the cToken that represents the underlying token.
    function getCrTokenAddress(CreamConfig memory self, address token_address) public view returns (address) {
        address[] memory markets = Unitroller(self.troller).getAllMarkets();

        for (uint i = 0; i <= markets.length; i++) {
            if (markets[i] == token_address) {
                return markets[i];
            }
        }

        return address(0);
    }

    function getUnderlyingAddress(address crtoken_address) public view returns (address) {
        
        return CErc20Delegator(crtoken_address).underlying();
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Get the token/ETH price.
    function getUSDPrice(CreamConfig memory self, address crtoken_address, address crUSDC_address, address USDC_address) public view returns (uint) {
        uint token_eth_price = getTokenPrice(self, crtoken_address);
        uint usd_eth_price = getUSDCETHPrice(self, crUSDC_address);
        
        uint usdc_decimals = IERC20(USDC_address).decimals();
        uint one_unit_of_usdc = SafeMath.mul(1, 10**usdc_decimals);
        return SafeMath.div(SafeMath.mul(token_eth_price, one_unit_of_usdc), usd_eth_price);
    }
    
    function repay(address crtoken_address, uint repay_amount) public returns (uint) {
        address underlying_address = getUnderlyingAddress(crtoken_address);
        IERC20(underlying_address).approve(crtoken_address, repay_amount);
        return CErc20Delegator(crtoken_address).repayBorrow(repay_amount);
    }
    
    function repayETH(address crETH_address, uint repay_amount) public returns (uint) {
        
        return CErc20Delegator(crETH_address).repayBorrow(repay_amount);
    }
    
    function repayAll(address token_addr, address crtoken_address /* , address crWETH_address */ ) public returns (bool) {
        uint current_wallet_amount = getWalletAmount(token_addr);
        uint borrow_amount = getBorrowAmount(crtoken_address /* , crWETH_address */ );
        
        require(current_wallet_amount > borrow_amount, "Not enough funds in the wallet for the transaction");
        repay(crtoken_address, borrow_amount);
        
        return true;
    }

    /// @param crtoken_address Cream crToken address
    /// @param amount amount of tokens to mint.
    /// @dev Supplies amount worth of crtokens into cream.
    function supply(address crtoken_address, uint amount) public returns (uint) {
        address underlying_address = getUnderlyingAddress(crtoken_address);
        IERC20(underlying_address).approve(crtoken_address, amount);
        return CErc20Delegator(crtoken_address).mint(amount);
    }
    
    function getTokenBalance(address token_address) public view returns (uint) {
        
        return IERC20(token_address).balanceOf(address(this));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/** 
 * @dev Interface for Curve.Fi swap contract for Y-pool.
 * @dev See original implementation in official repository:
 * https://github.com/curvefi/curve-contract/blob/master/contracts/pools/y/StableSwapY.vy
 */
interface ICurveFi_SwapY { 
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 _amount, uint256[4] calldata min_amounts) external;
    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;
    function calc_token_amount(uint256[4] calldata amounts, bool deposit) external view returns(uint256);

    function balances(int128 i) external view returns(uint256);
    
    function coins(int128 i) external view returns (address);
    // i==0 => yDAI , i==1 => yUSDC ...etc
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/** 
 * @dev Interface for Curve.Fi CRV minter contract.
 * @dev See original implementation in official repository:
 * https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/Minter.vy
 */
interface ICurveFi_Minter {
    function mint(address gauge_addr) external;
    function mint_for(address gauge_addr, address _for) external;
    function minted(address _for, address gauge_addr) external view returns(uint256);

    function toggle_approve_mint(address minting_user) external;

    function token() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/** 
 * @dev Interface for Curve.Fi CRV staking Gauge contract.
 * @dev See original implementation in official repository:
 * https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/LiquidityGauge.vy
 */
interface ICurveFi_GaugeY {
    function lp_token() external view returns(address);
    function crv_token() external view returns(address);
 
    function balanceOf(address addr) external view returns (uint256);
    function deposit(uint256 _value) external;
    function withdraw(uint256 _value) external;

    // claimable_tokens has been changed to view manually.
    function claimable_tokens(address addr) external view returns (uint256);
    
    function minter() external view returns(address); //use minter().mint(gauge_addr) to claim CRV

    function integrate_fraction(address _for) external view returns(uint256);
    function user_checkpoint(address _for) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/** 
 * @dev Interface for Curve.Fi deposit contract for Y-pool.
 * @dev See original implementation in official repository:
 * https://github.com/curvefi/curve-contract/blob/master/contracts/pools/y/DepositY.vy
 */
interface ICurveFi_DepositY { 
    function add_liquidity(uint256[4] calldata uamounts, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 _amount, uint256[4] calldata min_uamounts) external;
    function remove_liquidity_imbalance(uint256[4] calldata uamounts, uint256 max_burn_amount) external;

    function coins(int128 i) external view returns (address);
    function underlying_coins(int128 i) external view returns (address);
    function underlying_coins() external view returns (address[4] memory);
    function curve() external view returns (address);
    function token() external view returns (address);

    function calc_withdraw_one_coin (uint256 _token_amount, int128 i ) external view returns (uint256) ;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IYERC20 { 

    //ERC20 functions
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    //Y-token functions
    function deposit(uint256 amount) external;
    function withdraw(uint256 shares) external;
    function getPricePerFullShare() external view returns (uint256);

    function token() external returns(address);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface Unitroller {

    function allMarkets(uint) external view returns (address);
    function getAllMarkets() external view returns (address[] memory);
    
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
    constructor() {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}