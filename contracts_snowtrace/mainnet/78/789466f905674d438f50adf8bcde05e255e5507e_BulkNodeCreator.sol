/**
 *Submitted for verification at snowtrace.io on 2021-12-20
*/

interface Token {
    function transferFrom(address from, address to, uint value) external;
}

interface NodeManager {
    function createNode(address account, string memory nodeName) external;
}

contract BulkNodeCreator {
    NodeManager manager;
    Token token;
	
	uint256 pricePerNode = 10 ** 18 / 5;
	address owner;

    constructor(address tokenAddr, address managerAddr) {
        manager = NodeManager(managerAddr);
        token = Token(tokenAddr);
		owner = msg.sender;
    }
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

    function createBulkNodes(uint nodesAmount, string calldata baseName) external {
        token.transferFrom(msg.sender, address(token), pricePerNode * nodesAmount);

        for (uint256 i = 0; i < nodesAmount; i++) {
            manager.createNode(msg.sender, string(abi.encodePacked(baseName, uint2str(i))));
        }
    }
	
	function changePricePerNode(uint256 newPrice) external onlyOwner {
		pricePerNode = newPrice;
	}

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}