pragma solidity >=0.6.6;

import './libraries/ConfigNames.sol';
import './libraries/TransferHelper.sol';
import './modules/TokenRegistry.sol';
import './modules/Ownable.sol';

contract TomiConfig is TokenRegistry, Ownable {
    uint public version = 1;
    event ConfigValueChanged(bytes32 _name, uint _old, uint _value);

    struct Config {
        uint minValue;
        uint maxValue;
        uint maxSpan;
        uint value;
        uint enable;  // 0:disable, 1: enable
    }

    mapping(bytes32 => Config) public configs;
    address public tgas;                                // TGAS contract address
    address public platform;      
    address public dev;                         
    uint public constant PERCENT_DENOMINATOR = 10000;
    uint public constant TGAS_DECIMAL = 10 ** 18;
    address[] public defaultListTokens;

    modifier onlyPlatform() {
        require(msg.sender == platform, 'TomiConfig: ONLY_PLATFORM');
        _;
    }

    constructor()  public {
        _initConfig(ConfigNames.PRODUCE_TGAS_RATE, 1 * TGAS_DECIMAL, 120 * TGAS_DECIMAL, 10 * TGAS_DECIMAL, 40 * TGAS_DECIMAL);
        _initConfig(ConfigNames.SWAP_FEE_PERCENT, 5,30,5,30);
        _initConfig(ConfigNames.LIST_TGAS_AMOUNT, 0, 100000 * TGAS_DECIMAL, 1000 * TGAS_DECIMAL, 0);
        _initConfig(ConfigNames.UNSTAKE_DURATION, 17280, 17280*7, 17280, 17280);
        _initConfig(ConfigNames.REMOVE_LIQUIDITY_DURATION, 0, 17280*7, 17280, 0);
        _initConfig(ConfigNames.TOKEN_TO_TGAS_PAIR_MIN_PERCENT, 20, 500, 10, 100);
        _initConfig(ConfigNames.LIST_TOKEN_FAILURE_BURN_PRECENT, 100, 5000, 500, 1000);
        _initConfig(ConfigNames.LIST_TOKEN_SUCCESS_BURN_PRECENT, 1000, 5000, 500, 5000);
        _initConfig(ConfigNames.PROPOSAL_TGAS_AMOUNT, 100 * TGAS_DECIMAL, 10000 * TGAS_DECIMAL, 100 * TGAS_DECIMAL, 100 * TGAS_DECIMAL);
        _initConfig(ConfigNames.VOTE_DURATION, 17280, 17280*7, 17280, 17280);
        _initConfig(ConfigNames.VOTE_REWARD_PERCENT, 0, 1000, 100, 500);
        _initConfig(ConfigNames.TOKEN_PENGDING_SWITCH, 0, 1, 1, 1);  // 0:off, 1:on
        _initConfig(ConfigNames.TOKEN_PENGDING_TIME, 0, 100*17280, 10*17280, 100*17280);
        _initConfig(ConfigNames.LIST_TOKEN_SWITCH, 0, 1, 1, 0);  // 0:off, 1:on
        _initConfig(ConfigNames.DEV_PRECENT, 1000, 1000, 1000, 1000);

        _initConfig(ConfigNames.FEE_FUNDME_REWARD_PERCENT, 833, 833, 833, 833);  
        _initConfig(ConfigNames.FEE_LOTTERY_REWARD_PERCENT, 833, 833, 833, 833);
    }

    function _initConfig(bytes32 _name, uint _minValue, uint _maxValue, uint _maxSpan, uint _value) internal {
        Config storage config = configs[_name];
        config.minValue = _minValue;
        config.maxValue = _maxValue;
        config.maxSpan = _maxSpan;
        config.value = _value;
        config.enable = 1;
    }

    function initialize(
        address _tgas,
        address _governor,
        address _platform,
        address _dev,
        address[] memory _listTokens) public onlyOwner {
        require(_tgas != address(0), "TomiConfig: ZERO ADDRESS");
        tgas = _tgas;
        platform = _platform;
        dev = _dev;
        for(uint i = 0 ; i < _listTokens.length; i++){
            _updateToken(_listTokens[i], OPENED);
            defaultListTokens.push(_listTokens[i]);
        }
        initGovernorAddress(_governor);
    }

    function modifyGovernor(address _new) public onlyOwner {
        _changeGovernor(_new);
    }

    function modifyDev(address _new) public {
        require(msg.sender == dev, 'TomiConfig: FORBIDDEN');
        dev = _new;
    }

    function changeConfig(bytes32 _name, uint _minValue, uint _maxValue, uint _maxSpan, uint _value) external onlyOwner returns (bool) {
        _initConfig(_name, _minValue, _maxValue, _maxSpan, _value);
        return true;
    }

    function getConfig(bytes32 _name) external view returns (uint minValue, uint maxValue, uint maxSpan, uint value, uint enable) {
        Config memory config = configs[_name];
        minValue = config.minValue;
        maxValue = config.maxValue;
        maxSpan = config.maxSpan;
        value = config.value;
        enable = config.enable;
    }
    
    function getConfigValue(bytes32 _name) public view returns (uint) {
        return configs[_name].value;
    }

    function changeConfigValue(bytes32 _name, uint _value) external onlyGovernor returns (bool) {
        Config storage config = configs[_name];
        require(config.enable == 1, "TomiConfig: DISABLE");
        require(_value <= config.maxValue && _value >= config.minValue, "TomiConfig: OVERFLOW");
        uint old = config.value;
        uint span = _value >= old ? (_value - old) : (old - _value);
        require(span <= config.maxSpan, "TomiConfig: EXCEED MAX ADJUST SPAN");
        config.value = _value;
        emit ConfigValueChanged(_name, old, _value);
        return true;
    }

    function checkToken(address _token) public view returns(bool) {
        if (getConfigValue(ConfigNames.LIST_TOKEN_SWITCH) == 0) {
            return true;
        }
        if (tokenStatus[_token] == OPENED) {
            return true;
        } else if (tokenStatus[_token] == PENDING ) {
            if (getConfigValue(ConfigNames.TOKEN_PENGDING_SWITCH) == 1 && block.number > publishTime[_token] + getConfigValue(ConfigNames.TOKEN_PENGDING_TIME)) {
                return false;
            } else {
                return true;
            }
        }
        return false;
    }

    function checkPair(address tokenA, address tokenB) external view returns (bool) {
        if (checkToken(tokenA) && checkToken(tokenB)) {
            return true;
        }
        return false;
    }

    function getDefaultListTokens() external view returns (address[] memory) {
        address[] memory res = new address[](defaultListTokens.length);
        for (uint i; i < defaultListTokens.length; i++) {
            res[i] = defaultListTokens[i];
        }
        return res;
    }

    function addToken(address _token) external onlyPlatform returns (bool) {
        if(getConfigValue(ConfigNames.LIST_TOKEN_SWITCH) == 0) {
            if(tokenStatus[_token] != OPENED) {
                _updateToken(_token, OPENED);
            }
        }
        return true;
    }

}

