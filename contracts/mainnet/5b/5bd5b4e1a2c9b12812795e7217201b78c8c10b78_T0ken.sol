/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


pragma solidity ^0.5.2;


/**
 *  @title Ownable
 *  @dev Provides a modifier that requires the caller to be the owner of the contract.
 */
contract Ownable {
    address payable public owner;

    event OwnerTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner account is required");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwner(address payable newOwner)
    public
    onlyOwner {
        require(newOwner != owner, "New Owner cannot be the current owner");
        require(newOwner != address(0), "New Owner cannot be zero address");
        address payable prevOwner = owner;
        owner = newOwner;
        emit OwnerTransferred(prevOwner, newOwner);
    }
}

/**
 *  @title Lockable
 *  @dev The Lockable contract adds the ability for the contract owner to set the lock status
 *  of the account. A modifier is provided that checks the throws when the contract is
 *  in the locked state.
 */
contract Lockable is Ownable {
    bool public isLocked;

    constructor() public {
        isLocked = false;
    }

    modifier isUnlocked() {
        require(!isLocked, "Contract is currently locked for modification");
        _;
    }

    /**
     *  Set the contract to a read-only state.
     *  @param locked The locked state to set the contract to.
     */
    function setLocked(bool locked)
    onlyOwner
    external {
        require(isLocked != locked, "Contract already in requested lock state");

        isLocked = locked;
    }
}

/**
 *  @title Destroyable
 *  @dev The Destroyable contract alows the owner address to `selfdestruct` the contract.
 */
contract Destroyable is Ownable {
    /**
     *  Allow the owner to destroy this contract.
     */
    function kill()
    onlyOwner
    external {
        selfdestruct(owner);
    }
}

/**
 *  Contract to facilitate locking and self destructing.
 */
contract LockableDestroyable is Lockable, Destroyable { }

library AdditiveMath {
    /**
     *  Adds two numbers and returns the result
     *  THROWS when the result overflows
     *  @return The sum of the arguments
     */
    function add(uint256 x, uint256 y)
    internal
    pure
    returns (uint256) {
        uint256 sum = x + y;
        require(sum >= x, "Results in overflow");
        return sum;
    }

    /**
     *  Subtracts two numbers and returns the result
     *  THROWS when the result underflows
     *  @return The difference of the arguments
     */
    function subtract(uint256 x, uint256 y)
    internal
    pure
    returns (uint256) {
        require(y <= x, "Results in underflow");
        return x - y;
    }
}

/**
 *
 *  @title AddressMap
 *  @dev Map of unique indexed addresseses.
 *
 *  **NOTE**
 *    The internal collections are one-based.
 *    This is simply because null values are expressed as zero,
 *    which makes it hard to check for the existence of items within the array,
 *    or grabbing the first item of an array for non-existent items.
 *
 *    This is only exposed internally, so callers still use zero-based indices.
 *
 */
