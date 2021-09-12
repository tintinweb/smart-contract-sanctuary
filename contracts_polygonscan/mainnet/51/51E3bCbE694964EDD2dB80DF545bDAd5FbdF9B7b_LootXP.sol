// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.7;

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address firstOwner) {
        _owner = firstOwner;
        emit OwnershipTransferred(address(0), firstOwner);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "NOT_OWNER");
        _;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract LootXP is Ownable {
    event SourceSet(address indexed generator, address indexed source, bool added);
    event SinkSet(address indexed generator, address indexed sink, bool added);
    event GeneratorSet(address indexed generator, bool added);

    event XP(uint256 indexed lootId, address indexed sourceOrSink, uint256 previousAmount, uint256 newAmount);

    mapping(uint256 => uint256) public xp;
    mapping(address => uint256) public xpGenerated;
    mapping(address => uint256) public xpDestroyed;

    mapping(address => bool) public xpSource;
    mapping(address => bool) public xpSink;

    mapping(address => bool) public generator;

    // solhint-disable-next-line no-empty-blocks
    constructor(address firstOwner) Ownable(firstOwner) {}

    function addXP(uint256 lootId, uint256 amount) external returns (bool) {
        // use return bool instead of throw so that caller can be sure the call will not revert and can carry on
        if (xpSource[msg.sender]) {
            uint256 oldXP = xp[lootId];
            uint256 newXP;
            unchecked {newXP = oldXP + amount;}
            if (newXP < oldXP) {
                newXP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            }
            xp[lootId] = newXP;
            emit XP(lootId, msg.sender, oldXP, newXP);
            amount = newXP - oldXP;

            oldXP = xpGenerated[msg.sender];
            unchecked {newXP = oldXP + amount;}
            if (newXP < oldXP) {
                newXP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            }
            xpGenerated[msg.sender] = newXP;

            return true;
        }
        return false;
    }

    function removeXP(uint256 lootId, uint256 amount) external returns (bool) {
        // use return bool instead of throw so that caller can be sure the call will not revert and can carry on
        if (xpSink[msg.sender]) {
            uint256 oldXP = xp[lootId];
            uint256 newXP;
            if (amount > oldXP) {
                newXP = 0;
            } else {
                newXP = oldXP - amount;
            }
            xp[lootId] = newXP;
            emit XP(lootId, msg.sender, oldXP, newXP);
            amount = oldXP - newXP;

            oldXP = xpDestroyed[msg.sender];
            unchecked {newXP = oldXP + amount;}
            if (newXP < oldXP) {
                newXP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            }
            xpDestroyed[msg.sender] = newXP;

            return true;
        }
        return false;
    }

    function setSource(address source, bool add) external {
        require(generator[msg.sender] || msg.sender == _owner, "NOT_ALLOWED");
        xpSource[source] = add;
        emit SourceSet(msg.sender, source, add);
    }

    function setSink(address sink, bool add) external {
        require(generator[msg.sender] || msg.sender == _owner, "NOT_ALLOWED");
        xpSink[sink] = add;
        emit SinkSet(msg.sender, sink, add);
    }

    function setGenerator(address generatorToSet, bool add) external {
        require(msg.sender == _owner, "NOT_ALLOWED");
        generator[generatorToSet] = add;
        emit GeneratorSet(generatorToSet, add);
    }
}

{
  "evmVersion": "london",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "remappings": [],
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