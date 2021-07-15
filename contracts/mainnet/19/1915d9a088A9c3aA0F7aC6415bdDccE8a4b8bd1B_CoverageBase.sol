/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File contracts/interfaces/IArmorClient.sol

pragma solidity 0.8.4;

interface IArmorClient {
    function submitProofOfLoss(uint256[] calldata _ids) external;
}


// File contracts/interfaces/IArmorMaster.sol

pragma solidity 0.8.4;

interface IArmorMaster {
    function registerModule(bytes32 _key, address _module) external;
    function getModule(bytes32 _key) external view returns(address);
    function keep() external;
}


// File contracts/interfaces/IBalanceManager.sol

pragma solidity 0.8.4;

interface IBalanceManager {
  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Loss(address indexed user, uint256 amount);
  event PriceChange(address indexed user, uint256 price);
  event AffiliatePaid(address indexed affiliate, address indexed referral, uint256 amount, uint256 timestamp);
  event ReferralAdded(address indexed affiliate, address indexed referral, uint256 timestamp);
  function expireBalance(address _user) external;
  function deposit(address _referrer) external payable;
  function withdraw(uint256 _amount) external;
  function initialize(address _armormaster, address _devWallet) external;
  function balanceOf(address _user) external view returns (uint256);
  function perSecondPrice(address _user) external view returns(uint256);
  function changePrice(address user, uint64 _newPricePerSec) external;
}


// File contracts/interfaces/IPlanManager.sol

pragma solidity 0.8.4;

interface IPlanManager {
  // Mapping = protocol => cover amount
  struct Plan {
      uint64 startTime;
      uint64 endTime;
      uint128 length;
  }
  
  struct ProtocolPlan {
      uint64 protocolId;
      uint192 amount;
  }
    
  // Event to notify frontend of plan update.
  event PlanUpdate(address indexed user, address[] protocols, uint256[] amounts, uint256 endTime);
  function userCoverageLimit(address _user, address _protocol) external view returns(uint256);
  function markup() external view returns(uint256);
  function nftCoverPrice(address _protocol) external view returns(uint256);
  function initialize(address _armorManager) external;
  function changePrice(address _scAddress, uint256 _pricePerAmount) external;
  function updatePlan(address[] calldata _protocols, uint256[] calldata _coverAmounts) external;
  function checkCoverage(address _user, address _protocol, uint256 _hacktime, uint256 _amount) external view returns (uint256, bool);
  function coverageLeft(address _protocol) external view returns(uint256);
  function getCurrentPlan(address _user) external view returns(uint256 idx, uint128 start, uint128 end);
  function updateExpireTime(address _user, uint256 _expiry) external;
  function planRedeemed(address _user, uint256 _planIndex, address _protocol) external;
  function totalUsedCover(address _scAddress) external view returns (uint256);
}


// File contracts/interfaces/IClaimManager.sol

pragma solidity 0.8.4;

interface IClaimManager {
    function initialize(address _armorMaster) external;
    function transferNft(address _to, uint256 _nftId) external;
    function exchangeWithdrawal(uint256 _amount) external;
    function redeemClaim(address _protocol, uint256 _hackTime, uint256 _amount) external;
}


// File contracts/interfaces/IStakeManager.sol

pragma solidity 0.8.4;

interface IStakeManager {
    function totalStakedAmount(address protocol) external view returns(uint256);
    function protocolAddress(uint64 id) external view returns(address);
    function protocolId(address protocol) external view returns(uint64);
    function initialize(address _armorMaster) external;
    function allowedCover(address _newProtocol, uint256 _newTotalCover) external view returns (bool);
    function subtractTotal(uint256 _nftId, address _protocol, uint256 _subtractAmount) external;
}


// File contracts/libraries/ArmorCore.sol

pragma solidity 0.8.4;

