// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./PositionsV2.sol";
import "./CometStoreV2.sol";
import "./comets/IComet.sol";
import "./solarsystem/SolarSystemStore.sol";

interface ICometManagerV3 {
    struct Comet {
        address id;
        PositionsV2.Orbit orbit;
        address token;
        uint256 unit;
        uint256 balance;
        uint256 solarSystemID;
    }

    event NewComet(
        address indexed cometId,
        address indexed token,
        uint256 balance,
        uint256 unit,
        uint256 solarSystemID
    );

    event RemoveComet(
        address indexed cometId,
        address indexed token,
        uint256 solarSystemID
    );

    function updateSolarSystemStore(address newStore) external;

    function addComet(
        address cometId,
        int256 x,
        int256 y,
        uint32 distance,
        uint16 rotationSpeed,
        uint256 solarSystemID
    ) external;

    function removeComet(address cometId, uint256 solarSystemID) external;

    function cometPosition(
        address cometId,
        uint256 time,
        uint256 solarSystemID
    ) external view returns (PositionsV2.Cartesian memory);

    function getComet(address cometId, uint256 solarSystemID)
        external
        view
        returns (Comet memory);

    function cometsFrom(uint256 solarSystemID)
        external
        view
        returns (Comet[] memory);

    function countCometIn(uint256 solarSystemID)
        external
        view
        returns (uint256);
}

