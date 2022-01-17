/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

abstract contract UniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function allPairsLength() external view virtual returns (uint256);
}

contract Query {
    function getReservesByPairs(IUniswapV2Pair[] calldata _pairs)
        external
        view
        returns (uint256[3][] memory)
    {
        uint256[3][] memory result = new uint256[3][](_pairs.length);
        for (uint256 i = 0; i < _pairs.length; i++) {
            (result[i][0], result[i][1], result[i][2]) = _pairs[i]
                .getReserves();
        }
        return result;
    }

    function getPairsByIndexRange(
        UniswapV2Factory _uniswapFactory,
        uint256 _start,
        uint256 _stop
    ) external view returns (Pair[] memory) {
        uint256 _allPairsLength = _uniswapFactory.allPairsLength();
        if (_stop > _allPairsLength) {
            _stop = _allPairsLength;
        }
        require(_stop >= _start, "start cannot be higher than stop");
        uint256 _qty = _stop - _start;
        Pair[] memory result = new Pair[](_qty);
        for (uint256 i = 0; i < _qty; i++) {
            IUniswapV2Pair _uniswapPair = IUniswapV2Pair(
                _uniswapFactory.allPairs(_start + i)
            );
            uint256[3] memory reserves = [uint256(0), 0, 0];
            (reserves[0], reserves[1], reserves[2]) = _uniswapPair
                .getReserves();
            result[i] = Pair(
                _uniswapFactory.allPairs(_start + i),
                _uniswapPair.token0(),
                _uniswapPair.token1(),
                IERC20(_uniswapPair.token0()).name(),
                IERC20(_uniswapPair.token1()).name(),
                reserves
            );
        }
        return result;
    }
}

struct Pair {
    address pairAddress;
    address token0;
    address token1;
    string name0;
    string name1;
    uint256[3] reserves;
}