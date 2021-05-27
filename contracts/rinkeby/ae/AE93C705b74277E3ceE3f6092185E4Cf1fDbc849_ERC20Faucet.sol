pragma solidity ^0.5.8;

import "./Ownable.sol";
import "./os/ERC20.sol";
import "./os/SafeMath.sol";
import "./os/SafeERC20.sol";
import "./os/TimeHelpers.sol";

contract ERC20Faucet is Ownable, TimeHelpers {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    string private constant ERROR_QUOTA_AMOUNT_ZERO =
        "FAUCET_QUOTA_AMOUNT_ZERO";
    string private constant ERROR_QUOTA_PERIOD_ZERO =
        "FAUCET_QUOTA_PERIOD_ZERO";
    string private constant ERROR_TRANSFER_FAILED = "FAUCET_TRANSFER_FAILED";
    string private constant ERROR_NOT_ENOUGH_SUPPLY =
        "FAUCET_NOT_ENOUGH_SUPPLY";
    string private constant ERROR_FUTURE_START_DATE =
        "FAUCET_FUTURE_START_DATE";
    string private constant ERROR_FUTURE_LAST_PERIOD =
        "FAUCET_FUTURE_LAST_PERIOD";
    string private constant ERROR_AMOUNT_EXCEEDS_QUOTA =
        "FAUCET_AMOUNT_EXCEEDS_QUOTA";
    string private constant ERROR_INVALID_QUOTAS_LENGTH =
        "FAUCET_INVALID_QUOTAS_LENGTH";
    string private constant ERROR_ALREADY_WITHDRAWN =
        "FAUCET_ALREADT_WITHDRAWN";

    struct Quota {
        uint256 period;
        uint256 amount;
    }

    struct Withdrawal {
        uint256 lastPeriodId;
        mapping(address => uint256) lastPeriodAmount;
    }
    uint256 amountPerAccount;

    uint256 private startDate;
    mapping(address => Quota) private tokenQuotas;
    mapping(address => uint256) private supplyByToken;
    mapping(address => Withdrawal) private withdrawals;
    mapping(address => bool) private checkWithdraw;

    event TokenQuotaSet(ERC20 indexed token, uint256 period, uint256 amount);
    event TokensDonated(
        ERC20 indexed token,
        address indexed donor,
        uint256 amount,
        uint256 totalSupply
    );
    event TokensWithdrawn(
        ERC20 indexed token,
        address indexed account,
        uint256 amount,
        uint256 totalSupply
    );

    /**
     * @notice Initialize faucet
     * @param _tokens List of ERC20 tokens to be set
     * @param _periods List of periods length for each ERC20 token quota
     * @param _amounts List of quota amounts for each ERC20 token
     * @param _amountPerAccount List of quota amounts for each ERC20 token
     */
    constructor(
        ERC20[] memory _tokens,
        uint256[] memory _periods,
        uint256[] memory _amounts,
        uint256 _amountPerAccount
    ) public Ownable() {
        startDate = getTimestamp();
        _setQuotas(_tokens, _periods, _amounts);
        amountPerAccount = _amountPerAccount;
    }

    /**
     * @notice Donate `@tokenAmount(_token, _amount)`
     * @param _token ERC20 token being deposited
     * @param _token Amount being deposited
     */
    function donate(ERC20 _token, uint256 _amount) external {
        address tokenAddress = address(_token);
        require(tokenQuotas[tokenAddress].amount > 0, ERROR_QUOTA_AMOUNT_ZERO);

        uint256 totalSupply = supplyByToken[tokenAddress].add(_amount);
        supplyByToken[tokenAddress] = totalSupply;

        emit TokensDonated(_token, msg.sender, _amount, totalSupply);
        require(
            _token.safeTransferFrom(msg.sender, address(this), _amount),
            ERROR_TRANSFER_FAILED
        );
    }

    /**
     * @notice Withdraw `@tokenAmount(_token, _amount)`
     * @param _token ERC20 token being withdrawn
     * @param _token Amount being withdrawn
     */
    function withdraw(ERC20 _token) external {
        require(!checkWithdraw[msg.sender], ERROR_ALREADY_WITHDRAWN);
        // Check there are enough tokens
        address tokenAddress = address(_token);
        uint256 totalSupply = supplyByToken[tokenAddress];
        require(totalSupply >= amountPerAccount, ERROR_NOT_ENOUGH_SUPPLY);

        // If the last period is in the future, something went wrong somewhere
        Withdrawal storage withdrawal = withdrawals[msg.sender];
        uint256 lastPeriodId = withdrawal.lastPeriodId;
        Quota storage quota = tokenQuotas[tokenAddress];
        uint256 currentPeriodId = _getCurrentPeriodId(quota);
        require(lastPeriodId <= currentPeriodId, ERROR_FUTURE_LAST_PERIOD);

        // Check withdrawal amount does not exceed period quota based on current period
        uint256 lastPeriodAmount = withdrawal.lastPeriodAmount[tokenAddress];
        uint256 newPeriodAmount =
            (lastPeriodId == currentPeriodId)
                ? lastPeriodAmount.add(amountPerAccount)
                : amountPerAccount;
        require(newPeriodAmount <= quota.amount, ERROR_AMOUNT_EXCEEDS_QUOTA);

        // Update withdrawal and transfer tokens
        checkWithdraw[msg.sender] = true;
        uint256 newTotalSupply = totalSupply.sub(amountPerAccount);
        supplyByToken[tokenAddress] = newTotalSupply;
        withdrawal.lastPeriodId = currentPeriodId;
        withdrawal.lastPeriodAmount[tokenAddress] = newPeriodAmount;

        // Transfer tokens
        emit TokensWithdrawn(
            _token,
            msg.sender,
            amountPerAccount,
            newTotalSupply
        );
        require(
            _token.safeTransfer(msg.sender, amountPerAccount),
            ERROR_TRANSFER_FAILED
        );
    }

    /**
     * @notice Set a list of token quotas
     * @param _tokens List of ERC20 tokens to be set
     * @param _periods List of periods length for each ERC20 token quota
     * @param _amounts List of quota amounts for each ERC20 token
     */
    function setQuotas(
        ERC20[] calldata _tokens,
        uint256[] calldata _periods,
        uint256[] calldata _amounts
    ) external onlyOwner {
        _setQuotas(_tokens, _periods, _amounts);
    }

    /**
     * @dev Tell the start date of the faucet
     * @return Start date of the faucet
     */
    function getStartDate() external view returns (uint256) {
        return startDate;
    }

    /**
     * @dev Tell the quota information for a certain token
     * @param _token ERC20 token being queried
     * @return period Periods length for the requested ERC20 token quota
     * @return amount Quota amount for the requested ERC20 token
     */
    function getQuota(ERC20 _token)
        external
        view
        returns (uint256 period, uint256 amount)
    {
        Quota storage quota = tokenQuotas[address(_token)];
        return (quota.period, quota.amount);
    }

    /**
     * @dev Tell the total supply of the faucet for a certain ERC20 token
     * @param _token ERC20 token being queried
     * @return Total supply of the faucet for the requested ERC20 token
     */
    function getTotalSupply(ERC20 _token) external view returns (uint256) {
        return supplyByToken[address(_token)];
    }

    /**
     * @dev Tell the last period withdrawals of an ERC20 token for a certain account
     * @param _account Address of the account being queried
     * @param _token ERC20 token being queried
     * @return id ID of the last period when the requested account withdraw a certain amount
     * @return amount Amount withdrawn by the requested account during the last period
     */
    function getWithdrawal(address _account, ERC20 _token)
        external
        view
        returns (uint256 id, uint256 amount)
    {
        Withdrawal storage withdrawal = withdrawals[_account];
        uint256 lastPeriodAmount = withdrawal.lastPeriodAmount[address(_token)];
        return (withdrawal.lastPeriodId, lastPeriodAmount);
    }

    /**
     * @dev Internal function to set a list of token quotas
     * @param _tokens List of ERC20 tokens to be set
     * @param _periods List of periods length for each ERC20 token quota
     * @param _amounts List of quota amounts for each ERC20 token
     */
    function _setQuotas(
        ERC20[] memory _tokens,
        uint256[] memory _periods,
        uint256[] memory _amounts
    ) internal {
        require(_tokens.length == _periods.length, ERROR_INVALID_QUOTAS_LENGTH);
        require(_tokens.length == _amounts.length, ERROR_INVALID_QUOTAS_LENGTH);

        for (uint256 i = 0; i < _tokens.length; i++) {
            _setQuota(_tokens[i], _periods[i], _amounts[i]);
        }
    }

    /**
     * @dev Internal function to set a token quota
     * @param _token ERC20 token to be set
     * @param _period Periods length for the ERC20 token quota
     * @param _amount Quota amount for the ERC20 token
     */
    function _setQuota(
        ERC20 _token,
        uint256 _period,
        uint256 _amount
    ) internal {
        require(_period > 0, ERROR_QUOTA_PERIOD_ZERO);
        require(_amount > 0, ERROR_QUOTA_AMOUNT_ZERO);

        Quota storage quota = tokenQuotas[address(_token)];
        quota.period = _period;
        quota.amount = _amount;
        emit TokenQuotaSet(_token, _period, _amount);
    }

    /**
     * @dev Internal function to get the current period ID of a certain token quota
     * @param _quota ERC20 token quota being queried
     * @return ID of the current period for the given token quota based on the current timestamp
     */
    function _getCurrentPeriodId(Quota storage _quota)
        internal
        view
        returns (uint256)
    {
        // Check the faucet has already started
        uint256 startTimestamp = startDate;
        uint256 currentTimestamp = getTimestamp();
        require(currentTimestamp >= startTimestamp, ERROR_FUTURE_START_DATE);

        // No need for SafeMath: we already checked current timestamp is greater than or equal to start date
        uint256 timeDiff = currentTimestamp - startTimestamp;
        uint256 currentPeriodId = timeDiff / _quota.period;
        return currentPeriodId;
    }

    /**
     * @notice withdraw any erc20 send accidentally to the contract
     * @param _token address of erc20 token
     * @param _amount amount of tokens to withdraw
     */
    function EmergencyWithdrawERC20(ERC20 _token, uint256 _amount)
        external
        onlyOwner
    {
        require(
            _token.balanceOf(address(this)) >= _amount,
            "ArgoPayments: Insufficient tokens in contract"
        );
        _token.transfer(msg.sender, _amount);
    }

    /**
     * @notice update amount per account
     * @param _amount amount to withdraw per account
     */
    function withdrawAmountPerAccount(uint256 _amount) external onlyOwner {
        amountPerAccount = _amount;
    }
}

