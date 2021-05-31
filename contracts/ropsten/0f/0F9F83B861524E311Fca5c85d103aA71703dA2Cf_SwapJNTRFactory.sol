/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: No License (None)
pragma solidity =0.6.12;

//import "./SafeMath.sol";
//import "./Ownable.sol";



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/ownership/Ownable.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Ownable implementation from an openzeppelin version.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(),"Not Owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),"Zero address not allowed");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


interface ISwapFactory {
    function newFactory() external view returns(address);
}

contract SwapJNTRPair {
    using SafeMath for uint256;

    address public token;               // token address
    address public tokenForeign;        // Foreign token address
    address public foreignSwapPair;     // foreign SwapPair contract address (on other blockchain)
    address public factory;             // factory address


    // balanceOf contain two types of balance:
    // 1. balanceOf[user] - balance of tokens on native chain
    // 2. balanceOf[user+1] - swapped balance of foreign tokens. I.e. on BSC chain it contain amount of ETH that was swapped.  
    mapping (address => uint256) public balanceOf;

    modifier onlyFactory() {
        require(msg.sender == factory, "Caller is not the factory");
        _;
    }

    constructor() public {
        factory = msg.sender;
    }

    // swapAddress = user address + 1.
    // balanceOf contain two types of balance:
    // 1. balanceOf[user] - balance of tokens on native chain
    // 2. balanceOf[user+1] - swapped balance of foreign tokens. I.e. on BSC chain it contain amount of ETH that was swapped.
    function _swapAddress(address user) internal pure returns(address swapAddress) {
        swapAddress = address(uint160(user)+1);
    }

    function initialize(address _foreignPair, address tokenA, address tokenB) public onlyFactory {
        foreignSwapPair = _foreignPair;
        token = tokenA;
        tokenForeign = tokenB;
    }

    function update() public returns(bool) {
        factory = ISwapFactory(factory).newFactory();
        return true;
    }

    // user's deposit to the pool, waiting for swap
    function deposit(address user, uint256 amount) external onlyFactory returns(bool) {
        balanceOf[user] = balanceOf[user].add(amount);
        return true;
    }

    // request to claim token after swap
    function claimApprove(address user, uint256 amount) external onlyFactory returns(address, address) {
        address userSwap = _swapAddress(user);
        balanceOf[userSwap] = balanceOf[userSwap].add(amount);
        return (token, tokenForeign);
    }

}



interface IValidator {
    // returns: user balance, native (foreign for us) encoded balance, foreign (native for us) encoded balance
    function checkBalances(address pair, address foreignSwapPair, address user) external returns(uint256);
    // returns: user balance
    function checkBalance(address pair, address foreignSwapPair, address user) external returns(uint256);
    // returns: oracle fee
    function getOracleFee(uint256 req) external returns(uint256);  //req: 1 - cancel, 2 - claim, returns: value
}

interface IGatewayVault {
    function vaultTransfer(address token, address recipient, uint256 amount) external returns (bool);
    function vaultApprove(address token, address spender, uint256 amount) external returns (bool);
}

interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns(bool);
}

