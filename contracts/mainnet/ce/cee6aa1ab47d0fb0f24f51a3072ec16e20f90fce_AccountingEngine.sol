/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

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

pragma solidity 0.6.7;

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

abstract contract SAFEEngineLike {
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
    SAFEEngineLike             public safeEngine;
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
        safeEngine = SAFEEngineLike(safeEngine_);
        surplusAuctionHouse = SurplusAuctionHouseLike(surplusAuctionHouse_);
        debtAuctionHouse = DebtAuctionHouseLike(debtAuctionHouse_);
        safeEngine.approveSAFEModification(surplusAuctionHouse_);
        lastSurplusAuctionTime  = now;
        lastSurplusTransferTime = now;
        contractEnabled = 1;
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
     * @notice Modify general uint256 params for auctions
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
     * @notice Modify dependency addresses
     * @param parameter The name of the auction type we want to change the address for
     * @param data New address for the auction
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
    function unqueuedUnauctionedDebt() public view returns (uint256) {
        return subtract(subtract(safeEngine.debtBalance(address(this)), totalQueuedDebt), totalOnAuctionDebt);
    }
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
     * @notice Push debt (that the system tries to cover with collateral auctions) to a queue
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
     * @notice A block of debt can be popped from the queue after popDebtDelay seconds passed since it was
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
     * @notice Destroy an equal amount of coins and debt
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
     * @notice Use surplus coins to destroy debt that is/was in a debt auction
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
     *         system can accumulate surplus)
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
     *      auction trigger, if we keep enough surplus in the buffer and if there is no bad debt left to settle
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
     * @notice Send surplus to an address as an alternative to auctions
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
     * @dev When it's disabled, the contract will record the current timestamp. Afterwards,
     *      the contract tries to settle as much debt as possible (if there's any) with any surplus that's
     *      left in the system
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