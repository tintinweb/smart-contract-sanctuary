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

// File: contracts/aave/IAToken.sol

pragma solidity ^0.5.8;

interface IAToken {

    function balanceOf(address _user) external view returns (uint256);

    function redeem(uint256 _amount) external;

    function principalBalanceOf(address _user) external view returns (uint256);

    function getInterestRedirectionAddress(address _user) external view returns (address);

    function allowInterestRedirectionTo(address _to) external;

    function redirectInterestStream(address _to) external;

    function isTransferAllowed(address _user, uint256 _amount) external view returns (bool);

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

// File: contracts/YieldVault.sol

pragma solidity ^0.5.8;







contract YieldVault is YieldVaultInterface, RegistryAware, WhitelistedRole {

    using SafeMath for uint256;
    RegistryInterface public registry;
    mapping(address => uint256) public withdrawalBacklog;

    /**
     * @dev Payable fallback to receive ETH while converting ERC
     **/
    function() external payable {
    }

    function balance(address _atoken) public view returns (uint256) {
        return IAToken(_atoken).balanceOf(address(this));
    }

    function historicBalance(address _atoken) public view returns (uint256) {
        return balance(_atoken).add(withdrawalBacklog[_atoken]);
    }

    function communityVaultBalance(address _atoken) public view returns (uint256) {
        return balance(_atoken) / registry.communityCount();
    }

    /**
    * @dev Community triggers the withdrawal from Aave.
    * All aTokens (x communityCount) will be redeemed and the resulting ERC will be distributed among the communities
    * _amount = 0 means 'ALL'
    **/
    function withdraw(address _token, address _atoken, uint _amount) public onlyWhitelisted {
        if (_amount == 0) {
            //withdraw all available
            _amount = communityVaultBalance(_atoken);
        } else {
            require(communityVaultBalance(_atoken) >= _amount);
        }

        if (_amount > 0) {
            uint totalAmount = _amount.mul(registry.communityCount());
            IAToken aToken = IAToken(_atoken);
            //if not used as a collateral
            require(aToken.isTransferAllowed(address(this), totalAmount));
            aToken.redeem(totalAmount);
            withdrawalBacklog[_atoken] = withdrawalBacklog[_atoken].add(totalAmount);

            ERC20 token = ERC20(_token);
            //approve for swap
            token.approve(address(currencyConverter()), totalAmount);
            //swap
            currencyConverter().executeSwapMyERCToETH(token, totalAmount);

            //fund the BondingVault
            uint _bondingAllocation = (address(this).balance).mul(10).div(100);
            address payable bondingVaultPayable = address(uint160(address(getRegistry().getBondingVault())));
            bondingVaultPayable.transfer(_bondingAllocation);

            //distribute ETH all over communities
            uint ethAmout = (address(this).balance).div(registry.communityCount());
            for (uint8 i = 0; i < registry.communityCount(); i++) {
                CharityVaultInterface charityVault = CharityVaultInterface(registry.getCharityVaults()[i]);
                charityVault.deposit.value(ethAmout)(msg.sender);
            }
        }
    }

    function currencyConverter() internal view returns (CurrencyConverterInterface) {
        return CurrencyConverterInterface(getRegistry().getCurrencyConverter());
    }

    function setRegistry(address _registry) public onlyWhitelistAdmin {
        registry = (RegistryInterface)(_registry);
    }

    function getRegistry() public view returns (RegistryInterface) {
        return registry;
    }

}

interface CurrencyConverterInterface {
    function executeSwapMyERCToETH(ERC20 srcToken, uint srcQty) external;
}

interface CharityVaultInterface {
    function deposit(address _payee) external payable;
}