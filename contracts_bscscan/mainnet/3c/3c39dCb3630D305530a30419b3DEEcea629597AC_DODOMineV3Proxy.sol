/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/intf/IDODOApprove.sol

interface IDODOApprove {
    function claimTokens(address token,address who,address dest,uint256 amount) external;
    function getDODOProxy() external view returns (address);
}

// File: contracts/SmartRoute/DODOApproveProxy.sol


interface IDODOApproveProxy {
    function isAllowedProxy(address _proxy) external view returns (bool);
    function claimTokens(address token,address who,address dest,uint256 amount) external;
}

/**
 * @title DODOApproveProxy
 * @author DODO Breeder
 *
 * @notice Allow different version dodoproxy to claim from DODOApprove
 */
contract DODOApproveProxy is InitializableOwnable {
    
    // ============ Storage ============
    uint256 private constant _TIMELOCK_DURATION_ = 3 days;
    mapping (address => bool) public _IS_ALLOWED_PROXY_;
    uint256 public _TIMELOCK_;
    address public _PENDING_ADD_DODO_PROXY_;
    address public immutable _DODO_APPROVE_;

    // ============ Modifiers ============
    modifier notLocked() {
        require(
            _TIMELOCK_ <= block.timestamp,
            "SetProxy is timelocked"
        );
        _;
    }

    constructor(address dodoApporve) public {
        _DODO_APPROVE_ = dodoApporve;
    }

    function init(address owner, address[] memory proxies) external {
        initOwner(owner);
        for(uint i = 0; i < proxies.length; i++) 
            _IS_ALLOWED_PROXY_[proxies[i]] = true;
    }

    function unlockAddProxy(address newDodoProxy) public onlyOwner {
        _TIMELOCK_ = block.timestamp + _TIMELOCK_DURATION_;
        _PENDING_ADD_DODO_PROXY_ = newDodoProxy;
    }

    function lockAddProxy() public onlyOwner {
       _PENDING_ADD_DODO_PROXY_ = address(0);
       _TIMELOCK_ = 0;
    }


    function addDODOProxy() external onlyOwner notLocked() {
        _IS_ALLOWED_PROXY_[_PENDING_ADD_DODO_PROXY_] = true;
        lockAddProxy();
    }

    function removeDODOProxy (address oldDodoProxy) public onlyOwner {
        _IS_ALLOWED_PROXY_[oldDodoProxy] = false;
    }
    
    function claimTokens(
        address token,
        address who,
        address dest,
        uint256 amount
    ) external {
        require(_IS_ALLOWED_PROXY_[msg.sender], "DODOApproveProxy:Access restricted");
        IDODOApprove(_DODO_APPROVE_).claimTokens(
            token,
            who,
            dest,
            amount
        );
    }

    function isAllowedProxy(address _proxy) external view returns (bool) {
        return _IS_ALLOWED_PROXY_[_proxy];
    }
}

// File: contracts/lib/Ownable.sol

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/intf/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/lib/SafeMath.sol

/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/SafeERC20.sol



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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/DODOToken/DODOMineV3/RewardVault.sol


interface IRewardVault {
    function reward(address to, uint256 amount) external;
    function withdrawLeftOver(address to, uint256 amount) external; 
    function syncValue() external;
    function _TOTAL_REWARD_() external view returns(uint256);
}

contract RewardVault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public _REWARD_RESERVE_;
    uint256 public _TOTAL_REWARD_;
    address public _REWARD_TOKEN_;

    // ============ Event =============
    event DepositReward(uint256 totalReward, uint256 inputReward, uint256 rewardReserve);

    constructor(address _rewardToken) public {
        _REWARD_TOKEN_ = _rewardToken;
    }

    function reward(address to, uint256 amount) external onlyOwner {
        require(_REWARD_RESERVE_ >= amount, "VAULT_NOT_ENOUGH");
        _REWARD_RESERVE_ = _REWARD_RESERVE_.sub(amount);
        IERC20(_REWARD_TOKEN_).safeTransfer(to, amount);
    }

    function withdrawLeftOver(address to,uint256 amount) external onlyOwner {
        require(_REWARD_RESERVE_ >= amount, "VAULT_NOT_ENOUGH");
        _REWARD_RESERVE_ = _REWARD_RESERVE_.sub(amount);
        IERC20(_REWARD_TOKEN_).safeTransfer(to, amount);
    }

    function syncValue() external {
        uint256 rewardBalance = IERC20(_REWARD_TOKEN_).balanceOf(address(this));
        uint256 rewardInput = rewardBalance.sub(_REWARD_RESERVE_);

        _TOTAL_REWARD_ = _TOTAL_REWARD_.add(rewardInput);
        _REWARD_RESERVE_ = rewardBalance;

        emit DepositReward(_TOTAL_REWARD_, rewardInput, _REWARD_RESERVE_);
    }
}

