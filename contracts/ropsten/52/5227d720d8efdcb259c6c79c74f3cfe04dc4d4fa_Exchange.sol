pragma solidity ^0.4.23;

//Remix js testing > deploy > test deployed ctrt with Remix&#39;s interface
contract Exchange {
    //for reading variable value tests: from Remix:  gas limit 1442419, gas price 1 Gwei
    //deployed at: 0xf01a2920c01729bd3fb03c744bed34ba35dbfdd0 Rinkeby
    address public owner;
    string public zString;
    address public zAddress;
    uint public zUint256;
    bool public zBool;
    bytes32 public zBytes32;
    address[2] public zAddressesArray;
    uint[2] public zUint256Array;

    constructor() public {
        owner = msg.sender;
        zString = &#39;Hello&#39;;
        zAddress = 0x479CC461fEcd078F766eCc58533D6F69580CF3AC;
        zUint256  = 1234567890;
        zBool    = true;
        zBytes32       = "HelloBytes32";
        //0x48656c6c6f427974657333320000000000000000000000000000000000000000
        zAddressesArray = [0xc778417E063141139Fce010982780140Aa0cD5Ab,0x0d0F936Ee4c93e25944694D6C121de94D9760F11];
        zUint256Array  = [7777777777,8888888888];
        //exchangeContractAddress = "0x479cc461fecd078f766ecc58533d6f69580cf3ac";
    }
    function getVariables() view public returns (string, address, uint, bool, bytes32, address[2], uint[2]) {
        return (zString, zAddress, zUint256, zBool, zBytes32, zAddressesArray, zUint256Array);
    }

    function setzString(string _zString) public {
      zString = _zString;
    }
    function setzAddress(address _zAddress) public {
      zAddress = _zAddress;
    }
    function setzUint256(uint _zUint256) public {
      zUint256 = _zUint256;
    }
    function setzBool(bool _zBool) public {
      zBool = _zBool;
    }
    function setzBytes32(bytes32 _zBytes32) public {
      zBytes32 = _zBytes32;
    }
    function setzAddressesArray(address[2] _zAddressesArray) public {
      zAddressesArray = _zAddressesArray;
    }
    function setzUint256Array(uint[2] _zUint256Array) public {
      zUint256Array = _zUint256Array;
    }

    function setVariables(string _zString, address _zAddress, uint _zUint256, bool _zBool, bytes32 _zBytes32, address[2] _zAddressesArray, uint[2] _zUint256Array) public {
        zString = _zString;
        zAddress = _zAddress;
        zUint256 = _zUint256;
        zBool    = _zBool;
        zBytes32       = _zBytes32;
        zAddressesArray = _zAddressesArray;
        zUint256Array   = _zUint256Array;
    }

    function userAddr() public view returns (address) {
      return msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}