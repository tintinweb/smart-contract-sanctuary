pragma solidity 0.7.6;

import './interfaces/IPolyDexPair.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IERC20.sol';
contract PolydexFeeRemover {
    address public receiver;
    address public governance;

    event RemoveLiquidity(address indexed pair, uint token0, uint token1);


    constructor() {
        governance = msg.sender;
    }


    function setReceiver(address _receiver) external {
        require(msg.sender == governance, 'PolydexFeeRemover: FORBIDDEN');
        receiver = _receiver;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, 'PolydexFeeRemover: FORBIDDEN');
        governance = _governance;
    }

    function transfer(address _token, uint256 _value) external {
        require(msg.sender == governance, 'PolydexFeeRemover: FORBIDDEN');
        require(receiver != address(0), 'PolydexFeeRemover: Invalid Receiver address');
        TransferHelper.safeTransfer(_token, receiver, _value);
    }

    function transferAllTokens(address[] calldata _tokens) external {
        require(msg.sender == governance, 'PolydexFeeRemover: FORBIDDEN');
        require(receiver != address(0), 'PolydexFeeRemover: Invalid Receiver address');

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 _balance = IERC20(_tokens[i]).balanceOf(address(this));
            TransferHelper.safeTransfer(_tokens[i], receiver, _balance);
        }
    }

    function remove(address[] calldata pairs) external {
        address _receiver = receiver;
        // save gas
        require(_receiver != address(0), 'PolydexFeeRemover: Invalid Receiver address');
        for (uint i = 0; i < pairs.length; i++) {
            IPolyDexPair pair = IPolyDexPair(pairs[i]);
            uint liquidity = pair.balanceOf(address(this));
            if (liquidity > 0) {
                pair.transfer(address(pair), liquidity);
                (uint amount0, uint amount1) = pair.burn(_receiver);
                emit RemoveLiquidity(address(pair), amount0, amount1);
            }
        }
    }
}

pragma solidity >=0.5.16;

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

pragma solidity >=0.5.16;
interface IPolyDexPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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


    event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
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
    function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);
    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);
    function getSwapFee() external view returns (uint32);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, uint32) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.16;

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