/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Access control contract.
/// @author Adapted from https://github.com/sushiswap/trident/blob/master/contracts/utils/TridentOwnable.sol.
abstract contract LexOwnable {
    address public owner;
    address public pendingOwner;

    event TransferOwner(address indexed sender, address indexed recipient);
    event TransferOwnerClaim(address indexed sender, address indexed recipient);

    /// @notice Initialize and grant deployer account (`msg.sender`) `owner` access role.
    constructor() {
        owner = msg.sender;
        emit TransferOwner(address(0), msg.sender);
    }

    /// @notice Access control modifier that conditions modified function to be called by `owner` account.
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    /// @notice `pendingOwner` can claim `owner` account.
    function claimOwner() external {
        require(msg.sender == pendingOwner, "NOT_PENDING_OWNER");
        emit TransferOwner(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /// @notice Transfer `owner` account.
    /// @param recipient Account granted `owner` access control.
    /// @param direct If 'true', ownership is directly transferred.
    function transferOwner(address recipient, bool direct) external onlyOwner {
        require(recipient != address(0), "ZERO_ADDRESS");
        if (direct) {
            owner = recipient;
            emit TransferOwner(msg.sender, recipient);
        } else {
            pendingOwner = recipient;
            emit TransferOwnerClaim(msg.sender, recipient);
        }
    }
}

/// @notice Function pausing contract.
abstract contract LexPausable is LexOwnable {
    event SetPause(bool indexed paused);
    
    bool public paused;
    
    /// @notice Initialize contract with `paused` status.
    constructor(bool _paused) {
        paused = _paused;
        emit SetPause(_paused);
    }
    
    /// @notice Function pausability modifier.
    modifier notPaused() {
        require(!paused, "PAUSED");
        _;
    }
    
    /// @notice Sets function pausing status.
    /// @param _paused If 'true', modified functions are paused.
    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
        emit SetPause(_paused);
    }
}

/// @notice Function whitelisting contract.
abstract contract LexWhitelistable is LexOwnable {
    event ToggleWhiteList(bool indexed whitelistEnabled);
    event UpdateWhitelist(address indexed account, bool indexed whitelisted);
    
    bool public whitelistEnabled; 
    mapping(address => bool) public whitelisted; 
    
    /// @notice Initialize contract with `whitelistEnabled` status.
    constructor(bool _whitelistEnabled) {
        whitelistEnabled = _whitelistEnabled;
        emit ToggleWhiteList(_whitelistEnabled);
    }
    
    /// @notice Whitelisting modifier that conditions modified function to be called between `whitelisted` accounts.
    modifier onlyWhitelisted(address from, address to) {
        if (whitelistEnabled) 
        require(whitelisted[from] && whitelisted[to], "NOT_WHITELISTED");
        _;
    }
    
    /// @notice Update account `whitelisted` status.
    /// @param account Account to update.
    /// @param _whitelisted If 'true', `account` is `whitelisted`.
    function updateWhitelist(address account, bool _whitelisted) external onlyOwner {
        whitelisted[account] = _whitelisted;
        emit UpdateWhitelist(account, _whitelisted);
    }
    
    /// @notice Toggle `whitelisted` conditions on/off.
    /// @param _whitelistEnabled If 'true', `whitelisted` conditions are on.
    function toggleWhitelist(bool _whitelistEnabled) external onlyOwner {
        whitelistEnabled = _whitelistEnabled;
        emit ToggleWhiteList(_whitelistEnabled);
    }
}

contract LexTimeRestricted {
    uint immutable public timeRestrictionEnds; 
    
    /// @notice deploy `TimeRestricted` contract.
    /// @param _timeRestrictionEnds Unix time for restriction to lift.
    constructor(uint _timeRestrictionEnds) {
        timeRestrictionEnds = _timeRestrictionEnds;  
    }
    
    /// @notice Requires modified function to be called *at* `timeRestrictionEnds` in unix time or after.
    modifier timeRestricted { 
        require(block.timestamp >= timeRestrictionEnds, 'TimeRestricted:!time');
        _;
    }
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Adapted from RariCapital, https://github.com/Rari-Capital/solmate/blob/main/src/erc20/ERC20.sol,
/// License-Identifier: AGPL-3.0-only.
contract LexToken is LexOwnable, LexPausable, LexWhitelistable, LexTimeRestricted {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name;
    string public symbol;

    uint8 public immutable decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supply
    ) LexPausable(false) LexWhitelistable(true) LexTimeRestricted(1693711645) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function approve(address spender, uint256 value) public virtual returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        balanceOf[msg.sender] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

        return true;
    }

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

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

        allowance[recoveredAddress][spender] = value;

        emit Approval(owner, spender, value);
    }

    function mint(address to, uint256 value) external onlyOwner {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function burn(address from, uint256 value) external onlyOwner {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }
}