// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./StandardToken.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./utils/AccessProtected.sol";

contract SBTVesting is AccessProtected {
    using Address for address;
    address immutable public tokenAddress;
    address immutable public founderWallet;
    address immutable public advisorWallet;
    address immutable public teamAddress;
    address immutable public devAddress;
    uint64 public startTime;

    struct Claim {
        uint256 totalAmount;
        uint256 startTime_;
        uint256 amountClaimed;
    }

    mapping(address => Claim) private claims;

    event ClaimCreated(
        address _creator,
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _startTime
    );
    event Claimed(address _beneficiary, uint256 _amount);

    constructor(address _tokenAddress, address _founderWallet, address _advisorWallet, address _teamAddress, uint64 _startTime) {
        require(_tokenAddress.isContract(),"SBT Token address isn't contracts Address");
        tokenAddress = _tokenAddress;
        founderWallet = _founderWallet;
        advisorWallet = _advisorWallet;
        teamAddress = _teamAddress;
        devAddress = msg.sender;
        startTime = _startTime;
    }
    
    
    uint64 public endTime = startTime + 60000;

    function createClaim(
        address _beneficiary,
        uint256 _totalAmount
    ) external onlyAdmin {
        require(endTime >= startTime, "INVALID_TIME");
        require(_beneficiary != address(0), "INVALID_ADDRESS");
        require(_totalAmount > 0, "INVALID_AMOUNT");
        require(_beneficiary == founderWallet || _beneficiary == advisorWallet || _beneficiary == devAddress, "INVALID_ADDRESS");
        require(
            StandardToken(tokenAddress).allowance(msg.sender, address(this)) >=
            _totalAmount,
            "INVALID_ALLOWANCE"
        );
        StandardToken(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _totalAmount
        );
        Claim memory newClaim = Claim({
            totalAmount: _totalAmount,
            startTime_: startTime,
            amountClaimed: 0
        });
        claims[_beneficiary] = newClaim;
            emit ClaimCreated(
            msg.sender,
            _beneficiary,
            _totalAmount,
            startTime
            );
    }

    function getClaim(address beneficiary)
        external
        view
        returns (Claim memory)
    {
        require(beneficiary != address(0), "INVALID_ADDRESS");
        return (claims[beneficiary]);
    }

    function claimableAmount(address beneficiary)
        public
        view
        returns (uint256)
    {
        Claim memory _claim = claims[beneficiary];
        if (block.timestamp < _claim.startTime_) return 0;
        if (_claim.amountClaimed == _claim.totalAmount) return 0;

        uint256 minutesPassed =  (block.timestamp - _claim.startTime_)/600;
        uint256 _startPrice = _claim.totalAmount;
        uint256 _endPrice = 0;
        uint256 _startingTime = _claim.startTime_;
        uint256 tickPerBlock = (_startPrice - _endPrice)*(1e18) / ( endTime - _startingTime);
        uint256 tickPer10Min = (tickPerBlock *600)/(1e18);
        uint256 rewardPer10Min = minutesPassed * tickPer10Min;
        uint256 claimAmount = _claim.totalAmount * rewardPer10Min;
        uint256 unclaimedAmount = claimAmount - _claim.amountClaimed;
        return unclaimedAmount;
    }

    function withdrawal() external {
        address beneficiary = msg.sender;
        Claim memory _claim = claims[beneficiary];
        require(_claim.amountClaimed != _claim.totalAmount, "CLAIM_COMPLETE");
        uint256 unclaimedAmount = claimableAmount(beneficiary);
        StandardToken(tokenAddress).transfer(beneficiary, unclaimedAmount);
        _claim.amountClaimed = _claim.amountClaimed + unclaimedAmount;
        claims[beneficiary] = _claim;
        emit Claimed(beneficiary, unclaimedAmount);
    }

    function withdrawTokens(address wallet) external onlyOwner {
        uint256 balance = StandardToken(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        StandardToken(tokenAddress).transfer(wallet, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtected is Context, Ownable {
    mapping(address => bool) private _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Minter
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether minter has access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./IERC223.sol";

contract StandardToken is ERC20, ERC223
{
        
	uint256 public totalSupply;

        
	mapping (address => uint256) internal balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	event Burn(address indexed burner, uint256 value);

	function transfer(address _to, uint256 _value) external override returns (bool)
	{
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		balances[msg.sender] = balances[msg.sender] - _value;
		balances[_to] = balances[_to] + _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf (address _owner) public override view returns (uint256 balance)
	{
		return balances[_owner];
	}

	function transferFrom(address _from, address _to, uint256 _value) external override returns (bool)
	{
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from] - _value;
		balances[_to] = balances[_to] + _value;
		allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) external override returns (bool)
	{
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public override view returns (uint256)
	{
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint256 _addedValue) external returns (bool)
	{
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) external returns (bool)
	{
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue)
		{
			allowed[msg.sender][_spender] = 0;
		}
		else
		{
			allowed[msg.sender][_spender] = oldValue - _subtractedValue;
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function transfer(address _to, uint256 _value, bytes calldata _data) external override
	{
		require(_value > 0 );
		if(isContract(_to))
		{
			ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
			receiver.tokenFallback(msg.sender, _value, _data);
		}
		balances[msg.sender] = balances[msg.sender] - _value;
		balances[_to] = balances[_to] + _value;
		emit Transfer(msg.sender, _to, _value, _data);
	}

	function isContract(address _addr) view private returns (bool is_contract)
	{
		uint256 length;
		assembly
		{
			length := extcodesize(_addr)
		}
		return (length>0);
	}

	function burn(uint256 _value) external
	{
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender] - _value;
		totalSupply = totalSupply - _value;
		emit Burn(msg.sender, _value);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC223 interface
 */
interface ERC223
{
	function transfer(address to, uint256 value, bytes calldata data) external;
	event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
}

/*
Base class contracts willing to accept ERC223 token transfers must conform to.
*/

abstract contract ERC223ReceivingContract
{
	function tokenFallback(address _from, uint256 _value, bytes calldata _data) virtual external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface
 */
interface ERC20
{
	function balanceOf(address who) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
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
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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