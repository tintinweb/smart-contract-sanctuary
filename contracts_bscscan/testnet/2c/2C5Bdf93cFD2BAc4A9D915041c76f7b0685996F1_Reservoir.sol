pragma solidity ^0.7.5;

import "./libs/SafeMath.sol";
import "./libs/Address.sol";
import "./libs/Ownable.sol";
import "./libs/IERC20.sol";
import "./libs/SafeERC20.sol";

import "./interfaces/IGyro.sol";
import "./interfaces/IGyroBond.sol";

import "./interfaces/IReservoir.sol";

interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

contract Reservoir is IReservoir, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum TARGETS {
        COLLATERAL_TOKEN,
        BOND,
        DEPOSITOR,
        SPENDER,
        DEBTOR,
        COLLATERAL_MANAGER,
        LIQUIDITY_MANAGER,
        REWARD_MANAGER,
        S_GYRO
    }

    event LogDeposit(address indexed token, uint256 amount, uint256 value);
    event LogWithdraw(address indexed token, uint256 amount, uint256 value);
    event LogCreateDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event LogRepayDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event LogManageAssets(address indexed token, uint256 amount);
    event LogUpdateAssets(uint256 indexed totalAssets);
    event LogAuditAssets(uint256 indexed totalAssets);
    event LogMintRewards(address indexed caller, address indexed recipient, uint256 amount);
    event LogQueueChange(TARGETS indexed target, address queued);
    event LogActivateChange(TARGETS indexed target, address activated, bool result);

    address public immutable gyro;
    uint256 public immutable queueLength; // in blocks

    address[] public collateralTokens;
    mapping(address => uint256) public collateralTokenQueue; // Delays changes to mapping.

    address[] public bonds;
    mapping(address => uint256) public bondQueue; // Delays changes to mapping.

    address[] public depositors;
    mapping(address => uint256) public depositorQueue; // Delays changes to mapping.

    address[] public spenders;
    mapping(address => uint256) public spenderQueue; // Delays changes to mapping.

    address[] public debtors;
    mapping(address => uint256) public debtorQueue; // Delays changes to mapping.
    mapping(address => uint256) public debtorBalances;

    address[] public collateralManagers;
    mapping(address => uint256) public collateralManagerQueue; // Delays changes to mapping.

    address[] public liquidityManagers;
    mapping(address => uint256) public liquidityManagerQueue; // Delays changes to mapping.

    address[] public rewardManagers; // rewardManager => token
    mapping(address => uint256) public rewardManagerQueue; // Delays changes to mapping.

    address public sGyro;
    uint256 public sGyroQueue; // Delays change to sGyro address

    uint256 public totalAssets; // Risk-free value of all assets
    uint256 public totalDebt;

    modifier validate(address bond_) {
        require(bond_ != address(0), "Bond undefined");
        require(_listContains(bonds, bond_), "Bond not accepted");
        _;
    }

    modifier isDepositor() {
        require(_listContains(depositors, msg.sender), "Not approved");
        _;
    }

    modifier isSpender() {
        require(_listContains(spenders, msg.sender), "Not approved");
        _;
    }

    modifier isDebtor() {
        require(_listContains(debtors, msg.sender), "Not approved");
        _;
    }

    modifier isRewardManager() {
        require(_listContains(rewardManagers, msg.sender), "Not approved");
        _;
    }

    constructor(
        address gyro_,
        address collateralToken_,
        uint256 queueLength_
    ) {
        require(gyro_ != address(0), "Gyro undefined");
        gyro = gyro_;

        require(collateralToken_ != address(0), "Collateral undefined");
        collateralTokens.push(collateralToken_);

        queueLength = queueLength_;
    }

    /**
        @notice allow approved address to deposit an asset for gyro
        @param amount_ uint
        @param profit_ uint
        @return send_ uint
     */
    function bondDeposit(uint256 amount_, uint256 profit_)
        external
        override
        validate(msg.sender)
        returns (uint256 send_)
    {
        (uint256 value, address token) = IGyroBond(msg.sender).gyroValue(amount_);
        send_ = _deposit(token, amount_, value, profit_);
    }

    /**
        @notice allow approved address to deposit an asset for gyro
        @param token_ token address
        @param amount_ uint
        @param profit_ uint
        @return send_ uint
     */
    function deposit(
        address token_,
        uint256 amount_,
        uint256 profit_
    ) external override isDepositor() returns (uint256 send_) {
        require(!_listContains(bonds, msg.sender), "Bond not accepted");
        require(_listContains(collateralTokens, token_), "Collateral token only");
        uint256 value = _gyroValueOf(token_, amount_);
        send_ = _deposit(token_, amount_, value, profit_);
    }

    function _deposit(
        address token_,
        uint256 amount_,
        uint256 value,
        uint256 profit_
    ) private returns (uint256 send_) {
        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);

        // mint gyro needed and store amount of rewards for distribution
        send_ = value.sub(profit_);
        IERC20Mintable(gyro).mint(msg.sender, send_);

        totalAssets = totalAssets.add(value);
        emit LogUpdateAssets(totalAssets);

        emit LogDeposit(token_, amount_, value);
    }

    /**
        @notice allow approved address to burn gyro for collateral tokens
        @param bond_ address
        @param amount_ uint
     */
    function withdraw(address bond_, uint256 amount_) external isSpender() validate(bond_) {
        (uint256 value, address token) = IGyroBond(bond_).gyroValue(amount_);
        require(_listContains(collateralTokens, token), "Collateral token only");

        IGyro(gyro).burnFrom(msg.sender, value);

        totalAssets = totalAssets.sub(value);
        emit LogUpdateAssets(totalAssets);

        IERC20(token).safeTransfer(msg.sender, amount_);

        emit LogWithdraw(token, amount_, value);
    }

    /**
        @notice allow approved address to borrow collateral tokens
        @param bond_ address
        @param amount_ uint
     */
    function incurDebt(address bond_, uint256 amount_) external isDebtor() validate(bond_) {
        require(sGyro != address(0), "sGyro undefined");

        (uint256 value, address token) = IGyroBond(bond_).gyroValue(amount_);
        require(_listContains(collateralTokens, token), "Collateral token only");

        uint256 maximumDebt = IERC20(sGyro).balanceOf(msg.sender); // Can only borrow against sGyro held
        uint256 availableDebt = maximumDebt.sub(debtorBalances[msg.sender]);
        require(value <= availableDebt, "Exceeds debt limit");

        debtorBalances[msg.sender] = debtorBalances[msg.sender].add(value);
        totalDebt = totalDebt.add(value);

        totalAssets = totalAssets.sub(value);
        emit LogUpdateAssets(totalAssets);

        IERC20(token).safeTransfer(msg.sender, amount_);

        emit LogCreateDebt(msg.sender, token, amount_, value);
    }

    /**
        @notice allow approved address to repay borrowed collaterals with collateral tokens
        @param bond_ address
        @param amount_ uint
     */
    function repayDebtWithCollateral(address bond_, uint256 amount_) external isDebtor() validate(bond_) {
        (uint256 value, address token) = IGyroBond(bond_).gyroValue(amount_);
        require(_listContains(collateralTokens, token), "Collateral token only");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount_);

        debtorBalances[msg.sender] = debtorBalances[msg.sender].sub(value);
        totalDebt = totalDebt.sub(value);

        totalAssets = totalAssets.add(value);
        emit LogUpdateAssets(totalAssets);

        emit LogRepayDebt(msg.sender, token, amount_, value);
    }

    /**
        @notice allow approved address to repay borrowed collaterals with gyro
        @param amount_ uint
     */
    function repayDebtWithGyro(uint256 amount_) external isDebtor() {
        IGyro(gyro).burnFrom(msg.sender, amount_);

        debtorBalances[msg.sender] = debtorBalances[msg.sender].sub(amount_);
        totalDebt = totalDebt.sub(amount_);

        emit LogRepayDebt(msg.sender, gyro, amount_, amount_);
    }

    /**
        @notice allow approved address to withdraw assets
        @param bond_ address
        @param amount_ uint
     */
    function manage(address bond_, uint256 amount_) external validate(bond_) {
        if (IGyroBond(bond_).isLiquidityBond()) {
            require(_listContains(liquidityManagers, msg.sender), "Not approved");
        } else {
            require(_listContains(collateralManagers, msg.sender), "Not approved");
        }

        (uint256 value, address token) = IGyroBond(bond_).gyroValue(amount_);

        require(value <= excessAssets(), "Insufficient assets");

        totalAssets = totalAssets.sub(value);
        emit LogUpdateAssets(totalAssets);

        IERC20(token).safeTransfer(msg.sender, amount_);

        emit LogManageAssets(token, amount_);
    }

    /**
        @notice send epoch reward to staking contract
     */
    function mintRewards(address recipient_, uint256 amount_) external override isRewardManager() returns (uint256) {
        if (amount_ > excessAssets()) {
            // Not enough profit to create rewards
            emit LogMintRewards(msg.sender, recipient_, 0);
            return 0;
        }

        IERC20Mintable(gyro).mint(recipient_, amount_);

        emit LogMintRewards(msg.sender, recipient_, amount_);

        return amount_;
    }

    /**
        @notice returns excess assets not backing tokens
        @return uint
     */
    function excessAssets() public view returns (uint256) {
        uint256 net = IERC20(gyro).totalSupply().sub(totalDebt);
        if (totalAssets <= net) return 0;
        return totalAssets.sub(net);
    }

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized assets before auditing
     */
    function auditAssets() external onlyOwner() {
        uint256 assets;
        uint256 value;
        for (uint256 i = 0; i < bonds.length; i++) {
            IGyroBond bond = IGyroBond(bonds[i]);
            (value, ) = bond.gyroValue(IERC20(bond.tokenIn()).balanceOf(address(this)));
            assets = assets.add(value);
        }

        totalAssets = assets;
        emit LogUpdateAssets(assets);
        emit LogAuditAssets(assets);
    }

    /**
        @notice queue address to change boolean in mapping
        @param target_ TARGETS
        @param address_ address
        @return bool
     */
    function queue(TARGETS target_, address address_) external onlyOwner() returns (bool) {
        require(address_ != address(0));

        if (target_ == TARGETS.COLLATERAL_TOKEN) {
            // 0
            collateralTokenQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.BOND) {
            // 1
            bondQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.DEPOSITOR) {
            // 2
            depositorQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.SPENDER) {
            // 3
            spenderQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.DEBTOR) {
            // 4
            debtorQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.COLLATERAL_MANAGER) {
            // 5
            collateralManagerQueue[address_] = block.number.add(queueLength.mul(2));
        } else if (target_ == TARGETS.LIQUIDITY_MANAGER) {
            // 6
            liquidityManagerQueue[address_] = block.number.add(queueLength.mul(2));
        } else if (target_ == TARGETS.REWARD_MANAGER) {
            // 7
            rewardManagerQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.S_GYRO) {
            // 8
            sGyroQueue = block.number.add(queueLength);
        } else return false;

        emit LogQueueChange(target_, address_);
        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param target_ TARGETS
        @param address_ address
        @return bool
     */
    function toggle(TARGETS target_, address address_) external onlyOwner() returns (bool) {
        require(address_ != address(0), "Target address undefined");
        bool result = false;

        if (target_ == TARGETS.COLLATERAL_TOKEN) {
            // 0
            bool isNewToken = !_listContains(collateralTokens, address_);
            if (_ensureQueued(collateralTokenQueue[address_], isNewToken)) {
                collateralTokenQueue[address_] = 0;
                collateralTokens.push(address_);
                result = true;
            } else {
                _removeFromList(collateralTokens, address_);
            }
        } else if (target_ == TARGETS.BOND) {
            // 1
            bool isNewBond = !_listContains(bonds, address_);
            if (_ensureQueued(bondQueue[address_], isNewBond)) {
                bondQueue[address_] = 0;
                bonds.push(address_);
                result = true;
            } else {
                _removeFromList(bonds, address_);
            }
        } else if (target_ == TARGETS.DEPOSITOR) {
            // 2
            bool isNewDepositor = !_listContains(depositors, address_);

            if (_ensureQueued(depositorQueue[address_], isNewDepositor)) {
                depositorQueue[address_] = 0;
                depositors.push(address_);
                result = true;
            } else {
                _removeFromList(depositors, address_);
            }
        } else if (target_ == TARGETS.SPENDER) {
            // 3
            bool isNewSpender = !_listContains(spenders, address_);

            if (_ensureQueued(spenderQueue[address_], isNewSpender)) {
                spenderQueue[address_] = 0;
                spenders.push(address_);
                result = true;
            } else {
                _removeFromList(spenders, address_);
            }
        } else if (target_ == TARGETS.DEBTOR) {
            // 4
            bool isNewDebtor = !_listContains(debtors, address_);
            if (_ensureQueued(debtorQueue[address_], isNewDebtor)) {
                debtorQueue[address_] = 0;
                debtors.push(address_);
                result = true;
            } else {
                _removeFromList(debtors, address_);
            }
        } else if (target_ == TARGETS.COLLATERAL_MANAGER) {
            // 5
            bool isNewManager = !_listContains(collateralManagers, address_);
            if (_ensureQueued(collateralManagerQueue[address_], isNewManager)) {
                collateralManagerQueue[address_] = 0;
                collateralManagers.push(address_);
                result = true;
            } else {
                _removeFromList(collateralManagers, address_);
            }
        } else if (target_ == TARGETS.LIQUIDITY_MANAGER) {
            // 6
            bool isNewManager = !_listContains(liquidityManagers, address_);
            if (_ensureQueued(liquidityManagerQueue[address_], isNewManager)) {
                liquidityManagerQueue[address_] = 0;
                liquidityManagers.push(address_);
                result = true;
            } else {
                _removeFromList(liquidityManagers, address_);
            }
        } else if (target_ == TARGETS.REWARD_MANAGER) {
            // 7
            bool isNewManager = !_listContains(rewardManagers, address_);

            if (_ensureQueued(rewardManagerQueue[address_], isNewManager)) {
                rewardManagerQueue[address_] = 0;
                rewardManagers.push(address_);
                result = true;
            } else {
                _removeFromList(rewardManagers, address_);
            }
        } else if (target_ == TARGETS.S_GYRO) {
            // 8
            sGyroQueue = 0;
            sGyro = address_;
            result = true;
        } else return false;

        emit LogActivateChange(target_, address_, result);
        return true;
    }

    /**
        @notice checks requirements and returns altered structs
        @param queueLength_ uint
        @param notSet_ bool
        @return bool 
     */
    function _ensureQueued(uint256 queueLength_, bool notSet_) internal view returns (bool) {
        if (notSet_) {
            require(queueLength_ != 0, "Must queue");
            require(queueLength_ <= block.number, "Queue not expired");
            return true;
        }
        return false;
    }

    /**
        @notice checks array to ensure against duplicate
        @param list_ address[]
        @param token_ address
        @return bool
     */
    function _listContains(address[] storage list_, address token_) internal view returns (bool) {
        for (uint256 i = 0; i < list_.length; i++) {
            if (list_[i] == token_) {
                return true;
            }
        }
        return false;
    }

    /**
        @notice remove the element from the list
        @param list_ address[]
        @param el_ address
        @return uint256
     */
    function _removeFromList(address[] storage list_, address el_) internal returns (uint256) {
        uint256 i;
        for (i = 0; i < list_.length; i++) {
            if (list_[i] == el_) {
                list_[i] = list_[list_.length - 1];
                delete list_[list_.length - 1];
                list_.pop();
                break;
            }
        }

        return i;
    }

    /**
        @notice only for collateral tokens
        @param token_ address
        @param amount_ uint
        @return value_ uint256
     */
    function _gyroValueOf(address token_, uint256 amount_) internal view returns (uint256 value_) {
        value_ = amount_.mul(10**IERC20(gyro).decimals()).div(10**IERC20(token_).decimals());
    }
}

