/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

contract AleToschiSwitchPriceDumper {

    address private owner = msg.sender;

    uint256 public immutable fromBlock;

    uint256 public blockNumber;
    mapping(address => uint256) public pricePerETH;

    address[] private _tokenAddresses;
    address[] private _liquidityPoolAddresses;

    IAMM public amm;

    event PriceDump(address indexed from, address indexed to, uint256 pricePerETH);

    constructor(uint256 _fromBlock, address[] memory tokenAddresses, address[] memory liquidityPoolAddresses, address ammAddress) {
        fromBlock = _fromBlock;
        _tokenAddresses = tokenAddresses;
        _liquidityPoolAddresses = liquidityPoolAddresses;
        amm = IAMM(ammAddress);
    }

    receive() external payable {
        _ensureTime();
    }

    function addresses() external view returns(address[] memory tokenAddresses, address[] memory liquidityPoolAddresses) {
        return (tokenAddresses = _tokenAddresses, liquidityPoolAddresses = _liquidityPoolAddresses);
    }

    function _ensureTime() private view {
        require(blockNumber == 0, "Already dumped BRO");
        require(block.number >= fromBlock, "Too early to dump BRO");
    }

    function dump() external {
        _ensureTime();
        require(msg.sender == owner, "Unauthorized");
        (address ethereumAddress,,) = amm.data();

        address[] memory path = new address[](1);
        path[0] = ethereumAddress;

        SwapData memory data = SwapData({
            enterInETH : false,
            exitInETH : true,
            liquidityPoolAddresses : new address[](1),
            path : path,
            inputToken : address(0),
            amount : 0,
            receiver : address(this)
        });

        for(uint256 i = 0; i < _tokenAddresses.length; i++) {
            uint256 unity = 1 * (10**IERC20(_tokenAddresses[i]).decimals());
            IERC20(_tokenAddresses[i]).approve(address(amm), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            data.inputToken = _tokenAddresses[i];
            data.amount = unity;
            data.liquidityPoolAddresses[0] = _liquidityPoolAddresses[i];
            emit PriceDump(_tokenAddresses[i], ethereumAddress, pricePerETH[_tokenAddresses[i]] = amm.swapLiquidity(data));
        }
        blockNumber = block.number;
        owner.call{value : address(this).balance}("");
    }
}

struct SwapData {
    bool enterInETH;
    bool exitInETH;
    address[] liquidityPoolAddresses;
    address[] path;
    address inputToken;
    uint256 amount;
    address receiver;
}

interface IAMM {
    function data() external view returns(address ethereumAddress, uint256 maxTokensPerLiquidityPool, bool hasUniqueLiquidityPools);
    function swapLiquidity(SwapData calldata data) external payable returns(uint256);
}

interface IERC20 {
    function decimals() external view returns(uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}