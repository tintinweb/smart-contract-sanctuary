/**
 *Submitted for verification at polygonscan.com on 2021-09-27
*/

// File: contracts/privileged/Privileged.sol

pragma solidity ^0.4.24;

/**
 * Library to support managing and checking per-address privileges.
 */
contract Privileged {
  mapping (address => uint8) public privileges;
  uint8 internal rootPrivilege;

  constructor(uint8 _rootPrivilege) internal {
    rootPrivilege = _rootPrivilege;
    privileges[msg.sender] = rootPrivilege;
  }

  function grantPrivileges(address _target, uint8 _privileges) public requirePrivileges(rootPrivilege) {
    privileges[_target] |= _privileges;
  }

  function removePrivileges(address _target, uint8 _privileges) public requirePrivileges(rootPrivilege) {
    // May not remove privileges from self.
    require(_target != msg.sender);
    privileges[_target] &= ~_privileges;
  }

  modifier requirePrivileges(uint8 _mask) {
    require((privileges[msg.sender] & _mask) == _mask);
    _;
  }
}

// File: contracts/erc20/ERC20TokenInterface.sol

pragma solidity ^0.4.24;

contract ERC20TokenInterface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    function balanceOf(address owner) public constant returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/tokenretriever/TokenRetriever.sol

pragma solidity ^0.4.24;



/**
 * Used to retrieve ERC20 tokens that were accidentally sent to our contracts.
 */
contract TokenRetriever is Privileged {
  uint8 internal retrieveTokensFromContractPrivilege;

  constructor(uint8 _retrieveTokensFromContractPrivilege) internal {
    retrieveTokensFromContractPrivilege = _retrieveTokensFromContractPrivilege;
  }

  function invokeErc20Transfer(address _tokenContract, address _destination, uint256 _amount) external requirePrivileges(retrieveTokensFromContractPrivilege) {
      ERC20TokenInterface(_tokenContract).transfer(_destination, _amount);
  }
}

// File: contracts/vendingmachine/VendingMachine.sol

pragma solidity ^0.4.24;



/**
 * fb8919a77a3d4b42bc5181d649378a2d1dc7641698f99e8d412d38409586b226
 */

contract VendingMachine is Privileged, TokenRetriever {
    event SeedPurchase(address indexed from, uint256 indexed itemId, uint256 indexed value, uint32 itemType, bytes varData);
    event EtherPurchase(address indexed from, uint256 indexed itemId, uint256 indexed value, uint32 itemType, bytes varData);

    uint32 constant UINT32_MAX = ~uint32(0);

    struct InventoryEntry {
        uint256 index;
        uint256 seedPrice;
        uint256 ethPrice;
        uint32 quantity;
        uint32 itemType;
    }

    mapping(uint256 => InventoryEntry) public inventoryEntries;
    uint256[] public itemIds;

    // Privileges
    uint8 constant PRIV_ROOT = 1;
    uint8 constant PRIV_MANAGE = 2;
    uint8 constant PRIV_WITHDRAW = 4;

    ERC20TokenInterface internal seedContract;

    constructor(address _seedContractAddress) public Privileged(PRIV_ROOT) TokenRetriever(PRIV_ROOT) {
        seedContract = ERC20TokenInterface(_seedContractAddress);
        // Grant other privileges to the contract creator
        grantPrivileges(msg.sender, PRIV_MANAGE|PRIV_WITHDRAW);
    }

    function seedPurchase(uint256 _itemId, uint256 _value, bytes _varData) external {
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        require(_inventoryEntryExists(inventoryEntry));
        require(inventoryEntry.seedPrice != 0);
        require(_value == inventoryEntry.seedPrice);
        require(seedContract.transferFrom(msg.sender, address(this), _value));
        uint32 _itemType = inventoryEntry.itemType; // value saved before entry is deleted
        _deductInventoryItem(inventoryEntry, _itemId);
        emit SeedPurchase(msg.sender, _itemId, _value, _itemType, _varData);
    }

    function etherPurchase(uint256 _itemId, bytes _varData) external payable {
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        require(_inventoryEntryExists(inventoryEntry));
        require(inventoryEntry.ethPrice != 0);
        require(msg.value == inventoryEntry.ethPrice);
        uint32 _itemType = inventoryEntry.itemType; // value saved before entry is deleted
        _deductInventoryItem(inventoryEntry, _itemId);
        emit EtherPurchase(msg.sender, _itemId, msg.value, _itemType, _varData);
    }

    function upsertInventoryItem(uint256 _itemId, uint256 seedPrice, uint256 ethPrice, uint32 quantity, uint32 itemType) external requirePrivileges(PRIV_MANAGE) {
        require(quantity > 0);
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        if (!_inventoryEntryExists(inventoryEntry)) {
            // New item
            inventoryEntry.index = itemIds.length;
            itemIds.push(_itemId);
        }
        inventoryEntry.seedPrice = seedPrice;
        inventoryEntry.ethPrice = ethPrice;
        inventoryEntry.quantity = quantity;
        inventoryEntry.itemType = itemType;
    }

    function deleteInventoryItem(uint256 _itemId) external requirePrivileges(PRIV_MANAGE) {
        _deleteInventoryItem(_itemId);
    }

    function withdrawSeed(uint256 _amount) external requirePrivileges(PRIV_WITHDRAW) {
        seedContract.transfer(msg.sender, _amount);
    }

    function withdrawEther(uint256 _amount) external requirePrivileges(PRIV_WITHDRAW) {
        msg.sender.transfer(_amount);
    }

    function totalItems() public view returns (uint256) {
        return itemIds.length;
    }

    function _deductInventoryItem(InventoryEntry storage inventoryEntry, uint256 _itemId) internal {
        if (inventoryEntry.quantity == UINT32_MAX) {
            // Do nothing, this means infinite quantity available
        } else if (inventoryEntry.quantity > 1) {
            inventoryEntry.quantity--;
        } else {
            _deleteInventoryItem(_itemId);
        }
    }

    function _deleteInventoryItem(uint256 _itemId) internal {
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        if (!_inventoryEntryExists(inventoryEntry)) {
            return;
        }
        uint256 lastItemIndex = itemIds.length - 1; // Safe because at least one item must exist (asserted above)
        uint256 lastItemId = itemIds[lastItemIndex];
        itemIds[inventoryEntry.index] = itemIds[lastItemIndex];
        inventoryEntries[lastItemId].index = inventoryEntry.index;
        itemIds.length--;
        delete inventoryEntries[_itemId];
    }

    function _inventoryEntryExists(InventoryEntry storage inventoryEntry) internal view returns (bool) {
        return inventoryEntry.quantity != 0;
    }
}