contract CometManagerV3 is Ownable, ICometManagerV3, Modulable {
    using PositionsV2 for *;

    ISolarSystemStore public solarSystemStore;

    constructor(address ssStore) public {
        updateSolarSystemStore(ssStore);
    }

    function updateSolarSystemStore(address newStore)
        public
        override
        onlyOwner
    {
        solarSystemStore = ISolarSystemStore(newStore);
    }

    function addComet(
        address cometId,
        int256 x,
        int256 y,
        uint32 distance,
        uint16 rotationSpeed,
        uint256 solarSystemID
    ) external override onlyOwner {
        ICometStoreV2 cometStore =
            ICometStoreV2(solarSystemStore.cometStoreFor(solarSystemID));

        PositionsV2.Orbit memory orbit =
            PositionsV2.Orbit({
                center: PositionsV2.Cartesian({x: x, y: y}),
                last: PositionsV2.Polar({angle: 0, distance: distance}),
                lastUpdate: block.timestamp,
                rotationSpeed: rotationSpeed
            });

        cometStore.add(cometId, orbit);

        NewComet(
            cometId,
            IComet(cometId).token(),
            IComet(cometId).balance(),
            IComet(cometId).unit(),
            solarSystemID
        );
    }

    function removeComet(address cometId, uint256 solarSystemID)
        external
        override
    {
        require(
            isModule(msg.sender) || msg.sender == owner(),
            "CometManager: require module or owner"
        );
        _removeComet(cometId, solarSystemID);
    }

    function cometPosition(
        address cometId,
        uint256 time,
        uint256 solarSystemID
    ) public view override returns (PositionsV2.Cartesian memory position) {
        ICometStoreV2 cometStore =
            ICometStoreV2(solarSystemStore.cometStoreFor(solarSystemID));

        return PositionsV2.cartesianCoordinate(cometStore.orbit(cometId), time);
    }

    function getComet(address cometId, uint256 solarSystemID)
        public
        view
        override
        returns (Comet memory)
    {
        ICometStoreV2 cometStore =
            ICometStoreV2(solarSystemStore.cometStoreFor(solarSystemID));

        Comet memory comet =
            Comet({
                id: cometId,
                orbit: cometStore.orbit(cometId),
                token: IComet(cometId).token(),
                unit: IComet(cometId).unit(),
                balance: IComet(cometId).balance(),
                solarSystemID: solarSystemID
            });

        return comet;
    }

    function cometsFrom(uint256 solarSystemID)
        external
        view
        override
        returns (Comet[] memory)
    {
        ICometStoreV2 cometStore =
            ICometStoreV2(solarSystemStore.cometStoreFor(solarSystemID));

        Comet[] memory result = new Comet[](cometStore.length());
        for (uint256 i = 0; i < cometStore.length(); i++) {
            result[i] = getComet(cometStore.idAt(i), solarSystemID);
        }
        return result;
    }

    function countCometIn(uint256 solarSystemID)
        external
        view
        override
        returns (uint256)
    {
        ICometStoreV2 cometStore =
            ICometStoreV2(solarSystemStore.cometStoreFor(solarSystemID));

        return cometStore.length();
    }

    function _removeComet(address cometId, uint256 solarSystemID) internal {
        ICometStoreV2 cometStore =
            ICometStoreV2(solarSystemStore.cometStoreFor(solarSystemID));

        cometStore.remove(cometId);
        RemoveComet(cometId, IComet(cometId).token(), solarSystemID);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./PositionsV2.sol";
import "./Modulable.sol";

interface ICometStoreV2 {
    function add(address cometId, PositionsV2.Orbit memory orbit) external;

    function remove(address cometId) external;

    function length() external view returns (uint256);

    function idAt(uint256 index) external view returns (address);

    function ids() external view returns (address[] memory);

    function contains(address cometId) external view returns (bool);

    function orbit(address cometId)
        external
        view
        returns (PositionsV2.Orbit memory);
}

contract CometStoreV2 is ICometStoreV2, Modulable {
    using PositionsV2 for *;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _cometIds;
    mapping(address => PositionsV2.Orbit) internal orbits;

    constructor() public {}

    function add(address cometId, PositionsV2.Orbit memory orbit)
        external
        override
        onlyModule
    {
        require(_cometIds.add(cometId), "Store: already exist");
        orbits[cometId] = orbit;
    }

    function remove(address cometId) external override onlyModule {
        require(_cometIds.remove(cometId), "Store: unknow");
    }

    function length() external view override returns (uint256) {
        return _cometIds.length();
    }

    function idAt(uint256 index) external view override returns (address) {
        return _cometIds.at(index);
    }

    function ids() external view override returns (address[] memory) {
        address[] memory result = new address[](_cometIds.length());
        for (uint256 i = 0; i < _cometIds.length(); i++) {
            result[i] = _cometIds.at(i);
        }
        return result;
    }

    function contains(address minerId) external view override returns (bool) {
        return _cometIds.contains(minerId);
    }

    function orbit(address minerId)
        external
        view
        override
        returns (PositionsV2.Orbit memory)
    {
        return orbits[minerId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SpaceShipsRules.sol";

abstract contract HasRules is Ownable {
    SpaceShipsRules private _rules;

    event RulesChanged(address indexed previousRules, address indexed newRules);

    constructor(address rules) internal {
        changeRules(rules);
    }

    function defaultRotationSpeed() public view returns (int32) {
        return _rules.defaultRotationSpeed();
    }

    function boosterOf(uint256 id) public view returns (uint256) {
        return _rules.boosterOf(id);
    }

    function radarOf(uint256 id) public view returns (uint8) {
        return _rules.radarOf(id);
    }

    function drillOf(uint256 id, uint256 initialAmount)
        public
        view
        returns (uint256)
    {
        return _rules.drillOf(id, initialAmount);
    }

    function machineryOf(uint256 id) public view returns (uint256) {
        return _rules.machineryOf(id);
    }

    function changeRules(address newRules) public virtual onlyOwner {
        emit RulesChanged(address(_rules), newRules);
        _rules = SpaceShipsRules(newRules);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./PositionsV2.sol";
import "./Modulable.sol";

interface IMinerStoreV2 {
    function add(
        uint256 minerId,
        PositionsV2.Orbit memory orbit,
        uint256 pullingPrice
    ) external;

    function remove(uint256 minerId) external;

    function updateOrbit(uint256 minerId, PositionsV2.Orbit memory newOrbit)
        external;

    function updatePullingPrice(uint256 minerId, uint256 newPullingPrice)
        external;

    function updateLastAction(uint256 minerId, uint256 time) external;

    function length() external view returns (uint256);

    function idAt(uint256 index) external view returns (uint256);

    function ids() external view returns (uint256[] memory);

    function contains(uint256 minerId) external view returns (bool);

    function orbit(uint256 minerId)
        external
        view
        returns (PositionsV2.Orbit memory);

    function pullingPrice(uint256 minerId) external view returns (uint256);

    function lastAction(uint256 minerId) external view returns (uint256);
}

contract MinerStoreV2 is IMinerStoreV2, Modulable {
    using PositionsV2 for *;
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet internal _minerIds;
    mapping(uint256 => PositionsV2.Orbit) internal orbits;
    mapping(uint256 => uint256) internal pullingPrices;
    mapping(uint256 => uint256) internal lastActions;

    constructor() public {}

    function add(
        uint256 minerId,
        PositionsV2.Orbit memory orbit,
        uint256 pullingPrice
    ) external override onlyModule {
        require(_minerIds.add(minerId), "Store: already exist");
        orbits[minerId] = orbit;
        pullingPrices[minerId] = pullingPrice;
        lastActions[minerId] = 0;
    }

    function remove(uint256 minerId) external override onlyModule {
        require(_minerIds.remove(minerId), "Store: unknow");
    }

    function updateOrbit(uint256 minerId, PositionsV2.Orbit memory newOrbit)
        external
        override
        onlyModule
    {
        orbits[minerId] = newOrbit;
    }

    function updatePullingPrice(uint256 minerId, uint256 newPullingPrice)
        external
        override
        onlyModule
    {
        pullingPrices[minerId] = newPullingPrice;
    }

    function updateLastAction(uint256 minerId, uint256 time)
        external
        override
        onlyModule
    {
        lastActions[minerId] = time;
    }

    function length() external view override returns (uint256) {
        return _minerIds.length();
    }

    function idAt(uint256 index) external view override returns (uint256) {
        return _minerIds.at(index);
    }

    function ids() external view override returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_minerIds.length());
        for (uint256 i = 0; i < _minerIds.length(); i++) {
            result[i] = _minerIds.at(i);
        }
        return result;
    }

    function contains(uint256 minerId) external view override returns (bool) {
        return _minerIds.contains(minerId);
    }

    function orbit(uint256 minerId)
        external
        view
        override
        returns (PositionsV2.Orbit memory)
    {
        return orbits[minerId];
    }

    function pullingPrice(uint256 minerId)
        external
        view
        override
        returns (uint256)
    {
        return pullingPrices[minerId];
    }

    function lastAction(uint256 minerId)
        external
        view
        override
        returns (uint256)
    {
        return lastActions[minerId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./MinerStoreV2.sol";
import "./CometStoreV2.sol";
import "./CometManagerV3.sol";
import "./solarsystem/SolarSystemStore.sol";
import "./HasRules.sol";

interface IMiningManagerV4 {
    event Mined(
        uint256 indexed minerId,
        address indexed owner,
        address indexed cometId,
        address cometToken,
        uint256 amount,
        uint256 solarSystemID,
        uint256 time
    );

    function mine(
        uint256 minerId,
        address cometId,
        uint256 timestamp,
        uint256 solarSystemID
    ) external;

    function canMine(
        uint256 minerId,
        address cometId,
        uint256 time,
        uint256 solarSystemID
    ) external view returns (bool);

    function updateCometManager(address newCometManager) external;

    function updateSolarSystemStore(address newStore) external;

    function updateGateway(address newGateway) external;

    function updateDeltaMiningTime(uint256 newDeltaMiningTime) external;

    function updateFutureMiningTime(uint256 newFutureMiningTime) external;

    function updateNoMiningZone(uint32 distance) external;

    function updateMaxMiningPercentCut(uint16 newMax) external;

    function updateTimeFrameSize(uint16 newFrameSize) external;

    function getTimeFrame(uint256 timestamp) external view returns (uint256);

    function updateCutGap(uint16 newCutGap) external;

    function noMiningZone() external view returns (uint32);

    function pause() external;

    function unpause() external;
}

contract MiningManagerV4 is IMiningManagerV4, Ownable, Pausable, HasRules {
    using PositionsV2 for *;

    IERC721 public gateway;
    ISolarSystemStore public solarSystemStore;

    uint256 public deltaMiningTime = 180;
    uint256 public futureMiningTime = 10;

    uint32 public override noMiningZone = 240;

    uint16 public cutGap = 5;
    uint16 public maxMiningPercentCut = 50;
    uint16 public timeFrameSize = 4;

    mapping(address => mapping(uint256 => uint128)) public mineByTimeframe;

    mapping(uint256 => uint256) public minerLastMine;

    CometManagerV3 public cometManager;

    modifier validMiner(uint256 minerId, uint256 solarSystemID) {
        IMinerStoreV2 minerStore = IMinerStoreV2(
            solarSystemStore.minerStoreFor(solarSystemID)
        );

        require(minerStore.contains(minerId), "MiningManager: unknown miner");
        require(
            msg.sender == gateway.ownerOf(minerId) ||
                gateway.getApproved(minerId) == msg.sender ||
                gateway.isApprovedForAll(gateway.ownerOf(minerId), msg.sender),
            "MiningManager: require owner or approved"
        );
        _;
    }

    constructor(
        address ssStore,
        address newCometManager,
        address spaceshipsRules,
        address newGateway
    ) public HasRules(spaceshipsRules) {
        updateSolarSystemStore(ssStore);
        updateCometManager(newCometManager);
        updateGateway(newGateway);
    }

    function updateGateway(address newGateway) public override onlyOwner {
        gateway = IERC721(newGateway);
    }

    function updateDeltaMiningTime(uint256 newDeltaMiningTime)
        public
        override
        onlyOwner
    {
        deltaMiningTime = newDeltaMiningTime;
    }

    function updateFutureMiningTime(uint256 newFutureMiningTime)
        public
        override
        onlyOwner
    {
        futureMiningTime = newFutureMiningTime;
    }

    function updateSolarSystemStore(address newStore)
        public
        override
        onlyOwner
    {
        solarSystemStore = ISolarSystemStore(newStore);
    }

    function updateCometManager(address newCometManager)
        public
        override
        onlyOwner
    {
        cometManager = CometManagerV3(newCometManager);
    }

    function updateNoMiningZone(uint32 distance) public override onlyOwner {
        noMiningZone = distance;
    }

    function updateMaxMiningPercentCut(uint16 newMax)
        public
        override
        onlyOwner
    {
        maxMiningPercentCut = newMax;
    }

    function updateTimeFrameSize(uint16 newFrameSize)
        external
        override
        onlyOwner
    {
        timeFrameSize = newFrameSize;
    }

    function updateCutGap(uint16 newCutGap) public override onlyOwner {
        cutGap = newCutGap;
    }

    function getTimeFrame(uint256 timestamp)
        public
        view
        override
        returns (uint256)
    {
        return timestamp / timeFrameSize;
    }

    function getMiningAt(address cometId, uint256 timestamp)
        external
        view
        returns (uint128)
    {
        return mineByTimeframe[cometId][getTimeFrame(timestamp)];
    }

    function mine(
        uint256 minerId,
        address cometId,
        uint256 timestamp,
        uint256 solarSystemID
    ) external override validMiner(minerId, solarSystemID) {
        _beforeAction();
        _proximityCheck(minerId, cometId, timestamp, solarSystemID);

        uint256 amount = _calculateAmount(minerId, cometId, timestamp);

        _mine(cometId, gateway.ownerOf(minerId), amount, solarSystemID);

        IMinerStoreV2 minerStore = IMinerStoreV2(
            solarSystemStore.minerStoreFor(solarSystemID)
        );
        minerStore.updateLastAction(minerId, block.timestamp);
        minerLastMine[minerId] = block.timestamp;

        Mined(
            minerId,
            gateway.ownerOf(minerId),
            cometId,
            IComet(cometId).token(),
            amount,
            solarSystemID,
            block.timestamp
        );
    }

    function canMine(
        uint256 minerId,
        address cometId,
        uint256 time,
        uint256 solarSystemID
    ) public view override returns (bool) {
        ICometStoreV2 cometStore = ICometStoreV2(
            solarSystemStore.cometStoreFor(solarSystemID)
        );

        IMinerStoreV2 minerStore = IMinerStoreV2(
            solarSystemStore.minerStoreFor(solarSystemID)
        );

        if (
            block.timestamp - minerStore.lastAction(minerId) <=
            machineryOf(minerId)
        ) {
            return false;
        }

        return
            PositionsV2.collision(
                PositionsV2.cartesianCoordinate(
                    minerStore.orbit(minerId),
                    time
                ),
                PositionsV2.cartesianCoordinate(
                    cometStore.orbit(cometId),
                    time
                ),
                radarOf(minerId)
            );
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _beforeAction() internal view {
        require(!paused(), "MiningManager: paused");
    }

    function _mine(
        address cometId,
        address to,
        uint256 amount,
        uint256 solarSystemID
    ) internal returns (uint256) {
        IComet(cometId).claim(to, amount);

        if (IComet(cometId).balance() == 0) {
            cometManager.removeComet(cometId, solarSystemID);
        }

        return amount;
    }

    function _calculateAmount(
        uint256 minerId,
        address cometId,
        uint256 timestamp
    ) internal returns (uint256) {
        uint256 amount = drillOf(minerId, IComet(cometId).unit());
        amount = _applyCut(cometId, amount, timestamp);

        if (amount > IComet(cometId).balance()) {
            amount = IComet(cometId).balance();
        }
        return amount;
    }

    function _applyCut(
        address cometId,
        uint256 amount,
        uint256 timestamp
    ) internal returns (uint256) {
        uint256 cutPercent = (cutGap *
            mineByTimeframe[cometId][getTimeFrame(timestamp)]);

        if (cutPercent > maxMiningPercentCut) {
            cutPercent = maxMiningPercentCut;
        }

        mineByTimeframe[cometId][getTimeFrame(timestamp)]++;

        return amount - (amount * cutPercent) / 100;
    }

    function _proximityCheck(
        uint256 minerId,
        address cometId,
        uint256 timestamp,
        uint256 solarSystemID
    ) internal {
        ICometStoreV2 cometStore = ICometStoreV2(
            solarSystemStore.cometStoreFor(solarSystemID)
        );

        IMinerStoreV2 minerStore = IMinerStoreV2(
            solarSystemStore.minerStoreFor(solarSystemID)
        );

        require(cometStore.contains(cometId), "MiningManager: unknow comet");
        require(
            timestamp >= block.timestamp - deltaMiningTime,
            "MiningManager: trying to mine too far in the past"
        );

        require(
            timestamp > minerLastMine[minerId],
            "MiningManager: cannot mine before last known mining"
        );

        require(
            timestamp <= block.timestamp + futureMiningTime,
            "MiningManager: trying to mine too far in the futur"
        );
        require(
            timestamp >= minerStore.orbit(minerId).lastUpdate,
            "MiningManager: orbit too recent"
        );
        require(
            canMine(minerId, cometId, timestamp, solarSystemID),
            "MiningManager: comet out of range or miner in cooldown process"
        );
        require(
            minerStore.orbit(minerId).last.distance > noMiningZone,
            "MiningManager: mining disabled in radation zone"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";


contract Modulable is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _modules;

    modifier onlyModule() {
        require(
            _modules.contains(msg.sender),
            "Manager: caller is not a module"
        );
        _;
    }

    constructor() public {}

    function updateModule(address newModule) onlyOwner external {
        _updateModule(newModule);
    }

    function updateModules(address[] memory newModules) onlyOwner external {
        for(uint256 i = 0; i < newModules.length; i++) {
            _updateModule(newModules[i]);
        }
    }

    function isModule(address module) public view returns (bool) {
        return _modules.contains(module);
    }

    function modules() external view returns (address[] memory) {
        address[] memory result = new address[](_modules.length());
        for (uint256 i = 0; i < _modules.length(); i++) {
            result[i] = _modules.at(i);
        }
        return result;
    }

    function _updateModule(address newModule) private {
        if(_modules.contains(newModule)) {
            _modules.remove(newModule);
        } else {
            _modules.add(newModule);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

pragma experimental ABIEncoderV2;

import "./RealMath.sol";

library PositionsV2 {
    using RealMath for *;

    struct Orbit {
        Cartesian center;
        Polar last;
        int32 rotationSpeed;
        uint256 lastUpdate;
    }

    struct Polar {
        uint32 distance;
        int128 angle;
    }

    struct Cartesian {
        int256 x;
        int256 y;
    }

    /**@dev
     * half circle, to save on divides.
     */
    int128 constant REAL_HALF_CIRCLE = 197912092999680;

    /**@dev
     * circle, to save on divides.
     */
    int128 constant REAL_CIRCLE = 395824185999360;

    function toReal(int88 nb) public pure returns(int128) {
        return nb.toReal();
    }

    function realRadianToDegree(int128 realRadian)
        public
        pure
        returns (int128)
    {
        return realRadian.mul(REAL_HALF_CIRCLE).div(RealMath.REAL_PI);
    }

    function realDegreeToRadian(int128 realDegree)
        public
        pure
        returns (int128)
    {
        return realDegree.mul(RealMath.REAL_PI).div(REAL_HALF_CIRCLE);
    }

    function currentAngleDegreeReal(Orbit memory orbit, uint256 time)
        public
        pure
        returns (int128)
    {
        if (orbit.last.distance == 0) {
            return orbit.last.angle;
        }

        int128 speedReal = orbit.rotationSpeed.toReal();
        int128 distanceReal = orbit.last.distance.toReal();

        int128 radiansAngularSpeedInReal = speedReal.div(distanceReal);

        int128 timeDiffReal = int88(time - orbit.lastUpdate).toReal();

        int128 angleToAddRadianReal =
            radiansAngularSpeedInReal.mul(timeDiffReal);

        int128 angleToAddDegree = realRadianToDegree(angleToAddRadianReal);

        return ((angleToAddDegree + orbit.last.angle) % 360.toReal());
    }

    function cartesianCoordinate(Orbit memory orbit, uint256 time)
        public
        pure
        returns (Cartesian memory)
    {
        int128 currentAngleReal = currentAngleDegreeReal(orbit, time);

        int128 currentAngleRadians = realDegreeToRadian(currentAngleReal);

        int128 angleCos = currentAngleRadians.cos();
        int128 angleSin = currentAngleRadians.sin();

        int128 distanceReal = orbit.last.distance.toReal();

        int256 x =
            distanceReal.mul(angleCos).round().fromReal() + orbit.center.x;
        int256 y =
            distanceReal.mul(angleSin).round().fromReal() + orbit.center.y;

        return Cartesian({x: x, y: y});
    }

    function distance(Cartesian memory a, Cartesian memory b)
        public
        pure
        returns (int88)
    {
        int256 xDiff = b.x - a.x;
        int256 yDiff = b.y - a.y;

        int256 xDiffSquare = xDiff * xDiff;
        int256 yDiffSquare = yDiff * yDiff;

        int256 sum = xDiffSquare + yDiffSquare;
        int128 sumReal = int88(sum).toReal();

        return RealMath.sqrt(sumReal).fromReal();
    }

    function collision(
        Cartesian memory positionA,
        Cartesian memory positionB,
        uint8 area
    ) public pure returns (bool result) {
        return distance(positionA, positionB) <= area;
    }

    function polarMiddle(
        Orbit memory orbit1,
        Orbit memory orbit2,
        uint256 time
    ) public pure returns (Polar memory) {
        int128 r1 = int88(orbit1.last.distance).toReal();
        int128 r2 = int88(orbit2.last.distance).toReal();

        int128 a1 = currentAngleDegreeReal(orbit1, time);
        int128 a2 = currentAngleDegreeReal(orbit2, time);

        (int128 x, int128 y) = realCartesianMiddleFromPolar(r1, a1, r2, a2);

        int128 r =
            RealMath.sqrt(x.pow(RealMath.REAL_TWO) + y.pow(RealMath.REAL_TWO));
        int128 angleRad = RealMath.atan2(y, x);

        int128 angle = realRadianToDegree(angleRad);

        if (angle < 0) {
            angle = REAL_CIRCLE + angle;
        }

        return
            Polar({
                distance: uint32(r.round().fromReal()),
                angle: angle
            });
    }

    function realCartesianMiddleFromPolar(
        int128 r1,
        int128 ad1,
        int128 r2,
        int128 ad2
    ) public pure returns (int128, int128) {
        int128 a1 = realDegreeToRadian(ad1);
        int128 a2 = realDegreeToRadian(ad2);

        int128 x =
            (r1.mul(RealMath.cos(a1)) + r2.mul(RealMath.cos(a2))).div(
                RealMath.REAL_TWO
            );
        int128 y =
            (r1.mul(RealMath.sin(a1)) + r2.mul(RealMath.sin(a2))).div(
                RealMath.REAL_TWO
            );

        return (x, y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

/**
 * RealMath: fixed-point math library, based on fractional and integer parts.
 * Using int128 as real88x40, which isn't in Solidity yet.
 * 40 fractional bits gets us down to 1E-12 precision, while still letting us
 * go up to galaxy scale counting in meters.
 * Internally uses the wider int256 for some math.
 *
 * Note that for addition, subtraction, and mod (%), you should just use the
 * built-in Solidity operators. Functions for these operations are not provided.
 *
 * Note that the fancy functions like sqrt, atan2, etc. aren't as accurate as
 * they should be. They are (hopefully) Good Enough for doing orbital mechanics
 * on block timescales in a game context, but they may not be good enough for
 * other applications.
 */

library RealMath {

    /**@dev
     * How many total bits are there?
     */
    int256 constant REAL_BITS = 128;

    /**@dev
     * How many fractional bits are there?
     */
    int256 constant REAL_FBITS = 40;

    /**@dev
     * How many integer bits are there?
     */
    int256 constant REAL_IBITS = REAL_BITS - REAL_FBITS;

    /**@dev
     * What's the first non-fractional bit
     */
    int128 constant REAL_ONE = int128(1) << int128(REAL_FBITS);

    /**@dev
     * What's the last fractional bit?
     */
    int128 constant REAL_HALF = REAL_ONE >> int128(1);

    /**@dev
     * What's two? Two is pretty useful.
     */
    int128 constant REAL_TWO = REAL_ONE << int128(1);

    /**@dev
     * And our logarithms are based on ln(2).
     */
    int128 constant REAL_LN_TWO = 762123384786;

    /**@dev
     * It is also useful to have Pi around.
     */
    int128 constant REAL_PI = 3454217652358;

    /**@dev
     * And half Pi, to save on divides.
     * TODO: That might not be how the compiler handles constants.
     */
    int128 constant REAL_HALF_PI = 1727108826179;

    /**@dev
     * And two pi, which happens to be odd in its most accurate representation.
     */
    int128 constant REAL_TWO_PI = 6908435304715;

    /**@dev
     * What's the sign bit?
     */
    int128 constant SIGN_MASK = int128(1) << int128(127);


    /**
     * Convert an integer to a real. Preserves sign.
     */
    function toReal(int88 ipart) public pure returns (int128) {
        return int128(ipart) * REAL_ONE;
    }

    /**
     * Convert a real to an integer. Preserves sign.
     */
    function fromReal(int128 real_value) public pure returns (int88) {
        return int88(real_value / REAL_ONE);
    }

    /**
     * Round a real to the nearest integral real value.
     */
    function round(int128 real_value) public pure returns (int128) {
        // First, truncate.
        int88 ipart = fromReal(real_value);
        if ((fractionalBits(real_value) & (uint40(1) << uint40(REAL_FBITS - 1))) > 0) {
            // High fractional bit is set. Round up.
            if (real_value < int128(0)) {
                // Rounding up for a negative number is rounding down.
                ipart -= 1;
            } else {
                ipart += 1;
            }
        }
        return toReal(ipart);
    }

    /**
     * Get the absolute value of a real. Just the same as abs on a normal int128.
     */
    function abs(int128 real_value) public pure returns (int128) {
        if (real_value > 0) {
            return real_value;
        } else {
            return -real_value;
        }
    }

    /**
     * Returns the fractional bits of a real. Ignores the sign of the real.
     */
    function fractionalBits(int128 real_value) public pure returns (uint40) {
        return uint40(abs(real_value) % REAL_ONE);
    }

    /**
     * Get the fractional part of a real, as a real. Ignores sign (so fpart(-0.5) is 0.5).
     */
    function fpart(int128 real_value) public pure returns (int128) {
        // This gets the fractional part but strips the sign
        return abs(real_value) % REAL_ONE;
    }

    /**
     * Get the fractional part of a real, as a real. Respects sign (so fpartSigned(-0.5) is -0.5).
     */
    function fpartSigned(int128 real_value) public pure returns (int128) {
        // This gets the fractional part but strips the sign
        int128 fractional = fpart(real_value);
        if (real_value < 0) {
            // Add the negative sign back in.
            return -fractional;
        } else {
            return fractional;
        }
    }

    /**
     * Get the integer part of a fixed point value.
     */
    function ipart(int128 real_value) public pure returns (int128) {
        // Subtract out the fractional part to get the real part.
        return real_value - fpartSigned(real_value);
    }

    /**
     * Multiply one real by another. Truncates overflows.
     */
    function mul(int128 real_a, int128 real_b) public pure returns (int128) {
        // When multiplying fixed point in x.y and z.w formats we get (x+z).(y+w) format.
        // So we just have to clip off the extra REAL_FBITS fractional bits.
        return int128((int256(real_a) * int256(real_b)) >> REAL_FBITS);
    }

    /**
     * Divide one real by another real. Truncates overflows.
     */
    function div(int128 real_numerator, int128 real_denominator) public pure returns (int128) {
        // We use the reverse of the multiplication trick: convert numerator from
        // x.y to (x+z).(y+w) fixed point, then divide by denom in z.w fixed point.
        return int128((int256(real_numerator) * REAL_ONE) / int256(real_denominator));
    }

    /**
     * Create a real from a rational fraction.
     */
    function fraction(int88 numerator, int88 denominator) public pure returns (int128) {
        return div(toReal(numerator), toReal(denominator));
    }

    // Now we have some fancy math things (like pow and trig stuff). This isn't
    // in the RealMath that was deployed with the original Macroverse
    // deployment, so it needs to be linked into your contract statically.

    /**
     * Raise a number to a positive integer power in O(log power) time.
     * See <https://stackoverflow.com/a/101613>
     */
    function ipow(int128 real_base, int88 exponent) public pure returns (int128) {
        if (exponent < 0) {
            // Negative powers are not allowed here.
            revert();
        }

        // Start with the 0th power
        int128 real_result = REAL_ONE;
        while (exponent != 0) {
            // While there are still bits set
            if ((exponent & 0x1) == 0x1) {
                // If the low bit is set, multiply in the (many-times-squared) base
                real_result = mul(real_result, real_base);
            }
            // Shift off the low bit
            exponent = exponent >> 1;
            // Do the squaring
            real_base = mul(real_base, real_base);
        }

        // Return the final result.
        return real_result;
    }

    /**
     * Zero all but the highest set bit of a number.
     * See <https://stackoverflow.com/a/53184>
     */
    function hibit(uint256 val) internal pure returns (uint256) {
        // Set all the bits below the highest set bit
        val |= (val >>  1);
        val |= (val >>  2);
        val |= (val >>  4);
        val |= (val >>  8);
        val |= (val >> 16);
        val |= (val >> 32);
        val |= (val >> 64);
        val |= (val >> 128);
        return val ^ (val >> 1);
    }

    /**
     * Given a number with one bit set, finds the index of that bit.
     */
    function findbit(uint256 val) internal pure returns (uint8 index) {
        index = 0;
        // We and the value with alternating bit patters of various pitches to find it.

        if (val & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA != 0) {
            // Picth 1
            index |= 1;
        }
        if (val & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC != 0) {
            // Pitch 2
            index |= 2;
        }
        if (val & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0 != 0) {
            // Pitch 4
            index |= 4;
        }
        if (val & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00 != 0) {
            // Pitch 8
            index |= 8;
        }
        if (val & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000 != 0) {
            // Pitch 16
            index |= 16;
        }
        if (val & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000 != 0) {
            // Pitch 32
            index |= 32;
        }
        if (val & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000 != 0) {
            // Pitch 64
            index |= 64;
        }
        if (val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 != 0) {
            // Pitch 128
            index |= 128;
        }
    }

    /**
     * Shift real_arg left or right until it is between 1 and 2. Return the
     * rescaled value, and the number of bits of right shift applied. Shift may be negative.
     *
     * Expresses real_arg as real_scaled * 2^shift, setting shift to put real_arg between [1 and 2).
     *
     * Rejects 0 or negative arguments.
     */
    function rescale(int128 real_arg) internal pure returns (int128 real_scaled, int88 shift) {
        if (real_arg <= 0) {
            // Not in domain!
            revert();
        }

        // Find the high bit
        int88 high_bit = findbit(hibit(uint256(real_arg)));

        // We'll shift so the high bit is the lowest non-fractional bit.
        shift = high_bit - int88(REAL_FBITS);

        if (shift < 0) {
            // Shift left
            real_scaled = real_arg << int128(-shift);
        } else if (shift >= 0) {
            // Shift right
            real_scaled = real_arg >> int128(shift);
        }
    }

    /**
     * Calculate the natural log of a number. Rescales the input value and uses
     * the algorithm outlined at <https://math.stackexchange.com/a/977836> and
     * the ipow implementation.
     *
     * Lets you artificially limit the number of iterations.
     *
     * Note that it is potentially possible to get an un-converged value; lack
     * of convergence does not throw.
     */
    function lnLimited(int128 real_arg, int max_iterations) public pure returns (int128) {
        if (real_arg <= 0) {
            // Outside of acceptable domain
            revert();
        }

        if (real_arg == REAL_ONE) {
            // Handle this case specially because people will want exactly 0 and
            // not ~2^-39 ish.
            return 0;
        }

        // We know it's positive, so rescale it to be between [1 and 2)
        int128 real_rescaled;
        int88 shift;
        (real_rescaled, shift) = rescale(real_arg);

        // Compute the argument to iterate on
        int128 real_series_arg = div(real_rescaled - REAL_ONE, real_rescaled + REAL_ONE);

        // We will accumulate the result here
        int128 real_series_result = 0;

        for (int88 n = 0; n < max_iterations; n++) {
            // Compute term n of the series
            int128 real_term = div(ipow(real_series_arg, 2 * n + 1), toReal(2 * n + 1));
            // And add it in
            real_series_result += real_term;
            if (real_term == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }
            // If we somehow never converge I guess we will run out of gas
        }

        // Double it to account for the factor of 2 outside the sum
        real_series_result = mul(real_series_result, REAL_TWO);

        // Now compute and return the overall result
        return mul(toReal(shift), REAL_LN_TWO) + real_series_result;

    }

    /**
     * Calculate a natural logarithm with a sensible maximum iteration count to
     * wait until convergence. Note that it is potentially possible to get an
     * un-converged value; lack of convergence does not throw.
     */
    function ln(int128 real_arg) public pure returns (int128) {
        return lnLimited(real_arg, 100);
    }

    /**
     * Calculate e^x. Uses the series given at
     * <http://pages.mtu.edu/~shene/COURSES/cs201/NOTES/chap04/exp.html>.
     *
     * Lets you artificially limit the number of iterations.
     *
     * Note that it is potentially possible to get an un-converged value; lack
     * of convergence does not throw.
     */
    function expLimited(int128 real_arg, int max_iterations) public pure returns (int128) {
        // We will accumulate the result here
        int128 real_result = 0;

        // We use this to save work computing terms
        int128 real_term = REAL_ONE;

        for (int88 n = 0; n < max_iterations; n++) {
            // Add in the term
            real_result += real_term;

            // Compute the next term
            real_term = mul(real_term, div(real_arg, toReal(n + 1)));

            if (real_term == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }
            // If we somehow never converge I guess we will run out of gas
        }

        // Return the result
        return real_result;

    }

    /**
     * Calculate e^x with a sensible maximum iteration count to wait until
     * convergence. Note that it is potentially possible to get an un-converged
     * value; lack of convergence does not throw.
     */
    function exp(int128 real_arg) public pure returns (int128) {
        return expLimited(real_arg, 100);
    }

    /**
     * Raise any number to any power, except for negative bases to fractional powers.
     */
    function pow(int128 real_base, int128 real_exponent) public pure returns (int128) {
        if (real_exponent == 0) {
            // Anything to the 0 is 1
            return REAL_ONE;
        }

        if (real_base == 0) {
            if (real_exponent < 0) {
                // Outside of domain!
                revert();
            }
            // Otherwise it's 0
            return 0;
        }

        if (fpart(real_exponent) == 0) {
            // Anything (even a negative base) is super easy to do to an integer power.

            if (real_exponent > 0) {
                // Positive integer power is easy
                return ipow(real_base, fromReal(real_exponent));
            } else {
                // Negative integer power is harder
                return div(REAL_ONE, ipow(real_base, fromReal(-real_exponent)));
            }
        }

        if (real_base < 0) {
            // It's a negative base to a non-integer power.
            // In general pow(-x^y) is undefined, unless y is an int or some
            // weird rational-number-based relationship holds.
            revert();
        }

        // If it's not a special case, actually do it.
        return exp(mul(real_exponent, ln(real_base)));
    }

    /**
     * Compute the square root of a number.
     */
    function sqrt(int128 real_arg) public pure returns (int128) {
        return pow(real_arg, REAL_HALF);
    }

    /**
     * Compute the sin of a number to a certain number of Taylor series terms.
     */
    function sinLimited(int128 real_arg, int88 max_iterations) public pure returns (int128) {
        // First bring the number into 0 to 2 pi
        // TODO: This will introduce an error for very large numbers, because the error in our Pi will compound.
        // But for actual reasonable angle values we should be fine.
        real_arg = real_arg % REAL_TWO_PI;

        int128 accumulator = REAL_ONE;

        // We sum from large to small iteration so that we can have higher powers in later terms
        for (int88 iteration = max_iterations - 1; iteration >= 0; iteration--) {
            accumulator = REAL_ONE - mul(div(mul(real_arg, real_arg), toReal((2 * iteration + 2) * (2 * iteration + 3))), accumulator);
            // We can't stop early; we need to make it to the first term.
        }

        return mul(real_arg, accumulator);
    }

    /**
     * Calculate sin(x) with a sensible maximum iteration count to wait until
     * convergence.
     */
    function sin(int128 real_arg) public pure returns (int128) {
        return sinLimited(real_arg, 15);
    }

    /**
     * Calculate cos(x).
     */
    function cos(int128 real_arg) public pure returns (int128) {
        return sin(real_arg + REAL_HALF_PI);
    }

    /**
     * Calculate tan(x). May overflow for large results. May throw if tan(x)
     * would be infinite, or return an approximation, or overflow.
     */
    function tan(int128 real_arg) public pure returns (int128) {
        return div(sin(real_arg), cos(real_arg));
    }

    /**
     * Calculate atan(x) for x in [-1, 1].
     * Uses the Chebyshev polynomial approach presented at
     * https://www.mathworks.com/help/fixedpoint/examples/calculate-fixed-point-arctangent.html
     * Uses polynomials received by personal communication.
     * 0.999974x-0.332568x^3+0.193235x^5-0.115729x^7+0.0519505x^9-0.0114658x^11
     */
    function atanSmall(int128 real_arg) public pure returns (int128) {
        int128 real_arg_squared = mul(real_arg, real_arg);
        return mul(mul(mul(mul(mul(mul(
            - 12606780422,  real_arg_squared) // x^11
            + 57120178819,  real_arg_squared) // x^9
            - 127245381171, real_arg_squared) // x^7
            + 212464129393, real_arg_squared) // x^5
            - 365662383026, real_arg_squared) // x^3
            + 1099483040474, real_arg);       // x^1
    }

    /**
     * Compute the nice two-component arctangent of y/x.
     */
    function atan2(int128 real_y, int128 real_x) public pure returns (int128) {
        int128 atan_result;

        // Do the angle correction shown at
        // https://www.mathworks.com/help/fixedpoint/examples/calculate-fixed-point-arctangent.html

        // We will re-use these absolute values
        int128 real_abs_x = abs(real_x);
        int128 real_abs_y = abs(real_y);

        if (real_abs_x > real_abs_y) {
            // We are in the (0, pi/4] region
            // abs(y)/abs(x) will be in 0 to 1.
            atan_result = atanSmall(div(real_abs_y, real_abs_x));
        } else {
            // We are in the (pi/4, pi/2) region
            // abs(x) / abs(y) will be in 0 to 1; we swap the arguments
            atan_result = REAL_HALF_PI - atanSmall(div(real_abs_x, real_abs_y));
        }

        // Now we correct the result for other regions
        if (real_x < 0) {
            if (real_y < 0) {
                atan_result -= REAL_PI;
            } else {
                atan_result = REAL_PI - atan_result;
            }
        } else {
            if (real_y < 0) {
                atan_result = -atan_result;
            }
        }

        return atan_result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceShipsRules is Ownable {
    uint32 constant ID_TO_MODEL = 1000000;

    uint256 private _baseMiningArea = 15;
    uint256 private _baseMachinery = 300;

    int32 public defaultRotationSpeed = 3;

    mapping(uint256 => uint256) private _booster;
    mapping(uint256 => uint256) private _radar;
    mapping(uint256 => uint256) private _drill;
    mapping(uint256 => uint256) private _machinery;

    constructor() public {}

    function makeRule(
        uint256 model,
        uint256 booster,
        uint256 radar,
        uint256 drill,
        uint256 machinery
    ) external onlyOwner {
        _booster[model] = booster;
        _radar[model] = radar;
        _drill[model] = drill;
        _machinery[model] = machinery;
    }

    function updateDefaultRotationSpeed(int32 speed) external onlyOwner {
        defaultRotationSpeed = speed;
    }

    function updateMachinery(uint256 newBaseMachinery) external onlyOwner {
        _baseMachinery = newBaseMachinery;
    }

    function updateMiningArea(uint8 newBaseMiningArea) external onlyOwner {
        _baseMiningArea = newBaseMiningArea;
    }

    function boosterOf(uint256 id) public view returns (uint256) {
        return _booster[_idToModel(id)];
    }

    function radarOf(uint256 id) public view returns (uint8) {
        if(_radar[_idToModel(id)] == 0) {
            return uint8(_baseMiningArea);
        }
        return uint8(_baseMiningArea * _radar[_idToModel(id)] / 100);
    }

    function drillOf(uint256 id, uint256 initialAmount)
        public
        view
        returns (uint256)
    {
        if(_drill[_idToModel(id)] == 0) {
            return initialAmount;
        }
        return initialAmount * _drill[_idToModel(id)] / 100;
    }

    function machineryOf(uint256 id) public view returns (uint256) {
        if(_machinery[_idToModel(id)] == 0) {
            return _baseMachinery;
        }
        return _baseMachinery * _machinery[_idToModel(id)] / 100;
    }

    function _idToModel(uint256 id) internal pure returns (uint256) {
        return id / ID_TO_MODEL;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IComet {
    function claim(address to, uint amount) external;
    function unit() external view returns (uint256);
    function token() external view returns (address);
    function balance() external view returns (uint256);
    function cometType() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../Modulable.sol";
import "../PositionsV2.sol";

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface ISolarSystemStore {
    function add(
        uint256 solarSystemId,
        PositionsV2.Cartesian memory center,
        string memory name,
        address minerStore,
        address cometStore
    ) external;

    function remove(uint256 solarSystemId) external;

    function updateCenter(
        uint256 solarSystemId,
        PositionsV2.Cartesian memory newCenter
    ) external;

    function updateName(uint256 solarSystemId, string memory newName) external;

    function updateMinerStore(uint256 solarSystemId, address minerStore)
        external;

    function updateCometStore(uint256 solarSystemId, address cometStore)
        external;

    function length() external view returns (uint256);

    function idAt(uint256 index) external view returns (uint256);

    function ids() external view returns (uint256[] memory);

    function contains(uint256 solarSystemId) external view returns (bool);

    function centerFor(uint256 solarSystemId)
        external
        view
        returns (PositionsV2.Cartesian memory);

    function nameFor(uint256 solarSystemId)
        external
        view
        returns (string memory);

    function minerStoreFor(uint256 solarSystemId)
        external
        view
        returns (address);

    function cometStoreFor(uint256 solarSystemId)
        external
        view
        returns (address);
}

contract SolarSystemStore is ISolarSystemStore, Modulable {
    using PositionsV2 for *;
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet internal _solarSystemIds;
    mapping(uint256 => PositionsV2.Cartesian) internal centers;
    mapping(uint256 => address) internal minerStores;
    mapping(uint256 => address) internal cometStores;
    mapping(uint256 => string) internal names;

    constructor() public {}

    function add(
        uint256 solarSystemId,
        PositionsV2.Cartesian memory center,
        string memory name,
        address minerStore,
        address cometStore
    ) external override onlyModule {
        require(_solarSystemIds.add(solarSystemId), "Store: already exist");
        centers[solarSystemId] = center;
        names[solarSystemId] = name;
        minerStores[solarSystemId] = minerStore;
        cometStores[solarSystemId] = cometStore;
    }

    function remove(uint256 solarSystemId) external override onlyModule {
        require(_solarSystemIds.remove(solarSystemId), "Store: unknown");
    }

    function updateCenter(
        uint256 solarSystemId,
        PositionsV2.Cartesian memory newCenter
    ) external override onlyModule {
        centers[solarSystemId] = newCenter;
    }

    function updateName(uint256 solarSystemId, string memory name)
        external
        override
        onlyModule
    {
        names[solarSystemId] = name;
    }

    function updateMinerStore(uint256 solarSystemId, address minerStore)
        external
        override
        onlyModule
    {
        minerStores[solarSystemId] = minerStore;
    }

    function updateCometStore(uint256 solarSystemId, address cometStore)
        external
        override
        onlyModule
    {
        cometStores[solarSystemId] = cometStore;
    }

    function length() external view override returns (uint256) {
        return _solarSystemIds.length();
    }

    function idAt(uint256 index) external view override returns (uint256) {
        return _solarSystemIds.at(index);
    }

    function ids() external view override returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_solarSystemIds.length());
        for (uint256 i = 0; i < _solarSystemIds.length(); i++) {
            result[i] = _solarSystemIds.at(i);
        }
        return result;
    }

    function contains(uint256 solarSystemId)
        external
        view
        override
        returns (bool)
    {
        return _solarSystemIds.contains(solarSystemId);
    }

    function nameFor(uint256 solarSystemId)
        external
        view
        override
        returns (string memory)
    {
        return names[solarSystemId];
    }

    function centerFor(uint256 solarSystemId)
        external
        view
        override
        returns (PositionsV2.Cartesian memory)
    {
        return centers[solarSystemId];
    }

    function minerStoreFor(uint256 solarSystemId)
        external
        view
        override
        returns (address)
    {
        return minerStores[solarSystemId];
    }

    function cometStoreFor(uint256 solarSystemId)
        external
        view
        override
        returns (address)
    {
        return cometStores[solarSystemId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
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
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
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
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        address owner = ownerOf(tokenId);

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
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ownerOf(tokenId), to, tokenId);
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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

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
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
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
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
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
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

pragma solidity ^0.6.0;

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
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}