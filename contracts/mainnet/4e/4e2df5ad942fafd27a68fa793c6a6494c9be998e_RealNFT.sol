/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: GPL-3.0-or-later

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

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation
// - Designed for tokenizing realness by RealDAO with ownership, pausing, and whitelisting.
contract RealNFT is LexOwnable, LexPausable, LexWhitelistable {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    string public constant name = "RealNFT";
    string public constant symbol = "REAL";
    
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_ALL_TYPEHASH = 
        keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline)");
    
    uint256 internal immutable DOMAIN_SEPARATOR_CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    mapping(uint256 => uint256) public nonces;
    mapping(address => uint256) public noncesForAll;
    
    constructor() LexPausable(false) LexWhitelistable(true) {
        DOMAIN_SEPARATOR_CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator();
    }
    
    function _calculateDomainSeparator() internal view returns (bytes32 domainSeperator) {
        domainSeperator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeperator) {
        domainSeperator = block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator();
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function approve(address spender, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_APPROVED");
        
        getApproved[tokenId] = spender;
        
        emit Approval(owner, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function transfer(address to, uint256 tokenId) external notPaused onlyWhitelisted(msg.sender, to) {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        /// @dev This is safe because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked {
            balanceOf[msg.sender]--; 
        
            balanceOf[to]++;
        }
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        
        emit Transfer(msg.sender, to, tokenId); 
    }

    function transferFrom(address from, address to, uint256 tokenId) public notPaused onlyWhitelisted(from, to) {
        address owner = ownerOf[tokenId];
        
        require(from == owner, "FROM_NOT_OWNER");
        require(
            msg.sender == owner 
            || msg.sender == getApproved[tokenId]
            || isApprovedForAll[owner][msg.sender], 
            "NOT_APPROVED"
        );
        /// @dev This is safe because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked { 
            balanceOf[owner]--; 
        
            balanceOf[to]++;
        }
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        
        emit Transfer(owner, to, tokenId); 
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId); 
        
        if (to.code.length != 0) {
            /// @dev selector = `onERC721Received(address,address,uint,bytes)`.
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, from, tokenId, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }
    
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        
        address owner = ownerOf[tokenId];
        /// @dev This is reasonably safe from overflow because incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0), "INVALID_PERMIT_SIGNATURE");
            require(recoveredAddress == owner || isApprovedForAll[owner][recoveredAddress], "INVALID_SIGNER");
        }
        
        getApproved[tokenId] = spender;

        emit Approval(owner, spender, tokenId);
    }
    
    function permitAll(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        /// @dev This is reasonably safe from overflow because incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_ALL_TYPEHASH, owner, operator, noncesForAll[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(
                (recoveredAddress != address(0) && recoveredAddress == owner) || isApprovedForAll[owner][recoveredAddress],
                "INVALID_PERMIT_SIGNATURE"
            );
        }
        
        isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }
    
    function mint(address to, uint256 tokenId, string memory _tokenURI) external onlyOwner { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");
        /// @dev This is reasonably safe from overflow because incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits,
        // and because the sum of all user balances can't exceed 'type(uint256).max'.
        unchecked {
            totalSupply++;
            
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
        
        tokenURI[tokenId] = _tokenURI;
        
        emit Transfer(address(0), to, tokenId); 
    }
    
    function burn(uint256 tokenId) external onlyOwner { 
        address owner = ownerOf[tokenId];
        
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        /// @dev This is safe because a user won't ever
        // have a balance larger than totalSupply.
        unchecked {
            totalSupply--;
        
            balanceOf[owner]--;
        }
        
        delete ownerOf[tokenId];
        
        delete tokenURI[tokenId];
        
        emit Transfer(owner, address(0), tokenId); 
    }
}