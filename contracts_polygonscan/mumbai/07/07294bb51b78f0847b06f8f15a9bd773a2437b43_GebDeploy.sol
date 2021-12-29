/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// Verified using https://dapp.tools

// hevm: flattened sources of /nix/store/3kgg4vdxd3j6d12khdjg0jp7pg92lngx-h20-deploy/dapp/h20-deploy/src/GebDeploy.sol

pragma solidity =0.6.7 >=0.6.7;

////// /nix/store/9fna9h5xch481dxrqk780arvaafkmrh0-ds-auth/dapp/ds-auth/src/auth.sol
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

/* pragma solidity >=0.6.7; */

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

abstract contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        virtual
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        virtual
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) virtual internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

////// /nix/store/nfck33idmaryffxbga2lwc5vxsaxizc6-ds-pause/dapp/ds-pause/src/pause.sol
// Copyright (C) 2019 David Terry <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

/* import {DSAuth, DSAuthority} from "ds-auth/auth.sol"; */

contract DSPause is DSAuth {
    // --- Admin ---
    modifier isDelayed { require(msg.sender == address(proxy), "ds-pause-undelayed-call"); _; }

    function setOwner(address owner_) override public isDelayed {
        owner = owner_;
        emit LogSetOwner(owner);
    }
    function setAuthority(DSAuthority authority_) override public isDelayed {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }
    function setDelay(uint delay_) public isDelayed {
        require(delay_ <= MAX_DELAY, "ds-pause-delay-not-within-bounds");
        delay = delay_;
        emit SetDelay(delay_);
    }

    // --- Math ---
    function addition(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x, "ds-pause-add-overflow");
    }
    function subtract(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-pause-sub-underflow");
    }

    // --- Data ---
    mapping (bytes32 => bool)  public scheduledTransactions;
    mapping (bytes32 => bool)  public scheduledTransactionsDataHashes;
    DSPauseProxy_1               public proxy;
    uint                       public delay;
    uint                       public currentlyScheduledTransactions;

    uint256                    public constant EXEC_TIME                = 3 days;
    uint256                    public constant maxScheduledTransactions = 10;
    uint256                    public constant MAX_DELAY                = 28 days;
    bytes32                    public constant DS_PAUSE_TYPE            = bytes32("BASIC");

    // --- Events ---
    event SetDelay(uint256 delay);
    event ScheduleTransaction(address sender, address usr, bytes32 codeHash, bytes parameters, uint earliestExecutionTime);
    event AbandonTransaction(address sender, address usr, bytes32 codeHash, bytes parameters, uint earliestExecutionTime);
    event ExecuteTransaction(address sender, address usr, bytes32 codeHash, bytes parameters, uint earliestExecutionTime);
    event AttachTransactionDescription(address sender, address usr, bytes32 codeHash, bytes parameters, uint earliestExecutionTime, string description);

    // --- Init ---
    constructor(uint delay_, address owner_, DSAuthority authority_) public {
        require(delay_ <= MAX_DELAY, "ds-pause-delay-not-within-bounds");
        delay = delay_;
        owner = owner_;
        authority = authority_;
        proxy = new DSPauseProxy_1();
    }

    // --- Util ---
    function getTransactionDataHash(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime)
        public pure
        returns (bytes32)
    {
        return keccak256(abi.encode(usr, codeHash, parameters, earliestExecutionTime));
    }
    function getTransactionDataHash(address usr, bytes32 codeHash, bytes memory parameters)
        public pure
        returns (bytes32)
    {
        return keccak256(abi.encode(usr, codeHash, parameters));
    }

    function getExtCodeHash(address usr)
        internal view
        returns (bytes32 codeHash)
    {
        assembly { codeHash := extcodehash(usr) }
    }

    // --- Operations ---
    function scheduleTransaction(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime)
        public auth
    {
        schedule(usr, codeHash, parameters, earliestExecutionTime);
    }
    function scheduleTransaction(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime, string memory description)
        public auth
    {
        schedule(usr, codeHash, parameters, earliestExecutionTime);
        emit AttachTransactionDescription(msg.sender, usr, codeHash, parameters, earliestExecutionTime, description);
    }
    function schedule(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime) internal {
        require(!scheduledTransactions[getTransactionDataHash(usr, codeHash, parameters, earliestExecutionTime)], "ds-pause-already-scheduled");
        require(subtract(earliestExecutionTime, now) <= MAX_DELAY, "ds-pause-delay-not-within-bounds");
        require(earliestExecutionTime >= addition(now, delay), "ds-pause-delay-not-respected");
        require(currentlyScheduledTransactions < maxScheduledTransactions, "ds-pause-too-many-scheduled");
        bytes32 dataHash = getTransactionDataHash(usr, codeHash, parameters);
        require(!scheduledTransactionsDataHashes[dataHash], "ds-pause-cannot-schedule-same-tx-twice");
        currentlyScheduledTransactions = addition(currentlyScheduledTransactions, 1);
        scheduledTransactions[getTransactionDataHash(usr, codeHash, parameters, earliestExecutionTime)] = true;
        scheduledTransactionsDataHashes[dataHash] = true;
        emit ScheduleTransaction(msg.sender, usr, codeHash, parameters, earliestExecutionTime);
    }
    function attachTransactionDescription(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime, string memory description)
        public auth
    {
        require(scheduledTransactions[getTransactionDataHash(usr, codeHash, parameters, earliestExecutionTime)], "ds-pause-unplotted-plan");
        emit AttachTransactionDescription(msg.sender, usr, codeHash, parameters, earliestExecutionTime, description);
    }
    function abandonTransaction(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime)
        public auth
    {
        require(scheduledTransactions[getTransactionDataHash(usr, codeHash, parameters, earliestExecutionTime)], "ds-pause-unplotted-plan");
        scheduledTransactions[getTransactionDataHash(usr, codeHash, parameters, earliestExecutionTime)] = false;
        scheduledTransactionsDataHashes[getTransactionDataHash(usr, codeHash, parameters)] = false;
        currentlyScheduledTransactions = subtract(currentlyScheduledTransactions, 1);
        emit AbandonTransaction(msg.sender, usr, codeHash, parameters, earliestExecutionTime);
    }
    function executeTransaction(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime)
        public
        returns (bytes memory out)
    {
        require(scheduledTransactions[getTransactionDataHash(usr, codeHash, parameters, earliestExecutionTime)], "ds-pause-unplotted-plan");
        require(getExtCodeHash(usr) == codeHash, "ds-pause-wrong-codehash");
        require(now >= earliestExecutionTime, "ds-pause-premature-exec");
        require(now < addition(earliestExecutionTime, EXEC_TIME), "ds-pause-expired-tx");

        scheduledTransactions[getTransactionDataHash(usr, codeHash, parameters, earliestExecutionTime)] = false;
        scheduledTransactionsDataHashes[getTransactionDataHash(usr, codeHash, parameters)] = false;
        currentlyScheduledTransactions = subtract(currentlyScheduledTransactions, 1);

        emit ExecuteTransaction(msg.sender, usr, codeHash, parameters, earliestExecutionTime);

        out = proxy.executeTransaction(usr, parameters);
        require(proxy.owner() == address(this), "ds-pause-illegal-storage-change");
    }
}

// scheduled txs are executed in an isolated storage context to protect the pause from
// malicious storage modification during plan execution
contract DSPauseProxy_1 {
    address public owner;
    modifier isAuthorized { require(msg.sender == owner, "ds-pause-proxy-unauthorized"); _; }
    constructor() public { owner = msg.sender; }

    function executeTransaction(address usr, bytes memory parameters)
        public isAuthorized
        returns (bytes memory out)
    {
        bool ok;
        (ok, out) = usr.delegatecall(parameters);
        require(ok, "ds-pause-delegatecall-error");
    }
}

////// /nix/store/nfck33idmaryffxbga2lwc5vxsaxizc6-ds-pause/dapp/ds-pause/src/protest-pause.sol
// Copyright (C) 2019 David Terry <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

/* import {DSAuth, DSAuthority} from "ds-auth/auth.sol"; */

contract DSProtestPause is DSAuth {
    // --- Admin ---
    modifier isDelayed { require(msg.sender == address(proxy), "ds-protest-pause-undelayed-call"); _; }

    function setOwner(address owner_) override public isDelayed {
        owner = owner_;
        emit LogSetOwner(owner);
    }
    function setAuthority(DSAuthority authority_) override public isDelayed {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }
    function setProtester(address protester_) external isDelayed {
        protester = protester_;
        emit SetProtester(address(protester));
    }
    function setDelay(uint delay_) external isDelayed {
        require(delay_ <= MAX_DELAY, "ds-protest-pause-delay-not-within-bounds");
        delay = delay_;
        emit SetDelay(delay_);
    }
    function setDelayMultiplier(uint multiplier_) external isDelayed {
        require(both(multiplier_ >= 1, multiplier_ <= MAX_DELAY_MULTIPLIER), "ds-protest-pause-multiplier-exceeds-bounds");
        delayMultiplier = multiplier_;
        emit ChangeDelayMultiplier(multiplier_);
    }

    // --- Structs ---
    struct TransactionDelay {
        bool protested;
        uint scheduleTime;
        uint totalDelay;
    }

    // --- Data ---
    mapping (bytes32 => bool)             public scheduledTransactions;
    mapping (bytes32 => TransactionDelay) internal transactionDelays;

    DSPauseProxy_2     public proxy;
    address          public protester;

    uint             public delay;
    uint             public delayMultiplier = 1;
    uint             public currentlyScheduledTransactions;
    uint             public deploymentTime;
    uint             public protesterLifetime;

    uint256 constant public EXEC_TIME                = 3 days;
    uint256 constant public MAX_DELAY                = 28 days;
    uint256 constant public maxScheduledTransactions = 10;
    uint256 constant public protestEnd               = 500;                 // a tx can be protested against if max 1/2 of the time until earliest execution has passed
    uint256 constant public MAX_DELAY_MULTIPLIER     = 3;
    bytes32 constant public DS_PAUSE_TYPE            = bytes32("PROTEST");

    // --- Events ---
    event SetDelay(uint256 delay);
    event SetProtester(address protester);
    event ChangeDelayMultiplier(uint256 multiplier);
    event ScheduleTransaction(address sender, address usr, bytes32 codeHash, bytes parameters, uint earliestExecutionTime);
    event AbandonTransaction(address sender, address usr, bytes32 codeHash, bytes parameters, uint earliestExecutionTime);
    event ProtestAgainstTransaction(address sender, address usr, bytes32 codeHash, bytes parameters, uint totalDelay);
    event ExecuteTransaction(address sender, address usr, bytes32 codeHash, bytes parameters, uint earliestExecutionTime);
    event AttachTransactionDescription(address sender, address usr, bytes32 codeHash, bytes parameters, uint earliestExecutionTime, string description);

    // --- Init ---
    constructor(uint protesterLifetime_, uint delay_, address owner_, DSAuthority authority_) public {
        require(delay_ <= MAX_DELAY, "ds-protest-pause-delay-not-within-bounds");
        delay = delay_;
        owner = owner_;
        authority = authority_;
        deploymentTime = now;
        protesterLifetime = protesterLifetime_;
        proxy = new DSPauseProxy_2();
    }

    // --- Math ---
    function addition(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x, "ds-protest-pause-add-overflow");
    }
    function subtract(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-protest-pause-sub-underflow");
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-protest-pause-mul-invalid");
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Util ---
    function getTransactionDataHash(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime)
        public pure
        returns (bytes32)
    {
        return keccak256(abi.encode(usr, codeHash, parameters, earliestExecutionTime));
    }
    function getTransactionDataHash(address usr, bytes32 codeHash, bytes memory parameters)
        public pure
        returns (bytes32)
    {
        return keccak256(abi.encode(usr, codeHash, parameters));
    }
    function getExtCodeHash(address usr)
        internal view
        returns (bytes32 codeHash)
    {
        assembly { codeHash := extcodehash(usr) }
    }
    function protestWindowAvailable(address usr, bytes32 codeHash, bytes calldata parameters) external view returns (bool) {
        bytes32 partiallyHashedTx = getTransactionDataHash(usr, codeHash, parameters);
        (bool protested, ,) = getTransactionDelays(partiallyHashedTx);
        if (protested) return false;
        return (
          now < protestDeadline(partiallyHashedTx)
        );
    }
    function protestWindowAvailable(bytes32 txHash) external view returns (bool) {
        (bool protested, ,) = getTransactionDelays(txHash);
        if (protested) return false;
        return (
          now < protestDeadline(txHash)
        );
    }
    function timeUntilProposalProtestDeadline(address usr, bytes32 codeHash, bytes calldata parameters) external view returns (uint256) {
        bytes32 partiallyHashedTx = getTransactionDataHash(usr, codeHash, parameters);
        (bool protested, ,) = getTransactionDelays(partiallyHashedTx);
        if (protested) return 0;
        uint protestDeadline = protestDeadline(partiallyHashedTx);
        if (now >= protestDeadline) return 0;
        return subtract(protestDeadline, now);
    }
    function timeUntilProposalProtestDeadline(bytes32 txHash) external view returns (uint256) {
        (bool protested, ,) = getTransactionDelays(txHash);
        if (protested) return 0;
        uint protestDeadline = protestDeadline(txHash);
        if (now >= protestDeadline) return 0;
        return subtract(protestDeadline, now);
    }
    function protestDeadline(bytes32 txHash) internal view returns (uint256) {
        return addition(transactionDelays[txHash].scheduleTime, (multiply(transactionDelays[txHash].totalDelay, protestEnd) / 1000));
    }

    // --- Operations ---
    function scheduleTransaction(address usr, bytes32 codeHash, bytes calldata parameters, uint earliestExecutionTime)
        external auth
    {
        schedule(usr, codeHash, parameters, earliestExecutionTime);
    }
    function scheduleTransaction(address usr, bytes32 codeHash, bytes calldata parameters, uint earliestExecutionTime, string calldata description)
        external auth
    {
        schedule(usr, codeHash, parameters, earliestExecutionTime);
        emit AttachTransactionDescription(msg.sender, usr, codeHash, parameters, earliestExecutionTime, description);
    }
    function attachTransactionDescription(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime, string memory description)
        public auth
    {
        bytes32 partiallyHashedTx = getTransactionDataHash(usr, codeHash, parameters);
        require(transactionDelays[partiallyHashedTx].scheduleTime > 0, "ds-protest-pause-cannot-attach-for-null");
        emit AttachTransactionDescription(msg.sender, usr, codeHash, parameters, earliestExecutionTime, description);
    }
    function protestAgainstTransaction(address usr, bytes32 codeHash, bytes calldata parameters)
        external
    {
        require(msg.sender == protester, "ds-protest-pause-sender-not-protester");
        require(addition(protesterLifetime, deploymentTime) > now, "ds-protest-pause-protester-lifetime-passed");
        bytes32 partiallyHashedTx = getTransactionDataHash(usr, codeHash, parameters);
        require(transactionDelays[partiallyHashedTx].scheduleTime > 0, "ds-protest-pause-null-inexistent-transaction");
        require(!transactionDelays[partiallyHashedTx].protested, "ds-protest-pause-tx-already-protested");
        require(
          now < protestDeadline(partiallyHashedTx),
          "ds-protest-pause-exceed-protest-deadline"
        );

        transactionDelays[partiallyHashedTx].protested = true;

        uint multipliedDelay = multiply(delay, delayMultiplier);
        if (multipliedDelay > MAX_DELAY) {
          multipliedDelay = MAX_DELAY;
        }
        if (transactionDelays[partiallyHashedTx].totalDelay < multipliedDelay) {
          transactionDelays[partiallyHashedTx].totalDelay = multipliedDelay;
        }

        emit ProtestAgainstTransaction(msg.sender, usr, codeHash, parameters, transactionDelays[partiallyHashedTx].totalDelay);
    }
    function abandonTransaction(address usr, bytes32 codeHash, bytes calldata parameters, uint earliestExecutionTime)
        external auth
    {
        bytes32 fullyHashedTx = getTransactionDataHash(usr, codeHash, parameters, earliestExecutionTime);
        bytes32 partiallyHashedTx = getTransactionDataHash(usr, codeHash, parameters);
        require(transactionDelays[partiallyHashedTx].scheduleTime > 0, "ds-protest-pause-cannot-abandon-null");
        scheduledTransactions[fullyHashedTx] = false;
        delete(transactionDelays[partiallyHashedTx]);
        currentlyScheduledTransactions = subtract(currentlyScheduledTransactions, 1);
        emit AbandonTransaction(msg.sender, usr, codeHash, parameters, earliestExecutionTime);
    }
    function executeTransaction(address usr, bytes32 codeHash, bytes calldata parameters, uint earliestExecutionTime)
        external
        returns (bytes memory out)
    {
        bytes32 fullyHashedTx = getTransactionDataHash(usr, codeHash, parameters, earliestExecutionTime);
        bytes32 partiallyHashedTx = getTransactionDataHash(usr, codeHash, parameters);
        uint executionStart = addition(transactionDelays[partiallyHashedTx].scheduleTime, transactionDelays[partiallyHashedTx].totalDelay);
        require(scheduledTransactions[fullyHashedTx], "ds-protest-pause-inexistent-transaction");
        require(getExtCodeHash(usr) == codeHash, "ds-protest-pause-wrong-codehash");
        require(now >= executionStart, "ds-protest-pause-premature-exec");
        require(now < addition(executionStart, EXEC_TIME), "ds-protest-pause-expired-tx");

        scheduledTransactions[fullyHashedTx] = false;
        delete(transactionDelays[partiallyHashedTx]);
        currentlyScheduledTransactions = subtract(currentlyScheduledTransactions, 1);

        emit ExecuteTransaction(msg.sender, usr, codeHash, parameters, earliestExecutionTime);

        out = proxy.executeTransaction(usr, parameters);
        require(proxy.owner() == address(this), "ds-protest-pause-illegal-storage-change");
    }

    // --- Internal ---
    function schedule(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime) internal {
        require(subtract(earliestExecutionTime, now) <= MAX_DELAY, "ds-protest-pause-delay-not-within-bounds");
        require(earliestExecutionTime >= addition(now, delay), "ds-protest-pause-delay-not-respected");
        bytes32 fullyHashedTx = getTransactionDataHash(usr, codeHash, parameters, earliestExecutionTime);
        bytes32 partiallyHashedTx = getTransactionDataHash(usr, codeHash, parameters);
        require(transactionDelays[partiallyHashedTx].scheduleTime == 0, "ds-protest-pause-cannot-schedule-same-tx-twice");
        require(currentlyScheduledTransactions < maxScheduledTransactions, "ds-protest-pause-too-many-scheduled");
        currentlyScheduledTransactions = addition(currentlyScheduledTransactions, 1);
        scheduledTransactions[fullyHashedTx] = true;
        transactionDelays[partiallyHashedTx] = TransactionDelay(false, now, subtract(earliestExecutionTime, now));
        emit ScheduleTransaction(msg.sender, usr, codeHash, parameters, earliestExecutionTime);
    }

    // --- Getters ---
    function getTransactionDelays(address usr, bytes32 codeHash, bytes calldata parameters) external view returns (bool, uint256, uint256) {
        bytes32 hashedTx = getTransactionDataHash(usr, codeHash, parameters);
        return (
          transactionDelays[hashedTx].protested,
          transactionDelays[hashedTx].scheduleTime,
          transactionDelays[hashedTx].totalDelay
        );
    }
    function getTransactionDelays(bytes32 txHash) public view returns (bool, uint256, uint256) {
        return (
          transactionDelays[txHash].protested,
          transactionDelays[txHash].scheduleTime,
          transactionDelays[txHash].totalDelay
        );
    }
}

// scheduled txs are executed in an isolated storage context to protect the pause from
// malicious storage modification during plan execution
contract DSPauseProxy_2 {
    address public owner;
    modifier isAuthorized { require(msg.sender == owner, "ds-protest-pause-proxy-unauthorized"); _; }
    constructor() public { owner = msg.sender; }

    function executeTransaction(address usr, bytes memory parameters)
        public isAuthorized
        returns (bytes memory out)
    {
        bool ok;
        (ok, out) = usr.delegatecall(parameters);
        require(ok, "ds-protest-pause-delegatecall-error");
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/AccountingEngine.sol
/// AccountingEngine.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

abstract contract DebtAuctionHouseLike {
    function startAuction(address incomeReceiver, uint256 amountToSell, uint256 initialBid) virtual public returns (uint256);
    function protocolToken() virtual public view returns (address);
    function disableContract() virtual external;
    function contractEnabled() virtual public view returns (uint256);
}

abstract contract SurplusAuctionHouseLike {
    function startAuction(uint256, uint256) virtual public returns (uint256);
    function protocolToken() virtual public view returns (address);
    function disableContract() virtual external;
    function contractEnabled() virtual public view returns (uint256);
}

abstract contract SAFEEngineLike_2 {
    function coinBalance(address) virtual public view returns (uint256);
    function debtBalance(address) virtual public view returns (uint256);
    function settleDebt(uint256) virtual external;
    function transferInternalCoins(address,address,uint256) virtual external;
    function approveSAFEModification(address) virtual external;
    function denySAFEModification(address) virtual external;
}

abstract contract SystemStakingPoolLike {
    function canPrintProtocolTokens() virtual public view returns (bool);
}

abstract contract ProtocolTokenAuthorityLike {
    function authorizedAccounts(address) virtual public view returns (uint256);
}

contract AccountingEngine {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        require(contractEnabled == 1, "AccountingEngine/contract-not-enabled");
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "AccountingEngine/account-not-authorized");
        _;
    }

    // --- Data ---
    // SAFE database
    SAFEEngineLike_2             public safeEngine;
    // Contract that handles auctions for surplus stability fees (sell coins for protocol tokens that are then burned)
    SurplusAuctionHouseLike    public surplusAuctionHouse;
    /**
      Contract that handles auctions for debt that couldn't be covered by collateral
      auctions (it prints protocol tokens in exchange for coins that will settle the debt)
    **/
    DebtAuctionHouseLike       public debtAuctionHouse;
    // Permissions registry for who can burn and mint protocol tokens
    ProtocolTokenAuthorityLike public protocolTokenAuthority;
    // Staking pool for protocol tokens
    SystemStakingPoolLike      public systemStakingPool;
    // Contract that auctions extra surplus after settlement is triggered
    address                    public postSettlementSurplusDrain;
    // Address that receives extra surplus transfers
    address                    public extraSurplusReceiver;

    /**
      Debt blocks that need to be covered by auctions. There is a delay to pop debt from
      this queue and either settle it with surplus that came from collateral auctions or with debt auctions
      that print protocol tokens
    **/
    mapping (uint256 => uint256) public debtQueue;          // [unix timestamp => rad]
    // Addresses that popped debt out of the queue
    mapping (uint256 => address) public debtPoppers;        // [unix timestamp => address]
    // Total debt in the queue (that the system tries to cover with collateral auctions)
    uint256 public totalQueuedDebt;                         // [rad]
    // Total debt being auctioned in DebtAuctionHouse (printing protocol tokens for coins that will settle the debt)
    uint256 public totalOnAuctionDebt;                      // [rad]
    // When the last surplus auction was triggered
    uint256 public lastSurplusAuctionTime;                  // [unix timestamp]
    // When the last surplus transfer was triggered
    uint256 public lastSurplusTransferTime;                 // [unix timestamp]
    // Delay between surplus auctions
    uint256 public surplusAuctionDelay;                     // [seconds]
    // Delay between extra surplus transfers
    uint256 public surplusTransferDelay;                    // [seconds]
    // Delay after which debt can be popped from debtQueue
    uint256 public popDebtDelay;                            // [seconds]
    // Amount of protocol tokens to be minted post-auction
    uint256 public initialDebtAuctionMintedTokens;          // [wad]
    // Amount of debt sold in one debt auction (initial coin bid for initialDebtAuctionMintedTokens protocol tokens)
    uint256 public debtAuctionBidSize;                      // [rad]

    // Whether the system transfers surplus instead of auctioning it
    uint256 public extraSurplusIsTransferred;
    // Amount of surplus stability fees sold in one surplus auction
    uint256 public surplusAuctionAmountToSell;              // [rad]
    // Amount of extra surplus to transfer
    uint256 public surplusTransferAmount;                   // [rad]
    // Amount of stability fees that need to accrue in this contract before any surplus auction can start
    uint256 public surplusBuffer;                           // [rad]

    // Time to wait (post settlement) until any remaining surplus can be transferred to the settlement auctioneer
    uint256 public disableCooldown;                         // [seconds]
    // When the contract was disabled
    uint256 public disableTimestamp;                        // [unix timestamp]

    // Whether this contract is enabled or not
    uint256 public contractEnabled;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 indexed parameter, uint256 data);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event PushDebtToQueue(uint256 indexed timestamp, uint256 debtQueueBlock, uint256 totalQueuedDebt);
    event PopDebtFromQueue(uint256 indexed timestamp, uint256 debtQueueBlock, uint256 totalQueuedDebt);
    event SettleDebt(uint256 rad, uint256 coinBalance, uint256 debtBalance);
    event CancelAuctionedDebtWithSurplus(uint rad, uint256 totalOnAuctionDebt, uint256 coinBalance, uint256 debtBalance);
    event AuctionDebt(uint256 indexed id, uint256 totalOnAuctionDebt, uint256 debtBalance);
    event AuctionSurplus(uint256 indexed id, uint256 lastSurplusAuctionTime, uint256 coinBalance);
    event DisableContract(uint256 disableTimestamp, uint256 disableCooldown, uint256 coinBalance, uint256 debtBalance);
    event TransferPostSettlementSurplus(address postSettlementSurplusDrain, uint256 coinBalance, uint256 debtBalance);
    event TransferExtraSurplus(address indexed extraSurplusReceiver, uint256 lastSurplusAuctionTime, uint256 coinBalance);

    // --- Init ---
    constructor(
      address safeEngine_,
      address surplusAuctionHouse_,
      address debtAuctionHouse_
    ) public {
        authorizedAccounts[msg.sender] = 1;

        safeEngine                     = SAFEEngineLike_2(safeEngine_);
        surplusAuctionHouse            = SurplusAuctionHouseLike(surplusAuctionHouse_);
        debtAuctionHouse               = DebtAuctionHouseLike(debtAuctionHouse_);

        safeEngine.approveSAFEModification(surplusAuctionHouse_);

        lastSurplusAuctionTime         = now;
        lastSurplusTransferTime        = now;
        contractEnabled                = 1;

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "AccountingEngine/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "AccountingEngine/sub-underflow");
    }
    function minimum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    // --- Administration ---
    /**
     * @notice Modify an uint256 param
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "surplusAuctionDelay") surplusAuctionDelay = data;
        else if (parameter == "surplusTransferDelay") surplusTransferDelay = data;
        else if (parameter == "popDebtDelay") popDebtDelay = data;
        else if (parameter == "surplusAuctionAmountToSell") surplusAuctionAmountToSell = data;
        else if (parameter == "surplusTransferAmount") surplusTransferAmount = data;
        else if (parameter == "extraSurplusIsTransferred") extraSurplusIsTransferred = data;
        else if (parameter == "debtAuctionBidSize") debtAuctionBidSize = data;
        else if (parameter == "initialDebtAuctionMintedTokens") initialDebtAuctionMintedTokens = data;
        else if (parameter == "surplusBuffer") surplusBuffer = data;
        else if (parameter == "lastSurplusTransferTime") {
          require(data > now, "AccountingEngine/invalid-lastSurplusTransferTime");
          lastSurplusTransferTime = data;
        }
        else if (parameter == "lastSurplusAuctionTime") {
          require(data > now, "AccountingEngine/invalid-lastSurplusAuctionTime");
          lastSurplusAuctionTime = data;
        }
        else if (parameter == "disableCooldown") disableCooldown = data;
        else revert("AccountingEngine/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify an address param
     * @param parameter The name of the parameter
     * @param data New address for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "surplusAuctionHouse") {
            safeEngine.denySAFEModification(address(surplusAuctionHouse));
            surplusAuctionHouse = SurplusAuctionHouseLike(data);
            safeEngine.approveSAFEModification(data);
        }
        else if (parameter == "systemStakingPool") {
            systemStakingPool = SystemStakingPoolLike(data);
            systemStakingPool.canPrintProtocolTokens();
        }
        else if (parameter == "debtAuctionHouse") debtAuctionHouse = DebtAuctionHouseLike(data);
        else if (parameter == "postSettlementSurplusDrain") postSettlementSurplusDrain = data;
        else if (parameter == "protocolTokenAuthority") protocolTokenAuthority = ProtocolTokenAuthorityLike(data);
        else if (parameter == "extraSurplusReceiver") extraSurplusReceiver = data;
        else revert("AccountingEngine/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Getters ---
    /*
    * @notice Returns the amount of bad debt that is not in the debtQueue and is not currently handled by debt auctions
    */
    function unqueuedUnauctionedDebt() public view returns (uint256) {
        return subtract(subtract(safeEngine.debtBalance(address(this)), totalQueuedDebt), totalOnAuctionDebt);
    }
    /*
    * @notify Returns a bool indicating whether the AccountingEngine can currently print protocol tokens using debt auctions
    */
    function canPrintProtocolTokens() public view returns (bool) {
        if (address(systemStakingPool) == address(0)) return true;
        try systemStakingPool.canPrintProtocolTokens() returns (bool ok) {
          return ok;
        } catch(bytes memory) {
          return true;
        }
    }

    // --- Debt Queueing ---
    /**
     * @notice Push bad debt into a queue
     * @dev Debt is locked in a queue to give the system enough time to auction collateral
     *      and gather surplus
     * @param debtBlock Amount of debt to push
     */
    function pushDebtToQueue(uint256 debtBlock) external isAuthorized {
        debtQueue[now] = addition(debtQueue[now], debtBlock);
        totalQueuedDebt = addition(totalQueuedDebt, debtBlock);
        emit PushDebtToQueue(now, debtQueue[now], totalQueuedDebt);
    }
    /**
     * @notice Pop a block of bad debt from the debt queue
     * @dev A block of debt can be popped from the queue after popDebtDelay seconds have passed since it was
     *         added there
     * @param debtBlockTimestamp Timestamp of the block of debt that should be popped out
     */
    function popDebtFromQueue(uint256 debtBlockTimestamp) external {
        require(addition(debtBlockTimestamp, popDebtDelay) <= now, "AccountingEngine/pop-debt-delay-not-passed");
        require(debtQueue[debtBlockTimestamp] > 0, "AccountingEngine/null-debt-block");
        totalQueuedDebt = subtract(totalQueuedDebt, debtQueue[debtBlockTimestamp]);
        debtPoppers[debtBlockTimestamp] = msg.sender;
        emit PopDebtFromQueue(now, debtQueue[debtBlockTimestamp], totalQueuedDebt);
        debtQueue[debtBlockTimestamp] = 0;
    }

    // Debt settlement
    /**
     * @notice Destroy an equal amount of coins and bad debt
     * @dev We can only destroy debt that is not locked in the queue and also not in a debt auction
     * @param rad Amount of coins/debt to destroy (number with 45 decimals)
    **/
    function settleDebt(uint256 rad) public {
        require(rad <= safeEngine.coinBalance(address(this)), "AccountingEngine/insufficient-surplus");
        require(rad <= unqueuedUnauctionedDebt(), "AccountingEngine/insufficient-debt");
        safeEngine.settleDebt(rad);
        emit SettleDebt(rad, safeEngine.coinBalance(address(this)), safeEngine.debtBalance(address(this)));
    }
    /**
     * @notice Use surplus coins to destroy debt that was in a debt auction
     * @param rad Amount of coins/debt to destroy (number with 45 decimals)
    **/
    function cancelAuctionedDebtWithSurplus(uint256 rad) external {
        require(rad <= totalOnAuctionDebt, "AccountingEngine/not-enough-debt-being-auctioned");
        require(rad <= safeEngine.coinBalance(address(this)), "AccountingEngine/insufficient-surplus");
        totalOnAuctionDebt = subtract(totalOnAuctionDebt, rad);
        safeEngine.settleDebt(rad);
        emit CancelAuctionedDebtWithSurplus(rad, totalOnAuctionDebt, safeEngine.coinBalance(address(this)), safeEngine.debtBalance(address(this)));
    }

    // Debt auction
    /**
     * @notice Start a debt auction (print protocol tokens in exchange for coins so that the
     *         system can be recapitalized)
     * @dev We can only auction debt that is not already being auctioned and is not locked in the debt queue
    **/
    function auctionDebt() external returns (uint256 id) {
        require(debtAuctionBidSize <= unqueuedUnauctionedDebt(), "AccountingEngine/insufficient-debt");
        settleDebt(safeEngine.coinBalance(address(this)));
        require(safeEngine.coinBalance(address(this)) == 0, "AccountingEngine/surplus-not-zero");
        require(debtAuctionHouse.protocolToken() != address(0), "AccountingEngine/debt-auction-house-null-prot");
        require(protocolTokenAuthority.authorizedAccounts(address(debtAuctionHouse)) == 1, "AccountingEngine/debt-auction-house-cannot-print-prot");
        require(canPrintProtocolTokens(), "AccountingEngine/staking-pool-denies-printing");
        totalOnAuctionDebt = addition(totalOnAuctionDebt, debtAuctionBidSize);
        id = debtAuctionHouse.startAuction(address(this), initialDebtAuctionMintedTokens, debtAuctionBidSize);
        emit AuctionDebt(id, totalOnAuctionDebt, safeEngine.debtBalance(address(this)));
    }

    // Surplus auction
    /**
     * @notice Start a surplus auction
     * @dev We can only auction surplus if we wait at least 'surplusAuctionDelay' seconds since the last
     *      surplus auction trigger, if we keep enough surplus in the buffer and if there is no bad debt left to settle
    **/
    function auctionSurplus() external returns (uint256 id) {
        require(extraSurplusIsTransferred != 1, "AccountingEngine/surplus-transfer-no-auction");
        require(surplusAuctionAmountToSell > 0, "AccountingEngine/null-amount-to-auction");
        settleDebt(unqueuedUnauctionedDebt());
        require(
          now >= addition(lastSurplusAuctionTime, surplusAuctionDelay),
          "AccountingEngine/surplus-auction-delay-not-passed"
        );
        require(
          safeEngine.coinBalance(address(this)) >=
          addition(addition(safeEngine.debtBalance(address(this)), surplusAuctionAmountToSell), surplusBuffer),
          "AccountingEngine/insufficient-surplus"
        );
        require(
          unqueuedUnauctionedDebt() == 0,
          "AccountingEngine/debt-not-zero"
        );
        require(surplusAuctionHouse.protocolToken() != address(0), "AccountingEngine/surplus-auction-house-null-prot");
        lastSurplusAuctionTime  = now;
        lastSurplusTransferTime = now;
        id = surplusAuctionHouse.startAuction(surplusAuctionAmountToSell, 0);
        emit AuctionSurplus(id, lastSurplusAuctionTime, safeEngine.coinBalance(address(this)));
    }

    // Extra surplus transfers/surplus auction alternative
    /**
     * @notice Send surplus to an address as an alternative to surplus auctions
     * @dev We can only transfer surplus if we wait at least 'surplusTransferDelay' seconds since the last
     *      transfer, if we keep enough surplus in the buffer and if there is no bad debt left to settle
    **/
    function transferExtraSurplus() external {
        require(extraSurplusIsTransferred == 1, "AccountingEngine/surplus-auction-not-transfer");
        require(extraSurplusReceiver != address(0), "AccountingEngine/null-surplus-receiver");
        require(surplusTransferAmount > 0, "AccountingEngine/null-amount-to-transfer");
        settleDebt(unqueuedUnauctionedDebt());
        require(
          now >= addition(lastSurplusTransferTime, surplusTransferDelay),
          "AccountingEngine/surplus-transfer-delay-not-passed"
        );
        require(
          safeEngine.coinBalance(address(this)) >=
          addition(addition(safeEngine.debtBalance(address(this)), surplusTransferAmount), surplusBuffer),
          "AccountingEngine/insufficient-surplus"
        );
        require(
          unqueuedUnauctionedDebt() == 0,
          "AccountingEngine/debt-not-zero"
        );
        lastSurplusTransferTime = now;
        lastSurplusAuctionTime  = now;
        safeEngine.transferInternalCoins(address(this), extraSurplusReceiver, surplusTransferAmount);
        emit TransferExtraSurplus(extraSurplusReceiver, lastSurplusTransferTime, safeEngine.coinBalance(address(this)));
    }

    /**
     * @notice Disable this contract (normally called by Global Settlement)
     * @dev When it's being disabled, the contract will record the current timestamp. Afterwards,
     *      the contract tries to settle as much debt as possible (if there's any) with any surplus that's
     *      left in the AccountingEngine
    **/
    function disableContract() external isAuthorized {
        require(contractEnabled == 1, "AccountingEngine/contract-not-enabled");

        contractEnabled = 0;
        totalQueuedDebt = 0;
        totalOnAuctionDebt = 0;

        disableTimestamp = now;

        surplusAuctionHouse.disableContract();
        debtAuctionHouse.disableContract();

        safeEngine.settleDebt(minimum(safeEngine.coinBalance(address(this)), safeEngine.debtBalance(address(this))));

        emit DisableContract(disableTimestamp, disableCooldown, safeEngine.coinBalance(address(this)), safeEngine.debtBalance(address(this)));
    }
    /**
     * @notice Transfer any remaining surplus after the disable cooldown has passed. Meant to be a backup in case GlobalSettlement.processSAFE
               has a bug, governance doesn't have power over the system and there's still surplus left in the AccountingEngine
               which then blocks GlobalSettlement.setOutstandingCoinSupply.
     * @dev Transfer any remaining surplus after disableCooldown seconds have passed since disabling the contract
    **/
    function transferPostSettlementSurplus() external {
        require(contractEnabled == 0, "AccountingEngine/still-enabled");
        require(addition(disableTimestamp, disableCooldown) <= now, "AccountingEngine/cooldown-not-passed");
        safeEngine.settleDebt(minimum(safeEngine.coinBalance(address(this)), safeEngine.debtBalance(address(this))));
        safeEngine.transferInternalCoins(address(this), postSettlementSurplusDrain, safeEngine.coinBalance(address(this)));
        emit TransferPostSettlementSurplus(
          postSettlementSurplusDrain,
          safeEngine.coinBalance(address(this)),
          safeEngine.debtBalance(address(this))
        );
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/BasicTokenAdapters.sol
/// BasicTokenAdapters.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

abstract contract CollateralLike_2 {
    function decimals() virtual public view returns (uint256);
    function transfer(address,uint256) virtual public returns (bool);
    function transferFrom(address,address,uint256) virtual public returns (bool);
}

abstract contract DSTokenLike_2 {
    function mint(address,uint256) virtual external;
    function burn(address,uint256) virtual external;
}

abstract contract SAFEEngineLike_3 {
    function modifyCollateralBalance(bytes32,address,int256) virtual external;
    function transferInternalCoins(address,address,uint256) virtual external;
}

/*
    Here we provide *adapters* to connect the SAFEEngine to arbitrary external
    token implementations, creating a bounded context for the SAFEEngine. The
    adapters here are provided as working examples:
      - `BasicCollateralJoin`: For well behaved ERC20 tokens, with simple transfer semantics.
      - `ETHJoin`: For native Ether.
      - `CoinJoin`: For connecting internal coin balances to an external
                   `Coin` implementation.
    In practice, adapter implementations will be varied and specific to
    individual collateral types, accounting for different transfer
    semantics and token standards.
    Adapters need to implement two basic methods:
      - `join`: enter collateral into the system
      - `exit`: remove collateral from the system
*/

contract BasicCollateralJoin {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "BasicCollateralJoin/account-not-authorized");
        _;
    }

    // SAFE database
    SAFEEngineLike_3  public safeEngine;
    // Collateral type name
    bytes32        public collateralType;
    // Actual collateral token contract
    CollateralLike_2 public collateral;
    // How many decimals the collateral token has
    uint256        public decimals;
    // Whether this adapter contract is enabled or not
    uint256        public contractEnabled;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address account, uint256 wad);
    event Exit(address sender, address account, uint256 wad);

    constructor(address safeEngine_, bytes32 collateralType_, address collateral_) public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;
        safeEngine      = SAFEEngineLike_3(safeEngine_);
        collateralType  = collateralType_;
        collateral      = CollateralLike_2(collateral_);
        decimals        = collateral.decimals();
        require(decimals == 18, "BasicCollateralJoin/non-18-decimals");
        emit AddAuthorization(msg.sender);
    }
    /**
     * @notice Disable this contract
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }
    /**
    * @notice Join collateral in the system
    * @dev This function locks collateral in the adapter and creates a 'representation' of
    *      the locked collateral inside the system. This adapter assumes that the collateral
    *      has 18 decimals
    * @param account Account from which we transferFrom collateral and add it in the system
    * @param wad Amount of collateral to transfer in the system (represented as a number with 18 decimals)
    **/
    function join(address account, uint256 wad) external {
        require(contractEnabled == 1, "BasicCollateralJoin/contract-not-enabled");
        require(int256(wad) >= 0, "BasicCollateralJoin/overflow");
        safeEngine.modifyCollateralBalance(collateralType, account, int256(wad));
        require(collateral.transferFrom(msg.sender, address(this), wad), "BasicCollateralJoin/failed-transfer");
        emit Join(msg.sender, account, wad);
    }
    /**
    * @notice Exit collateral from the system
    * @dev This function destroys the collateral representation from inside the system
    *      and exits the collateral from this adapter. The adapter assumes that the collateral
    *      has 18 decimals
    * @param account Account to which we transfer the collateral
    * @param wad Amount of collateral to transfer to 'account' (represented as a number with 18 decimals)
    **/
    function exit(address account, uint256 wad) external {
        require(wad <= 2 ** 255, "BasicCollateralJoin/overflow");
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int256(wad));
        require(collateral.transfer(account, wad), "BasicCollateralJoin/failed-transfer");
        emit Exit(msg.sender, account, wad);
    }
}

