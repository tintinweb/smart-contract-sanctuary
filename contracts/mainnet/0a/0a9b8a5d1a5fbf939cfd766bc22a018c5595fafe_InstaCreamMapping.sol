pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface CrTokenInterface {
    function underlying() external view returns (address);
}

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

interface IndexInterface {
    function master() external view returns (address);
}

contract Helpers {
    address public constant connectors = 0xD6A602C01a023B98Ecfb29Df02FBA380d3B21E0c;
    address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    uint public version = 1;

    mapping (address => address) public crTokenMapping;

    event LogAddcrTokenMapping(address crToken);
    
    modifier isChief {
        require(
            ConnectorsInterface(connectors).chief(msg.sender) ||
            IndexInterface(instaIndex).master() == msg.sender, "not-Chief");
        _;
    }

    function _addCrtknMapping(address crTkn) internal {
        address cErc20 = crTkn;
        address erc20 = CrTokenInterface(cErc20).underlying();
        require(crTokenMapping[erc20] == address(0), "Token-Already-Added");
        crTokenMapping[erc20] = cErc20;
        emit LogAddcrTokenMapping(crTkn);
    }

    function addCrtknMapping(address[] memory crTkns) public isChief {
        require(crTkns.length > 0, "No-CrToken-length");
        for (uint i = 0; i < crTkns.length; i++) {
            _addCrtknMapping(crTkns[i]);
        }
    }
}


contract InstaCreamMapping is Helpers {
    constructor(address[] memory crTkns) public {
        address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address crEth = 0xD06527D5e56A3495252A528C4987003b712860eE;
        crTokenMapping[ethAddress] = crEth;
        for (uint i = 0; i < crTkns.length; i++) {
            _addCrtknMapping(crTkns[i]);
        }
    }

    string constant public name = "Cream-finance-v1.0";
}