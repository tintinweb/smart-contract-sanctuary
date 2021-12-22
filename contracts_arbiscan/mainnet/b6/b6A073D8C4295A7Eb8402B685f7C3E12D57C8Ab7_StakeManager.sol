// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IRewardDelegators.sol";
import "../MPond.sol";


contract StakeManager is
    Initializable,  // initializer
    ContextUpgradeable,  // _msgSender, _msgData
    ERC165Upgradeable,  // supportsInterface
    AccessControlUpgradeable,  // RBAC
    AccessControlEnumerableUpgradeable,  // RBAC enumeration
    ERC1967UpgradeUpgradeable,  // delegate slots, proxy admin, private upgrade
    UUPSUpgradeable  // public upgrade
{
    // in case we add more contracts in the inheritance chain
    uint256[500] private __gap0;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // initializes the logic contract without any admins
    // safeguard against takeover of the logic contract
    constructor() initializer {}

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _;
    }

//-------------------------------- Overrides start --------------------------------//

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, AccessControlUpgradeable, AccessControlEnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _grantRole(bytes32 role, address account) internal virtual override(AccessControlUpgradeable, AccessControlEnumerableUpgradeable) {
        super._grantRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override(AccessControlUpgradeable, AccessControlEnumerableUpgradeable) {
        super._revokeRole(role, account);

        // protect against accidentally removing all admins
        require(getRoleMemberCount(DEFAULT_ADMIN_ROLE) != 0);
    }

    function _authorizeUpgrade(address /*account*/) onlyAdmin internal view override {}

//-------------------------------- Overrides end --------------------------------//

//-------------------------------- Initializer start --------------------------------//

    uint256[50] private __gap1;

    function initialize(
        bytes32[] memory _tokenIds,
        address[] memory _tokenAddresses,
        bool[] memory _delegatable,
        address _rewardDelegatorsAddress,
        uint256 _redelegationWaitTime,
        uint256 _undelegationWaitTime,
        address _gatewayL1
    )
        initializer
        public
    {
        require(
            _tokenIds.length == _tokenAddresses.length
        );

        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        for(uint256 i=0; i < _tokenIds.length; i++) {
            _addToken(_tokenIds[i], _tokenAddresses[i]);
            if(_delegatable[i]) {
                _setupRole(DELEGATABLE_TOKEN_ROLE, _tokenAddresses[i]);
            }
        }
        _updateRewardDelegators(_rewardDelegatorsAddress);
        _updateLockWaitTime(REDELEGATION_LOCK_SELECTOR, _redelegationWaitTime);
        _updateLockWaitTime(UNDELEGATION_LOCK_SELECTOR, _undelegationWaitTime);
        _setupRole(GATEWAY_ROLE, _gatewayL1);
    }

//-------------------------------- Initializer end --------------------------------//

//-------------------------------- Locks start --------------------------------//

    struct Lock {
        uint256 unlockTime;
        uint256 iValue;
    }

    mapping(bytes32 => Lock) public locks;
    mapping(bytes32 => uint256) public lockWaitTime;

    uint256[48] private __gap2;

    enum LockStatus {
        None,
        Unlocked,
        Locked
    }

    event LockWaitTimeUpdated(bytes32 indexed selector, uint256 prevLockTime, uint256 updatedLockTime);
    event LockCreated(bytes32 indexed selector, bytes32 indexed key, uint256 iValue, uint256 unlockTime);
    event LockDeleted(bytes32 indexed selector, bytes32 indexed key, uint256 iValue);

    function _lockStatus(bytes32 _selector, bytes32 _key) internal view returns (LockStatus) {
        bytes32 _lockId = keccak256(abi.encodePacked(_selector, _key));
        uint256 _unlockTime = locks[_lockId].unlockTime;
        if(_unlockTime == 0) {
            return LockStatus.None;
        } else if(_unlockTime <= block.timestamp) {
            return LockStatus.Unlocked;
        } else {
            return LockStatus.Locked;
        }
    }

    function _lock(bytes32 _selector, bytes32 _key, uint256 _iValue) internal returns (uint256) {
        require(_lockStatus(_selector, _key) == LockStatus.None);

        uint256 _duration = lockWaitTime[_selector];
        bytes32 _lockId = keccak256(abi.encodePacked(_selector, _key));
        uint256 _unlockTime = block.timestamp + _duration;
        locks[_lockId].unlockTime = _unlockTime;
        locks[_lockId].iValue = _iValue;

        emit LockCreated(_selector, _key, _iValue, _unlockTime);

        return _unlockTime;
    }

    function _revertLock(bytes32 _selector, bytes32 _key) internal returns (uint256) {
        bytes32 _lockId = keccak256(abi.encodePacked(_selector, _key));
        uint256 _iValue = locks[_lockId].iValue;
        delete locks[_lockId];

        emit LockDeleted(_selector, _key, _iValue);

        return _iValue;
    }

    function _unlock(bytes32 _selector, bytes32 _key) internal returns (uint256) {
        require(_lockStatus(_selector, _key) == LockStatus.Unlocked);
        return _revertLock(_selector, _key);
    }

    function _cloneLock(bytes32 _selector, bytes32 _fromKey, bytes32 _toKey) internal {
        bytes32 _fromLockId = keccak256(abi.encodePacked(_selector, _fromKey));
        bytes32 _toLockId = keccak256(abi.encodePacked(_selector, _toKey));

        uint256 _unlockTime = locks[_fromLockId].unlockTime;
        uint256 _iValue = locks[_fromLockId].iValue;

        locks[_toLockId].unlockTime = _unlockTime;
        locks[_toLockId].iValue = _iValue;

        emit LockCreated(_selector, _toKey, _iValue, _unlockTime);
    }

    function _updateLockWaitTime(bytes32 _selector, uint256 _updatedWaitTime) internal {
        emit LockWaitTimeUpdated(_selector, lockWaitTime[_selector], _updatedWaitTime);
        lockWaitTime[_selector] = _updatedWaitTime;
    }

    function updateLockWaitTime(bytes32 _selector, uint256 _updatedWaitTime) external onlyAdmin {
        _updateLockWaitTime(_selector, _updatedWaitTime);
    }

//-------------------------------- Locks end --------------------------------//

//-------------------------------- Tokens start --------------------------------//

    bytes32 public constant DELEGATABLE_TOKEN_ROLE = keccak256("DELEGATABLE_TOKEN_ROLE");
    bytes32 public constant ACTIVE_TOKEN_ROLE = keccak256("ACTIVE_TOKEN_ROLE");

    mapping(bytes32 => address) public tokens;
    bytes32[] public tokenList;
    mapping(bytes32 => uint256) public tokenIndex;

    uint256[47] private __gap3;

    event TokenAdded(bytes32 tokenId, address tokenAddress);
    event TokenUpdated(bytes32 tokenId, address oldTokenAddress, address newTokenAddress);

    function _addToken(bytes32 _tokenId, address _address) internal {
        require(_address != address(0));
        require(tokens[_tokenId] == address(0));

        tokens[_tokenId] = _address;
        tokenIndex[_tokenId] = tokenList.length;
        tokenList.push(_tokenId);

        emit TokenAdded(_tokenId, _address);
        _enableToken(_tokenId);
    }

    function _enableToken(bytes32 _tokenId) internal {
        require(hasRole(ACTIVE_TOKEN_ROLE, tokens[_tokenId]) == false);
        _grantRole(ACTIVE_TOKEN_ROLE, tokens[_tokenId]);
    }

    function _disableToken(bytes32 _tokenId) internal {
        require(hasRole(ACTIVE_TOKEN_ROLE, tokens[_tokenId]) == true);
        _revokeRole(ACTIVE_TOKEN_ROLE, tokens[_tokenId]);
    }

    function _updateToken(bytes32 _tokenId, address _address) internal {
        require(_address != address(0));
        address _oldAddress = tokens[_tokenId];
        require(_oldAddress != address(0));

        tokens[_tokenId] = _address;

        emit TokenUpdated(_tokenId, _oldAddress, _address);
    }

    function addToken(bytes32 _tokenId, address _address) external onlyAdmin {
        _addToken(_tokenId, _address);
    }

    function enableToken(bytes32 _tokenId) external onlyAdmin {
        _enableToken(_tokenId);
    }

    function disableToken(bytes32 _tokenId) external onlyAdmin {
        _disableToken(_tokenId);
    }

    function updateToken(bytes32 _tokenId, address _address) external onlyAdmin {
        _updateToken(_tokenId, _address);
    }

    function _lockTokens(bytes32 _stashId, bytes32 _tokenId, uint256 _amount, address _delegator) internal {
        if(_amount == 0) {
            return;
        }
        address tokenAddress = tokens[_tokenId];
        // pull tokens from mpond/pond contract
        // if mpond transfer the governance rights back
        require(
            IERC20Upgradeable(tokenAddress).transferFrom(
                _delegator,
                address(this),
                _amount
            )
        );
        if(hasRole(DELEGATABLE_TOKEN_ROLE, tokenAddress)) {
            // send a request to delegate governance rights for the amount to delegator
            MPond(tokenAddress).delegate(
                _delegator,
                uint96(_amount)
            );

            stashes[_stashId].govDelegations[_tokenId] = _delegator;
        }
    }

    function _unlockTokens(bytes32 _stashId, bytes32 _tokenId, uint256 _amount, address _delegator) internal {
        if(_amount == 0) {
            return;
        }
        address tokenAddress = tokens[_tokenId];
        if(hasRole(DELEGATABLE_TOKEN_ROLE, tokenAddress)) {
            // send a request to undelegate governacne rights for the amount to previous delegator
            MPond(tokenAddress).undelegate(
                _delegator,
                uint96(_amount)
            );

            delete stashes[_stashId].govDelegations[_tokenId];
        }
        require(
            IERC20Upgradeable(tokenAddress).transfer(
                _delegator,
                _amount
            )
        );
    }

//-------------------------------- Tokens end --------------------------------//

//-------------------------------- Stash internals start --------------------------------//

    struct Stash {
        address staker;
        address delegatedCluster;
        mapping(bytes32 => uint256) amounts;
        mapping(bytes32 => address) govDelegations;
    }

    // stashId to stash
    // stashId = keccak256(index)
    mapping(bytes32 => Stash) public stashes;
    // Stash index for unique id generation
    uint256 public stashIndex;

    IRewardDelegators public rewardDelegators;

    uint256[47] private __gap4;

    event StashCreated(bytes32 indexed stashId, address indexed creator);
    event StashDeposit(bytes32 indexed stashId, bytes32[] tokenIds, uint256[] amounts);
    event StashWithdraw(bytes32 indexed stashId, bytes32[] tokenIds, uint256[] amounts);
    event StashMove(bytes32 indexed fromStashId, bytes32 indexed toStashId, bytes32[] tokenIds, uint256[] amounts);
    event StashDelegated(bytes32 indexed stashId, address indexed delegatedCluster);
    event StashUndelegated(bytes32 indexed stashId, address indexed delegatedCluster);
    event RewardDelegatorsUpdated(address from, address to);

    function _newId() internal returns (bytes32) {
        uint256 _stashIndex = stashIndex;
        bytes32 _stashId = keccak256(abi.encodePacked(_stashIndex));
        stashIndex = _stashIndex + 1;

        return _stashId;
    }

    function _newStash(address _staker) internal returns (bytes32) {
        bytes32 _stashId = _newId();
        stashes[_stashId].staker = _staker;

        emit StashCreated(_stashId, _staker);
        return _stashId;
    }

    function _deposit(
        bytes32 _stashId,
        bytes32[] memory _tokenIds,
        uint256[] memory _amounts
    ) internal {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            bytes32 _tokenId = _tokenIds[i];
            require(
                hasRole(ACTIVE_TOKEN_ROLE, tokens[_tokenId])
            );
            if(_amounts[i] != 0) {
                stashes[_stashId].amounts[_tokenId] = stashes[_stashId].amounts[_tokenId] + _amounts[i];
                _lockTokens(_stashId, _tokenId, _amounts[i], _msgSender());
            }
        }

        emit StashDeposit(_stashId, _tokenIds, _amounts);
    }

    function _withdraw(
        bytes32 _stashId,
        bytes32[] memory _tokenIds,
        uint256[] memory _amounts
    ) internal {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            bytes32 _tokenId = _tokenIds[i];
            if(_amounts[i] != 0) {
                stashes[_stashId].amounts[_tokenId] = stashes[_stashId].amounts[_tokenId] - _amounts[i];
                _unlockTokens(_stashId, _tokenId, _amounts[i], _msgSender());
            }
        }

        emit StashWithdraw(_stashId, _tokenIds, _amounts);
    }

    function _move(
        bytes32 _fromStashId,
        bytes32 _toStashId,
        bytes32[] memory _tokenIds,
        uint256[] memory _amounts
    ) internal {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            bytes32 _tokenId = _tokenIds[i];
            stashes[_fromStashId].amounts[_tokenId] = stashes[_fromStashId].amounts[_tokenId] - _amounts[i];
            stashes[_toStashId].amounts[_tokenId] = stashes[_toStashId].amounts[_tokenId] + _amounts[i];
        }

        emit StashMove(_fromStashId, _toStashId, _tokenIds, _amounts);
    }

    function _delegate(
        bytes32 _stashId,
        bytes32[] memory _tokenIds,
        uint256[] memory _amounts,
        address _delegatedCluster
    ) internal {
        stashes[_stashId].delegatedCluster = _delegatedCluster;
        rewardDelegators.delegate(_msgSender(), _delegatedCluster, _tokenIds, _amounts);

        emit StashDelegated(_stashId, stashes[_stashId].delegatedCluster);
    }

    function _undelegate(
        bytes32 _stashId,
        bytes32[] memory _tokenIds,
        uint256[] memory _amounts,
        address _delegatedCluster
    ) internal {
        rewardDelegators.undelegate(_msgSender(), _delegatedCluster, _tokenIds, _amounts);
        delete stashes[_stashId].delegatedCluster;

        emit StashUndelegated(_stashId, stashes[_stashId].delegatedCluster);
    }

    function _updateRewardDelegators(address _updatedRewardDelegator) internal {
        emit RewardDelegatorsUpdated(address(rewardDelegators), _updatedRewardDelegator);
        rewardDelegators = IRewardDelegators(_updatedRewardDelegator);
    }

    function updateRewardDelegators(
        address _updatedRewardDelegator
    ) external onlyAdmin {
        _updateRewardDelegators(_updatedRewardDelegator);
    }

