pragma solidity 0.4.24;
pragma experimental "v0.5.0";

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a >= _b ? _a : _b;
  }

  function min64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a < _b ? _a : _b;
  }

  function max256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a >= _b ? _a : _b;
  }

  function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/lib/AccessControlledBase.sol

/*

    Copyright 2018 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/


/**
 * @title AccessControlledBase
 * @author dYdX
 *
 * Base functionality for access control. Requires an implementation to
 * provide a way to grant and optionally revoke access
 */
contract AccessControlledBase {
    // ============ State Variables ============

    mapping (address => bool) public authorized;

    // ============ Events ============

    event AccessGranted(
        address who
    );

    event AccessRevoked(
        address who
    );

    // ============ Modifiers ============

    modifier requiresAuthorization() {
        require(
            authorized[msg.sender],
            "AccessControlledBase#requiresAuthorization: Sender not authorized"
        );
        _;
    }
}

// File: contracts/lib/StaticAccessControlled.sol

/*

    Copyright 2018 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/


/**
 * @title StaticAccessControlled
 * @author dYdX
 *
 * Allows for functions to be access controled
 * Permissions cannot be changed after a grace period
 */
contract StaticAccessControlled is AccessControlledBase, Ownable {
    using SafeMath for uint256;

    // ============ State Variables ============

    // Timestamp after which no additional access can be granted
    uint256 public GRACE_PERIOD_EXPIRATION;

    // ============ Constructor ============

    constructor(
        uint256 gracePeriod
    )
        public
        Ownable()
    {
        GRACE_PERIOD_EXPIRATION = block.timestamp.add(gracePeriod);
    }

    // ============ Owner-Only State-Changing Functions ============

    function grantAccess(
        address who
    )
        external
        onlyOwner
    {
        require(
            block.timestamp < GRACE_PERIOD_EXPIRATION,
            "StaticAccessControlled#grantAccess: Cannot grant access after grace period"
        );

        emit AccessGranted(who);
        authorized[who] = true;
    }
}

// File: contracts/lib/GeneralERC20.sol

/*

    Copyright 2018 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/


/**
 * @title GeneralERC20
 * @author dYdX
 *
 * Interface for using ERC20 Tokens. We have to use a special interface to call ERC20 functions so
 * that we dont automatically revert when calling non-compliant tokens that have no return value for
 * transfer(), transferFrom(), or approve().
 */
interface GeneralERC20 {
    function totalSupply(
    )
        external
        view
        returns (uint256);

    function balanceOf(
        address who
    )
        external
        view
        returns (uint256);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function transfer(
        address to,
        uint256 value
    )
        external;


    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external;

    function approve(
        address spender,
        uint256 value
    )
        external;
}

// File: contracts/lib/TokenInteract.sol

/*

    Copyright 2018 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/


/**
 * @title TokenInteract
 * @author dYdX
 *
 * This library contains functions for interacting with ERC20 tokens
 */
library TokenInteract {
    function balanceOf(
        address token,
        address owner
    )
        internal
        view
        returns (uint256)
    {
        return GeneralERC20(token).balanceOf(owner);
    }

    function allowance(
        address token,
        address owner,
        address spender
    )
        internal
        view
        returns (uint256)
    {
        return GeneralERC20(token).allowance(owner, spender);
    }

    function approve(
        address token,
        address spender,
        uint256 amount
    )
        internal
    {
        GeneralERC20(token).approve(spender, amount);

        require(
            checkSuccess(),
            "TokenInteract#approve: Approval failed"
        );
    }

    function transfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        address from = address(this);
        if (
            amount == 0
            || from == to
        ) {
            return;
        }

        GeneralERC20(token).transfer(to, amount);

        require(
            checkSuccess(),
            "TokenInteract#transfer: Transfer failed"
        );
    }

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        if (
            amount == 0
            || from == to
        ) {
            return;
        }

        GeneralERC20(token).transferFrom(from, to, amount);

        require(
            checkSuccess(),
            "TokenInteract#transferFrom: TransferFrom failed"
        );
    }

    // ============ Private Helper-Functions ============

    /**
     * Checks the return value of the previous function up to 32 bytes. Returns true if the previous
     * function returned 0 bytes or 32 bytes that are not all-zero.
     */
    function checkSuccess(
    )
        private
        pure
        returns (bool)
    {
        uint256 returnValue = 0;

        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            // check number of bytes returned from last function call
            switch returndatasize

            // no bytes returned: assume success
            case 0x0 {
                returnValue := 1
            }

            // 32 bytes returned: check if non-zero
            case 0x20 {
                // copy 32 bytes into scratch space
                returndatacopy(0x0, 0x0, 0x20)

                // load those bytes into returnValue
                returnValue := mload(0x0)
            }

            // not sure what was returned: dont mark as success
            default { }
        }

        return returnValue != 0;
    }
}

// File: contracts/margin/TokenProxy.sol

/*

    Copyright 2018 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/


/**
 * @title TokenProxy
 * @author dYdX
 *
 * Used to transfer tokens between addresses which have set allowance on this contract.
 */
