/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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

// File: @openzeppelin/contracts/interfaces/IERC165.sol



pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/interfaces/IERC2981.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: contracts/IRoyaltyLedger.sol



pragma solidity 0.8.0;

/**
 * @title Interface for a NFT royalty ledger
 */
interface IRoyaltyLedger {

    function enlist(address tokenContract, address royaltyContract) external;

    function delist(address tokenContract) external;

    function enlisted(address tokenContract) external view returns(bool);

    function royaltyInfo(address tokenContract, uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// File: contracts/RoyaltyLedger.sol



pragma solidity 0.8.0;




/**
 * @title A royalty ledger for ERC721 tokens.
 * @notice This contract contains all of the royalties logic. An enlisted royalty provider must implement EIP-2981
 */
contract RoyaltyLedger is IRoyaltyLedger {

    struct Royalty{
        address receiver;
        uint256 percentage;
    }

    mapping(address => address) private _ledger;
    mapping(address => mapping(uint256 => Royalty)) public royalties;

    modifier onlyEnlisted(address contractAddress){
        require(_ledger[contractAddress] != address(0), "Royalties not enlisted for contract!");
        _;
    }

    modifier ownsContract(address contractAddress){
        Ownable ownableContract = Ownable(contractAddress);
        require(ownableContract.owner() == msg.sender, "Sender must own contract!");
        _;
    }


    function enlist(address tokenContract, address royaltyContract) external override ownsContract(tokenContract) {
        _ledger[tokenContract] = royaltyContract;
    }

    function delist(address tokenContract) external override ownsContract(tokenContract) {
        delete _ledger[tokenContract];
    }

    function enlisted(address tokenContract) public view override returns(bool){
        return _ledger[tokenContract] != address(0);
    }

    function setRoyaltyInfo(address tokenContract, uint256 tokenId, address receiver, uint256 percentage) external ownsContract(tokenContract) {
        Royalty memory r;
        r.receiver = receiver;
        r.percentage = percentage; 
        royalties[tokenContract][tokenId] = r;
    }

    function royaltyInfo(address tokenContract, uint256 tokenId, uint256 salePrice) 
    external 
    view 
    override 
    returns (address, uint256){
        if(!enlisted(tokenContract)){
            Royalty memory royalty = royalties[tokenContract][tokenId]; 
            require(royalty.receiver != address(0) && royalty.percentage >= 0 &&
                royalty.percentage <= 100);
            return (royalty.receiver, salePrice * royalty.percentage / 100); //TODO better math!
        }
       return IERC2981(_ledger[tokenContract]).royaltyInfo(tokenId, salePrice);
    }

}