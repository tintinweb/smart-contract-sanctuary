// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Cagnotte {
    address public creator;
    address payable public receiver;
    string multihash;
    uint public timeout;
    uint public minCap;
    uint public total;
    bool public isStarted;
    bool public isFinalized;
    mapping(address => uint) public contributors;

    constructor(address payable _receiver, uint _delay, uint _minCap) {
        creator = msg.sender;
        receiver = _receiver;
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
        // require(total >= minCap);
        
        receiver.transfer(address(this).balance);
        timeout = 0;
        isFinalized = true;
    }

    function withdraw() public {
        require(!isFinalized && contributors[msg.sender] > 0 && block.timestamp < timeout);
        
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
    
    function getDetails() public view returns(address, address payable, string memory, uint, uint256, uint) {
        return (creator, receiver, multihash, timeout, total, minCap);
    }
}

// _receiver: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// _multihash: QmXeDksYDm7Z1HGXQ27LVDsRtzKoC8P3b6skviBJ21FSgb
// _daly: 100
// _minCap: 3000000000000000000

// bytes32 = 0x0000000000000000000000000000000000000000000000000000000000000000

contract CryptoLeetchi {
    Cagnotte[] private cagnottes;

    event cagnotteStarted(address _contractAddress, address _cagnotteOwner, string _multihash, uint256 _targetDate, uint256 _amountToRaise);

    mapping(string => Cagnotte) public ipfsCagnotte;

    function startCagnotte(address payable _receiver, string memory _multihash, uint _targetDate, uint _targetAmount) external returns (Cagnotte) {
        uint targetTime = block.timestamp + _targetDate;
        Cagnotte newCagnotte = new Cagnotte(_receiver, targetTime, _targetAmount); 
        ipfsCagnotte[_multihash] = newCagnotte;
        cagnottes.push(newCagnotte);
        
        emit cagnotteStarted(address(newCagnotte), msg.sender, _multihash, targetTime, _targetAmount);

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