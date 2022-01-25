// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./ripLibrary.sol";

contract DPS is Ownable{
    address[] private members;
    mapping(address => address) private chain;
    mapping(address => uint) private balances;
    uint private minBet = 0.1 ether;

    event Joined(address indexed who, address indexed sup, uint amount);
    event Ponzi(address indexed winner, uint amount);

    //function renounceOwnership() public pure override {
    //    revert("Doesn't make sense to renounce ownership");
    //}

    constructor() Ownable() {
        chain[msg.sender] = msg.sender;
        members.push(msg.sender);
    }

    function join(address sup) public payable {
        if (inChain(msg.sender)) {
            balances[msg.sender] += msg.value;
            return;
        }

        if (!inChain(sup)) {
            sup = randMember();
        }

        bool min_ok = (msg.value >= minBet);
        if (min_ok) {
            chain[msg.sender] = sup;
            members.push(msg.sender);
        }
        ponzi(msg.value, sup);
    }

    fallback() external payable {
        balances[owner()] += msg.value;
    }

    receive() external payable {
        balances[owner()] += msg.value;
    }

    function getMinBet() public view onlyOwner returns(uint) {
        return minBet;
    }

    function changeMinBet(uint i_minBet) public onlyOwner {
        minBet = i_minBet;
    }

    function supOf(address who) public view onlyOwner returns(address) {
        return chain[who];
    }

    function balanceOf(address who) public view onlyOwner returns(uint) {
        return balances[who];
    }

    function getMembers() public view onlyOwner returns(address[] memory) {
        return members;
    }

    function destroySmartContract(address payable to) public onlyOwner {
        selfdestruct(to);
    }

    function getBalance() public view returns(uint) {
        return balances[msg.sender];
    }

    function withdraw() public {
        uint amount = balances[msg.sender];
        require(amount > 0, "Insufficient Funds");
        balances[msg.sender] = 0;
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }

    function inChain(address who) private view returns(bool) {
        return chain[who] != address(0);
    }

    function ponzi(uint amount, address to) private {
        if (to==owner() || !inChain(to)) {
            balances[owner()] += amount;
            emit Ponzi(owner(), amount);
        } else {
            uint theAmount = amount/2;
            balances[to] += theAmount;
            emit Ponzi(to, theAmount);
            address sup = chain[to];
            ponzi(theAmount, sup);
        }
    }

    function randMember() private view returns(address) {
        uint rand = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, members, owner())));
        return members[rand % members.length];
    }
}