library AddressMap {
    struct Data {
        int256 count;
        mapping(address => int256) indices;
        mapping(int256 => address) items;
    }

    address constant ZERO_ADDRESS = address(0);

    /**
     *  Appends the address to the end of the map, if the address is not
     *  zero and the address doesn&#39;t currently exist.
     *  @param addr The address to append.
     *  @return true if the address was added.
     */
    function append(Data storage self, address addr)
    internal
    returns (bool) {
        if (addr == ZERO_ADDRESS) {
            return false;
        }

        int256 index = self.indices[addr] - 1;
        if (index >= 0 && index < self.count) {
            return false;
        }

        self.count++;
        self.indices[addr] = self.count;
        self.items[self.count] = addr;
        return true;
    }

    /**
     *  Removes the given address from the map.
     *  @param addr The address to remove from the map.
     *  @return true if the address was removed.
     */
    function remove(Data storage self, address addr)
    internal
    returns (bool) {
        int256 oneBasedIndex = self.indices[addr];
        if (oneBasedIndex < 1 || oneBasedIndex > self.count) {
            return false;  // address doesn&#39;t exist, or zero.
        }

        // When the item being removed is not the last item in the collection,
        // replace that item with the last one, otherwise zero it out.
        //
        //  If {2} is the item to be removed
        //     [0, 1, 2, 3, 4]
        //  The result would be:
        //     [0, 1, 4, 3]
        //
        if (oneBasedIndex < self.count) {
            // Replace with last item
            address last = self.items[self.count];  // Get the last item
            self.indices[last] = oneBasedIndex;     // Update last items index to current index
            self.items[oneBasedIndex] = last;       // Update current index to last item
            delete self.items[self.count];          // Delete the last item, since it&#39;s moved
        } else {
            // Delete the address
            delete self.items[oneBasedIndex];
        }

        delete self.indices[addr];
        self.count--;
        return true;
    }

    /**
     * Clears all items within the map.
     */
    function clear(Data storage self)
    internal {
        self.count = 0;
    }

    /**
     *  Retrieves the address at the given index.
     *  THROWS when the index is invalid.
     *  @param index The index of the item to retrieve.
     *  @return The address of the item at the given index.
     */
    function at(Data storage self, int256 index)
    internal
    view
    returns (address) {
        require(index >= 0 && index < self.count, "Index outside of bounds.");
        return self.items[index + 1];
    }

    /**
     *  Gets the index of the given address.
     *  @param addr The address of the item to get the index for.
     *  @return The index of the given address.
     */
    function indexOf(Data storage self, address addr)
    internal
    view
    returns (int256) {
        if (addr == ZERO_ADDRESS) {
            return -1;
        }

        int256 index = self.indices[addr] - 1;
        if (index < 0 || index >= self.count) {
            return -1;
        }
        return index;
    }

    /**
     *  Returns whether or not the given address exists within the map.
     *  @param addr The address to check for existence.
     *  @return If the given address exists or not.
     */
    function exists(Data storage self, address addr)
    internal
    view
    returns (bool) {
        int256 index = self.indices[addr] - 1;
        return index >= 0 && index < self.count;
    }

}

/**
 *
 *  @title AccountMap
 *  @dev Map of unique indexed accounts.
 *
 *  **NOTE**
 *    The internal collections are one-based.
 *    This is simply because null values are expressed as zero,
 *    which makes it hard to check for the existence of items within the array,
 *    or grabbing the first item of an array for non-existent items.
 *
 *    This is only exposed internally, so callers still use zero-based indices.
 *
 */
library AccountMap {
    struct Account {
        address addr;
        uint8 kind;
        bool frozen;
        address parent;
    }

    struct Data {
        int256 count;
        mapping(address => int256) indices;
        mapping(int256 => Account) items;
    }

    address constant ZERO_ADDRESS = address(0);

    /**
     *  Appends the address to the end of the map, if the addres is not
     *  zero and the address doesn&#39;t currently exist.
     *  @param addr The address to append.
     *  @return true if the address was added.
     */
    function append(Data storage self, address addr, uint8 kind, bool isFrozen, address parent)
    internal
    returns (bool) {
        if (addr == ZERO_ADDRESS) {
            return false;
        }

        int256 index = self.indices[addr] - 1;
        if (index >= 0 && index < self.count) {
            return false;
        }

        self.count++;
        self.indices[addr] = self.count;
        self.items[self.count] = Account(addr, kind, isFrozen, parent);
        return true;
    }

    /**
     *  Removes the given address from the map.
     *  @param addr The address to remove from the map.
     *  @return true if the address was removed.
     */
    function remove(Data storage self, address addr)
    internal
    returns (bool) {
        int256 oneBasedIndex = self.indices[addr];
        if (oneBasedIndex < 1 || oneBasedIndex > self.count) {
            return false;  // address doesn&#39;t exist, or zero.
        }

        // When the item being removed is not the last item in the collection,
        // replace that item with the last one, otherwise zero it out.
        //
        //  If {2} is the item to be removed
        //     [0, 1, 2, 3, 4]
        //  The result would be:
        //     [0, 1, 4, 3]
        //
        if (oneBasedIndex < self.count) {
            // Replace with last item
            Account storage last = self.items[self.count];  // Get the last item
            self.indices[last.addr] = oneBasedIndex;        // Update last items index to current index
            self.items[oneBasedIndex] = last;               // Update current index to last item
            delete self.items[self.count];                  // Delete the last item, since it&#39;s moved
        } else {
            // Delete the account
            delete self.items[oneBasedIndex];
        }

        delete self.indices[addr];
        self.count--;
        return true;
    }

    /**
     * Clears all items within the map.
     */
    function clear(Data storage self)
    internal {
        self.count = 0;
    }

    /**
     *  Retrieves the address at the given index.
     *  THROWS when the index is invalid.
     *  @param index The index of the item to retrieve.
     *  @return The address of the item at the given index.
     */
    function at(Data storage self, int256 index)
    internal
    view
    returns (Account memory) {
        require(index >= 0 && index < self.count, "Index outside of bounds.");
        return self.items[index + 1];
    }

    /**
     *  Gets the index of the given address.
     *  @param addr The address of the item to get the index for.
     *  @return The index of the given address.
     */
    function indexOf(Data storage self, address addr)
    internal
    view
    returns (int256) {
        if (addr == ZERO_ADDRESS) {
            return -1;
        }

        int256 index = self.indices[addr] - 1;
        if (index < 0 || index >= self.count) {
            return -1;
        }
        return index;
    }

    /**
     *  Gets the Account for the given address.
     *  THROWS when an account doesn&#39;t exist for the given address.
     *  @param addr The address of the item to get.
     *  @return The account of the given address.
     */
    function get(Data storage self, address addr)
    internal
    view
    returns (Account memory) {
        return at(self, indexOf(self, addr));
    }

    /**
     *  Returns whether or not the given address exists within the map.
     *  @param addr The address to check for existence.
     *  @return If the given address exists or not.
     */
    function exists(Data storage self, address addr)
    internal
    view
    returns (bool) {
        int256 index = self.indices[addr] - 1;
        return index >= 0 && index < self.count;
    }

}

