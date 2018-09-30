pragma solidity ^0.4.24;
 
/**
 * @title CrankysLottery
 * @dev The CrankysLottery contract is an ETH lottery contract
 * that allows unlimited entries at the cost of 1 ETH per entry.
 * Winners are rewarded the pot.
 */
contract CrankysLottery {
 
    address public owner;
    uint private latestBlockNumber;
    bytes32 private cumulativeHash;
    address[] private bets;
    mapping(address => uint256) winners;
 
    constructor() public {
        owner = msg.sender;
        latestBlockNumber = block.number;
        cumulativeHash = bytes32(0);
    }
 
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
 
    function placeBet() public payable returns (bool) {
        uint _wei = msg.value;
        assert(_wei == 1000000000000000000);
        cumulativeHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber), cumulativeHash));
        latestBlockNumber = block.number;
        bets.push(msg.sender);
        return true;
    }
 
    function drawWinner() public onlyOwner returns (address) {
        assert(bets.length > 4);
        latestBlockNumber = block.number;
        bytes32 _finalHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber-1), cumulativeHash));
        uint256 _randomInt = uint256(_finalHash) % bets.length;
        address _winner = bets[_randomInt];
        winners[_winner] = 1000000000000000000 * bets.length;
        cumulativeHash = bytes32(0);
        delete bets;
        return _winner;
    }
 
    function withdraw() public returns (bool) {
        uint256 amount = winners[msg.sender];
        winners[msg.sender] = 0;
        if (msg.sender.send(amount)) {
            return true;
        } else {
            winners[msg.sender] = amount;
            return false;
        }
    }
 
    function getBet(uint256 betNumber) public view returns (address) {
        return bets[betNumber];
    }
 
    function getNumberOfBets() public view returns (uint256) {
        return bets.length;
    }
}