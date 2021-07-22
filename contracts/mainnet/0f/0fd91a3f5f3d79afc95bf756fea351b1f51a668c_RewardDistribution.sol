/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function mint(address account, uint amount) external;
  function burn(address account, uint amount) external;
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

interface IPairFactory {
  function pairByTokens(address _tokenA, address _tokenB) external view returns(address);
}

interface ILendingPair {
  function checkAccountHealth(address _account) external view;
  function accrueAccount(address _account) external;
  function accrue() external;
  function accountHealth(address _account) external view returns(uint);
  function totalDebt(address _token) external view returns(uint);
  function tokenA() external view returns(address);
  function tokenB() external view returns(address);
  function lpToken(address _token) external view returns(IERC20);
  function debtOf(address _account, address _token) external view returns(uint);
  function pendingDebtTotal(address _token) external view returns(uint);
  function pendingSupplyTotal(address _token) external view returns(uint);
  function deposit(address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function controller() external view returns(IController);

  function borrowBalance(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint);

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint);
}

interface IInterestRateModel {
  function systemRate(ILendingPair _pair, address _token) external view returns(uint);
  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
}

interface IRewardDistribution {
  function distributeReward(address _account, address _token) external;
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
  function rewardDistribution() external view returns(IRewardDistribution);
  function feeRecipient() external view returns(address);
  function LIQ_MIN_HEALTH() external view returns(uint);
  function minBorrowUSD() external view returns(uint);
  function liqFeeSystem(address _token) external view returns(uint);
  function liqFeeCaller(address _token) external view returns(uint);
  function liqFeesTotal(address _token) external view returns(uint);
  function colFactor(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function borrowLimit(address _lendingPair, address _token) external view returns(uint);
  function originFee(address _token) external view returns(uint);
  function depositsEnabled() external view returns(bool);
  function borrowingEnabled() external view returns(bool);
  function setFeeRecipient(address _feeRecipient) external;
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
  function setRewardDistribution(address _value) external;
}

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

contract Ownable {

  address public owner;
  address public pendingOwner;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// Calling setTotalRewardPerBlock, addPool or setReward, pending rewards will be changed.
// Since all pools are likely to get accrued every hour or so, this is an acceptable deviation.
// Accruing all pools here may consume too much gas.
// up to the point of exceeding the gas limit if there are too many pools.

contract RewardDistribution is Ownable {

  using Address for address;

  struct Pool {
    address pair;
    address token;
    bool    isSupply;
    uint    points;             // How many allocation points assigned to this pool.
    uint    lastRewardBlock;    // Last block number that reward distribution occurs.
    uint    accRewardsPerToken; // Accumulated total rewards, multiplied by 1e12
  }

  struct PoolPosition {
    uint pid;
    bool added; // To prevent duplicates.
  }

  IPairFactory public immutable factory;
  IController  public immutable controller;
  IERC20  public immutable rewardToken;
  Pool[]  public pools;
  uint    public totalRewardPerBlock;
  uint    public totalPoints;

  // Pair[token][isSupply] supply = true, borrow = false
  mapping (address => mapping (address => mapping (bool => PoolPosition))) public pidByPairToken;
  // rewardSnapshot[pid][account]
  mapping (uint => mapping (address => uint)) public rewardSnapshot;

  event PoolUpdate(
    uint    indexed pid,
    address indexed pair,
    address indexed token,
    bool    isSupply,
    uint    points
  );

  event RewardRateUpdate(uint value);

  constructor(
    IController  _controller,
    IPairFactory _factory,
    IERC20  _rewardToken,
    uint    _totalRewardPerBlock
  ) {
    controller = _controller;
    factory = _factory;
    rewardToken = _rewardToken;
    totalRewardPerBlock = _totalRewardPerBlock;
  }

  // Lending pair will never call this for feeRecipient
  function distributeReward(address _account, address _token) external {
    _onlyLendingPair();
    address pair = msg.sender;
    _distributeReward(_account, pair, _token, true);
    _distributeReward(_account, pair, _token, false);
  }

  // Pending rewards will be changed. See class comments.
  function addPool(
    address _pair,
    address _token,
    bool    _isSupply,
    uint    _points
  ) external onlyOwner {

    require(
      pidByPairToken[_pair][_token][_isSupply].added == false,
      "RewardDistribution: already added"
    );

    require(
      ILendingPair(_pair).tokenA() == _token || ILendingPair(_pair).tokenB() == _token,
      "RewardDistribution: invalid token"
    );

    totalPoints += _points;

    pools.push(Pool({
      pair:     _pair,
      token:    _token,
      isSupply: _isSupply,
      points:   _points,
      lastRewardBlock: block.number,
      accRewardsPerToken: 0
    }));

    uint pid = pools.length - 1;

    pidByPairToken[_pair][_token][_isSupply] = PoolPosition({
      pid: pid,
      added: true
    });

    emit PoolUpdate(pid, _pair, _token, _isSupply, _points);
  }

  // Pending rewards will be changed. See class comments.
  function setReward(
    address _pair,
    address _token,
    bool    _isSupply,
    uint    _points
  ) external onlyOwner {

    uint pid = _getPid(_pair, _token, _isSupply);
    accruePool(pid);

    totalPoints = totalPoints - pools[pid].points + _points;
    pools[pid].points = _points;

    emit PoolUpdate(pid, _pair, _token, _isSupply, _points);
  }

  // Pending rewards will be changed. See class comments.
  function setTotalRewardPerBlock(uint _value) external onlyOwner {
    totalRewardPerBlock = _value;
    emit RewardRateUpdate(_value);
  }

  function accrueAllPools() public {
      uint length = pools.length;
      for (uint pid = 0; pid < length; ++pid) {
        accruePool(pid);
      }
  }

  function accruePool(uint _pid) public {
    Pool storage pool = pools[_pid];
    pool.accRewardsPerToken += _pendingRewardPerToken(pool);
    pool.lastRewardBlock = block.number;
  }

  function pendingSupplyReward(address _account, address _pair, address _token) public view returns(uint) {
    if (_poolExists(_pair, _token, true)) {
      return _pendingAccountReward(_getPid(_pair, _token, true), _account);
    } else {
      return 0;
    }
  }

  function pendingBorrowReward(address _account, address _pair, address _token) public view returns(uint) {
    if (_poolExists(_pair, _token, false)) {
      return _pendingAccountReward(_getPid(_pair, _token, false), _account);
    } else {
      return 0;
    }
  }

  function pendingTokenReward(address _account, address _pair, address _token) public view returns(uint) {
    return pendingSupplyReward(_account, _pair, _token) + pendingBorrowReward(_account, _pair, _token);
  }

  function pendingAccountReward(address _account, address _pair) external view returns(uint) {
    ILendingPair pair = ILendingPair(_pair);
    return pendingTokenReward(_account, _pair, pair.tokenA()) + pendingTokenReward(_account, _pair, pair.tokenB());
  }

  function supplyBlockReward(address _pair, address _token) external view returns(uint) {
    return _poolRewardRate(_pair, _token, true);
  }

  function borrowBlockReward(address _pair, address _token) external view returns(uint) {
    return _poolRewardRate(_pair, _token, false);
  }

  function poolLength() external view returns (uint) {
    return pools.length;
  }

  // Allows to migrate rewards to a new staking contract.
  function migrateRewards(address _recipient, uint _amount) external onlyOwner {
    rewardToken.transfer(_recipient, _amount);
  }

  function _transferReward(address _to, uint _amount) internal {
    if (_amount > 0) {
      uint rewardTokenBal = rewardToken.balanceOf(address(this));
      if (_amount > rewardTokenBal) {
        rewardToken.transfer(_to, rewardTokenBal);
      } else {
        rewardToken.transfer(_to, _amount);
      }
    }
  }

  function _distributeReward(address _account, address _pair, address _token, bool _isSupply) internal {

    if (_poolExists(_pair, _token, _isSupply)) {

      uint pid = _getPid(_pair, _token, _isSupply);

      accruePool(pid);
      _transferReward(_account, _pendingAccountReward(pid, _account));

      Pool memory pool = _getPool(_pair, _token, _isSupply);
      rewardSnapshot[pid][_account] = pool.accRewardsPerToken;
    }
  }

  function _poolRewardRate(address _pair, address _token, bool _isSupply) internal view returns(uint) {

    if (_poolExists(_pair, _token, _isSupply)) {

      Pool memory pool = _getPool(_pair, _token, _isSupply);
      return totalRewardPerBlock * pool.points / totalPoints;

    } else {
      return 0;
    }
  }

  function _pendingAccountReward(uint _pid, address _account) internal view returns(uint) {
    Pool memory pool = pools[_pid];

    pool.accRewardsPerToken += _pendingRewardPerToken(pool);
    uint rewardsPerTokenDelta = pool.accRewardsPerToken - rewardSnapshot[_pid][_account];
    return rewardsPerTokenDelta * _stakedAccount(pool, _account) / 1e12;
  }

  function _pendingRewardPerToken(Pool memory _pool) internal view returns(uint) {
    uint totalStaked = _stakedTotal(_pool);

    if (_pool.lastRewardBlock == 0 || totalStaked == 0) {
      return 0;
    }

    uint blocksElapsed = block.number - _pool.lastRewardBlock;
    return blocksElapsed * _poolRewardRate(_pool.pair, _pool.token, _pool.isSupply) * 1e12 / totalStaked;
  }

  function _getPool(address _pair, address _token, bool _isSupply) internal view returns(Pool memory) {
    return pools[_getPid(_pair, _token, _isSupply)];
  }

  function _getPid(address _pair, address _token, bool _isSupply) internal view returns(uint) {
    PoolPosition memory poolPosition = pidByPairToken[_pair][_token][_isSupply];
    require(poolPosition.added, "RewardDistribution: invalid pool");

    return poolPosition.pid;
  }

  function _poolExists(address _pair, address _token, bool _isSupply) internal view returns(bool) {
    return pidByPairToken[_pair][_token][_isSupply].added;
  }

  function _stakedTotal(Pool memory _pool) internal view returns(uint) {
    ILendingPair pair = ILendingPair(_pool.pair);
    uint feeRecipientBalance = pair.lpToken(_pool.token).balanceOf(_feeRecipient());

    if (_pool.isSupply) {
      // stake of feeRecipient should not be included in the reward pool
      return pair.lpToken(_pool.token).totalSupply() - feeRecipientBalance;
    } else {
      // feeRecipient will never have any debt
      return pair.totalDebt(_pool.token);
    }
  }

  function _stakedAccount(Pool memory _pool, address _account) internal view returns(uint) {
    ILendingPair pair = ILendingPair(_pool.pair);

    if (_account == _feeRecipient()) {
      return 0;
    } else if (_pool.isSupply) {
      return pair.lpToken(_pool.token).balanceOf(_account);
    } else {
      return pair.debtOf(_pool.token, _account);
    }
  }

  function _onlyLendingPair() internal view {

    if (msg.sender.isContract()) {
      address factoryPair = factory.pairByTokens(ILendingPair(msg.sender).tokenA(), ILendingPair(msg.sender).tokenB());
      require(factoryPair == msg.sender, "RewardDistribution: caller not lending pair");

    } else {
      revert("RewardDistribution: caller not lending pair");
    }
  }

  function _feeRecipient() internal view returns(address) {
    return controller.feeRecipient();
  }
}