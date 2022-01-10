// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {IGenzee} from "./IGenzee.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

error NotOwnerOfToken();
error InvalidInput();
error NoTokensToClaim();
error NftHoldRewardsNotActive();
error NotAdmin();

/// @title Oddworx
/// @author Mytchall / Alephao
/// @notice General functions to mint, burn, reward NFT holders incl staking
contract Oddworx is ERC20, Pausable {

    IGenzee immutable public _genzeeContract;
    bool public nftHoldRewardsActive = true;
    uint256 public NFT_STAKING_WEEKLY_REWARD_AMOUNT = 20 * 10 ** 18; // Doesn't have to be public
    uint256 constant public NFT_HOLDING_WEEKLY_REWARD_AMOUNT = 10 * 10 ** 18;
    
    struct StakingData {
        address ownerAddress; // 160 bits
        uint96 timestamp; // 96 bits
    }

    mapping(address => bool) public adminAddresses;
    mapping(uint256 => StakingData) public stakedNft;
    mapping(uint256 => uint256) public latestUnstakedClaimTimestamp;
    
    constructor(address _nftContractAddress) ERC20("Oddworx", "ODDX", 18) {
        _mint(msg.sender, 1000000000 * 10 ** 18);
        _genzeeContract = IGenzee(_nftContractAddress);
        adminAddresses[msg.sender] = true;
    }

    /// @notice emitted when an item is purchased
    /// @param user address of the user that purchased an item
    /// @param itemSKU the SKU of the item purchased
    /// @param price the amount paid for the item
    event ItemPurchased(address indexed user, uint256 itemSKU, uint256 price);

    /// @notice emitted when a user stakes a token
    /// @param user address of the user that staked the Genzee
    /// @param genzee the id of the Genzee staked
    event StakedNft(address indexed user, uint256 indexed genzee);

    /// @notice emitted when a user unstakes a token
    /// @param user address of the user that unstaked the Genzee
    /// @param genzee the id of the Genzee unstaked
    /// @param amount the amount of ODDX claimed
    event UnstakedNft(address indexed user, uint256 indexed genzee, uint256 amount);

    /// @notice emitted when a user claim NFT rewards
    /// @param user address of the user that claimed ODDX
    /// @param genzee the id of the Genzee that generated the rewards
    /// @param amount the amount of ODDX claimed
    event UserClaimedNftRewards(address indexed user, uint256 indexed genzee, uint256 amount);

    modifier onlyAdmin() {
        if (adminAddresses[msg.sender]  != true) revert NotAdmin();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                             General Functions
    //////////////////////////////////////////////////////////////*/
    function mint(address to, uint256 amount) public onlyAdmin {
        _mint(to, amount);
    }

    function burn(address _from, uint256 amount) public onlyAdmin {
        if (balanceOf[_from] < amount) revert InvalidInput();
        _burn(_from, amount);
    }

    function toggleAdminContract(address _adminAddress) public onlyAdmin {
         adminAddresses[_adminAddress] = !adminAddresses[_adminAddress];
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    /*///////////////////////////////////////////////////////////////
                             Shop features
    //////////////////////////////////////////////////////////////*/
    /// @notice Buy item in shop by burning Oddx.
    /// @param itemSKU A unique ID used to identify shop products.
    /// @param amount Amount of Oddx to burn.
    function buyItem(uint itemSKU, uint amount) public whenNotPaused {
        if (balanceOf[msg.sender] < amount) revert InvalidInput();
        _burn(msg.sender, amount);
        emit ItemPurchased(msg.sender, itemSKU, amount);
    }

    /*///////////////////////////////////////////////////////////////
                             NFT Staking Rewards
    //////////////////////////////////////////////////////////////*/
    /// @notice stake genzees in this contract. 
    /// The Genzee owners need to approve this contract for transfering
    /// before calling this function.
    /// @param genzeeIds list of genzee ids to stake.
    function stakeNfts(uint256[] calldata genzeeIds) external whenNotPaused {
        if (genzeeIds.length == 0) revert InvalidInput();
        uint256 genzeeId;
        for (uint256 i; i < genzeeIds.length; i++) {
            genzeeId = genzeeIds[i];
            // No need to check ownership since transferFrom already checks that
            // and the caller of this function should be the Genzee owner
            stakedNft[genzeeId] = StakingData(msg.sender, uint96(block.timestamp));
            _genzeeContract.transferFrom(msg.sender, address(this), genzeeId);
            emit StakedNft(msg.sender, genzeeId);
        }
    }

    /// @notice unstake genzees back to they rightful owners and pay them what it's owed in ODDX.
    /// @param genzeeIds list of genzee ids to unstake.
    function unstakeNfts(uint256[] calldata genzeeIds) external whenNotPaused {
        if (genzeeIds.length == 0) revert InvalidInput();

        // total rewards amount to claim (all genzees)
        uint256 totalRewards;

        // loop variables

        // rewards for current genzee in the loop below
        uint256 rewards;

        // current genzeeid in the loop below
        uint256 genzeeId;

        // staking information for the current genzee in the loop below
        StakingData memory stake;

        for (uint256 i; i < genzeeIds.length; i++) {
            genzeeId = genzeeIds[i];
            stake = stakedNft[genzeeId];

            if (stake.ownerAddress != msg.sender && stake.ownerAddress != address(0))  {
                revert NotOwnerOfToken();
            }

            rewards = _stakedRewardsForTimestamp(genzeeId);
            totalRewards += rewards;

            // Reset timestamp for unstaked rewards
            latestUnstakedClaimTimestamp[genzeeId] = block.timestamp;

            // No need to run safeTransferFrom because we're returning the NFT to
            // an address that was holding it before
            _genzeeContract.transferFrom(address(this), stake.ownerAddress, genzeeId);

            delete stakedNft[genzeeId];

            emit UnstakedNft(msg.sender, genzeeId, rewards);
        }

        if (totalRewards > 0) {
            _mint(msg.sender, totalRewards);
        }
    }

    /// @notice Claim Staked NFT rewards in ODDX. Also resets general holding
    /// timestamp so users can't double-claim for holding/staking.
    /// @param genzeeIds list of genzee ids to claim rewards for.
    function claimStakedNftRewards(uint256[] calldata genzeeIds) external whenNotPaused {
        if (genzeeIds.length == 0) revert InvalidInput();

        // total rewards amount to claim (all genzees)
        uint256 totalRewards;

        // loop variables

        // rewards for current genzee in the loop below
        uint256 rewards;

        // current genzeeid in the loop below
        uint256 genzeeId;

        // staking information for the current genzee in the loop below
        StakingData memory stake;

        for (uint256 i; i < genzeeIds.length; i++) {
            genzeeId = genzeeIds[i];
            stake = stakedNft[genzeeId];

            if (stake.ownerAddress != msg.sender) revert NotOwnerOfToken();

            rewards = _stakedRewardsForTimestamp(stake.timestamp);
            totalRewards += rewards;

            stakedNft[genzeeId].timestamp = uint96(block.timestamp);

            emit UserClaimedNftRewards(msg.sender, genzeeId, rewards);
        }

        if (totalRewards == 0) revert NoTokensToClaim();
        _mint(msg.sender, totalRewards);
    }

    /// @notice Calculate staking rewards owed per week.
    /// @param genzeeId NFT id to check.
    /// @return Returns amount of tokens available to claim
    function calculateStakedNftRewards(uint256 genzeeId) external view returns (uint256) {
        uint256 timestamp = stakedNft[genzeeId].timestamp;
        return _stakedRewardsForTimestamp(timestamp);
    }

    function _stakedRewardsForTimestamp(uint256 timestamp) private view returns (uint256) {
        return timestamp > 0
            ? NFT_STAKING_WEEKLY_REWARD_AMOUNT * ((block.timestamp - timestamp) / 1 weeks)
            : 0;
    }

    /// @notice Updates amount users are rewarded weekly.
    /// @param newAmount new amount to use, supply number in wei.
    function updateNftStakedRewardAmount(uint256 newAmount) external onlyAdmin {
        NFT_STAKING_WEEKLY_REWARD_AMOUNT = newAmount;
    }


    /*///////////////////////////////////////////////////////////////
                             NFT Holding Rewards
    //////////////////////////////////////////////////////////////*/
    /// @notice Claim rewards for NFT if we are the holder. 
    /// Rewards are attached to the NFT, so if it's transferred, new owner can claim tokens
    /// But the intital rewards can't be reclaimed
    /// @param genzeeIds list of genzee ids to stake.
    function claimNftHoldRewards(uint256[] calldata genzeeIds) external whenNotPaused {
        if (!nftHoldRewardsActive) revert NftHoldRewardsNotActive();
        if (genzeeIds.length == 0) revert InvalidInput();

        // total rewards amount to claim (all genzees)
        uint256 totalRewards;

        // loop variables

        // rewards for current genzee in the loop below
        uint256 rewards;

        // current genzeeid in the loop below
        uint256 genzeeId;

        // last time owner claimed rewards for the genzee
        uint256 latestClaimTimestamp;

        for (uint256 i; i < genzeeIds.length; i++) {
            genzeeId = genzeeIds[i];
            if (_genzeeContract.ownerOf(genzeeId) != msg.sender) revert NotOwnerOfToken();
            latestClaimTimestamp = latestUnstakedClaimTimestamp[genzeeId];

            rewards = _unstakedRewardsForTimestamp(latestClaimTimestamp);
            totalRewards += rewards;

            // Set claim timestamp to now
            latestUnstakedClaimTimestamp[genzeeId] = block.timestamp;

            emit UserClaimedNftRewards(msg.sender, genzeeId, rewards);
        }

        if (totalRewards == 0) revert NoTokensToClaim();
        _mint(msg.sender, totalRewards);
    }

    function calculateNftHoldReward(uint256 _nftIndex) external view returns (uint256)  {
        uint256 timestamp = latestUnstakedClaimTimestamp[_nftIndex];
        return _unstakedRewardsForTimestamp(timestamp);
    }

    function _unstakedRewardsForTimestamp(uint256 timestamp) private view returns (uint256) {
        return (timestamp > 0)
            ? NFT_HOLDING_WEEKLY_REWARD_AMOUNT * ((block.timestamp - timestamp) / 1 weeks)
            : NFT_HOLDING_WEEKLY_REWARD_AMOUNT;
    }

    function toggleNftHoldRewards() external onlyAdmin {
        nftHoldRewardsActive = !nftHoldRewardsActive;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

interface IGenzee {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}