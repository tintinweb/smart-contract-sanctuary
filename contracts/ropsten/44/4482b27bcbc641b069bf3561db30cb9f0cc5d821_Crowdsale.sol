pragma solidity 0.4.24;

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

// File: contracts/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    )
    internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    )
    internal {
        require(token.approve(spender, value));
    }
}

// File: contracts/IToken.sol

/**
 * @title Full interface of VMN token
 */
contract IToken is IERC20 {
    function pause() external;
	function unpause() external;
    function addLockedAccount(address _account, uint256 amount, uint256 dateOfRelease) external;
}

// File: contracts/IEthPriceOraclize.sol

/**
 * @title EthPriceOraclize interface
 */
interface IEthPriceOraclize {
	function changeQueryDelay(uint256 newDelay) external;
	function getEthPrice() external view returns (uint256);
}

// File: contracts/Roles.sol

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage _role, address _account)
    internal {
        _role.bearer[_account] = true;
    }

    /**
     * @dev remove an account&#39;s access to this role
     */
    function remove(Role storage _role, address _account)
    internal {
        _role.bearer[_account] = false;
    }

    /**
     * @dev check if an account has this role
     * // reverts
     */
    function check(Role storage _role, address _account)
    internal
    view {
        require(has(_role, _account), "The msg.sender has no enough permission for calling this method");
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage _role, address _account)
    internal
    view
    returns (bool) {
        return _role.bearer[_account];
    }
}

// File: contracts/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
    using Roles for Roles.Role;

    mapping(string => Roles.Role) private roles;

    event RoleAdded(address indexed operator, string role);
    event RoleRemoved(address indexed operator, string role);

    /**
     * @dev reverts if addr does not have role
     * @param _operator address
     * @param _role the name of the role
     * // reverts
     */
    function _checkRole(address _operator, string _role)
    internal
    view {
        roles[_role].check(_operator);
    }

    /**
     * @dev determine if addr has role
     * @param _operator address
     * @param _role the name of the role
     * @return bool
     */
    function _hasRole(address _operator, string _role)
    internal
    view
    returns (bool) {
        return roles[_role].has(_operator);
    }

    /**
     * @dev add a role to an address
     * @param _operator address
     * @param _role the name of the role
     */
    function _addRole(address _operator, string _role)
    internal {
        roles[_role].add(_operator);
        emit RoleAdded(_operator, _role);
    }

    /**
     * @dev remove a role from an address
     * @param _operator address
     * @param _role the name of the role
     */
    function _removeRole(address _operator, string _role)
    internal {
        roles[_role].remove(_operator);
        emit RoleRemoved(_operator, _role);
    }

    /**
     * @dev modifier to scope access to a single role (uses msg.sender as addr)
     * @param _role the name of the role
     * // reverts
     */
    modifier onlyRole(string _role) {
        _checkRole(msg.sender, _role);
        _;
    }
}

// File: contracts/Multiownable.sol

/**
 * @title Multiownable
 * @dev The Multiownable contract has many addresses as a owners, which can call a METHODS
 * but method will work only after enough amount of owners will sign the same
 * method with the same parameters
 */
