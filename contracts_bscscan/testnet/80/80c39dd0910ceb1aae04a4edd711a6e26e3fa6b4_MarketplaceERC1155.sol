/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenRecover is Ownable {
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}




interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

contract MarketplaceERC1155 is Ownable, TokenRecover, ERC1155Holder {
    
    struct Sale {
        uint256 id;
        uint256 nftId;
        uint256 price;
        address owner;
        uint256 openAt;
        bool isOpen;
    }
    
    Sale[] public sales;

    IERC1155 nft;
    IERC20 token;

    mapping (uint => uint) public priceOf;

    uint totalOpened;
    
    event Bought(uint indexed nftId, address from, address to, uint price);
    event Opened(uint indexed nftId, address indexed lister, uint price);
    event Minted(uint indexed nftId, address to);

    constructor(IERC1155 nft_, IERC20 token_) {
        nft = nft_;
        token = token_;
    }

    function setToken(IERC20 token_) external onlyOwner {
        token = token_;
    }

    function setNft(IERC1155 nft_) external onlyOwner {
        nft = nft_;
    }

    function open(uint256 nftId, uint256 price) external {
        require(nft.balanceOf(msg.sender, nftId) >= 1, "Marketplace: insufficient balance");
        require(nft.isApprovedForAll(msg.sender, address(this)), "Marketplace: insufficient allowance");
        uint saleId = sales.length;
        sales.push();
        Sale storage s = sales[saleId];
        s.nftId = nftId;
        s.price = price;
        s.owner = msg.sender;
        s.openAt = block.timestamp;
        s.isOpen = true;
        totalOpened += 1;
        nft.safeTransferFrom(msg.sender, address(this), s.nftId, 1, "");
        emit Opened(s.nftId, msg.sender, price);
    }

    function close(uint256 saleId) external {
        Sale storage s = sales[saleId];
        require(s.owner == msg.sender, "Marketplace: caller is not sale owner");
        s.isOpen = false;
        totalOpened -= 1;
        nft.safeTransferFrom(address(this), s.owner, s.nftId, 1, "");
    }

    function buy(uint256 saleId) external {
        Sale storage s = sales[saleId];
        require(token.balanceOf(msg.sender) >= s.price, "Marketplace: insufficient balance");
        require(token.allowance(msg.sender, address(this)) >= s.price, "Marketplace: insufficient allowance");
        require(s.isOpen, "Marketplace: sales not available.");

        s.isOpen = false;
        totalOpened -= 1;

        nft.safeTransferFrom(address(this), msg.sender, s.nftId, 1, "");
        bool success = token.transferFrom(msg.sender, s.owner, s.price);
        require(success, "Marketplace: failed to transfer scb");
        emit Bought(s.nftId, s.owner, msg.sender, s.price);
    }
    
    function openSales() external view returns (Sale[] memory){
        Sale[] memory sl = new Sale[](totalOpened);

        uint counter;
        for(uint i = 0; i < sales.length; i++) {
            if (sales[i].isOpen == false) continue;
                sl[counter] = sales[i];
                counter++;
        }
        return sl;
    }
    
    function closedSales() external view returns (Sale[] memory){
        Sale[] memory sl = new Sale[](sales.length-totalOpened);

        uint counter;
        for(uint i = 0; i < sales.length; i++) {
            if (sales[i].isOpen == true) continue; 
            sl[counter] = sales[i];
            counter++;
        }
        return sl;
    }

    function setPrice(uint nftId, uint price) external onlyOwner {
        priceOf[nftId] = price;
    }

    function mint(uint nftId) external {
        require(priceOf[nftId] != 0, "Marketplace: nft not found");
        require(token.balanceOf(msg.sender) >= priceOf[nftId], "Marketplace: insufficient balance");

        token.transferFrom(msg.sender, address(this), priceOf[nftId]);
        nft.mint(msg.sender, nftId, 1, "");
        emit Minted(nftId, msg.sender);
    }

    function totalSales() external view returns (uint){
        return sales.length;
    }
}