/**
 *  @title Registry Storage
 */
contract Storage is Ownable, LockableDestroyable {
  
    using AccountMap for AccountMap.Data;
    using AddressMap for AddressMap.Data;

    // ------------------------------- Variables -------------------------------
    // Number of data slots available for accounts
    uint8 constant MAX_DATA = 30;

    // Accounts
    AccountMap.Data public accounts;

    // Account Data
    //   - mapping of:
    //     (address        => (index =>    data))
    mapping(address => mapping(uint8 => bytes32)) public data;

    // Address write permissions
    //     (kind  => address)
    mapping(uint8 => AddressMap.Data) public permissions;


    // ------------------------------- Modifiers -------------------------------
    /**
     *  Ensures the `msg.sender` has permission for the given kind/type of account.
     *
     *    - The `owner` account is always allowed
     *    - Addresses/Contracts must have a corresponding entry, for the given kind
     */
    modifier isAllowed(uint8 kind) {
        require(kind > 0, "Invalid, or missing permission");
        if (msg.sender != owner) {
            require(permissions[kind].exists(msg.sender), "Missing permission");
        }
        _;
    }

    // -------------------------------------------------------------------------

    /**
     *  Adds an account to storage
     *  THROWS when `msg.sender` doesn&#39;t have permission
     *  THROWS when the account already exists
     *  @param addr The address of the account
     *  @param kind The kind of account
     *  @param isFrozen The frozen status of the account
     *  @param parent The account parent/owner
     */
    function addAccount(address addr, uint8 kind, bool isFrozen, address parent)
    isUnlocked
    isAllowed(kind)
    external {
        require(accounts.append(addr, kind, isFrozen, parent), "Account already exists");
    }

    /**
     *  Sets an account&#39;s frozen status
     *  THROWS when the account doesn&#39;t exist
     *  @param addr The address of the account
     *  @param frozen The frozen status of the account
     */
    function setAccountFrozen(address addr, bool frozen)
    isUnlocked
    isAllowed(accounts.get(addr).kind)
    external {
        // NOTE: Not bounds checking `index` here, as `isAllowed` ensures the address exists.
        //       Indices are one-based internally, so we need to add one to compensate.
        int256 index = accounts.indexOf(addr) + 1;
        accounts.items[index].frozen = frozen;
    }

    /**
     *  Removes an account from storage
     *  THROWS when the account doesn&#39;t exist
     *  @param addr The address of the account
     */
    function removeAccount(address addr)
    isUnlocked
    isAllowed(accounts.get(addr).kind)
    external {
        bytes32 ZERO_BYTES = bytes32(0);
        mapping(uint8 => bytes32) storage accountData = data[addr];

        // Remove data
        for (uint8 i = 0; i < MAX_DATA; i++) {
            if (accountData[i] != ZERO_BYTES) {
                delete accountData[i];
            }
        }

        // Remove account
        accounts.remove(addr);
    }

    /**
     *  Sets data for an address/caller
     *  THROWS when the account doesn&#39;t exist
     *  @param addr The address
     *  @param index The index of the data
     *  @param customData The data store set
     */
    function setAccountData(address addr, uint8 index, bytes32 customData)
    isUnlocked
    isAllowed(accounts.get(addr).kind)
    external {
        require(index < MAX_DATA, "index outside of bounds");
        data[addr][index] = customData;
    }

    /**
     *  Grants the address permission for the given kind
     *  @param kind The kind of address
     *  @param addr The address
     */
    function grantPermission(uint8 kind, address addr)
    isUnlocked
    isAllowed(kind)
    external {
        permissions[kind].append(addr);
    }

    /**
     *  Revokes the address permission for the given kind
     *  @param kind The kind of address
     *  @param addr The address
     */
    function revokePermission(uint8 kind, address addr)
    isUnlocked
    isAllowed(kind)
    external {
        permissions[kind].remove(addr);
    }

    // ---------------------------- Address Getters ----------------------------
    /**
     *  Gets the account at the given index
     *  THROWS when the index is out-of-bounds
     *  @param index The index of the item to retrieve
     *  @return The address, kind, frozen status, and parent of the account at the given index
     */
    function accountAt(int256 index)
    external
    view
    returns(address, uint8, bool, address) {
        AccountMap.Account memory acct = accounts.at(index);
        return (acct.addr, acct.kind, acct.frozen, acct.parent);
    }

    /**
     *  Gets the account for the given address
     *  THROWS when the account doesn&#39;t exist
     *  @param addr The address of the item to retrieve
     *  @return The address, kind, frozen status, and parent of the account at the given index
     */
    function accountGet(address addr)
    external
    view
    returns(uint8, bool, address) {
        AccountMap.Account memory acct = accounts.get(addr);
        return (acct.kind, acct.frozen, acct.parent);
    }

    /**
     *  Gets the parent address for the given account address
     *  THROWS when the account doesn&#39;t exist
     *  @param addr The address of the account
     *  @return The parent address
     */
    function accountParent(address addr)
    external
    view
    returns(address) {
        return accounts.get(addr).parent;
    }

    /**
     *  Gets the account kind, for the given account address
     *  THROWS when the account doesn&#39;t exist
     *  @param addr The address of the account
     *  @return The kind of account
     */
    function accountKind(address addr)
    external
    view
    returns(uint8) {
        return accounts.get(addr).kind;
    }

    /**
     *  Gets the frozen status of the account
     *  THROWS when the account doesn&#39;t exist
     *  @param addr The address of the account
     *  @return The frozen status of the account
     */
    function accountFrozen(address addr)
    external
    view
    returns(bool) {
        return accounts.get(addr).frozen;
    }

    /**
     *  Gets the index of the account
     *  Returns -1 for missing accounts
     *  @param addr The address of the account to get the index for
     *  @return The index of the given account address
     */
    function accountIndexOf(address addr)
    external
    view
    returns(int256) {
        return accounts.indexOf(addr);
    }

    /**
     *  Returns wether or not the given address exists
     *  @param addr The account address
     *  @return If the given address exists
     */
    function accountExists(address addr)
    external
    view
    returns(bool) {
        return accounts.exists(addr);
    }

    /**
     *  Returns wether or not the given address exists for the given kind
     *  @param addr The account address
     *  @param kind The kind of address
     *  @return If the given address exists with the given kind
     */
    function accountExists(address addr, uint8 kind)
    external
    view
    returns(bool) {
        int256 index = accounts.indexOf(addr);
        if (index < 0) {
            return false;
        }
        return accounts.at(index).kind == kind;
    }


    // -------------------------- Permission Getters ---------------------------
    /**
     *  Retrieves the permission address at the index for the given type
     *  THROWS when the index is out-of-bounds
     *  @param kind The kind of permission
     *  @param index The index of the item to retrieve
     *  @return The permission address of the item at the given index
     */
    function permissionAt(uint8 kind, int256 index)
    external
    view
    returns(address) {
        return permissions[kind].at(index);
    }

    /**
     *  Gets the index of the permission address for the given type
     *  Returns -1 for missing permission
     *  @param kind The kind of perission
     *  @param addr The address of the permission to get the index for
     *  @return The index of the given permission address
     */
    function permissionIndexOf(uint8 kind, address addr)
    external
    view
    returns(int256) {
        return permissions[kind].indexOf(addr);
    }

    /**
     *  Returns wether or not the given permission address exists for the given type
     *  @param kind The kind of permission
     *  @param addr The address to check for permission
     *  @return If the given address has permission or not
     */
    function permissionExists(uint8 kind, address addr)
    external
    view
    returns(bool) {
        return permissions[kind].exists(addr);
    }

}


