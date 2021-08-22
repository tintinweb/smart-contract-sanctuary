/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// File contracts/IAMB.sol

pragma solidity 0.5.17;

interface IAMB {
    function requireToPassMessage(address _contract, bytes calldata _data, uint256 _gas) external returns (bytes32);
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function messageSourceChainId() external view returns (bytes32);
    function messageId() external view returns (bytes32);
}


// File contracts/IPOH.sol

pragma solidity 0.5.17;

interface IPOH {
    function isRegistered(address _submissionID) external view returns (bool);
}


// File contracts/POHBridge.sol

pragma solidity 0.5.17;


interface IHomePOH {
    function updateProfile(address _human, bool _isRegistered) external;
    function submitHash(bytes32 _dataHash) external;
}

contract POHBridge {
    
    IAMB public amb;
    address public homePOH;
    IPOH public poh;

    constructor(IPOH _poh, IAMB _amb, address _homePOH) public {
        poh = _poh;
        amb = _amb;
        homePOH = _homePOH;
    }
    
    function updateProfile(address _human) external {
        bool isRegistered = poh.isRegistered(_human);
        bytes4 functionSelector = IHomePOH(0).updateProfile.selector;
        bytes memory data = abi.encodeWithSelector(functionSelector, _human, isRegistered);
        amb.requireToPassMessage(homePOH, data, amb.maxGasPerTx());
    }
    
    function updateBatch(address[] calldata _humans) external {
        IPOH _poh = poh;
        uint batchSize = _humans.length;
        bool[] memory isRegistered = new bool[](batchSize);
        for (uint i = 0; i < batchSize; i++) {
            isRegistered[i] = _poh.isRegistered(_humans[i]);
        }

        bytes32 dataHash = keccak256(abi.encodePacked(_humans, isRegistered));
        bytes4 functionSelector = IHomePOH(0).submitHash.selector;
        bytes memory data = abi.encodeWithSelector(functionSelector, dataHash);
        amb.requireToPassMessage(homePOH, data, amb.maxGasPerTx());
    }
    
}