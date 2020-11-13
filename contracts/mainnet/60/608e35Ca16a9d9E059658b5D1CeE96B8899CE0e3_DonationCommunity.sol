// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

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

// File: openzeppelin-solidity/contracts/access/roles/WhitelistAdminRole.sol

pragma solidity ^0.5.0;



/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
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

// File: openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol

pragma solidity ^0.5.0;




/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
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
        _removeWhitelisted(_msgSender());
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Secondary.sol

pragma solidity ^0.5.0;

/**
 * @dev A Secondary contract can only be used by its primary account (the one that created it).
 */
contract Secondary is Context {
    address private _primary;

    /**
     * @dev Emitted when the primary contract changes.
     */
    event PrimaryTransferred(
        address recipient
    );

    /**
     * @dev Sets the primary account to the one that is creating the Secondary contract.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _primary = msgSender;
        emit PrimaryTransferred(msgSender);
    }

    /**
     * @dev Reverts if called from any account other than the primary.
     */
    modifier onlyPrimary() {
        require(_msgSender() == _primary, "Secondary: caller is not the primary account");
        _;
    }

    /**
     * @return the address of the primary.
     */
    function primary() public view returns (address) {
        return _primary;
    }

    /**
     * @dev Transfers contract to a new primary.
     * @param recipient The address of new primary.
     */
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0), "Secondary: new primary is the zero address");
        _primary = recipient;
        emit PrimaryTransferred(recipient);
    }
}

// File: contracts/ERC20.sol

pragma solidity ^0.5.2;

interface ERC20 {
    function totalSupply() external view returns (uint supply);

    function balanceOf(address _owner) external view returns (uint balance);

    function transfer(address _to, uint _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint _value) external returns (bool success);

    function approve(address _spender, uint _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint remaining);

    function decimals() external view returns (uint digits);

    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// File: contracts/BondingVaultInterface.sol

pragma solidity ^0.5.2;

interface BondingVaultInterface {

    function fundWithReward(address payable _donor) external payable;

    function getEthKidsToken() external view returns (address);

    function calculateReward(uint256 _ethAmount) external view returns (uint256 _tokenAmount);

    function calculateReturn(uint256 _tokenAmount) external view returns (uint256 _returnEth);

    function sweepVault(address payable _operator) external;

    function addWhitelisted(address account) external;

    function removeWhitelisted(address account) external;

}

// File: contracts/YieldVaultInterface.sol

pragma solidity ^0.5.8;

interface YieldVaultInterface {

    function withdraw(address _token, address _atoken, uint _amount) external;

    function addWhitelisted(address account) external;

    function removeWhitelisted(address account) external;

}

// File: contracts/RegistryInterface.sol

pragma solidity ^0.5.2;



interface RegistryInterface {

    function getCurrencyConverter() external view returns (address);

    function getBondingVault() external view returns (BondingVaultInterface);

    function yieldVault() external view returns (YieldVaultInterface);

    function getCharityVaults() external view returns (address[] memory);

    function communityCount() external view returns (uint256);

}

// File: contracts/RegistryAware.sol

pragma solidity ^0.5.2;


interface RegistryAware {

    function setRegistry(address _registry) external;

    function getRegistry() external view returns (RegistryInterface);
}

// File: contracts/community/CharityVault.sol

pragma solidity ^0.5.2;






/**
 * @title CharityVault
 * @dev Vault which holds the assets until the community leader(s) decide to transfer
 * them to the actual charity destination.
 * Deposit and withdrawal calls come only from the actual community contract
 */
contract CharityVault is RegistryAware, Secondary {
    using SafeMath for uint256;

    RegistryInterface public registry;
    uint256 public sumStats;

    event LogDonationReceived(
        uint256 amount,
        address indexed account
    );
    event LogDonationWithdrawn(
        uint256 amount,
        address indexed account
    );

    /**
    * @dev 'deposit' must be used instead
    **/
    function() external {
        //no 'payable' here
    }

    /**
     * @dev Receives some ETH and stores it.
     * @param _payee the donor's address.
     */
    function deposit(address _payee) public payable {
        sumStats = sumStats.add(msg.value);
        emit LogDonationReceived(msg.value, _payee);
    }

    /**
     * @dev Withdraw some of accumulated balance for a _payee.
     */
    function withdraw(address payable _payee, uint256 _payment) public onlyPrimary {
        require(_payment > 0 && address(this).balance >= _payment, "Insufficient funds in the charity vault");
        _payee.transfer(_payment);
        emit LogDonationWithdrawn(_payment, _payee);
    }

    function setRegistry(address _registry) public onlyPrimary {
        registry = (RegistryInterface)(_registry);
    }

    function getRegistry() public view returns (RegistryInterface) {
        return registry;
    }

}

// File: contracts/community/IDonationCommunity.sol

pragma solidity ^0.5.2;

interface IDonationCommunity {

