/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

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