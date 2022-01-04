// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC165Spec.sol";
import "../interfaces/ERC20Spec.sol";
import "../utils/AccessControl.sol";

/**
 * @title Artificial Liquid Intelligence ERC20 Token (ALI) vesting
 * 
 * @notice Allows to release 10% grant immediately after vesting period starts,
 *          release 90% grant devided by total vesting months on mnthly basis 
 */
contract AliVesting is AccessControl {

    // Grant struct to hold granted and claimed amount data for recipient
    struct Grant {
        uint256 amount;
        uint256 totalClaimed;
    }

    /**
	 * @dev Fired in addTokenGrant()
	 *
	 * @param recipient an address of the recipient
	 * @param grantedAmount amount of token grant added to the recipient
	 */
    event GrantAdded(address indexed recipient, uint256 grantedAmount);
    
    /**
	 * @dev Fired in revokeTokenGrant()
	 *
	 * @param recipient an address of the recipient to whom grant is revoked
	 * @param amountVested amount of token vested by recipient till the grant is revoked
     * @param amountNotVested amount of token not vested by recipient till the grant is revoked
	 */
    event GrantRevoked(address indexed recipient, uint256 amountVested, uint256 amountNotVested);

    /**
	 * @dev Fired in release()
	 *
	 * @param recipient an address of the recipient
	 * @param amount token amount released to the recipient
	 */
    event Released(address indexed recipient, uint256 amount);

    /**
	 * @dev ALI ERC20 contract address to transfer tokens
	 */
    address public immutable aliContract;

    /**
	 * @dev Total number of seconds of 30 days month
	 */
    uint32 private constant SECONDS_PER_MONTH = 30 minutes ;//days; TEST Changes

    /**
	 * @dev Starting time from when vesting will begin
	 */
    uint32 public immutable startTimestamp;
    
    /**
	 * @notice Allows release of the tokens publicly for recipients
	 *
	 * @dev When `FEATURE_RELEASE` is enabled, recipient can release unclaimed tokens
	 */
    uint32 public constant FEATURE_RELEASE = 0x0000_0001;

    /**
	 * @notice Grant manager is responsible for adding and revoking token grants
	 *
	 * @dev Role ROLE_GRANT_MANAGER allows add/revoke token grant via addTokenGrant()/revokeTokenGrant function
	 */
    uint32 public constant ROLE_GRANT_MANAGER = 0x0001_0000;

    /**
	 * @dev Duration in months of the cliff in which tokens will begin to vest
	 */
    uint8 public immutable cliffInMonths;

    /**
	 * @dev Total vesting duration in months
	 */
    uint8 public immutable vestingDurationInMonths;

    /**
	 * @dev Mapping from recipient to `Grant` data
	 */
    mapping (address => Grant) public tokenGrants;

    /**
	 * @dev Creates/deploys AliVesting
	 *
	 * @param _ali deployed ALI ERC20 smart contract address
	 * @param _startTimestamp starting time from when vesting will begin  
	 * @param _cliffInMonths duration in months of the cliff in which tokens will begin to vest
	 * @param _vestingDurationInMonths total vesting duration in months 
	 */
    constructor(
        address _ali,
        uint32 _startTimestamp,
        uint8 _cliffInMonths,
        uint8 _vestingDurationInMonths
    ) {
		// verify inputs are set
		require(_ali != address(0), "ALI Token addr is not set");

		// verify inputs are valid smart contracts of the expected interfaces
		require(ERC165(_ali).supportsInterface(type(ERC20).interfaceId), "unexpected ALI Token type");
		
		// setup smart contract internal state
		aliContract = _ali;
		
        cliffInMonths = _cliffInMonths;

        vestingDurationInMonths = _vestingDurationInMonths;

        startTimestamp = _startTimestamp == 0 ? blockTimestamp() : _startTimestamp;

	}

    /**
	 * @dev Adds token grant to given recipient 
	 *
	 * @param _recipient address of the recipient 
	 * @param _amount token amount to be granted  
	 */
    function addTokenGrant(
        address _recipient,
        uint256 _amount    
    ) 
        external
    {
        require(isSenderInRole(ROLE_GRANT_MANAGER), "Access denied");

        require(tokenGrants[_recipient].amount == 0, "Grant already exists");
        
        // Calculate monthly vesting amount
        uint256 amountVestedPerMonth = (_amount * 9) / (vestingDurationInMonths * 10);

        require(amountVestedPerMonth > 0, "Amount not enough");

        // Transfer the grant tokens under the control of the vesting contract
        ERC20(aliContract).transferFrom(msg.sender, address(this), _amount);

        // Bind data to `Grant`
        Grant memory grant = Grant({
            amount: _amount,
            totalClaimed: 0
        });

        // Record `Grant` data for given recipient
        tokenGrants[_recipient] = grant;
        
        // Emits an event
        emit GrantAdded(_recipient, _amount);
    }

    /**
	 * @dev Revokes token grant from given recipient 
	 *
	 * @param _recipient address of the recipient to whom grant is revoked 
	 */
    function revokeTokenGrant(address _recipient) 
        external
    {
        require(isSenderInRole(ROLE_GRANT_MANAGER), "Access denied");

        // Calculate vested amount
        uint256 vested = vestedAmount(_recipient);

        // Calculated non vested amount
        uint256 notVested = tokenGrants[_recipient].amount - vested;

        // Calculate unclaimed amount from vested amount
        uint256 unclaimed = vested - tokenGrants[_recipient].totalClaimed;

        // Transfer non vested tokens to grant manager
        ERC20(aliContract).transfer(msg.sender, notVested);

        // Transfer unclaimed tokens to recipient
        ERC20(aliContract).transfer(_recipient, unclaimed);

        // Delete data to `Grant`
        Grant memory grant = Grant({
            amount: 0,
            totalClaimed: 0
        });

        // Record `Grant` data for given recipient
        tokenGrants[_recipient] = grant;

        // Emits an event
        emit GrantRevoked(_recipient, vested, notVested);

    }

    /**
	 * @dev Releases unclaimed tokens to recipient  
	 *
	 * @param _recipient address of the recipient 
	 */
    function release(address _recipient) external {
        
        require(isFeatureEnabled(FEATURE_RELEASE), "Release is disabled");

        // Calculate vested amount
        uint256 vested = vestedAmount(_recipient);

        // Calculate unclaimed amount
        uint256 unclaimed = vested - tokenGrants[_recipient].totalClaimed; 
        
        require(unclaimed > 0, "No tokens to release");

        // Add unclaimed amount to total claimed amount
        tokenGrants[_recipient].totalClaimed = tokenGrants[_recipient].totalClaimed + unclaimed;
        
        // Transfer unclaimed tokens to recipient
        ERC20(aliContract).transfer(_recipient, unclaimed);

        // Emits an event
        emit Released(_recipient, unclaimed);
    }

    /**
     * @dev Calculates the amount that has already vested for given recipient
     *
     * @param _recipient address of the recipient
     */
    function vestedAmount(address _recipient) public view returns (uint256) {
        
        // Check if vesting period started
        if (blockTimestamp() < startTimestamp) {
            return 0;
        }

        // Calculate elapsed time in seconds
        uint32 elapsedTime = blockTimestamp() - startTimestamp;
        
        // Calculate elapsed time in months
        uint32 elapsedMonths = elapsedTime / SECONDS_PER_MONTH;

        // Put thresold to elapsed months to stop vesting calculation after total vesting duartion is over
        elapsedMonths = (elapsedMonths > vestingDurationInMonths) ? vestingDurationInMonths : elapsedMonths; 

        // Check if cliff reached
        if (elapsedMonths < cliffInMonths) {
            
            return tokenGrants[_recipient].amount / 10;

        } else {
            
            uint256 vested = tokenGrants[_recipient].amount * (1 + ((9 * elapsedMonths) / vestingDurationInMonths)) / 10; 
            
            return vested;

        }

    }

    /**
     * @dev Returns current block timestamp
     */
    function blockTimestamp() public view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    /**
     * @dev Returns unclaimed amount for given recipient
     */
    function unclaimedAmount(address _recipient) public view returns (uint256) {
        return (vestedAmount(_recipient) - tokenGrants[_recipient].totalClaimed); 
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title ERC-165 Standard Interface Detection
 *
 * @dev Interface of the ERC165 standard, as defined in the
 *       https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * @dev Implementers can declare support of contract interfaces,
 *      which can then be queried by others.
 *
 * @author Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 */
interface ERC165 {
	/**
	 * @notice Query if a contract implements an interface
	 *
	 * @dev Interface identification is specified in ERC-165.
	 *      This function uses less than 30,000 gas.
	 *
	 * @param interfaceID The interface identifier, as specified in ERC-165
	 * @return `true` if the contract implements `interfaceID` and
	 *      `interfaceID` is not 0xffffffff, `false` otherwise
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title EIP-20: ERC-20 Token Standard
 *
 * @notice The ERC-20 (Ethereum Request for Comments 20), proposed by Fabian Vogelsteller in November 2015,
 *      is a Token Standard that implements an API for tokens within Smart Contracts.
 *
 * @notice It provides functionalities like to transfer tokens from one account to another,
 *      to get the current token balance of an account and also the total supply of the token available on the network.
 *      Besides these it also has some other functionalities like to approve that an amount of
 *      token from an account can be spent by a third party account.
 *
 * @notice If a Smart Contract implements the following methods and events it can be called an ERC-20 Token
 *      Contract and, once deployed, it will be responsible to keep track of the created tokens on Ethereum.
 *
 * @notice See https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
 * @notice See https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
	/**
	 * @dev Fired in transfer(), transferFrom() to indicate that token transfer happened
	 *
	 * @param from an address tokens were consumed from
	 * @param to an address tokens were sent to
	 * @param value number of tokens transferred
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Fired in approve() to indicate an approval event happened
	 *
	 * @param owner an address which granted a permission to transfer
	 *      tokens on its behalf
	 * @param spender an address which received a permission to transfer
	 *      tokens on behalf of the owner `_owner`
	 * @param value amount of tokens granted to transfer on behalf
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @return name of the token (ex.: USD Coin)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function name() external view returns (string memory);

	/**
	 * @return symbol of the token (ex.: USDC)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function symbol() external view returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 *      For example, if `decimals` equals `2`, a balance of `505` tokens should
	 *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * @dev Tokens usually opt for a value of 18, imitating the relationship between
	 *      Ether and Wei. This is the value {ERC20} uses, unless this function is
	 *      overridden;
	 *
	 * @dev NOTE: This information is only used for _display_ purposes: it in
	 *      no way affects any of the arithmetic of the contract, including
	 *      {IERC20-balanceOf} and {IERC20-transfer}.
	 *
	 * @return token decimals
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function decimals() external view returns (uint8);

	/**
	 * @return the amount of tokens in existence
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @notice Gets the balance of a particular address
	 *
	 * @param _owner the address to query the the balance for
	 * @return balance an amount of tokens owned by the address specified
	 */
	function balanceOf(address _owner) external view returns (uint256 balance);

	/**
	 * @notice Transfers some tokens to an external address or a smart contract
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * self address or
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transfer(address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner (transaction sender)
	 *
	 * @dev Transaction sender must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approve(address _spender, uint256 _value) external returns (bool success);

	/**
	 * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
	 *
	 * @dev A function to check an amount of tokens owner approved
	 *      to transfer on its behalf by some other address called "spender"
	 *
	 * @param _owner an address which approves transferring some tokens on its behalf
	 * @param _spender an address approved to transfer some tokens on behalf
	 * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
	 *      of token owner `_owner`
	 */
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 *
 * @author Basil Gorin
 */
contract AccessControl {
	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @notice Creates an access control instance,
	 *      setting contract creator to have full privileges
	 */
	constructor() {
		// contract creator has full privileges
		userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns(uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}
}