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

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;


/// @title IAuthenticator
/// @dev Authenticator interface
/// @author Frank Bonnet - <[email protected]>
interface IAuthenticator {
    

    /// @dev Authenticate 
    /// Returns whether `_account` is authenticated
    /// @param _account The account to authenticate
    /// @return whether `_account` is successfully authenticated
    function authenticate(address _account) external view returns (bool);
}

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

import "../../../../infrastructure/authentication/IAuthenticator.sol";
import "../../ERC20/retriever/TokenRetriever.sol";
import "./ICryptopiaEarlyAccessToken.sol";


/// @title Cryptopia EarlyAccess Token Factory 
/// @dev Non-fungible token (ERC721) factory that mints CryptopiaEarlyAccess tokens
/// @author Frank Bonnet - <[email protected]>
contract CryptopiaEarlyAccessTokenFactory is Ownable, TokenRetriever {

    enum Stages {
        Initializing,
        Deploying,
        Deployed
    }

    /**
     *  Storage
     */
    uint constant NUMBER_OF_FACTIONS = 4;
    uint constant MAX_SUPPLY = 10_000;
    uint constant MAX_MINT_PER_CALL = 12;
    uint constant MINT_FEE = 0.1 ether;
    uint constant PERCENTAGE_DENOMINATOR = 10_000;

    // Beneficiary
    address payable public beneficiary; 

    // Stakeholders
    mapping (address => uint) public stakeholders;
    address[] private stakeholdersIndex;

     // State
    uint public start;
    Stages public stage;
    address public token;

    /**
     * Modifiers
     */
    /// @dev Throw if at stage other than current stage
    /// @param _stage expected stage to test for
    modifier atStage(Stages _stage) {
        require(stage == _stage, "In wrong stage");
        _;
    }
    

    /// @dev Throw sender isn't a stakeholders
    modifier onlyStakeholders() {
        require(stakeholders[msg.sender] > 0, "Only stakeholders");
        _;
    }


    /**
     * Public Functions
     */
    /// @dev Start in the Initializing stage
    constructor() {
        stage = Stages.Initializing;
    }


    /// @dev Setup stakeholders
    /// @param _stakeholders The addresses of the stakeholders (first stakeholder is the beneficiary)
    /// @param _percentages The percentages of the stakeholders 
    function setupStakeholders(address payable[] calldata _stakeholders, uint[] calldata _percentages) public onlyOwner atStage(Stages.Initializing) {
        require(stakeholdersIndex.length == 0, "Stakeholders already setup");
        
        // First stakeholder is expected to be the beneficiary
        beneficiary = _stakeholders[0]; 

        uint total = 0;
        for (uint i = 0; i < _stakeholders.length; i++) {
            stakeholdersIndex.push(_stakeholders[i]);
            stakeholders[_stakeholders[i]] = _percentages[i];
            total += _percentages[i];
        }

        require(total == PERCENTAGE_DENOMINATOR, "Stakes should add up to 100%");
    }


    /// @dev Initialize the factory
    /// @param _start The timestamp of the start date
    /// @param _token The token that is minted
    function initialize(uint _start, address _token) public onlyOwner atStage(Stages.Initializing) {
        require(stakeholdersIndex.length > 0, "Setup stakeholders first");
        token = _token;
        start = _start;
        stage = Stages.Deploying;
    }


    /// @dev Premint for givaways etc
    /// @param _numberOfItemsToMint Number of items to mint
    /// @param _toAddress Receiving address
    /// @param _referrer Referrer choice
    /// @param _faction Faction choice
    function premint(uint _numberOfItemsToMint, address _toAddress, uint _referrer, uint8 _faction) public onlyOwner atStage(Stages.Deploying) {
        for (uint i = 0; i < _numberOfItemsToMint; i++) {
            ICryptopiaEarlyAccessToken(token).mintTo(_toAddress, _referrer, _faction);
        }
    }


    /// @dev Deploy the contract (setup is final)
    function deploy() public onlyOwner atStage(Stages.Deploying) {
        stage = Stages.Deployed;
    }


    /// @dev Set contract URI
    /// @param _uri Location to contract info
    function setContractURI(string memory _uri) public onlyOwner {
        ICryptopiaEarlyAccessToken(token).setContractURI(_uri);
    }


    /// @dev Set base token URI 
    /// @param _uri Base of location where token data is stored. To be postfixed with tokenId
    function setBaseTokenURI(string memory _uri) public onlyOwner {
        ICryptopiaEarlyAccessToken(token).setBaseTokenURI(_uri);
    }


    /// @dev MintSet `_numberOfSetsToMint` items to to `_toAddress`
    /// @param _numberOfSetsToMint Number of items to mint
    /// @param _toAddress Address to mint to
    /// @param _referrer Referrer choice
    function mintSet(uint _numberOfSetsToMint, address _toAddress, uint _referrer) public payable atStage(Stages.Deployed) {
        require(canMint(_numberOfSetsToMint * NUMBER_OF_FACTIONS), "Unable to mint items");
        require(_canPayMintFee(_numberOfSetsToMint * NUMBER_OF_FACTIONS, msg.value), "Unable to pay");

        if (_numberOfSetsToMint == 1) {
            for (uint8 faction = 0; faction < NUMBER_OF_FACTIONS; faction++)
            {
                ICryptopiaEarlyAccessToken(token).mintTo(_toAddress, _referrer, faction);
            }
        } else if (_numberOfSetsToMint > 1 && _numberOfSetsToMint * 4 <= MAX_MINT_PER_CALL) {
            for (uint i = 0; i < _numberOfSetsToMint; i++) {
                for (uint8 faction = 0; faction < NUMBER_OF_FACTIONS; faction++)
                {
                    ICryptopiaEarlyAccessToken(token).mintTo(_toAddress, _referrer, faction);
                }
            }
        }
    }


    /// @dev Mint `_numberOfItemsToMint` items to to `_toAddress`
    /// @param _numberOfItemsToMint Number of items to mint
    /// @param _toAddress Address to mint to
    /// @param _referrer Referrer choice
    /// @param _faction Faction choice
    function mint(uint _numberOfItemsToMint, address _toAddress, uint _referrer, uint8 _faction) public payable atStage(Stages.Deployed) {
        require(canMint(_numberOfItemsToMint), "Unable to mint items");
        require(_canPayMintFee(_numberOfItemsToMint, msg.value), "Unable to pay");

        if (_numberOfItemsToMint == 1) {
            ICryptopiaEarlyAccessToken(token).mintTo(_toAddress, _referrer, _faction);
        } else if (_numberOfItemsToMint > 1 && _numberOfItemsToMint <= MAX_MINT_PER_CALL) {
            for (uint i = 0; i < _numberOfItemsToMint; i++) {
                ICryptopiaEarlyAccessToken(token).mintTo(_toAddress, _referrer, _faction);
            }
        }
    }


    /// @dev Returns if it's still possible to mint `_numberOfItemsToMint`
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return If the items can be minted
    function canMint(uint _numberOfItemsToMint) public view returns (bool) {
        
        // Enforce started rule
        if (block.timestamp < start){
            return false;
        }

        // Enforce max per call rule
        if (_numberOfItemsToMint > MAX_MINT_PER_CALL) {
            return false;
        }

        // Enforce max token rule
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
    function withdraw() public onlyStakeholders {
        uint balance = address(this).balance;
        for (uint i = 0; i < stakeholdersIndex.length; i++)
        {
            payable(stakeholdersIndex[i]).transfer(
                balance * stakeholders[stakeholdersIndex[i]] / PERCENTAGE_DENOMINATOR);
        }
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


/// @title CryptopiaEarlyAccess Token
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaEarlyAccessToken {


    /**
     * Public functions
     */
    /// @dev Initializes the token contract
    /// @param _proxyRegistry Whitelist for easy trading
    /// @param _initialContractURI Location to contract info
    /// @param _initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function initialize(
        address _proxyRegistry, 
        string calldata _initialContractURI, 
        string calldata _initialBaseTokenURI) external;


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


    /// @dev Mints a token to an address.
    /// @param _to address of the future owner of the token
    /// @param _referrer referrer that's added to the token uri
    /// @param _faction faction that's added to the token uri
    function mintTo(address _to, uint _referrer, uint8 _faction) external;
}