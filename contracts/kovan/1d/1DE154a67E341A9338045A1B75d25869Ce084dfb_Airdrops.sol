/**
* Submitted for verification at blockscout.com on 2018-10-22 15:11:03.814491Z
*/
pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract Airdrops {
    
    address public mcnToken = 0x27135d12442DE6B4eA5FD59B5fc59ff56aB81f79;
    address public usdcToken = 0x2F375e94FC336Cdec2Dc0cCB5277FE59CBf1cAe5;
    
    
    function disperseEther(address[] recipients, uint256[] values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            msg.sender.transfer(balance);
    }

    function disperseMCNToken(address[] recipients, uint256[] values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(IERC20(mcnToken).transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipients.length; i++)
            require(IERC20(mcnToken).transfer(recipients[i], values[i]));
    }
    
     function disperseUSDCToken(address[] recipients, uint256[] values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(IERC20(usdcToken).transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipients.length; i++)
            require(IERC20(usdcToken).transfer(recipients[i], values[i]));
    }

    function disperseTokenSimple(IERC20 token, address[] recipients, uint256[] values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }
}

