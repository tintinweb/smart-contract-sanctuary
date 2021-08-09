pragma solidity >=0.5.0 <0.6.0;

import "./CHILLYPenguinFactory.sol";

contract KittyInterface {
  function getKitty(uint256 _id) external view returns (
    bool isGestating,
    bool isReady,
    uint256 cooldownIndex,
    uint256 nextActionAt,
    uint256 siringWithId,
    uint256 birthTime,
    uint256 matronId,
    uint256 sireId,
    uint256 generation,
    uint256 genes
  );
}

contract ChillyPenguinFeeder is ChillyPenguinFactory {

  address ckAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
  KittyInterface kittyContract = KittyInterface(ckAddress);

  // Modify function definition here:
  function feedAndMultiply(uint _penguinoId, uint _targetDna) public {
    require(msg.sender == penguinoToOwner[_penguinoId]);
    Penguino storage myPenguino = penguinos[_penguinoId];
    _targetDna = _targetDna % dnaModulus;
    uint newDna = (myPenguino.dna + _targetDna) / 2;
    // Add an if statement here
    _createPenguino("NoName", newDna);
  }

  function feedOnKitty(uint _penguinoId, uint _kittyId) public {
    uint kittyDna;
    (,,,,,,,,,kittyDna) = kittyContract.getKitty(_kittyId);
    // And modify function call here:
    feedAndMultiply(_penguinoId, kittyDna);
  }

}

pragma solidity >=0.5.0 <0.6.0;

contract ChillyPenguinFactory{

    event NewPenguino(uint penguinoId, string name, uint dna);

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;

    struct Penguino {
        string name;
        uint dna;
    }

    Penguino[] public penguinos;

    mapping (uint => address) public penguinoToOwner;
    mapping (address => uint) ownerPenguinoCount;

    function _createPenguino(string memory _name, uint _dna) internal {
        uint id = penguinos.push(Penguino(_name, _dna)) - 1;
        penguinoToOwner[id] = msg.sender;
        ownerPenguinoCount[msg.sender]++;
        emit NewPenguino(id, _name, _dna);
    }

    function _generateRandomDna(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }

    function createRandomPenguino(string memory _name) public {
        require(ownerPenguinoCount[msg.sender] == 0);
        uint randDna = _generateRandomDna(_name);
        _createPenguino(_name, randDna);
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