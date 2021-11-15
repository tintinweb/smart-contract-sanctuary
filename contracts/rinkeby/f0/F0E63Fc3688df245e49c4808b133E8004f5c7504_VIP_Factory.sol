// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Mandelbrot VIP
 */
contract IERC20 {
    function balanceOf(address account) public view virtual returns (uint256) {}
}

contract IVIP {
    function transfer(address _to, uint256 _value) public returns (bool) {}
}

contract VIP_Factory {     

    address constant ART_BLOCKS_ADDRESS = 0xAAd173dd25AAe3BB176139643155878f214601Bc;
    address constant VIP_PASS_ADDRESS   = 0x4bFf0abF174E84b4cD35a1f0fa8de5c1B82095A2;
    mapping (address => uint256) claimed;
    string public name;
    string public symbol;
    

    constructor() { 
        name = "Mandelbrot VIP Dispenser";
        symbol = "MVD";
    }

    function claim(uint256 vips) public {
        uint256 art_blocks_holdings = IERC20(ART_BLOCKS_ADDRESS).balanceOf(msg.sender);
        require(art_blocks_holdings>vips, "You don't hold enough Art Blocks!");
        require(claimed[msg.sender] + vips < art_blocks_holdings, "You are claiming too many VIPS");
        claimed[msg.sender] = claimed[msg.sender] + vips;
        IVIP(VIP_PASS_ADDRESS).transfer(msg.sender, vips);
    }
}

