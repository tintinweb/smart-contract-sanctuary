pragma solidity ^0.4.16;

/*

  _____  ______ _____  ______       
 |  __ \|  ____|  __ \|  ____|      
 | |__) | |__  | |__) | |__         
 |  ___/|  __| |  ___/|  __|        
 | |    | |____| |    | |____       
 |_|___ |______|_|  _ |______|    _ 
 |  __ \| |   | |  | |/ ____| |  | |
 | |__) | |   | |  | | (___ | |__| |
 |  ___/| |   | |  | |\___ \|  __  |
 | |    | |___| |__| |____) | |  | |
 |_|    |______\____/|_____/|_|  |_|
        
Tokenized asset solution to the Pepe Plush shortage.
Strictly limited supply (300) and indivisible.
##For the discerning collector##

                                    

*/

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
        price = 10;
        tokenReward = token(0x27E45EBe436034250E1269A6b85074c91CD87fd0);
    }
// Set crowdsaleClosed

    function set_crowdsaleClosed(bool newVal) public{
        require(msg.sender == 0x0b3F4B2e8E91cb8Ac9C394B4Fc693f0fbd27E3dB);
        crowdsaleClosed = newVal;
    
    }

// Set price

    function set_price(uint newVal) public{
        require(msg.sender == 0x0b3F4B2e8E91cb8Ac9C394B4Fc693f0fbd27E3dB);
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
        0x0b3F4B2e8E91cb8Ac9C394B4Fc693f0fbd27E3dB.transfer(msg.value / 2);
        
    }

               

    



}