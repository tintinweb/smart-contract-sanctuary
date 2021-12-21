/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

/// @notice Modern and gas-optimized ERC-1155 implementation.
/// @author Modified from Helios (https://github.com/z0r0z/Helios/blob/main/contracts/ERC1155.sol)
contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    string public baseURI;

    string public name = "Santa Swap Participation Token";

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) internal operators;

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error ArrayParity();

    error InvalidOperator();

    error NullAddress();

    error InvalidReceiver();

    /*///////////////////////////////////////////////////////////////
                            ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    /* GETTERS */

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory batchBalances) {
        if (owners.length != ids.length) revert ArrayParity();

        batchBalances = new uint256[](owners.length);

        for (uint256 i = 0; i < owners.length; i++) {
            batchBalances[i] = balanceOf[owners[i]][ids[i]];
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0xd9b67a26 || interfaceId == 0x0e89341c;
    }

    function uri(uint256) external view returns (string memory meta) {
        meta = baseURI;
    }

    /* APPROVALS */

    function isApprovedForAll(address owner, address operator) public view returns (bool isOperator) {
        isOperator = operators[owner][operator];
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        operators[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /* TRANSFERS */

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 id, 
        uint256 amount, 
        bytes memory data
    ) external {
        if (msg.sender != from || !isApprovedForAll(from, msg.sender)) revert InvalidOperator();

        if (to == address(0)) revert NullAddress();

        balanceOf[from][id] -= amount;

        balanceOf[to][id] += amount;

        _callonERC1155Received(from, to, id, amount, gasleft(), data);

        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function safeBatchTransferFrom(
        address from, 
        address to, 
        uint256[] memory ids,
        uint256[] memory amounts, 
        bytes memory data
    ) external {
        if (msg.sender != from || !isApprovedForAll(from, msg.sender)) revert InvalidOperator();

        if (to == address(0)) revert NullAddress();

        if (ids.length != amounts.length) revert ArrayParity();

        for (uint256 i = 0; i < ids.length; i++) {
            balanceOf[from][ids[i]] -= amounts[i];

            balanceOf[to][ids[i]] += amounts[i];
        }

        _callonERC1155BatchReceived(from, to, ids, amounts, gasleft(), data);

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    function _callonERC1155Received(
        address from, 
        address to, 
        uint256 id, 
        uint256 amount, 
        uint256 gasLimit, 
        bytes memory data
    ) internal view {
        if (to.code.length != 0) {
            // selector = `bytes4(keccak256('onERC1155Received(address,address,uint256,uint256,bytes)'))`
            (, bytes memory returned) = to.staticcall{gas: gasLimit}(abi.encodeWithSelector(0xf23a6e61,
                msg.sender, from, id, amount, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));

            if (selector != 0xf23a6e61) revert InvalidReceiver();
        }
    }

    function _callonERC1155BatchReceived(
        address from, 
        address to, 
        uint256[] memory ids,
        uint256[] memory amounts, 
        uint256 gasLimit, 
        bytes memory data
    ) internal view {
        if (to.code.length != 0) {
            // selector = `bytes4(keccak256('onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)'))`
            (, bytes memory returned) = to.staticcall{gas: gasLimit}(abi.encodeWithSelector(0xbc197c81,
                msg.sender, from, ids, amounts, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));

            if (selector != 0xbc197c81) revert InvalidReceiver();
        }
    }

    /*///////////////////////////////////////////////////////////////
                            MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to, 
        uint256 id, 
        uint256 amount, 
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        if (to.code.length != 0) _callonERC1155Received(address(0), to, id, amount, gasleft(), data);

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function _batchMint(
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) internal {
        if (ids.length != amounts.length) revert ArrayParity();

        for (uint256 i = 0; i < ids.length; i++) {
            balanceOf[to][ids[i]] += amounts[i];
        }

        if (to.code.length != 0) _callonERC1155BatchReceived(address(0x0), to, ids, amounts, gasleft(), data);

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }

    /*///////////////////////////////////////////////////////////////
                            URI LOGIC
    //////////////////////////////////////////////////////////////*/

    function _updateURI(string memory newURI) internal {
        baseURI = newURI;
    }
}

/// @title SantaSwapNFT
/// @author Anish Agnihotri
/// @notice Participation tickets for 2021 Santa Swap NFT Gift Exchange
contract SantaSwapNFT is ERC1155 {

    /// ============ Immutable storage ============

    /// @notice Maximum number of mintable NFTs (global)
    uint256 immutable MAX_NFTS = 10_000;
    /// @notice Maximum number of mintable NFTs (local, by address)
    uint256 immutable MAX_NFTS_PER_ADDRESS = 10;

    /// ============ Mutable storage ============

    /// @notice Contract owner
    address public owner;
    /// @notice Number of NFTs minted
    uint256 public nftsMinted = 0;

    /// ============ Events ============

    /// @notice Emitted after an NFT is minted
    /// @param to new NFT owner
    /// @param handleHash custom hashed Twitter handle of owner
    /// @param amount number of NFTs minted
    event NFTMinted(address indexed to, bytes32 handleHash, uint256 amount);

    /// ============ Errors ============

    /// @notice Thrown when not enough ETH provided to pay for NFT mint
    error InsufficientPayment();

    /// @notice Thrown when attempting to call owner functions as non-owner
    error NotOwner();

    /// @notice Thrown when max number of NFTs have or would be minted (total or by address)
    error MaxMinted();

    /// @notice Thrown when error in low-level call
    error CallError();

    /// ============ Constructor ============

    /// @notice Creates a new SantaSwapNFT contract
    /// @param baseURI of ERC-1155 compatible metadata 
    constructor(string memory baseURI) {
        // Update owner to deployer
        owner = msg.sender;
        // Update URI
        _updateURI(baseURI);
    }

    /// ============ Functions ============

    /// @notice Mints a single NFT
    /// @param handleHash custom hashed Twitter handle of owner
    function mintSingle(bytes32 handleHash) external payable {
        // Revert if not enough payment provided
        if (msg.value < 0.03 ether) revert InsufficientPayment();
        // Revert if maximum NFTs minted (address) after minting single
        if (balanceOf[msg.sender][0] + 1 > MAX_NFTS_PER_ADDRESS) revert MaxMinted();
        // Revert if maximum NFTs minted (global) after minting single
        if (nftsMinted + 1 > MAX_NFTS) revert MaxMinted();

        // Mint NFT
        _mint(msg.sender, 0, 1, "");
        // Increment number of mints
        nftsMinted++;

        // Emit NFTMinted event
        emit NFTMinted(msg.sender, handleHash, 1);
    }

    /// @notice Mints many NFTs
    /// @param handleHash custom hashed Twitter handle of owner
    /// @param numToMint number of NFTs to mint in bulk
    function mintBatch(bytes32 handleHash, uint256 numToMint) external payable {
        // Revert if not enough payment provided
        if (msg.value < (numToMint * 0.03 ether)) revert InsufficientPayment();
        // Revert if maximum NFTs minted (address) after minting bulk
        if (balanceOf[msg.sender][0] + numToMint > MAX_NFTS_PER_ADDRESS) revert MaxMinted();
        // Revert if maximum NFTs minted (global) after minting bulk
        if (nftsMinted + numToMint > MAX_NFTS) revert MaxMinted();

        // Batch mint NFTs
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = numToMint;
        _batchMint(msg.sender, ids, amounts, "");
        // Increment number of mints
        nftsMinted += numToMint;

        // Emit NFTMinted event
        emit NFTMinted(msg.sender, handleHash, numToMint);
    }

    /// @notice Allows owner to withdraw balance of contract
    function withdrawBalance() external {
        // Revert if caller is not owner
        if (msg.sender != owner) revert NotOwner();
        // Drain balance
        (bool sent,) = owner.call{value: address(this).balance}("");
        if (!sent) revert CallError();
    }

    /// @notice Allows owner to update owner of contract
    function updateOwner(address newOwner) external {
        // Revert if caller is not owner
        if (msg.sender != owner) revert NotOwner();
        // Update new owner
        owner = newOwner;
    }

    /// @notice Allows owner to update contract URI
    function updateURI(string memory newURI) external {
        // Revert if caller is not owner
        if (msg.sender != owner) revert NotOwner();
        // Update new URI
        _updateURI(newURI);
    }

    /// @notice Returns total supply of NFTs
    /// @return Total supply
    function totalSupply() public pure returns (uint256) {
        return MAX_NFTS;
    }
}