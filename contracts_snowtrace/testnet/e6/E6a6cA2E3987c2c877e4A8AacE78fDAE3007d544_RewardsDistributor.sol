// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IRewardsDistributionRecipient } from "../interfaces/IRewardsDistributionRecipient.sol";
import { ImmutableModule } from "../shared/ImmutableModule.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IProtocolFeeCollector } from "../interfaces/IProtocolFeeCollector.sol";


/**
 * @title  RewardsDistributor
 * @author mStable
 * @notice RewardsDistributor allows Fund Managers to send rewards (usually in MTA)
 * to specified Reward Recipients.
 */
contract RewardsDistributor is ImmutableModule {
    using SafeERC20 for IERC20;

    IProtocolFeeCollector public protocolFeeCollector;

    uint256 public teamPct = 0;
    uint256 public fundPct = 0;
    uint256 public treasuaryPct = 0;

    mapping(address => uint256) public teamBalance;
    mapping(address => uint256) public treasuaryBalance;

    mapping(address => bool) public fundManagers;
    mapping(address => bool) public teamManagers;
    mapping(address => bool) public treasuaryManagers;

    event AddedFundManager(address indexed _address);
    event AddedTeamManager(address indexed _address);
    event AddedTreasuaryManager(address indexed _address);

    event RemovedFundManager(address indexed _address);
    event RemovedTeamManager(address indexed _address);
    event RemovedTreasuaryManager(address indexed _address);

    event DistributedReward(
        address recipient,
        address rewardToken,
        uint256 amount
    );

    /**
     * @dev Modifier to allow function calls only from a fundManager address.
     */
    modifier onlyFundManager() {
        require(fundManagers[msg.sender], "Not a fund manager");
        _;
    }

        /**
     * @dev Modifier to allow function calls only from a fundManager address.
     */
    modifier onlyTeamManager() {
        require(teamManagers[msg.sender], "Not a team manager");
        _;
    }

     /**
     * @dev Modifier to allow function calls only from a fundManager address.
     */
    modifier onlyTreasuaryManager() {
        require(treasuaryManagers[msg.sender], "Not a treasuary manager");
        _;
    }


    /** @dev Recipient is a module, governed by Embr governance */
    constructor(
        address _fulcrum, 
        address _protocolFeeCollector,
        address[] memory _fundManagers,
        address[] memory _teamManagers,
        address[] memory _treasuaryManagers, 
        uint256 _teamPct,
        uint256 _fundPct,
        uint256 _treasuaryPct
    ) ImmutableModule(_fulcrum) {
        require(_teamPct + _fundPct + _treasuaryPct == 1000, "Distrubtion percent is not 1000");

        protocolFeeCollector = IProtocolFeeCollector(_protocolFeeCollector);

        for (uint256 i = 0; i < _fundManagers.length; i++) {
            _addFundManager(_fundManagers[i]);
        }
        for (uint256 i = 0; i < _teamManagers.length; i++) {
            _addTeamManager(_teamManagers[i]);
        }
        for (uint256 i = 0; i < _treasuaryManagers.length; i++) {
            _addTreasuaryManager(_treasuaryManagers[i]);
        }

        teamPct = _teamPct;
        fundPct = _fundPct;
        treasuaryPct = _treasuaryPct;
    }

    /**
     * @dev Allows the Embr governance to add a new FundManager
     * @param _address  FundManager to add
     */
    function addFundManager(address _address) external onlyGovernor {
        _addFundManager(_address);
    }

    /**
     * @dev Allows the Embr governance to add a new FundManager
     * @param _address  FundManager to add
     */
    function addTeamManager(address _address) external onlyGovernor {
        _addTeamManager(_address);
    }

    /**
     * @dev Allows the Embr governance to add a new FundManager
     * @param _address  FundManager to add
     */
    function addTreasuaryManager(address _address) external onlyGovernor {
        _addTreasuaryManager(_address);
    }

    /**
     * @dev Adds a new whitelist address
     * @param _address Address to add in whitelist
     */
    function _addFundManager(address _address) internal {
        require(_address != address(0), "Address is zero");
        require(!fundManagers[_address], "Already fund manager");

        fundManagers[_address] = true;

        emit AddedFundManager(_address);
    }

    /**
     * @dev Adds a new whitelist address
     * @param _address Address to add in whitelist
     */
    function _addTeamManager(address _address) internal {
        require(_address != address(0), "Address is zero");
        require(!teamManagers[_address], "Already team manager");

        teamManagers[_address] = true;

        emit AddedTeamManager(_address);
    }

    /**
     * @dev Adds a new whitelist address
     * @param _address Address to add in whitelist
     */
    function _addTreasuaryManager(address _address) internal {
        require(_address != address(0), "Address is zero");
        require(!treasuaryManagers[_address], "Already treasuary manager");

        treasuaryManagers[_address] = true;

        emit AddedTreasuaryManager(_address);
    }

    /**
     * @dev Allows the Embr governance to remove inactive FundManagers
     * @param _address  FundManager to remove
     */
    function removeFundManager(address _address) external onlyGovernor {
        require(_address != address(0), "Address is zero");
        require(fundManagers[_address], "Not a fund manager");

        fundManagers[_address] = false;

        emit RemovedFundManager(_address);
    }

     /**
     * @dev Allows the Embr governance to remove inactive FundManagers
     * @param _address  TeamManager to remove
     */
    function removeTeamManager(address _address) external onlyGovernor {
        require(_address != address(0), "Address is zero");
        require(teamManagers[_address], "Not a team manager");

        teamManagers[_address] = false;

        emit RemovedTeamManager(_address);
    }

     /**
     * @dev Allows the Embr governance to remove inactive FundManagers
     * @param _address  FundManager to remove
     */
    function removeTreasuaryManager(address _address) external onlyGovernor {
        require(_address != address(0), "Address is zero");
        require(treasuaryManagers[_address], "Not a treasuary manager");

        treasuaryManagers[_address] = false;

        emit RemovedTreasuaryManager(_address);
    }

    /**
     * @dev Distributes reward tokens to list of recipients and notifies them
     * of the transfer. Only callable by FundManagers
     * @param _recipient        Reward recipient to credit
     */
    function distributeProtocolRewards(
        IRewardsDistributionRecipient _recipient
    ) external onlyFundManager {
        IRewardsDistributionRecipient recipient = _recipient;
        uint256 activeTokenCount = recipient.activeTokenCount();

        IERC20[] memory rewardTokens = new IERC20[](activeTokenCount);
        uint256[] memory currentIndexes = new uint256[](activeTokenCount);
        for (uint256 i = 0; i < activeTokenCount; i++) {
            currentIndexes[i] = recipient.getActiveIndex(i);
            IERC20 rewardToken =  recipient.getRewardToken(currentIndexes[i]);
            rewardTokens[i] = rewardToken;
        }
        uint256[] memory feeAmounts = protocolFeeCollector.getCollectedFeeAmounts(rewardTokens);
        protocolFeeCollector.withdrawCollectedFees(rewardTokens, feeAmounts, address(_recipient));
 
        for (uint256 i = 0; i < activeTokenCount; i++) {
            if (feeAmounts[i] > 0) { 
                uint256 fundAmt = (feeAmounts[i] * fundPct) / 1000;
                uint256 teamAmt = (feeAmounts[i] * teamPct) / 1000;
                uint256 treasuaryAmt = (feeAmounts[i] * treasuaryPct) / 1000;

                if (teamAmt > 0) { 
                    teamBalance[address(rewardTokens[i])];
                }

                if (treasuaryAmt > 0) {
                    treasuaryBalance[address(rewardTokens[i])];
                }

                // Only after successful fee collcetion - notify the contract of the new funds
                recipient.notifyRewardAmount(currentIndexes[i], fundAmt);

                emit DistributedReward(
                    address(recipient),
                    address(rewardTokens[i]),
                    feeAmounts[i]
                );
            }
        }
    }

     /**
     * @dev Distributes reward tokens to list of recipients and notifies them
     * of the transfer. Only callable by FundManagers
     * @param _recipient        Reward recipient to credit
     */
    function distributeRewards(
        IRewardsDistributionRecipient _recipient,
        uint256[] calldata _amounts,
        uint256[] calldata _indexes
    ) external onlyFundManager {
        uint256 len = _indexes.length;
        require(len == _amounts.length, "Mismatching inputs");
        IRewardsDistributionRecipient recipient = _recipient;
        for (uint256 i = 0; i < len; i++) {
            IERC20 rewardToken =  recipient.getRewardToken(i);
            rewardToken.safeTransferFrom(msg.sender, address(recipient), _amounts[i]);
            recipient.notifyRewardAmount(i, _amounts[i]);

            emit DistributedReward(
                address(recipient),
                address(rewardToken),
                _amounts[i]
            );
        }

    }

    function withdrawTeam(address _addr, address _token) 
        external 
        onlyTeamManager 
    {
        uint256 _teamBalance = teamBalance[_token];
        if (_teamBalance > 0) { 
            uint256 balance = IERC20(_token).balanceOf(address(this));
            if (balance > 0 && balance >= _teamBalance) {
                teamBalance[_token] = 0;
                IERC20(_token).safeTransfer(_addr, _teamBalance);
            }
        }
    }

    function withdrawTreasuary(address _addr, address _token) 
        external 
        onlyTreasuaryManager 
    {
        uint256 _treasuaryBalance = treasuaryBalance[_token];
        if (_treasuaryBalance > 0) { 
            uint256 balance = IERC20(_token).balanceOf(address(this));
            if (balance > 0 && balance >= _treasuaryBalance) {
                treasuaryBalance[_token] = 0;
                IERC20(_token).safeTransfer(_addr, _treasuaryBalance);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 _tid, uint256 reward) external;

    function getRewardToken(uint256 _tid) external view returns (IERC20);

    function getActiveIndex(uint256 _tid) external view returns (uint256);

    function activeTokenCount() external view returns (uint256);
}

interface IRewardsRecipientWithPlatformToken {
    function notifyRewardAmount(uint256 _tid, uint256 reward) external;

    function getRewardToken(uint256 _tid) external view returns (IERC20);

    function getActiveIndex(uint256 _tid) external view returns (uint256);

    function getPlatformToken() external view returns (IERC20);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { ModuleKeys } from "./ModuleKeys.sol";
import { IFulcrum } from "../interfaces/IFulcrum.sol";

/**
 * @title   ImmutableModule
 * @author  mStable
 * @dev     Subscribes to module updates from a given publisher and reads from its registry.
 *          Contract is used for upgradable proxy contracts.
 */
abstract contract ImmutableModule is ModuleKeys {
    IFulcrum public immutable fulcrum;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _fulcrum Fulcrum contract address
     */
    constructor(address _fulcrum) {
        require(_fulcrum != address(0), "Fulcrum address is zero");
        fulcrum = IFulcrum(_fulcrum);
    }

    /**
     * @dev Modifier to allow function calls only from the Governor.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == _governor(), "Only governor can execute");
    }

    /**
     * @dev Modifier to allow function calls only from the Governor or the Keeper EOA.
     */
    modifier onlyKeeperOrGovernor() {
        _keeperOrGovernor();
        _;
    }

    function _keeperOrGovernor() internal view {
        require(msg.sender == _keeper() || msg.sender == _governor(), "Only keeper or governor");
    }

    /**
     * @dev Modifier to allow function calls only from the Governance.
     *      Governance is either Governor address or Governance address.
     */
    modifier onlyGovernance() {
        require(
            msg.sender == _governor() || msg.sender == _governance(),
            "Only governance can execute"
        );
        _;
    }

    /**
     * @dev Returns Governor address from the Fulcrum
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return fulcrum.governor();
    }

    /**
     * @dev Returns Governance Module address from the Fulcrum
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return fulcrum.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return Keeper address from the Fulcrum.
     *      This account is used for operational transactions that
     *      don't need multiple signatures.
     * @return  Address of the Keeper externally owned account.
     */
    function _keeper() internal view returns (address) {
        return fulcrum.getModule(KEY_KEEPER);
    }

    /**
     * @dev Return ProxyAdmin Module address from the Fulcrum
     * @return Address of the ProxyAdmin Module contract
     */
    function _proxyAdmin() internal view returns (address) {
        return fulcrum.getModule(KEY_PROXY_ADMIN);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IProtocolFeeCollector {
    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external;

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external;

    function getSwapFeePercentage() external view returns (uint256);

    function getFlashLoanFeePercentage() external view returns (uint256);

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title  ModuleKeys
 * @author mStable
 * @notice Provides system wide access to the byte32 represntations of system modules
 *         This allows each system module to be able to reference and update one another in a
 *         friendly way
 * @dev    keccak256() values are hardcoded to avoid re-evaluation of the constants at runtime.
 */
contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("Recollateraliser");
    bytes32 internal constant KEY_RECOLLATERALISER =
        0x39e3ed1fc335ce346a8cbe3e64dd525cf22b37f1e2104a755e761c3c1eb4734f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("SavingsManager");
    bytes32 internal constant KEY_SAVINGS_MANAGER =
        0x12fe936c77a1e196473c4314f3bed8eeac1d757b319abb85bdda70df35511bf1;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
    // keccak256("InterestValidator");
    bytes32 internal constant KEY_INTEREST_VALIDATOR =
        0xc10a28f028c7f7282a03c90608e38a4a646e136e614e4b07d119280c5f7f839f;
    // keccak256("Keeper");
    bytes32 internal constant KEY_KEEPER =
        0x4f78afe9dfc9a0cb0441c27b9405070cd2a48b490636a7bdd09f355e33a5d7de;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IFulcrum
 * @dev Basic interface for interacting with the Fulcrum i.e. SystemKernel
 */
interface IFulcrum {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
}

// SPDX-License-Identifier: MIT

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