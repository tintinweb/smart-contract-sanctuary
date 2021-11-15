pragma solidity ^0.7.5;

import "./libs/SafeMath.sol";
import "./libs/Address.sol";
import "./libs/Ownable.sol";
import "./libs/IERC20.sol";
import "./libs/SafeERC20.sol";

import "./interfaces/IBondCalculator.sol";
import "./interfaces/IGyro.sol";
import "./interfaces/IReservoir.sol";

interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

contract Reservoir is IReservoir, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum TARGETS {
        COLLATERAL_DEPOSITOR,
        COLLATERAL_SPENDER,
        COLLATERAL_TOKEN,
        COLLATERAL_MANAGER,
        LIQUIDITY_DEPOSITOR,
        LIQUIDITY_TOKEN,
        LIQUIDITY_MANAGER,
        DEBTOR,
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

    address[] public collateralTokens; // Push only, beware false-positives.
    mapping(address => bool) public isCollateralToken;
    mapping(address => uint256) public collateralTokenQueue; // Delays changes to mapping.

    address[] public collateralDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isCollateralDepositor;
    mapping(address => uint256) public collateralDepositorQueue; // Delays changes to mapping.

    address[] public collateralSpenders; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isCollateralSpender;
    mapping(address => uint256) public collateralSpenderQueue; // Delays changes to mapping.

    address[] public liquidityTokens; // Push only, beware false-positives.
    mapping(address => bool) public isLiquidityToken;
    mapping(address => uint256) public liquidityTokenQueue; // Delays changes to mapping.

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityDepositor;
    mapping(address => uint256) public liquidityDepositorQueue; // Delays changes to mapping.

    mapping(address => address) public bondCalculator; // bond calculator for liquidity token

    address[] public collateralManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isCollateralManager;
    mapping(address => uint256) public collateralManagerQueue; // Delays changes to mapping.

    address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityManager;
    mapping(address => uint256) public liquidityManagerQueue; // Delays changes to mapping.

    address[] public debtors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isDebtor;
    mapping(address => uint256) public debtorQueue; // Delays changes to mapping.
    mapping(address => uint256) public debtorBalance;

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isRewardManager;
    mapping(address => uint256) public rewardManagerQueue; // Delays changes to mapping.

    address public sGyro;
    uint256 public sGyroQueue; // Delays change to sGyro address

    uint256 public totalAssets; // Risk-free value of all assets
    uint256 public totalDebt;

    constructor(
        address gyro_,
        address collateralToken_,
        address liquidityToken_,
        address calculator_,
        uint256 queueLength_
    ) {
        require(gyro_ != address(0) && (collateralToken_ != address(0) || liquidityToken_ != address(0)));

        gyro = gyro_;

        if (collateralToken_ != address(0)) {
            isCollateralToken[collateralToken_] = true;
            collateralTokens.push(collateralToken_);
        }

        if (liquidityToken_ != address(0)) {
            isLiquidityToken[liquidityToken_] = true;
            liquidityTokens.push(liquidityToken_);
            bondCalculator[liquidityToken_] = calculator_;
        }

        queueLength = queueLength_;
    }

    /**
        @notice allow approved address to deposit an asset for gyro
        @param amount_ uint
        @param token_ address
        @param profit_ uint
        @return send_ uint
     */
    function deposit(
        uint256 amount_,
        address token_,
        uint256 profit_
    ) external override returns (uint256 send_) {
        require(isCollateralToken[token_] || isLiquidityToken[token_], "Not accepted");
        if (isCollateralToken[token_]) {
            require(isCollateralDepositor[msg.sender], "Not approved");
        } else {
            require(isLiquidityDepositor[msg.sender], "Not approved");
        }

        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);

        uint256 value = gyroValueOf(token_, amount_);
        // mint gyro needed and store amount of rewards for distribution
        send_ = value.sub(profit_);
        IERC20Mintable(gyro).mint(msg.sender, send_);

        totalAssets = totalAssets.add(value);
        emit LogUpdateAssets(totalAssets);

        emit LogDeposit(token_, amount_, value);
    }

    /**
        @notice allow approved address to burn gyro for collateral tokens
        @param amount_ uint
        @param token_ address
     */
    function withdraw(uint256 amount_, address token_) external {
        require(isCollateralToken[token_], "Not accepted"); // Only collateral tokens can be used for redemptions
        require(isCollateralSpender[msg.sender] == true, "Not approved");

        uint256 value = gyroValueOf(token_, amount_);
        IGyro(gyro).burnFrom(msg.sender, value);

        totalAssets = totalAssets.sub(value);
        emit LogUpdateAssets(totalAssets);

        IERC20(token_).safeTransfer(msg.sender, amount_);

        emit LogWithdraw(token_, amount_, value);
    }

    /**
        @notice allow approved address to borrow collateral tokens
        @param amount_ uint
        @param token_ address
     */
    function incurDebt(uint256 amount_, address token_) external {
        require(isDebtor[msg.sender], "Not approved");
        require(isCollateralToken[token_], "Not accepted");

        uint256 value = gyroValueOf(token_, amount_);

        uint256 maximumDebt = IERC20(sGyro).balanceOf(msg.sender); // Can only borrow against sGyro held
        uint256 availableDebt = maximumDebt.sub(debtorBalance[msg.sender]);
        require(value <= availableDebt, "Exceeds debt limit");

        debtorBalance[msg.sender] = debtorBalance[msg.sender].add(value);
        totalDebt = totalDebt.add(value);

        totalAssets = totalAssets.sub(value);
        emit LogUpdateAssets(totalAssets);

        IERC20(token_).transfer(msg.sender, amount_);

        emit LogCreateDebt(msg.sender, token_, amount_, value);
    }

    /**
        @notice allow approved address to repay borrowed collaterals with collateral tokens
        @param amount_ uint
        @param token_ address
     */
    function repayDebtWithCollateral(uint256 amount_, address token_) external {
        require(isDebtor[msg.sender], "Not approved");
        require(isCollateralToken[token_], "Not accepted");

        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);

        uint256 value = gyroValueOf(token_, amount_);
        debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(value);
        totalDebt = totalDebt.sub(value);

        totalAssets = totalAssets.add(value);
        emit LogUpdateAssets(totalAssets);

        emit LogRepayDebt(msg.sender, token_, amount_, value);
    }

    /**
        @notice allow approved address to repay borrowed collaterals with gyro
        @param amount_ uint
     */
    function repayDebtWithGyro(uint256 amount_) external {
        require(isDebtor[msg.sender], "Not approved");

        IGyro(gyro).burnFrom(msg.sender, amount_);

        debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(amount_);
        totalDebt = totalDebt.sub(amount_);

        emit LogRepayDebt(msg.sender, gyro, amount_, amount_);
    }

    /**
        @notice allow approved address to withdraw assets
        @param token_ address
        @param amount_ uint
     */
    function manage(address token_, uint256 amount_) external {
        if (isLiquidityToken[token_]) {
            require(isLiquidityManager[msg.sender], "Not approved");
        } else {
            require(isCollateralManager[msg.sender], "Not approved");
        }

        uint256 value = gyroValueOf(token_, amount_);
        require(value <= excessAssets(), "Insufficient assets");

        totalAssets = totalAssets.sub(value);
        emit LogUpdateAssets(totalAssets);

        IERC20(token_).safeTransfer(msg.sender, amount_);

        emit LogManageAssets(token_, amount_);
    }

    /**
        @notice send epoch reward to staking contract
     */
    function mintRewards(address recipient_, uint256 amount_) external override {
        require(isRewardManager[msg.sender], "Not approved");
        require(amount_ <= excessAssets(), "Insufficient assets");

        IERC20Mintable(gyro).mint(recipient_, amount_);

        emit LogMintRewards(msg.sender, recipient_, amount_);
    }

    /**
        @notice returns excess assets not backing tokens
        @return uint
     */
    function excessAssets() public view returns (uint256) {
        return totalAssets.sub(IERC20(gyro).totalSupply().sub(totalDebt));
    }

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized assets before auditing
     */
    function auditAssets() external onlyOwner() {
        uint256 assets;
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            assets = assets.add(gyroValueOf(collateralTokens[i], IERC20(collateralTokens[i]).balanceOf(address(this))));
        }
        for (uint256 i = 0; i < liquidityTokens.length; i++) {
            assets = assets.add(gyroValueOf(liquidityTokens[i], IERC20(liquidityTokens[i]).balanceOf(address(this))));
        }
        totalAssets = assets;
        emit LogUpdateAssets(assets);
        emit LogAuditAssets(assets);
    }

    /**
        @notice returns gyro valuation of asset
        @param token_ address
        @param amount_ uint
        @return value_ uint
     */
    function gyroValueOf(address token_, uint256 amount_) public view override returns (uint256 value_) {
        if (isCollateralToken[token_]) {
            // convert amount to match gyro decimals
            value_ = amount_.mul(10**IERC20(gyro).decimals()).div(10**IERC20(token_).decimals());
        } else if (isLiquidityToken[token_]) {
            value_ = IBondCalculator(bondCalculator[token_]).valuation(token_, amount_);
        }
    }

    /**
        @notice queue address to change boolean in mapping
        @param target_ TARGETS
        @param address_ address
        @return bool
     */
    function queue(TARGETS target_, address address_) external onlyOwner() returns (bool) {
        require(address_ != address(0));
        if (target_ == TARGETS.COLLATERAL_DEPOSITOR) {
            // 0
            collateralDepositorQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.COLLATERAL_SPENDER) {
            // 1
            collateralSpenderQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.COLLATERAL_TOKEN) {
            // 2
            collateralTokenQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.COLLATERAL_MANAGER) {
            // 3
            collateralManagerQueue[address_] = block.number.add(queueLength.mul(2));
        } else if (target_ == TARGETS.LIQUIDITY_DEPOSITOR) {
            // 4
            liquidityDepositorQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.LIQUIDITY_TOKEN) {
            // 5
            liquidityTokenQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.LIQUIDITY_MANAGER) {
            // 6
            liquidityManagerQueue[address_] = block.number.add(queueLength.mul(2));
        } else if (target_ == TARGETS.DEBTOR) {
            // 7
            debtorQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.REWARD_MANAGER) {
            // 8
            rewardManagerQueue[address_] = block.number.add(queueLength);
        } else if (target_ == TARGETS.S_GYRO) {
            // 9
            sGyroQueue = block.number.add(queueLength);
        } else return false;

        emit LogQueueChange(target_, address_);
        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param target_ TARGETS
        @param address_ address
        @param calculator_ address
        @return bool
     */
    function toggle(
        TARGETS target_,
        address address_,
        address calculator_
    ) external onlyOwner() returns (bool) {
        require(address_ != address(0));
        bool result;
        if (target_ == TARGETS.COLLATERAL_DEPOSITOR) {
            // 0
            if (requirements(collateralDepositorQueue, isCollateralDepositor, address_)) {
                collateralDepositorQueue[address_] = 0;
                if (!listContains(collateralDepositors, address_)) {
                    collateralDepositors.push(address_);
                }
            }
            result = !isCollateralDepositor[address_];
            isCollateralDepositor[address_] = result;
        } else if (target_ == TARGETS.COLLATERAL_SPENDER) {
            // 1
            if (requirements(collateralSpenderQueue, isCollateralSpender, address_)) {
                collateralSpenderQueue[address_] = 0;
                if (!listContains(collateralSpenders, address_)) {
                    collateralSpenders.push(address_);
                }
            }
            result = !isCollateralSpender[address_];
            isCollateralSpender[address_] = result;
        } else if (target_ == TARGETS.COLLATERAL_TOKEN) {
            // 2
            if (requirements(collateralTokenQueue, isCollateralToken, address_)) {
                collateralTokenQueue[address_] = 0;
                if (!listContains(collateralTokens, address_)) {
                    collateralTokens.push(address_);
                }
            }
            result = !isCollateralToken[address_];
            isCollateralToken[address_] = result;
        } else if (target_ == TARGETS.COLLATERAL_MANAGER) {
            // 3
            if (requirements(collateralManagerQueue, isCollateralManager, address_)) {
                collateralManagers.push(address_);
                collateralManagerQueue[address_] = 0;
                if (!listContains(collateralManagers, address_)) {
                    collateralManagers.push(address_);
                }
            }
            result = !isCollateralManager[address_];
            isCollateralManager[address_] = result;
        } else if (target_ == TARGETS.LIQUIDITY_DEPOSITOR) {
            // 4
            if (requirements(liquidityDepositorQueue, isLiquidityDepositor, address_)) {
                liquidityDepositors.push(address_);
                liquidityDepositorQueue[address_] = 0;
                if (!listContains(liquidityDepositors, address_)) {
                    liquidityDepositors.push(address_);
                }
            }
            result = !isLiquidityDepositor[address_];
            isLiquidityDepositor[address_] = result;
        } else if (target_ == TARGETS.LIQUIDITY_TOKEN) {
            // 5
            if (requirements(liquidityTokenQueue, isLiquidityToken, address_)) {
                liquidityTokenQueue[address_] = 0;
                if (!listContains(liquidityTokens, address_)) {
                    liquidityTokens.push(address_);
                }
            }
            result = !isLiquidityToken[address_];
            isLiquidityToken[address_] = result;
            bondCalculator[address_] = calculator_;
        } else if (target_ == TARGETS.LIQUIDITY_MANAGER) {
            // 6
            if (requirements(liquidityManagerQueue, isLiquidityManager, address_)) {
                liquidityManagerQueue[address_] = 0;
                if (!listContains(liquidityManagers, address_)) {
                    liquidityManagers.push(address_);
                }
            }
            result = !isLiquidityManager[address_];
            isLiquidityManager[address_] = result;
        } else if (target_ == TARGETS.DEBTOR) {
            // 7
            if (requirements(debtorQueue, isDebtor, address_)) {
                debtorQueue[address_] = 0;
                if (!listContains(debtors, address_)) {
                    debtors.push(address_);
                }
            }
            result = !isDebtor[address_];
            isDebtor[address_] = result;
        } else if (target_ == TARGETS.REWARD_MANAGER) {
            // 8
            if (requirements(rewardManagerQueue, isRewardManager, address_)) {
                rewardManagerQueue[address_] = 0;
                if (!listContains(rewardManagers, address_)) {
                    rewardManagers.push(address_);
                }
            }
            result = !isRewardManager[address_];
            isRewardManager[address_] = result;
        } else if (target_ == TARGETS.S_GYRO) {
            // 9
            sGyroQueue = 0;
            sGyro = address_;
            result = true;
        } else return false;

        emit LogActivateChange(target_, address_, result);
        return true;
    }

    /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param address_ address
        @return bool 
     */
    function requirements(
        mapping(address => uint256) storage queue_,
        mapping(address => bool) storage status_,
        address address_
    ) internal view returns (bool) {
        if (!status_[address_]) {
            require(queue_[address_] != 0, "Must queue");
            require(queue_[address_] <= block.number, "Queue not expired");
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
    function listContains(address[] storage list_, address token_) internal view returns (bool) {
        for (uint256 i = 0; i < list_.length; i++) {
            if (list_[i] == token_) {
                return true;
            }
        }
        return false;
    }
}

pragma solidity ^0.7.5;

interface IBondCalculator {
    function valuation(address pair_, uint256 amount_) external view returns (uint256 value_);

    function markdown(address pair_) external view returns (uint256);
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

interface IReservoir {
    function deposit(
        uint256 amount,
        address token,
        uint256 profit
    ) external returns (uint256);

    function gyroValueOf(address token, uint256 amount) external view returns (uint256 value_);

    function mintRewards(address recipient, uint256 amount) external;
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

