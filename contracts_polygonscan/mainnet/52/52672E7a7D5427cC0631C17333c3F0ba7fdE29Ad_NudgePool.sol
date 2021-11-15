// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./lib/BytesUtils.sol";
import "./lib/Safety.sol";
import "./storage/NPStorage.sol";
import "./NPProxy.sol";

contract NudgePool is NPStorage, NPProxy, Pausable {
    using BytesUtils for bytes;
    using Safety for uint256;

    event CreatePool(address _ip, address _ipToken, address _baseToken, uint256 _ipTokensAmount, uint256 _dgtTokensAmount,
                        uint32 _ipImpawnRatio, uint32 _ipCloseLine,uint32 _chargeRatio, uint256 _duration);
    event AuctionPool(address _ip, address _ipToken, address _baseToken, uint256 _ipTokensAmount, uint256 _dgtTokensAmount);
    event AllocateFundraising(address _ipToken, address _baseToken);
    event DestroyPool(address _ipToken, address _baseToken);
    event ChangePoolParam(address _ipToken, address _baseToken, uint32 _ipImpawnRatio, uint32 _ipCloseLine,
                   uint32 _chargeRatio, uint256 _duration);
    event RunningIPDeposit(address _ipToken, address _baseToken, uint256 _ipTokensAmount);
    event RaisingGPDeposit(address _ipToken, address _baseToken, uint256 _baseTokensAmount);
    event RunningGPDeposit(address _ipToken, address _baseToken, uint256 _baseTokensAmount);
    event RunningGPDoDeposit(address _ipToken, address _baseToken);
    event RunningGPWithdraw(address _ipToken, address _baseToken, uint256 _baseTokensAmount);
    event LiquidationGPWithdraw(address _ipToken, address _baseToken);
    event RaisingLPDeposit(address _ipToken, address _baseToken, uint256 _baseTokensAmount);
    event RunningLPDeposit(address _ipToken, address _baseToken, uint256 _baseTokensAmount);
    event RunningLPDoDeposit(address _ipToken, address _baseToken);
    event RunningLPWithdraw(address _ipToken, address _baseToken, uint256 _baseTokensAmount);
    event LiquidationLPWithdraw(address _ipToken, address _baseToken);
    event WithdrawVault(address _ipToken, address _baseToken, uint256 _baseTokensAmount);

    constructor(
        address _DGTToken,
        address _DGTBeneficiary,
        address _ips,
        address _gps,
        address _lps,
        address _vts
    )
    {
        require(_DGTToken != address(0) && _DGTBeneficiary != address(0) &&
                _ips != address(0) && _gps != address(0) &&
                _lps != address(0) && _vts != address(0), "Invalid Address");

        DGTToken = _DGTToken;
        DGTBeneficiary = _DGTBeneficiary;
        _IPS = IPStorage(_ips);
        _GPS = GPStorage(_gps);
        _LPS = LPStorage(_lps);
        _VTS = VaultStorage(_vts);
    }

    function initialize(
        address _ipc,
        address _gpdc,
        address _gpwc,
        address _lpc,
        address _vtc,
        address _stc,
        address _lqdc
    )
        external onlyOwner
    {
        require(!initialized, "Already Initialized");
        setUpgrade("0.0.1", _ipc, _gpdc, _gpwc, _lpc, _vtc, _stc, _lqdc);
        executeUpgrade();
        initialized = true;
    }

    function setPause(
    )
        external onlyOwner
    {
        _pause();
        emit Paused(msg.sender);
    }

    function unPause(
    )
        external onlyOwner
    {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function createPool(
        address _ip,
        address _ipToken,
        address _baseToken,
        uint256 _ipTokensAmount,
        uint256 _dgtTokensAmount,
        uint32 _ipImpawnRatio,
        uint32 _ipCloseLine,
        uint32 _chargeRatio,
        uint256 _duration
    )
        external whenNotPaused
    {
        (bool status,) = curVersion.ipc.delegatecall(abi.encodeWithSelector(bytes4(keccak256(
            "createPool(address,address,address,uint256,uint256,uint32,uint32,uint32,uint256)")),
            _ip, _ipToken, _baseToken, _ipTokensAmount, _dgtTokensAmount,
            _ipImpawnRatio, _ipCloseLine, _chargeRatio, _duration));
        require(status, "Create Pool Failed");
        emit CreatePool(_ip, _ipToken, _baseToken, _ipTokensAmount, _dgtTokensAmount,
                        _ipImpawnRatio, _ipCloseLine, _chargeRatio, _duration);
    }

    function auctionPool(
        address _ip,
        address _ipToken,
        address _baseToken,
        uint256 _ipTokensAmount,
        uint256 _dgtTokensAmount
    )
        external whenNotPaused
    {
        (bool status,) = curVersion.ipc.delegatecall(abi.encodeWithSelector(bytes4(keccak256(
            "auctionPool(address,address,address,uint256,uint256)")),
            _ip, _ipToken, _baseToken, _ipTokensAmount, _dgtTokensAmount));
        require(status, "Auction Pool Failed");
        emit AuctionPool(_ip, _ipToken, _baseToken, _ipTokensAmount, _dgtTokensAmount);
    }

    function destroyPool(
        address _ipToken,
        address _baseToken
    )
        external onlyOwner
    {
        (bool status,) = curVersion.ipc.delegatecall(abi.encodeWithSelector(bytes4(keccak256(
            "destroyPool(address,address)")), _ipToken, _baseToken));
        require(status, "Destroy Pool Failed");
        emit DestroyPool(_ipToken, _baseToken);
    }

    function changePoolParam(
        address _ipToken,
        address _baseToken,
        uint32 _ipImpawnRatio,
        uint32 _ipCloseLine,
        uint32 _chargeRatio,
        uint256 _duration
    )
        external whenNotPaused
    {
        (bool status,) = curVersion.ipc.delegatecall(abi.encodeWithSelector(bytes4(keccak256(
            "changePoolParam(address,address,uint32,uint32,uint32,uint256)")),
            _ipToken, _baseToken, _ipImpawnRatio,
            _ipCloseLine, _chargeRatio, _duration));
        require(status, "Change Pool Param Failed");
        emit ChangePoolParam(_ipToken, _baseToken, _ipImpawnRatio, _ipCloseLine,
                            _chargeRatio, _duration);
    }

    function IPDepositRunning(
        address _ipToken,
        address _baseToken,
        uint256 _ipTokensAmount
    )
        external whenNotPaused
        returns (uint256 amount)
    {
        (bool status, bytes memory data) = curVersion.ipc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "IPDepositRunning(address,address,uint256)")),
            _ipToken, _baseToken, _ipTokensAmount));
        require(status, "IP Deposit Failed");
        amount = data.bytesToUint256();
        emit RunningIPDeposit(_ipToken, _baseToken, _ipTokensAmount);
        return amount;
    }

    function GPDepositRaising(
        address _ipToken,
        address _baseToken,
        uint256 _baseTokensAmount,
        bool _create
    )
        external whenNotPaused
        returns (uint256 amount)
    {
        (bool status, bytes memory data) = curVersion.gpdc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "GPDepositRaising(address,address,uint256,bool)")),
            _ipToken, _baseToken, _baseTokensAmount, _create));
        require(status, "GP Deposit Failed");
        amount = data.bytesToUint256();
        emit RaisingGPDeposit(_ipToken, _baseToken, _baseTokensAmount);
        return amount;
    }

    function GPDepositRunning(
        address _ipToken,
        address _baseToken,
        uint256 _baseTokensAmount,
        bool _create
    )
        external whenNotPaused
        returns (uint256 amount)
    {
        (bool status, bytes memory data) = curVersion.gpdc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "GPDepositRunning(address,address,uint256,bool)")),
            _ipToken, _baseToken, _baseTokensAmount, _create));
        require(status, "GP Deposit Failed");
        amount = data.bytesToUint256();
        emit RunningGPDeposit(_ipToken, _baseToken, _baseTokensAmount);
        return amount;
    }

    function GPDoDepositRunning(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
    {
        (bool status,) = curVersion.gpdc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "GPDoDepositRunning(address,address)")), _ipToken, _baseToken));
        require(status, "GP Do Deposit Failed");
        emit RunningGPDoDeposit(_ipToken, _baseToken);
    }

    function GPWithdrawRunning(
        address _ipToken,
        address _baseToken,
        uint256 _baseTokensAmount
    )
        external whenNotPaused
        returns (uint256 amount)
    {
        (bool status, bytes memory data) = curVersion.gpwc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "GPWithdrawRunning(address,address,uint256)")),
            _ipToken, _baseToken, _baseTokensAmount));
        require(status, "GP Withdraw Failed");
        amount = data.bytesToUint256();
        emit RunningGPWithdraw(_ipToken, _baseToken, _baseTokensAmount);
        return amount;
    }

    function GPWithdrawLiquidation(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
    {
        (bool status,) = curVersion.gpwc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "GPWithdrawLiquidation(address,address)")),
            _ipToken, _baseToken));
        require(status, "GP Withdraw Failed");
        emit LiquidationGPWithdraw(_ipToken, _baseToken);
    }

    function LPDepositRaising(
        address _ipToken,
        address _baseToken,
        uint256 _baseTokensAmount,
        bool _create
    )
        external whenNotPaused
        returns (uint256 amount)
    {
        (bool status, bytes memory data) = curVersion.lpc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "LPDepositRaising(address,address,uint256,bool)")),
            _ipToken, _baseToken, _baseTokensAmount, _create));
        require(status, "LP Deposit Failed");
        amount = data.bytesToUint256();
        emit RaisingLPDeposit(_ipToken, _baseToken, _baseTokensAmount);
        return amount;
    }

    function LPDepositRunning(
        address _ipToken,
        address _baseToken,
        uint256 _baseTokensAmount,
        bool _create
    )
        external whenNotPaused
        returns (uint256 amount)
    {
        (bool status, bytes memory data) = curVersion.lpc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "LPDepositRunning(address,address,uint256,bool)")),
            _ipToken, _baseToken, _baseTokensAmount, _create));
        require(status, "LP Deposit Failed");
        amount = data.bytesToUint256();
        emit RunningLPDeposit(_ipToken, _baseToken, _baseTokensAmount);
        return amount;
    }

    function LPDoDepositRunning(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
    {
        (bool status,) = curVersion.lpc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "LPDoDepositRunning(address,address)")), _ipToken, _baseToken));
        require(status, "LP Do Deposit Failed");
        emit RunningLPDoDeposit(_ipToken, _baseToken);
    }

    function LPWithdrawRunning(
        address _ipToken,
        address _baseToken,
        uint256 _baseTokensAmount,
        bool _vaultOnly
    )
        external whenNotPaused
        returns (uint256 amount)
    {
        (bool status, bytes memory data) = curVersion.lpc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "LPWithdrawRunning(address,address,uint256,bool)")),
            _ipToken, _baseToken, _baseTokensAmount, _vaultOnly));
        require(status, "LP Withdraw Failed");
        amount = data.bytesToUint256();
        emit RunningLPWithdraw(_ipToken, _baseToken, _baseTokensAmount);
        return amount;
    }

    function LPWithdrawLiquidation(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
    {
        (bool status,) = curVersion.lpc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "LPWithdrawLiquidation(address,address)")),
            _ipToken, _baseToken));
        require(status, "LP Withdraw Failed");
        emit LiquidationLPWithdraw(_ipToken, _baseToken);
    }

    function checkAuctionEnd(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
        returns (bool)
    {
        (bool status, bytes memory data) = curVersion.stc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "checkAuctionEnd(address,address)")), _ipToken, _baseToken));
        require(status, "Check Failed");
        return data.bytesToBool();
    }

    function checkRaisingEnd(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
        returns (bool)
    {
        (bool status, bytes memory data) = curVersion.stc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "checkRaisingEnd(address,address)")), _ipToken, _baseToken));
        require(status, "Check Failed");
        return data.bytesToBool();
    }

    function allocateFundraising(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
    {
        (bool status,) = curVersion.stc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "allocateFundraising(address,address)")), _ipToken, _baseToken));
        require(status, "Allocate Failed");
        emit AllocateFundraising(_ipToken, _baseToken);
    }

    function checkRunningEnd(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
        returns (bool)
    {
        (bool status, bytes memory data) = curVersion.lqdc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "checkRunningEnd(address,address)")), _ipToken, _baseToken));
        require(status, "Check Failed");
        return data.bytesToBool();
    }

    function checkIPLiquidation(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
        returns (bool)
    {
        (bool status, bytes memory data) = curVersion.lqdc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "checkIPLiquidation(address,address)")), _ipToken, _baseToken));
        require(status, "Check Failed");
        return data.bytesToBool();
    }

    function checkGPLiquidation(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
        returns (bool)
    {
        (bool status, bytes memory data) = curVersion.lqdc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "checkGPLiquidation(address,address)")), _ipToken, _baseToken));
        require(status, "Check Failed");
        return data.bytesToBool();
    }

    function computeVaultReward(
        address _ipToken,
        address _baseToken
    )
        external whenNotPaused
    {
        (bool status,) = curVersion.vtc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "computeVaultReward(address,address)")), _ipToken, _baseToken));
        require(status, "Compute Reward Failed");
    }

    function withdrawVault(
        address _ipToken,
        address _baseToken,
        uint256 _baseTokensAmount
    )
        external whenNotPaused
        returns (uint256 amount)
    {
        (bool status, bytes memory data) = curVersion.vtc.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256(
            "withdrawVault(address,address,uint256)")),
            _ipToken, _baseToken, _baseTokensAmount));
        require(status, "Withdraw Vault Failed");
        amount = data.bytesToUint256();
        emit WithdrawVault(_ipToken, _baseToken, _baseTokensAmount);
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
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

