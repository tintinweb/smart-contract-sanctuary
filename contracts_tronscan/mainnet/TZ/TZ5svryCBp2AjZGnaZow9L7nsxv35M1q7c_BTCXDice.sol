//SourceUnit: BTCXDice.sol

pragma solidity ^0.4.25;

contract BTCXDice {
    address public owner = msg.sender;
    address private lastSender;
    address private lastOrigin;
    uint public tokenId = 1002573;
    
    event Dice(address indexed from, uint256 bet, uint256 prize, uint256 number, uint256 rollUnder);
    
    uint private seed;
 
    modifier notContract() {
        lastSender = msg.sender;
        lastOrigin = tx.origin;
        require(lastSender == lastOrigin);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // uint256 to bytes32
    function toBytes(uint256 x) internal pure returns (bytes b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
    
    // returns a pseudo-random number
    function random(uint lessThan) internal returns (uint) {
        seed += block.timestamp + uint(msg.sender);
        return uint(sha256(toBytes(uint(blockhash(block.number - 1)) + seed))) % lessThan;
    }

    function getMaxBet() public view returns (uint) {
        uint maxBet = address(this).tokenBalance(tokenId) / 50;
        return maxBet > 100000000000 ? 100000000000 : maxBet;
    }

    function getProfit(uint amount) external onlyOwner {
        uint max = address(this).tokenBalance(tokenId);
        owner.transferToken(amount < max ? amount : max, tokenId);
    }
    
    function dice(uint rollUnder) external payable notContract {
        require(msg.tokenid == tokenId);
        require(msg.tokenvalue >= 50000000 && msg.tokenvalue <= getMaxBet());
        require(rollUnder >= 4 && rollUnder <= 95);
        
        uint number = random(100);
        if (number < rollUnder) {
            uint prize = msg.tokenvalue * 98 / rollUnder;
            msg.sender.transferToken(prize, tokenId);
            emit Dice(msg.sender, msg.tokenvalue, prize, number, rollUnder);
        } else {
            emit Dice(msg.sender, msg.tokenvalue, 0, number, rollUnder);
        }
    }
}