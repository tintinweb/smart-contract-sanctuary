// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface UniOracleFactory {
    function update(address tokenA, address tokenB) external;
}

interface Keep3r {
    function isKeeper(address) external view returns (bool);
    function workReceipt(address keeper, uint amount) external;
}

contract Keep3rJob {
    UniOracleFactory constant JOB = UniOracleFactory(0x61da8b0808CEA5281A912Cd85421A6D12261D136);
    Keep3r constant KPR = Keep3r(0x9696Fea1121C938C861b94FcBEe98D971de54B32);
    
    function update(address tokenA, address tokenB) external {
        require(KPR.isKeeper(msg.sender), "Keep3rJob::update: not a valid keeper");
        JOB.update(tokenA, tokenB);
        KPR.workReceipt(msg.sender, 1e18);
    }
}