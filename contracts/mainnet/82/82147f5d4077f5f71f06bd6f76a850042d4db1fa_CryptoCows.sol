pragma solidity ^0.4.23;

contract owned {

    address owner;

    /*this function is executed at initialization and sets the owner of the contract */
    constructor() public { owner = msg.sender; }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract mortal is owned {

    /* Function to recover the funds on the contract */
    function kill() public onlyOwner() {
        selfdestruct(owner);
    }

}

contract CryptoCows is owned, mortal {
   
    struct Cow {
        uint32 milk;
        uint32 readyTime;
    }

    event GetCowEvent(uint id);
    event GetMilkEvent(uint32 milk, uint32 timestamp);
    
    Cow[] public cows;
    uint public allMilk;
    
    mapping(uint => address) public owners;
    mapping(address => uint) public count;
    mapping(address => uint) public ownerCow;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function getCow(uint _cowId) public view returns (uint32, uint32) {
        Cow storage _cow = cows[_cowId];
        return (_cow.milk, _cow.readyTime);
    }
    
    function countCows() public view returns(uint) {
        return cows.length;
    }
    
    function countMilk() public view returns(uint) {
        return allMilk;
    }
    
    function buyCow() public {
        require(count[msg.sender] == 0);
        uint id = cows.length;
        cows.push(Cow(0, uint32(now)));
        owners[id] = msg.sender;
        count[msg.sender] = 1;
        ownerCow[msg.sender] = id;
        emit GetCowEvent(id);
    }
    
    function removeCooldown() public payable {
        require(msg.value == 0.001 ether);
        require(count[msg.sender] == 1);
        uint _cowId = ownerCow[msg.sender];
        Cow storage currentCow = cows[_cowId];
        require(_isReady(currentCow) == false);
        currentCow.readyTime = uint32(now);
        emit GetCowEvent(_cowId);
    }
    
    function _isReady(Cow storage _cow) internal view returns (bool) {
        return (_cow.readyTime <= now);
    }    
    
    function getMilk() public {
        require(count[msg.sender] == 1);
        uint _cowId = ownerCow[msg.sender];
        Cow storage currentCow = cows[_cowId];
        require(_isReady(currentCow));
        uint32 addMilk = uint32(random());
        allMilk = allMilk + uint(addMilk);
        currentCow.milk += addMilk;
        currentCow.readyTime = uint32(now + 1 hours);
        emit GetMilkEvent(addMilk, currentCow.readyTime);
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty))%221);
    }    
    
    function withDraw() public onlyOwner {
        uint amount = getBalance();
        owner.transfer(amount);
    }
    
    function getBalance() public view returns (uint){
        return address(this).balance;
    }    
}