/**
 * @dev ArmorCore library simplifies integration of Armor Core into other contracts. It contains most functionality needed for a contract to use arCore.
**/
library ArmorCore {

    IArmorMaster internal constant armorMaster = IArmorMaster(0x1337DEF1900cEaabf5361C3df6aF653D814c6348);

    /**
     * @dev Get Armor module such as BalanceManager, PlanManager, etc.
     * @param _name Name of the module (such as "BALANCE").
    **/
    function getModule(bytes32 _name) internal view returns(address) {
        return armorMaster.getModule(_name);
    }

    /**
     * @dev Calculate the price per second for a specific amount of Ether.
     * @param _protocol Address of protocol to protect.
     * @param _coverAmount Amount of Ether to cover (in Wei). We div by 1e18 at the end because both _coverAmount and pricePerETH return are 1e18.
     * @return pricePerSec Ether (in Wei) price per second of this coverage.
    **/
    function calculatePricePerSec(address _protocol, uint256 _coverAmount) internal view returns (uint256 pricePerSec) {
        return pricePerETH(_protocol) * _coverAmount / 1e18;
    }

    /**
     * @dev Calculate price per second for an array of protocols and amounts.
     * @param _protocols Protocols to protect.
     * @param _coverAmounts Amounts (in Wei) of Ether to protect.
     * @return pricePerSec Ether (in Wei) price per second of this coverage,
    **/
    function calculatePricePerSec(address[] memory _protocols, uint256[] memory _coverAmounts) internal view returns (uint256 pricePerSec) {
        require(_protocols.length == _coverAmounts.length, "Armor: array length diff");
        for(uint256 i = 0; i<_protocols.length; i++){
            pricePerSec = pricePerSec + pricePerETH(_protocols[i]) * _coverAmounts[i];
        }
        return pricePerSec / 1e18;
    }

    /**
     * @dev Find amount of cover available for the specified protocol (up to amount desired).
     * @param _protocol Protocol to check cover for.
     * @param _amount Max amount of cover you would like.
     * @return available Amount of cover that is available (in Wei) up to full amount desired.
    **/
    function availableCover(address _protocol, uint256 _amount) internal view returns (uint256 available) {
        IPlanManager planManager = IPlanManager(getModule("PLAN"));
        uint256 limit = planManager.userCoverageLimit(address(this), _protocol);
        return limit >= _amount ? _amount : limit;
    }

    /**  
     * @dev Find the price per second per Ether for the protocol.
     * @param _protocol Protocol we are finding the price for.
     * @return pricePerSecPerETH The price per second per each full Eth for the protocol.
    **/
    function pricePerETH(address _protocol) internal view returns(uint256 pricePerSecPerETH) {
        IPlanManager planManager = IPlanManager(getModule("PLAN"));
        pricePerSecPerETH = planManager.nftCoverPrice(_protocol) * planManager.markup() / 100;
    }

    /**
     * @dev Subscribe to or update an Armor plan.
     * @param _protocols Protocols to be covered for.
     * @param _coverAmounts Ether amounts (in Wei) to purchase cover for. 
    **/
    function subscribe(address[] memory _protocols, uint256[] memory _coverAmounts) internal {
        IPlanManager planManager = IPlanManager(getModule("PLAN"));
        planManager.updatePlan(_protocols, _coverAmounts);
    }

    /**
     * @dev Subscribe to or update an Armor plan.
     * @param _protocol Protocols to be covered for.
     * @param _coverAmount Ether amounts (in Wei) to purchase cover for. 
    **/
    function subscribe(address _protocol, uint256 _coverAmount) internal {
        IPlanManager planManager = IPlanManager(getModule("PLAN"));
        address[] memory protocols = new address[](1);
        protocols[0] = _protocol;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _coverAmount;
        planManager.updatePlan(protocols, amounts);
    }

    /**
     * @dev Return this contract's balance on the Armor Core BalanceManager.
     * @return This contract's ablance on Armor Core.
    **/
    function balanceOf() internal view returns (uint256) {
        IBalanceManager balanceManager = IBalanceManager(getModule("BALANCE"));
        return balanceManager.balanceOf( address(this) );
    }

    /**
     * @dev Deposit funds into the BalanceManager contract.
     * @param amount Amount of Ether (in Wei) to deposit into the contract.
    **/
    function deposit(uint256 amount) internal {
        IBalanceManager balanceManager = IBalanceManager(getModule("BALANCE"));
        balanceManager.deposit{value:amount}(address(0));
    }

    /**
     * @dev Withdraw balance from the BalanceManager contract.
     * @param amount Amount (in Wei) if Ether to withdraw from the contract.
    **/
    function withdraw(uint256 amount) internal {
        IBalanceManager balanceManager = IBalanceManager(getModule("BALANCE"));
        balanceManager.withdraw(amount);
    }

    /**
     * @dev Claim funds after a hack has occurred on a protected protocol.
     * @param _protocol The protocol that was hacked.
     * @param _hackTime The Unix timestamp at which the hack occurred. Determined by Armor DAO.
     * @param _amount Amount of funds to claim (in Ether Wei).
    **/
    function claim(address _protocol, uint256 _hackTime, uint256 _amount) internal {
        IClaimManager claimManager = IClaimManager(getModule("CLAIM"));
        claimManager.redeemClaim(_protocol, _hackTime, _amount);
    }

    /**
     * @dev End Armor coverage. 
    **/
    function cancelPlan() internal {
        IPlanManager planManager = IPlanManager(getModule("PLAN"));
        address[] memory emptyProtocols = new address[](0);
        uint256[] memory emptyAmounts = new uint256[](0);
        planManager.updatePlan(emptyProtocols, emptyAmounts);
    }
}