pragma solidity ^0.5.8;


contract Ownable {
    string private constant ERROR_SENDER_NOT_OWNER = "OWNABLE_SENDER_NOT_OWNER";
    string private constant ERROR_NEW_OWNER_ADDRESS_ZERO = "OWNABLE_NEW_OWNER_ADDRESS_ZERO";

    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, ERROR_SENDER_NOT_OWNER);
        _;
    }

    constructor () public {
        _setOwner(msg.sender);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), ERROR_NEW_OWNER_ADDRESS_ZERO);
        _setOwner(_newOwner);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function _setOwner(address _newOwner) private {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/token/ERC20.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

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

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/math/SafeMath.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/SafeERC20.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;

import "./ERC20.sol";


library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), approveCallData);
    }

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata) private returns (bool) {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
            // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                // Only return success if returned data was true
                // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/TimeHelpers.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;

import "./Uint256Helpers.sol";


contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/Uint256Helpers.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


library Uint256Helpers {
    uint256 private constant MAX_UINT8 = uint8(-1);
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_UINT8_NUMBER_TOO_BIG = "UINT8_NUMBER_TOO_BIG";
    string private constant ERROR_UINT64_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint8(uint256 a) internal pure returns (uint8) {
        require(a <= MAX_UINT8, ERROR_UINT8_NUMBER_TOO_BIG);
        return uint8(a);
    }

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_UINT64_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}