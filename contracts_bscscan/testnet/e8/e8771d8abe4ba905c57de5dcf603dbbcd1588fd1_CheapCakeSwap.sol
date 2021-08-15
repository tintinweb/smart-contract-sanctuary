/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol"

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20
{
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

interface IPancakePair
{
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

interface IWETH
{
    function withdraw(uint) external;
}

contract CheapCakeSwap
{
    address public immutable owner;
    
    //address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // real BSC
    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // testnet
    
    constructor() public
    {
        owner = msg.sender;
    }
    
    function cheapCakeSwapTokenZeroToOne(
        address liquidityPair, address token0,
        uint256 tokenZeroAmountIn,
        uint256 tokenZeroAmountWithFee,
        uint256 tokenOneAmountOutMin,
        address receiver) external
    {
        //unchecked
        {
            (uint reserve0, uint reserve1, ) = IPancakePair(liquidityPair).getReserves();
            uint possibleOut = (tokenZeroAmountWithFee * reserve1) / (reserve0 + tokenZeroAmountWithFee);
            require(possibleOut >= tokenOneAmountOutMin, 'INSUFFICIENT_OUTPUT');
            IERC20(token0).transferFrom(msg.sender, liquidityPair, tokenZeroAmountIn);
            IPancakePair(liquidityPair).swap(0, possibleOut, receiver, new bytes(0));
        }
    }
    
    function cheapCakeSwapTokenZeroToOneAsBNB(
        address liquidityPair, address token0,
        uint256 tokenZeroAmountIn,
        uint256 tokenZeroAmountWithFee,
        uint256 tokenOneAmountOutMin,
        address receiver) external
    {
        //unchecked
        {
            (uint reserve0, uint reserve1, ) = IPancakePair(liquidityPair).getReserves();
            uint possibleOut = (tokenZeroAmountWithFee * reserve1) / (reserve0 + tokenZeroAmountWithFee);
            require(possibleOut >= tokenOneAmountOutMin, 'INSUFFICIENT_OUTPUT');
            IERC20(token0).transferFrom(msg.sender, liquidityPair, tokenZeroAmountIn);
            IPancakePair(liquidityPair).swap(0, possibleOut, address(this), new bytes(0));
            IWETH(WBNB).withdraw(possibleOut);
            payable(receiver).send(possibleOut);
        }
    }
    
    function cheapCakeSwapTokenOneToZero(
        address liquidityPair, address token1,
        uint256 tokenOneAmountIn,
        uint256 tokenOneAmountInWithFee,
        uint256 tokenZeroAmountOutMin,
        address receiver) external
    {
        //unchecked
        {
            (uint reserve0, uint reserve1, ) = IPancakePair(liquidityPair).getReserves();
            uint possibleOut = (tokenOneAmountInWithFee * reserve0) / (reserve1 + tokenOneAmountInWithFee);
            require(possibleOut >= tokenZeroAmountOutMin, 'INSUFFICIENT_OUTPUT');
            IERC20(token1).transferFrom(msg.sender, liquidityPair, tokenOneAmountIn);
            IPancakePair(liquidityPair).swap(possibleOut, 0, receiver, new bytes(0));
        }
    } 
    
    receive() external payable {}
    
    function killme() external
    {
        require(msg.sender == owner, "not owner");
        selfdestruct(payable(owner));
    }
}