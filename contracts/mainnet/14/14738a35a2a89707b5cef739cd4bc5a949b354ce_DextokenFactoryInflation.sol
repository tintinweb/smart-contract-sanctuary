// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.5.17;

import "./Math.sol";
import "./SafeMath.sol";
import "./DextokenPoolInflation.sol";


contract DextokenFactoryInflation {
    using SafeMath for uint;

    event PoolCreated(address indexed token0, address indexed pair, address indexed creator, uint);

    address public owner;
    address public feePool;
    address public WETH;

    mapping(address => mapping(address => address)) private _allPools;
    address [] public allPoolsAddress;

    constructor(address token1) public {
        owner = msg.sender;
        feePool = address(0);
        WETH = token1;
    }

    function createPool(address token0, uint Ct, uint Pt) external returns (address pool) {
        require(token0 != address(0), 'createPool: zero address');
        require(feePool != address(0), 'createPool: feePool not set');
        require(_allPools[token0][msg.sender] == address(0), 'createPool: user pool exists');
        bytes memory bytecode = type(DextokenPoolInflation).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, WETH, msg.sender));
        /// precompute the address where a contract will be deployed
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IDextokenPool(pool).initialize(token0, WETH, Ct, Pt);
        _allPools[token0][msg.sender] = pool;
        allPoolsAddress.push(pool);
        emit PoolCreated(token0, pool, msg.sender, allPoolsAddress.length);
        return pool;
    }

    function getFeePool() external view returns (address) {
        return feePool;
    }

    function setFeePool(address _feePool) external {
        require(msg.sender == owner, "setFeePool: Forbidden");
        feePool = _feePool;
    }

    function getAllPools() external view returns (address [] memory) {
        return allPoolsAddress;
    }   
}