contract Multiownable {

    // VARIABLES

    uint256 private _ownersGeneration;
    uint256 private _howManyOwnersDecide;
    address[] private _owners;

    bytes32[] public allOperations;
    address private _insideCallSender;
    uint256 private _insideCallCount;
    address private _superOwner;

    // Reverse lookup tables for _owners and allOperations
    mapping(address => uint) private _ownersIndices; // Starts from 1
    mapping(bytes32 => uint) private _allOperationsIndicies;

    // Owners voting mask per operations
    mapping(bytes32 => uint256) private _votesMaskByOperation;
    mapping(bytes32 => uint256) private _votesCountByOperation;

    // EVENTS

    event OwnershipTransferred(address[] previousOwners, uint howManyOwnersDecide, address[] newOwners, uint newHowManyOwnersDecide);
    event OperationCreated(bytes32 operation, uint howMany, uint ownersCount, address proposer);
    event OperationUpvoted(bytes32 operation, uint votes, uint howMany, uint ownersCount, address upvoter);
    event OperationPerformed(bytes32 operation, uint howMany, uint ownersCount, address performer);
    event OperationDownvoted(bytes32 operation, uint votes, uint ownersCount, address downvoter);
    event OperationCancelled(bytes32 operation, address lastCanceller);

    // ACCESSORS

    function isOwner() external view returns (bool) {
        return _ownersIndices[msg.sender] > 0;
    }

    function ownersCount() external view returns (uint) {
        return _owners.length;
    }

    function allOperationsCount() external view returns (uint) {
        return allOperations.length;
    }

    // MODIFIERS

    /**
     * @dev Allows to perform method by any of the owners
     */
    modifier onlyAnyOwner {
        if (_checkHowManyOwners(1)) {
            bool update = (_insideCallSender == address(0));
            if (update) {
                _insideCallSender = msg.sender;
                _insideCallCount = 1;
            }
            _;
            if (update) {
                _insideCallSender = address(0);
                _insideCallCount = 0;
            }
        }
    }

    /**
     * @dev Allows to perform method only after many owners call it with the same arguments
     */
    modifier onlyManyOwners {
        if (_checkHowManyOwners(_howManyOwnersDecide)) {
            bool update = (_insideCallSender == address(0));
            if (update) {
                _insideCallSender = msg.sender;
                _insideCallCount = _howManyOwnersDecide;
            }
            _;
            if (update) {
                _insideCallSender = address(0);
                _insideCallCount = 0;
            }
        }
    }

    /**
     * @dev Allows to perform method only after all owners call it with the same arguments
     */
    modifier onlyAllOwners {
        if (_checkHowManyOwners(_owners.length)) {
            bool update = (_insideCallSender == address(0));
            if (update) {
                _insideCallSender = msg.sender;
                _insideCallCount = _owners.length;
            }
            _;
            if (update) {
                _insideCallSender = address(0);
                _insideCallCount = 0;
            }
        }
    }

    /**
     * @dev Allows to perform method only after some owners call it with the same arguments
     */
    modifier onlySomeOwners(uint howMany) {
        require(howMany > 0, "onlySomeOwners: howMany argument is zero");
        require(howMany <= _owners.length, "onlySomeOwners: howMany argument exceeds the number of owners");

        if (_checkHowManyOwners(howMany)) {
            bool update = (_insideCallSender == address(0));
            if (update) {
                _insideCallSender = msg.sender;
                _insideCallCount = howMany;
            }
            _;
            if (update) {
                _insideCallSender = address(0);
                _insideCallCount = 0;
            }
        }
    }

    // CONSTRUCTOR

    constructor() public {
        _owners.push(msg.sender);
        _ownersIndices[msg.sender] = 1;
        _howManyOwnersDecide = 1;
    }

    // INTERNAL METHODS

    /**
     * @dev onlyManyOwners modifier helper
     */
    function _checkHowManyOwners(uint howMany) internal returns (bool) {
        if (_insideCallSender == msg.sender) {
            require(howMany <= _insideCallCount, "_checkHowManyOwners: nested _owners modifier check require more owners");
            return true;
        }

        uint ownerIndex = _ownersIndices[msg.sender] - 1;
        require(ownerIndex < _owners.length, "_checkHowManyOwners: msg.sender is not an owner");
        bytes32 operation = keccak256(abi.encodePacked(msg.data, _ownersGeneration));

        require((_votesMaskByOperation[operation] & (2 ** ownerIndex)) == 0, "_checkHowManyOwners: owner already voted for the operation");

        _votesMaskByOperation[operation] |= (2 ** ownerIndex);
        uint operationVotesCount = _votesCountByOperation[operation] + 1;
        _votesCountByOperation[operation] = operationVotesCount;

        if (operationVotesCount == 1) {
            _allOperationsIndicies[operation] = allOperations.length;
            allOperations.push(operation);
            emit OperationCreated(
                operation,
                howMany,
                _owners.length,
                msg.sender
            );
        }
        emit OperationUpvoted(
            operation,
            operationVotesCount,
            howMany,
            _owners.length,
            msg.sender
        );

        // If enough owners confirmed the same operation
        if (_votesCountByOperation[operation] >= howMany) {
            if (howMany != 1 && _votesMaskByOperation[operation] & (2 ** (_ownersIndices[_superOwner] - 1)) == 0) {
                return false;
            }

            _deleteOperation(operation);
            emit OperationPerformed(
                operation,
                howMany,
                _owners.length,
                msg.sender
            );

            return true;
        }

        return false;
    }

    /**
     * @dev Used to delete cancelled or performed operation
     * @param operation defines which operation to delete
     */
    function _deleteOperation(bytes32 operation) internal {
        uint index = _allOperationsIndicies[operation];
        if (index < allOperations.length - 1) { // Not last
            allOperations[index] = allOperations[allOperations.length - 1];
            _allOperationsIndicies[allOperations[index]] = index;
        }
        allOperations.length--;

        delete _votesMaskByOperation[operation];
        delete _votesCountByOperation[operation];
        delete _allOperationsIndicies[operation];
    }

    // PUBLIC METHODS

    /**
     * @dev Allows _owners to change their mind by cancelling _votesMaskByOperation operations
     * @param operation defines which operation to delete
     */
    function cancelPending(bytes32 operation) external onlyAnyOwner {
        uint ownerIndex = _ownersIndices[msg.sender] - 1;
        require((_votesMaskByOperation[operation] & (2 ** ownerIndex)) != 0, "cancelPending: operation not found for this user");
        _votesMaskByOperation[operation] &= ~(2 ** ownerIndex);
        uint operationVotesCount = _votesCountByOperation[operation] - 1;
        _votesCountByOperation[operation] = operationVotesCount;
        emit OperationDownvoted(
            operation,
            operationVotesCount,
            _owners.length,
            msg.sender
        );
        if (operationVotesCount == 0) {
            _deleteOperation(operation);
            emit OperationCancelled(operation, msg.sender);
        }
    }

    /**
     * @dev Allows owners to change ownership
     * @param newOwners defines array of addresses of new owners
     * @param newHowManyOwnersDecide defines how many owners can decide
     */
    function transferOwnershipWithHowMany(address[] newOwners, address superOwner, uint256 newHowManyOwnersDecide) external onlyManyOwners {
        require(newOwners.length > 0, "transferOwnershipWithHowMany: owners array is empty");
        require(superOwner != address(0), "transferOwnershipWithHowMany: superOwner address is not valid");
        require(newOwners.length <= 256, "transferOwnershipWithHowMany: owners count is greater then 256");
        require(newHowManyOwnersDecide > 0, "transferOwnershipWithHowMany: newHowManyOwnersDecide equal to 0");
        require(newHowManyOwnersDecide <= newOwners.length, "transferOwnershipWithHowMany: newHowManyOwnersDecide exceeds the number of owners");

        // Reset owners reverse lookup table
        for (uint j = 0; j < _owners.length; j++) {
            delete _ownersIndices[_owners[j]];
        }

        _superOwner = superOwner;
        _ownersIndices[_superOwner] = 1;

        for (uint i = 0; i < newOwners.length; i++) {
            require(newOwners[i] != address(0), "transferOwnershipWithHowMany: owners array contains zero");
            require(_ownersIndices[newOwners[i]] == 0, "transferOwnershipWithHowMany: owners array contains duplicates");
            _ownersIndices[newOwners[i]] = i + 2;
        }

        emit OwnershipTransferred(
            _owners,
            _howManyOwnersDecide,
            newOwners,
            newHowManyOwnersDecide
        );

        _owners = newOwners;
        _owners.push(_superOwner);
        _howManyOwnersDecide = newHowManyOwnersDecide;
        allOperations.length = 0;
        _ownersGeneration++;
    }

}