// File contracts/client/ArmorClient.sol

pragma solidity 0.8.4;

/**
 * @dev ArmorClient is the main contract for non-Armor contracts to inherit when connecting to arCore. It contains all functionality needed for a contract to use arCore.
**/
contract ArmorClient {

    // Address that has permission to submit proof-of-loss. Armor will assign NFTs for this address to submit proof-of-loss for.
    address public armorController;

    constructor() {
        armorController = msg.sender;
    }

    /**
     * @dev ClaimManager calls into this contract to prompt 0 Ether transactions to addresses corresponding to NFTs that this contract must provide proof-of-loss for.
     *      This is required because of Nexus' proof-of-loss system in which an amount of proof-of-loss is required to claim cover that was paid for.
     *      EOAs would generally just sign a message to be sent in, but contracts send transactions to addresses corresponding to a cover ID (0xc1D000...000hex(coverId)).
     * @param _addresses Ethereum addresses to send 0 Ether transactions to.
    **/
    function submitProofOfLoss(address payable[] calldata _addresses) external {
        require(msg.sender == armorController || msg.sender == ArmorCore.getModule("CLAIM"),"Armor: only Armor controller or Claim Manager may call this function.");
        for(uint256 i = 0; i < _addresses.length; i++){
            _addresses[i].transfer(0);
        }
    }

    /**
     * @dev Transfer the address that is allowed to call sensitive Armor transactions (submitting proof-of-loss).
     * @param _newController Address to set as the new Armor controller. 
    **/
    function transferArmorController(address _newController) external {
        require(msg.sender == armorController, "Armor: only Armor controller may call this function.");
        armorController = _newController;
    }

}


// File contracts/interfaces/IarShield.sol

pragma solidity ^0.8.0;

interface IarShield {
    function initialize(
        address _oracle,
        address _pToken,
        address _arToken,
        address _uTokenLink,
        uint256[] calldata _fees,
        address[] calldata _covBases
    ) 
      external;
    function locked() external view returns(bool);
}


// File contracts/interfaces/IController.sol

pragma solidity 0.8.4;

interface IController {
    function bonus() external view returns (uint256);
    function refFee() external view returns (uint256);
    function governor() external view returns (address);
    function depositAmt() external view returns (uint256);
    function beneficiary() external view returns (address payable);
}


// File contracts/core/CoverageBase.sol

// SPDX-License-Identifier: (c) Armor.Fi, 2021

pragma solidity 0.8.4;

