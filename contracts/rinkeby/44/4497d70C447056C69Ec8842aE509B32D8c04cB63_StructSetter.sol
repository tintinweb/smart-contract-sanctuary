contract StructSetter {
    uint256 public value;


    struct Scalars {
        uint256 number;
        bool flag;
    }
    
    struct Nested {
        uint256 number;
        Scalars scalars;
    }
    
    struct WithArray {
        uint256[] numbers;
    }
    
    function setScalars(Scalars memory scalars) public {
        value = scalars.number + (scalars.flag ? 1 : 0);
    }
    
    function setNested(Nested memory nested) public {
        value = nested.scalars.number + (nested.scalars.flag ? 1 : 0);
    }
    
    function setWithArray(WithArray memory s) public {
        value = s.numbers[0] + s.numbers[1];
    }
    
    function setScalarsArray(Scalars[] memory manyScalars, uint256 extra) public {
        value = manyScalars[0].number + (manyScalars[0].flag ? 1 : 0) + manyScalars[1].number + (manyScalars[1].flag ? 1 : 0) + extra;
    }
    
    function setTwoScalarsArrays(Scalars[] memory manyScalars, Scalars[] memory moreScalars, uint256 extra) public {
        value = manyScalars[0].number + (manyScalars[0].flag ? 1 : 0) + moreScalars[1].number + (moreScalars[1].flag ? 1 : 0) + extra;
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
  },
  "libraries": {}
}