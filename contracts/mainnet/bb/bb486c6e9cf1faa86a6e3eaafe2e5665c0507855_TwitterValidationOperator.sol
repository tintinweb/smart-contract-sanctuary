// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/WhitelistAdminRole.sol

pragma solidity ^0.5.0;


/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: @openzeppelin/contracts/access/roles/WhitelistedRole.sol

pragma solidity ^0.5.0;



/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

// File: @openzeppelin/contracts/access/roles/CapperRole.sol

pragma solidity ^0.5.0;


contract CapperRole {
    using Roles for Roles.Role;

    event CapperAdded(address indexed account);
    event CapperRemoved(address indexed account);

    Roles.Role private _cappers;

    constructor () internal {
        _addCapper(msg.sender);
    }

    modifier onlyCapper() {
        require(isCapper(msg.sender), "CapperRole: caller does not have the Capper role");
        _;
    }

    function isCapper(address account) public view returns (bool) {
        return _cappers.has(account);
    }

    function addCapper(address account) public onlyCapper {
        _addCapper(account);
    }

    function renounceCapper() public {
        _removeCapper(msg.sender);
    }

    function _addCapper(address account) internal {
        _cappers.add(account);
        emit CapperAdded(account);
    }

    function _removeCapper(address account) internal {
        _cappers.remove(account);
        emit CapperRemoved(account);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: @chainlink/contracts/src/v0.5/interfaces/LinkTokenInterface.sol

pragma solidity ^0.5.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// File: contracts/util/ERC677Receiver.sol

pragma solidity 0.5.12;

contract ERC677Receiver {
    /**
    * @dev Method invoked when tokens transferred via transferAndCall method
    * @param _sender Original token sender
    * @param _value Tokens amount
    * @param _data Additional data passed to contract
    */
    function onTokenTransfer(address _sender, uint256 _value, bytes calldata _data) external;
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * 
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/IRegistry.sol

pragma solidity 0.5.12;


contract IRegistry is IERC721Metadata {

    event NewURI(uint256 indexed tokenId, string uri);

    event NewURIPrefix(string prefix);

    event Resolve(uint256 indexed tokenId, address indexed to);

    event Sync(address indexed resolver, uint256 indexed updateId, uint256 indexed tokenId);

    /**
     * @dev Controlled function to set the token URI Prefix for all tokens.
     * @param prefix string URI to assign
     */
    function controlledSetTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

    /**
     * @dev Mints a new a child token.
     * Calculates child token ID using a namehash function.
     * Requires the msg.sender to be the owner, approved, or operator of tokenId.
     * Requires the token not exist.
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the parent token
     * @param label subdomain label of the child token ID
     */
    function mintChild(address to, uint256 tokenId, string calldata label) external;

    /**
     * @dev Controlled function to mint a given token ID.
     * Requires the msg.sender to be controller.
     * Requires the token ID to not exist.
     * @param to address the given token ID will be minted to
     * @param label string that is a subdomain
     * @param tokenId uint256 ID of the parent token
     */
    function controlledMintChild(address to, uint256 tokenId, string calldata label) external;

    /**
     * @dev Transfers the ownership of a child token ID to another address.
     * Calculates child token ID using a namehash function.
     * Requires the msg.sender to be the owner, approved, or operator of tokenId.
     * Requires the token already exist.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param label subdomain label of the child token ID
     */
    function transferFromChild(address from, address to, uint256 tokenId, string calldata label) external;

    /**
     * @dev Controlled function to transfers the ownership of a token ID to
     * another address.
     * Requires the msg.sender to be controller.
     * Requires the token already exist.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function controlledTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Safely transfers the ownership of a child token ID to another address.
     * Calculates child token ID using a namehash function.
     * Implements a ERC721Reciever check unlike transferFromChild.
     * Requires the msg.sender to be the owner, approved, or operator of tokenId.
     * Requires the token already exist.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 parent ID of the token to be transferred
     * @param label subdomain label of the child token ID
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFromChild(address from, address to, uint256 tokenId, string calldata label, bytes calldata _data) external;

    /// Shorthand for calling the above ^^^ safeTransferFromChild function with an empty _data parameter. Similar to ERC721.safeTransferFrom.
    function safeTransferFromChild(address from, address to, uint256 tokenId, string calldata label) external;

    /**
     * @dev Controlled frunction to safely transfers the ownership of a token ID
     * to another address.
     * Implements a ERC721Reciever check unlike controlledSafeTransferFrom.
     * Requires the msg.sender to be controller.
     * Requires the token already exist.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 parent ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function controlledSafeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external;

    /**
     * @dev Burns a child token ID.
     * Calculates child token ID using a namehash function.
     * Requires the msg.sender to be the owner, approved, or operator of tokenId.
     * Requires the token already exist.
     * @param tokenId uint256 ID of the token to be transferred
     * @param label subdomain label of the child token ID
     */
    function burnChild(uint256 tokenId, string calldata label) external;

    /**
     * @dev Controlled function to burn a given token ID.
     * Requires the msg.sender to be controller.
     * Requires the token already exist.
     * @param tokenId uint256 ID of the token to be burned
     */
    function controlledBurn(uint256 tokenId) external;

    /**
     * @dev Sets the resolver of a given token ID to another address.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param to address the given token ID will resolve to
     * @param tokenId uint256 ID of the token to be transferred
     */
    function resolveTo(address to, uint256 tokenId) external;

    /**
     * @dev Gets the resolver of the specified token ID.
     * @param tokenId uint256 ID of the token to query the resolver of
     * @return address currently marked as the resolver of the given token ID
     */
    function resolverOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Controlled function to sets the resolver of a given token ID.
     * Requires the msg.sender to be controller.
     * @param to address the given token ID will resolve to
     * @param tokenId uint256 ID of the token to be transferred
     */
    function controlledResolveTo(address to, uint256 tokenId) external;

    /**
     * @dev Provides child token (subdomain) of provided tokenId.
     * @param tokenId uint256 ID of the token
     * @param label label of subdomain (for `aaa.bbb.crypto` it will be `aaa`)
     */
    function childIdOf(uint256 tokenId, string calldata label) external pure returns (uint256);

    /**
     * @dev Transfer domain ownership without resetting domain records.
     * @param to address of new domain owner
     * @param tokenId uint256 ID of the token to be transferred
     */
    function setOwner(address to, uint256 tokenId) external;
}

// File: contracts/IResolver.sol

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

contract IResolver {
    /**
     * @dev Reset all domain records and set new ones
     * @param keys New record keys
     * @param values New record values
     * @param tokenId ERC-721 token id of the domain
     */
    function reconfigure(string[] memory keys, string[] memory values, uint256 tokenId) public;

    /**
     * @dev Set or update domain records
     * @param keys New record keys
     * @param values New record values
     * @param tokenId ERC-721 token id of the domain
     */
    function setMany(string[] memory keys, string[] memory values, uint256 tokenId) public;

    /**
     * @dev Function to set record.
     * @param key The key set the value of.
     * @param value The value to set key to.
     * @param tokenId ERC-721 token id to set.
     */
    function set(string calldata key, string calldata value, uint256 tokenId) external;

    /**
     * @dev Function to reset all existing records on a domain.
     * @param tokenId ERC-721 token id to set.
     */
    function reset(uint256 tokenId) external;
}

// File: contracts/operators/TwitterValidationOperator.sol

pragma solidity 0.5.12;
// pragma experimental ABIEncoderV2;








contract TwitterValidationOperator is WhitelistedRole, CapperRole, ERC677Receiver {
    string public constant NAME = 'Chainlink Twitter Validation Operator';
    string public constant VERSION = '0.2.0';

    using SafeMath for uint256;

    event Validation(uint256 indexed tokenId, uint256 requestId, uint256 paymentAmount);
    event ValidationRequest(uint256 indexed tokenId, address indexed owner, uint256 requestId, string code);
    event PaymentSet(uint256 operatorPaymentPerValidation, uint256 userPaymentPerValidation);

    uint256 public operatorPaymentPerValidation;
    uint256 public userPaymentPerValidation;
    uint256 public withdrawableTokens;

    uint256 private frozenTokens;
    uint256 private lastRequestId = 1;
    mapping(uint256 => uint256) private userRequests;
    IRegistry private registry;
    LinkTokenInterface private linkToken;

    /**
    * @notice Deploy with the address of the LINK token, domains registry and payment amount in LINK for one valiation
    * @dev Sets the LinkToken address, Registry address and payment in LINK tokens for one validation
    * @param _registry The address of the .crypto Registry
    * @param _linkToken The address of the LINK token
    * @param _paymentCappers Addresses allowed to update payment amount per validation
    */
    constructor (IRegistry _registry, LinkTokenInterface _linkToken, address[] memory _paymentCappers) public {
        require(address(_registry) != address(0), "TwitterValidationOperator: INVALID_REGISTRY_ADDRESS");
        require(address(_linkToken) != address(0), "TwitterValidationOperator: INVALID_LINK_TOKEN_ADDRESS");
        require(_paymentCappers.length > 0, "TwitterValidationOperator: NO_CAPPERS_PROVIDED");
        registry = _registry;
        linkToken = _linkToken;
        uint256 cappersCount = _paymentCappers.length;
        for (uint256 i = 0; i < cappersCount; i++) {
            addCapper(_paymentCappers[i]);
        }
        renounceCapper();
    }

    /**
    * @dev Reverts if amount requested is greater than withdrawable balance
    * @param _amount The given amount to compare to `withdrawableTokens`
    */
    modifier hasAvailableFunds(uint256 _amount) {
        require(withdrawableTokens >= _amount, "TwitterValidationOperator: TOO_MANY_TOKENS_REQUESTED");
        _;
    }

    /**
     * @dev Reverts if contract doesn not have enough LINK tokens to fulfil validation
     */
    modifier hasAvailableBalance() {
        require(
            availableBalance() >= withdrawableTokens.add(operatorPaymentPerValidation),
            "TwitterValidationOperator: NOT_ENOUGH_TOKENS_ON_CONTRACT_BALANCE"
        );
        _;
    }

    /**
     * @dev Reverts if method called not from LINK token contract
     */
    modifier linkTokenOnly() {
        require(msg.sender == address(linkToken), "TwitterValidationOperator: CAN_CALL_FROM_LINK_TOKEN_ONLY");
        _;
    }

    /**
     * @dev Reverts if user sent incorrect amount of LINK tokens
     */
    modifier correctTokensAmount(uint256 _value) {
        require(_value == userPaymentPerValidation, "TwitterValidationOperator: INCORRECT_TOKENS_AMOUNT");
        _;
    }

    /**
     * @notice Method will be called by Chainlink node in the end of the job. Provides user twitter name and validation signature
     * @dev Sets twitter username and signature to .crypto domain records
     * @param _username Twitter username
     * @param _signature Signed twitter username. Ensures the validity of twitter username
     * @param _tokenId Domain token ID
     * @param _requestId Request id for validations were requested from Smart Contract. If validation was requested from operator `_requestId` should be equals to zero.
     */
    function setValidation(string calldata _username, string calldata _signature, uint256 _tokenId, uint256 _requestId)
    external
    onlyWhitelisted
    hasAvailableBalance {
        uint256 _payment = calculatePaymentForValidation(_requestId);
        withdrawableTokens = withdrawableTokens.add(_payment);
        IResolver Resolver = IResolver(registry.resolverOf(_tokenId));
        Resolver.set("social.twitter.username", _username, _tokenId);
        Resolver.set("validation.social.twitter.username", _signature, _tokenId);
        emit Validation(_tokenId, _requestId, _payment);
    }

    /**
    * @notice Method returns true if Node Operator able to set validation
    * @dev Returns true or error
    */
    function canSetValidation() external view onlyWhitelisted hasAvailableBalance returns (bool) {
        return true;
    }

    /**
     * @notice Method allows to update payments per one validation in LINK tokens
     * @dev Sets operatorPaymentPerValidation and userPaymentPerValidation variables
     * @param _operatorPaymentPerValidation Payment amount in LINK tokens when verification initiated via Operator
     * @param _userPaymentPerValidation Payment amount in LINK tokens when verification initiated directly by user via Smart Contract call
     */
    function setPaymentPerValidation(uint256 _operatorPaymentPerValidation, uint256 _userPaymentPerValidation) external onlyCapper {
        operatorPaymentPerValidation = _operatorPaymentPerValidation;
        userPaymentPerValidation = _userPaymentPerValidation;
        emit PaymentSet(operatorPaymentPerValidation, userPaymentPerValidation);
    }

    /**
    * @notice Allows the node operator to withdraw earned LINK to a given address
    * @dev The owner of the contract can be another wallet and does not have to be a Chainlink node
    * @param _recipient The address to send the LINK token to
    * @param _amount The amount to send (specified in wei)
    */
    function withdraw(address _recipient, uint256 _amount) external onlyWhitelistAdmin hasAvailableFunds(_amount) {
        withdrawableTokens = withdrawableTokens.sub(_amount);
        assert(linkToken.transfer(_recipient, _amount));
    }

    /**
    * @notice Initiate Twitter validation
    * @dev Method invoked when LINK tokens transferred via transferAndCall method. Requires additional encoded data
    * @param _sender Original token sender
    * @param _value Tokens amount
    * @param _data Encoded additional data needed to initiate domain verification: `abi.encode(uint256 tokenId, string code)`
    */
    function onTokenTransfer(address _sender, uint256 _value, bytes calldata _data) external linkTokenOnly correctTokensAmount(_value) {
        (uint256 _tokenId, string memory _code) = abi.decode(_data, (uint256, string));
        require(registry.isApprovedOrOwner(_sender, _tokenId), "TwitterValidationOperator: SENDER_DOES_NOT_HAVE_ACCESS_TO_DOMAIN");
        require(bytes(_code).length > 0, "TwitterValidationOperator: CODE_IS_EMPTY");
        require(registry.isApprovedOrOwner(address(this), _tokenId), "TwitterValidationOperator: OPERATOR_SHOULD_BE_APPROVED");
        frozenTokens = frozenTokens.add(_value);
        userRequests[lastRequestId] = _value;

        emit ValidationRequest(_tokenId, registry.ownerOf(_tokenId), lastRequestId, _code);
        lastRequestId = lastRequestId.add(1);
    }

    /**
    * @notice Method returns available LINK tokens balance minus held tokens
    * @dev Returns tokens amount
    */
    function availableBalance() public view returns (uint256) {
        return linkToken.balanceOf(address(this)).sub(frozenTokens);
    }

    function calculatePaymentForValidation(uint256 _requestId) private returns (uint256 _paymentPerValidation) {
        if (_requestId > 0) {// Validation was requested from Smart Contract. We need to search for price in mapping
            _paymentPerValidation = userRequests[_requestId];
            frozenTokens = frozenTokens.sub(_paymentPerValidation);
            delete userRequests[_requestId];
        } else {
            _paymentPerValidation = operatorPaymentPerValidation;
        }
    }
}