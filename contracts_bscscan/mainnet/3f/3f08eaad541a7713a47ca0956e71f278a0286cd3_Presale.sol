/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// SPDX-License-Identifier: MIT

/*//////////////////////////////////////////////////////////////////////////////////////////////////
*
*   _____ ____  __  __ __  __          _   _ _____  ______ _____    _____  ______ ______ _____ 
*  / ____/ __ \|  \/  |  \/  |   /\   | \ | |  __ \|  ____|  __ \  |  __ \|  ____|  ____|_   _|
* | |   | |  | | \  / | \  / |  /  \  |  \| | |  | | |__  | |__) | | |  | | |__  | |__    | |  
* | |   | |  | | |\/| | |\/| | / /\ \ | . ` | |  | |  __| |  _  /  | |  | |  __| |  __|   | |  
* | |___| |__| | |  | | |  | |/ ____ \| |\  | |__| | |____| | \ \  | |__| | |____| |     _| |_ 
*  \_____\____/|_|  |_|_|  |_/_/    \_\_| \_|_____/|______|_|  \_\ |_____/|______|_|    |_____|
*                                                                                              
* $COMFI ICO Contract. Don't miss out: buy.commanderdefi.io                                                                                       
*//////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.6.0 <0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _creator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _creator = msgSender;
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

    modifier onlyCreator() {
        require(_creator == _msgSender(), "Ownable: caller is not the creator");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERCBurn {
    function burn(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract Presale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public token = 0x1c934DA97CA679e1EFD3878090e90cAFc6bd56FE;
    // address public token = 0x3cDF630d16B8709c3174784d113B78ee052D95f4;

    mapping (address => bool) private _inICO;

    bool public isIco = true; 

    mapping (uint8 => uint256) public usdForPhases;

    uint256 public totalDepositAmount = 70000;
    uint8 public currentPhase = 2;
    uint public minBuyAmount = 40;
    uint public MaxPhase = 4;
    uint256 private totalSoldToken;

    address payable public wallet;

    mapping (uint8 => uint256) public comFiAllocated;


    // main
    address public uniswapRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // test
    // address public uniswapRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    // address public wbnb = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    // address public busd = 0x370a3ce51113E09f7a585795e5d435B5EB5bb6aA;

    constructor() {
        usdForPhases[0] = 30000;
        usdForPhases[1] = 40000;
        usdForPhases[2] = 160000;
        usdForPhases[3] = 320000;
        usdForPhases[4] = 640000;

        comFiAllocated[0] = 3500000000000;
        comFiAllocated[1] = 4000000000000;
        comFiAllocated[2] = 8000000000000;
        comFiAllocated[3] = 11500000000000;
        comFiAllocated[4] = 20000000000000;
    }

    function setOpenICO(bool _isIco) external onlyOwner {
        isIco = _isIco;
    }

    function set_MaxPhase(uint _amount) external onlyOwner {
        MaxPhase = _amount;
    }

    function set_minBuyAmount(uint256 _amount) external onlyOwner {
        minBuyAmount = _amount;
    }

    function set_token(address _token) external onlyOwner {
        token = _token;
    }

    function set_comFiAllocated(uint8 _phase ,uint256 _amount) external onlyOwner {
        comFiAllocated[_phase] = _amount;
    }

    function set_usdForPhases(uint8 _phase ,uint256 _amount) external onlyOwner {
        usdForPhases[_phase] = _amount;
    }

    function withdrawlp (address _lpToken, address _des) external onlyOwner {
        uint _amount = IERCBurn(_lpToken).balanceOf(address(this));
        TransferHelper.safeTransfer(_lpToken, _des, _amount);
    }

    function withdrawEth(address _des) external onlyOwner {
        payable(_des).transfer(address(this).balance);
    }

    function buyTokens(address _des) payable external nonReentrant {
        require(isIco, "It is not activated");
        // require(comFiAllocated[currentPhase]-totalSoldToken < amountToGive.mul(9).sub(10), "exceed sell amount");
        uint256 usdAmount = msg.value.mul(getBNBPrice()).div(1 ether);
        require(usdAmount>=minBuyAmount, "BuyFail: MinBuyAmount");
        uint256 amountToGive = getAmountToGive(usdAmount);
        totalDepositAmount = totalDepositAmount.add(usdAmount);
        if(totalDepositAmount >= usdForPhases[currentPhase] && currentPhase <= MaxPhase - 1) {
            totalDepositAmount = totalDepositAmount - usdForPhases[currentPhase];
            currentPhase = currentPhase + 1;
        }
        totalSoldToken = totalSoldToken + amountToGive;
        TransferHelper.safeTransfer(address(token), _des, amountToGive);
        _inICO[msg.sender] = true;
    }

    function isInICO(address account) public view returns(bool) {
        return _inICO[account];
    }

    function getAmountToGive(uint256 usdAmount) view public returns(uint256) {
        uint8 tokenDecimal = IERCBurn(token).decimals();
        uint256 amountToGive = usdAmount.mul(comFiAllocated[currentPhase]).div(usdForPhases[currentPhase]).mul(10**tokenDecimal);
        return amountToGive;
    }

    receive() external payable {}

    function getBNBPrice() public view returns (uint256) {

        address[] memory path;
        path = new address[](2);
        path[0] = wbnb;
        path[1] = busd;
        uint256[] memory amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(1, path);

        return amounts[amounts.length - 1];
    }
}