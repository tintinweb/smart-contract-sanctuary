// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './ICalcifireVault.sol';
import './Ownable.sol';
import './SafeMath.sol';


interface IKawaiiVault {
    function earn(uint, uint, uint, uint) external;

    function getExpectedOutputs() external view returns (uint, uint, uint, uint);

    function totalStake() external view returns (uint);
}

interface KeeperCompatibleInterface {
    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (
        bool upkeepNeeded,
        bytes memory performData
    );

    function performUpkeep(
        bytes calldata performData
    ) external;
}

contract KawaiiKeeper is Ownable, KeeperCompatibleInterface {
    using SafeMath for uint;

    struct VaultInfo {
        uint lastCompound;
        bool enabled;
    }

    struct CompoundInfo {
        address[] kawaiiVaults;
        uint[] minPlatformOutputs;
        uint[] minKeeperOutputs;
        uint[] minBurnOutputs;
        uint[] minCalcifireOutputs;
    }

    ICalcifireVault immutable public AUTO_CALCIFIRE;

    address[] public kawaiiVaults;

    mapping(address => VaultInfo) public vaultInfos;

    address public keeper;
    address public moderator;

    uint public maxDelay = 1 days;
    uint public minKeeperFee = 25000000000000;
    uint public slippageFactor = 9600; // 4%
    uint16 public maxVaults = 3;

    constructor(
        address _keeper,
        address _moderator,
        address _owner,
        address _autoCalcifire
    ) public {

        require(_keeper != address(0), "_keeper cannot be zero address");
        require(_moderator != address(0), "_moderator cannot be zero address");
        require(_owner != address(0), "_owner cannot be zero address");
        require(_autoCalcifire != address(0), "_autoCalcifire cannot be zero address");

        AUTO_CALCIFIRE = ICalcifireVault(_autoCalcifire);
        keeper = _keeper;
        moderator = _moderator;

        transferOwnership(_owner);
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "KawaiiKeeper::onlyKeeper: Not keeper");
        _;
    }

    modifier onlyModerator() {
        require(msg.sender == moderator, "KawaiiKeeper::onlyModerator: Not moderator");
        _;
    }

    function checkUpkeep(
        bytes calldata
    ) external override view returns (
        bool upkeepNeeded,
        bytes memory performData
    ) {
        CompoundInfo memory tempCompoundInfo = CompoundInfo(
            new address[](kawaiiVaults.length),
            new uint[](kawaiiVaults.length),
            new uint[](kawaiiVaults.length),
            new uint[](kawaiiVaults.length),
            new uint[](kawaiiVaults.length)
        );

        uint16 kawaiiVaultsLength = 0;

        for (uint16 index = 0; index < kawaiiVaults.length; ++index) {
            if (maxVaults == kawaiiVaultsLength) {
                continue;
            }

            address vault = kawaiiVaults[index];
            VaultInfo memory vaultInfo = vaultInfos[vault];

            if (!vaultInfo.enabled || IKawaiiVault(vault).totalStake() == 0) {
                continue;
            }

            (uint platformOutput, uint keeperOutput, uint burnOutput, uint calcifireOutput) = _getExpectedOutputs(vault);

            if (
                block.timestamp >= vaultInfo.lastCompound + maxDelay
                || keeperOutput >= minKeeperFee
            ) {
                tempCompoundInfo.kawaiiVaults[kawaiiVaultsLength] = vault;

                tempCompoundInfo.minPlatformOutputs[kawaiiVaultsLength] = platformOutput.mul(slippageFactor).div(10000);
                tempCompoundInfo.minKeeperOutputs[kawaiiVaultsLength] = keeperOutput.mul(slippageFactor).div(10000);
                tempCompoundInfo.minBurnOutputs[kawaiiVaultsLength] = burnOutput.mul(slippageFactor).div(10000);
                tempCompoundInfo.minCalcifireOutputs[kawaiiVaultsLength] = calcifireOutput.mul(slippageFactor).div(10000);

                kawaiiVaultsLength = kawaiiVaultsLength + 1;
            }
        }

        if (kawaiiVaultsLength > 0) {
            CompoundInfo memory compoundInfo = CompoundInfo(
                new address[](kawaiiVaultsLength),
                new uint[](kawaiiVaultsLength),
                new uint[](kawaiiVaultsLength),
                new uint[](kawaiiVaultsLength),
                new uint[](kawaiiVaultsLength)
            );

            for (uint16 index = 0; index < kawaiiVaultsLength; ++index) {
                compoundInfo.kawaiiVaults[index] = tempCompoundInfo.kawaiiVaults[index];
                compoundInfo.minPlatformOutputs[index] = tempCompoundInfo.minPlatformOutputs[index];
                compoundInfo.minKeeperOutputs[index] = tempCompoundInfo.minKeeperOutputs[index];
                compoundInfo.minBurnOutputs[index] = tempCompoundInfo.minBurnOutputs[index];
                compoundInfo.minCalcifireOutputs[index] = tempCompoundInfo.minCalcifireOutputs[index];
            }

            return (true, abi.encode(
                compoundInfo.kawaiiVaults,
                compoundInfo.minPlatformOutputs,
                compoundInfo.minKeeperOutputs,
                compoundInfo.minBurnOutputs,
                compoundInfo.minCalcifireOutputs
            ));
        }

        return (false, "");
    }

    function performUpkeep(
        bytes calldata performData
    ) external override onlyKeeper {
        (
        address[] memory _kawaiiVaults,
        uint[] memory _minPlatformOutputs,
        uint[] memory _minKeeperOutputs,
        uint[] memory _minBurnOutputs,
        uint[] memory _minCalcifireOutputs
        ) = abi.decode(
            performData,
            (address[], uint[], uint[], uint[], uint[])
        );

        _earn(
            _kawaiiVaults,
            _minPlatformOutputs,
            _minKeeperOutputs,
            _minBurnOutputs,
            _minCalcifireOutputs
        );
    }

    function _earn(
        address[] memory _kawaiiVaults,
        uint[] memory _minPlatformOutputs,
        uint[] memory _minKeeperOutputs,
        uint[] memory _minBurnOutputs,
        uint[] memory _minCalcifireOutputs
    ) private {

        uint kawaiiLength = _kawaiiVaults.length;

        for (uint index = 0; index < kawaiiLength; ++index) {
            address vault = _kawaiiVaults[index];

            IKawaiiVault(vault).earn(
                _minPlatformOutputs[index],
                _minKeeperOutputs[index],
                _minBurnOutputs[index],
                _minCalcifireOutputs[index]
            );

            vaultInfos[vault].lastCompound = block.timestamp;
        }

        AUTO_CALCIFIRE.harvest();
    }

    function _getExpectedOutputs(
        address _vault
    ) private view returns (
        uint, uint, uint, uint
    ) {
        try IKawaiiVault(_vault).getExpectedOutputs() returns (
            uint platformOutput,
            uint keeperOutput,
            uint burnOutput,
            uint calcifireOutput
        ) {
            return (platformOutput, keeperOutput, burnOutput, calcifireOutput);
        }
        catch (bytes memory) {
        }

        return (0, 0, 0, 0);
    }


    function kawaiiVaultsLength() external view returns (uint) {
        return kawaiiVaults.length;
    }

    function addVault(address _vault) public onlyModerator {
        require(
            vaultInfos[_vault].lastCompound == 0,
            "KawaiiKeeper::addVault: Vault already exists"
        );

        vaultInfos[_vault] = VaultInfo(
            block.timestamp - 6 hours,
            true
        );

        kawaiiVaults.push(_vault);
    }

    function enableVault(address _vault) external onlyModerator {
        vaultInfos[_vault].enabled = true;
    }

    function disableVault(address _vault) external onlyModerator {
        vaultInfos[_vault].enabled = false;
    }

    function setKeeper(address _keeper) public onlyOwner {
        keeper = _keeper;
    }

    function setModerator(address _moderator) public onlyOwner {
        moderator = _moderator;
    }

    function setMaxDelay(uint _maxDelay) public onlyOwner {
        maxDelay = _maxDelay;
    }

    function setMinKeeperFee(uint _minKeeperFee) public onlyOwner {
        minKeeperFee = _minKeeperFee;
    }

    function setSlippageFactor(uint _slippageFactor) public onlyOwner {
        slippageFactor = _slippageFactor;
    }

    function setMaxVaults(uint16 _maxVaults) public onlyOwner {
        maxVaults = _maxVaults;
    }
}