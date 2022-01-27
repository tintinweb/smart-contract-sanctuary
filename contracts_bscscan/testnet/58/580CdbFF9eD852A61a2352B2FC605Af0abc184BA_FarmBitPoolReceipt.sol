// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./HitchensUnorderedKeySet.sol";
import "./FMBPriceTracker.sol";
import "./FarmBitPool.sol";
import "./Shared.sol";

/// @custom:security-contact [email protected]
contract FarmBitPoolReceipt is ERC721, ERC721Enumerable, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Shared for uint256;
    using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;

    // Roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    // Events
    event ReceiptCreated(uint256 indexed tokenId, Shared.ReceiptInfo receipt);
    event ReceiptDeleted(uint256 indexed tokenId, Shared.ReceiptInfo receipt);

    // Fields
    mapping(uint256 => Shared.ReceiptInfo) receipts;
    HitchensUnorderedKeySetLib.Set receiptSet;

    Counters.Counter private _tokenIdCounter;

    IERC20 public subscriptionToken;
    FMBPriceTracker public fmbPriceTracker;

    constructor(address _subscriptionToken, address _fmbPriceTracker) ERC721("FarmBit Pool Receipt", "FPR") {
        subscriptionToken = IERC20(_subscriptionToken);
        fmbPriceTracker = FMBPriceTracker(_fmbPriceTracker);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    function setFmbPriceTracker(address _fmbPriceTracker) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fmbPriceTracker = FMBPriceTracker(_fmbPriceTracker);
    }

    function setSubscriptionToken(address _subscriptionToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        subscriptionToken = IERC20(_subscriptionToken);
    }

    // Creates a new receipt
    function createReceipt(address _owner, uint256 _subscriptionAmount, uint256 _poolId, uint256 _poolApy, 
        address _poolAddress) external 
        isNotZero(_subscriptionAmount, "FarmBitPoolReceipt: _subscriptionAmount must be > 0")
        returns (Shared.ReceiptInfo memory receipt) {
        
        // Try to transfer the subscription amount first
        require(subscriptionToken.transferFrom(_owner, _poolAddress, _subscriptionAmount), 
            "FarmBitPoolReceipt: Failed to trasnfer subscription tokens");

        // Create the receipt
        _safeMint(_owner);

        uint256 _tokenId = _tokenIdCounter.current(); // The just used id 
        receipt = Shared.ReceiptInfo(_tokenId, _poolId, _subscriptionAmount, _poolApy, _poolAddress);
        receiptSet.insert(bytes32(_tokenId));
        receipts[_tokenId] = receipt;

        emit ReceiptCreated(_tokenId, receipt);
    }

    // Destroys an existing receipt
    // NOTE: burning receipts manually will not give you rewards!
    // It is always advisable to let the pool burn receipts on your behalf
    function burnReceipt(uint256 _tokenId) external {
        _burn(_tokenId);

        Shared.ReceiptInfo memory receipt = receipts[_tokenId];
        receiptSet.remove(bytes32(_tokenId));
        delete receipts[_tokenId];

        emit ReceiptDeleted(_tokenId, receipt);
    }

    // Returns the informations of a receipt
    function getReceipt(uint256 _tokenId) external view 
        returns (uint256 _subscriptionAmount, uint256 _poolApy, address _poolAddress,
        address _receiptOwner) {
        require(receiptSet.exists(bytes32(_tokenId)), "FarmBitPoolReceipt: receipt does not exist!");

        Shared.ReceiptInfo memory receipt = receipts[_tokenId];
        _subscriptionAmount = receipt.subscriptionAmount;
        _poolApy = receipt.poolApy;
        _poolAddress = receipt.poolAddress;
        _receiptOwner = ownerOf(_tokenId);
    }

    function getReceiptByIndex(uint256 index) external view 
        returns (uint256 _subscriptionAmount, uint256 _poolApy, address _poolAddress,
        address _receiptOwner) {
        bytes32 key = receiptSet.keyAtIndex(index);
        require(receiptSet.exists(key), "FarmBitPoolReceipt: receipt does not exist!");

        uint256 _tokenId = uint256(key);
        Shared.ReceiptInfo memory receipt = receipts[_tokenId];
        _subscriptionAmount = receipt.subscriptionAmount;
        _poolApy = receipt.poolApy;
        _poolAddress = receipt.poolAddress;
        _receiptOwner = ownerOf(_tokenId);
    }

    function getTotalReceipts() external view returns (uint256) {
        return receiptSet.count();
    }

    function getReceiptsOf(address _owner) external view returns (Shared.ReceiptInfo[] memory) {
        uint256 total = receiptSet.count();
        uint256 i;
        uint256 j;
        Shared.ReceiptInfo memory receipt;
        Shared.ReceiptInfo[] memory temp = new Shared.ReceiptInfo[](total);

        for (i = 0; i < total; i++) {
            receipt = receipts[uint256(receiptSet.keyAtIndex(i))];
            if (ownerOf(receipt.id) == _owner) {
                temp[j] = receipt;
                j++;
            }
        }

        Shared.ReceiptInfo[] memory result = new Shared.ReceiptInfo[](j);
        for (i = 0; i < j; i++) {
            result[i] = temp[i];
        }

        return result;
    }

    // Returns the yield of a receipt when the referenced pool reaches maturity
    // NOTE: this value is dependent on both the pool's APY and the current BUSD value of FMB!
    function getCurrentMaturityYieldInBusd(uint256 _tokenId) external view 
        returns (uint256 yield, uint256 fmbInBusd, uint256 apy) {
        require(receipts[_tokenId].poolAddress != address(0), "FarmBitPoolReceipt: receipt doesn't exist!");

        Shared.ReceiptInfo memory receipt = receipts[_tokenId];
        yield = fmbPriceTracker.fmbToBusd(receipt.subscriptionAmount).percentage(receipt.poolApy);
        fmbInBusd = fmbPriceTracker.oneFmbInBusd();
        apy = receipt.poolApy;
    }

    // Returns the yield in BUSD, given the amount of FMB and the APY
    function calculateMaturityYieldInBusd(uint256 _fmb, uint256 _apy) external view 
        returns (uint256 yield, uint256 fmbInBusd) {
        yield = fmbPriceTracker.fmbToBusd(_fmb).percentage(_apy);
        fmbInBusd = fmbPriceTracker.oneFmbInBusd();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _safeMint(address to) private {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Modifiers

    modifier isNotZero(uint256 value, string memory message) {
        require(value > 0, message);
        _;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Shared {
  using SafeMath for uint256;

  struct ReceiptInfo {
    uint256 id; // A unique id for the receipt token
    uint256 poolId; // A unique id for the pool
    uint256 subscriptionAmount; // Total amount used for subscription in FMB
    uint256 poolApy; // The APY of the pool in percentage
    address poolAddress; // The address of the pool
  }

  struct PoolInfo {
    uint256 id; // A unique id for the pool
    address poolAddress; // The pool address
    address poolOwner; // The address of the pool owner
    uint256 createdOn; // The creation date of the pool
  }

  function daysToTimestamp(uint256 _days) internal pure returns (uint256) {
    return _days.mul(86400);
  }

  function percentage(uint256 _value, uint256 _percentage) internal pure returns (uint256) {
    return _value.mul(_percentage).div(100);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Hitchens UnorderedKeySet v0.93
Library for managing CRUD operations in dynamic key sets.
https://github.com/rob-Hitchens/UnorderedKeySet
Copyright (c), 2019, Rob Hitchens, the MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

library HitchensUnorderedKeySetLib {
  struct Set {
    mapping(bytes32 => uint) keyPointers;
    bytes32[] keyList;
  }

  function insert(Set storage self, bytes32 key) internal {
    require(key != 0x0, "UnorderedKeySet(100) - Key cannot be 0x0");
    require(!exists(self, key), "UnorderedKeySet(101) - Key already exists in the set.");
    self.keyList.push(key);
    self.keyPointers[key] = self.keyList.length - 1;
  }

  function remove(Set storage self, bytes32 key) internal {
    require(exists(self, key), "UnorderedKeySet(102) - Key does not exist in the set.");
    bytes32 keyToMove = self.keyList[count(self)-1];
    uint rowToReplace = self.keyPointers[key];
    self.keyPointers[keyToMove] = rowToReplace;
    self.keyList[rowToReplace] = keyToMove;
    delete self.keyPointers[key];
    self.keyList.pop();
  }

  function count(Set storage self) internal view returns(uint) {
    return(self.keyList.length);
  }

  function exists(Set storage self, bytes32 key) internal view returns(bool) {
    if(self.keyList.length == 0) return false;
    return self.keyList[self.keyPointers[key]] == key;
  }

  function keyAtIndex(Set storage self, uint index) internal view returns(bytes32) {
    return self.keyList[index];
  }

  function nukeSet(Set storage self) public {
    delete self.keyList;
  }
}

contract HitchensUnorderedKeySet {

  using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
  HitchensUnorderedKeySetLib.Set set;

  event LogUpdate(address sender, string action, bytes32 key);

  function exists(bytes32 key) public view returns(bool) {
    return set.exists(key);
  }

  function insert(bytes32 key) public {
    set.insert(key);
    emit LogUpdate(msg.sender, "insert", key);
  }

  function remove(bytes32 key) public {
    set.remove(key);
    emit LogUpdate(msg.sender, "remove", key);
  }

  function count() public view returns(uint) {
    return set.count();
  }

  function keyAtIndex(uint index) public view returns(bytes32) {
    return set.keyAtIndex(index);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./HitchensUnorderedKeySet.sol";
import "./FarmBitPool.sol";
import "./FarmBitPoolReceipt.sol";
import "./Shared.sol";

contract FarmBitPoolManager is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Shared for uint256;
    using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;

    // Events
    event PoolAdded(uint256 indexed poolId, address poolAddress, address indexed poolOwner);
    event PoolRemoved(uint256 indexed poolId, address poolAddress, address indexed poolOwner);
    event PoolPaused(uint256 indexed poolId, address poolAddress, address indexed poolOwner);
    event PoolResumed(uint256 indexed poolId, address poolAddress, address indexed poolOwner);

    mapping(uint256 => Shared.PoolInfo) pools; // Availaible pools
    HitchensUnorderedKeySetLib.Set poolSet;

    uint256 public maxSubscriptionDays = 15; // The maximum number of days a pool can be opened before it gets closed
    uint256 public emergencyWithdrawalCharge = 30; // How much percentage is charged when withdrawing before asset maturity
    uint256 public unsubscriptionFee = 2; // The standard ubscription fee in percentage

    Counters.Counter private _idCounter;

    FarmBitPoolReceipt public receiptToken;

    constructor(address _receiptToken) {
      require(_receiptToken != address(0), "FarmBitPoolManager: invalid receipt token address");
      receiptToken = FarmBitPoolReceipt(_receiptToken);
    }

    function setMaxSubscriptionDays(uint256 _maxSubscriptionDays) external onlyOwner 
      isNotZero(_maxSubscriptionDays, "FarmBitPoolManager: Invalid days") {
      maxSubscriptionDays = _maxSubscriptionDays;
    }
    
    function setEmergencyWithdrawalCharge(uint256 _emergencyWithdrawalCharge) external onlyOwner {
      emergencyWithdrawalCharge = _emergencyWithdrawalCharge;
    }

    function setReceiptToken(address _receiptToken) external onlyOwner  {
      require(_receiptToken != address(0), "FarmBitPoolManager: invalid receipt token address");
      receiptToken = FarmBitPoolReceipt(_receiptToken);
    }

    // Creates a new pool and returns the pool address
    function addPool(address _poolAddress, address _poolOwner, uint256 _poolApy, uint256 _assetMaturityDateInDays,
      uint256 _maxSubscriptionAmount, uint256 _subscriptionStartDate) external onlyOwner returns (uint256 poolId) {
      require(_poolOwner != address(0), "FarmBitPoolManager: invalid pool owner address");
      require(_poolAddress != address(0), "FarmBitPoolManager: invalid pool address");
      
      _idCounter.increment();
      poolId = _idCounter.current();

      uint256 createdOn = block.timestamp;

      FarmBitPool pool = FarmBitPool(_poolAddress);
      pool.setup(poolId, _poolOwner, createdOn, _poolApy, _assetMaturityDateInDays, _maxSubscriptionAmount, 
        _subscriptionStartDate, _subscriptionStartDate.add(maxSubscriptionDays.daysToTimestamp()),
        unsubscriptionFee, emergencyWithdrawalCharge);

      Shared.PoolInfo memory poolInfo = Shared.PoolInfo(poolId, _poolAddress, _poolOwner, createdOn);
      poolSet.insert(bytes32(poolId));
      pools[poolId] = poolInfo;
      
      emit PoolAdded(poolId, _poolAddress, _poolOwner);
    }

    // Removes a pool from the list of existing pools
    function removePool(uint256 _poolId) external onlyOwner {
      require(pools[_poolId].poolAddress != address(0), 
          "FarmBitPoolManager: Attempting to delete nonexistent pool");

      Shared.PoolInfo memory poolInfo = pools[_poolId];
      poolSet.remove(bytes32(_poolId));
      delete pools[_poolId];

      emit PoolRemoved(_poolId, poolInfo.poolAddress, poolInfo.poolOwner);
    }

    // Pauses a pool
    function pausePool(uint256 _poolId) external onlyOwner {
      require(poolSet.exists(bytes32(_poolId)), "FarmBitPoolManager: Attempting to pause nonexistent pool");
      
      Shared.PoolInfo memory poolInfo = pools[_poolId];
      FarmBitPool pool = FarmBitPool(poolInfo.poolAddress);
      pool.pause();

      emit PoolPaused(_poolId, poolInfo.poolAddress, poolInfo.poolOwner);
    }

    // Resumes a pool
    function resumePool(uint256 _poolId) external onlyOwner {
      require(poolSet.exists(bytes32(_poolId)), "FarmBitPoolManager: Attempting to resume nonexistent pool");

      Shared.PoolInfo memory poolInfo = pools[_poolId];
      FarmBitPool pool = FarmBitPool(poolInfo.poolAddress);
      pool.resume();

      emit PoolResumed(_poolId, poolInfo.poolAddress, poolInfo.poolOwner);
    }
    
    function getPoolByIndex(uint256 index) external view 
      returns (address _poolOwner, address _poolAddress, uint256 _createdOn) {
      bytes32 key = poolSet.keyAtIndex(index);
      require(poolSet.exists(key), "FarmBitPoolManager: pool does not exist!");

      uint256 poolId = uint256(key);
      Shared.PoolInfo memory pool = pools[poolId];
      _poolOwner = pool.poolOwner;
      _createdOn = pool.createdOn;
      _poolAddress = pool.poolAddress;
    }

    function getTotalPools() external view returns (uint256) {
      return poolSet.count();
    }

    // Modifiers

    modifier isNotZero(uint256 value, string memory message) {
      require(value > 0, message);
      _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./HitchensUnorderedKeySet.sol";
import "./FarmBitPoolManager.sol";
import "./Shared.sol";

contract FarmBitPool is Pausable, AccessControl, Ownable {
    using SafeMath for uint256;
    using Shared for uint256;
    using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;

    uint256 public poolId; // A unique id for the pool
    address public poolOwner; // The address of the pool owner
    uint256 public createdOn; // The creation date of the pool

    uint256 public poolApy; // The APY for this pool
    uint256 public assetMaturityDate; // The maturity date for this pool
    uint256 public maxSubscriptionAmount; // The maximum amount required to lock this pool
    uint256 public totalAmountSubscribed; // The total amount subscribed so far

    uint256 public subscriptionStartDate; // The subscription start date
    uint256 public subscriptionEndDate; // The subscription end date
    uint256 public emergencyWithdrawalCharge; // How much percentage is charged when withdrawing before asset maturity
    uint256 public unsubscriptionFee; // The standard ubscription fee in percentage

    mapping(uint256 => Shared.ReceiptInfo) subscriptions; // A mapping of receipts to their token ids
    HitchensUnorderedKeySetLib.Set subscriptionSet;

    FarmBitPoolManager public poolManager; // The manager of the pool
    
    // Roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    // Events
    event SubscriptionCreated(uint256 indexed receiptId);
    event SubscriptionDeleted(uint256 indexed receiptId);

    constructor(address _poolManager) {
        poolManager = FarmBitPoolManager(_poolManager);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, _poolManager);
        _setupRole(PAUSER_ROLE, _poolManager);
        _setupRole(MODERATOR_ROLE, _poolManager);

        transferOwnership(_poolManager);
    }

    function setUnsubscriptionFee(uint256 _unsubscriptionFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        unsubscriptionFee = _unsubscriptionFee;
    }

    function setMaxSubscriptionAmount(uint256 _maxSubscriptionAmount) external onlyRole(MODERATOR_ROLE) 
        isNotZero(_maxSubscriptionAmount, "FarmBitPool: Invalid value") {
        require((totalAmountSubscribed < maxSubscriptionAmount) && (_maxSubscriptionAmount < maxSubscriptionAmount), 
            "FarmBitPool: pool is already filled");

        maxSubscriptionAmount = _maxSubscriptionAmount;
    }

    function setSubscriptionStartDate(uint256 _subscriptionStartDate) external onlyRole(MODERATOR_ROLE) 
        isNotZero(_subscriptionStartDate, "FarmBitPool: Invalid value") {
        require(_subscriptionStartDate < subscriptionEndDate, "FarmBitPool: subscription start date is after end date");

        subscriptionStartDate = _subscriptionStartDate;
    }

    function setSubscriptionEndDate(uint256 _subscriptionEndDate) external onlyRole(MODERATOR_ROLE) 
        isNotZero(_subscriptionEndDate, "FarmBitPool: Invalid value") {
        require(_subscriptionEndDate > subscriptionStartDate, "FarmBitPool: subscription end date is before start date");
        
        assetMaturityDate = assetMaturityDate.sub(subscriptionEndDate);
        subscriptionEndDate = _subscriptionEndDate;
        assetMaturityDate = assetMaturityDate.add(subscriptionEndDate);
    }

    function setEmergencyWithdrawalCharge(uint256 _emergencyWithdrawalCharge) external onlyRole(MODERATOR_ROLE) {
        emergencyWithdrawalCharge = _emergencyWithdrawalCharge;
    }

    // For test purposes
    function setAssetMaturityDate(uint256 _assetMaturityDate) external onlyRole(MODERATOR_ROLE) 
        isNotZero(_assetMaturityDate, "FarmBitPool: Invalid value") {
        require(_assetMaturityDate > block.timestamp, "FarmBitPool: asset maturity date is before current date");
        
        assetMaturityDate = _assetMaturityDate;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function resume() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Transfers FMB from this pool
    function transferFmb(address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        poolManager.receiptToken().subscriptionToken().transfer(_to, _amount);
    }

    // Transfers BUSD from this pool
    function transferBusd(address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(poolManager.receiptToken().fmbPriceTracker().busdToken()).transfer(_to, _amount);
    }

    function fmbBalance() external view returns (uint256) {
        return poolManager.receiptToken().subscriptionToken().balanceOf(address(this));
    }

    function busdBalance() external view returns (uint256) {
        return IERC20(poolManager.receiptToken().fmbPriceTracker().busdToken()).balanceOf(address(this));
    }

    // Called by the manager contract to setup the pool
    function setup(uint256 _poolId, address _poolOwner, uint256 _createdOn, uint256 _poolApy, 
        uint256 _assetMaturityDateInDays, uint256 _maxSubscriptionAmount, uint256 _subscriptionStartDate,
        uint256 _subscriptionEndDate, uint256 _unsubscriptionFee, uint256 _emergencyWithdrawalCharge) 
        public onlyRole(DEFAULT_ADMIN_ROLE) {

        // Init the fields
        poolId = _poolId;
        poolOwner = _poolOwner;
        createdOn = _createdOn;
        poolApy = _poolApy;
        assetMaturityDate = _subscriptionEndDate.add(_assetMaturityDateInDays.daysToTimestamp());
        maxSubscriptionAmount = _maxSubscriptionAmount;
        subscriptionStartDate = _subscriptionStartDate;
        subscriptionEndDate = _subscriptionEndDate;
        emergencyWithdrawalCharge = _emergencyWithdrawalCharge;
        unsubscriptionFee = _unsubscriptionFee;

        _setupRole(MODERATOR_ROLE, _poolOwner);
        transferOwnership(_poolOwner);
    }

    // Creates a new subscription
    function subscribe(uint256 _subscriptionAmount) external 
        whenNotPaused whenSubscriptionIsOngoing shouldNotExceedMaxSubscriptionAmount(_subscriptionAmount)
        returns (Shared.ReceiptInfo memory receipt) {
        
        // Create the receipt
        receipt = poolManager.receiptToken().createReceipt(msg.sender, _subscriptionAmount, poolId, poolApy, address(this));
        subscriptionSet.insert(bytes32(receipt.id));
        subscriptions[receipt.id] = receipt;

        // Increment the total amount subscribed
        totalAmountSubscribed = totalAmountSubscribed.add(receipt.subscriptionAmount);

        // Lock the pool if the max subscription is reached
        if (totalAmountSubscribed == maxSubscriptionAmount) {
            assetMaturityDate -= subscriptionEndDate;
            subscriptionEndDate = block.timestamp; // End subscription now
            assetMaturityDate += subscriptionEndDate;
        }

        emit SubscriptionCreated(receipt.id);
    }

    // Removes an existing subscription
    function unsubscribe(uint256 _receiptId) external 
        whenNotPaused isValidSubscription(_receiptId) {
        require(canUnsubscribe(), "FarmBitPool: this pool is locked");

        Shared.ReceiptInfo memory receipt = subscriptions[_receiptId];
        uint256 fmbSubscribed = receipt.subscriptionAmount;
        uint256 fmbToReturn = 0;

        // Remove standard fee if asset is matured else remove emergency withdrawal fee
        bool assetMatured = isAssetMatured();
        if (assetMatured) {
            fmbToReturn = fmbSubscribed.sub(fmbSubscribed.percentage(unsubscriptionFee));
        } else {
            fmbToReturn = fmbSubscribed.sub(fmbSubscribed.percentage(emergencyWithdrawalCharge));
        }
        
        // Calculated yield if it applies
        uint256 yield = 0;
        if (assetMatured) {
            (yield,,) = poolManager.receiptToken().getCurrentMaturityYieldInBusd(_receiptId);
        }

        // Burn the receipt
        poolManager.receiptToken().burnReceipt(_receiptId);
        subscriptionSet.remove(bytes32(_receiptId));
        delete subscriptions[_receiptId];
        totalAmountSubscribed -= fmbSubscribed;

        // Transfer the fmb remaining
        require(poolManager.receiptToken().subscriptionToken().transfer(msg.sender, fmbToReturn),
            "FarmBitPool: failed to transfer fmb");

        // Send the BUSD earned if asset is matured
        if (assetMatured) {
            // Transfer the yield to the unscubscriber
            IERC20 busdToken = IERC20(poolManager.receiptToken().fmbPriceTracker().busdToken());
            require(busdToken.transfer(msg.sender, yield));
        }

        emit SubscriptionDeleted(_receiptId);
    }

    // Verifies if a subscription exists in this pool
    // NOTE: Even if the subscription was generated by this pool, once it is destroyed, this pool considers it invalid!
    function verifySubscription(uint256 _receiptId) external view returns (bool) {
        return (subscriptionSet.exists(bytes32(_receiptId)) && subscriptions[_receiptId].poolAddress == address(this));
    }

    function getSubscriptionByIndex(uint256 index) external view 
        returns (uint256 _subscriptionAmount, uint256 _poolApy, address _poolAddress,
        address _receiptOwner) {
        bytes32 key = subscriptionSet.keyAtIndex(index);
        require(subscriptionSet.exists(key), "FarmBitPool: subscription does not exist!");

        uint256 _tokenId = uint256(key);
        Shared.ReceiptInfo memory receipt = subscriptions[_tokenId];
        _subscriptionAmount = receipt.subscriptionAmount;
        _poolApy = receipt.poolApy;
        _poolAddress = receipt.poolAddress;
        _receiptOwner = poolManager.receiptToken().ownerOf(_tokenId);
    }

    function getTotalSubscriptions() external view returns (uint256) {
        return subscriptionSet.count();
    }

    function getSubscriptionsOf(address _owner) external view returns (Shared.ReceiptInfo[] memory) {
        uint256 total = subscriptionSet.count();
        uint256 i;
        uint256 j;
        Shared.ReceiptInfo memory receipt;
        Shared.ReceiptInfo[] memory temp = new Shared.ReceiptInfo[](total);

        for (i = 0; i < total; i++) {
            receipt = subscriptions[uint256(subscriptionSet.keyAtIndex(i))];
            if (poolManager.receiptToken().ownerOf(receipt.id) == _owner) {
                temp[j] = receipt;
                j++;
            }
        }

        Shared.ReceiptInfo[] memory result = new Shared.ReceiptInfo[](j);
        for (i = 0; i < j; i++) {
            result[i] = temp[i];
        }

        return result;
    }

    // Returns the data for this pool
    function getData() external view returns (uint256 _subscribed, uint256 _maxSubscription, uint256 _secondsToMaturity,
        uint256 _secondsToStarting, uint256 _secondsToClosing, uint256 _apy, uint256 _emergencyWithdrawalFee, 
        uint256 _unsubscriptionFee) {
        
        _subscribed = totalAmountSubscribed;
        _maxSubscription = maxSubscriptionAmount;
        _apy = poolApy;
        _emergencyWithdrawalFee = emergencyWithdrawalCharge;
        _unsubscriptionFee = unsubscriptionFee;
        
        if (assetMaturityDate > 0 && assetMaturityDate > block.timestamp) {
            _secondsToMaturity = assetMaturityDate.sub(block.timestamp);
        }
        if (subscriptionEndDate > 0 && subscriptionEndDate > block.timestamp) {
            _secondsToClosing = subscriptionEndDate.sub(block.timestamp);
        }
        if (subscriptionStartDate > 0 && subscriptionStartDate > block.timestamp) {
            _secondsToStarting = subscriptionStartDate.sub(block.timestamp);
        }
    }

    function getStateData() external view returns (bool _canSubscribe, bool _canUnsubscribe, bool _isSubscriptionOnGoing, 
        bool _isAssetMatured, bool _isLocked) {
        
        _isSubscriptionOnGoing = isSubscriptionOnGoing();
        _isAssetMatured = isAssetMatured();
        _isLocked = isLocked();
        _canSubscribe = canSubscribe();
        _canUnsubscribe = canUnsubscribe();
    }

    function isSubscriptionOnGoing() public view returns (bool) {
        return block.timestamp >= subscriptionStartDate && block.timestamp < subscriptionEndDate;
    }

    function canUnsubscribe() public view returns (bool) {
        return !paused() && (isSubscriptionOnGoing() || isAssetMatured());
    }

    function canSubscribe() public view returns (bool) {
        return !paused() && isSubscriptionOnGoing();
    }

    function isAssetMatured() public view returns (bool) {
        return block.timestamp >= assetMaturityDate;
    }

    function isLocked() public view returns (bool) {
        return (block.timestamp >= subscriptionEndDate && !isAssetMatured()) 
            || (totalAmountSubscribed == maxSubscriptionAmount);
    }

    // Modifiers
    modifier whenSubscriptionIsOngoing() {
        require(isSubscriptionOnGoing(),
            "FarmBitPool: subscription is closed");
        _;
    }

    modifier shouldNotExceedMaxSubscriptionAmount(uint256 _subscriptionAmount) {
        require(totalAmountSubscribed.add(_subscriptionAmount) <= maxSubscriptionAmount,
            "FarmBitPool: subscription amount exceeds the remaining amount for this pool");
        _;
    }

    modifier isValidSubscription(uint256 _receiptId) {
        require(subscriptions[_receiptId].poolAddress == address(this),
            "FarmBitPool: unknown subscription");
        require(poolManager.receiptToken().ownerOf(_receiptId) == msg.sender,
            "FarmBitPool: you do not own this subscription");
        _;
    }

    modifier isNotZero(uint256 value, string memory message) {
        require(value > 0, message);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IPancakePair.sol";

contract FMBPriceTracker is Ownable {
  using SafeMath for uint256;

  IPancakePair public bnbBusdPair;
  IPancakePair public bnbFmbPair;

  address public bnbToken;
  address public busdToken;
  address public fmbToken;

  constructor(address _bnbBusdPair, address _bnbFmbPair, address _bnbToken, address _busdToken,
    address _fmbToken) {
    bnbBusdPair = IPancakePair(_bnbBusdPair);
    bnbFmbPair = IPancakePair(_bnbFmbPair);
    bnbToken = _bnbToken;
    busdToken = _busdToken;
    fmbToken = _fmbToken;
  }

  function setBnbBusdPair(address _bnbBusdPair) external onlyOwner {
    bnbBusdPair = IPancakePair(_bnbBusdPair);
  }

  function setBnbFmbPair(address _bnbFmbPair) external onlyOwner {
    bnbFmbPair = IPancakePair(_bnbFmbPair);
  }

  function setBnbToken(address _bnbToken) external onlyOwner {
    bnbToken = _bnbToken;
  }

  function setBusdToken(address _busdToken) external onlyOwner {
    busdToken = _busdToken;
  }

  function setFmbToken(address _fmbToken) external onlyOwner {
    fmbToken = _fmbToken;
  }

  // Converts a value in FMB to BUSD
  function fmbToBusd(uint256 fmb) external view returns(uint256 value) {
    value = _token0ToToken1(fmb, bnbFmbPair, bnbBusdPair);
  }

  // Returns the value of 1 FMB in BUSD
  function oneFmbInBusd() external view returns(uint256 value) {
    value = _token0ToToken1(10 ** bnbFmbPair.decimals(), bnbFmbPair, bnbBusdPair);
  }

  // Converts a value in BUSD to FMB
  function busdToFmb(uint256 busd) external view returns(uint256 value) {
    value = _token0ToToken1(busd, bnbBusdPair, bnbFmbPair);
  }

  // Returns the value of 1 BUSD in FMB
  function oneBusdInFmb() external view returns(uint256 value) {
    value = _token0ToToken1(10 ** bnbBusdPair.decimals(), bnbBusdPair, bnbFmbPair);
  }

  // Returns the value of 1 FMB in BNB
  function oneFmbInBnb() external view returns(uint256 value) {
    value = _tokenToBnb(10 ** bnbFmbPair.decimals(), bnbFmbPair);
  }

  // Converts a value in FMB to BNB
  function fmbToBnb(uint256 fmb) external view returns(uint256 value) {
    value = _tokenToBnb(fmb, bnbFmbPair);
  }

  // Converts a value in BNB to FMB
  function bnbToFmb(uint256 bnb) external view returns(uint256 value) {
    uint256 decimals = 10 ** bnbFmbPair.decimals();
    value = bnb.div(_tokenToBnb(decimals, bnbFmbPair)).mul(decimals);
  }

  // Returns the value of 1 BNB in FMB
  function oneBnbInFmb() external view returns(uint256 value) {
    uint256 decimals = 10 ** bnbFmbPair.decimals();
    value = (decimals).div(_tokenToBnb(decimals, bnbFmbPair)).mul(decimals);
  }

  function _isBnbToken0(IPancakePair pair) private view returns(bool) {
    return pair.token0() == bnbToken;
  }

  function _convertToken0ToToken1(uint256 token0, uint256 token0ToBnb, uint256 bnbToToken1, 
    uint256 decimals) private pure returns (uint256) {
    return token0ToBnb.mul(token0).mul(bnbToToken1).div(decimals).div(decimals);
  }

  // Converts token0 to token1 given the pairs of both tokens to BNB
  function _token0ToToken1(uint256 token0, IPancakePair bnbToken0Pair, IPancakePair bnbToken1Pair) 
    private view returns(uint256 value) {
    
    // First get the value of a BNB in token1
    (uint256 reserve0, uint256 reserve1,) = bnbToken1Pair.getReserves();
    uint256 decimals0 = 10 ** bnbToken0Pair.decimals();
    uint256 decimals1 = 10 ** bnbToken1Pair.decimals();

    uint256 bnbToToken1 = 0;
    if (_isBnbToken0(bnbToken1Pair)) {
      reserve1 = reserve1.mul(decimals1);
      bnbToToken1 = reserve1.div(reserve0);
    } else {
      reserve0 = reserve0.mul(decimals1);
      bnbToToken1 = reserve0.div(reserve1);
    }

    // Get the value of token0 in a BNB
    (reserve0, reserve1,) = bnbToken0Pair.getReserves();
    
    uint256 token0ToBnb = 0;
    if (_isBnbToken0(bnbToken0Pair)) {
      reserve0 = reserve0.mul(decimals0);
      token0ToBnb = reserve0.div(reserve1);
    } else {
      reserve1 = reserve1.mul(decimals0);
      token0ToBnb = reserve1.div(reserve0);
    }

    // Convert token0 to token1
    value = _convertToken0ToToken1(token0, token0ToBnb, bnbToToken1, decimals0);
  }

  // Converts a token to BNB given a pair of the token to BNB
  function _tokenToBnb(uint256 token, IPancakePair bnbTokenPair) 
    private view returns(uint256 value) {
    
    // Get the value of BNB in a token
    (uint256 reserve0, uint256 reserve1,) = bnbTokenPair.getReserves();
    uint256 decimals = 10 ** bnbTokenPair.decimals();

    uint256 tokenToBnb = 0;
    if (_isBnbToken0(bnbTokenPair)) {
      reserve0 = reserve0.mul(decimals);
      tokenToBnb = reserve0.div(reserve1);
    } else {
      reserve1 = reserve1.mul(decimals);
      tokenToBnb = reserve1.div(reserve0);
    }

    // Convert token0 to token1
    value = tokenToBnb.mul(token).div(decimals);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
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
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}