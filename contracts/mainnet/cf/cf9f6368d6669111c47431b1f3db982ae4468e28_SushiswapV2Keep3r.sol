// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;

interface IKeep3rV1 {
    function isKeeper(address) external returns (bool);
    function worked(address keeper) external;
}

interface ISushiswapV2Factory {
    function allPairsLength() external view returns (uint);
    function allPairs(uint) external view returns (address pair);
}

interface ISushiswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address account) external view returns (uint);
}

interface ISushiswapV2Maker {
    function convert(address token0, address token1) external;
}

contract SushiswapV2Keep3r {
    
    modifier upkeep() {
        require(KP3R.isKeeper(msg.sender), "SushiswapV2Keep3r::isKeeper: keeper is not registered");
        _;
        KP3R.worked(msg.sender);
    }
    
    IKeep3rV1 public constant KP3R = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    ISushiswapV2Factory public constant SV2F = ISushiswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    ISushiswapV2Maker public constant SV2M = ISushiswapV2Maker(0x6684977bBED67e101BB80Fc07fCcfba655c0a64F);
    
    function count() public view returns (uint) {
        uint _count = 0;
        for (uint i = 0; i < SV2F.allPairsLength(); i++) {
            if (haveBalance(SV2F.allPairs(i))) {
                _count++;
            }
        }
        return _count;
    }
    
    function workableAll(uint _count) external view returns (address[] memory) {
        return (workable(_count, 0, SV2F.allPairsLength()));
    }
    
    function workable(uint _count, uint start, uint end) public view returns (address[] memory) {
        address[] memory _workable = new address[](_count);
        uint index = 0;
        for (uint i = start; i < end; i++) {
            if (haveBalance(SV2F.allPairs(i))) {
                _workable[index] = SV2F.allPairs(i);
                index++;
            }
        }
        return _workable;
    }
    
    function haveBalance(address pair) public view returns (bool) {
        return ISushiswapV2Pair(pair).balanceOf(address(SV2M)) > 0;
    }
    
    function batch(ISushiswapV2Pair[] calldata pair) external {
        bool _worked = true;
        for (uint i = 0; i < pair.length; i++) {
            if (haveBalance(address(pair[i]))) {
                (bool success, bytes memory message) = address(SV2M).delegatecall(abi.encodeWithSignature("convert(address,address)", pair[i].token0(), pair[i].token1()));
                require(success, string(abi.encodePacked("SushiswapV2Keep3r::convert: failed [", message, "]")));
            } else {
                _worked = false;
            }
        }
        require(_worked, "SushiswapV2Keep3r::batch: job(s) failed");
    }
    
    function work(ISushiswapV2Pair pair) external {
        require(haveBalance(address(pair)), "SushiswapV2Keep3r::work: invalid pair");
        (bool success, bytes memory message) = address(SV2M).delegatecall(abi.encodeWithSignature("convert(address,address)", pair.token0(), pair.token1()));
        require(success,  string(abi.encodePacked("SushiswapV2Keep3r::convert: failed [", message, "]")));
    }
}