// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./INFTree.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//               ,@@@@@@@,
//       ,,,.   ,@@@@@@/@@,  .oo8888o.
//    ,&%%&%&&%,@@@@@/@@@@@@,8888\88/8o
//   ,%&\%&&%&&%,@@@\@@@/@@@88\88888/88'
//   %&&%&%&/%&&%@@\@@/ /@@@88888\88888'
//   %&&%/ %&%%&&@@\ V /@@' `88\8 `/88'
//   `&%\ ` /%&'    |.|        \ '|8'
//       |o|        | |         | |
//       |.|        | |         | |
//    \\/ ._\//_/__/  ,\_//__\\/.  \_//__/_

/**  
    @title NFTreeFactory
    @author Lorax + Bebop
    @notice Enables the purchase/minting of Genesis Colletion NFTrees.
 */

contract NFTreeFactory is Ownable {

    INFTree nftree;
    address treasury;
    uint256[] levels;
    string[] coins;
    bool public isLocked;

    mapping(uint256 => Level) levelMap;
    mapping(string => Coin) coinMap;

    struct Level {
        bool isValid;
        uint256 cost;
        uint256 carbonValue;
        uint256 treeValue;
        uint256 numMinted;
        string tokenURI;
    }

    struct Coin {
        bool isValid;
        IERC20 coinContract;
    }

    /**
        @dev Sets values for {nftree} and {treasury}.
        @param _nftreeAddress NFTree contract address.
        @param _treasuryAddress NFTrees vault wallet address.
     */
    constructor(address _nftreeAddress, address _treasuryAddress)
    {   
        nftree = INFTree(_nftreeAddress);
        treasury = _treasuryAddress;
        isLocked = false;
    }

    /**
        @dev Locks/unlocks minting.
     */
    function toggleLock() external onlyOwner {
        isLocked = !isLocked;
    }

    /**
        @dev Updates {nftree} contract address.
        @param _nftreeAddress New NFTree contract address.
     */
    function setNFTreeContract(address _nftreeAddress) external {
        nftree = INFTree(_nftreeAddress);
    }

    /**
        @dev Retrieves current NFTree contract instance.
        @return INFTree {nftree}.
     */
    function getNFTreeContract() external view returns(INFTree) {
        return nftree;
    }

    /**
        @dev Updates {treasury} wallet address.
        @param _address New NFTrees vault wallet address.
     */
    function setTreasury(address _address) external onlyOwner {
        treasury = _address;
    }
    
    /**
        @dev Retrieves current NFtree vault wallet address.
        @return address {treasury}.
     */
    function getTreasury() external view onlyOwner returns(address) {
        return treasury;
    }

    /**
        @dev Creates new Level instance and maps to the {levels} array. If the level already exists,
        the function updates the struct but does not push to the levels array.
        @param _level Carbon value.
        @param _trees Number of trees planted.
        @param _cost Cost of level.
        @param _tokenURI IPFS hash of token metadata.
     */
    function addLevel(uint256 _level, uint256 _trees, uint256 _cost, string memory _tokenURI) external onlyOwner {
        if (!levelMap[_level].isValid) {
            levels.push(_level);
        }
            
        levelMap[_level] = Level(true, _cost, _level, _trees, 0, _tokenURI);
    }

    /**
        @dev Deletes Level instance and removes from {levels} array.
        @param _level Carbon value of level to be removed.

        requirements: 
            - {_level} must be a valid level.

     */
    function removeLevel(uint256 _level) external onlyOwner {
        require(levelMap[_level].isValid, 'Not a valid level.');

        uint256 index;

        for (uint256 i = 0; i < levels.length; i++) {
            if (levels[i] == _level){
                index = i;
            }
        }

        levels[index] = levels[levels.length - 1];

        levels.pop();
        delete levelMap[_level];
    }

    /**
        @dev Retrieves variables in that carbon value's Level struct.
        @param _level Carbon value of level to be returned.
        @return uint256 {levelMap[_level].cost}.
        @return uint256 {levelMap[_level].carbonValue}.
        @return uint256 {levelMap[_level].numMinted}.

        requirements:
            - {_level} must be a valid level.
     */
    function getLevel(uint256 _level) external view returns(uint256, uint256, uint256, uint256, string memory) {
        require(levelMap[_level].isValid, 'Not a valid level');
        return (levelMap[_level].carbonValue, levelMap[_level].treeValue, levelMap[_level].cost, levelMap[_level].numMinted, levelMap[_level].tokenURI);
    }

    /**
        @dev Retrieves array of valid levels.
        @return uint256[] {levels}.
     */
    function getValidLevels() external view returns(uint256[] memory) {
        return sort_array(levels);
    }

    /**
        @dev Creates new Coin instance and maps to the {coins} array.
        @param _coin Coin name.
        @param _address Contract address for the coin.

        Requirements:
            - {_coin} must not already be a valid coin.
     */
    function addCoin(string memory _coin, address _address) external onlyOwner {
        require(!coinMap[_coin].isValid, 'Already a valid coin.');

        coins.push(_coin);
        coinMap[_coin] = Coin(true, IERC20(_address));

    }

    /**
        @dev Deletes Coin instance and removes from {coins} array.
        @param _coin Name of coin.

        requirements: 
            - {_coin} must be a valid coin.
     */
    function removeCoin(string memory _coin) external onlyOwner {
        require(coinMap[_coin].isValid, 'Not a valid coin.');

        uint256 index;

        for (uint256 i = 0; i < coins.length; i++) {
            if (keccak256(abi.encodePacked(coins[i])) == keccak256(abi.encodePacked(_coin))) {
                index = i;
            }
        }

        coins[index] = coins[coins.length - 1];

        coins.pop();
        delete coinMap[_coin];
    }

    /**
        @dev Retrieves array of valid coins.
        @return uint256[] {coins}.
     */
    function getValidCoins() external view returns(string[] memory) {
        return coins;
    }

    /**
        @dev Mints NFTree to {msg.sender} and transfers payment to {treasury}. 
        @param _tonnes Carbon value of NFTree to purchase.
        @param _amount Dollar value to be transferred to {treasury} from {msg.sender}.
        @param _coin Coin to be used to purchase.

        Requirements:
            - {isLocked} must be false, mint lock must be off.
            - {msg.sender} can not be the zero address.
            - {_level} must be a valid level.
            - {_coin} must be a valid coin.
            - {_amount} must be creater than the cost to mint that level.
            - {msg.sender} must have a balance of {_coin} that is greater than or equal to {_amount}.
            - Allowance of {address(this)} to spend {msg.sender}'s {_coin} must be greater than or equal to {_amount}.

     */
    function mintNFTree(uint256 _tonnes, uint256 _amount, string memory _coin) external {
        // check requirements
        require(!isLocked, 'Minting is locked.');
        require(msg.sender != address(0) && msg.sender != address(this), 'Sending from zero address.'); 
        require(levelMap[_tonnes].isValid, 'Not a valid level.');
        require(coinMap[_coin].isValid, 'Not a valid coin.');
        require(_amount >= levelMap[_tonnes].cost, 'Not enough value.');
        require(coinMap[_coin].coinContract.balanceOf(msg.sender) >= _amount, 'Not enough balance.');
        require(coinMap[_coin].coinContract.allowance(msg.sender, address(this)) >= _amount, 'Not enough allowance.');
        
        // transfer tokens
        coinMap[_coin].coinContract.transferFrom(msg.sender, treasury, _amount * 1e18);
        nftree.mintNFTree(msg.sender, levelMap[_tonnes].tokenURI, _tonnes, _tonnes, "Genesis");
        
        // log purchase
        levelMap[_tonnes].numMinted += 1;
    }

    /**
        @dev Sorts array.
        @return uint256[] {arr}.
     */
    function sort_array(uint256[] memory arr) private pure returns (uint256[] memory) {
        uint256 l = arr.length;
        for(uint i = 0; i < l; i++) {
            for(uint j = i+1; j < l ;j++) {
                if(arr[i] > arr[j]) {
                    uint256 temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
        return arr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTree is IERC721{

    /**
        @dev see {NFTree-mintNFTree}
     */
    function mintNFTree(address _recipient, string memory _tokenURI, uint256 _carbonOffset, uint256 _treesPlanted, string memory _collection) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

