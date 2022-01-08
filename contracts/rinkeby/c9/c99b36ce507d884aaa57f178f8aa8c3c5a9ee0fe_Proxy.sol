/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// File: contracts/Itoadken.sol



pragma solidity ^0.8.0;

interface iToadken { 
    
 function airdrop(uint256 numberOfMints) external; 
 function safeTransferFrom(address from, address to, uint256 tokenId) external;
 function totalSupply() external view returns (uint256);
 function withdraw() external;
 function transferOwnership(address newOwner) external;
 function setBaseURI(string memory baseURI) external;
}

interface ILilyPass {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/proxy.sol




contract Proxy is Ownable, IERC721Receiver {

    uint256 public constant toadkensprice = 2000000000000000; //0.002 ETH

    uint public constant maxToadKenPurchase = 3;
    mapping(uint256 => uint256) public lilyPassMinted;
    uint256 public MAX_TOADKEN = 4444;
    bool public mintPassActive;

    iToadken public Toadken = iToadken(0x9304771F31D8d4e815114C0b980598Ca4B67df7B);
    ILilyPass public LilyPass = ILilyPass(0xcd6b25068E6C5215645732505DfEB8A28d8B5480);
    constructor() {
    }
    
    function transferOwnershipToadken(address newOwnerToadken) public onlyOwner {
        Toadken.transferOwnership(newOwnerToadken);
    }
    
    function withdraw() public onlyOwner {
        Toadken.withdraw();
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function toggleMintPass() public onlyOwner {
        mintPassActive = !mintPassActive;
    }
    
    function onERC721Received(address, address, uint256, bytes memory) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
    * Mints ToadKens
    */

    function mintPassHolder(uint256 passId, uint numberOfTokens) public payable {
        require(mintPassActive);
        require(numberOfTokens + lilyPassMinted[passId] <=3, "Cannot mint more than 3");
        require(toadkensprice*numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(LilyPass.ownerOf(passId) == msg.sender, "You do not own that Lily Pass");
        uint supply = Toadken.totalSupply();
        require(supply + numberOfTokens <= MAX_TOADKEN);
        lilyPassMinted[passId] += numberOfTokens;
        Toadken.airdrop(numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++) {
            Toadken.safeTransferFrom(address(this), msg.sender, supply+i);
        }
    }

    function setBaseURI(string memory BaseURI) public onlyOwner{
       Toadken.setBaseURI(BaseURI);
    }

    receive() external payable {}

}