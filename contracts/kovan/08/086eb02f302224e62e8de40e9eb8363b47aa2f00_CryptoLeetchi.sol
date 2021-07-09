// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Cagnotte {
    address payable public creator;
    address public receiver;
    string public multihash;
    uint public timeout;
    uint public minCap;
    uint public total;
    bool public isStarted;
    bool public isFinalized;
    mapping(address => uint) public contributors;

    constructor(address payable _creator, address _receiver, string memory _multihash, uint _delay, uint _minCap) {
        creator = _creator;
        receiver = _receiver;
        multihash = _multihash;
        timeout = block.timestamp + _delay;
        minCap = _minCap;
        total = 0;
        isStarted = true;
    }

    function contribute() public payable {
        require(msg.value > 0 && block.timestamp < timeout);
        
        contributors[msg.sender] += msg.value;
        total += msg.value;
    }

    function finalize() public {
        require(!isFinalized && block.timestamp > timeout);

        creator.transfer(address(this).balance);
        timeout = 0;
        isFinalized = true;
    }

    function withdraw() public {
        require(!isFinalized && block.timestamp < timeout);
        require(contributors[msg.sender] > 0);
        
        address payable contributor = payable(msg.sender);
        uint amount = contributors[msg.sender];
        
        contributors[msg.sender] = 0;
        total -= amount;
        contributor.transfer(amount);
    }

    function getTimeLeft() public view returns (uint) {
        if (timeout <= block.timestamp) {
            return 0;
        }
        return timeout - block.timestamp;
    }
    
    function getDetails() public view returns(address payable, address, string memory, uint, uint256, uint) {
        return (creator, receiver, multihash, timeout, total, minCap);
    }
}


contract CryptoLeetchi {
    Cagnotte[] private cagnottes;

    event cagnotteStarted(address addressContract, address addressCreator, address addressReceiver, string multihash, uint256 delay, uint256 minCap);

    mapping(address => string) public ipfsCagnotte;

    // _receiver: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // _multihash: QmXeDksYDm7Z1HGXQ27LVDsRtzKoC8P3b6skviBJ21FSgb
    // _dalay: 100
    // _minCap: 3000000000000000000
    function startCagnotte(address payable _creator, address _receiver, string memory _multihash, uint _delay, uint _minCap) external returns (Cagnotte) {
        require(_creator == msg.sender);
        // uint targetTime = block.timestamp + _delay;
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}