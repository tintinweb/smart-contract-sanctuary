/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// SPDX-License-Identifier: (c) Armor.Fi DAO, 2021

pragma solidity ^0.6.6;

interface IArmorMaster {
    function registerModule(bytes32 _key, address _module) external;
    function getModule(bytes32 _key) external view returns(address);
    function keep() external;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * 
 * @dev Completely default OpenZeppelin.
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_owner == address(0), "already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }


    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;

    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingOwner, "only pending owner can call this function");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private __gap;
}

library Bytes32 {
    function toString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

/**
 * @dev Each arCore contract is a module to enable simple communication and interoperability. ArmorMaster.sol is master.
**/
contract ArmorModule {
    IArmorMaster internal _master;

    using Bytes32 for bytes32;

    modifier onlyOwner() {
        require(msg.sender == Ownable(address(_master)).owner(), "only owner can call this function");
        _;
    }

    modifier doKeep() {
        _master.keep();
        _;
    }

    modifier onlyModule(bytes32 _module) {
        string memory message = string(abi.encodePacked("only module ", _module.toString()," can call this function"));
        require(msg.sender == getModule(_module), message);
        _;
    }

    /**
     * @dev Used when multiple can call.
    **/
    modifier onlyModules(bytes32 _moduleOne, bytes32 _moduleTwo) {
        string memory message = string(abi.encodePacked("only module ", _moduleOne.toString()," or ", _moduleTwo.toString()," can call this function"));
        require(msg.sender == getModule(_moduleOne) || msg.sender == getModule(_moduleTwo), message);
        _;
    }

    function initializeModule(address _armorMaster) internal {
        require(address(_master) == address(0), "already initialized");
        require(_armorMaster != address(0), "master cannot be zero address");
        _master = IArmorMaster(_armorMaster);
    }

    function changeMaster(address _newMaster) external onlyOwner {
        _master = IArmorMaster(_newMaster);
    }

    function getModule(bytes32 _key) internal view returns(address) {
        return _master.getModule(_key);
    }
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 * 
 * @dev Default OpenZeppelin
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
  function calculateRoot(bytes32[] memory leaves) internal pure returns(bytes32) {
    require(leaves.length > 0, "Cannot compute zero length");
    bytes32[] memory elements = leaves;
    bytes32[] memory nextLayer = new bytes32[]((elements.length+1)/2) ;
    while(elements.length > 1) {
      for(uint256 i = 0; i<elements.length;i+=2){
        bytes32 left;
        bytes32 right;
        if(i == elements.length - 1){
          left = elements[i];
          right = elements[i];
        }
        else if(elements[i] <= elements[i+1]){
          left = elements[i];
          right = elements[i+1];
        }
        else {
          left = elements[i+1];
          right = elements[i];
        }
        bytes32 elem = keccak256(abi.encodePacked(left,right));
        nextLayer[i/2] = elem;
      }
      elements = nextLayer;
      nextLayer = new bytes32[]((elements.length+1)/2);
    }
    return elements[0];

  }
  /**
   * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
   * defined by `root`. For this, a `proof` must be provided, containing
   * sibling hashes on the branch from the leaf to the root of the tree. Each
   * pair of leaves and each pair of pre-images are assumed to be sorted.
   */
  function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }
}

interface IStakeManager {
    function totalStakedAmount(address protocol) external view returns(uint256);
    function protocolAddress(uint64 id) external view returns(address);
    function protocolId(address protocol) external view returns(uint64);
    function initialize(address _armorMaster) external;
    function allowedCover(address _newProtocol, uint256 _newTotalCover) external view returns (bool);
    function subtractTotal(uint256 _nftId, address _protocol, uint256 _subtractAmount) external;
}

interface IBalanceManager {
  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Loss(address indexed user, uint256 amount);
  event PriceChange(address indexed user, uint256 price);
  event AffiliatePaid(address indexed affiliate, address indexed referral, uint256 amount, uint256 timestamp);
  event ReferralAdded(address indexed affiliate, address indexed referral, uint256 timestamp);
  function deposit(address _referrer) external payable;
  function withdraw(uint256 _amount) external;
  function initialize(address _armormaster, address _devWallet) external;
  function balanceOf(address _user) external view returns (uint256);
  function perSecondPrice(address _user) external view returns(uint256);
  function changePrice(address user, uint64 _newPricePerSec) external;
}

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

