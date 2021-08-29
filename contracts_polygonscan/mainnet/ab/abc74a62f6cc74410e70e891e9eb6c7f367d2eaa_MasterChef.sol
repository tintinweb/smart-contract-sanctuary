// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./PolygalaxyToken.sol"; 

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal { 
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

// 
/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// 
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     * 
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account. 
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// For interacting with our own strategy
interface IStrategy {
    // Want address
    function wantAddress() external view returns (address);
    
    // Total want tokens managed by strategy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(uint256 _wantAmt) external returns (uint256);

    // Transfer want tokens strategy -> vaultChef
    function withdraw(uint256 _wantAmt) external returns (uint256);
}

// 
// MasterChef is the master of GALAXY. He can make GALAXY and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once GALAXY is sufficiently
// distributed and the community can show to govern itself.
//
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of GALAXYs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGalaxyPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGalaxyPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        address strat;              // Strategy address that will auto compound lpToken tokens
        uint256 allocPoint;         // How many allocation points assigned to this pool. GALAXYs to distribute per block.
        uint256 lastRewardBlock;    // Last block number that GALAXYs distribution occurs.
        uint256 accGalaxyPerShare;  // Accumulated GALAXYs per share, times 1e12. See below.
        uint16 depositFeeBP;        // Deposit fee in basis points
        uint256 lpBalance;           // Balance of LP token contract.
    }

    // NFT GALAXY 
    IERC721 public galaxyNFT;
    // The GALAXYs TOKEN!
    Polygalaxy public galaxy;
    // Dev address.
    address public devAddress;
    // GALAXYs tokens created per block.
    uint256 public galaxyPerBlock;
    // Bonus muliplier for early Galaxy makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress; 
    bool public galaxyNFTEnable;
    uint16 public constant MAXIMUM_NFT_BURN_RATE = 3000;
    uint256 public burnNFTRate = 1200;
    uint256 public maxNFTBurn = 12;
    // Burn address
    address private constant BURN = 0x000000000000000000000000000000000000dEaD;
    
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping(address => bool) private strats;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when GALAXYs mining starts.
    uint256 public startBlock;
    
    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }
    
    event AddPool(address indexed strat);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        Polygalaxy _galaxy,
        address _devaddr,
        address _feeAddress,
        uint256 _galaxyPerBlock
    ) public {
        galaxy = _galaxy;
        devAddress = _devaddr;
        feeAddress = _feeAddress;
        galaxyPerBlock = _galaxyPerBlock;
        startBlock = block.number + 3*30*60*24;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(uint256 _allocPoint, IERC20 _lpToken, address _strat, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner nonDuplicated(_lpToken) {
        require(!strats[_strat], "Existing strategy");
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            lpBalance: 0,
            strat: _strat,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accGalaxyPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
        if(_strat != address(0)) { 
            strats[_strat] = true; 
            resetSingleAllowance(poolInfo.length.sub(1)); 
            emit AddPool(_strat);
        }
    }

    // Update the given pool's GALAXYs allocation point and deposit fee. Can only be called by the owner.
    function setPool(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending GALAXYs on frontend.
    function pendingGalaxy(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGalaxyPerShare = pool.accGalaxyPerShare;
        uint256 lpSupply = pool.strat != address(0) ? pool.lpBalance : pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 galaxyReward = multiplier.mul(galaxyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accGalaxyPerShare = accGalaxyPerShare.add(galaxyReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accGalaxyPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.strat != address(0) ? pool.lpBalance : pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 galaxyReward = multiplier.mul(galaxyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        galaxy.mint(devAddress, galaxyReward.div(10));
        galaxy.mint(address(this), galaxyReward);
        pool.accGalaxyPerShare = pool.accGalaxyPerShare.add(galaxyReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for Galaxy allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        _deposit(_pid, _amount, msg.sender);
    }
    
    function _deposit(uint256 _pid, uint256 _amount, address _to) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];
        updatePool(_pid);
        
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accGalaxyPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                if (!galaxyNFTEnable) {
                    safeGalaxyTransfer(_to, pending);
                } else {
                    safeGalaxyNFTTransfer(_to, pending);
                }
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 depositAmount = _amount;
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                depositAmount = _amount.sub(depositFee);
            }
            if(pool.strat != address(0)) {
                IStrategy(pool.strat).deposit(depositAmount);
                pool.lpBalance = pool.lpBalance.add(depositAmount); 
            } 
            user.amount = user.amount.add(depositAmount);
        }
        user.rewardDebt = user.amount.mul(pool.accGalaxyPerShare).div(1e12);
        emit Deposit(_to, _pid, _amount);
    }
    
    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        _withdraw(_pid, _amount, msg.sender);
    }
    
    function _withdraw(uint256 _pid, uint256 _amount, address _to) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        
        uint256 pending = user.amount.mul(pool.accGalaxyPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            if (!galaxyNFTEnable) {
                safeGalaxyTransfer(_to, pending);
            } else {
                safeGalaxyNFTTransfer(_to, pending);
            }
        }
        if(_amount > 0) {
            if(pool.strat != address(0)) {
                uint256 wantLockedTotal = IStrategy(pool.strat).wantLockedTotal();
                uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
                require(sharesTotal > 0, "sharesTotal is 0");
                // Withdraw want tokens
                uint256 amount = user.amount.mul(wantLockedTotal).div(sharesTotal);
                if (_amount > amount) {
                    _amount = amount;
                }
                if (_amount > 0) {
                    IStrategy(pool.strat).withdraw(_amount);
                }
            }
            uint256 wantBal = IERC20(pool.lpToken).balanceOf(address(this));
            if (wantBal < _amount) {
                _amount = wantBal;
            }
            pool.lpBalance = pool.strat != address(0) ? pool.lpBalance.sub(_amount) : 0; 
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(_to, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accGalaxyPerShare).div(1e12); 
        emit Withdraw(_to, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount > 0) {
            uint256 amount = user.amount;
            if(pool.strat != address(0)) {
                uint256 wantBefore = IERC20(pool.lpToken).balanceOf(address(this));
                IStrategy(pool.strat).withdraw(amount);
                uint256 wantAffter = IERC20(pool.lpToken).balanceOf(address(this));
                amount = wantAffter>wantBefore ? wantAffter.sub(wantBefore) : 0;
                pool.lpBalance = pool.lpBalance.sub(amount);
            }
            user.amount = 0;
            user.rewardDebt = 0;
            pool.lpToken.safeTransfer(address(msg.sender), amount);
            emit EmergencyWithdraw(msg.sender, _pid, amount);
        }
    }
    
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount >= _amount && _amount > 0) {
            uint256 amount = _amount;
            if(pool.strat != address(0)) {
                uint256 wantBefore = IERC20(pool.lpToken).balanceOf(address(this));
                IStrategy(pool.strat).withdraw(amount); 
                uint256 wantAffter = IERC20(pool.lpToken).balanceOf(address(this));
                amount = wantAffter>wantBefore ? wantAffter.sub(wantBefore) : 0;
                pool.lpBalance = pool.lpBalance.sub(amount);
            }
            user.amount = user.amount.sub(amount);
            user.rewardDebt = user.amount.mul(pool.accGalaxyPerShare).div(1e12);
            pool.lpToken.safeTransfer(address(msg.sender), amount);
            emit EmergencyWithdraw(msg.sender, _pid, amount);
        }
    }
    
    // Safe Galaxy transfer function, just in case if rounding error causes pool to not have enough Galaxys.
    function safeGalaxyTransfer(address _to, uint256 _amount) internal {
        uint256 galaxyBal = galaxy.balanceOf(address(this));
        if (_amount > galaxyBal) {
            galaxy.transfer(_to, galaxyBal);
        } else if(_amount > 0) {
            galaxy.transfer(_to, _amount);
        }
    }
    
    // Safe Galaxy transfer function, just in case if rounding error causes pool to not have enough Galaxys.
    function safeGalaxyNFTTransfer(address _to, uint256 pending) internal {
        if (galaxyNFT.balanceOf(_to) == 0) {
            uint256 burnAmount = pending.mul(burnNFTRate).div(10000);
            safeGalaxyTransfer(_to, pending.sub(burnAmount));
            safeGalaxyTransfer(BURN, burnAmount);
        } else {
            uint256 balanceNFT = galaxyNFT.balanceOf(_to);
            uint256 _burnNFTRate = balanceNFT >= maxNFTBurn ? 0 : burnNFTRate.sub(balanceNFT.mul(100));
            uint256 burnAmount = pending.mul(_burnNFTRate).div(10000);
            safeGalaxyTransfer(_to, pending.sub(burnAmount));
            safeGalaxyTransfer(BURN, burnAmount);
        }
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devaddr) external {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        devAddress = _devaddr;
    }

    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _galaxyPerBlock) external onlyOwner {
        massUpdatePools();
        galaxyPerBlock = _galaxyPerBlock;
    }
    
    // Only update before start of farm
    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        require(block.number < startBlock, "updateStartBlock: expired!");
        startBlock = _startBlock;
    }
    
    function setGalaxyNFT(address _galaxyNFT) external onlyOperator {
        require(_galaxyNFT != address(0), "");
        galaxyNFT = IERC721(_galaxyNFT);
    }
    
    function setGalaxyNFTSetting(uint256 _burnNFTRate, uint8 _maxNFTBurn) external onlyOperator {
        require(_burnNFTRate <= MAXIMUM_NFT_BURN_RATE, "ERROR::setGalaxyNFTSetting: invalid _burnNFTRate");
        require(_maxNFTBurn <= 30, "ERROR::setGalaxyNFTSetting: invalid _maxNFTBurn");
        burnNFTRate = _burnNFTRate;
        maxNFTBurn = _maxNFTBurn;
    }
    
    function setGalaxyNFTEnable(bool _enabled) external onlyOperator {
        galaxyNFTEnable = _enabled;
    }
    
     function resetAllowances() external onlyOperator {
        for (uint256 i=0; i<poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            if (pool.strat != address(0)) {
                pool.lpToken.safeApprove(pool.strat, uint256(0));
                pool.lpToken.safeIncreaseAllowance(pool.strat, uint256(-1));
            }
        }
    }

    function resetSingleAllowance(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.strat != address(0)) {
            pool.lpToken.safeApprove(pool.strat, uint256(0));
            pool.lpToken.safeIncreaseAllowance(pool.strat, uint256(-1));
        }
    }
    
}