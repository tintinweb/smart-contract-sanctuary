// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";
import "../interfaces/ILastSurvivorCharacter.sol";
import "../interfaces/ILastSurvivorItem.sol";
import "../utils/RandomUtil.sol";

contract GachaBox is Initializable , OwnableUpgradeable{
    
    constructor() initializer {}

    struct BoxInfo {
        uint256 quota;
        uint256 totalSold;
        uint256 price;
        uint256 maxRewardCardNumber;
    }

    struct UserOpenBoxInfo {
        uint256 xBoxMissingEpicCount;
        uint256 YBoxMissingEpicCount;
        uint256 YBoxMissingLegendCount;
        uint256 ZBoxMissingLegendCount;
    }

    mapping(address => UserOpenBoxInfo) public userOpenInfo;     
    mapping(uint256 => BoxInfo) public boxConfig;     
    address public lastSurvivorCharacter;
    address public lastSurvivorItem;
    address public treasury;
    address public buyToken;
    address private randomContract;

    function initialize() initializer public {
        __Ownable_init();
    }

    modifier onlyNonContract {
        require(tx.origin == msg.sender, "Only non-contract call");
        _;
    }

    // Update config
    function updateConfig(address _lastSurvivorCharacter, address _lastSurvivorItem, address _buyToken, address _treasury, address _randomContract) public onlyOwner{
        lastSurvivorCharacter = _lastSurvivorCharacter; 
        lastSurvivorItem = _lastSurvivorItem;
        buyToken = _buyToken; 
        treasury = _treasury;
        randomContract = _randomContract;
    }

    // Update boxConfig
    function updateBoxConfig(uint256 _quota, uint256 _price, uint256 _boxId, uint256 _maxRewardCardNumber) public onlyOwner{
        require(_boxId != 0, "Invalid boxId");
        require(_boxId < 4, "Invalid boxId");
        boxConfig[_boxId].quota = _quota;
        boxConfig[_boxId].price = _price;
        boxConfig[_boxId].maxRewardCardNumber = _maxRewardCardNumber;
    }

    function gachaXBox() public returns (uint256, uint256) {
        uint256 characterID = RandomUtil(randomContract).getRandomNumber(8);
        uint256 typeID; // 1: Normal, 2 Epic, 3 Legend
        if (userOpenInfo[msg.sender].xBoxMissingEpicCount >= 5) {
            typeID = 2;
            userOpenInfo[msg.sender].xBoxMissingEpicCount = 0;
        } else {
            uint256 randomValue = RandomUtil(randomContract).getRandomNumber(10000);
            if (randomValue < 795) {
                typeID = 2;
                userOpenInfo[msg.sender].xBoxMissingEpicCount = 0;
            } else {
                typeID = 1;
                userOpenInfo[msg.sender].xBoxMissingEpicCount += 1;
            }
        }
        return (characterID, typeID);
    }

    function gachaYBox() public returns (uint256, uint256) {
        uint256 characterID = RandomUtil(randomContract).getRandomNumber(8);
        uint256 typeID; // 1: Normal, 2 Epic, 3 Legend
        if (userOpenInfo[msg.sender].YBoxMissingLegendCount >= 20) {
            typeID = 3;
            userOpenInfo[msg.sender].YBoxMissingLegendCount = 0;
        } else if (userOpenInfo[msg.sender].YBoxMissingEpicCount >= 5) {
            typeID = 2;
            userOpenInfo[msg.sender].YBoxMissingEpicCount = 0;
        } else {
            uint256 randomValue = RandomUtil(randomContract).getRandomNumber(10000);
            if (randomValue < 85) {
                typeID = 3;
                userOpenInfo[msg.sender].YBoxMissingLegendCount = 0;
                userOpenInfo[msg.sender].YBoxMissingEpicCount += 1;
            } else if (randomValue < 4547){
                typeID = 2;
                userOpenInfo[msg.sender].YBoxMissingLegendCount += 1;
                userOpenInfo[msg.sender].YBoxMissingEpicCount = 0;
            } else {
                typeID = 1;
                userOpenInfo[msg.sender].YBoxMissingLegendCount += 1;
                userOpenInfo[msg.sender].YBoxMissingEpicCount += 1;
            }
        }
        return (characterID, typeID);
    }

    function gachaZBox() public returns (uint256, uint256) {
        uint256 characterID = RandomUtil(randomContract).getRandomNumber(8);
        uint256 typeID; // 1: Normal, 2 Epic, 3 Legend
        if (userOpenInfo[msg.sender].ZBoxMissingLegendCount >= 3) {
            typeID = 3;
            userOpenInfo[msg.sender].ZBoxMissingLegendCount = 0;
        } else {
            uint256 randomValue = RandomUtil(randomContract).getRandomNumber(10000);
            if (randomValue < 2535) {
                typeID = 3;
                userOpenInfo[msg.sender].ZBoxMissingLegendCount = 0;
            } else {
                typeID = 2;
                userOpenInfo[msg.sender].ZBoxMissingLegendCount += 1;
            }
        }
        return (characterID, typeID);
    }

    function getRelatedCard(uint256 characterID, uint256 typeID) public view returns (uint256) {
        uint256 cardID;
        if (typeID == 1) {
            if (characterID == 1) {
                cardID = 1; 
            } else if (characterID == 2) {
                cardID = 2;
            } else if (characterID == 3) {
                cardID = 3;
            } else if (characterID == 4) {
                cardID = 4;
            } else if (characterID == 5) {
                cardID = 5;
            } else if (characterID == 6) {
                cardID = 6;
            } else if (characterID == 7) {
                cardID = 7;
            } else if (characterID == 8) {
                cardID = 8;
            }
        } else if (typeID == 2) {
            if (characterID == 1) {
                cardID = 9; 
            } else if (characterID == 2) {
                cardID = 10;
            } else if (characterID == 3) {
                cardID = 11;
            } else if (characterID == 4) {
                cardID = 12;
            } else if (characterID == 5) {
                cardID = 13;
            } else if (characterID == 6) {
                cardID = 14;
            } else if (characterID == 7) {
                cardID = 15;
            } else if (characterID == 8) {
                cardID = 16;
            }
        }
        else if (typeID == 3) {
            if (characterID == 1) {
                cardID = 17; 
            } else if (characterID == 2) {
                cardID = 18;
            } else if (characterID == 3) {
                cardID = 19;
            } else if (characterID == 4) {
                cardID = 20;
            } else if (characterID == 5) {
                cardID = 21;
            } else if (characterID == 6) {
                cardID = 22;
            } else if (characterID == 7) {
                cardID = 23;
            } else if (characterID == 8) {
                cardID = 24;
            }
        }
        return cardID;
    }

    function getRewardCardBox(uint256 boxID, uint256 totalNFT) public view returns(uint256[] memory) {  
        uint256[6] memory amount;
        if (boxID == 1) {
            if (totalNFT <= 1) { amount = [uint256(20), 0, 0, 0, 0, 0]; }
            else if (totalNFT <= 2) { amount = [uint256(10), 15, 0, 0, 0, 0];}
            else if (totalNFT <= 3) { amount = [uint256(10), 10, 10, 0, 0, 0];}
            else if (totalNFT <= 4) { amount = [uint256(5), 10, 10, 10, 0, 0];}
            else { amount = [uint256(10), 10, 10, 10, 0, 0];}
        } else if (boxID == 2) {
            if (totalNFT <= 1) { amount = [uint256(50), 0, 0, 0, 0, 0];}
            else if (totalNFT <= 2) { amount = [uint256(25), 30, 0, 0, 0, 0]; }
            else if (totalNFT <= 3) { amount = [uint256(10), 20, 30, 0, 0, 0];}
            else if (totalNFT <= 4) { amount = [uint256(15), 15, 15, 25, 0, 0];}
            else if (totalNFT <= 5) { amount = [uint256(10), 10, 15, 15, 20, 0];}
            else if (totalNFT <= 6) { amount = [uint256(10), 15, 15, 15, 20, 0];}
            else { amount = [uint256(15), 15, 15, 15, 20, 0];}
        }
        else {
            if (totalNFT <= 1) { amount = [uint256(100), 0, 0, 0, 0, 0];}
            else if (totalNFT <= 2) { amount = [uint256(50), 60, 0, 0, 0, 0];}
            else if (totalNFT <= 3) { amount = [uint256(30), 40, 50, 0, 0, 0];}
            else if (totalNFT <= 4) { amount = [uint256(30), 30, 30, 40, 0, 0];}
            else if (totalNFT <= 5) { amount = [uint256(20), 20, 30, 30, 40, 0];}
            else if (totalNFT <= 6) { amount = [uint256(15), 15, 25, 25, 35, 35];}
            else if (totalNFT <= 7) { amount = [uint256(20), 20, 25, 25, 35, 35];}
            else if (totalNFT <= 8) { amount = [uint256(20), 20, 30, 30, 35, 35];}
            else { amount = [uint256(20), 20, 30, 30, 40, 40];}
        }
        uint256 lengthAmount = 6;
        for (uint256 i = 0; i < amount.length; i++) {
            if (amount[i] == 0) {
                lengthAmount--;
            }
        }
        
        uint256[] memory result = new uint256[](lengthAmount);
        for (uint256 i = 0; i < lengthAmount; i++) {
            result[i] = amount[i];
        }
        return (result);
    }

    function getRewardNFTCard(uint256 boxID, address _sender) public view returns (uint256[] memory) {
        // Gacha fighter card
        uint256[] memory totalIdx = new uint256[](ILastSurvivorCharacter(lastSurvivorCharacter).balanceOf(_sender));
        uint256 selectNumber;
        bool needRandom = false;
        if (boxID == 1) { 
            if (totalIdx.length < 6) { selectNumber = totalIdx.length; }
            else { selectNumber = 5; needRandom = true;}
        } else if (boxID == 2) { 
            if (totalIdx.length < 6) { selectNumber = totalIdx.length; }
            else { selectNumber = 5; needRandom = true;}
        } else {
            if (totalIdx.length < 7) { selectNumber = totalIdx.length; }
            else { selectNumber = 6; needRandom = true;}
        }

        for (uint256 i = 0; i < totalIdx.length; i++) {
            totalIdx[i] = i;
        }
        uint256[] memory rewardNft = new uint256[](selectNumber);
        for (uint256 i = 0; i < selectNumber; i++) {
            if (needRandom) { 
                uint256 rewardIndex = RandomUtil(randomContract).getRandomNumber(totalIdx.length - i) - 1;
                rewardNft[i] = ILastSurvivorCharacter(lastSurvivorCharacter).tokensOfOwners(_sender, rewardIndex);
                totalIdx[rewardIndex] = totalIdx[totalIdx.length];
            } else {
                rewardNft[i] = ILastSurvivorCharacter(lastSurvivorCharacter).tokensOfOwners(_sender, i);
            }
            
        }
        return rewardNft;
    }

    // Open box
    function openBox(uint256 _boxId) public onlyNonContract  returns (uint256) {
        require(boxConfig[_boxId].totalSold <= boxConfig[_boxId].quota, "Exceed mint quota." );
        require(boxConfig[_boxId].price > 0, "Invalid Box." );
        boxConfig[_boxId].totalSold += 1;
        IERC20Upgradeable(buyToken).transferFrom(msg.sender, treasury, boxConfig[_boxId].price);
        uint256 characterID;
        uint256 typeID;
        // XBox = 1, YBox = 2, ZBox = 3
        uint256 totalNFT = ILastSurvivorCharacter(lastSurvivorCharacter).balanceOf(msg.sender);
        if (_boxId == 1) {
            (characterID, typeID) = gachaXBox();
        } else if (_boxId == 2) {
            (characterID, typeID) = gachaYBox();
        } else {
            (characterID, typeID) = gachaZBox();
        }
        uint256[] memory amountCard = getRewardCardBox(_boxId, totalNFT);
        uint256[] memory reChaIdx = getRewardNFTCard(_boxId, msg.sender);
        ILastSurvivorCharacter.CharacterInfo[] memory reNft = ILastSurvivorCharacter(lastSurvivorCharacter).getTokenOwners(msg.sender, reChaIdx);
        uint256[] memory rewrardID = new uint256[](reChaIdx.length);
        for (uint256 i = 0; i < reChaIdx.length; i++) {
            rewrardID[i] = getRelatedCard(reNft[i].characterID, reNft[i].typeID);
        }
        // ILastSurvivorItem(lastSurvivorItem).mintBatch(msg.sender, rewrardID, amountCard, "");
        uint256 nftID = ILastSurvivorCharacter(lastSurvivorCharacter).safeMint(msg.sender, characterID, typeID);
        return nftID;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../dependencies/open-zeppelin/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ILastSurvivorCharacter is IERC165Upgradeable {

    
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

    struct CharacterInfo {
        uint256 nftID;
        uint256 ascensionLevel;
        uint256 characterID;
        uint256 typeID; // 1: Normal, 2 Epic, 3 Legend
    }

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

    function safeMint(address to, uint256 _charId, uint256 _typeID) external returns (uint256);
    function getTokenOwners(address _owner, uint256[] memory _selectedIdx) external view returns (CharacterInfo[] memory);
    function tokensOfOwners(address _owner, uint256 index) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../dependencies/open-zeppelin/interfaces/IERC1155Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ILastSurvivorItem is IERC1155Upgradeable {
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";
import "../dependencies/open-zeppelin/utils/StringsUpgradeable.sol";

contract RandomUtil is Initializable , OwnableUpgradeable{
    
    constructor() initializer {}

    uint256 randomCounter;
    mapping(address => bool) public whitelistRandom;  

    function initialize() initializer public {
        __Ownable_init();
    }

    modifier onlyWhitelistRandom() {
        require(whitelistRandom[msg.sender], 'Only whitelist');
        _;
    }

    function getRandomSeed() internal view returns (uint256) {
        return uint256(sha256(abi.encodePacked(block.coinbase, randomCounter, blockhash(block.number -1), block.difficulty, block.gaslimit, block.timestamp, gasleft(), msg.sender)));
    }

    function setWhiteList(address _whitelist, bool status) public onlyOwner {
        whitelistRandom[_whitelist] = status;
    }

    // Get random number
    function updateCounter(uint256 addedCounter) public onlyWhitelistRandom{
        unchecked { randomCounter += addedCounter; }
    }

    // Get random number
    function getRandomNumber(uint256 _rate) public view onlyWhitelistRandom returns (uint256) {
        return (getRandomSeed() % _rate)  + 1;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

import "../token/ERC1155/IERC1155Upgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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