interface IClaimManager {
    function initialize(address _armorMaster) external;
    function transferNft(address _to, uint256 _nftId) external;
    function exchangeWithdrawal(uint256 _amount) external;
}

contract PlanManager is ArmorModule, IPlanManager {
    
    using SafeMath for uint;
    
    uint256 constant private DENOMINATOR = 1000;
    
    // List of plans that a user has purchased so there is a historical record.
    mapping (address => Plan[]) public plans;

    // keccak256("ARMORFI.PLAN", address(user), uint256(planIdx), uint256(protocolIdx)) => ProtocolPlan
    mapping (bytes32 => ProtocolPlan) public protocolPlan;
    
    // StakeManager calls this when a new NFT is added to update what the price for that protocol is.
    // Cover price in ETH (1e18) of price per second per ETH covered.
    mapping (address => uint256) public override nftCoverPrice;
    
    // Mapping to doKeep track of how much coverage we've sold for each protocol.
    // smart contract address => total borrowed cover
    mapping (address => uint256) public override totalUsedCover;
    
    // Protocol => amount of coverage bought by shields (then shields plus) for that protocol.
    // Keep track of these to only allow a % of staked NFTs to be bought by each.
    mapping (address => uint256) public arShieldCover;
    mapping (address => uint256) public arShieldPlusCover;
    mapping (address => uint256) public coreCover;
    
    // Percent allocated to each part of the system. 350 == 35%.
    uint256 public arShieldPercent;
    uint256 public arShieldPlusPercent;
    uint256 public corePercent;
    
    // Mapping of the address of shields => 1 if they're arShield and 2 if they're arShieldPlus.
    mapping (address => uint256) public arShields;
    
    // The amount of markup for Armor's service vs. the original cover cost. 200 == 200%.
    uint256 public override markup;
    
    function initialize(
        address _armorMaster
    ) external override {
        initializeModule(_armorMaster);
        markup = 150;
        arShieldPercent = 350;
        arShieldPlusPercent = 350;
        corePercent = 300;
    }
    
    function getCurrentPlan(address _user) external view override returns(uint256 idx, uint128 start, uint128 end){
        if(plans[_user].length == 0){
            return(0,0,0);
        }
        Plan memory plan = plans[_user][plans[_user].length-1];
        
        //return 0 if there is no active plan
        if(plan.endTime < now){
            return(0,0,0);
        } else {
            idx = plans[_user].length - 1;
            start = plan.startTime;
            end = plan.endTime;
        }
    }

    function getProtocolPlan(address _user, uint256 _idx, address _protocol) external view returns(uint256 idx, uint64 protocolId, uint192 amount) {
        IStakeManager stakeManager = IStakeManager(getModule("STAKE"));
        uint256 length = plans[_user][_idx].length;
        for(uint256 i = 0; i<length; i++){
            ProtocolPlan memory protocol = protocolPlan[_hashKey(_user, _idx, i)];
            address addr = stakeManager.protocolAddress(protocol.protocolId);
            if(addr == _protocol){
                return (i, protocol.protocolId, protocol.amount);
            }
        }
        return(0,0,0);
    }

    function userCoverageLimit(address _user, address _protocol) external view override returns(uint256){
        IStakeManager stakeManager = IStakeManager(getModule("STAKE"));
        uint64 protocolId = stakeManager.protocolId(_protocol);
       
        uint256 idx = plans[_user].length - 1;
        uint256 currentCover = 0;
        if(idx != uint256(-1)){ 
            Plan memory plan = plans[_user][idx];
            uint256 length = uint256( plan.length );

            for (uint256 i = 0; i < length; i++) {
                ProtocolPlan memory protocol = protocolPlan[ _hashKey(_user, idx, i) ];
                if (protocol.protocolId == protocolId) currentCover = uint256( protocol.amount );
            }
        }

        uint256 extraCover = coverageLeft(_protocol);

        // Add current coverage because coverageLeft on planManager does not include what we're currently using.
        return extraCover.add(currentCover);
    }

    /*
     * @dev User can update their plan for cover amount on any protocol.
     * @param _protocols Addresses of the protocols that we want coverage for.
     * @param _coverAmounts The amount of coverage desired in WEI.
     * @notice Let's simplify this somehow--even just splitting into different functions.
    **/
    function updatePlan(address[] calldata _protocols, uint256[] calldata _coverAmounts)
      external
      // doKeep
      override
    {
        require(_protocols.length == _coverAmounts.length, "protocol and coverAmount length mismatch");
        require(_protocols.length <= 30, "You may not protect more than 30 protocols at once.");
        
        // Need to get price of the protocol here
        if(plans[msg.sender].length > 0){
          Plan storage lastPlan = plans[msg.sender][plans[msg.sender].length - 1];

          // First go through and subtract all old cover amounts.
          _removeLatestTotals(msg.sender);
          
          // Set current plan to have ended now or when it ended previously.
          lastPlan.endTime = lastPlan.endTime <= now ? lastPlan.endTime : uint64(now);
        }

        _addNewTotals(_protocols, _coverAmounts);
        uint256 newPricePerSec;
        uint256 _markup = markup;
        
        
        // Loop through protocols, find price per second, add to rate, add coverage amount to mapping.
        for (uint256 i = 0; i < _protocols.length; i++) {
            require(nftCoverPrice[_protocols[i]] != 0, "Protocol price is zero");
            
            // nftCoverPrice is Wei per second per full Ether, so a cover amont in Wei. This is divided after this loop.
            uint256 pricePerSec = nftCoverPrice[ _protocols[i] ].mul(_coverAmounts[i]);
            newPricePerSec = newPricePerSec.add(pricePerSec);
        }
        
        //newPricePerSec = newPricePerSec * _markup / 1e18 for decimals / 100 to make up for markup (200 == 200%);
        newPricePerSec = newPricePerSec.mul(_markup).div(1e18).div(100);
        
        // this means user is canceling all plans
        if(newPricePerSec == 0){
            Plan memory newPlan;
            newPlan = Plan(uint64(now), uint64(-1), uint128(0));
            plans[msg.sender].push(newPlan);
            IBalanceManager(getModule("BALANCE")).changePrice(msg.sender, 0);
            emit PlanUpdate(msg.sender, _protocols, _coverAmounts, uint64(-1));
            return;
        }

        uint256 balance = IBalanceManager(getModule("BALANCE")).balanceOf(msg.sender);
        uint256 endTime = balance.div(newPricePerSec).add(block.timestamp);
        
        // Let's make sure a user can pay for this for at least a week. Weird manipulation of utilization farming could happen otherwise.
        require(endTime >= block.timestamp.add(7 days), "Balance must be enough for 7 days of coverage.");
        
        //add plan
        Plan memory newPlan;
        newPlan = Plan(uint64(now), uint64(endTime), uint128(_protocols.length));
        plans[msg.sender].push(newPlan);
        
        //add protocol plan
        for(uint256 i = 0;i<_protocols.length; i++){
            bytes32 key = _hashKey(msg.sender, plans[msg.sender].length - 1, i);
            uint64 protocolId = IStakeManager(getModule("STAKE")).protocolId(_protocols[i]);
            protocolPlan[key] = ProtocolPlan(protocolId, uint192(_coverAmounts[i]));
        }
        
        // update balance price per second here
        uint64 castPricePerSec = uint64(newPricePerSec);
        require(uint256(castPricePerSec) == newPricePerSec);
        IBalanceManager(getModule("BALANCE")).changePrice(msg.sender, castPricePerSec);

        emit PlanUpdate(msg.sender, _protocols, _coverAmounts, endTime);
    }

    /**
     * @dev Update the contract-wide totals for each protocol that has changed.
     * @param _user User whose plan is updating these totals.
    **/
    function _removeLatestTotals(address _user) internal {
        Plan storage plan = plans[_user][plans[_user].length - 1];

        uint256 idx = plans[_user].length - 1;

        for (uint256 i = 0; i < plan.length; i++) {
            bytes32 key = _hashKey(_user, idx, i);
            ProtocolPlan memory protocol = protocolPlan[key];
            address protocolAddress = IStakeManager(getModule("STAKE")).protocolAddress(protocol.protocolId);
            totalUsedCover[protocolAddress] = totalUsedCover[protocolAddress].sub(uint256(protocol.amount));
            
            uint256 shield = arShields[_user];
            if (shield == 1) {
                arShieldCover[protocolAddress] = arShieldCover[protocolAddress].sub(protocol.amount);
            } else if (shield == 2) {
                arShieldPlusCover[protocolAddress] = arShieldPlusCover[protocolAddress].sub(protocol.amount);
            } else {
                coreCover[protocolAddress] = coreCover[protocolAddress].sub(protocol.amount);
            }   
        }
    }

    /**
     * @dev Add new totals for new protocol/cover amounts.
     * @param _newProtocols Protocols that are being borrowed for.
     * @param _newCoverAmounts Cover amounts (in Wei) that are being borrowed.
    **/
    function _addNewTotals(address[] memory _newProtocols, uint256[] memory _newCoverAmounts) internal {
        for (uint256 i = 0; i < _newProtocols.length; i++) {
            
            (uint256 shield, uint256 allowed) = _checkBuyerAllowed(_newProtocols[i]);
            require(allowed >= _newCoverAmounts[i], "Exceeds allowed cover amount.");
            
            totalUsedCover[_newProtocols[i]] = totalUsedCover[_newProtocols[i]].add(_newCoverAmounts[i]);
            
            if (shield == 1) {
                arShieldCover[_newProtocols[i]] = arShieldCover[_newProtocols[i]].add(_newCoverAmounts[i]);
            } else if (shield == 2) {
                arShieldPlusCover[_newProtocols[i]] = arShieldPlusCover[_newProtocols[i]].add(_newCoverAmounts[i]);
            } else {
                coreCover[_newProtocols[i]] = coreCover[_newProtocols[i]].add(_newCoverAmounts[i]);
            }
        }
    }

    /**
     * @dev Determine the amount of coverage left for a specific protocol.
     * @param _protocol The address of the protocol we're determining coverage left for.
    **/
    function coverageLeft(address _protocol)
      public
      override
      view
    returns (uint256) {
        (/* uint256 shield */, uint256 allowed) = _checkBuyerAllowed(_protocol);
        return allowed;
    }
    
    /**
     * @dev Check whether the buyer is allowed to purchase this amount of cover.
     *      Used because core can only buy 30%, and 35% for shields.
     * @param _protocol The protocol cover is being purchased for.
    **/
    function _checkBuyerAllowed(address _protocol)
      internal
      view
    returns (uint256, uint256)
    {
        uint256 totalAllowed = IStakeManager(getModule("STAKE")).totalStakedAmount(_protocol);
        uint256 shield = arShields[msg.sender];
            
        if (shield == 1) {
            uint256 currentCover = arShieldCover[_protocol];
            uint256 allowed = totalAllowed * arShieldPercent / DENOMINATOR;
            return (shield, allowed > currentCover ? allowed - currentCover : 0);
        } else if (shield == 2) {
            uint256 currentCover = arShieldPlusCover[_protocol];
            uint256 allowed = totalAllowed * arShieldPlusPercent / DENOMINATOR;
            return (shield, allowed > currentCover ? allowed - currentCover : 0);
        } else {
            uint256 currentCover = coreCover[_protocol];
            uint256 allowed = totalAllowed * corePercent / DENOMINATOR;
            return (shield, allowed > currentCover ? allowed - currentCover : 0);        
        }
    }
    
    /**
     * @dev Used by ClaimManager to check how much coverage the user had at the time of a hack.
     * @param _user The user to check coverage for.
     * @param _protocol The address of the protocol that was hacked. (Address used according to arNFT).
     * @param _hackTime The timestamp of when a hack happened.
     * @return index index of plan for hackTime
     * @return check whether amount is allowed
    **/
    function checkCoverage(address _user, address _protocol, uint256 _hackTime, uint256 _amount)
      external
      view
      override
      returns(uint256 index, bool check)
    {
        // This may be more gas efficient if we don't grab this first but instead grab each plan from storage individually?
        Plan[] storage planArray = plans[_user];
        
        // In normal operation, this for loop should never get too big.
        // If it does (from malicious action), the user will be the only one to suffer.
        for (int256 i = int256(planArray.length - 1); i >= 0; i--) {
            Plan storage plan = planArray[uint256(i)];
            // Only one plan will be active at the time of a hack--return cover amount from then.
            if (_hackTime >= plan.startTime && _hackTime < plan.endTime) {
                for(uint256 j = 0; j< plan.length; j++){
                    bytes32 key = _hashKey(_user, uint256(i), j);
                    if(IStakeManager(getModule("STAKE")).protocolAddress(protocolPlan[key].protocolId) == _protocol){
                        return (uint256(i), _amount <= uint256(protocolPlan[key].amount));
                    }
                }
                return (uint256(i), false);
            }
        }
        return (uint256(-1), false);
    }

    /**
     * @dev ClaimManager redeems the plan if it has been claimed. Sets claim amount to 0 so it cannot be claimed again.
     * @param _user User that is redeeming this plan.
     * @param _planIndex The index in the user's Plan array that we're checking.
     * @param _protocol Address of the protocol that a claim is being redeemed for.
    **/
    function planRedeemed(address _user, uint256 _planIndex, address _protocol) 
      external 
      override 
      onlyModule("CLAIM")
    {
        Plan storage plan = plans[_user][_planIndex];
        require(plan.endTime <= now, "Cannot redeem active plan, update plan to redeem properly.");

        for (uint256 i = 0; i < plan.length; i++) {
            bytes32 key = _hashKey(_user,_planIndex,i);
            
            ProtocolPlan memory protocol = protocolPlan[key];
            address protocolAddress = IStakeManager(getModule("STAKE")).protocolAddress(protocol.protocolId);
            
            if (protocolAddress == _protocol) protocolPlan[key].amount = 0;
        }
    }

    /**
     * @dev Armor has the ability to change the price that a user is paying for their insurance.
     * @param _protocol The protocol whose arNFT price is being updated.
     * @param _newPrice the new price PER SECOND that the user will be paying.
    **/
    function changePrice(address _protocol, uint256 _newPrice)
      external
      override
      onlyModule("STAKE")
    {
        nftCoverPrice[_protocol] = _newPrice;
    }

    /**
     * @dev BalanceManager calls to update expire time of a plan when a deposit/withdrawal happens.
     * @param _user Address whose balance was updated.
     * @param _expiry New time plans expire.
    **/
    function updateExpireTime(address _user, uint256 _expiry)
      external
      override
      onlyModule("BALANCE")
    {
        if (plans[_user].length == 0) return;
        Plan storage plan = plans[_user][plans[_user].length-1];
        if (plan.endTime > block.timestamp && _expiry <= block.timestamp) _removeLatestTotals(_user);
        plan.endTime = uint64(_expiry);
    }
    
    /**
     * @dev Hash for protocol info identifier.
     * @param _user Address of the user.
     * @param _planIndex Index of the plan in the user's plan array.
     * @param _protoIndex Index of the protocol in the plan.
     * @return Hash for identifier for protocolPlan mapping.
    **/
    function _hashKey(address _user, uint256 _planIndex, uint256 _protoIndex)
      internal
      pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked("ARMORFI.PLAN.", _user, _planIndex, _protoIndex));
    }
    
    /**
     * @dev Owner (DAO) can adjust the markup buyers pay for coverage.
     * @param _newMarkup The new markup that will be used. 100 == 100% (no markup).
    **/
    function adjustMarkup(uint256 _newMarkup)
      external
      onlyOwner
    {
        require(_newMarkup >= 100, "Markup must be at least 0 (100%).");
        markup = _newMarkup;
    }
    
    /**
     * @dev Owner (DAO) can adjust the percent of coverage allowed for each product.
     * @param _newCorePercent New percent of coverage for general arCore users.
     * @param _newArShieldPercent New percent of coverage for arShields.
     * @param _newArShieldPlusPercent New percent of coverage for arShield Plus.
    **/
    function adjustPercents(uint256 _newCorePercent, uint256 _newArShieldPercent, uint256 _newArShieldPlusPercent)
      external
      onlyOwner
    {
        require(_newCorePercent + _newArShieldPercent + _newArShieldPlusPercent == 1000, "Total allocation cannot be more than 100%.");
        corePercent = _newCorePercent;
        arShieldPercent = _newArShieldPercent;
        arShieldPlusPercent = _newArShieldPlusPercent;
    }
    
    /**
     * @dev Owner (DAO) can adjust shields on the contract.
     * @param _shieldAddress Array of addresses we're adjusting.
     * @param _shieldType Type of shield: 1 for arShield, 2 for arShield Plus.
    **/
    function adjustShields(address[] calldata _shieldAddress, uint256[] calldata _shieldType)
      external
      onlyOwner
    {
        require(_shieldAddress.length == _shieldType.length, "Submitted arrays are not of equal length.");
        for (uint256 i = 0; i < _shieldAddress.length; i++) {
            arShields[_shieldAddress[i]] = _shieldType[i];
        }
    }
    
}