contract TokenProxy is StaticAccessControlled {
    using SafeMath for uint256;

    // ============ Constructor ============

    constructor(
        uint256 gracePeriod
    )
        public
        StaticAccessControlled(gracePeriod)
    {}

    // ============ Authorized-Only State Changing Functions ============

    /**
     * Transfers tokens from an address (that has set allowance on the proxy) to another address.
     *
     * @param  token  The address of the ERC20 token
     * @param  from   The address to transfer token from
     * @param  to     The address to transfer tokens to
     * @param  value  The number of tokens to transfer
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 value
    )
        external
        requiresAuthorization
    {
        TokenInteract.transferFrom(
            token,
            from,
            to,
            value
        );
    }

    // ============ Public Constant Functions ============

    /**
     * Getter function to get the amount of token that the proxy is able to move for a particular
     * address. The minimum of 1) the balance of that address and 2) the allowance given to proxy.
     *
     * @param  who    The owner of the tokens
     * @param  token  The address of the ERC20 token
     * @return        The number of tokens able to be moved by the proxy from the address specified
     */
    function available(
        address who,
        address token
    )
        external
        view
        returns (uint256)
    {
        return Math.min256(
            TokenInteract.allowance(token, who, address(this)),
            TokenInteract.balanceOf(token, who)
        );
    }
}

// File: contracts/margin/Vault.sol

/*

    Copyright 2018 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/


/**
 * @title Vault
 * @author dYdX
 *
 * Holds and transfers tokens in vaults denominated by id
 *
 * Vault only supports ERC20 tokens, and will not accept any tokens that require
 * a tokenFallback or equivalent function (See ERC223, ERC777, etc.)
 */
contract Vault is StaticAccessControlled
{
    using SafeMath for uint256;

    // ============ Events ============

    event ExcessTokensWithdrawn(
        address indexed token,
        address indexed to,
        address caller
    );

    // ============ State Variables ============

    // Address of the TokenProxy contract. Used for moving tokens.
    address public TOKEN_PROXY;

    // Map from vault ID to map from token address to amount of that token attributed to the
    // particular vault ID.
    mapping (bytes32 => mapping (address => uint256)) public balances;

    // Map from token address to total amount of that token attributed to some account.
    mapping (address => uint256) public totalBalances;

    // ============ Constructor ============

    constructor(
        address proxy,
        uint256 gracePeriod
    )
        public
        StaticAccessControlled(gracePeriod)
    {
        TOKEN_PROXY = proxy;
    }

    // ============ Owner-Only State-Changing Functions ============

    /**
     * Allows the owner to withdraw any excess tokens sent to the vault by unconventional means,
     * including (but not limited-to) token airdrops. Any tokens moved to the vault by TOKEN_PROXY
     * will be accounted for and will not be withdrawable by this function.
     *
     * @param  token  ERC20 token address
     * @param  to     Address to transfer tokens to
     * @return        Amount of tokens withdrawn
     */
    function withdrawExcessToken(
        address token,
        address to
    )
        external
        onlyOwner
        returns (uint256)
    {
        uint256 actualBalance = TokenInteract.balanceOf(token, address(this));
        uint256 accountedBalance = totalBalances[token];
        uint256 withdrawableBalance = actualBalance.sub(accountedBalance);

        require(
            withdrawableBalance != 0,
            "Vault#withdrawExcessToken: Withdrawable token amount must be non-zero"
        );

        TokenInteract.transfer(token, to, withdrawableBalance);

        emit ExcessTokensWithdrawn(token, to, msg.sender);

        return withdrawableBalance;
    }

    // ============ Authorized-Only State-Changing Functions ============

    /**
     * Transfers tokens from an address (that has approved the proxy) to the vault.
     *
     * @param  id      The vault which will receive the tokens
     * @param  token   ERC20 token address
     * @param  from    Address from which the tokens will be taken
     * @param  amount  Number of the token to be sent
     */
    function transferToVault(
        bytes32 id,
        address token,
        address from,
        uint256 amount
    )
        external
        requiresAuthorization
    {
        // First send tokens to this contract
        TokenProxy(TOKEN_PROXY).transferTokens(
            token,
            from,
            address(this),
            amount
        );

        // Then increment balances
        balances[id][token] = balances[id][token].add(amount);
        totalBalances[token] = totalBalances[token].add(amount);

        // This should always be true. If not, something is very wrong
        assert(totalBalances[token] >= balances[id][token]);

        validateBalance(token);
    }

    /**
     * Transfers a certain amount of funds to an address.
     *
     * @param  id      The vault from which to send the tokens
     * @param  token   ERC20 token address
     * @param  to      Address to transfer tokens to
     * @param  amount  Number of the token to be sent
     */
    function transferFromVault(
        bytes32 id,
        address token,
        address to,
        uint256 amount
    )
        external
        requiresAuthorization
    {
        // Next line also asserts that (balances[id][token] >= amount);
        balances[id][token] = balances[id][token].sub(amount);

        // Next line also asserts that (totalBalances[token] >= amount);
        totalBalances[token] = totalBalances[token].sub(amount);

        // This should always be true. If not, something is very wrong
        assert(totalBalances[token] >= balances[id][token]);

        // Do the sending
        TokenInteract.transfer(token, to, amount); // asserts transfer succeeded

        // Final validation
        validateBalance(token);
    }

    // ============ Private Helper-Functions ============

    /**
     * Verifies that this contract is in control of at least as many tokens as accounted for
     *
     * @param  token  Address of ERC20 token
     */
    function validateBalance(
        address token
    )
        private
        view
    {
        // The actual balance could be greater than totalBalances[token] because anyone
        // can send tokens to the contract&#39;s address which cannot be accounted for
        assert(TokenInteract.balanceOf(token, address(this)) >= totalBalances[token]);
    }
}