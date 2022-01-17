/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// License-Identifier: AGPL-3.0-only
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotApproved();
    
    error NotOwner();

    error InvalidRecipient();

    error SignatureExpired();

    error InvalidSignature();

    error AlreadyMinted();

    error NotMinted();

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/
    
    string public name;

    string public symbol;

    function tokenURI(uint256 tokenId) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/
    
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE STORAGE
    //////////////////////////////////////////////////////////////*/
    
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');

    bytes32 public constant PERMIT_ALL_TYPEHASH = 
        keccak256('Permit(address owner,address spender,uint256 nonce,uint256 deadline)');
    
    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(uint256 => uint256) public nonces;

    mapping(address => uint256) public noncesForAll;
    
    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        
        symbol = symbol_;
        
        INITIAL_CHAIN_ID = block.chainid;
        
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                            ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function approve(address spender, uint256 tokenId) public virtual {
        address owner = ownerOf[tokenId];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert NotApproved();
        
        getApproved[tokenId] = spender;
        
        emit Approval(owner, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function transfer(address to, uint256 tokenId) public virtual returns (bool) {
        if (msg.sender != ownerOf[tokenId]) revert NotOwner();

        if (to == address(0)) revert InvalidRecipient();
        
        // underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow
        unchecked {
            balanceOf[msg.sender]--; 
        
            balanceOf[to]++;
        }
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        
        emit Transfer(msg.sender, to, tokenId); 
        
        return true;
    }

    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public virtual {
        if (from != ownerOf[tokenId]) revert NotOwner();

        if (to == address(0)) revert InvalidRecipient();
        
        if (msg.sender != from 
            && msg.sender != getApproved[tokenId]
            && !isApprovedForAll[from][msg.sender]
        ) revert NotApproved();  
        
        // underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow
        unchecked { 
            balanceOf[from]--; 
        
            balanceOf[to]++;
        }
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        
        emit Transfer(from, to, tokenId); 
    }
    
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public virtual {
        transferFrom(from, to, tokenId); 

        if (to.code.length != 0 
            && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, '') 
            != ERC721TokenReceiver.onERC721Received.selector
        ) revert InvalidRecipient();
    }
    
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId, 
        bytes memory data
    ) public virtual {
        transferFrom(from, to, tokenId); 
        
        if (to.code.length != 0 
            && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) 
            != ERC721TokenReceiver.onERC721Received.selector
        ) revert InvalidRecipient();
    }

    /*///////////////////////////////////////////////////////////////
                            ERC-165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC-165 Interface ID for ERC-721
            interfaceId == 0x5b5e139f || // ERC-165 Interface ID for ERC-165
            interfaceId == 0x01ffc9a7; // ERC-165 Interface ID for ERC-721 Metadata
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert SignatureExpired();
        
        address owner = ownerOf[tokenId];
        
        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            if (recoveredAddress == address(0)) revert InvalidSignature();

            if (recoveredAddress != owner && !isApprovedForAll[owner][recoveredAddress]) revert InvalidSignature(); 
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
    ) public virtual {
        if (block.timestamp > deadline) revert SignatureExpired();
        
        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_ALL_TYPEHASH, owner, operator, noncesForAll[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            if (recoveredAddress == address(0)) revert InvalidSignature();

            if (recoveredAddress != owner && !isApprovedForAll[owner][recoveredAddress]) revert InvalidSignature();
        }
        
        isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return 
            keccak256(
                abi.encode(
                    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                    keccak256(bytes(name)),
                    keccak256(bytes('1')),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                            MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function _mint(address to, uint256 tokenId) internal virtual { 
        if (to == address(0)) revert InvalidRecipient();

        if (ownerOf[tokenId] != address(0)) revert AlreadyMinted();
  
        // cannot realistically overflow on human timescales
        unchecked {
            totalSupply++;
            
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
        
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(uint256 tokenId) internal virtual { 
        address owner = ownerOf[tokenId];

        if (ownerOf[tokenId] == address(0)) revert NotMinted();
        
        // ownership check ensures no underflow
        unchecked {
            totalSupply--;
        
            balanceOf[owner]--;
        }
        
        delete ownerOf[tokenId];
        
        delete getApproved[tokenId];
        
        emit Transfer(owner, address(0), tokenId); 
    }
}

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract Multicall {
    function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);

                if (!success) {
                    if (result.length < 68) revert();
                    
                    assembly {
                        result := add(result, 0x04)
                    }
                    
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }
}

/// @notice Ricardian LLC NFT minter.
contract RicardianLLC is ERC721, Multicall {
    error NotGovernance();

    error NotFee();

    error ETHtransferFailed();

    address public governance;

    string public commonURI;

    string public masterOperatingAgreement;

    uint256 public mintFee;

    mapping(uint256 => string) public tokenDetails;

    modifier onlyGovernance {
        if (msg.sender != governance) revert NotGovernance();

        _;
    }

    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory commonURI_,
        string memory masterOperatingAgreement_,
        uint256 mintFee_
    ) ERC721(name_, symbol_) {
        governance = msg.sender;

        commonURI = commonURI_;

        masterOperatingAgreement = masterOperatingAgreement_;

        mintFee = mintFee_;
    }

    function tokenURI(uint256) public override view virtual returns (string memory) {
        return commonURI;
    }
    
    function mintLLC(address to) public payable virtual { 
        if (msg.value != mintFee) revert NotFee();

        uint256 tokenId = totalSupply;

        _mint(to, tokenId);
    }

    receive() external payable virtual {
        mintLLC(msg.sender);
    }

    function burn(uint256 tokenId) public virtual {
        if (msg.sender != ownerOf[tokenId]) revert NotOwner();

        _burn(tokenId);
    }

    function updateTokenDetails(uint256 tokenId, string calldata details) public virtual {
        if (msg.sender != ownerOf[tokenId]) revert NotOwner();

        tokenDetails[tokenId] = details;
    }

    /*///////////////////////////////////////////////////////////////
                            GOV LOGIC
    //////////////////////////////////////////////////////////////*/

    function govMint(address to) public onlyGovernance virtual {
        uint256 tokenId = totalSupply;
        
        _mint(to, tokenId);
    }

    function govBurn(uint256 tokenId) public onlyGovernance virtual {
        _burn(tokenId);
    }

    function updateGov(address governance_) public onlyGovernance virtual {
        governance = governance_;
    }

    function updateURI(string calldata commonURI_) public onlyGovernance virtual {
        commonURI = commonURI_;
    }

    function updateAgreement(string calldata masterOperatingAgreement_) public onlyGovernance virtual {
        masterOperatingAgreement = masterOperatingAgreement_;
    }

    function updateFee(uint256 mintFee_) public onlyGovernance virtual {
        mintFee = mintFee_;
    }

    function collectFee() public onlyGovernance virtual {
        _safeTransferETH(governance, address(this).balance);
    }

    function _safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // transfer the ETH and store if it succeeded or not
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!callStatus) revert ETHtransferFailed();
    }
}