contract ETHJoin {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call a restricted function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "ETHJoin/account-not-authorized");
        _;
    }

    // SAFE database
    SAFEEngineLike_3 public safeEngine;
    // Collateral type name
    bytes32       public collateralType;
    // Whether this contract is enabled or not
    uint256       public contractEnabled;
    // Number of decimals ETH has
    uint256       public decimals;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address account, uint256 wad);
    event Exit(address sender, address account, uint256 wad);

    constructor(address safeEngine_, bytes32 collateralType_) public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled                = 1;
        safeEngine                     = SAFEEngineLike_3(safeEngine_);
        collateralType                 = collateralType_;
        decimals                       = 18;
        emit AddAuthorization(msg.sender);
    }
    /**
     * @notice Disable this contract
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }
    /**
    * @notice Join ETH in the system
    * @param account Account that will receive the ETH representation inside the system
    **/
    function join(address account) external payable {
        require(contractEnabled == 1, "ETHJoin/contract-not-enabled");
        require(int256(msg.value) >= 0, "ETHJoin/overflow");
        safeEngine.modifyCollateralBalance(collateralType, account, int256(msg.value));
        emit Join(msg.sender, account, msg.value);
    }
    /**
    * @notice Exit ETH from the system
    * @param account Account that will receive the ETH representation inside the system
    **/
    function exit(address payable account, uint256 wad) external {
        require(int256(wad) >= 0, "ETHJoin/overflow");
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int256(wad));
        emit Exit(msg.sender, account, wad);
        account.transfer(wad);
    }
}

contract CoinJoin {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CoinJoin/account-not-authorized");
        _;
    }

    // SAFE database
    SAFEEngineLike_3 public safeEngine;
    // Coin created by the system; this is the external, ERC-20 representation, not the internal 'coinBalance'
    DSTokenLike_2    public systemCoin;
    // Whether this contract is enabled or not
    uint256        public contractEnabled;
    // Number of decimals the system coin has
    uint256        public decimals;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address account, uint256 wad);
    event Exit(address sender, address account, uint256 wad);

    constructor(address safeEngine_, address systemCoin_) public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled                = 1;
        safeEngine                     = SAFEEngineLike_3(safeEngine_);
        systemCoin                     = DSTokenLike_2(systemCoin_);
        decimals                       = 18;
        emit AddAuthorization(msg.sender);
    }
    /**
     * @notice Disable this contract
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }
    uint256 constant RAY = 10 ** 27;
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "CoinJoin/mul-overflow");
    }
    /**
    * @notice Join system coins in the system
    * @dev Exited coins have 18 decimals but inside the system they have 45 (rad) decimals.
           When we join, the amount (wad) is multiplied by 10**27 (ray)
    * @param account Account that will receive the joined coins
    * @param wad Amount of external coins to join (18 decimal number)
    **/
    function join(address account, uint256 wad) external {
        safeEngine.transferInternalCoins(address(this), account, multiply(RAY, wad));
        systemCoin.burn(msg.sender, wad);
        emit Join(msg.sender, account, wad);
    }
    /**
    * @notice Exit system coins from the system and inside 'Coin.sol'
    * @dev Inside the system, coins have 45 (rad) decimals but outside of it they have 18 decimals (wad).
           When we exit, we specify a wad amount of coins and then the contract automatically multiplies
           wad by 10**27 to move the correct 45 decimal coin amount to this adapter
    * @param account Account that will receive the exited coins
    * @param wad Amount of internal coins to join (18 decimal number that will be multiplied by ray)
    **/
    function exit(address account, uint256 wad) external {
        require(contractEnabled == 1, "CoinJoin/contract-not-enabled");
        safeEngine.transferInternalCoins(msg.sender, address(this), multiply(RAY, wad));
        systemCoin.mint(account, wad);
        emit Exit(msg.sender, account, wad);
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/Coin.sol
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

contract Coin {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "Coin/account-not-authorized");
        _;
    }

    // --- ERC20 Data ---
    // The name of this coin
    string  public name;
    // The symbol of this coin
    string  public symbol;
    // The version of this Coin contract
    string  public version = "1";
    // The number of decimals that this coin has
    uint8   public constant decimals = 18;

    // The id of the chain where this coin was deployed
    uint256 public chainId;
    // The total supply of this coin
    uint256 public totalSupply;

    // Mapping of coin balances
    mapping (address => uint256)                      public balanceOf;
    // Mapping of allowances
    mapping (address => mapping (address => uint256)) public allowance;
    // Mapping of nonces used for permits
    mapping (address => uint256)                      public nonces;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Approval(address indexed src, address indexed guy, uint256 amount);
    event Transfer(address indexed src, address indexed dst, uint256 amount);

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Coin/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Coin/sub-underflow");
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 chainId_
      ) public {
        authorizedAccounts[msg.sender] = 1;
        name          = name_;
        symbol        = symbol_;
        chainId       = chainId_;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
        emit AddAuthorization(msg.sender);
    }

    // --- Token ---
    /*
    * @notice Transfer coins to another address
    * @param dst The address to transfer coins to
    * @param amount The amount of coins to transfer
    */
    function transfer(address dst, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, dst, amount);
    }
    /*
    * @notice Transfer coins from a source address to a destination address (if allowed)
    * @param src The address from which to transfer coins
    * @param dst The address that will receive the coins
    * @param amount The amount of coins to transfer
    */
    function transferFrom(address src, address dst, uint256 amount)
        public returns (bool)
    {
        require(dst != address(0), "Coin/null-dst");
        require(dst != address(this), "Coin/dst-cannot-be-this-contract");
        require(balanceOf[src] >= amount, "Coin/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= amount, "Coin/insufficient-allowance");
            allowance[src][msg.sender] = subtract(allowance[src][msg.sender], amount);
        }
        balanceOf[src] = subtract(balanceOf[src], amount);
        balanceOf[dst] = addition(balanceOf[dst], amount);
        emit Transfer(src, dst, amount);
        return true;
    }
    /*
    * @notice Mint new coins
    * @param usr The address for which to mint coins
    * @param amount The amount of coins to mint
    */
    function mint(address usr, uint256 amount) external isAuthorized {
        balanceOf[usr] = addition(balanceOf[usr], amount);
        totalSupply    = addition(totalSupply, amount);
        emit Transfer(address(0), usr, amount);
    }
    /*
    * @notice Burn coins from an address
    * @param usr The address that will have its coins burned
    * @param amount The amount of coins to burn
    */
    function burn(address usr, uint256 amount) external {
        require(balanceOf[usr] >= amount, "Coin/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint256(-1)) {
            require(allowance[usr][msg.sender] >= amount, "Coin/insufficient-allowance");
            allowance[usr][msg.sender] = subtract(allowance[usr][msg.sender], amount);
        }
        balanceOf[usr] = subtract(balanceOf[usr], amount);
        totalSupply    = subtract(totalSupply, amount);
        emit Transfer(usr, address(0), amount);
    }
    /*
    * @notice Change the transfer/burn allowance that another address has on your behalf
    * @param usr The address whose allowance is changed
    * @param amount The new total allowance for the usr
    */
    function approve(address usr, uint256 amount) external returns (bool) {
        allowance[msg.sender][usr] = amount;
        emit Approval(msg.sender, usr, amount);
        return true;
    }

    // --- Alias ---
    /*
    * @notice Send coins to another address
    * @param usr The address to send tokens to
    * @param amount The amount of coins to send
    */
    function push(address usr, uint256 amount) external {
        transferFrom(msg.sender, usr, amount);
    }
    /*
    * @notice Transfer coins from another address to your address
    * @param usr The address to take coins from
    * @param amount The amount of coins to take from the usr
    */
    function pull(address usr, uint256 amount) external {
        transferFrom(usr, msg.sender, amount);
    }
    /*
    * @notice Transfer coins from another address to a destination address (if allowed)
    * @param src The address to transfer coins from
    * @param dst The address to transfer coins to
    * @param amount The amount of coins to transfer
    */
    function move(address src, address dst, uint256 amount) external {
        transferFrom(src, dst, amount);
    }

    // --- Approve by signature ---
    /*
    * @notice Submit a signed message that modifies an allowance for a specific address
    */
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "Coin/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Coin/invalid-permit");
        require(expiry == 0 || now <= expiry, "Coin/permit-expired");
        require(nonce == nonces[holder]++, "Coin/invalid-nonce");
        uint256 wad = allowed ? uint256(-1) : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/CoinSavingsAccount.sol
/// CoinSavingsAccount.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

/*
   "Savings Coin" is obtained when the core coin created by the protocol
   is deposited into this contract. Each "Savings Coin" accrues interest
   at the "Savings Rate". This contract does not implement a user tradeable token
   and is intended to be used with adapters.
         --- `save` your `coin` in the `savings account` ---
   - `savingsRate`: the Savings Rate
   - `savings`: user balance of Savings Coins
   - `deposit`: start saving some coins
   - `withdraw`: withdraw coins from the savings account
   - `updateAccumulatedRate`: perform rate collection
*/

abstract contract SAFEEngineLike_4 {
    function transferInternalCoins(address,address,uint256) virtual external;
    function createUnbackedDebt(address,address,uint256) virtual external;
}

contract CoinSavingsAccount {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CoinSavingsAccount/account-not-authorized");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event DisableContract();
    event Deposit(address indexed usr, uint256 balance, uint256 totalSavings);
    event Withdraw(address indexed usr, uint256 balance, uint256 totalSavings);
    event UpdateAccumulatedRate(uint256 newAccumulatedRate, uint256 coinAmount);

    // --- Data ---
    // Amount of coins each user has deposited
    mapping (address => uint256) public savings;

    // Total amount of coins deposited
    uint256 public totalSavings;
    // Per second savings rate
    uint256 public savingsRate;
    // An index representing total accumulated rates
    uint256 public accumulatedRate;

    // SAFE database
    SAFEEngineLike_4 public safeEngine;
    // Accounting engine
    address public accountingEngine;
    // When accumulated rates were last updated
    uint256 public latestUpdateTime;
    // Whether this contract is enabled or not
    uint256 public contractEnabled;

    // --- Init ---
    constructor(address safeEngine_) public {
        authorizedAccounts[msg.sender] = 1;
        safeEngine = SAFEEngineLike_4(safeEngine_);
        savingsRate = RAY;
        accumulatedRate = RAY;
        latestUpdateTime = now;
        contractEnabled = 1;
    }

    // --- Math ---
    uint256 constant RAY = 10 ** 27;
    function rpower(uint256 x, uint256 n, uint256 base) internal pure returns (uint256 z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
    function rmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = multiply(x, y) / RAY;
    }
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "CoinSavingsAccount/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "CoinSavingsAccount/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "CoinSavingsAccount/mul-overflow");
    }

    // --- Administration ---
    /**
     * @notice Modify an uint256 parameter
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        require(contractEnabled == 1, "CoinSavingsAccount/contract-not-enabled");
        require(now == latestUpdateTime, "CoinSavingsAccount/accumulation-time-not-updated");
        if (parameter == "savingsRate") savingsRate = data;
        else revert("CoinSavingsAccount/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify the address of the accountingEngine
     * @param parameter The name of the parameter modified
     * @param addr New value for the parameter
     */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        if (parameter == "accountingEngine") accountingEngine = addr;
        else revert("CoinSavingsAccount/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }
    /**
     * @notice Disable this contract (usually called by Global Settlement)
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        savingsRate = RAY;
        emit DisableContract();
    }

    // --- Savings Rate Accumulation ---
    /**
     * @notice Update the accumulated rate index
     * @dev We return early if 'latestUpdateTime' is greater than or equal to block.timestamp. When the savings
            rate is positive, we create unbacked debt for the accountingEngine and issue new coins for
            this contract
     */
    function updateAccumulatedRate() public returns (uint256 newAccumulatedRate) {
        if (now <= latestUpdateTime) return accumulatedRate;
        newAccumulatedRate = rmultiply(rpower(savingsRate, subtract(now, latestUpdateTime), RAY), accumulatedRate);
        uint accumulatedRate_ = subtract(newAccumulatedRate, accumulatedRate);
        accumulatedRate = newAccumulatedRate;
        latestUpdateTime = now;
        safeEngine.createUnbackedDebt(address(accountingEngine), address(this), multiply(totalSavings, accumulatedRate_));
        emit UpdateAccumulatedRate(newAccumulatedRate, multiply(totalSavings, accumulatedRate_));
    }
    /**
     * @notice Get the next value of 'accumulatedRate' without actually updating the variable
     */
    function nextAccumulatedRate() external view returns (uint256) {
        if (now <= latestUpdateTime) return accumulatedRate;
        return rmultiply(rpower(savingsRate, subtract(now, latestUpdateTime), RAY), accumulatedRate);
    }

    // --- Savings Management ---
    /**
     * @notice Deposit coins in the savings account
     * @param wad Amount of coins to deposit (expressed as an 18 decimal number). 'wad' will be multiplied by
              'accumulatedRate' (27 decimals) to result in a correct amount of internal coins to transfer
     */
    function deposit(uint256 wad) external {
        updateAccumulatedRate();
        require(now == latestUpdateTime, "CoinSavingsAccount/accumulation-time-not-updated");
        savings[msg.sender] = addition(savings[msg.sender], wad);
        totalSavings        = addition(totalSavings, wad);
        safeEngine.transferInternalCoins(msg.sender, address(this), multiply(accumulatedRate, wad));
        emit Deposit(msg.sender, savings[msg.sender], totalSavings);
    }
    /**
     * @notice Withdraw coins (alongside any interest accrued) from the savings account
     * @param wad Amount of coins to withdraw (expressed as an 18 decimal number). 'wad' will be multiplied by
              'accumulatedRate' (27 decimals) to result in a correct amount of internal coins to transfer
     */
    function withdraw(uint256 wad) external {
        updateAccumulatedRate();
        savings[msg.sender] = subtract(savings[msg.sender], wad);
        totalSavings        = subtract(totalSavings, wad);
        safeEngine.transferInternalCoins(address(this), msg.sender, multiply(accumulatedRate, wad));
        emit Withdraw(msg.sender, savings[msg.sender], totalSavings);
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/CollateralAuctionHouse.sol
/// EnglishCollateralAuctionHouse.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

abstract contract SAFEEngineLike_5 {
    function transferInternalCoins(address,address,uint256) virtual external;
    function transferCollateral(bytes32,address,address,uint256) virtual external;
}
abstract contract OracleRelayerLike_1 {
    function redemptionPrice() virtual public returns (uint256);
}
abstract contract OracleLike_1 {
    function priceSource() virtual public view returns (address);
    function getResultWithValidity() virtual public view returns (uint256, bool);
}
abstract contract LiquidationEngineLike_1 {
    function removeCoinsFromAuction(uint256) virtual public;
}

/*
   This thing lets you (English) auction some collateral for a given amount of system coins
*/

contract EnglishCollateralAuctionHouse {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "EnglishCollateralAuctionHouse/account-not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        // Bid size (how many coins are offered per collateral sold)
        uint256 bidAmount;                                                                                            // [rad]
        // How much collateral is sold in an auction
        uint256 amountToSell;                                                                                         // [wad]
        // Who the high bidder is
        address highBidder;
        // When the latest bid expires and the auction can be settled
        uint48  bidExpiry;                                                                                            // [unix epoch time]
        // Hard deadline for the auction after which no more bids can be placed
        uint48  auctionDeadline;                                                                                      // [unix epoch time]
        // Who (which SAFE) receives leftover collateral that is not sold in the auction; usually the liquidated SAFE
        address forgoneCollateralReceiver;
        // Who receives the coins raised from the auction; usually the accounting engine
        address auctionIncomeRecipient;
        // Total/max amount of coins to raise
        uint256 amountToRaise;                                                                                        // [rad]
    }

    // Bid data for each separate auction
    mapping (uint256 => Bid) public bids;

    // SAFE database
    SAFEEngineLike_5 public safeEngine;
    // Collateral type name
    bytes32       public collateralType;

    uint256  constant ONE = 1.00E18;                                                                                  // [wad]
    // Minimum bid increase compared to the last bid in order to take the new one in consideration
    uint256  public   bidIncrease = 1.05E18;                                                                          // [wad]
    // How long the auction lasts after a new bid is submitted
    uint48   public   bidDuration = 3 hours;                                                                          // [seconds]
    // Total length of the auction
    uint48   public   totalAuctionLength = 2 days;                                                                    // [seconds]
    // Number of auctions started up until now
    uint256  public   auctionsStarted = 0;

    LiquidationEngineLike_1 public liquidationEngine;

    bytes32 public constant AUCTION_HOUSE_TYPE = bytes32("COLLATERAL");
    bytes32 public constant AUCTION_TYPE       = bytes32("ENGLISH");

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event StartAuction(
        uint256 id,
        uint256 auctionsStarted,
        uint256 amountToSell,
        uint256 initialBid,
        uint256 indexed amountToRaise,
        address indexed forgoneCollateralReceiver,
        address indexed auctionIncomeRecipient,
        uint256 auctionDeadline
    );
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event RestartAuction(uint256 indexed id, uint256 auctionDeadline);
    event IncreaseBidSize(uint256 indexed id, address highBidder, uint256 amountToBuy, uint256 rad, uint256 bidExpiry);
    event DecreaseSoldAmount(uint256 indexed id, address highBidder, uint256 amountToBuy, uint256 rad, uint256 bidExpiry);
    event SettleAuction(uint256 indexed id);
    event TerminateAuctionPrematurely(uint256 indexed id, address sender, uint256 bidAmount, uint256 collateralAmount);

    // --- Init ---
    constructor(address safeEngine_, address liquidationEngine_, bytes32 collateralType_) public {
        safeEngine = SAFEEngineLike_5(safeEngine_);
        liquidationEngine = LiquidationEngineLike_1(liquidationEngine_);
        collateralType = collateralType_;
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addUint48(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x, "EnglishCollateralAuctionHouse/add-uint48-overflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "EnglishCollateralAuctionHouse/mul-overflow");
    }
    uint256 constant WAD = 10 ** 18;
    function wmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = multiply(x, y) / WAD;
    }
    uint256 constant RAY = 10 ** 27;
    function rdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "EnglishCollateralAuctionHouse/division-by-zero");
        z = multiply(x, RAY) / y;
    }

    // --- Admin ---
    /**
     * @notice Modify an uint256 parameter
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "bidIncrease") bidIncrease = data;
        else if (parameter == "bidDuration") bidDuration = uint48(data);
        else if (parameter == "totalAuctionLength") totalAuctionLength = uint48(data);
        else revert("EnglishCollateralAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify an address parameter
     * @param parameter The name of the contract whose address we modify
     * @param data New contract address
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "liquidationEngine") liquidationEngine = LiquidationEngineLike_1(data);
        else revert("EnglishCollateralAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Auction ---
    /**
     * @notice Start a new collateral auction
     * @param forgoneCollateralReceiver Address that receives leftover collateral that is not auctioned
     * @param auctionIncomeRecipient Address that receives the amount of system coins raised by the auction
     * @param amountToRaise Total amount of coins to raise (rad)
     * @param amountToSell Total amount of collateral available to sell (wad)
     * @param initialBid Initial bid size (usually zero in this implementation) (rad)
     */
    function startAuction(
        address forgoneCollateralReceiver,
        address auctionIncomeRecipient,
        uint256 amountToRaise,
        uint256 amountToSell,
        uint256 initialBid
    ) public isAuthorized returns (uint256 id)
    {
        require(auctionsStarted < uint256(-1), "EnglishCollateralAuctionHouse/overflow");
        require(amountToSell > 0, "EnglishCollateralAuctionHouse/null-amount-sold");
        id = ++auctionsStarted;

        bids[id].bidAmount = initialBid;
        bids[id].amountToSell = amountToSell;
        bids[id].highBidder = msg.sender;
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);
        bids[id].forgoneCollateralReceiver = forgoneCollateralReceiver;
        bids[id].auctionIncomeRecipient = auctionIncomeRecipient;
        bids[id].amountToRaise = amountToRaise;

        safeEngine.transferCollateral(collateralType, msg.sender, address(this), amountToSell);

        emit StartAuction(
          id,
          auctionsStarted,
          amountToSell,
          initialBid,
          amountToRaise,
          forgoneCollateralReceiver,
          auctionIncomeRecipient,
          bids[id].auctionDeadline
        );
    }
    /**
     * @notice Restart an auction if no bids were submitted for it
     * @param id ID of the auction to restart
     */
    function restartAuction(uint256 id) external {
        require(bids[id].auctionDeadline < now, "EnglishCollateralAuctionHouse/not-finished");
        require(bids[id].bidExpiry == 0, "EnglishCollateralAuctionHouse/bid-already-placed");
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);
        emit RestartAuction(id, bids[id].auctionDeadline);
    }
    /**
     * @notice First auction phase: submit a higher bid for the same amount of collateral
     * @param id ID of the auction you want to submit the bid for
     * @param amountToBuy Amount of collateral to buy (wad)
     * @param rad New bid submitted (rad)
     */
    function increaseBidSize(uint256 id, uint256 amountToBuy, uint256 rad) external {
        require(bids[id].highBidder != address(0), "EnglishCollateralAuctionHouse/high-bidder-not-set");
        require(bids[id].bidExpiry > now || bids[id].bidExpiry == 0, "EnglishCollateralAuctionHouse/bid-already-expired");
        require(bids[id].auctionDeadline > now, "EnglishCollateralAuctionHouse/auction-already-expired");

        require(amountToBuy == bids[id].amountToSell, "EnglishCollateralAuctionHouse/amounts-not-matching");
        require(rad <= bids[id].amountToRaise, "EnglishCollateralAuctionHouse/higher-than-amount-to-raise");
        require(rad >  bids[id].bidAmount, "EnglishCollateralAuctionHouse/new-bid-not-higher");
        require(multiply(rad, ONE) >= multiply(bidIncrease, bids[id].bidAmount) || rad == bids[id].amountToRaise, "EnglishCollateralAuctionHouse/insufficient-increase");

        if (msg.sender != bids[id].highBidder) {
            safeEngine.transferInternalCoins(msg.sender, bids[id].highBidder, bids[id].bidAmount);
            bids[id].highBidder = msg.sender;
        }
        safeEngine.transferInternalCoins(msg.sender, bids[id].auctionIncomeRecipient, rad - bids[id].bidAmount);

        bids[id].bidAmount = rad;
        bids[id].bidExpiry = addUint48(uint48(now), bidDuration);

        emit IncreaseBidSize(id, msg.sender, amountToBuy, rad, bids[id].bidExpiry);
    }
    /**
     * @notice Second auction phase: decrease the collateral amount you're willing to receive in
     *         exchange for providing the same amount of coins as the winning bid
     * @param id ID of the auction for which you want to submit a new amount of collateral to buy
     * @param amountToBuy Amount of collateral to buy (must be smaller than the previous proposed amount) (wad)
     * @param rad New bid submitted; must be equal to the winning bid from the increaseBidSize phase (rad)
     */
    function decreaseSoldAmount(uint256 id, uint256 amountToBuy, uint256 rad) external {
        require(bids[id].highBidder != address(0), "EnglishCollateralAuctionHouse/high-bidder-not-set");
        require(bids[id].bidExpiry > now || bids[id].bidExpiry == 0, "EnglishCollateralAuctionHouse/bid-already-expired");
        require(bids[id].auctionDeadline > now, "EnglishCollateralAuctionHouse/auction-already-expired");

        require(rad == bids[id].bidAmount, "EnglishCollateralAuctionHouse/not-matching-bid");
        require(rad == bids[id].amountToRaise, "EnglishCollateralAuctionHouse/bid-increase-not-finished");
        require(amountToBuy < bids[id].amountToSell, "EnglishCollateralAuctionHouse/amount-bought-not-lower");
        require(multiply(bidIncrease, amountToBuy) <= multiply(bids[id].amountToSell, ONE), "EnglishCollateralAuctionHouse/insufficient-decrease");

        if (msg.sender != bids[id].highBidder) {
            safeEngine.transferInternalCoins(msg.sender, bids[id].highBidder, rad);
            bids[id].highBidder = msg.sender;
        }
        safeEngine.transferCollateral(
          collateralType,
          address(this),
          bids[id].forgoneCollateralReceiver,
          bids[id].amountToSell - amountToBuy
        );

        bids[id].amountToSell = amountToBuy;
        bids[id].bidExpiry    = addUint48(uint48(now), bidDuration);

        emit DecreaseSoldAmount(id, msg.sender, amountToBuy, rad, bids[id].bidExpiry);
    }
    /**
     * @notice Settle/finish an auction
     * @param id ID of the auction to settle
     */
    function settleAuction(uint256 id) external {
        require(bids[id].bidExpiry != 0 && (bids[id].bidExpiry < now || bids[id].auctionDeadline < now), "EnglishCollateralAuctionHouse/not-finished");
        safeEngine.transferCollateral(collateralType, address(this), bids[id].highBidder, bids[id].amountToSell);
        liquidationEngine.removeCoinsFromAuction(bids[id].amountToRaise);
        delete bids[id];
        emit SettleAuction(id);
    }
    /**
     * @notice Terminate an auction prematurely (if it's still in the first phase).
     *         Usually called by Global Settlement.
     * @param id ID of the auction to settle
     */
    function terminateAuctionPrematurely(uint256 id) external isAuthorized {
        require(bids[id].highBidder != address(0), "EnglishCollateralAuctionHouse/high-bidder-not-set");
        require(bids[id].bidAmount < bids[id].amountToRaise, "EnglishCollateralAuctionHouse/already-decreasing-sold-amount");
        liquidationEngine.removeCoinsFromAuction(bids[id].amountToRaise);
        safeEngine.transferCollateral(collateralType, address(this), msg.sender, bids[id].amountToSell);
        safeEngine.transferInternalCoins(msg.sender, bids[id].highBidder, bids[id].bidAmount);
        emit TerminateAuctionPrematurely(id, msg.sender, bids[id].bidAmount, bids[id].amountToSell);
        delete bids[id];
    }

    // --- Getters ---
    function bidAmount(uint256 id) public view returns (uint256) {
        return bids[id].bidAmount;
    }
    function remainingAmountToSell(uint256 id) public view returns (uint256) {
        return bids[id].amountToSell;
    }
    function forgoneCollateralReceiver(uint256 id) public view returns (address) {
        return bids[id].forgoneCollateralReceiver;
    }
    function raisedAmount(uint256 id) public view returns (uint256) {
        return 0;
    }
    function amountToRaise(uint256 id) public view returns (uint256) {
        return bids[id].amountToRaise;
    }
}

/// FixedDiscountCollateralAuctionHouse.sol

// Copyright (C) 2018 Rain <[email protected]>, 2020 Reflexer Labs, INC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/*
   This thing lets you sell some collateral at a fixed discount in order to instantly recapitalize the system
*/

