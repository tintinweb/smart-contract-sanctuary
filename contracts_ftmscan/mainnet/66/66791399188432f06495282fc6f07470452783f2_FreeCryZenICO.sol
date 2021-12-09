/**
 *Submitted for verification at FtmScan.com on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract FreeCryZenICO {

    address public owner;
    address private tokenAddress;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    receive() external payable {
        send();
    }

    fallback() external payable {
        send();
    }

    function send() private {
        require(msg.value > 0, "Send FTM to buy some tokens");
        
        uint tokenAmount =  msg.value * 1000;
        try ERC20(tokenAddress).transfer(msg.sender, tokenAmount) {
        } catch Error(string memory) {
            (bool success, ) = msg.sender.call{ value: msg.value }("");
            require(success, "Failed to process transaction");
        } catch (bytes memory reason) {
            (bool success, ) = msg.sender.call{ value: msg.value }(reason);
            require(success, "Failed to process transaction");
        }
    }

    function returnToken() public {
        require(msg.sender == owner, "Only owner can return token");
        ERC20(tokenAddress).transfer(msg.sender, ERC20(tokenAddress).balanceOf(address(this)));
    }

    function returnFTM() public {
        require(msg.sender == owner, "Only owner can return FTM");
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Failed to process transaction");
    }

}