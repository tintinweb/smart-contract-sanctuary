/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// hevm: flattened sources of src/JungleSerum.sol
// SPDX-License-Identifier: MIT AND AGPL-3.0-only AND Unlicense
pragma solidity >=0.8.0 >=0.8.0 <0.9.0 >=0.8.10 <0.9.0;

////// lib/openzeppelin-contracts/src/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/src/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

////// lib/openzeppelin-contracts/src/utils/Strings.sol
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

/* pragma solidity ^0.8.0; */

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

////// lib/solmate/src/tokens/ERC1155.sol
/* pragma solidity >=0.8.0; */

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

////// lib/solmate/src/tokens/ERC20.sol
/* pragma solidity >=0.8.0; */

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

////// lib/solmate/src/tokens/ERC721.sol
/* pragma solidity >=0.8.0; */

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            totalSupply++;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            totalSupply--;

            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

////// src/CyberGorillaBabies.sol
/* pragma solidity ^0.8.10; */

/* import "openzeppelin-contracts/access/Ownable.sol"; */
/* import "openzeppelin-contracts/utils/Strings.sol"; */
/* import "solmate/tokens/ERC721.sol"; */

/*
   ______      __              ______           _ ____          
  / ____/_  __/ /_  ___  _____/ ____/___  _____(_) / /___ ______
 / /   / / / / __ \/ _ \/ ___/ / __/ __ \/ ___/ / / / __ `/ ___/
/ /___/ /_/ / /_/ /  __/ /  / /_/ / /_/ / /  / / / / /_/ (__  ) 
\____/\__, /_.___/\___/_/   \____/\____/_/  /_/_/_/\__,_/____/  
     /____/                                                     

*/