/**
 * @title Coverage Base
 * @notice Coverage base takes care of all Armor Core interactions for arShields.
 * @author Armor.fi -- Robert M.C. Forster
**/
contract CoverageBase is ArmorClient {
    
    // Denominator for coverage percent.
    uint256 public constant DENOMINATOR = 10000;

    // The protocol that this contract purchases coverage for.
    address public protocol;
    // Percent of funds from shields to cover.
    uint256 public coverPct;
    // Current cost per second for all Ether on contract.
    uint256 public totalCostPerSec;
    // Current cost per second per Ether.
    uint256 public costPerEth;
    // sum of cost per Ether for every second -- cumulative lol.
    uint256 public cumCost;
    // Last update of cumCost.
    uint256 public lastUpdate;
    // Total Ether value to be protecting in the contract.
    uint256 public totalEthValue;
    // Separate variable from above because there may be less than coverPct coverage available.
    uint256 public totalEthCoverage;
  
    // Value in Ether and last updates of each shield vault.
    mapping (address => ShieldStats) public shieldStats;

    // Controller holds governance contract.
    IController public controller;
    
    // Every time a shield updates it saves the full contracts cumulative cost, its Ether value, and 
    struct ShieldStats {
        uint128 lastCumCost;
        uint128 ethValue;
        uint128 lastUpdate;
        uint128 unpaid;
    }
    
    // Only let the governance address or the ShieldController edit these functions.
    modifier onlyGov 
    {
        require(msg.sender == controller.governor() || msg.sender == address(controller), "Sender is not governor.");
        _;
    }

    /**
     * @notice Just used to set the controller for the coverage base.
     * @param _controller ShieldController proxy address.
     * @param _protocol Address of the protocol to cover (from Nexus Mutual).
     * @param _coverPct Percent of the cover to purchase -- 10000 == 100%.
    **/
    function initialize(
        address _controller,
        address _protocol,
        uint256 _coverPct
    )
      external
    {
        require(protocol == address(0), "Contract already initialized.");
        controller = IController(_controller);
        protocol = _protocol;
        coverPct = _coverPct;
    }
    
    // Needed to receive a claim payout.
    receive() external payable {}

    /**
     * @notice Called by a keeper to update the amount covered by this contract on arCore.
    **/
    function updateCoverage()
      external
    {
        ArmorCore.deposit(address(this).balance);
        uint256 available = getAvailableCover();
        ArmorCore.subscribe(protocol, available);
        totalCostPerSec = getCoverageCost(available);
        totalEthCoverage = available;
        checkpoint();
    }
    
    /**
     * @notice arShield uses this to update the value of funds on their contract and deposit payments to here.
     *      We're okay with being loose-y goose-y here in terms of making sure shields pay (no cut-offs, timeframes, etc.).
     * @param _newEthValue The new Ether value of funds in the shield contract.
    **/
    function updateShield(
        uint256 _newEthValue
    )
      external
      payable
    {
        ShieldStats memory stats = shieldStats[msg.sender];
        require(stats.lastUpdate > 0, "Only arShields may access this function.");
        
        // Determine how much the shield owes for the last period.
        uint256 owed = getShieldOwed(msg.sender);
        uint256 unpaid = owed <= msg.value ? 
                         0 
                         : owed - msg.value;

        totalEthValue = totalEthValue 
                        - uint256(stats.ethValue)
                        + _newEthValue;

        checkpoint();

        shieldStats[msg.sender] = ShieldStats( 
                                    uint128(cumCost), 
                                    uint128(_newEthValue), 
                                    uint128(block.timestamp), 
                                    uint128(unpaid) 
                                  );
    }
    
    /**
     * @notice CoverageBase tells shield what % of current coverage it must pay.
     * @param _shield Address of the shield to get owed amount for.
     * @return owed Amount of Ether that the shield owes for past coverage.
    **/
    function getShieldOwed(
        address _shield
    )
      public
      view
    returns(
        uint256 owed
    )
    {
        ShieldStats memory stats = shieldStats[_shield];
        
        // difference between current cumulative and cumulative at last shield update
        uint256 pastDiff = cumCost - uint256(stats.lastCumCost);
        uint256 currentDiff = costPerEth * ( block.timestamp - uint256(lastUpdate) );
        
        owed = (uint256(stats.ethValue) 
                  * pastDiff
                  / 1 ether)
                + (uint256(stats.ethValue)
                  * currentDiff
                  / 1 ether)
                + uint256(stats.unpaid);
    }
    
    /**
     * @notice Record total values from last period and set new ones.
    **/
    function checkpoint()
      internal
    {
        cumCost += costPerEth * (block.timestamp - lastUpdate);
        costPerEth = totalCostPerSec
                     * 1 ether 
                     / totalEthValue;
        lastUpdate = block.timestamp;
    }
    
    /**
     * @notice Get the available amount of coverage for all shields' current values.
    **/
    function getAvailableCover()
      public
      view
    returns(
        uint256
    )
    {
        uint256 ideal = totalEthValue 
                        * coverPct 
                        / DENOMINATOR;
        return ArmorCore.availableCover(protocol, ideal);

    }
    
    /**
     * @notice Get the cost of coverage for all shields' current values.
     * @param _amount The amount of coverage to get the cost of.
    **/
    function getCoverageCost(uint256 _amount)
      public
      view
    returns(
        uint256
    )
    {
        return ArmorCore.calculatePricePerSec(protocol, _amount);
    }
    
    /**
     * @notice Check whether a new Ether value is available for purchase.
     * @param _newEthValue The new Ether value of the shield.
     * @return allowed True if we may purchase this much more coverage.
    **/
    function checkCoverage(
      uint256 _newEthValue
    )
      public
      view
    returns(
      bool allowed
    )
    {
      uint256 desired = (totalEthValue 
                         + _newEthValue
                         - uint256(shieldStats[msg.sender].ethValue) )
                        * coverPct
                        / DENOMINATOR;
      allowed = ArmorCore.availableCover( protocol, desired ) == desired;
    }

    /**
     * @notice Either add or delete a shield.
     * @param _shield Address of the shield to edit.
     * @param _active Whether we want it to be added or deleted.
    **/
    function editShield(
        address _shield,
        bool _active
    )
      external
      onlyGov
    {
        // If active, set timestamp of last update to now, else delete.
        if (_active) shieldStats[_shield] = ShieldStats( 
                                              uint128(cumCost), 
                                              0, 
                                              uint128(block.timestamp), 
                                              0 );
        else delete shieldStats[_shield]; 
    }
    
    /**
     * @notice Withdraw an amount of funds from arCore.
    **/
    function withdraw(address payable _beneficiary, uint256 _amount)
      external
      onlyGov
    {
        ArmorCore.withdraw(_amount);
        _beneficiary.transfer(_amount);
    }
    
    /**
     * @notice Cancel entire arCore plan.
    **/
    function cancelCoverage()
      external
      onlyGov
    {
        ArmorCore.cancelPlan();
    }
    
    /**
     * @notice Governance may call to a redeem a claim for Ether that this contract held.
     * @param _hackTime Time that the hack occurred.
     * @param _amount Amount of funds to be redeemed.
    **/
    function redeemClaim(
        uint256 _hackTime,
        uint256 _amount
    )
      external
      onlyGov
    {
        ArmorCore.claim(protocol, _hackTime, _amount);
    }
    
    /**
     * @notice Governance may disburse funds from a claim to the chosen shields.
     * @param _shield Address of the shield to disburse funds to.
     * @param _amount Amount of funds to disburse to the shield.
    **/
    function disburseClaim(
        address payable _shield,
        uint256 _amount
    )
      external
      onlyGov
    {
        require(shieldStats[_shield].lastUpdate > 0 && IarShield(_shield).locked(), "Shield is not authorized to use this contract or shield is not locked.");
        _shield.transfer(_amount);
    }
    
    /**
     * @notice Change the percent of coverage that should be bought. For example, 500 means that 50% of Ether value will be covered.
     * @param _newPct New percent of coverage to be bought--1000 == 100%.
    **/
    function changeCoverPct(
        uint256 _newPct
    )
      external
      onlyGov
    {
        require(_newPct <= 10000, "Coverage percent may not be greater than 100%.");
        coverPct = _newPct;    
    }
    
}