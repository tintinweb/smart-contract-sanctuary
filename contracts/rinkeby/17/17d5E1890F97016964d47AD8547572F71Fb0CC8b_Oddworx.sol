// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

//import "https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol";
import "./solmateERC20.sol";

// DEBUGGING ONLY
//import "hardhat/console.sol";

error NotOwnerOfToken();
error InvalidInput();
error NoTokensToClaim();
error NftHoldRewardsNotActive();
error ContractIsPaused();
error NotAdmin();

/// @title Genzee NFTs
/// @notice Allows us to query owner of Genzee Nft
interface GenzeeContract {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external returns (bool);
}

/// @title Oddworx
/// @author Mytchall / Alephao
/// @notice General functions to mint, burn, reward NFT holders incl staking
contract Oddworx is ERC20 {

    GenzeeContract immutable public _genzeeContract;
    bool contractPaused = false;
    bool public NftHoldRewardsActive = true;
    uint256 public NFT_STAKING_WEEKLY_REWARD_AMOUNT = 20 * 10 ** 18; // Doesn't have to be public
    uint256 constant public NFT_HOLDING_WEEKLY_REWARD_AMOUNT = 10 * 10 ** 18;
    
    struct StakingData {
        address ownerAddress; // 160 bits
        uint96 timestamp; // 96 bits
    }

    mapping(address => bool) public adminAddresses;
    mapping(uint => StakingData) public stakedNft;
    
    constructor(address _nftContractAddress) ERC20("Oddworx", "ODDX", 18) {
        _mint(msg.sender, 1000000000 * 10 ** 18);
        _genzeeContract = GenzeeContract(_nftContractAddress);
        adminAddresses[msg.sender] = true;
    }

    /// @notice emitted when an item is purchased
    /// @param user address of the user that purchased an item
    /// @param itemSKU the SKU of the item purchased
    /// @param price the amount paid for the item
    event ItemPurchased(address indexed user, uint256 itemSKU, uint256 price);

    /// @notice emitted when a user stakes a token
    /// @param user address of the user that staked the Genzee
    /// @param genzeeId the id of the Genzee staked
    event StakedNft(address indexed user, uint256 indexed genzeeId);

    /// @notice emitted when a user unstakes a token
    /// @param user address of the user that unstaked the Genzee
    /// @param genzeeId the id of the Genzee unstaked
    event UnstakedNft(address indexed user, uint256 indexed genzeeId);

    /// @notice emitted when a user claim NFT rewards
    /// @param user address of the user that claimed ODDX
    /// @param amount the amount of ODDX claimed
    event UserClaimedNftRewards(address indexed user, uint256 amount);

    modifier onlyAdmin() {
        if (adminAddresses[msg.sender]  != true) revert NotAdmin();
        _;
    }

    modifier unpaused() {
        if (contractPaused == true) revert ContractIsPaused();
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

    function togglePaused() public onlyAdmin {
        contractPaused = !contractPaused;
    }

    function toggleAdminContract(address _adminAddress) public onlyAdmin {
         adminAddresses[_adminAddress] = !adminAddresses[_adminAddress];
    }

    /*///////////////////////////////////////////////////////////////
                             Shop features
    //////////////////////////////////////////////////////////////*/
    /// @notice Buy item in shop by burning Oddx.
    /// @param itemSKU A unique ID used to identify shop products.
    /// @param amount Amount of Oddx to burn.
    function buyItem(uint itemSKU, uint amount) public unpaused {
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
    function stakeNfts(uint256[] calldata genzeeIds) external unpaused {
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
    function unstakeNfts(uint256[] calldata genzeeIds) external unpaused {
        if (genzeeIds.length == 0) revert InvalidInput();
        uint256 genzeeId;
        uint256 nftRewardsOwing;
        StakingData memory stake;

        for (uint256 i; i < genzeeIds.length; i++) {
            genzeeId = genzeeIds[i];
            stake = stakedNft[genzeeId];
            if (stake.ownerAddress != msg.sender && stake.ownerAddress != address(0))  {
                revert NotOwnerOfToken();
            }

            nftRewardsOwing = calculateStakedNftRewards(genzeeId);
            heldNfts[genzeeId].timestamp = uint96(block.timestamp); // Reset timer for general staking rewards
            _genzeeContract.transferFrom(address(this), stake.ownerAddress, genzeeId);
            delete stakedNft[genzeeId];
            emit UnstakedNft(msg.sender, genzeeId);
        }
        if (nftRewardsOwing>0) {
            emit UserClaimedNftRewards(msg.sender, nftRewardsOwing);
            _mint(msg.sender, nftRewardsOwing);
        }
    }

    /// @notice Claim Staked NFT rewards in ODDX. Also resets general holding
    /// timestamp so users can't double-claim for holding/staking.
    /// @param _nftIDs list of genzee ids to claim rewards for.
    function claimStakedNftRewards(uint256[] memory _nftIDs) public unpaused {
        uint addedNftRewards;

        for (uint256 i; i < _nftIDs.length; i++) {
            if (stakedNft[_nftIDs[i]].ownerAddress != msg.sender) revert NotOwnerOfToken();
            addedNftRewards += calculateStakedNftRewards(_nftIDs[i]);
            stakedNft[_nftIDs[i]].timestamp = uint96(block.timestamp);
        }
        if (addedNftRewards < 1) revert NoTokensToClaim();
        //return rewards; // only for testing purposes, otherwise mint // Will need returns (uint)
        //console.log("minting tokens to: ", _nftIDs[0]].ownerAddress);
        emit UserClaimedNftRewards(msg.sender, addedNftRewards);
        _mint(stakedNft[_nftIDs[0]].ownerAddress, addedNftRewards);
    }

    /// @notice Calculate staking rewards owed per week.
    /// @param _nftId NFT id to check.
    /// @return Returns amount of tokens available to claim
    function calculateStakedNftRewards(uint _nftId) public view returns (uint256) {
        uint256 timestamp = stakedNft[_nftId].timestamp;
        return (timestamp > 0)  ? NFT_STAKING_WEEKLY_REWARD_AMOUNT * ((block.timestamp - timestamp) / 604800) : 0;
    }

    /// @notice Updates amount users are rewarded weekly.
    /// @param newAmount new amount to use, supply number in wei.
    function updateNftStakedRewardAmount(uint256 newAmount) external onlyAdmin {
        NFT_STAKING_WEEKLY_REWARD_AMOUNT = newAmount;
    }


    /*///////////////////////////////////////////////////////////////
                             NFT Holding Rewards
    //////////////////////////////////////////////////////////////*/
    struct NftHoldingData {
        address ownerAddress; // 160 bits
        uint96 timestamp; // 96 bits
    }
    
    mapping(uint256 => NftHoldingData) public heldNfts;

    /// @notice Claim rewards for NFT if we are the holder. 
    /// Rewards are attached to the NFT, so if it's transferred, new owner can claim tokens
    /// But the intital rewards can't be reclaimed
    /// @param genzeeIds list of genzee ids to stake.
    function claimNftHoldRewards(uint256[] calldata genzeeIds) public unpaused {
        if (!NftHoldRewardsActive) revert NftHoldRewardsNotActive();

        uint256 addedNftRewards;
        uint256 genzeeId;
        address ownerAddress;

        for (uint256 i; i < genzeeIds.length; i++) {
            genzeeId = genzeeIds[i];
            if (_genzeeContract.ownerOf(genzeeId) != msg.sender) revert NotOwnerOfToken();
            ownerAddress = heldNfts[genzeeId].ownerAddress;

            if ((ownerAddress != address(0)) && (ownerAddress != msg.sender)) {
                heldNfts[genzeeId] = NftHoldingData(msg.sender, uint96(block.timestamp));
            }

            addedNftRewards += calculateNftHoldReward(genzeeId);
            heldNfts[genzeeId].timestamp = uint96(block.timestamp);
        }

        if (addedNftRewards < 1) revert NoTokensToClaim();
        emit UserClaimedNftRewards(msg.sender, addedNftRewards);
        _mint(msg.sender, addedNftRewards);
    }

    function calculateNftHoldReward(uint256 _nftIndex) public view returns (uint256)  {
        uint256 timestamp = heldNfts[_nftIndex].timestamp;
        return (timestamp > 0) ? NFT_HOLDING_WEEKLY_REWARD_AMOUNT * ((block.timestamp - timestamp) / 1 weeks) : NFT_HOLDING_WEEKLY_REWARD_AMOUNT;
    }

    function toggleNftHoldRewards() external onlyAdmin {
        NftHoldRewardsActive = !NftHoldRewardsActive;
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
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
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

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
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

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
                    keccak256(bytes("1")),
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