/// @author Delta Developers (@zkarbie, @distractedm1nd)
contract CyberGorillaBabies is ERC721, Ownable {
    using Strings for uint256;
    address private gorillaBreeder;
    string public baseURI;

    constructor(string memory initialBaseURI)
        ERC721("Cyber Gorilla Babies", "CyberGorillaBabies")
    {
        baseURI = initialBaseURI;
    }

    function setGorillaBreeder(address newGorillaBreeder) public onlyOwner {
        gorillaBreeder = newGorillaBreeder;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function mintBaby(address to) public {
        require(msg.sender == gorillaBreeder, "Not Authorized");
        _mint(to, totalSupply);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}

////// src/CyberGorillas.sol
/* pragma solidity ^0.8.10; */

/* import "openzeppelin-contracts/access/Ownable.sol"; */
/* import "openzeppelin-contracts/utils/Strings.sol"; */
/* import "solmate/tokens/ERC721.sol"; */

error SoldOut();
error SaleClosed();
error InvalidMintParameters();
error MintingTooMany();
error NotWhitelisted();
error NotAuthorized();

/*
   ______      __              ______           _ ____          
  / ____/_  __/ /_  ___  _____/ ____/___  _____(_) / /___ ______
 / /   / / / / __ \/ _ \/ ___/ / __/ __ \/ ___/ / / / __ `/ ___/
/ /___/ /_/ / /_/ /  __/ /  / /_/ / /_/ / /  / / / / /_/ (__  ) 
\____/\__, /_.___/\___/_/   \____/\____/_/  /_/_/_/\__,_/____/  
     /____/                                                     

*/

/// @author distractedm1nd
contract CyberGorillas is ERC721, Ownable {
    using Strings for uint256;
    address private passwordSigner;
    address private gorillaBurner;

    bool publicSaleActive;

    uint256 constant PRESALE_MAX_TX = 2;
    uint256 constant PUBLIC_MAX_TX = 5;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 constant PRICE = 0.08 ether;

    string public baseURI;

    mapping(address => uint256) private presaleWalletLimits;
    mapping(address => uint256) private mainsaleWalletLimits;

    constructor(string memory initialBaseURI, address initialPasswordSigner)
        ERC721("Cyber Gorillas", "CyberGorillas")
    {
        baseURI = initialBaseURI;
        passwordSigner = initialPasswordSigner;
    }

    function airdrop(address[] calldata airdropAddresses) public onlyOwner {
        for (uint256 i = 0; i < airdropAddresses.length; i++) {
            _mint(airdropAddresses[i], totalSupply);
        }
    }

    function setGorilliaBurner(address newGorillaBurner) public onlyOwner {
        gorillaBurner = newGorillaBurner;
    }

    function setPasswordSigner(address signer) public onlyOwner {
        passwordSigner = signer;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setPublicSale(bool publicSale) public onlyOwner {
        publicSaleActive = publicSale;
    }

    function purchase(uint256 amount) public payable {
        if (!publicSaleActive) revert SaleClosed();
        if (totalSupply + amount > MAX_SUPPLY) revert SoldOut();
        if (
            mainsaleWalletLimits[msg.sender] + amount > PUBLIC_MAX_TX ||
            msg.value < PRICE * amount
        ) revert InvalidMintParameters();

        mainsaleWalletLimits[msg.sender] += amount;
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply);
        }
    }

    function presale(uint256 amount, bytes memory signature) public payable {
        if (publicSaleActive) revert SaleClosed();
        if (totalSupply + amount > MAX_SUPPLY) revert SoldOut();
        if (!isWhitelisted(msg.sender, signature)) revert NotWhitelisted();
        if (
            presaleWalletLimits[msg.sender] + amount > PRESALE_MAX_TX ||
            msg.value < PRICE * amount
        ) revert InvalidMintParameters();

        presaleWalletLimits[msg.sender] += amount;
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply);
        }
    }

    function unstake(address payable recipient) external onlyOwner {
        recipient.transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function isWhitelisted(address user, bytes memory signature)
        public
        view
        returns (bool)
    {
        bytes32 messageHash = keccak256(abi.encode(user));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == passwordSigner;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function recoverSignerTest(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "sig invalid");

        assembly {
            /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function burn(uint256 tokenId) public {
        if (msg.sender != gorillaBurner) revert NotAuthorized();
        _burn(tokenId);
    }
}

////// src/JungleSerum.sol
/* pragma solidity ^0.8.10; */

/* import "solmate/tokens/ERC1155.sol"; */
/* import "openzeppelin-contracts/access/Ownable.sol"; */
/* import "./CyberGorillas.sol"; */
/* import "./CyberGorillaBabies.sol"; */
/* import "./GrillaToken.sol"; */

/// @dev Inspired by BoredApeChemistryClub.sol (https://etherscan.io/address/0x22c36bfdcef207f9c0cc941936eff94d4246d14a)
contract JungleSerum is ERC1155, Ownable {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    event MutateGorilla(
        uint256 indexed firstGorilla,
        uint256 indexed secondGorilla
    );

    /*///////////////////////////////////////////////////////////////
                        METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string serumURI;
    string constant public name = "Jungle Serum";
    string constant public symbol = "JS";

    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/
    
    uint256 public serumPrice;
    CyberGorillas cyberGorillaContract;
    CyberGorillaBabies cyberBabiesContract;

    GrillaToken public grillaTokenContract;

    mapping(uint256 => bool) mutatedGorillas;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor(string memory _serumURI, uint256 _serumPrice, address cyberGorillas, address cyberBabies) {
        serumURI = _serumURI;
        serumPrice = _serumPrice;
        cyberGorillaContract = CyberGorillas(cyberGorillas);
        cyberBabiesContract = CyberGorillaBabies(cyberBabies);
    }

    /*///////////////////////////////////////////////////////////////
                        STORAGE SETTERS
    //////////////////////////////////////////////////////////////*/
    
    function setSerumURI(string memory _serumURI) public onlyOwner {
        serumURI = _serumURI;
    }

    function setSerumPrice(uint256 _serumPrice) public onlyOwner {
        serumPrice = _serumPrice;
    }

    function setGrillaTokenContract(address _grillaTokenContract)
        public
        onlyOwner
    {
        grillaTokenContract = GrillaToken(_grillaTokenContract);
    }

    function setCyberGorillaContract(address _cyberGorillaContract)
        public
        onlyOwner
    {
        cyberGorillaContract = CyberGorillas(_cyberGorillaContract);
    }

    function setCyberBabiesContract(address _cyberGorillaBabiesContract)
        public
        onlyOwner
    {
        cyberBabiesContract = CyberGorillaBabies(_cyberGorillaBabiesContract);
    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN LOGIC
    //////////////////////////////////////////////////////////////*/

    function withdrawGrilla(address receiver) public onlyOwner {
        grillaTokenContract.transfer(
            receiver,
            grillaTokenContract.balanceOf(address(this))
        );
    }

    /*///////////////////////////////////////////////////////////////
                        METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view override returns (string memory) {
        return serumURI;
    }

    /*///////////////////////////////////////////////////////////////
                            MINTING LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function mint(address gorillaOwner) public {
        require(msg.sender == address(grillaTokenContract), "Not authorized");
        _mint(gorillaOwner, 1, 1, "");
    }

    /*///////////////////////////////////////////////////////////////
                            BREEDING LOGIC
    //////////////////////////////////////////////////////////////*/

    function breed(uint256 firstGorilla, uint256 secondGorilla) public {
        require(
            cyberGorillaContract.ownerOf(firstGorilla) == msg.sender &&
            cyberGorillaContract.ownerOf(secondGorilla) == msg.sender,
            "Invalid Owner"
        );
        require(
            firstGorilla != secondGorilla,
            "Cannot breed with self"
        );
        require(
            balanceOf[msg.sender][1] >= 1,
            "You do not own any serum."
        );

        cyberBabiesContract.mintBaby(msg.sender);
        _burn(msg.sender, 1, 1);
        if (cyberBabiesContract.totalSupply() >= 1667) {
            cyberGorillaContract.burn(floop() ? firstGorilla : secondGorilla);
        }

        emit MutateGorilla(firstGorilla, secondGorilla);
    }
    
    // TODO: Get better floop online
    function floop() private view returns (bool) {
        unchecked {
            return
                uint256(
                    keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))
                ) %
                    2 ==
                0;
        }
    }
}

////// src/GrillaToken.sol
/* pragma solidity ^0.8.10; */

/* import "solmate/tokens/ERC20.sol"; */
/* import "openzeppelin-contracts/access/Ownable.sol"; */
/* import "./JungleSerum.sol"; */
/* import "./CyberGorillasStaking.sol"; */

contract GrillaToken is ERC20, Ownable {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event UtilityPurchase(address indexed sender, uint256 indexed itemId);

    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    JungleSerum serumContract;
    CyberGorillasStaking stakingContract;

    mapping(uint256 => uint256) utilityPrices;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() ERC20("GRILLA", "GRILLA", 18) {}


    /*///////////////////////////////////////////////////////////////
                            MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function ownerMint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function stakerMint(address account, uint256 amount) public {
        require(
            msg.sender == address(stakingContract),
            "Request only valid from staking contract"
        );
        _mint(account, amount);
    }

    /*///////////////////////////////////////////////////////////////
                        CONTRACT SETTERS
    //////////////////////////////////////////////////////////////*/

    function setStakingContract(address staker) public onlyOwner {
        stakingContract = CyberGorillasStaking(staker);
    }

    function setSerumContract(address serumContractAddress) public onlyOwner {
        serumContract = JungleSerum(serumContractAddress);
    }

    /*///////////////////////////////////////////////////////////////
                    UTILITY PURCHASING LOGIC
    //////////////////////////////////////////////////////////////*/

    function buySerum() public {
        transfer(address(serumContract), serumContract.serumPrice());
        serumContract.mint(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                    OFFCHAIN UTILITY PURCHASING LOGIC
    //////////////////////////////////////////////////////////////*/

    function getUtilityPrice(uint256 itemId) public view returns (uint256) {
        return utilityPrices[itemId];
    }

    function addOffchainUtility(uint256 itemId, uint256 itemPrice)
        public
        onlyOwner
    {
        utilityPrices[itemId] = itemPrice;
    }

    function deleteUtilityPrice(uint256 itemId) public onlyOwner {
        delete utilityPrices[itemId];
    }

    function uploadUtilityPrices(
        uint256[] memory items,
        uint256[] memory prices
    ) public onlyOwner {
        for (uint256 i = 0; i < items.length; i++) {
            utilityPrices[items[i]] = prices[i];
        }
    }

    function buyOffchainUtility(uint256 itemId) public {
        require(utilityPrices[itemId] > 0, "Invalid utility id");
        transfer(address(serumContract), utilityPrices[itemId]);
        emit UtilityPurchase(msg.sender, itemId);
    }
}

////// src/CyberGorillasStaking.sol
/* pragma solidity ^0.8.10; */

/* import "./CyberGorillas.sol"; */
/* import "./GrillaToken.sol"; */
/* import "solmate/tokens/ERC721.sol"; */
/* import "openzeppelin-contracts/access/Ownable.sol"; */
/* import "openzeppelin-contracts/utils/Strings.sol"; */

// https://solidity-by-example.org/defi/staking-rewards/
contract CyberGorillasStaking is Ownable {
    /*///////////////////////////////////////////////////////////////
                        CONTRACT STORAGE
    //////////////////////////////////////////////////////////////*/

    GrillaToken public rewardsToken;
    ERC721 public gorillaContract;

    uint256 constant normalRate = (10 * 1E18) / uint(1 days);
    uint256 constant genesisRate = (15 * 1E18) / uint(1 days);

    /*///////////////////////////////////////////////////////////////
                    GORILLA METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    mapping(uint => bool) private genesisTokens;

    /*///////////////////////////////////////////////////////////////
                        STAKING STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public tokenToAddr;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public _balancesNormal;
    mapping(address => uint256) public _balancesGenesis;
    mapping(address => uint256) public _updateTimes;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _stakingToken, address _rewardsToken) {
        gorillaContract = ERC721(_stakingToken);
        rewardsToken = GrillaToken(_rewardsToken);
    }

    /*///////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    function uploadGenesisArray(uint256[] memory genesisIndexes) public onlyOwner {
        for (uint256 i = 0; i < genesisIndexes.length; i++) {
            genesisTokens[genesisIndexes[i]] = true;
        }
    }

    /*///////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    function viewReward() public view returns (uint256) {
        return rewards[msg.sender] + rewardDifferential(msg.sender);
    }

    function rewardDifferential(address account) public view returns (uint256) {
        return
            ((block.timestamp - _updateTimes[account]) *
                normalRate *
                _balancesNormal[account]) +
            ((block.timestamp - _updateTimes[account]) *
                genesisRate *
                _balancesGenesis[account]);
    }

    function isGenesis(uint256 tokenId) private view returns (bool) {
        return genesisTokens[tokenId];
    }

    modifier updateReward(address account) {
        uint256 reward = rewardDifferential(account);
        _updateTimes[account] = block.timestamp;
        rewards[account] += reward;
        _;
    }


    /*///////////////////////////////////////////////////////////////
                            STAKING LOGIC
    //////////////////////////////////////////////////////////////*/

    // TODO: This function is only for testing, can be removed
    // REASONING: Nothing else calls it, and a user would not spend the gas
    //            necessary in order to updateReward()
    function earned(address account)
        public
        updateReward(account)
        returns (uint256)
    {
        return rewards[account];
    }

    function withdrawReward() public updateReward(msg.sender) returns (uint256) {
        require(_updateTimes[msg.sender] + 12 hours >= block.timestamp, "You can only collect a reward once every 12 hours.");
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        // rewardsToken.transfer(msg.sender, reward);
        rewardsToken.stakerMint(msg.sender, reward);
        return reward;
    }

    function stake(uint256 _tokenId) public updateReward(msg.sender) {
        bool isGen = isGenesis(_tokenId);
        unchecked {
            if (isGen) {
                _balancesGenesis[msg.sender]++;
            } else {
                _balancesNormal[msg.sender]++;
            }
        }
        tokenToAddr[_tokenId] = msg.sender;
        gorillaContract.transferFrom(msg.sender, address(this), _tokenId);
    }

    function stakeMultiple(uint256[] memory tokenIds) public updateReward(msg.sender) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
           stake(tokenIds[i]);
        }
    }

    function unstake(uint256 _tokenId) public updateReward(msg.sender) {
        require(tokenToAddr[_tokenId] == msg.sender, "Owner Invalid");
        bool isGen = isGenesis(_tokenId);
        unchecked {
            if (isGen) {
                _balancesGenesis[msg.sender]--;
            } else {
                _balancesNormal[msg.sender]--;
            }
        }
        delete tokenToAddr[_tokenId];
        gorillaContract.transferFrom(address(this), msg.sender, _tokenId);
    }

    function unstakeMultiple(uint256[] memory tokenIds) public updateReward(msg.sender) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
           unstake(tokenIds[i]);
        }
    }

}