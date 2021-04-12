/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// File: original_contracts/deployer/IPartnerDeployer.sol

pragma solidity 0.7.5;


interface IPartnerDeployer {

    function deploy(
        string calldata referralId,
        address payable feeWallet,
        uint256 fee,
        uint256 paraswapShare,
        uint256 partnerShare,
        address owner,
        uint256 timelock,
        uint256 maxFee,
        bool positiveSlippageToUser,
        bool noPositiveSlippage
    )
        external
        returns(address);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: openzeppelin-solidity/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: original_contracts/IPartner.sol

pragma solidity 0.7.5;


interface IPartner {

    function getPartnerInfo() external view returns(
        address payable feeWallet,
        uint256 fee,
        uint256 partnerShare,
        uint256 paraswapShare,
        bool positiveSlippageToUser,
        bool noPositiveSlippage
    );
}

// File: original_contracts/Partner.sol

pragma solidity 0.7.5;





contract Partner is Ownable, IPartner {
    using SafeMath for uint256;

    enum ChangeType { _, FEE, WALLET, SLIPPAGE }

    struct ChangeRequest {
        uint256 fee;
        address payable wallet;
        bool slippageToUser;
        bool completed;
        uint256 requestedBlockNumber;
    }

    mapping(uint256 => ChangeRequest) private _typeVsChangeRequest;

    string private _referralId;

    address payable private _feeWallet;

    //It should be in basis points. For 1% it should be 100
    uint256 private _fee;

    //Paraswap share in the fee. For 20% it should 2000
    //It means 20% of 1% fee charged
    uint256 private _paraswapShare;

    //Partner share in the fee. For 80% it should be 8000
    uint256 private _partnerShare;

    //Number of blocks after which change request can be fulfilled
    uint256 private _timelock;

    uint256 private _maxFee;

    //Whether positive slippage will go to user
    bool private _positiveSlippageToUser;

    bool private _noPositiveSlippage;

    event FeeWalletChanged(address indexed feeWallet);
    event FeeChanged(uint256 fee);

    event ChangeRequested(
        ChangeType changeType,
        uint256 fee,
        address wallet,
        bool positiveSlippageToUser,
        uint256 requestedBlockNumber
    );
    event ChangeRequestCancelled(
        ChangeType changeType,
        uint256 fee,
        address wallet,
        bool positiveSlippageToUser,
        uint256 requestedBlockNumber
    );
    event ChangeRequestFulfilled(
        ChangeType changeType,
        uint256 fee,
        address wallet,
        bool positiveSlippageToUser,
        uint256 requestedBlockNumber,
        uint256 fulfilledBlockNumber
    );

    constructor(
        string memory referralId,
        address payable feeWallet,
        uint256 fee,
        uint256 paraswapShare,
        uint256 partnerShare,
        address owner,
        uint256 timelock,
        uint256 maxFee,
        bool positiveSlippageToUser,
        bool noPositiveSlippage
    )
        public
    {
        _referralId = referralId;
        _feeWallet = feeWallet;
        _fee = fee;
        _paraswapShare = paraswapShare;
        _partnerShare = partnerShare;
        _timelock = timelock;
        _maxFee = maxFee;
        _positiveSlippageToUser = positiveSlippageToUser;
        _noPositiveSlippage = noPositiveSlippage;

        transferOwnership(owner);
    }

    function getReferralId() external view returns(string memory) {
        return _referralId;
    }

    function getFeeWallet() external view returns(address payable) {
        return _feeWallet;
    }

    function getFee() external view returns(uint256) {
        return _fee;
    }

    function getPartnerShare() external view returns(uint256) {
        return _partnerShare;
    }

    function getParaswapShare() external view returns(uint256) {
        return _paraswapShare;
    }

    function getTimeLock() external view returns(uint256) {
        return _timelock;
    }

    function getMaxFee() external view returns(uint256) {
        return _maxFee;
    }

    function getNoPositiveSlippage() external view returns(bool) {
        return _noPositiveSlippage;
    }

    function getPositiveSlippageToUser() external view returns(bool) {
        return _positiveSlippageToUser;
    }

    function getPartnerInfo() external override view returns(
        address payable feeWallet,
        uint256 fee,
        uint256 partnerShare,
        uint256 paraswapShare,
        bool positiveSlippageToUser,
        bool noPositiveSlippage
    )
    {
        return(
            _feeWallet,
            _fee,
            _partnerShare,
            _paraswapShare,
            _positiveSlippageToUser,
            _noPositiveSlippage
        );
    }

    function getChangeRequest(
        ChangeType changeType
    )
        external
        view
        returns(
            uint256,
            address,
            bool,
            uint256
        )
    {
        ChangeRequest memory changeRequest = _typeVsChangeRequest[uint256(changeType)];

        return(
            changeRequest.fee,
            changeRequest.wallet,
            changeRequest.completed,
            changeRequest.requestedBlockNumber
        );
    }

    function changeFeeRequest(uint256 fee) external onlyOwner {
        require(fee <= _maxFee, "Invalid fee passed!!");
        ChangeRequest storage changeRequest = _typeVsChangeRequest[uint256(ChangeType.FEE)];
        require(
            changeRequest.requestedBlockNumber == 0 || changeRequest.completed,
            "Previous fee change request pending"
        );

        changeRequest.fee = fee;
        changeRequest.requestedBlockNumber = block.number;
        changeRequest.completed = false;
        emit ChangeRequested(
            ChangeType.FEE,
            fee,
            address(0),
            false,
            block.number
        );
    }

    function changeWalletRequest(address payable wallet) external onlyOwner {
        require(wallet != address(0), "Invalid fee wallet passed!!");
        ChangeRequest storage changeRequest = _typeVsChangeRequest[uint256(ChangeType.WALLET)];

        require(
            changeRequest.requestedBlockNumber == 0 || changeRequest.completed,
            "Previous fee change request pending"
        );

        changeRequest.wallet = wallet;
        changeRequest.requestedBlockNumber = block.number;
        changeRequest.completed = false;
        emit ChangeRequested(
            ChangeType.WALLET,
            0,
            wallet,
            false,
            block.number
        );
    }

    function changePositiveSlippageToUser(bool slippageToUser) external onlyOwner {
        ChangeRequest storage changeRequest = _typeVsChangeRequest[uint256(ChangeType.SLIPPAGE)];

        require(
            changeRequest.requestedBlockNumber == 0 || changeRequest.completed,
            "Previous slippage change request pending"
        );

        changeRequest.slippageToUser = slippageToUser;
        changeRequest.requestedBlockNumber = block.number;
        changeRequest.completed = false;
        emit ChangeRequested(
            ChangeType.SLIPPAGE,
            0,
            address(0),
            slippageToUser,
            block.number
        );
    }

    function confirmChangeRequest(ChangeType changeType) external onlyOwner {
        ChangeRequest storage changeRequest = _typeVsChangeRequest[uint256(changeType)];

        require(
            changeRequest.requestedBlockNumber > 0 && !changeRequest.completed,
            "Invalid request"
        );

        require(
            changeRequest.requestedBlockNumber.add(_timelock) <= block.number,
            "Request is in waiting period"
        );

        changeRequest.completed = true;

        if(changeType == ChangeType.FEE) {
            _fee = changeRequest.fee;
        }

        else if(changeType == ChangeType.WALLET) {
            _feeWallet = changeRequest.wallet;
        }
        else {
            _positiveSlippageToUser = changeRequest.slippageToUser;
        }

        emit ChangeRequestFulfilled(
            changeType,
            changeRequest.fee,
            changeRequest.wallet,
            changeRequest.slippageToUser,
            changeRequest.requestedBlockNumber,
            block.number
        );
    }

    function cancelChangeRequest(ChangeType changeType) external onlyOwner {
        ChangeRequest storage changeRequest = _typeVsChangeRequest[uint256(changeType)];

        require(
            changeRequest.requestedBlockNumber > 0 && !changeRequest.completed,
            "Invalid request"
        );
        changeRequest.completed = true;

        emit ChangeRequestCancelled(
            changeType,
            changeRequest.fee,
            changeRequest.wallet,
            changeRequest.slippageToUser,
            changeRequest.requestedBlockNumber
        );

    }

}

// File: original_contracts/deployer/PartnerDeployer.sol

pragma solidity 0.7.5;




contract PartnerDeployer is IPartnerDeployer {

    function deploy(
        string calldata referralId,
        address payable feeWallet,
        uint256 fee,
        uint256 paraswapShare,
        uint256 partnerShare,
        address owner,
        uint256 timelock,
        uint256 maxFee,
        bool positiveSlippageToUser,
        bool noPositiveSlippage
    )
        external
        override
        returns(address)
    {
        Partner partner = new Partner(
            referralId,
            feeWallet,
            fee,
            paraswapShare,
            partnerShare,
            owner,
            timelock,
            maxFee,
            positiveSlippageToUser,
            noPositiveSlippage
        );
        return address(partner);
    }
}