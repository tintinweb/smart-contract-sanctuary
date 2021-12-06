/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
// pragma experimental SMTChecker;

/// @title ERC20If
abstract contract ERC20If {
    function totalSupply() virtual public view returns (uint256);

    function balanceOf(address _who) virtual public view returns (uint256);

    function transfer(address _to, uint256 _value) virtual public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address _owner, address _spender) virtual public view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool);

    function approve(address _spender, uint256 _value) virtual public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}






// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract OwnableIf {

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner(), "not owner......");
        _;
    }

    function _owner() view virtual public returns (address);
}

















// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is OwnableIf {
    address public owner;

    function _owner() view override public returns (address){
        return owner;
    }

    //    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    //    /**
    //     * @dev Throws if called by any account other than the owner.
    //     */
    //    modifier onlyOwner() {
    //        require(msg.sender == owner);
    //        _;
    //    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    //   function renounceOwnership() public onlyOwner {
    //     emit OwnershipRenounced(owner);
    //     owner = address(0);
    //   }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) virtual public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "invalid _newOwner");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}




// File: openzeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
    address public pendingOwner;

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "no permission");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) override public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}










/// @title CanReclaimToken
abstract contract CanReclaimToken is OwnableIf {

    function reclaimToken(ERC20If _token) external onlyOwner {
        uint256 balance = _token.balanceOf((address)(this));
        require(_token.transfer(_owner(), balance));
    }

}




// 












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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract ccTokenWrap is Ownable, CanReclaimToken {
    using SafeMath for uint256;
    ERC20If public cctoken;
    string public nativeCoinType;
    address public cctokenRepository;
    uint256 public wrapSeq;
    mapping(bytes32 => uint256) public wrapSeqMap;

    // bool public checkSignature = true;

    uint256 constant rate_precision = 1e10;

    // function _checkSignature(bool _b) public onlyOwner {
    //     checkSignature = _b;
    // }

    function _cctokenRepositorySet(address newRepository)
        public
        onlyOwner
    {
        require(newRepository != (address)(0), "invalid addr");
        cctokenRepository = newRepository;
    }

    function wrapHash(string memory nativeCoinAddress, string memory nativeTxId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(nativeCoinAddress, nativeTxId));
    }

    event SETUP(
        address _cctoken,
        string _nativeCoinType,
        address _cctokenRepository
    );

    function setup(
        address _cctoken,
        string memory _nativeCoinType,
        address _cctokenRepository,
        address _initOwner
    )
        public
        returns (
            bool
        )
    {
        if (wrapSeq <= 0) {
            wrapSeq = 1;
            cctoken = (ERC20If)(_cctoken);
            nativeCoinType = _nativeCoinType;
            cctokenRepository = _cctokenRepository;
            owner = _initOwner;
            emit SETUP(_cctoken, _nativeCoinType, _cctokenRepository);
            emit OwnershipTransferred(_owner(), _initOwner);
            return true;
        }
        return false;
    }

    function uintToString(uint256 _i) public pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function toHexString(bytes memory data)
        public
        pure
        returns (string memory)
    {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function toHexString(address account) public pure returns (string memory) {
        return toHexString(abi.encodePacked(account));
    }

    function calcCCTokenAmount(
        uint256 amt,
        uint256 fee,
        uint256 rate
    ) public pure returns (uint256) {
        return amt.sub(fee).mul(rate).div(rate_precision);
    }

    function encode(
        address receiveCCTokenAddress,
        string memory nativeCoinAddress,
        uint256 amt,
        uint256 fee,
        uint256 rate,
        uint64 deadline
    ) public view returns (bytes memory) {
        uint id;
        assembly {
            id := chainid()
        }
        return
            abi.encodePacked(
                "wrap ",
                nativeCoinType,
                "\nto:",
                toHexString(receiveCCTokenAddress),
                "\namt:",
                uintToString(amt),
                "\nfee:",
                uintToString(fee),
                "\nrate:",
                uintToString(rate),
                "\ndeadline:",
                uintToString(deadline),
                "\naddr:",
                nativeCoinAddress,
                "\nchainid:",
                uintToString(id)
            );
    }

    function personalMessage(bytes memory _msg)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                uintToString(_msg.length),
                _msg
            );
    }

    function recoverPersonalSignature(
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory text
    ) public pure returns (address) {
        bytes32 h = keccak256(personalMessage(text));
        return ecrecover(h, v, r, s);
    }

    function wrap(
        address ethAccount,
        address receiveCCTokenAddress,
        string memory nativeCoinAddress,
        string memory nativeTxId,
        uint256 amt,
        uint256 fee,
        uint256 rate,
        uint64 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public onlyOwner returns (bool) {
        uint256 cctokenAmount = calcCCTokenAmount(amt, fee, rate);
        // if (checkSignature) 
        {
            bytes memory text =
                encode(
                    receiveCCTokenAddress,
                    nativeCoinAddress,
                    amt,
                    fee,
                    rate,
                    deadline
                );

            address addr = recoverPersonalSignature(r, s, v, text);
            require(addr != address(0), "0 address");
            require(addr == ethAccount, "invalid signature");
        }
        require(
            wrapSeqMap[wrapHash(nativeCoinAddress, nativeTxId)] <= 0,
            "wrap dup."
        );
        wrapSeqMap[wrapHash(nativeCoinAddress, nativeTxId)] = wrapSeq;
        wrapSeq = wrapSeq + 1;

        require(
            cctoken.transferFrom(
                cctokenRepository,
                receiveCCTokenAddress,
                cctokenAmount
            ),
            "transferFrom failed"
        );
        emit WRAP_EVENT(
            wrapSeq,
            ethAccount,
            receiveCCTokenAddress,
            nativeCoinAddress,
            nativeTxId,
            amt,fee,rate,
            deadline,
            r,
            s,
            v
        );

        return true;
    }

    event WRAP_EVENT(
        uint256 indexed wrapSeq,
        address ethAccount,
        address receiveCCTokenAddress,
        string nativeCoinAddress,
        string nativeTxId,
        uint256 amt,
        uint256 fee,
        uint256 rate,
        uint64 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    );
}


