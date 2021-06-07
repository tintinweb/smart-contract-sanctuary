/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity 0.5.6;


interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract Wallet {
    address internal token = 0xbD62253c8033F3907C0800780662EaB7378a4B96;
    address internal hotWallet = 0xa3601967B0c3180b7C2631638dea69eafA956475;

    constructor() public {
        // send all tokens from this contract to hotwallet
        IERC20(token).transfer(
            hotWallet,
            IERC20(token).balanceOf(address(this))
        );

    }
}

contract Fabric {
    function createContract(uint256 salt) public {
        // get wallet init_code
        bytes memory bytecode = type(Wallet).creationCode;
        assembly {
            let codeSize := mload(bytecode) // get size of init_bytecode
            let newAddr := create2(
            0, // 0 wei
            add(bytecode, 32), // the bytecode itself starts at the second slot. The first slot contains array length
            codeSize, // size of init_code
            salt // salt from function arguments
            )
        }
    }
}