// File: contracts/Factory/Registries/DODOMineV3Registry.sol


interface IDODOMineV3Registry {
    function addMineV3(
        address mine,
        bool isLpToken,
        address stakeToken
    ) external;
}

/**
 * @title DODOMineV3 Registry
 * @author DODO Breeder
 *
 * @notice Register DODOMineV3 Pools 
 */
contract DODOMineV3Registry is InitializableOwnable, IDODOMineV3Registry {

    mapping (address => bool) public isAdminListed;
    
    // ============ Registry ============
    // minePool -> stakeToken
    mapping(address => address) public _MINE_REGISTRY_;
    // lpToken -> minePool
    mapping(address => address[]) public _LP_REGISTRY_;
    // singleToken -> minePool
    mapping(address => address[]) public _SINGLE_REGISTRY_;


    // ============ Events ============
    event NewMineV3(address mine, address stakeToken, bool isLpToken);
    event RemoveMineV3(address mine, address stakeToken);
    event addAdmin(address admin);
    event removeAdmin(address admin);


    function addMineV3(
        address mine,
        bool isLpToken,
        address stakeToken
    ) override external {
        require(isAdminListed[msg.sender], "ACCESS_DENIED");
        _MINE_REGISTRY_[mine] = stakeToken;
        if(isLpToken) {
            _LP_REGISTRY_[stakeToken].push(mine);
        }else {
            _SINGLE_REGISTRY_[stakeToken].push(mine);
        }

        emit NewMineV3(mine, stakeToken, isLpToken);
    }

    // ============ Admin Operation Functions ============

    function removeMineV3(
        address mine,
        bool isLpToken,
        address stakeToken
    ) external onlyOwner {
        _MINE_REGISTRY_[mine] = address(0);
        if(isLpToken) {
            uint256 len = _LP_REGISTRY_[stakeToken].length;
            for (uint256 i = 0; i < len; i++) {
                if (mine == _LP_REGISTRY_[stakeToken][i]) {
                    if(i != len - 1) {
                        _LP_REGISTRY_[stakeToken][i] = _LP_REGISTRY_[stakeToken][len - 1];
                    }
                    _LP_REGISTRY_[stakeToken].pop();
                    break;
                }
            }
        }else {
            uint256 len = _SINGLE_REGISTRY_[stakeToken].length;
            for (uint256 i = 0; i < len; i++) {
                if (mine == _SINGLE_REGISTRY_[stakeToken][i]) {
                    if(i != len - 1) {
                        _SINGLE_REGISTRY_[stakeToken][i] = _SINGLE_REGISTRY_[stakeToken][len - 1];
                    }
                    _SINGLE_REGISTRY_[stakeToken].pop();
                    break;
                }
            }
        }

        emit RemoveMineV3(mine, stakeToken);
    }

    function addAdminList (address contractAddr) external onlyOwner {
        isAdminListed[contractAddr] = true;
        emit addAdmin(contractAddr);
    }

    function removeAdminList (address contractAddr) external onlyOwner {
        isAdminListed[contractAddr] = false;
        emit removeAdmin(contractAddr);
    }
}

// File: contracts/lib/CloneFactory.sol

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract CloneFactory is ICloneFactory {
    function clone(address prototype) external override returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}

// File: contracts/SmartRoute/proxies/DODOMineV3Proxy.sol

interface IMineV3 {
    function init(address owner, address token) external;