pragma solidity >=0.5.16;

library ConfigNames {
    bytes32 public constant PRODUCE_TGAS_RATE = bytes32('PRODUCE_TGAS_RATE');
    bytes32 public constant SWAP_FEE_PERCENT = bytes32('SWAP_FEE_PERCENT');
    bytes32 public constant LIST_TGAS_AMOUNT = bytes32('LIST_TGAS_AMOUNT');
    bytes32 public constant UNSTAKE_DURATION = bytes32('UNSTAKE_DURATION');
    bytes32 public constant REMOVE_LIQUIDITY_DURATION = bytes32('REMOVE_LIQUIDITY_DURATION');
    bytes32 public constant TOKEN_TO_TGAS_PAIR_MIN_PERCENT = bytes32('TOKEN_TO_TGAS_PAIR_MIN_PERCENT');
    bytes32 public constant LIST_TOKEN_FAILURE_BURN_PRECENT = bytes32('LIST_TOKEN_FAILURE_BURN_PRECENT');
    bytes32 public constant LIST_TOKEN_SUCCESS_BURN_PRECENT = bytes32('LIST_TOKEN_SUCCESS_BURN_PRECENT');
    bytes32 public constant PROPOSAL_TGAS_AMOUNT = bytes32('PROPOSAL_TGAS_AMOUNT');
    bytes32 public constant VOTE_DURATION = bytes32('VOTE_DURATION');
    bytes32 public constant VOTE_REWARD_PERCENT = bytes32('VOTE_REWARD_PERCENT');
    bytes32 public constant TOKEN_PENGDING_SWITCH = bytes32('TOKEN_PENGDING_SWITCH');
    bytes32 public constant TOKEN_PENGDING_TIME = bytes32('TOKEN_PENGDING_TIME');
    bytes32 public constant LIST_TOKEN_SWITCH = bytes32('LIST_TOKEN_SWITCH');
    bytes32 public constant DEV_PRECENT = bytes32('DEV_PRECENT');
    bytes32 public constant FEE_GOVERNANCE_REWARD_PERCENT = bytes32('FEE_GOVERNANCE_REWARD_PERCENT');
    bytes32 public constant FEE_LP_REWARD_PERCENT = bytes32('FEE_LP_REWARD_PERCENT');
    bytes32 public constant FEE_FUNDME_REWARD_PERCENT = bytes32('FEE_FUNDME_REWARD_PERCENT');
    bytes32 public constant FEE_LOTTERY_REWARD_PERCENT = bytes32('FEE_LOTTERY_REWARD_PERCENT');
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.16;

contract Governable {
    address public governor;

    event ChangeGovernor(address indexed _old, address indexed _new);

    modifier onlyGovernor() {
        require(msg.sender == governor, 'Governable: FORBIDDEN');
        _;
    }

    // called after deployment
    function initGovernorAddress(address _governor) internal {
        require(_governor != address(0), 'Governable: INPUT_ADDRESS_IS_ZERO');
        governor = _governor;
    }

    function changeGovernor(address _new) public onlyGovernor {
        _changeGovernor(_new);
    }

    function _changeGovernor(address _new) internal {
        require(_new != address(0), 'Governable: INVALID_ADDRESS');
        require(_new != governor, 'Governable: NO_CHANGE');
        address old = governor;
        governor = _new;
        emit ChangeGovernor(old, _new);
    }

}

pragma solidity >=0.5.16;

contract Ownable {
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: FORBIDDEN');
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'Ownable: INVALID_ADDRESS');
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

}