//-------------------------------- Stash internals end --------------------------------//

//-------------------------------- Stash externals start --------------------------------//

    bytes32 public constant REDELEGATION_LOCK_SELECTOR = keccak256("REDELEGATION_LOCK");
    bytes32 public constant UNDELEGATION_LOCK_SELECTOR = keccak256("UNDELEGATION_LOCK");

    uint256[50] private __gap5;

    modifier onlyStakerOf(bytes32 _stashId) {
        require(stashes[_stashId].staker == _msgSender());
        _;
    }

    function createStashAndDelegate(
        bytes32[] memory _tokens,
        uint256[] memory _amounts,
        address _delegatedCluster
    ) public {
        bytes32 stashId = createStash(_tokens, _amounts);
        delegateStash(stashId, _delegatedCluster);
    }

    function createStash(
        bytes32[] memory _tokens,
        uint256[] memory _amounts
    ) public returns(bytes32) {
        require(
            _tokens.length == _amounts.length
        );
        require(
            _tokens.length != 0
        );
        bytes32 _stashId = _newStash(_msgSender());
        _deposit(_stashId, _tokens, _amounts);

        return _stashId;
    }

    function addToStash(
        bytes32 _stashId,
        bytes32[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyStakerOf(_stashId) {
        require(
            _tokens.length == _amounts.length
        );
        _deposit(_stashId, _tokens, _amounts);

        address _delegatedCluster = stashes[_stashId].delegatedCluster;
        if(_delegatedCluster != address(0)) {
            _delegate(_stashId, _tokens, _amounts, _delegatedCluster);
        }
    }

    function delegateStash(bytes32 _stashId, address _delegatedCluster) public onlyStakerOf(_stashId) {
        require(
            _delegatedCluster != address(0)
        );
        require(
            stashes[_stashId].delegatedCluster == address(0)
        );
        require(
            _lockStatus(UNDELEGATION_LOCK_SELECTOR, _stashId) != LockStatus.Locked
        );
        _revertLock(UNDELEGATION_LOCK_SELECTOR, _stashId);
        bytes32[] memory _tokens = tokenList;
        uint256[] memory _amounts = new uint256[](_tokens.length);
        for(uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = stashes[_stashId].amounts[_tokens[i]];
        }

        _delegate(_stashId, _tokens, _amounts, _delegatedCluster);
    }

    function requestStashRedelegation(bytes32 _stashId, address _newCluster) public onlyStakerOf(_stashId) {
        require(
            stashes[_stashId].delegatedCluster != address(0)
        );
        require(
            _newCluster != address(0)
        );
        _lock(REDELEGATION_LOCK_SELECTOR, _stashId, uint256(uint160(_newCluster)));
    }

    function requestStashRedelegations(bytes32[] memory _stashIds, address[] memory _newClusters) public {
        require(_stashIds.length == _newClusters.length);
        for(uint256 i=0; i < _stashIds.length; i++) {
            requestStashRedelegation(_stashIds[i], _newClusters[i]);
        }
    }

    function redelegateStash(bytes32 _stashId) public onlyStakerOf(_stashId) {
        require(
             stashes[_stashId].delegatedCluster != address(0)
        );
        address _updatedCluster = address(uint160(_unlock(REDELEGATION_LOCK_SELECTOR, _stashId)));
        _redelegateStash(_stashId,  stashes[_stashId].delegatedCluster, _updatedCluster);
    }

    function _redelegateStash(
        bytes32 _stashId,
        address _delegatedCluster,
        address _updatedCluster
    ) internal {
        bytes32[] memory _tokens = tokenList;
        uint256[] memory _amounts = new uint256[](_tokens.length);
        for(uint256 i=0; i < _tokens.length; i++) {
            _amounts[i] = stashes[_stashId].amounts[_tokens[i]];
        }

        if(_delegatedCluster != address(0)) {
            _undelegate(_stashId, _tokens, _amounts, _delegatedCluster);
        }
        if(_updatedCluster != address(0)) {
            _delegate(_stashId, _tokens, _amounts, _updatedCluster);
        }
    }

    function splitStash(bytes32 _stashId, bytes32[] calldata _tokens, uint256[] calldata _amounts) external onlyStakerOf(_stashId) {
        require(
            _tokens.length != 0
        );
        require(
            _tokens.length == _amounts.length
        );
        bytes32 _newStashId = _newStash(_msgSender());
        _move(_stashId, _newStashId, _tokens, _amounts);
        stashes[_newStashId].delegatedCluster = stashes[_stashId].delegatedCluster;
        _cloneLock(UNDELEGATION_LOCK_SELECTOR, _stashId, _newStashId);
    }

    function mergeStash(bytes32 _stashId1, bytes32 _stashId2) external onlyStakerOf(_stashId1) onlyStakerOf(_stashId2) {
        require(_stashId1 != _stashId2);
        require(
            stashes[_stashId1].delegatedCluster == stashes[_stashId2].delegatedCluster
        );
        require(
            _lockStatus(UNDELEGATION_LOCK_SELECTOR, _stashId1) != LockStatus.Locked &&
            _lockStatus(UNDELEGATION_LOCK_SELECTOR, _stashId2) != LockStatus.Locked &&
            _lockStatus(REDELEGATION_LOCK_SELECTOR, _stashId1) == LockStatus.None &&
            _lockStatus(REDELEGATION_LOCK_SELECTOR, _stashId2) == LockStatus.None
        );

        bytes32[] memory _tokens = tokenList;
        uint256[] memory _amounts = new uint256[](_tokens.length);
        for(uint256 i=0; i < _tokens.length; i++) {
            _amounts[i] = stashes[_stashId2].amounts[_tokens[i]];
        }

        _move(_stashId2, _stashId1, _tokens, _amounts);

        delete stashes[_stashId2];
    }

    function redelegateStashes(bytes32[] memory _stashIds) public {
        for(uint256 i=0; i < _stashIds.length; i++) {
            redelegateStash(_stashIds[i]);
        }
    }

    function cancelRedelegation(bytes32 _stashId) public onlyStakerOf(_stashId) {
        require(_cancelRedelegation(_stashId));
    }

    function _cancelRedelegation(bytes32 _stashId) internal returns(bool) {
        bool _exists = _lockStatus(REDELEGATION_LOCK_SELECTOR, _stashId) != LockStatus.None;
        if(_exists) {
            _revertLock(REDELEGATION_LOCK_SELECTOR, _stashId);
        }
        return _exists;
    }

    function undelegateStash(bytes32 _stashId) public onlyStakerOf(_stashId) {
        address _delegatedCluster = stashes[_stashId].delegatedCluster;
        require(
            stashes[_stashId].delegatedCluster != address(0)
        );

        bytes32[] memory _tokens = tokenList;
        uint256[] memory _amounts = new uint256[](_tokens.length);
        for(uint256 i=0; i < _tokens.length; i++) {
            _amounts[i] = stashes[_stashId].amounts[_tokens[i]];
        }

        _undelegate(_stashId, _tokens, _amounts, _delegatedCluster);

        _lock(UNDELEGATION_LOCK_SELECTOR, _stashId, uint256(uint160(_delegatedCluster)));
        _cancelRedelegation(_stashId);
    }

    function undelegateStashes(bytes32[] memory _stashIds) public {
        for(uint256 i=0; i < _stashIds.length; i++) {
            undelegateStash(_stashIds[i]);
        }
    }

    function cancelUndelegation(bytes32 _stashId) public onlyStakerOf(_stashId) {
        require(
            _lockStatus(UNDELEGATION_LOCK_SELECTOR, _stashId) == LockStatus.Locked
        );
        address _delegatedCluster = address(uint160(_revertLock(UNDELEGATION_LOCK_SELECTOR, _stashId)));

        bytes32[] memory _tokens = tokenList;
        uint256[] memory _amounts = new uint256[](_tokens.length);
        for(uint256 i=0; i < _tokens.length; i++) {
            _amounts[i] = stashes[_stashId].amounts[_tokens[i]];
        }

        _delegate(_stashId, _tokens, _amounts, _delegatedCluster);
    }

    function withdrawStash(bytes32 _stashId) external onlyStakerOf(_stashId) {
        require(
            stashes[_stashId].delegatedCluster == address(0)
        );
        require(
            _lockStatus(UNDELEGATION_LOCK_SELECTOR, _stashId) != LockStatus.Locked
        );
        bytes32[] memory _tokens = tokenList;
        uint256[] memory _amounts = new uint256[](_tokens.length);
        for(uint256 i=0; i < _tokens.length; i++) {
            _amounts[i] = stashes[_stashId].amounts[_tokens[i]];
        }

        _withdraw(_stashId, _tokens, _amounts);
    }

    function withdrawStash(
        bytes32 _stashId,
        bytes32[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyStakerOf(_stashId) {
        require(
            stashes[_stashId].delegatedCluster == address(0)
        );
        require(
            _lockStatus(UNDELEGATION_LOCK_SELECTOR, _stashId) != LockStatus.Locked
        );
        require(
            _tokens.length == _amounts.length
        );
        _withdraw(_stashId, _tokens, _amounts);
    }

    function getTokenAmountInStash(bytes32 _stashId, bytes32 _tokenId) external view returns(uint256) {
        return stashes[_stashId].amounts[_tokenId];
    }

//-------------------------------- Stash externals end --------------------------------//

//-------------------------------- Gateway start --------------------------------//

    bytes32 public constant GATEWAY_ROLE = keccak256("GATEWAY_ROLE");
    uint160 constant diff = uint160(0x1111000000000000000000000000000000001111);

    uint256[50] private __gap6;

    modifier onlyGatewayL1() {
        unchecked {
            require(
                hasRole(GATEWAY_ROLE, address(uint160(_msgSender()) - diff))
            );
        }
        _;
    }

    function transferL2(
        address _staker,
        bytes32[] calldata _tokenIds,
        uint256[] calldata _allAmounts,
        address[] calldata _delegatedClusters
    ) external onlyGatewayL1 {
        uint256 _stashCount = _delegatedClusters.length;
        for(uint256 _sidx = 0; _sidx < _stashCount; _sidx++) {
            // create stash
            bytes32 _stashId = _newStash(_staker);
            uint256[] memory _amounts = _allAmounts[(_sidx*_tokenIds.length):((_sidx+1)*_tokenIds.length)];
            for(uint256 _tidx=0; _tidx < _tokenIds.length; _tidx++) {
                bytes32 _tokenId = _tokenIds[_tidx];
                uint256 _amount = _amounts[_tidx];
                if(_amount == 0) {
                    continue;
                }
                stashes[_stashId].amounts[_tokenId] = _amount;
            }
            stashes[_stashId].staker = _staker;

            emit StashDeposit(_stashId, _tokenIds, _amounts);

            // delegate
            if(_delegatedClusters[_sidx] != address(0)) {
                _delegate(_stashId, _tokenIds, _amounts, _delegatedClusters[_sidx]);
            }
        }
    }

//-------------------------------- Gateway end --------------------------------//

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

interface IRewardDelegators {
    // there's no undelegationWaitTime in rewardDelegators contract
    function undelegationWaitTime() external returns(uint256);
    function minMPONDStake() external returns(uint256);
    function MPONDTokenId() external returns(bytes32);
    function updateMPONDTokenId(bytes32 _updatedMPONDTokenId) external;
    function addRewardFactor(bytes32 _tokenId, uint256 _rewardFactor) external;
    function removeRewardFactor(bytes32 _tokenId) external;
    function updateRewardFactor(bytes32 _tokenId, uint256 _updatedRewardFactor) external;
    function _updateRewards(address _cluster) external;
    function delegate(
        address _delegator,
        address _cluster,
        bytes32[] calldata _tokens,
        uint256[] calldata _amounts
    ) external;
    function undelegate(
        address _delegator,
        address _cluster,
        bytes32[] calldata _tokens,
        uint256[] calldata _amounts
    ) external;
    function withdrawRewards(address _delegator, address _cluster) external returns(uint256);
    function isClusterActive(address _cluster) external returns(bool);
    function getClusterDelegation(address _cluster, bytes32 _tokenId) external view returns(uint256);
    function getDelegation(address _cluster, address _delegator, bytes32 _tokenId) external view returns(uint256);
    function updateUndelegationWaitTime(uint256 _undelegationWaitTime) external;
    function updateMinMPONDStake(uint256 _minMPONDStake) external;
    function updateStakeAddress(address _updatedStakeAddress) external;
    function updateClusterRewards(address _updatedClusterRewards) external;
    function updateClusterRegistry(address _updatedClusterRegistry) external;
    function updatePONDAddress(address _updatedPOND) external;
    function getFullTokenList() external view returns (bytes32[] memory);
    function getAccRewardPerShare(address _cluster, bytes32 _tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: BSD-3-Clause

// Copyright 2020 Marlin contributors and Compound Labs, Inc.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


// do not use any of the OpenZeppelin ERC20 contracts or extensions
contract MPond is
    Initializable,  // initializer
    ContextUpgradeable,  // _msgSender, _msgData
    ERC165Upgradeable,  // supportsInterface
    AccessControlUpgradeable,  // RBAC
    AccessControlEnumerableUpgradeable,  // RBAC enumeration
    ERC1967UpgradeUpgradeable,  // delegate slots, proxy admin, private upgrade
    UUPSUpgradeable  // public upgrade
{
    // in case we add more contracts in the inheritance chain
    uint256[500] private __gap0;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // initializes the logic contract without any admins
    // safeguard against takeover of the logic contract
    constructor() initializer {}

//-------------------------------- Overrides start --------------------------------//

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, AccessControlUpgradeable, AccessControlEnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _grantRole(bytes32 role, address account) internal virtual override(AccessControlUpgradeable, AccessControlEnumerableUpgradeable) {
        super._grantRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override(AccessControlUpgradeable, AccessControlEnumerableUpgradeable) {
        super._revokeRole(role, account);

        // protect against accidentally removing all admins
        require(getRoleMemberCount(DEFAULT_ADMIN_ROLE) != 0, "Cannot be adminless");
    }

    function _authorizeUpgrade(address /*account*/) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MPond: must be admin to upgrade");
    }

//-------------------------------- Overrides end --------------------------------//

//-------------------------------- Initializer start --------------------------------//

    uint256[50] private __gap1;

    function initialize() public initializer {
        // initialize parents
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();

        // set sender as admin
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // mint supply to sender
        uint96 _amount = safe96(totalSupply, "Supply exceeds 2^96");
        balances[_msgSender()] = Balance(_amount, _amount, 0);
        emit Transfer(address(0), _msgSender(), totalSupply);
    }

//-------------------------------- Initializer end --------------------------------//

//-------------------------------- Whitelist start --------------------------------//

    uint256[50] private __gap2;

    /// @notice Role used for whitelist
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    function isWhitelistedTransfer(address _address1, address _address2)
        public
        view
        returns (bool)
    {
        if (
            hasRole(WHITELIST_ROLE, _address2) ||
            hasRole(WHITELIST_ROLE, _address1)
        ) {
            return true;
        }
        return false;
    }

//-------------------------------- Whitelist end --------------------------------//

//-------------------------------- ERC20 start --------------------------------//

    /// @notice EIP-20 token name for this token
    string public constant name = "Marlin MPond";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "MPond";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public constant totalSupply = 10000e18;  // 10k

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    /// @notice Optimize balances by storing multiple items in same slot
    struct Balance {
        uint96 undelegated;
        uint96 token;
        uint64 __unused;
    }

    /// @notice Official record of token balances for each account
    mapping(address => Balance) internal balances;

    uint256[48] private __gap3;

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     */
    function approve(address spender, uint256 rawAmount)
        external returns (bool)
    {
        uint96 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(
                rawAmount,
                "MPond::approve: amount exceeds 96 bits"
            );
        }

        allowances[_msgSender()][spender] = amount;

        emit Approval(_msgSender(), spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedAmount)
        external
    {
        uint96 amount;
        if (addedAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(
                addedAmount,
                "MPond::approve: addedAmount exceeds 96 bits"
            );
        }

        allowances[_msgSender()][spender] = add96(
            allowances[_msgSender()][spender],
            amount,
            "MPond: increaseAllowance allowance value overflows"
        );
        emit Approval(_msgSender(), spender, allowances[_msgSender()][spender]);
    }

    function decreaseAllowance(address spender, uint256 removedAmount)
        external
    {
        uint96 amount;
        if (removedAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(
                removedAmount,
                "MPond::approve: removedAmount exceeds 96 bits"
            );
        }

        allowances[_msgSender()][spender] = sub96(
            allowances[_msgSender()][spender],
            amount,
            "MPond: decreaseAllowance allowance value underflows"
        );
        emit Approval(_msgSender(), spender, allowances[_msgSender()][spender]);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return uint256(balances[account].token);
    }

    function undelegatedBalanceOf(address account) external view returns (uint256) {
        return uint256(balances[account].undelegated);
    }

    /**
     * @notice Transfer `amount` tokens from `_msgSender()` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        require(
            isWhitelistedTransfer(_msgSender(), dst),
            "Atleast one of the address (src or dst) should be whitelisted or all transfers must be enabled via enableAllTransfers()"
        );
        uint96 amount = safe96(
            rawAmount,
            "MPond::transfer: amount exceeds 96 bits"
        );
        _transferTokens(_msgSender(), dst, amount);

        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool) {
        require(
            isWhitelistedTransfer(src, dst),
            "Atleast one of the address (src or dst) should be whitelisted or all transfers must be enabled via enableAllTransfers()"
        );
        address spender = _msgSender();
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(
            rawAmount,
            "MPond::approve: amount exceeds 96 bits"
        );

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(
                spenderAllowance,
                amount,
                "MPond::transferFrom: transfer amount exceeds spender allowance"
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);

        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint96 amount
    ) internal {
        require(
            src != address(0),
            "MPond::_transferTokens: cannot transfer from the zero address"
        );
        require(
            dst != address(0),
            "MPond::_transferTokens: cannot transfer to the zero address"
        );

        Balance memory _srcBalance = balances[src];
        _srcBalance.undelegated = sub96(
            _srcBalance.undelegated,
            amount,
            "MPond::_transferTokens: transfer amount exceeds undelegated balance"
        );
        _srcBalance.token = sub96(
            _srcBalance.token,
            amount,
            "MPond::_transferTokens: transfer amount exceeds balance"
        );
        balances[src] = _srcBalance;

        Balance memory _dstBalance = balances[dst];
        _dstBalance.undelegated = add96(
            _dstBalance.undelegated,
            amount,
            "MPond::_transferTokens: undelegated balance overflow"
        );
        _dstBalance.token = add96(
            _dstBalance.token,
            amount,
            "MPond::_transferTokens: balance overflow"
        );
        balances[dst] = _dstBalance;

        emit Transfer(src, dst, amount);
    }

//-------------------------------- ERC20 end --------------------------------//

//-------------------------------- Delegation start --------------------------------//

    /// @notice A record of each accounts delegates and values except to 0x0 which is stored in balances
    mapping(address => mapping(address => uint96)) internal delegates;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    uint256[48] private __gap4;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256(
        "Delegation(address delegatee,uint256 nonce,uint256 expiry,uint96 amount)"
    );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant UNDELEGATION_TYPEHASH = keccak256(
        "Undelegation(address delegatee,uint256 nonce,uint256 expiry,uint96 amount)"
    );

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /**
     * @notice Delegate votes from `_msgSender()` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee, uint96 amount) public {
        return _delegate(_msgSender(), delegatee, amount);
    }

    function undelegate(address delegatee, uint96 amount) public {
        return _undelegate(_msgSender(), delegatee, amount);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint96 amount
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                block.chainid,
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry, amount)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "MPond::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "MPond::delegateBySig: invalid nonce"
        );
        require(block.timestamp <= expiry, "MPond::delegateBySig: signature expired");
        return _delegate(signatory, delegatee, amount);
    }

    function undelegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint96 amount
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                block.chainid,
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(UNDELEGATION_TYPEHASH, delegatee, nonce, expiry, amount)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "MPond::undelegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "MPond::undelegateBySig: invalid nonce"
        );
        require(block.timestamp <= expiry, "MPond::undelegateBySig: signature expired");
        return _undelegate(signatory, delegatee, amount);
    }

    function _delegate(
        address delegator,
        address delegatee,
        uint96 amount
    ) internal {
        Balance memory _srcBalance = balances[delegator];
        _srcBalance.undelegated = sub96(
            _srcBalance.undelegated,
            amount,
            "MPond::_transferTokens: transfer amount exceeds undelegated balance"
        );
        balances[delegator] = _srcBalance;

        delegates[delegator][delegatee] = add96(
            delegates[delegator][delegatee],
            amount,
            "MPond: delegates overflow"
        );

        emit DelegateChanged(delegator, address(0), delegatee);

        _moveDelegates(address(0), delegatee, amount);
    }

    function _undelegate(
        address delegator,
        address delegatee,
        uint96 amount
    ) internal {
        delegates[delegator][delegatee] = sub96(
            delegates[delegator][delegatee],
            amount,
            "MPond: undelegates underflow"
        );

        Balance memory _srcBalance = balances[delegator];
        _srcBalance.undelegated = add96(
            _srcBalance.undelegated,
            amount,
            "MPond::_transferTokens: transfer amount exceeds undelegated balance"
        );
        balances[delegator] = _srcBalance;

        emit DelegateChanged(delegator, delegatee, address(0));
        _moveDelegates(delegatee, address(0), amount);
    }

//-------------------------------- Delegation end --------------------------------//


//-------------------------------- Checkpoints start --------------------------------//

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    uint256[48] private __gap5;

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints != 0
                ? checkpoints[account][nCheckpoints - 1].votes
                : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint96)
    {
        require(
            blockNumber < block.number,
            "MPond::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum != 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint96 srcRepNew = sub96(
                    srcRepOld,
                    amount,
                    "MPond::_moveVotes: vote amount underflows"
                );
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum != 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint96 dstRepNew = add96(
                    dstRepOld,
                    amount,
                    "MPond::_moveVotes: vote amount overflows"
                );
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "MPond::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints != 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

//-------------------------------- Checkpoints end --------------------------------//


//-------------------------------- uint96 math start --------------------------------//

    uint256[50] private __gap6;

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint96)
    {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

//-------------------------------- uint96 math end --------------------------------//

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
library EnumerableSetUpgradeable {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}