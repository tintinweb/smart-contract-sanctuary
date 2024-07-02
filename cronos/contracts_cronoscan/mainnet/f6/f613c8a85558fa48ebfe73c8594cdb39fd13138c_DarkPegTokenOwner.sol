/**
 *Submitted for verification at cronoscan.com on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDarkPegTokenOperable {
    function setOracle(address _oracle) external;

    function setSellBurnRate(uint256 _sellBurnRate) external;

    function setSellCeilingSupplyRate(uint256 _sellCeilingSupplyRate) external;

    function setSellCeilingLiquidityRate(uint256 _sellCeilingLiquidityRate)
        external;

    function setPriceRange(uint256 _priceLowerRange, uint256 _priceUpperRange)
        external;

    function setWhitelisted(address _account, bool _status) external;

    function setLiquidityPair(address _account, bool _status) external;

    function setMainLiquidity(address _pair) external;

    function transferOperator(address newOperator_) external;

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function governanceRecoverUnsupported(address _token) external;
}

contract DarkPegTokenOwner is Ownable {
    address public pegToken;
    mapping(address => bool) private strategist_;

    /* ========== EVENTS ========== */

    event Strategist(address indexed account, bool isStrategist);

    /* ========== Modifiers =============== */

    modifier onlyStrategist() {
        require(strategist_[msg.sender], "!strategist_");
        _;
    }

    /* ========== GOVERNANCE ========== */

    constructor(address _pegToken) public {
        pegToken = _pegToken;
        strategist_[msg.sender] = true;
    }

    function setStrategist(address _account, bool _isStrategist)
        external
        onlyOwner
    {
        strategist_[_account] = _isStrategist;
        emit Strategist(_account, _isStrategist);
    }

    function setSellBurnRate(uint256 _sellBurnRate) external onlyStrategist {
        IDarkPegTokenOperable(pegToken).setSellBurnRate(_sellBurnRate);
    }

    function setSellCeilingSupplyRate(uint256 _sellCeilingSupplyRate)
        external
        onlyStrategist
    {
        IDarkPegTokenOperable(pegToken).setSellCeilingSupplyRate(
            _sellCeilingSupplyRate
        );
    }

    function setSellCeilingLiquidityRate(uint256 _sellCeilingLiquidityRate)
        external
        onlyStrategist
    {
        IDarkPegTokenOperable(pegToken).setSellCeilingLiquidityRate(
            _sellCeilingLiquidityRate
        );
    }

    function setPriceRange(uint256 _priceLowerRange, uint256 _priceUpperRange)
        external
        onlyStrategist
    {
        IDarkPegTokenOperable(pegToken).setPriceRange(
            _priceLowerRange,
            _priceUpperRange
        );
    }

    function setWhitelisted(address _account, bool _status)
        external
        onlyStrategist
    {
        IDarkPegTokenOperable(pegToken).setWhitelisted(_account, _status);
    }

    function setLiquidityPair(address _account, bool _status)
        external
        onlyStrategist
    {
        IDarkPegTokenOperable(pegToken).setLiquidityPair(_account, _status);
    }

    function setMainLiquidity(address _pair) external onlyStrategist {
        IDarkPegTokenOperable(pegToken).setMainLiquidity(_pair);
    }

    /* ========== EMERGENCY ========== */

    function tokenTransferOperator(address newOperator_) external onlyOwner {
        IDarkPegTokenOperable(pegToken).transferOperator(newOperator_);
    }

    function tokenTransferOwnership(address newOwner) external onlyOwner {
        IDarkPegTokenOperable(pegToken).transferOwnership(newOwner);
    }

    function tokenGovernanceRecoverUnsupported(address _token)
        external
        onlyOwner
    {
        IDarkPegTokenOperable(pegToken).governanceRecoverUnsupported(_token);
    }

    function governanceRecoverUnsupported(IERC20 _token) external onlyOwner {
        _token.transfer(owner(), _token.balanceOf(address(this)));
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public onlyOwner returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(
            success,
            string(
                "DarkPegTokenOwner::executeTransaction: Transaction execution reverted."
            )
        );

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }

    event ExecuteTransaction(
        address indexed target,
        uint256 value,
        string signature,
        bytes data
    );
}