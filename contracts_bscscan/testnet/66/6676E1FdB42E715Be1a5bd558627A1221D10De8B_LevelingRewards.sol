// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./StarlinkComponent.sol";
import "./ITaxFreeTransfers.sol";
import "./ILeveling.sol";
import "./ILevelingRewards.sol";

contract LevelingRewards is ILevelingRewards, StarlinkComponent {
    ITaxFreeTransfers public taxFreeTransfers;
    ILeveling public leveling;
    uint256 public tetTokensPerLevel = 133709 * 10**9;

    mapping(address => mapping(uint256 => uint256)) public rewardDatesPerLevel;
  
    event LevelRewardClaimed(address user, uint256 level);

	constructor(IXLD xld, IStarlinkEngine engine, ITaxFreeTransfers _taxFreeTransfers, ILeveling _leveling) StarlinkComponent(xld, engine) {
        setTaxFreeTransfers(_taxFreeTransfers);
        setLeveling(_leveling);
	}

    function claimRewards(uint256 level) external override notPaused nonReentrant notUnauthorizedContract process {
        uint256 currentLevel = leveling.levelOf(msg.sender);
        require(currentLevel > 0 && level <= currentLevel, "LevelingRewards: Cannot claim yet");
        require(rewardDatesPerLevel[msg.sender][level] == 0, "LevelingRewards: Already claimed");

        doClaimRewards(msg.sender, level);
    }

    function claimRewards(address user, uint256 level) external override onlyAdmins {
        doClaimRewards(user, level);
    }

    function doClaimRewards(address user, uint256 level) private {
        rewardDatesPerLevel[user][level] = block.timestamp;

        if (level == 9 || level == 21 || level % 31 == 0) {
            taxFreeTransfers.increaseTaxFreeTransferVouchers(user, 1);
        }

        if (level == 20 || level % 41 == 0) {
            leveling.increaseNameChangeVouchers(user, 1);
        }

        if (level == 1 || level % 2 == 0) {
            leveling.grantRestXp(user, (120 + 67 * level + 83 * (level / 7)) * 10**9);
        }

        if (level == 7 || level == 20 || (level > 20 && level % 2 == 0) || level == 1337) {
            if (tetTokensPerLevel > 0) {
                taxFreeTransfers.increaseTaxExemptionTokens(user, level * tetTokensPerLevel);
            }
        }

        emit LevelRewardClaimed(user, level);
    }

    function setTetTokensPerLevel(uint256 amount) external onlyOwner {
        tetTokensPerLevel = amount;
    }

    function setTaxFreeTransfers(ITaxFreeTransfers _taxFreeTransfers) public onlyAdmins {
        require(address(_taxFreeTransfers) != address(0), "LevelingRewards: Invalid address");
        taxFreeTransfers = _taxFreeTransfers;
    }

    function setLeveling(ILeveling _leveling) public onlyAdmins {
        require(address(_leveling) != address(0), "LevelingRewards: Invalid address");
        leveling = _leveling;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./base/token/BEP20/IXLD.sol";
import "./IStarlink.sol";
import "./IStarlinkEngine.sol";
import "./base/access/AccessControlled.sol";
import "./base/token/BEP20/EmergencyWithdrawable.sol";

contract StarlinkComponent is AccessControlled, EmergencyWithdrawable {
    IXLD public xld;
    IStarlinkEngine public engine;
    uint256 processGas = 200000;

    modifier process() {
        if (processGas > 0) {
            engine.addGas(processGas);
        }
        
        _;
    }

    constructor(IXLD _xld, IStarlinkEngine _engine) {
        require(address(_xld) != address(0), "StarlinkComponent: Invalid address");
       
        xld = _xld;
        setEngine(_engine);
    }

    function setProcessGas(uint256 gas) external onlyOwner {
        processGas = gas;
    }

    function setEngine(IStarlinkEngine _engine) public onlyOwner {
        require(address(_engine) != address(0), "StarlinkComponent: Invalid address");

        engine = _engine;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface ITaxFreeTransfers {
    function taxFreeTransfer(address source, address destination, uint256 amount) external;

    function increaseTaxFreeTransferVouchers(address userAddress, uint256 amount) external;

    function decreaseTaxFreeTransferVouchers(address userAddress, uint256 amount) external;

    function increaseTaxExemptionTokens(address userAddress, uint256 amount) external;

    function decreaseTaxExemptionTokens(address userAddress, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ILeveling {

    function grantStarlinkPoints(address userAddress, uint256 amount) external;

    function spendStarlinkPoints(address userAddress, uint256 amount) external;

    function levelUp(address userAddress) external;

    function changeName(address userAddress, bytes32 newName) external;

    function grantXp(address userAddress, uint256 amount, uint256 reasonId) external;
    
    function activateXpBoost(address userAddress, uint8 rate, uint256 duration) external;

    function deactivateXpBoost(address userAddress) external;

    function grantRestXp(address userAddress, uint256 amount) external;

    function spendRestXp(address userAddress, uint256 amount) external;

    function currentXpOf(address userAddress) external view returns(uint256); 

    function xpOfLevel(uint256 level) external pure returns (uint256);

    function levelOf(address userAddress) external view returns(uint256);

    function starlinkPointsPrecision() external pure returns(uint256);

    function setNameChangeVouchers(address userAddress, uint8 amount) external;

    function increaseNameChangeVouchers(address userAddress, uint8 amount) external;

    function decreaseNameChangeVouchers(address userAddress, uint8 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ILevelingRewards {
    function claimRewards(uint256 level) external;

    function claimRewards(address user, uint256 level) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IBEP20.sol";

interface IXLD is IBEP20 {
   	function processRewardClaimQueue(uint256 gas) external;

    function calculateRewardCycleExtension(uint256 balance, uint256 amount) external view returns (uint256);

    function claimReward() external;

    function claimReward(address addr) external;

    function isRewardReady(address user) external view returns (bool);

    function isExcludedFromFees(address addr) external view returns(bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function rewardClaimQueueIndex() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStarlink {
   	function processFunds(uint256 gas) external;

	function xldAddress() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStarlinkEngine {
    function addGas(uint256 amount) external;

    function donate() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * @dev Contract module that helps prevent calls to a function.
 */
abstract contract AccessControlled {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    address private _owner;
    bool private _isPaused;
    mapping(address => bool) private _admins;
    mapping(address => bool) private _authorizedContracts;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _status = _NOT_ENTERED;
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        setAdmin(_owner, true);
        setAdmin(address(this), true);
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "AccessControlled: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "AccessControlled: contract not allowed");
        require(msg.sender == tx.origin, "AccessControlled: proxy contract not allowed");
        _;
    }

    modifier notUnauthorizedContract() {
        if (!_authorizedContracts[msg.sender]) {
            require(!_isContract(msg.sender), "AccessControlled: unauthorized contract not allowed");
            require(msg.sender == tx.origin, "AccessControlled: unauthorized proxy contract not allowed");
        }
        _;
    }

    modifier isNotUnauthorizedContract(address addr) {
        if (!_authorizedContracts[addr]) {
            require(!_isContract(addr), "AccessControlled: contract not allowed");
        }
        
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "AccessControlled: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by a non-admin account
     */
    modifier onlyAdmins() {
        require(_admins[msg.sender], "AccessControlled: caller does not have permission");
        _;
    }

    modifier notPaused() {
        require(!_isPaused, "AccessControlled: paused");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function setAdmin(address addr, bool _isAdmin) public onlyOwner {
        _admins[addr] = _isAdmin;
    }

    function isAdmin(address addr) public view returns(bool) {
        return _admins[addr];
    }

    function setAuthorizedContract(address addr, bool isAuthorized) public onlyOwner {
        _authorizedContracts[addr] = isAuthorized;
    }

    function pause() public onlyOwner {
        _isPaused = true;
    }

    function unpause() public onlyOwner {
        _isPaused = false;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../../../base/access/AccessControlled.sol";
import "./IBEP20.sol";

abstract contract EmergencyWithdrawable is AccessControlled {
    /**
     * @notice Withdraw unexpected tokens sent to the contract
     */
    function withdrawStuckTokens(address token) external onlyOwner {
        uint256 amount = IBEP20(token).balanceOf(address(this));
        IBEP20(token).transfer(msg.sender, amount);
    }
    
    /**
     * @notice Withdraws funds of the contract - only for emergencies
     */
    function emergencyWithdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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

