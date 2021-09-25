//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStation {
    function mint(address to, uint256 tokenId, string memory _tokenURI, bytes memory _data) external;
    function totalSupply() external view returns (uint256);
}

contract ManufacturerV1 {
    uint256 public constant SALE_LIMIT = 9000;
    uint256 public constant TEAM_LIMIT = 1000;
    uint256 public constant PRICE = 0.08 ether;
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    address public operator;
    uint256 public sold;
    uint256 public teamMinted;
    bool public saleIsActive;
    IStation public station;
    address public stationLabs;
    address public signerAddress;

    constructor(
        address _operator,
        IStation _station,
        address _stationLabs,
        address _signerAddress
    ) {
        operator = _operator;
        station = _station;
        stationLabs = _stationLabs;
        signerAddress = _signerAddress;
    }

    function buy(uint256 _count, bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) public payable {
        require(_count > 0, "Spaceship count cannot be Zero!");
        require(_count <= SALE_LIMIT - sold, "Sale out of stock!");
        require(saleIsActive, "Sale is not active!");
        require(verifyHash(_hash, _v, _r, _s) == signerAddress);
        uint256 amountDue = _count * PRICE;
        require(msg.value == amountDue, "Sent ether is less than the required amount for purchase completion");
        for(uint i=0; i<_count; i++) {
            string memory tokenURI = string(abi.encodePacked("https://station0x.com/api/", addressToString(address(station)), "/", toString(station.totalSupply()), ".json"));
            station.mint(msg.sender, station.totalSupply(), tokenURI, "");
        }
        sold += _count;
    }

    function mintTo(address _to, uint256 _count) public {
        require(msg.sender == operator);
        require(_count <= TEAM_LIMIT - teamMinted);
        require(_count > 0);

        for(uint i=0; i<_count; i++) {
            string memory tokenURI = string(abi.encodePacked("https://station0x.com/api/", addressToString(address(station)), "/", toString(station.totalSupply()), ".json"));
            station.mint(_to, station.totalSupply(), tokenURI, "");
        }
        teamMinted += _count;
    }

    function setSaleStatus(bool _status) public {
        require(msg.sender == operator);
        saleIsActive = _status;
    }

    function setOperator(address _newOperator) public {
        require(msg.sender == operator);
        operator = _newOperator;
        emit SetOperator(_newOperator);
    }

    function addressToString(address _addr) internal pure returns (string memory) {
        uint value = uint256(uint160(_addr));
        uint length = 20;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function verifyHash(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address signer) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
        return ecrecover(messageDigest, _v, _r, _s);
    }

    event SetOperator(address _newOperator);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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