    function addRewardToken(
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 endBlock
    ) external;

    function directTransferOwnership(address newOwner) external;

    function getVaultByRewardToken(address rewardToken) external view returns(address);
}

/**
 * @title DODOMineV3 Proxy
 * @author DODO Breeder
 *
 * @notice Create And Register DODOMineV3 Contracts 
 */
contract DODOMineV3Proxy is InitializableOwnable {
    using SafeMath for uint256;
    // ============ Templates ============

    address public immutable _CLONE_FACTORY_;
    address public immutable _DODO_APPROVE_PROXY_;
    address public immutable _DODO_MINEV3_REGISTRY_;
    address public _MINEV3_TEMPLATE_;


    // ============ Events ============
    event DepositRewardToVault(address mine, address rewardToken, uint256 amount);
    event DepositRewardToMine(address mine, address rewardToken, uint256 amount);
    event CreateMineV3(address account, address mineV3);
    event ChangeMineV3Template(address mineV3);

    constructor(
        address cloneFactory,
        address mineTemplate,
        address dodoApproveProxy,
        address dodoMineV3Registry
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _MINEV3_TEMPLATE_ = mineTemplate;
        _DODO_APPROVE_PROXY_ = dodoApproveProxy;
        _DODO_MINEV3_REGISTRY_ = dodoMineV3Registry;
    }

    // ============ Functions ============

    function createDODOMineV3(
        address stakeToken,
        bool isLpToken,
        address[] memory rewardTokens,
        uint256[] memory rewardPerBlock,
        uint256[] memory startBlock,
        uint256[] memory endBlock
    ) external returns (address newMineV3) {
        require(rewardTokens.length > 0, "REWARD_EMPTY");
        require(rewardTokens.length == rewardPerBlock.length, "REWARD_PARAM_NOT_MATCH");
        require(startBlock.length == rewardPerBlock.length, "REWARD_PARAM_NOT_MATCH");
        require(endBlock.length == rewardPerBlock.length, "REWARD_PARAM_NOT_MATCH");

        newMineV3 = ICloneFactory(_CLONE_FACTORY_).clone(_MINEV3_TEMPLATE_);

        IMineV3(newMineV3).init(address(this), stakeToken);

        for(uint i = 0; i<rewardTokens.length; i++) {
            uint256 rewardAmount = rewardPerBlock[i].mul(endBlock[i].sub(startBlock[i]));
            IDODOApproveProxy(_DODO_APPROVE_PROXY_).claimTokens(rewardTokens[i], msg.sender, newMineV3, rewardAmount);
            IMineV3(newMineV3).addRewardToken(
                rewardTokens[i],
                rewardPerBlock[i],
                startBlock[i],
                endBlock[i]
            );
        }

        IMineV3(newMineV3).directTransferOwnership(msg.sender);

        IDODOMineV3Registry(_DODO_MINEV3_REGISTRY_).addMineV3(newMineV3, isLpToken, stakeToken);

        emit CreateMineV3(msg.sender, newMineV3);
    }

    function depositRewardToVault(
        address mineV3,
        address rewardToken,
        uint256 amount
    ) external {    
        address rewardVault = IMineV3(mineV3).getVaultByRewardToken(rewardToken);
        IDODOApproveProxy(_DODO_APPROVE_PROXY_).claimTokens(rewardToken, msg.sender, rewardVault, amount);
        IRewardVault(rewardVault).syncValue();

        emit DepositRewardToVault(mineV3,rewardToken,amount);
    }

    function depositRewardToMine(
        address mineV3,
        address rewardToken,
        uint256 amount
    ) external {
        require(mineV3 != address(0), "MINE_EMPTY");
        IDODOApproveProxy(_DODO_APPROVE_PROXY_).claimTokens(rewardToken, msg.sender, mineV3, amount);

        emit DepositRewardToMine(mineV3,rewardToken,amount);
    }

    // ============ Admin Operation Functions ============
    
    function updateMineV3Template(address _newMineV3Template) external onlyOwner {
        _MINEV3_TEMPLATE_ = _newMineV3Template;
        emit ChangeMineV3Template(_newMineV3Template);
    }
}