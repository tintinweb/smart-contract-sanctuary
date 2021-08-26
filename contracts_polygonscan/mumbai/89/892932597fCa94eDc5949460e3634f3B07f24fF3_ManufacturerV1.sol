//SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

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
    IERC20 public saleToken;
    uint256 public sold;
    uint256 public teamMinted;
    bool public saleIsActive;

    IStation public station;
    address public stationLabs;

    constructor(
        address _operator,
        IERC20 _saleToken,
        IStation _station,
        address _stationLabs
    ) {
        operator = _operator;
        saleToken = _saleToken;
        station = _station;
        stationLabs = _stationLabs;
    }

    function buy(uint256 count) public {
        require(count > 0, "Spaceship count cannot be Zero!");
        require(count <= SALE_LIMIT - sold, "Sale out of stock!");
        require(saleIsActive, "Sale is not active!");
        
        uint256 amountDue = count * PRICE;
        uint256 balanceBefore = saleToken.balanceOf(stationLabs);
        saleToken.transferFrom(msg.sender, stationLabs, amountDue);
        uint256 balanceAfter = saleToken.balanceOf(stationLabs);
        require(balanceAfter - balanceBefore == amountDue);

        for(uint i=0; i<count; i++) {
            string memory tokenURI = string(abi.encodePacked("https://station0x.com/api/", addressToString(address(station)), "/", toString(station.totalSupply()), ".json"));
            station.mint(msg.sender, station.totalSupply(), tokenURI, "");
        }

        sold += count;
    }

    function mintTo(address to, uint256 count) public {
        require(msg.sender == operator);
        require(count <= TEAM_LIMIT - teamMinted);
        require(count > 0);

        for(uint i=0; i<count; i++) {
            string memory tokenURI = string(abi.encodePacked("https://station0x.com/api/", addressToString(address(station)), "/", toString(station.totalSupply()), ".json"));
            station.mint(to, station.totalSupply(), tokenURI, "");
        }

        teamMinted += count;

    }

    function setSaleStatus(bool status) public {
        require(msg.sender == operator);
        saleIsActive = status;
    }

    function setOperator(address _newOperator) public {
        require(msg.sender == operator);
        operator = _newOperator;
        emit SetOperator(_newOperator);
    }

    function addressToString(address addr) internal pure returns (string memory) {
        uint value = uint256(uint160(addr));
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