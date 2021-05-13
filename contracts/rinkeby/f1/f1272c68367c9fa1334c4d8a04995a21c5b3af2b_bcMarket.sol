/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity =0.6.6;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}
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
    using SafeMath for uint;

    uint oneUsdg = 1000000000;
    uint8  public rate = 100;

    address[] pathUsdg2Bc;
    IUniswapV2Router01 public uniswapRouter;

    constructor(address _usdg, address _bc, address _uniswap)public {
        _setPath(_usdg,_bc,_uniswap);
    }

    function _setPath(address _usdg, address _bc,address _uniswap)private {
        uniswapRouter = IUniswapV2Router01(_uniswap);
        pathUsdg2Bc.push(_usdg);
        pathUsdg2Bc.push(_bc);
    }

    function getUniOutput(uint _input, address _token1, address _token2)public view returns (uint) {
        address[] memory paths = new address[](2);
        paths[0] = _token1;
        paths[1] = _token2;
        uint[] memory amounts = uniswapRouter.getAmountsOut( _input, paths);
        return amounts[1];
    }

    function usdgToBc() external view returns (uint){
        uint[] memory amounts = uniswapRouter.getAmountsOut( oneUsdg, pathUsdg2Bc);
        uint rs =  amounts[1];
        if(rate != 100){
            rs = rs.mul(rate).div(100);
        }
        return rs;
    }

    function changeRates(uint8 _rate)onlyOwner public {
        require(201 > _rate, "_rate big than 200");
        rate = _rate;
    }

}