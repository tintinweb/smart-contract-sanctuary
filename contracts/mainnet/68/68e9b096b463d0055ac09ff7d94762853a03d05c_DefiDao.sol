// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
 contract DefiDao is ERC20 {
    using SafeMath for uint256;
    using Address for address;
    address private _owner;  
    address payable private _auctionContract; //拍卖主合约的地址

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (string memory name, string memory symbol,uint8 decimals, uint256 totalSupply) ERC20(name,symbol,decimals) public {
        _mint(_msgSender(),totalSupply);
    } 
}