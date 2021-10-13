// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

interface IToken {
    function mint(address _receiver, uint256 _amount) external;
    function burn(address _receiver, uint256 _amount) external;
}

/// @notice Contract that defines GRO DAOs' tokenomics - Contracts set below
///     are allowed to mint tokens based on predefined quotas. This contract is
///     intrinsically tied to the GRO Dao token, and is the only contract that is
///     allowed to mint and burn tokens.
contract GRODistributer {
    // Limits for token minting
    uint256 public constant DEFAULT_FACTOR = 1E18;
    // Amount dedicated to the dao (13M - 5M)
    uint256 public constant DAO_QUOTA = 8_000_000 * DEFAULT_FACTOR;
    // Amount dedicated to the investor group
    uint256 public constant INVESTOR_QUOTA = 19_490_577 * DEFAULT_FACTOR;
    // Amount dedicated to the team
    uint256 public constant TEAM_QUOTA = 22_509_423 * DEFAULT_FACTOR;
    // Amount dedicated to the community
    uint256 public constant COMMUNITY_QUOTA = 45_000_000 * DEFAULT_FACTOR;

    IToken public immutable govToken;
    // contracts that are allowed to mint
    address public immutable DAO_VESTER;
    address public immutable INVESTOR_VESTER;
    address public immutable TEAM_VESTER;
    address public immutable COMMUNITY_VESTER;
    // contract that is allowed to burn
    address public immutable BURNER;

    // pool with minting limits for above contracts
    mapping(address => uint256) public mintingPools;

    constructor(address token, address[4] memory vesters, address burner) {
        // set token
        govToken = IToken(token);
        
        // set vesters
        DAO_VESTER = vesters[0];
        INVESTOR_VESTER = vesters[1];
        TEAM_VESTER = vesters[2];
        COMMUNITY_VESTER = vesters[3];
        BURNER = burner;
        
        // set quotas for each vester
        mintingPools[vesters[0]] = DAO_QUOTA;
        mintingPools[vesters[1]] = INVESTOR_QUOTA;
        mintingPools[vesters[2]] = TEAM_QUOTA;
        mintingPools[vesters[3]] = COMMUNITY_QUOTA;
    }

    /// @notice mint tokens - Reduces total allowance for minting pool
    /// @param account account to mint for
    /// @param amount amount to mint
    function mint(address account, uint256 amount) external {
        require(
            msg.sender == INVESTOR_VESTER ||
            msg.sender == TEAM_VESTER ||
            msg.sender == COMMUNITY_VESTER,
            'mint: msg.sender != vester'
        );
        uint256 available = mintingPools[msg.sender];
        mintingPools[msg.sender] = available - amount;
        govToken.mint(account, amount);
    }

    /// @notice mintDao seperate minting function for dao vester - can mint from both
    ///      community and dao quota
    /// @param account account to mint for
    /// @param amount amount to mint
    /// @param community If the vest comes from the community or dao quota
    function mintDao(
        address account,
        uint256 amount,
        bool community
    ) external {
        require(msg.sender == DAO_VESTER, "mintDao: msg.sender != DAO_VESTER");
        address poolId = msg.sender;
        if (community) {
            poolId = COMMUNITY_VESTER;
        }
        uint256 available = mintingPools[poolId];
        mintingPools[poolId] = available - amount;
        govToken.mint(account, amount);
    }

    /// @notice burn tokens - adds allowance to community pool
    /// @param amount amount to burn
    /// @dev Burned tokens should get add to users vesting position and
    ///  add to the community quota.
    function burn(uint256 amount) external {
        require(msg.sender == BURNER, "burn: msg.sender != BURNER");
        govToken.burn(msg.sender, amount);
        mintingPools[COMMUNITY_VESTER] = mintingPools[COMMUNITY_VESTER] + amount;
    }
}