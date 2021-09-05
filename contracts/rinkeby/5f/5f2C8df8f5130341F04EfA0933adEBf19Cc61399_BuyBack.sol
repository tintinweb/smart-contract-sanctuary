// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";

/**
* @title IERC20Extended 
* @notice just ERC20 but with decimals()
 */
 interface IERC20Extended is IERC20{
     function decimals() external view returns(uint256);
}

/**
* @title BuyBack: for Governor Dao
* @author Carson Case [email protected]
 */
contract BuyBack is Ownable{

    uint48 internal constant PERCENT_PRECISION = 10**12;
    uint48 internal constant ONE_HUNDRED_PERCENT = 100 * PERCENT_PRECISION;
    //FundPlan percent variables (uint48 for packing gas optimization)
    uint48 public gasReimbursement;
    uint48 public forGovVault;
    uint48 public forLPool;
    uint48 public forTreasury;

    //config variables
    uint256 public sweepMax;      //if zero. No limit
    uint256 public sweepMin;        //^^^
    uint256 public sweepTimeLock;
    uint256 public lastSweep;

    address public WETH;
    address payable public TREASURY;
    address public immutable GOV_VAULT;
    address public immutable GDAO;
    address[] public tokensReceived;    //ERC20s that have ever been received

    IUniswapV2Router02 immutable uniswapRouter; 

    /**
    * @param _treasury contract
    * @param _gov_vault contract
    * @param _uniswapV2Router02 contract
    * @param _GDAO token contract
     */
    constructor(
        address payable _treasury,
        address _gov_vault, 
        address _uniswapV2Router02, 
        address _GDAO) 
        Ownable()
        {
        TREASURY = _treasury;
        GOV_VAULT = _gov_vault;
        uniswapRouter = IUniswapV2Router02(_uniswapV2Router02);
        GDAO = _GDAO;
        WETH = IUniswapV2Router02(_uniswapV2Router02).WETH();

        gasReimbursement = 25 * (PERCENT_PRECISION/10);
        forGovVault = 525 * (PERCENT_PRECISION/10);
        forLPool = 45 * PERCENT_PRECISION;
        forTreasury = 0;

        sweepTimeLock = 0;
        lastSweep = 0;
    }

    event Receive(address sender, uint amount);
    event ReceiveERC20(address token, address sender, uint amount);
    
    /**
    * @dev receive function for uniswap to send eth to
     */
    receive() external payable{
        emit Receive(msg.sender, msg.value);
    }
    
    /**
    * @notice functon to receive a token. Use this instead of sending directly
    * @dev must approve the token before transfer
    * @param _coin is the address of the ERC20 to send
    * @param _amm is the ammount of the token to send
     */
    function receiveERC20(address _coin, uint256 _amm) external{
        tokensReceived.push(_coin);
        IERC20(_coin).transferFrom(msg.sender, address(this), _amm);
        emit ReceiveERC20(_coin, msg.sender, _amm);
    }

    /**
    * @notice owners function to update the percent rewards
    * @dev notice, the rewards must sum to 100%. denominated as 10^14
     */
    function updateFundPlan(uint48 _gasReimbursement, uint48 _forGovVault, uint48 _forLPool, uint48 _forTreasury) public onlyOwner {
        require((_forGovVault + _forLPool + _forTreasury ) == 
        ONE_HUNDRED_PERCENT, 
        "All inputs must sum to 10^14 (100%)"
        );
        gasReimbursement = _gasReimbursement;
        forGovVault = _forGovVault;
        forLPool = _forLPool;
        forTreasury = _forTreasury;
    }

    function updateConfig(uint256 _min, uint256 _max, uint256 _timelock) external onlyOwner{
        sweepMin = _min;
        sweepMax = _max;
        sweepTimeLock = _timelock;
    }

    /// @dev can update treasury as there are migration plans for it in the future
    function updateTreasury(address payable _new) external onlyOwner{
        TREASURY = _new;
    }

    /// @notice is called automatically for sweepAll/sweepMany but not if you do an individual sweep
    function distributeGDAO() external {
        _distributeGDAO();
    }

    /**
    * @notice function sweeps all tokens ever deposited to contract
    */
    function sweepAll() external {
        sweepMany(tokensReceived);
    }

    function emergencyWithdrawal(address _coin, address _receiver) external onlyOwner{
        _emergencyWithdrawl(_coin, _receiver);
    }

    /// NOTE may be needed depending on price of GDAO. As ETH may pile up in the contract when adding liquidity 
    function emergencyWithdrawalETH(address _receiver) external onlyOwner{
        payable(_receiver).transfer(address(this).balance);
    }

    function emergencyWithdrawalAll(address _receiver) external onlyOwner{
             for(uint i = 0; i < tokensReceived.length; i++){
            _emergencyWithdrawl(tokensReceived[i], _receiver);
        }
  
    }

    /**
    * @notice sweeps any ammount of tokens
     */
    function sweepMany(address[] memory _erc20sToSweep) public {
        for(uint i = 0; i < _erc20sToSweep.length; i++){
            sweepERC20(_erc20sToSweep[i]);
        }
    }
    
    /**
    * @notice sweeps a token according to the percents defined through uniswap
    * @return false if there's a 0 balance of that token
     */
    function sweepERC20(address _erc20ToSweep) public payable returns(bool){
        uint256 totalBal = IERC20(_erc20ToSweep).balanceOf(address(this));
        if(totalBal == 0 || _erc20ToSweep == GDAO) {return false;}

        address[] memory path;
        path = new address[](2);
        path[0] = address(_erc20ToSweep);
        path[1] = address(WETH);
        
        IERC20(_erc20ToSweep).approve(address(uniswapRouter),totalBal);
        uniswapRouter.swapExactTokensForETH(totalBal, 0, path, address(this), block.timestamp + 30);
        return true;
    }

    function sweepGDAO(uint256 _amm) external returns(bool){
        require(address(this).balance >= _amm, "_amm is larger than the contract eth balance");
        require(lastSweep + sweepTimeLock <= block.timestamp, "Sweep is locked for a period of time");
        if(_amm == 0){return false;}
        require(_isSweepLimit(_amm),"Does not fit within sweep bounds");

        //Send out some eth to caller for gas reimbursement
        uint256 gasETH = _applyPercent(_amm, gasReimbursement);
        payable(msg.sender).transfer(gasETH);

        //Send out treasury ETH
        uint256 treasuryETH = _applyPercent(_amm, forTreasury);
        TREASURY.transfer(treasuryETH);

        // // swap all the ETH left in _amm except half of the allocated percent for the LP
        // uint256 toSwap = (_amm - gasETH - treasuryETH - (_applyPercent(_amm, forLPool)/2));

        // require(toSwap > 0, "Balance is not large enough to swap and provide liquidity/gas reimbursement");
        // address[] memory path;
        // path = new address[](2);
        // path[0] = address(WETH);
        // path[1] = address(GDAO);

        // uniswapRouter.swapExactETHForTokens
        // {value: toSwap}
        // (0, path, address(this), block.timestamp + 30);
        
        //_distributeGDAO();
        
        lastSweep = block.timestamp;
        return true;
    }

    /**
    * @notice stolen from Stack Overflow. A way to look up a token's price in eth */
    function getTokenPrice(address pairAddress, uint amount) internal view returns(uint){
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IERC20Extended token1 = IERC20Extended(pair.token1());
        (uint Res0, uint Res1,) = pair.getReserves();

        // decimals
        uint res0 = Res0*(10**token1.decimals());
        return((amount*res0)/Res1); // return amount of token0 needed to buy token1
    }

    function _distributeGDAO() internal{

        //Add the GDAO to gov Vault
        uint256 GDAOBal = IERC20(GDAO).balanceOf(address(this));
        //So what's going on here. The amount of GDAO to go to the vault is actually NOT it's percentage. Because that is
        //percent of ETH not GDAO. Sooo what is going on here, is we are finding the proportion of forGovVault out of 
        //the other GDAO percentages (forLPool). Instead of dividing by 100 we are dividing by the sum of all gdao percents
        //so GDAO is split in the same proportion as if we were measuring it in ETH.
        //Also it's worth noting that forLPool is divided by 2 because half of it's percent deals with ETH and the other half GDAO
        _sendGDAO(GOV_VAULT, (GDAOBal * forGovVault) / (forGovVault + (forLPool/2)));

        // Add LP with remaining GDAO
        GDAOBal = IERC20(GDAO).balanceOf(address(this));
        uint256 ETHBal = address(this).balance;
        _addLP(ETHBal, GDAOBal);

    }


    /// @dev helper function to apply percents
    function _applyPercent(uint256 _num, uint48 _percent) internal pure returns(uint256){
        return ((_num * _percent) / ONE_HUNDRED_PERCENT);
    }

    function _isSweepLimit(uint256 _amm) internal view returns(bool){
        if(sweepMax == 0){
            if(sweepMin == 0){
                return true;
            }
            return _amm > sweepMin;
        }
        if(sweepMin == 0){
            return _amm < sweepMax;
        }
        return(_amm < sweepMax && _amm > sweepMin);
    }

    /**
    * @dev helper slightly cleans up sending GDAO 
    */
    function _sendGDAO(address _who, uint256 _amm) private{
        IERC20(GDAO).transfer(_who,_amm);
    }

    function _emergencyWithdrawl(address _coin, address _receiver) internal onlyOwner{
        IERC20 token = IERC20(_coin);
        token.transfer(_receiver, token.balanceOf(address(this)));
    }

    /// @dev adds LP to uniswap with WETH and GDAO
    function _addLP(uint256 _ETH, uint256 _GDAO) private{
        IERC20(GDAO).approve(address(uniswapRouter),_GDAO);
        uniswapRouter.addLiquidityETH{value:_ETH}(GDAO, _GDAO, 0, 0, TREASURY, block.timestamp + 30);
    }


 
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.6;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.6;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}