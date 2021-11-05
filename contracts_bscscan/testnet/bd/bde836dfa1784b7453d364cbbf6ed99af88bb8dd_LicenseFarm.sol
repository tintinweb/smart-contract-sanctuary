// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IMaterials.sol";
import "./ReentrancyGuard.sol";

// standard interface of IERC20 token
// using this in this contract to receive LP tokens or transfer
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

interface ISolvNFT {
    function ownerOf(uint256 tokenId) external view returns (address);

    function isValid(uint256 tokenId) external view returns (bool);
    
    // claimType, term, vestingAmount, principal, maturities, perentages, availableWithdrawAmount, originalInvestor, isValid
    function getSnapshot(uint256 tokenId) external view returns (uint8, uint64, uint256, uint256, 
        uint64[] memory, uint32[] memory, uint256, string memory, bool);
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// for receiving Solv NFT
interface IVNFTReceiver {
    function onVNFTReceived(address operator, address from, uint256 tokenId, 
        uint256 units, bytes calldata data) external returns (bytes4);
}


contract LicenseFarm is Ownable, IVNFTReceiver, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each staked Solv NFT tokenId
    struct TokenInfo {
        address owner;
        uint256 amount;
        uint256 rewardDebt;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 totalPrincipal;   // the last maturity time recorded in Solv NFT
        uint256 allocPoint; // How many allocation points assigned to this pool. Materials to distribute per block.
        uint256 lastRewardBlock; // Last block number that Materials distribution occurs.
        uint256 accMaterialPerShare; // Accumulated Materials per share, times 1e30. See below.
    }

    address private _materials = 0x04898c211e112e558def9f28B22640Ef814f56e6;
    address private _binoToken = 0xf8Ca318db090124E1468CC6c77f69Fd7eb78685a;
    address private _solvNFT = 0xBE07A58bBEC3c73Ecd7Ed44Be97B8B494750D9a3;
    // Material (ERC1155) contract address
    IMaterials public materials;
    // Bino for reward
    IERC20 public binoToken;
    // solvNFT proxy address on bsc mainnet: 0xe5ffDE144592121195d43fdfb3621fc7530c0040
    ISolvNFT public solvNFT;
    // This contract is license Farm, and the license's tokenId = 0
    uint256 public materialId = 0;
    // onVNFTReceived.selector
    bytes4 private constant _VNFT_RECEIVED = 0xb382cdcd;
    // mainnet: 2023.2.1, 1675206000 ;  testnet: 1668816000
    uint256 private constant BINO_REWARD_PID = 1668816000;
    uint256 private constant MAX_PRINCIPAL = 20000000 * 1e18;
    // Dev address.
    address public devaddr;
    // MATERIAL tokens created per block.
    uint256 public materialPerBlock;
    uint256 public binoPerBlock;
    uint256[] public pidList;

