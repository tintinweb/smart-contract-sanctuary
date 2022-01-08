// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PrivateSale is Ownable {

    IERC20 public token;
    uint256 decimalsDiff;
    uint256 public privateSaleStartTimestamp;
    uint256 public privateSaleEndTimestamp;
    uint256 public hardCapEthAmount = 1000 ether;
    uint256 public totalDepositedEthBalance;
    uint256 public minimumDepositEthAmount = uint256(1 ether)/10;
    uint256 public maximumDepositEthAmount = uint256(30 ether);
    uint256 public tokenPerBNB = 70000000000;
    bool public claimEnabled;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public tokens;

    mapping(address => bool) public whitelist;

    struct LastTx {
        uint256 tokenAmount;
        address buyer;
    }

    LastTx[3] public lastTxList;

    constructor(
        IERC20 _token,
        uint256 decimals
    ) {
        token = _token;
        whitelist[msg.sender] = true;
        decimalsDiff = 18 - decimals;
    }

    receive() payable external {
        deposit();
    }

    function claim() external returns(bool) {
        require(claimEnabled == true, "Claim is not enabled!");
        require(tokens[msg.sender] > 0, "tokens limit!");
        uint256 claimAmount = getAccountTokes(msg.sender);
        token.transfer(msg.sender, claimAmount);
        tokens[msg.sender] = tokens[msg.sender] - claimAmount;
        return true;
    }

    function setClaimEnabled(bool enabled) external onlyOwner {
        claimEnabled = enabled;
    }

    function getAccountTokes(address account) public view returns(uint256) {
        return tokens[account];
    }

    function reachedHardCap() view public returns (bool) {
        return hardCapEthAmount == totalDepositedEthBalance;
    }

    function tokenBalanceOfSender() view external returns (uint256) {
        return token.balanceOf(msg.sender);
    }

    function tokenBalanceOfContract() view external returns (uint256) {
        return token.balanceOf(address(this));
    }

    function deposit() public payable {
        require(whitelist[msg.sender], "invalid withdraw address");
        require(!reachedHardCap(), "Hard Cap is already reached");
        require(privateSaleStartTimestamp > 0 && block.timestamp >= privateSaleStartTimestamp && block.timestamp <= privateSaleEndTimestamp, "presale is not active");
        uint256 take;
        uint256 sendBack;

        if (totalDepositedEthBalance + msg.value > hardCapEthAmount) {
            take = hardCapEthAmount - totalDepositedEthBalance;
            sendBack = totalDepositedEthBalance + msg.value - hardCapEthAmount;
        } else {
            take = msg.value;
        }

        require(deposits[msg.sender] + take >= minimumDepositEthAmount && deposits[msg.sender] + take <= maximumDepositEthAmount, "Deposited balance is less or grater than allowed range");

        totalDepositedEthBalance = totalDepositedEthBalance + take;
        deposits[msg.sender] = deposits[msg.sender] + take;
        emit Deposited(msg.sender, take);
        uint256 tokenAmount = take * tokenPerBNB / (10 ** decimalsDiff);

        tokens[msg.sender] = tokens[msg.sender] + tokenAmount;


        addLastTx(msg.sender, tokenAmount);

        if (sendBack > 0) {
            privateSaleEndTimestamp = block.timestamp;
            (bool success, ) = msg.sender.call{value: sendBack}('');
            require(success);
            emit SendBack(msg.sender, sendBack);
        }
    }

    function addLastTx(address buyer, uint256 amount) internal {
        LastTx memory ltx;
        ltx.buyer = buyer;
        ltx.tokenAmount = amount;

        lastTxList[0] = lastTxList[1];
        lastTxList[1] = lastTxList[2];
        lastTxList[2] = ltx;
    }

    function releaseFunds() external onlyOwner {
        require(block.timestamp >= privateSaleEndTimestamp, "Too soon");
        payable(msg.sender).transfer(address(this).balance);
    }

    function addWhiteList(address payable _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function removeWhiteList(address payable _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function addWhiteListMulti(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 1000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeWhiteListMulti(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 1000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function getDepositAmount() public view returns (uint256) {
        return totalDepositedEthBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if(block.timestamp > privateSaleEndTimestamp) {
            return 0;
        } else {
            return (privateSaleEndTimestamp - block.timestamp);
        }
    }

    function setMinDepositAmount(uint256 newValue) external onlyOwner {
        require(newValue < maximumDepositEthAmount, "Min value should be less than max value");
        emit UpdateMinDepositAmount(minimumDepositEthAmount, newValue);
        minimumDepositEthAmount = newValue;
    }

    function setMaxDepositAmount(uint256 newValue) external onlyOwner {
        require(newValue > minimumDepositEthAmount, "Max value should be greater than min value");
        emit UpdateMinDepositAmount(maximumDepositEthAmount, newValue);
        maximumDepositEthAmount = newValue;
    }

    function setTokenPerBNB(uint256 newValue) external onlyOwner {
        require(block.timestamp < privateSaleStartTimestamp || privateSaleStartTimestamp == 0, "Private sale already started");
        emit UpdateTokenPerBNB(tokenPerBNB, newValue);
        tokenPerBNB = newValue;
    }

    function setHardCapEthAmount(uint256 newValue) external onlyOwner {
        require(block.timestamp < privateSaleStartTimestamp, "Private sale already started");
        emit UpdateHardCapEthAmount(hardCapEthAmount, newValue);
        hardCapEthAmount = newValue;
    }

    function setPrivateSaleTime(uint256 start, uint256 end) external onlyOwner {
        require(privateSaleEndTimestamp == 0 && privateSaleStartTimestamp == 0, "Sale times cannot be changed after setting once");
        privateSaleStartTimestamp = start < block.timestamp ? block.timestamp : start;
        require(end > block.timestamp, "Sale End time should be grater than current time.");
        privateSaleEndTimestamp = end;
    }


    event UpdateMinDepositAmount(uint256 oldValue, uint256 newValue);
    event UpdateMaxDepositAmount(uint256 oldValue, uint256 newValue);
    event UpdateTokenPerBNB(uint256 oldValue, uint256 newValue);
    event UpdateHardCapEthAmount(uint256 oldValue, uint256 newValue);
    event Deposited(address indexed user, uint256 amount);
    event SendBack(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
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
     * @dev Throws if called by any account other than the owner
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