/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Cagnotte {
    address payable public creator;
    address payable public receiver;
    string public multihash;
    uint public timeout;
    uint public minCap;
    uint public total;
    uint public countContributors;
    bool public isStarted;
    bool public isFinalized;
    mapping(address => uint) public contributors;

    constructor(address payable _creator, address payable _receiver, string memory _multihash, uint _delay, uint _minCap) {
        creator = _creator;
        receiver = _receiver;
        multihash = _multihash;
        timeout = block.timestamp + _delay;
        minCap = _minCap;
        total = 0;
        countContributors = 0;
        isStarted = true;
    }

    function contribute() external payable {
        require(msg.value > 0 && block.timestamp < timeout);
        
        contributors[msg.sender] += msg.value;
        countContributors += 1;
        total += msg.value;
    }


    function finalize() external {
        require(!isFinalized && block.timestamp > timeout);
        
        if (total >= minCap) {
            receiver.transfer(address(this).balance);
        }
        
        isFinalized = true;
    }

    function withdraw() external {
        require(isFinalized && contributors[msg.sender] > 0);
        
        address payable contributor = payable(msg.sender);
        uint amount = contributors[msg.sender];
        
        contributors[msg.sender] = 0;
        contributor.transfer(amount);
    }

    function getTimeLeft() external view returns (uint) {
        if (timeout <= block.timestamp) {
            return 0;
        }
        return timeout - block.timestamp;
    }
    
    function getDetails() external view returns(address, address, string memory, uint, uint, uint, uint, bool) {
        return (creator, receiver, multihash, timeout, minCap, total, countContributors, isFinalized);
    }
}


contract CryptoLeetchi {
    Cagnotte[] private cagnottes;

    event cagnotteStarted(address addressContract, address addressCreator, address addressReceiver, string multihash, uint256 delay, uint256 minCap);

    mapping(address => string) public ipfsCagnotte;

    function startCagnotte(address payable _creator, address payable _receiver, string memory _multihash, uint _delay, uint _minCap) external returns (Cagnotte) {
        require(_creator == msg.sender);
        Cagnotte newCagnotte = new Cagnotte(_creator, _receiver, _multihash, _delay, _minCap); 
        ipfsCagnotte[address(newCagnotte)] = _multihash;
        cagnottes.push(newCagnotte);
        
        emit cagnotteStarted(address(newCagnotte), _creator, _receiver, _multihash, _delay, _minCap);

        return newCagnotte;
    }

    function getAllCagnottes() external view returns(Cagnotte[] memory) {
        return cagnottes;
    }
}