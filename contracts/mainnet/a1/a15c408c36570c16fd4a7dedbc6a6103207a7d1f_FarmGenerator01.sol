// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./Farm01.sol";

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
contract Ownable is Context {
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

interface IERCBurn {
    function burn(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
}

interface FarmFactory {
    function registerFarm (address _farmAddress) external;
}

interface IUniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract FarmGenerator01 is Ownable {
    using SafeMath for uint256;
    
    FarmFactory public factory;
    
    struct FarmParameters {
        uint256 bonusBlocks;
        uint256 totalBonusReward;
        uint256 numBlocks;
        uint256 endBlock;
        uint256 requiredAmount;
    }
    
    constructor(FarmFactory _factory) public {
        factory = _factory;
    }
    
    /**
     * @notice Determine the endBlock based on inputs. Used on the front end to show the exact settings the Farm contract will be deployed with
     */
    function determineEndBlock (uint256 _amount, uint256 _blockReward, uint256 _startBlock, uint256 _bonusEndBlock, uint256 _bonus) public pure returns (uint256, uint256) {
        FarmParameters memory params;
        params.bonusBlocks = _bonusEndBlock.sub(_startBlock);
        params.totalBonusReward = params.bonusBlocks.mul(_bonus).mul(_blockReward);
        params.numBlocks = _amount.sub(params.totalBonusReward).div(_blockReward);
        params.endBlock = params.numBlocks.add(params.bonusBlocks).add(_startBlock);
        
        uint256 nonBonusBlocks = params.endBlock.sub(_bonusEndBlock);
        uint256 effectiveBlocks = params.bonusBlocks.mul(_bonus).add(nonBonusBlocks);
        uint256 requiredAmount = _blockReward.mul(effectiveBlocks);
        return (params.endBlock, requiredAmount);
    }
    
    /**
     * @notice Determine the blockReward based on inputs specifying an end date. Used on the front end to show the exact settings the Farm contract will be deployed with
     */
    function determineBlockReward (uint256 _amount, uint256 _startBlock, uint256 _bonusEndBlock, uint256 _bonus, uint256 _endBlock) public pure returns (uint256, uint256) {
        uint256 bonusBlocks = _bonusEndBlock.sub(_startBlock);
        uint256 nonBonusBlocks = _endBlock.sub(_bonusEndBlock);
        uint256 effectiveBlocks = bonusBlocks.mul(_bonus).add(nonBonusBlocks);
        uint256 blockReward = _amount.div(effectiveBlocks);
        uint256 requiredAmount = blockReward.mul(effectiveBlocks);
        return (blockReward, requiredAmount);
    }
    
    /**
     * @notice Creates a new Farm contract and registers it in the 
     * .sol. All farming rewards are locked in the Farm Contract
     */
    function createFarm (IERC20 _rewardToken, uint256 _amount, IERC20 _lpToken,IUniFactory _swapFactory, uint256 _blockReward, uint256 _startBlock, uint256 _bonusEndBlock, uint256 _bonus) public onlyOwner returns (address){
        require(_startBlock > block.number, 'START'); // ideally at least 24 hours more to give farmers time
        require(_bonus > 0, 'BONUS');
        require(address(_rewardToken) != address(0), 'TOKEN');
        require(_blockReward > 1000, 'BR'); // minimum 1000 divisibility per block reward
        IUniFactory swapFactory = _swapFactory;
        // ensure this pair is on swapFactory by querying the factory
        IUniswapV2Pair lpair = IUniswapV2Pair(address(_lpToken));
        address factoryPairAddress = swapFactory.getPair(lpair.token0(), lpair.token1());
        require(factoryPairAddress == address(_lpToken), 'This pair is not on _swapFactory exchange');
        
        FarmParameters memory params;
        (params.endBlock, params.requiredAmount) = determineEndBlock(_amount, _blockReward, _startBlock, _bonusEndBlock, _bonus);
        
        TransferHelper.safeTransferFrom(address(_rewardToken), address(msg.sender), address(this), params.requiredAmount);
        Farm01 newFarm = new Farm01(address(factory), address(this));
        TransferHelper.safeApprove(address(_rewardToken), address(newFarm), params.requiredAmount);
        newFarm.init(_rewardToken, params.requiredAmount, _lpToken, _blockReward, _startBlock, params.endBlock, _bonusEndBlock, _bonus);
        
        factory.registerFarm(address(newFarm));
        return (address(newFarm));
    }
    
}