pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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
    mapping(uint256 => mapping(address => Syrum)) public syrum; // packageId => user => details

    event PackageCreation(uint256 packageId, address token, uint256 supply, uint256 startTime, uint256 endTime);
    event PackageLockAdded(uint256 packageId, address token, uint256 startTime);
    event PackageConsumption(uint256 packageId, uint256 amount);
    event SupplyClaimed(uint256 packageId, uint256 remainingSupply);


    // ------------------------
    //  Package Creation
    // ------------------------

    /**
     * @dev Static airdrop: best for even distribution
     * @param streamEnd when puncture drip ends (if 0, no stream)
     * @param startTime when redemption begins
     * @param endTime when redemption halts
     * @param token token being airdropped
     * @param supply amount of tokens being airdropped
     * @param perPerson default amount per consumer
     */
    function packageStatic(
        uint96 streamEnd,
        uint96 startTime,
        uint96 endTime,
        address token,
        uint256 supply,
        uint256 perPerson
    ) public returns(uint256 packageId) {
        PillPackage storage package = pillPackage[pillPackages];
        
        IERC20(token).transferFrom(msg.sender, address(this), supply);

        if (streamEnd == 0) { package.streamEnd = streamEnd; }
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
     * @param streamEnd when puncture drip ends (if 0, no stream)
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
        
        IERC20(token).transferFrom(msg.sender, address(this), supply);

        if (streamEnd == 0) { package.streamEnd = streamEnd; }
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
        Dispensary storage pills = dispensary[packageId][msg.sender];
        require(!pills.consumed, 'Overdose');
        require(unlockPackage(packageId, msg.sender));

        uint256 receiving;
        if (pills.owed == 0) { initialCalculation(packageId); }
        
        PillPackage memory package = pillPackage[packageId];
        if (package.streamEnd == 0) {
            require(package.endTime > block.timestamp, "Empty");
            pills.consumed = true; 
            receiving = package.limit;
            pills.owed -= receiving;
        } else if (package.streamEnd != 0) {
            require(package.endTime < block.timestamp, "Brewing");
            receiving = pills.perSecond * (block.timestamp - pills.lastConsumtion);
            pills.lastConsumtion = block.timestamp;
            pills.owed -= receiving;
            if (pills.owed == 0) { pills.consumed = true; }
            pills.perSecond = pills.owed / package.streamEnd;

            Syrum memory brew = syrum[packageId][msg.sender];
            if (!brew.claimed && brew.amount[0] != 0) { extractSyrum(packageId); }
        }

        IERC20(package.token).transfer(msg.sender, receiving);
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
        PillPackage memory package = pillPackage[pillPackages];
        require(package.supply != 0, 'Supply outage');
        require(unlockPackage(packageId, msg.sender));
        Syrum storage brew = syrum[packageId][msg.sender];

        // cycle through package tokens and try to match inputted
        for (uint8 i; i < package.erc20Pills.length; i++) {
            // cycle through inputted tokens 
            for (uint8 r; r < erc20s.length; r++) {
                // if inputted token == package token, depo and record
                if (erc20s[i] == package.erc20Pills[r].token) {
                    IERC20(erc20s[i]).transferFrom(msg.sender, address(this), erc20Tokens[i]);
                    brew.tokens[i] = erc20s[i];
                    brew.amount[i] = erc20Tokens[i];
                    break;
                }
                assert(brew.tokens[0] != address(bytes20('')));
            }
        }

        return true;
    }


    /**
     * @dev User can extract syrum from lock
     * @param packageId package to consume from
     */
    function extractSyrum(uint256 packageId) public {
        Syrum storage brew = syrum[packageId][msg.sender];
        require(!brew.claimed && brew.amount[0] != 0, 'Already claimed');
        brew.claimed = true;
        for (uint8 i; i < brew.tokens.length; i++) {
            brew.amount[i] = 0;
            IERC20(brew.tokens[i]).transfer(msg.sender, brew.amount[i]);
        }
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

        // calculate dispensary details for user
        if (package.streamEnd != 0) {
        
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
        else if (package.streamEnd == 0) {
            pills.owed = package.limit;
        }

        package.supply -= owed; // remove pills from supply
        emit SupplyClaimed(packageId, package.supply);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}