contract FixedDiscountCollateralAuctionHouse {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "FixedDiscountCollateralAuctionHouse/account-not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        // System coins raised up until now
        uint256 raisedAmount;                                                                                         // [rad]
        // Amount of collateral that has been sold up until now
        uint256 soldAmount;                                                                                           // [wad]
        // How much collateral is sold in an auction
        uint256 amountToSell;                                                                                         // [wad]
        // Total/max amount of coins to raise
        uint256 amountToRaise;                                                                                        // [rad]
        // Duration of time after which the auction can be settled
        uint48  auctionDeadline;                                                                                      // [unix epoch time]
        // Who (which SAFE) receives leftover collateral that is not sold in the auction; usually the liquidated SAFE
        address forgoneCollateralReceiver;
        // Who receives the coins raised by the auction; usually the accounting engine
        address auctionIncomeRecipient;
    }

    // Bid data for each separate auction
    mapping (uint256 => Bid) public bids;

    // SAFE database
    SAFEEngineLike_5 public safeEngine;
    // Collateral type name
    bytes32       public collateralType;

    // Minimum acceptable bid
    uint256  public   minimumBid = 5 * WAD;                                                                           // [wad]
    // Total length of the auction. Kept to adhere to the same interface as the English auction but redundant
    uint48   public   totalAuctionLength = uint48(-1);                                                                // [seconds]
    // Number of auctions started up until now
    uint256  public   auctionsStarted = 0;
    // The last read redemption price
    uint256  public   lastReadRedemptionPrice;
    // Discount (compared to the system coin's current redemption price) at which collateral is being sold
    uint256  public   discount = 0.95E18;                         // 5% discount                                      // [wad]
    // Max lower bound deviation that the collateral median can have compared to the FSM price
    uint256  public   lowerCollateralMedianDeviation = 0.90E18;   // 10% deviation                                    // [wad]
    // Max upper bound deviation that the collateral median can have compared to the FSM price
    uint256  public   upperCollateralMedianDeviation = 0.95E18;   // 5% deviation                                     // [wad]
    // Max lower bound deviation that the system coin oracle price feed can have compared to the systemCoinOracle price
    uint256  public   lowerSystemCoinMedianDeviation = WAD;       // 0% deviation                                     // [wad]
    // Max upper bound deviation that the system coin oracle price feed can have compared to the systemCoinOracle price
    uint256  public   upperSystemCoinMedianDeviation = WAD;       // 0% deviation                                     // [wad]
    // Min deviation for the system coin median result compared to the redemption price in order to take the median into account
    uint256  public   minSystemCoinMedianDeviation   = 0.999E18;                                                      // [wad]

    OracleRelayerLike_1     public oracleRelayer;
    OracleLike_1            public collateralFSM;
    OracleLike_1            public systemCoinOracle;
    LiquidationEngineLike_1 public liquidationEngine;

    bytes32 public constant AUCTION_HOUSE_TYPE = bytes32("COLLATERAL");
    bytes32 public constant AUCTION_TYPE       = bytes32("FIXED_DISCOUNT");

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event StartAuction(
        uint256 id,
        uint256 auctionsStarted,
        uint256 amountToSell,
        uint256 initialBid,
        uint256 indexed amountToRaise,
        address indexed forgoneCollateralReceiver,
        address indexed auctionIncomeRecipient,
        uint256 auctionDeadline
    );
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event BuyCollateral(uint256 indexed id, uint256 wad, uint256 boughtCollateral);
    event SettleAuction(uint256 indexed id, uint256 leftoverCollateral);
    event TerminateAuctionPrematurely(uint256 indexed id, address sender, uint256 collateralAmount);

    // --- Init ---
    constructor(address safeEngine_, address liquidationEngine_, bytes32 collateralType_) public {
        safeEngine = SAFEEngineLike_5(safeEngine_);
        liquidationEngine = LiquidationEngineLike_1(liquidationEngine_);
        collateralType = collateralType_;
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addUint48(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x, "FixedDiscountCollateralAuctionHouse/add-uint48-overflow");
    }
    function addUint256(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "FixedDiscountCollateralAuctionHouse/add-uint256-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "FixedDiscountCollateralAuctionHouse/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "FixedDiscountCollateralAuctionHouse/mul-overflow");
    }
    uint256 constant WAD = 10 ** 18;
    function wmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = multiply(x, y) / WAD;
    }
    uint256 constant RAY = 10 ** 27;
    function rdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "FixedDiscountCollateralAuctionHouse/rdiv-by-zero");
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "FixedDiscountCollateralAuctionHouse/wdiv-by-zero");
        z = multiply(x, WAD) / y;
    }
    function minimum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x <= y) ? x : y;
    }
    function maximum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x >= y) ? x : y;
    }

    // --- General Utils ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Admin ---
    /**
     * @notice Modify an uint256 parameter
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "discount") {
            require(data < WAD, "FixedDiscountCollateralAuctionHouse/no-discount-offered");
            discount = data;
        }
        else if (parameter == "lowerCollateralMedianDeviation") {
            require(data <= WAD, "FixedDiscountCollateralAuctionHouse/invalid-lower-collateral-median-deviation");
            lowerCollateralMedianDeviation = data;
        }
        else if (parameter == "upperCollateralMedianDeviation") {
            require(data <= WAD, "FixedDiscountCollateralAuctionHouse/invalid-upper-collateral-median-deviation");
            upperCollateralMedianDeviation = data;
        }
        else if (parameter == "lowerSystemCoinMedianDeviation") {
            require(data <= WAD, "FixedDiscountCollateralAuctionHouse/invalid-lower-system-coin-median-deviation");
            lowerSystemCoinMedianDeviation = data;
        }
        else if (parameter == "upperSystemCoinMedianDeviation") {
            require(data <= WAD, "FixedDiscountCollateralAuctionHouse/invalid-upper-system-coin-median-deviation");
            upperSystemCoinMedianDeviation = data;
        }
        else if (parameter == "minSystemCoinMedianDeviation") {
            minSystemCoinMedianDeviation = data;
        }
        else if (parameter == "minimumBid") {
            minimumBid = data;
        }
        else revert("FixedDiscountCollateralAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify an address parameter
     * @param parameter The name of the contract address being updated
     * @param data New address for the oracle contract
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "oracleRelayer") oracleRelayer = OracleRelayerLike_1(data);
        else if (parameter == "collateralFSM") {
          collateralFSM = OracleLike_1(data);
          // Check that priceSource() is implemented
          collateralFSM.priceSource();
        }
        else if (parameter == "systemCoinOracle") systemCoinOracle = OracleLike_1(data);
        else if (parameter == "liquidationEngine") liquidationEngine = LiquidationEngineLike_1(data);
        else revert("FixedDiscountCollateralAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Private Auction Utils ---
    /*
    * @notify Get the amount of bought collateral from a specific auction using custom collateral price feeds and a system coin price feed
    * @param id The ID of the auction to bid in and get collateral from
    * @param collateralFsmPriceFeedValue The collateral price fetched from the FSM
    * @param collateralMedianPriceFeedValue The collateral price fetched from the oracle median
    * @param systemCoinPriceFeedValue The system coin market price fetched from the oracle
    * @param adjustedBid The system coin bid
    */
    function getBoughtCollateral(
        uint256 id,
        uint256 collateralFsmPriceFeedValue,
        uint256 collateralMedianPriceFeedValue,
        uint256 systemCoinPriceFeedValue,
        uint256 adjustedBid
    ) private view returns (uint256) {
        // calculate the collateral price in relation to the latest system coin price and apply the discount
        uint256 discountedCollateralPrice =
          getDiscountedCollateralPrice(
            collateralFsmPriceFeedValue,
            collateralMedianPriceFeedValue,
            systemCoinPriceFeedValue,
            discount
          );
        // calculate the amount of collateral bought
        uint256 boughtCollateral = wdivide(adjustedBid, discountedCollateralPrice);
        // if the calculated collateral amount exceeds the amount still up for sale, adjust it to the remaining amount
        boughtCollateral = (boughtCollateral > subtract(bids[id].amountToSell, bids[id].soldAmount)) ?
                           subtract(bids[id].amountToSell, bids[id].soldAmount) : boughtCollateral;

        return boughtCollateral;
    }

    // --- Public Auction Utils ---
    /*
    * @notice Fetch the collateral median price (from the oracle, not FSM)
    * @returns The collateral price from the oracle median; zero if the address of the collateralMedian (as fetched from the FSM) is null
    */
    function getCollateralMedianPrice() public view returns (uint256 priceFeed) {
        // Fetch the collateral median address from the collateral FSM
        address collateralMedian;
        try collateralFSM.priceSource() returns (address median) {
          collateralMedian = median;
        } catch (bytes memory revertReason) {}

        if (collateralMedian == address(0)) return 0;

        // wrapped call toward the collateral median
        try OracleLike_1(collateralMedian).getResultWithValidity()
          returns (uint256 price, bool valid) {
          if (valid) {
            priceFeed = uint256(price);
          }
        } catch (bytes memory revertReason) {
          return 0;
        }
    }
    /*
    * @notice Fetch the system coin market price
    * @returns The system coin market price fetch from the oracle
    */
    function getSystemCoinMarketPrice() public view returns (uint256 priceFeed) {
        if (address(systemCoinOracle) == address(0)) return 0;

        // wrapped call toward the system coin oracle
        try systemCoinOracle.getResultWithValidity()
          returns (uint256 price, bool valid) {
          if (valid) {
            priceFeed = uint256(price) * 10 ** 9; // scale to RAY
          }
        } catch (bytes memory revertReason) {
          return 0;
        }
    }
    /*
    * @notice Get the smallest possible price that's at max lowerSystemCoinMedianDeviation deviated from the redemption price and at least
    *         minSystemCoinMedianDeviation deviated
    */
    function getSystemCoinFloorDeviatedPrice(uint256 redemptionPrice) public view returns (uint256 floorPrice) {
        uint256 minFloorDeviatedPrice = wmultiply(redemptionPrice, minSystemCoinMedianDeviation);
        floorPrice = wmultiply(redemptionPrice, lowerSystemCoinMedianDeviation);
        floorPrice = (floorPrice <= minFloorDeviatedPrice) ? floorPrice : redemptionPrice;
    }
    /*
    * @notice Get the highest possible price that's at max upperSystemCoinMedianDeviation deviated from the redemption price and at least
    *         minSystemCoinMedianDeviation deviated
    */
    function getSystemCoinCeilingDeviatedPrice(uint256 redemptionPrice) public view returns (uint256 ceilingPrice) {
        uint256 minCeilingDeviatedPrice = wmultiply(redemptionPrice, subtract(2 * WAD, minSystemCoinMedianDeviation));
        ceilingPrice = wmultiply(redemptionPrice, subtract(2 * WAD, upperSystemCoinMedianDeviation));
        ceilingPrice = (ceilingPrice >= minCeilingDeviatedPrice) ? ceilingPrice : redemptionPrice;
    }
    /*
    * @notice Get the collateral price from the FSM and the final system coin price that will be used when bidding in an auction
    * @param systemCoinRedemptionPrice The system coin redemption price
    * @returns The collateral price from the FSM and the final system coin price used for bidding (picking between redemption and market prices)
    */
    function getCollateralFSMAndFinalSystemCoinPrices(uint256 systemCoinRedemptionPrice) public view returns (uint256, uint256) {
        require(systemCoinRedemptionPrice > 0, "FixedDiscountCollateralAuctionHouse/invalid-redemption-price-provided");
        (uint256 collateralFsmPriceFeedValue, bool collateralFsmHasValidValue) = collateralFSM.getResultWithValidity();
        if (!collateralFsmHasValidValue) {
          return (0, 0);
        }

        uint256 systemCoinAdjustedPrice  = systemCoinRedemptionPrice;
        uint256 systemCoinPriceFeedValue = getSystemCoinMarketPrice();

        if (systemCoinPriceFeedValue > 0) {
          uint256 floorPrice   = getSystemCoinFloorDeviatedPrice(systemCoinAdjustedPrice);
          uint256 ceilingPrice = getSystemCoinCeilingDeviatedPrice(systemCoinAdjustedPrice);

          if (uint(systemCoinPriceFeedValue) < systemCoinAdjustedPrice) {
            systemCoinAdjustedPrice = maximum(uint256(systemCoinPriceFeedValue), floorPrice);
          } else {
            systemCoinAdjustedPrice = minimum(uint256(systemCoinPriceFeedValue), ceilingPrice);
          }
        }

        return (uint256(collateralFsmPriceFeedValue), systemCoinAdjustedPrice);
    }
    /*
    * @notice Get the collateral price used in bidding by picking between the raw FSM and the oracle median price and taking into account
    *         deviation limits
    * @param collateralFsmPriceFeedValue The collateral price fetched from the FSM
    * @param collateralMedianPriceFeedValue The collateral price fetched from the median attached to the FSM
    */
    function getFinalBaseCollateralPrice(
        uint256 collateralFsmPriceFeedValue,
        uint256 collateralMedianPriceFeedValue
    ) public view returns (uint256) {
        uint256 floorPrice   = wmultiply(collateralFsmPriceFeedValue, lowerCollateralMedianDeviation);
        uint256 ceilingPrice = wmultiply(collateralFsmPriceFeedValue, subtract(2 * WAD, upperCollateralMedianDeviation));

        uint256 adjustedMedianPrice = (collateralMedianPriceFeedValue == 0) ?
          collateralFsmPriceFeedValue : collateralMedianPriceFeedValue;

        if (adjustedMedianPrice < collateralFsmPriceFeedValue) {
          return maximum(adjustedMedianPrice, floorPrice);
        } else {
          return minimum(adjustedMedianPrice, ceilingPrice);
        }
    }
    /*
    * @notice Get the discounted collateral price (using a custom discount)
    * @param collateralFsmPriceFeedValue The collateral price fetched from the FSM
    * @param collateralMedianPriceFeedValue The collateral price fetched from the oracle median
    * @param systemCoinPriceFeedValue The system coin price fetched from the oracle
    * @param customDiscount The custom discount used to calculate the collateral price offered
    */
    function getDiscountedCollateralPrice(
        uint256 collateralFsmPriceFeedValue,
        uint256 collateralMedianPriceFeedValue,
        uint256 systemCoinPriceFeedValue,
        uint256 customDiscount
    ) public view returns (uint256) {
        // calculate the collateral price in relation to the latest system coin price and apply the discount
        return wmultiply(
          rdivide(getFinalBaseCollateralPrice(collateralFsmPriceFeedValue, collateralMedianPriceFeedValue), systemCoinPriceFeedValue),
          customDiscount
        );
    }
    /*
    * @notice Get the actual bid that will be used in an auction (taking into account the bidder input)
    * @param id The id of the auction to calculate the adjusted bid for
    * @param wad The initial bid submitted
    * @returns Whether the bid is valid or not and the adjusted bid
    */
    function getAdjustedBid(
        uint256 id, uint256 wad
    ) public view returns (bool, uint256) {
        if (either(
          either(bids[id].amountToSell == 0, bids[id].amountToRaise == 0),
          either(wad == 0, wad < minimumBid)
        )) {
          return (false, wad);
        }

        uint256 remainingToRaise = subtract(bids[id].amountToRaise, bids[id].raisedAmount);

        // bound max amount offered in exchange for collateral
        uint256 adjustedBid = wad;
        if (multiply(adjustedBid, RAY) > remainingToRaise) {
            adjustedBid = addUint256(remainingToRaise / RAY, 1);
        }

        remainingToRaise = subtract(bids[id].amountToRaise, bids[id].raisedAmount);
        if (both(remainingToRaise > 0, remainingToRaise < RAY)) {
            return (false, adjustedBid);
        }

        return (true, adjustedBid);
    }

    // --- Core Auction Logic ---
    /**
     * @notice Start a new collateral auction
     * @param forgoneCollateralReceiver Who receives leftover collateral that is not auctioned
     * @param auctionIncomeRecipient Who receives the amount raised in the auction
     * @param amountToRaise Total amount of coins to raise (rad)
     * @param amountToSell Total amount of collateral available to sell (wad)
     * @param initialBid Unused
     */
    function startAuction(
        address forgoneCollateralReceiver,
        address auctionIncomeRecipient,
        uint256 amountToRaise,
        uint256 amountToSell,
        uint256 initialBid
    ) public isAuthorized returns (uint256 id) {
        require(auctionsStarted < uint256(-1), "FixedDiscountCollateralAuctionHouse/overflow");
        require(amountToSell > 0, "FixedDiscountCollateralAuctionHouse/no-collateral-for-sale");
        require(amountToRaise > 0, "FixedDiscountCollateralAuctionHouse/nothing-to-raise");
        require(amountToRaise >= RAY, "FixedDiscountCollateralAuctionHouse/dusty-auction");
        id = ++auctionsStarted;

        bids[id].auctionDeadline = uint48(-1);
        bids[id].amountToSell = amountToSell;
        bids[id].forgoneCollateralReceiver = forgoneCollateralReceiver;
        bids[id].auctionIncomeRecipient = auctionIncomeRecipient;
        bids[id].amountToRaise = amountToRaise;

        safeEngine.transferCollateral(collateralType, msg.sender, address(this), amountToSell);

        emit StartAuction(
          id,
          auctionsStarted,
          amountToSell,
          initialBid,
          amountToRaise,
          forgoneCollateralReceiver,
          auctionIncomeRecipient,
          bids[id].auctionDeadline
        );
    }
    /**
     * @notice Calculate how much collateral someone would buy from an auction using the last read redemption price
     * @param id ID of the auction to buy collateral from
     * @param wad New bid submitted
     */
    function getApproximateCollateralBought(uint256 id, uint256 wad) external view returns (uint256, uint256) {
        if (lastReadRedemptionPrice == 0) return (0, wad);

        (bool validAuctionAndBid, uint256 adjustedBid) = getAdjustedBid(id, wad);
        if (!validAuctionAndBid) {
            return (0, adjustedBid);
        }

        // check that the oracle doesn't return an invalid value
        (uint256 collateralFsmPriceFeedValue, uint256 systemCoinPriceFeedValue) = getCollateralFSMAndFinalSystemCoinPrices(lastReadRedemptionPrice);
        if (collateralFsmPriceFeedValue == 0) {
          return (0, adjustedBid);
        }

        return (getBoughtCollateral(
          id,
          collateralFsmPriceFeedValue,
          getCollateralMedianPrice(),
          systemCoinPriceFeedValue,
          adjustedBid
        ), adjustedBid);
    }
    /**
     * @notice Calculate how much collateral someone would buy from an auction using the latest redemption price fetched from the OracleRelayer
     * @param id ID of the auction to buy collateral from
     * @param wad New bid submitted
     */
    function getCollateralBought(uint256 id, uint256 wad) external returns (uint256, uint256) {
        (bool validAuctionAndBid, uint256 adjustedBid) = getAdjustedBid(id, wad);
        if (!validAuctionAndBid) {
            return (0, adjustedBid);
        }

        // Read the redemption price
        lastReadRedemptionPrice = oracleRelayer.redemptionPrice();

        // check that the oracle doesn't return an invalid value
        (uint256 collateralFsmPriceFeedValue, uint256 systemCoinPriceFeedValue) = getCollateralFSMAndFinalSystemCoinPrices(lastReadRedemptionPrice);
        if (collateralFsmPriceFeedValue == 0) {
          return (0, adjustedBid);
        }

        return (getBoughtCollateral(
          id,
          collateralFsmPriceFeedValue,
          getCollateralMedianPrice(),
          systemCoinPriceFeedValue,
          adjustedBid
        ), adjustedBid);
    }
    /**
     * @notice Buy collateral from an auction at a fixed discount
     * @param id ID of the auction to buy collateral from
     * @param wad New bid submitted (as a WAD which has 18 decimals)
     */
    function buyCollateral(uint256 id, uint256 wad) external {
        require(both(bids[id].amountToSell > 0, bids[id].amountToRaise > 0), "FixedDiscountCollateralAuctionHouse/inexistent-auction");

        uint256 remainingToRaise = subtract(bids[id].amountToRaise, bids[id].raisedAmount);
        require(both(wad > 0, wad >= minimumBid), "FixedDiscountCollateralAuctionHouse/invalid-bid");

        // bound max amount offered in exchange for collateral (in case someone offers more than is necessary)
        uint256 adjustedBid = wad;
        if (multiply(adjustedBid, RAY) > remainingToRaise) {
            adjustedBid = addUint256(remainingToRaise / RAY, 1);
        }

        // update amount raised
        bids[id].raisedAmount = addUint256(bids[id].raisedAmount, multiply(adjustedBid, RAY));

        // check that there's at least RAY left to raise if raisedAmount < amountToRaise
        if (bids[id].raisedAmount < bids[id].amountToRaise) {
            require(subtract(bids[id].amountToRaise, bids[id].raisedAmount) >= RAY, "FixedDiscountCollateralAuctionHouse/invalid-left-to-raise");
        }

        // Read the redemption price
        lastReadRedemptionPrice = oracleRelayer.redemptionPrice();

        // check that the collateral FSM doesn't return an invalid value
        (uint256 collateralFsmPriceFeedValue, uint256 systemCoinPriceFeedValue) = getCollateralFSMAndFinalSystemCoinPrices(lastReadRedemptionPrice);
        require(collateralFsmPriceFeedValue > 0, "FixedDiscountCollateralAuctionHouse/collateral-fsm-invalid-value");

        // get the amount of collateral bought
        uint256 boughtCollateral = getBoughtCollateral(
          id, collateralFsmPriceFeedValue, getCollateralMedianPrice(), systemCoinPriceFeedValue, adjustedBid
        );
        // check that the calculated amount is greater than zero
        require(boughtCollateral > 0, "FixedDiscountCollateralAuctionHouse/null-bought-amount");
        // update the amount of collateral already sold
        bids[id].soldAmount = addUint256(bids[id].soldAmount, boughtCollateral);

        // transfer the bid to the income recipient and the collateral to the bidder
        safeEngine.transferInternalCoins(msg.sender, bids[id].auctionIncomeRecipient, multiply(adjustedBid, RAY));
        safeEngine.transferCollateral(collateralType, address(this), msg.sender, boughtCollateral);

        // Emit the buy event
        emit BuyCollateral(id, adjustedBid, boughtCollateral);

        // Remove coins from the liquidation buffer
        bool soldAll = either(bids[id].amountToRaise <= bids[id].raisedAmount, bids[id].amountToSell == bids[id].soldAmount);
        if (soldAll) {
          liquidationEngine.removeCoinsFromAuction(remainingToRaise);
        } else {
          liquidationEngine.removeCoinsFromAuction(multiply(adjustedBid, RAY));
        }

        // If the auction raised the whole amount or all collateral was sold,
        // send remaining collateral back to the forgone receiver
        if (soldAll) {
            uint256 leftoverCollateral = subtract(bids[id].amountToSell, bids[id].soldAmount);
            safeEngine.transferCollateral(collateralType, address(this), bids[id].forgoneCollateralReceiver, leftoverCollateral);
            delete bids[id];
            emit SettleAuction(id, leftoverCollateral);
        }
    }
    /**
     * @notice Settle/finish an auction
     * @param id ID of the auction to settle
     */
    function settleAuction(uint256 id) external {
        return;
    }
    /**
     * @notice Terminate an auction prematurely. Usually called by Global Settlement.
     * @param id ID of the auction to settle
     */
    function terminateAuctionPrematurely(uint256 id) external isAuthorized {
        require(both(bids[id].amountToSell > 0, bids[id].amountToRaise > 0), "FixedDiscountCollateralAuctionHouse/inexistent-auction");
        uint256 leftoverCollateral = subtract(bids[id].amountToSell, bids[id].soldAmount);
        liquidationEngine.removeCoinsFromAuction(subtract(bids[id].amountToRaise, bids[id].raisedAmount));
        safeEngine.transferCollateral(collateralType, address(this), msg.sender, leftoverCollateral);
        delete bids[id];
        emit TerminateAuctionPrematurely(id, msg.sender, leftoverCollateral);
    }

    // --- Getters ---
    function bidAmount(uint256 id) public view returns (uint256) {
        return 0;
    }
    function remainingAmountToSell(uint256 id) public view returns (uint256) {
        return subtract(bids[id].amountToSell, bids[id].soldAmount);
    }
    function forgoneCollateralReceiver(uint256 id) public view returns (address) {
        return bids[id].forgoneCollateralReceiver;
    }
    function raisedAmount(uint256 id) public view returns (uint256) {
        return bids[id].raisedAmount;
    }
    function amountToRaise(uint256 id) public view returns (uint256) {
        return bids[id].amountToRaise;
    }
}

/// IncreasingDiscountCollateralAuctionHouse.sol

// Copyright (C) 2018 Rain <[email protected]>, 2020 Reflexer Labs, INC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/*
   This thing lets you sell some collateral at an increasing discount in order to instantly recapitalize the system
*/