contract ccTokenDeSwap is ccTokenWrap {
    using SafeMath for uint256;

    //PENDING=》CANCELED
    //PENDING=》APPROVED
    //APPROVED=》FINISHED
    enum OrderStatus {PENDING, CANCELED, APPROVED, FINISHED}

    function getStatusString(OrderStatus status)
        internal
        pure
        returns (string memory)
    {
        if (status == OrderStatus.PENDING) {
            return "pending";
        } else if (status == OrderStatus.CANCELED) {
            return "canceled";
        } else if (status == OrderStatus.APPROVED) {
            return "approved";
        } else if (status == OrderStatus.FINISHED) {
            return "finished";
        } else {
            // unreachable.
            return "unknown";
        }
    }

    struct UnWrapOrder {
        address ethAccount;
        uint256 nativeCoinAmount;
        uint256 cctokenAmount;
        string nativeCoinAddress;
        string nativeTxId;
        uint256 requestBlockNo;
        uint256 confirmedBlockNo;
        OrderStatus status;
        uint256 fee;
        uint256 rate;
    }

    UnWrapOrder[] public unWrapOrders;
    bool public paused = false;
    modifier notPaused() {
        require(!paused, "paused");
        _;
    }

    function pause(bool _paused) public onlyOwner returns (bool) {
        paused = _paused;
        return true;
    }

    function getUnWrapOrderNum() public view returns (uint256) {
        return unWrapOrders.length;
    }

    function getUnWrapOrderInfo(uint256 seq)
        public
        view
        returns (
            address ethAccount,
            uint256 nativeCoinAmount,
            uint256 cctokenAmount,
            string memory nativeCoinAddress,
            string memory nativeTxId,
            uint256 requestBlockNo,
            uint256 confirmedBlockNo,
            string memory status
        )
    {
        require(seq < unWrapOrders.length, "invalid seq");
        UnWrapOrder memory order = unWrapOrders[seq];
        ethAccount = order.ethAccount;
        nativeCoinAmount = order.nativeCoinAmount;
        cctokenAmount = order.cctokenAmount;
        nativeCoinAddress = order.nativeCoinAddress;
        nativeTxId = order.nativeTxId;
        requestBlockNo = order.requestBlockNo;
        confirmedBlockNo = order.confirmedBlockNo;
        status = getStatusString(order.status);
    }

    function calcUnWrapAmount(
        uint256 amt,
        uint256 fee,
        uint256 rate
    ) public pure returns (uint256) {
        return amt.sub(fee).mul(rate).div(rate_precision);
    }

    function unWrap(
        uint256 amt,
        uint256 fee,
        uint256 rate,
        string memory nativeCoinAddress
    ) public notPaused returns (bool) {
        address ethAccount = msg.sender;
        uint256 cctokenAmount = amt;
        uint256 nativeCoinAmount = calcUnWrapAmount(amt, fee, rate);
        require(
            cctoken.transferFrom(ethAccount, cctokenRepository, cctokenAmount),
            "transferFrom failed"
        );
        uint256 seq = unWrapOrders.length;
        unWrapOrders.push(
            UnWrapOrder({
                ethAccount: ethAccount,
                nativeCoinAmount: nativeCoinAmount,
                cctokenAmount: cctokenAmount,
                nativeCoinAddress: nativeCoinAddress,
                requestBlockNo: block.number,
                status: OrderStatus.PENDING,
                nativeTxId: "",
                confirmedBlockNo: 0,
                fee: fee,
                rate: rate
            })
        );
        emit UNWRAP_REQUEST(seq, ethAccount, nativeCoinAddress, amt, fee, rate);

        return true;
    }

    event UNWRAP_REQUEST(
        uint256 indexed seq,
        address ethAccount,
        string nativeCoinAddress,
        uint256 amt,
        uint256 fee,
        uint256 rate
    );

    event UNWRAP_APPROVE(uint256 indexed seq);

    function approveUnWrapOrder(
        uint256 seq,
        address ethAccount,
        uint256 nativeCoinAmount,
        uint256 cctokenAmount,
        string memory nativeCoinAddress
    ) public onlyOwner returns (bool) {
        require(unWrapOrders.length > seq, "invalid seq");
        UnWrapOrder memory order = unWrapOrders[seq];
        require(order.status == OrderStatus.PENDING, "status not pending");
        require(ethAccount == order.ethAccount, "invalid param1");
        require(cctokenAmount == order.cctokenAmount, "invalid param2");
        require(nativeCoinAmount == order.nativeCoinAmount, "invalid param3");
        require(
            stringEquals(nativeCoinAddress, order.nativeCoinAddress),
            "invalid param4"
        );

        unWrapOrders[seq].status = OrderStatus.APPROVED;
        emit UNWRAP_APPROVE(seq);
        return true;
    }

    event UNWRAP_CANCEL(uint256 indexed seq);

    function cancelUnWrapOrder(uint256 seq) public returns (bool) {
        require(unWrapOrders.length > seq, "invalid seq");
        UnWrapOrder memory order = unWrapOrders[seq];
        require(msg.sender == order.ethAccount, "invalid auth.");
        require(order.status == OrderStatus.PENDING, "status not pending");
        unWrapOrders[seq].status = OrderStatus.CANCELED;

        require(
            cctoken.transferFrom(
                cctokenRepository,
                order.ethAccount,
                order.cctokenAmount
            ),
            "transferFrom failed"
        );

        emit UNWRAP_CANCEL(seq);
        return true;
    }

    function stringEquals(string memory s1, string memory s2)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked(s1)) ==
            keccak256(abi.encodePacked(s2)));
    }

    event UNWRAP_FINISH(uint256 indexed seq, string nativeTxId);

    function finishUnWrapOrder(uint256 seq, string memory nativeTxId)
        public
        onlyOwner
        returns (bool)
    {
        require(unWrapOrders.length > seq, "invalid seq");
        UnWrapOrder memory order = unWrapOrders[seq];
        require(order.status == OrderStatus.APPROVED, "status not approved");

        unWrapOrders[seq].status = OrderStatus.FINISHED;
        unWrapOrders[seq].nativeTxId = nativeTxId;
        unWrapOrders[seq].confirmedBlockNo = block.number;
        emit UNWRAP_FINISH(seq, nativeTxId);
        return true;
    }

    address public pendingOwner;

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "no permission");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) override public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}














