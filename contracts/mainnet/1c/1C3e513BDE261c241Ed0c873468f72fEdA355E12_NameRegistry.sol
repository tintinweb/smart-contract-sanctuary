pragma solidity >=0.8.0;

import "./Base.sol";

contract NameRegistry is Base {
    event OwnerTransfered(address indexed from, address owner);

    event NameRegistered(address indexed from, string name, string url);

    event UrlChanged(address indexed from, string url);

    uint256 public PRICE;

    mapping(bytes32 => address) private getAddress;

    mapping(address => bytes32) private addressToName;
    mapping(address => string) private addressToUrl;
    address[] private registers;

    constructor(address _config, uint256 _price) Base(_config) {
        require(_price > 0, "price == 0");
        PRICE = _price;
    }

    function register(string memory _name, string memory _url)
        external
        payable
    {
        require(msg.value == PRICE, "ether amount != price");
        address manager = msg.sender;
        bytes32 name = strToB32(_name);
        address nameOwner = getAddress[name];
        require(nameOwner == address(0), "name registered");

        bool newRegister = addressToName[manager] == bytes32(0);

        addressToName[manager] = name;
        addressToUrl[manager] = _url;
        getAddress[name] = manager;

        if (newRegister) {
            // new register
            registers.push(msg.sender);
            config.notify(IConfig.EventType.REG_CREATED, manager);
        } else {
            config.notify(IConfig.EventType.REG_UPDATED, manager);
        }
        emit NameRegistered(msg.sender, _name, _url);
    }

    function isRegistered(address _owner) external view returns (bool) {
        return addressToName[_owner] != bytes32(0);
    }

    function getName(address _addr) external view returns (string memory) {
        return b32ToStr(addressToName[_addr]);
    }

    function getUrl(address _addr) external view returns (string memory) {
        return addressToUrl[_addr];
    }

    function setUrl(string memory _url) external {
        require(addressToName[msg.sender] != 0x0, "not registered");
        addressToUrl[msg.sender] = _url;
        config.notify(IConfig.EventType.REG_UPDATED, msg.sender);
    }

    function registerCount() external view returns (uint256) {
        return registers.length;
    }

    function getRegisters() external view returns (address[] memory) {
        return registers;
    }

    bool locker = false;

    function transfer(address payable _to) external onlyCEO() {
        require(_to != address(0), "Zero_Address");
        require(!locker, "locked");
        locker = true;
        _to.transfer(address(this).balance);
        locker = false;
    }

    function updateFee(uint256 _newFee) external onlyCEO() {
        PRICE = _newFee;
    }

    function strToB32(string memory _name)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory b = bytes(_name);
        require(b.length > 0 && b.length <= 32, "Exceed_32_Bytes");

        assembly {
            result := mload(add(_name, 32))
        }
    }

    function b32ToStr(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}

pragma solidity >=0.8.0;

import "./interfaces/IConfig.sol";

contract Base {
    event ConfigUpdated(address indexed owner, address indexed config);

    IConfig internal config;

    modifier onlyCEO() {
        require(msg.sender == config.ceo(), "only CEO");
        _;
    }

    constructor(address _configAddr) {
        require(_configAddr != address(0), "config address = 0");
        config = IConfig(_configAddr);
    }

    function updateConfig(address _config) external onlyCEO() {
        require(_config != address(0), "config address = 0");
        require(address(config) != _config, "address identical");
        config = IConfig(_config);
        emit ConfigUpdated(msg.sender, _config);
    }

    function configAddress() external view returns (address) {
        return address(config);
    }

    function getConfig() external view returns (IConfig) {
        return config;
    }
}

pragma solidity >=0.8.0;

interface IConfig {
    enum EventType {FUND_CREATED, FUND_UPDATED, STAKE_CREATED, STAKE_UPDATED, REG_CREATED, REG_UPDATED, PFUND_CREATED, PFUND_UPDATED}

    function ceo() external view returns (address);

    function protocolPool() external view returns (address);

    function protocolToken() external view returns (address);

    function feeTo() external view returns (address);

    function nameRegistry() external view returns (address);

    //  function investTokenWhitelist() external view returns (address[] memory);

    function tokenMinFundSize(address token) external view returns (uint256);

    function investFeeRate() external view returns (uint256);

    function redeemFeeRate() external view returns (uint256);

    function claimFeeRate() external view returns (uint256);

    function poolCreationRate() external view returns (uint256);

    function slot0() external view returns (uint256);

    function slot1() external view returns (uint256);

    function slot2() external view returns (uint256);

    function slot3() external view returns (uint256);

    function slot4() external view returns (uint256);

    function notify(EventType _type, address _src) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2000
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