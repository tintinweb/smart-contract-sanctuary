/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
}

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract WETHTest {
    IWETH9 public immutable WETH;

    constructor(address _weth) {
        WETH = IWETH9(payable(_weth));
    }
    
    receive() external payable {}
    
    function wrapEverythingUsingDeposit() external {
        uint256 balance = address(this).balance;
        WETH.deposit{value: balance}();
    }
    
    function wrapEverythingBySending() external {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = payable(WETH).call{value: balance}("");
        require(sent, "Could not send");
    }
    
    function balanceInETH() external view returns(uint256) {
        return address(this).balance;
    }
    
    function balanceInWETH() external view returns(uint256) {
        return WETH.balanceOf(address(this));
    }
    
    function withdrawAllETHAndWETH() external {
        uint256 wethBalance = WETH.balanceOf(address(this));
        WETH.withdraw(wethBalance);

        (bool sent, bytes memory data) = payable(address(msg.sender)).call{value: address(this).balance}("");
        require(sent, "Could not send ETH");
    }
}