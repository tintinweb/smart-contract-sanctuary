/**
 *Submitted for verification at arbiscan.io on 2021-10-16
*/

pragma solidity ^0.6.0;

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IOracle {
    function getUnderlyingPrice(address) view external returns(uint256);
}

contract OracleObserver is Ownable {
    struct Arg{
        address source;
        uint256 scale;
    }
    address public oracle;
    mapping(address => Arg) public args;
    
    constructor(address _oracle) public {
        oracle = _oracle;
    }
    
    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }
    
    function setPriceArgument(address[] calldata targets, address[] calldata sources, uint256[] calldata scales) external onlyOwner {
        require(targets.length == sources.length && targets.length == scales.length, "Oracle:length error");
        for (uint256 i = 0; i < targets.length; i++) {
            require(targets[i] != address(0), "Oracle:zero address");
            require(scales[i] <= 36, "Oracle:decimal overflow");
            Arg storage arg = args[targets[i]];
            arg.source = sources[i];
            arg.scale = scales[i];
        }
    }
    
    function getPrice(address token) external view returns (uint256 price, uint256 updateTime) {
        Arg memory arg = args[token];
        if (arg.source == address(0)) {
            return (0,0);
        }
        return (IOracle(oracle).getUnderlyingPrice(arg.source) * (10 ** (36 - arg.scale)) / (10 ** 18), 0);
    }
}