// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC721 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
}

interface IEpicHeroNFT is IERC721{
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);
    function getHero(uint tokenId) external view returns (uint256 level, uint256 tier);
}

interface IReferral {
    function recordReferral(address user, address referrer) external;
    function recordReferralCommission(address referrer, uint256 commission) external;
    function getReferrer(address user) external view returns (address);
}

interface IStrategy {
    function calculateShares(address _user, uint256[] memory _tokenIds) external view returns (uint256);
}

interface ITreasury {
    function claimTokens(address _token, uint256 _amount, address _receiver) external;
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
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

library SafeMathExt {
    function add128(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "uint128: addition overflow");

        return c;
    }

    function sub128(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "uint128: subtraction overflow");
        uint128 c = a - b;

        return c;
    }

    function add64(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a, "uint64: addition overflow");

        return c;
    }

    function sub64(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b <= a, "uint64: subtraction overflow");
        uint64 c = a - b;

        return c;
    }

    function safe128(uint256 a) internal pure returns(uint128) {
        require(a < 0x0100000000000000000000000000000000, "uint128: number overflow");
        return uint128(a);
    }

    function safe64(uint256 a) internal pure returns(uint64) {
        require(a < 0x010000000000000000, "uint64: number overflow");
        return uint64(a);
    }

    function safe32(uint256 a) internal pure returns(uint32) {
        require(a < 0x0100000000, "uint32: number overflow");
        return uint32(a);
    }

    function safe16(uint256 a) internal pure returns(uint16) {
        require(a < 0x010000, "uint32: number overflow");
        return uint16(a);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

abstract contract Auth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

contract MasterChefV4 is Auth, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_EPICHERO_PER_BLOCK = 2000 * 10 ** 18;
    uint256 public constant BONUS_MULTIPLIER = 1;
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 365 days;
    uint16 public constant MAXIMUM_REFERRAL_RATE = 1000;
    uint16 public constant MAXIMUM_FEE_RATE = 9000;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardLockedUp;
        uint256 nextHarvestUntil;
        uint256 countNft;
        bool canDeposit;
    }

    struct PoolInfo {
        address lpToken;
        address strat;

        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accEpicHeroPerShare;
        uint16 depositFeeBP;
        uint256 harvestInterval;
        uint256 minLevel;
        uint256 minTier;
        uint256 totalLp;
        uint256 countNft;

        uint8 maxNft;
        bool paused;
    }

    struct NftOwner {
        address addr;
        uint256 pid;
        uint64  index;
    }

    IERC20 public feeToken;
    IERC20 public epicHero;
    ITreasury treasury;
    IReferral public referral;

    uint16 public referralRate = 0;
    uint16 public devFeeRate = 0;
    uint16 public demiFeeDividend = 20;

    uint256 public joinPoolFee = 1000 * 10 ** 18;

    address public devAddress = 0xFFCdB6cFF70223306f6506C3e244e7012322f044;
    address public feeAddress = 0xFFCdB6cFF70223306f6506C3e244e7012322f044;

    PoolInfo[] public poolInfo;
    
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping (address => uint256[]) _stakingHeroArray;
    mapping (uint256 => NftOwner) _heroIdToOwnerAndIndex;

    mapping (address => uint256[]) _stakingHeroArray2;
    mapping (uint256 => NftOwner) _heroIdToOwnerAndIndex2;

    uint256 public startBlock;
    uint256 public totalAllocPoint = 0;
    uint256 public totalLockedUpRewards;

    uint256 public epicHeroPerBlock;

    bool public isPaused = false;
    
    constructor(
        address _epicHero,
        address _feeToken,
        address _treasury,
        address _referral,
        uint256 _epicHeroPerBlock
    ) Auth(msg.sender) ReentrancyGuard(){
        
        startBlock = block.number + (10 * 365 * 24 * 60 * 60);

        epicHero = IERC20(_epicHero);
        feeToken = IERC20(_feeToken);
        treasury = ITreasury(_treasury);
        referral = IReferral(_referral);

        epicHeroPerBlock = _epicHeroPerBlock;
    }
    
    // Set farming start, can call only once
    function startFarming() public onlyOwner {
        require(block.number < startBlock, "Error::Farm started already");

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardBlock = block.number;
        }

        startBlock = block.number;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(
        uint256 _allocPoint,
        address _lpToken,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        uint8 _minLevel,
        uint8 _minTier,
        uint8 _maxNft,
        address _strat,
        bool _paused,
        bool _withUpdate
    ) public authorized {
        require(_depositFeeBP <= MAXIMUM_FEE_RATE, "add: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        strat: _strat,

        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accEpicHeroPerShare : 0,
        depositFeeBP : _depositFeeBP,
        harvestInterval : _harvestInterval,
        minLevel: _minLevel,
        minTier: _minTier,
        totalLp : 0,
        countNft: 0,
        maxNft: _maxNft,
        paused: _paused
        }));
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        uint256 _minLevel,
        uint256 _minTier,
        uint8 _maxNft,
        address _strat,
        bool _paused,
        bool _withUpdate
    ) public authorized {
        require(_depositFeeBP <= MAXIMUM_FEE_RATE, "set: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].paused = _paused;
        poolInfo[_pid].maxNft = _maxNft;
        poolInfo[_pid].strat = _strat;
        poolInfo[_pid].minLevel = _minLevel;
        poolInfo[_pid].minTier = _minTier;
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function pendingEpicHero(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accEpicHeroPerShare = pool.accEpicHeroPerShare;
        uint256 lpSupply = pool.totalLp;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 epicHeroReward = multiplier.mul(epicHeroPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accEpicHeroPerShare = accEpicHeroPerShare.add(epicHeroReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accEpicHeroPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.number >= startBlock && block.timestamp >= user.nextHarvestUntil;
    }

    function getNftStaking(address _user) external view returns (uint256[] memory) {
        return _stakingHeroArray[_user];
    }

    function getNftOwner(uint256 _heroId) external view returns (address){
        return _heroIdToOwnerAndIndex[_heroId].addr;
    }

    function getNftOwner2(uint256 _heroId) external view returns (address){
        return _heroIdToOwnerAndIndex2[_heroId].addr;
    }

    function countNftInPool(uint256 _pid, address _user) public view returns (uint256){
        UserInfo storage user = userInfo[_pid][_user];
        return user.countNft;
    }

    function getNftInPool(uint256 _pid, address _user) public view returns (uint256[] memory) {
        uint256[] storage _heroIds = _stakingHeroArray[_user];

        uint256[] memory ownerHeroIds = new uint256[](countNftInPool(_pid, _user));

        uint256 index = 0;
        for(uint i = 0; i < _heroIds.length; i++) {
            NftOwner storage _nftOwner = _heroIdToOwnerAndIndex[_heroIds[i]];
            if( _nftOwner.pid == _pid && _nftOwner.addr == _user ){
                ownerHeroIds[index] = _heroIds[i];
                index++;
            }
        }

        return ownerHeroIds;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        uint256 totalReward = 0;

        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            if (block.number <= pool.lastRewardBlock) {
                continue;
            }

            if (pool.totalLp == 0 || pool.allocPoint == 0) {
                pool.lastRewardBlock = block.number;
                continue;
            }

            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 epicHeroReward = multiplier.mul(epicHeroPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

            pool.accEpicHeroPerShare = pool.accEpicHeroPerShare.add(epicHeroReward.mul(1e12).div(pool.totalLp));
            pool.lastRewardBlock = block.number;

            totalReward.add(epicHeroReward.mul(devFeeRate).div(10000));
        }
        if(totalReward > 0){
            safeEpicHeroTransfer(devAddress, totalReward);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalLp == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 epicHeroReward = multiplier.mul(epicHeroPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accEpicHeroPerShare = pool.accEpicHeroPerShare.add(epicHeroReward.mul(1e12).div(pool.totalLp));
        pool.lastRewardBlock = block.number;

        if(devFeeRate > 0){
            safeEpicHeroTransfer(devAddress, epicHeroReward.mul(devFeeRate).div(10000));
        }
    }

    function depositNFTs(uint256 _pid, uint256[] memory _heroIds, address _referrer) public nonReentrant {
        require(block.number >= startBlock, "MasterChef: Can not deposit before farm start");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(!isPaused && !pool.paused, "Pool: Paused");

        if(_heroIds.length > 0){
            require(user.countNft.add(_heroIds.length) <= pool.maxNft, "Invalid maxNft");
            require(joinPoolFee == 0 || user.canDeposit, "Join fee not paid");
        }

        updatePool(_pid);

        if (_heroIds.length > 0 && address(referral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            referral.recordReferral(msg.sender, _referrer);
        }

        payOrLockupPendingEpicHero(_pid);

        if (pool.depositFeeBP > 0) {
            uint256 depositFee = _heroIds.length.mul(pool.depositFeeBP);
            feeToken.safeTransferFrom(address(msg.sender), feeAddress, depositFee);
        }

        if (_heroIds.length > 0) {
            IEpicHeroNFT nftContract = IEpicHeroNFT(pool.lpToken);

            uint256[] storage heroIds = _stakingHeroArray[msg.sender];

            for(uint i = 0; i < _heroIds.length; i++) {
                (uint256 level, uint256 tier) = nftContract.getHero(_heroIds[i]);

                require(level > 0, "Require higher level");
                require(tier > 0, "Require higher tier");

                nftContract.safeTransferFrom(
                    address(msg.sender),
                    address(this),
                    _heroIds[i]
                );

                _heroIdToOwnerAndIndex[_heroIds[i]] = NftOwner(msg.sender, _pid, SafeMathExt.safe64(heroIds.length));
                heroIds.push(_heroIds[i]);
            }

            uint256 sharesAdded = IStrategy(pool.strat).calculateShares(msg.sender, _heroIds);

            user.amount = user.amount.add(sharesAdded);
            user.countNft = user.countNft.add(_heroIds.length);

            pool.totalLp = pool.totalLp.add(sharesAdded);
            pool.countNft = pool.countNft.add(_heroIds.length);
        }



        user.rewardDebt = user.amount.mul(pool.accEpicHeroPerShare).div(1e12);
        emit DepositNFT(msg.sender, _pid, _heroIds);
    }

    function withdrawNFTs(uint256 _pid, uint256[] memory _heroIds) public nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.countNft > 0 , "Withdraw: User nft not enough");
        require(pool.countNft > 0 , "Withdraw: Pool nft not enough");

        updatePool(_pid);
        payOrLockupPendingEpicHero(_pid);

        if(_heroIds.length > 0){
            uint256 sharesRemoved = IStrategy(pool.strat).calculateShares(msg.sender, _heroIds);

            if (sharesRemoved > user.amount) {
                user.amount = 0;
            } else {
                user.amount = user.amount.sub(sharesRemoved);
            }

            if(pool.totalLp > sharesRemoved){
                pool.totalLp = pool.totalLp.sub(sharesRemoved);
            }else{
                pool.totalLp = 0;
            }

            if(pool.countNft > _heroIds.length){
                pool.countNft = pool.countNft.sub(_heroIds.length);
            }else{
                pool.countNft = 0;
            }

            if(user.countNft > _heroIds.length){
                user.countNft = user.countNft.sub(_heroIds.length);
            }else{
                user.countNft = 0;
            }

            uint256[] storage heroIds = _stakingHeroArray[msg.sender];
            for(uint i = 0; i < _heroIds.length; i++) {
                NftOwner storage _nftOwner = _heroIdToOwnerAndIndex[_heroIds[i]];
                require(msg.sender == address(_nftOwner.addr), "Invalid NFT owner");
                require(_pid == _nftOwner.pid, "Invalid NFT pool");

                if(uint256(_nftOwner.index) != heroIds.length.sub(1)){
                    heroIds[uint256(_nftOwner.index)] = heroIds[heroIds.length.sub(1)];
                    _heroIdToOwnerAndIndex[heroIds[uint256(_nftOwner.index)]].index = _nftOwner.index;
                }

                heroIds.pop();

                delete _heroIdToOwnerAndIndex[_heroIds[i]];

                IEpicHeroNFT(pool.lpToken).transferFrom(
                    address(this),
                    address(msg.sender),
                    _heroIds[i]
                );
            }
        }


        user.rewardDebt = user.amount.mul(pool.accEpicHeroPerShare).div(1e12);
        emit WithdrawNFT(msg.sender, _pid, _heroIds);
    }

    function joinPool(uint256 _pid) public nonReentrant{
        require(block.number >= startBlock, "MasterChef: Can not deposit before farm start");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(!isPaused && !pool.paused, "Pool: Paused");
        require(!user.canDeposit,"Already joined this pool");

        if(joinPoolFee > 0){
            feeToken.safeTransferFrom(address(msg.sender), feeAddress, joinPoolFee);
            user.canDeposit = true;
        }

        emit JoinPool(msg.sender, _pid);
    }

    function payOrLockupPendingEpicHero(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0 && block.number >= startBlock) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accEpicHeroPerShare).div(1e12).sub(user.rewardDebt);

        if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
        }
    }

    function claimPendingReward(uint256 _pid) public nonReentrant {
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0 && block.number >= startBlock) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accEpicHeroPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // send rewards
                safeEpicHeroTransfer(msg.sender, totalRewards);
                payReferralCommission(msg.sender, totalRewards);
            }
        }

        user.rewardDebt = user.amount.mul(pool.accEpicHeroPerShare).div(1e12);
    }

    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(referral) != address(0) && referralRate > 0) {
            address referrer = referral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                safeEpicHeroTransfer(referrer, commissionAmount);
                referral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    function safeEpicHeroTransfer(address _to, uint256 _amount) internal {
        require(epicHero.balanceOf(address(treasury)) >= _amount,"Treasury not enough _amount");
        treasury.claimTokens(address(epicHero), _amount, _to);
    }

    function setDevAddress(address _devAddress) public onlyOwner{
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner{
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    function setFeeToken(address _feeToken) public onlyOwner{
        require(_feeToken != address(0), "setFeeToken: ZERO");
        feeToken = IERC20(_feeToken);
    }

    function setTreasury(address _treasuryAddress) public onlyOwner{
        require(_treasuryAddress != address(0), "setTreasury: ZERO");
        treasury = ITreasury(_treasuryAddress);
    }

    function setReferral(address _referralAddress) public onlyOwner {
        require(_referralAddress != address(0), "setReferral: ZERO");
        referral = IReferral(_referralAddress);
    }

    function setReferralRate(uint16 _referralRate) public onlyOwner {
        require(_referralRate <= MAXIMUM_REFERRAL_RATE, "Invalid referralRate");
        referralRate = _referralRate;
    }

    function setDevFeeRate(uint16 _devFeeRate) public onlyOwner {
        require(_devFeeRate <= MAXIMUM_FEE_RATE, "Invalid devFeeRate");
        devFeeRate = _devFeeRate;
    }

    function setJoinPoolFee(uint256 _joinFee) public onlyOwner {
        joinPoolFee = _joinFee;
    }

    function setPaused(bool value) external authorized {
        require(value != isPaused, "Same");
        isPaused = value;
    }

    function retrieveBNB(uint _amount) external onlyOwner{
        uint balance = address(this).balance;

        if(_amount > balance){
            _amount = balance;
        }

        (bool success,) = payable(msg.sender).call{ value: _amount }("");
        require(success, "Failed");
    }

    function emergencyRetrieveTokens(address _token, uint _amount) external onlyOwner {
        uint balance = IERC20(_token).balanceOf(address(this));

        if(_amount > balance){
            _amount = balance;
        }

        require(IERC20(_token).transfer(msg.sender, _amount), "Transfer failed");
    }

    function emergencyRetrieveNfts(address _ntfAddress, uint256[] memory _heroIds) external onlyOwner {
        for (uint i = 0; i < _heroIds.length; i++) {
            IEpicHeroNFT(_ntfAddress).safeTransferFrom(address(this), msg.sender, _heroIds[i]);
        }
    }

    function emergencyRetrieveAllNfts(address _ntfAddress) external onlyOwner {
        IEpicHeroNFT nftContract = IEpicHeroNFT(_ntfAddress);

        uint256 balance = nftContract.balanceOf(address(this));
        uint256[] memory heroIds = new uint256[](balance);

        for (uint i = 0; i < balance; i++) {
            heroIds[i] = nftContract.tokenOfOwnerByIndex(address(this), i);
        }

        for (uint i = 0; i < heroIds.length; i++) {
            nftContract.safeTransferFrom(address(this), msg.sender, heroIds[i]);
        }
    }

    function emergencyReturnAllNfts(address _ntfAddress) external onlyOwner {
        IEpicHeroNFT nftContract = IEpicHeroNFT(_ntfAddress);

        uint256 balance = nftContract.balanceOf(address(this));
        uint256[] memory heroIds = new uint256[](balance);

        for (uint i = 0; i < balance; i++) {
            heroIds[i] = nftContract.tokenOfOwnerByIndex(address(this), i);
        }

        for (uint i = 0; i < heroIds.length; i++) {
            NftOwner storage _nftOwner = _heroIdToOwnerAndIndex[heroIds[i]];
            nftContract.safeTransferFrom(address(this), _nftOwner.addr, heroIds[i]);
        }
    }

    function emergencyReturnAllNfts2(address _ntfAddress) external onlyOwner {
        IEpicHeroNFT nftContract = IEpicHeroNFT(_ntfAddress);

        uint256 balance = nftContract.balanceOf(address(this));
        uint256[] memory heroIds = new uint256[](balance);

        for (uint i = 0; i < balance; i++) {
            heroIds[i] = nftContract.tokenOfOwnerByIndex(address(this), i);
        }

        for (uint i = 0; i < heroIds.length; i++) {
            NftOwner storage _nftOwner = _heroIdToOwnerAndIndex2[heroIds[i]];
            nftContract.safeTransferFrom(address(this), _nftOwner.addr, heroIds[i]);
        }
    }

    function updateEmissionRate(uint256 _epicHeroPerBlock) external authorized {
        require(_epicHeroPerBlock <= MAX_EPICHERO_PER_BLOCK, "EPICHERO per block too high");
        massUpdatePools();

        emit EmissionRateUpdated(msg.sender, epicHeroPerBlock, _epicHeroPerBlock);
        epicHeroPerBlock = _epicHeroPerBlock;
    }

    function updateAllocPoint(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external authorized {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function updatePoolPaused(uint256 _pid, bool _paused) external authorized {
        require(poolInfo[_pid].paused != _paused,"Same");
        poolInfo[_pid].paused = _paused;
    }

    function onERC721Received(address, address, uint, bytes calldata) public pure returns (bytes4) {
        return 0x150b7a02;
    }

    event DepositNFT(address indexed user, uint256 indexed pid, uint256[] heroIds);
    event WithdrawNFT(address indexed user, uint256 indexed pid, uint256[] heroIds);
    event JoinPool(address indexed user, uint256 indexed pid);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
}