contract IncreasingDiscountCollateralAuctionHouse {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "IncreasingDiscountCollateralAuctionHouse/account-not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        // How much collateral is sold in an auction
        uint256 amountToSell;                                                                                         // [wad]
        // Total/max amount of coins to raise
        uint256 amountToRaise;                                                                                        // [rad]
        // Current discount
        uint256 currentDiscount;                                                                                      // [wad]
        // Max possibe discount
        uint256 maxDiscount;                                                                                          // [wad]
        // Rate at which the discount is updated every second
        uint256 perSecondDiscountUpdateRate;                                                                          // [ray]
        // Last time when the current discount was updated
        uint256 latestDiscountUpdateTime;                                                                             // [unix timestamp]
        // Deadline after which the discount cannot increase anymore
        uint48  discountIncreaseDeadline;                                                                             // [unix epoch time]
        // Who (which SAFE) receives leftover collateral that is not sold in the auction; usually the liquidated SAFE
        address forgoneCollateralReceiver;
        // Who receives the coins raised by the auction; usually the accounting engine
        address auctionIncomeRecipient;
    }

    // Bid data for each separate auction
    mapping (uint256 => Bid) public bids;

    // SAFE database
    SAFEEngineLike_5 public safeEngine;
    // Collateral type name
    bytes32        public collateralType;

    // Minimum acceptable bid
    uint256  public   minimumBid = 5 * WAD;                                                                           // [wad]
    // Total length of the auction. Kept to adhere to the same interface as the English auction but redundant
    uint48   public   totalAuctionLength = uint48(-1);                                                                // [seconds]
    // Number of auctions started up until now
    uint256  public   auctionsStarted = 0;
    // The last read redemption price
    uint256  public   lastReadRedemptionPrice;
    // Minimum discount (compared to the system coin's current redemption price) at which collateral is being sold
    uint256  public   minDiscount = 0.95E18;                      // 5% discount                                      // [wad]
    // Maximum discount (compared to the system coin's current redemption price) at which collateral is being sold
    uint256  public   maxDiscount = 0.95E18;                      // 5% discount                                      // [wad]
    // Rate at which the discount will be updated in an auction
    uint256  public   perSecondDiscountUpdateRate = RAY;                                                              // [ray]
    // Max time over which the discount can be updated
    uint256  public   maxDiscountUpdateRateTimeline  = 1 hours;                                                       // [seconds]
    // Max lower bound deviation that the collateral median can have compared to the FSM price
    uint256  public   lowerCollateralMedianDeviation = 0.90E18;   // 10% deviation                                    // [wad]
    // Max upper bound deviation that the collateral median can have compared to the FSM price
    uint256  public   upperCollateralMedianDeviation = 0.95E18;   // 5% deviation                                     // [wad]
    // Max lower bound deviation that the system coin oracle price feed can have compared to the systemCoinOracle price
    uint256  public   lowerSystemCoinMedianDeviation = WAD;       // 0% deviation                                     // [wad]
    // Max upper bound deviation that the system coin oracle price feed can have compared to the systemCoinOracle price
    uint256  public   upperSystemCoinMedianDeviation = WAD;       // 0% deviation                                     // [wad]
    // Min deviation for the system coin median result compared to the redemption price in order to take the median into account
    uint256  public   minSystemCoinMedianDeviation   = 0.999E18;                                                      // [wad]

    OracleRelayerLike_1     public oracleRelayer;
    OracleLike_1            public collateralFSM;
    OracleLike_1            public systemCoinOracle;
    LiquidationEngineLike_1 public liquidationEngine;

    bytes32 public constant AUCTION_HOUSE_TYPE = bytes32("COLLATERAL");
    bytes32 public constant AUCTION_TYPE       = bytes32("INCREASING_DISCOUNT");

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event StartAuction(
        uint256 id,
        uint256 auctionsStarted,
        uint256 amountToSell,
        uint256 initialBid,
        uint256 indexed amountToRaise,
        uint256 startingDiscount,
        uint256 maxDiscount,
        uint256 perSecondDiscountUpdateRate,
        uint48  discountIncreaseDeadline,
        address indexed forgoneCollateralReceiver,
        address indexed auctionIncomeRecipient
    );
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event BuyCollateral(uint256 indexed id, uint256 wad, uint256 boughtCollateral);
    event SettleAuction(uint256 indexed id, uint256 leftoverCollateral);
    event TerminateAuctionPrematurely(uint256 indexed id, address sender, uint256 collateralAmount);

    // --- Init ---
    constructor(address safeEngine_, address liquidationEngine_, bytes32 collateralType_) public {
        safeEngine = SAFEEngineLike_5(safeEngine_);
        liquidationEngine = LiquidationEngineLike_1(liquidationEngine_);
        collateralType = collateralType_;
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addUint48(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x, "IncreasingDiscountCollateralAuctionHouse/add-uint48-overflow");
    }
    function addUint256(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "IncreasingDiscountCollateralAuctionHouse/add-uint256-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "IncreasingDiscountCollateralAuctionHouse/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "IncreasingDiscountCollateralAuctionHouse/mul-overflow");
    }
    uint256 constant WAD = 10 ** 18;
    function wmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = multiply(x, y) / WAD;
    }
    uint256 constant RAY = 10 ** 27;
    function rdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "IncreasingDiscountCollateralAuctionHouse/rdiv-by-zero");
        z = multiply(x, RAY) / y;
    }
    function rmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x, "IncreasingDiscountCollateralAuctionHouse/rmul-overflow");
        z = z / RAY;
    }
    function wdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "IncreasingDiscountCollateralAuctionHouse/wdiv-by-zero");
        z = multiply(x, WAD) / y;
    }
    function minimum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x <= y) ? x : y;
    }
    function maximum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x >= y) ? x : y;
    }
    function rpower(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }

    // --- General Utils ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Admin ---
    /**
     * @notice Modify an uint256 parameter
     * @param parameter The name of the parameter to modify
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "minDiscount") {
            require(both(data >= maxDiscount, data < WAD), "IncreasingDiscountCollateralAuctionHouse/invalid-min-discount");
            minDiscount = data;
        }
        else if (parameter == "maxDiscount") {
            require(both(both(data <= minDiscount, data < WAD), data > 0), "IncreasingDiscountCollateralAuctionHouse/invalid-max-discount");
            maxDiscount = data;
        }
        else if (parameter == "perSecondDiscountUpdateRate") {
            require(data <= RAY, "IncreasingDiscountCollateralAuctionHouse/invalid-discount-update-rate");
            perSecondDiscountUpdateRate = data;
        }
        else if (parameter == "maxDiscountUpdateRateTimeline") {
            require(both(data > 0, uint256(uint48(-1)) > addUint256(now, data)), "IncreasingDiscountCollateralAuctionHouse/invalid-update-rate-time");
            maxDiscountUpdateRateTimeline = data;
        }
        else if (parameter == "lowerCollateralMedianDeviation") {
            require(data <= WAD, "IncreasingDiscountCollateralAuctionHouse/invalid-lower-collateral-median-deviation");
            lowerCollateralMedianDeviation = data;
        }
        else if (parameter == "upperCollateralMedianDeviation") {
            require(data <= WAD, "IncreasingDiscountCollateralAuctionHouse/invalid-upper-collateral-median-deviation");
            upperCollateralMedianDeviation = data;
        }
        else if (parameter == "lowerSystemCoinMedianDeviation") {
            require(data <= WAD, "IncreasingDiscountCollateralAuctionHouse/invalid-lower-system-coin-median-deviation");
            lowerSystemCoinMedianDeviation = data;
        }
        else if (parameter == "upperSystemCoinMedianDeviation") {
            require(data <= WAD, "IncreasingDiscountCollateralAuctionHouse/invalid-upper-system-coin-median-deviation");
            upperSystemCoinMedianDeviation = data;
        }
        else if (parameter == "minSystemCoinMedianDeviation") {
            minSystemCoinMedianDeviation = data;
        }
        else if (parameter == "minimumBid") {
            minimumBid = data;
        }
        else revert("IncreasingDiscountCollateralAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify an addres parameter
     * @param parameter The parameter name
     * @param data New address for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "oracleRelayer") oracleRelayer = OracleRelayerLike_1(data);
        else if (parameter == "collateralFSM") {
          collateralFSM = OracleLike_1(data);
          // Check that priceSource() is implemented
          collateralFSM.priceSource();
        }
        else if (parameter == "systemCoinOracle") systemCoinOracle = OracleLike_1(data);
        else if (parameter == "liquidationEngine") liquidationEngine = LiquidationEngineLike_1(data);
        else revert("IncreasingDiscountCollateralAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Private Auction Utils ---
    /*
    * @notify Get the amount of bought collateral from a specific auction using custom collateral price feeds, a system
    *         coin price feed and a custom discount
    * @param id The ID of the auction to bid in and get collateral from
    * @param collateralFsmPriceFeedValue The collateral price fetched from the FSM
    * @param collateralMedianPriceFeedValue The collateral price fetched from the oracle median
    * @param systemCoinPriceFeedValue The system coin market price fetched from the oracle
    * @param adjustedBid The system coin bid
    * @param customDiscount The discount offered
    */
    function getBoughtCollateral(
        uint256 id,
        uint256 collateralFsmPriceFeedValue,
        uint256 collateralMedianPriceFeedValue,
        uint256 systemCoinPriceFeedValue,
        uint256 adjustedBid,
        uint256 customDiscount
    ) private view returns (uint256) {
        // calculate the collateral price in relation to the latest system coin price and apply the discount
        uint256 discountedCollateralPrice =
          getDiscountedCollateralPrice(
            collateralFsmPriceFeedValue,
            collateralMedianPriceFeedValue,
            systemCoinPriceFeedValue,
            customDiscount
          );
        // calculate the amount of collateral bought
        uint256 boughtCollateral = wdivide(adjustedBid, discountedCollateralPrice);
        // if the calculated collateral amount exceeds the amount still up for sale, adjust it to the remaining amount
        boughtCollateral = (boughtCollateral > bids[id].amountToSell) ? bids[id].amountToSell : boughtCollateral;

        return boughtCollateral;
    }
    /*
    * @notice Update the discount used in a particular auction
    * @param id The id of the auction to update the discount for
    * @returns The newly computed currentDiscount for the targeted auction
    */
    function updateCurrentDiscount(uint256 id) private returns (uint256) {
        // Work directly with storage
        Bid storage auctionBidData              = bids[id];
        auctionBidData.currentDiscount          = getNextCurrentDiscount(id);
        auctionBidData.latestDiscountUpdateTime = now;
        return auctionBidData.currentDiscount;
    }

    // --- Public Auction Utils ---
    /*
    * @notice Fetch the collateral median price (from the oracle, not FSM)
    * @returns The collateral price from the oracle median; zero if the address of the collateralMedian (as fetched from the FSM) is null
    */
    function getCollateralMedianPrice() public view returns (uint256 priceFeed) {
        // Fetch the collateral median address from the collateral FSM
        address collateralMedian;
        try collateralFSM.priceSource() returns (address median) {
          collateralMedian = median;
        } catch (bytes memory revertReason) {}

        if (collateralMedian == address(0)) return 0;

        // wrapped call toward the collateral median
        try OracleLike_1(collateralMedian).getResultWithValidity()
          returns (uint256 price, bool valid) {
          if (valid) {
            priceFeed = uint256(price);
          }
        } catch (bytes memory revertReason) {
          return 0;
        }
    }
    /*
    * @notice Fetch the system coin market price
    * @returns The system coin market price fetch from the oracle
    */
    function getSystemCoinMarketPrice() public view returns (uint256 priceFeed) {
        if (address(systemCoinOracle) == address(0)) return 0;

        // wrapped call toward the system coin oracle
        try systemCoinOracle.getResultWithValidity()
          returns (uint256 price, bool valid) {
          if (valid) {
            priceFeed = uint256(price) * 10 ** 9; // scale to RAY
          }
        } catch (bytes memory revertReason) {
          return 0;
        }
    }
    /*
    * @notice Get the smallest possible price that's at max lowerSystemCoinMedianDeviation deviated from the redemption price and at least
    *         minSystemCoinMedianDeviation deviated
    */
    function getSystemCoinFloorDeviatedPrice(uint256 redemptionPrice) public view returns (uint256 floorPrice) {
        uint256 minFloorDeviatedPrice = wmultiply(redemptionPrice, minSystemCoinMedianDeviation);
        floorPrice = wmultiply(redemptionPrice, lowerSystemCoinMedianDeviation);
        floorPrice = (floorPrice <= minFloorDeviatedPrice) ? floorPrice : redemptionPrice;
    }
    /*
    * @notice Get the highest possible price that's at max upperSystemCoinMedianDeviation deviated from the redemption price and at least
    *         minSystemCoinMedianDeviation deviated
    */
    function getSystemCoinCeilingDeviatedPrice(uint256 redemptionPrice) public view returns (uint256 ceilingPrice) {
        uint256 minCeilingDeviatedPrice = wmultiply(redemptionPrice, subtract(2 * WAD, minSystemCoinMedianDeviation));
        ceilingPrice = wmultiply(redemptionPrice, subtract(2 * WAD, upperSystemCoinMedianDeviation));
        ceilingPrice = (ceilingPrice >= minCeilingDeviatedPrice) ? ceilingPrice : redemptionPrice;
    }
    /*
    * @notice Get the collateral price from the FSM and the final system coin price that will be used when bidding in an auction
    * @param systemCoinRedemptionPrice The system coin redemption price
    * @returns The collateral price from the FSM and the final system coin price used for bidding (picking between redemption and market prices)
    */
    function getCollateralFSMAndFinalSystemCoinPrices(uint256 systemCoinRedemptionPrice) public view returns (uint256, uint256) {
        require(systemCoinRedemptionPrice > 0, "IncreasingDiscountCollateralAuctionHouse/invalid-redemption-price-provided");
        (uint256 collateralFsmPriceFeedValue, bool collateralFsmHasValidValue) = collateralFSM.getResultWithValidity();
        if (!collateralFsmHasValidValue) {
          return (0, 0);
        }

        uint256 systemCoinAdjustedPrice  = systemCoinRedemptionPrice;
        uint256 systemCoinPriceFeedValue = getSystemCoinMarketPrice();

        if (systemCoinPriceFeedValue > 0) {
          uint256 floorPrice   = getSystemCoinFloorDeviatedPrice(systemCoinAdjustedPrice);
          uint256 ceilingPrice = getSystemCoinCeilingDeviatedPrice(systemCoinAdjustedPrice);

          if (uint(systemCoinPriceFeedValue) < systemCoinAdjustedPrice) {
            systemCoinAdjustedPrice = maximum(uint256(systemCoinPriceFeedValue), floorPrice);
          } else {
            systemCoinAdjustedPrice = minimum(uint256(systemCoinPriceFeedValue), ceilingPrice);
          }
        }

        return (uint256(collateralFsmPriceFeedValue), systemCoinAdjustedPrice);
    }
    /*
    * @notice Get the collateral price used in bidding by picking between the raw FSM and the oracle median price and taking into account
    *         deviation limits
    * @param collateralFsmPriceFeedValue The collateral price fetched from the FSM
    * @param collateralMedianPriceFeedValue The collateral price fetched from the median attached to the FSM
    */
    function getFinalBaseCollateralPrice(
        uint256 collateralFsmPriceFeedValue,
        uint256 collateralMedianPriceFeedValue
    ) public view returns (uint256) {
        uint256 floorPrice   = wmultiply(collateralFsmPriceFeedValue, lowerCollateralMedianDeviation);
        uint256 ceilingPrice = wmultiply(collateralFsmPriceFeedValue, subtract(2 * WAD, upperCollateralMedianDeviation));

        uint256 adjustedMedianPrice = (collateralMedianPriceFeedValue == 0) ?
          collateralFsmPriceFeedValue : collateralMedianPriceFeedValue;

        if (adjustedMedianPrice < collateralFsmPriceFeedValue) {
          return maximum(adjustedMedianPrice, floorPrice);
        } else {
          return minimum(adjustedMedianPrice, ceilingPrice);
        }
    }
    /*
    * @notice Get the discounted collateral price (using a custom discount)
    * @param collateralFsmPriceFeedValue The collateral price fetched from the FSM
    * @param collateralMedianPriceFeedValue The collateral price fetched from the oracle median
    * @param systemCoinPriceFeedValue The system coin price fetched from the oracle
    * @param customDiscount The custom discount used to calculate the collateral price offered
    */
    function getDiscountedCollateralPrice(
        uint256 collateralFsmPriceFeedValue,
        uint256 collateralMedianPriceFeedValue,
        uint256 systemCoinPriceFeedValue,
        uint256 customDiscount
    ) public view returns (uint256) {
        // calculate the collateral price in relation to the latest system coin price and apply the discount
        return wmultiply(
          rdivide(getFinalBaseCollateralPrice(collateralFsmPriceFeedValue, collateralMedianPriceFeedValue), systemCoinPriceFeedValue),
          customDiscount
        );
    }
    /*
    * @notice Get the upcoming discount that will be used in a specific auction
    * @param id The ID of the auction to calculate the upcoming discount for
    * @returns The upcoming discount that will be used in the targeted auction
    */
    function getNextCurrentDiscount(uint256 id) public view returns (uint256) {
        if (bids[id].forgoneCollateralReceiver == address(0)) return RAY;
        uint256 nextDiscount = bids[id].currentDiscount;

        // If the increase deadline hasn't been passed yet and the current discount is not at or greater than max
        if (both(uint48(now) < bids[id].discountIncreaseDeadline, bids[id].currentDiscount > bids[id].maxDiscount)) {
            // Calculate the new current discount
            nextDiscount = rmultiply(
              rpower(bids[id].perSecondDiscountUpdateRate, subtract(now, bids[id].latestDiscountUpdateTime), RAY),
              bids[id].currentDiscount
            );

            // If the new discount is greater than the max one
            if (nextDiscount <= bids[id].maxDiscount) {
              nextDiscount = bids[id].maxDiscount;
            }
        } else {
            // Determine the conditions when we can instantly set the current discount to max
            bool currentZeroMaxNonZero = both(bids[id].currentDiscount == 0, bids[id].maxDiscount > 0);
            bool doneUpdating          = both(uint48(now) >= bids[id].discountIncreaseDeadline, bids[id].currentDiscount != bids[id].maxDiscount);

            if (either(currentZeroMaxNonZero, doneUpdating)) {
              nextDiscount = bids[id].maxDiscount;
            }
        }

        return nextDiscount;
    }
    /*
    * @notice Get the actual bid that will be used in an auction (taking into account the bidder input)
    * @param id The id of the auction to calculate the adjusted bid for
    * @param wad The initial bid submitted
    * @returns Whether the bid is valid or not and the adjusted bid
    */
    function getAdjustedBid(
        uint256 id, uint256 wad
    ) public view returns (bool, uint256) {
        if (either(
          either(bids[id].amountToSell == 0, bids[id].amountToRaise == 0),
          either(wad == 0, wad < minimumBid)
        )) {
          return (false, wad);
        }

        uint256 remainingToRaise = bids[id].amountToRaise;

        // bound max amount offered in exchange for collateral
        uint256 adjustedBid = wad;
        if (multiply(adjustedBid, RAY) > remainingToRaise) {
            adjustedBid = addUint256(remainingToRaise / RAY, 1);
        }

        remainingToRaise = (multiply(adjustedBid, RAY) > remainingToRaise) ? 0 : subtract(bids[id].amountToRaise, multiply(adjustedBid, RAY));
        if (both(remainingToRaise > 0, remainingToRaise < RAY)) {
            return (false, adjustedBid);
        }

        return (true, adjustedBid);
    }

    // --- Core Auction Logic ---
    /**
     * @notice Start a new collateral auction
     * @param forgoneCollateralReceiver Who receives leftover collateral that is not auctioned
     * @param auctionIncomeRecipient Who receives the amount raised in the auction
     * @param amountToRaise Total amount of coins to raise (rad)
     * @param amountToSell Total amount of collateral available to sell (wad)
     * @param initialBid Unused
     */
    function startAuction(
        address forgoneCollateralReceiver,
        address auctionIncomeRecipient,
        uint256 amountToRaise,
        uint256 amountToSell,
        uint256 initialBid
    ) public isAuthorized returns (uint256 id) {
        require(auctionsStarted < uint256(-1), "IncreasingDiscountCollateralAuctionHouse/overflow");
        require(amountToSell > 0, "IncreasingDiscountCollateralAuctionHouse/no-collateral-for-sale");
        require(amountToRaise > 0, "IncreasingDiscountCollateralAuctionHouse/nothing-to-raise");
        require(amountToRaise >= RAY, "IncreasingDiscountCollateralAuctionHouse/dusty-auction");
        id = ++auctionsStarted;

        uint48 discountIncreaseDeadline      = addUint48(uint48(now), uint48(maxDiscountUpdateRateTimeline));

        bids[id].currentDiscount             = minDiscount;
        bids[id].maxDiscount                 = maxDiscount;
        bids[id].perSecondDiscountUpdateRate = perSecondDiscountUpdateRate;
        bids[id].discountIncreaseDeadline    = discountIncreaseDeadline;
        bids[id].latestDiscountUpdateTime    = now;
        bids[id].amountToSell                = amountToSell;
        bids[id].forgoneCollateralReceiver   = forgoneCollateralReceiver;
        bids[id].auctionIncomeRecipient      = auctionIncomeRecipient;
        bids[id].amountToRaise               = amountToRaise;

        safeEngine.transferCollateral(collateralType, msg.sender, address(this), amountToSell);

        emit StartAuction(
          id,
          auctionsStarted,
          amountToSell,
          initialBid,
          amountToRaise,
          minDiscount,
          maxDiscount,
          perSecondDiscountUpdateRate,
          discountIncreaseDeadline,
          forgoneCollateralReceiver,
          auctionIncomeRecipient
        );
    }
    /**
     * @notice Calculate how much collateral someone would buy from an auction using the last read redemption price and the old current
     *         discount associated with the auction
     * @param id ID of the auction to buy collateral from
     * @param wad New bid submitted
     */
    function getApproximateCollateralBought(uint256 id, uint256 wad) external view returns (uint256, uint256) {
        if (lastReadRedemptionPrice == 0) return (0, wad);

        (bool validAuctionAndBid, uint256 adjustedBid) = getAdjustedBid(id, wad);
        if (!validAuctionAndBid) {
            return (0, adjustedBid);
        }

        // check that the oracle doesn't return an invalid value
        (uint256 collateralFsmPriceFeedValue, uint256 systemCoinPriceFeedValue) = getCollateralFSMAndFinalSystemCoinPrices(lastReadRedemptionPrice);
        if (collateralFsmPriceFeedValue == 0) {
          return (0, adjustedBid);
        }

        return (getBoughtCollateral(
          id,
          collateralFsmPriceFeedValue,
          getCollateralMedianPrice(),
          systemCoinPriceFeedValue,
          adjustedBid,
          bids[id].currentDiscount
        ), adjustedBid);
    }
    /**
     * @notice Calculate how much collateral someone would buy from an auction using the latest redemption price fetched from the
     *         OracleRelayer and the latest updated discount associated with the auction
     * @param id ID of the auction to buy collateral from
     * @param wad New bid submitted
     */
    function getCollateralBought(uint256 id, uint256 wad) external returns (uint256, uint256) {
        (bool validAuctionAndBid, uint256 adjustedBid) = getAdjustedBid(id, wad);
        if (!validAuctionAndBid) {
            return (0, adjustedBid);
        }

        // Read the redemption price
        lastReadRedemptionPrice = oracleRelayer.redemptionPrice();

        // check that the oracle doesn't return an invalid value
        (uint256 collateralFsmPriceFeedValue, uint256 systemCoinPriceFeedValue) = getCollateralFSMAndFinalSystemCoinPrices(lastReadRedemptionPrice);
        if (collateralFsmPriceFeedValue == 0) {
          return (0, adjustedBid);
        }

        return (getBoughtCollateral(
          id,
          collateralFsmPriceFeedValue,
          getCollateralMedianPrice(),
          systemCoinPriceFeedValue,
          adjustedBid,
          updateCurrentDiscount(id)
        ), adjustedBid);
    }
    /**
     * @notice Buy collateral from an auction at an increasing discount
     * @param id ID of the auction to buy collateral from
     * @param wad New bid submitted (as a WAD which has 18 decimals)
     */
    function buyCollateral(uint256 id, uint256 wad) external {
        require(both(bids[id].amountToSell > 0, bids[id].amountToRaise > 0), "IncreasingDiscountCollateralAuctionHouse/inexistent-auction");
        require(both(wad > 0, wad >= minimumBid), "IncreasingDiscountCollateralAuctionHouse/invalid-bid");

        // bound max amount offered in exchange for collateral (in case someone offers more than it's necessary)
        uint256 adjustedBid = wad;
        if (multiply(adjustedBid, RAY) > bids[id].amountToRaise) {
            adjustedBid = addUint256(bids[id].amountToRaise / RAY, 1);
        }

        // Read the redemption price
        lastReadRedemptionPrice = oracleRelayer.redemptionPrice();

        // check that the collateral FSM doesn't return an invalid value
        (uint256 collateralFsmPriceFeedValue, uint256 systemCoinPriceFeedValue) = getCollateralFSMAndFinalSystemCoinPrices(lastReadRedemptionPrice);
        require(collateralFsmPriceFeedValue > 0, "IncreasingDiscountCollateralAuctionHouse/collateral-fsm-invalid-value");

        // get the amount of collateral bought
        uint256 boughtCollateral = getBoughtCollateral(
            id, collateralFsmPriceFeedValue, getCollateralMedianPrice(), systemCoinPriceFeedValue, adjustedBid, updateCurrentDiscount(id)
        );
        // check that the calculated amount is greater than zero
        require(boughtCollateral > 0, "IncreasingDiscountCollateralAuctionHouse/null-bought-amount");
        // update the amount of collateral to sell
        bids[id].amountToSell = subtract(bids[id].amountToSell, boughtCollateral);

        // update remainingToRaise in case amountToSell is zero (everything has been sold)
        uint256 remainingToRaise = (either(multiply(wad, RAY) >= bids[id].amountToRaise, bids[id].amountToSell == 0)) ?
            bids[id].amountToRaise : subtract(bids[id].amountToRaise, multiply(wad, RAY));

        // update leftover amount to raise in the bid struct
        bids[id].amountToRaise = (multiply(adjustedBid, RAY) > bids[id].amountToRaise) ?
            0 : subtract(bids[id].amountToRaise, multiply(adjustedBid, RAY));

        // check that the remaining amount to raise is either zero or higher than RAY
        require(
          either(bids[id].amountToRaise == 0, bids[id].amountToRaise >= RAY),
          "IncreasingDiscountCollateralAuctionHouse/invalid-left-to-raise"
        );

        // transfer the bid to the income recipient and the collateral to the bidder
        safeEngine.transferInternalCoins(msg.sender, bids[id].auctionIncomeRecipient, multiply(adjustedBid, RAY));
        safeEngine.transferCollateral(collateralType, address(this), msg.sender, boughtCollateral);

        // Emit the buy event
        emit BuyCollateral(id, adjustedBid, boughtCollateral);

        // Remove coins from the liquidation buffer
        bool soldAll = either(bids[id].amountToRaise == 0, bids[id].amountToSell == 0);
        if (soldAll) {
            liquidationEngine.removeCoinsFromAuction(remainingToRaise);
        } else {
            liquidationEngine.removeCoinsFromAuction(multiply(adjustedBid, RAY));
        }

        // If the auction raised the whole amount or all collateral was sold,
        // send remaining collateral to the forgone receiver
        if (soldAll) {
            safeEngine.transferCollateral(collateralType, address(this), bids[id].forgoneCollateralReceiver, bids[id].amountToSell);
            delete bids[id];
            emit SettleAuction(id, bids[id].amountToSell);
        }
    }
    /**
     * @notice Settle/finish an auction
     * @param id ID of the auction to settle
     */
    function settleAuction(uint256 id) external {
        return;
    }
    /**
     * @notice Terminate an auction prematurely. Usually called by Global Settlement.
     * @param id ID of the auction to settle
     */
    function terminateAuctionPrematurely(uint256 id) external isAuthorized {
        require(both(bids[id].amountToSell > 0, bids[id].amountToRaise > 0), "IncreasingDiscountCollateralAuctionHouse/inexistent-auction");
        liquidationEngine.removeCoinsFromAuction(bids[id].amountToRaise);
        safeEngine.transferCollateral(collateralType, address(this), msg.sender, bids[id].amountToSell);
        delete bids[id];
        emit TerminateAuctionPrematurely(id, msg.sender, bids[id].amountToSell);
    }

    // --- Getters ---
    function bidAmount(uint256 id) public view returns (uint256) {
        return 0;
    }
    function remainingAmountToSell(uint256 id) public view returns (uint256) {
        return bids[id].amountToSell;
    }
    function forgoneCollateralReceiver(uint256 id) public view returns (address) {
        return bids[id].forgoneCollateralReceiver;
    }
    function raisedAmount(uint256 id) public view returns (uint256) {
        return 0;
    }
    function amountToRaise(uint256 id) public view returns (uint256) {
        return bids[id].amountToRaise;
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/DebtAuctionHouse.sol
/// DebtAuctionHouse.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

abstract contract SAFEEngineLike_6 {
    function transferInternalCoins(address,address,uint256) virtual external;
    function createUnbackedDebt(address,address,uint256) virtual external;
}
abstract contract TokenLike_1 {
    function mint(address,uint256) virtual external;
}
abstract contract AccountingEngineLike_1 {
    function totalOnAuctionDebt() virtual public returns (uint256);
    function cancelAuctionedDebtWithSurplus(uint256) virtual external;
}

/*
   This thing creates protocol tokens on demand in return for system coins
*/

contract DebtAuctionHouse {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "DebtAuctionHouse/account-not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        // Bid size
        uint256 bidAmount;                                                        // [rad]
        // How many protocol tokens are sold in an auction
        uint256 amountToSell;                                                     // [wad]
        // Who the high bidder is
        address highBidder;
        // When the latest bid expires and the auction can be settled
        uint48  bidExpiry;                                                        // [unix epoch time]
        // Hard deadline for the auction after which no more bids can be placed
        uint48  auctionDeadline;                                                  // [unix epoch time]
    }

    // Bid data for each separate auction
    mapping (uint256 => Bid) public bids;

    // SAFE database
    SAFEEngineLike_6 public safeEngine;
    // Protocol token address
    TokenLike_1 public protocolToken;
    // Accounting engine
    address public accountingEngine;

    uint256  constant ONE = 1.00E18;                                              // [wad]
    // Minimum bid increase compared to the last bid in order to take the new one in consideration
    uint256  public   bidDecrease = 1.05E18;                                      // [wad]
    // Increase in protocol tokens sold in case an auction is restarted
    uint256  public   amountSoldIncrease = 1.50E18;                               // [wad]
    // How long the auction lasts after a new bid is submitted
    uint48   public   bidDuration = 3 hours;                                      // [seconds]
    // Total length of the auction
    uint48   public   totalAuctionLength = 2 days;                                // [seconds]
    // Number of auctions started up until now
    uint256  public   auctionsStarted = 0;
    // Accumulator for all debt auctions currently not settled
    uint256  public   activeDebtAuctions;
    uint256  public   contractEnabled;

    bytes32 public constant AUCTION_HOUSE_TYPE = bytes32("DEBT");

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event StartAuction(
      uint256 indexed id,
      uint256 auctionsStarted,
      uint256 amountToSell,
      uint256 initialBid,
      address indexed incomeReceiver,
      uint256 indexed auctionDeadline,
      uint256 activeDebtAuctions
    );
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event RestartAuction(uint256 indexed id, uint256 auctionDeadline);
    event DecreaseSoldAmount(uint256 indexed id, address highBidder, uint256 amountToBuy, uint256 bid, uint256 bidExpiry);
    event SettleAuction(uint256 indexed id, uint256 activeDebtAuctions);
    event TerminateAuctionPrematurely(uint256 indexed id, address sender, address highBidder, uint256 bidAmount, uint256 activeDebtAuctions);
    event DisableContract(address sender);

    // --- Init ---
    constructor(address safeEngine_, address protocolToken_) public {
        authorizedAccounts[msg.sender] = 1;
        safeEngine = SAFEEngineLike_6(safeEngine_);
        protocolToken = TokenLike_1(protocolToken_);
        contractEnabled = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addUint48(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x, "DebtAuctionHouse/add-uint48-overflow");
    }
    function addUint256(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "DebtAuctionHouse/add-uint256-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "DebtAuctionHouse/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "DebtAuctionHouse/mul-overflow");
    }
    function minimum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) { z = y; } else { z = x; }
    }

    // --- Admin ---
    /**
     * @notice Modify an uint256 parameter
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "bidDecrease") bidDecrease = data;
        else if (parameter == "amountSoldIncrease") amountSoldIncrease = data;
        else if (parameter == "bidDuration") bidDuration = uint48(data);
        else if (parameter == "totalAuctionLength") totalAuctionLength = uint48(data);
        else revert("DebtAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify an address parameter
     * @param parameter The name of the oracle contract modified
     * @param addr New contract address
     */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(contractEnabled == 1, "DebtAuctionHouse/contract-not-enabled");
        if (parameter == "protocolToken") protocolToken = TokenLike_1(addr);
        else if (parameter == "accountingEngine") accountingEngine = addr;
        else revert("DebtAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    // --- Auction ---
    /**
     * @notice Start a new debt auction
     * @param incomeReceiver Who receives the auction proceeds
     * @param amountToSell Amount of protocol tokens to sell (wad)
     * @param initialBid Initial bid size (rad)
     */
    function startAuction(
        address incomeReceiver,
        uint256 amountToSell,
        uint256 initialBid
    ) external isAuthorized returns (uint256 id) {
        require(contractEnabled == 1, "DebtAuctionHouse/contract-not-enabled");
        require(auctionsStarted < uint256(-1), "DebtAuctionHouse/overflow");
        id = ++auctionsStarted;

        bids[id].bidAmount = initialBid;
        bids[id].amountToSell = amountToSell;
        bids[id].highBidder = incomeReceiver;
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);

        activeDebtAuctions = addUint256(activeDebtAuctions, 1);

        emit StartAuction(id, auctionsStarted, amountToSell, initialBid, incomeReceiver, bids[id].auctionDeadline, activeDebtAuctions);
    }
    /**
     * @notice Restart an auction if no bids were submitted for it
     * @param id ID of the auction to restart
     */
    function restartAuction(uint256 id) external {
        require(id <= auctionsStarted, "DebtAuctionHouse/auction-never-started");
        require(bids[id].auctionDeadline < now, "DebtAuctionHouse/not-finished");
        require(bids[id].bidExpiry == 0, "DebtAuctionHouse/bid-already-placed");
        bids[id].amountToSell = multiply(amountSoldIncrease, bids[id].amountToSell) / ONE;
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);
        emit RestartAuction(id, bids[id].auctionDeadline);
    }
    /**
     * @notice Decrease the protocol token amount you're willing to receive in
     *         exchange for providing the same amount of system coins being raised by the auction
     * @param id ID of the auction for which you want to submit a new bid
     * @param amountToBuy Amount of protocol tokens to buy (must be smaller than the previous proposed amount) (wad)
     * @param bid New system coin bid (must always equal the total amount raised by the auction) (rad)
     */
    function decreaseSoldAmount(uint256 id, uint256 amountToBuy, uint256 bid) external {
        require(contractEnabled == 1, "DebtAuctionHouse/contract-not-enabled");
        require(bids[id].highBidder != address(0), "DebtAuctionHouse/high-bidder-not-set");
        require(bids[id].bidExpiry > now || bids[id].bidExpiry == 0, "DebtAuctionHouse/bid-already-expired");
        require(bids[id].auctionDeadline > now, "DebtAuctionHouse/auction-already-expired");

        require(bid == bids[id].bidAmount, "DebtAuctionHouse/not-matching-bid");
        require(amountToBuy <  bids[id].amountToSell, "DebtAuctionHouse/amount-bought-not-lower");
        require(multiply(bidDecrease, amountToBuy) <= multiply(bids[id].amountToSell, ONE), "DebtAuctionHouse/insufficient-decrease");

        safeEngine.transferInternalCoins(msg.sender, bids[id].highBidder, bid);

        // on first bid submitted, clear as much totalOnAuctionDebt as possible
        if (bids[id].bidExpiry == 0) {
            uint256 totalOnAuctionDebt = AccountingEngineLike_1(bids[id].highBidder).totalOnAuctionDebt();
            AccountingEngineLike_1(bids[id].highBidder).cancelAuctionedDebtWithSurplus(minimum(bid, totalOnAuctionDebt));
        }

        bids[id].highBidder = msg.sender;
        bids[id].amountToSell = amountToBuy;
        bids[id].bidExpiry = addUint48(uint48(now), bidDuration);

        emit DecreaseSoldAmount(id, msg.sender, amountToBuy, bid, bids[id].bidExpiry);
    }
    /**
     * @notice Settle/finish an auction
     * @param id ID of the auction to settle
     */
    function settleAuction(uint256 id) external {
        require(contractEnabled == 1, "DebtAuctionHouse/not-live");
        require(bids[id].bidExpiry != 0 && (bids[id].bidExpiry < now || bids[id].auctionDeadline < now), "DebtAuctionHouse/not-finished");
        protocolToken.mint(bids[id].highBidder, bids[id].amountToSell);
        activeDebtAuctions = subtract(activeDebtAuctions, 1);
        delete bids[id];
        emit SettleAuction(id, activeDebtAuctions);
    }

    // --- Shutdown ---
    /**
    * @notice Disable the auction house (usually called by the AccountingEngine)
    */
    function disableContract() external isAuthorized {
        contractEnabled    = 0;
        accountingEngine   = msg.sender;
        activeDebtAuctions = 0;
        emit DisableContract(msg.sender);
    }
    /**
     * @notice Terminate an auction prematurely
     * @param id ID of the auction to terminate
     */
    function terminateAuctionPrematurely(uint256 id) external {
        require(contractEnabled == 0, "DebtAuctionHouse/contract-still-enabled");
        require(bids[id].highBidder != address(0), "DebtAuctionHouse/high-bidder-not-set");
        safeEngine.createUnbackedDebt(accountingEngine, bids[id].highBidder, bids[id].bidAmount);
        emit TerminateAuctionPrematurely(id, msg.sender, bids[id].highBidder, bids[id].bidAmount, activeDebtAuctions);
        delete bids[id];
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/GlobalSettlement.sol
/// GlobalSettlement.sol

// Copyright (C) 2018 Rain <[email protected]>
// Copyright (C) 2018 Lev Livnev <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

abstract contract SAFEEngineLike_7 {
    function coinBalance(address) virtual public view returns (uint256);
    function collateralTypes(bytes32) virtual public view returns (
        uint256 debtAmount,        // [wad]
        uint256 accumulatedRate,   // [ray]
        uint256 safetyPrice,       // [ray]
        uint256 debtCeiling,       // [rad]
        uint256 debtFloor,         // [rad]
        uint256 liquidationPrice   // [ray]
    );
    function safes(bytes32,address) virtual public view returns (
        uint256 lockedCollateral, // [wad]
        uint256 generatedDebt     // [wad]
    );
    function globalDebt() virtual public returns (uint256);
    function transferInternalCoins(address src, address dst, uint256 rad) virtual external;
    function approveSAFEModification(address) virtual external;
    function transferCollateral(bytes32 collateralType, address src, address dst, uint256 wad) virtual external;
    function confiscateSAFECollateralAndDebt(bytes32 collateralType, address safe, address collateralSource, address debtDestination, int256 deltaCollateral, int256 deltaDebt) virtual external;
    function createUnbackedDebt(address debtDestination, address coinDestination, uint256 rad) virtual external;
    function disableContract() virtual external;
}
abstract contract LiquidationEngineLike_2 {
    function collateralTypes(bytes32) virtual public view returns (
        address collateralAuctionHouse,
        uint256 liquidationPenalty,     // [wad]
        uint256 liquidationQuantity     // [rad]
    );
    function disableContract() virtual external;
}
abstract contract StabilityFeeTreasuryLike {
    function disableContract() virtual external;
}
abstract contract AccountingEngineLike_2 {
    function disableContract() virtual external;
}
abstract contract CoinSavingsAccountLike {
    function disableContract() virtual external;
}
abstract contract CollateralAuctionHouseLike_1 {
    function bidAmount(uint256 id) virtual public view returns (uint256);
    function raisedAmount(uint256 id) virtual public view returns (uint256);
    function remainingAmountToSell(uint256 id) virtual public view returns (uint256);
    function forgoneCollateralReceiver(uint256 id) virtual public view returns (address);
    function amountToRaise(uint256 id) virtual public view returns (uint256);
    function terminateAuctionPrematurely(uint256 auctionId) virtual external;
}
abstract contract OracleLike_2 {
    function read() virtual public view returns (uint256);
}
abstract contract OracleRelayerLike_2 {
    function redemptionPrice() virtual public returns (uint256);
    function collateralTypes(bytes32) virtual public view returns (
        OracleLike_2 orcl,
        uint256 safetyCRatio,
        uint256 liquidationCRatio
    );
    function disableContract() virtual external;
}

/*
    This is the Global Settlement module. It is an
    involved, stateful process that takes place over nine steps.
    First we freeze the system and lock the prices for each collateral type.
    1. `shutdownSystem()`:
        - freezes user entrypoints
        - starts cooldown period
    2. `freezeCollateralType(collateralType)`:
       - set the final price for each collateralType, reading off the price feed
    We must process some system state before it is possible to calculate
    the final coin / collateral price. In particular, we need to determine:
      a. `collateralShortfall` (considers under-collateralised SAFEs)
      b. `outstandingCoinSupply` (after including system surplus / deficit)
    We determine (a) by processing all under-collateralised SAFEs with
    `processSAFE`
    3. `processSAFE(collateralType, safe)`:
       - cancels SAFE debt
       - any excess collateral remains
       - backing collateral taken
    We determine (b) by processing ongoing coin generating processes,
    i.e. auctions. We need to ensure that auctions will not generate any
    further coin income. In the two-way auction model this occurs when
    all auctions are in the reverse (`decreaseSoldAmount`) phase. There are two ways
    of ensuring this:
    4.  i) `shutdownCooldown`: set the cooldown period to be at least as long as the
           longest auction duration, which needs to be determined by the
           shutdown administrator.
           This takes a fairly predictable time to occur but with altered
           auction dynamics due to the now varying price of the system coin.
       ii) `fastTrackAuction`: cancel all ongoing auctions and seize the collateral.
           This allows for faster processing at the expense of more
           processing calls. This option allows coin holders to retrieve
           their collateral faster.
           `fastTrackAuction(collateralType, auctionId)`:
            - cancel individual collateral auctions in the `increaseBidSize` (forward) phase
            - retrieves collateral and returns coins to bidder
            - `decreaseSoldAmount` (reverse) phase auctions can continue normally
    Option (i), `shutdownCooldown`, is sufficient for processing the system
    settlement but option (ii), `fastTrackAuction`, will speed it up. Both options
    are available in this implementation, with `fastTrackAuction` being enabled on a
    per-auction basis.
    When a SAFE has been processed and has no debt remaining, the
    remaining collateral can be removed.
    5. `freeCollateral(collateralType)`:
        - remove collateral from the caller's SAFE
        - owner can call as needed
    After the processing period has elapsed, we enable calculation of
    the final price for each collateral type.
    6. `setOutstandingCoinSupply()`:
       - only callable after processing time period elapsed
       - assumption that all under-collateralised SAFEs are processed
       - fixes the total outstanding supply of coin
       - may also require extra SAFE processing to cover system surplus
    7. `calculateCashPrice(collateralType)`:
        - calculate `collateralCashPrice`
        - adjusts `collateralCashPrice` in the case of deficit / surplus
    At this point we have computed the final price for each collateral
    type and coin holders can now turn their coin into collateral. Each
    unit coin can claim a fixed basket of collateral.
    Coin holders must first `prepareCoinsForRedeeming` into a `coinBag`. Once prepared,
    coins cannot be transferred out of the bag. More coin can be added to a bag later.
    8. `prepareCoinsForRedeeming(coinAmount)`:
        - put some coins into a bag in order to 'redeemCollateral'. The bigger the bag, the more collateral the user can claim.
    9. `redeemCollateral(collateralType, collateralAmount)`:
        - exchange some coin from your bag for tokens from a specific collateral type
        - the amount of collateral available to redeem is limited by how big your bag is
*/

contract GlobalSettlement {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "GlobalSettlement/account-not-authorized");
        _;
    }

    // --- Data ---
    SAFEEngineLike_7           public safeEngine;
    LiquidationEngineLike_2    public liquidationEngine;
    AccountingEngineLike_2     public accountingEngine;
    OracleRelayerLike_2        public oracleRelayer;
    CoinSavingsAccountLike   public coinSavingsAccount;
    StabilityFeeTreasuryLike public stabilityFeeTreasury;

    // Flag that indicates whether settlement has been triggered or not
    uint256  public contractEnabled;
    // The timestamp when settlement was triggered
    uint256  public shutdownTime;
    // The amount of time post settlement during which no processing takes place
    uint256  public shutdownCooldown;
    // The outstanding supply of system coins computed during the setOutstandingCoinSupply() phase
    uint256  public outstandingCoinSupply;                                      // [rad]

    // The amount of collateral that a system coin can redeem
    mapping (bytes32 => uint256) public finalCoinPerCollateralPrice;            // [ray]
    // Total amount of bad debt in SAFEs with different collateral types
    mapping (bytes32 => uint256) public collateralShortfall;                    // [wad]
    // Total debt backed by every collateral type
    mapping (bytes32 => uint256) public collateralTotalDebt;                    // [wad]
    // Mapping of collateral prices in terms of system coins after taking into account system surplus/deficit and finalCoinPerCollateralPrices
    mapping (bytes32 => uint256) public collateralCashPrice;                    // [ray]

    // Bags of coins ready to be used for collateral redemption
    mapping (address => uint256)                      public coinBag;           // [wad]
    // Amount of coins already used for collateral redemption by every address and for different collateral types
    mapping (bytes32 => mapping (address => uint256)) public coinsUsedToRedeem; // [wad]

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event ShutdownSystem();
    event FreezeCollateralType(bytes32 indexed collateralType, uint256 finalCoinPerCollateralPrice);
    event FastTrackAuction(bytes32 indexed collateralType, uint256 auctionId, uint256 collateralTotalDebt);
    event ProcessSAFE(bytes32 indexed collateralType, address safe, uint256 collateralShortfall);
    event FreeCollateral(bytes32 indexed collateralType, address sender, int256 collateralAmount);
    event SetOutstandingCoinSupply(uint256 outstandingCoinSupply);
    event CalculateCashPrice(bytes32 indexed collateralType, uint256 collateralCashPrice);
    event PrepareCoinsForRedeeming(address indexed sender, uint256 coinBag);
    event RedeemCollateral(bytes32 indexed collateralType, address indexed sender, uint256 coinsAmount, uint256 collateralAmount);

    // --- Init ---
    constructor() public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x, "GlobalSettlement/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "GlobalSettlement/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "GlobalSettlement/mul-overflow");
    }
    function minimum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    function rmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "GlobalSettlement/rdiv-by-zero");
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "GlobalSettlement/wdiv-by-zero");
        z = multiply(x, WAD) / y;
    }

    // --- Administration ---
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the parameter to modify
    * @param data The new address for the parameter
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(contractEnabled == 1, "GlobalSettlement/contract-not-enabled");
        if (parameter == "safeEngine") safeEngine = SAFEEngineLike_7(data);
        else if (parameter == "liquidationEngine") liquidationEngine = LiquidationEngineLike_2(data);
        else if (parameter == "accountingEngine") accountingEngine = AccountingEngineLike_2(data);
        else if (parameter == "oracleRelayer") oracleRelayer = OracleRelayerLike_2(data);
        else if (parameter == "coinSavingsAccount") coinSavingsAccount = CoinSavingsAccountLike(data);
        else if (parameter == "stabilityFeeTreasury") stabilityFeeTreasury = StabilityFeeTreasuryLike(data);
        else revert("GlobalSettlement/modify-unrecognized-parameter");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to modify
    * @param data The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        require(contractEnabled == 1, "GlobalSettlement/contract-not-enabled");
        if (parameter == "shutdownCooldown") shutdownCooldown = data;
        else revert("GlobalSettlement/modify-unrecognized-parameter");
        emit ModifyParameters(parameter, data);
    }

    // --- Settlement ---
    /**
     * @notice Freeze the system and start the cooldown period
     */
    function shutdownSystem() external isAuthorized {
        require(contractEnabled == 1, "GlobalSettlement/contract-not-enabled");
        contractEnabled = 0;
        shutdownTime = now;
        safeEngine.disableContract();
        liquidationEngine.disableContract();
        // treasury must be disabled before the accounting engine so that all surplus is gathered in one place
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.disableContract();
        }
        accountingEngine.disableContract();
        oracleRelayer.disableContract();
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.disableContract();
        }
        emit ShutdownSystem();
    }
    /**
     * @notice Calculate a collateral type's final price according to the latest system coin redemption price
     * @param collateralType The collateral type to calculate the price for
     */
    function freezeCollateralType(bytes32 collateralType) external {
        require(contractEnabled == 0, "GlobalSettlement/contract-still-enabled");
        require(finalCoinPerCollateralPrice[collateralType] == 0, "GlobalSettlement/final-collateral-price-already-defined");
        (collateralTotalDebt[collateralType],,,,,) = safeEngine.collateralTypes(collateralType);
        (OracleLike_2 orcl,,) = oracleRelayer.collateralTypes(collateralType);
        // redemptionPrice is a ray, orcl returns a wad
        finalCoinPerCollateralPrice[collateralType] = wdivide(oracleRelayer.redemptionPrice(), uint256(orcl.read()));
        emit FreezeCollateralType(collateralType, finalCoinPerCollateralPrice[collateralType]);
    }
    /**
     * @notice Fast track an ongoing collateral auction
     * @param collateralType The collateral type associated with the auction contract
     * @param auctionId The ID of the auction to be fast tracked
     */
    function fastTrackAuction(bytes32 collateralType, uint256 auctionId) external {
        require(finalCoinPerCollateralPrice[collateralType] != 0, "GlobalSettlement/final-collateral-price-not-defined");

        (address auctionHouse_,,)       = liquidationEngine.collateralTypes(collateralType);
        CollateralAuctionHouseLike_1 collateralAuctionHouse = CollateralAuctionHouseLike_1(auctionHouse_);
        (, uint256 accumulatedRate,,,,) = safeEngine.collateralTypes(collateralType);

        uint256 bidAmount                 = collateralAuctionHouse.bidAmount(auctionId);
        uint256 raisedAmount              = collateralAuctionHouse.raisedAmount(auctionId);
        uint256 collateralToSell          = collateralAuctionHouse.remainingAmountToSell(auctionId);
        address forgoneCollateralReceiver = collateralAuctionHouse.forgoneCollateralReceiver(auctionId);
        uint256 amountToRaise             = collateralAuctionHouse.amountToRaise(auctionId);

        safeEngine.createUnbackedDebt(address(accountingEngine), address(accountingEngine), subtract(amountToRaise, raisedAmount));
        safeEngine.createUnbackedDebt(address(accountingEngine), address(this), bidAmount);
        safeEngine.approveSAFEModification(address(collateralAuctionHouse));
        collateralAuctionHouse.terminateAuctionPrematurely(auctionId);

        uint256 debt_ = subtract(amountToRaise, raisedAmount) / accumulatedRate;
        collateralTotalDebt[collateralType] = addition(collateralTotalDebt[collateralType], debt_);
        require(int256(collateralToSell) >= 0 && int256(debt_) >= 0, "GlobalSettlement/overflow");
        safeEngine.confiscateSAFECollateralAndDebt(collateralType, forgoneCollateralReceiver, address(this), address(accountingEngine), int256(collateralToSell), int256(debt_));
        emit FastTrackAuction(collateralType, auctionId, collateralTotalDebt[collateralType]);
    }
    /**
     * @notice Cancel a SAFE's debt and leave any extra collateral in it
     * @param collateralType The collateral type associated with the SAFE
     * @param safe The SAFE to be processed
     */
    function processSAFE(bytes32 collateralType, address safe) external {
        require(finalCoinPerCollateralPrice[collateralType] != 0, "GlobalSettlement/final-collateral-price-not-defined");
        (, uint256 accumulatedRate,,,,) = safeEngine.collateralTypes(collateralType);
        (uint256 safeCollateral, uint256 safeDebt) = safeEngine.safes(collateralType, safe);

        uint256 amountOwed = rmultiply(rmultiply(safeDebt, accumulatedRate), finalCoinPerCollateralPrice[collateralType]);
        uint256 minCollateral = minimum(safeCollateral, amountOwed);
        collateralShortfall[collateralType] = addition(
            collateralShortfall[collateralType],
            subtract(amountOwed, minCollateral)
        );

        require(minCollateral <= 2**255 && safeDebt <= 2**255, "GlobalSettlement/overflow");
        safeEngine.confiscateSAFECollateralAndDebt(
            collateralType,
            safe,
            address(this),
            address(accountingEngine),
            -int256(minCollateral),
            -int256(safeDebt)
        );

        emit ProcessSAFE(collateralType, safe, collateralShortfall[collateralType]);
    }
    /**
     * @notice Remove collateral from the caller's SAFE
     * @param collateralType The collateral type to free
     */
    function freeCollateral(bytes32 collateralType) external {
        require(contractEnabled == 0, "GlobalSettlement/contract-still-enabled");
        (uint256 safeCollateral, uint256 safeDebt) = safeEngine.safes(collateralType, msg.sender);
        require(safeDebt == 0, "GlobalSettlement/safe-debt-not-zero");
        require(safeCollateral <= 2**255, "GlobalSettlement/overflow");
        safeEngine.confiscateSAFECollateralAndDebt(
          collateralType,
          msg.sender,
          msg.sender,
          address(accountingEngine),
          -int256(safeCollateral),
          0
        );
        emit FreeCollateral(collateralType, msg.sender, -int256(safeCollateral));
    }
    /**
     * @notice Set the final outstanding supply of system coins
     * @dev There must be no remaining surplus in the accounting engine
     */
    function setOutstandingCoinSupply() external {
        require(contractEnabled == 0, "GlobalSettlement/contract-still-enabled");
        require(outstandingCoinSupply == 0, "GlobalSettlement/outstanding-coin-supply-not-zero");
        require(safeEngine.coinBalance(address(accountingEngine)) == 0, "GlobalSettlement/surplus-not-zero");
        require(now >= addition(shutdownTime, shutdownCooldown), "GlobalSettlement/shutdown-cooldown-not-finished");
        outstandingCoinSupply = safeEngine.globalDebt();
        emit SetOutstandingCoinSupply(outstandingCoinSupply);
    }
    /**
     * @notice Calculate a collateral's price taking into consideration system surplus/deficit and the finalCoinPerCollateralPrice
     * @param collateralType The collateral whose cash price will be calculated
     */
    function calculateCashPrice(bytes32 collateralType) external {
        require(outstandingCoinSupply != 0, "GlobalSettlement/outstanding-coin-supply-zero");
        require(collateralCashPrice[collateralType] == 0, "GlobalSettlement/collateral-cash-price-already-defined");

        (, uint256 accumulatedRate,,,,) = safeEngine.collateralTypes(collateralType);
        uint256 redemptionAdjustedDebt = rmultiply(
          rmultiply(collateralTotalDebt[collateralType], accumulatedRate), finalCoinPerCollateralPrice[collateralType]
        );
        collateralCashPrice[collateralType] =
          multiply(subtract(redemptionAdjustedDebt, collateralShortfall[collateralType]), RAY) / (outstandingCoinSupply / RAY);

        emit CalculateCashPrice(collateralType, collateralCashPrice[collateralType]);
    }
    /**
     * @notice Add coins into a 'bag' so that you can use them to redeem collateral
     * @param coinAmount The amount of internal system coins to add into the bag
     */
    function prepareCoinsForRedeeming(uint256 coinAmount) external {
        require(outstandingCoinSupply != 0, "GlobalSettlement/outstanding-coin-supply-zero");
        safeEngine.transferInternalCoins(msg.sender, address(accountingEngine), multiply(coinAmount, RAY));
        coinBag[msg.sender] = addition(coinBag[msg.sender], coinAmount);
        emit PrepareCoinsForRedeeming(msg.sender, coinBag[msg.sender]);
    }
    /**
     * @notice Redeem a specific collateral type using an amount of internal system coins from your bag
     * @param collateralType The collateral type to redeem
     * @param coinsAmount The amount of internal coins to use from your bag
     */
    function redeemCollateral(bytes32 collateralType, uint256 coinsAmount) external {
        require(collateralCashPrice[collateralType] != 0, "GlobalSettlement/collateral-cash-price-not-defined");
        uint256 collateralAmount = rmultiply(coinsAmount, collateralCashPrice[collateralType]);
        safeEngine.transferCollateral(
          collateralType,
          address(this),
          msg.sender,
          collateralAmount
        );
        coinsUsedToRedeem[collateralType][msg.sender] = addition(coinsUsedToRedeem[collateralType][msg.sender], coinsAmount);
        require(coinsUsedToRedeem[collateralType][msg.sender] <= coinBag[msg.sender], "GlobalSettlement/insufficient-bag-balance");
        emit RedeemCollateral(collateralType, msg.sender, coinsAmount, collateralAmount);
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/LiquidationEngine.sol
/// LiquidationEngine.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

abstract contract CollateralAuctionHouseLike_2 {
    function startAuction(
      address forgoneCollateralReceiver,
      address initialBidder,
      uint256 amountToRaise,
      uint256 collateralToSell,
      uint256 initialBid
    ) virtual public returns (uint256);
}
abstract contract SAFESaviourLike {
    function saveSAFE(address,bytes32,address) virtual external returns (bool,uint256,uint256);
}
abstract contract SAFEEngineLike_8 {
    function collateralTypes(bytes32) virtual public view returns (
        uint256 debtAmount,        // [wad]
        uint256 accumulatedRate,   // [ray]
        uint256 safetyPrice,       // [ray]
        uint256 debtCeiling,       // [rad]
        uint256 debtFloor,         // [rad]
        uint256 liquidationPrice   // [ray]
    );
    function safes(bytes32,address) virtual public view returns (
        uint256 lockedCollateral,  // [wad]
        uint256 generatedDebt      // [wad]
    );
    function confiscateSAFECollateralAndDebt(bytes32,address,address,address,int256,int256) virtual external;
    function canModifySAFE(address, address) virtual public view returns (bool);
    function approveSAFEModification(address) virtual external;
    function denySAFEModification(address) virtual external;
}
abstract contract AccountingEngineLike_3 {
    function pushDebtToQueue(uint256) virtual external;
}

contract LiquidationEngine {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "LiquidationEngine/account-not-authorized");
        _;
    }

    // --- SAFE Saviours ---
    // Contracts that can save SAFEs from liquidation
    mapping (address => uint256) public safeSaviours;
    /**
    * @notice Authed function to add contracts that can save SAFEs from liquidation
    * @param saviour SAFE saviour contract to be whitelisted
    **/
    function connectSAFESaviour(address saviour) external isAuthorized {
        (bool ok, uint256 collateralAdded, uint256 liquidatorReward) =
          SAFESaviourLike(saviour).saveSAFE(address(this), "", address(0));
        require(ok, "LiquidationEngine/saviour-not-ok");
        require(both(collateralAdded == uint256(-1), liquidatorReward == uint256(-1)), "LiquidationEngine/invalid-amounts");
        safeSaviours[saviour] = 1;
        emit ConnectSAFESaviour(saviour);
    }
    /**
    * @notice Governance used function to remove contracts that can save SAFEs from liquidation
    * @param saviour SAFE saviour contract to be removed
    **/
    function disconnectSAFESaviour(address saviour) external isAuthorized {
        safeSaviours[saviour] = 0;
        emit DisconnectSAFESaviour(saviour);
    }

    // --- Data ---
    struct CollateralType {
        // Address of the collateral auction house handling liquidations for this collateral type
        address collateralAuctionHouse;
        // Penalty applied to every liquidation involving this collateral type. Discourages SAFE users from bidding on their own SAFEs
        uint256 liquidationPenalty;                                                                                                   // [wad]
        // Max amount of system coins to request in one auction
        uint256 liquidationQuantity;                                                                                                  // [rad]
    }

    // Collateral types included in the system
    mapping (bytes32 => CollateralType)              public collateralTypes;
    // Saviour contract chosen for each SAFE by its creator
    mapping (bytes32 => mapping(address => address)) public chosenSAFESaviour;
    // Mutex used to block against re-entrancy when 'liquidateSAFE' passes execution to a saviour
    mapping (bytes32 => mapping(address => uint8))   public mutex;

    // Max amount of system coins that can be on liquidation at any time
    uint256 public onAuctionSystemCoinLimit;                                // [rad]
    // Current amount of system coins out for liquidation
    uint256 public currentOnAuctionSystemCoins;                             // [rad]
    // Whether this contract is enabled
    uint256 public contractEnabled;

    SAFEEngineLike_8       public safeEngine;
    AccountingEngineLike_3 public accountingEngine;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ConnectSAFESaviour(address saviour);
    event DisconnectSAFESaviour(address saviour);
    event UpdateCurrentOnAuctionSystemCoins(uint256 currentOnAuctionSystemCoins);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event ModifyParameters(
      bytes32 collateralType,
      bytes32 parameter,
      uint256 data
    );
    event ModifyParameters(
      bytes32 collateralType,
      bytes32 parameter,
      address data
    );
    event DisableContract();
    event Liquidate(
      bytes32 indexed collateralType,
      address indexed safe,
      uint256 collateralAmount,
      uint256 debtAmount,
      uint256 amountToRaise,
      address collateralAuctioneer,
      uint256 auctionId
    );
    event SaveSAFE(
      bytes32 indexed collateralType,
      address indexed safe,
      uint256 collateralAddedOrDebtRepaid
    );
    event FailedSAFESave(bytes failReason);
    event ProtectSAFE(
      bytes32 indexed collateralType,
      address indexed safe,
      address saviour
    );

    // --- Init ---
    constructor(address safeEngine_) public {
        authorizedAccounts[msg.sender] = 1;

        safeEngine               = SAFEEngineLike_8(safeEngine_);
        onAuctionSystemCoinLimit = uint256(-1);
        contractEnabled          = 1;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("onAuctionSystemCoinLimit", uint256(-1));
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant MAX_LIQUIDATION_QUANTITY = uint256(-1) / RAY;

    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "LiquidationEngine/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "LiquidationEngine/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "LiquidationEngine/mul-overflow");
    }
    function minimum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) { z = y; } else { z = x; }
    }

    // --- Utils ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Administration ---
    /*
    * @notice Modify uint256 parameters
    * @param paramter The name of the parameter modified
    * @param data Value for the new parameter
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "onAuctionSystemCoinLimit") onAuctionSystemCoinLimit = data;
        else revert("LiquidationEngine/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify contract integrations
     * @param parameter The name of the parameter modified
     * @param data New address for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "accountingEngine") accountingEngine = AccountingEngineLike_3(data);
        else revert("LiquidationEngine/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify liquidation params
     * @param collateralType The collateral type we change parameters for
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) external isAuthorized {
        if (parameter == "liquidationPenalty") collateralTypes[collateralType].liquidationPenalty = data;
        else if (parameter == "liquidationQuantity") {
          require(data <= MAX_LIQUIDATION_QUANTITY, "LiquidationEngine/liquidation-quantity-overflow");
          collateralTypes[collateralType].liquidationQuantity = data;
        }
        else revert("LiquidationEngine/modify-unrecognized-param");
        emit ModifyParameters(
          collateralType,
          parameter,
          data
        );
    }
    /**
     * @notice Modify collateral auction address
     * @param collateralType The collateral type we change parameters for
     * @param parameter The name of the integration modified
     * @param data New address for the integration contract
     */
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        address data
    ) external isAuthorized {
        if (parameter == "collateralAuctionHouse") {
            safeEngine.denySAFEModification(collateralTypes[collateralType].collateralAuctionHouse);
            collateralTypes[collateralType].collateralAuctionHouse = data;
            safeEngine.approveSAFEModification(data);
        }
        else revert("LiquidationEngine/modify-unrecognized-param");
        emit ModifyParameters(
            collateralType,
            parameter,
            data
        );
    }
    /**
     * @notice Disable this contract (normally called by GlobalSettlement)
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }

    // --- SAFE Liquidation ---
    /**
     * @notice Choose a saviour contract for your SAFE
     * @param collateralType The SAFE's collateral type
     * @param safe The SAFE's address
     * @param saviour The chosen saviour
     */
    function protectSAFE(
        bytes32 collateralType,
        address safe,
        address saviour
    ) external {
        require(safeEngine.canModifySAFE(safe, msg.sender), "LiquidationEngine/cannot-modify-safe");
        require(saviour == address(0) || safeSaviours[saviour] == 1, "LiquidationEngine/saviour-not-authorized");
        chosenSAFESaviour[collateralType][safe] = saviour;
        emit ProtectSAFE(
            collateralType,
            safe,
            saviour
        );
    }
    /**
     * @notice Liquidate a SAFE
     * @param collateralType The SAFE's collateral type
     * @param safe The SAFE's address
     */
    function liquidateSAFE(bytes32 collateralType, address safe) external returns (uint256 auctionId) {
        require(mutex[collateralType][safe] == 0, "LiquidationEngine/non-null-mutex");
        mutex[collateralType][safe] = 1;

        (, uint256 accumulatedRate, , , uint256 debtFloor, uint256 liquidationPrice) = safeEngine.collateralTypes(collateralType);
        (uint256 safeCollateral, uint256 safeDebt) = safeEngine.safes(collateralType, safe);

        require(contractEnabled == 1, "LiquidationEngine/contract-not-enabled");
        require(both(
          liquidationPrice > 0,
          multiply(safeCollateral, liquidationPrice) < multiply(safeDebt, accumulatedRate)
        ), "LiquidationEngine/safe-not-unsafe");
        require(
          both(currentOnAuctionSystemCoins < onAuctionSystemCoinLimit,
          subtract(onAuctionSystemCoinLimit, currentOnAuctionSystemCoins) >= debtFloor),
          "LiquidationEngine/liquidation-limit-hit"
        );

        if (chosenSAFESaviour[collateralType][safe] != address(0) &&
            safeSaviours[chosenSAFESaviour[collateralType][safe]] == 1) {
          try SAFESaviourLike(chosenSAFESaviour[collateralType][safe]).saveSAFE(msg.sender, collateralType, safe)
            returns (bool ok, uint256 collateralAddedOrDebtRepaid, uint256) {
            if (both(ok, collateralAddedOrDebtRepaid > 0)) {
              emit SaveSAFE(collateralType, safe, collateralAddedOrDebtRepaid);
            }
          } catch (bytes memory revertReason) {
            emit FailedSAFESave(revertReason);
          }
        }

        // Checks that the saviour didn't take collateral or add more debt to the SAFE
        {
          (uint256 newSafeCollateral, uint256 newSafeDebt) = safeEngine.safes(collateralType, safe);
          require(both(newSafeCollateral >= safeCollateral, newSafeDebt <= safeDebt), "LiquidationEngine/invalid-safe-saviour-operation");
        }

        (, accumulatedRate, , , , liquidationPrice) = safeEngine.collateralTypes(collateralType);
        (safeCollateral, safeDebt) = safeEngine.safes(collateralType, safe);

        if (both(liquidationPrice > 0, multiply(safeCollateral, liquidationPrice) < multiply(safeDebt, accumulatedRate))) {
          CollateralType memory collateralData = collateralTypes[collateralType];

          uint256 limitAdjustedDebt = minimum(
            safeDebt,
            multiply(minimum(collateralData.liquidationQuantity, subtract(onAuctionSystemCoinLimit, currentOnAuctionSystemCoins)), WAD) / accumulatedRate / collateralData.liquidationPenalty
          );
          require(limitAdjustedDebt > 0, "LiquidationEngine/null-auction");
          require(either(limitAdjustedDebt == safeDebt, multiply(subtract(safeDebt, limitAdjustedDebt), accumulatedRate) >= debtFloor), "LiquidationEngine/dusty-safe");

          uint256 collateralToSell = minimum(safeCollateral, multiply(safeCollateral, limitAdjustedDebt) / safeDebt);

          require(collateralToSell > 0, "LiquidationEngine/null-collateral-to-sell");
          require(both(collateralToSell <= 2**255, limitAdjustedDebt <= 2**255), "LiquidationEngine/collateral-or-debt-overflow");

          safeEngine.confiscateSAFECollateralAndDebt(
            collateralType, safe, address(this), address(accountingEngine), -int256(collateralToSell), -int256(limitAdjustedDebt)
          );
          accountingEngine.pushDebtToQueue(multiply(limitAdjustedDebt, accumulatedRate));

          {
            // This calcuation will overflow if multiply(limitAdjustedDebt, accumulatedRate) exceeds ~10^14,
            // i.e. the maximum amountToRaise is roughly 100 trillion system coins.
            uint256 amountToRaise_      = multiply(multiply(limitAdjustedDebt, accumulatedRate), collateralData.liquidationPenalty) / WAD;
            currentOnAuctionSystemCoins = addition(currentOnAuctionSystemCoins, amountToRaise_);

            auctionId = CollateralAuctionHouseLike_2(collateralData.collateralAuctionHouse).startAuction(
              { forgoneCollateralReceiver: safe
              , initialBidder: address(accountingEngine)
              , amountToRaise: amountToRaise_
              , collateralToSell: collateralToSell
              , initialBid: 0
             });

             emit UpdateCurrentOnAuctionSystemCoins(currentOnAuctionSystemCoins);
          }

          emit Liquidate(collateralType, safe, collateralToSell, limitAdjustedDebt, multiply(limitAdjustedDebt, accumulatedRate), collateralData.collateralAuctionHouse, auctionId);
        }

        mutex[collateralType][safe] = 0;
    }
    /**
     * @notice Remove debt that was being auctioned
     * @param rad The amount of debt to withdraw from currentOnAuctionSystemCoins
     */
    function removeCoinsFromAuction(uint256 rad) public isAuthorized {
        currentOnAuctionSystemCoins = subtract(currentOnAuctionSystemCoins, rad);
        emit UpdateCurrentOnAuctionSystemCoins(currentOnAuctionSystemCoins);
    }

    // --- Getters ---
    /*
    * @notice Get the amount of debt that can currently be covered by a collateral auction for a specific safe
    * @param collateralType The collateral type stored in the SAFE
    * @param safe The SAFE's address/handler
    */
    function getLimitAdjustedDebtToCover(bytes32 collateralType, address safe) external view returns (uint256) {
        (, uint256 accumulatedRate,,,,)            = safeEngine.collateralTypes(collateralType);
        (uint256 safeCollateral, uint256 safeDebt) = safeEngine.safes(collateralType, safe);
        CollateralType memory collateralData       = collateralTypes[collateralType];

        return minimum(
          safeDebt,
          multiply(minimum(collateralData.liquidationQuantity, subtract(onAuctionSystemCoinLimit, currentOnAuctionSystemCoins)), WAD) / accumulatedRate / collateralData.liquidationPenalty
        );
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/OracleRelayer.sol
/// OracleRelayer.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

abstract contract SAFEEngineLike_9 {
    function modifyParameters(bytes32, bytes32, uint256) virtual external;
}

abstract contract OracleLike_3 {
    function getResultWithValidity() virtual public view returns (uint256, bool);
}

contract OracleRelayer {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "OracleRelayer/account-not-authorized");
        _;
    }

    // --- Data ---
    struct CollateralType {
        // Usually an oracle security module that enforces delays to fresh price feeds
        OracleLike_3 orcl;
        // CRatio used to compute the 'safePrice' - the price used when generating debt in SAFEEngine
        uint256 safetyCRatio;
        // CRatio used to compute the 'liquidationPrice' - the price used when liquidating SAFEs
        uint256 liquidationCRatio;
    }

    // Data about each collateral type
    mapping (bytes32 => CollateralType) public collateralTypes;

    SAFEEngineLike_9 public safeEngine;

    // Whether this contract is enabled
    uint256 public contractEnabled;
    // Virtual redemption price (not the most updated value)
    uint256 internal _redemptionPrice;                                                        // [ray]
    // The force that changes the system users' incentives by changing the redemption price
    uint256 public redemptionRate;                                                            // [ray]
    // Last time when the redemption price was changed
    uint256 public redemptionPriceUpdateTime;                                                 // [unix epoch time]
    // Upper bound for the per-second redemption rate
    uint256 public redemptionRateUpperBound;                                                  // [ray]
    // Lower bound for the per-second redemption rate
    uint256 public redemptionRateLowerBound;                                                  // [ray]

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event ModifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        address addr
    );
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    );
    event UpdateRedemptionPrice(uint256 redemptionPrice);
    event UpdateCollateralPrice(
      bytes32 indexed collateralType,
      uint256 priceFeedValue,
      uint256 safetyPrice,
      uint256 liquidationPrice
    );

    // --- Init ---
    constructor(address safeEngine_) public {
        authorizedAccounts[msg.sender] = 1;

        safeEngine                     = SAFEEngineLike_9(safeEngine_);
        _redemptionPrice               = RAY;
        redemptionRate                 = RAY;
        redemptionPriceUpdateTime      = now;
        redemptionRateUpperBound       = RAY * WAD;
        redemptionRateLowerBound       = 1;
        contractEnabled                = 1;

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
        require(z <= x, "OracleRelayer/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "OracleRelayer/mul-overflow");
    }
    function rmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // always rounds down
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "OracleRelayer/rdiv-by-zero");
        z = multiply(x, RAY) / y;
    }
    function rpower(uint256 x, uint256 n, uint256 base) internal pure returns (uint256 z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

    // --- Administration ---
    /**
     * @notice Modify oracle price feed addresses
     * @param collateralType Collateral whose oracle we change
     * @param parameter Name of the parameter
     * @param addr New oracle address
     */
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        address addr
    ) external isAuthorized {
        require(contractEnabled == 1, "OracleRelayer/contract-not-enabled");
        if (parameter == "orcl") collateralTypes[collateralType].orcl = OracleLike_3(addr);
        else revert("OracleRelayer/modify-unrecognized-param");
        emit ModifyParameters(
            collateralType,
            parameter,
            addr
        );
    }
    /**
     * @notice Modify redemption rate/price related parameters
     * @param parameter Name of the parameter
     * @param data New param value
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        require(contractEnabled == 1, "OracleRelayer/contract-not-enabled");
        require(data > 0, "OracleRelayer/null-data");
        if (parameter == "redemptionPrice") {
          _redemptionPrice = data;
        }
        else if (parameter == "redemptionRate") {
          require(now == redemptionPriceUpdateTime, "OracleRelayer/redemption-price-not-updated");
          uint256 adjustedRate = data;
          if (data > redemptionRateUpperBound) {
            adjustedRate = redemptionRateUpperBound;
          } else if (data < redemptionRateLowerBound) {
            adjustedRate = redemptionRateLowerBound;
          }
          redemptionRate = adjustedRate;
        }
        else if (parameter == "redemptionRateUpperBound") {
          require(data > RAY, "OracleRelayer/invalid-redemption-rate-upper-bound");
          redemptionRateUpperBound = data;
        }
        else if (parameter == "redemptionRateLowerBound") {
          require(data < RAY, "OracleRelayer/invalid-redemption-rate-lower-bound");
          redemptionRateLowerBound = data;
        }
        else revert("OracleRelayer/modify-unrecognized-param");
        emit ModifyParameters(
            parameter,
            data
        );
    }
    /**
     * @notice Modify CRatio related parameters
     * @param collateralType Collateral whose parameters we change
     * @param parameter Name of the parameter
     * @param data New param value
     */
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) external isAuthorized {
        require(contractEnabled == 1, "OracleRelayer/contract-not-enabled");
        if (parameter == "safetyCRatio") {
          require(data >= collateralTypes[collateralType].liquidationCRatio, "OracleRelayer/safety-lower-than-liquidation-cratio");
          collateralTypes[collateralType].safetyCRatio = data;
        }
        else if (parameter == "liquidationCRatio") {
          require(data <= collateralTypes[collateralType].safetyCRatio, "OracleRelayer/safety-lower-than-liquidation-cratio");
          collateralTypes[collateralType].liquidationCRatio = data;
        }
        else revert("OracleRelayer/modify-unrecognized-param");
        emit ModifyParameters(
            collateralType,
            parameter,
            data
        );
    }

    // --- Redemption Price Update ---
    /**
     * @notice Update the redemption price using the current redemption rate
     */
    function updateRedemptionPrice() internal returns (uint256) {
        // Update redemption price
        _redemptionPrice = rmultiply(
          rpower(redemptionRate, subtract(now, redemptionPriceUpdateTime), RAY),
          _redemptionPrice
        );
        if (_redemptionPrice == 0) _redemptionPrice = 1;
        redemptionPriceUpdateTime = now;
        emit UpdateRedemptionPrice(_redemptionPrice);
        // Return updated redemption price
        return _redemptionPrice;
    }
    /**
     * @notice Fetch the latest redemption price by first updating it
     */
    function redemptionPrice() public returns (uint256) {
        if (now > redemptionPriceUpdateTime) return updateRedemptionPrice();
        return _redemptionPrice;
    }

    // --- Update value ---
    /**
     * @notice Update the collateral price inside the system (inside SAFEEngine)
     * @param collateralType The collateral we want to update prices (safety and liquidation prices) for
     */
    function updateCollateralPrice(bytes32 collateralType) external {
        (uint256 priceFeedValue, bool hasValidValue) =
          collateralTypes[collateralType].orcl.getResultWithValidity();
        uint256 redemptionPrice_ = redemptionPrice();
        uint256 safetyPrice_ = hasValidValue ? rdivide(rdivide(multiply(uint256(priceFeedValue), 10 ** 9), redemptionPrice_), collateralTypes[collateralType].safetyCRatio) : 0;
        uint256 liquidationPrice_ = hasValidValue ? rdivide(rdivide(multiply(uint256(priceFeedValue), 10 ** 9), redemptionPrice_), collateralTypes[collateralType].liquidationCRatio) : 0;

        safeEngine.modifyParameters(collateralType, "safetyPrice", safetyPrice_);
        safeEngine.modifyParameters(collateralType, "liquidationPrice", liquidationPrice_);
        emit UpdateCollateralPrice(collateralType, priceFeedValue, safetyPrice_, liquidationPrice_);
    }

    /**
     * @notice Disable this contract (normally called by GlobalSettlement)
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        redemptionRate = RAY;
        emit DisableContract();
    }

    /**
     * @notice Fetch the safety CRatio of a specific collateral type
     * @param collateralType The collateral type we want the safety CRatio for
     */
    function safetyCRatio(bytes32 collateralType) public view returns (uint256) {
        return collateralTypes[collateralType].safetyCRatio;
    }
    /**
     * @notice Fetch the liquidation CRatio of a specific collateral type
     * @param collateralType The collateral type we want the liquidation CRatio for
     */
    function liquidationCRatio(bytes32 collateralType) public view returns (uint256) {
        return collateralTypes[collateralType].liquidationCRatio;
    }
    /**
     * @notice Fetch the oracle price feed of a specific collateral type
     * @param collateralType The collateral type we want the oracle price feed for
     */
    function orcl(bytes32 collateralType) public view returns (address) {
        return address(collateralTypes[collateralType].orcl);
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/SAFEEngine.sol
/// SAFEEngine.sol -- SAFE database

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

contract SAFEEngine {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        require(contractEnabled == 1, "SAFEEngine/contract-not-enabled");
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        require(contractEnabled == 1, "SAFEEngine/contract-not-enabled");
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "SAFEEngine/account-not-authorized");
        _;
    }

    // Who can transfer collateral & debt in/out of a SAFE
    mapping(address => mapping (address => uint256)) public safeRights;
    /**
     * @notice Allow an address to modify your SAFE
     * @param account Account to give SAFE permissions to
     */
    function approveSAFEModification(address account) external {
        safeRights[msg.sender][account] = 1;
        emit ApproveSAFEModification(msg.sender, account);
    }
    /**
     * @notice Deny an address the rights to modify your SAFE
     * @param account Account that is denied SAFE permissions
     */
    function denySAFEModification(address account) external {
        safeRights[msg.sender][account] = 0;
        emit DenySAFEModification(msg.sender, account);
    }
    /**
    * @notice Checks whether msg.sender has the right to modify a SAFE
    **/
    function canModifySAFE(address safe, address account) public view returns (bool) {
        return either(safe == account, safeRights[safe][account] == 1);
    }

    // --- Data ---
    struct CollateralType {
        // Total debt issued for this specific collateral type
        uint256 debtAmount;        // [wad]
        // Accumulator for interest accrued on this collateral type
        uint256 accumulatedRate;   // [ray]
        // Floor price at which a SAFE is allowed to generate debt
        uint256 safetyPrice;       // [ray]
        // Maximum amount of debt that can be generated with this collateral type
        uint256 debtCeiling;       // [rad]
        // Minimum amount of debt that must be generated by a SAFE using this collateral
        uint256 debtFloor;         // [rad]
        // Price at which a SAFE gets liquidated
        uint256 liquidationPrice;  // [ray]
    }
    struct SAFE {
        // Total amount of collateral locked in a SAFE
        uint256 lockedCollateral;  // [wad]
        // Total amount of debt generated by a SAFE
        uint256 generatedDebt;     // [wad]
    }

    // Data about each collateral type
    mapping (bytes32 => CollateralType)                public collateralTypes;
    // Data about each SAFE
    mapping (bytes32 => mapping (address => SAFE ))    public safes;
    // Balance of each collateral type
    mapping (bytes32 => mapping (address => uint256))  public tokenCollateral;  // [wad]
    // Internal balance of system coins
    mapping (address => uint256)                       public coinBalance;      // [rad]
    // Amount of debt held by an account. Coins & debt are like matter and antimatter. They nullify each other
    mapping (address => uint256)                       public debtBalance;      // [rad]

    // Total amount of debt that a single safe can generate
    uint256 public safeDebtCeiling;      // [wad]
    // Total amount of debt (coins) currently issued
    uint256  public globalDebt;          // [rad]
    // 'Bad' debt that's not covered by collateral
    uint256  public globalUnbackedDebt;  // [rad]
    // Maximum amount of debt that can be issued
    uint256  public globalDebtCeiling;   // [rad]
    // Access flag, indicates whether this contract is still active
    uint256  public contractEnabled;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ApproveSAFEModification(address sender, address account);
    event DenySAFEModification(address sender, address account);
    event InitializeCollateralType(bytes32 collateralType);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 collateralType, bytes32 parameter, uint256 data);
    event DisableContract();
    event ModifyCollateralBalance(bytes32 indexed collateralType, address indexed account, int256 wad);
    event TransferCollateral(bytes32 indexed collateralType, address indexed src, address indexed dst, uint256 wad);
    event TransferInternalCoins(address indexed src, address indexed dst, uint256 rad);
    event ModifySAFECollateralization(
        bytes32 indexed collateralType,
        address indexed safe,
        address collateralSource,
        address debtDestination,
        int256 deltaCollateral,
        int256 deltaDebt,
        uint256 lockedCollateral,
        uint256 generatedDebt,
        uint256 globalDebt
    );
    event TransferSAFECollateralAndDebt(
        bytes32 indexed collateralType,
        address indexed src,
        address indexed dst,
        int256 deltaCollateral,
        int256 deltaDebt,
        uint256 srcLockedCollateral,
        uint256 srcGeneratedDebt,
        uint256 dstLockedCollateral,
        uint256 dstGeneratedDebt
    );
    event ConfiscateSAFECollateralAndDebt(
        bytes32 indexed collateralType,
        address indexed safe,
        address collateralCounterparty,
        address debtCounterparty,
        int256 deltaCollateral,
        int256 deltaDebt,
        uint256 globalUnbackedDebt
    );
    event SettleDebt(address indexed account, uint256 rad, uint256 debtBalance, uint256 coinBalance, uint256 globalUnbackedDebt, uint256 globalDebt);
    event CreateUnbackedDebt(
        address indexed debtDestination,
        address indexed coinDestination,
        uint256 rad,
        uint256 debtDstBalance,
        uint256 coinDstBalance,
        uint256 globalUnbackedDebt,
        uint256 globalDebt
    );
    event UpdateAccumulatedRate(
        bytes32 indexed collateralType,
        address surplusDst,
        int256 rateMultiplier,
        uint256 dstCoinBalance,
        uint256 globalDebt
    );

    // --- Init ---
    constructor() public {
        authorizedAccounts[msg.sender] = 1;
        safeDebtCeiling = uint256(-1);
        contractEnabled = 1;
        emit AddAuthorization(msg.sender);
        emit ModifyParameters("safeDebtCeiling", uint256(-1));
    }

    // --- Math ---
    function addition(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x + uint256(y);
        require(y >= 0 || z <= x, "SAFEEngine/add-uint-int-overflow");
        require(y <= 0 || z >= x, "SAFEEngine/add-uint-int-underflow");
    }
    function addition(int256 x, int256 y) internal pure returns (int256 z) {
        z = x + y;
        require(y >= 0 || z <= x, "SAFEEngine/add-int-int-overflow");
        require(y <= 0 || z >= x, "SAFEEngine/add-int-int-underflow");
    }
    function subtract(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x - uint256(y);
        require(y <= 0 || z <= x, "SAFEEngine/sub-uint-int-overflow");
        require(y >= 0 || z >= x, "SAFEEngine/sub-uint-int-underflow");
    }
    function subtract(int256 x, int256 y) internal pure returns (int256 z) {
        z = x - y;
        require(y <= 0 || z <= x, "SAFEEngine/sub-int-int-overflow");
        require(y >= 0 || z >= x, "SAFEEngine/sub-int-int-underflow");
    }
    function multiply(uint256 x, int256 y) internal pure returns (int256 z) {
        z = int256(x) * y;
        require(int256(x) >= 0, "SAFEEngine/mul-uint-int-null-x");
        require(y == 0 || z / y == int256(x), "SAFEEngine/mul-uint-int-overflow");
    }
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "SAFEEngine/add-uint-uint-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "SAFEEngine/sub-uint-uint-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "SAFEEngine/multiply-uint-uint-overflow");
    }

    // --- Administration ---
    /**
     * @notice Creates a brand new collateral type
     * @param collateralType Collateral type name (e.g ETH-A, TBTC-B)
     */
    function initializeCollateralType(bytes32 collateralType) external isAuthorized {
        require(collateralTypes[collateralType].accumulatedRate == 0, "SAFEEngine/collateral-type-already-exists");
        collateralTypes[collateralType].accumulatedRate = 10 ** 27;
        emit InitializeCollateralType(collateralType);
    }
    /**
     * @notice Modify general uint256 params
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        require(contractEnabled == 1, "SAFEEngine/contract-not-enabled");
        if (parameter == "globalDebtCeiling") globalDebtCeiling = data;
        else if (parameter == "safeDebtCeiling") safeDebtCeiling = data;
        else revert("SAFEEngine/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify collateral specific params
     * @param collateralType Collateral type we modify params for
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) external isAuthorized {
        require(contractEnabled == 1, "SAFEEngine/contract-not-enabled");
        if (parameter == "safetyPrice") collateralTypes[collateralType].safetyPrice = data;
        else if (parameter == "liquidationPrice") collateralTypes[collateralType].liquidationPrice = data;
        else if (parameter == "debtCeiling") collateralTypes[collateralType].debtCeiling = data;
        else if (parameter == "debtFloor") collateralTypes[collateralType].debtFloor = data;
        else revert("SAFEEngine/modify-unrecognized-param");
        emit ModifyParameters(collateralType, parameter, data);
    }
    /**
     * @notice Disable this contract (normally called by GlobalSettlement)
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }

    // --- Fungibility ---
    /**
     * @notice Join/exit collateral into and and out of the system
     * @param collateralType Collateral type to join/exit
     * @param account Account that gets credited/debited
     * @param wad Amount of collateral
     */
    function modifyCollateralBalance(
        bytes32 collateralType,
        address account,
        int256 wad
    ) external isAuthorized {
        tokenCollateral[collateralType][account] = addition(tokenCollateral[collateralType][account], wad);
        emit ModifyCollateralBalance(collateralType, account, wad);
    }
    /**
     * @notice Transfer collateral between accounts
     * @param collateralType Collateral type transferred
     * @param src Collateral source
     * @param dst Collateral destination
     * @param wad Amount of collateral transferred
     */
    function transferCollateral(
        bytes32 collateralType,
        address src,
        address dst,
        uint256 wad
    ) external {
        require(canModifySAFE(src, msg.sender), "SAFEEngine/not-allowed");
        tokenCollateral[collateralType][src] = subtract(tokenCollateral[collateralType][src], wad);
        tokenCollateral[collateralType][dst] = addition(tokenCollateral[collateralType][dst], wad);
        emit TransferCollateral(collateralType, src, dst, wad);
    }
    /**
     * @notice Transfer internal coins (does not affect external balances from Coin.sol)
     * @param src Coins source
     * @param dst Coins destination
     * @param rad Amount of coins transferred
     */
    function transferInternalCoins(address src, address dst, uint256 rad) external {
        require(canModifySAFE(src, msg.sender), "SAFEEngine/not-allowed");
        coinBalance[src] = subtract(coinBalance[src], rad);
        coinBalance[dst] = addition(coinBalance[dst], rad);
        emit TransferInternalCoins(src, dst, rad);
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- SAFE Manipulation ---
    /**
     * @notice Add/remove collateral or put back/generate more debt in a SAFE
     * @param collateralType Type of collateral to withdraw/deposit in and from the SAFE
     * @param safe Target SAFE
     * @param collateralSource Account we take collateral from/put collateral into
     * @param debtDestination Account from which we credit/debit coins and debt
     * @param deltaCollateral Amount of collateral added/extract from the SAFE (wad)
     * @param deltaDebt Amount of debt to generate/repay (wad)
     */
    function modifySAFECollateralization(
        bytes32 collateralType,
        address safe,
        address collateralSource,
        address debtDestination,
        int256 deltaCollateral,
        int256 deltaDebt
    ) external {
        // system is live
        require(contractEnabled == 1, "SAFEEngine/contract-not-enabled");

        SAFE memory safeData = safes[collateralType][safe];
        CollateralType memory collateralTypeData = collateralTypes[collateralType];
        // collateral type has been initialised
        require(collateralTypeData.accumulatedRate != 0, "SAFEEngine/collateral-type-not-initialized");

        safeData.lockedCollateral      = addition(safeData.lockedCollateral, deltaCollateral);
        safeData.generatedDebt         = addition(safeData.generatedDebt, deltaDebt);
        collateralTypeData.debtAmount  = addition(collateralTypeData.debtAmount, deltaDebt);

        int256 deltaAdjustedDebt = multiply(collateralTypeData.accumulatedRate, deltaDebt);
        uint256 totalDebtIssued  = multiply(collateralTypeData.accumulatedRate, safeData.generatedDebt);
        globalDebt               = addition(globalDebt, deltaAdjustedDebt);

        // either debt has decreased, or debt ceilings are not exceeded
        require(
          either(
            deltaDebt <= 0,
            both(multiply(collateralTypeData.debtAmount, collateralTypeData.accumulatedRate) <= collateralTypeData.debtCeiling,
              globalDebt <= globalDebtCeiling)
            ),
          "SAFEEngine/ceiling-exceeded"
        );
        // safe is either less risky than before, or it is safe
        require(
          either(
            both(deltaDebt <= 0, deltaCollateral >= 0),
            totalDebtIssued <= multiply(safeData.lockedCollateral, collateralTypeData.safetyPrice)
          ),
          "SAFEEngine/not-safe"
        );

        // safe is either more safe, or the owner consents
        require(either(both(deltaDebt <= 0, deltaCollateral >= 0), canModifySAFE(safe, msg.sender)), "SAFEEngine/not-allowed-to-modify-safe");
        // collateral src consents
        require(either(deltaCollateral <= 0, canModifySAFE(collateralSource, msg.sender)), "SAFEEngine/not-allowed-collateral-src");
        // debt dst consents
        require(either(deltaDebt >= 0, canModifySAFE(debtDestination, msg.sender)), "SAFEEngine/not-allowed-debt-dst");

        // safe has no debt, or a non-dusty amount
        require(either(safeData.generatedDebt == 0, totalDebtIssued >= collateralTypeData.debtFloor), "SAFEEngine/dust");

        // safe didn't go above the safe debt limit
        if (deltaDebt > 0) {
          require(safeData.generatedDebt <= safeDebtCeiling, "SAFEEngine/above-debt-limit");
        }

        tokenCollateral[collateralType][collateralSource] =
          subtract(tokenCollateral[collateralType][collateralSource], deltaCollateral);

        coinBalance[debtDestination] = addition(coinBalance[debtDestination], deltaAdjustedDebt);

        safes[collateralType][safe] = safeData;
        collateralTypes[collateralType] = collateralTypeData;

        emit ModifySAFECollateralization(
            collateralType,
            safe,
            collateralSource,
            debtDestination,
            deltaCollateral,
            deltaDebt,
            safeData.lockedCollateral,
            safeData.generatedDebt,
            globalDebt
        );
    }

    // --- SAFE Fungibility ---
    /**
     * @notice Transfer collateral and/or debt between SAFEs
     * @param collateralType Collateral type transferred between SAFEs
     * @param src Source SAFE
     * @param dst Destination SAFE
     * @param deltaCollateral Amount of collateral to take/add into src and give/take from dst (wad)
     * @param deltaDebt Amount of debt to take/add into src and give/take from dst (wad)
     */
    function transferSAFECollateralAndDebt(
        bytes32 collateralType,
        address src,
        address dst,
        int256 deltaCollateral,
        int256 deltaDebt
    ) external {
        SAFE storage srcSAFE = safes[collateralType][src];
        SAFE storage dstSAFE = safes[collateralType][dst];
        CollateralType storage collateralType_ = collateralTypes[collateralType];

        srcSAFE.lockedCollateral = subtract(srcSAFE.lockedCollateral, deltaCollateral);
        srcSAFE.generatedDebt    = subtract(srcSAFE.generatedDebt, deltaDebt);
        dstSAFE.lockedCollateral = addition(dstSAFE.lockedCollateral, deltaCollateral);
        dstSAFE.generatedDebt    = addition(dstSAFE.generatedDebt, deltaDebt);

        uint256 srcTotalDebtIssued = multiply(srcSAFE.generatedDebt, collateralType_.accumulatedRate);
        uint256 dstTotalDebtIssued = multiply(dstSAFE.generatedDebt, collateralType_.accumulatedRate);

        // both sides consent
        require(both(canModifySAFE(src, msg.sender), canModifySAFE(dst, msg.sender)), "SAFEEngine/not-allowed");

        // both sides safe
        require(srcTotalDebtIssued <= multiply(srcSAFE.lockedCollateral, collateralType_.safetyPrice), "SAFEEngine/not-safe-src");
        require(dstTotalDebtIssued <= multiply(dstSAFE.lockedCollateral, collateralType_.safetyPrice), "SAFEEngine/not-safe-dst");

        // both sides non-dusty
        require(either(srcTotalDebtIssued >= collateralType_.debtFloor, srcSAFE.generatedDebt == 0), "SAFEEngine/dust-src");
        require(either(dstTotalDebtIssued >= collateralType_.debtFloor, dstSAFE.generatedDebt == 0), "SAFEEngine/dust-dst");

        emit TransferSAFECollateralAndDebt(
            collateralType,
            src,
            dst,
            deltaCollateral,
            deltaDebt,
            srcSAFE.lockedCollateral,
            srcSAFE.generatedDebt,
            dstSAFE.lockedCollateral,
            dstSAFE.generatedDebt
        );
    }

    // --- SAFE Confiscation ---
    /**
     * @notice Normally used by the LiquidationEngine in order to confiscate collateral and
       debt from a SAFE and give them to someone else
     * @param collateralType Collateral type the SAFE has locked inside
     * @param safe Target SAFE
     * @param collateralCounterparty Who we take/give collateral to
     * @param debtCounterparty Who we take/give debt to
     * @param deltaCollateral Amount of collateral taken/added into the SAFE (wad)
     * @param deltaDebt Amount of debt taken/added into the SAFE (wad)
     */
    function confiscateSAFECollateralAndDebt(
        bytes32 collateralType,
        address safe,
        address collateralCounterparty,
        address debtCounterparty,
        int256 deltaCollateral,
        int256 deltaDebt
    ) external isAuthorized {
        SAFE storage safe_ = safes[collateralType][safe];
        CollateralType storage collateralType_ = collateralTypes[collateralType];

        safe_.lockedCollateral = addition(safe_.lockedCollateral, deltaCollateral);
        safe_.generatedDebt = addition(safe_.generatedDebt, deltaDebt);
        collateralType_.debtAmount = addition(collateralType_.debtAmount, deltaDebt);

        int256 deltaTotalIssuedDebt = multiply(collateralType_.accumulatedRate, deltaDebt);

        tokenCollateral[collateralType][collateralCounterparty] = subtract(
          tokenCollateral[collateralType][collateralCounterparty],
          deltaCollateral
        );
        debtBalance[debtCounterparty] = subtract(
          debtBalance[debtCounterparty],
          deltaTotalIssuedDebt
        );
        globalUnbackedDebt = subtract(
          globalUnbackedDebt,
          deltaTotalIssuedDebt
        );

        emit ConfiscateSAFECollateralAndDebt(
            collateralType,
            safe,
            collateralCounterparty,
            debtCounterparty,
            deltaCollateral,
            deltaDebt,
            globalUnbackedDebt
        );
    }

    // --- Settlement ---
    /**
     * @notice Nullify an amount of coins with an equal amount of debt
     * @param rad Amount of debt & coins to destroy
     */
    function settleDebt(uint256 rad) external {
        address account       = msg.sender;
        debtBalance[account]  = subtract(debtBalance[account], rad);
        coinBalance[account]  = subtract(coinBalance[account], rad);
        globalUnbackedDebt    = subtract(globalUnbackedDebt, rad);
        globalDebt            = subtract(globalDebt, rad);
        emit SettleDebt(account, rad, debtBalance[account], coinBalance[account], globalUnbackedDebt, globalDebt);
    }
    /**
     * @notice Usually called by CoinSavingsAccount in order to create unbacked debt
     * @param debtDestination Usually AccountingEngine that can settle uncovered debt with surplus
     * @param coinDestination Usually CoinSavingsAccount that passes the new coins to depositors
     * @param rad Amount of debt to create
     */
    function createUnbackedDebt(
        address debtDestination,
        address coinDestination,
        uint256 rad
    ) external isAuthorized {
        debtBalance[debtDestination]  = addition(debtBalance[debtDestination], rad);
        coinBalance[coinDestination]  = addition(coinBalance[coinDestination], rad);
        globalUnbackedDebt            = addition(globalUnbackedDebt, rad);
        globalDebt                    = addition(globalDebt, rad);
        emit CreateUnbackedDebt(
            debtDestination,
            coinDestination,
            rad,
            debtBalance[debtDestination],
            coinBalance[coinDestination],
            globalUnbackedDebt,
            globalDebt
        );
    }

    // --- Rates ---
    /**
     * @notice Usually called by TaxCollector in order to accrue interest on a specific collateral type
     * @param collateralType Collateral type we accrue interest for
     * @param surplusDst Destination for the newly created surplus
     * @param rateMultiplier Multiplier applied to the debtAmount in order to calculate the surplus [ray]
     */
    function updateAccumulatedRate(
        bytes32 collateralType,
        address surplusDst,
        int256 rateMultiplier
    ) external isAuthorized {
        require(contractEnabled == 1, "SAFEEngine/contract-not-enabled");
        CollateralType storage collateralType_ = collateralTypes[collateralType];
        collateralType_.accumulatedRate        = addition(collateralType_.accumulatedRate, rateMultiplier);
        int256 deltaSurplus                    = multiply(collateralType_.debtAmount, rateMultiplier);
        coinBalance[surplusDst]                = addition(coinBalance[surplusDst], deltaSurplus);
        globalDebt                             = addition(globalDebt, deltaSurplus);
        emit UpdateAccumulatedRate(
            collateralType,
            surplusDst,
            rateMultiplier,
            coinBalance[surplusDst],
            globalDebt
        );
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/StabilityFeeTreasury.sol
/// StabilityFeeTreasury.sol

// Copyright (C) 2018 Rain <[email protected]>, 2020 Reflexer Labs, INC

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

/* pragma solidity 0.6.7; */

abstract contract SAFEEngineLike_10 {
    function approveSAFEModification(address) virtual external;
    function denySAFEModification(address) virtual external;
    function transferInternalCoins(address,address,uint256) virtual external;
    function settleDebt(uint256) virtual external;
    function coinBalance(address) virtual public view returns (uint256);
    function debtBalance(address) virtual public view returns (uint256);
}
abstract contract SystemCoinLike {
    function balanceOf(address) virtual public view returns (uint256);
    function approve(address, uint256) virtual public returns (uint256);
    function transfer(address,uint256) virtual public returns (bool);
    function transferFrom(address,address,uint256) virtual public returns (bool);
}
abstract contract CoinJoinLike {
    function systemCoin() virtual public view returns (address);
    function join(address, uint256) virtual external;
}

contract StabilityFeeTreasury {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "StabilityFeeTreasury/account-not-authorized");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, address addr);
    event ModifyParameters(bytes32 parameter, uint256 val);
    event DisableContract();
    event SetTotalAllowance(address indexed account, uint256 rad);
    event SetPerBlockAllowance(address indexed account, uint256 rad);
    event GiveFunds(address indexed account, uint256 rad, uint256 expensesAccumulator);
    event TakeFunds(address indexed account, uint256 rad);
    event PullFunds(address indexed sender, address indexed dstAccount, address token, uint256 rad, uint256 expensesAccumulator);
    event TransferSurplusFunds(address extraSurplusReceiver, uint256 fundsToTransfer);

    // --- Structs ---
    struct Allowance {
        uint256 total;
        uint256 perBlock;
    }

    // Mapping of total and per block allowances
    mapping(address => Allowance)                   private allowance;
    // Mapping that keeps track of how much surplus an authorized address has pulled each block
    mapping(address => mapping(uint256 => uint256)) public pulledPerBlock;

    SAFEEngineLike_10  public safeEngine;
    SystemCoinLike  public systemCoin;
    CoinJoinLike    public coinJoin;

    // The address that receives any extra surplus which is not used by the treasury
    address public extraSurplusReceiver;

    uint256 public treasuryCapacity;           // max amount of SF that can be kept in the treasury                        [rad]
    uint256 public minimumFundsRequired;       // minimum amount of SF that must be kept in the treasury at all times      [rad]
    uint256 public expensesMultiplier;         // multiplier for expenses                                                  [hundred]
    uint256 public surplusTransferDelay;       // minimum time between transferSurplusFunds calls                          [seconds]
    uint256 public expensesAccumulator;        // expenses accumulator                                                     [rad]
    uint256 public accumulatorTag;             // latest tagged accumulator price                                          [rad]
    uint256 public pullFundsMinThreshold;      // minimum funds that must be in the treasury so that someone can pullFunds [rad]
    uint256 public latestSurplusTransferTime;  // latest timestamp when transferSurplusFunds was called                    [seconds]
    uint256 public contractEnabled;

    modifier accountNotTreasury(address account) {
        require(account != address(this), "StabilityFeeTreasury/account-cannot-be-treasury");
        _;
    }

    constructor(
        address safeEngine_,
        address extraSurplusReceiver_,
        address coinJoin_
    ) public {
        require(address(CoinJoinLike(coinJoin_).systemCoin()) != address(0), "StabilityFeeTreasury/null-system-coin");
        require(extraSurplusReceiver_ != address(0), "StabilityFeeTreasury/null-surplus-receiver");

        authorizedAccounts[msg.sender] = 1;

        safeEngine                = SAFEEngineLike_10(safeEngine_);
        extraSurplusReceiver      = extraSurplusReceiver_;
        coinJoin                  = CoinJoinLike(coinJoin_);
        systemCoin                = SystemCoinLike(coinJoin.systemCoin());
        latestSurplusTransferTime = now;
        expensesMultiplier        = HUNDRED;
        contractEnabled           = 1;

        systemCoin.approve(address(coinJoin), uint256(-1));

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    uint256 constant HUNDRED = 10 ** 2;
    uint256 constant RAY     = 10 ** 27;

    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x, "StabilityFeeTreasury/add-uint-uint-overflow");
    }
    function addition(int256 x, int256 y) internal pure returns (int256 z) {
        z = x + y;
        if (y <= 0) require(z <= x, "StabilityFeeTreasury/add-int-int-underflow");
        if (y  > 0) require(z > x, "StabilityFeeTreasury/add-int-int-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "StabilityFeeTreasury/sub-uint-uint-underflow");
    }
    function subtract(int256 x, int256 y) internal pure returns (int256 z) {
        z = x - y;
        require(y <= 0 || z <= x, "StabilityFeeTreasury/sub-int-int-underflow");
        require(y >= 0 || z >= x, "StabilityFeeTreasury/sub-int-int-overflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "StabilityFeeTreasury/mul-uint-uint-overflow");
    }
    function divide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "StabilityFeeTreasury/div-y-null");
        z = x / y;
        require(z <= x, "StabilityFeeTreasury/div-invalid");
    }
    function minimum(uint256 x, uint256 y) internal view returns (uint256 z) {
        z = (x <= y) ? x : y;
    }

    // --- Administration ---
    /**
     * @notice Modify address parameters
     * @param parameter The name of the contract whose address will be changed
     * @param addr New address for the contract
     */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(contractEnabled == 1, "StabilityFeeTreasury/contract-not-enabled");
        require(addr != address(0), "StabilityFeeTreasury/null-addr");
        if (parameter == "extraSurplusReceiver") {
          require(addr != address(this), "StabilityFeeTreasury/accounting-engine-cannot-be-treasury");
          extraSurplusReceiver = addr;
        }
        else revert("StabilityFeeTreasury/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }
    /**
     * @notice Modify uint256 parameters
     * @param parameter The name of the parameter to modify
     * @param val New parameter value
     */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        require(contractEnabled == 1, "StabilityFeeTreasury/not-live");
        if (parameter == "expensesMultiplier") expensesMultiplier = val;
        else if (parameter == "treasuryCapacity") {
          require(val >= minimumFundsRequired, "StabilityFeeTreasury/capacity-lower-than-min-funds");
          treasuryCapacity = val;
        }
        else if (parameter == "minimumFundsRequired") {
          require(val <= treasuryCapacity, "StabilityFeeTreasury/min-funds-higher-than-capacity");
          minimumFundsRequired = val;
        }
        else if (parameter == "pullFundsMinThreshold") {
          pullFundsMinThreshold = val;
        }
        else if (parameter == "surplusTransferDelay") surplusTransferDelay = val;
        else revert("StabilityFeeTreasury/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }
    /**
     * @notice Disable this contract (normally called by GlobalSettlement)
     */
    function disableContract() external isAuthorized {
        require(contractEnabled == 1, "StabilityFeeTreasury/already-disabled");
        contractEnabled = 0;
        joinAllCoins();
        safeEngine.transferInternalCoins(address(this), extraSurplusReceiver, safeEngine.coinBalance(address(this)));
        emit DisableContract();
    }

    // --- Utils ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    /**
     * @notice Join all ERC20 system coins that the treasury has inside the SAFEEngine
     */
    function joinAllCoins() internal {
        if (systemCoin.balanceOf(address(this)) > 0) {
          coinJoin.join(address(this), systemCoin.balanceOf(address(this)));
        }
    }
    /*
    * @notice Settle as much bad debt as possible (if this contract has any)
    */
    function settleDebt() public {
        uint256 coinBalanceSelf = safeEngine.coinBalance(address(this));
        uint256 debtBalanceSelf = safeEngine.debtBalance(address(this));

        if (debtBalanceSelf > 0) {
          safeEngine.settleDebt(minimum(coinBalanceSelf, debtBalanceSelf));
        }
    }

    // --- Getters ---
    /*
    * @notice Returns the total and per block allowances for a specific address
    * @param account The address to return the allowances for
    */
    function getAllowance(address account) public view returns (uint256, uint256) {
        return (allowance[account].total, allowance[account].perBlock);
    }

    // --- SF Transfer Allowance ---
    /**
     * @notice Modify an address' total allowance in order to withdraw SF from the treasury
     * @param account The approved address
     * @param rad The total approved amount of SF to withdraw (number with 45 decimals)
     */
    function setTotalAllowance(address account, uint256 rad) external isAuthorized accountNotTreasury(account) {
        require(account != address(0), "StabilityFeeTreasury/null-account");
        allowance[account].total = rad;
        emit SetTotalAllowance(account, rad);
    }
    /**
     * @notice Modify an address' per block allowance in order to withdraw SF from the treasury
     * @param account The approved address
     * @param rad The per block approved amount of SF to withdraw (number with 45 decimals)
     */
    function setPerBlockAllowance(address account, uint256 rad) external isAuthorized accountNotTreasury(account) {
        require(account != address(0), "StabilityFeeTreasury/null-account");
        allowance[account].perBlock = rad;
        emit SetPerBlockAllowance(account, rad);
    }

    // --- Stability Fee Transfer (Governance) ---
    /**
     * @notice Governance transfers SF to an address
     * @param account Address to transfer SF to
     * @param rad Amount of internal system coins to transfer (a number with 45 decimals)
     */
    function giveFunds(address account, uint256 rad) external isAuthorized accountNotTreasury(account) {
        require(account != address(0), "StabilityFeeTreasury/null-account");

        joinAllCoins();
        settleDebt();

        require(safeEngine.debtBalance(address(this)) == 0, "StabilityFeeTreasury/outstanding-bad-debt");
        require(safeEngine.coinBalance(address(this)) >= rad, "StabilityFeeTreasury/not-enough-funds");

        if (account != extraSurplusReceiver) {
          expensesAccumulator = addition(expensesAccumulator, rad);
        }

        safeEngine.transferInternalCoins(address(this), account, rad);
        emit GiveFunds(account, rad, expensesAccumulator);
    }
    /**
     * @notice Governance takes funds from an address
     * @param account Address to take system coins from
     * @param rad Amount of internal system coins to take from the account (a number with 45 decimals)
     */
    function takeFunds(address account, uint256 rad) external isAuthorized accountNotTreasury(account) {
        safeEngine.transferInternalCoins(account, address(this), rad);
        emit TakeFunds(account, rad);
    }

    // --- Stability Fee Transfer (Approved Accounts) ---
    /**
     * @notice Pull stability fees from the treasury (if your allowance permits)
     * @param dstAccount Address to transfer funds to
     * @param token Address of the token to transfer (in this case it must be the address of the ERC20 system coin).
     *              Used only to adhere to a standard for automated, on-chain treasuries
     * @param wad Amount of system coins (SF) to transfer (expressed as an 18 decimal number but the contract will transfer
              internal system coins that have 45 decimals)
     */
    function pullFunds(address dstAccount, address token, uint256 wad) external {
        if (dstAccount == address(this)) return;
	      require(allowance[msg.sender].total >= multiply(wad, RAY), "StabilityFeeTreasury/not-allowed");
        require(dstAccount != address(0), "StabilityFeeTreasury/null-dst");
        require(dstAccount != extraSurplusReceiver, "StabilityFeeTreasury/dst-cannot-be-accounting");
        require(wad > 0, "StabilityFeeTreasury/null-transfer-amount");
        require(token == address(systemCoin), "StabilityFeeTreasury/token-unavailable");
        if (allowance[msg.sender].perBlock > 0) {
          require(addition(pulledPerBlock[msg.sender][block.number], multiply(wad, RAY)) <= allowance[msg.sender].perBlock, "StabilityFeeTreasury/per-block-limit-exceeded");
        }

        pulledPerBlock[msg.sender][block.number] = addition(pulledPerBlock[msg.sender][block.number], multiply(wad, RAY));

        joinAllCoins();
        settleDebt();

        require(safeEngine.debtBalance(address(this)) == 0, "StabilityFeeTreasury/outstanding-bad-debt");
        require(safeEngine.coinBalance(address(this)) >= multiply(wad, RAY), "StabilityFeeTreasury/not-enough-funds");
        require(safeEngine.coinBalance(address(this)) >= pullFundsMinThreshold, "StabilityFeeTreasury/below-pullFunds-min-threshold");

        // Update allowance and accumulator
        allowance[msg.sender].total = subtract(allowance[msg.sender].total, multiply(wad, RAY));
        expensesAccumulator         = addition(expensesAccumulator, multiply(wad, RAY));

        // Transfer money
        safeEngine.transferInternalCoins(address(this), dstAccount, multiply(wad, RAY));

        emit PullFunds(msg.sender, dstAccount, token, multiply(wad, RAY), expensesAccumulator);
    }

    // --- Treasury Maintenance ---
    /**
     * @notice Transfer surplus stability fees to the extraSurplusReceiver. This is here to make sure that the treasury
               doesn't accumulate fees that it doesn't even need in order to pay for allowances. It ensures
               that there are enough funds left in the treasury to account for projected expenses (latest expenses multiplied
               by an expense multiplier)
     */
    function transferSurplusFunds() external {
        require(now >= addition(latestSurplusTransferTime, surplusTransferDelay), "StabilityFeeTreasury/transfer-cooldown-not-passed");
        // Compute latest expenses
        uint256 latestExpenses = subtract(expensesAccumulator, accumulatorTag);
        // Check if we need to keep more funds than the total capacity
        uint256 remainingFunds =
          (treasuryCapacity <= divide(multiply(expensesMultiplier, latestExpenses), HUNDRED)) ?
          divide(multiply(expensesMultiplier, latestExpenses), HUNDRED) : treasuryCapacity;
        // Make sure to keep at least minimum funds
        remainingFunds = (divide(multiply(expensesMultiplier, latestExpenses), HUNDRED) <= minimumFundsRequired) ?
                   minimumFundsRequired : remainingFunds;
        // Set internal vars
        accumulatorTag            = expensesAccumulator;
        latestSurplusTransferTime = now;
        // Join all coins in system
        joinAllCoins();
        // Settle outstanding bad debt
        settleDebt();
        // Check that there's no bad debt left
        require(safeEngine.debtBalance(address(this)) == 0, "StabilityFeeTreasury/outstanding-bad-debt");
        // Check if we have too much money
        if (safeEngine.coinBalance(address(this)) > remainingFunds) {
          // Make sure that we still keep min SF in treasury
          uint256 fundsToTransfer = subtract(safeEngine.coinBalance(address(this)), remainingFunds);
          // Transfer surplus to accounting engine
          safeEngine.transferInternalCoins(address(this), extraSurplusReceiver, fundsToTransfer);
          // Emit event
          emit TransferSurplusFunds(extraSurplusReceiver, fundsToTransfer);
        }
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/SurplusAuctionHouse.sol
/// SurplusAuctionHouse.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

abstract contract SAFEEngineLike_11 {
    function transferInternalCoins(address,address,uint256) virtual external;
    function coinBalance(address) virtual external view returns (uint256);
    function approveSAFEModification(address) virtual external;
    function denySAFEModification(address) virtual external;
}
abstract contract TokenLike_2 {
    function approve(address, uint256) virtual public returns (bool);
    function balanceOf(address) virtual public view returns (uint256);
    function move(address,address,uint256) virtual external;
    function burn(address,uint256) virtual external;
}

/*
   This thing lets you auction some system coins in return for protocol tokens that are then burnt
*/

contract BurningSurplusAuctionHouse {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "BurningSurplusAuctionHouse/account-not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        // Bid size (how many protocol tokens are offered per system coins sold)
        uint256 bidAmount;                                                            // [wad]
        // How many system coins are sold in an auction
        uint256 amountToSell;                                                         // [rad]
        // Who the high bidder is
        address highBidder;
        // When the latest bid expires and the auction can be settled
        uint48  bidExpiry;                                                            // [unix epoch time]
        // Hard deadline for the auction after which no more bids can be placed
        uint48  auctionDeadline;                                                      // [unix epoch time]
    }

    // Bid data for each separate auction
    mapping (uint256 => Bid) public bids;

    // SAFE database
    SAFEEngineLike_11 public safeEngine;
    // Protocol token address
    TokenLike_2      public protocolToken;

    uint256  constant ONE = 1.00E18;                                                  // [wad]
    // Minimum bid increase compared to the last bid in order to take the new one in consideration
    uint256  public   bidIncrease = 1.05E18;                                          // [wad]
    // How long the auction lasts after a new bid is submitted
    uint48   public   bidDuration = 3 hours;                                          // [seconds]
    // Total length of the auction
    uint48   public   totalAuctionLength = 2 days;                                    // [seconds]
    // Number of auctions started up until now
    uint256  public   auctionsStarted = 0;
    // Whether the contract is settled or not
    uint256  public   contractEnabled;

    bytes32 public constant AUCTION_HOUSE_TYPE   = bytes32("SURPLUS");
    bytes32 public constant SURPLUS_AUCTION_TYPE = bytes32("BURNING");

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event RestartAuction(uint256 id, uint256 auctionDeadline);
    event IncreaseBidSize(uint256 id, address highBidder, uint256 amountToBuy, uint256 bid, uint256 bidExpiry);
    event StartAuction(
        uint256 indexed id,
        uint256 auctionsStarted,
        uint256 amountToSell,
        uint256 initialBid,
        uint256 auctionDeadline
    );
    event SettleAuction(uint256 indexed id);
    event DisableContract();
    event TerminateAuctionPrematurely(uint256 indexed id, address sender, address highBidder, uint256 bidAmount);

    // --- Init ---
    constructor(address safeEngine_, address protocolToken_) public {
        authorizedAccounts[msg.sender] = 1;
        safeEngine = SAFEEngineLike_11(safeEngine_);
        protocolToken = TokenLike_2(protocolToken_);
        contractEnabled = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addUint48(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x, "BurningSurplusAuctionHouse/add-uint48-overflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "BurningSurplusAuctionHouse/mul-overflow");
    }

    // --- Admin ---
    /**
     * @notice Modify auction parameters
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "bidIncrease") bidIncrease = data;
        else if (parameter == "bidDuration") bidDuration = uint48(data);
        else if (parameter == "totalAuctionLength") totalAuctionLength = uint48(data);
        else revert("BurningSurplusAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Auction ---
    /**
     * @notice Start a new surplus auction
     * @param amountToSell Total amount of system coins to sell (rad)
     * @param initialBid Initial protocol token bid (wad)
     */
    function startAuction(uint256 amountToSell, uint256 initialBid) external isAuthorized returns (uint256 id) {
        require(contractEnabled == 1, "BurningSurplusAuctionHouse/contract-not-enabled");
        require(auctionsStarted < uint256(-1), "BurningSurplusAuctionHouse/overflow");
        id = ++auctionsStarted;

        bids[id].bidAmount = initialBid;
        bids[id].amountToSell = amountToSell;
        bids[id].highBidder = msg.sender;
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);

        safeEngine.transferInternalCoins(msg.sender, address(this), amountToSell);

        emit StartAuction(id, auctionsStarted, amountToSell, initialBid, bids[id].auctionDeadline);
    }
    /**
     * @notice Restart an auction if no bids were submitted for it
     * @param id ID of the auction to restart
     */
    function restartAuction(uint256 id) external {
        require(bids[id].auctionDeadline < now, "BurningSurplusAuctionHouse/not-finished");
        require(bids[id].bidExpiry == 0, "BurningSurplusAuctionHouse/bid-already-placed");
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);
        emit RestartAuction(id, bids[id].auctionDeadline);
    }
    /**
     * @notice Submit a higher protocol token bid for the same amount of system coins
     * @param id ID of the auction you want to submit the bid for
     * @param amountToBuy Amount of system coins to buy (rad)
     * @param bid New bid submitted (wad)
     */
    function increaseBidSize(uint256 id, uint256 amountToBuy, uint256 bid) external {
        require(contractEnabled == 1, "BurningSurplusAuctionHouse/contract-not-enabled");
        require(bids[id].highBidder != address(0), "BurningSurplusAuctionHouse/high-bidder-not-set");
        require(bids[id].bidExpiry > now || bids[id].bidExpiry == 0, "BurningSurplusAuctionHouse/bid-already-expired");
        require(bids[id].auctionDeadline > now, "BurningSurplusAuctionHouse/auction-already-expired");

        require(amountToBuy == bids[id].amountToSell, "BurningSurplusAuctionHouse/amounts-not-matching");
        require(bid > bids[id].bidAmount, "BurningSurplusAuctionHouse/bid-not-higher");
        require(multiply(bid, ONE) >= multiply(bidIncrease, bids[id].bidAmount), "BurningSurplusAuctionHouse/insufficient-increase");

        if (msg.sender != bids[id].highBidder) {
            protocolToken.move(msg.sender, bids[id].highBidder, bids[id].bidAmount);
            bids[id].highBidder = msg.sender;
        }
        protocolToken.move(msg.sender, address(this), bid - bids[id].bidAmount);

        bids[id].bidAmount = bid;
        bids[id].bidExpiry = addUint48(uint48(now), bidDuration);

        emit IncreaseBidSize(id, msg.sender, amountToBuy, bid, bids[id].bidExpiry);
    }
    /**
     * @notice Settle/finish an auction
     * @param id ID of the auction to settle
     */
    function settleAuction(uint256 id) external {
        require(contractEnabled == 1, "BurningSurplusAuctionHouse/contract-not-enabled");
        require(bids[id].bidExpiry != 0 && (bids[id].bidExpiry < now || bids[id].auctionDeadline < now), "BurningSurplusAuctionHouse/not-finished");
        safeEngine.transferInternalCoins(address(this), bids[id].highBidder, bids[id].amountToSell);
        protocolToken.burn(address(this), bids[id].bidAmount);
        delete bids[id];
        emit SettleAuction(id);
    }
    /**
    * @notice Disable the auction house (usually called by AccountingEngine)
    **/
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        safeEngine.transferInternalCoins(address(this), msg.sender, safeEngine.coinBalance(address(this)));
        emit DisableContract();
    }
    /**
     * @notice Terminate an auction prematurely.
     * @param id ID of the auction to settle/terminate
     */
    function terminateAuctionPrematurely(uint256 id) external {
        require(contractEnabled == 0, "BurningSurplusAuctionHouse/contract-still-enabled");
        require(bids[id].highBidder != address(0), "BurningSurplusAuctionHouse/high-bidder-not-set");
        protocolToken.move(address(this), bids[id].highBidder, bids[id].bidAmount);
        emit TerminateAuctionPrematurely(id, msg.sender, bids[id].highBidder, bids[id].bidAmount);
        delete bids[id];
    }
}