/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}





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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}


/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable UpgradeableProxy(_logic, "") {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);

         if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}


contract ccTokenDeSwapFactory is Claimable, CanReclaimToken {
    mapping(bytes32 => address) public deSwaps;

    function getDeSwap(string memory _nativeCoinType)
        public
        view
        returns (address)
    {
        bytes32 nativeCoinTypeHash =
            keccak256(abi.encodePacked(_nativeCoinType));
        return deSwaps[nativeCoinTypeHash];
    }

    function deployDeSwap(
        address _cctoken,
        string memory _nativeCoinType,
        address _cctokenRepository,
        address _operator
    ) public onlyOwner returns (bool) {
        bytes32 nativeCoinTypeHash =
            keccak256(abi.encodePacked(_nativeCoinType));
        require(_operator!=_owner(), "owner same as _operator");
        require(deSwaps[nativeCoinTypeHash] == (address)(0), "deEx exists.");
        ccTokenDeSwap cctokenDeSwap = new ccTokenDeSwap();
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(
                (address)(cctokenDeSwap),
                (address)(this),
                abi.encodeWithSignature(
                    "setup(address,string,address,address)",
                        _cctoken,
                    _nativeCoinType,
                        _cctokenRepository,
                    _operator
                )
            );

        proxy.changeAdmin(_owner());
        deSwaps[nativeCoinTypeHash] = (address)(proxy);

        return true;
    }
}