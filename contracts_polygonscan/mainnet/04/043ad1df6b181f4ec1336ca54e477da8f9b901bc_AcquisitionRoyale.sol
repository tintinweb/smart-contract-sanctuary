// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./ERC721EnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";
import "./IAcquisitionRoyale.sol";

contract AcquisitionRoyale is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    IAcquisitionRoyale,
    ERC721EnumerableUpgradeable
{
    using SafeERC20 for IERC20;

    struct ImmunityPeriods {
        uint256 acquisition;
        uint256 merger;
        uint256 revival;
    }

    struct FoundingParameters {
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 endTime;
    }

    struct PassiveRpParameters {
        uint256 max;
        uint256 base;
        uint256 acquisitions;
        uint256 mergers;
    }

    uint256 private _gameStartTime;
    uint256 private _mergerBurnPercentage;
    uint256 private _withdrawalBurnPercentage;
    ImmunityPeriods private _immunityPeriods;
    FoundingParameters private _foundingParameters;
    PassiveRpParameters private _passiveRpPerDay;
    IMerkleProofVerifier private _verifier;
    IERC20 private _weth;
    IRunwayPoints private _runwayPoints;
    ICompete private _compete;
    ICost private _acquireCost;
    ICost private _mergeCost;
    ICost private _fundraiseCost;
    IERC1155Burnable private _consumables;
    IBranding private _fallbackBranding;
    mapping(address => bool) private _hasFoundedFree;
    mapping(string => bool) private _nameInUse;
    mapping(IBranding => bool) private _supportForBranding;

    mapping(uint256 => Enterprise) internal _enterprises;
    uint256 internal _reservedCount;
    uint256 internal _freeCount;
    uint256 internal _auctionCount;

    // auctioned = 0-8999
    uint256 private constant MAX_AUCTIONED = 9000;
    // free = 9000-13999
    uint256 private constant MAX_FREE = 5000;
    // reserved = 14000-14999
    uint256 private constant MAX_RESERVED = 1000;
    // percentages represented as 8 decimal place values.
    uint256 private constant PERCENT_DENOMINATOR = 10000000000;

    function initialize(
        string memory _newName,
        string memory _newSymbol,
        address _newVerifier,
        address _newWeth,
        address _newRunwayPoints,
        address _newConsumables
    ) public initializer {
        __ERC721_init(_newName, _newSymbol);
        __Ownable_init();
        // default rp passive accumulation rates
        _passiveRpPerDay.max = 2e19; // 20 max rp/day
        _passiveRpPerDay.base = 1e18; // 1 base rp/day
        _passiveRpPerDay.acquisitions = 2e18; // 2 rp/day per acquisition
        _passiveRpPerDay.mergers = 1e18; // 1 rp/day per merger
        _withdrawalBurnPercentage = 2500000000; // 25%
        _verifier = IMerkleProofVerifier(_newVerifier);
        _weth = IERC20(_newWeth);
        _runwayPoints = IRunwayPoints(_newRunwayPoints);
        _consumables = IERC1155Burnable(_newConsumables);
    }

    function foundReserved(address _recipient)
        external
        override
        onlyOwner
        nonReentrant
    {
        _supplyCheck(_reservedCount, MAX_RESERVED);
        uint256 _id = MAX_AUCTIONED + MAX_FREE + _reservedCount;
        _reservedCount++;
        _safeMint(_recipient, _id);
        _enterprises[_id].name = string(
            abi.encodePacked("Enterprise #", _toString(_id))
        );
        _enterprises[_id].revivalImmunityStartTime = block.timestamp;
        _enterprises[_id].branding = _fallbackBranding;
    }

    function foundFree(bytes32[] memory _proof)
        external
        override
        nonReentrant
    {
        _publicFoundingCheck();
        _supplyCheck(_freeCount, MAX_FREE);
        if (
            !(block.timestamp >= _foundingParameters.endTime &&
                msg.sender == owner())
        ) {
            require(_proof.length > 0, "proof is empty");
            require(
                block.timestamp <= _foundingParameters.endTime,
                "founding has ended"
            );
            require(!_hasFoundedFree[msg.sender], "already founded free");
            require(
                _verifier.verify(msg.sender, _proof),
                "ineligible address"
            );
        }
        uint256 _id = MAX_AUCTIONED + _freeCount;
        _freeCount++;
        _safeMint(msg.sender, _id);
        _enterprises[_id].name = string(
            abi.encodePacked("Enterprise #", _toString(_id))
        );
        _enterprises[_id].revivalImmunityStartTime = block.timestamp;
        _enterprises[_id].branding = _fallbackBranding;
        _hasFoundedFree[msg.sender] = true;
    }

    // this function assumes wETH approval has been made
    function foundAuctioned(uint256 _quantity, bytes32[] memory _proof)
        external
        override
        nonReentrant
    {
        _publicFoundingCheck();
        require(_quantity > 0, "amount cannot be zero");
        _supplyCheck((_auctionCount + _quantity), MAX_AUCTIONED);
        if (msg.sender != owner()) {
            require(
                block.timestamp <= _foundingParameters.endTime,
                "founding has ended"
            );
            uint256 _auctionPrice = getAuctionPrice();
            // apply 25% discount for eligible addresses
            if (_proof.length > 0 && _verifier.verify(msg.sender, _proof)) {
                _auctionPrice = (_auctionPrice * 3) / 4;
            }
            _weth.safeTransferFrom(
                msg.sender,
                owner(),
                _auctionPrice * _quantity
            );
        }
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 _id = _auctionCount;
            _auctionCount++;
            _safeMint(msg.sender, _id);
            _enterprises[_id].name = string(
                abi.encodePacked("Enterprise #", _toString(_id))
            );
            _enterprises[_id].revivalImmunityStartTime = block.timestamp;
            _enterprises[_id].branding = _fallbackBranding;
        }
    }

    function compete(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _rpToSpend
    ) external override {
        _gameStartCheck();
        _hostileActionCheck(msg.sender, _callerId, _targetId);
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_callerId);
        _updateEnterpriseRp(_targetId);
        require(
            _enterprises[_callerId].rp >= _rpToSpend,
            "insufficient RP for spending"
        );
        uint256 _damage = _compete.getDamage(_callerId, _targetId, _rpToSpend);
        _competeUnchecked(_callerId, _targetId, _damage, _rpToSpend);
    }

    function competeAndAcquire(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _burnedId
    ) external override {
        _gameStartCheck();
        _hostileActionCheck(msg.sender, _callerId, _targetId);
        require(
            _burnedId == _callerId || _burnedId == _targetId,
            "invalid burn target"
        );
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_callerId);
        _updateEnterpriseRp(_targetId);
        uint256 _damage = _enterprises[_targetId].rp;
        uint256 _rpToSpend =
            _compete.getRpRequiredForDamage(_callerId, _targetId, _damage);
        require(
            _enterprises[_callerId].rp >= _rpToSpend,
            "insufficient RP for spending"
        );
        _competeUnchecked(_callerId, _targetId, _damage, _rpToSpend);
        _acquireUnchecked(_callerId, _targetId, _burnedId);
    }

    function merge(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _burnedId
    ) external override nonReentrant {
        _gameStartCheck();
        _selfActionCheck(msg.sender, _callerId, _targetId);
        require(
            _burnedId == _callerId || _burnedId == _targetId,
            "invalid burn target"
        );
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_callerId);
        _updateEnterpriseRp(_targetId);

        (, uint256 _amountToTreasury, ) =
            _mergeCost.updateAndGetCost(_callerId, _targetId, 1);
        _weth.safeTransferFrom(msg.sender, owner(), _amountToTreasury);

        _burn(_burnedId);
        uint256 _idToKeep = (_burnedId == _callerId) ? _targetId : _callerId;
        // round up to prevent amounts too small for precision costing zero
        uint256 _rpToBurn =
            ((_enterprises[_burnedId].rp * _mergerBurnPercentage) /
                PERCENT_DENOMINATOR) + 1;
        if (_rpToBurn > _enterprises[_burnedId].rp) {
            _enterprises[_burnedId].rp = 0;
        } else {
            _enterprises[_idToKeep].rp +=
                _enterprises[_burnedId].rp -
                _rpToBurn;
            _enterprises[_burnedId].rp = 0;
        }

        _enterprises[_idToKeep].mergers++;
        _enterprises[_idToKeep].mergerImmunityStartTime = block.timestamp;
        emit Merger(_callerId, _targetId, _burnedId);
    }

    function fundraise(uint256 _enterpriseId, uint256 _amount)
        external
        override
        nonReentrant
    {
        _gameStartCheck();
        _enterpriseOwnerCheck(msg.sender, _enterpriseId);
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_enterpriseId);
        (, uint256 _amountToTreasury, ) =
            _fundraiseCost.updateAndGetCost(
                _enterpriseId,
                _enterpriseId,
                _amount
            );
        uint256 _sentToTreasury = (_amount * _amountToTreasury) / 1e18;
        _weth.safeTransferFrom(msg.sender, owner(), _sentToTreasury);
        _runwayPoints.mint(address(this), _amount);
        _enterprises[_enterpriseId].rp += _amount;
        _enterprises[_enterpriseId].fundraiseRpTotal += _amount;
        _enterprises[_enterpriseId].fundraiseWethTotal += _sentToTreasury;
        emit Fundraise(_enterpriseId, _amount);
    }

    function deposit(uint256 _enterpriseId, uint256 _amount)
        external
        override
        nonReentrant
    {
        _gameStartCheck();
        _enterpriseOwnerCheck(msg.sender, _enterpriseId);
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_enterpriseId);
        _runwayPoints.transferFrom(msg.sender, address(this), _amount);
        _enterprises[_enterpriseId].rp += _amount;
        emit Deposit(_enterpriseId, _amount);
    }

    function withdraw(uint256 _enterpriseId, uint256 _amount)
        external
        override
        nonReentrant
    {
        _gameStartCheck();
        _enterpriseOwnerCheck(msg.sender, _enterpriseId);
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_enterpriseId);
        require(
            _enterprises[_enterpriseId].rp >= _amount,
            "insufficient RP for withdrawal"
        );
        _reduceEnterpriseRp(_enterpriseId, _amount);
        uint256 _rpToBurn =
            (_amount * _withdrawalBurnPercentage) / PERCENT_DENOMINATOR;
        _amount -= _rpToBurn;
        uint256 _latentRP = _runwayPoints.balanceOf(address(this));
        if (_amount > _latentRP) {
            _runwayPoints.mint(address(this), _amount - _latentRP);
        }
        _runwayPoints.transfer(msg.sender, _amount);
        emit Withdrawal(_enterpriseId, _amount, _rpToBurn);
    }

    function rename(uint256 _enterpriseId, string memory _name)
        external
        override
        nonReentrant
    {
        if (msg.sender != owner()) {
            _enterpriseOwnerCheck(msg.sender, _enterpriseId);
            _consumableTokenCheck(msg.sender, 0);
            require(!_nameInUse[_name], "name in use");
            require(_verifyName(_name), "invalid name");
            _consumables.burn(msg.sender, 0, 1);
            _nameInUse[_name] = true;
        }
        _enterprises[_enterpriseId].name = _name;
        _enterprises[_enterpriseId].renames++;
        emit Rename(_enterpriseId, _name);
    }

    function rebrand(uint256 _enterpriseId, IBranding _branding)
        external
        override
        nonReentrant
    {
        _enterpriseOwnerCheck(msg.sender, _enterpriseId);
        require(_supportForBranding[_branding], "branding not supported");
        if (msg.sender != owner()) {
            _consumableTokenCheck(msg.sender, 1);
            _consumables.burn(msg.sender, 1, 1);
        }
        _enterprises[_enterpriseId].branding = _branding;
        _enterprises[_enterpriseId].rebrands++;
        emit Rebrand(_enterpriseId, address(_branding));
    }

    function revive(uint256 _enterpriseId) external override nonReentrant {
        _gameStartCheck();
        require(!_exists(_enterpriseId), "enterprise already exists");
        require(
            _isEnterpriseMinted(_enterpriseId),
            "enterprise has not been minted"
        );
        if (msg.sender != owner()) {
            _consumableTokenCheck(msg.sender, 2);
            _consumables.burn(msg.sender, 2, 1);
        }
        _safeMint(msg.sender, _enterpriseId);
        _enterprises[_enterpriseId].revivalImmunityStartTime = block.timestamp;
        _enterprises[_enterpriseId].lastRpUpdateTime = block.timestamp;
        _enterprises[_enterpriseId].revives++;
        emit Revival(_enterpriseId);
    }

    function setVerifier(address _newVerifier) external onlyOwner {
        _verifier = IMerkleProofVerifier(_newVerifier);
    }

    function setGameStartTime(uint256 _startTime) external override onlyOwner {
        if (_gameStartTime > 0) {
            require(_gameStartTime > block.timestamp, "game already started");
        }
        _gameStartTime = _startTime;
        emit GameStartTimeChanged(_gameStartTime);
    }

    function setFoundingPriceAndTime(
        uint256 _newFoundingStartPrice,
        uint256 _newFoundingEndPrice,
        uint256 _newFoundingStartTime,
        uint256 _newFoundingEndTime
    ) external override onlyOwner {
        require(
            _newFoundingStartPrice > _newFoundingEndPrice,
            "start price must be > end price"
        );
        require(
            _newFoundingEndTime > _newFoundingStartTime,
            "end time must be > start time"
        );
        _foundingParameters.startPrice = _newFoundingStartPrice;
        _foundingParameters.endPrice = _newFoundingEndPrice;
        _foundingParameters.startTime = _newFoundingStartTime;
        _foundingParameters.endTime = _newFoundingEndTime;
        emit FoundingPriceAndTimeChanged(
            _foundingParameters.startPrice,
            _foundingParameters.endPrice,
            _foundingParameters.startTime,
            _foundingParameters.endTime
        );
    }

    function setPassiveRpPerDay(
        uint256 _newMax,
        uint256 _newBase,
        uint256 _newAcquisitions,
        uint256 _newMergers
    ) external override onlyOwner {
        _passiveRpPerDay.max = _newMax;
        _passiveRpPerDay.base = _newBase;
        _passiveRpPerDay.acquisitions = _newAcquisitions;
        _passiveRpPerDay.mergers = _newMergers;
        emit PassiveRpPerDayChanged(
            _passiveRpPerDay.max,
            _passiveRpPerDay.base,
            _passiveRpPerDay.acquisitions,
            _passiveRpPerDay.mergers
        );
    }

    function setImmunityPeriods(
        uint256 _acquisitionImmunityPeriod,
        uint256 _mergerImmunityPeriod,
        uint256 _revivalImmunityPeriod
    ) external override onlyOwner {
        _immunityPeriods.acquisition = _acquisitionImmunityPeriod;
        _immunityPeriods.merger = _mergerImmunityPeriod;
        _immunityPeriods.revival = _revivalImmunityPeriod;
        emit ImmunityPeriodsChanged(
            _immunityPeriods.acquisition,
            _immunityPeriods.merger,
            _immunityPeriods.revival
        );
    }

    function setMergerBurnPercentage(uint256 _percentage)
        external
        override
        onlyOwner
    {
        require(_percentage <= PERCENT_DENOMINATOR, "cannot exceed 100%");
        _mergerBurnPercentage = _percentage;
        emit MergerBurnPercentageChanged(_mergerBurnPercentage);
    }

    function setWithdrawalBurnPercentage(uint256 _percentage)
        external
        override
        onlyOwner
    {
        require(_percentage <= PERCENT_DENOMINATOR, "cannot exceed 100%");
        _withdrawalBurnPercentage = _percentage;
        emit WithdrawalBurnPercentageChanged(_withdrawalBurnPercentage);
    }

    function setCompete(address _newCompete) external override onlyOwner {
        _zeroAddressCheck(_newCompete);
        _compete = ICompete(_newCompete);
        emit CompeteChanged(_newCompete);
    }

    function setAcquireCost(address _newAcquireCost)
        external
        override
        onlyOwner
    {
        _zeroAddressCheck(_newAcquireCost);
        _acquireCost = ICost(_newAcquireCost);
        emit AcquireCostChanged(_newAcquireCost);
    }

    function setMergeCost(address _newMergeCost) external override onlyOwner {
        _zeroAddressCheck(_newMergeCost);
        _mergeCost = ICost(_newMergeCost);
        emit MergeCostChanged(_newMergeCost);
    }

    function setFundraiseCost(address _newFundraiseCost)
        external
        override
        onlyOwner
    {
        _zeroAddressCheck(_newFundraiseCost);
        _fundraiseCost = ICost(_newFundraiseCost);
        emit FundraiseCostChanged(_newFundraiseCost);
    }

    function setSupportForBranding(address _branding, bool _support)
        external
        override
        onlyOwner
    {
        _zeroAddressCheck(_branding);
        _supportForBranding[IBranding(_branding)] = _support;
        emit SupportForBrandingChanged(_branding, _support);
    }

    function setFallbackBranding(address _newFallbackBranding)
        external
        override
        onlyOwner
    {
        _weth.transfer(owner(), _weth.balanceOf(address(this)));
        _zeroAddressCheck(_newFallbackBranding);
        _fallbackBranding = IBranding(_newFallbackBranding);
        emit FallbackBrandingChanged(_newFallbackBranding);
    }

    function getVerifier()
        external
        view
        override
        returns (IMerkleProofVerifier)
    {
        return _verifier;
    }

    function getWETH() external view override returns (IERC20) {
        return _weth;
    }

    function getRunwayPoints() external view override returns (IRunwayPoints) {
        return _runwayPoints;
    }

    function getCompete() external view override returns (ICompete) {
        return _compete;
    }

    function getAcquireCost() external view override returns (ICost) {
        return _acquireCost;
    }

    function getMergeCost() external view override returns (ICost) {
        return _mergeCost;
    }

    function getFundraiseCost() external view override returns (ICost) {
        return _fundraiseCost;
    }

    function isNameInUse(string memory _name)
        external
        view
        override
        returns (bool)
    {
        return _nameInUse[_name];
    }

    function isBrandingSupported(IBranding _branding)
        external
        view
        override
        returns (bool)
    {
        return _supportForBranding[_branding];
    }

    function getConsumables()
        external
        view
        override
        returns (IERC1155Burnable)
    {
        return _consumables;
    }

    function getArtist(uint256 _enterpriseId)
        external
        view
        override
        returns (string memory)
    {
        return
            _revertToFallback(_enterpriseId)
                ? _fallbackBranding.getArtist()
                : _enterprises[_enterpriseId].branding.getArtist();
    }

    function getFallbackBranding() external view override returns (IBranding) {
        return _fallbackBranding;
    }

    function getReservedCount() external view override returns (uint256) {
        return _reservedCount;
    }

    function getFreeCount() external view override returns (uint256) {
        return _freeCount;
    }

    function getAuctionCount() external view override returns (uint256) {
        return _auctionCount;
    }

    function getGameStartTime() external view override returns (uint256) {
        return _gameStartTime;
    }

    function getFoundingPriceAndTime()
        external
        view
        override
        returns (
            uint256 _startPrice,
            uint256 _endPrice,
            uint256 _startTime,
            uint256 _endTime
        )
    {
        return (
            _foundingParameters.startPrice,
            _foundingParameters.endPrice,
            _foundingParameters.startTime,
            _foundingParameters.endTime
        );
    }

    function getPassiveRpPerDay()
        external
        view
        override
        returns (
            uint256 _max,
            uint256 _base,
            uint256 _acquisitions,
            uint256 _mergers
        )
    {
        return (
            _passiveRpPerDay.max,
            _passiveRpPerDay.base,
            _passiveRpPerDay.acquisitions,
            _passiveRpPerDay.mergers
        );
    }

    function getAcquisitionImmunityPeriod()
        external
        view
        override
        returns (uint256)
    {
        return _immunityPeriods.acquisition;
    }

    function getMergerImmunityPeriod()
        external
        view
        override
        returns (uint256)
    {
        return _immunityPeriods.merger;
    }

    function getRevivalImmunityPeriod()
        external
        view
        override
        returns (uint256)
    {
        return _immunityPeriods.revival;
    }

    function getMergerBurnPercentage()
        external
        view
        override
        returns (uint256)
    {
        return _mergerBurnPercentage;
    }

    function getWithdrawalBurnPercentage()
        external
        view
        override
        returns (uint256)
    {
        return _withdrawalBurnPercentage;
    }

    function hasFoundedFree(address _user)
        external
        view
        override
        returns (bool)
    {
        return _hasFoundedFree[_user];
    }

    function getMaxReserved() external pure override returns (uint256) {
        return MAX_RESERVED;
    }

    function getMaxFree() external pure override returns (uint256) {
        return MAX_FREE;
    }

    function getMaxAuctioned() external pure override returns (uint256) {
        return MAX_AUCTIONED;
    }

    function getEnterprise(uint256 _enterpriseId)
        external
        view
        override
        returns (Enterprise memory)
    {
        return _enterprises[_enterpriseId];
    }

    function tokenURI(uint256 _enterpriseId)
        public
        view
        override(ERC721Upgradeable, IERC721MetadataUpgradeable)
        returns (string memory)
    {
        return
            _revertToFallback(_enterpriseId)
                ? _fallbackBranding.getArt(_enterpriseId)
                : _enterprises[_enterpriseId].branding.getArt(_enterpriseId);
    }

    function getAuctionPrice() public view override returns (uint256) {
        // round up to prevent a small enough range resulting in a decay of zero
        uint256 _decayPerSecond =
            (_foundingParameters.startPrice - _foundingParameters.endPrice) /
                (_foundingParameters.endTime - _foundingParameters.startTime) +
                1;
        uint256 _decay =
            _decayPerSecond *
                (block.timestamp - _foundingParameters.startTime);
        uint256 _auctionPrice;
        if (_decay > _foundingParameters.startPrice) {
            return _foundingParameters.endPrice;
        }
        _auctionPrice = _foundingParameters.startPrice - _decay;
        return
            _auctionPrice < _foundingParameters.endPrice
                ? _foundingParameters.endPrice
                : _auctionPrice;
    }

    function isEnterpriseImmune(uint256 _enterpriseId)
        public
        view
        override
        returns (bool)
    {
        uint256 _acquisitionImmunityEnd =
            _enterprises[_enterpriseId].acquisitionImmunityStartTime +
                _immunityPeriods.acquisition;
        uint256 _mergerImmunityEnd =
            _enterprises[_enterpriseId].mergerImmunityStartTime +
                _immunityPeriods.merger;
        uint256 _revivalImmunityEnd =
            _enterprises[_enterpriseId].revivalImmunityStartTime +
                _immunityPeriods.revival;
        return (_acquisitionImmunityEnd >= block.timestamp ||
            _mergerImmunityEnd >= block.timestamp ||
            _revivalImmunityEnd >= block.timestamp);
    }

    function getEnterpriseVirtualBalance(uint256 _enterpriseId)
        public
        view
        override
        returns (uint256)
    {
        if (!(block.timestamp >= _gameStartTime && _gameStartTime != 0)) {
            return 0;
        }
        // if balance has never been updated, use the game's start time
        uint256 _lastRpUpdateTime =
            (_enterprises[_enterpriseId].lastRpUpdateTime == 0)
                ? _gameStartTime
                : _enterprises[_enterpriseId].lastRpUpdateTime;
        uint256 _rpPerDay =
            _passiveRpPerDay.base +
                (_passiveRpPerDay.acquisitions *
                    _enterprises[_enterpriseId].acquisitions) +
                (_passiveRpPerDay.mergers *
                    _enterprises[_enterpriseId].mergers);
        _rpPerDay = (_rpPerDay > _passiveRpPerDay.max)
            ? _passiveRpPerDay.max
            : _rpPerDay;
        // divide rpPerDay by 86400 seconds in a day
        return
            _enterprises[_enterpriseId].rp +
            ((_rpPerDay * (block.timestamp - _lastRpUpdateTime)) / 86400);
    }

    function _competeUnchecked(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _damage,
        uint256 _rpToSpend
    ) private nonReentrant {
        /* if balance of target enterprise is less than damage that would be done with all the committed RP,
         * only take the amount to bring target enterprise's RP to zero.
         */
        uint256 _percentOfBase = PERCENT_DENOMINATOR;
        uint256 _targetBalance = _enterprises[_targetId].rp;
        if (_damage > _targetBalance) {
            _percentOfBase = (_targetBalance * PERCENT_DENOMINATOR) / _damage;
            // round up to prevent amounts too small for precision costing zero
            _percentOfBase += 1;
            _damage = _targetBalance;
        }
        _reduceEnterpriseRp(_targetId, _damage);
        _rpToSpend = (_percentOfBase * _rpToSpend) / PERCENT_DENOMINATOR;
        _reduceEnterpriseRp(_callerId, _rpToSpend);
        _enterprises[_callerId].competes += _rpToSpend;
        _enterprises[_callerId].damageDealt += _damage;
        _enterprises[_targetId].damageTaken += _damage;
        _enterprises[_callerId].acquisitionImmunityStartTime = 0;
        _enterprises[_callerId].mergerImmunityStartTime = 0;
        _enterprises[_callerId].revivalImmunityStartTime = 0;
        emit Compete(_callerId, _targetId, _rpToSpend, _damage);
    }

    function _acquireUnchecked(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _burnedId
    ) private nonReentrant {
        (uint256 _amountToRecipient, uint256 _amountToTreasury, ) =
            _acquireCost.updateAndGetCost(_callerId, _targetId, 1);

        _weth.safeTransferFrom(msg.sender, owner(), _amountToTreasury);
        _weth.safeTransferFrom(
            msg.sender,
            ownerOf(_targetId),
            _amountToRecipient
        );

        _burn(_burnedId);
        uint256 _idToKeep = (_burnedId == _callerId) ? _targetId : _callerId;
        if (_idToKeep == _targetId) {
            _transfer(ownerOf(_targetId), msg.sender, _targetId);
        }

        _enterprises[_idToKeep].acquisitions++;
        _enterprises[_idToKeep].acquisitionImmunityStartTime = block.timestamp;
        emit Acquisition(_callerId, _targetId, _burnedId);
    }

    function _updateEnterpriseRp(uint256 _enterpriseId) private {
        _enterprises[_enterpriseId].rp = getEnterpriseVirtualBalance(
            _enterpriseId
        );
        _enterprises[_enterpriseId].lastRpUpdateTime = block.timestamp;
    }

    function _reduceEnterpriseRp(uint256 _enterpriseId, uint256 _amount)
        private
    {
        require(
            _enterprises[_enterpriseId].rp >= _amount,
            "exceeds enterprise RP"
        );
        _enterprises[_enterpriseId].rp -= _amount;
    }

    function _publicFoundingCheck() private view {
        require(
            _foundingParameters.startPrice != 0 &&
                _foundingParameters.endTime != 0 &&
                block.timestamp >= _foundingParameters.startTime,
            "founding has not started"
        );
    }

    function _gameStartCheck() private view {
        require(
            (block.timestamp >= _gameStartTime && _gameStartTime != 0),
            "game has not begun"
        );
    }

    function _hostileActionCheck(
        address _sender,
        uint256 _callerId,
        uint256 _targetId
    ) private view {
        _baseActionCheck(_sender, _callerId, _targetId);
        require(_exists(_targetId), "target enterprise doesn't exist");
        require(!isEnterpriseImmune(_targetId), "target enterprise is immune");
    }

    function _selfActionCheck(
        address _sender,
        uint256 _callerId,
        uint256 _targetId
    ) private view {
        _baseActionCheck(_sender, _callerId, _targetId);
        require(
            ownerOf(_targetId) == _sender,
            "not owner of target enterprise"
        );
    }

    function _baseActionCheck(
        address _sender,
        uint256 _callerId,
        uint256 _targetId
    ) private view {
        require(_callerId != _targetId, "enterprises are identical");
        _enterpriseOwnerCheck(_sender, _callerId);
    }

    function _enterpriseOwnerCheck(address _sender, uint256 _enterpriseId)
        private
        view
    {
        require(ownerOf(_enterpriseId) == _sender, "not enterprise owner");
    }

    function _consumableTokenCheck(address _sender, uint256 _id) private view {
        require(
            _consumables.balanceOf(_sender, _id) > 0,
            "caller is not token owner"
        );
    }

    function _supplyCheck(uint256 _count, uint256 _max) private pure {
        require(_count < _max, "exceeds supply");
    }

    function _isEnterpriseMinted(uint256 _id) private view returns (bool) {
        return ((_id >= 0 && _id < _auctionCount) ||
            (_id >= MAX_AUCTIONED && _id < _freeCount + MAX_AUCTIONED) ||
            (_id >= MAX_AUCTIONED + MAX_FREE &&
                _id < _reservedCount + MAX_AUCTIONED + MAX_FREE));
    }

    function _revertToFallback(uint256 _enterpriseId)
        private
        view
        returns (bool)
    {
        try
            _enterprises[_enterpriseId].branding.getArt(_enterpriseId)
        returns (string memory _enterpriseArt) {
            if (
                (bytes(_enterpriseArt).length == 0) ||
                !_supportForBranding[_enterprises[_enterpriseId].branding]
            ) {
                return true;
            } else {
                return false;
            }
        } catch {
            return true;
        }
    }

    function _zeroAddressCheck(address _newAddress) private pure {
        require(_newAddress != address(0), "zero address");
    }

    function _verifyName(string memory _name) private pure returns (bool) {
        bytes memory _nameInBytes = bytes(_name);
        if (_nameInBytes.length < 1) return false; // Cannot be empty
        if (_nameInBytes.length > 20) return false; // Cannot be longer than 20 characters
        if (_nameInBytes[0] == 0x20) return false; // Leading space
        if (_nameInBytes[_nameInBytes.length - 1] == 0x20) return false; // Trailing space

        bytes1 _lastChar = _nameInBytes[0];
        for (uint256 _i; _i < _nameInBytes.length; _i++) {
            bytes1 _char = _nameInBytes[_i];

            if (_char == 0x20 && _lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(_char >= 0x30 && _char <= 0x39) && //9-0
                !(_char >= 0x41 && _char <= 0x5A) && //A-Z
                !(_char >= 0x61 && _char <= 0x7A) && //a-z
                !(_char == 0x20) //space
            ) return false;

            _lastChar = _char;
        }
        return true;
    }

    function _toString(uint256 value) private pure returns (string memory) {
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}