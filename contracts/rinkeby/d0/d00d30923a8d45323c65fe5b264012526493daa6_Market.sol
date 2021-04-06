/**
 *Submitted for verification at Etherscan.io on 2021-04-05
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


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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

contract Market is Ownable{
    using SafeMath for uint;

    uint8  public buyTokenRate = 0;
    uint8  public saleTokenRate = 0;


    IUniswapV2Router01 public uniswapRouter;
    address private usdg;
    address private usdt;
    address[] pathEth2Usdg;
    address[] pathUsdg2Eth;

    address public upgradedAddress;
    bool public upgraded = false;

    event BuyToken(address indexed from,uint inValue, uint outValue);
    event SaleToken(address indexed from,uint inValue, uint outValue);
    event GovWithdrawEth(address indexed to, uint256 value);
    event GovWithdrawToken(address indexed to, uint256 value);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'Market: EXPIRED');
        _;
    }

    constructor(address _usdg, address _usdt, address _uniswap)public {
        _setPath(_usdg,_usdt,_uniswap);
    }


    function _setPath(address _usdg, address _usdt,address _uniswap)private {
        uniswapRouter = IUniswapV2Router01(_uniswap);
        address _weth = uniswapRouter.WETH();
        usdg = _usdg;
        pathEth2Usdg.push(_weth);
        pathEth2Usdg.push(_usdt);
        pathUsdg2Eth.push(_usdt);
        pathUsdg2Eth.push(_weth);
    }
    // 根据ETH算出能换多少token
    function _getAmountsOutToken(uint value, uint8 rate) private view returns (uint balance) {
        uint[] memory amounts = uniswapRouter.getAmountsOut( value, pathEth2Usdg);
        uint rs = amounts[1];
        if(rate > 0){
            rs = rs.mul(100+rate).div(100);
        }
        return rs;

    }

    // 根据token算出能换多少ETH
    function _getAmountsOutEth(uint value, uint8 rate) private view returns (uint balance) {
        if(rate > 0){
            value = value.mul(100-rate).div(100);
        }
        uint[] memory amounts = uniswapRouter.getAmountsOut( value, pathUsdg2Eth);
        return amounts[1];
    }

    // 根据ETH算出能换多少token
    function getAmountsOutToken(uint _value) public view returns (uint balance) {
        uint amount;
        if (upgraded) {
            amount = UpgradedPriceAble(upgradedAddress).getAmountsOutToken(_value,buyTokenRate);
        } else {
            amount = _getAmountsOutToken(_value,buyTokenRate);
        }
        return amount;
    }

    // 根据token算出能换多少ETH
    function getAmountsOutEth(uint _value) public view returns (uint balance) {
        uint amount;
        if (upgraded) {
            amount = UpgradedPriceAble(upgradedAddress).getAmountsOutToken(_value,saleTokenRate);
        } else {
            amount = _getAmountsOutEth(_value,saleTokenRate);
        }
        return amount;
    }

    function buyTokenSafe(uint amountOutMin,  uint deadline)payable ensure(deadline) public {
        require(msg.value > 0, "!value");
        uint amount = getAmountsOutToken(msg.value);
        require(amount >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransfer(usdg, msg.sender, amount);

        BuyToken(msg.sender,msg.value, amount);
    }

    function saleTokenSafe(uint256 _value,uint amountOutMin,  uint deadline) ensure(deadline) public {
        require(_value > 0, "!value");
        uint amount = getAmountsOutEth(_value);
        require(amount >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        msg.sender.transfer(amount);

        SaleToken(msg.sender,_value, amount);
    }

    function buyToken()payable  public {
        require(msg.value > 0, "!value");
        uint amount = getAmountsOutToken(msg.value);
        TransferHelper.safeTransfer(usdg, msg.sender, amount);
        BuyToken(msg.sender,msg.value, amount);
    }

    function saleToken(uint256 _value) public {
        require(_value > 0, "!value");
        uint amount = getAmountsOutEth(_value);
        msg.sender.transfer(amount);
        SaleToken(msg.sender,_value, amount);
    }

    function govWithdrawToken(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        TransferHelper.safeTransfer(usdg, msg.sender, _amount);
        emit GovWithdrawToken(msg.sender, _amount);
    }

    function govWithdrawEth(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        msg.sender.transfer(_amount);
        emit GovWithdrawEth(msg.sender, _amount);
    }



    function changeRates(uint8 _buyTokenRate, uint8 _saleTokenRate)onlyOwner public {
        require(9 > buyTokenRate, "_buyTokenRate big than 8");
        require(9 > _saleTokenRate, "_saleTokenRate big than 8");
        buyTokenRate = _buyTokenRate;
        saleTokenRate = _saleTokenRate;
    }

    fallback() external payable {}
}