/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-06
 */

// File: @openzeppelin/contracts/utils/Address.sol
//admin - 0xe43C5a175be55926672068fF83d78f1DA7F71a12

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
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );

        (bool success, ) = recipient.call{value: amount}('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, 'Address: low-level call failed');
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                'Address: low-level call with value failed'
            );
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
        require(
            address(this).balance >= value,
            'Address: insufficient balance for call'
        );
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                'Address: low-level static call failed'
            );
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
        require(isContract(target), 'Address: static call to non-contract');

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                'Address: low-level delegate call failed'
            );
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
        require(isContract(target), 'Address: delegate call to non-contract');

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function decimals() external view returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

pragma solidity ^0.8.0;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                'SafeERC20: decreased allowance below zero'
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: sale.sol

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.8.0;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

contract TokenSale is Ownable {
    using SafeERC20 for IERC20;

    bool public paused;
    address public dev;
    address public admin;
    address public investor;

    IERC20 usdt = IERC20(0x8EBe3706fceE695fA006622416C24728d46d34bB);
    IERC20 btc = IERC20(0xEf69eFfd3dA25c5F6590366320B751966506Af4d);
    IERC20 eth = IERC20(0xea6838c9e17ed7334682dF1d96A7852cCE370eFe);
    IERC20 busd = IERC20(0xF188Fcd3e22FA9C3204A285b7bbAb4F3cB8b9c00);

    // types:
    // 1 - USDT
    // 2 - BNB
    // 3 - BTC
    // 4 - ETH
    // 5 - BUSD

    uint256 public maxSaleAmount = 50000 ether;
    uint256 public price = 43000000;
    uint256 public totalTokenSold;
    uint256 public start;
    uint256 public end;
    uint256 public refBonus = 10; // 10%
    uint256 public devDividend = 25; //25%
    uint256 public ownerDividend = 65; // 65%
    uint256 public investorDividend = 10; // 10%

    uint256 public startId = 10000;
    uint256 public currId;

    AggregatorInterface public pricefeedUSDT =
        AggregatorInterface(0xEca2605f0BCF2BA5966372C99837b1F182d3D620);
    AggregatorInterface public pricefeedBNB =
        AggregatorInterface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    AggregatorInterface public pricefeedBTC =
        AggregatorInterface(0x5741306c21795FdCBb9b265Ea0255F499DFe515C);
    AggregatorInterface public pricefeedETH =
        AggregatorInterface(0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7);
    AggregatorInterface public pricefeedBUSD =
        AggregatorInterface(0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa);

    IERC20 public token = IERC20(0xF768C1253A7321Cd449Af066708eFFD9A852618b);

    mapping(address=>uint256) public usersId;
    mapping(uint256=>address) public usersAddresses;

    event TokenPurchasedEvent(
        address _purchasingAccount,
        uint256 _referrer,
        uint256 _tokenType,
        uint256 indexed _tokensPurchase,
        uint256 indexed _amountPaid,
        uint256 indexed _currPrice
    );

    modifier isNotPaused() {
        require(paused == false, 'contract is paused');
        _;
    }

    constructor(address _admin,address _dev, address _investor) public {
        //needs to be updated
        admin = _admin;
        dev = _dev;
        investor = _investor;
        start = block.timestamp;
        end = block.timestamp+10 days;
        currId = 10000;
        usersId[admin] = currId;
        usersAddresses[currId] = admin;
    }

    /* GETTERS */

    // to get token address through types
    // types:
    // 1 - USDT
    // 2 - BNB
    // 3 - BTC
    // 4 - ETH
    // 5 - BUSD
    function getTokensByType(uint256 _type)
        public
        view
        returns (IERC20 _token)
    {
        require(_type != 2, 'type 2 is for BNB');

        if (_type == 1) {
            return usdt;
        } else if (_type == 3) {
            return btc;
        } else if (_type == 4) {
            return eth;
        } else if (_type == 5) {
            return busd;
        }
    }

    // to get current token price in usd
    function getCurrentPriceInUSD(uint256 _type)
        public
        view
        returns (uint256 _price)
    {
        if (_type == 1) {
            uint256 res = uint256(pricefeedUSDT.latestAnswer());
            return res;
        } else if (_type == 2) {
            uint256 res = uint256(pricefeedBNB.latestAnswer());
            return res;
        } else if (_type == 3) {
            uint256 res = uint256(pricefeedBTC.latestAnswer());
            return res;
        } else if (_type == 4) {
            uint256 res = uint256(pricefeedETH.latestAnswer());
            return res;
        } else if (_type == 5) {
            uint256 res = uint256(pricefeedBUSD.latestAnswer());
            return res;
        }
    }

    // get amount to be paid to buy _amount tokens of type _type
    function amountNeedsToBePaid(uint256 _amount, uint256 _type)
        public
        view
        returns (uint256)
    {
        uint256 res = getCurrentPriceInUSD(_type);
        uint256 amount = (_amount * price / res);
        return amount;
    }
    
    function getCorrespondingTokens(uint256 _amount,uint256 _type) public view returns(uint256){
        uint256 currPrice = getCurrentPriceInUSD(_type);
        uint256 recievingEQX = (_amount * currPrice / price);
        return recievingEQX;
    }

    // how much token user will get after applying bonus
    function getReceivingTokens(uint256 _amount)
        public
        pure
        returns (uint256 _receivingAmount)
    {
        if (_amount >= 5000 ether && _amount < 10000 ether) {
            _amount = _amount + _amount * 5 / 100;
        } else if (_amount >= 10000 ether && _amount < 25000 ether) {
            _amount = _amount + _amount * 10 / 100;
        } else if (_amount >= 25000 ether && _amount < 50000 ether) {
            _amount = _amount + _amount * 15 / 100;
        } else if (_amount >= 50000 ether) {
            _amount = _amount + _amount * 25 / 100;
        }
        return _amount;
    }

    /* SETTERS */

    // this will buy tokens equal to amount entered plus bonus if applicable
    function buyTokens(
        uint256 _referrer,
        uint256 _amount,
        uint256 _type
    ) public payable isNotPaused {
        require(_amount <= maxSaleAmount, 'max limit reached');
        require(_referrer>=startId && _referrer<=currId, "Invalid referrer");
        if(usersId[msg.sender]<startId){
            currId++;
            usersId[msg.sender] = currId;
            usersAddresses[currId] = msg.sender;
        }
        uint256 currPrice = getCurrentPriceInUSD(_type);
        uint256 recievingAmount;
        uint256 amountToPay;
        if (_type == 2) {
            amountToPay = amountNeedsToBePaid(_amount, _type);
            require(amountToPay<=msg.value,"insufficient amount");
            if(msg.value>amountToPay){
                payable(msg.sender).transfer(msg.value - amountToPay);
            }
            payable(investor).transfer(amountToPay * investorDividend / 100);
            payable(admin).transfer(amountToPay * ownerDividend / 100);
            payable(dev).transfer(amountToPay * devDividend / 100);
            
        } else {
            IERC20 depositToken = getTokensByType(_type);
            amountToPay = amountNeedsToBePaid(_amount, _type);
            depositToken.safeTransferFrom(
                msg.sender,
                address(this),
                amountToPay
            );
            depositToken.safeTransferFrom(
                msg.sender,
                investor,
                (_amount * investorDividend / 100)
            );
            depositToken.safeTransferFrom(
                msg.sender,
                admin,
                (_amount * ownerDividend / 100)
            );
            depositToken.safeTransferFrom(
                msg.sender,
                dev,
                (_amount * devDividend / 100)
            );
        }
        
        recievingAmount = getReceivingTokens(_amount);
        totalTokenSold = totalTokenSold + recievingAmount;


        token.safeTransfer(
            msg.sender,
            recievingAmount
        );
    
   if(usersAddresses[_referrer]!=address(0))
        token.safeTransfer(usersAddresses[_referrer], recievingAmount * refBonus / 100);

        emit TokenPurchasedEvent(
            msg.sender,
            _referrer,
            _type,
            recievingAmount,
            amountToPay,
            currPrice
        );
    }

    // function used in case accidently someone sends their tokens in contract to avoid its permanent locking
    function inCaseTokensGetStuck(IERC20 _token, address _receivingAccount)
        public
        onlyOwner
    {
        require(_receivingAccount != address(0), 'invalid address');
        _token.safeTransfer(_receivingAccount, _token.balanceOf(address(this)));
    }

    // this will update sale start or end time, _isStart = true means update start time otherwise end time
    function updateSaleStartEndTime(uint256 _newTime, bool _isStart)
        public
        onlyOwner
        isNotPaused
    {
        if (_isStart) {
            start = _newTime;
        } else {
            end = _newTime;
        }
    }

    // update price feeder contract in future
    function updatePriceFeedContract(
        AggregatorInterface _newPriceFeeder,
        uint256 _type
    ) public onlyOwner isNotPaused {
        if (_type == 1) {
            pricefeedUSDT = _newPriceFeeder;
        } else if (_type == 2) {
            pricefeedBNB = _newPriceFeeder;
        } else if (_type == 3) {
            pricefeedBTC = _newPriceFeeder;
        } else if (_type == 4) {
            pricefeedETH = _newPriceFeeder;
        } else if (_type == 5) {
            pricefeedBUSD = _newPriceFeeder;
        }
    }

    // sets new price for token in usd, _newPrice will be with 8 decimals
    function updatePrice(uint256 _newPrice) public onlyOwner isNotPaused {
        price = _newPrice;
    }

    // pause the contract if _pause is true else unpause
    function setPaused(bool _pause) public onlyOwner {
        paused = _pause;
    }

    // will destroy smart contract, not recommended
    function destroySmartContract(address payable _to) public onlyOwner {
        selfdestruct(_to);
    }

    function updateWallets(address _dev,address _admin,address _investor)
        public
        onlyOwner
    {
        require(_dev != address(0) && _admin!=address(0) && _investor!=address(0), 'invalid address');
        admin = _admin;
        investor = _investor;
        dev = _dev;
    }

    function changeDividends(uint256 _dev,uint256 _admin,uint256 _investor) public onlyOwner isNotPaused{
        require(_dev+_admin+_investor==100,"invalid percent");
        devDividend = _dev;
        ownerDividend =_admin;
        investorDividend = _investor;
    }

    // function to change referral bonus percent
    function changeReferralBonus(uint256 _newAmount)
        public
        onlyOwner
        isNotPaused
    {
        refBonus = _newAmount;
    }
}