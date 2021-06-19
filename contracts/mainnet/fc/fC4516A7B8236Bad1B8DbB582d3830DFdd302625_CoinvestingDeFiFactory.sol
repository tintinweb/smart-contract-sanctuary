// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./ICoinvestingDeFiFactory.sol";
import "./CoinvestingDeFiPair.sol";

contract CoinvestingDeFiFactory is ICoinvestingDeFiFactory {
    // Public variables
    address[] public override allPairs;
    address public override feeTo;
    address public override feeToSetter;
    
    mapping(address => mapping(address => address)) public override getPair;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    //External functions
    function createPair(
        address tokenA,
        address tokenB
    )
    external
    override
    returns (address pair)
    {
        require(tokenA != tokenB, "FAC: IDT_ADDR");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "FAC: ZERO_ADDR");
        require(getPair[token0][token1] == address(0), "FAC: PAIR_EXISTS");
        bytes memory bytecode = type(CoinvestingDeFiPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ICoinvestingDeFiPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter,
            "FAC: CALLER_AINT_SETTER");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter,
            "FAC: CALLER_AINT_SETTER");
        feeToSetter = _feeToSetter;
    }

    //External functions that are view
    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }
}