    function donateDelegated(address payable _donator) external payable;

    function name() external view returns (string memory);

    function charityVault() external view returns (address);
}

// File: contracts/community/DonationCommunity.sol

pragma solidity ^0.5.2;







/**
 * @title DonationCommunity
 * @dev Manages donations and owns a charity vault
 * Aware of the EthKidsRegistry and passes a part of donations to the whole community
 * The 'admin' is the community leader
 * The 'whitelisted' account is the EthKidsRegistry and must be specified
 * prior to adding to the EthKidsRegistry
 */
contract DonationCommunity is IDonationCommunity, RegistryAware, WhitelistedRole {
    using SafeMath for uint256;

    uint256 public constant CHARITY_DISTRIBUTION = 90; //%, the rest funds bonding curve

    string private _name;
    CharityVault public charityVault;

    RegistryInterface public registry;

    event LogDonationReceived
    (
        address from,
        uint256 amount
    );
    event LogPassToCharity
    (
        address by,
        address intermediary,
        uint256 amount,
        string ipfsHash
    );

    /**
    * @dev not allowed, can't store ETH
    **/
    function() external {
        //no 'payable' here
    }

    /**
    * @dev Constructor
    * @param name for reference
    */
    constructor (string memory name) public {
        _name = name;
        charityVault = new CharityVault();
    }

    function setRegistry(address _registry) public onlyWhitelisted {
        registry = (RegistryInterface)(_registry);
        charityVault.setRegistry(_registry);
    }

    function getRegistry() public view returns (RegistryInterface) {
        return registry;
    }

    function allocate(uint256 donation) internal pure returns (uint256 _charityAllocation, uint256 _bondingAllocation) {
        uint256 _multiplier = 100;
        _charityAllocation = (donation).mul(CHARITY_DISTRIBUTION).div(_multiplier);
        _bondingAllocation = donation.sub(_charityAllocation);
        return (_charityAllocation, _bondingAllocation);
    }

    function myReward(uint256 _ethAmount) public view returns (uint256 tokenAmount) {
        (uint256 _charityAllocation, uint256  _bondingAllocation) = allocate(_ethAmount);
        return getRegistry().getBondingVault().calculateReward(_bondingAllocation);
    }

    function myReturn(uint256 _tokenAmount) public view returns (uint256 returnEth) {
        return getRegistry().getBondingVault().calculateReturn(_tokenAmount);
    }

    function donate() public payable {
        donateDelegated(msg.sender);
    }

    /**
    * @dev Donate funds on behalf of someone else.
    * Primary use is to pass the actual donor when the caller is a proxy, like KyberConverter
    * @param _donor address that will be recorded as a donor and will receive the community tokens
    **/
    function donateDelegated(address payable _donor) public payable {
        require(msg.value > 0, "Must include some ETH to donate");

        (uint256 _charityAllocation, uint256  _bondingAllocation) = allocate(msg.value);
        charityVault.deposit.value(_charityAllocation)(_donor);

        getRegistry().getBondingVault().fundWithReward.value(_bondingAllocation)(_donor);

        emit LogDonationReceived(_donor, msg.value);
    }

    /**
    * @dev Donate funds on behalf of someone else without being rewarded.
    * @param _donor address that will be recorded as a donor
    **/
    function donateDelegatedNoReward(address payable _donor) public payable {
        require(msg.value > 0, "Must include some ETH to donate");

        (uint256 _charityAllocation, uint256  _bondingAllocation) = allocate(msg.value);
        charityVault.deposit.value(_charityAllocation)(_donor);

        address payable bondingVaultPayable = address(uint160(address(getRegistry().getBondingVault())));
        bondingVaultPayable.transfer(_bondingAllocation);

        emit LogDonationReceived(_donor, msg.value);
    }

    function passToCharity(uint256 _amount, address payable _intermediary, string memory _ipfsHash) public onlyWhitelistAdmin {
        require(_intermediary != address(0));
        charityVault.withdraw(_intermediary, _amount);

        emit LogPassToCharity(msg.sender, _intermediary, _amount, _ipfsHash);
    }

    function passToCharityWithInterest(uint256 _amount, address payable _intermediary, string memory _ipfsHash, address _aaveToken, address _aaveAToken) public onlyWhitelistAdmin {
        passToCharity(_amount, _intermediary, _ipfsHash);
        //distribute accumulated interest amongst the communities
        registry.yieldVault().withdraw(_aaveToken, _aaveAToken, 0);
    }

    function name() public view returns (string memory) {
        return _name;
    }


}