contract SwapJNTRFactory is Ownable {
    using SafeMath for uint256;
    
    address USDT = address(0x47A530f3Fa882502344DC491549cA9c058dbC7Da); // USDT address on ETH chain

    mapping(address => mapping(address => address payable)) public getPair;
    mapping(address => address) public foreignPair;
    address[] public allPairs;
    address public foreignFactory;

    mapping(address => bool) public canMint;  //if token we cen mint and burn token
    mapping(address => address) private _finalToken;

    uint256 public fee;
    address payable public validator;
    address public system;  // system address mey change fee amount
    bool public paused;
    address public gatewayVault; // GatewayVault contract

    address public newFactory;            // new factory address to upgrade
    event PairCreated(address indexed tokenA, address indexed tokenB, address pair, uint);
    event SwapRequest(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount);
    event Swap(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount);

    event ClaimRequest(address indexed tokenA, address indexed tokenB, address indexed user);
    event ClaimApprove(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount);

    modifier notPaused() {
        require(!paused,"Swap paused");
        _;
    }

    /**
    * @dev Throws if called by any account other than the system.
    */
    modifier onlySystem() {
        require(msg.sender == system, "Caller is not the system");
        _;
    }

    constructor (address _system, address _vault) public {
        system = _system;
        newFactory = address(this);
        gatewayVault = _vault;
    }

    function setFee(uint256 _fee) external onlySystem returns(bool) {
        fee = _fee;
        return true;
    }

    function setSystem(address _system) external onlyOwner returns(bool) {
        system = _system;
        return true;
    }

    function setValidator(address payable _validator) external onlyOwner returns(bool) {
        validator = _validator;
        return true;
    }

    function setPause(bool pause) external onlyOwner returns(bool) {
        paused = pause;
        return true;
    }

    function setForeignFactory(address _addr) external onlyOwner returns(bool) {
        foreignFactory = _addr;
        return true;
    }
    
    function setNewFactory(address _addr) external onlyOwner returns(bool) {
        newFactory = _addr;
        return true;
    }
    
    function setMintableToken(address _addr, bool _canMint) external onlyOwner returns(bool) {
        canMint[_addr] = _canMint;
        return true;
    }
    // TakenA should be JNTR token
    // for local swap (tokens on the same chain): pair = address(1) when TokenA = JNTR, and address(2) when TokenB = JNTR
    function createPair(address tokenA, address tokenB, bool local) public onlyOwner returns (address payable pair) {
        require(getPair[tokenA][tokenB] == address(0), 'PAIR_EXISTS'); // single check is sufficient
        if (local) {
            pair = payable(address(1));
            getPair[tokenA][tokenB] = pair;
            getPair[tokenB][tokenA] = pair;
            emit PairCreated(tokenA, tokenB, pair, allPairs.length);
            return pair;            
        }

        bytes memory bytecode = type(SwapJNTRPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        foreignPair[pair] = getForeignPair(tokenB, tokenA);
        SwapJNTRPair(pair).initialize(foreignPair[pair], tokenA, tokenB);

        getPair[tokenA][tokenB] = pair;
        allPairs.push(pair);
        emit PairCreated(tokenA, tokenB, pair, allPairs.length);
    }
    
    function getPairs(address tokenA, address tokenB) external view returns (address) {
        return getPair[tokenA][tokenB];
    }
        

    function getForeignPair(address tokenA, address tokenB) internal view returns(address pair) {
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                foreignFactory,
                keccak256(abi.encodePacked(tokenA, tokenB)),
                hex'a79d0b2d0d229d9f2750acf6e4ca00b89da9065d62058701247d526ed6b3e65d' // init code hash
            ))));
    }

    // set already existed pairs in case of contract upgrade
    function setPairs(address[] memory tokenA, address[] memory tokenB, address payable[] memory pair) external onlyOwner returns(bool) {
        uint256 len = tokenA.length;
        while (len > 0) {
            len--;
            getPair[tokenA[len]][tokenB[len]] = pair[len];
            if (pair[len] > address(8)) // we can use address(0)- address(8) as special marker
                foreignPair[pair[len]] = SwapJNTRPair(pair[len]).foreignSwapPair();
            allPairs.push(pair[len]);
            emit PairCreated(tokenA[len], tokenB[len], pair[len], allPairs.length);            
        }
        return true;
    }
    // calculates the CREATE2 address for a pair without making any external calls
    function pairAddressFor(address tokenA, address tokenB) external view returns (address pair, bytes32 bytecodeHash) {
        bytes memory bytecode = type(SwapJNTRPair).creationCode;
        bytecodeHash = keccak256(bytecode);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(tokenA, tokenB)),
                bytecodeHash    // hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    //user should approve tokens transfer before calling this function.
    // for local swap (tokens on the same chain): pair = address(1) when TokenA = JNTR, and address(2) when TokenB = JNTR
    function swap(address tokenA, address tokenB, uint256 amount, address user) external payable notPaused returns (bool) {
        require(amount != 0, "Zero amount");
        address payable pair = getPair[tokenA][tokenB];
        require(pair != address(0), 'PAIR_NOT_EXISTS');

        if (canMint[tokenA])
            IBEP20(tokenA).burnFrom(msg.sender, amount);
        else {
            require(gatewayVault != address(0), "No vault address");
            IBEP20(tokenA).transferFrom(msg.sender, gatewayVault, amount);
        }

        // if (pair == address(1)) { //local pair
        //     if (canMint[tokenB])
        //         IBEP20(tokenB).mint(msg.sender, amount);
        //     else
        //         IGatewayVault(gatewayVault).vaultTransfer(tokenB, msg.sender, amount);
        //     emit Swap(tokenA, tokenB, msg.sender, amount);
        // }
        // else {  // foreign pair
    
        // require(msg.value >= fee,"Insufficient fee");
        // transfer fee to validator. May be changed to request tokens for compensation
        // validator.transfer(msg.value);
        SwapJNTRPair(pair).deposit(user, amount);
        emit SwapRequest(tokenA, tokenB, user, amount);
            
        // }
        return true;
    }

    function _claim(address tokenA, address tokenB, address user) internal {
        address payable pair = getPair[tokenA][tokenB];
        require(pair > address(9), 'PAIR_NOT_EXISTS');
        IValidator(validator).checkBalance(pair, foreignPair[pair], user);
        
        emit ClaimRequest(tokenA, tokenB, user);
    }
    // amountB - amount of foreign token to swap
    function claimTokenBehalf(address tokenA, address tokenB,address finalToken, address user) external onlySystem notPaused returns (bool) {
        _claim(tokenA, tokenB, user);
        _finalToken[user] = finalToken;
        return true;
    }

    // function claim(address tokenA, address tokenB) external payable notPaused returns (bool) {
    //     uint256 claimFee = IValidator(validator).getOracleFee(1);
    //     require (msg.value >= claimFee, "Not enough fee");
    //     _claim(tokenA, tokenB, msg.sender);
    //     return true;
    // }

    // On both side (BEP and ERC) we accumulate user's deposits (balance).
    // If balance on one side it greater then on other, the difference means user deposit.
    function balanceCallback(address payable pair, address user, uint256 balanceForeign) external returns(bool) {
        require (validator == msg.sender, "Not validator");
        // address finalToken = _finalToken[user];
        address tokenA;
        address tokenB;
        address swapAddress = address(uint160(user)+1);
        uint256 swappedBalance = SwapJNTRPair(pair).balanceOf(swapAddress);
        require(balanceForeign > swappedBalance, "No tokens deposit");
        uint256 amount = balanceForeign - swappedBalance;
        (tokenA, tokenB) = SwapJNTRPair(pair).claimApprove(user, amount);
        // if (canMint[tokenA])
        //     IBEP20(tokenA).mint(user, amount);
        // else
        
        IGatewayVault(gatewayVault).vaultTransfer(USDT, system, amount);        
        emit ClaimApprove(tokenA, tokenB, user, amount);
        return true;
    }
}