// File: contracts/UserPermissions.sol

/**
 * @title UserPermissions
 * @dev The User Permissions contract has a whitelist, grant access and backend addresses, and provides basic authorization control functions.
 */
contract UserPermissions is RBAC, Multiownable {
    using SafeMath for uint256;

    // Grant Access Investor Role
    string private constant ROLE_GRANT = "grant";

    // Name Of The Whitelisted Role.
    string private constant ROLE_WHITELISTED = "whitelist";

    // Backend Based Account Role
    string private constant ROLE_BACKEND = "backend";

    // Mapping Of Addresses And Individual Limits
    mapping (address => uint256) private _grantAccessAmounts;


    // -----------------------------------------
    // GRANT ACCESS INVESTORS
    // If Admin Allow Some Investors Can Buy Tokens From "Early Investors" Balance Even If Private Sale Is Finished
    // -----------------------------------------

    /**
     * @dev Determine if an investor has grant access
     * @return true if the account has, false otherwise.
     */
    function hasGrantAccess(address _investor) public view returns (bool) {
        return _hasRole(_investor, ROLE_GRANT);
    }

    /**
     * @dev Return the value which investor can use for buying tokens from Early investor limit
     * @return usd from investor limit
     */
    function getAmountOfGrantAccessInvestor(address _investor) public view returns (uint256) {
        return _grantAccessAmounts[_investor];
    }

    /**
     * @dev Determine if the investor has enough tokens in his Early balance or not
     * @return true if the account has, false otherwise.
     */
    function hasEnoughGrantAmount(address _investor, uint256 _amount) public view returns (bool) {
        bool isEnough = _grantAccessAmounts[_investor] >= _amount;
        return isEnough;
    }

    /**
     * @dev Change allowance for _investor, which is already has grant access
     */
    function changeAllowance(address _investor, uint256 _amount) external onlyManyOwners returns (bool) {
        _grantAccessAmounts[_investor] = _amount;
        return true;
    }

    /**
     * @dev remove an address from the grant access addresses
     * @param _investor address
     * @return true if the address was removed from the grant access addresses,
     * false if the address wasn&#39;t in the grant access in the first place
     */
    function removeAddressFromGrantAccess(address _investor) external onlyAnyOwner {
        _removeRole(_investor, ROLE_GRANT);
    }

    /**
     * @dev add an investor address to the grant
     * @param _investor address
     * @return true if the address was added to the grant access addresses, false if the address was already in there
     */
    function _addAddressToGrantAccess(address _investor, uint256 _amountUsd) internal {
        _addRole(_investor, ROLE_GRANT);
        _grantAccessAmounts[_investor] = _amountUsd;
    }

    /**
     * @dev Decrease allowance for the investor after token purchasing
     */
    function _decreaseAllowance(address _investor, uint256 _amount) internal returns (bool) {
        uint256 currentLimit = _grantAccessAmounts[_investor];
        _grantAccessAmounts[_investor] = currentLimit.sub(_amount);
        return true;
    }

    // -----------------------------------------
    // BACKEND
    // -----------------------------------------

    /**
     * @dev Throws if operator not the backend address
     */
    modifier onlyBackEnd() {
        _checkRole(msg.sender, ROLE_BACKEND);
        _;
    }

    /**
     * @dev add an address to the backend
     * @param _operator address
     * @return true if the address was added to the backend addresses, false if the address was already in the backend addresses
     */
    function addAddressToBackEnd(address _operator) public onlyManyOwners {
        _addRole(_operator, ROLE_BACKEND);
    }

    /**
     * @dev remove an address from the backend addresses
     * @param _operator address
     * @return true if the address was removed from the backend,
     * false if the address wasn&#39;t in the backend in the first place
     */
    function removeAddressFromBackend(address _operator) external onlyManyOwners {
        _removeRole(_operator, ROLE_BACKEND);
    }

    /**
     * @dev Determine if an account is backend address.
     * @return true if the account is backend, false otherwise.
     */
    function isBackend() external view returns (bool) {
        return _hasRole(msg.sender, ROLE_BACKEND);
    }


    // -----------------------------------------
    // WHITELIST
    // -----------------------------------------

    /**
     * @dev Throws if operator is not whitelisted.
     * @param _operator address
     */
    modifier onlyIfWhitelisted(address _operator) {
        _checkRole(_operator, ROLE_WHITELISTED);
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param _operator address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address _operator) public onlyBackEnd {
        _addRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev remove an address from the whitelist
     * @param _operator address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn&#39;t in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address _operator) public onlyBackEnd {
        _removeRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev add addresses to the whitelist
     * @param _operators addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] _operators) external onlyBackEnd {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param _operators addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren&#39;t in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] _operators) external onlyBackEnd {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

    /**
     * @dev Determine if an account is whitelisted.
     * @return true if the account is whitelisted, false otherwise.
     */
    function isWhitelisted(address _operator) external view returns (bool) {
        return _hasRole(_operator, ROLE_WHITELISTED);
    }

}

