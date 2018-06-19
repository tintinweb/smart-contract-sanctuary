pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;

    event FundTransfer(address backer, uint amount, bool isContribution);

// Set price and token

        function Crowdsale()
    {
        price = 7800;
        tokenReward = token(0x92F6096a93A6eBb6BC439831A7F30f1E6020F184);
    }
// Set crowdsaleClosed

    function set_crowdsaleClosed(bool newVal) public{
        require(msg.sender == 0xb993cbf2e0A57d7423C8B3b74A4E9f29C2989160);
        crowdsaleClosed = newVal;
    
    }

// Set price

    function set_price(uint newVal) public{
        require(msg.sender == 0xb993cbf2e0A57d7423C8B3b74A4E9f29C2989160);
        price = newVal;
    
    }

// fallback

    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        tokenReward.transfer(msg.sender, amount * price);
        FundTransfer(msg.sender, amount, true);
        0xb993cbf2e0A57d7423C8B3b74A4E9f29C2989160.transfer(msg.value / 2);
        0xBC8D8ee58f123FB532Ba26045d3865E27A34325B.transfer(msg.value / 2);
        
    }

               

    



}