/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    function percentageOf(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a * b / 100;
    }
    
}

contract CoinFlip {
    enum Coin {HEAD,TAIL}
    using SafeMath for uint;
    
    address payable private me;
    uint identifier;
    uint nonce;
    
    mapping (address => uint) private pots;
    
    
    constructor (uint _identifier) public {
        identifier = _identifier;
        me = address(this);
    }
    
    // ------------------------------------------------------------------------
    // toss coin
    // ------------------------------------------------------------------------
    function tossCoin() private returns (Coin) {
       uint random = luck(0,1);
       return random == 0 ? Coin.HEAD : Coin.TAIL;
    }
    
    // ------------------------------------------------------------------------
    // generate random number from (min to max)
    // ------------------------------------------------------------------------
    function luck(uint min, uint max) private returns (uint) {
        uint randomNumber = uint(
            uint(keccak256(abi.encodePacked(identifier, nonce, block.timestamp, block.difficulty, msg.sender))) % (max - min + 1)
        );
        nonce++;
        randomNumber = randomNumber + min;
        return randomNumber;
    }

    function palceBet(uint betOption) external payable returns (bool) {
        uint betAmount = msg.value;
        bool limit = betAmount < 0.001 ether || betAmount > 1 ether;
        require(uint(Coin.TAIL) >= betOption, "place bet (HEAD-0, TAIL-1)");
        require(!limit, "bet limit, (between 0.001 - 5)");
        
        uint pot = betAmount.mul(2);
        uint fee = betAmount.percentageOf(5); //service fee
        uint winAmount = pot -fee; 
        
        Coin coinResult = tossCoin();
        if(uint(coinResult) == betOption) {
            //Player win
            if(address(this).balance < winAmount) {
                uint contractBalance = me.balance;
                msg.sender.transfer(contractBalance);
            }
            else {
                msg.sender.transfer(winAmount);
            }
            return true;
        }
        return false;
    }
    
    
    function chargeBalance() external payable {
    }
    
    function ownBalance() public view returns (uint256) {
        return me.balance;
    }
    
    
    function () external payable {
    }

}