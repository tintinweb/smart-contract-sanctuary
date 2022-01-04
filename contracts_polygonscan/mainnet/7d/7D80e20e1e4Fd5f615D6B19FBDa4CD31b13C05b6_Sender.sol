/**
 *Submitted for verification at polygonscan.com on 2022-01-03
*/

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract Sender {
    function SendOutEther(uint256 value, address payable[]  calldata recipients)  external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(value);
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(msg.sender).transfer(balance);
    }

    function SendOutToken(IERC20 token,uint256 value, address[] calldata recipients) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += value;
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], value));
    }

    function SendOutTokenSimple(IERC20 token,uint256 value, address[] calldata recipients) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], value));
    }
}