// File: contracts/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev The main smart contract, which responsible for token distribution and token management
 */
contract Crowdsale is UserPermissions {
    using SafeMath for uint256;
    using SafeERC20 for IToken;

    IToken private _token;
    IEthPriceOraclize private _oraclize;

    address private _wallet;
    bool private _open = true;

    uint256 private _weiRaised;
    uint256 private _usdRaised;
    uint256 private _tokensSold;

    uint256 private constant _minUsdPrivate = 50000000;       // $500,000.00
    uint256 private constant _minUsdPublicFirst = 25000000;   // $250,000.00
    uint256 private constant _minUsdPublicSecond = 55;        // $0.55

    uint256 private _equityInvestors = 571428571 * 1 ether;
    uint256 private _teamTokens = 457142857 * 1 ether;
    uint256 private _advisorsTokens = 140000000 * 1 ether;
    uint256 private _foundationTokens = 637857143 * 1 ether;
    uint256 private _syndicateTokens = 10000000 * 1 ether;

    struct SaleStage {
        uint256 initialAmount;
        uint256 availableTokens;
        uint256 rate;
        bool finalized;
    }

    SaleStage private _earlyInvestors = SaleStage(300000000 * 1 ether, 300000000 * 1 ether, 10, false);
    SaleStage private _privateSale = SaleStage(271428571 * 1 ether, 271428571 * 1 ether, 10, false);
    SaleStage private _publicFirst = SaleStage(85714286 * 1 ether, 85714286 * 1 ether, 35, false);
    SaleStage private _publicSecond = SaleStage(27272727 * 1 ether, 27272727 * 1 ether, 55, false);

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    enum Stage { Early, PrivateSale, PublicFirst, PublicSecond }

    /**
     * @dev Constructor
     */
    constructor(address token, address oraclize, address wallet, address backend) public {
        _token = IToken(token);
        _oraclize = IEthPriceOraclize(oraclize);
        _wallet = wallet;

        addAddressToBackEnd(backend);
    }

    // -----------------------------------------
    // STATE CHANGING METHODS
    // -----------------------------------------

    /**
     * @dev fallback function
     */
    function() external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param beneficiary Address performing the token purchase
     */
    function buyTokens(address beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate eth to usd amount
        uint256 usdAmount = _getEthToUsdPrice(weiAmount);
        SaleStage storage stage = _detectInvestorGroup(usdAmount, beneficiary);

        uint256 tokens = _getTokenAmount(usdAmount, stage.rate);
        stage.availableTokens = stage.availableTokens.sub(tokens);

        bool isEarly = (stage.initialAmount == _earlyInvestors.initialAmount);
        _updatePurchasingState(weiAmount, usdAmount, tokens, isEarly, beneficiary);
        _processPurchase(beneficiary, tokens);
        _forwardFunds();

        emit TokensPurchased(
            msg.sender,
            beneficiary,
            weiAmount,
            tokens
        );
    }

    /**
     * @dev Transfer tokens to BTC/BCH and Fiat buyers using USD calculation
     */
    function transferTokensToNonEthBuyer(address beneficiary, uint256 usdAmount) public onlyManyOwners returns (bool) {
        _preValidatePurchase(beneficiary, usdAmount);

        SaleStage storage stage = _detectInvestorGroup(usdAmount, beneficiary);

        uint256 tokens = _getTokenAmount(usdAmount, stage.rate);
        stage.availableTokens = stage.availableTokens.sub(tokens);

        bool isEarly = (stage.initialAmount == _earlyInvestors.initialAmount);
        _updatePurchasingState(0, usdAmount, tokens, isEarly, beneficiary);
        _processPurchase(beneficiary, tokens);

        emit TokensPurchased(
            msg.sender,
            beneficiary,
            0,
            tokens
        );

        return true;
    }

    /**
     * @dev Transfer tokens to BTC/BCH and Fiat buyers using USD calculation to many addresses
     */
    function transferTokensToNonEthBuyerToMany(address[] addresses, uint256[] usdAmounts) external onlyManyOwners returns (uint256) {
        require(addresses.length > 0, "transferTokensToNonEthBuyerToMany: receivers array is empty");
        require(usdAmounts.length > 0, "transferTokensToNonEthBuyerToMany: usdAmounts array is empty");
        require(addresses.length == usdAmounts.length, "transferTokensToNonEthBuyerToMany: the array of receivers and usdAmounts is not equal");

        uint256 i = 0;

        while (i < addresses.length) {
            transferTokensToNonEthBuyer(addresses[i], usdAmounts[i]);
            i++;
        }

        return i;
    }

    /**
     * @dev Transfer token to team, advisors, foundation, early and equity users by tokens amount
     * @param to of receiver
     * @param amount for send
     * @param id of limit
     * 0 - Team
     * 1 - Advisor
     * 2 - Foundation
     * 3 - Syndicat
     * 4 - Early
     * 5 - Equity
     * 6 - Private
     * 7 - Public 1
     * 8 - Public 2
     */
    function transferTokensManually(address to, uint256 amount, uint256 id) public onlyManyOwners returns (bool) {
        _preValidatePurchase(to, amount);

        if (id == 0) {
            require(_teamTokens >= amount, "transferTokensManually: not enough tokens in team balance");
            _teamTokens = _teamTokens.sub(amount);
            _processPurchase(to, amount);
        } else if (id == 1) {
            require(_advisorsTokens >= amount, "transferTokensManually: not enough tokens in advisors balance");
            _advisorsTokens = _advisorsTokens.sub(amount);
            _processPurchase(to, amount);
        } else if (id == 2) {
            require(_foundationTokens >= amount, "transferTokensManually: not enough tokens in foundation balance");
            _foundationTokens = _foundationTokens.sub(amount);
            _processPurchase(to, amount);
        } else if (id == 3) {
            require(_syndicateTokens >= amount, "transferTokensManually: not enough tokens in syndicates balance");
            _syndicateTokens = _syndicateTokens.sub(amount);
            _processPurchase(to, amount);
        } else if (id == 4) {
            require(_earlyInvestors.availableTokens >= amount, "transferTokensManually: not enough tokens in early investors balance");
            _earlyInvestors.availableTokens = _earlyInvestors.availableTokens.sub(amount);
            _processPurchase(to, amount);
        } else if (id == 5) {
            require(_equityInvestors >= amount, "transferTokensManually: not enough tokens in equity investors balance");
            _equityInvestors = _equityInvestors.sub(amount);
            _token.addLockedAccount(to, amount, block.timestamp + 730 days);
            _deliverTokens(to, amount);
        } else if (id == 6) {
            require(_privateSale.availableTokens >= amount, "transferTokensManually: not enough tokens in private sale balance");
            _privateSale.availableTokens = _privateSale.availableTokens.sub(amount);
            _processPurchase(to, amount);
        } else if (id == 7) {
            require(_publicFirst.availableTokens >= amount, "transferTokensManually: not enough tokens in public first balance");
            _publicFirst.availableTokens = _publicFirst.availableTokens.sub(amount);
            _processPurchase(to, amount);
        } else if (id == 8) {
            require(_publicSecond.availableTokens >= amount, "transferTokensManually: not enough tokens in public second balance");
            _publicSecond.availableTokens = _publicSecond.availableTokens.sub(amount);
            _processPurchase(to, amount);
        }

        return true;
    }

    /**
     * @dev Transfer token to many wallets of team, advisors, foundation, early and equity users
     * @param addresses of receivers
     * @param amounts for send
     * @param id of limit
     * 0 - Team
     * 1 - Advisor
     * 2 - Foundation
     * 3 - Syndicat
     * 4 - Early
     * 5 - Equity
     * 6 - Private
     * 7 - Public 1
     * 8 - Public 2
     */
    function transferTokensManuallyToMany(address[] addresses, uint256[] amounts, uint256 id) external onlyManyOwners returns (uint256) {
        require(addresses.length > 0, "transferTokensManuallyToMany: receivers array is empty");
        require(amounts.length > 0, "transferTokensManuallyToMany: amounts array is empty");
        require(addresses.length == amounts.length, "transferTokensManuallyToMany: the array of receivers and amounts is not equal");

        uint256 i = 0;

        while (i < addresses.length) {
            transferTokensManually(addresses[i], amounts[i], id);
            i++;
        }

        return i;
    }

    /**
     * @dev Finalaze the certain stage by id, if limit of this stage is bigger than 0 all tokens will be go to syndicat limit
     * @param id - Id of stage
     * 0 - Early investors
     * 1 - Private sale
     * 2 - Public sale first
     * 3 - Public sale second
     */
    function finalizeStage(uint256 id) external onlyManyOwners {
        SaleStage storage stage = _detectStage(id);

        // After closing this stage all tokens of the current stage will redirected to syndicate balance
        if (stage.availableTokens > 0) {
            _syndicateTokens += stage.availableTokens;
            stage.availableTokens = 0;
        }

        stage.finalized = true;
    }

    /**
     * @dev Change wallet address, all future funds will be transferred to this address
     */
    function changeWallet(address newWallet) external onlyManyOwners {
        _wallet = newWallet;
    }

    /**
     * @dev Change wallet address, all future funds will be transferred to this address
     */
    function changeEthPriceQueryDelay(uint256 newDelay) external onlyManyOwners {
        _oraclize.changeQueryDelay(newDelay);
    }

    /**
     * @dev add an investor address to the grant
     * @param _investor address
     * @return true if the address was added to the grant access addresses, false if the address was already in there
     */
    function addAddressToGrantAccess(address _investor, uint256 _amountUsd) external onlyManyOwners {
        _addAddressToGrantAccess(_investor, _amountUsd);
    }


    // -----------------------------------------
    // EMERGENCY FUNCTIONS
    // -----------------------------------------

    // Emergency stop and resume token transactions (using pause/resume method from token contract)

    /**
     * @dev Freeze token transactions for all token owners (Pausable token)
     */
    function freezeAllTransactions() external onlyManyOwners {
        _token.pause();
    }

    /**
     * @dev Unfreeze token transactions for all token owners (Pausable token)
     */
    function unFreezeAllTransactions() external onlyManyOwners {
        _token.unpause();
    }

    // Emergency stop and resume incoming investments

    /**
     * @dev Disable incoming funds
     */
    function pauseCrowdsale() external onlyManyOwners {
        _open = false;
    }

    /**
     * @dev Ebable incoming funds
     */
    function resumeCrowdsale() external onlyManyOwners {
        _open = true;
    }


    // -----------------------------------------
    // INTERNAL METHODS
    // -----------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * @param beneficiary Address performing the token purchase
     * @param amount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 amount) internal view onlyIfWhitelisted(beneficiary) {
        require(_open, "_preValidatePurchase: crowdsale closed");
        require(beneficiary != address(0), "_preValidatePurchase: beneficiary address is not valid");
        require(amount != 0, "_preValidatePurchase: funded amount is 0");
        require(_getEthToUsdPrice(amount) >= 1, "_preValidatePurchase: for correct calculation funded amount should be bigger than $0.01");
    }

    /**
     * @dev Convert ETH to USD and return amount
     * @param weiAmount ETH amount which will convert to USD
     */
    function _getEthToUsdPrice(uint256 weiAmount) internal view returns (uint256) {
        return (weiAmount.mul(_getEthPrice())).div(1 ether);
    }

    /**
     * @dev Getting price from oraclize contract
     */
    function _getEthPrice() internal view returns (uint256) {
        return _oraclize.getEthPrice();
    }

    /**
     * @dev Override to extend the way in which usd is converted to tokens.
     * @param usdAmount Value in usd to be converted into tokens
     * @return Number of tokens that can be purchased with the specified usdAmount
     */
    function _getTokenAmount(uint256 usdAmount, uint256 rate) internal pure returns (uint256) {
        return (usdAmount.mul(1 ether)).div(rate);
    }

    /**
     * @dev Detect to which group investor related
     */
    function _detectInvestorGroup(uint256 usdAmount, address beneficiary) internal view returns (SaleStage storage) {
        if (_checkStage(Stage.PrivateSale, usdAmount, beneficiary)) {
            return _privateSale;
        } else if (_checkStage(Stage.Early, usdAmount, beneficiary)) {
            return _earlyInvestors;
        } else if (_checkStage(Stage.PublicFirst, usdAmount, beneficiary)) {
            return _publicFirst;
        } else if (_checkStage(Stage.PublicSecond, usdAmount, beneficiary)) {
            return _publicSecond;
        } else {
            revert();
        }
    }

    /**
     * @dev Check which stage contain all necessary details to be active
     */
    function _checkStage(Stage stage, uint256 usdAmount, address beneficiary) internal view returns (bool) {
        if (stage == Stage.PrivateSale) {
            return (
                !_privateSale.finalized && 
                usdAmount >= _minUsdPrivate && 
                _privateSale.availableTokens >= _getTokenAmount(usdAmount, _privateSale.rate)
            );
        } else if (stage == Stage.Early) {
            return (
                hasGrantAccess(beneficiary) && 
                hasEnoughGrantAmount(beneficiary, usdAmount) && 
                !_earlyInvestors.finalized && 
                usdAmount >= _minUsdPrivate && 
                _earlyInvestors.availableTokens >= _getTokenAmount(usdAmount, _earlyInvestors.rate)
            );
        } else if (stage == Stage.PublicFirst) {
            return (
                !_publicFirst.finalized && 
                usdAmount >= _minUsdPublicFirst && 
                _publicFirst.availableTokens >= _getTokenAmount(usdAmount, _publicFirst.rate)
            );
        } else if (stage == Stage.PublicSecond) {
            return (
                !_publicSecond.finalized && 
                _publicSecond.availableTokens >= _getTokenAmount(usdAmount, _publicSecond.rate)
            );
        }
    }

    /**
     * @dev Detect stage by ID
     */
    function _detectStage(uint256 id) internal view returns (SaleStage storage) {
        if (id == 0) {
            return _earlyInvestors;
        } else if (id == 1) {
            return _privateSale;
        } else if (id == 2) {
            return _publicFirst;
        } else if (id == 3) {
            return _publicSecond;
        } else {
            revert();
        }
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _token.addLockedAccount(beneficiary, tokenAmount, block.timestamp + 365 days);
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
     */
    function _updatePurchasingState(uint256 weiAmount, uint256 usdAmount, uint256 tokens, bool isEarlyInvestor, address beneficiary) internal {
        if (isEarlyInvestor) {
            _decreaseAllowance(beneficiary, usdAmount);
        }

        // update global state
        _weiRaised += weiAmount;
        _usdRaised += usdAmount;
        _tokensSold += tokens;
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    /**
     * @dev add an investor address to the grant
     * @param _investor address
     * @return true if the address was added to the grant access addresses, false if the address was already in there
     */
    function _addAddressToGrantAccess(address _investor, uint256 _amountUsd) internal {
        uint256 privateSaleUsd = (_privateSale.availableTokens * _privateSale.rate) / 1 ether;
        require(_amountUsd + privateSaleUsd >= 50000000, "addAddressToGrantAccess: the minimum amount should be bigger $500k");

        super._addAddressToGrantAccess(_investor, _amountUsd);
    }

    // -----------------------------------------
    // GETTERS
    // -----------------------------------------

    /**
     * @param id - Id of stage
     * 0 - Early investors
     * 1 - Private sale
     * 2 - Public sale first
     * 3 - Public sale second
     * @return initial amount, current amount, rate, finalized or not
     */
    function getStageState(uint256 id) external view returns (uint256, uint256, uint256, bool) {
        SaleStage memory stage = _detectStage(id);

        return (
            stage.initialAmount,
            stage.availableTokens,
            stage.rate,
            stage.finalized
        );
    }

    /**
     * @return tokens reserve of team, advisors, foundation and syndicat balancecs
     */
    function getTokensReserve() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            _teamTokens,
            _advisorsTokens,
            _foundationTokens,
            _syndicateTokens,
            _equityInvestors
        );
    }

    /**
     * @return the available amount of tokens for this investor by price $0.10/$0.35/$0.55
     */
    function getAvailableTokenForUser(address investor) external view returns (uint256, uint256, uint256) {
        uint256 tokensFor10Cents = _privateSale.availableTokens;

        if (hasGrantAccess(investor)) {
            uint256 earlyTokens = _getTokenAmount(getAmountOfGrantAccessInvestor(investor), _earlyInvestors.rate);
            tokensFor10Cents += earlyTokens;
        }

        return (
            tokensFor10Cents,
            _publicFirst.availableTokens,
            _publicSecond.availableTokens
        );
    }

    /**
     * @return the token being sold.
     */
    function token() external view returns (IToken) {
        return _token;
    }

    /**
     * @return the oraclize interface
     */
    function oraclize() external view returns (IEthPriceOraclize) {
        return _oraclize;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() external view returns (address) {
        return _wallet;
    }

    /**
     * @return the mount of wei raised.
     */
    function weiRaised() external view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return the mount of USD raised.
     */
    function usdRaised() external view returns (uint256) {
        return _usdRaised;
    }

    /**
     * @return the mount of tokens sold.
     */
    function tokensSold() external view returns (uint256) {
        return _tokensSold;
    }

    /**
     * @return the mount of tokens sold.
     */
    function isOpen() external view returns (bool) {
        return _open;
    }

    /**
     * @return the address where funds are collected.
     */
    function minLimitPrivateSale() external pure returns (uint256) {
        return _minUsdPrivate;
    }

    /**
     * @return the address where funds are collected.
     */
    function minLimitPublicFirstSale() external pure returns (uint256) {
        return _minUsdPublicFirst;
    }

    /**
     * @return the address where funds are collected.
     */
    function minLimitPublicSecondSale() external pure returns (uint256) {
        return _minUsdPublicSecond;
    }
}