// File: contracts/breedfee/BreedFee.sol

pragma solidity ^0.4.24;




contract BreedFee is Privileged {
    event BreedEth(address indexed breeder, address indexed breedee, uint256 indexed price);
    event BreedSeed(address indexed breeder, address indexed breedee, uint256 indexed price);

    // Constants & Privileges
    uint8 constant PRIV_ROOT = 1;
    uint8 constant PRIV_MANAGE = 2;
    uint8 constant PRIV_WITHDRAW = 4;
    uint256 constant public MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // Internal Variables
    VendingMachine internal vmContract;
    ERC20TokenInterface internal seedContract;

    // Public Variables (getters only created automatically)
    uint256 public breedeeFeeEth;
    uint256 public breedeeFeeSeed;

    constructor(address _vendingMachineAddress, address _seedContractAddress) public Privileged(PRIV_ROOT) {
        breedeeFeeEth = 0.0005 ether;
        breedeeFeeSeed = 500;

        vmContract = VendingMachine(_vendingMachineAddress);
        seedContract = ERC20TokenInterface(_seedContractAddress);

        // We allow VM to spend our SEED
        seedContract.approve(address(vmContract), MAX_UINT256);

        // Grant other privileges to the contract creator
        grantPrivileges(msg.sender, PRIV_MANAGE|PRIV_WITHDRAW);
    }

    // Wrapper around VM's etherPurchase to implement splitting
    function breedEth(address _breedee, uint256 _itemId, bytes _varData) external payable {
        // Validity of _breedee address is checked later by Minter
        // Validity of the _itemId is checked later by Minter
        uint256 ethPrice;
        uint32 quantity;
        (, , ethPrice, quantity, ) = vmContract.inventoryEntries(_itemId);
        require(quantity != 0);
        require(ethPrice != 0);
        require(msg.value == ethPrice + breedeeFeeEth);

        // Could limit this further with a .gas() modifier, but we trust VM
        vmContract.etherPurchase.value(ethPrice)(_itemId, _varData);

        // Send to unknown address/contract must come last, since it comes
        // with code execution and could fail. Transfer throws an exception
        _breedee.transfer(breedeeFeeEth);
        emit BreedEth(msg.sender, _breedee, ethPrice + breedeeFeeEth);
    }

    // Wrapper around VM's seedPurchase to implement splitting
    function breedSeed(address _breedee, uint256 _itemId, bytes _varData) external {
        // Validity of _breedee address is checked later by Minter
        // Validity of the _itemId is checked later by Minter
        uint256 seedPrice;
        uint32 quantity;
        (, seedPrice, , quantity, ) = vmContract.inventoryEntries(_itemId);
        require(quantity != 0);
        require(seedPrice != 0);

        // Do split transfers
        require(seedContract.transferFrom(msg.sender, address(this), seedPrice));
        if (msg.sender != _breedee) {
            require(seedContract.transferFrom(msg.sender, _breedee, breedeeFeeSeed));
        }
        vmContract.seedPurchase(_itemId, seedPrice, _varData);

        emit BreedSeed(msg.sender, _breedee, seedPrice + breedeeFeeSeed);
    }

    function setBreedeeFeeEth(uint256 _fee) external requirePrivileges(PRIV_MANAGE) {
        breedeeFeeEth = _fee;
    }

    function setBreedeeFeeSeed(uint256 _fee) external requirePrivileges(PRIV_MANAGE) {
        breedeeFeeSeed = _fee;
    }

    function withdrawEth(uint256 _amount) external requirePrivileges(PRIV_WITHDRAW) {
        msg.sender.transfer(_amount);
    }

    function withdrawSeed(uint256 _amount) external requirePrivileges(PRIV_WITHDRAW) {
        seedContract.transfer(msg.sender, _amount);
    }
}