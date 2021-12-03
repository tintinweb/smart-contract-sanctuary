/**
 *Submitted for verification at polygonscan.com on 2021-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTContract {
    function mint(address to) external;
}

interface IWETH {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Presale {
    INFTContract private NFTContract;
    IWETH private WETH;
    address private _wallet;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(address contractAddress, address wethAddress, address wallet) {
        NFTContract = INFTContract(contractAddress);
        WETH = IWETH(wethAddress);
        _wallet = wallet;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function mint() public payable virtual {
        WETH.transferFrom(msg.sender, _wallet, 0.02 ether);
        NFTContract.mint(msg.sender);
    }
}