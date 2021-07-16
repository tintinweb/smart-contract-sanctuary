//SourceUnit: BTCXDice.sol

pragma solidity ^0.4.25;

contract BTCXDice {
    address public owner = msg.sender;
    address private lastSender;
    address private lastOrigin;
    uint public tokenId = 1002573;
    uint public totalUsers;
    
    mapping (address => bool) public registered;
    mapping (address => address) public referrers;
    
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

    function _register(address referrerAddress) internal {
        if (!registered[msg.sender]) {  
            if (referrerAddress != msg.sender && registered[referrerAddress]) {
                referrers[msg.sender] = referrerAddress;
            }

            totalUsers++;
            registered[msg.sender] = true;
        }
    }
    
    function dice(uint rollUnder, address referer) external payable notContract {
        require(msg.tokenid == tokenId);
        require(msg.tokenvalue >= 50000000 && msg.tokenvalue <= getMaxBet());
        require(rollUnder >= 4 && rollUnder <= 95);

        _register(referer);
        
        uint number = random(100);
        if (number < rollUnder) {
            uint prize = msg.tokenvalue * 98 / rollUnder;
            msg.sender.transferToken(prize, tokenId);
            emit Dice(msg.sender, msg.tokenvalue, prize, number, rollUnder);
        } else {
            if (referrers[msg.sender] != 0x0) {
               referrers[msg.sender].transferToken(msg.tokenvalue / 10, tokenId);
            }
            emit Dice(msg.sender, msg.tokenvalue, 0, number, rollUnder);
        }
    }
}