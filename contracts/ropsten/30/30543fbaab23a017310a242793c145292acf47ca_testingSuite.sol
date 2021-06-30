/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

/**
 *Our testing suite
*/

pragma solidity 0.5.17;


contract testingSuite {
    
    //set via constructor - cannot be reset
    bool public constructorRun;
    

//SINGLE VARIABLE SECTION:

    //set and reset via addString
    string public currentString;
    //event fired by addString
    event stringEvent(string newStringValue);
    event stringEventWithOtherParams(string newStringValue, uint256 testUint256, bool testBool);
    
    //set and reset via addBool
    bool public currentBool;
    //event fired by addBool
    event boolEvent(bool newBoolValue);
    
    //set and reset via addUint256
    uint256 public currentUint256;
    //event fired by addUint256
    event uint256Event(uint256 newUint256Value);
    
    //set and reset via addUint16
    uint16 public currentUint16;
    //event fired by addUint16
    event uint16Event(uint16 newUint16Value);
    
    //set and reset via addInt256
    int256 public currentInt256;
    //event fired by addInt16
    event int256Event(int256 newInt256Value);
    
    //set and reset via addInt16
    int16 public currentInt16;
    //event fired by addUint16
    event int16Event(int16 newInt16Value);
    event int16WithOtherParams(int16 newInt16Value, uint16 testUint16, int256 testInt256);
    
    //set and reset via addbytes32
    bytes32 public currentBytes32;
    //event fired by addbytes32
    event bytes32Event(bytes32 newBytes32Value);
    
    //set and reset via addbytes5
    bytes5 public currentBytes5;
    //event fired by addbytes5
    event bytes5Event(bytes5 newBytes5Value);
    
    //set and reset via addbytes
    bytes public currentBytes;
    //event fired by addbytes
    event bytesEvent(bytes newBytesValue);
    

//ARRAY VARIABLE SECTION:

    //**STRING ARRAY IS EXPERIMENTAL AND THEREFORE NOT USED ATM
    //set and reset via addStringArray
    //string[] public currentStringArray;
    //event fired by addStringArray
    //event stringArrayEvent(string newStringArrayValue);
    
    //set and reset via addBoolArray
    bool[] public currentBoolArray;
    //event fired by addBoolArray
    event boolArrayEvent(bool[] newBoolArrayValue);
    
    //set and reset via addUint256Array
    uint256[] public currentUint256Array;
    //event fired by addUint256Array
    event uint256ArrayEvent(uint256[] newUint256ValueArray);
    
    //set and reset via addUint16Array
    uint16[] public currentUint16Array;
    //event fired by addUint16Array
    event uint16ArrayEvent(uint16[] newUint16ValueArray);
    
    //set and reset via addInt256Array
    int256[] public currentInt256Array;
    //event fired by addInt16Array
    event int256ArrayEvent(int256[] newInt256ArrayValue);
    
    //set and reset via addInt16
    int16[] public currentInt16Array;
    //event fired by addUint16
    event int16ArrayEvent(int16[] newInt16ValueArray);
    
    //set and reset via addbytes32
    bytes32[] public currentBytes32Array;
    //event fired by addbytes32
    event bytes32ArrayEvent(bytes32[] newBytes32ValueArray);
    
    //set and reset via addbytes5
    bytes5[] public currentBytes5Array;
    //event fired by addbytes5
    event bytes5ArrayEvent(bytes5[] newBytes5ValueArray);
    
    //set and expanded on via addFixedLengthArray and addDynamicArray
    uint256[] public growableUintsArray;
    bool[] public growableBoolArray;
    address[] public growableAddressArray;

    //event fired by addFixedLengthArray
    event arraysFixed(uint256[3] numbers, address[2] addresses, bool[4] bools);
    
    //event fired by addDynamicArray
    event arraysDynamic(uint256[] numbers, address[] addresses, bool[] bools);

    
    
    
//FUNCTIONS    

    
    constructor () public {
        constructorRun = true;
    }    
    
    
//SINGLE VARIABLE SECTION:

    
    function addString(string calldata newString) external {
        
        currentString = newString;
        emit stringEvent(currentString);
        emit stringEventWithOtherParams(currentString, 14, true);
        
    }
    
    function addBool(bool newBool) external {
        
        currentBool = newBool;
        emit boolEvent(currentBool);
        
    }
    
    function addUint256(uint256 newUint) external {
        
        currentUint256 = newUint;
        emit uint256Event(currentUint256);
        
    }
    
    //uint in Solidity is equal to uint256, lets see if we can handle this
    function addUint(uint newUint) external {
        
        currentUint256 = newUint;
        emit uint256Event(currentUint256);
        
    }
    
    function addUint16(uint16 newUint) external {
        
        currentUint16 = newUint;
        emit uint16Event(currentUint16);
        
    }
    
    function addInt256(int256 newInt) external {
        
        currentInt256 = newInt;
        emit int256Event(currentInt256);
        
    }

    //int in Solidity is equal to int256, lets see if we can handle this
    function addInt(int newInt) external {
        
        currentInt256 = newInt;
        emit int256Event(currentInt256);
        
    }
    
    function addInt16(int16 newInt) external {
        
        currentInt16 = newInt;
        emit int16Event(currentInt16);
        emit int16WithOtherParams(currentInt16, 245,123456);
        
    }
    

    function addBytes32(bytes32 newbytes) external {
        
        currentBytes32 = newbytes;
        emit bytes32Event(currentBytes32);
        
    }
    

    function addBytes5(bytes5 newbytes) external {
        
        currentBytes5 = newbytes;
        emit bytes5Event(currentBytes5);
        
    }
    
    function addBytes(bytes calldata newbytes) external {
        
        currentBytes = newbytes;
        emit bytesEvent(currentBytes);
        
    }
    

//ARRAY VARIABLE SECTION:


    
    function addBoolArray(bool[] calldata newBool) external {
        
        currentBoolArray = newBool;
        emit boolArrayEvent(currentBoolArray);
        
    }
    
    function addUint256Array(uint256[] calldata newUint) external {
        
        currentUint256Array = newUint;
        emit uint256ArrayEvent(currentUint256Array);
        
    }
    
    //uint in Solidity is equal to uint256, lets see if we can handle this
    function addUintArray(uint[] calldata newUint) external {
        
        currentUint256Array = newUint;
        emit uint256ArrayEvent(currentUint256Array);
        
    }
    
    function addUint16Array(uint16[] calldata newUint) external {
        
        currentUint16Array = newUint;
        emit uint16ArrayEvent(currentUint16Array);
        
    }
    
    function addInt256Array(int256[] calldata newInt) external {
        
        currentInt256Array = newInt;
        emit int256ArrayEvent(currentInt256Array);
        
    }

    //int in Solidity is equal to int256, lets see if we can handle this
    function addIntArray(int[] calldata  newInt) external {
        
        currentInt256Array = newInt;
        emit int256ArrayEvent(currentInt256Array);
        
    }
    
    function addInt16Array(int16[] calldata newInt) external {
        
        currentInt16Array = newInt;
        emit int16ArrayEvent(currentInt16Array);
        emit int16WithOtherParams(currentInt16, 245,123456);
        
    }
    
    function addDifferentIntegersArray(uint256[] calldata newUint1, int16[] calldata newInt2) external {

        currentUint256Array = newUint1;
        emit uint256ArrayEvent(currentUint256Array);
        currentInt16Array = newInt2;
        emit int16ArrayEvent(currentInt16Array);
        emit int16WithOtherParams(currentInt16, 245,123456);
        
    }
    

    function addBytes32Array(bytes32[] calldata newbytes) external {
        
        currentBytes32Array = newbytes;
        emit bytes32ArrayEvent(currentBytes32Array);
        
    }
    

    function addBytes5Array(bytes5[] calldata newbytes) external {
        
        currentBytes5Array = newbytes;
        emit bytes5ArrayEvent(currentBytes5Array);
        
    }
    
    function addDifferentTypesArray(uint256[] calldata newUint, bytes32[] calldata newbytes, bool[] calldata newBool) external {

        currentUint256Array = newUint;
        emit uint256ArrayEvent(currentUint256Array);
        currentBytes32Array = newbytes;
        emit bytes32ArrayEvent(currentBytes32Array);
        currentBoolArray = newBool;
        emit boolArrayEvent(currentBoolArray);
        
    }

    


    
    function addFixedLengthArray() external {

        uint256 one = 1;
        uint256 two = 2;
        uint256 threehundredand4 = 304;
        uint256[3] memory  uints = [one,two,threehundredand4];
        bool[4] memory bools = [true,false,true,false];
        address[2] memory addresses = [address(this), msg.sender];

        emit arraysFixed(uints,  addresses,  bools);
    }
    
    function addDynamicArray(uint slots) external {

        uint256 count = 1;
        bool current = true;
        while (count <= slots){
            growableUintsArray.push(count);
            growableBoolArray.push(current);
            current = !current;
            growableAddressArray.push(block.coinbase);
            count++;
        }

        emit arraysDynamic(growableUintsArray,  growableAddressArray,  growableBoolArray);
    }
    
    
    

    
}