interface ComplianceRule {

    /**
     *  @dev Checks if a transfer can occur between the from/to addresses and MUST throw when the check fails.
     *  @param initiator The address initiating the transfer.
     *  @param from The address of the sender
     *  @param to The address of the receiver
     *  @param toKind The kind of the to address
     *  @param tokens The number of tokens being transferred.
     *  @param store The Storage contract
     */
    function check(address initiator, address from, address to, uint8 toKind, uint256 tokens, Storage store)
    external;
}

interface Compliance {

    /**
     *  This event is emitted when an address&#39;s frozen status has changed.
     *  @param addr The address whose frozen status has been updated.
     *  @param isFrozen Whether the custodian is being frozen.
     *  @param owner The address that updated the frozen status.
     */
    event AddressFrozen(
        address indexed addr,
        bool indexed isFrozen,
        address indexed owner
    );

    /**
     *  Sets an address frozen status for this token
     *  @param addr The address to update frozen status.
     *  @param freeze Frozen status of the address.
     */
    function setFrozen(address addr, bool freeze)
    external;

    /**
     *  Replaces all of the existing rules with the given ones
     *  @param kind The bucket of rules to set.
     *  @param rules New compliance rules.
     */
    function setRules(uint8 kind, ComplianceRule[] calldata rules)
    external;

