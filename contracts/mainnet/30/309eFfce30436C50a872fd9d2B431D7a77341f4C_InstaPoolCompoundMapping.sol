pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface CTokenInterface {
    function underlying() external view returns (address);
}

interface GemJoinInterface {
    function ilk() external view returns (bytes32);
}

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

interface IndexInterface {
    function master() external view returns (address);
}


contract Helpers {
    address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;

    mapping (address => address) public cTokenMapping;

    event LogAddCTokenMapping(address indexed token, address indexed cToken);
    event LogUpdateCTokenMapping(address indexed token, address indexed oldCToken, address indexed newCToken);
    
    modifier isMaster {
        require(
            IndexInterface(instaIndex).master() == msg.sender, "not-master");
        _;
    }

    function _addCtknMapping(address[] memory cTkns) internal {
        require(cTkns.length > 0, "No-CToken-Address");
        for (uint i = 0; i < cTkns.length; i++) {
            address cErc20 = cTkns[i];
            address erc20 = CTokenInterface(cErc20).underlying();
            require(cTokenMapping[erc20] == address(0), "Token-already-added");
            cTokenMapping[erc20] = cErc20;
            emit LogAddCTokenMapping(cErc20, erc20);
        }
    }

    function addCtknMapping(address[] memory cTkns) public isMaster {
        _addCtknMapping(cTkns);
    }

    function updateCtknMapping(address[] memory cTkn) public isMaster {
        require(cTkn.length > 0, "No-CToken-Address");
        for (uint i = 0; i < cTkn.length; i++) {
            address cErc20 = cTkn[i];
            address erc20 = CTokenInterface(cErc20).underlying();
            require(cTokenMapping[erc20] != address(0), "Token-not-added");
            emit LogUpdateCTokenMapping(erc20, cTokenMapping[erc20], cErc20);
            cTokenMapping[erc20] = cErc20;
        }
    }
}


contract InstaPoolCompoundMapping is Helpers {
    string constant public name = "Instapool-Compound-Mapping-v1";
    constructor(address[] memory ctokens) public {
        address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address cEth = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
        cTokenMapping[ethAddress] = cEth;
        _addCtknMapping(ctokens);
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