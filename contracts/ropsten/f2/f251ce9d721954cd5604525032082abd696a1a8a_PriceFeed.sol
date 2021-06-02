/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface OracleClient{
    function returnValue(bytes32 requestId) external returns (int256);
    function makeRequest(
        bytes32 providerId,
        bytes32 endpointId,
        uint256 requesterInd,
        address designatedWallet,
        bytes calldata parameters
        )
        external 
        returns (bytes32);
        
}

contract PriceFeed {
   
    bytes32 public providerId;
    bytes32 public endpointId;
    uint256 public requesterInd;
    address public designatedWallet;
    uint256 public blockBuffer;
    OracleClient public oracle;
    bytes32 public Bytes = bytes32("TSLA");
    bytes32 public nameBytes = bytes32("symbol");
    bytes32 public constant paramBytes = bytes32("1b");
    uint256 public priceBlock;
    int256 public price;
    mapping(bytes32 => uint256) public requests;
    bytes private parameters;
    
    
    constructor(address clientAddress, uint256 _blockBuffer, address _designatedWallet, uint256 _requesterInd, bytes32 _endpointId, bytes32 _providerId) public payable {
        oracle = OracleClient(clientAddress);
        blockBuffer = _blockBuffer;
        designatedWallet = _designatedWallet;
        requesterInd = _requesterInd;
        endpointId = _endpointId;
        providerId = _providerId;
        //do these need to cast
       // assetBytes = _assetBytes;
        //nameBytes = bytes32(_nameBytes);
        
    }
    
    function requestOraclePriceFulfillment() public {
        bytes memory parameters = abi.encode(
        bytes32("1b"),
        bytes32("symbol"), 
        bytes32("tsla")
        );
        bytes32 requestId = oracle.makeRequest(providerId, endpointId, requesterInd, designatedWallet, parameters);
        requests[requestId] = block.number;    
        //emit event with requestId here
    }
    // Find a way to make old requests invalid for re updating
    function requestOraclePriceUpdate(bytes32 requestId) public {
        int256 newPrice = oracle.returnValue(requestId);
        price = newPrice;
        priceBlock = requests[requestId];
        //emit event here
    }
    
    function getOraclePrice() public view returns (int256){
        return price;
    }
    
    function isValidPrice() public view returns (bool){
        //this should use safeMath
        if (block.number >= priceBlock + blockBuffer){
            return false;
        }
        else {
            return true;
        }
    }
}