    /**
     *  Returns all of the current compliance rules for this token
     *  @param kind The bucket of rules to get.
     *  @return List of all compliance rules.
     */
    function getRules(uint8 kind)
    external
    view
    returns (ComplianceRule[] memory);

    /**
     *  @dev Checks if issuance can occur between the from/to addresses.
     *
     *  Both addresses must be whitelisted and unfrozen
     *  THROWS when the transfer should fail.
     *  @param issuer The address initiating the issuance.
     *  @param from The address of the sender.
     *  @param to The address of the receiver.
     *  @param tokens The number of tokens being transferred.
     *  @return If a issuance can occur between the from/to addresses.
     */
    function canIssue(address issuer, address from, address to, uint256 tokens)
    external
    returns (bool);

    /**
     *  @dev Checks if a transfer can occur between the from/to addresses.
     *
     *  Both addresses must be whitelisted, unfrozen, and pass all compliance rule checks.
     *  THROWS when the transfer should fail.
     *  @param initiator The address initiating the transfer.
     *  @param from The address of the sender.
     *  @param to The address of the receiver.
     *  @param tokens The number of tokens being transferred.
     *  @return If a transfer can occur between the from/to addresses.
     */
    function canTransfer(address initiator, address from, address to, uint256 tokens)
    external
    returns (bool);

    /**
     *  @dev Checks if an override by the sender can occur between the from/to addresses.
     *
     *  Both addresses must be whitelisted and unfrozen.
     *  THROWS when the sender is not allowed to override.
     *  @param admin The address initiating the transfer.
     *  @param from The address of the sender.
     *  @param to The address of the receiver.
     *  @param tokens The number of tokens being transferred.
     *  @return If an override can occur between the from/to addresses.
     */
    function canOverride(address admin, address from, address to, uint256 tokens)
    external
    returns (bool);
}