pragma solidity ^0.7.5;

interface IGyro {
    function burnFrom(address account_, uint256 amount_) external;

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity ^0.7.5;

interface IGyroBond {
    function deposit(
        uint256 amount_,
        uint256 maxPrice_,
        address depositor_,
        bytes32 referralCode_
    ) external returns (uint256);

    function isLiquidityBond() external view returns (bool);

    function tokenIn() external view returns (address);

    function gyroValue(uint256 amount_) external view returns (uint256 value_, address token_);
}

pragma solidity ^0.7.5;

interface IReservoir {
    function bondDeposit(uint256 amount, uint256 profit) external returns (uint256);

    function deposit(
        address tokenIn,
        uint256 amount,
        uint256 profit
    ) external returns (uint256);

    function mintRewards(address recipient, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     return _functionCallWithValue(target, data, value, errorMessage);
    // }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        // solhint-disable-next-line var-name-mixedcase
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = "0";
        _addr[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IOwnable.sol";

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
contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner() {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner_) public virtual override onlyOwner() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";
import "./SafeMath.sol";
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
    using SafeMath for uint256;
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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

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

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    /*
     * Expects percentage to be trailed by 00,
     */
    function percentageAmount(uint256 total_, uint8 percentage_) internal pure returns (uint256 percentAmount_) {
        return div(mul(total_, percentage_), 1000);
    }

    /*
     * Expects percentage to be trailed by 00,
     */
    function substractPercentage(uint256 total_, uint8 percentageToSub_) internal pure returns (uint256 result_) {
        return sub(total_, div(mul(total_, percentageToSub_), 1000));
    }

    function percentageOfTotal(uint256 part_, uint256 total_) internal pure returns (uint256 percent_) {
        return div(mul(part_, 100), total_);
    }

    /**
     * Taken from Hypersonic https://github.com/M2629/HyperSonic/blob/main/Math.sol
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function quadraticPricing(uint256 payment_, uint256 multiplier_) internal pure returns (uint256) {
        return sqrrt(mul(multiplier_, payment_));
    }

    function bondingCurve(uint256 supply_, uint256 multiplier_) internal pure returns (uint256) {
        return mul(multiplier_, supply_);
    }
}