pragma solidity >=0.5.16;

import './Governable.sol';

/**
    Business Process
    step 1. publishToken
    step 2. addToken or removeToken
 */

contract TokenRegistry is Governable {
    mapping (address => uint) public tokenStatus;
    mapping (address => uint) public publishTime;
    uint public tokenCount;
    address[] public tokenList;
    uint public constant NONE = 0;
    uint public constant REGISTERED = 1;
    uint public constant PENDING = 2;
    uint public constant OPENED = 3;
    uint public constant CLOSED = 4;

    event TokenStatusChanged(address indexed _token, uint _status, uint _block);

    function registryToken(address _token) external onlyGovernor returns (bool) {
        return _updateToken(_token, REGISTERED);
    }

    function publishToken(address _token) external onlyGovernor returns (bool) {
        publishTime[_token] = block.number;
        return _updateToken(_token, PENDING);
    }

    function updateToken(address _token, uint _status) external onlyGovernor returns (bool) {
        return _updateToken(_token, _status);
    }

    function validTokens() external view returns (address[] memory) {
        uint count;
        for (uint i; i < tokenList.length; i++) {
            if (tokenStatus[tokenList[i]] == PENDING || tokenStatus[tokenList[i]] == OPENED) {
                count++;
            }
        }
        address[] memory res = new address[](count);
        uint index = 0;
        for (uint i; i < tokenList.length; i++) {
            if (tokenStatus[tokenList[i]] == PENDING || tokenStatus[tokenList[i]] == OPENED) {
                res[index] = tokenList[i];
                index++;
            }
        }
        return res;
    }

    function iterateValidTokens(uint _start, uint _end) external view returns (address[] memory) {
        require(_end <= tokenList.length, "TokenRegistry: OVERFLOW");
        require(_start <= _end && _start >= 0 && _end >= 0, "TokenRegistry: INVAID_PARAMTERS");
        uint count;
        for (uint i = _start; i < _end; i++) {
            if (tokenStatus[tokenList[i]] == PENDING || tokenStatus[tokenList[i]] == OPENED) {
                count++;
            }
        }
        address[] memory res = new address[](count);
        uint index = 0;
        for (uint i = _start; i < _end; i++) {
            if (tokenStatus[tokenList[i]] == PENDING || tokenStatus[tokenList[i]] == OPENED) {
                res[index] = tokenList[i];
                index++;
            }
        }
        return res;
    }

    function _updateToken(address _token, uint _status) internal returns (bool) {
        require(_token != address(0), 'TokenRegistry: INVALID_TOKEN');
        require(tokenStatus[_token] != _status, 'TokenRegistry: TOKEN_STATUS_NO_CHANGE');
        if (tokenStatus[_token] == NONE) {
            tokenCount++;
            require(tokenCount <= uint(-1), 'TokenRegistry: OVERFLOW');
            tokenList.push(_token);
        }
        tokenStatus[_token] = _status;
        emit TokenStatusChanged(_token, _status, block.number);
        return true;
    }

}