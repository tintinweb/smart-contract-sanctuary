// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
import "./Ownable.sol";

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IFlashloanReceiver {
    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external;
}

interface ICTokenFlashloan {
    function flashLoan(address receiver, uint amount, bytes calldata params) external;
}

// FlashloanReceiver is a simple flashloan receiver sample code
contract FlashloanExample is IFlashloanReceiver, Ownable {

    address public executor;  // TEMPORARY: allowed executor

    function doFlashloan(address cToken, uint256 borrowAmount) external onlyOwner {

        bytes memory data = "0x";

        // call the flashLoan method
        executor = cToken;
        ICTokenFlashloan(cToken).flashLoan(address(this), borrowAmount, data);
        executor = address(0);
    }

    // this function is called after your contract has received the flash loaned amount
    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
        require(msg.sender == executor);
        address cToken = msg.sender;

        uint currentBalance = IERC20(underlying).balanceOf(address(this));
        require(currentBalance >= amount, "Invalid balance, was the flashLoan successful?");

        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `underlying` funds to payback the `fee` !!
        //


        // transfer fund + fee back to cToken
        require(IERC20(underlying).transfer(cToken, amount + fee), "Transfer fund back failed");
    }

    // KEEP THIS FUNCTION IN CASE THE CONTRACT KEEPS LEFTOVER TOKENS!
    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, balance);
    }

    // KEEP THIS FUNCTION IN CASE THE CONTRACT KEEPS LEFTOVER ETHER!
    function withdrawEther() public onlyOwner {
        address self = address(this); // workaround for a possible solidity bug
        uint256 balance = self.balance;
        msg.sender.transfer(balance);
    }
}