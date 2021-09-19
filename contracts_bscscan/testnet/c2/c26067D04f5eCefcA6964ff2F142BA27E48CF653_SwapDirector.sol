/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// File: contracts/interfaces/IOperContract.sol


pragma solidity =0.7.6;

interface IOperContract {
    function operator() external view returns (address);

    function owner() external view returns (address);
}

// File: contracts/interfaces/ISwapDirector.sol

pragma solidity =0.7.6;


interface ISwapDirector is IOperContract {
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.7.0;

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
    constructor () {
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

// File: contracts/lib/Operatable.sol


pragma solidity =0.7.6;


// seperate owner and operator, operator is for daily devops, only owner can update operator
contract Operatable is Ownable {
    address public operator;

    event SetOperator(address indexed oldOperator, address indexed newOperator);

    constructor(){
        operator = msg.sender;
        emit SetOperator(address(0), operator);
    }

    modifier onlyOperator() {
        require(msg.sender == operator, 'not operator');
        _;
    }

    function setOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0), 'bad new operator');
        address oldOperator = operator;
        operator = newOperator;
        emit SetOperator(oldOperator, newOperator);
    }
}

// File: contracts/lib/CheckOper.sol


pragma solidity =0.7.6;



// seperate owner and operator, operator is for daily devops, only owner can update operator
contract CheckOper is IOperContract {
    Operatable public operatable;

    event SetOperatorContract(address indexed oldOperator, address indexed newOperator);

    constructor(address _oper){
        operatable = Operatable(_oper);
        emit SetOperatorContract(address(0), _oper);
    }

    modifier onlyOperator() {
        require(operatable.operator() == msg.sender, 'not operator');
        _;
    }

    modifier onlyOwner() {
        require(operatable.owner() == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function operator() public view override returns (address) {
        return operatable.operator();
    }

    function owner() public view override returns (address) {
        return operatable.owner();
    }

    function setOperContract(address _oper) public onlyOwner {
        require(_oper != address(0), 'bad new operator');
        address oldOperator = _oper;
        operatable = Operatable(_oper);
        emit SetOperatorContract(oldOperator, _oper);
    }
}

// File: contracts/SwapDirector.sol

pragma solidity =0.7.6;



contract SwapDirector is ISwapDirector, CheckOper {
    mapping(uint24 => int24) private _feeAmountTickSpacing;

    constructor(address _operatorMsg) CheckOper(_operatorMsg) {
        _feeAmountTickSpacing[500] = 10;
        _feeAmountTickSpacing[1000] = 20;
        _feeAmountTickSpacing[1500] = 30;
        _feeAmountTickSpacing[2000] = 40;
        _feeAmountTickSpacing[3000] = 60;
        _feeAmountTickSpacing[4000] = 80;
        _feeAmountTickSpacing[5000] = 100;
        _feeAmountTickSpacing[10000] = 200;
    }

    function feeAmountTickSpacing(uint24 fee) public view override returns (int24) {
        return _feeAmountTickSpacing[fee];
    }

    function enableFeeAmount(uint24 fee, int24 tickSpacing) public onlyOperator {
        require(fee < 1000000);
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(_feeAmountTickSpacing[fee] == 0);
        _feeAmountTickSpacing[fee] = tickSpacing;
    }
}