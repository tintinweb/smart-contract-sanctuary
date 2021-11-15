// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC1155TokenReceiver.sol";
import "../libraries/LibMeta.sol";
import {Epoch} from "../libraries/AppStorage.sol";

interface IERC1155Marketplace {
    function updateBatchERC1155Listing(
        address _erc1155TokenAddress,
        uint256[] calldata _erc1155TypeIds,
        address _owner
    ) external;
}

interface IERC20Mintable {
    function mint(address _to, uint256 _amount) external;

    function burn(address _to, uint256 _amount) external;
}

contract StakingFacet {
    AppStorage internal s;
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event PoolTokensRate(uint256 _newRate);
    event GhstUsdcRate(uint256 _newRate);
    event RateManagerAdded(address indexed rateManager_);
    event RateManagerRemoved(address indexed rateManager_);
    event GhstWethRate(uint256 _newRate);

    //Epoch events
    event StakeInEpoch(address indexed _account, address indexed _poolAddress, uint256 indexed _epoch, uint256 _amount);
    event WithdrawInEpoch(address indexed _account, address indexed _poolAddress, uint256 indexed _epoch, uint256 _amount);
    event PoolAddedInEpoch(address indexed _poolAddress, uint256 indexed _epoch);
    event EpochIncreased(uint256 indexed _newEpoch);
    event UserMigrated(address indexed _account);

    struct PoolInput {
        address _poolAddress;
        address _poolReceiptToken; //The receipt token for staking into this pool.
        uint256 _rate;
        string _poolName;
        string _poolUrl;
    }

    struct PoolStakedOutput {
        address poolAddress;
        string poolName;
        string poolUrl;
        uint256 rate;
        uint256 amount;
    }

    /***********************************|
   |  External Epoch Read Functions     |
   |__________________________________*/

    function userEpoch(address _account) external view returns (uint256) {
        return s.accounts[_account].userCurrentEpoch;
    }

    function currentEpoch() external view returns (uint256) {
        return s.currentEpoch;
    }

    function getPoolInfo(address _poolAddress, uint256 _epoch) external view returns (PoolInput memory _poolInfo) {
        Pool storage pool = s.pools[_poolAddress];
        return PoolInput(_poolAddress, pool.receiptToken, pool.epochPoolRate[_epoch], pool.name, pool.url);
    }

    function poolRatesInEpoch(uint256 _epoch) external view returns (PoolStakedOutput[] memory _rates) {
        Epoch storage epoch = s.epochs[_epoch];
        _rates = new PoolStakedOutput[](epoch.supportedPools.length);

        for (uint256 index = 0; index < epoch.supportedPools.length; index++) {
            address poolAddress = epoch.supportedPools[index];
            uint256 rate = s.pools[poolAddress].epochPoolRate[_epoch];
            string memory poolName = s.pools[poolAddress].name;
            string memory url = s.pools[poolAddress].url;
            _rates[index] = PoolStakedOutput(poolAddress, poolName, url, rate, 0);
        }
    }

    function stakedInCurrentEpoch(address _account) external view returns (PoolStakedOutput[] memory _staked) {
        //Used for compatibility between migrated and non-migrated users
        if (!hasMigrated(_account)) {
            Account storage account = s.accounts[_account];
            _staked = new PoolStakedOutput[](4);
            _staked[0] = _stakedOutput(s.ghstContract, s.currentEpoch, account.ghst);
            _staked[1] = _stakedOutput(s.poolContract, s.currentEpoch, account.poolTokens);
            _staked[2] = _stakedOutput(s.ghstUsdcPoolToken, s.currentEpoch, account.ghstUsdcPoolTokens);
            _staked[3] = _stakedOutput(s.ghstWethPoolToken, s.currentEpoch, account.ghstWethPoolTokens);
        } else return stakedInEpoch(_account, s.currentEpoch);
    }

    /***********************************|
   |    Public Epoch Read Functions      |
   |__________________________________*/

    function hasMigrated(address _account) public view returns (bool) {
        return s.accounts[_account].hasMigrated;
    }

    function frens(address _account) public view returns (uint256 frens_) {
        if (s.accounts[_account].hasMigrated) return _epochFrens(_account);
        else return _deprecatedFrens(_account);
    }

    function bulkFrens(address[] calldata _accounts) public view returns (uint256[] memory frens_) {
        frens_ = new uint256[](_accounts.length);
        for (uint256 i; i < _accounts.length; i++) {
            frens_[i] = frens(_accounts[i]);
        }
    }

    function stakedInEpoch(address _account, uint256 _epoch) public view returns (PoolStakedOutput[] memory _staked) {
        Epoch storage epoch = s.epochs[_epoch];
        _staked = new PoolStakedOutput[](epoch.supportedPools.length);

        for (uint256 index = 0; index < epoch.supportedPools.length; index++) {
            address poolAddress = epoch.supportedPools[index];
            uint256 amount = s.accounts[_account].accountStakedTokens[poolAddress];
            _staked[index] = _stakedOutput(poolAddress, _epoch, amount);
        }
    }

    /***********************************|
   |  Internal Epoch Read Functions    |
   |__________________________________*/

    function _stakedOutput(
        address _poolContractAddress,
        uint256 _epoch,
        uint256 _amount
    ) internal view returns (PoolStakedOutput memory) {
        return
            PoolStakedOutput(
                _poolContractAddress,
                s.pools[_poolContractAddress].name,
                s.pools[_poolContractAddress].url,
                s.pools[_poolContractAddress].epochPoolRate[_epoch],
                _amount
            );
    }

    function _frensForEpoch(address _account, uint256 _epoch) internal view returns (uint256) {
        Epoch memory epoch = s.epochs[_epoch];
        address[] memory supportedPools = epoch.supportedPools;
        uint256 lastFrensUpdate = s.accounts[_account].lastFrensUpdate;

        uint256 duration = 0;

        //When epoch is not over yet
        if (epoch.endTime == 0) {
            uint256 epochDuration = block.timestamp - epoch.beginTime;
            uint256 timeSinceLastFrensUpdate = block.timestamp - lastFrensUpdate;
            //Time since last update is longer than the current epoch, so only use epoch time
            if (timeSinceLastFrensUpdate > epochDuration) {
                duration = epochDuration;
            } else {
                //Otherwise use timeSinceLastFrensUpdate
                duration = timeSinceLastFrensUpdate;
            }
        }
        //When epoch is over
        else {
            duration = epoch.endTime - epoch.beginTime;
        }

        uint256 accumulatedFrens = 0;

        for (uint256 index = 0; index < supportedPools.length; index++) {
            address poolAddress = supportedPools[index];

            uint256 poolHistoricRate = s.pools[poolAddress].epochPoolRate[_epoch];
            uint256 stakedTokens = s.accounts[_account].accountStakedTokens[poolAddress];
            accumulatedFrens += (stakedTokens * poolHistoricRate * duration) / 24 hours;
        }

        return accumulatedFrens;
    }

    //Gets the amount of FRENS for a given user up to a specific epoch.
    function _epochFrens(address _account) internal view returns (uint256 frens_) {
        Account storage account = s.accounts[_account];

        frens_ = account.frens;

        uint256 epochsBehind = s.currentEpoch - account.userCurrentEpoch;

        //Get frens for current epoch
        frens_ += _frensForEpoch(_account, s.currentEpoch);

        for (uint256 i = 1; i <= epochsBehind; i++) {
            uint256 historicEpoch = s.currentEpoch - i;
            frens_ += _frensForEpoch(_account, historicEpoch);
        }
    }

    function _deprecatedFrens(address _account) internal view returns (uint256 frens_) {
        Account storage account = s.accounts[_account];
        // this cannot underflow or overflow
        uint256 timePeriod = block.timestamp - account.lastFrensUpdate;
        frens_ = account.frens;
        // 86400 the number of seconds in 1 day
        // 100 frens are generated for each LP token over 24 hours
        frens_ += ((account.poolTokens * s.poolTokensRate) * timePeriod) / 24 hours;

        frens_ += ((account.ghstUsdcPoolTokens * s.ghstUsdcRate) * timePeriod) / 24 hours;
        // 1 fren is generated for each GHST over 24 hours
        frens_ += (account.ghst * timePeriod) / 24 hours;

        //Add in frens for GHST-WETH
        frens_ += ((account.ghstWethPoolTokens * s.ghstWethRate) * timePeriod) / 24 hours;
        return frens_;
    }

    function _validPool(address _poolContractAddress) internal view returns (bool) {
        //Validate that pool exists in current epoch
        bool validPool = false;
        Epoch memory epoch = s.epochs[s.currentEpoch];
        for (uint256 index = 0; index < epoch.supportedPools.length; index++) {
            address pool = epoch.supportedPools[index];
            if (_poolContractAddress == pool) {
                validPool = true;
                break;
            }
        }
        return validPool;
    }

    /***********************************|
   |   External Epoch Write Functions   |
   |__________________________________*/

    function migrateToV2(address[] memory _accounts) external {
        for (uint256 index = 0; index < _accounts.length; index++) {
            _migrateAndUpdateFrens(_accounts[index]);
        }
    }

    function initiateEpoch(PoolInput[] calldata _pools) external {
        LibDiamond.enforceIsContractOwner();
        require(s.epochs[0].supportedPools.length == 0, "StakingFacet: Can only be called on first epoch");
        require(_pools.length > 0, "StakingFacet: Pools length cannot be zero");

        Epoch storage firstEpoch = s.epochs[0];
        firstEpoch.beginTime = block.timestamp;

        //Update the pool rates for each pool in this epoch
        _addPools(_pools);
        emit EpochIncreased(0);
    }

    function updateRates(uint256 _currentEpoch, PoolInput[] calldata _newPools) external onlyRateManager {
        require(_newPools.length > 0, "StakingFacet: Pools length cannot be zero");
        //Used to prevent duplicate rate updates from happening in bad network conditions
        require(_currentEpoch == s.currentEpoch, "StakingFacet: Incorrect epoch given");

        //End current epoch
        Epoch storage epochNow = s.epochs[s.currentEpoch];
        epochNow.endTime = block.timestamp;

        //Increase epoch counter
        s.currentEpoch++;

        //Begin new epoch
        Epoch storage newEpoch = s.epochs[s.currentEpoch];
        newEpoch.beginTime = block.timestamp;

        //Add pools
        _addPools(_newPools);
        emit EpochIncreased(s.currentEpoch);
    }

    //Escape hatch mechanism callable by anyone to bump a user to a certain epoch.
    function bumpEpoch(address _account, uint256 _epoch) external {
        Account storage account = s.accounts[_account];
        require(account.hasMigrated == true, "StakingFacet: Can only bump migrated user");
        require(_epoch > account.userCurrentEpoch, "StakingFacet: Cannot bump to lower epoch");
        require(_epoch <= s.currentEpoch, "StakingFacet: Epoch must be lower than current epoch");
        _updateFrens(_account, _epoch);
    }

    /***********************************|
   |     Public Epoch Write Functions    |
   |__________________________________*/

    function stakeIntoPool(address _poolContractAddress, uint256 _amount) public {
        address sender = LibMeta.msgSender();

        require(_validPool(_poolContractAddress) == true, "StakingFacet: Pool is not valid in this epoch");

        require(IERC20(_poolContractAddress).balanceOf(sender) >= _amount, "StakingFacet: Insufficient token balance");

        _migrateOrUpdate(sender);

        //Credit the user's with their new LP token balance
        s.accounts[sender].accountStakedTokens[_poolContractAddress] += _amount;

        if (_poolContractAddress == s.ghstContract) {
            //Do nothing for original GHST contract
        } else if (_poolContractAddress == s.poolContract) {
            //Keep the GHST-QUICK staking token balance up to date
            s.accounts[sender].ghstStakingTokens += _amount;
            s.ghstStakingTokensTotalSupply += _amount;
            emit Transfer(address(0), sender, _amount);
        } else {
            //Use mintable for minting other stkGHST- tokens
            address stkTokenAddress = s.pools[_poolContractAddress].receiptToken;
            IERC20Mintable(stkTokenAddress).mint(sender, _amount);
        }

        //Transfer the LP tokens into the Diamond
        LibERC20.transferFrom(_poolContractAddress, sender, address(this), _amount);

        emit StakeInEpoch(sender, _poolContractAddress, s.currentEpoch, _amount);
    }

    function withdrawFromPool(address _poolContractAddress, uint256 _amount) public {
        address sender = LibMeta.msgSender();

        _migrateOrUpdate(sender);

        address receiptTokenAddress = s.pools[_poolContractAddress].receiptToken;
        uint256 stakedBalance = s.accounts[sender].accountStakedTokens[_poolContractAddress];

        //GHST does not have a receipt token
        if (receiptTokenAddress != address(0)) {
            require(IERC20(receiptTokenAddress).balanceOf(sender) >= _amount, "StakingFacet: Receipt token insufficient");
        }

        require(stakedBalance >= _amount, "StakingFacet: Can't withdraw more tokens than staked");

        //Reduce user balance of staked token
        s.accounts[sender].accountStakedTokens[_poolContractAddress] -= _amount;

        if (_poolContractAddress == s.ghstContract) {
            //Do nothing for GHST
        } else if (_poolContractAddress == s.poolContract) {
            s.accounts[sender].ghstStakingTokens -= _amount;
            s.ghstStakingTokensTotalSupply -= _amount;

            emit Transfer(sender, address(0), _amount);
        } else {
            IERC20Mintable(receiptTokenAddress).burn(sender, _amount);
        }

        //Transfer stake tokens from GHST diamond
        LibERC20.transfer(_poolContractAddress, sender, _amount);
        emit WithdrawInEpoch(sender, _poolContractAddress, s.currentEpoch, _amount);
    }

    /***********************************|
   |    Internal Epoch Write Functions   |
   |__________________________________*/

    function _migrateOrUpdate(address _account) internal {
        if (hasMigrated(_account)) {
            _updateFrens(_account, s.currentEpoch);
        } else {
            _migrateAndUpdateFrens(_account);
        }
    }

    function _addPools(PoolInput[] memory _pools) internal {
        for (uint256 index = 0; index < _pools.length; index++) {
            PoolInput memory _pool = _pools[index];
            address poolAddress = _pool._poolAddress;
            if (poolAddress != s.ghstContract) {
                require(_pool._poolReceiptToken != address(0), "StakingFacet: Pool must have receipt token");
            }

            //GHST token cannot have receipt token
            if (poolAddress == s.ghstContract) {
                require(_pool._poolReceiptToken == address(0), "StakingFacet: GHST token cannot have receipt token");
            }

            //Cannot introduce a new poolReceiptToken to an existing pool
            require(
                s.pools[poolAddress].receiptToken == address(0) || _pool._poolReceiptToken == s.pools[poolAddress].receiptToken,
                "StakingFacet: Cannot override poolReceiptToken"
            );

            s.pools[poolAddress].name = _pool._poolName;
            s.pools[poolAddress].receiptToken = _pool._poolReceiptToken;
            s.pools[poolAddress].epochPoolRate[s.currentEpoch] = _pool._rate;
            s.pools[poolAddress].url = _pool._poolUrl;

            s.epochs[s.currentEpoch].supportedPools.push(poolAddress);
            emit PoolAddedInEpoch(poolAddress, s.currentEpoch);
        }
    }

    function _updateFrens(address _sender, uint256 _epoch) internal {
        Account storage account = s.accounts[_sender];
        account.frens = frens(_sender);
        account.lastFrensUpdate = uint40(block.timestamp);

        //Bring this user to the specified epoch;
        s.accounts[_sender].userCurrentEpoch = _epoch;
    }

    function _migrateAndUpdateFrens(address _account) internal {
        require(s.accounts[_account].hasMigrated == false, "StakingFacet: Already migrated");
        uint256 ghst_ = s.accounts[_account].ghst;
        uint256 poolTokens_ = s.accounts[_account].poolTokens;
        uint256 ghstUsdcPoolToken_ = s.accounts[_account].ghstUsdcPoolTokens;
        uint256 ghstWethPoolToken_ = s.accounts[_account].ghstWethPoolTokens;

        //Set balances for all of the V1 pools
        s.accounts[_account].accountStakedTokens[s.ghstContract] = ghst_;
        s.accounts[_account].accountStakedTokens[s.poolContract] = poolTokens_;
        s.accounts[_account].accountStakedTokens[s.ghstUsdcPoolToken] = ghstUsdcPoolToken_;
        s.accounts[_account].accountStakedTokens[s.ghstWethPoolToken] = ghstWethPoolToken_;

        //Update FRENS with last balance
        _updateFrens(_account, s.currentEpoch);
        s.accounts[_account].hasMigrated = true;

        emit UserMigrated(_account);
    }

    /***********************************|
   |     Deprecated Write Functions     |
   |__________________________________*/

    function stakeGhst(uint256 _ghstValue) external {
        stakeIntoPool(s.ghstContract, _ghstValue);
    }

    function stakePoolTokens(uint256 _poolTokens) external {
        stakeIntoPool(s.poolContract, _poolTokens);
    }

    function stakeGhstUsdcPoolTokens(uint256 _poolTokens) external {
        stakeIntoPool(s.ghstUsdcPoolToken, _poolTokens);
    }

    function stakeGhstWethPoolTokens(uint256 _poolTokens) external {
        stakeIntoPool(s.ghstWethPoolToken, _poolTokens);
    }

    function withdrawGhstStake(uint256 _ghstValue) external {
        withdrawFromPool(s.ghstContract, _ghstValue);
    }

    function withdrawPoolStake(uint256 _poolTokens) external {
        withdrawFromPool(s.poolContract, _poolTokens);
    }

    function withdrawGhstUsdcPoolStake(uint256 _poolTokens) external {
        withdrawFromPool(s.ghstUsdcPoolToken, _poolTokens);
    }

    function withdrawGhstWethPoolStake(uint256 _poolTokens) external {
        withdrawFromPool(s.ghstWethPoolToken, _poolTokens);
    }

    /***********************************|
   |      Deprecated Read Functions     |
   |__________________________________*/

    function getGhstUsdcPoolToken() external view returns (address) {
        return s.ghstUsdcPoolToken;
    }

    function getStkGhstUsdcToken() external view returns (address) {
        return s.stkGhstUsdcToken;
    }

    function getGhstWethPoolToken() external view returns (address) {
        return s.ghstWethPoolToken;
    }

    function getStkGhstWethToken() external view returns (address) {
        return s.stkGhstWethToken;
    }

    function staked(address _account)
        external
        view
        returns (
            uint256 ghst_,
            uint256 poolTokens_,
            uint256 ghstUsdcPoolToken_,
            uint256 ghstWethPoolToken_
        )
    {
        if (hasMigrated(_account)) {
            ghst_ = s.accounts[_account].accountStakedTokens[s.ghstContract];
            poolTokens_ = s.accounts[_account].accountStakedTokens[s.poolContract];
            ghstUsdcPoolToken_ = s.accounts[_account].accountStakedTokens[s.ghstUsdcPoolToken];
            ghstWethPoolToken_ = s.accounts[_account].accountStakedTokens[s.ghstWethPoolToken];
        } else {
            ghst_ = s.accounts[_account].ghst;
            poolTokens_ = s.accounts[_account].poolTokens;
            ghstUsdcPoolToken_ = s.accounts[_account].ghstUsdcPoolTokens;
            ghstWethPoolToken_ = s.accounts[_account].ghstWethPoolTokens;
        }
    }

    /***********************************|
   |           Ticket Functions          |
   |__________________________________*/

    function claimTickets(uint256[] calldata _ids, uint256[] calldata _values) external {
        require(_ids.length == _values.length, "Staking: _ids not the same length as _values");

        address sender = LibMeta.msgSender();
        _updateFrens(sender, s.currentEpoch);
        uint256 frensBal = s.accounts[sender].frens;
        for (uint256 i; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            require(id < 7, "Staking: Ticket not found");
            uint256 l_ticketCost = ticketCost(id);
            uint256 cost = l_ticketCost * value;
            require(cost / l_ticketCost == value, "Staking: multiplication overflow");
            require(frensBal >= cost, "Staking: Not enough frens points");
            frensBal -= cost;
            s.tickets[id].accountBalances[sender] += value;
            s.tickets[id].totalSupply += uint96(value);
        }
        s.accounts[sender].frens = frensBal;
        emit TransferBatch(sender, address(0), sender, _ids, _values);
        uint256 size;
        assembly {
            size := extcodesize(sender)
        }
        if (size > 0) {
            require(
                ERC1155_BATCH_ACCEPTED == IERC1155TokenReceiver(sender).onERC1155BatchReceived(sender, address(0), _ids, _values, new bytes(0)),
                "Staking: Ticket transfer rejected/failed"
            );
        }
    }

    function convertTickets(uint256[] calldata _ids, uint256[] calldata _values) external {
        require(_ids.length == _values.length, "Staking: _ids not the same length as _values");
        address sender = LibMeta.msgSender();
        uint256 totalCost;
        uint256 dropTicketId = 6;
        uint256 dropTicketCost = ticketCost(dropTicketId);
        for (uint256 i; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            // Can't convert drop ticket itself to another drop ticket
            require(id != dropTicketId, "Staking: Cannot convert Drop Ticket");
            uint256 l_ticketCost = ticketCost(id);
            uint256 cost = l_ticketCost * value;
            require(cost / l_ticketCost == value, "Staking: multiplication overflow");
            require(s.tickets[id].accountBalances[sender] >= value, "Staking: Not enough Ticket balance");
            totalCost += cost;

            s.tickets[id].accountBalances[sender] -= value;
            s.tickets[id].totalSupply -= uint96(value);
        }
        require(totalCost > 0, "Staking: Invalid Ticket Ids and Values");
        require(totalCost % dropTicketCost == 0, "Staking: Cannot partially convert Drop Tickets");

        emit TransferBatch(sender, sender, address(0), _ids, _values);

        uint256 newDropTickets = totalCost / dropTicketCost;
        uint256[] memory eventTicketIds = new uint256[](1);
        eventTicketIds[0] = dropTicketId;

        uint256[] memory eventTicketValues = new uint256[](1);
        eventTicketValues[0] = newDropTickets;

        s.tickets[dropTicketId].accountBalances[sender] += newDropTickets;
        s.tickets[dropTicketId].totalSupply += uint96(newDropTickets);

        if (s.aavegotchiDiamond != address(0)) {
            IERC1155Marketplace(s.aavegotchiDiamond).updateBatchERC1155Listing(address(this), _ids, sender);
        }
        emit TransferBatch(sender, address(0), sender, eventTicketIds, eventTicketValues);

        uint256 size;
        assembly {
            size := extcodesize(sender)
        }
        if (size > 0) {
            require(
                ERC1155_BATCH_ACCEPTED ==
                    IERC1155TokenReceiver(sender).onERC1155BatchReceived(sender, address(0), eventTicketIds, eventTicketValues, new bytes(0)),
                "Staking: Ticket transfer rejected/failed"
            );
        }
    }

    function ticketCost(uint256 _id) public pure returns (uint256 _frensCost) {
        if (_id == 0) {
            _frensCost = 50e18;
        } else if (_id == 1) {
            _frensCost = 250e18;
        } else if (_id == 2) {
            _frensCost = 500e18;
        } else if (_id == 3) {
            _frensCost = 2_500e18;
        } else if (_id == 4) {
            _frensCost = 10_000e18;
        } else if (_id == 5) {
            _frensCost = 50_000e18;
        } else if (_id == 6) {
            _frensCost = 10_000e18;
        } else {
            revert("Staking: _id does not exist");
        }
    }

    /***********************************|
   |       Rate Manager Functions        |
   |__________________________________*/

    modifier onlyRateManager() {
        require(isRateManager(msg.sender), "StakingFacet: Must be rate manager");
        _;
    }

    function isRateManager(address account) public view returns (bool) {
        return s.rateManagers[account];
    }

    function addRateManagers(address[] calldata rateManagers_) external {
        LibDiamond.enforceIsContractOwner();
        for (uint256 index = 0; index < rateManagers_.length; index++) {
            s.rateManagers[rateManagers_[index]] = true;
            emit RateManagerAdded(rateManagers_[index]);
        }
    }

    function removeRateManagers(address[] calldata rateManagers_) external {
        LibDiamond.enforceIsContractOwner();
        for (uint256 index = 0; index < rateManagers_.length; index++) {
            s.rateManagers[rateManagers_[index]] = false;
            emit RateManagerRemoved(rateManagers_[index]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

struct Account {
    // spender => amount
    mapping(address => uint256) ghstStakingTokensAllowances;
    mapping(address => bool) ticketsApproved;
    uint96 ghst;
    uint40 lastFrensUpdate;
    uint256 ghstStakingTokens;
    uint256 poolTokens;
    uint256 frens;
    uint256 ghstUsdcPoolTokens;
    uint256 ghstWethPoolTokens;
    //New
    bool hasMigrated;
    uint256 userCurrentEpoch;
    mapping(address => uint256) accountStakedTokens;
}

struct Ticket {
    // user address => balance
    mapping(address => uint256) accountBalances;
    uint96 totalSupply;
}

struct Epoch {
    uint256 beginTime;
    uint256 endTime;
    address[] supportedPools;
}

struct Pool {
    address receiptToken;
    string name;
    string url;
    mapping(uint256 => uint256) epochPoolRate;
}

struct AppStorage {
    mapping(address => Account) accounts;
    mapping(uint256 => Ticket) tickets;
    address ghstContract;
    address poolContract;
    string ticketsBaseUri;
    uint256 ghstStakingTokensTotalSupply;
    uint256 poolTokensRate;
    uint256 ghstUsdcRate;
    address ghstUsdcPoolToken;
    address stkGhstUsdcToken;
    bytes32 domainSeparator;
    mapping(address => uint256) metaNonces;
    address aavegotchiDiamond;
    mapping(address => bool) rateManagers;
    //new
    address ghstWethPoolToken; //token address of GHST-WETH LP
    address stkGhstWethToken; //token address of the stkGHST-WETH receipt token
    uint256 ghstWethRate; //the FRENS rate for GHST-WETH stakers
    //New for Epoch
    uint256 currentEpoch;
    mapping(address => Pool) pools;
    mapping(uint256 => Epoch) epochs;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of Diamond facet.
* Uses the diamond-2 version 1.3.4 implementation:
* https://github.com/mudgen/diamond-2
*
* This is gas optimized by reducing storage reads and storage writes.
* This code is as complex as it is to reduce gas costs.
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // owner of the contract
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    modifier onlyOwner {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
        _;
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount % 8 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount / 8];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount % 8 > 0) {
            ds.selectorSlots[selectorCount / 8] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            require(_newFacetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount % 8) * 32;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount / 8] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            require(_newFacetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            uint256 selectorSlotCount = _selectorCount / 8;
            uint256 selectorInSlotIndex = (_selectorCount % 8) - 1;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex * 32));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount / 8;
                    oldSelectorInSlotPosition = (oldSelectorCount % 8) * 32;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
                selectorInSlotIndex--;
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex + 1;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (success == false) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Nick Mudge
*
/******************************************************************************/

import "../interfaces/IERC20.sol";

library LibERC20 {
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: Address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
        handleReturn(success, result);
    }

    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: Address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
        handleReturn(success, result);
    }

    function handleReturn(bool _success, bytes memory _result) internal pure {
        if (_success) {
            if (_result.length > 0) {
                require(abi.decode(_result, (bool)), "LibERC20: contract call returned false");
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                revert(string(_result));
            } else {
                revert("LibERC20: contract call reverted");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}