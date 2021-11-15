pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./utils/TransferHelper.sol";

// --------------------------------------------------------------------------------------
//
// (c) PillPackager 23/06/2021 | SPDX-License-Identifier: MIT
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// PillPackage is the hub for all airdrops. Project owners are able to distribute their
// tokens with the customisable options. Once the airdrop settings are set, PillPackage
// deploys a proxy contract containing those settings, allowing users to interact with
// it.
//
// Allows for dynamic and static airdrops.
// Dynamic: 100 of x token give you 200. 10 of n token gives 250.
//
// Creators can choose whether the airdrop will be streamed or a lump sum.
//
// --------------------------------------------------------------------------------------

contract PillPackager {

    /// @dev Static/Dynamic airdrop
    struct PillPackage {
        uint24 consumers; // amount of users that have consumed the package
        bool dispense; // whether pills will be streamed per second
        bool requireSyrum;
        uint96 streamEnd; // timestamp of when the stream ends
        address token; // token contract address
        uint96 startTime; // when redemptions are unlocked
        uint96 endTime; // when redemptions lock (and stream starts)
        uint256 supply; // supply to be packaged
        uint256 limit; // how many tokens one may receive
        Erc20Pills[] erc20Pills; // dynamic pill distribution for Erc20 specific tokens
        Requirement requirement; // token(s) required to be held to consume
    }

    /// @dev Package unlock requirement(s)
    struct Requirement {
        address erc721token;
        address erc20token; // token address
        uint256 erc20amount; // amount to consumer
    }

    /// @dev How many `tokens` for amount of `pills`
    struct Erc20Pills {
        address token; // token contract address
        uint256 tokens; // amount of tokens required
        uint256 pills;  // amount of pills for `amount`
    }

    /// @dev Mixture to be poured in the dispensary to supply pills
    struct Syrum {
        bool claimed;
        address[] tokens; // locked pills being used for syrum
        uint256[] amount; // amount of tokens used for syrum
    }

    /// @dev User details
    struct Dispensary  {
        bool consumed; // whether has consumed or not
        uint256 owed; // amount owed
        uint256 perSecond; // amoun
        uint256 lastConsumtion;
    }   


    uint32 pillPackages; // total static airdrops
    mapping(uint256 => PillPackage) public pillPackage; // static package assigned to number
    mapping(uint256 => mapping(address => Dispensary)) public dispensary; // packageId => user => details
    mapping(uint256 => mapping(address => Syrum)) syrum; // packageId => user => details

    event PackageCreation(uint256 packageId, address token, uint256 supply, uint256 startTime, uint256 endTime);
    event PackageLockAdded(uint256 packageId, address token, uint256 startTime);
    event PackageConsumption(uint256 packageId, uint256 amount);
    event SupplyClaimed(uint256 packageId, uint256 remainingSupply);


    // ------------------------
    //  Package Creation
    // ------------------------

    /**
     * @dev Static airdrop: best for even distribution
     * @param dispense whether airdrop is given as a sum or slow release
     * @param streamEnd when dispensary drip ends
     * @param startTime when redemption begins
     * @param endTime when redemption halts
     * @param token token being airdropped
     * @param supply amount of tokens being airdropped
     * @param perPerson default amount per consumer
     */
    function packageStatic(
        bool dispense,
        uint96 streamEnd,
        uint96 startTime,
        uint96 endTime,
        address token,
        uint256 supply,
        uint256 perPerson
    ) public returns(uint256 packageId) {
        PillPackage storage package = pillPackage[pillPackages];

        if (dispense) { 
            package.dispense = true;
            package.streamEnd = streamEnd; 
        }

        package.token = token;
        package.supply = supply;
        package.limit = perPerson;
        package.startTime = startTime;
        package.endTime = endTime;

        pillPackages += 1;

        emit PackageCreation(pillPackages - 1, token, supply, startTime, endTime);
        return pillPackages - 1;
    }


    /**
     * @dev Dynamic airdrop: best for rewarding platform loyalty
     * @param dispense whether airdrop is given as a sum or slow release
     * @param streamEnd when puncture drip ends
     * @param startTime when redemption begins
     * @param endTime when redemption halts
     * @param token token being airdropped
     * @param supply amount of tokens being airdropped
     * @param limit max pills one can receive (if 0, no limit)
     * @param erc20s erc20s with dynamic rates (1xyz = 10pills)
     * @param erc20Tokens how many erc20 tokens for `erc20Pills`
     * @param erc20Pills how many airdrop tokens for `erc20Tokens`
     */
    function packageDynamic(
        bool dispense,
        uint96 streamEnd,
        uint96 startTime,
        uint96 endTime,
        address token,
        uint256 supply,
        uint256 limit,
        address[] memory erc20s,
        uint256[] memory erc20Tokens,
        uint256[] memory erc20Pills
    ) public returns(uint256 packageId) {
        PillPackage storage package = pillPackage[pillPackages];
        
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), supply);

        if (dispense) { 
            package.dispense = true;
            package.streamEnd = streamEnd; 
        }

        package.token = token;
        package.supply = supply;
        if (limit != 0) { package.limit = limit; }

        if (package.erc20Pills[0].tokens != 0 && package.erc20Pills[0].pills != 0) {
            for (uint8 i; i < erc20s.length; i++) {
                package.erc20Pills[i].token = erc20s[i];
                package.erc20Pills[i].tokens = erc20Tokens[i];
                package.erc20Pills[i].pills = erc20Pills[i];
            }
        }
        
        package.startTime = startTime;
        package.endTime = endTime;

        pillPackages += 1;

        emit PackageCreation(pillPackages -1, token, supply, startTime, endTime);
        return pillPackages - 1;
    }


    // ------------------------
    //  Package Requirements
    // ------------------------

    /**
     * @dev Adds entry requirement to package
     * @param packageId packageId referring to
     * @param erc721token address of erc721 token
     * @param erc20token address of erc20 token
     * @param erc20amount erc20 amountcrequired to hold
     */
    function lockPackage(
        uint256 packageId,
        address erc721token,
        address erc20token,
        uint256 erc20amount
    ) public {
        PillPackage storage package = pillPackage[packageId];
        require(block.timestamp < package.endTime, "No lacing");

        if (erc20token != address(bytes20(''))) {
            package.requirement.erc20token = erc20token;
            package.requirement.erc20amount = erc20amount;
        }
        if (erc721token != address(bytes20(''))) {
            package.requirement.erc721token = erc721token;
        } 
        emit PackageLockAdded(packageId, package.token, package.startTime);
    }


    /**
     * @dev Checks package requirement to consume
     * @param packageId packageId referring to
     * @param user who to check
     */
    function unlockPackage(uint256 packageId, address user) public view returns (bool unlocked) {
        PillPackage memory package = pillPackage[packageId];
        if (package.requirement.erc20amount != 0) {
            require(
                IERC20(package.requirement.erc20token).balanceOf(user) != 0,
                "erc20 unheld"
            );
        }
        if (package.requirement.erc721token != address(bytes20(''))) {
                require(
                    IERC721(package.requirement.erc721token).balanceOf(user) != 0,
                    "any erc721 unheld"
                );

        }
        return true;
    }


    // ------------------------
    //  Consumption
    // ------------------------

    /**
     * @dev allows users to consume pills from the pillPackage
     * @param packageId package to consume from
     */
    function consumePills(uint256 packageId) public {
        PillPackage memory package = pillPackage[packageId];
        require(package.endTime < block.timestamp, "In transit");
        Dispensary storage pills = dispensary[packageId][msg.sender];
        require(!pills.consumed && pills.owed != 0, 'Overdose');
        require(unlockPackage(packageId, msg.sender));

        uint256 receiving;
        if (!pills.consumed && pills.owed == 0) {
            initialCalculation(packageId);
        }

        if (!package.dispense) {
            receiving = package.limit;
            pills.owed -= receiving;
        } else if (package.dispense) {
            receiving = pills.perSecond * (block.timestamp - pills.lastConsumtion);
            pills.lastConsumtion = block.timestamp;
            pills.owed -= receiving;
            pills.perSecond = pills.owed / package.streamEnd;

            if (syrum[packageId][msg.sender].amount[0] != 0) {
                Syrum storage brew = syrum[packageId][msg.sender];
                require(!brew.claimed, 'Already claimed');
                brew.claimed = true;
                for (uint8 i; i < brew.tokens.length; i++) {
                    TransferHelper.safeTransfer(brew.tokens[i], msg.sender, brew.amount[i]);
                }
            }
        }

        TransferHelper.safeTransfer(package.token, msg.sender, receiving);
        emit PackageConsumption(packageId, receiving);
    }


    /**
     * @dev Users create a syrum to produce pills, enabling `calculatePills`
     * This acts as a prevention mechanism to stop hopping funds to multiple wallets
     * for higher (unfair) allocation of pills.
     * @param packageId package to consume from
     * @param erc20s erc20s with dynamic rates (1xyz = 10pills)
     * @param erc20Tokens how many erc20 tokens for `erc20Pills`
     */
    function brewSyrum(
        uint256 packageId, 
        address[] memory erc20s,
        uint256[] memory erc20Tokens
    ) public returns(bool brewing) {
        require(pillPackage[packageId].supply != 0, 'Supply outage');
        require(unlockPackage(packageId, msg.sender));
        PillPackage memory package = pillPackage[pillPackages];

        // cycle through package tokens and try to match inputted
        for (uint8 i; i < package.erc20Pills.length; i++) {
            // cycle through inputted tokens 
            for (uint8 r; r < erc20s.length; r++) {
                // if inputted token == package token, depo and record
                if (erc20s[i] == package.erc20Pills[r].token) {
                    TransferHelper.safeTransferFrom(erc20s[i], msg.sender, address(this), erc20Tokens[i]);
                    syrum[packageId][msg.sender].tokens[i] = erc20s[i];
                    syrum[packageId][msg.sender].amount[i] = erc20Tokens[i];
                    break;
                }
            }
        }

        assert(syrum[packageId][msg.sender].tokens[0] != address(bytes20('')));
        return true;
    }


    /**
     * @dev 
     * - originally, users are able to redeem, transfer tokens to another wallet, then redeem again
     * - now, users are required to lock their tokens into a syrum to create the pills
     * @param packageId package to consume from
     */
    function initialCalculation(uint256 packageId) private {
        Dispensary storage pills = dispensary[packageId][msg.sender];
        require(!pills.consumed && pills.owed == 0, 'cant calculaton');
        PillPackage storage package = pillPackage[packageId];
        Syrum memory brew = syrum[packageId][msg.sender];
        if (package.requireSyrum) {
            require(brew.amount[0] != 0, 'No syrum');
        }

        uint256 owed;
        pills.consumed = true;

        // calculate dispensary details for user
        if (package.dispense) {
        
            // Cycle through each token and calculate total receiving
            for (uint8 i; i < package.erc20Pills.length; i++) {
                uint256 bal = brew.amount[i];

                // if bal is empty, skip
                if (bal != 0) {  
                    
                    //  calculate the amount of pills to be created with the syrum provided
                    owed += bal / package.erc20Pills[i].tokens * package.erc20Pills[i].pills;
                    
                    // if receiving is more than limit, give limit
                    if (package.limit != 0 && owed > package.limit) {
                        // if receiving is more than supply, give remaining
                        if ((package.supply -= owed) <= 0) {
                            owed =  package.supply;
                        }
                        // otherwise, return limit amount
                        else if ((package.supply -= owed) > 0) {
                            owed = package.limit;
                        }
                        break; // stop the loop
                    }
                }
            }
            
            // set despense details
            pills.lastConsumtion = package.endTime;
            pills.owed = owed;
            pills.perSecond = owed / package.streamEnd;
        } 
        
        // if no dispensary, provide limit amount
        else if (!package.dispense) {
            pills.owed = package.limit;
        }

        package.supply -= owed; // remove pills from supply
        emit SupplyClaimed(packageId, package.supply);
    }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

