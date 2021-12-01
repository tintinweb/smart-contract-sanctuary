/**
 *Submitted for verification at snowtrace.io on 2021-12-01
*/

// File: contracts/IERC20.sol

//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

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

// File: contracts/IKineOracle.sol

pragma solidity ^0.6.12;
interface IKineOracle {
    function getUnderlyingPrice(address kToken) external view returns (uint);
}

// File: contracts/KineProtocolHelper.sol


pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;



contract KineProtocolHelper{
    function totalStakingValueByKTokens(address[] memory kTokenAddresses, address oracleAddress) external view returns (uint){
        IKineOracle kineOracle = IKineOracle(oracleAddress);
        uint totalStakingValue;

        for(uint i = 0; i < kTokenAddresses.length; i++){
            IERC20 kToken = IERC20(kTokenAddresses[i]);
            uint tmpTotalSupply = kToken.totalSupply();
            uint tmpPrice = kineOracle.getUnderlyingPrice(kTokenAddresses[i]);
            uint tmpValue = tmpPrice * tmpTotalSupply;
            totalStakingValue += tmpValue;
        }
        return totalStakingValue;
    }

    function stakingValueByKToken(address kTokenAddress, address oracleAddress) external view returns (uint){
        IKineOracle kineOracle = IKineOracle(oracleAddress);
        IERC20 kToken = IERC20(kTokenAddress);
        uint tmpTotalSupply = kToken.totalSupply();
        uint tmpPrice = kineOracle.getUnderlyingPrice(kTokenAddress);
        return tmpPrice * tmpTotalSupply;
    }
}