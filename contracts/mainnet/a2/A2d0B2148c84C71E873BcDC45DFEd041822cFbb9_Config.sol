pragma solidity >=0.8.0;

import "./interfaces/IConfig.sol";

contract Config is IConfig {
    event InvestTokensUpdated(address indexed from, address[] tokens, uint256[] amounts);

    event AddressConfigUpdated(address indexed from, uint256[] indexed keys, address[] values);

    event UintConfigUpdated(address indexed from, uint256[] indexed keys, uint256[] values);

    event FUND_CREATED(address indexed fund);

    event FUND_UPDATED(address indexed fund);

    event PFUND_CREATED(address indexed fund);

    event PFUND_UPDATED(address indexed fund);

    event STAKE_CREATED(address indexed stake);

    event STAKE_UPDATED(address indexed stake);

    event REG_CREATED(address indexed owner);

    event REG_UPDATED(address indexed owner);

    address public override protocolToken; // 1

    address public override protocolPool; // 2

    address public override nameRegistry; // 3

    address public override feeTo; // 4

    address public override ceo; // 5

    uint256 public override investFeeRate; // 6

    uint256 public override redeemFeeRate; // 7

    uint256 public override claimFeeRate; // 8

    uint256 public override poolCreationRate; // 9

    uint256 public override slot0; // 10

    uint256 public override slot1; // 11

    uint256 public override slot2; // 12

    uint256 public override slot3; // 13

    uint256 public override slot4; // 14

    mapping(address => uint256) public override tokenMinFundSize; // token -> minimal invest amount, unsupport it if amount == 0

    address[] public tokens; // all tokens

    modifier onlyCEO() {
        require(msg.sender == ceo, "only CEO");
        _;
    }

    constructor() {
        ceo = msg.sender;
    }

    function updateAddressConfigs(uint256[] memory _keys, address[] memory _values) external onlyCEO() {
        require(_keys.length == _values.length, "keys length != values length");
        for (uint256 i = 0; i < _keys.length; i++) {
            require(_values[i] != address(0), "zero address");
            uint256 key = _keys[i];
            if (key == 1) {
                protocolToken = _values[i];
            } else if (key == 2) {
                protocolPool = _values[i];
            } else if (key == 3) {
                nameRegistry = _values[i];
            } else if (key == 4) {
                feeTo = _values[i];
            } else if (key == 5) {
                ceo = _values[i];
            } else {
                require(false, "unsupport key");
            }
        }
        emit AddressConfigUpdated(msg.sender, _keys, _values);
    }

    function updateUintConfigs(uint256[] memory _keys, uint256[] memory _values) external onlyCEO() {
        require(_keys.length == _values.length, "keys length != values length");
        for (uint256 i = 0; i < _keys.length; i++) {
            uint256 key = _keys[i];
            if (key == 6) {
                investFeeRate = _values[i];
            } else if (key == 7) {
                redeemFeeRate = _values[i];
            } else if (key == 8) {
                claimFeeRate = _values[i];
            } else if (key == 9) {
                poolCreationRate = _values[i];
            } else if (key == 10) {
                slot0 = _values[i];
            } else if (key == 11) {
                slot1 = _values[i];
            } else if (key == 12) {
                slot2 = _values[i];
            } else if (key == 13) {
                slot3 = _values[i];
            } else if (key == 14) {
                slot4 = _values[i];
            } else {
                require(false, "unsupport key");
            }
        }
        emit UintConfigUpdated(msg.sender, _keys, _values);
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function updateInvestTokens(address[] memory _tokens, uint256[] memory _amounts) external onlyCEO() {
        require(_tokens.length > 1, "tokens length <= 1");
        require(_tokens.length == _amounts.length, "tokens length != _amounts length");
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenMinFundSize[tokens[i]] = 0;
        }
        delete tokens;

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), "ZERO_ADDRESS");
            require(_amounts[i] > 0, "amount is zero");
            require(tokenMinFundSize[_tokens[i]] == 0, "token exist");
            tokenMinFundSize[_tokens[i]] = _amounts[i];
        }
        tokens = _tokens;
        emit InvestTokensUpdated(msg.sender, _tokens, _amounts);
    }

    function notify(EventType _type, address _src) external override {
        if (_type == EventType.FUND_CREATED) {
            emit FUND_CREATED(_src);
        } else if (_type == EventType.FUND_UPDATED) {
            emit FUND_UPDATED(_src);
        } else if (_type == EventType.STAKE_CREATED) {
            emit STAKE_CREATED(_src);
        } else if (_type == EventType.STAKE_UPDATED) {
            emit STAKE_UPDATED(_src);
        } else if (_type == EventType.REG_CREATED) {
            emit REG_CREATED(_src);
        } else if (_type == EventType.REG_UPDATED) {
            emit REG_UPDATED(_src);
        } else if (_type == EventType.PFUND_CREATED) {
            emit PFUND_CREATED(_src);
        } else if (_type == EventType.PFUND_UPDATED) {
            emit PFUND_UPDATED(_src);
        }
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