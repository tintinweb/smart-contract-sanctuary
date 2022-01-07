pragma solidity 0.8.7;

/**
 * @author InsureDAO
 * @title InsureDAO vault contract
 * @notice
 * SPDX-License-Identifier: GPL-3.0
 */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IOwnership.sol";
import "./interfaces/IVault.sol";

import "./interfaces/IController.sol";
import "./interfaces/IRegistry.sol";

contract Vault is IVault {
    using SafeERC20 for IERC20;

    /**
     * Storage
     */

    address public override token;
    IController public controller;
    IRegistry public registry;
    IOwnership public ownership;

    mapping(address => uint256) public override debts;
    mapping(address => uint256) public attributions;
    uint256 public totalAttributions;

    address public keeper; //keeper can operate utilize(), if address zero, anyone can operate.
    uint256 public balance; //balance of underlying token
    uint256 public totalDebt; //total debt balance. 1debt:1token

    uint256 public constant MAGIC_SCALE_1E6 = 1e6; //internal multiplication scale 1e6 to reduce decimal truncation



    event ControllerSet(address controller);

    modifier onlyOwner() {
        require(
            ownership.owner() == msg.sender,
            "Restricted: caller is not allowed to operate"
        );
        _;
    }

    modifier onlyMarket() {
        require(
            IRegistry(registry).isListed(msg.sender),
            "ERROR_ONLY_MARKET"
        );
        _;
    }

    constructor(
        address _token,
        address _registry,
        address _controller,
        address _ownership
    ) {
        require(_token != address(0));
        require(_registry != address(0));
        require(_ownership != address(0));
        //controller can be zero

        token = _token;
        registry = IRegistry(_registry);
        controller = IController(_controller);
        ownership = IOwnership(_ownership);
    }

    /**
     * Vault Functions
     */

    /**
     * @notice A market contract can deposit collateral and get attribution point in return
     * @param  _amount amount of tokens to deposit
     * @param _from sender's address
     * @param _beneficiaries beneficiary's address array
     * @param _shares funds share within beneficiaries (100% = 1e6)
     * @return _allocations attribution amount generated from the transaction
     */
    function addValueBatch(
        uint256 _amount,
        address _from,
        address[2] memory _beneficiaries,
        uint256[2] memory _shares
    ) external override onlyMarket returns (uint256[2] memory _allocations) {
        
        require(_shares[0] + _shares[1] == 1000000, "ERROR_INCORRECT_SHARE");

        uint256 _attributions;
        if (totalAttributions == 0) {
            _attributions = _amount;
        } else {
            uint256 _pool = valueAll();
            _attributions = (_amount * totalAttributions) / _pool;
        }
        IERC20(token).safeTransferFrom(_from, address(this), _amount);

        balance += _amount;
        totalAttributions += _attributions;
        for (uint128 i = 0; i < 2; i++) {
            uint256 _allocation = (_shares[i] * _attributions) / MAGIC_SCALE_1E6;
            attributions[_beneficiaries[i]] += _allocation;
            _allocations[i] = _allocation;
        }
    }

    /**
     * @notice A market contract can deposit collateral and get attribution point in return
     * @param  _amount amount of tokens to deposit
     * @param _from sender's address
     * @param _beneficiary beneficiary's address
     * @return _attributions attribution amount generated from the transaction
     */

    function addValue(
        uint256 _amount,
        address _from,
        address _beneficiary
    ) external override onlyMarket returns (uint256 _attributions) {

        if (totalAttributions == 0) {
            _attributions = _amount;
        } else {
            uint256 _pool = valueAll();
            _attributions = (_amount * totalAttributions) / _pool;
        }
        IERC20(token).safeTransferFrom(_from, address(this), _amount);
        balance += _amount;
        totalAttributions += _attributions;
        attributions[_beneficiary] += _attributions;
    }

    /**
     * @notice an address that has balance in the vault can withdraw underlying value
     * @param _amount amount of tokens to withdraw
     * @param _to address to get underlying tokens
     * @return _attributions amount of attributions burnet
     */
    function withdrawValue(uint256 _amount, address _to)
        external
        override
        returns (uint256 _attributions)
    {
        require(
            attributions[msg.sender] > 0 &&
                underlyingValue(msg.sender) >= _amount,
            "ERROR_WITHDRAW-VALUE_BADCONDITOONS"
        );
        _attributions = (totalAttributions * _amount) / valueAll();

        attributions[msg.sender] -= _attributions;
        totalAttributions -= _attributions;

        if (available() < _amount) {
            //when USDC in this contract isn't enough
            uint256 _shortage = _amount - available();
            _unutilize(_shortage);

            assert(available() >= _amount);
        }

        balance -= _amount;
        IERC20(token).safeTransfer(_to, _amount);
    }

    /**
     * @notice an address that has balance in the vault can transfer underlying value
     * @param _amount sender of value
     * @param _destination reciepient of value
     */

    function transferValue(uint256 _amount, address _destination)
        external
        override
        returns (uint256 _attributions)
    {
        require(
            attributions[msg.sender] > 0 &&
                underlyingValue(msg.sender) >= _amount,
            "ERROR_TRANSFER-VALUE_BADCONDITOONS"
        );
        _attributions = (_amount * totalAttributions) / valueAll();
        attributions[msg.sender] -= _attributions;
        attributions[_destination] += _attributions;
    }

    /**
     * @notice a registered contract can borrow balance from the vault
     * @param _amount borrow amount
     * @param _to borrower's address
     */
    function borrowValue(uint256 _amount, address _to) external onlyMarket override {
        debts[msg.sender] += _amount;
        totalDebt += _amount;

        IERC20(token).safeTransfer(_to, _amount);
    }

    /**
     * @notice an address that has balance in the vault can offset an address's debt
     * @param _amount debt amount to offset
     * @param _target borrower's address
     */

    function offsetDebt(uint256 _amount, address _target)
        external
        override
        returns (uint256 _attributions)
    {
        require(
            attributions[msg.sender] > 0 &&
                underlyingValue(msg.sender) >= _amount,
            "ERROR_REPAY_DEBT_BADCONDITOONS"
        );
        _attributions = (_amount * totalAttributions) / valueAll();
        attributions[msg.sender] -= _attributions;
        totalAttributions -= _attributions;
        balance -= _amount;
        debts[_target] -= _amount;
        totalDebt -= _amount;
    }

    /**
     * @notice a registerd market can transfer their debt to system debt
     * @param _amount debt amount to transfer
     * @dev will be called when CDS could not afford when resume the market.
     */
    function transferDebt(uint256 _amount) external onlyMarket override {

        if(_amount != 0){
            debts[msg.sender] -= _amount;
            debts[address(0)] += _amount;
        }
    }

    /**
     * @notice anyone can repay the system debt by sending tokens to this contract
     * @param _amount debt amount to repay
     * @param _target borrower's address
     */
    function repayDebt(uint256 _amount, address _target) external override {
        uint256 _debt = debts[_target];
        if (_debt >= _amount) {
            debts[_target] -= _amount;
            totalDebt -= _amount;
            IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        } else {
            debts[_target] = 0;
            totalDebt -= _debt;
            IERC20(token).safeTransferFrom(msg.sender, address(this), _debt);
        }
    }

    /**
     * @notice an address that has balance in the vault can withdraw value denominated in attribution
     * @param _attribution amount of attribution to burn
     * @param _to beneficiary's address
     * @return _retVal number of tokens withdrawn from the transaction
     */
    function withdrawAttribution(uint256 _attribution, address _to)
        external
        override
        returns (uint256 _retVal)
    {
        _retVal = _withdrawAttribution(_attribution, _to);
    }

    /**
     * @notice an address that has balance in the vault can withdraw all value
     * @param _to beneficiary's address
     * @return _retVal number of tokens withdrawn from the transaction
     */
    function withdrawAllAttribution(address _to)
        external
        override
        returns (uint256 _retVal)
    {
        _retVal = _withdrawAttribution(attributions[msg.sender], _to);
    }

    /**
     * @notice an address that has balance in the vault can withdraw all value
     * @param _attribution amount of attribution to burn
     * @param _to beneficiary's address
     * @return _retVal number of tokens withdrawn from the transaction
     */
    function _withdrawAttribution(uint256 _attribution, address _to)
        internal
        returns (uint256 _retVal)
    {
        require(
            attributions[msg.sender] >= _attribution,
            "ERROR_WITHDRAW-ATTRIBUTION_BADCONDITOONS"
        );
        _retVal = (_attribution * valueAll()) / totalAttributions;

        attributions[msg.sender] -= _attribution;
        totalAttributions -= _attribution;

        if (available() < _retVal) {
            uint256 _shortage = _retVal - available();
            _unutilize(_shortage);
        }

        balance -= _retVal;
        IERC20(token).safeTransfer(_to, _retVal);
    }

    /**
     * @notice an address that has balance in the vault can transfer value denominated in attribution
     * @param _amount amount of attribution to transfer
     * @param _destination reciepient of attribution
     */
    function transferAttribution(uint256 _amount, address _destination)
        external
        override
    {
        require(_destination != address(0), "ERROR_ZERO_ADDRESS");

        require(
            _amount != 0 && attributions[msg.sender] >= _amount,
            "ERROR_TRANSFER-ATTRIBUTION_BADCONDITOONS"
        );

        attributions[msg.sender] -= _amount;
        attributions[_destination] += _amount;
    }

    /**
     * @notice the controller can utilize all available stored funds
     * @return _amount amount of tokens utilized
     */
    function utilize() external override returns (uint256 _amount) {
        if (keeper != address(0)) {
            require(msg.sender == keeper, "ERROR_NOT_KEEPER");
        }
        _amount = available(); //balance
        if (_amount > 0) {
            IERC20(token).safeTransfer(address(controller), _amount);
            balance -= _amount;
            controller.earn(address(token), _amount);
        }
    }

    /**
     * @notice get attribution number for the specified address
     * @param _target target address
     * @return amount of attritbution
     */

    function attributionOf(address _target)
        external
        view
        override
        returns (uint256)
    {
        return attributions[_target];
    }

    /**
     * @notice get all attribution number for this contract
     * @return amount of all attribution
     */
    function attributionAll() external view returns (uint256) {
        return totalAttributions;
    }

    /**
     * @notice Convert attribution number into underlying assset value
     * @param _attribution amount of attribution
     * @return token value of input attribution
     */
    function attributionValue(uint256 _attribution)
        external
        view
        override
        returns (uint256)
    {
        if (totalAttributions > 0 && _attribution > 0) {
            return (_attribution * valueAll()) / totalAttributions;
        } else {
            return 0;
        }
    }

    /**
     * @notice return underlying value of the specified address
     * @param _target target address
     * @return token value of target address
     */
    function underlyingValue(address _target)
        public
        view
        override
        returns (uint256)
    {
        if (attributions[_target] > 0) {
            return (valueAll() * attributions[_target]) / totalAttributions;
        } else {
            return 0;
        }
    }

    /**
     * @notice return underlying value of this contract
     * @return all token value of the vault
     */
    function valueAll() public view returns (uint256) {
        if (address(controller) != address(0)) {
            return balance + controller.valueAll();
        } else {
            return balance;
        }
    }

    /**
     * @notice internal function to unutilize the funds and keep utilization rate
     * @param _amount amount to withdraw from controller
     */
    function _unutilize(uint256 _amount) internal {
        require(address(controller) != address(0), "ERROR_CONTROLLER_NOT_SET");

        controller.withdraw(address(this), _amount);
        balance += _amount;
    }

    /**
     * @notice return how much funds in this contract is available to be utilized
     * @return available balance to utilize
     */
    function available() public view returns (uint256) {
        return balance - totalDebt;
    }

    /**
     * @notice return how much price for each attribution
     * @return value of one share of attribution
     */
    function getPricePerFullShare() public view returns (uint256) {
        return (valueAll() * MAGIC_SCALE_1E6) / totalAttributions;
    }

    /**
     * onlyOwner
     */

    /**
     * @notice withdraw redundant token stored in this contract
     * @param _token token address
     * @param _to beneficiary's address
     */
    function withdrawRedundant(address _token, address _to)
        external
        override
        onlyOwner
    {
        if (
            _token == address(token) &&
            balance < IERC20(token).balanceOf(address(this))
        ) {
            uint256 _redundant = IERC20(token).balanceOf(address(this)) -
                balance;
            IERC20(token).safeTransfer(_to, _redundant);
        } else if (IERC20(_token).balanceOf(address(this)) > 0) {
            IERC20(_token).safeTransfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    /**
     * @notice admin function to set controller address
     * @param _controller address of the controller
     */
    function setController(address _controller) public override onlyOwner {
        require(_controller != address(0), "ERROR_ZERO_ADDRESS");

        if (address(controller) != address(0)) {
            controller.migrate(address(_controller));
            controller = IController(_controller);
        } else {
            controller = IController(_controller);
        }

        emit ControllerSet(_controller);
    }

    /**
     * @notice the controller can utilize all available stored funds
     * @param _keeper keeper address
     */
    function setKeeper(address _keeper) external override onlyOwner {
        if (keeper != _keeper) {
            keeper = _keeper;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.8.7;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}

pragma solidity 0.8.7;

interface IVault {
    function addValueBatch(
        uint256 _amount,
        address _from,
        address[2] memory _beneficiaries,
        uint256[2] memory _shares
    ) external returns (uint256[2] memory _allocations);

    function addValue(
        uint256 _amount,
        address _from,
        address _attribution
    ) external returns (uint256 _attributions);

    function withdrawValue(uint256 _amount, address _to)
        external
        returns (uint256 _attributions);

    function transferValue(uint256 _amount, address _destination)
        external
        returns (uint256 _attributions);

    function withdrawAttribution(uint256 _attribution, address _to)
        external
        returns (uint256 _retVal);

    function withdrawAllAttribution(address _to)
        external
        returns (uint256 _retVal);

    function transferAttribution(uint256 _amount, address _destination)
        external;

    function attributionOf(address _target) external view returns (uint256);

    function underlyingValue(address _target) external view returns (uint256);

    function attributionValue(uint256 _attribution)
        external
        view
        returns (uint256);

    function utilize() external returns (uint256 _amount);

    function token() external returns (address);

    function borrowValue(uint256 _amount, address _to) external;

    /*
    function borrowAndTransfer(uint256 _amount, address _to)
        external
        returns (uint256 _attributions);
    */

    function offsetDebt(uint256 _amount, address _target)
        external
        returns (uint256 _attributions);

    function repayDebt(uint256 _amount, address _target) external;

    function debts(address _debtor) external view returns (uint256);

    function transferDebt(uint256 _amount) external;

    //onlyOwner
    function withdrawRedundant(address _token, address _to) external;

    function setController(address _controller) external;

    function setKeeper(address _keeper) external;
}

pragma solidity 0.8.7;

interface IController {
    function withdraw(address, uint256) external;

    function valueAll() external view returns (uint256);

    function earn(address, uint256) external;

    function migrate(address) external;
}

pragma solidity 0.8.7;

interface IRegistry {
    function isListed(address _market) external view returns (bool);

    function getCDS(address _address) external view returns (address);

    function confirmExistence(address _template, address _target)
        external
        view
        returns (bool);

    //onlyOwner
    function setFactory(address _factory) external;

    function supportMarket(address _market) external;

    function setExistence(address _template, address _target) external;

    function setCDS(address _address, address _cds) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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