    // pid => bool
    mapping(uint256 => bool) private _isPoolValid;
    // pid => PoolInfo
    mapping(uint256 => PoolInfo) public poolInfo;
    // pid => tokenId => TokenInfo
    mapping(uint256 => mapping(uint256 => TokenInfo)) public tokenInfo;
    // pid => tokenId => rewardBinoDebt for pool #1
    mapping(uint256 => mapping(uint256 => uint256)) public rewardBinoDebt;
    uint256 public accBinoPerShare;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when MATERIAL mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 tokenId);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 tokenId);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 tokenId);

    constructor(
        address _devaddr,
        uint256 _materialPerBlock,
        uint256 _binoPerBlock,
        uint256 _startBlock
    ) public {
        devaddr = _devaddr;
        materialPerBlock = _materialPerBlock;     // decimal: 1e0
        binoPerBlock = _binoPerBlock;             // decimal: 1e18
        startBlock = _startBlock;
        
        materials = IMaterials(_materials);
        binoToken = IERC20(_binoToken);
        solvNFT = ISolvNFT(_solvNFT);
    }

    // read solvNFT's principal and last maturity timestamp
    function getVNFTInfo(uint256 tokenId) public view returns (uint256, uint256) {
        require(solvNFT.isValid(tokenId), "this tokenId is not valid");
        uint256 principal;
        uint64[] memory maturities;
        ( , , , principal, maturities, , , , ) = solvNFT.getSnapshot(tokenId);
        uint256 maturity = uint256(maturities[maturities.length - 1]);

        return (principal, maturity);
    }

    function solvNFTOwnerOf(uint256 tokenId) public view returns (address) {
        return solvNFT.ownerOf(tokenId);
    }

    // _pid is the maturity time
    function add(
        uint256 _pid,
        uint256 _allocPoint
    ) public onlyOwner {
        require(!_isPoolValid[_pid], "this pool has already been added");
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo[_pid] =
            PoolInfo({
                totalPrincipal: 0,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accMaterialPerShare: 0
            });
        _isPoolValid[_pid] = true;
        pidList.push(_pid);
    }

    // Update the given pool's MATERIAL allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint
    ) public onlyOwner {
        require(_isPoolValid[_pid], "this pool is not added");
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function massUpdatePools() public {
        uint256 length = pidList.length;
        for(uint256 i = 0; i < length; ++i) {
            updatePool(pidList[i]);
        }
    }

    function poolLength() public view returns(uint256) {
        return pidList.length;
    }

    function isPoolValid(uint256 _pid) public view returns (bool) {
        return _isPoolValid[_pid];
    }

    function availableLimitForBinoRewardPool() public view returns (uint256) {
        PoolInfo storage pool = poolInfo[BINO_REWARD_PID];
        return MAX_PRINCIPAL.sub(pool.totalPrincipal);
    }

    // View function to see pending Materials on frontend.
    function pendingMaterial(uint256 _pid, uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        require(_isPoolValid[_pid], "this pool is not added");
        require(solvNFT.isValid(_tokenId), "this tokenId is not valid on solv");

        PoolInfo storage pool = poolInfo[_pid];
        TokenInfo storage stakedToken = tokenInfo[_pid][_tokenId];
        uint256 accMaterialPerShare = pool.accMaterialPerShare;
        uint256 totalPrincipal = pool.totalPrincipal;   // 1e18
        if (block.number > pool.lastRewardBlock && totalPrincipal != 0) {
            uint256 materialReward =(block.number.sub(pool.lastRewardBlock))
                    .mul(materialPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accMaterialPerShare = accMaterialPerShare.add(
                materialReward.mul(1e30).div(totalPrincipal)
            );
        }
        return stakedToken.amount.mul(accMaterialPerShare).div(1e30).sub(stakedToken.rewardDebt);
    }

    // only for the bino reward pool
    function pendingBinoReward(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        require(solvNFT.isValid(_tokenId), "this tokenId is not valid on solv");

        PoolInfo storage pool = poolInfo[BINO_REWARD_PID];
        TokenInfo storage stakedToken = tokenInfo[BINO_REWARD_PID][_tokenId];

        uint256 tempAccBinoPerShare = accBinoPerShare;
        uint256 totalPrincipal = pool.totalPrincipal;   // 1e18
        if (block.number > pool.lastRewardBlock && totalPrincipal != 0) {
            uint256 binoReward =(block.number.sub(pool.lastRewardBlock)).mul(binoPerBlock);
            tempAccBinoPerShare = tempAccBinoPerShare.add(binoReward.mul(1e12).div(totalPrincipal));
        }
        return stakedToken.amount.mul(tempAccBinoPerShare).div(1e12).sub(rewardBinoDebt[BINO_REWARD_PID][_tokenId]);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        require(_isPoolValid[_pid], "this pool is not added");
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 totalPrincipal = pool.totalPrincipal;   // 1e18
        if (totalPrincipal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 materialReward =(block.number.sub(pool.lastRewardBlock))
                .mul(materialPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            
        pool.accMaterialPerShare = pool.accMaterialPerShare.add(
            materialReward.mul(1e30).div(totalPrincipal)
        );

        if(_pid == BINO_REWARD_PID) {
            uint256 binoReward = (block.number.sub(pool.lastRewardBlock)).mul(binoPerBlock);
            accBinoPerShare = accBinoPerShare.add(binoReward.mul(1e12).div(totalPrincipal));
        }

        pool.lastRewardBlock = block.number;
    }

    // solvNFT proxy contract must approve this contract as the operator
    function deposit(uint256 _pid, uint256 _tokenId) public nonReentrant {
        require(_isPoolValid[_pid], "this pool is not added");
        require(msg.sender == solvNFT.ownerOf(_tokenId), "you are not the owner of this tokenId");
        require(solvNFT.isValid(_tokenId), "this tokenId is not valid on solv");
        // read info from solv contract
        (uint256 principal, uint256 maturity) = getVNFTInfo(_tokenId);
        require(maturity == _pid, "this maturity solv can not deposit into this pool");

        PoolInfo storage pool = poolInfo[_pid];
        TokenInfo storage stakedToken = tokenInfo[_pid][_tokenId];
        // additional requirement for BINO_REWARD_PID
        if(_pid == BINO_REWARD_PID) {
            require(pool.totalPrincipal <= MAX_PRINCIPAL, "exceed total staked 20m BINO valued solv");
            require(pool.totalPrincipal.add(principal) <= MAX_PRINCIPAL, "exceed total staked 20m BINO valued solv");
        }

        updatePool(_pid);
        // stake
        solvNFT.safeTransferFrom(address(msg.sender), address(this), _tokenId);

        pool.totalPrincipal = pool.totalPrincipal.add(principal);
        stakedToken.owner = msg.sender;
        stakedToken.amount = principal;
        stakedToken.rewardDebt = stakedToken.amount.mul(pool.accMaterialPerShare).div(1e30);
        if(_pid == BINO_REWARD_PID) {
            rewardBinoDebt[BINO_REWARD_PID][_tokenId] = stakedToken.amount.mul(accBinoPerShare).div(1e12);
        }

        emit Deposit(msg.sender, _pid, _tokenId);
    }

    // this contract must be assigned as MinterRole for the Material contract
    // Admin MUST deposit enough Bino Token as reward for pid#1 users
    function withdraw(uint256 _pid, uint256 _tokenId) public nonReentrant {
        require(_isPoolValid[_pid], "this pool is not added");
        require(solvNFT.isValid(_tokenId), "this tokenId is not valid on solv");
        PoolInfo storage pool = poolInfo[_pid];
        TokenInfo storage stakedToken = tokenInfo[_pid][_tokenId];
        address theOwner = stakedToken.owner;
        require(msg.sender == theOwner, "you are not the original owner of this solv NFT");
        updatePool(_pid);

        uint256 pending =
            stakedToken.amount.mul(pool.accMaterialPerShare).div(1e30).sub(
                stakedToken.rewardDebt
            );
        materials.mint(msg.sender, materialId, pending, "license minted");
        if(_pid == BINO_REWARD_PID) {
            uint256 pendingBino = stakedToken.amount.mul(accBinoPerShare).div(1e12).sub(
                rewardBinoDebt[BINO_REWARD_PID][_tokenId]);
            require(binoToken.balanceOf(address(this)) >= pendingBino, "not enough Bino balance in this contract");
            binoToken.safeTransfer(msg.sender, pendingBino);
        }
        pool.totalPrincipal = pool.totalPrincipal.sub(stakedToken.amount);
        stakedToken.amount = 0;
        stakedToken.rewardDebt = 0;

        solvNFT.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit Withdraw(msg.sender, _pid, _tokenId);
    }

    function emergencyWithdraw(uint256 _pid, uint256 _tokenId) public {
        require(_isPoolValid[_pid], "this pool is not added");
        TokenInfo storage stakedToken = tokenInfo[_pid][_tokenId];
        address theOwner = stakedToken.owner;
        require(msg.sender == theOwner, "you are not the original owner of this solv NFT");

        stakedToken.amount = 0;
        stakedToken.rewardDebt = 0;
        solvNFT.safeTransferFrom(address(this), msg.sender, _tokenId);
        
        emit EmergencyWithdraw(msg.sender, _pid, _tokenId);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function withdrawRemainingBino(address account, uint256 amount) public onlyOwner {
        require(amount <= binoToken.balanceOf(address(this)), "withdraw amount > bino balance in this contract");
        binoToken.safeTransfer(account, amount);
    }

    function onVNFTReceived(address, address, uint256, uint256, bytes memory) public override returns (bytes4) {
        return _VNFT_RECEIVED;
    }
}