// This thing lets you auction surplus for protocol tokens that are then sent to another address

contract RecyclingSurplusAuctionHouse {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "RecyclingSurplusAuctionHouse/account-not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        // Bid size (how many protocol tokens are offered per system coins sold)
        uint256 bidAmount;                                                            // [wad]
        // How many system coins are sold in an auction
        uint256 amountToSell;                                                         // [rad]
        // Who the high bidder is
        address highBidder;
        // When the latest bid expires and the auction can be settled
        uint48  bidExpiry;                                                            // [unix epoch time]
        // Hard deadline for the auction after which no more bids can be placed
        uint48  auctionDeadline;                                                      // [unix epoch time]
    }

    // Bid data for each separate auction
    mapping (uint256 => Bid) public bids;

    // SAFE database
    SAFEEngineLike_11 public safeEngine;
    // Protocol token address
    TokenLike_2      public protocolToken;
    // Receiver of protocol tokens
    address        public protocolTokenBidReceiver;

    uint256  constant ONE = 1.00E18;                                                  // [wad]
    // Minimum bid increase compared to the last bid in order to take the new one in consideration
    uint256  public   bidIncrease = 1.05E18;                                          // [wad]
    // How long the auction lasts after a new bid is submitted
    uint48   public   bidDuration = 3 hours;                                          // [seconds]
    // Total length of the auction
    uint48   public   totalAuctionLength = 2 days;                                    // [seconds]
    // Number of auctions started up until now
    uint256  public   auctionsStarted = 0;
    // Whether the contract is settled or not
    uint256  public   contractEnabled;

    bytes32 public constant AUCTION_HOUSE_TYPE = bytes32("SURPLUS");
    bytes32 public constant SURPLUS_AUCTION_TYPE = bytes32("RECYCLING");

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address addr);
    event RestartAuction(uint256 id, uint256 auctionDeadline);
    event IncreaseBidSize(uint256 id, address highBidder, uint256 amountToBuy, uint256 bid, uint256 bidExpiry);
    event StartAuction(
        uint256 indexed id,
        uint256 auctionsStarted,
        uint256 amountToSell,
        uint256 initialBid,
        uint256 auctionDeadline
    );
    event SettleAuction(uint256 indexed id);
    event DisableContract();
    event TerminateAuctionPrematurely(uint256 indexed id, address sender, address highBidder, uint256 bidAmount);

    // --- Init ---
    constructor(address safeEngine_, address protocolToken_) public {
        authorizedAccounts[msg.sender] = 1;
        safeEngine = SAFEEngineLike_11(safeEngine_);
        protocolToken = TokenLike_2(protocolToken_);
        contractEnabled = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addUint48(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x, "RecyclingSurplusAuctionHouse/add-uint48-overflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "RecyclingSurplusAuctionHouse/mul-overflow");
    }

    // --- Admin ---
    /**
     * @notice Modify uint256 parameters
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "bidIncrease") bidIncrease = data;
        else if (parameter == "bidDuration") bidDuration = uint48(data);
        else if (parameter == "totalAuctionLength") totalAuctionLength = uint48(data);
        else revert("RecyclingSurplusAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify address parameters
     * @param parameter The name of the parameter modified
     * @param addr New address value
     */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "RecyclingSurplusAuctionHouse/invalid-address");
        if (parameter == "protocolTokenBidReceiver") protocolTokenBidReceiver = addr;
        else revert("RecyclingSurplusAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    // --- Auction ---
    /**
     * @notice Start a new surplus auction
     * @param amountToSell Total amount of system coins to sell (rad)
     * @param initialBid Initial protocol token bid (wad)
     */
    function startAuction(uint256 amountToSell, uint256 initialBid) external isAuthorized returns (uint256 id) {
        require(contractEnabled == 1, "RecyclingSurplusAuctionHouse/contract-not-enabled");
        require(auctionsStarted < uint256(-1), "RecyclingSurplusAuctionHouse/overflow");
        require(protocolTokenBidReceiver != address(0), "RecyclingSurplusAuctionHouse/null-prot-token-receiver");
        id = ++auctionsStarted;

        bids[id].bidAmount = initialBid;
        bids[id].amountToSell = amountToSell;
        bids[id].highBidder = msg.sender;
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);

        safeEngine.transferInternalCoins(msg.sender, address(this), amountToSell);

        emit StartAuction(id, auctionsStarted, amountToSell, initialBid, bids[id].auctionDeadline);
    }
    /**
     * @notice Restart an auction if no bids were submitted for it
     * @param id ID of the auction to restart
     */
    function restartAuction(uint256 id) external {
        require(bids[id].auctionDeadline < now, "RecyclingSurplusAuctionHouse/not-finished");
        require(bids[id].bidExpiry == 0, "RecyclingSurplusAuctionHouse/bid-already-placed");
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);
        emit RestartAuction(id, bids[id].auctionDeadline);
    }
    /**
     * @notice Submit a higher protocol token bid for the same amount of system coins
     * @param id ID of the auction you want to submit the bid for
     * @param amountToBuy Amount of system coins to buy (rad)
     * @param bid New bid submitted (wad)
     */
    function increaseBidSize(uint256 id, uint256 amountToBuy, uint256 bid) external {
        require(contractEnabled == 1, "RecyclingSurplusAuctionHouse/contract-not-enabled");
        require(bids[id].highBidder != address(0), "RecyclingSurplusAuctionHouse/high-bidder-not-set");
        require(bids[id].bidExpiry > now || bids[id].bidExpiry == 0, "RecyclingSurplusAuctionHouse/bid-already-expired");
        require(bids[id].auctionDeadline > now, "RecyclingSurplusAuctionHouse/auction-already-expired");

        require(amountToBuy == bids[id].amountToSell, "RecyclingSurplusAuctionHouse/amounts-not-matching");
        require(bid > bids[id].bidAmount, "RecyclingSurplusAuctionHouse/bid-not-higher");
        require(multiply(bid, ONE) >= multiply(bidIncrease, bids[id].bidAmount), "RecyclingSurplusAuctionHouse/insufficient-increase");

        if (msg.sender != bids[id].highBidder) {
            protocolToken.move(msg.sender, bids[id].highBidder, bids[id].bidAmount);
            bids[id].highBidder = msg.sender;
        }
        protocolToken.move(msg.sender, address(this), bid - bids[id].bidAmount);

        bids[id].bidAmount = bid;
        bids[id].bidExpiry = addUint48(uint48(now), bidDuration);

        emit IncreaseBidSize(id, msg.sender, amountToBuy, bid, bids[id].bidExpiry);
    }
    /**
     * @notice Settle/finish an auction
     * @param id ID of the auction to settle
     */
    function settleAuction(uint256 id) external {
        require(contractEnabled == 1, "RecyclingSurplusAuctionHouse/contract-not-enabled");
        require(bids[id].bidExpiry != 0 && (bids[id].bidExpiry < now || bids[id].auctionDeadline < now), "RecyclingSurplusAuctionHouse/not-finished");
        safeEngine.transferInternalCoins(address(this), bids[id].highBidder, bids[id].amountToSell);
        protocolToken.move(address(this), protocolTokenBidReceiver, bids[id].bidAmount);
        delete bids[id];
        emit SettleAuction(id);
    }
    /**
    * @notice Disable the auction house (usually called by AccountingEngine)
    **/
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        safeEngine.transferInternalCoins(address(this), msg.sender, safeEngine.coinBalance(address(this)));
        emit DisableContract();
    }
    /**
     * @notice Terminate an auction prematurely.
     * @param id ID of the auction to settle/terminate
     */
    function terminateAuctionPrematurely(uint256 id) external {
        require(contractEnabled == 0, "RecyclingSurplusAuctionHouse/contract-still-enabled");
        require(bids[id].highBidder != address(0), "RecyclingSurplusAuctionHouse/high-bidder-not-set");
        protocolToken.move(address(this), bids[id].highBidder, bids[id].bidAmount);
        emit TerminateAuctionPrematurely(id, msg.sender, bids[id].highBidder, bids[id].bidAmount);
        delete bids[id];
    }
}

