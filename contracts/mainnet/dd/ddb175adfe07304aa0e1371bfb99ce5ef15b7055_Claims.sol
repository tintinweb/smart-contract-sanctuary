/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function burnFrom(address account_, uint256 amount_) external;
}

contract Claims {
    address public constant CERBERUS = 0x8a14897eA5F668f36671678593fAe44Ae23B39FB;
    address public constant owner = 0xdB00139222c99e9098DEf2ceBCD94bDCDa8E7625;
    uint public supplyRemaining = 0;

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function claimAmount(address claimer) public view returns (uint) {
        uint tokenBalance = IERC20(CERBERUS).balanceOf(claimer);
        require(supplyRemaining > 0, "supplyRemaining not set");
        require(tokenBalance > 0, "No 3dog");
        require(address(this).balance > 0, "eth not received");
        uint ethAmount = address(this).balance * tokenBalance / supplyRemaining;
        return ethAmount;
    }

    function claim() external {
        uint tokenBalance = IERC20(CERBERUS).balanceOf(msg.sender);
        uint ethAmount = claimAmount(msg.sender);
        // Subtract from denominator
        supplyRemaining -= tokenBalance;
        // Burn the 3dog
        IERC20(CERBERUS).burnFrom(msg.sender, tokenBalance);
        // Send the eth
        (bool sent, bytes memory data) = msg.sender.call{value: ethAmount}("");
        require(sent, "Failed to send Ether");
    }

    function setSupplyRemaining(uint _supplyRemaining) external onlyOwner {
        supplyRemaining = _supplyRemaining;
    }

    function retrieveTokens(address token) external onlyOwner {
        if(token == address(0x0)) {
            uint ethAmount = address(this).balance;
            (bool sent, bytes memory data) = owner.call{value: ethAmount}("");
            require(sent, "Failed to send Ether");
        } else {
            uint tokenBalance = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(owner, tokenBalance);
        }
    }

}