interface ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract T0ken is ERC20, Ownable, LockableDestroyable {

    // ------------------------------- Variables -------------------------------

    using AdditiveMath for uint256;
    using AddressMap for AddressMap.Data;

    address constant internal ZERO_ADDRESS = address(0);
    string public constant name = "TZERO PREFERRED";
    string public constant symbol = "TZROP";
    uint8 public constant decimals = 0;

    AddressMap.Data public shareholders;
    Compliance public compliance;
    address public issuer;
    bool public issuingFinished = false;
    mapping(address => address) public cancellations;

    mapping(address => uint256) internal balances;
    uint256 internal totalSupplyTokens;

    mapping (address => mapping (address => uint256)) private allowed;

    // ------------------------------- Modifiers -------------------------------

    modifier onlyIssuer() {
        require(msg.sender == issuer, "Only issuer allowed");
        _;
    }

    modifier canIssue() {
        require(!issuingFinished, "Issuing is already finished");
        _;
    }

    modifier isNotCancelled(address addr) {
        require(cancellations[addr] == ZERO_ADDRESS, "Address has been cancelled");
        _;
    }

    modifier hasFunds(address addr, uint256 tokens) {
        require(tokens <= balances[addr], "Insufficient funds");
        _;
    }

    // -------------------------------- Events ---------------------------------

    /**
     *  This event is emitted when an address is cancelled and replaced with
     *  a new address.  This happens in the case where a shareholder has
     *  lost access to their original address and needs to have their share
     *  reissued to a new address.  This is the equivalent of issuing replacement
     *  share certificates.
     *  @param original The address being superseded.
     *  @param replacement The new address.
     *  @param sender The address that caused the address to be superseded.
    */
    event VerifiedAddressSuperseded(address indexed original, address indexed replacement, address indexed sender);
    event IssuerSet(address indexed previousIssuer, address indexed newIssuer);
    event Issue(address indexed to, uint256 tokens);
    event IssueFinished();
    event ShareholderAdded(address shareholder);
    event ShareholderRemoved(address shareholder);

    // -------------------------------------------------------------------------

    /**
     *  @dev Transfers tokens to the whitelisted account.
     *
     *  If the &#39;to&#39; address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce &#39;msg.sender&#39; balance to 0, then that address MUST be removed
     *  from the list of shareholders.
     *  MUST be removed from the list of shareholders.
     *  @param to The address to transfer to.
     *  @param tokens The number of tokens to be transferred.
     */
    function transfer(address to, uint256 tokens)
    external
    isUnlocked
    isNotCancelled(to)
    hasFunds(msg.sender, tokens)
    returns (bool) {
        bool transferAllowed;

        // Issuance
        if (msg.sender == issuer) {
            transferAllowed = address(compliance) == ZERO_ADDRESS;
            if (!transferAllowed) {
                transferAllowed = compliance.canIssue(issuer, issuer, to, tokens);
            }
        }
        // Transfer
        else {
            transferAllowed = canTransfer(msg.sender, to, tokens, false);
        }

        // Ensure the transfer is allowed.
        if (transferAllowed) {
            transferTokens(msg.sender, to, tokens);
        }
        return transferAllowed;
    }

    /**
     *  @dev Transfers tokens between whitelisted accounts.
     *
     *  If the &#39;to&#39; address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce &#39;from&#39; balance to 0 then that address MUST be removed from the list of shareholders.
     *  @param from The address to transfer from
     *  @param to The address to transfer to.
     *  @param tokens uint256 the number of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 tokens)
    external
    isUnlocked
    isNotCancelled(to)
    hasFunds(from, tokens)
    returns (bool) {
        require(tokens <= allowed[from][msg.sender], "Transfer exceeds allowance");

        // Transfer the tokens
        bool transferAllowed = canTransfer(from, to, tokens, false);
        if (transferAllowed) {
            // Update the allowance to reflect the transfer
            allowed[from][msg.sender] = allowed[from][msg.sender].subtract(tokens);
            // Transfer the tokens
            transferTokens(from, to, tokens);
        }
        return transferAllowed;
    }

    /**
     *  @dev Overrides a transfer of tokens to the whitelisted account.
     *
     *  If the &#39;to&#39; address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce &#39;msg.sender&#39; balance to 0, then that address MUST be removed
     *  from the list of shareholders.
     *  MUST be removed from the list of shareholders.
     *  @param from The address to transfer from
     *  @param to The address to transfer to.
     *  @param tokens The number of tokens to be transferred.
     */
    function transferOverride(address from, address to, uint256 tokens)
    external
    isUnlocked
    isNotCancelled(to)
    hasFunds(from, tokens)
    returns (bool) {
        // Ensure the sender can perform the override.
        bool transferAllowed = canTransfer(from, to, tokens, true);
        // Ensure the transfer is allowed.
        if (transferAllowed) {
            transferTokens(from, to, tokens);
        }
        return transferAllowed;
    }

