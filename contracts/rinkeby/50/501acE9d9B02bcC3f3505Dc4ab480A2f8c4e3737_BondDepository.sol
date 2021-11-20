// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Factory.sol";
import "./Governable.sol";
import "./interface/ISOLACE.sol";
import "./interface/IxSOLACE.sol";
import "./interface/IBondTeller.sol";
import "./interface/IBondDepository.sol";

contract BondDepository is IBondDepository, Factory, Governable {

    ISOLACE internal _solace;
    IxSOLACE internal _xsolace;
    address internal _pool;
    address internal _dao;

    // track tellers
    mapping(address => bool) internal _isTeller;

    /**
     * @notice Constructs the BondDepository contract.
     * @param governance The address of the [governor](/docs/protocol/governance).
     * @param solace Address of [**SOLACE**](./solace).
     * @param solace Address of [**xSOLACE**](./xsolace).
     * @param pool Address of [`UnderwritingPool`](./underwritingpool).
     * @param solace Address of the DAO.
     */
    constructor(address governance, address solace, address xsolace, address pool, address dao) Governable(governance) {
        _setParams(solace, xsolace, pool, dao);
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Native [**SOLACE**](./SOLACE) Token.
    function solace() external view override returns (address solace_) {
        return address(_solace);
    }

    /// @notice [**xSOLACE**](./xSOLACE) Token.
    function xsolace() external view override returns (address xsolace_) {
        return address(_xsolace);
    }

    /// @notice Underwriting Pool contract.
    function underwritingPool() external view override returns (address pool_) {
        return _pool;
    }

    /// @notice The DAO.
    function dao() external view override returns (address dao_) {
        return _dao;
    }

    /// @notice Returns true if the address is a teller.
    function isTeller(address teller) external view override returns (bool isTeller_) {
        return _isTeller[teller];
    }

    /***************************************
    TELLER MANAGEMENT FUNCTIONS
    ***************************************/

    /**
     * @notice Creates a new [`BondTeller`](./bondteller).
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param governance The address of the teller's [governor](/docs/protocol/governance).
     * @param impl The address of BondTeller implementation.
     * @param principal address The ERC20 token that users give.
     * @return teller The address of the new teller.
     */
    function createBondTeller(
        address governance,
        address impl,
        address principal
    ) external override onlyGovernance returns (address teller) {
        teller = _deployMinimalProxy(impl);
        IBondTeller(teller).initialize(governance, address(_solace), address(_xsolace), _pool, _dao, principal, address(this));
        _isTeller[teller] = true;
        emit TellerAdded(teller);
        return teller;
    }

    /**
     * @notice Creates a new [`BondTeller`](./bondteller).
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param governance The address of the teller's [governor](/docs/protocol/governance).
     * @param impl The address of BondTeller implementation.
     * @param salt The salt for CREATE2.
     * @param principal address The ERC20 token that users give.
     * @return teller The address of the new teller.
     */
    function create2BondTeller(
        address governance,
        address impl,
        bytes32 salt,
        address principal
    ) external override onlyGovernance returns (address teller) {
        teller = _deployMinimalProxy(impl, salt);
        IBondTeller(teller).initialize(governance, address(_solace), address(_xsolace), _pool, _dao, principal, address(this));
        _isTeller[teller] = true;
        emit TellerAdded(teller);
        return teller;
    }

    /**
     * @notice Adds a teller.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param teller The teller to add.
     */
    function addTeller(address teller) external override onlyGovernance {
        _isTeller[teller] = true;
        emit TellerAdded(teller);
    }

    /**
     * @notice Adds a teller.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param teller The teller to remove.
     */
    function removeTeller(address teller) external override onlyGovernance {
        _isTeller[teller] = false;
        emit TellerRemoved(teller);
    }

    /**
     * @notice Sets the parameters to pass to new tellers.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param solace Address of [**SOLACE**](./solace).
     * @param solace Address of [**xSOLACE**](./xsolace).
     * @param pool Address of [`UnderwritingPool`](./underwritingpool).
     * @param solace Address of the DAO.
     */
    function setParams(address solace, address xsolace, address pool, address dao) external override onlyGovernance {
        _setParams(solace, xsolace, pool, dao);
    }

    /**
     * @notice Sets the parameters to pass to new tellers.
     * @param solace Address of [**SOLACE**](./solace).
     * @param solace Address of [**xSOLACE**](./xsolace).
     * @param pool Address of [`UnderwritingPool`](./underwritingpool).
     * @param solace Address of the DAO.
     */
    function _setParams(address solace, address xsolace, address pool, address dao) internal {
        require(solace != address(0x0), "zero address solace");
        require(xsolace != address(0x0), "zero address xsolace");
        require(pool != address(0x0), "zero address pool");
        require(dao != address(0x0), "zero address dao");
        _solace = ISOLACE(solace);
        _xsolace = IxSOLACE(xsolace);
        _pool = pool;
        _dao = dao;
        emit ParamsSet(solace, xsolace, pool, dao);
    }

    /***************************************
    TELLER ONLY FUNCTIONS
    ***************************************/

    /**
     * @notice Mints new **SOLACE** to the teller.
     * Can only be called by tellers.
     * @param amount The number of new tokens.
     */
    function mint(uint256 amount) external override {
        // this contract must have permissions to mint solace
        // tellers should mint via bond depository instead of directly through solace
        // acts as a second layer of access control that declutters solace minters

        // can only be called by authorized minters
        require(_isTeller[msg.sender], "!teller");
        // mint
        _solace.mint(msg.sender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title Factory for arbitrary code deployment using the "CREATE" and "CREATE2" opcodes
 */
abstract contract Factory {
    bytes private constant MINIMAL_PROXY_INIT_CODE_PREFIX =
        hex"3d602d80600a3d3981f3_363d3d373d3d3d363d73";
    bytes private constant MINIMAL_PROXY_INIT_CODE_SUFFIX =
        hex"5af43d82803e903d91602b57fd5bf3";

    event ContractDeployed(address indexed deployment);

    /**
     * @notice deploy an EIP1167 minimal proxy using "CREATE" opcode
     * @param target implementation contract to proxy
     * @return minimalProxy address of deployed proxy
     */
    function _deployMinimalProxy(address target) internal returns (address minimalProxy) {
        return _deploy(_generateMinimalProxyInitCode(target));
    }

    /**
     * @notice deploy an EIP1167 minimal proxy using "CREATE2" opcode
     * @dev reverts if deployment is not successful (likely because salt has already been used)
     * @param target implementation contract to proxy
     * @param salt input for deterministic address calculation
     * @return minimalProxy address of deployed proxy
     */
    function _deployMinimalProxy(address target, bytes32 salt) internal returns (address minimalProxy) {
        return _deploy(_generateMinimalProxyInitCode(target), salt);
    }

    /**
     * @notice calculate the deployment address for a given target and salt
     * @param target implementation contract to proxy
     * @param salt input for deterministic address calculation
     * @return deployment address
     */
    function calculateMinimalProxyDeploymentAddress(address target, bytes32 salt) public view returns (address) {
        return
            calculateDeploymentAddress(
                keccak256(_generateMinimalProxyInitCode(target)),
                salt
            );
    }

    /**
     * @notice concatenate elements to form EIP1167 minimal proxy initialization code
     * @param target implementation contract to proxy
     * @return bytes memory initialization code
     */
    function _generateMinimalProxyInitCode(address target) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                MINIMAL_PROXY_INIT_CODE_PREFIX,
                target,
                MINIMAL_PROXY_INIT_CODE_SUFFIX
            );
    }

    /**
     * @notice deploy contract code using "CREATE" opcode
     * @param initCode contract initialization code
     * @return deployment address of deployed contract
     */
    function _deploy(bytes memory initCode) internal returns (address deployment) {
        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            deployment := create(0, encoded_data, encoded_size)
        }
        require(deployment != address(0), "Factory: failed deployment");
        emit ContractDeployed(deployment);
    }

    /**
     * @notice deploy contract code using "CREATE2" opcode
     * @dev reverts if deployment is not successful (likely because salt has already been used)
     * @param initCode contract initialization code
     * @param salt input for deterministic address calculation
     * @return deployment address of deployed contract
     */
    function _deploy(bytes memory initCode, bytes32 salt) internal returns (address deployment) {
        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            deployment := create2(0, encoded_data, encoded_size, salt)
        }
        require(deployment != address(0), "Factory: failed deployment");
        emit ContractDeployed(deployment);
    }

    /**
     * @notice calculate the _deployMetamorphicContract deployment address for a given salt
     * @param initCodeHash hash of contract initialization code
     * @param salt input for deterministic address calculation
     * @return deployment address
     */
    function calculateDeploymentAddress(bytes32 initCodeHash, bytes32 salt) public view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                address(this),
                                salt,
                                initCodeHash
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./interface/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setPendingGovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./interface/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title Solace Token (SOLACE)
 * @author solace.fi
 * @notice **Solace** tokens can be earned by depositing **Capital Provider** or **Liquidity Provider** tokens to the [`Master`](./Master) contract.
 * **SOLACE** can also be locked for a preset time in the `Locker` contract to recieve `veSOLACE` tokens.
 */
interface ISOLACE is IERC20Metadata {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a minter is added.
    event MinterAdded(address indexed minter);
    /// @notice Emitted when a minter is removed.
    event MinterRemoved(address indexed minter);

    /***************************************
    MINT FUNCTIONS
    ***************************************/

    /**
     * @notice Returns true if `account` is authorized to mint **SOLACE**.
     * @param account Account to query.
     * @return status True if `account` can mint, false otherwise.
     */
    function isMinter(address account) external view returns (bool status);

    /**
     * @notice Mints new **SOLACE** to the receiver account.
     * Can only be called by authorized minters.
     * @param account The receiver of new tokens.
     * @param amount The number of new tokens.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice Burns **SOLACE** from msg.sender.
     * @param amount Amount to burn.
     */
    function burn(uint256 amount) external;

    /**
     * @notice Adds a new minter.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param minter The new minter.
     */
    function addMinter(address minter) external;

    /**
     * @notice Removes a minter.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param minter The minter to remove.
     */
    function removeMinter(address minter) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";


/**
 * @title xSolace Token (xSOLACE)
 * @author solace.fi
 * @notice
 */
interface IxSOLACE is IERC20, IERC20Permit {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when SOLACE is staked.
    event Staked(address user, uint256 amountSolace, uint256 amountXSolace);
    /// @notice Emitted when SOLACE is unstaked.
    event Unstaked(address user, uint256 amountSolace, uint256 amountXSolace);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice native solace token
    function solace() external view returns (address solace_);

    /**
     * @notice Determines the current value in xsolace for an amount of solace.
     * @param amountSolace The amount of solace.
     * @return amountXSolace The amount of xsolace.
     */
    function solaceToXSolace(uint256 amountSolace) external view returns (uint256 amountXSolace);

    /**
     * @notice Determines the current value in solace for an amount of xsolace.
     * @param amountXSolace The amount of xsolace.
     * @return amountSolace The amount of solace.
     */
    function xSolaceToSolace(uint256 amountXSolace) external view returns (uint256 amountSolace);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Allows a user to stake **SOLACE**.
     * Shares of the pool (xSOLACE) are minted to msg.sender.
     * @param amountSolace Amount of solace to deposit.
     * @return amountXSolace The amount of xsolace minted.
     */
    function stake(uint256 amountSolace) external returns (uint256 amountXSolace);

    /**
     * @notice Allows a user to stake **SOLACE**.
     * Shares of the pool (xSOLACE) are minted to msg.sender.
     * @param depositor The depositing user.
     * @param amountSolace The deposit amount.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     * @return amountXSolace The amount of xsolace minted.
     */
    function stakeSigned(address depositor, uint256 amountSolace, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountXSolace);

    /**
     * @notice Allows a user to unstake **xSOLACE**.
     * Burns **xSOLACE** tokens and transfers **SOLACE** to msg.sender.
     * @param amountXSolace Amount of xSOLACE.
     * @return amountSolace Amount of SOLACE returned.
     */
    function unstake(uint256 amountXSolace) external returns (uint256 amountSolace);

    /**
     * @notice Burns **xSOLACE** from msg.sender.
     * @param amount Amount to burn.
     */
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IBondTeller {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a bond is created.
    event CreateBond(uint256 bondID, uint256 principalAmount, address payoutToken, uint256 payoutAmount, uint256 maturation);
    /// @notice Emitted when a bond is redeemed.
    event RedeemBond(uint256 bondID, address recipient, address payoutToken, uint256 payoutAmount);
    /// @notice Emitted when deposits are paused.
    event Paused();
    /// @notice Emitted when deposits are unpaused.
    event Unpaused();

    /***************************************
    INITIALIZER
    ***************************************/

    /**
     * @notice Initializes the teller.
     * @param governance The address of the [governor](/docs/protocol/governance).
     * @param solace The SOLACE token.
     * @param xsolace The xSOLACE token.
     * @param pool The underwriting pool.
     * @param dao The DAO.
     * @param principal address The ERC20 token that users deposit.
     * @param bondDepo The bond depository.
     */
    function initialize(
        address governance,
        address solace,
        address xsolace,
        address pool,
        address dao,
        address principal,
        address bondDepo
    ) external;

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Pauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
    */
    function pause() external;

    /**
     * @notice Unpauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
    */
    function unpause() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


interface IBondDepository {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a teller is added.
    event TellerAdded(address indexed teller);
    /// @notice Emitted when a teller is removed.
    event TellerRemoved(address indexed teller);
    /// @notice Emitted when the params are set.
    event ParamsSet(address solace, address xsolace, address pool, address dao);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Native [**SOLACE**](./SOLACE) Token.
    function solace() external view returns (address solace_);

    /// @notice [**xSOLACE**](./xSOLACE) Token.
    function xsolace() external view returns (address xsolace_);

    /// @notice Underwriting Pool contract.
    function underwritingPool() external view returns (address pool_);

    /// @notice The DAO.
    function dao() external view returns (address dao_);

    /// @notice Returns true if the address is a teller.
    function isTeller(address teller) external view returns (bool isTeller_);

    /***************************************
    TELLER MANAGEMENT FUNCTIONS
    ***************************************/

    /**
     * @notice Creates a new [`BondTeller`](./bondteller).
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param governance The address of the teller's [governor](/docs/protocol/governance).
     * @param impl The address of BondTeller implementation.
     * @param principal address The ERC20 token that users give.
     * @return teller The address of the new teller.
     */
    function createBondTeller(
        address governance,
        address impl,
        address principal
    ) external returns (address teller);

    /**
     * @notice Creates a new [`BondTeller`](./bondteller).
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param governance The address of the teller's [governor](/docs/protocol/governance).
     * @param impl The address of BondTeller implementation.
     * @param salt The salt for CREATE2.
     * @param principal address The ERC20 token that users give.
     * @return teller The address of the new teller.
     */
    function create2BondTeller(
        address governance,
        address impl,
        bytes32 salt,
        address principal
    ) external returns (address teller);

    /**
     * @notice Adds a teller.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param teller The teller to add.
     */
    function addTeller(address teller) external;

    /**
     * @notice Adds a teller.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param teller The teller to remove.
     */
    function removeTeller(address teller) external;

    /**
     * @notice Sets the parameters to pass to new tellers.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param solace Address of [**SOLACE**](./solace).
     * @param solace Address of [**xSOLACE**](./xsolace).
     * @param pool Address of [`UnderwritingPool`](./underwritingpool).
     * @param solace Address of the DAO.
     */
    function setParams(address solace, address xsolace, address pool, address dao) external;

    /***************************************
    TELLER ONLY FUNCTIONS
    ***************************************/

    /**
     * @notice Mints new **SOLACE** to the teller.
     * Can only be called by tellers.
     * @param amount The number of new tokens.
     */
    function mint(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setPendingGovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}