pragma solidity ^0.8.0;

library BytesUtils {

    function bytesToUint256(bytes memory data) internal pure returns (uint256 res) {
        require(data.length >= 32, "Data Too Short");
        assembly {
            res := mload(add(data, 32))
        }
    }

    function bytesToUint32(bytes memory data) internal pure returns (uint32 res) {
        assembly {
            res := mload(data)
        }
    }
    
    function bytesToBool(bytes memory data) internal pure returns (bool res) {
        assembly {
            res := mload(data)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Safety {
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

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/Authority.sol";
import "./IPStorage.sol";
import "./GPStorage.sol";
import "./VaultStorage.sol";
import "./LPStorage.sol";
import "../lib/Safety.sol";

contract NPStorage is Authority {
    using Safety for uint256;

    uint256 constant RATIO_FACTOR = 1000000;

    uint32 public minRatio = uint32(RATIO_FACTOR * 5 / 10000);
    uint32 public alpha = 0;
    uint32 public raiseRatio = uint32(RATIO_FACTOR * 1);
    // Lowest swap boundary
    uint32 public swapBoundaryRatio = uint32(RATIO_FACTOR * 80 / 100);

    uint256 public auctionDuration = 7 days;
    uint256 public raisingDuration = 3 days;
    uint256 public minimumDuration = 90 days;

    address public DGTToken;
    address public DGTBeneficiary;

    IPStorage public _IPS;
    GPStorage public _GPS;
    LPStorage public _LPS;
    VaultStorage public _VTS;

    event SetMinRatio(uint32 _MinRatio);
    event SetAlpha(uint32 _Alpha);
    event SetRaiseRatio(uint32 _RaiseRatio);
    event SetSwapBoundaryRatio(uint32 _swapBoundaryRatio);
    event SetDuration(uint256 _AuctionDuration, uint256 _RaisingDuration, uint256 _MinimumDuration);

    function setMinRatio(uint32 _minRatio) external onlyOwner {
        minRatio = _minRatio;
        emit SetMinRatio(minRatio);
    }

    function setAlpha(uint32 _alpha) external onlyOwner {
        alpha = _alpha;
        emit SetAlpha(alpha);
    }

    function setRaiseRatio(uint32 _raiseRatio) external onlyOwner {
        raiseRatio = _raiseRatio;
        emit SetRaiseRatio(raiseRatio);
    }

    function setSwapBoundaryRatio(uint32 _swapBoundaryRatio) external onlyOwner {
        require(_swapBoundaryRatio >= RATIO_FACTOR.mul(80).div(100) &&
                _swapBoundaryRatio <= RATIO_FACTOR, "Low Swap Ratio");
        swapBoundaryRatio = _swapBoundaryRatio;
        emit SetSwapBoundaryRatio(swapBoundaryRatio);
    }

    function setDuration(uint256 _auction, uint256 _raising, uint256 _duration) external onlyOwner {
        require(_auction > 0 && _raising > 0 && _duration >= 2 * _raising,
                "Wrong Duration");
        auctionDuration = _auction;
        raisingDuration = _raising;
        minimumDuration = _duration;
        emit SetDuration(auctionDuration, raisingDuration, minimumDuration);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/Authority.sol";
import "./lib/Safety.sol";

contract NPProxy is Authority {
    using Safety for uint256;

    struct LogicContracts {
        address ipc;
        address gpdc;
        address gpwc;
        address lpc;
        address vtc;
        address stc;
        address lqdc;
    }

    mapping(string => LogicContracts) internal versions;
    LogicContracts public curVersion;
    LogicContracts public delayVersion;
    string[] public versionList;
    string public versionName;
    string public delayVersionName;
    uint256 constant delayTime = 24 hours;
    uint256 public startTime;
    bool public initialized;

    event SetUpgrade(string version, address IPlogic, address GPDepositLogic, address GPWithdrawLogic,
                    address LPLogic, address VaultLogic, address StateLogic, address LiquidationLogic);
    event ExecuteUpgrade(string version, address IPlogic, address GPDepositLogic, address GPWithdrawLogic,
                    address LPLogic, address VaultLogic, address StateLogic, address LiquidationLogic);
    event Rollback();

    function setUpgrade(
        string memory _newVersion,
        address _ipc,
        address _gpdc,
        address _gpwc,
        address _lpc,
        address _vtc,
        address _stc,
        address _lqdc
    )
        public onlyOwner
    {
        require(_ipc != address(0) && _gpdc != address(0) && _gpwc != address(0) &&
                _lpc != address(0) && _vtc != address(0) && _stc != address(0) &&
                _lqdc != address(0), "Wrong Address");
        require(bytes(_newVersion).length > 0, "Empty Version");
        require(keccak256(abi.encodePacked(versionName)) != keccak256(abi.encodePacked(_newVersion)), "Existing Version");
        delayVersionName = _newVersion;
        delayVersion.ipc = _ipc;
        delayVersion.gpdc = _gpdc;
        delayVersion.gpwc = _gpwc;
        delayVersion.lpc = _lpc;
        delayVersion.vtc = _vtc;
        delayVersion.stc = _stc;
        delayVersion.lqdc = _lqdc;
        startTime = block.timestamp;
        emit SetUpgrade(_newVersion, _ipc, _gpdc, _gpwc, _lpc, _vtc, _stc, _lqdc);
    }

    function executeUpgrade(
    )
        public onlyOwner
    {
        require(delayVersion.ipc != address(0) && delayVersion.gpdc != address(0) && delayVersion.gpwc != address(0) &&
                delayVersion.lpc != address(0) && delayVersion.vtc != address(0) && delayVersion.stc != address(0) &&
                delayVersion.lqdc != address(0), "Wrong Address");
        if (initialized) {
            require(block.timestamp > startTime.add(delayTime), "In Delay" );
        }
        versions[delayVersionName] = delayVersion;
        versionName = delayVersionName;
        curVersion = delayVersion;
        versionList.push(delayVersionName);
        delayVersionName = '';
        delete delayVersion;
        emit ExecuteUpgrade(versionName, curVersion.ipc, curVersion.gpdc, curVersion.gpwc, curVersion.lpc,
                            curVersion.vtc, curVersion.stc, curVersion.lqdc);
    }

    function rollback(
    )
        external onlyOwner
    {
        delayVersionName = '';
        delete delayVersion;
        emit Rollback();
    }

    function getLogicContracts(
        string calldata _version
    ) 
        external view onlyOwner
        returns(address, address, address, address, address, address, address)
    {
        require(bytes(_version).length > 0, "Empty Version");
        return (versions[_version].ipc, versions[_version].gpdc,
                versions[_version].gpwc, versions[_version].lpc,
                versions[_version].vtc, versions[_version].stc,
                versions[_version].lqdc);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
abstract contract Authority is Context {
    address private _owner;
    address public proxy;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function setProxy(address _proxy) external onlyOwner {
        require(_proxy != address(0), "Invalid Address");
        proxy = _proxy;
    }

    modifier onlyProxy() {
        require(proxy == _msgSender(), "Not Permit: caller is not the proxy"); 
        _;
    }
}

// SPDX-License-Identifier: MIT
import "../lib/Authority.sol";

pragma solidity ^0.8.0;

contract IPStorage is Authority {
    struct IPParam {
        uint32      ipImpawnRatio;
        uint32      ipCloseLine;
        uint32      chargeRatio;
        uint256     duration;
    }

    struct IPInfo {
        address     ip;
        uint256     ipTokensAmount;
        uint256     dgtTokensAmount;
        IPParam     param;
    }

    struct PoolInfo {
        bool        valid;
        bool        locked;
        uint8       stage;

        uint256     id; // index in poolsArray
        uint256     createdTime;
        uint256     auctionEndTime;
        
        uint256     initPrice;
        uint256     initIPCanRaiseAmount;
        uint256     maxIPCanRaiseAmount; // baseToken unit
        IPInfo      IP;
    }

    struct Pool {
        address     ipToken;
        address     baseToken;
    }

    mapping(address => mapping(address => PoolInfo)) private pools;
    Pool[]  private poolsArray;

    function insertPool(address _ipt, address _bst) external onlyProxy {
        require(!pools[_ipt][_bst].valid, "Pool Already Exist");

        poolsArray.push(Pool(_ipt, _bst));
        pools[_ipt][_bst].valid = true;
        pools[_ipt][_bst].locked = false;
        pools[_ipt][_bst].id = poolsArray.length;
        pools[_ipt][_bst].createdTime = block.timestamp;
    }

    function deletePool(address _ipt, address _bst) external onlyProxy {
        require(pools[_ipt][_bst].valid, "Pool Not Exist");
        uint256 id = pools[_ipt][_bst].id;
        uint256 length = poolsArray.length;

        poolsArray[id - 1] = poolsArray[length - 1];
        pools[poolsArray[length - 1].ipToken][poolsArray[length - 1].baseToken].id = id;
        poolsArray.pop();

        pools[_ipt][_bst].valid = false;
        pools[_ipt][_bst].locked = false;
        pools[_ipt][_bst].id = 0;
        pools[_ipt][_bst].createdTime = 0;

        pools[_ipt][_bst].auctionEndTime = 0;
        pools[_ipt][_bst].initPrice = 0;
        pools[_ipt][_bst].initIPCanRaiseAmount = 0;
        pools[_ipt][_bst].maxIPCanRaiseAmount = 0;

        pools[_ipt][_bst].IP.ip = address(0);
        pools[_ipt][_bst].IP.ipTokensAmount = 0;
        pools[_ipt][_bst].IP.dgtTokensAmount = 0;

        pools[_ipt][_bst].IP.param.ipImpawnRatio = 0;
        pools[_ipt][_bst].IP.param.ipCloseLine = 0;
        pools[_ipt][_bst].IP.param.chargeRatio = 0;
        pools[_ipt][_bst].IP.param.duration = 0;
    }

    function setPoolValid(address _ipt, address _bst, bool _valid) external onlyProxy {
        pools[_ipt][_bst].valid = _valid;
    }

    function setPoolLocked(address _ipt, address _bst, bool _locked) external onlyProxy {
        pools[_ipt][_bst].locked = _locked;
    }

    function setPoolStage(address _ipt, address _bst, uint8 _stage) external onlyProxy {
        pools[_ipt][_bst].stage = _stage;
    }

    function setPoolCreateTime(address _ipt, address _bst, uint256 _time) external onlyProxy {
        pools[_ipt][_bst].createdTime = _time;
    }

    function setPoolAuctionEndTime(address _ipt, address _bst, uint256 _time) external onlyProxy {
        pools[_ipt][_bst].auctionEndTime = _time;
    }

    function setPoolInitPrice(address _ipt, address _bst, uint256 _price) external onlyProxy {
        pools[_ipt][_bst].initPrice = _price;
    }

    function setIPInitCanRaise(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].initIPCanRaiseAmount = _amount;
    }

    function setIPMaxCanRaise(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].maxIPCanRaiseAmount = _amount;
    }

    function setIPAddress(address _ipt, address _bst, address _ip) external onlyProxy {
        pools[_ipt][_bst].IP.ip = _ip;
    }

    function setIPTokensAmount(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].IP.ipTokensAmount = _amount;
    }

    function setDGTTokensAmount(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].IP.dgtTokensAmount = _amount;
    }

    function setIPImpawnRatio(address _ipt, address _bst, uint32 _ratio) external onlyProxy {
        pools[_ipt][_bst].IP.param.ipImpawnRatio = _ratio;
    }

    function setIPCloseLine(address _ipt, address _bst, uint32 _ratio) external onlyProxy {
        pools[_ipt][_bst].IP.param.ipCloseLine = _ratio;
    }

    function setIPChargeRatio(address _ipt, address _bst, uint32 _ratio) external onlyProxy {
        pools[_ipt][_bst].IP.param.chargeRatio = _ratio;
    }

    function setIPDuration(address _ipt, address _bst, uint256 _duration) external onlyProxy {
        pools[_ipt][_bst].IP.param.duration = _duration;
    }

    function getPoolValid(address _ipt, address _bst) external view returns(bool) {
        return pools[_ipt][_bst].valid;
    }

    function getPoolLocked(address _ipt, address _bst) external view returns(bool) {
        return pools[_ipt][_bst].locked;
    }

    function getPoolStage(address _ipt, address _bst) external view returns(uint8) {
        return pools[_ipt][_bst].stage;
    }

    function getPoolCreateTime(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].createdTime;
    }

    function getPoolAuctionEndTime(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].auctionEndTime;
    }

    function getPoolInitPrice(address _ipt, address _bst) external view returns(uint256){
        return pools[_ipt][_bst].initPrice;
    }

    function getIPInitCanRaise(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].initIPCanRaiseAmount;
    }

    function getIPMaxCanRaise(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].maxIPCanRaiseAmount;
    }

    function getIPAddress(address _ipt, address _bst) external view returns(address) {
        return pools[_ipt][_bst].IP.ip;
    }

    function getIPTokensAmount(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].IP.ipTokensAmount;
    }

    function getDGTTokensAmount(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].IP.dgtTokensAmount;
    }

    function getIPImpawnRatio(address _ipt, address _bst) external view returns(uint32) {
        return pools[_ipt][_bst].IP.param.ipImpawnRatio;
    }

    function getIPCloseLine(address _ipt, address _bst) external view returns(uint32) {
        return pools[_ipt][_bst].IP.param.ipCloseLine;
    }

    function getIPChargeRatio(address _ipt, address _bst) external view returns(uint32) {
        return pools[_ipt][_bst].IP.param.chargeRatio;
    }

    function getIPDuration(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].IP.param.duration;
    }

    function getPoolsArray() external view returns (address[] memory, address[] memory) {
        uint256 length = poolsArray.length;
        address[] memory iptArr = new address[](length);
        address[] memory bstArr = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            iptArr[i] = poolsArray[i].ipToken;
            bstArr[i] = poolsArray[i].baseToken;
        }

        return (iptArr, bstArr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/Safety.sol";
import "../lib/Authority.sol";

contract GPStorage is Authority {
    using Safety for uint256;

    // For gas optimization
    uint256 constant NONZERO_INIT = 1;

    struct GPInfo {
        bool        valid;
        uint256     id; // index in GPA
        uint256     baseTokensAmount; // baseToken unit
        uint256     baseTokensBalance; // ipTokensAmount * price - raisedFromLPAmount
        uint256     runningDepositAmount;
        uint256     ipTokensAmount; // ipToken unit, include GP and LP
        uint256     raisedFromLPAmount; // baseToken unit
        uint256     overRaisedAmount;    //baseToken repay to GP after raising end
    }

    struct PoolInfo {
        uint256     curTotalGPAmount; // baseToken unit
        uint256     curTotalBalance; // baseToken unit
        uint256     curTotalLPAmount; // baseToken unit
        uint256     curTotalIPAmount; // baseToken swapped into ipToken amount
        uint256     liquidationBaseAmount; // baseToken repay to GP
        uint256     liquidationIPAmount; // IPToken repay to GP

        address[]   GPA;
        mapping(address => GPInfo) GPM;
    }

    mapping(address => mapping(address => PoolInfo)) private pools;

    function setCurGPAmount(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].curTotalGPAmount = _amount;
    }

    function setCurRaiseLPAmount(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].curTotalLPAmount = _amount;
    }

    function setCurIPAmount(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].curTotalIPAmount = _amount;
    }

    function setCurGPBalance(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].curTotalBalance = _amount;
    }

    function setLiquidationBaseAmount(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].liquidationBaseAmount = _amount;
    }

    function setLiquidationIPAmount(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].liquidationIPAmount = _amount;
    }

    function setGPBaseAmount(address _ipt, address _bst, address _gp, uint256 _amount) external onlyProxy {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        pools[_ipt][_bst].GPM[_gp].baseTokensAmount = _amount;
    }

    function setGPRunningDepositAmount(address _ipt, address _bst, address _gp, uint256 _amount) external onlyProxy {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        pools[_ipt][_bst].GPM[_gp].runningDepositAmount = _amount;
    }

    function setGPHoldIPAmount(address _ipt, address _bst, address _gp, uint256 _amount) external onlyProxy {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        pools[_ipt][_bst].GPM[_gp].ipTokensAmount = _amount;
    }

    function setGPRaiseLPAmount(address _ipt, address _bst, address _gp, uint256 _amount) external onlyProxy {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        pools[_ipt][_bst].GPM[_gp].raisedFromLPAmount = _amount;
    }

    function setGPBaseBalance(address _ipt, address _bst, address _gp, uint256 _amount) external onlyProxy {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        pools[_ipt][_bst].GPM[_gp].baseTokensBalance = _amount;
    }

    function setGPAmount(address _ipt, address _bst, address _gp, uint256 _baseAmount, uint256 _baseBalance, uint256 _overRaisedAmount) external onlyProxy {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        pools[_ipt][_bst].GPM[_gp].baseTokensAmount = _baseAmount;
        pools[_ipt][_bst].GPM[_gp].baseTokensBalance = _baseBalance;
        pools[_ipt][_bst].GPM[_gp].overRaisedAmount = NONZERO_INIT.add(_overRaisedAmount);
    }

    function setOverRaisedAmount(address _ipt, address _bst, address _gp, uint256 _amount) external onlyProxy {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        pools[_ipt][_bst].GPM[_gp].overRaisedAmount = _amount;
    }

    function insertGP(address _ipt, address _bst, address _gp, uint256 _amount, bool running) external onlyProxy {
        require(!pools[_ipt][_bst].GPM[_gp].valid, "GP Already Exist");
        pools[_ipt][_bst].GPA.push(_gp);

        pools[_ipt][_bst].GPM[_gp].valid = true;
        pools[_ipt][_bst].GPM[_gp].id = pools[_ipt][_bst].GPA.length;
        if (running) {
            pools[_ipt][_bst].GPM[_gp].baseTokensAmount = 0;
            pools[_ipt][_bst].GPM[_gp].runningDepositAmount = _amount;
        } else {
            pools[_ipt][_bst].GPM[_gp].baseTokensAmount = _amount;
            pools[_ipt][_bst].GPM[_gp].runningDepositAmount = 0;
        }

        pools[_ipt][_bst].GPM[_gp].ipTokensAmount = NONZERO_INIT;
        pools[_ipt][_bst].GPM[_gp].raisedFromLPAmount = NONZERO_INIT;
        pools[_ipt][_bst].GPM[_gp].overRaisedAmount = NONZERO_INIT;
        pools[_ipt][_bst].GPM[_gp].baseTokensBalance = 0;
    }

    function deleteGP(address _ipt, address _bst, address _gp) external onlyProxy {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        uint256 id = pools[_ipt][_bst].GPM[_gp].id;
        uint256 length = pools[_ipt][_bst].GPA.length;

        pools[_ipt][_bst].GPA[id - 1] = pools[_ipt][_bst].GPA[length - 1];
        pools[_ipt][_bst].GPM[pools[_ipt][_bst].GPA[length - 1]].id = id;
        pools[_ipt][_bst].GPA.pop();

        pools[_ipt][_bst].GPM[_gp].valid = false;
        pools[_ipt][_bst].GPM[_gp].id = 0;
        pools[_ipt][_bst].GPM[_gp].baseTokensAmount = 0;
        pools[_ipt][_bst].GPM[_gp].runningDepositAmount = 0;
        pools[_ipt][_bst].GPM[_gp].ipTokensAmount = 0;
        pools[_ipt][_bst].GPM[_gp].raisedFromLPAmount = 0;
        pools[_ipt][_bst].GPM[_gp].overRaisedAmount = 0;
        pools[_ipt][_bst].GPM[_gp].baseTokensBalance = 0;
    }

    function getCurGPAmount(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].curTotalGPAmount;
    }

    function getCurRaiseLPAmount(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].curTotalLPAmount;
    }

    function getCurIPAmount(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].curTotalIPAmount;
    }

    function getCurGPBalance(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].curTotalBalance;
    }

    function getLiquidationBaseAmount(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].liquidationBaseAmount;
    }

    function getLiquidationIPAmount(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].liquidationIPAmount;
    }

    function getGPBaseAmount(address _ipt, address _bst, address _gp) external view returns(uint256) {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        return pools[_ipt][_bst].GPM[_gp].baseTokensAmount;
    }

    function getGPRunningDepositAmount(address _ipt, address _bst, address _gp) external view returns(uint256) {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        return pools[_ipt][_bst].GPM[_gp].runningDepositAmount;
    }

    function getGPHoldIPAmount(address _ipt, address _bst, address _gp) external view returns(uint256) {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        return pools[_ipt][_bst].GPM[_gp].ipTokensAmount;
    }

    function getGPRaiseLPAmount(address _ipt, address _bst, address _gp) external view returns(uint256) {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        return pools[_ipt][_bst].GPM[_gp].raisedFromLPAmount;
    }

    function getGPBaseBalance(address _ipt, address _bst, address _gp) external view returns(uint256) {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        return pools[_ipt][_bst].GPM[_gp].baseTokensBalance;
    }

    function getOverRaisedAmount(address _ipt, address _bst, address _gp) external view returns(uint256) {
        require(pools[_ipt][_bst].GPM[_gp].valid, "GP Not Exist");
        if (pools[_ipt][_bst].GPM[_gp].overRaisedAmount == 0) {
            return 0;
        } else {
            return pools[_ipt][_bst].GPM[_gp].overRaisedAmount.sub(NONZERO_INIT);
        }
    }

    function getGPValid(address _ipt, address _bst, address _gp) external view returns(bool) {
        return pools[_ipt][_bst].GPM[_gp].valid;
    }

    function getGPArrayLength(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].GPA.length;
    }

    function getGPByIndex(address _ipt, address _bst, uint256 _id) external view returns(address) {
        require(_id < pools[_ipt][_bst].GPA.length, "Wrong ID");
        return pools[_ipt][_bst].GPA[_id];
    }

    function getGPAddresses(address _ipt, address _bst) external view returns(address[] memory) {
        return pools[_ipt][_bst].GPA;
    }

    function allocateFunds(address _ipt, address _bst) external onlyProxy {
        uint256 len = pools[_ipt][_bst].GPA.length;
        uint256 balance = pools[_ipt][_bst].curTotalBalance;
        uint256 IPAmount = pools[_ipt][_bst].curTotalIPAmount;
        uint256 raiseLP = pools[_ipt][_bst].curTotalLPAmount;
        uint256 resIPAmount = IPAmount;
        uint256 resRaiseLP = raiseLP;

        for (uint256 i = 0; i < len; i++) {
            address gp = pools[_ipt][_bst].GPA[i];
            uint256 gpBalance = pools[_ipt][_bst].GPM[gp].baseTokensBalance;

            uint256 curIPAmount = gpBalance.mul(IPAmount).div(balance);
            resIPAmount -= curIPAmount;
            curIPAmount = i == len - 1 ? curIPAmount.add(resIPAmount) : curIPAmount;

            uint256 curRaiseAmount = gpBalance.mul(raiseLP).div(balance);
            resRaiseLP -= curRaiseAmount;
            curRaiseAmount = i == len - 1 ? curRaiseAmount.add(resRaiseLP) : curRaiseAmount;

            pools[_ipt][_bst].GPM[gp].ipTokensAmount = curIPAmount;
            pools[_ipt][_bst].GPM[gp].raisedFromLPAmount = curRaiseAmount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Authority.sol";

contract VaultStorage is Authority {
    struct VaultInfo {
        uint256     totalVault;
        uint256     ipWithdrawed;
        uint256     curVault;
        uint256     lastUpdateTime;
    }

    struct PoolInfo {
        VaultInfo   VT;
    }

    mapping(address => mapping(address => PoolInfo)) private pools;

    function setTotalVault(address _ipt, address _bst, uint256 amount) external onlyProxy {
        pools[_ipt][_bst].VT.totalVault = amount;
    }

    function setIPWithdrawed(address _ipt, address _bst, uint256 amount) external onlyProxy {
        pools[_ipt][_bst].VT.ipWithdrawed = amount;
    }

    function setCurVault(address _ipt, address _bst, uint256 amount) external onlyProxy {
        pools[_ipt][_bst].VT.curVault = amount;
    }

    function setLastUpdateTime(address _ipt, address _bst, uint256 time) external onlyProxy {
        pools[_ipt][_bst].VT.lastUpdateTime = time;
    }

    function getTotalVault(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].VT.totalVault;
    }

    function getIPWithdrawed(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].VT.ipWithdrawed;
    }

    function getCurVault(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].VT.curVault;
    }

    function getLastUpdateTime(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].VT.lastUpdateTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/Safety.sol";
