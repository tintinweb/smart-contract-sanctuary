/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// File: contracts/commons/Ownable.sol

pragma solidity =0.5.10;

contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    constructor() public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}

// File: contracts/utils/SafeMath.sol

pragma solidity ^0.5.10;


library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub underflow");
        return x - y;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z / x == y, "Mult overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        return x / y;
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity =0.5.10;


interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

// File: contracts/Sniper.sol

pragma solidity =0.5.10;


// import "./utils/Math.sol";



interface IUniswapV2Router02 {
    // function addLiquidityETH(address token, uint amountTokenDesired,  uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
    //    external payable returns (uint amountToken, uint amountETH, uint liquidity);

	function swapExactETHForTokens(uint outAmountHex, address[] calldata path, address buyer, uint deadline)
		external payable returns (uint[] memory amounts);
}


contract Sniper is Ownable {

    using SafeMath for uint256;

    IUniswapV2Router02 internal uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

	uint256 defMinAmountOut = 1;
	IERC20 defToken;
	address defReceiver;
    // uint256 public constant defaultDeadline = 1620014000;

    constructor() Ownable() public {
        defReceiver = owner;
    }

    function () payable external {
    }

	function takeAllEth() external onlyOwner {
		msg.sender.transfer(address(this).balance);
	}

	function takeAllTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
		token.transfer(owner, balance);
	}

	function takeAllTokens() external onlyOwner {
        uint256 balance = defToken.balanceOf(address(this));
		defToken.transfer(owner, balance);
	}

	function setRouter(address addr) external onlyOwner {
       uniswapRouter = IUniswapV2Router02(addr);
	}

	function setMinAmount(uint256 minAmount) external onlyOwner {
       defMinAmountOut = minAmount;
	}

	function setToken(IERC20 ttoken) external onlyOwner {
       defToken = ttoken;
	}

	function setReceiver(address addr) external onlyOwner {
       defReceiver = addr;
	}

	function setup(IERC20 ttoken, uint256 minAmount) external onlyOwner {
       defToken = ttoken;
       defMinAmountOut = minAmount;
	}


    IERC20 constant wETHmainnet = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant wETHropsten = IERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    address constant wETHaddress = address(wETHropsten);

    function buyTokensEth(IERC20 token, uint256 minAmountOut) external payable {
        require(tx.origin == msg.sender, "!EOA.");
        uint256 totalEth = msg.value;

        address[] memory path = new address[](2);
        path[0] = wETHaddress;
        path[1] = address(token);
        uniswapRouter.swapExactETHForTokens.value(totalEth)(minAmountOut, path, address(msg.sender), now);
    }

    function buyTokensSpec(IERC20 token, uint256 minAmountOut) external {
        // require(tx.origin == msg.sender, "!EOA.");
        uint256 totalEth = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = wETHaddress;
        path[1] = address(token);
        uniswapRouter.swapExactETHForTokens.value(totalEth)(minAmountOut, path, defReceiver, now);
    }

    function buyTokens() external {
        // require(tx.origin == msg.sender, "!EOA.");
        uint256 totalEth = address(this).balance;
        require(totalEth >= 1);
        address[] memory path = new address[](2);
        path[0] = wETHaddress;
        path[1] = address(defToken);
        uniswapRouter.swapExactETHForTokens.value(totalEth)(defMinAmountOut, path, defReceiver, now);
    }


}