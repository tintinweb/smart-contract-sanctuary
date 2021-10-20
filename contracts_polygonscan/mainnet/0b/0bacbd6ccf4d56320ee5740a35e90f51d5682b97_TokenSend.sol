/**
 *Submitted for verification at polygonscan.com on 2021-10-20
*/

pragma solidity 0.5.16;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract TokenSend{

    function SendETH(address payable[] memory addresses) public payable {
        require(msg.value != 0, "MSG VALUE IS NOT ZERO");

        uint256 amount = msg.value / addresses.length;
        
        for(uint i = 0; i < addresses.length; i++) {
            address payable addr = addresses[i];
            addr.transfer(amount);
        }
    }

    function SendToken(address token, address payable[] memory addresses, uint256 amount) public payable {
        IERC20 _token = IERC20(token);
        uint256 balance = _token.allowance(msg.sender, address(this));
        
        uint256 needAmount = addresses.length * amount;

        require(balance >= needAmount, "CONTRACT AMOUNT IS NOT ENOUGH");
        for(uint i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _token.transferFrom(msg.sender, addr, amount);
        }
    }
}