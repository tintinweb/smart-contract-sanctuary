/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity =0.6.6;

/**
 * Math operations with safety checks
 */
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

interface UpgradedPriceAble {
    function getAmountsOutToken(uint value, uint8 rate) external view returns (uint balance);
    function getAmountsOutEth(uint value, uint8 rate) external view returns (uint balance);
}


interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external;
    //    function approve(address spender, uint256 value) public;
    //    function totalSupply() public view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
    //    event Transfer(address indexed from, address indexed to, uint256 value);
    //    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UsdgMarket is Ownable{
    using SafeMath for uint;

    uint decimalGap = 1000000000;
    //百分比
    uint  public buyTokenRate = 100;
    uint  public saleTokenRate = 100;

    ERC20 public usdg;

    event BuyToken(address indexed from,uint inValue, uint outValue);
    event SaleToken(address indexed from,uint inValue, uint outValue);
    event GovWithdrawEth(address indexed to, uint256 value);
    event GovWithdrawToken(address indexed to, uint256 value);

    constructor(address _usdg)public {
        usdg = ERC20(_usdg);
    }

    function buyToken()payable  public {
        require(msg.value > 0, "!value");
        uint amount = getAmountsOutToken(msg.value);
        uint balanced = usdg.balanceOf(address(this));
        require(balanced >= amount, "!contract balanced");
        usdg.transfer(msg.sender, amount);
        BuyToken(msg.sender,msg.value, amount);
    }

    function saleToken(uint256 _value) public {
        require(_value > 0, "!value");
        uint amount = getAmountsOutEth(_value);
        msg.sender.transfer(amount);
        uint allowed = usdg.allowance(msg.sender,address(this));
        uint balanced = usdg.balanceOf(msg.sender);
        require(allowed >= _value, "!allowed");
        require(balanced >= _value, "!balanced");
        usdg.transferFrom( msg.sender,address(this), _value);
        SaleToken(msg.sender,_value, amount);
    }

    function getAmountsOutEth(uint _value) public view returns (uint balance) {
        return _value.mul(decimalGap).mul(saleTokenRate).div(100);
    }

    function getAmountsOutToken(uint _value) public view returns (uint balance) {
        return _value.mul(buyTokenRate).div(100).div(decimalGap);
    }

    function govWithdrawToken(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");

        usdg.transfer( msg.sender, _amount);
        emit GovWithdrawToken(msg.sender, _amount);
    }

    function govWithdrawEth(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        msg.sender.transfer(_amount);
        emit GovWithdrawEth(msg.sender, _amount);
    }

    function changeRates(uint _buyTokenRate, uint _saleTokenRate)onlyOwner public {
        buyTokenRate = _buyTokenRate;
        saleTokenRate = _saleTokenRate;
    }

fallback() external payable {}
}