import "../lib/Authority.sol";

contract LPStorage is Authority {
    using Safety for uint256;

    struct LPInfo {
        bool        valid;
        uint256     id; // index in LPA
        uint256     baseTokensAmount;
        uint256     runningDepositAmount;
        uint256     accVaultReward;
    }

    struct PoolInfo {
        uint256     curTotalLPAmount; // baseToken unit
        uint256     liquidationBaseAmount; // baseToken repay to LP
        uint256     liquidationIPAmount; // IPToken repay to LP

        address[]   LPA;
        mapping(address => LPInfo) LPM;
    }

    // For gas optimization
    uint256 constant NONZERO_INIT = 1;

    mapping(address => mapping(address => PoolInfo)) private pools;

    function setCurLPAmount(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].curTotalLPAmount = _amount;
    }

    function setLiquidationBaseAmount(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].liquidationBaseAmount = _amount;
    }

    function setLiquidationIPAmount(address _ipt, address _bst, uint256 _amount) external onlyProxy {
        pools[_ipt][_bst].liquidationIPAmount = _amount;
    }

    function divideVault(address _ipt, address _bst, uint256 _vault) external onlyProxy {
        uint256 len = pools[_ipt][_bst].LPA.length;
        uint256 LPAmount = pools[_ipt][_bst].curTotalLPAmount;
        uint256 resVault = _vault;

        for (uint256 i = 0; i < len; i++) {
            address lp = pools[_ipt][_bst].LPA[i];
            uint256 reward = pools[_ipt][_bst].LPM[lp].accVaultReward;
            uint256 amount = pools[_ipt][_bst].LPM[lp].baseTokensAmount;
            uint256 curVault = _vault.mul(amount).div(LPAmount);

            resVault -= curVault;
            curVault = i == len - 1 ? curVault.add(resVault) : curVault;
            pools[_ipt][_bst].LPM[lp].accVaultReward = reward.add(curVault);
        }
    }

    function setLPBaseAmount(address _ipt, address _bst, address _lp, uint256 _amount) external onlyProxy {
        require(pools[_ipt][_bst].LPM[_lp].valid, "LP Not Exist");
        pools[_ipt][_bst].LPM[_lp].baseTokensAmount = _amount;
    }

    function setLPRunningDepositAmount(address _ipt, address _bst, address _lp, uint256 _amount) external onlyProxy {
        require(pools[_ipt][_bst].LPM[_lp].valid, "LP Not Exist");
        pools[_ipt][_bst].LPM[_lp].runningDepositAmount = _amount;
    }

    function setLPVaultReward(address _ipt, address _bst, address _lp, uint256 _amount) external onlyProxy {
        require(pools[_ipt][_bst].LPM[_lp].valid, "LP Not Exist");
        pools[_ipt][_bst].LPM[_lp].accVaultReward = NONZERO_INIT.add(_amount);
    }

    function insertLP(address _ipt, address _bst, address _lp, uint256 _amount, bool running) external onlyProxy {
        require(!pools[_ipt][_bst].LPM[_lp].valid, "LP Already Exist");
        pools[_ipt][_bst].LPA.push(_lp);

        pools[_ipt][_bst].LPM[_lp].valid = true;
        pools[_ipt][_bst].LPM[_lp].id = pools[_ipt][_bst].LPA.length;
        if (running) {
            pools[_ipt][_bst].LPM[_lp].baseTokensAmount = 0;
            pools[_ipt][_bst].LPM[_lp].runningDepositAmount = _amount;
        } else {
            pools[_ipt][_bst].LPM[_lp].baseTokensAmount = _amount;
            pools[_ipt][_bst].LPM[_lp].runningDepositAmount = 0;
        }
        
        pools[_ipt][_bst].LPM[_lp].accVaultReward = NONZERO_INIT;
    }

    function deleteLP(address _ipt, address _bst, address _lp) external onlyProxy {
        require(pools[_ipt][_bst].LPM[_lp].valid, "LP Not Exist");
        uint256 id = pools[_ipt][_bst].LPM[_lp].id;
        uint256 length = pools[_ipt][_bst].LPA.length;

        pools[_ipt][_bst].LPA[id - 1] = pools[_ipt][_bst].LPA[length - 1];
        pools[_ipt][_bst].LPM[pools[_ipt][_bst].LPA[length - 1]].id = id;
        pools[_ipt][_bst].LPA.pop();

        pools[_ipt][_bst].LPM[_lp].valid = false;
        pools[_ipt][_bst].LPM[_lp].id = 0;
        pools[_ipt][_bst].LPM[_lp].baseTokensAmount = 0;
        pools[_ipt][_bst].LPM[_lp].runningDepositAmount = 0;
        pools[_ipt][_bst].LPM[_lp].accVaultReward = 0;
    }

    function getCurLPAmount(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].curTotalLPAmount;
    }

    function getLiquidationBaseAmount(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].liquidationBaseAmount;
    }

    function getLiquidationIPAmount(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].liquidationIPAmount;
    }

    function getLPBaseAmount(address _ipt, address _bst, address _lp) external view returns(uint256) {
        require(pools[_ipt][_bst].LPM[_lp].valid, "LP Not Exist");
        return pools[_ipt][_bst].LPM[_lp].baseTokensAmount;
    }

    function getLPRunningDepositAmount(address _ipt, address _bst, address _lp) external view returns(uint256) {
        require(pools[_ipt][_bst].LPM[_lp].valid, "LP Not Exist");
        return pools[_ipt][_bst].LPM[_lp].runningDepositAmount;
    }

    function getLPVaultReward(address _ipt, address _bst, address _lp) external view returns(uint256) {
        require(pools[_ipt][_bst].LPM[_lp].valid, "LP Not Exist");
        return pools[_ipt][_bst].LPM[_lp].accVaultReward.sub(NONZERO_INIT);
    }

    function getLPValid(address _ipt, address _bst, address _lp) external view returns(bool) {
        return pools[_ipt][_bst].LPM[_lp].valid;
    }

    function getLPArrayLength(address _ipt, address _bst) external view returns(uint256) {
        return pools[_ipt][_bst].LPA.length;
    }

    function getLPByIndex(address _ipt, address _bst, uint256 _id) external view returns(address) {
        require(_id < pools[_ipt][_bst].LPA.length, "Wrong ID");
        return pools[_ipt][_bst].LPA[_id];
    }

    function getLPAddresses(address _ipt, address _bst) external view returns(address[] memory){
        return pools[_ipt][_bst].LPA;
    }
}

