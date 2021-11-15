// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

library Utils {
    function find(address[] memory arr, address item)
        internal
        pure
        returns (bool exist, uint256 index)
    {
        for (uint256 i = 0; i < arr.length; i += 1) {
            if (arr[i] == item) {
                return (true, i);
            }
        }
    }

    function find(bytes4[] memory arr, bytes4 sig)
        internal
        pure
        returns (bool exist, uint256 index)
    {
        for (uint256 i = 0; i < arr.length; i += 1) {
            if (arr[i] == sig) {
                return (true, i);
            }
        }
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

contract ERC20Recoverer is Initializable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public permanentlyNonRecoverable;
    mapping(address => bool) public nonRecoverable;

    event Recovered(address token, uint256 amount);

    address public recoverer;

    constructor() {}

    modifier onlyRecoverer() {
        require(msg.sender == recoverer, "Only allowed to recoverer");
        _;
    }

    function initialize(address _recoverer, address[] memory disableList)
        public
        initializer
    {
        for (uint256 i = 0; i < disableList.length; i++) {
            permanentlyNonRecoverable[disableList[i]] = true;
        }
        recoverer = _recoverer;
    }

    function setRecoverer(address _recoverer) public onlyRecoverer {
        recoverer = _recoverer;
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyRecoverer
    {
        require(nonRecoverable[tokenAddress] == false, "Non-recoverable ERC20");
        require(
            permanentlyNonRecoverable[tokenAddress] == false,
            "Non-recoverable ERC20"
        );
        IERC20(tokenAddress).safeTransfer(recoverer, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function disable(address _contract) public onlyRecoverer {
        nonRecoverable[_contract] = true;
    }

    function disablePermanently(address _contract) public onlyRecoverer {
        permanentlyNonRecoverable[_contract] = true;
    }

    function enable(address _contract) public onlyRecoverer {
        permanentlyNonRecoverable[_contract] = true;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import {
    ERC20Burnable,
    ERC20 as _ERC20
} from "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

/**
 * @title Commit Token
 * @notice Commit Token is used for redeeming stable coins, buying crypto products
 *      from the village market and mining vision tokens. It is minted by the admin and
 *      given to the contributors. The amount of mintable token is limited to the balance
 *      of redeemable stable coins. Therefore, it's 1:1 pegged to the given stable coin
 *      or expected to have higher value than the redeemable coin values.
 */
contract ERC20 is ERC20Burnable {
    address public minter;

    constructor() _ERC20("ERC20Mock", "MOCK") {
        minter = msg.sender;
    }

    modifier onlyMinter {
        require(msg.sender == minter, "Not a minter");
        _;
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function setMinter(address _minter) public onlyMinter {
        minter = _minter;
    }
}

//SPDX-License-Identifier: CC0
pragma solidity ^0.7.0;

/**
 * @title ERC-1620 Money Streaming Standard
 * @author Sablier
 * @dev See https://eips.ethereum.org/EIPS/eip-1620
 */
interface IERC1620 {
    /**
     * @notice Emits when a stream is successfully created.
     */
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );

    /**
     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Emits when a stream is successfully cancelled and tokens are transferred back on a pro rata basis.
     */
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    function balanceOf(uint256 streamId, address who)
        external
        view
        returns (uint256 balance);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        );

    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256 streamId);

    function withdrawFromStream(uint256 streamId, uint256 funds)
        external
        returns (bool);

    function cancelStream(uint256 streamId) external returns (bool);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import {
    ERC1155Burnable,
    ERC1155 as _ERC1155
} from "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";

/**
 * @title Commit Token
 * @notice Commit Token is used for redeeming stable coins, buying crypto products
 *      from the village market and mining vision tokens. It is minted by the admin and
 *      given to the contributors. The amount of mintable token is limited to the balance
 *      of redeemable stable coins. Therefore, it's 1:1 pegged to the given stable coin
 *      or expected to have higher value than the redeemable coin values.
 */
contract ERC1155 is ERC1155Burnable {
    address public minter;

    constructor() _ERC1155("ERC1155Mock") {
        minter = msg.sender;
    }

    modifier onlyMinter {
        require(msg.sender == minter, "Not a minter");
        _;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyMinter {
        _mint(to, id, amount, bytes(""));
    }

    function setMinter(address _minter) public onlyMinter {
        minter = _minter;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import {
    IERC20 as _IERC20
} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20 is _IERC20 {}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

contract WETH9 {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

library Sqrt {
    /**
     * @dev This code is written by Noah Zinsmeister @ Uniswap
     * https://github.com/Uniswap/uniswap-v2-core/blob/v1.0.1/contracts/libraries/Math.sol
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/utils/SafeCast.sol";

library Int128 {
    using SafeCast for uint256;
    using SafeCast for int256;

    function toInt128(uint256 val) internal pure returns (int128) {
        return val.toInt256().toInt128();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "../../../core/emission/libraries/MiningPool.sol";

contract ERC20BurnMiningV1 is MiningPool {
    using SafeMath for uint256;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC20BurnMiningV1(0).burn.selector);
        _registerInterface(ERC20BurnMiningV1(0).exit.selector);
        _registerInterface(ERC20BurnMiningV1(0).erc20BurnMiningV1.selector);
    }

    function burn(uint256 amount) public {
        _dispatchMiners(amount);
        ERC20Burnable(baseToken()).burnFrom(msg.sender, amount);
    }

    function exit() public {
        // transfer vision token
        _mine();
        // withdraw all miners
        uint256 numOfMiners = dispatchedMiners(msg.sender);
        _withdrawMiners(numOfMiners);
    }

    function erc20BurnMiningV1() external pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
// Refactored synthetix StakingRewards.sol for general purpose mining pool logic.
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "../../../core/tokens/COMMIT.sol";
import "../../../core/emission/interfaces/ITokenEmitter.sol";
import "../../../core/emission/interfaces/IMiningPool.sol";
import "../../../utils/ERC20Recoverer.sol";

abstract contract MiningPool is
    ReentrancyGuard,
    Pausable,
    ERC20Recoverer,
    ERC165,
    IMiningPool
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private _baseToken;
    address private _token;
    address private _tokenEmitter;

    uint256 private _miningEnds = 0;
    uint256 private _miningRate = 0;
    uint256 private _lastUpdateTime;
    uint256 private _tokenPerMiner;
    uint256 private _totalMiners;

    mapping(address => uint256) private _paidTokenPerMiner;
    mapping(address => uint256) private _mined;
    mapping(address => uint256) private _dispatchedMiners;

    modifier onlyTokenEmitter() {
        require(
            msg.sender == address(_tokenEmitter),
            "Only the token emitter can call this function"
        );
        _;
    }

    modifier recordMining(address account) {
        _tokenPerMiner = tokenPerMiner();
        _lastUpdateTime = lastTimeMiningApplicable();
        if (account != address(0)) {
            _mined[account] = mined(account);
            _paidTokenPerMiner[account] = _tokenPerMiner;
        }
        _;
    }

    function initialize(address tokenEmitter_, address baseToken_)
        public
        virtual
        override
    {
        address token_ = ITokenEmitter(tokenEmitter_).token();

        require(address(_token) == address(0), "Already initialized");
        require(token_ != address(0), "Token is zero address");
        require(tokenEmitter_ != address(0), "Token emitter is zero address");
        require(baseToken_ != address(0), "Base token is zero address");
        _token = token_;
        _tokenEmitter = tokenEmitter_;
        _baseToken = baseToken_;
        // ERC20Recoverer
        address[] memory disable = new address[](2);
        disable[0] = token_;
        disable[1] = baseToken_;
        ERC20Recoverer.initialize(msg.sender, disable);
        // ERC165
        bytes4 _INTERFACE_ID_ERC165 = 0x01ffc9a7;
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(MiningPool(0).allocate.selector);
    }

    function allocate(uint256 amount)
        public
        override
        onlyTokenEmitter
        recordMining(address(0))
    {
        uint256 miningPeriod = ITokenEmitter(_tokenEmitter).EMISSION_PERIOD();
        if (block.timestamp >= _miningEnds) {
            _miningRate = amount.div(miningPeriod);
        } else {
            uint256 remaining = _miningEnds.sub(block.timestamp);
            uint256 leftover = remaining.mul(_miningRate);
            _miningRate = amount.add(leftover).div(miningPeriod);
        }

        // Ensure the provided mining amount is not more than the balance in the contract.
        // This keeps the mining rate in the right range, preventing overflows due to
        // very high values of miningRate in the mined and tokenPerMiner functions;
        // (allocated_amount + leftover) must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(_miningRate <= balance.div(miningPeriod), "not enough balance");

        _lastUpdateTime = block.timestamp;
        _miningEnds = block.timestamp.add(miningPeriod);
        emit Allocated(amount);
    }

    function token() public view override returns (address) {
        return _token;
    }

    function tokenEmitter() public view override returns (address) {
        return _tokenEmitter;
    }

    function baseToken() public view override returns (address) {
        return _baseToken;
    }

    function miningEnds() public view override returns (uint256) {
        return _miningEnds;
    }

    function miningRate() public view override returns (uint256) {
        return _miningRate;
    }

    function lastUpdateTime() public view override returns (uint256) {
        return _lastUpdateTime;
    }

    function lastTimeMiningApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, _miningEnds);
    }

    function tokenPerMiner() public view override returns (uint256) {
        if (_totalMiners == 0) {
            return _tokenPerMiner;
        }
        return
            _tokenPerMiner.add(
                lastTimeMiningApplicable()
                    .sub(_lastUpdateTime)
                    .mul(_miningRate)
                    .mul(1e18)
                    .div(_totalMiners)
            );
    }

    function mined(address account) public view override returns (uint256) {
        // prev mined + ((token/miner - paidToken/miner) 1e18 unit) * dispatchedMiner
        return
            _dispatchedMiners[account]
                .mul(tokenPerMiner().sub(_paidTokenPerMiner[account]))
                .div(1e18)
                .add(_mined[account]);
    }

    function getMineableForPeriod() public view override returns (uint256) {
        uint256 miningPeriod = ITokenEmitter(_tokenEmitter).EMISSION_PERIOD();
        return _miningRate.mul(miningPeriod);
    }

    function paidTokenPerMiner(address account)
        public
        view
        override
        returns (uint256)
    {
        return _paidTokenPerMiner[account];
    }

    function dispatchedMiners(address account)
        public
        view
        override
        returns (uint256)
    {
        return _dispatchedMiners[account];
    }

    function totalMiners() public view override returns (uint256) {
        return _totalMiners;
    }

    function _dispatchMiners(uint256 miners) internal {
        _dispatchMiners(msg.sender, miners);
    }

    function _dispatchMiners(address account, uint256 miners)
        internal
        nonReentrant
        whenNotPaused
        recordMining(account)
    {
        require(miners > 0, "Cannot stake 0");
        _totalMiners = _totalMiners.add(miners);
        _dispatchedMiners[account] = _dispatchedMiners[account].add(miners);
        emit Dispatched(account, miners);
    }

    function _withdrawMiners(uint256 miners) internal {
        _withdrawMiners(msg.sender, miners);
    }

    function _withdrawMiners(address account, uint256 miners)
        internal
        nonReentrant
        recordMining(account)
    {
        require(miners > 0, "Cannot withdraw 0");
        _totalMiners = _totalMiners.sub(miners);
        _dispatchedMiners[account] = _dispatchedMiners[account].sub(miners);
        emit Withdrawn(account, miners);
    }

    function _mine() internal {
        _mine(msg.sender);
    }

    function _mine(address account)
        internal
        nonReentrant
        recordMining(account)
    {
        uint256 amount = _mined[account];
        if (amount > 0) {
            _mined[account] = 0;
            IERC20(_token).safeTransfer(account, amount);
            emit Mined(account, amount);
        }
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

/**
 * @title Commit Token
 * @notice Commit Token is used for redeeming stable coins, buying crypto products
 *      from the village market and mining vision tokens. It is minted by the admin and
 *      given to the contributors. The amount of mintable token is limited to the balance
 *      of redeemable stable coins. Therefore, it's 1:1 pegged to the given stable coin
 *      or expected to have higher value than the redeemable coin values.
 */
contract COMMIT is ERC20Burnable, Initializable {
    using SafeMath for uint256;

    address private _minter;
    uint256 private _totalBurned;
    string private _name;
    string private _symbol;

    constructor() ERC20("", "") {
        // this constructor will not be called since it'll be cloned by proxy pattern.
        // initalize() will be called instead.
    }

    modifier onlyMinter {
        require(msg.sender == _minter, "Not a minter");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address minter_
    ) public initializer {
        _name = name_;
        _symbol = symbol_;
        _minter = minter_;
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function setMinter(address minter_) public onlyMinter {
        _setMinter(minter_);
    }

    function _setMinter(address minter_) internal {
        _minter = minter_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function minter() public view returns (address) {
        return _minter;
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        _totalBurned = _totalBurned.add(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

struct EmissionWeight {
    address[] pools;
    uint256[] weights;
    uint256 treasury;
    uint256 caller;
    uint256 protocol;
    uint256 dev;
    uint256 sum;
}

struct EmitterConfig {
    uint256 projId;
    uint256 initialEmission;
    uint256 minEmissionRatePerWeek;
    uint256 emissionCutRate;
    uint256 founderShareRate;
    uint256 startDelay;
    address treasury;
    address gov;
    address token;
    address protocolPool;
    address contributionBoard;
    address erc20BurnMiningFactory;
    address erc20StakeMiningFactory;
    address erc721StakeMiningFactory;
    address erc1155StakeMiningFactory;
    address erc1155BurnMiningFactory;
    address initialContributorShareFactory;
}

struct MiningPoolConfig {
    uint256 weight;
    bytes4 poolType;
    address baseToken;
}

struct MiningConfig {
    MiningPoolConfig[] pools;
    uint256 treasuryWeight;
    uint256 callerWeight;
}

interface ITokenEmitter {
    event Start();
    event TokenEmission(uint256 amount);
    event EmissionCutRateUpdated(uint256 rate);
    event EmissionRateUpdated(uint256 rate);
    event EmissionWeightUpdated(uint256 numberOfPools);
    event NewMiningPool(bytes4 poolTypes, address baseToken, address pool);

    function start() external;

    function distribute() external;

    function token() external view returns (address);

    function projId() external view returns (uint256);

    function poolTypes(address pool) external view returns (bytes4);

    function factories(bytes4 poolType) external view returns (address);

    function minEmissionRatePerWeek() external view returns (uint256);

    function emissionCutRate() external view returns (uint256);

    function emission() external view returns (uint256);

    function initialContributorPool() external view returns (address);

    function initialContributorShare() external view returns (address);

    function treasury() external view returns (address);

    function protocolPool() external view returns (address);

    function pools(uint256 index) external view returns (address);

    function emissionWeight() external view returns (EmissionWeight memory);

    function emissionStarted() external view returns (uint256);

    function emissionWeekNum() external view returns (uint256);

    function INITIAL_EMISSION() external view returns (uint256);

    function FOUNDER_SHARE_DENOMINATOR() external view returns (uint256);

    function EMISSION_PERIOD() external pure returns (uint256);

    function DENOMINATOR() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IMiningPool {
    event Allocated(uint256 amount);
    event Dispatched(address indexed user, uint256 numOfMiners);
    event Withdrawn(address indexed user, uint256 numOfMiners);
    event Mined(address indexed user, uint256 amount);

    function initialize(address _tokenEmitter, address _baseToken) external;

    function allocate(uint256 amount) external;

    function token() external view returns (address);

    function tokenEmitter() external view returns (address);

    function baseToken() external view returns (address);

    function miningEnds() external view returns (uint256);

    function miningRate() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function lastTimeMiningApplicable() external view returns (uint256);

    function tokenPerMiner() external view returns (uint256);

    function mined(address account) external view returns (uint256);

    function getMineableForPeriod() external view returns (uint256);

    function paidTokenPerMiner(address account) external view returns (uint256);

    function dispatchedMiners(address account) external view returns (uint256);

    function totalMiners() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../../../core/emission/libraries/MiningPool.sol";

contract ERC1155StakeMiningV1 is MiningPool, ERC1155Holder {
    using SafeMath for uint256;

    mapping(address => mapping(uint256 => uint256)) private _staking;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC1155StakeMiningV1(0).stake.selector);
        _registerInterface(ERC1155StakeMiningV1(0).mine.selector);
        _registerInterface(ERC1155StakeMiningV1(0).withdraw.selector);
        _registerInterface(ERC1155StakeMiningV1(0).exit.selector);
        _registerInterface(ERC1155StakeMiningV1(0).dispatchableMiners.selector);
        _registerInterface(
            ERC1155StakeMiningV1(0).erc1155StakeMiningV1.selector
        );
    }

    function stake(uint256 id, uint256 amount) public {
        bytes memory zero;
        IERC1155(baseToken()).safeTransferFrom(
            msg.sender,
            address(this),
            id,
            amount,
            zero
        );
    }

    function withdraw(uint256 tokenId, uint256 amount) public {
        uint256 staked = _staking[msg.sender][tokenId];
        require(staked >= amount, "Withdrawing more than staked.");
        _staking[msg.sender][tokenId] = staked - amount;
        uint256 miners = dispatchableMiners(tokenId).mul(amount);
        _withdrawMiners(miners);
        bytes memory zero;
        IERC1155(baseToken()).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            zero
        );
    }

    function mine() public {
        _mine();
    }

    function exit(uint256 tokenId) public {
        mine();
        withdraw(tokenId, _staking[msg.sender][tokenId]);
    }

    function _stake(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal {
        _staking[account][tokenId] = _staking[account][tokenId].add(amount);
        uint256 miners = dispatchableMiners(tokenId).mul(amount);
        _dispatchMiners(account, miners);
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) public virtual override returns (bytes4) {
        _stake(from, id, value);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) public virtual override returns (bytes4) {
        require(ids.length == values.length, "Not a valid input");
        for (uint256 i = 0; i < ids.length; i++) {
            _stake(from, ids[i], values[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev override this function if you customize this mining pool
     */
    function dispatchableMiners(uint256)
        public
        view
        virtual
        returns (uint256 numOfMiner)
    {
        return 1;
    }

    function erc1155StakeMiningV1() external pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";
import "../../../core/emission/libraries/MiningPool.sol";
import "../../../core/emission/pools/ERC1155BurnMiningV1.sol";
import "../../../core/emission/interfaces/ITokenEmitter.sol";

contract InitialContributorShare is ERC1155BurnMiningV1 {
    using SafeMath for uint256;

    uint256 private _projId;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC1155BurnMiningV1(0).burn.selector);
        _registerInterface(ERC1155BurnMiningV1(0).exit.selector);
        _registerInterface(ERC1155BurnMiningV1(0).dispatchableMiners.selector);
        _registerInterface(ERC1155BurnMiningV1(0).erc1155BurnMiningV1.selector);
        _registerInterface(
            InitialContributorShare(0).initialContributorShare.selector
        );
        _projId = ITokenEmitter(tokenEmitter_).projId();
    }

    function burn(uint256 amount) public {
        burn(_projId, amount);
    }

    function burn(uint256 projId_, uint256 amount) public override {
        require(_projId == projId_);
        super.burn(_projId, amount);
    }

    function exit() public {
        exit(_projId);
    }

    function exit(uint256 projId_) public override {
        require(_projId == projId_);
        super.exit(_projId);
    }

    /**
     * @dev override this function if you customize this mining pool
     */
    function dispatchableMiners(uint256 id)
        public
        view
        override
        returns (uint256 numOfMiner)
    {
        if (_projId == id) return 1;
        else return 0;
    }

    function projId() public view returns (uint256) {
        return _projId;
    }

    function initialContributorShare() external pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";
import "../../../core/emission/libraries/MiningPool.sol";
import "../../../core/emission/interfaces/ITokenEmitter.sol";

contract ERC1155BurnMiningV1 is MiningPool, ERC1155Holder {
    using SafeMath for uint256;

    mapping(address => mapping(uint256 => uint256)) private _burned;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        virtual
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC1155BurnMiningV1(0).burn.selector);
        _registerInterface(ERC1155BurnMiningV1(0).exit.selector);
        _registerInterface(ERC1155BurnMiningV1(0).dispatchableMiners.selector);
        _registerInterface(ERC1155BurnMiningV1(0).erc1155BurnMiningV1.selector);
    }

    function burn(uint256 tokenId, uint256 amount) public virtual {
        _dispatch(msg.sender, tokenId, amount);
        ERC1155Burnable(baseToken()).burn(msg.sender, tokenId, amount);
    }

    function exit(uint256 tokenId) public virtual {
        // transfer vision token
        _mine();
        uint256 burnedAmount = _burned[msg.sender][tokenId];
        _burned[msg.sender][tokenId] = 0;
        // withdraw all miners for the given token id
        uint256 minersToWithdraw =
            dispatchableMiners(tokenId).mul(burnedAmount);
        _withdrawMiners(minersToWithdraw);
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) public virtual override returns (bytes4) {
        _dispatch(from, id, value);
        ERC1155Burnable(baseToken()).burn(address(this), id, value);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) public virtual override returns (bytes4) {
        require(ids.length == values.length, "Not a valid input");
        for (uint256 i = 0; i < ids.length; i++) {
            _dispatch(from, ids[i], values[i]);
            ERC1155Burnable(baseToken()).burn(address(this), ids[i], values[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev override this function if you customize this mining pool
     */
    function dispatchableMiners(uint256)
        public
        view
        virtual
        returns (uint256 numOfMiner)
    {
        return 1;
    }

    function erc1155BurnMiningV1() external pure returns (bool) {
        return true;
    }

    function _dispatch(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        uint256 minersToDispatch = dispatchableMiners(tokenId).mul(amount);
        _dispatchMiners(account, minersToDispatch);
        _burned[account][tokenId] = _burned[account][tokenId].add(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../core/emission/libraries/MiningPool.sol";

contract ERC20StakeMiningV1 is MiningPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC20StakeMiningV1(0).stake.selector);
        _registerInterface(ERC20StakeMiningV1(0).mine.selector);
        _registerInterface(ERC20StakeMiningV1(0).withdraw.selector);
        _registerInterface(ERC20StakeMiningV1(0).exit.selector);
        _registerInterface(ERC20StakeMiningV1(0).erc20StakeMiningV1.selector);
    }

    function stake(uint256 amount) public {
        IERC20(baseToken()).safeTransferFrom(msg.sender, address(this), amount);
        _dispatchMiners(amount);
    }

    function withdraw(uint256 amount) public {
        _withdrawMiners(amount);
        IERC20(baseToken()).safeTransfer(msg.sender, amount);
    }

    function mine() public {
        _mine();
    }

    function exit() public {
        mine();
        withdraw(dispatchedMiners(msg.sender));
    }

    function erc20StakeMiningV1() external pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "../../../core/emission/libraries/MiningPool.sol";

contract ERC721StakeMiningV1 is MiningPool, ERC721Holder {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    mapping(address => EnumerableSet.UintSet) private _stakedTokensOf;
    EnumerableMap.UintToAddressMap private _stakers;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC721StakeMiningV1(0).stake.selector);
        _registerInterface(ERC721StakeMiningV1(0).mine.selector);
        _registerInterface(ERC721StakeMiningV1(0).withdraw.selector);
        _registerInterface(ERC721StakeMiningV1(0).exit.selector);
        _registerInterface(ERC721StakeMiningV1(0).dispatchableMiners.selector);
        _registerInterface(ERC721StakeMiningV1(0).erc721StakeMiningV1.selector);
    }

    function stake(uint256 id) public {
        IERC721(baseToken()).safeTransferFrom(msg.sender, address(this), id);
    }

    function withdraw(uint256 tokenId) public {
        require(
            _stakers.get(tokenId) == msg.sender,
            "Only staker can withdraw"
        );
        _stakedTokensOf[msg.sender].remove(tokenId);
        _stakers.remove(tokenId);
        uint256 miners = dispatchableMiners(tokenId);
        _withdrawMiners(miners);
        IERC721(baseToken()).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    function mine() public {
        _mine();
    }

    function exit() public {
        mine();
        uint256 bal = _stakedTokensOf[msg.sender].length();
        for (uint256 i = 0; i < bal; i++) {
            uint256 tokenId = _stakedTokensOf[msg.sender].at(i);
            withdraw(tokenId);
        }
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public override returns (bytes4) {
        _stake(from, tokenId);
        return this.onERC721Received.selector;
    }

    /**
     * @dev override this function if you customize this mining pool
     */
    function dispatchableMiners(uint256 tokenId)
        public
        view
        virtual
        returns (uint256 numOfMiner)
    {
        if (IERC721(baseToken()).ownerOf(tokenId) != address(0)) return 1;
        else return 0;
    }

    function erc721StakeMiningV1() external pure returns (bool) {
        return true;
    }

    function _stake(address from, uint256 tokenId) internal {
        uint256 miners = dispatchableMiners(tokenId);
        _stakedTokensOf[from].add(tokenId);
        _stakers.set(tokenId, from);
        _dispatchMiners(from, miners);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import {
    ERC20BurnMiningV1 as _ERC20BurnMiningV1
} from "../../../core/emission/pools/ERC20BurnMiningV1.sol";
import {
    ERC20StakeMiningV1 as _ERC20StakeMiningV1
} from "../../../core/emission/pools/ERC20StakeMiningV1.sol";
import {
    ERC721StakeMiningV1 as _ERC721StakeMiningV1
} from "../../../core/emission/pools/ERC721StakeMiningV1.sol";
import {
    ERC1155StakeMiningV1 as _ERC1155StakeMiningV1
} from "../../../core/emission/pools/ERC1155StakeMiningV1.sol";
import {
    ERC1155BurnMiningV1 as _ERC1155BurnMiningV1
} from "../../../core/emission/pools/ERC1155BurnMiningV1.sol";
import {
    InitialContributorShare as _InitialContributorShare
} from "../../../core/emission/pools/InitialContributorShare.sol";

library PoolType {
    bytes4 public constant ERC20BurnMiningV1 =
        _ERC20BurnMiningV1(0).erc20BurnMiningV1.selector;
    bytes4 public constant ERC20StakeMiningV1 =
        _ERC20StakeMiningV1(0).erc20StakeMiningV1.selector;
    bytes4 public constant ERC721StakeMiningV1 =
        _ERC721StakeMiningV1(0).erc721StakeMiningV1.selector;
    bytes4 public constant ERC1155StakeMiningV1 =
        _ERC1155StakeMiningV1(0).erc1155StakeMiningV1.selector;
    bytes4 public constant ERC1155BurnMiningV1 =
        _ERC1155BurnMiningV1(0).erc1155BurnMiningV1.selector;
    bytes4 public constant InitialContributorShare =
        _InitialContributorShare(0).initialContributorShare.selector;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../../core/emission/interfaces/IMiningPoolFactory.sol";
import "../../../core/emission/interfaces/IMiningPool.sol";

abstract contract MiningPoolFactory is IMiningPoolFactory, ERC165 {
    using Clones for address;

    address private _controller;

    constructor() ERC165() {
        _registerInterface(IMiningPoolFactory(0).newPool.selector);
        _registerInterface(IMiningPoolFactory(0).poolType.selector);
    }

    function _setController(address controller_) internal {
        _controller = controller_;
    }

    function newPool(address emitter, address baseToken)
        public
        virtual
        override
        returns (address pool)
    {
        address predicted = this.poolAddress(emitter, baseToken);
        if (_isDeployed(predicted)) {
            // already deployed;
            return predicted;
        } else {
            // not deployed;
            bytes32 salt = keccak256(abi.encodePacked(emitter, baseToken));
            pool = _controller.cloneDeterministic(salt);
            require(
                predicted == pool,
                "Different result. This factory has a serious problem."
            );
            IMiningPool(pool).initialize(emitter, baseToken);
            emit NewMiningPool(emitter, baseToken, pool);
            return pool;
        }
    }

    function controller() public view override returns (address) {
        return _controller;
    }

    function getPool(address emitter, address baseToken)
        public
        view
        override
        returns (address)
    {
        address predicted = this.poolAddress(emitter, baseToken);
        return _isDeployed(predicted) ? predicted : address(0);
    }

    function poolAddress(address emitter, address baseToken)
        external
        view
        virtual
        override
        returns (address pool)
    {
        bytes32 salt = keccak256(abi.encodePacked(emitter, baseToken));
        pool = _controller.predictDeterministicAddress(salt);
    }

    function _isDeployed(address pool) private view returns (bool) {
        return Address.isContract(pool);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IMiningPoolFactory {
    event NewMiningPool(
        address _emitter,
        address _stakingToken,
        address _poolAddress
    );

    function newPool(address _emitter, address _baseToken)
        external
        returns (address);

    function controller() external view returns (address);

    function getPool(address _emitter, address _baseToken)
        external
        view
        returns (address);

    function poolType() external view returns (bytes4);

    function poolAddress(address _emitter, address _baseToken)
        external
        view
        returns (address _pool);
}

//SPDX-License-Identifier: GPL-3.0
// This contract referenced Sushi's MasterChef.sol logic
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../../core/emission/interfaces/ITokenEmitter.sol";
import "../../../core/emission/interfaces/IMiningPool.sol";
import "../../../core/emission/interfaces/IMiningPoolFactory.sol";
import "../../../core/emission/libraries/PoolType.sol";
import "../../../core/governance/Governed.sol";
import "../../../core/dividend/interfaces/IDividendPool.sol";
import "../../../utils/IERC20Mintable.sol";
import "../../../utils/Utils.sol";
import "../../../utils/ERC20Recoverer.sol";

contract TokenEmitter is
    Governed,
    ReentrancyGuard,
    ITokenEmitter,
    Initializable,
    ERC20Recoverer
{
    using ERC165Checker for address;
    using SafeMath for uint256;
    using Utils for bytes4[];

    uint256 public constant override DENOMINATOR = 10000;
    uint256 public constant override EMISSION_PERIOD = 1 weeks;
    uint256 private _INITIAL_EMISSION;
    uint256 private _FOUNDER_SHARE_DENOMINATOR;

    address private _token;
    uint256 private _minEmissionRatePerWeek = 60; // 0.006 per week ~= 36% yearly inflation
    uint256 private _emissionCutRate = 3000; // 30%
    uint256 private _emission;

    address private _initialContributorPool;
    address private _initialContributorShare;
    address private _treasury;
    address private _protocolPool;
    uint256 private _startDelay;

    mapping(bytes4 => address) private _factories;

    mapping(address => bytes4) private _poolTypes;

    EmissionWeight private _emissionWeight;

    uint256 private _emissionStarted;

    uint256 private _emissionWeekNum;

    uint256 private _projId;

    function initialize(EmitterConfig memory params) public initializer {
        require(params.treasury != address(0), "Should not be zero");
        Governed.initialize(msg.sender);
        // set params
        _projId = params.projId;
        _INITIAL_EMISSION = params.initialEmission;
        _emission = params.initialEmission;
        _minEmissionRatePerWeek = params.minEmissionRatePerWeek;
        _emissionCutRate = params.emissionCutRate;
        _protocolPool = params.protocolPool;
        _startDelay = params.startDelay;
        // set contract addresses
        _token = params.token;
        setTreasury(params.treasury);
        require(params.founderShareRate < DENOMINATOR);
        _FOUNDER_SHARE_DENOMINATOR = params.founderShareRate != 0
            ? DENOMINATOR / params.founderShareRate
            : 0;
        ERC20Recoverer.initialize(params.gov, new address[](0));
        setFactory(params.erc20BurnMiningFactory);
        setFactory(params.erc20StakeMiningFactory);
        setFactory(params.erc721StakeMiningFactory);
        setFactory(params.erc1155StakeMiningFactory);
        setFactory(params.erc1155BurnMiningFactory);
        setFactory(params.initialContributorShareFactory);
        address initialContributorPool_ =
            newPool(PoolType.InitialContributorShare, params.contributionBoard);
        _initialContributorPool = initialContributorPool_;
        _initialContributorShare = params.contributionBoard;
        Governed.setGovernance(params.gov);
    }

    /**
     * StakeMiningV1:
     */
    function newPool(bytes4 poolType, address token_) public returns (address) {
        address factory = _factories[poolType];
        require(factory != address(0), "Factory not exists");
        address _pool =
            IMiningPoolFactory(factory).getPool(address(this), token_);
        if (_pool == address(0)) {
            _pool = IMiningPoolFactory(factory).newPool(address(this), token_);
        }
        require(
            _pool.supportsInterface(poolType),
            "Does not have the given pool type"
        );
        require(
            _pool.supportsInterface(IMiningPool(0).allocate.selector),
            "Cannot allocate reward"
        );
        require(_poolTypes[_pool] == bytes4(0), "Pool already exists");
        _poolTypes[_pool] = poolType;
        emit NewMiningPool(poolType, token_, _pool);
        return _pool;
    }

    function setEmission(MiningConfig memory config) public governed {
        require(config.treasuryWeight < 1e4, "prevent overflow");
        require(config.callerWeight < 1e4, "prevent overflow");
        // starting the summation with treasury and caller weights
        uint256 _sum = config.treasuryWeight + config.callerWeight;
        // prepare list to store
        address[] memory _pools = new address[](config.pools.length);
        uint256[] memory _weights = new uint256[](config.pools.length);
        // deploy pool if not the pool exists and do the weight summation
        // udpate the pool & weight arr on memory
        for (uint256 i = 0; i < config.pools.length; i++) {
            address _pool =
                _getOrDeployPool(
                    config.pools[i].poolType,
                    config.pools[i].baseToken
                );
            require(
                _poolTypes[_pool] != bytes4(0),
                "Not a deployed mining pool"
            );
            require(config.pools[i].weight < 1e4, "prevent overflow");
            _weights[i] = config.pools[i].weight;
            _pools[i] = _pool;
            _sum += config.pools[i].weight; // doesn't overflow
        }
        // compute the founder share
        uint256 _dev =
            _FOUNDER_SHARE_DENOMINATOR != 0
                ? _sum / _FOUNDER_SHARE_DENOMINATOR
                : 0; // doesn't overflow;
        _sum += _dev;
        // compute the protocol share
        uint256 _protocol = _protocolPool == address(0) ? 0 : _sum / 33;
        _sum += _protocol;
        // store the updated emission weight
        _emissionWeight = EmissionWeight(
            _pools,
            _weights,
            config.treasuryWeight,
            config.callerWeight,
            _protocol,
            _dev,
            _sum
        );
        emit EmissionWeightUpdated(_pools.length);
    }

    function setFactory(address factory) public governed {
        bytes4[] memory interfaces = new bytes4[](2);
        interfaces[0] = IMiningPoolFactory(0).newPool.selector;
        interfaces[1] = IMiningPoolFactory(0).poolType.selector;
        require(
            factory.supportsAllInterfaces(interfaces),
            "Not a valid factory"
        );
        bytes4 _sig = IMiningPoolFactory(factory).poolType();
        require(_factories[_sig] == address(0), "Factory already exists.");
        _factories[_sig] = factory;
    }

    function setTreasury(address treasury_) public governed {
        _treasury = treasury_;
    }

    function start() public override governed {
        require(_emissionStarted == 0, "Already started");
        _emissionStarted = block.timestamp.add(_startDelay).sub(1 weeks);
        emit Start();
    }

    function setEmissionCutRate(uint256 rate) public governed {
        require(
            1000 <= rate && rate <= 9000,
            "Emission cut should be greater than 10% and less than 90%"
        );
        _emissionCutRate = rate;
        emit EmissionCutRateUpdated(rate);
    }

    function setMinimumRate(uint256 rate) public governed {
        require(
            rate <= 134,
            "Protect from the superinflationary(99.8% per year) situation"
        );
        _minEmissionRatePerWeek = rate;
        emit EmissionRateUpdated(rate);
    }

    function distribute() public override nonReentrant {
        // current week from the mining start;
        uint256 weekNum =
            block.timestamp.sub(_emissionStarted).div(EMISSION_PERIOD);
        // The first token token drop will be started a week after the "start" func called.
        require(
            weekNum > _emissionWeekNum,
            "Already minted or not started yet."
        );
        // update emission week num
        _emissionWeekNum = weekNum;
        // allocate to mining pools
        uint256 weightSum = _emissionWeight.sum;
        uint256 prevSupply = IERC20(_token).totalSupply();
        for (uint256 i = 0; i < _emissionWeight.pools.length; i++) {
            require(i < _emissionWeight.pools.length, "out of index");
            uint256 weighted =
                _emissionWeight.weights[i].mul(_emission).div(weightSum);
            _mintAndNotifyAllocation(_emissionWeight.pools[i], weighted);
        }
        // Caller
        IERC20Mintable(_token).mint(
            msg.sender,
            _emissionWeight.caller.mul(_emission).div(weightSum)
        );
        if (_treasury != address(0)) {
            // Protocol fund(protocol treasury)
            IERC20Mintable(_token).mint(
                _treasury,
                _emissionWeight.treasury.mul(_emission).div(weightSum)
            );
        }
        // Protocol
        if (_protocolPool != address(0)) {
            IERC20Mintable(_token).mint(
                _protocolPool,
                _emissionWeight.protocol.mul(_emission).div(weightSum)
            );
            // balance diff automatically distributed. no approval needed
            IDividendPool(_protocolPool).distribute(_token, 0);
        }
        if (_initialContributorPool != address(0)) {
            // Founder
            _mintAndNotifyAllocation(
                _initialContributorPool,
                _emission.sub(IERC20(_token).totalSupply().sub(prevSupply))
            );
        }
        emit TokenEmission(_emission);
        _updateEmission();
    }

    function getNumberOfPools() public view returns (uint256) {
        return _emissionWeight.pools.length;
    }

    function getPoolWeight(uint256 poolIndex) public view returns (uint256) {
        return _emissionWeight.weights[poolIndex];
    }

    function token() public view override returns (address) {
        return _token;
    }

    function minEmissionRatePerWeek() public view override returns (uint256) {
        return _minEmissionRatePerWeek;
    }

    function emissionCutRate() public view override returns (uint256) {
        return _emissionCutRate;
    }

    function emission() public view override returns (uint256) {
        return _emission;
    }

    function initialContributorPool() public view override returns (address) {
        return _initialContributorPool;
    }

    function initialContributorShare() public view override returns (address) {
        return _initialContributorShare;
    }

    function treasury() public view override returns (address) {
        return _treasury;
    }

    function protocolPool() public view override returns (address) {
        return _protocolPool;
    }

    function pools(uint256 index) public view override returns (address) {
        return _emissionWeight.pools[index];
    }

    function emissionWeight()
        public
        view
        override
        returns (EmissionWeight memory)
    {
        return _emissionWeight;
    }

    function emissionStarted() public view override returns (uint256) {
        return _emissionStarted;
    }

    function emissionWeekNum() public view override returns (uint256) {
        return _emissionWeekNum;
    }

    function projId() public view override returns (uint256) {
        return _projId;
    }

    function poolTypes(address pool) public view override returns (bytes4) {
        return _poolTypes[pool];
    }

    function factories(bytes4 poolType) public view override returns (address) {
        return _factories[poolType];
    }

    function INITIAL_EMISSION() public view override returns (uint256) {
        return _INITIAL_EMISSION;
    }

    function FOUNDER_SHARE_DENOMINATOR()
        public
        view
        override
        returns (uint256)
    {
        return _FOUNDER_SHARE_DENOMINATOR;
    }

    function _mintAndNotifyAllocation(address miningPool, uint256 amount)
        private
    {
        IERC20Mintable(_token).mint(address(miningPool), amount);
        try IMiningPool(miningPool).allocate(amount) {
            // success
        } catch {
            // pool does not handled the emission
        }
    }

    function _updateEmission() private returns (uint256) {
        // Minimum emission 0.05% per week will make 2.63% of inflation per year
        uint256 minEmission =
            IERC20(_token).totalSupply().mul(_minEmissionRatePerWeek).div(
                DENOMINATOR
            );
        // Emission will be continuously halved until it reaches to its minimum emission. It will be about 10 weeks.
        uint256 cutEmission =
            _emission.mul(DENOMINATOR.sub(_emissionCutRate)).div(DENOMINATOR);
        _emission = Math.max(cutEmission, minEmission);
        return _emission;
    }

    function _getOrDeployPool(bytes4 poolType, address baseToken)
        internal
        returns (address _pool)
    {
        address _factory = _factories[poolType];
        require(_factory != address(0), "Factory not exists");
        // get predicted pool address
        _pool = IMiningPoolFactory(_factory).poolAddress(
            address(this),
            baseToken
        );
        if (_poolTypes[_pool] == poolType) {
            // pool is registered successfully
            return _pool;
        } else {
            // try to deploy new pool and register
            return newPool(poolType, baseToken);
        }
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "../../utils/Utils.sol";

contract Governed {
    using Utils for address[];

    bool private _initialized;
    address internal _gov;
    uint256 private _anarchizedAt = 0;
    uint256 private _forceAnarchizeAt = 0;

    event NewGovernance(
        address indexed _prevGovernance,
        address indexed _newGovernance
    );
    event Anarchized();

    constructor() {}

    modifier governed {
        require(msg.sender == _gov, "Not authorized");
        _;
    }

    function initialize(address gov_) public {
        require(!_initialized, "Initialized");
        _initialized = true;
        _gov = gov_;
    }

    function setGovernance(address gov_) public governed {
        require(gov_ != address(0), "Use anarchize() instead.");
        _setGovernance(gov_);
    }

    function setAnarchyPoint(uint256 timestamp) public governed {
        require(_forceAnarchizeAt == 0, "Cannot update.");
        require(
            timestamp >= block.timestamp,
            "Timepoint should be in the future."
        );
        _forceAnarchizeAt = timestamp;
    }

    function anarchize() public governed {
        _anarchize();
    }

    function forceAnarchize() public {
        require(_forceAnarchizeAt != 0, "Cannot disband the gov");
        require(block.timestamp >= _forceAnarchizeAt, "Cannot disband the gov");
        _anarchize();
    }

    function gov() public view returns (address) {
        return _gov;
    }

    function anarchizedAt() public view returns (uint256) {
        return _anarchizedAt;
    }

    function forceAnarchizeAt() public view returns (uint256) {
        return _forceAnarchizeAt;
    }

    function _anarchize() internal {
        _setGovernance(address(0));
        _anarchizedAt = block.timestamp;
        emit Anarchized();
    }

    function _setGovernance(address gov_) internal {
        emit NewGovernance(_gov, gov_);
        _gov = gov_;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IDividendPool {
    function distribute(address token, uint256 amount) external;

    function veVISION() external view returns (address);

    function veLocker() external view returns (address);

    function genesis() external view returns (uint256);

    function getEpoch(uint256 timestamp) external view returns (uint256);

    function getCurrentEpoch() external view returns (uint256);

    function distributedTokens() external view returns (address[] memory);

    function totalDistributed(address token) external view returns (uint256);

    function distributionBalance(address token) external view returns (uint256);

    function distributionOfWeek(address token, uint256 epochNum)
        external
        view
        returns (uint256);

    function claimStartWeek(address token, uint256 veLockId)
        external
        view
        returns (uint256);

    function claimable(address token) external view returns (uint256);

    function featuredRewards() external view returns (address[] memory);
}

//SPDX-License-Identifier: GPL-3.0
// This contract referenced Sushi's MasterChef.sol logic
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../core/emission/libraries/TokenEmitter.sol";
import "../../core/tokens/VISION.sol";

contract VisionEmitter is TokenEmitter {}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../core/governance/Governed.sol";

contract VISION is ERC20, Governed, Initializable {
    address private _minter;
    string private _name;
    string private _symbol;

    constructor() ERC20("", "") {
        // this constructor will not be called since it'll be cloned by proxy pattern.
        // initalize() will be called instead.
    }

    modifier onlyMinter {
        require(msg.sender == _minter, "Not a minter");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address minter_,
        address gov_
    ) public initializer {
        _name = name_;
        _symbol = symbol_;
        _minter = minter_;
        Governed.initialize(gov_);
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function setMinter(address minter_) public governed {
        _setMinter(minter_);
    }

    function _setMinter(address minter_) internal {
        _minter = minter_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function minter() public view returns (address) {
        return _minter;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IMiningPool {
    function allocate(uint256 amount) external;

    function setMiningPeriod(uint256 period) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "../../../core/emission/pools/ERC1155StakeMiningV1.sol";
import "../../../core/emission/libraries/MiningPoolFactory.sol";

contract ERC1155StakeMiningV1Factory is MiningPoolFactory {
    using ERC165Checker for address;
    /*
     *     // copied from openzeppelin ERC1155 spec impl
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    bytes4 public override poolType =
        ERC1155StakeMiningV1(0).erc1155StakeMiningV1.selector;

    constructor() MiningPoolFactory() {
        address _controller = address(new ERC1155StakeMiningV1());
        _setController(_controller);
    }

    function newPool(address _emitter, address _stakingToken)
        public
        override
        returns (address _pool)
    {
        require(
            _stakingToken.supportsInterface(_INTERFACE_ID_ERC1155),
            "Not an ERC1155"
        );
        return super.newPool(_emitter, _stakingToken);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "../../../core/emission/pools/ERC20BurnMiningV1.sol";
import "../../../core/emission/libraries/MiningPoolFactory.sol";

contract ERC20BurnMiningV1Factory is MiningPoolFactory {
    bytes4 public override poolType =
        ERC20BurnMiningV1(0).erc20BurnMiningV1.selector;

    constructor() MiningPoolFactory() {
        address _controller = address(new ERC20BurnMiningV1());
        _setController(_controller);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "../../../core/emission/pools/ERC721StakeMiningV1.sol";
import "../../../core/emission/libraries/MiningPoolFactory.sol";

contract ERC721StakeMiningV1Factory is MiningPoolFactory {
    using ERC165Checker for address;
    /*
     *     // copied from openzeppelin ERC721 spec impl
     *
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes4 public override poolType =
        ERC721StakeMiningV1(0).erc721StakeMiningV1.selector;

    constructor() MiningPoolFactory() {
        address _controller = address(new ERC721StakeMiningV1());
        _setController(_controller);
    }

    function newPool(address _emitter, address _stakingToken)
        public
        override
        returns (address _pool)
    {
        require(
            _stakingToken.supportsInterface(_INTERFACE_ID_ERC721),
            "Not an ERC721"
        );
        return super.newPool(_emitter, _stakingToken);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "../../../core/emission/libraries/MiningPoolFactory.sol";
import "../../../core/emission/pools/InitialContributorShare.sol";

contract InitialContributorShareFactory is MiningPoolFactory {
    using ERC165Checker for address;
    /*
     *     // copied from openzeppelin ERC1155 spec impl
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    bytes4 public override poolType =
        InitialContributorShare(0).initialContributorShare.selector;

    constructor() MiningPoolFactory() {
        address _controller = address(new InitialContributorShare());
        _setController(_controller);
    }

    function newPool(address _emitter, address _contributionBoard)
        public
        override
        returns (address _pool)
    {
        require(
            _contributionBoard.supportsInterface(_INTERFACE_ID_ERC1155),
            "Not an ERC1155"
        );
        return super.newPool(_emitter, _contributionBoard);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "../../../core/emission/pools/ERC20StakeMiningV1.sol";
import "../../../core/emission/libraries/MiningPoolFactory.sol";

contract ERC20StakeMiningV1Factory is MiningPoolFactory {
    bytes4 public override poolType =
        ERC20StakeMiningV1(0).erc20StakeMiningV1.selector;

    constructor() MiningPoolFactory() {
        address _controller = address(new ERC20StakeMiningV1());
        _setController(_controller);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "../../../core/emission/pools/ERC1155BurnMiningV1.sol";
import "../../../core/emission/libraries/MiningPoolFactory.sol";

contract ERC1155BurnMiningV1Factory is MiningPoolFactory {
    using ERC165Checker for address;
    /*
     *     // copied from openzeppelin ERC1155 spec impl
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    bytes4 public override poolType =
        ERC1155BurnMiningV1(0).erc1155BurnMiningV1.selector;

    constructor() MiningPoolFactory() {
        address _controller = address(new ERC1155BurnMiningV1());
        _setController(_controller);
    }

    function newPool(address _emitter, address _burningToken)
        public
        override
        returns (address _pool)
    {
        require(
            _burningToken.supportsInterface(_INTERFACE_ID_ERC1155),
            "Not an ERC1155"
        );
        return super.newPool(_emitter, _burningToken);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../../core/tokens/VISION.sol";
import "../../core/tokens/COMMIT.sol";
import "../../core/tokens/RIGHT.sol";
import "../../core/work/StableReserve.sol";
import "../../core/work/ContributionBoard.sol";
import "../../core/work/interfaces/IContributionBoard.sol";
import "../../core/governance/TimelockedGovernance.sol";
import "../../core/governance/WorkersUnion.sol";
import "../../core/governance/libraries/VoteCounter.sol";
import "../../core/governance/libraries/VotingEscrowLock.sol";
import "../../core/dividend/DividendPool.sol";
import "../../core/emission/VisionEmitter.sol";
import "../../core/emission/factories/ERC20BurnMiningV1Factory.sol";
import "../../core/emission/libraries/PoolType.sol";
import "../../core/marketplace/Marketplace.sol";

contract Project is ERC721, ERC20Recoverer {
    using Clones for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    struct DAO {
        address multisig;
        address baseCurrency;
        address timelock;
        address vision;
        address commit;
        address right;
        address stableReserve;
        address contributionBoard;
        address marketplace;
        address dividendPool;
        address voteCounter;
        address workersUnion;
        address visionEmitter;
        address votingEscrow;
    }

    struct CommonContracts {
        address pool2Factory;
        address weth;
        address sablier;
        address erc20StakeMiningV1Factory;
        address erc20BurnMiningV1Factory;
        address erc721StakeMiningV1Factory;
        address erc1155StakeMiningV1Factory;
        address erc1155BurnMiningV1Factory;
        address initialContributorShareFactory;
    }

    struct CloneParams {
        address multisig;
        address treasury;
        address baseCurrency;
        // Project
        string projectName;
        string projectSymbol;
        // tokens
        string visionName;
        string visionSymbol;
        string commitName;
        string commitSymbol;
        string rightName;
        string rightSymbol;
        uint256 emissionStartDelay;
        uint256 minDelay; // timelock
        uint256 voteLaunchDelay;
        uint256 initialEmission;
        uint256 minEmissionRatePerWeek;
        uint256 emissionCutRate;
        uint256 founderShare;
    }

    // Metadata for each project
    mapping(uint256 => uint256) private _growth;
    mapping(uint256 => string) private _nameOf;
    mapping(uint256 => string) private _symbolOf;
    mapping(uint256 => bool) private _immortalized;

    // Common contracts and controller(not upgradeable)
    CommonContracts private _commons;
    DAO private _controller;

    // Launched DAO's contracts
    mapping(uint256 => DAO) private _dao;
    uint256[] private _allDAOs;

    mapping(address => uint256) private _daoAddressBook;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _daoProjects; // timelock will be the pointing contract
    EnumerableMap.UintToAddressMap private _belongsTo;
    uint256 private projNum;

    event DAOLaunched(uint256 id);
    event NewProject(uint256 indexed daoId, uint256 id);
    event ProjectMoved(uint256 indexed from, uint256 indexed to);

    constructor(DAO memory controller, CommonContracts memory commons)
        ERC721("WORKHARD DAO", "WORKHARD")
    {
        _setBaseURI("ipfs://");
        _controller = controller;
        _commons = commons;
        uint256 masterDAOId = 0;
        address masterTimelock =
            Clones.predictDeterministicAddress(
                controller.timelock,
                bytes32(masterDAOId),
                address(this)
            );
        createProject(
            masterDAOId,
            "QmTFKqcLx9utcxSDLbfWicLnUDFACbrGjcQ6Yhz13qWDqS"
        );
        ERC20Recoverer.initialize(masterTimelock, new address[](0));
    }

    modifier onlyOwnerOf(uint256 id) {
        require(msg.sender == ownerOf(id), "Not the project owner");
        _;
    }

    /**
     * Creating a project for another forked DAO.
     */
    function createProject(uint256 daoId, string memory uri)
        public
        returns (uint256 id)
    {
        id = projNum;
        projNum++;
        require(_growth[id] < 1, "Already created.");
        require(
            daoId == 0 || _growth[daoId] == 4,
            "Parent project should be a DAO."
        );
        _growth[id] = 1;
        _mint(msg.sender, id);
        _setTokenURI(id, uri);
        address daoAddress = _getGovAddressOfDAO(daoId);
        _daoProjects[daoAddress].add(id);
        _belongsTo.set(id, daoAddress);
        emit NewProject(daoId, id);
        return id;
    }

    function upgradeToDAO(uint256 id, CloneParams memory params)
        public
        onlyOwnerOf(id)
    {
        require(_dao[id].vision == address(0), "Already upgraded.");
        _deploy(id);
        _initialize(id, params);
        _daoAddressBook[_getGovAddressOfDAO(id)] = id;
        // Now it does not belong to any dao. A new dao!
        _daoProjects[_belongsTo.get(id, "owner query for nonexistent token")]
            .remove(id);
        _belongsTo.remove(id);
        _nameOf[id] = params.projectName;
        _symbolOf[id] = params.projectSymbol;
        emit DAOLaunched(id);
        _allDAOs.push(id);
    }

    function launch(
        uint256 id,
        uint256 liquidityMiningRate,
        uint256 commitMiningRate,
        uint256 treasury,
        uint256 caller
    ) public onlyOwnerOf(id) {
        // 1. deploy sushi LP
        DAO storage fork = _dao[id];
        address lp =
            IUniswapV2Factory(_commons.pool2Factory).getPair(
                fork.vision,
                _commons.weth
            );
        if (lp == address(0)) {
            IUniswapV2Factory(_commons.pool2Factory).createPair(
                fork.vision,
                _commons.weth
            );
            lp = IUniswapV2Factory(_commons.pool2Factory).getPair(
                fork.vision,
                _commons.weth
            );
        }
        MiningConfig memory miningConfig;
        miningConfig.pools = new MiningPoolConfig[](2);
        miningConfig.pools[0] = MiningPoolConfig(
            liquidityMiningRate,
            PoolType.ERC20StakeMiningV1,
            lp
        );
        miningConfig.pools[1] = MiningPoolConfig(
            commitMiningRate,
            PoolType.ERC20BurnMiningV1,
            fork.commit
        );
        miningConfig.treasuryWeight = treasury;
        miningConfig.callerWeight = caller;
        _launch(id, miningConfig);
    }

    function immortalize(uint256 id) public onlyOwnerOf(id) {
        _immortalized[id] = true;
    }

    function updateURI(uint256 id, string memory uri) public onlyOwnerOf(id) {
        require(!_immortalized[id], "This project is immortalized.");
        _setTokenURI(id, uri);
    }

    function changeMultisig(uint256 id, address newMultisig) public {
        require(
            msg.sender == _dao[id].multisig,
            "Only the prev owner can change this value."
        );
        _dao[id].multisig = newMultisig;
    }

    function growth(uint256 id) public view returns (uint256) {
        return _growth[id];
    }

    function nameOf(uint256 id) public view returns (string memory) {
        return _nameOf[id];
    }

    function symbolOf(uint256 id) public view returns (string memory) {
        return _symbolOf[id];
    }

    function immortalized(uint256 id) public view returns (bool) {
        return _immortalized[id];
    }

    function daoOf(uint256 id) public view returns (uint256 daoId) {
        address daoAddress =
            _belongsTo.get(id, "owner query for nonexistent token");
        return _getDAOIdOfGov(daoAddress);
    }

    function projectsOf(uint256 daoId) public view returns (uint256 len) {
        return _daoProjects[_getGovAddressOfDAO(daoId)].length();
    }

    function projectsOfDAOByIndex(uint256 daoId, uint256 index)
        public
        view
        returns (uint256 id)
    {
        return _daoProjects[_getGovAddressOfDAO(daoId)].at(index);
    }

    function getMasterDAO() public view returns (DAO memory) {
        return _dao[0];
    }

    function getCommons() public view returns (CommonContracts memory) {
        return _commons;
    }

    function getDAO(uint256 id) public view returns (DAO memory) {
        return _dao[id];
    }

    function getAllDAOs() public view returns (uint256[] memory) {
        return _allDAOs;
    }

    function getController() public view returns (DAO memory) {
        return _controller;
    }

    function _deploy(uint256 id) internal {
        require(msg.sender == ownerOf(id));
        require(_growth[id] < 2, "Already deployed.");
        require(_growth[id] > 0, "Project does not exists.");
        _growth[id] = 2;
        DAO storage fork = _dao[id];
        bytes32 salt = bytes32(id);
        fork.timelock = _controller.timelock.cloneDeterministic(salt);
        fork.vision = _controller.vision.cloneDeterministic(salt);
        fork.commit = _controller.commit.cloneDeterministic(salt);
        fork.right = _controller.right.cloneDeterministic(salt);
        fork.stableReserve = _controller.stableReserve.cloneDeterministic(salt);
        fork.dividendPool = _controller.dividendPool.cloneDeterministic(salt);
        fork.voteCounter = _controller.voteCounter.cloneDeterministic(salt);
        fork.contributionBoard = _controller
            .contributionBoard
            .cloneDeterministic(salt);
        fork.marketplace = _controller.marketplace.cloneDeterministic(salt);
        fork.workersUnion = _controller.workersUnion.cloneDeterministic(salt);
        fork.visionEmitter = _controller.visionEmitter.cloneDeterministic(salt);
        fork.votingEscrow = _controller.votingEscrow.cloneDeterministic(salt);
    }

    function _initialize(uint256 id, CloneParams memory params) internal {
        require(msg.sender == ownerOf(id));

        require(_growth[id] < 3, "Already initialized.");
        require(_growth[id] > 1, "Contracts are not deployed.");
        _growth[id] = 3;
        DAO storage fork = _dao[id];
        fork.multisig = params.multisig;
        fork.baseCurrency = params.baseCurrency;

        DAO storage parentDAO =
            _dao[
                _getDAOIdOfGov(
                    _belongsTo.get(id, "owner query for nonexistent token")
                )
            ];

        require(
            params.founderShare >=
                ContributionBoard(parentDAO.contributionBoard).minimumShare(id),
            "founder share should be greater than the committed minimum share"
        );
        TimelockedGovernance(payable(fork.timelock)).initialize(
            params.minDelay,
            fork.multisig,
            fork.workersUnion
        );
        VISION(fork.vision).initialize(
            params.visionName,
            params.visionSymbol,
            fork.visionEmitter,
            fork.timelock
        );
        COMMIT(fork.commit).initialize(
            params.commitName,
            params.commitSymbol,
            fork.stableReserve
        );
        RIGHT(fork.right).initialize(
            params.rightName,
            params.rightSymbol,
            fork.votingEscrow
        );
        address[] memory stableReserveMinters = new address[](1);
        stableReserveMinters[0] = fork.contributionBoard;
        StableReserve(fork.stableReserve).initialize(
            fork.timelock,
            fork.commit,
            fork.baseCurrency,
            stableReserveMinters
        );
        ContributionBoard(fork.contributionBoard).initialize(
            address(this),
            fork.timelock,
            fork.dividendPool,
            fork.stableReserve,
            fork.commit,
            _commons.sablier
        );
        Marketplace(fork.marketplace).initialize(
            fork.timelock,
            fork.commit,
            fork.dividendPool
        );
        address[] memory _rewardTokens = new address[](2);
        _rewardTokens[0] = fork.commit;
        _rewardTokens[1] = fork.baseCurrency;
        DividendPool(fork.dividendPool).initialize(
            fork.timelock,
            fork.right,
            _rewardTokens
        );
        VoteCounter(fork.voteCounter).initialize(fork.right);
        WorkersUnion(payable(fork.workersUnion)).initialize(
            fork.voteCounter,
            fork.timelock,
            params.voteLaunchDelay
        );
        VisionEmitter(fork.visionEmitter).initialize(
            EmitterConfig(
                id,
                params.initialEmission,
                params.minEmissionRatePerWeek,
                params.emissionCutRate,
                params.founderShare,
                params.emissionStartDelay,
                params.treasury,
                address(this), // gov => will be transfered to timelock
                fork.vision,
                id != 0 ? parentDAO.dividendPool : address(0),
                parentDAO.contributionBoard,
                _commons.erc20BurnMiningV1Factory,
                _commons.erc20StakeMiningV1Factory,
                _commons.erc721StakeMiningV1Factory,
                _commons.erc1155StakeMiningV1Factory,
                _commons.erc1155BurnMiningV1Factory,
                _commons.initialContributorShareFactory
            )
        );
        VotingEscrowLock(fork.votingEscrow).initialize(
            string(abi.encodePacked(params.projectName, " Voting Escrow Lock")),
            string(abi.encodePacked(params.projectSymbol, "-VE-LOCK")),
            fork.vision,
            fork.right,
            fork.timelock
        );
    }

    function _launch(uint256 id, MiningConfig memory config) internal {
        require(_growth[id] < 4, "Already launched.");
        require(_growth[id] > 2, "Not initialized.");
        _growth[id] = 4;

        DAO storage fork = _dao[id];
        // 1. set emission
        VisionEmitter(fork.visionEmitter).setEmission(config);
        // 2. start emission
        VisionEmitter(fork.visionEmitter).start();
        // 3. transfer governance
        VisionEmitter(fork.visionEmitter).setGovernance(fork.timelock);
        // 4. transfer ownership to timelock
        _transfer(msg.sender, fork.timelock, id);
        // 5. No more initial contribution record
        address initialContributorPool =
            VisionEmitter(fork.visionEmitter).initialContributorPool();
        IContributionBoard(IMiningPool(initialContributorPool).baseToken())
            .finalize(id);
    }

    /**
     * @notice it returns timelock governance contract's address.
     */
    function _getGovAddressOfDAO(uint256 id) private view returns (address) {
        return
            Clones.predictDeterministicAddress(
                _controller.timelock,
                bytes32(id),
                address(this)
            );
    }

    /**
     * @notice it can return only launched DAO's token id.
     */
    function _getDAOIdOfGov(address daoAddress)
        private
        view
        returns (uint256 daoId)
    {
        return _daoAddressBook[daoAddress];
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../core/governance/libraries/VotingEscrowToken.sol";

contract RIGHT is VotingEscrowToken {
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../../core/governance/interfaces/IVotingEscrowToken.sol";
import "../../../utils/Int128.sol";

/**
 * @dev Voting Escrow Token is the solidity implementation of veCRV
 *      Its original code https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
 */

contract VotingEscrowToken is ERC20, IVotingEscrowToken, Initializable {
    using SafeMath for uint256;
    using Int128 for uint256;

    uint256 public constant MAXTIME = 4 * (365 days);
    uint256 public constant MULTIPLIER = 1e18;

    address private _veLocker;
    mapping(uint256 => int128) private _slopeChanges;
    Point[] private _pointHistory;
    mapping(uint256 => Point[]) private _lockPointHistory;
    string private _name;
    string private _symbol;

    modifier onlyVELock() {
        require(
            msg.sender == _veLocker,
            "Only ve lock contract can call this."
        );
        _;
    }

    constructor() ERC20("", "") {
        // this constructor will not be called since it'll be cloned by proxy pattern.
        // initalize() will be called instead.
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address veLocker_
    ) public initializer {
        _name = name_;
        _symbol = symbol_;
        _veLocker = veLocker_;
    }

    function checkpoint(uint256 maxRecord) external override {
        // Point memory lastPoint = _recordPointHistory();
        // pointHistory[epoch] = lastPoint;
        _recordPointHistory(maxRecord);
    }

    function checkpoint(
        uint256 veLockId,
        Lock calldata oldLock,
        Lock calldata newLock
    ) external onlyVELock {
        // Record history
        _recordPointHistory(0);

        // Compute points
        (Point memory oldLockPoint, Point memory newLockPoint) =
            _computePointsFromLocks(oldLock, newLock);

        _updateLastPoint(oldLockPoint, newLockPoint);

        _recordLockPointHistory(
            veLockId,
            oldLock,
            newLock,
            oldLockPoint,
            newLockPoint
        );
    }

    // View functions

    function veLocker() public view virtual override returns (address) {
        return _veLocker;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure virtual override returns (uint8) {
        return 18;
    }

    function balanceOf(address account)
        public
        view
        override(IERC20, ERC20)
        returns (uint256)
    {
        uint256 numOfLocks = IERC721Enumerable(_veLocker).balanceOf(account);
        uint256 balance = 0;
        for (uint256 i = 0; i < numOfLocks; i++) {
            uint256 veLockId =
                IERC721Enumerable(_veLocker).tokenOfOwnerByIndex(account, i);
            balance = balance.add(balanceOfLock(veLockId));
        }
        return balance;
    }

    function balanceOfAt(address account, uint256 timestamp)
        public
        view
        override
        returns (uint256)
    {
        uint256 numOfLocks = IERC721Enumerable(_veLocker).balanceOf(account);
        uint256 balance = 0;
        for (uint256 i = 0; i < numOfLocks; i++) {
            uint256 veLockId =
                IERC721Enumerable(_veLocker).tokenOfOwnerByIndex(account, i);
            balance = balance.add(balanceOfLockAt(veLockId, timestamp));
        }
        return balance;
    }

    function balanceOfLock(uint256 veLockId)
        public
        view
        override
        returns (uint256)
    {
        return balanceOfLockAt(veLockId, block.timestamp);
    }

    function balanceOfLockAt(uint256 veLockId, uint256 timestamp)
        public
        view
        override
        returns (uint256)
    {
        (bool success, Point memory point) =
            _searchClosestPoint(_lockPointHistory[veLockId], timestamp);
        if (success) {
            int128 bal =
                point.bias -
                    point.slope *
                    (timestamp.toInt128() - point.timestamp.toInt128());
            return bal > 0 ? uint256(bal) : 0;
        } else {
            return 0;
        }
    }

    function totalSupply()
        public
        view
        override(IERC20, ERC20)
        returns (uint256)
    {
        return totalSupplyAt(block.timestamp);
    }

    function totalSupplyAt(uint256 timestamp)
        public
        view
        override
        returns (uint256)
    {
        (bool success, Point memory point) =
            _searchClosestPoint(_pointHistory, timestamp);
        if (success) {
            return _computeSupplyFrom(point, timestamp);
        } else {
            return 0;
        }
    }

    function slopeChanges(uint256 timestamp)
        public
        view
        override
        returns (int128)
    {
        return _slopeChanges[timestamp];
    }

    function pointHistory(uint256 index)
        public
        view
        override
        returns (Point memory)
    {
        return _pointHistory[index];
    }

    function lockPointHistory(uint256 index)
        public
        view
        override
        returns (Point[] memory)
    {
        return _lockPointHistory[index];
    }

    // checkpoint() should be called if it emits out of gas error.
    function _computeSupplyFrom(Point memory point, uint256 timestamp)
        internal
        view
        returns (uint256)
    {
        require(point.timestamp <= timestamp, "scan only to the rightward");
        Point memory _point = point;
        uint256 x = (point.timestamp / 1 weeks) * 1 weeks;

        // find the closest point
        do {
            x = Math.min(x + 1 weeks, timestamp);
            uint256 delta = x - point.timestamp; // always greater than 0
            _point.timestamp = x;
            _point.bias -= (_point.slope) * int128(delta);
            _point.slope += _slopeChanges[x];
            _point.bias = _point.bias > 0 ? _point.bias : 0;
            _point.slope = _point.slope > 0 ? _point.slope : 0;
        } while (timestamp != x);
        int128 y = _point.bias - _point.slope * (timestamp - x).toInt128();
        return y > 0 ? uint256(y) : 0;
    }

    function _computePointsFromLocks(Lock memory oldLock, Lock memory newLock)
        internal
        view
        returns (Point memory oldPoint, Point memory newPoint)
    {
        if (oldLock.end > block.timestamp && oldLock.amount > 0) {
            oldPoint.slope = (oldLock.amount / MAXTIME).toInt128();
            oldPoint.bias =
                oldPoint.slope *
                int128(oldLock.end - block.timestamp);
        }
        if (newLock.end > block.timestamp && newLock.amount > 0) {
            newPoint.slope = (newLock.amount / MAXTIME).toInt128();
            newPoint.bias =
                newPoint.slope *
                int128((newLock.end - block.timestamp));
        }
    }

    function _recordPointHistory(uint256 maxRecord) internal {
        // last_point: Point = Point({bias: 0, slope: 0, ts: block.timestamp})
        Point memory _point;
        // Get the latest right most point
        if (_pointHistory.length > 0) {
            _point = _pointHistory[_pointHistory.length - 1];
        } else {
            _point = Point({bias: 0, slope: 0, timestamp: block.timestamp});
        }

        // fill history
        uint256 timestamp = block.timestamp;
        uint256 x = (_point.timestamp / 1 weeks) * 1 weeks;
        // record intermediate histories
        uint256 i = 0;
        do {
            x = Math.min(x + 1 weeks, timestamp);
            uint256 delta = Math.min(timestamp - x, 1 weeks);
            _point.timestamp = x;
            _point.bias -= (_point.slope) * int128(delta);
            _point.slope += _slopeChanges[x];
            _point.bias = _point.bias > 0 ? _point.bias : 0;
            _point.slope = _point.slope > 0 ? _point.slope : 0;
            _pointHistory.push(_point);
            i++;
        } while (timestamp != x && i != maxRecord);
    }

    function _recordLockPointHistory(
        uint256 veLockId,
        Lock memory oldLock,
        Lock memory newLock,
        Point memory oldPoint,
        Point memory newPoint
    ) internal {
        require(
            (oldLock.end / 1 weeks) * 1 weeks == oldLock.end,
            "should be exact epoch timestamp"
        );
        require(
            (newLock.end / 1 weeks) * 1 weeks == newLock.end,
            "should be exact epoch timestamp"
        );
        int128 oldSlope = _slopeChanges[oldLock.end];
        int128 newSlope;
        if (newLock.end != 0) {
            if (newLock.end == oldLock.end) {
                newSlope = oldSlope;
            } else {
                newSlope = _slopeChanges[newLock.end];
            }
        }
        if (oldLock.end > block.timestamp) {
            oldSlope += oldPoint.slope;
            if (newLock.end == oldLock.end) {
                oldSlope -= newPoint.slope;
            }
            _slopeChanges[oldLock.end] = oldSlope;
        }
        if (newLock.end > block.timestamp) {
            if (newLock.end > oldLock.end) {
                newSlope -= newPoint.slope;
                _slopeChanges[newLock.end] = newSlope;
            }
        }
        newPoint.timestamp = block.timestamp;
        _lockPointHistory[veLockId].push(newPoint);
    }

    function _updateLastPoint(
        Point memory oldLockPoint,
        Point memory newLockPoint
    ) internal {
        if (_pointHistory.length == 0) {
            _pointHistory.push(
                Point({bias: 0, slope: 0, timestamp: block.timestamp})
            );
        }
        Point memory newLastPoint =
            _computeTheLatestSupplyGraphPoint(
                oldLockPoint,
                newLockPoint,
                _pointHistory[_pointHistory.length - 1]
            );
        _pointHistory[_pointHistory.length - 1] = newLastPoint;
    }

    function _computeTheLatestSupplyGraphPoint(
        Point memory oldLockPoint,
        Point memory newLockPoint,
        Point memory lastPoint
    ) internal pure returns (Point memory newLastPoint) {
        newLastPoint = lastPoint;
        newLastPoint.slope += (newLockPoint.slope - oldLockPoint.slope);
        newLastPoint.bias += (newLockPoint.bias - oldLockPoint.bias);
        if (newLastPoint.slope < 0) {
            newLastPoint.slope = 0;
        }
        if (newLastPoint.bias < 0) {
            newLastPoint.bias = 0;
        }
    }

    function _searchClosestPoint(Point[] storage history, uint256 timestamp)
        internal
        view
        returns (bool success, Point memory point)
    {
        require(timestamp <= block.timestamp, "Only past blocks");
        if (history.length == 0) {
            return (false, point);
        } else if (timestamp < history[0].timestamp) {
            // block num is before the first lock
            return (false, point);
        } else if (timestamp == block.timestamp) {
            return (true, history[history.length - 1]);
        }
        // binary search
        uint256 min = 0;
        uint256 max = history.length - 1;
        uint256 mid;
        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) {
                break;
            }
            mid = (min + max + 1) / 2;
            if (history[mid].timestamp <= timestamp) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return (true, history[min]);
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256
    ) internal pure override {
        revert("Non-transferrable. You can only transfer locks.");
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Point {
    int128 bias;
    int128 slope;
    uint256 timestamp;
}

struct Lock {
    uint256 amount;
    uint256 start;
    uint256 end;
}

interface IVotingEscrowToken is IERC20 {
    function veLocker() external view returns (address);

    function checkpoint(uint256 maxRecord) external;

    function totalSupplyAt(uint256 timestamp) external view returns (uint256);

    function balanceOfAt(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function balanceOfLock(uint256 veLockId) external view returns (uint256);

    function balanceOfLockAt(uint256 veLockId, uint256 timestamp)
        external
        view
        returns (uint256);

    function slopeChanges(uint256 timestamp) external view returns (int128);

    function pointHistory(uint256 index) external view returns (Point memory);

    function lockPointHistory(uint256 index)
        external
        view
        returns (Point[] memory);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../core/work/interfaces/IStableReserve.sol";
import "../../core/work/interfaces/IGrantReceiver.sol";
import "../../core/tokens/COMMIT.sol";
import "../../core/governance/Governed.sol";
import "../../utils/ERC20Recoverer.sol";

/**
 * @notice StableReserve is the $COMMIT minter. It allows ContributionBoard to mint $COMMIT token.
 */
contract StableReserve is ERC20Recoverer, Governed, IStableReserve {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address private _commitToken;
    address private _baseCurrency;
    uint256 private _priceOfCommit;
    mapping(address => bool) private _allowed; // allowed crypto job board contracts
    address private _deployer;

    function initialize(
        address gov_,
        address commitToken_,
        address baseCurrency_,
        address[] memory admins
    ) public initializer {
        _priceOfCommit = 20000; // denominator = 10000, ~= $2
        _commitToken = commitToken_;
        _baseCurrency = baseCurrency_;

        address[] memory disable = new address[](2);
        disable[0] = commitToken_;
        disable[1] = baseCurrency_;
        ERC20Recoverer.initialize(gov_, disable);
        Governed.initialize(gov_);
        _deployer = msg.sender;
        _allow(gov_, true);
        for (uint256 i = 0; i < admins.length; i++) {
            _allow(admins[i], true);
        }
    }

    modifier onlyAllowed() {
        require(_allowed[msg.sender], "Not authorized");
        _;
    }

    function redeem(uint256 amount) public override {
        require(
            COMMIT(_commitToken).balanceOf(msg.sender) >= amount,
            "Not enough balance"
        );
        COMMIT(_commitToken).burnFrom(msg.sender, amount);
        IERC20(_baseCurrency).transfer(msg.sender, amount);
        emit Redeemed(msg.sender, amount);
    }

    function payInsteadOfWorking(uint256 amount) public override {
        uint256 amountToPay = amount.mul(_priceOfCommit).div(10000);
        IERC20(_baseCurrency).safeTransferFrom(
            msg.sender,
            address(this),
            amountToPay
        );
        _mintCOMMIT(msg.sender, amount);
    }

    function reserveAndMint(uint256 amount) public override onlyAllowed {
        IERC20(_baseCurrency).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        _mintCOMMIT(msg.sender, amount);
    }

    function grant(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public override governed {
        _mintCOMMIT(recipient, amount);
        bytes memory returndata =
            address(recipient).functionCall(
                abi.encodeWithSelector(
                    IGrantReceiver(recipient).receiveGrant.selector,
                    _commitToken,
                    amount,
                    data
                ),
                "GrantReceiver: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "GrantReceiver: low-level call failed"
            );
        }
    }

    function allow(address account, bool active) public override governed {
        _allow(account, active);
    }

    function baseCurrency() public view override returns (address) {
        return _baseCurrency;
    }

    function commitToken() public view override returns (address) {
        return _commitToken;
    }

    function priceOfCommit() public view override returns (uint256) {
        return _priceOfCommit;
    }

    function mintable() public view override returns (uint256) {
        uint256 currentSupply = COMMIT(_commitToken).totalSupply();
        uint256 currentRedeemable =
            IERC20(_baseCurrency).balanceOf(address(this));
        return currentRedeemable.sub(currentSupply);
    }

    function allowed(address account) public view override returns (bool) {
        return _allowed[account];
    }

    function _mintCOMMIT(address to, uint256 amount) internal {
        require(amount <= mintable(), "Not enough reserve");
        COMMIT(_commitToken).mint(to, amount);
    }

    function _allow(address account, bool active) internal {
        if (_allowed[account] != active) {
            emit AdminUpdated(account);
        }
        _allowed[account] = active;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IStableReserve {
    event AdminUpdated(address indexed minter);
    event Redeemed(address to, uint256 amount);

    function redeem(uint256 amount) external;

    function payInsteadOfWorking(uint256 amount) external;

    function reserveAndMint(uint256 amount) external;

    function grant(
        address recipient,
        uint256 amount,
        bytes memory data
    ) external;

    function allow(address account, bool active) external;

    function baseCurrency() external view returns (address);

    function commitToken() external view returns (address);

    function priceOfCommit() external view returns (uint256);

    function allowed(address account) external view returns (bool);

    function mintable() external view returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IGrantReceiver {
    function receiveGrant(
        address currency,
        uint256 amount,
        bytes calldata data
    ) external returns (bool result);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "../../core/governance/Governed.sol";
import "../../core/work/libraries/CommitMinter.sol";
import "../../core/work/libraries/GrantReceiver.sol";
import "../../core/work/interfaces/IStableReserve.sol";
import "../../core/work/interfaces/IContributionBoard.sol";
import "../../core/dividend/libraries/Distributor.sol";
import "../../core/dividend/interfaces/IDividendPool.sol";
import "../../utils/IERC1620.sol";
import "../../utils/Utils.sol";

contract ContributionBoard is
    CommitMinter,
    GrantReceiver,
    Distributor,
    Governed,
    ReentrancyGuard,
    Initializable,
    ERC1155Burnable,
    IContributionBoard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using Utils for address[];

    address private _sablier;
    IERC721 private _project;
    mapping(uint256 => uint256) private _projectFund;
    mapping(uint256 => uint256) private _totalSupplyOf;
    mapping(uint256 => uint256) private _maxSupplyOf;
    mapping(uint256 => uint256) private _minimumShare;
    mapping(uint256 => bool) private _fundingPaused;
    mapping(uint256 => bool) private _finalized;
    mapping(uint256 => uint256) private _projectOf;
    mapping(uint256 => uint256[]) private _streams;
    mapping(uint256 => address[]) private _contributors;

    constructor() ERC1155("") {
        // this will not be called
    }

    function initialize(
        address project_,
        address gov_,
        address dividendPool_,
        address stableReserve_,
        address commit_,
        address sablier_
    ) public initializer {
        CommitMinter._setup(stableReserve_, commit_);
        Distributor._setup(dividendPool_);
        _project = IERC721(project_);
        _sablier = sablier_;
        Governed.initialize(gov_);
        _setURI("");

        // register the supported interfaces to conform to ERC1155 via ERC165
        bytes4 _INTERFACE_ID_ERC165 = 0x01ffc9a7;
        bytes4 _INTERFACE_ID_ERC1155 = 0xd9b67a26;
        bytes4 _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(_INTERFACE_ID_ERC1155);
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    modifier onlyStableReserve() {
        require(
            address(stableReserve) == msg.sender,
            "Only the stable reserves can call this function"
        );
        _;
    }

    modifier onlyProjectOwner(uint256 projId) {
        require(_project.ownerOf(projId) == msg.sender, "Not authorized");
        _;
    }

    function addProjectFund(uint256 projId, uint256 amount) public override {
        require(!_fundingPaused[projId], "Should resume funding");
        IERC20(commitToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256 updated = _projectFund[projId].add(amount);
        _projectFund[projId] = updated;
        if (_initialContributorShareProgram(projId)) {
            // record funding
            _recordContribution(msg.sender, projId, amount);
        }
    }

    function startInitialContributorShareProgram(
        uint256 projectId,
        uint256 minimumShare_,
        uint256 maxContribution
    ) public override onlyProjectOwner(projectId) {
        require(0 < minimumShare_, "Should be greater than 0");
        require(minimumShare_ < 10000, "Cannot be greater than denominator");
        require(_minimumShare[projectId] == 0, "Funding is already enabled.");
        _minimumShare[projectId] = minimumShare_;
        _setMaxContribution(projectId, maxContribution);
    }

    /**
     * @notice Usually the total supply = funded + paid. If you want to raise
     *         10000 COMMITs you should set the max contribution at least 20000.
     */
    function setMaxContribution(uint256 projectId, uint256 maxContribution)
        public
        override
        onlyProjectOwner(projectId)
    {
        _setMaxContribution(projectId, maxContribution);
    }

    function pauseFunding(uint256 projectId)
        public
        override
        onlyProjectOwner(projectId)
    {
        require(!_fundingPaused[projectId], "Already paused");
        _fundingPaused[projectId] = true;
    }

    function resumeFunding(uint256 projectId)
        public
        override
        onlyProjectOwner(projectId)
    {
        require(_fundingPaused[projectId], "Already unpaused");
        _fundingPaused[projectId] = false;
    }

    function compensate(
        uint256 projectId,
        address to,
        uint256 amount
    ) public override onlyProjectOwner(projectId) {
        require(_projectFund[projectId] >= amount, "Not enough fund.");
        _projectFund[projectId] = _projectFund[projectId] - amount; // "require" protects underflow
        IERC20(commitToken).safeTransfer(to, amount);
        _recordContribution(to, projectId, amount);
        emit Payed(projectId, to, amount);
    }

    function compensateInStream(
        uint256 projectId,
        address to,
        uint256 amount,
        uint256 period
    ) public override onlyProjectOwner(projectId) {
        require(_projectFund[projectId] >= amount);
        _projectFund[projectId] = _projectFund[projectId] - amount; // "require" protects underflow
        _recordContribution(to, projectId, amount);
        IERC20(commitToken).approve(_sablier, amount); // approve the transfer
        uint256 streamId =
            IERC1620(_sablier).createStream(
                to,
                amount,
                commitToken,
                block.timestamp,
                block.timestamp + period
            );

        _projectOf[streamId] = projectId;
        _streams[projectId].push(streamId);
        emit PayedInStream(projectId, to, amount, streamId);
    }

    function cancelStream(uint256 projectId, uint256 streamId)
        public
        override
        onlyProjectOwner(projectId)
    {
        require(projectOf(streamId) == projectId, "Invalid project id");

        (
            ,
            address recipient,
            uint256 deposit,
            ,
            uint256 startTime,
            uint256 stopTime,
            ,
            uint256 ratePerSecond
        ) = IERC1620(_sablier).getStream(streamId);

        uint256 earned = Math.min(block.timestamp, stopTime).sub(startTime);
        uint256 remaining = deposit.sub(ratePerSecond.mul(earned));
        require(IERC1620(_sablier).cancelStream(streamId), "Failed to cancel");

        _projectFund[projectId] = _projectFund[projectId].add(remaining);
        uint256 cancelContribution =
            Math.min(balanceOf(recipient, projectId), remaining);
        _burn(recipient, projectId, cancelContribution);
    }

    function recordContribution(
        address to,
        uint256 id,
        uint256 amount
    ) external override onlyProjectOwner(id) {
        require(
            !_initialContributorShareProgram(id),
            "Once it starts to get funding, you cannot record additional contribution"
        );
        require(
            _recordContribution(to, id, amount),
            "Cannot record after it's launched."
        );
    }

    function finalize(uint256 id) external override {
        require(
            msg.sender == address(_project),
            "this should be called only for upgrade"
        );
        require(!_finalized[id], "Already _finalized");
        _finalized[id] = true;
    }

    function receiveGrant(
        address currency,
        uint256 amount,
        bytes calldata data
    ) external override onlyStableReserve returns (bool result) {
        require(
            currency == commitToken,
            "Only can get $COMMIT token for its grant"
        );
        uint256 projId = abi.decode(data, (uint256));
        require(_project.ownerOf(projId) != address(0), "No budget owner");
        _projectFund[projId] = _projectFund[projId].add(amount);
        emit Grant(projId, amount);
        return true;
    }

    function sablier() public view override returns (address) {
        return _sablier;
    }

    function project() public view override returns (address) {
        return address(_project);
    }

    function projectFund(uint256 projId)
        public
        view
        override
        returns (uint256)
    {
        return _projectFund[projId];
    }

    function totalSupplyOf(uint256 projId)
        public
        view
        override
        returns (uint256)
    {
        return _totalSupplyOf[projId];
    }

    function maxSupplyOf(uint256 projId)
        public
        view
        override
        returns (uint256)
    {
        return _maxSupplyOf[projId];
    }

    function initialContributorShareProgram(uint256 projId)
        public
        view
        override
        returns (bool)
    {
        return _initialContributorShareProgram(projId);
    }

    function minimumShare(uint256 projId)
        public
        view
        override
        returns (uint256)
    {
        return _minimumShare[projId];
    }

    function fundingPaused(uint256 projId) public view override returns (bool) {
        return _fundingPaused[projId];
    }

    function finalized(uint256 projId) public view override returns (bool) {
        return _finalized[projId];
    }

    function projectOf(uint256 streamId)
        public
        view
        override
        returns (uint256 id)
    {
        return _projectOf[streamId];
    }

    function getStreams(uint256 projId)
        public
        view
        override
        returns (uint256[] memory)
    {
        return _streams[projId];
    }

    function getContributors(uint256 projId)
        public
        view
        override
        returns (address[] memory)
    {
        return _contributors[projId];
    }

    function uri(uint256 id)
        external
        view
        override(ERC1155, IContributionBoard)
        returns (string memory)
    {
        return IERC721Metadata(address(_project)).tokenURI(id);
    }

    function _setMaxContribution(uint256 id, uint256 maxContribution) internal {
        require(!_finalized[id], "DAO is launched. You cannot update it.");
        _maxSupplyOf[id] = maxContribution;
        emit NewMaxContribution(id, maxContribution);
    }

    function _recordContribution(
        address to,
        uint256 id,
        uint256 amount
    ) internal returns (bool) {
        if (_finalized[id]) return false;
        (bool exist, ) = _contributors[id].find(to);
        if (!exist) {
            _contributors[id].push(to);
        }
        bytes memory zero;
        _mint(to, id, amount, zero);
        return true;
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._mint(account, id, amount, data);
        _totalSupplyOf[id] = _totalSupplyOf[id].add(amount);
        require(
            _maxSupplyOf[id] == 0 || _totalSupplyOf[id] <= _maxSupplyOf[id],
            "Exceeds the max supply. Set a new max supply value."
        );
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override {
        super._burn(account, id, amount);
        _totalSupplyOf[id] = _totalSupplyOf[id].sub(amount);
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal override {
        if (from == address(0) || to == address(0)) {
            // contribution can be minted or burned before the dao launch
        } else {
            // transfer is only allowed after the finalization
            for (uint256 i = 0; i < ids.length; i++) {
                require(_finalized[ids[i]], "Not finalized");
            }
        }
    }

    function _initialContributorShareProgram(uint256 projId)
        internal
        view
        returns (bool)
    {
        return _minimumShare[projId] != 0;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../core/work/interfaces/IStableReserve.sol";

contract CommitMinter {
    using SafeERC20 for IERC20;

    address public stableReserve;
    address public commitToken;

    function _setup(address _stableReserve, address _commit) internal {
        stableReserve = _stableReserve;
        commitToken = _commit;
    }

    function _mintCommit(uint256 amount) internal virtual {
        address _baseCurrency = IStableReserve(stableReserve).baseCurrency();
        IERC20(_baseCurrency).safeApprove(address(stableReserve), amount);
        IStableReserve(stableReserve).reserveAndMint(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "../../../core/work/interfaces/IGrantReceiver.sol";

abstract contract GrantReceiver is IGrantReceiver {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";

interface IContributionBoard is IERC1155MetadataURI {
    event ManagerUpdated(address indexed manager, bool active);
    event ProjectPosted(uint256 projId);
    event ProjectClosed(uint256 projId);
    event Grant(uint256 projId, uint256 amount);
    event Payed(uint256 projId, address to, uint256 amount);
    event PayedInStream(
        uint256 projId,
        address to,
        uint256 amount,
        uint256 streamId
    );
    event ProjectFunded(uint256 indexed projId, uint256 amount);
    event NewMaxContribution(uint256 _id, uint256 _maxContribution);

    function finalize(uint256 id) external;

    function addProjectFund(uint256 projId, uint256 amount) external;

    function startInitialContributorShareProgram(
        uint256 projectId,
        uint256 _minimumShare,
        uint256 _maxContribution
    ) external;

    function setMaxContribution(uint256 projectId, uint256 maxContribution)
        external;

    function pauseFunding(uint256 projectId) external;

    function resumeFunding(uint256 projectId) external;

    function compensate(
        uint256 projectId,
        address to,
        uint256 amount
    ) external;

    function compensateInStream(
        uint256 projectId,
        address to,
        uint256 amount,
        uint256 period
    ) external;

    function cancelStream(uint256 projectId, uint256 streamId) external;

    function recordContribution(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function sablier() external view returns (address);

    function project() external view returns (address);

    function projectFund(uint256 projId) external view returns (uint256);

    function totalSupplyOf(uint256 projId) external view returns (uint256);

    function maxSupplyOf(uint256 projId) external view returns (uint256);

    function initialContributorShareProgram(uint256 projId)
        external
        view
        returns (bool);

    function minimumShare(uint256 projId) external view returns (uint256);

    function fundingPaused(uint256 projId) external view returns (bool);

    function finalized(uint256 projId) external view returns (bool);

    function projectOf(uint256 streamId) external view returns (uint256 id);

    function getStreams(uint256 projId)
        external
        view
        returns (uint256[] memory);

    function getContributors(uint256 projId)
        external
        view
        returns (address[] memory);

    function uri(uint256 id) external view override returns (string memory);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../core/dividend/interfaces/IDividendPool.sol";

contract Distributor {
    using SafeERC20 for IERC20;

    IDividendPool public dividendPool;

    function _setup(address _dividendPool) internal {
        dividendPool = IDividendPool(_dividendPool);
    }

    function _distribute(address currency, uint256 amount) internal virtual {
        IERC20(currency).safeApprove(address(dividendPool), amount);
        dividendPool.distribute(currency, amount);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/TimelockController.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

/**
 * @notice Gnosis Safe Multisig wallet has the Ownership of this contract.
 *      In the future, We can transfer the ownership to a well-formed governance contract.
 *      **Ownership grpah**
 *      TimelockedGovernance -controls-> COMMIT, ContributionBoard, Market, DividendPool, and VisionEmitter
 *      VisionEmitter -controls-> VISION
 */
contract TimelockedGovernance is TimelockController, Initializable {
    mapping(bytes32 => bool) public nonCancelable;

    constructor()
        TimelockController(1 days, new address[](0), new address[](0))
    {
        // this constructor will not be called since it'll be cloned by proxy pattern.
        // initalize() will be called instead.
    }

    function initialize(
        uint256 delay,
        address multisig,
        address workersUnion
    ) public initializer {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));
        _setupRole(TIMELOCK_ADMIN_ROLE, workersUnion);
        _setupRole(PROPOSER_ROLE, workersUnion);
        _setupRole(PROPOSER_ROLE, multisig);
        _setupRole(EXECUTOR_ROLE, workersUnion);
        _setupRole(EXECUTOR_ROLE, multisig);
        TimelockController(this).updateDelay(delay);
    }

    function cancel(bytes32 id) public override {
        require(!nonCancelable[id], "non-cancelable");
        super.cancel(id);
    }

    function forceSchedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        nonCancelable[id] = true;
        super.schedule(target, value, data, predecessor, salt, delay);
    }

    function forceScheduleBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public {
        bytes32 id = hashOperationBatch(target, value, data, predecessor, salt);
        nonCancelable[id] = true;
        super.scheduleBatch(target, value, data, predecessor, salt, delay);
    }

    function scheduleBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public override {
        super.scheduleBatch(target, value, data, predecessor, salt, delay);
    }

    function executeBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable override {
        super.executeBatch(target, value, data, predecessor, salt);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../core/dividend/interfaces/IDividendPool.sol";
import "../../core/governance/Governed.sol";
import "../../core/governance/TimelockedGovernance.sol";
import "../../core/governance/interfaces/IVoteCounter.sol";
import "../../core/governance/interfaces/IWorkersUnion.sol";
import "../../utils/Sqrt.sol";

/**
 * @notice referenced openzeppelin's TimelockController.sol
 */
contract WorkersUnion is Pausable, Governed, Initializable, IWorkersUnion {
    using SafeMath for uint256;
    using Sqrt for uint256;

    bytes32 public constant NO_DEPENDENCY = bytes32(0);

    uint256 private _launch;
    VotingRule private _votingRule;
    mapping(bytes32 => Proposal) private _proposals;

    event TxProposed(
        bytes32 indexed txHash,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 start,
        uint256 end
    );

    event BatchTxProposed(
        bytes32 indexed txHash,
        address[] target,
        uint256[] value,
        bytes[] data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 start,
        uint256 end
    );

    event Vote(bytes32 txHash, address voter, bool forVote);
    event VoteUpdated(bytes32 txHash, uint256 forVotes, uint256 againsVotes);

    function initialize(
        address voteCounter,
        address timelockGov,
        uint256 launchDelay
    ) public initializer {
        _votingRule = VotingRule(
            1 days, // minimum pending for vote
            1 weeks, // maximum pending for vote
            1 weeks, // minimum voting period
            4 weeks, // maximum voting period
            0 gwei, // minimum votes for proposing
            0 gwei, // minimum votes
            voteCounter
        );
        Governed.initialize(timelockGov);
        _pause();
        _launch = block.timestamp.add(launchDelay);
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    function launch() public override {
        require(block.timestamp >= _launch, "Wait a bit please.");
        _unpause();
    }

    function changeVotingRule(
        uint256 minimumPendingPeriod,
        uint256 maximumPendingPeriod,
        uint256 minimumVotingPeriod,
        uint256 maximumVotingPeriod,
        uint256 minimumVotesForProposing,
        uint256 minimumVotes,
        address voteCounter
    ) public override governed {
        uint256 totalVotes = IVoteCounter(voteCounter).getTotalVotes();

        require(minimumPendingPeriod <= maximumPendingPeriod, "invalid arg");
        require(minimumVotingPeriod <= maximumVotingPeriod, "invalid arg");
        require(minimumVotingPeriod >= 1 days, "too short");
        require(minimumPendingPeriod >= 1 days, "too short");
        require(maximumVotingPeriod <= 30 days, "too long");
        require(maximumPendingPeriod <= 30 days, "too long");
        require(
            minimumVotesForProposing <= totalVotes.div(10),
            "too large number"
        );
        require(minimumVotes <= totalVotes.div(2), "too large number");
        require(address(voteCounter) != address(0), "null address");
        _votingRule = VotingRule(
            minimumPendingPeriod,
            maximumPendingPeriod,
            minimumVotingPeriod,
            maximumVotingPeriod,
            minimumVotesForProposing,
            minimumVotes,
            voteCounter
        );
    }

    function proposeTx(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 startsIn,
        uint256 votingPeriod
    ) public override {
        _beforePropose(startsIn, votingPeriod);
        bytes32 txHash =
            _timelock().hashOperation(target, value, data, predecessor, salt);
        _propose(txHash, startsIn, votingPeriod);
        emit TxProposed(
            txHash,
            target,
            value,
            data,
            predecessor,
            salt,
            block.timestamp + startsIn,
            block.timestamp + startsIn + votingPeriod
        );
    }

    function proposeBatchTx(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 startsIn,
        uint256 votingPeriod
    ) public override whenNotPaused {
        _beforePropose(startsIn, votingPeriod);
        bytes32 txHash =
            _timelock().hashOperationBatch(
                target,
                value,
                data,
                predecessor,
                salt
            );
        _propose(txHash, startsIn, votingPeriod);
        emit BatchTxProposed(
            txHash,
            target,
            value,
            data,
            predecessor,
            salt,
            block.timestamp + startsIn,
            block.timestamp + startsIn + votingPeriod
        );
    }

    /**
     * @notice Should use vote(bytes32, uint256[], bool) when too many voting rights are delegated to avoid out of gas.
     */
    function vote(bytes32 txHash, bool agree) public override {
        uint256[] memory votingRights =
            IVoteCounter(_votingRule.voteCounter).votingRights(msg.sender);
        manualVote(txHash, votingRights, agree);
    }

    /**
     * @notice The voting will be updated if the voter already voted. Please
     *      note that the voting power may change by the locking period or others.
     *      To have more detail information about how voting power is computed,
     *      Please go to the QVCounter.sol.
     */
    function manualVote(
        bytes32 txHash,
        uint256[] memory rightIds,
        bool agree
    ) public override {
        Proposal storage proposal = _proposals[txHash];
        uint256 timestamp = proposal.start;
        require(
            getVotingStatus(txHash) == VotingState.Voting,
            "Not in the voting period"
        );
        uint256 totalForVotes = proposal.totalForVotes;
        uint256 totalAgainstVotes = proposal.totalAgainstVotes;
        for (uint256 i = 0; i < rightIds.length; i++) {
            uint256 id = rightIds[i];
            require(
                IVoteCounter(_votingRule.voteCounter).voterOf(id) == msg.sender,
                "not the voting right owner"
            );
            uint256 prevForVotes = proposal.forVotes[id];
            uint256 prevAgainstVotes = proposal.againstVotes[id];
            uint256 votes =
                IVoteCounter(_votingRule.voteCounter).getVotes(id, timestamp);
            proposal.forVotes[id] = agree ? votes : 0;
            proposal.againstVotes[id] = agree ? 0 : votes;
            totalForVotes = totalForVotes.add(agree ? votes : 0).sub(
                prevForVotes
            );
            totalAgainstVotes = totalAgainstVotes.add(agree ? 0 : votes).sub(
                prevAgainstVotes
            );
        }
        proposal.totalForVotes = totalForVotes;
        proposal.totalAgainstVotes = totalAgainstVotes;
        emit Vote(txHash, msg.sender, agree);
        emit VoteUpdated(txHash, totalForVotes, totalAgainstVotes);
    }

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public override {
        bytes32 txHash =
            _timelock().hashOperation(target, value, data, predecessor, salt);
        require(
            getVotingStatus(txHash) == VotingState.Passed,
            "vote is not passed"
        );
        _timelock().forceSchedule(
            target,
            value,
            data,
            predecessor,
            salt,
            _timelock().getMinDelay()
        );
    }

    function scheduleBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public override {
        bytes32 txHash =
            _timelock().hashOperationBatch(
                target,
                value,
                data,
                predecessor,
                salt
            );
        require(
            getVotingStatus(txHash) == VotingState.Passed,
            "vote is not passed"
        );
        _timelock().forceScheduleBatch(
            target,
            value,
            data,
            predecessor,
            salt,
            _timelock().getMinDelay()
        );
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable override {
        bytes32 txHash =
            _timelock().hashOperation(target, value, data, predecessor, salt);
        require(
            getVotingStatus(txHash) == VotingState.Passed,
            "vote is not passed"
        );
        _timelock().execute{value: value}(
            target,
            value,
            data,
            predecessor,
            salt
        );
    }

    function executeBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable override {
        require(target.length == value.length, "length mismatch");
        require(target.length == data.length, "length mismatch");
        bytes32 txHash =
            _timelock().hashOperationBatch(
                target,
                value,
                data,
                predecessor,
                salt
            );
        require(
            getVotingStatus(txHash) == VotingState.Passed,
            "vote is not passed"
        );
        uint256 valueSum = 0;
        for (uint256 i = 0; i < value.length; i++) {
            valueSum = valueSum.add(value[i]);
        }
        _timelock().executeBatch{value: valueSum}(
            target,
            value,
            data,
            predecessor,
            salt
        );
    }

    function votingRule() public view override returns (VotingRule memory) {
        return _votingRule;
    }

    function getVotingStatus(bytes32 txHash)
        public
        view
        override
        returns (VotingState)
    {
        Proposal storage proposal = _proposals[txHash];
        require(proposal.start != 0, "Not an existing proposal");
        if (block.timestamp < proposal.start) return VotingState.Pending;
        else if (block.timestamp <= proposal.end) return VotingState.Voting;
        else if (_timelock().isOperationDone(txHash))
            return VotingState.Executed;
        else if (proposal.totalForVotes < _votingRule.minimumVotes)
            return VotingState.Rejected;
        else if (proposal.totalForVotes > proposal.totalAgainstVotes)
            return VotingState.Passed;
        else return VotingState.Rejected;
    }

    function getVotesFor(address account, bytes32 txHash)
        public
        view
        override
        returns (uint256)
    {
        uint256 timestamp = _proposals[txHash].start;
        return getVotesAt(account, timestamp);
    }

    function getVotesAt(address account, uint256 timestamp)
        public
        view
        override
        returns (uint256)
    {
        uint256[] memory votingRights =
            IVoteCounter(_votingRule.voteCounter).votingRights(account);
        uint256 votes;
        for (uint256 i = 0; i < votingRights.length; i++) {
            votes = votes.add(
                IVoteCounter(_votingRule.voteCounter).getVotes(
                    votingRights[i],
                    timestamp
                )
            );
        }
        return votes;
    }

    function proposals(bytes32 proposalHash)
        public
        view
        override
        returns (
            address proposer,
            uint256 start,
            uint256 end,
            uint256 totalForVotes,
            uint256 totalAgainstVotes
        )
    {
        Proposal storage proposal = _proposals[proposalHash];
        return (
            proposal.proposer,
            proposal.start,
            proposal.end,
            proposal.totalForVotes,
            proposal.totalAgainstVotes
        );
    }

    function _propose(
        bytes32 txHash,
        uint256 startsIn,
        uint256 votingPeriod
    ) private whenNotPaused {
        Proposal storage proposal = _proposals[txHash];
        require(proposal.proposer == address(0));
        proposal.proposer = msg.sender;
        proposal.start = block.timestamp + startsIn;
        proposal.end = proposal.start + votingPeriod;
    }

    function _beforePropose(uint256 startsIn, uint256 votingPeriod)
        private
        view
    {
        uint256 votes = getVotesAt(msg.sender, block.timestamp);
        require(
            _votingRule.minimumVotesForProposing <= votes,
            "Not enough votes for proposing."
        );
        require(
            _votingRule.minimumPending <= startsIn,
            "Pending period is too short."
        );
        require(
            startsIn <= _votingRule.maximumPending,
            "Pending period is too long."
        );
        require(
            _votingRule.minimumVotingPeriod <= votingPeriod,
            "Voting period is too short."
        );
        require(
            votingPeriod <= _votingRule.maximumVotingPeriod,
            "Voting period is too long."
        );
    }

    function _timelock() internal view returns (TimelockedGovernance) {
        return TimelockedGovernance(payable(_gov));
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVoteCounter {
    function getVotes(uint256 votingRightId, uint256 timestamp)
        external
        view
        returns (uint256);

    function voterOf(uint256 votingRightId) external view returns (address);

    function votingRights(address voter)
        external
        view
        returns (uint256[] memory rights);

    function getTotalVotes() external view returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

struct Proposal {
    address proposer;
    uint256 start;
    uint256 end;
    uint256 totalForVotes;
    uint256 totalAgainstVotes;
    mapping(uint256 => uint256) forVotes; // votingRightId => for vote amount
    mapping(uint256 => uint256) againstVotes; // votingRightId => against vote amount
}

struct VotingRule {
    uint256 minimumPending;
    uint256 maximumPending;
    uint256 minimumVotingPeriod;
    uint256 maximumVotingPeriod;
    uint256 minimumVotesForProposing;
    uint256 minimumVotes;
    address voteCounter;
}

interface IWorkersUnion {
    enum VotingState {Pending, Voting, Passed, Rejected, Executed} // Enum

    function launch() external;

    function changeVotingRule(
        uint256 minimumPendingPeriod,
        uint256 maximumPendingPeriod,
        uint256 minimumVotingPeriod,
        uint256 maximumVotingPeriod,
        uint256 minimumVotesForProposing,
        uint256 minimumVotes,
        address voteCounter
    ) external;

    function proposeTx(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 startsIn,
        uint256 votingPeriod
    ) external;

    function proposeBatchTx(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 startsIn,
        uint256 votingPeriod
    ) external;

    function vote(bytes32 txHash, bool agree) external;

    function manualVote(
        bytes32 txHash,
        uint256[] memory rightIds,
        bool agree
    ) external;

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external;

    function scheduleBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external;

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external payable;

    function executeBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external payable;

    function votingRule() external view returns (VotingRule memory);

    function getVotingStatus(bytes32 txHash)
        external
        view
        returns (VotingState);

    function getVotesFor(address account, bytes32 txHash)
        external
        view
        returns (uint256);

    function getVotesAt(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function proposals(bytes32 proposalHash)
        external
        view
        returns (
            address proposer,
            uint256 start,
            uint256 end,
            uint256 totalForVotes,
            uint256 totalAgainstVotes
        );
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../../core/governance/interfaces/IVoteCounter.sol";
import "../../../core/governance/interfaces/IVotingEscrowToken.sol";
import "../../../core/governance/interfaces/IVotingEscrowLock.sol";
import "../../../utils/Sqrt.sol";

contract VoteCounter is IVoteCounter, Initializable {
    IVotingEscrowLock private _veLock;
    IVotingEscrowToken private _veToken;

    function initialize(address veToken_) public initializer {
        _veToken = IVotingEscrowToken(veToken_);
        _veLock = IVotingEscrowLock(_veToken.veLocker());
    }

    function getTotalVotes() public view virtual override returns (uint256) {
        return _veToken.totalSupply();
    }

    function getVotes(uint256 veLockId, uint256 timestamp)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _veToken.balanceOfLockAt(veLockId, timestamp);
    }

    function voterOf(uint256 veLockId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _veLock.delegateeOf(veLockId);
    }

    function votingRights(address voter)
        public
        view
        virtual
        override
        returns (uint256[] memory rights)
    {
        uint256 totalLocks = _veLock.delegatedRights(voter);
        rights = new uint256[](totalLocks);
        for (uint256 i = 0; i < rights.length; i++) {
            rights[i] = _veLock.delegatedRightByIndex(voter, i);
        }
    }

    /**
     * @dev This should be used only for the snapshot voting feature.
     * Do not use this interface for other purposes.
     */
    function balanceOf(address account)
        external
        view
        virtual
        returns (uint256)
    {
        uint256[] memory rights = votingRights(account);
        uint256 sum;
        for (uint256 i = 0; i < rights.length; i++) {
            sum += getVotes(rights[i], block.timestamp);
        }
        return sum;
    }

    function veLock() public view returns (address) {
        return address(_veLock);
    }

    function veToken() public view returns (address) {
        return address(_veToken);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVotingEscrowLock is IERC721 {
    event LockCreated(uint256 veLockId);
    event LockUpdate(uint256 veLockId, uint256 amount, uint256 end);
    event Withdraw(uint256 veLockId, uint256 amount);
    event VoteDelegated(uint256 veLockId, address to);

    function locks(uint256 veLockId)
        external
        view
        returns (
            uint256 amount,
            uint256 start,
            uint256 end
        );

    function createLock(uint256 amount, uint256 epochs) external;

    function createLockUntil(uint256 amount, uint256 lockEnd) external;

    function increaseAmount(uint256 veLockId, uint256 amount) external;

    function extendLock(uint256 veLockId, uint256 epochs) external;

    function extendLockUntil(uint256 veLockId, uint256 end) external;

    function withdraw(uint256 veLockId) external;

    function delegate(uint256 veLockId, address to) external;

    function totalLockedSupply() external view returns (uint256);

    function MAXTIME() external view returns (uint256);

    function baseToken() external view returns (address);

    function veToken() external view returns (address);

    function delegateeOf(uint256 veLockId) external view returns (address);

    function delegatedRights(address delegatee) external view returns (uint256);

    function delegatedRightByIndex(address delegatee, uint256 idx)
        external
        view
        returns (uint256 veLockId);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

import "../../../core/governance/Governed.sol";
import "../../../core/governance/libraries/VotingEscrowToken.sol";
import "../../../core/governance/interfaces/IVotingEscrowLock.sol";

/**
 * @dev Voting Escrow Lock is the refactored solidity implementation of veCRV.
 *      The token lock is ERC721 and transferrable.
 *      Its original code https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
 */

contract VotingEscrowLock is
    IVotingEscrowLock,
    ERC721,
    ReentrancyGuard,
    Initializable,
    Governed
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    uint256 public constant override MAXTIME = 4 * (365 days);

    address private _baseToken;
    address private _veToken;
    uint256 private _totalLockedSupply;

    mapping(uint256 => Lock) private _locks;

    mapping(address => EnumerableSet.UintSet) private _delegated;
    EnumerableMap.UintToAddressMap private _rightOwners;

    string private _name;
    string private _symbol;

    modifier onlyOwner(uint256 veLockId) {
        require(
            ownerOf(veLockId) == msg.sender,
            "Only the owner can call this function"
        );
        _;
    }

    constructor() ERC721("", "") {
        // this constructor will not be called since it'll be cloned by proxy pattern.
        // initalize() will be called instead.
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address baseToken_,
        address veToken_,
        address gov_
    ) public initializer {
        _baseToken = baseToken_;
        _veToken = veToken_;
        _name = name_;
        _symbol = symbol_;
        Governed.initialize(gov_);
    }

    function updateBaseUri(string memory baseURI_) public governed {
        _setBaseURI(baseURI_);
    }

    function createLock(uint256 amount, uint256 epochs) public override {
        uint256 until = block.timestamp.add(epochs.mul(1 weeks));
        createLockUntil(amount, until);
    }

    function createLockUntil(uint256 amount, uint256 lockEnd) public override {
        require(amount > 0, "should be greater than zero");
        uint256 veLockId =
            uint256(keccak256(abi.encodePacked(block.number, msg.sender)));
        require(!_exists(veLockId), "Already exists");
        _locks[veLockId].start = block.timestamp;
        _safeMint(msg.sender, veLockId);
        _updateLock(veLockId, amount, lockEnd);
        emit LockCreated(veLockId);
    }

    function increaseAmount(uint256 veLockId, uint256 amount)
        public
        override
        onlyOwner(veLockId)
    {
        require(amount > 0, "should be greater than zero");
        uint256 newAmount = _locks[veLockId].amount.add(amount);
        _updateLock(veLockId, newAmount, _locks[veLockId].end);
    }

    function extendLock(uint256 veLockId, uint256 epochs)
        public
        override
        onlyOwner(veLockId)
    {
        uint256 until = block.timestamp.add(epochs.mul(1 weeks));
        extendLockUntil(veLockId, until);
    }

    function extendLockUntil(uint256 veLockId, uint256 end)
        public
        override
        onlyOwner(veLockId)
    {
        _updateLock(veLockId, _locks[veLockId].amount, end);
    }

    function withdraw(uint256 veLockId) public override onlyOwner(veLockId) {
        Lock memory lock = _locks[veLockId];
        require(block.timestamp >= lock.end, "Locked.");
        // transfer
        IERC20(_baseToken).safeTransfer(msg.sender, lock.amount);
        _totalLockedSupply = _totalLockedSupply.sub(lock.amount);
        VotingEscrowToken(_veToken).checkpoint(veLockId, lock, Lock(0, 0, 0));
        _locks[veLockId].amount = 0;
        emit Withdraw(veLockId, lock.amount);
    }

    function delegate(uint256 veLockId, address to)
        external
        override
        onlyOwner(veLockId)
    {
        _delegate(veLockId, to);
    }

    function baseToken() public view override returns (address) {
        return _baseToken;
    }

    function veToken() public view override returns (address) {
        return _veToken;
    }

    function totalLockedSupply() public view override returns (uint256) {
        return _totalLockedSupply;
    }

    function delegateeOf(uint256 veLockId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(veLockId)) {
            return address(0);
        }
        (bool delegated, address delegatee) = _rightOwners.tryGet(veLockId);
        return delegated ? delegatee : ownerOf(veLockId);
    }

    function delegatedRights(address voter)
        public
        view
        override
        returns (uint256)
    {
        require(
            voter != address(0),
            "VotingEscrowLock: delegate query for the zero address"
        );
        return _delegated[voter].length();
    }

    function delegatedRightByIndex(address voter, uint256 idx)
        public
        view
        override
        returns (uint256 veLockId)
    {
        require(
            voter != address(0),
            "VotingEscrowLock: delegate query for the zero address"
        );
        return _delegated[voter].at(idx);
    }

    function locks(uint256 veLockId)
        public
        view
        override
        returns (
            uint256 amount,
            uint256 start,
            uint256 end
        )
    {
        Lock memory lock = _locks[veLockId];
        return (lock.amount, lock.start, lock.end);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _updateLock(
        uint256 veLockId,
        uint256 amount,
        uint256 end
    ) internal nonReentrant {
        Lock memory prevLock = _locks[veLockId];
        Lock memory newLock =
            Lock(amount, prevLock.start, (end / 1 weeks).mul(1 weeks));
        require(_exists(veLockId), "Lock does not exist.");
        require(
            prevLock.end == 0 || prevLock.end > block.timestamp,
            "Cannot update expired. Create a new lock."
        );
        require(
            newLock.end > block.timestamp,
            "Unlock time should be in the future"
        );
        require(
            newLock.end <= block.timestamp + MAXTIME,
            "Max lock is 4 years"
        );
        require(
            !(prevLock.amount == newLock.amount && prevLock.end == newLock.end),
            "No update"
        );
        require(
            prevLock.amount <= newLock.amount,
            "new amount should be greater than before"
        );
        require(
            prevLock.end <= newLock.end,
            "new end timestamp should be greater than before"
        );

        uint256 increment = (newLock.amount - prevLock.amount); // require prevents underflow
        // 2. transfer
        if (increment > 0) {
            IERC20(_baseToken).safeTransferFrom(
                msg.sender,
                address(this),
                increment
            );
            // 3. update lock amount
            _totalLockedSupply = _totalLockedSupply.add(increment);
        }
        _locks[veLockId] = newLock;

        // 4. updateCheckpoint
        VotingEscrowToken(_veToken).checkpoint(veLockId, prevLock, newLock);
        emit LockUpdate(veLockId, amount, newLock.end);
    }

    function _delegate(uint256 veLockId, address to) internal {
        address _voter = delegateeOf(veLockId);
        _delegated[_voter].remove(veLockId);
        _delegated[to].add(veLockId);
        _rightOwners.set(veLockId, to);
        emit VoteDelegated(veLockId, to);
    }

    function _beforeTokenTransfer(
        address,
        address to,
        uint256 veLockId
    ) internal override {
        _delegate(veLockId, to);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../core/governance/interfaces/IVotingEscrowToken.sol";
import "../../core/governance/interfaces/IVotingEscrowLock.sol";
import "../../core/dividend/interfaces/IDividendPool.sol";
import "../../core/governance/Governed.sol";
import "../../utils/Utils.sol";

struct Distribution {
    uint256 totalDistribution;
    uint256 balance;
    mapping(uint256 => uint256) tokenPerWeek; // key is week num
    mapping(uint256 => uint256) claimStartWeekNum; // key is lock id
}

/** @title Dividend Pool */
contract DividendPool is
    IDividendPool,
    Governed,
    Initializable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Utils for address[];

    // public constants
    uint256 public constant epochUnit = 1 weeks; // default 1 epoch is 1 week

    // state variables
    address private _veVISION; // a.k.a RIGHT
    address private _veLocker;
    mapping(address => Distribution) private _distributions;
    mapping(address => bool) private _distributed;
    uint256 private _genesis;
    address[] private _distributedTokens;
    address[] private _featuredRewards;

    // events
    event NewReward(address token);
    event NewDistribution(address indexed token, uint256 amount);

    function initialize(
        address gov,
        address RIGHT,
        address[] memory _rewardTokens
    ) public initializer {
        _veVISION = RIGHT;
        _veLocker = IVotingEscrowToken(RIGHT).veLocker();
        Governed.initialize(gov);
        _genesis = (block.timestamp / epochUnit) * epochUnit;
        _featuredRewards = _rewardTokens;
    }

    // distribution

    function distribute(address _token, uint256 _amount)
        public
        override
        nonReentrant
    {
        if (!_distributed[_token]) {
            _distributed[_token] = true;
            _distributedTokens.push(_token);
            emit NewReward(_token);
        }
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 newBalance = IERC20(_token).balanceOf(address(this));
        Distribution storage distribution = _distributions[_token];
        uint256 increment = newBalance.sub(distribution.balance);
        distribution.balance = newBalance;
        distribution.totalDistribution = distribution.totalDistribution.add(
            increment
        );
        uint256 weekNum = getCurrentEpoch();
        distribution.tokenPerWeek[weekNum] = distribution.tokenPerWeek[weekNum]
            .add(increment);
        emit NewDistribution(_token, _amount);
    }

    /**
     * @notice If there's no ve token holder for that given epoch, anyone can call
     *          this function to redistribute the rewards to the closest epoch.
     */
    function redistribute(address token, uint256 epoch) public {
        require(
            epoch < getCurrentEpoch(),
            "Given epoch is still accepting rights."
        );
        uint256 timestamp = _genesis + epoch * epochUnit + 1 weeks;
        require(
            IVotingEscrowToken(_veVISION).totalSupplyAt(timestamp) == 0,
            "Locked Token exists for that epoch"
        );
        uint256 newEpoch;
        uint256 increment = 1;
        while (timestamp + (increment * 1 weeks) <= block.timestamp) {
            if (
                IVotingEscrowToken(_veVISION).totalSupplyAt(
                    timestamp + (increment * 1 weeks)
                ) > 0
            ) {
                newEpoch = epoch + increment;
                break;
            }
            increment += 1;
        }
        require(newEpoch > epoch, "Failed to find new epoch to redistribute");
        Distribution storage distribution = _distributions[token];
        distribution.tokenPerWeek[newEpoch] = distribution.tokenPerWeek[
            newEpoch
        ]
            .add(distribution.tokenPerWeek[epoch]);
        distribution.tokenPerWeek[epoch] = 0;
    }

    // claim

    function claim(address token) public nonReentrant {
        uint256 prevEpochTimestamp = block.timestamp - epochUnit; // safe from underflow
        _claimUpTo(token, prevEpochTimestamp);
    }

    function claimUpTo(address token, uint256 timestamp) public nonReentrant {
        _claimUpTo(token, timestamp);
    }

    function claimBatch(address[] memory tokens) public nonReentrant {
        uint256 prevEpochTimestamp = block.timestamp - epochUnit; // safe from underflow
        for (uint256 i = 0; i < tokens.length; i++) {
            _claimUpTo(tokens[i], prevEpochTimestamp);
        }
    }

    // governance
    function setFeaturedRewards(address[] memory featured) public governed {
        _featuredRewards = featured;
    }

    function genesis() public view override returns (uint256) {
        return _genesis;
    }

    function veVISION() public view override returns (address) {
        return _veVISION;
    }

    function veLocker() public view override returns (address) {
        return _veLocker;
    }

    function getEpoch(uint256 timestamp)
        public
        view
        override
        returns (uint256)
    {
        return (timestamp - _genesis) / epochUnit; // safe from underflow
    }

    /** @notice 1 epoch is 1 week */
    function getCurrentEpoch() public view override returns (uint256) {
        return getEpoch(block.timestamp);
    }

    function distributedTokens()
        public
        view
        override
        returns (address[] memory)
    {
        return _distributedTokens;
    }

    function totalDistributed(address token)
        public
        view
        override
        returns (uint256)
    {
        return _distributions[token].totalDistribution;
    }

    function distributionBalance(address token)
        public
        view
        override
        returns (uint256)
    {
        return _distributions[token].balance;
    }

    function distributionOfWeek(address token, uint256 epochNum)
        public
        view
        override
        returns (uint256)
    {
        return _distributions[token].tokenPerWeek[epochNum];
    }

    function claimStartWeek(address token, uint256 veLockId)
        public
        view
        override
        returns (uint256)
    {
        return _distributions[token].claimStartWeekNum[veLockId];
    }

    function claimable(address token) public view override returns (uint256) {
        Distribution storage distribution = _distributions[token];
        uint256 currentEpoch = getCurrentEpoch();
        if (currentEpoch == 0) return 0;
        uint256 myLocks = IVotingEscrowLock(_veLocker).balanceOf(msg.sender);
        uint256 acc;
        for (uint256 i = 0; i < myLocks; i++) {
            uint256 lockId =
                IERC721Enumerable(_veLocker).tokenOfOwnerByIndex(msg.sender, i);
            acc = acc.add(_claimable(distribution, lockId, currentEpoch - 1));
        }
        return acc;
    }

    function featuredRewards() public view override returns (address[] memory) {
        return _featuredRewards;
    }

    function _claimUpTo(address token, uint256 timestamp) internal {
        uint256 epoch = getEpoch(timestamp);
        uint256 myLocks = IVotingEscrowLock(_veLocker).balanceOf(msg.sender);
        uint256 amountToClaim = 0;
        for (uint256 i = 0; i < myLocks; i++) {
            uint256 lockId =
                IERC721Enumerable(_veLocker).tokenOfOwnerByIndex(msg.sender, i);

            uint256 amount = _recordClaim(token, lockId, epoch);
            amountToClaim = amountToClaim.add(amount);
        }
        if (amountToClaim != 0) {
            IERC20(token).safeTransfer(msg.sender, amountToClaim);
        }
    }

    function _recordClaim(
        address token,
        uint256 tokenId,
        uint256 epoch
    ) internal returns (uint256 amountToClaim) {
        Distribution storage distribution = _distributions[token];
        amountToClaim = _claimable(distribution, tokenId, epoch);
        distribution.claimStartWeekNum[tokenId] = epoch + 1;
        distribution.balance = distribution.balance.sub(amountToClaim);
        return amountToClaim;
    }

    function _claimable(
        Distribution storage distribution,
        uint256 tokenId,
        uint256 epoch
    ) internal view returns (uint256) {
        require(epoch < getCurrentEpoch(), "Current epoch is being updated.");
        uint256 epochCursor = distribution.claimStartWeekNum[tokenId];
        uint256 endEpoch;
        {
            (, uint256 start, uint256 end) =
                IVotingEscrowLock(_veLocker).locks(tokenId);
            epochCursor = epochCursor != 0 ? epochCursor : getEpoch(start);
            endEpoch = getEpoch(end);
        }
        uint256 accumulated;
        while (epochCursor <= epoch && epochCursor <= endEpoch) {
            // check the balance when the epoch ends
            uint256 timestamp = _genesis + epochCursor * epochUnit + 1 weeks;
            // calculate amount;
            uint256 bal =
                IVotingEscrowToken(_veVISION).balanceOfLockAt(
                    tokenId,
                    timestamp
                );
            uint256 supply =
                IVotingEscrowToken(_veVISION).totalSupplyAt(timestamp);
            if (supply != 0) {
                accumulated = accumulated.add(
                    distribution.tokenPerWeek[epochCursor].mul(bal).div(supply)
                );
            }
            // update cursor
            epochCursor += 1;
        }
        return accumulated;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../utils/ERC20Recoverer.sol";
import "../../core/dividend/libraries/Distributor.sol";
import "../../core/dividend/interfaces/IDividendPool.sol";
import "../../core/governance/Governed.sol";
import "../../core/marketplace/interfaces/IMarketplace.sol";

contract Marketplace is
    Distributor,
    ERC20Recoverer,
    Governed,
    ReentrancyGuard,
    ERC1155Burnable,
    IMarketplace
{
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20Burnable;
    using SafeMath for uint256;

    uint256 public constant RATE_DENOMINATOR = 10000;

    ERC20Burnable private _commitToken;
    uint256 private _taxRate = 2000; // denominator is 10,000
    mapping(uint256 => Product) private _products;
    uint256[] private _featured;

    modifier onlyManufacturer(uint256 id) {
        require(
            msg.sender == _products[id].manufacturer,
            "allowed only for manufacturer"
        );
        _;
    }

    constructor() ERC1155("") {
        // this constructor will not be called since it'll be cloned by proxy pattern.
        // initalize() will be called instead.
    }

    function initialize(
        address _gov,
        address commitToken_,
        address _dividendPool
    ) public initializer {
        _taxRate = 2000; // denominator is 10,000
        _commitToken = ERC20Burnable(commitToken_);
        ERC20Recoverer.initialize(_gov, new address[](0));
        Governed.initialize(_gov);
        Distributor._setup(_dividendPool);
    }

    function buy(
        uint256 id,
        address to,
        uint256 amount
    ) public override nonReentrant {
        require(amount > 0, "cannot buy 0");
        // check the product is for sale
        Product storage product = _products[id];
        require(product.manufacturer != address(0), "Product not exists");

        if (product.maxSupply != 0) {
            uint256 stock = product.maxSupply.sub(product.totalSupply);
            require(amount <= stock, "Not enough stock");
            require(stock > 0, "Not for sale.");
        }
        uint256 totalPayment = product.price.mul(amount); // SafeMath prevents overflow
        // Vision Tax
        uint256 visionTax = totalPayment.mul(_taxRate).div(RATE_DENOMINATOR);
        // Burn tokens
        uint256 postTax = totalPayment.sub(visionTax);
        uint256 forManufacturer =
            postTax.mul(product.profitRate).div(RATE_DENOMINATOR);
        uint256 amountToBurn = postTax.sub(forManufacturer);
        _commitToken.safeTransferFrom(msg.sender, address(this), visionTax);
        _commitToken.safeTransferFrom(
            msg.sender,
            product.manufacturer,
            forManufacturer
        );
        _commitToken.burnFrom(msg.sender, amountToBurn);
        _distribute(address(_commitToken), visionTax);
        // mint & give
        _mint(to, id, amount, "");
    }

    function manufacture(
        string memory cid,
        uint256 profitRate,
        uint256 price
    ) external override {
        uint256 id = uint256(keccak256(abi.encodePacked(cid, msg.sender)));
        _products[id] = Product(msg.sender, 0, 0, price, profitRate, cid);
        emit NewProduct(id, msg.sender, cid);
    }

    function manufactureLimitedEdition(
        string memory cid,
        uint256 profitRate,
        uint256 price,
        uint256 maxSupply
    ) external override {
        uint256 id = uint256(keccak256(abi.encodePacked(cid, msg.sender)));
        _products[id] = Product(
            msg.sender,
            0,
            maxSupply,
            price,
            profitRate,
            cid
        );
        emit NewProduct(id, msg.sender, cid);
    }

    /**
     * @notice Set max supply and make it a limited edition.
     */
    function setMaxSupply(uint256 id, uint256 _maxSupply)
        external
        override
        onlyManufacturer(id)
    {
        require(_products[id].maxSupply == 0, "Max supply is already set");
        require(
            _products[id].totalSupply <= _maxSupply,
            "Max supply is less than current supply"
        );
        _products[id].maxSupply = _maxSupply;
    }

    function setPrice(uint256 id, uint256 price)
        public
        override
        onlyManufacturer(id)
    {
        // to prevent overflow
        require(price * 1000000000 > price, "Cannot be expensive too much");
        _products[id].price = price;
        emit PriceUpdated(id, price);
    }

    /**
     * @notice The profit rate is based on the post-tax amount of the payment.
     *      For example, when the price is 10000 DCT, tax rate is 2000, and profit rate is 5000,
     *      2000 DCT will go to the vision farm, 4000 DCT will be burnt, and 4000 will be given
     *      to the manufacturer.
     */
    function setProfitRate(uint256 id, uint256 profitRate)
        public
        override
        onlyManufacturer(id)
    {
        require(profitRate <= RATE_DENOMINATOR, "Profit rate is too high");
        _products[id].profitRate = profitRate;
        emit ProfitRateUpdated(id, profitRate);
    }

    function setFeatured(uint256[] calldata featured_)
        external
        override
        governed
    {
        _featured = featured_;
    }

    function setTaxRate(uint256 rate) public override governed {
        require(rate <= RATE_DENOMINATOR);
        _taxRate = rate;
    }

    function commitToken() public view override returns (address) {
        return address(_commitToken);
    }

    function taxRate() public view override returns (uint256) {
        return _taxRate;
    }

    function products(uint256 id)
        public
        view
        override
        returns (Product memory)
    {
        return _products[id];
    }

    function featured() public view override returns (uint256[] memory) {
        return _featured;
    }

    function uri(uint256 id)
        external
        view
        override(IERC1155MetadataURI, ERC1155)
        returns (string memory)
    {
        return string(abi.encodePacked("ipfs://", _products[id].uri));
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        uint256 newSupply = _products[id].totalSupply.add(amount);
        require(
            _products[id].maxSupply == 0 ||
                newSupply <= _products[id].maxSupply,
            "Sold out"
        );
        _products[id].totalSupply = newSupply;
        super._mint(account, id, amount, data);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";

struct Product {
    address manufacturer;
    uint256 totalSupply;
    uint256 maxSupply;
    uint256 price;
    uint256 profitRate;
    string uri;
}

interface IMarketplace is IERC1155MetadataURI {
    function buy(
        uint256 id,
        address to,
        uint256 amount
    ) external;

    function manufacture(
        string memory cid,
        uint256 profitRate,
        uint256 price
    ) external;

    function manufactureLimitedEdition(
        string memory cid,
        uint256 profitRate,
        uint256 price,
        uint256 maxSupply
    ) external;

    function setMaxSupply(uint256 id, uint256 _maxSupply) external;

    function setPrice(uint256 id, uint256 price) external;

    function setProfitRate(uint256 id, uint256 profitRate) external;

    function setTaxRate(uint256 rate) external;

    function setFeatured(uint256[] calldata _featured) external;

    function commitToken() external view returns (address);

    function taxRate() external view returns (uint256);

    function products(uint256 id) external view returns (Product memory);

    function featured() external view returns (uint256[] memory);

    event NewProduct(uint256 id, address manufacturer, string uri);

    event TaxRateUpdated(uint256 taxRate);

    event PriceUpdated(uint256 indexed productId, uint256 price);

    event ProfitRateUpdated(uint256 indexed productId, uint256 profitRate);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "../../../core/governance/Governed.sol";
import "../../../core/work/libraries/CommitMinter.sol";
import "../../../core/work/libraries/GrantReceiver.sol";
import "../../../core/work/interfaces/IStableReserve.sol";
import "../../../core/work/interfaces/IContributionBoard.sol";
import "../../../core/dividend/libraries/Distributor.sol";
import "../../../core/dividend/interfaces/IDividendPool.sol";
import "../../../core/project/Project.sol";
import "../../../utils/IERC1620.sol";
import "../../../utils/Utils.sol";

struct Budget {
    uint256 amount;
    bool transferred;
}

contract JobBoard is
    CommitMinter,
    GrantReceiver,
    Distributor,
    Governed,
    ReentrancyGuard,
    Initializable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using Utils for address[];

    bool thirdPartyAccess;

    address public sablier;

    address public baseCurrency;

    Project public project;

    uint256 public normalTaxRate = 2000; // 20% goes to the vision sharing farm, 80% is swapped to stable coin and goes to the labor market

    uint256 public taxRateForUndeclared = 5000; // 50% goes to the vision farm when the budget is undeclared.

    mapping(address => bool) public acceptableTokens;

    mapping(uint256 => uint256) public projectFund;

    mapping(bytes32 => bool) public claimed;

    mapping(uint256 => Budget[]) public projectBudgets;

    mapping(uint256 => bool) public approvedProjects;

    mapping(uint256 => bool) public finalized;

    mapping(uint256 => uint256) private _projectOf;

    mapping(uint256 => uint256[]) private _streams;

    mapping(uint256 => address[]) private _contributors;

    event ManagerUpdated(address indexed manager, bool active);

    event ProjectPosted(uint256 projId);

    event ProjectClosed(uint256 projId);

    event Grant(uint256 projId, uint256 amount);

    event Payed(uint256 projId, address to, uint256 amount);

    event PayedInStream(
        uint256 projId,
        address to,
        uint256 amount,
        uint256 streamId
    );

    event BudgetAdded(
        uint256 indexed projId,
        uint256 index,
        address token,
        uint256 amount
    );

    event BudgetExecuted(uint256 projId, uint256 index);

    event BudgetWithdrawn(uint256 projId, uint256 index);

    constructor() {
        // this will not be called
    }

    function initialize(
        address _project,
        address _gov,
        address _dividendPool,
        address _stableReserve,
        address _baseCurrency,
        address _commit,
        address _sablier
    ) public initializer {
        normalTaxRate = 2000; // 20% goes to the vision sharing farm, 80% is swapped to stable coin and goes to the labor market
        taxRateForUndeclared = 5000; // 50% goes to the vision farm when the budget is undeclared.
        CommitMinter._setup(_stableReserve, _commit);
        Distributor._setup(_dividendPool);
        baseCurrency = _baseCurrency;
        project = Project(_project);
        acceptableTokens[_baseCurrency] = true;
        thirdPartyAccess = true;
        sablier = _sablier;
        Governed.initialize(_gov);
    }

    modifier onlyStableReserve() {
        require(
            address(stableReserve) == msg.sender,
            "Only the stable reserves can call this function"
        );
        _;
    }

    modifier onlyProjectOwner(uint256 projId) {
        require(project.ownerOf(projId) == msg.sender, "Not authorized");
        _;
    }

    modifier onlyApprovedProject(uint256 projId) {
        require(thirdPartyAccess, "Third party access is not allowed.");
        require(approvedProjects[projId], "Not an approved project.");
        _;
    }

    function addBudget(
        uint256 projId,
        address token,
        uint256 amount
    ) public onlyProjectOwner(projId) {
        _addBudget(projId, token, amount);
    }

    function addAndExecuteBudget(
        uint256 projId,
        address token,
        uint256 amount
    ) public onlyProjectOwner(projId) {
        uint256 budgetIdx = _addBudget(projId, token, amount);
        executeBudget(projId, budgetIdx);
    }

    function closeProject(uint256 projId) public onlyProjectOwner(projId) {
        _withdrawAllBudgets(projId);
        approvedProjects[projId] = false;
        emit ProjectClosed(projId);
    }

    function forceExecuteBudget(uint256 projId, uint256 index)
        public
        onlyProjectOwner(projId)
    {
        // force approve does not allow swap and approve func to prevent
        // exploitation using flash loan attack
        _convertStableToCommit(projId, index, taxRateForUndeclared);
    }

    // Operator functions
    function executeBudget(uint256 projId, uint256 index)
        public
        onlyApprovedProject(projId)
    {
        _convertStableToCommit(projId, index, normalTaxRate);
    }

    function addProjectFund(uint256 projId, uint256 amount) public {
        IERC20(commitToken).safeTransferFrom(msg.sender, address(this), amount);
        projectFund[projId] = projectFund[projId].add(amount);
    }

    function receiveGrant(
        address currency,
        uint256 amount,
        bytes calldata data
    ) external override onlyStableReserve returns (bool result) {
        require(
            currency == commitToken,
            "Only can get $COMMIT token for its grant"
        );
        uint256 projId = abi.decode(data, (uint256));
        require(project.ownerOf(projId) != address(0), "No budget owner");
        projectFund[projId] = projectFund[projId].add(amount);
        emit Grant(projId, amount);
        return true;
    }

    function compensate(
        uint256 projectId,
        address to,
        uint256 amount
    ) public onlyProjectOwner(projectId) {
        _compensate(projectId, to, amount);
    }

    function compensateInStream(
        uint256 projectId,
        address to,
        uint256 amount,
        uint256 period
    ) public onlyProjectOwner(projectId) {
        require(projectFund[projectId] >= amount);
        projectFund[projectId] = projectFund[projectId] - amount; // "require" protects underflow
        IERC20(commitToken).approve(sablier, amount); // approve the transfer
        uint256 streamId =
            IERC1620(sablier).createStream(
                to,
                amount,
                commitToken,
                block.timestamp,
                block.timestamp + period
            );

        _projectOf[streamId] = projectId;
        _streams[projectId].push(streamId);
        emit PayedInStream(projectId, to, amount, streamId);
    }

    function cancelStream(uint256 projectId, uint256 streamId)
        public
        onlyProjectOwner(projectId)
    {
        require(projectOf(streamId) == projectId, "Invalid project id");

        (, , , , , , uint256 remainingBalance, ) =
            IERC1620(sablier).getStream(streamId);

        require(IERC1620(sablier).cancelStream(streamId), "Failed to cancel");
        projectFund[projectId] = projectFund[projectId].add(remainingBalance);
    }

    function claim(
        uint256 projectId,
        address to,
        uint256 amount,
        bytes32 salt,
        bytes memory sig
    ) public {
        bytes32 claimHash =
            keccak256(abi.encodePacked(projectId, to, amount, salt));
        require(!claimed[claimHash], "Already claimed");
        claimed[claimHash] = true;
        address signer = claimHash.recover(sig);
        require(project.ownerOf(projectId) == signer, "Invalid signer");
        _compensate(projectId, to, amount);
    }

    function projectOf(uint256 streamId) public view returns (uint256 id) {
        return _projectOf[streamId];
    }

    // Governed functions

    function addCurrency(address currency) public governed {
        acceptableTokens[currency] = true;
    }

    function removeCurrency(address currency) public governed {
        acceptableTokens[currency] = false;
    }

    function approveProject(uint256 projId) public governed {
        _approveProject(projId);
    }

    function disapproveProject(uint256 projId) public governed {
        _withdrawAllBudgets(projId);
        approvedProjects[projId] = false;
        emit ProjectClosed(projId);
    }

    function setTaxRate(uint256 rate) public governed {
        require(rate <= 10000);
        normalTaxRate = rate;
    }

    function setTaxRateForUndeclared(uint256 rate) public governed {
        require(rate <= 10000);
        taxRateForUndeclared = rate;
    }

    function allowThirdPartyAccess(bool allow) public governed {
        thirdPartyAccess = allow;
    }

    function getTotalBudgets(uint256 projId) public view returns (uint256) {
        return projectBudgets[projId].length;
    }

    function getStreams(uint256 projId) public view returns (uint256[] memory) {
        return _streams[projId];
    }

    function getContributors(uint256 projId)
        public
        view
        returns (address[] memory)
    {
        return _contributors[projId];
    }

    // Internal functions
    function _addBudget(
        uint256 projId,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        require(acceptableTokens[token], "Not a supported currency");
        Budget memory budget = Budget(amount, false);
        projectBudgets[projId].push(budget);
        emit BudgetAdded(
            projId,
            projectBudgets[projId].length - 1,
            token,
            amount
        );
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return projectBudgets[projId].length - 1;
    }

    function _approveProject(uint256 projId) internal {
        require(!approvedProjects[projId], "Already approved");
        approvedProjects[projId] = true;
    }

    function _withdrawAllBudgets(uint256 projId) internal nonReentrant {
        Budget[] storage budgets = projectBudgets[projId];
        address projOwner = project.ownerOf(projId);
        for (uint256 i = 0; i < budgets.length; i += 1) {
            Budget storage budget = budgets[i];
            if (!budget.transferred) {
                budget.transferred = true;
                IERC20(baseCurrency).transfer(projOwner, budget.amount);
                emit BudgetWithdrawn(projId, i);
            }
        }
        delete projectBudgets[projId];
    }

    /**
     * @param projId The project NFT id for this budget.
     * @param taxRate The tax rate to approve the budget.
     */
    function _convertStableToCommit(
        uint256 projId,
        uint256 index,
        uint256 taxRate
    ) internal {
        Budget storage budget = projectBudgets[projId][index];
        require(budget.transferred == false, "Budget is already transferred.");
        // Mark the budget as transferred
        budget.transferred = true;
        // take vision tax from the budget
        uint256 visionTax = budget.amount.mul(taxRate).div(10000);
        uint256 fund = budget.amount.sub(visionTax);
        _distribute(baseCurrency, visionTax);
        // Mint commit fund
        _mintCommit(fund);
        projectFund[projId] = projectFund[projId].add(fund);
        emit BudgetExecuted(projId, index);
    }

    function _compensate(
        uint256 projectId,
        address to,
        uint256 amount
    ) internal {
        require(projectFund[projectId] >= amount);
        projectFund[projectId] = projectFund[projectId] - amount; // "require" protects underflow
        IERC20(commitToken).safeTransfer(to, amount);
        emit Payed(projectId, to, amount);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
import "../../../core/governance/libraries/VoteCounter.sol";
import "../../../utils/Sqrt.sol";

contract SquareRootVoteCounter is VoteCounter {
    using Sqrt for uint256;

    function getVotes(uint256 veLockId, uint256 timestamp)
        public
        view
        override
        returns (uint256)
    {
        uint256 votes = super.getVotes(veLockId, timestamp);
        return votes.sqrt();
    }

    function getTotalVotes() public view virtual override returns (uint256) {
        return IVotingEscrowToken(veToken()).totalSupply().sqrt();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
abstract contract ReentrancyGuard {
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

    constructor () {
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

pragma solidity ^0.7.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../utils/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./../math/SafeMath.sol";
import "./AccessControl.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl {

    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data, bytes32 predecessor, uint256 delay);

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`.
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()) || hasRole(role, address(0)), "TimelockController: sender requires permission");
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        // solhint-disable-next-line not-rely-on-time
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt, uint256 delay) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt, uint256 delay) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        // solhint-disable-next-line not-rely-on-time
        _timestamps[id] = SafeMath.add(block.timestamp, delay);
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function execute(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) public payable virtual onlyRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt) public payable virtual onlyRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 predecessor) private view {
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(bytes32 id, uint256 index, address target, uint256 value, bytes calldata data) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

