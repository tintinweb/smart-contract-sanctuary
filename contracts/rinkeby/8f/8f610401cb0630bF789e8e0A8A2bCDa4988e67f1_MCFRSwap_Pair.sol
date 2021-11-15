// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

import './interfaces/IERC20.sol';
import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
// import "./interfaces/IMCFRSwap_Pair.sol";

contract MCFRSwap_Pair {
    using SafeMath for uint;

    uint public bid;
    uint public ask;
    uint public fee;
    IERC20 public token0;
    IERC20 public token1;
    address public setter;
    address public owner;
    uint public charge;

    event UpdatedRate(address indexed from,  uint rate);
    event Swap(address indexed from, address indexed tokenA, uint amountIn, address indexed tokenB, uint amountOut, uint handling, uint commission);
    event AddToken(address indexed from, address indexed token, uint amountIn);
    event RemoveToken(address indexed from, address indexed token, uint amountOut);

    modifier onlySetter() {
        require(msg.sender == setter, "Unauthorized person");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized person");
        _;
    }

    modifier noBalance() {
        require(token0.balanceOf(address(this)) <=0, "Balance is not empty");
        require(token1.balanceOf(address(this)) <=0, "Balance is not empty");
        _;
    }

    constructor(address tokenA, address tokenB, uint initBid, uint initAsk, uint commission, uint sercharge) {
        token0 = IERC20(tokenA);
        token1 = IERC20(tokenB);
        setter = msg.sender;
        bid = initBid; // setter buy token0
        ask = initAsk; // setter sell token0
        fee = commission; // Commission Fee for a swap
        charge = sercharge; // Platform fee from Setter
        owner = msg.sender;
    }

    function setBid(uint newBid) external onlySetter {
        require(newBid != bid, 'Same rate. No update is needed');
        require(newBid > 0, 'Zero or negative rate');
        
        bid = newBid;
        emit UpdatedRate(msg.sender, newBid);
    }

    function setAsk(uint newAsk) external onlySetter {
        require(newAsk != ask, 'Same rate. No update is needed');
        require(newAsk > 0, 'Zero or negative rate');
        
        ask = newAsk;
        emit UpdatedRate(msg.sender, newAsk);
    }

    function setSetter(address newSetter) external onlyOwner {
        setter = newSetter;
    }

    function setFee(uint newFee) external onlyOwner {
        fee = newFee;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setCharge(uint newCharge) external onlyOwner {
        charge = newCharge;
    }

    function addTokens(address token, uint amountIn) external onlySetter {
        IERC20 targetToken = IERC20(token);

        // Check token validiity
        require(targetToken == token0 || targetToken == token1, 'Not a valid token');

        // Check sender to have enough tokens and allowance 
        require(targetToken.balanceOf(msg.sender) >= amountIn, 'Not enough balance from sender!');
        require(targetToken.allowance(msg.sender, address(this)) >= amountIn, 'Check the token allowance');

        TransferHelper.safeTransferFrom(address(targetToken), msg.sender, address(this), amountIn);

        emit AddToken(msg.sender, token, amountIn);
    }

    function removeTokens(address token, uint amountOut) external onlySetter {
        IERC20 targetToken = IERC20(token);

        // Check token validiity
        require(targetToken == token0 || targetToken == token1, 'Not a valid token');

        // Check sender to have enough tokens and allowance 
        require(targetToken.balanceOf(address(this)) >= amountOut, 'Not enough balance from pair!');

        TransferHelper.safeTransfer(address(targetToken), msg.sender, amountOut);

        emit RemoveToken(msg.sender, token, amountOut);
    }

    function swapToken(address tokenIn, uint amountIn, address tokenOut) external {
        // Check sender to have enough token
        require(tokenIn != tokenOut, 'Same tokens');

        require(tokenIn == address(token0) || tokenIn == address(token1), 'Not a valid in token');
        require(tokenOut == address(token0) || tokenOut == address(token1), 'Not a valid out token');

        IERC20 _tokenIn = tokenIn == address(token0) ? token0 : token1;
        IERC20 _tokenOut = tokenOut == address(token0) ? token0 : token1;

        require(_tokenIn.balanceOf(msg.sender) >= amountIn, 'Not enough balance from sender');
        
        // Check sender has grant enough allowance to contract 
        uint allowance = _tokenIn.allowance(msg.sender, address(this));
        require(allowance >= amountIn, 'Check the token allowance');

        // Calculate commission, handling charge and amountOut
        // 10000 => 2 decimal places
        // 1000 => 1 decimal placesd
        uint handling = amountIn.mul(fee) / 10000; // Handling fee for swap
        uint commission = amountIn.mul(charge) / 10000; // Platfrom charge from setter
        uint amountOut = amountIn.sub(handling).mul(_tokenIn == token0 ? bid : 1000) / (_tokenIn == token0 ? 1000 : ask); // Actual token received by user
        handling = handling.sub(commission); // Actual handling received by setter

        // Check contract have enough balance
        require(_tokenOut.balanceOf(address(this)) >= amountOut,'Not enough balance from Contract');

        // Get token from 
        TransferHelper.safeTransferFrom(address(_tokenIn), msg.sender, address(this), amountIn);

        TransferHelper.safeTransfer(address(_tokenIn), owner, commission);
        TransferHelper.safeTransfer(address(_tokenIn), setter, handling);
        TransferHelper.safeTransfer(address(_tokenOut), msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, amountIn, tokenOut, amountOut, handling, commission);
    }
    
    // function kill() external onlyOwner noBalance {
    //     selfdestruct(payable(owner));
    // }
}

pragma solidity >=0.6.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.6.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    // function safeTransferETH(address to, uint256 value) internal {
    //     // (bool success, ) = to.call(value: value)(new bytes(0));
    //     (bool success, ) = to.call.value(value)(new bytes(0));
    //     require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    // }
}