contract PostSettlementSurplusAuctionHouse {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "PostSettlementSurplusAuctionHouse/account-not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        // Bid size (how many protocol tokens are offered per system coins sold)
        uint256 bidAmount;                                                        // [rad]
        // How many system coins are sold in an auction
        uint256 amountToSell;                                                     // [wad]
        // Who the high bidder is
        address highBidder;
        // When the latest bid expires and the auction can be settled
        uint48  bidExpiry;                                                        // [unix epoch time]
        // Hard deadline for the auction after which no more bids can be placed
        uint48  auctionDeadline;                                                  // [unix epoch time]
    }

    // Bid data for each separate auction
    mapping (uint256 => Bid) public bids;

    // SAFE database
    SAFEEngineLike_11        public safeEngine;
    // Protocol token address
    TokenLike_2            public protocolToken;

    uint256  constant ONE = 1.00E18;                                              // [wad]
    // Minimum bid increase compared to the last bid in order to take the new one in consideration
    uint256  public   bidIncrease = 1.05E18;                                      // [wad]
    // How long the auction lasts after a new bid is submitted
    uint48   public   bidDuration = 3 hours;                                      // [seconds]
    // Total length of the auction
    uint48   public   totalAuctionLength = 2 days;                                // [seconds]
    // Number of auctions started up until now
    uint256  public   auctionsStarted = 0;

    bytes32 public constant AUCTION_HOUSE_TYPE = bytes32("SURPLUS");

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event RestartAuction(uint256 indexed id, uint256 auctionDeadline);
    event IncreaseBidSize(uint256 indexed id, address highBidder, uint256 amountToBuy, uint256 bid, uint256 bidExpiry);
    event StartAuction(
        uint256 indexed id,
        uint256 auctionsStarted,
        uint256 amountToSell,
        uint256 initialBid,
        uint256 auctionDeadline
    );
    event SettleAuction(uint256 indexed id);

    // --- Init ---
    constructor(address safeEngine_, address protocolToken_) public {
        authorizedAccounts[msg.sender] = 1;
        safeEngine = SAFEEngineLike_11(safeEngine_);
        protocolToken = TokenLike_2(protocolToken_);
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addUint48(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x);
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Admin ---
    /**
     * @notice Modify uint256 parameters
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "bidIncrease") bidIncrease = data;
        else if (parameter == "bidDuration") bidDuration = uint48(data);
        else if (parameter == "totalAuctionLength") totalAuctionLength = uint48(data);
        else revert("PostSettlementSurplusAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Auction ---
    /**
     * @notice Start a new surplus auction
     * @param amountToSell Total amount of system coins to sell (wad)
     * @param initialBid Initial protocol token bid (rad)
     */
    function startAuction(uint256 amountToSell, uint256 initialBid) external isAuthorized returns (uint256 id) {
        require(auctionsStarted < uint256(-1), "PostSettlementSurplusAuctionHouse/overflow");
        id = ++auctionsStarted;

        bids[id].bidAmount = initialBid;
        bids[id].amountToSell = amountToSell;
        bids[id].highBidder = msg.sender;
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);

        safeEngine.transferInternalCoins(msg.sender, address(this), amountToSell);

        emit StartAuction(id, auctionsStarted, amountToSell, initialBid, bids[id].auctionDeadline);
    }
    /**
     * @notice Restart an auction if no bids were submitted for it
     * @param id ID of the auction to restart
     */
    function restartAuction(uint256 id) external {
        require(bids[id].auctionDeadline < now, "PostSettlementSurplusAuctionHouse/not-finished");
        require(bids[id].bidExpiry == 0, "PostSettlementSurplusAuctionHouse/bid-already-placed");
        bids[id].auctionDeadline = addUint48(uint48(now), totalAuctionLength);
        emit RestartAuction(id, bids[id].auctionDeadline);
    }
    /**
     * @notice Submit a higher protocol token bid for the same amount of system coins
     * @param id ID of the auction you want to submit the bid for
     * @param amountToBuy Amount of system coins to buy (wad)
     * @param bid New bid submitted (rad)
     */
    function increaseBidSize(uint256 id, uint256 amountToBuy, uint256 bid) external {
        require(bids[id].highBidder != address(0), "PostSettlementSurplusAuctionHouse/high-bidder-not-set");
        require(bids[id].bidExpiry > now || bids[id].bidExpiry == 0, "PostSettlementSurplusAuctionHouse/bid-already-expired");
        require(bids[id].auctionDeadline > now, "PostSettlementSurplusAuctionHouse/auction-already-expired");

        require(amountToBuy == bids[id].amountToSell, "PostSettlementSurplusAuctionHouse/amounts-not-matching");
        require(bid > bids[id].bidAmount, "PostSettlementSurplusAuctionHouse/bid-not-higher");
        require(multiply(bid, ONE) >= multiply(bidIncrease, bids[id].bidAmount), "PostSettlementSurplusAuctionHouse/insufficient-increase");

        if (msg.sender != bids[id].highBidder) {
            protocolToken.move(msg.sender, bids[id].highBidder, bids[id].bidAmount);
            bids[id].highBidder = msg.sender;
        }
        protocolToken.move(msg.sender, address(this), bid - bids[id].bidAmount);

        bids[id].bidAmount = bid;
        bids[id].bidExpiry = addUint48(uint48(now), bidDuration);

        emit IncreaseBidSize(id, msg.sender, amountToBuy, bid, bids[id].bidExpiry);
    }
    /**
     * @notice Settle/finish an auction
     * @param id ID of the auction to settle
     */
    function settleAuction(uint256 id) external {
        require(bids[id].bidExpiry != 0 && (bids[id].bidExpiry < now || bids[id].auctionDeadline < now), "PostSettlementSurplusAuctionHouse/not-finished");
        safeEngine.transferInternalCoins(address(this), bids[id].highBidder, bids[id].amountToSell);
        protocolToken.burn(address(this), bids[id].bidAmount);
        delete bids[id];
        emit SettleAuction(id);
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/LinkedList.sol
/* pragma solidity 0.6.7; */

abstract contract StructLike {
    function val(uint256 _id) virtual public view returns (uint256);
}

/**
 * @title LinkedList (Structured Link List)
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev A utility library for using sorted linked list data structures in your Solidity project.
 */
library LinkedList {

    uint256 private constant NULL = 0;
    uint256 private constant HEAD = 0;

    bool private constant PREV = false;
    bool private constant NEXT = true;

    struct List {
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function isList(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function isNode(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function range(List storage self) internal view returns (uint256) {
        uint256 i;
        uint256 num;
        (, i) = adj(self, HEAD, NEXT);
        while (i != HEAD) {
            (, i) = adj(self, i, NEXT);
            num++;
        }
        return num;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function node(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!isNode(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function adj(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!isNode(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function next(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return adj(self, _node, NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function prev(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return adj(self, _node, PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `back` or `face` basing on your list order.
     * @dev If you want to order basing on other than `structure.val()` override this function
     * @param self stored linked list from contract
     * @param _struct the structure instance
     * @param _val value to seek
     * @return uint256 next node with a value less than StructLike(_struct).val(next_)
     */
    function sort(List storage self, address _struct, uint256 _val) internal view returns (uint256) {
        if (range(self) == 0) {
            return 0;
        }
        bool exists;
        uint256 next_;
        (exists, next_) = adj(self, HEAD, NEXT);
        while ((next_ != 0) && ((_val < StructLike(_struct).val(next_)) != NEXT)) {
            next_ = self.list[next_][NEXT];
        }
        return next_;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node first node for linking
     * @param _link  node to link to in the _direction
     */
    function form(List storage self, uint256 _node, uint256 _link, bool _dir) internal {
        self.list[_link][!_dir] = _node;
        self.list[_node][_dir] = _link;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function insert(List storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if (!isNode(self, _new) && isNode(self, _node)) {
            uint256 c = self.list[_node][_direction];
            form(self, _node, _new, _direction);
            form(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function face(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return insert(self, _node, _new, NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function back(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return insert(self, _node, _new, PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function del(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!isNode(self, _node))) {
            return 0;
        }
        form(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

    /**
     * @dev Pushes an entry to the head or tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (NEXT) or tail (PREV)
     * @return bool true if success, false otherwise
     */
    function push(List storage self, uint256 _node, bool _direction) internal returns (bool) {
        return insert(self, HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (NEXT) or the tail (PREV)
     * @return uint256 the removed node
     */
    function pop(List storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj_;
        (exists, adj_) = adj(self, HEAD, _direction);
        return del(self, adj_);
    }
}

////// /nix/store/y030pwvdl929ab9l65d81l2nx85p3gwn-geb/dapp/geb/src/TaxCollector.sol
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

/* pragma solidity 0.6.7; */

/* import "./LinkedList.sol"; */

abstract contract SAFEEngineLike_12 {
    function collateralTypes(bytes32) virtual public view returns (
        uint256 debtAmount,       // [wad]
        uint256 accumulatedRate   // [ray]
    );
    function updateAccumulatedRate(bytes32,address,int256) virtual external;
    function coinBalance(address) virtual public view returns (uint256);
}

contract TaxCollector {
    using LinkedList for LinkedList.List;

    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "TaxCollector/account-not-authorized");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event InitializeCollateralType(bytes32 collateralType);
    event ModifyParameters(
      bytes32 collateralType,
      bytes32 parameter,
      uint256 data
    );
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event ModifyParameters(
      bytes32 collateralType,
      uint256 position,
      uint256 val
    );
    event ModifyParameters(
      bytes32 collateralType,
      uint256 position,
      uint256 taxPercentage,
      address receiverAccount
    );
    event AddSecondaryReceiver(
      bytes32 indexed collateralType,
      uint256 secondaryReceiverNonce,
      uint256 latestSecondaryReceiver,
      uint256 secondaryReceiverAllotedTax,
      uint256 secondaryReceiverRevenueSources
    );
    event ModifySecondaryReceiver(
      bytes32 indexed collateralType,
      uint256 secondaryReceiverNonce,
      uint256 latestSecondaryReceiver,
      uint256 secondaryReceiverAllotedTax,
      uint256 secondaryReceiverRevenueSources
    );
    event CollectTax(bytes32 indexed collateralType, uint256 latestAccumulatedRate, int256 deltaRate);
    event DistributeTax(bytes32 indexed collateralType, address indexed target, int256 taxCut);

    // --- Data ---
    struct CollateralType {
        // Per second borrow rate for this specific collateral type
        uint256 stabilityFee;
        // When SF was last collected for this collateral type
        uint256 updateTime;
    }
    // SF receiver
    struct TaxReceiver {
        // Whether this receiver can accept a negative rate (taking SF from it)
        uint256 canTakeBackTax;                                                 // [bool]
        // Percentage of SF allocated to this receiver
        uint256 taxPercentage;                                                  // [ray%]
    }

    // Data about each collateral type
    mapping (bytes32 => CollateralType)                  public collateralTypes;
    // Percentage of each collateral's SF that goes to other addresses apart from the primary receiver
    mapping (bytes32 => uint256)                         public secondaryReceiverAllotedTax;              // [%ray]
    // Whether an address is already used for a tax receiver
    mapping (address => uint256)                         public usedSecondaryReceiver;                    // [bool]
    // Address associated to each tax receiver index
    mapping (uint256 => address)                         public secondaryReceiverAccounts;
    // How many collateral types send SF to a specific tax receiver
    mapping (address => uint256)                         public secondaryReceiverRevenueSources;
    // Tax receiver data
    mapping (bytes32 => mapping(uint256 => TaxReceiver)) public secondaryTaxReceivers;

    // The address that always receives some SF
    address    public primaryTaxReceiver;
    // Base stability fee charged to all collateral types
    uint256    public globalStabilityFee;                                                                 // [ray%]
    // Number of secondary tax receivers ever added
    uint256    public secondaryReceiverNonce;
    // Max number of secondarytax receivers a collateral type can have
    uint256    public maxSecondaryReceivers;
    // Latest secondary tax receiver that still has at least one revenue source
    uint256    public latestSecondaryReceiver;

    // All collateral types
    bytes32[]        public   collateralList;
    // Linked list with tax receiver data
    LinkedList.List  internal secondaryReceiverList;

    SAFEEngineLike_12 public safeEngine;

    // --- Init ---
    constructor(address safeEngine_) public {
        authorizedAccounts[msg.sender] = 1;
        safeEngine = SAFEEngineLike_12(safeEngine_);
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    uint256 public constant RAY           = 10 ** 27;
    uint256 public constant WHOLE_TAX_CUT = 10 ** 29;
    uint256 public constant ONE           = 1;
    int256  public constant INT256_MIN    = -2**255;

    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x, "TaxCollector/add-uint-uint-overflow");
    }
    function addition(int256 x, int256 y) internal pure returns (int256 z) {
        z = x + y;
        if (y <= 0) require(z <= x, "TaxCollector/add-int-int-underflow");
        if (y  > 0) require(z > x, "TaxCollector/add-int-int-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "TaxCollector/sub-uint-uint-underflow");
    }
    function subtract(int256 x, int256 y) internal pure returns (int256 z) {
        z = x - y;
        require(y <= 0 || z <= x, "TaxCollector/sub-int-int-underflow");
        require(y >= 0 || z >= x, "TaxCollector/sub-int-int-overflow");
    }
    function deduct(uint256 x, uint256 y) internal pure returns (int256 z) {
        z = int256(x) - int256(y);
        require(int256(x) >= 0 && int256(y) >= 0, "TaxCollector/ded-invalid-numbers");
    }
    function multiply(uint256 x, int256 y) internal pure returns (int256 z) {
        z = int256(x) * y;
        require(int256(x) >= 0, "TaxCollector/mul-uint-int-invalid-x");
        require(y == 0 || z / y == int256(x), "TaxCollector/mul-uint-int-overflow");
    }
    function multiply(int256 x, int256 y) internal pure returns (int256 z) {
        require(!both(x == -1, y == INT256_MIN), "TaxCollector/mul-int-int-overflow");
        require(y == 0 || (z = x * y) / y == x, "TaxCollector/mul-int-int-invalid");
    }
    function rmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x, "TaxCollector/rmul-overflow");
        z = z / RAY;
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Administration ---
    /**
     * @notice Initialize a brand new collateral type
     * @param collateralType Collateral type name (e.g ETH-A, TBTC-B)
     */
    function initializeCollateralType(bytes32 collateralType) external isAuthorized {
        CollateralType storage collateralType_ = collateralTypes[collateralType];
        require(collateralType_.stabilityFee == 0, "TaxCollector/collateral-type-already-init");
        collateralType_.stabilityFee = RAY;
        collateralType_.updateTime   = now;
        collateralList.push(collateralType);
        emit InitializeCollateralType(collateralType);
    }
    /**
     * @notice Modify collateral specific uint256 params
     * @param collateralType Collateral type who's parameter is modified
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) external isAuthorized {
        require(now == collateralTypes[collateralType].updateTime, "TaxCollector/update-time-not-now");
        if (parameter == "stabilityFee") collateralTypes[collateralType].stabilityFee = data;
        else revert("TaxCollector/modify-unrecognized-param");
        emit ModifyParameters(
          collateralType,
          parameter,
          data
        );
    }
    /**
     * @notice Modify general uint256 params
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "globalStabilityFee") globalStabilityFee = data;
        else if (parameter == "maxSecondaryReceivers") maxSecondaryReceivers = data;
        else revert("TaxCollector/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify general address params
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "TaxCollector/null-data");
        if (parameter == "primaryTaxReceiver") primaryTaxReceiver = data;
        else revert("TaxCollector/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Set whether a tax receiver can incur negative fees
     * @param collateralType Collateral type giving fees to the tax receiver
     * @param position Receiver position in the list
     * @param val Value that specifies whether a tax receiver can incur negative rates
     */
    function modifyParameters(
        bytes32 collateralType,
        uint256 position,
        uint256 val
    ) external isAuthorized {
        if (both(secondaryReceiverList.isNode(position), secondaryTaxReceivers[collateralType][position].taxPercentage > 0)) {
            secondaryTaxReceivers[collateralType][position].canTakeBackTax = val;
        }
        else revert("TaxCollector/unknown-tax-receiver");
        emit ModifyParameters(
          collateralType,
          position,
          val
        );
    }
    /**
     * @notice Create or modify a secondary tax receiver's data
     * @param collateralType Collateral type that will give SF to the tax receiver
     * @param position Receiver position in the list. Used to determine whether a new tax receiver is
              created or an existing one is edited
     * @param taxPercentage Percentage of SF offered to the tax receiver
     * @param receiverAccount Receiver address
     */
    function modifyParameters(
      bytes32 collateralType,
      uint256 position,
      uint256 taxPercentage,
      address receiverAccount
    ) external isAuthorized {
        (!secondaryReceiverList.isNode(position)) ?
          addSecondaryReceiver(collateralType, taxPercentage, receiverAccount) :
          modifySecondaryReceiver(collateralType, position, taxPercentage);
        emit ModifyParameters(
          collateralType,
          position,
          taxPercentage,
          receiverAccount
        );
    }

    // --- Tax Receiver Utils ---
    /**
     * @notice Add a new secondary tax receiver
     * @param collateralType Collateral type that will give SF to the tax receiver
     * @param taxPercentage Percentage of SF offered to the tax receiver
     * @param receiverAccount Tax receiver address
     */
    function addSecondaryReceiver(bytes32 collateralType, uint256 taxPercentage, address receiverAccount) internal {
        require(receiverAccount != address(0), "TaxCollector/null-account");
        require(receiverAccount != primaryTaxReceiver, "TaxCollector/primary-receiver-cannot-be-secondary");
        require(taxPercentage > 0, "TaxCollector/null-sf");
        require(usedSecondaryReceiver[receiverAccount] == 0, "TaxCollector/account-already-used");
        require(addition(secondaryReceiversAmount(), ONE) <= maxSecondaryReceivers, "TaxCollector/exceeds-max-receiver-limit");
        require(addition(secondaryReceiverAllotedTax[collateralType], taxPercentage) < WHOLE_TAX_CUT, "TaxCollector/tax-cut-exceeds-hundred");
        secondaryReceiverNonce                                                       = addition(secondaryReceiverNonce, 1);
        latestSecondaryReceiver                                                      = secondaryReceiverNonce;
        usedSecondaryReceiver[receiverAccount]                                       = ONE;
        secondaryReceiverAllotedTax[collateralType]                                  = addition(secondaryReceiverAllotedTax[collateralType], taxPercentage);
        secondaryTaxReceivers[collateralType][latestSecondaryReceiver].taxPercentage = taxPercentage;
        secondaryReceiverAccounts[latestSecondaryReceiver]                           = receiverAccount;
        secondaryReceiverRevenueSources[receiverAccount]                             = ONE;
        secondaryReceiverList.push(latestSecondaryReceiver, false);
        emit AddSecondaryReceiver(
          collateralType,
          secondaryReceiverNonce,
          latestSecondaryReceiver,
          secondaryReceiverAllotedTax[collateralType],
          secondaryReceiverRevenueSources[receiverAccount]
        );
    }
    /**
     * @notice Update a secondary tax receiver's data (add a new SF source or modify % of SF taken from a collateral type)
     * @param collateralType Collateral type that will give SF to the tax receiver
     * @param position Receiver's position in the tax receiver list
     * @param taxPercentage Percentage of SF offered to the tax receiver (ray%)
     */
    function modifySecondaryReceiver(bytes32 collateralType, uint256 position, uint256 taxPercentage) internal {
        if (taxPercentage == 0) {
          secondaryReceiverAllotedTax[collateralType] = subtract(
            secondaryReceiverAllotedTax[collateralType],
            secondaryTaxReceivers[collateralType][position].taxPercentage
          );

          if (secondaryReceiverRevenueSources[secondaryReceiverAccounts[position]] == 1) {
            if (position == latestSecondaryReceiver) {
              (, uint256 prevReceiver) = secondaryReceiverList.prev(latestSecondaryReceiver);
              latestSecondaryReceiver = prevReceiver;
            }
            secondaryReceiverList.del(position);
            delete(usedSecondaryReceiver[secondaryReceiverAccounts[position]]);
            delete(secondaryTaxReceivers[collateralType][position]);
            delete(secondaryReceiverRevenueSources[secondaryReceiverAccounts[position]]);
            delete(secondaryReceiverAccounts[position]);
          } else if (secondaryTaxReceivers[collateralType][position].taxPercentage > 0) {
            secondaryReceiverRevenueSources[secondaryReceiverAccounts[position]] = subtract(secondaryReceiverRevenueSources[secondaryReceiverAccounts[position]], 1);
            delete(secondaryTaxReceivers[collateralType][position]);
          }
        } else {
          uint256 secondaryReceiverAllotedTax_ = addition(
            subtract(secondaryReceiverAllotedTax[collateralType], secondaryTaxReceivers[collateralType][position].taxPercentage),
            taxPercentage
          );
          require(secondaryReceiverAllotedTax_ < WHOLE_TAX_CUT, "TaxCollector/tax-cut-too-big");
          if (secondaryTaxReceivers[collateralType][position].taxPercentage == 0) {
            secondaryReceiverRevenueSources[secondaryReceiverAccounts[position]] = addition(
              secondaryReceiverRevenueSources[secondaryReceiverAccounts[position]],
              1
            );
          }
          secondaryReceiverAllotedTax[collateralType]                   = secondaryReceiverAllotedTax_;
          secondaryTaxReceivers[collateralType][position].taxPercentage = taxPercentage;
        }
        emit ModifySecondaryReceiver(
          collateralType,
          secondaryReceiverNonce,
          latestSecondaryReceiver,
          secondaryReceiverAllotedTax[collateralType],
          secondaryReceiverRevenueSources[secondaryReceiverAccounts[position]]
        );
    }

    // --- Tax Collection Utils ---
    /**
     * @notice Check if multiple collateral types are up to date with taxation
     */
    function collectedManyTax(uint256 start, uint256 end) public view returns (bool ok) {
        require(both(start <= end, end < collateralList.length), "TaxCollector/invalid-indexes");
        for (uint256 i = start; i <= end; i++) {
          if (now > collateralTypes[collateralList[i]].updateTime) {
            ok = false;
            return ok;
          }
        }
        ok = true;
    }
    /**
     * @notice Check how much SF will be charged (to collateral types between indexes 'start' and 'end'
     *         in the collateralList) during the next taxation
     * @param start Index in collateralList from which to start looping and calculating the tax outcome
     * @param end Index in collateralList at which we stop looping and calculating the tax outcome
     */
    function taxManyOutcome(uint256 start, uint256 end) public view returns (bool ok, int256 rad) {
        require(both(start <= end, end < collateralList.length), "TaxCollector/invalid-indexes");
        int256  primaryReceiverBalance = -int256(safeEngine.coinBalance(primaryTaxReceiver));
        int256  deltaRate;
        uint256 debtAmount;
        for (uint256 i = start; i <= end; i++) {
          if (now > collateralTypes[collateralList[i]].updateTime) {
            (debtAmount, ) = safeEngine.collateralTypes(collateralList[i]);
            (, deltaRate)  = taxSingleOutcome(collateralList[i]);
            rad = addition(rad, multiply(debtAmount, deltaRate));
          }
        }
        if (rad < 0) {
          ok = (rad < primaryReceiverBalance) ? false : true;
        } else {
          ok = true;
        }
    }
    /**
     * @notice Get how much SF will be distributed after taxing a specific collateral type
     * @param collateralType Collateral type to compute the taxation outcome for
     * @return The newly accumulated rate as well as the delta between the new and the last accumulated rates
     */
    function taxSingleOutcome(bytes32 collateralType) public view returns (uint256, int256) {
        (, uint256 lastAccumulatedRate) = safeEngine.collateralTypes(collateralType);
        uint256 newlyAccumulatedRate =
          rmultiply(
            rpow(
              addition(
                globalStabilityFee,
                collateralTypes[collateralType].stabilityFee
              ),
              subtract(
                now,
                collateralTypes[collateralType].updateTime
              ),
            RAY),
          lastAccumulatedRate);
        return (newlyAccumulatedRate, deduct(newlyAccumulatedRate, lastAccumulatedRate));
    }

    // --- Tax Receiver Utils ---
    /**
     * @notice Get the secondary tax receiver list length
     */
    function secondaryReceiversAmount() public view returns (uint256) {
        return secondaryReceiverList.range();
    }
    /**
     * @notice Get the collateralList length
     */
    function collateralListLength() public view returns (uint256) {
        return collateralList.length;
    }
    /**
     * @notice Check if a tax receiver is at a certain position in the list
     */
    function isSecondaryReceiver(uint256 _receiver) public view returns (bool) {
        if (_receiver == 0) return false;
        return secondaryReceiverList.isNode(_receiver);
    }

    // --- Tax (Stability Fee) Collection ---
    /**
     * @notice Collect tax from multiple collateral types at once
     * @param start Index in collateralList from which to start looping and calculating the tax outcome
     * @param end Index in collateralList at which we stop looping and calculating the tax outcome
     */
    function taxMany(uint256 start, uint256 end) external {
        require(both(start <= end, end < collateralList.length), "TaxCollector/invalid-indexes");
        for (uint256 i = start; i <= end; i++) {
            taxSingle(collateralList[i]);
        }
    }
    /**
     * @notice Collect tax from a single collateral type
     * @param collateralType Collateral type to tax
     */
    function taxSingle(bytes32 collateralType) public returns (uint256) {
        uint256 latestAccumulatedRate;
        if (now <= collateralTypes[collateralType].updateTime) {
          (, latestAccumulatedRate) = safeEngine.collateralTypes(collateralType);
          return latestAccumulatedRate;
        }
        (, int256 deltaRate) = taxSingleOutcome(collateralType);
        // Check how much debt has been generated for collateralType
        (uint256 debtAmount, ) = safeEngine.collateralTypes(collateralType);
        splitTaxIncome(collateralType, debtAmount, deltaRate);
        (, latestAccumulatedRate) = safeEngine.collateralTypes(collateralType);
        collateralTypes[collateralType].updateTime = now;
        emit CollectTax(collateralType, latestAccumulatedRate, deltaRate);
        return latestAccumulatedRate;
    }
    /**
     * @notice Split SF between all tax receivers
     * @param collateralType Collateral type to distribute SF for
     * @param deltaRate Difference between the last and the latest accumulate rates for the collateralType
     */
    function splitTaxIncome(bytes32 collateralType, uint256 debtAmount, int256 deltaRate) internal {
        // Start looping from the latest tax receiver
        uint256 currentSecondaryReceiver = latestSecondaryReceiver;
        // While we still haven't gone through the entire tax receiver list
        while (currentSecondaryReceiver > 0) {
          // If the current tax receiver should receive SF from collateralType
          if (secondaryTaxReceivers[collateralType][currentSecondaryReceiver].taxPercentage > 0) {
            distributeTax(
              collateralType,
              secondaryReceiverAccounts[currentSecondaryReceiver],
              currentSecondaryReceiver,
              debtAmount,
              deltaRate
            );
          }
          // Continue looping
          (, currentSecondaryReceiver) = secondaryReceiverList.prev(currentSecondaryReceiver);
        }
        // Distribute to primary receiver
        distributeTax(collateralType, primaryTaxReceiver, uint256(-1), debtAmount, deltaRate);
    }

    /**
     * @notice Give/withdraw SF from a tax receiver
     * @param collateralType Collateral type to distribute SF for
     * @param receiver Tax receiver address
     * @param receiverListPosition Position of receiver in the secondaryReceiverList (if the receiver is secondary)
     * @param debtAmount Total debt currently issued
     * @param deltaRate Difference between the latest and the last accumulated rates for the collateralType
     */
    function distributeTax(
        bytes32 collateralType,
        address receiver,
        uint256 receiverListPosition,
        uint256 debtAmount,
        int256 deltaRate
    ) internal {
        require(safeEngine.coinBalance(receiver) < 2**255, "TaxCollector/coin-balance-does-not-fit-into-int256");
        // Check how many coins the receiver has and negate the value
        int256 coinBalance   = -int256(safeEngine.coinBalance(receiver));
        // Compute the % out of SF that should be allocated to the receiver
        int256 currentTaxCut = (receiver == primaryTaxReceiver) ?
          multiply(subtract(WHOLE_TAX_CUT, secondaryReceiverAllotedTax[collateralType]), deltaRate) / int256(WHOLE_TAX_CUT) :
          multiply(int256(secondaryTaxReceivers[collateralType][receiverListPosition].taxPercentage), deltaRate) / int256(WHOLE_TAX_CUT);
        /**
            If SF is negative and a tax receiver doesn't have enough coins to absorb the loss,
            compute a new tax cut that can be absorbed
        **/
        currentTaxCut  = (
          both(multiply(debtAmount, currentTaxCut) < 0, coinBalance > multiply(debtAmount, currentTaxCut))
        ) ? coinBalance / int256(debtAmount) : currentTaxCut;
        /**
          If the tax receiver's tax cut is not null and if the receiver accepts negative SF
          offer/take SF to/from them
        **/
        if (currentTaxCut != 0) {
          if (
            either(
              receiver == primaryTaxReceiver,
              either(
                deltaRate >= 0,
                both(currentTaxCut < 0, secondaryTaxReceivers[collateralType][receiverListPosition].canTakeBackTax > 0)
              )
            )
          ) {
            safeEngine.updateAccumulatedRate(collateralType, receiver, currentTaxCut);
            emit DistributeTax(collateralType, receiver, currentTaxCut);
          }
       }
    }
}

////// /nix/store/zzn5ww2xv48rynmb4h4g3acd4sjgb2fq-esm/dapp/esm/src/ESM.sol
// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

abstract contract ESMThresholdSetter {
    function recomputeThreshold() virtual public;
}

abstract contract TokenLike_3 {
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address) virtual public view returns (uint256);
    function transfer(address, uint256) virtual public returns (bool);
    function transferFrom(address, address, uint256) virtual public returns (bool);
}

abstract contract GlobalSettlementLike_2 {
    function shutdownSystem() virtual public;
}

contract ESM {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) public isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) public isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "esm/account-not-authorized");
        _;
    }

    TokenLike_3            public protocolToken;      // collateral
    GlobalSettlementLike_2 public globalSettlement;   // shutdown module
    ESMThresholdSetter   public thresholdSetter;    // threshold setter

    address              public tokenBurner;        // burner
    uint256              public triggerThreshold;   // threshold
    uint256              public settled;            // flag that indicates whether the shutdown module has been called/triggered

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 wad);
    event ModifyParameters(bytes32 parameter, address account);
    event Shutdown();
    event FailRecomputeThreshold(bytes revertReason);

    constructor(
      address protocolToken_,
      address globalSettlement_,
      address tokenBurner_,
      address thresholdSetter_,
      uint256 triggerThreshold_
    ) public {
        require(both(triggerThreshold_ > 0, triggerThreshold_ < TokenLike_3(protocolToken_).totalSupply()), "esm/threshold-not-within-bounds");

        authorizedAccounts[msg.sender] = 1;

        protocolToken    = TokenLike_3(protocolToken_);
        globalSettlement = GlobalSettlementLike_2(globalSettlement_);
        thresholdSetter  = ESMThresholdSetter(thresholdSetter_);
        tokenBurner      = tokenBurner_;
        triggerThreshold = triggerThreshold_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters(bytes32("triggerThreshold"), triggerThreshold_);
        emit ModifyParameters(bytes32("thresholdSetter"), thresholdSetter_);
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    // --- Utils ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Administration ---
    /*
    * @notice Modify a uint256 parameter
    * @param parameter The name of the parameter to change the value for
    * @param wad The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 wad) external {
        require(settled == 0, "esm/already-settled");
        require(either(address(thresholdSetter) == msg.sender, authorizedAccounts[msg.sender] == 1), "esm/account-not-authorized");
        if (parameter == "triggerThreshold") {
          require(both(wad > 0, wad < protocolToken.totalSupply()), "esm/threshold-not-within-bounds");
          triggerThreshold = wad;
        }
        else revert("esm/modify-unrecognized-param");
        emit ModifyParameters(parameter, wad);
    }
    /*
    * @notice Modify an address parameter
    * @param parameter The parameter name whose value will be changed
    * @param account The new address for the parameter
    */
    function modifyParameters(bytes32 parameter, address account) external isAuthorized {
        require(settled == 0, "esm/already-settled");
        if (parameter == "thresholdSetter") {
          thresholdSetter = ESMThresholdSetter(account);
          // Make sure the update works
          thresholdSetter.recomputeThreshold();
        }
        else revert("esm/modify-unrecognized-param");
        emit ModifyParameters(parameter, account);
    }

    /*
    * @notify Recompute the triggerThreshold using the thresholdSetter
    */
    function recomputeThreshold() internal {
        if (address(thresholdSetter) != address(0)) {
          try thresholdSetter.recomputeThreshold() {}
          catch(bytes memory revertReason) {
            emit FailRecomputeThreshold(revertReason);
          }
        }
    }
    /*
    * @notice Sacrifice tokens and trigger settlement
    * @dev This can only be done once
    */
    function shutdown() external {
        require(settled == 0, "esm/already-settled");
        recomputeThreshold();
        settled = 1;
        require(protocolToken.transferFrom(msg.sender, tokenBurner, triggerThreshold), "esm/transfer-failed");
        emit Shutdown();
        globalSettlement.shutdownSystem();
    }
}

////// /nix/store/3kgg4vdxd3j6d12khdjg0jp7pg92lngx-h20-deploy/dapp/h20-deploy/src/GebDeploy.sol
/// GebDeploy.sol

// Copyright (C) 2018-2019 Gonzalo Balabasquer <[email protected]>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

/* import {DSAuth, DSAuthority} from "ds-auth/auth.sol"; */
/* import {DSPause, DSPauseProxy} from "ds-pause/pause.sol"; */
/* import {DSProtestPause} from "ds-pause/protest-pause.sol"; */

/* import {SAFEEngine} from "geb/SAFEEngine.sol"; */
/* import {TaxCollector} from "geb/TaxCollector.sol"; */
/* import {AccountingEngine} from "geb/AccountingEngine.sol"; */
/* import {LiquidationEngine} from "geb/LiquidationEngine.sol"; */
/* import {CoinJoin} from "geb/BasicTokenAdapters.sol"; */
/* import {RecyclingSurplusAuctionHouse, BurningSurplusAuctionHouse} from "geb/SurplusAuctionHouse.sol"; */
/* import {DebtAuctionHouse} from "geb/DebtAuctionHouse.sol"; */
/* import {EnglishCollateralAuctionHouse, IncreasingDiscountCollateralAuctionHouse , FixedDiscountCollateralAuctionHouse} from "geb/CollateralAuctionHouse.sol"; */
/* import {Coin} from "geb/Coin.sol"; */
/* import {GlobalSettlement} from "geb/GlobalSettlement.sol"; */
/* import {ESM} from "esm/ESM.sol"; */
/* import {StabilityFeeTreasury} from "geb/StabilityFeeTreasury.sol"; */
/* import {CoinSavingsAccount} from "geb/CoinSavingsAccount.sol"; */
/* import {OracleRelayer} from "geb/OracleRelayer.sol"; */

abstract contract CollateralAuctionHouse {
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, address) virtual external;
}

abstract contract AuthorizableContract {
    function addAuthorization(address) virtual external;
    function removeAuthorization(address) virtual external;
}

contract SAFEEngineFactory {
    function newSAFEEngine() public returns (SAFEEngine safeEngine) {
        safeEngine = new SAFEEngine();
        safeEngine.addAuthorization(msg.sender);
        safeEngine.removeAuthorization(address(this));
    }
}

contract TaxCollectorFactory {
    function newTaxCollector(address safeEngine) public returns (TaxCollector taxCollector) {
        taxCollector = new TaxCollector(safeEngine);
        taxCollector.addAuthorization(msg.sender);
        taxCollector.removeAuthorization(address(this));
    }
}

contract AccountingEngineFactory {
    function newAccountingEngine(address safeEngine, address surplusAuctionHouse, address debtAuctionHouse) public returns (AccountingEngine accountingEngine) {
        accountingEngine = new AccountingEngine(safeEngine, surplusAuctionHouse, debtAuctionHouse);
        accountingEngine.addAuthorization(msg.sender);
        accountingEngine.removeAuthorization(address(this));
    }
}

contract LiquidationEngineFactory {
    function newLiquidationEngine(address safeEngine) public returns (LiquidationEngine liquidationEngine) {
        liquidationEngine = new LiquidationEngine(safeEngine);
        liquidationEngine.addAuthorization(msg.sender);
        liquidationEngine.removeAuthorization(address(this));
    }
}

contract CoinFactory {
    function newCoin(string memory name, string memory symbol, uint chainId)
      public returns (Coin coin) {
        coin = new Coin(name, symbol, chainId);
        coin.addAuthorization(msg.sender);
        coin.removeAuthorization(address(this));
    }
}

contract CoinJoinFactory {
    function newCoinJoin(address safeEngine, address coin) public returns (CoinJoin coinJoin) {
        coinJoin = new CoinJoin(safeEngine, coin);
        coinJoin.addAuthorization(msg.sender);
        coinJoin.removeAuthorization(address(this));
    }
}

contract BurningSurplusAuctionHouseFactory {
    function newSurplusAuctionHouse(address safeEngine, address prot) public returns (BurningSurplusAuctionHouse surplusAuctionHouse) {
        surplusAuctionHouse = new BurningSurplusAuctionHouse(safeEngine, prot);
        surplusAuctionHouse.addAuthorization(msg.sender);
        surplusAuctionHouse.removeAuthorization(address(this));
    }
}

contract RecyclingSurplusAuctionHouseFactory {
    function newSurplusAuctionHouse(address safeEngine, address prot) public returns (RecyclingSurplusAuctionHouse surplusAuctionHouse) {
        surplusAuctionHouse = new RecyclingSurplusAuctionHouse(safeEngine, prot);
        surplusAuctionHouse.addAuthorization(msg.sender);
        surplusAuctionHouse.removeAuthorization(address(this));
    }
}

contract DebtAuctionHouseFactory {
    function newDebtAuctionHouse(address safeEngine, address prot) public returns (DebtAuctionHouse debtAuctionHouse) {
        debtAuctionHouse = new DebtAuctionHouse(safeEngine, prot);
        debtAuctionHouse.addAuthorization(msg.sender);
        debtAuctionHouse.removeAuthorization(address(this));
    }
}

contract EnglishCollateralAuctionHouseFactory {
    function newCollateralAuctionHouse(address safeEngine, address liquidationEngine, bytes32 collateralType) public returns (EnglishCollateralAuctionHouse englishCollateralAuctionHouse) {
        englishCollateralAuctionHouse = new EnglishCollateralAuctionHouse(safeEngine, liquidationEngine, collateralType);
        englishCollateralAuctionHouse.addAuthorization(msg.sender);
        englishCollateralAuctionHouse.removeAuthorization(address(this));
    }
}

contract IncreasingDiscountCollateralAuctionHouseFactory {
    function newCollateralAuctionHouse(address safeEngine, address liquidationEngine, bytes32 collateralType) public returns (IncreasingDiscountCollateralAuctionHouse increasingDiscountCollateralAuctionHouse) {
        increasingDiscountCollateralAuctionHouse = new IncreasingDiscountCollateralAuctionHouse(safeEngine, liquidationEngine, collateralType);
        increasingDiscountCollateralAuctionHouse.addAuthorization(msg.sender);
        increasingDiscountCollateralAuctionHouse.removeAuthorization(address(this));
    }
}

contract FixedDiscountCollateralAuctionHouseFactory {
    function newCollateralAuctionHouse(address safeEngine , address liquidationEngine , bytes32 collateralType) public returns (FixedDiscountCollateralAuctionHouse  fixedDiscountCollateralAuctionHouse) {
      fixedDiscountCollateralAuctionHouse = new FixedDiscountCollateralAuctionHouse(safeEngine , liquidationEngine , collateralType);
      fixedDiscountCollateralAuctionHouse.addAuthorization(msg.sender);
      fixedDiscountCollateralAuctionHouse.removeAuthorization(address(this));

    }
}




contract OracleRelayerFactory {
    function newOracleRelayer(address safeEngine) public returns (OracleRelayer oracleRelayer) {
        oracleRelayer = new OracleRelayer(safeEngine);
        oracleRelayer.addAuthorization(msg.sender);
        oracleRelayer.removeAuthorization(address(this));
    }
}

contract CoinSavingsAccountFactory {
    function newCoinSavingsAccount(address safeEngine) public returns (CoinSavingsAccount coinSavingsAccount) {
        coinSavingsAccount = new CoinSavingsAccount(safeEngine);
        coinSavingsAccount.addAuthorization(msg.sender);
        coinSavingsAccount.removeAuthorization(address(this));
    }
}

contract StabilityFeeTreasuryFactory {
    function newStabilityFeeTreasury(
      address safeEngine,
      address accountingEngine,
      address coinJoin
    ) public returns (StabilityFeeTreasury stabilityFeeTreasury) {
        stabilityFeeTreasury = new StabilityFeeTreasury(safeEngine, accountingEngine, coinJoin);
        stabilityFeeTreasury.addAuthorization(msg.sender);
        stabilityFeeTreasury.removeAuthorization(address(this));
    }
}

contract ESMFactory {
    function newESM(
        address prot, address globalSettlement, address tokenBurner, address thresholdSetter, uint threshold
    ) public returns (ESM esm) {
        esm = new ESM(prot, globalSettlement, tokenBurner, thresholdSetter, threshold);
        esm.addAuthorization(msg.sender);
        esm.removeAuthorization(address(this));
    }
}

contract GlobalSettlementFactory {
    function newGlobalSettlement() public returns (GlobalSettlement globalSettlement) {
        globalSettlement = new GlobalSettlement();
        globalSettlement.addAuthorization(msg.sender);
        globalSettlement.removeAuthorization(address(this));
    }
}

contract PauseFactory {
    function newPause(uint delay, address owner, DSAuthority authority) public returns (DSPause pause) {
        pause = new DSPause(delay, owner, authority);
    }
}

contract ProtestPauseFactory {
    function newPause(uint protesterLifetime, uint delay, address owner, DSAuthority authority) public returns (DSProtestPause pause) {
        pause = new DSProtestPause(protesterLifetime, delay, owner, authority);
    }
}

contract GebDeploy is DSAuth {
    SAFEEngineFactory                               public safeEngineFactory;
    TaxCollectorFactory                             public taxCollectorFactory;
    AccountingEngineFactory                         public accountingEngineFactory;
    LiquidationEngineFactory                        public liquidationEngineFactory;
    CoinFactory                                     public coinFactory;
    CoinJoinFactory                                 public coinJoinFactory;
    StabilityFeeTreasuryFactory                     public stabilityFeeTreasuryFactory;
    RecyclingSurplusAuctionHouseFactory             public recyclingSurplusAuctionHouseFactory;
    BurningSurplusAuctionHouseFactory               public burningSurplusAuctionHouseFactory;
    DebtAuctionHouseFactory                         public debtAuctionHouseFactory;
    EnglishCollateralAuctionHouseFactory            public englishCollateralAuctionHouseFactory;
    IncreasingDiscountCollateralAuctionHouseFactory public increasingDiscountCollateralAuctionHouseFactory;
    FixedDiscountCollateralAuctionHouseFactory      public fixedDiscountCollateralAuctionHouseFactory;
    OracleRelayerFactory                            public oracleRelayerFactory;
    GlobalSettlementFactory                         public globalSettlementFactory;
    ESMFactory                                      public esmFactory;
    PauseFactory                                    public pauseFactory;
    ProtestPauseFactory                             public protestPauseFactory;
    CoinSavingsAccountFactory                       public coinSavingsAccountFactory;

    SAFEEngine                        public safeEngine;
    TaxCollector                      public taxCollector;
    AccountingEngine                  public accountingEngine;
    LiquidationEngine                 public liquidationEngine;
    StabilityFeeTreasury              public stabilityFeeTreasury;
    Coin                              public coin;
    CoinJoin                          public coinJoin;
    RecyclingSurplusAuctionHouse      public recyclingSurplusAuctionHouse;
    BurningSurplusAuctionHouse        public burningSurplusAuctionHouse;
    DebtAuctionHouse                  public debtAuctionHouse;
    OracleRelayer                     public oracleRelayer;
    CoinSavingsAccount                public coinSavingsAccount;
    GlobalSettlement                  public globalSettlement;
    ESM                               public esm;
    DSPause                           public pause;
    DSProtestPause                    public protestPause;

    mapping(bytes32 => CollateralType) public collateralTypes;

    struct CollateralType {
        EnglishCollateralAuctionHouse englishCollateralAuctionHouse;
        //TODO : changed to fixedDiscountAuction based on the geb present deployment 
//      IncreasingDiscountCollateralAuctionHouse increasingDiscountCollateralAuctionHouse;
        FixedDiscountCollateralAuctionHouse fixedDiscountCollateralAuctionHouse;
        address adapter;
    }

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function setFirstFactoryBatch(
        SAFEEngineFactory safeEngineFactory_,
        TaxCollectorFactory taxCollectorFactory_,
        AccountingEngineFactory accountingEngineFactory_,
        LiquidationEngineFactory liquidationEngineFactory_,
        CoinFactory coinFactory_,
        CoinJoinFactory coinJoinFactory_,
        CoinSavingsAccountFactory coinSavingsAccountFactory_
    ) public auth {
        require(address(safeEngineFactory) == address(0), "SAFEEngine Factory already set");
        safeEngineFactory = safeEngineFactory_;
        taxCollectorFactory = taxCollectorFactory_;
        accountingEngineFactory = accountingEngineFactory_;
        liquidationEngineFactory = liquidationEngineFactory_;
        coinFactory = coinFactory_;
        coinJoinFactory = coinJoinFactory_;
        coinSavingsAccountFactory = coinSavingsAccountFactory_;
    }
    function setSecondFactoryBatch(
        RecyclingSurplusAuctionHouseFactory recyclingSurplusAuctionHouseFactory_,
        BurningSurplusAuctionHouseFactory burningSurplusAuctionHouseFactory_,
        DebtAuctionHouseFactory debtAuctionHouseFactory_,
        EnglishCollateralAuctionHouseFactory englishCollateralAuctionHouseFactory_,
        IncreasingDiscountCollateralAuctionHouseFactory increasingDiscountCollateralAuctionHouseFactory_,
        FixedDiscountCollateralAuctionHouseFactory fixedDiscountCollateralAuctionHouseFactory_, 
        OracleRelayerFactory oracleRelayerFactory_,
        GlobalSettlementFactory globalSettlementFactory_,
        ESMFactory esmFactory_
    ) public auth {
        require(address(safeEngineFactory) != address(0), "SAFEEngine Factory not set");
        require(address(recyclingSurplusAuctionHouseFactory) == address(0), "RecyclingSurplusAuctionHouse Factory already set");
        recyclingSurplusAuctionHouseFactory = recyclingSurplusAuctionHouseFactory_;
        burningSurplusAuctionHouseFactory = burningSurplusAuctionHouseFactory_;
        debtAuctionHouseFactory = debtAuctionHouseFactory_;
        englishCollateralAuctionHouseFactory = englishCollateralAuctionHouseFactory_;
        increasingDiscountCollateralAuctionHouseFactory = increasingDiscountCollateralAuctionHouseFactory_;
        fixedDiscountCollateralAuctionHouseFactory =  fixedDiscountCollateralAuctionHouseFactory_;
        oracleRelayerFactory = oracleRelayerFactory_;
        globalSettlementFactory = globalSettlementFactory_;
        esmFactory = esmFactory_;
    }
    function setThirdFactoryBatch(
        PauseFactory pauseFactory_,
        ProtestPauseFactory protestPauseFactory_,
        StabilityFeeTreasuryFactory stabilityFeeTreasuryFactory_
    ) public auth {
        require(address(safeEngineFactory) != address(0), "SAFEEngine Factory not set");
        pauseFactory = pauseFactory_;
        protestPauseFactory = protestPauseFactory_;
        stabilityFeeTreasuryFactory = stabilityFeeTreasuryFactory_;
    }

    function deploySAFEEngine() public auth {
        require(address(safeEngine) == address(0), "SAFEEngine already deployed");
        safeEngine = safeEngineFactory.newSAFEEngine();
        oracleRelayer = oracleRelayerFactory.newOracleRelayer(address(safeEngine));

        // Internal auth
        safeEngine.addAuthorization(address(oracleRelayer));
    }

    function deployCoin(string memory name, string memory symbol, uint256 chainId)
      public auth {
        require(address(safeEngine) != address(0), "Missing previous step");

        // Deploy
        coin      = coinFactory.newCoin(name, symbol, chainId);
        coinJoin  = coinJoinFactory.newCoinJoin(address(safeEngine), address(coin));
        coin.addAuthorization(address(coinJoin));
    }

    function deployTaxation() public auth {
        require(address(safeEngine) != address(0), "Missing previous step");

        // Deploy
        taxCollector = taxCollectorFactory.newTaxCollector(address(safeEngine));

        // Internal auth
        safeEngine.addAuthorization(address(taxCollector));
    }

    function deploySavingsAccount() public auth {
        require(address(safeEngine) != address(0), "Missing previous step");

        // Deploy
        coinSavingsAccount = coinSavingsAccountFactory.newCoinSavingsAccount(address(safeEngine));

        // Internal auth
        safeEngine.addAuthorization(address(coinSavingsAccount));
    }

    function deployAuctions(address prot, address surplusProtTokenReceiver, bytes32 surplusAuctionHouseType) public auth {
        require(address(taxCollector) != address(0), "Missing previous step");
        require(address(coin) != address(0), "Missing COIN address");

        // Deploy
        if (surplusAuctionHouseType == "recycling") {
          recyclingSurplusAuctionHouse = recyclingSurplusAuctionHouseFactory.newSurplusAuctionHouse(address(safeEngine), prot);
        }
        else {
          burningSurplusAuctionHouse = burningSurplusAuctionHouseFactory.newSurplusAuctionHouse(address(safeEngine), prot);
        }

        debtAuctionHouse = debtAuctionHouseFactory.newDebtAuctionHouse(address(safeEngine), prot);

        // Surplus auction setup
        if (surplusAuctionHouseType == "recycling" && surplusProtTokenReceiver != address(0)) {
          recyclingSurplusAuctionHouse.modifyParameters("protocolTokenBidReceiver", surplusProtTokenReceiver);
        }

        // Internal auth
        safeEngine.addAuthorization(address(debtAuctionHouse));
    }

    function deployAccountingEngine() public auth {
        address deployedSurplusAuctionHouse =
          (address(recyclingSurplusAuctionHouse) != address(0)) ?
          address(recyclingSurplusAuctionHouse) : address(burningSurplusAuctionHouse);

        accountingEngine = accountingEngineFactory.newAccountingEngine(address(safeEngine), deployedSurplusAuctionHouse, address(debtAuctionHouse));

        // Setup
        debtAuctionHouse.modifyParameters("accountingEngine", address(accountingEngine));
        taxCollector.modifyParameters("primaryTaxReceiver", address(accountingEngine));

        // Internal auth
        AuthorizableContract(deployedSurplusAuctionHouse).addAuthorization(address(accountingEngine));
        debtAuctionHouse.addAuthorization(address(accountingEngine));
    }

    function deployStabilityFeeTreasury() public auth {
        require(address(safeEngine) != address(0), "Missing previous step");
        require(address(accountingEngine) != address(0), "Missing previous step");
        require(address(coinJoin) != address(0), "Missing previous step");

        // Deploy
        stabilityFeeTreasury = stabilityFeeTreasuryFactory.newStabilityFeeTreasury(
          address(safeEngine),
          address(accountingEngine),
          address(coinJoin)
        );
    }

    function deployLiquidator() public auth {
        require(address(accountingEngine) != address(0), "Missing previous step");

        // Deploy
        liquidationEngine = liquidationEngineFactory.newLiquidationEngine(address(safeEngine));

        // Internal references set up
        liquidationEngine.modifyParameters("accountingEngine", address(accountingEngine));

        // Internal auth
        safeEngine.addAuthorization(address(liquidationEngine));
        accountingEngine.addAuthorization(address(liquidationEngine));
    }

    function deployShutdown(address prot, address tokenBurner, address thresholdSetter, uint256 threshold) public auth {
        require(address(liquidationEngine) != address(0), "Missing previous step");

        // Deploy
        globalSettlement = globalSettlementFactory.newGlobalSettlement();

        globalSettlement.modifyParameters("safeEngine", address(safeEngine));
        globalSettlement.modifyParameters("liquidationEngine", address(liquidationEngine));
        globalSettlement.modifyParameters("accountingEngine", address(accountingEngine));
        globalSettlement.modifyParameters("oracleRelayer", address(oracleRelayer));
        if (address(coinSavingsAccount) != address(0)) {
          globalSettlement.modifyParameters("coinSavingsAccount", address(coinSavingsAccount));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          globalSettlement.modifyParameters("stabilityFeeTreasury", address(stabilityFeeTreasury));
        }

        // Internal auth
        safeEngine.addAuthorization(address(globalSettlement));
        liquidationEngine.addAuthorization(address(globalSettlement));
        accountingEngine.addAuthorization(address(globalSettlement));
        oracleRelayer.addAuthorization(address(globalSettlement));
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.addAuthorization(address(globalSettlement));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.addAuthorization(address(globalSettlement));
        }

        // Deploy ESM
        if (prot != address(0)) {
          esm = esmFactory.newESM(prot, address(globalSettlement), address(tokenBurner), address(thresholdSetter), threshold);
          globalSettlement.addAuthorization(address(esm));
        }
    }

    function deployPause(uint delay, DSAuthority authority) public auth {
        require(address(coin) != address(0), "Missing previous step");
        require(address(globalSettlement) != address(0), "Missing previous step");
        require(address(protestPause) == address(0), "Protest Pause already deployed");

        pause = pauseFactory.newPause(delay, address(0), authority);
    }

    function deployProtestPause(uint protesterLifetime, uint delay, DSAuthority authority) public auth {
        require(address(coin) != address(0), "Missing previous step");
        require(address(globalSettlement) != address(0), "Missing previous step");
        require(address(pause) == address(0), "Pause already deployed");

        protestPause = protestPauseFactory.newPause(protesterLifetime, delay, address(0), authority);
    }

    function giveControl(address usr) public auth {
        address deployedSurplusAuctionHouse =
          (address(recyclingSurplusAuctionHouse) != address(0)) ?
          address(recyclingSurplusAuctionHouse) : address(burningSurplusAuctionHouse);

        safeEngine.addAuthorization(address(usr));
        liquidationEngine.addAuthorization(address(usr));
        accountingEngine.addAuthorization(address(usr));
        taxCollector.addAuthorization(address(usr));
        oracleRelayer.addAuthorization(address(usr));
        AuthorizableContract(deployedSurplusAuctionHouse).addAuthorization(address(usr));
        debtAuctionHouse.addAuthorization(address(usr));
        globalSettlement.addAuthorization(address(usr));
        coinJoin.addAuthorization(address(usr));
        coin.addAuthorization(address(usr));
        if (address(esm) != address(0)) {
          esm.addAuthorization(address(usr));
        }
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.addAuthorization(address(usr));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.addAuthorization(address(usr));
        }
    }

    function giveControl(address usr, address target) public auth {
        AuthorizableContract(target).addAuthorization(usr);
    }

    function takeControl(address usr) public auth {
        address deployedSurplusAuctionHouse =
          (address(recyclingSurplusAuctionHouse) != address(0)) ?
          address(recyclingSurplusAuctionHouse) : address(burningSurplusAuctionHouse);

        safeEngine.removeAuthorization(address(usr));
        liquidationEngine.removeAuthorization(address(usr));
        accountingEngine.removeAuthorization(address(usr));
        taxCollector.removeAuthorization(address(usr));
        oracleRelayer.removeAuthorization(address(usr));
        AuthorizableContract(deployedSurplusAuctionHouse).removeAuthorization(address(usr));
        debtAuctionHouse.removeAuthorization(address(usr));
        globalSettlement.removeAuthorization(address(usr));
        coinJoin.removeAuthorization(address(usr));
        if (address(esm) != address(0)) {
          esm.removeAuthorization(address(usr));
        }
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.removeAuthorization(address(usr));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.removeAuthorization(address(usr));
        }
    }

    function takeControl(address usr, address target) public auth {
        AuthorizableContract(target).removeAuthorization(usr);
    }
// replacement of  address(collateralTypes[collateralType].increasingDiscountCollateralAuctionHouse) != address(0) with fixedDiscount .
    function addAuthToCollateralAuctionHouse(bytes32 collateralType, address usr) public auth {
        require(
          address(collateralTypes[collateralType].englishCollateralAuctionHouse) != address(0) ||
           address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse) != address(0),
          "Collateral auction houses not initialized"
        );
        if (address(collateralTypes[collateralType].englishCollateralAuctionHouse) != address(0)) {
          collateralTypes[collateralType].englishCollateralAuctionHouse.addAuthorization(usr);
        } else if (address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse) != address(0)) {
          collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse.addAuthorization(usr);
        }
    }

    function releaseAuthCollateralAuctionHouse(bytes32 collateralType, address usr) public auth {
        if (address(collateralTypes[collateralType].englishCollateralAuctionHouse) != address(0)) {
          collateralTypes[collateralType].englishCollateralAuctionHouse.removeAuthorization(usr);
        } else if (address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse) != address(0)) {
          collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse.removeAuthorization(usr);
        }
    }

    function deployCollateral(
        bytes32 auctionHouseType,
        bytes32 collateralType,
        address adapter,
        address collateralFSM,
        address systemCoinOracle
    ) public auth {
        require(collateralType != bytes32(""), "Missing collateralType name");
        require(adapter != address(0), "Missing adapter address");
        require(collateralFSM != address(0), "Missing OSM address");

        // Deploy
        address auctionHouse;

        safeEngine.addAuthorization(adapter);

        if (auctionHouseType == "ENGLISH") {
          collateralTypes[collateralType].englishCollateralAuctionHouse =
            englishCollateralAuctionHouseFactory.newCollateralAuctionHouse(address(safeEngine), address(liquidationEngine), collateralType);
          liquidationEngine.modifyParameters(collateralType, "collateralAuctionHouse", address(collateralTypes[collateralType].englishCollateralAuctionHouse));
          // Approve the auction house in order to reduce the currentOnAuctionSystemCoins
          liquidationEngine.addAuthorization(address(collateralTypes[collateralType].englishCollateralAuctionHouse));
          // Internal auth
          collateralTypes[collateralType].englishCollateralAuctionHouse.addAuthorization(address(liquidationEngine));
          collateralTypes[collateralType].englishCollateralAuctionHouse.addAuthorization(address(globalSettlement));
          auctionHouse = address(collateralTypes[collateralType].englishCollateralAuctionHouse);
        } else {
          collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse =
          fixedDiscountCollateralAuctionHouseFactory.newCollateralAuctionHouse(address(safeEngine), address(liquidationEngine), collateralType);
          liquidationEngine.modifyParameters(collateralType, "collateralAuctionHouse", address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse));
          // Approve the auction house in order to reduce the currentOnAuctionSystemCoins
          liquidationEngine.addAuthorization(address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse));
          // Internal auth
          collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse.addAuthorization(address(liquidationEngine));
          collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse.addAuthorization(address(globalSettlement));
          auctionHouse = address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse);
        }

        collateralTypes[collateralType].adapter = adapter;
        OracleRelayer(oracleRelayer).modifyParameters(collateralType, "orcl", address(collateralFSM));

        // Internal references set up
        safeEngine.initializeCollateralType(collateralType);
        taxCollector.initializeCollateralType(collateralType);

        // Set bid restrictions
        if (auctionHouseType != "ENGLISH") {
          CollateralAuctionHouse(auctionHouse).modifyParameters("oracleRelayer", address(oracleRelayer));
          CollateralAuctionHouse(auctionHouse).modifyParameters("collateralFSM", address(collateralFSM));
          CollateralAuctionHouse(auctionHouse).modifyParameters("systemCoinOracle", address(systemCoinOracle));
        }
    }

    function releaseAuth() public auth {
        address deployedSurplusAuctionHouse =
          (address(recyclingSurplusAuctionHouse) != address(0)) ?
          address(recyclingSurplusAuctionHouse) : address(burningSurplusAuctionHouse);

        safeEngine.removeAuthorization(address(this));
        liquidationEngine.removeAuthorization(address(this));
        accountingEngine.removeAuthorization(address(this));
        taxCollector.removeAuthorization(address(this));
        coin.removeAuthorization(address(this));
        oracleRelayer.removeAuthorization(address(this));
        AuthorizableContract(deployedSurplusAuctionHouse).removeAuthorization(address(this));
        debtAuctionHouse.removeAuthorization(address(this));
        globalSettlement.removeAuthorization(address(this));
        coinJoin.removeAuthorization(address(this));
        if (address(esm) != address(0)) {
          esm.removeAuthorization(address(this));
        }
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.removeAuthorization(address(this));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.removeAuthorization(address(address(this)));
        }
    }

    function addCreatorAuth() public auth {
        safeEngine.addAuthorization(msg.sender);
        accountingEngine.addAuthorization(msg.sender);
    }
}