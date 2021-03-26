// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";

contract Test {
    IERC20 private _token;
    event DoneStuff(address from);

    constructor(IERC20 tokenaddress){ // 0xd086d6e1a5b73b2138bc86437e94105ef36e8aa5
        _token = tokenaddress;
    }

    function receveToken() public {
        _token.approve(msg.sender, 100000);
        _token.transferFrom(msg.sender, address(this), 100000);
        emit DoneStuff(msg.sender);
    }
}

// contract Caccamo2 is ERC20 {
    
//     constructor() ERC20("caccamo", "ccm" ) {
//         _mint(msg.sender, 100000 * (10 ** uint256(18)));
//     } 
// }