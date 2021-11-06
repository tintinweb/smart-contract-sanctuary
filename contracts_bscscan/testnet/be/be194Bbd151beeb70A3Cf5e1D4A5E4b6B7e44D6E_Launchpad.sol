// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./lib/Ownable.sol";
import "./lib/SafeMath.sol";
import "./lib/IERC20.sol";
import "./lib/SafeERC20.sol";
import "./lib/ReentrancyGuard.sol";


contract Launchpad is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 totalDeposit;      // How many MMPro tokens the user has provided.
        uint256 allocatedAmount;   // How many lTokens are available to the user for purchase
        uint256 purchasedAmount;   // How many lTokens the user has already bought
        uint256 rewardDebt;
    }

    // Info of each pool.
    struct PoolInfo {
        address owner;         // owner of this pool      
        IERC20 lToken;             // Launched Token
        uint256 lTokenPrice;       // 5 digits LToken price (in stables) ex. 1:1 lTokenPrice=100000
        uint256 lTokenPerSec;      // How many Token distributed per second
        uint256 depositLimit;        // MMProToken deposit limit
        uint256 buyLimit;          // lToken buy limit
        uint256 startTimestamp;    // Stacking start timestamp
        uint256 stakingEnd;   // Stacking duration in seconds
        uint256 purchaseEnd;  // Purchase duration in seconds, start = startTimestamp+stakingDuration
        uint256 lockupEnd;    // lTokens lockup duration, start = startTimestamp+stakingDuration + purchaseDuration
        uint256 sharesTotal;  // total staked amount
        uint256 lastRewardTimestamp;  // Last timestamp that lTokens distribution occurs.
        uint256 accLTokenPerShare;   // Accumulated lTokens per share, times 1e18.
        uint256 totalBought;   
        
    }

    // Stablecoin contracts
    IERC20[] public stablesInfo;

    /*
    [
        IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56),//BUSD
        IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d),//USDC
        IERC20(0x55d398326f99059fF775485246999027B3197955),//USDT
        IERC20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3)//DAI
    ];
    */

    // The MMpro TOKEN!
    IERC20 immutable public MMpro;
    // fee in basis points
    address public feeAddress;
    uint256 feeBP=500;
    uint256 public constant FEE_MAX = 2000; // 20%
    uint256 public immutable allocationDelay;

  

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes MMPROtoken.
    mapping(address => mapping(uint256 => UserInfo)) public userInfo;

    mapping(address=>uint256) public totalAllocation;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event BuyToken(address indexed user, uint256 indexed pid, uint256 amount);
    event PickUpTokens(address indexed user, uint256 indexed pid, uint256 amount);
    event TakeAwayUnsold(uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event ChangeFeeBP(uint256 feeBP);

    modifier onlyPoolOwner(uint256 _pid) {
        require(poolInfo[_pid].owner == msg.sender, "the caller is not a pool owner");
        _;
    }

    constructor(IERC20 _MMpro,
        address _feeAddress,
        IERC20[] memory _stablesInfo,
        uint256 _allocationDelay) public {
        MMpro = _MMpro;
        feeAddress = _feeAddress;
        stablesInfo=_stablesInfo;
        allocationDelay=_allocationDelay;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new pool. Can only be called by the owner.
    function add(address _poolOwner,
                IERC20 _lToken,
                uint256 _lTokenPrice,
                uint256 _poolAllocationBP,
                uint256 _depositLimit,
                uint256 _buyLimit,
                uint256 _startTimestamp,
                uint256 _stakingDuration,
                uint256 _purchaseDuration,
                uint256 _lockupDuration
                ) external onlyOwner {
        require(
            (_depositLimit>0 && _buyLimit>0) 
            || (_depositLimit==0 && _buyLimit==0),
            "is this pool limited or not?"
        );
        require(_poolAllocationBP.add(totalAllocation[address(_lToken)]) <= 10000,
        "_poolAllocationBP is too high");
        require(_stakingDuration>allocationDelay,"_stakingDuration is too small");
        uint256 lTokenMax=_lToken.balanceOf(address(this)).mul(_poolAllocationBP).div(10000);

        require(
            lTokenMax > _stakingDuration,
            "not enough tokens on the contract balance"
        );

        totalAllocation[address(_lToken)]=totalAllocation[address(_lToken)].add(_poolAllocationBP);
        uint256 startTimestamp = block.timestamp > _startTimestamp ? block.timestamp : _startTimestamp;

        poolInfo.push(PoolInfo({
            owner : _poolOwner,
            lToken : _lToken,
            lTokenPrice : _lTokenPrice,
            lTokenPerSec : lTokenMax.div(_stakingDuration.sub(allocationDelay)),
            depositLimit : _depositLimit,
            buyLimit : _buyLimit,
            startTimestamp : startTimestamp,
            stakingEnd : startTimestamp.add(_stakingDuration),
            purchaseEnd : startTimestamp.add(_stakingDuration).add(_purchaseDuration),
            lockupEnd : startTimestamp.add(_stakingDuration).add(_purchaseDuration).add(_lockupDuration),
            sharesTotal : 0,
            lastRewardTimestamp : startTimestamp.add(allocationDelay),
            accLTokenPerShare : 0,
            totalBought:0
        }));
    }


    function changeFee(uint256 _feeBP) external onlyOwner {
        require(_feeBP <= FEE_MAX, "changeFee: the fee is too high");
        feeBP = _feeBP;
        emit ChangeFeeBP(_feeBP);
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    // View function to see pending lToken allocation on frontend.
    function pendingAllocation(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_user][_pid];
        uint256 accLTokenPerShare = pool.accLTokenPerShare;
        uint256 lpSupply = pool.sharesTotal;
        if (block.timestamp > pool.lastRewardTimestamp 
            && pool.lastRewardTimestamp < pool.stakingEnd 
            && lpSupply != 0) {

            uint256 multiplier = block.timestamp > pool.stakingEnd ? 
                pool.stakingEnd.sub(pool.lastRewardTimestamp):block.timestamp.sub(pool.lastRewardTimestamp);

            uint256 reward = multiplier.mul(pool.lTokenPerSec);
            accLTokenPerShare = accLTokenPerShare.add(reward.mul(1e18).div(lpSupply));
            
        }
        return user.totalDeposit.mul(accLTokenPerShare).div(1e18).sub(user.rewardDebt);
        
    }

    
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        
        if (block.timestamp <= pool.lastRewardTimestamp 
        || pool.lastRewardTimestamp>=pool.stakingEnd) {
            return;
        }

        if (pool.sharesTotal == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 multiplier = block.timestamp > pool.stakingEnd ? 
        pool.stakingEnd.sub(pool.lastRewardTimestamp):block.timestamp.sub(pool.lastRewardTimestamp);

        uint256 reward = multiplier.mul(pool.lTokenPerSec);
        pool.accLTokenPerShare = pool.accLTokenPerShare.add(reward.mul(1e18).div(pool.sharesTotal));
        pool.lastRewardTimestamp = block.timestamp;

    }

    // Deposit MMpro tokens for lTokens allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        
        PoolInfo storage pool = poolInfo[_pid];
        require(
          block.timestamp > pool.startTimestamp && block.timestamp <= pool.stakingEnd,
          "deposit: not time to deposit"
        );
        UserInfo storage user = userInfo[msg.sender][_pid];
        require(pool.depositLimit==0 || user.totalDeposit.add(_amount) <= pool.depositLimit,
        "deposit limit exceeded");
        updatePool(_pid);

        if (user.totalDeposit > 0) {
            user.allocatedAmount = user.allocatedAmount
            .add(
              user.totalDeposit
              .mul(pool.accLTokenPerShare)
              .div(1e18)
              .sub(user.rewardDebt)
            );
        }
        if (_amount > 0) {
            MMpro.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.totalDeposit = user.totalDeposit.add(_amount);
            pool.sharesTotal = pool.sharesTotal.add(_amount);
        }
        user.rewardDebt = user.totalDeposit.mul(pool.accLTokenPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw MMpro tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        require(
          block.timestamp > pool.stakingEnd,
          "withdraw: not time to withdraw"
        );
        UserInfo storage user = userInfo[msg.sender][_pid];
        require(user.totalDeposit >= _amount, "withdraw: _amount not good");
        updatePool(_pid);

        user.allocatedAmount = user.allocatedAmount
            .add(
              user.totalDeposit
              .mul(pool.accLTokenPerShare)
              .div(1e18)
              .sub(user.rewardDebt)
            );

        if (_amount > 0) {
            user.totalDeposit = user.totalDeposit.sub(_amount);
            pool.sharesTotal = pool.sharesTotal.sub(_amount);
            MMpro.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.totalDeposit.mul(pool.accLTokenPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function buyToken(uint256 _pid, uint256 _amount,uint256 stableId) public {
        require(stableId<stablesInfo.length,"buyToken: stableId out of range");
        PoolInfo storage pool = poolInfo[_pid];
        
        require(
          block.timestamp > pool.stakingEnd && block.timestamp <= pool.purchaseEnd,
          "buyToken: not time to buy"
        );

        UserInfo storage user = userInfo[msg.sender][_pid];

        updatePool(_pid);
        
        if (user.totalDeposit > 0) {
            user.allocatedAmount = user.allocatedAmount
            .add(
              user.totalDeposit
              .mul(pool.accLTokenPerShare)
              .div(1e18)
              .sub(user.rewardDebt)
            );
        }

        uint256 stableTokenAmount = pool.lTokenPrice.mul(_amount).div(1e5);

        if(stableTokenAmount>0){
            
            require(user.allocatedAmount >= _amount, "buyToken: _amount not good");
            require(
                pool.buyLimit == 0 || user.purchasedAmount.add(_amount)<=pool.buyLimit,
                "buyToken: amount of tokens for purchase is limited"
            );
            user.allocatedAmount=user.allocatedAmount.sub(_amount);
            user.purchasedAmount=user.purchasedAmount.add(_amount);            
            pool.totalBought = pool.totalBought.add(_amount);

            IERC20 stableToken=stablesInfo[stableId];
            uint256 feeAmount=stableTokenAmount.mul(feeBP).div(10000);
            if(feeAmount>0){
                stableTokenAmount=stableTokenAmount.sub(feeAmount);
                stableToken.safeTransferFrom(address(msg.sender), feeAddress, feeAmount);
            }
            stableToken.safeTransferFrom(address(msg.sender), pool.owner, stableTokenAmount);
            emit BuyToken(msg.sender, _pid, _amount);
        }
    }

    function pickUpTokens(uint256 _pid) public{

        PoolInfo storage pool = poolInfo[_pid];
        require(
          block.timestamp > pool.lockupEnd,
          "pickUpTokens: tokens are still locked"
        );
        UserInfo storage user = userInfo[msg.sender][_pid];
        uint256 amount = user.purchasedAmount;
        user.purchasedAmount=0;
        if(amount>0){
            pool.lToken.safeTransfer(msg.sender, amount);
            emit PickUpTokens(msg.sender, _pid, amount);
        }
        
    }

    function takeAwayUnsold(uint256 _pid) external onlyPoolOwner(_pid){

        PoolInfo storage pool = poolInfo[_pid];
        require(
          block.timestamp > pool.purchaseEnd,
          "takeAwayUnsold: the sale is not over yet"
        );
        
        uint256 unsoldAmount = pool.lTokenPerSec.mul(
            pool.stakingEnd
            .sub(pool.startTimestamp.add(allocationDelay))
            ).sub(pool.totalBought);
        
        if(unsoldAmount>pool.lToken.balanceOf(address(this))){
            unsoldAmount=pool.lToken.balanceOf(address(this));
        }
        if(unsoldAmount>0){
            pool.lToken.safeTransfer(msg.sender,unsoldAmount);
            emit TakeAwayUnsold(_pid, unsoldAmount);
        }
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Context.sol";


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Address.sol";
import "./SafeMath.sol";
import "./IERC20.sol";


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}