    /**
     *  @dev Tokens will be issued to the issuer&#39;s address only.
     *  @param quantity The number of tokens to mint.
     *  @return A boolean that indicates if the operation was successful.
     */
    function issueTokens(uint256 quantity)
    external
    isUnlocked
    onlyIssuer
    canIssue
    returns (bool) {
        // Avoid doing any state changes for zero quantities
        if (quantity > 0) {
            totalSupplyTokens = totalSupplyTokens.add(quantity);
            balances[issuer] = balances[issuer].add(quantity);
            shareholders.append(issuer);
        }
        emit Issue(issuer, quantity);
        emit Transfer(ZERO_ADDRESS, issuer, quantity);
        return true;
    }

    /**
     *  @dev Finishes token issuance.
     *  This is a single use function, once invoked it cannot be undone.
     */
    function finishIssuing()
    external
    isUnlocked
    onlyIssuer
    canIssue
    returns (bool) {
        issuingFinished = true;
        emit IssueFinished();
        return issuingFinished;
    }

    /**
     *  @dev Cancel the original address and reissue the Tokens to the replacement address.
     *
     *  Access to this function is restricted to the Issuer only.
     *  The &#39;original&#39; address MUST be removed from the set of whitelisted addresses.
     *  Throw if the &#39;original&#39; address supplied is not a shareholder.
     *  Throw if the &#39;replacement&#39; address is not a whitelisted address.
     *  This function MUST emit the &#39;VerifiedAddressSuperseded&#39; event.
     *  @param original The address to be superseded. This address MUST NOT be reused and must be whitelisted.
     *  @param replacement The address  that supersedes the original. This address MUST be whitelisted.
     */
    function cancelAndReissue(address original, address replacement)
    external
    isUnlocked
    onlyIssuer
    isNotCancelled(replacement) {
        // Ensure the reissue can take place
        require(shareholders.exists(original) && !shareholders.exists(replacement), "Original doesn&#39;t exist or replacement does");
        if (address(compliance) != ZERO_ADDRESS) {
            require(compliance.canIssue(msg.sender, original, replacement, balances[original]), "Failed &#39;canIssue&#39; check.");
        }

        // Replace the original shareholder with the replacement
        shareholders.remove(original);
        shareholders.append(replacement);
        // Add the original as a cancelled address (preventing it from future trading)
        cancellations[original] = replacement;
        // Transfer the balance to the replacement
        balances[replacement] = balances[original];
        balances[original] = 0;
        emit VerifiedAddressSuperseded(original, replacement, msg.sender);
    }

