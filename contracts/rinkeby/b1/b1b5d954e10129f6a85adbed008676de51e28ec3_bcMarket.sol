/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity =0.6.6;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract bcMarket is Ownable{
    uint  public price = 1000000000000000000;

    uint oneUsdg = 1000000000;
    ERC20 public bc;
    ERC20 public usdg;

    address[] pathUsdg2Bc;
    IUniswapV2Router01 public uniswapRouter;

    constructor(address _usdg, address _bc, address _uniswap)public {
        _setPath(_usdg,_bc,_uniswap);
    }

    function _setPath(address _usdg, address _bc,address _uniswap)private {
        uniswapRouter = IUniswapV2Router01(_uniswap);
        usdg = ERC20(_usdg);
        bc = ERC20(_bc);
        pathUsdg2Bc.push(_usdg);
        pathUsdg2Bc.push(_bc);
    }

    //1eth可换成的usdt数量
    function getUniPrice()public view returns (uint balance) {
        uint[] memory amounts = uniswapRouter.getAmountsOut( oneUsdg, pathUsdg2Bc);
        return amounts[1];
    }

    function usdgToBc() external view returns (uint){
        return getUniPrice();
    }
    function changePrice(uint _price)onlyOwner public {
        price = _price;
    }

}