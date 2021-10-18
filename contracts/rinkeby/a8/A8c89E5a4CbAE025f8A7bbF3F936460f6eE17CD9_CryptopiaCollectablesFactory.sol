// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;

/**
 * ITokenRetriever
 *
 * Allows tokens to be retrieved from a contract
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
interface ITokenRetriever {

    /**
     * Extracts tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retrieveTokens(address _tokenContract) external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokenRetriever.sol";

/**
 * TokenRetriever
 *
 * Allows tokens to be retrieved from a contract
 *
 * #created 31/12/2021
 * #author Frank Bonnet
 */
contract TokenRetriever is ITokenRetriever {

    /**
     * Extracts tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retrieveTokens(address _tokenContract) override virtual public {
        IERC20 tokenInstance = IERC20(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(address(this));
        if (tokenBalance > 0) {
            tokenInstance.transfer(msg.sender, tokenBalance);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "../../ERC20/retriever/TokenRetriever.sol";
import "./ICryptopiaCollectables.sol";


/// @title Cryptopia Collectables Factory 
/// @dev Non-fungible token (ERC721) factory that mints collectables in Cryptopia
/// @author Frank Bonnet - <[email protected]>
contract CryptopiaCollectablesFactory is Ownable, TokenRetriever {

    enum Stages {
        Initializing,
        Initialized,
        Confirmed
    }

    /**
     *  Storage
     */
    uint constant MAX_SUPPLY = 10_000;
    uint constant MAX_MINT_PER_CALL = 10;
    uint constant MINT_FEE = 0.0721 ether;

    // Factory state
    uint public start;
    Stages public stage;
    address public token;
    address payable public beneficiary; 


    /**
     * Modifiers
     */
    /// @dev Throw if at stage other than current stage
    /// @param _stage expected stage to test for
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }


    /// @dev Throw if sender is not beneficiary
    modifier onlyBeneficiary() {
        require(beneficiary == msg.sender);
        _;
    }


    /**
     * Public Functions
     */
    /// @dev Start in the deployed stage
    constructor() {
        stage = Stages.Initializing;
    }


    /// @dev Initialize the factory
    /// @param _start The timestamp of the start date
    /// @param _token The token that is minted
    /// @param _beneficiary The beneficiary address
    function initialize(uint _start, address _token, address payable _beneficiary) public onlyOwner atStage(Stages.Initializing) {
        token = _token;
        start = _start;
        beneficiary = _beneficiary;
        stage = Stages.Initialized;
    }


    /// @dev Mint to beneficiary for givaways etc
    /// @param _numberOfItemsToMint Preminted items
    function mintBeneficiary(uint _numberOfItemsToMint) public onlyOwner atStage(Stages.Initialized) {
        for (
            uint i = 0;
            i < _numberOfItemsToMint;
            i++
        ) {
            ICryptopiaCollectables(token).mintTo(beneficiary);
        }
    }


    /// @dev Prove that beneficiary is able to sign transactions 
    /// and start minting
    function confirmBeneficiary() public onlyBeneficiary atStage(Stages.Initialized) {
        stage = Stages.Confirmed;
    }


    /// @dev Set contract URI
    /// @param _uri Location to contract info
    function setContractURI(string memory _uri) public onlyOwner {
        ICryptopiaCollectables(token).setContractURI(_uri);
    }


    /// @dev Set base token URI 
    /// @param _uri Base of location where token data is stored. To be postfixed with tokenId
    function setBaseTokenURI(string memory _uri) public onlyOwner {
        ICryptopiaCollectables(token).setBaseTokenURI(_uri);
    }


    /// @dev Mint `_numberOfItemsToMint` items to to `_toAddress`
    /// @param _numberOfItemsToMint Number of items to mint
    /// @param _toAddress Address to mint to
    function mint(uint _numberOfItemsToMint, address _toAddress) public payable atStage(Stages.Confirmed) {
        require(canMint(_numberOfItemsToMint), "Unable to mint items");
        require(_canPayMintFee(_numberOfItemsToMint, msg.value), "Unable to pay");

        if (_numberOfItemsToMint == 1) {
            ICryptopiaCollectables(token).mintTo(_toAddress);
        } else if (_numberOfItemsToMint > 1 && _numberOfItemsToMint <= MAX_MINT_PER_CALL) {
            for (
                uint i = 0;
                i < _numberOfItemsToMint;
                i++
            ) {
                ICryptopiaCollectables(token).mintTo(_toAddress);
            }
        }
    }


    /// @dev Returns if it's still possible to mint `_numberOfItemsToMint`
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return If the items can be minted
    function canMint(uint _numberOfItemsToMint) public view returns (bool) {
        if (block.timestamp < start){
            return false;
        }

        if (_numberOfItemsToMint > MAX_MINT_PER_CALL) {
            return false;
        }

        return IERC721Enumerable(token).totalSupply() <= (MAX_SUPPLY - _numberOfItemsToMint);
    }


    /// @dev Returns true if the call has enough ether to pay the minting fee
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return If the minting fee can be payed
    function canPayMintFee(uint _numberOfItemsToMint) public view returns (bool) {
        return _canPayMintFee(_numberOfItemsToMint, address(msg.sender).balance);
    }


    /// @dev Returns the ether amount needed to pay the minting fee
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return Ether amount needed to pay the minting fee
    function getMintFee(uint _numberOfItemsToMint) public pure returns (uint) {
        return _getMintFee(_numberOfItemsToMint);
    }


    /// @dev Allows the beneficiary to withdraw 
    function withdraw() public onlyBeneficiary {
        beneficiary.transfer(address(this).balance);
    }


    /// @dev Failsafe mechanism
    /// Allows the owner to retrieve tokens from the contract that 
    /// might have been send there by accident
    /// @param _tokenContract The address of ERC20 compatible token
    function retrieveTokens(address _tokenContract) override public onlyOwner {
        super.retrieveTokens(_tokenContract);

        // Retrieve tokens from our token contract
        ITokenRetriever(address(token)).retrieveTokens(_tokenContract);
    }


    /// @dev Failsafe and clean-up mechanism
    /// Makes the token URI's perminant since the factory is it's only owner
    function destroy() public onlyOwner {
        selfdestruct(beneficiary);
    }


    /**
     * Internal Functions
     */
    /// @dev Returns if the call has enough ether to pay the minting fee
    /// @param _numberOfItemsToMint Number of items to mint
    /// @param _received The amount that was received
    /// @return If the minting fee can be payed
    function _canPayMintFee(uint _numberOfItemsToMint, uint _received) internal pure returns (bool) {
        return _received >= _getMintFee(_numberOfItemsToMint);
    }


    /// @dev Returns the ether amount needed to pay the minting fee
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return Ether amount needed to pay the minting fee
    function _getMintFee(uint _numberOfItemsToMint) internal pure returns (uint) {
        return MINT_FEE * _numberOfItemsToMint;
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;


/// @title Cryptopia Collectables 
/// @dev Non-fungible token (ERC721) that represends collectables in Cryptopia
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaCollectables {


    /**
     * Public functions
     */
    /// @dev Initializes the token contract
    /// @param _proxyRegistry Whitelist for easy trading
    /// @param _initialContractURI Location to contract info
    /// @param _initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    /// @param _legendaryMistery ???
    /// @param _rareMistery ???
    function initialize(
        address _proxyRegistry, 
        string calldata _initialContractURI, 
        string calldata _initialBaseTokenURI, 
        bytes32 _legendaryMistery, 
        bytes32 _rareMistery) external;


    /// @dev Get contract URI
    /// @return Location to contract info
    function getContractURI() external view returns (string memory);


    /// @dev Set contract URI
    /// @param _uri Location to contract info
    function setContractURI(string memory _uri) external;


    /// @dev Get base token URI 
    /// @return Base of location where token data is stored. To be postfixed with tokenId
    function getBaseTokenURI() external view returns (string memory);


    /// @dev Set base token URI 
    /// @param _uri Base of location where token data is stored. To be postfixed with tokenId
    function setBaseTokenURI(string memory _uri) external;


    /// @dev getTokenURI() postfixed with the token ID baseTokenURI(){tokenID}
    /// @param _tokenId Token ID
    /// @return Location where token data is stored
    function getTokenURI(uint _tokenId) external view returns (string memory);


    /// @dev Read token traits from token randomness
    /// @param _tokenId Token to obtain traits for
    /// @return faction 
    ///     < 10000 = Eco (25%)
    ///     < 7500  = Tech (25%)
    ///     < 5000  = Industrial (25%)
    ///     < 2500  = Traditional (25%)
    /// @return cardType
    ///     < 10000 = Special (5%)
    ///     < 9500  = Default (95%)
    /// @return backgroundType
    ///     < 10000 = Special (5%)
    ///     < 9500  = Faction 1 (15%)
    ///     < 8000  = Faction 2 (15%)
    ///     < 6500  = Faction 3 (15%)
    ///     < 5000  = Neutral (50%)
    /// @return backgroundAttributes
    ///     < 10000 = Special (1%)
    ///     < 9900  = 3 attributes (5%)
    ///     < 9400  = 2 attributes (15%)
    ///     < 7900  = 1 attributes (15%)
    ///     < 4900  = Neutral (49%)
    /// @return characterPose
    ///     < 10000 = Approving (2%)
    ///     < 9800  = Thinking (3%)
    ///     < 9500  = Angry (10%)
    ///     < 8500  = Fear (15%)
    ///     < 7000  = Disaproving (20%)
    ///     < 5000  = Neutral (50%)
    /// @return characterAttributes
    ///     < 10000 = Legendary (0,1%)
    ///     < 8990  = Rare (19,9%)
    ///     < 8000  = None (80%)
    /// @return characterSpecials
    ///     < 10000 = Diamond (0,1%)
    ///     < 9970  = Gold (0,9%)
    ///     < 9900  = None (99%)
    /// @return easterEgg
    ///     < 10000 = Yes (0,05%)
    ///     < 9995  = No (99,95%)
    function getTokenTraits(uint _tokenId)
        external view 
        returns (
            uint32 faction,
            uint32 cardType,
            uint32 backgroundType,
            uint32 backgroundAttributes,
            uint32 characterPose,
            uint32 characterAttributes,
            uint32 characterSpecials,
            uint32 easterEgg
        );


    /// @dev Calculate the token score that determins the rarity
    /// @param _tokenId Token to obtain score for
    function getTokenScore(uint _tokenId) external view returns (uint);


    /// @dev Check if token with `_tokenId` is indeed a legendary item
    /// @param _tokenId Token to check
    /// @return True if _tokenId is legendary
    function isLegendary(uint _tokenId) external view returns (bool);


    /// @dev Become a legend and get rewarded with a legendary reward
    /// @param _myLegendaryWords The words that will make you a legend
    /// @param _legendaryTokenId A legendary token
    function becomeLegend(string calldata _myLegendaryWords, uint _legendaryTokenId) external;


    /// @dev Check if token with `_tokenId` is indeed a rare item
    /// @param _tokenId Token to check
    /// @return True if _tokenId is rare
    function isRare(uint _tokenId) external view returns (bool);


    /// @dev Take a chance and get rewarded with a unique reward
    /// @param _myUnusualWords Your words, not mine
    /// @param _rareTokenId A rare token
    function takeARareChance(string calldata _myUnusualWords, uint _rareTokenId) external;


    /// @dev Check if token with `_tokenId` contains an egg
    /// @param _tokenId Token to check
    /// @return True if _tokenId likes eggs
    function likesEggs(uint _tokenId) external view returns (bool);


    /// @dev Take a chance and get rewarded with a unique reward
    /// @param _someSauce What's an egg without sause?
    function bakeAnEgg(uint _someSauce) external;


    /// @dev Mints a token to an address with a tokenURI.
    /// @param _to address of the future owner of the token
    function mintTo(address _to) external;
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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