interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}

interface INiftyRegistry {
   function isValidNiftySender(address sending_key) external view returns (bool);
}

contract OmnibusProxy {

	address public _omnibus;

	constructor() {
		_omnibus = 0xBDbAEe6326cF7164EDaf107C525c1928B66d133f; // Rinkeby
        //omnibus = 0xE052113bd7D7700d623414a0a4585BCaE754E9d5; // Mainnet
	}

    modifier onlyValidSender() {
        address registry = 0xCefBf44ff649B6E0Bc63785699c6F1690b8cF73b; // Rinkeby
        //address registry = 0x6e53130dDfF21E3BC963Ee902005223b9A202106; // Mainnet
        require(INiftyRegistry(registry).isValidNiftySender(msg.sender), "NiftyEntity: Invalid msg.sender");
        _;
    }

	function safeTransferFrom721(address contractAddr, uint tokenId) public onlyValidSender {
    	IERC721(contractAddr).safeTransferFrom(_omnibus, msg.sender, tokenId);
	}

	function safeTransferFrom1155(address contractAddr, uint _id, uint256 _value, bytes calldata _data) public onlyValidSender {
    	IERC1155(contractAddr).safeTransferFrom(_omnibus, msg.sender, _id, _value, _data);
	}

	function safeBatchTransferFrom1155(address contractAddr, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) public onlyValidSender {
    	IERC1155(contractAddr).safeBatchTransferFrom(_omnibus, msg.sender, _ids, _values, _data);
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