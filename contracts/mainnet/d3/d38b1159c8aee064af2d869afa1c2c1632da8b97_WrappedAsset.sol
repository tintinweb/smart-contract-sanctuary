// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./erc1363.sol";
import "./pausable.sol";
import "./managable.sol";
import "./vendorregistry.sol";
import "./imigratablewrappedasset.sol";
import "./imigratablevendorregistry.sol";



/// An ERC1363 (also ERC20) for wrapping MRX on the ethereum or BSC chain.
/// @title  WrappedAsset
/// @author loma oopaloopa
contract WrappedAsset is ERC1363, Pausable, Managable, IMigratableWrappedAsset
    {
    address                  public  prevVendorRegistry      = address(0);
    address                  public  prevWrappedAsset        = address(0);
    address                  public  nextWrappedAsset        = address(0);

    uint256 immutable        private maxSupply;
    uint256                  private snapshotIntervalSeconds;
    uint256                  private snapshotId              = 0;
    uint256                  private snapshotBlockTimestamp  = 0;
    mapping(bytes32 => bool) private usedNonces;
    address                  private registryAddr            = address(0);
    VendorRegistry           private registry;

    /// Emitted whenever a new snapshot is stored.
    /// @param blockTimestamp The timestamp of the first block after the snapshot.
    /// @param blockNumber    The block number of the first block after the snapshot.
    /// @param snapshotId     The new current snapshot ID after the snapshot.
    event SnapshotInfo(uint256 indexed blockTimestamp, uint256 indexed blockNumber, uint256 indexed snapshotId);

    /// Deploy a new WrappedAsset contract, never called directly -- only from VendorRegistry's constructor.
    /// @param tokenName                  The name for the token (returned by name()).
    /// @param tokenSymbol                The symbol for the token (returned by symbol()).
    /// @param tokenCap                   The cap or maximum amount of tokens allowed in satoshi.
    /// @param tokenSnapshotIntervalHours The initial time in hours between automatic snapshots.
    constructor(string memory tokenName, string memory tokenSymbol, uint256 tokenCap, uint256 tokenSnapshotIntervalHours) ERC20(tokenName, tokenSymbol) Ownable() Pausable()
        {
        require(tokenCap > 0, "WrappedAsset: The maxSupply is 0, it must be > 0.");
        require(tokenSnapshotIntervalHours > 0, "WrappedAsset: The time between snapshots can't be 0, it must be at least 1 hour.");
        maxSupply = tokenCap;
        snapshotIntervalSeconds = 60*60*tokenSnapshotIntervalHours;
        }

    /// An owner only method to change the VendorRegistry this WrappedAsset is associated with, use VendorRegistry.setWrappedAsset() to make the required reciprical change on VendorRegistry.
    /// @param vendorRegistryAddress The address of the new VendorRegistry contract to pair with.
    function setVendorRegistry(address vendorRegistryAddress) public isOwner
        {
        registryAddr = vendorRegistryAddress;
        registry = VendorRegistry(vendorRegistryAddress);
        }

    /// Get the address of this WrappedAsset's VendorRegistry.
    /// @return The VendorRegistry contract's address.
    function getVendorRegistry() public view returns (address)
        {
        return registryAddr;
        }

    /// An owner only method to set the origin VendorRegistry & WrappedAsset from which the public method migrateFromPreviousVersion() will transfer registrations and funds to this WrappedAsset and it's VendorRegistry.
    /// Call setNextVersion() on the previous WrappedAsset first.
    /// @param vendorRegistry The address of the origin VendorRegistry from which registrations will be transfered to this WrappedAsset's VendorRegistry by migrateFromPreviousVersion().
    /// @param wrappedAsset   The address of the origin WrappedAsset from which funds will be transfered to this WrappedAsset by migrateFromPreviousVersion().
    function setPrevVersion(address vendorRegistry, address wrappedAsset) public isOwner
        {
        require(vendorRegistry != address(0), "WrappedAsset: The address of the previous VendorRegistry can't be 0.");
        require(wrappedAsset != address(0), "WrappedAsset: The address of the previous WrappedAsset can't be 0.");
        require(prevVendorRegistry == address(0), "WrappedAsset: The previous version has already been set.");
        prevVendorRegistry = vendorRegistry;
        prevWrappedAsset = wrappedAsset;
        }

    /// An owner only method to set the address of the next version of WrappedAsset which is allowed to migrate funds and registrations out of this WrappedAsset and it's VendorRegistry.
    /// After calling this call setPrevVersion() on the next WrappedAsset to enable migration.
    /// @param wrappedAsset The address of the WrappedAsset to which funds may be migrated (I.E. the WrappedAsset allowed to call migrationBurn()).
    function setNextVersion(address wrappedAsset) public isOwner
        {
        require(wrappedAsset != address(0), "WrappedAsset: The address of the next WrappedAsset can't be 0.");
        require(nextWrappedAsset == address(0), "WrappedAsset: The next version has already been set.");
        nextWrappedAsset = wrappedAsset;
        }

    /// @inheritdoc ERC20
    function name() public view virtual override returns (string memory)
        {
        return super.name();
        }

    /// @inheritdoc ERC20
    function symbol() public view virtual override returns (string memory)
        {
        return super.symbol();
        }

    /// @inheritdoc ERC20
    function decimals() public pure virtual override returns (uint8)
        {
        return 8;
        }

    /// Get the maximum amount of tokens allowed in satoshi.
    /// @return The maximum amount of tokens allowed in satoshi.
    function cap() public view returns (uint256)
        {
        return maxSupply;
        }

    /// Get the maximum amount of tokens in satoshi that can currently be minted without exceeding the maximum supply.
    /// @return The number of satoshi available before reaching the maximum supply.
    function unusedSupply() public view virtual returns (uint256)
        {
        return maxSupply - totalSupply();
        }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual override returns (uint256)
        {
        return super.totalSupply();
        }

    /// Get the amount of wrapped MRX in the caller's account in satoshi.
    /// @return The caller's balance in satoshi.
    function balance() public view virtual returns (uint256)
        {
        return super.balanceOf(_msgSender());
        }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual override returns (uint256)
        {
        return super.balanceOf(account);
        }

    /// @inheritdoc IERC20
    function transfer(address recipient, uint256 amount) public virtual override returns (bool)
        {
        return super.transfer(recipient, amount);
        }

    /// Move the caller's funds and, if necessary, their registration from the previous WrappedAsset & VendorRegistry (as set with setPrevVersion()) to this WrappedAsset and ir's VendorRegistry.
    /// This is the method members of the public use to move to an upgraded WrappedAsset & VendorRegistry.
    function migrateFromPreviousVersion() public
        {
        require(prevVendorRegistry != address(0), "WrappedAsset: Migration failed because the previous version has not been set.");
        IMigratableVendorRegistry prevVr = IMigratableVendorRegistry(prevVendorRegistry);
        address mrxAddress = prevVr.findMrxFromVendor(_msgSender());
        require(mrxAddress != address(0), "WrappedAsset: Migration failed because the caller is not registered with the previous version.");
        if (registry.findMrxFromVendor(_msgSender()) == address(0)) registry.migrateVendorRegistration(mrxAddress, _msgSender());
        IMigratableWrappedAsset prevWa = IMigratableWrappedAsset(prevWrappedAsset);
        uint256 amount = prevWa.migrationBurn(_msgSender(), unusedSupply());
        _mint(_msgSender(), amount);
        }

    /// A pausable method by which a member of the public can add an amount of wrapped MRX to their account 1 time only, and only with permission in the form of a nonce and a signature.
    /// @param amount    The amount of wrapped MRX to add to the caller's account in satoshi.
    /// @param nonce     A 1 time use only large number forever uniquely identifying this permission to mint.
    /// @param signature A manager of this contract's signature on a premission to mint message.
    function vendorMint(uint256 amount, bytes32 nonce, bytes memory signature) public whenNotPaused
        {
        require(totalSupply() + amount <= maxSupply, "WrappedAsset: Mint failed, it would exceed the cap.");
        require(registry.findMrxFromVendor(msg.sender) != address(0), "WrappedAsset: Mint failed, the caller's address has not been registered as a vendor.");
        require(!usedNonces[nonce], "WrappedAsset: Mint failed, this mint has been used before.");
        usedNonces[nonce] = true;
        bytes memory message = abi.encodePacked(msg.sender, amount, address(this), nonce);
        require(addressIsAManager(recoverSigner(message, signature)), "WrappedAsset: Mint failed, invalid signature.");
        _mint(_msgSender(), amount);
        }

    /// Check whether or not the vendor mint identifed by the nonce has happened.
    /// @return True if the mint has happened, and false otherwise.
    function mintRedeemed(bytes32 nonce) public view returns (bool)
        {
        return usedNonces[nonce];
        }

    /// A manager only method to mint wrapped MRX into the manager's account without needing any permission.
    /// @param amount The amount of wrapped MRX to add to the manager's account in satoshi.
    function mint(uint256 amount) public isManager virtual
        {
        require(totalSupply() + amount <= maxSupply, "WrappedAsset: Mint failed, it would exceed the cap.");
        _mint(_msgSender(), amount);
        }

    /// Deduct the given amount from the caller's account.
    /// @param amount The amount to be deducted from the caller's account in satoshi.
    function burn(uint256 amount) public virtual
        {
        require(registry.findMrxFromVendor(_msgSender()) != address(0), "WrappedAsset: Burn failed, the caller's address has not been registered as a vendor.");
        _burn(_msgSender(), amount);
        }

    /// @inheritdoc IMigratableWrappedAsset
    function migrationBurn(address account, uint256 maxAmount) external override returns (uint256)
        {
        require(address(0) != nextWrappedAsset, "WrappedAsset: Migration failed because the next version has not been set.");
        require(_msgSender() == nextWrappedAsset, "WrappedAsset: Access not permitted.");
        require(registry.findMrxFromVendor(account) != address(0), "WrappedAsset: Migration failed, the caller's address has not been registered as a vendor.");
        uint256 amount = balanceOf(account);
        if (amount > maxAmount) amount = maxAmount;
        _burn(account, amount);
        return amount;
        }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual override returns (uint256)
        {
        return super.allowance(owner, spender);
        }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) public virtual override returns (bool)
        {
        return super.approve(spender, amount);
        }

    /// @inheritdoc IERC20
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool)
        {
        return super.transferFrom(sender, recipient, amount);
        }

    /// @inheritdoc ERC20
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool)
        {
        return super.increaseAllowance(spender, addedValue);
        }

    /// @inheritdoc ERC20
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool)
        {
        return super.decreaseAllowance(spender, subtractedValue);
        }

    /// Pause the process of vendor minting with vendorMint().
    function pause() public isManager virtual
        {
        _pause();
        }

    /// Restart the process of vendor minting with vendorMint().
    function unpause() public isManager virtual
        {
        _unpause();
        }
    /// Check whether or not the process of vendor minting with vendorMint() is currently paused.
    /// @return True if the process of vendor minting with vendorMint() is currently paused, otherwise false.
    function paused() public view virtual override returns (bool)
        {
        return super.paused();
        }

    /// Get the balance of account at the time snapshotId was created.
    /// @param  account The account for which to get the balance at the time snapshotId was created.
    /// @param  snapId  The id of the snapshot.
    /// @return The amount of wrapped MRX in the account in satoshi. 
    function balanceOfAt(address account, uint256 snapId) public view virtual override returns (uint256)
        {
        return super.balanceOfAt(account, snapId);
        }

    /// Get the total supply at the time snapshotId was created.
    /// @param  snapId The snapshot id.
    /// @return The total supply at the time snapshotId was created in satoshi.
    function totalSupplyAt(uint256 snapId) public view virtual override returns(uint256)
        {
        return super.totalSupplyAt(snapId);
        }

    /// Get the current snapshot id.
    /// @return The current snapshot id.
    function getCurrentSnapshotId() public view virtual returns (uint256)
        {
        return _getCurrentSnapshotId();
        }

    /// Take a snapshot.
    /// @return The new current snapshot id after the snapshot.
    function takeSnapshot() public isManager virtual returns (uint256)
        {
        nextSnapshotId(block.timestamp);
        return _getCurrentSnapshotId();
        }

    /// Set the interval in hours between automatic snapshots.
    /// @param snapshotIntervalHours The new interval in hours between automatic snapshots.
    function setSnapshotIntervalHours(uint256 snapshotIntervalHours) public isManager virtual
        {
        require(snapshotIntervalHours > 0, "WrappedAsset: The time between snapshots can't be 0, it must be at least 1 hour.");
        snapshotIntervalSeconds = 60*60*snapshotIntervalHours;
        }

    /// Get the current interval in hours between automatic snapshots.
    /// @return The current interval in hours between automatic snapshots.
    function getSnapshotIntervalHours() public view virtual returns (uint256)
        {
        return snapshotIntervalSeconds/(60*60);
        }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override
        {
        uint256 timestamp = block.timestamp;
        if (timestamp > snapshotBlockTimestamp + snapshotIntervalSeconds) nextSnapshotId(timestamp);
        super._beforeTokenTransfer(from, to, amount);
        }

    function nextSnapshotId(uint256 blockTimestamp) private
        {
        snapshotId++;
        snapshotBlockTimestamp = blockTimestamp;
        emit SnapshotInfo(blockTimestamp, block.number, snapshotId);
        }

    function _getCurrentSnapshotId() internal view virtual override returns (uint256)
        {
        return snapshotId;
        }

    function recoverSigner(bytes memory message, bytes memory signature) internal pure returns (address)
        {
        require(signature.length == 65, "WrappedAsset: Action failed, invalid signature.");
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly
            {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
            }
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message))), v, r, s);
        }
    }