    /**
     * @dev Approve the passed address to spend the specified number of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param tokens The number of tokens of tokens to be spent.
     */
    function approve(address spender, uint256 tokens)
    external
    isUnlocked
    isNotCancelled(msg.sender)
    returns (bool) {
        require(shareholders.exists(msg.sender), "Must be a shareholder to approve token transfer");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /**
     *  @dev Set the issuer address.
     *  @param newIssuer The address of the issuer.
     */
    function setIssuer(address newIssuer)
    external
    isUnlocked
    onlyOwner {
        issuer = newIssuer;
        emit IssuerSet(issuer, newIssuer);
    }

    /**
     *  @dev Sets the compliance contract address to use during transfers.
     *  @param newComplianceAddress The address of the compliance contract.
     */
    function setCompliance(address newComplianceAddress)
    external
    isUnlocked
    onlyOwner {
        compliance = Compliance(newComplianceAddress);
    }

    // -------------------------------- Getters --------------------------------

    /**
     *  @dev Returns the total token supply
     *  @return total number of tokens in existence
     */
    function totalSupply()
    external
    view
    returns (uint256) {
        return totalSupplyTokens;
    }

    /**
     *  @dev Gets the balance of the specified address.
     *  @param addr The address to query the the balance of.
     *  @return An uint256 representing the tokens owned by the passed address.
     */
    function balanceOf(address addr)
    external
    view
    returns (uint256) {
        return balances[addr];
    }

    /**
     *  @dev Gets the number of tokens that an owner has allowed the spender to transfer.
     *  @param addrOwner address The address which owns the funds.
     *  @param spender address The address which will spend the funds.
     *  @return A uint256 specifying the number of tokens still available for the spender.
     */
    function allowance(address addrOwner, address spender)
    external
    view
    returns (uint256) {
        return allowed[addrOwner][spender];
    }

    /**
     *  By counting the number of token holders using &#39;holderCount&#39;
     *  you can retrieve the complete list of token holders, one at a time.
     *  It MUST throw if &#39;index >= holderCount()&#39;.
     *  @dev Returns the holder at the given index.
     *  @param index The zero-based index of the holder.
     *  @return the address of the token holder with the given index.
     */
    function holderAt(int256 index)
    external
    view
    returns (address){
        return shareholders.at(index);
    }

    /**
     *  @dev Checks to see if the supplied address is a share holder.
     *  @param addr The address to check.
     *  @return true if the supplied address owns a token.
     */
    function isHolder(address addr)
    external
    view
    returns (bool) {
        return shareholders.exists(addr);
    }

    /**
     *  @dev Checks to see if the supplied address was superseded.
     *  @param addr The address to check.
     *  @return true if the supplied address was superseded by another address.
     */
    function isSuperseded(address addr)
    external
    view
    returns (bool) {
        return cancellations[addr] != ZERO_ADDRESS;
    }

    /**
     *  Gets the most recent address, given a superseded one.
     *  Addresses may be superseded multiple times, so this function needs to
     *  follow the chain of addresses until it reaches the final, verified address.
     *  @param addr The superseded address.
     *  @return the verified address that ultimately holds the share.
     */
    function getSuperseded(address addr)
    external
    view
    returns (address) {
        require(addr != ZERO_ADDRESS, "Non-zero address required");

        address candidate = cancellations[addr];
        if (candidate == ZERO_ADDRESS) {
            return ZERO_ADDRESS;
        }
        return candidate;
    }


    // -------------------------------- Private --------------------------------

    /**
     *  @dev Checks if a transfer/override may take place between the two accounts.
     *
     *   Validates that the transfer can take place.
     *     - Ensure the &#39;to&#39; address is not cancelled
     *     - Ensure the transfer is compliant
     *  @param from The sender address.
     *  @param to The recipient address.
     *  @param tokens The number of tokens being transferred.
     *  @param isOverride If this is a transfer override
     *  @return If the transfer can take place.
     */
    function canTransfer(address from, address to, uint256 tokens, bool isOverride)
    private
    isNotCancelled(to)
    returns (bool) {
        // Don&#39;t allow overrides and ignore compliance rules when compliance not set.
        if (address(compliance) == ZERO_ADDRESS) {
            return !isOverride;
        }

        // Ensure the override is valid, or that the transfer is compliant.
        if (isOverride) {
            return compliance.canOverride(msg.sender, from, to, tokens);
        } else {
            return compliance.canTransfer(msg.sender, from, to, tokens);
        }
    }

    /**
     *  @dev Transfers tokens from one address to another
     *  @param from The sender address.
     *  @param to The recipient address.
     *  @param tokens The number of tokens being transferred.
     */
    function transferTokens(address from, address to, uint256 tokens)
    private {
        // Update balances
        balances[from] = balances[from].subtract(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);

        // Adds the shareholder if they don&#39;t already exist.
        if (balances[to] > 0 && shareholders.append(to)) {
            emit ShareholderAdded(to);
        }
        // Remove the shareholder if they no longer hold tokens.
        if (balances[from] == 0 && shareholders.remove(from)) {
            emit ShareholderRemoved(from);
        }
    }

}