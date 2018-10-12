/*  

$$$$$$$\                                 $$\$$\   $$\                       $$$$$$\                                
$$  __$$\                                $$ $$$\  $$ |                     $$  __$$\                               
$$ |  $$ |$$$$$$\ $$$$$$\ $$$$$$$\  $$$$$$$ $$$$\ $$ |$$$$$$\ $$\  $$\  $$\$$ /  \__|$$$$$$$\$$$$$$\ $$$$$$\$$$$\  
$$$$$$$\ $$  __$$\\____$$\$$  __$$\$$  __$$ $$ $$\$$ $$  __$$\$$ | $$ | $$ \$$$$$$\ $$  _____\____$$\$$  _$$  _$$\ 
$$  __$$\$$ |  \__$$$$$$$ $$ |  $$ $$ /  $$ $$ \$$$$ $$$$$$$$ $$ | $$ | $$ |\____$$\$$ /     $$$$$$$ $$ / $$ / $$ |
$$ |  $$ $$ |    $$  __$$ $$ |  $$ $$ |  $$ $$ |\$$$ $$   ____$$ | $$ | $$ $$\   $$ $$ |    $$  __$$ $$ | $$ | $$ |
$$$$$$$  $$ |    \$$$$$$$ $$ |  $$ \$$$$$$$ $$ | \$$ \$$$$$$$\\$$$$$\$$$$  \$$$$$$  \$$$$$$$\$$$$$$$ $$ | $$ | $$ |
\_______/\__|     \_______\__|  \__|\_______\__|  \__|\_______|\_____\____/ \______/ \_______\_______\__| \__| \__|

           __________                                 
         .&#39;----------`.                              
         | .--------. |                             
         | |$$$$$$$$| |       __________              
         | |$$$$$$$$| |      /__________\             
.--------| `--------&#39; |------|    --=-- |-------------.
|        `----,-.-----&#39;      |o ======  |             | 
|       ______|_|_______     |__________|             | 
|      /  %%%%%%%%%%%%  \                             | 
|     /  %%%%%%%%%%%%%%  \                            | 
|     ^^^^^^^^^^^^^^^^^^^^                            | 
+-----------------------------------------------------+
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 

You&#39;re always on the ground floor to somewhere...

* No divs. No refs. Only scams
* Scam price only goes up 
* No guarantee there will be any ETH left when you sell
* 30-minute time out between buying and selling 
* Contract has a built-in equal opportunity ETH drain
* 5% stupid tax 
* The whole contract can be exit scammed in 48 hours

*/

pragma solidity ^0.4.25;

    contract BrandNewScam {

    using ScamMath for uint256;
    
    address public scammerInChief;
    uint256 public greaterFools;
    uint256 public availableBalance;
    uint256 public countdownToExitScam;
    uint256 public scamSupply;
    uint256 public scamPrice = 69696969696969;
    uint256 public stupidTaxRate = 5;
    uint256 public timeOut = 30 minutes;
    mapping (address => uint256) public userTime;
    mapping (address => uint256) public userScams;
    mapping (address => uint256) public userBalance;
    
    constructor() public payable{
        scammerInChief = msg.sender;
        buyScams();
        countdownToExitScam = now + 48 hours;
    }
    
    modifier relax { 
        require (msg.sender == tx.origin); 
        _; 
    }

    modifier wait { 
        require (now >= userTime[msg.sender] + timeOut);
        _; 
    }
    
    function () public payable relax {
        buyScams();
    }

    function buyScams() public payable relax {
        uint256 stupidTax = msg.value.mul(stupidTaxRate).div(100);
        uint256 ethRemaining = msg.value.sub(stupidTax);
        require(ethRemaining >= scamPrice);
        uint256 scamsPurchased = ethRemaining.div(scamPrice);
        userTime[msg.sender] = now;
        userScams[msg.sender] += scamsPurchased;
        scamSupply += scamsPurchased;
        availableBalance += ethRemaining;
        uint256 newScamPrice = availableBalance.div(scamSupply).mul(2);
        if (newScamPrice > scamPrice) {
            scamPrice = newScamPrice;
        }
        scammerInChief.transfer(stupidTax);
        greaterFools++;
    }
    
    function sellScams(uint256 _scams) public relax wait {
        require (userScams[msg.sender] > 0 && userScams[msg.sender] >= _scams);
        uint256 scamProfit = _scams.mul(scamPrice);
        require (scamProfit <= availableBalance);
        scamSupply = scamSupply.sub(_scams);
        availableBalance = availableBalance.sub(scamProfit);
        userScams[msg.sender] = userScams[msg.sender].sub(_scams);
        userBalance[msg.sender] += scamProfit;
        userTime[msg.sender] = now;
    }
        
    function withdrawScamEarnings() public relax {
        require (userBalance[msg.sender] > 0);
        uint256 balance = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        msg.sender.transfer(balance);
    }

    function fastEscape() public relax {
        uint256 scamProfit = userScams[msg.sender].mul(scamPrice);
        if (scamProfit <= availableBalance) {
            sellScams(userScams[msg.sender]);
            withdrawScamEarnings();
        } else {
            uint256 maxScams = availableBalance.div(scamPrice);
            assert (userScams[msg.sender] >= maxScams);
            sellScams(maxScams);
            withdrawScamEarnings();
        }
    }

    function drainMe() public relax {
        require (availableBalance > 420);
        uint256 notRandomNumber = uint256(blockhash(block.number - 1)) % 2;
        if (notRandomNumber == 0) {
            msg.sender.transfer(420);
            availableBalance.sub(420);
        } else {
            msg.sender.transfer(69);
            availableBalance.sub(69);
        }
    }

    function exitScam() public relax {
        require (msg.sender == scammerInChief);
        require (now >= countdownToExitScam);
        selfdestruct(scammerInChief);
    }
    
    function checkBalance() public view returns(uint256) {
        return address(this).balance;
    }
}

library ScamMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}