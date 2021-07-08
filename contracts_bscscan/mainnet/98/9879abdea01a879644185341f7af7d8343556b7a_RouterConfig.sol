/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

interface IConfigQuery {
    struct ChainConfig {
        string  BlockChain;
        address RouterContract;
        uint64  Confirmations;
        uint64  InitialHeight;
    }

    struct TokenConfig {
        uint8   Decimals;
        address ContractAddress;
        uint256 ContractVersion;
    }

    struct SwapConfig {
        uint256 MaximumSwap;
        uint256 MinimumSwap;
        uint256 BigValueThreshold;
        uint256 SwapFeeRatePerMillion;
        uint256 MaximumSwapFee;
        uint256 MinimumSwapFee;
    }

    struct MultichainToken {
        uint256 ChainID;
        address TokenAddress;
    }

    function getAllChainIDs() external view returns (uint256[] memory);
    function getAllTokenIDs() external view returns (string[] memory);
    function getAllMultichainTokens(string calldata tokenID) external view returns (MultichainToken[] memory);
    function getMultichainToken(string calldata tokenID, uint256 chainID) external view returns (address);
    function getTokenID(uint256 chainID, address tokenAddress) external view returns (string memory);

    function isChainIDExist(uint256 chainID) external view returns (bool);
    function isTokenIDExist(string calldata tokenID) external view returns (bool);

    function getChainConfig(uint256 chainID) external view returns (ChainConfig memory);
    function getTokenConfig(string calldata tokenID, uint256 chainID) external view returns (TokenConfig memory);
    function getUserTokenConfig(string calldata tokenID, uint256 chainID) external view returns (TokenConfig memory);
    function getSwapConfig(string calldata tokenID, uint256 toChainID) external view returns (SwapConfig memory);
    function getCustomConfig(uint256 chainID, string calldata key) external view returns (string memory);
    function getMPCPubkey(address mpcAddress) external view returns (string memory);

    modifier checkChainconfig(ChainConfig memory config) {
        require(config.RouterContract != address(0), "zero router contract");
        require(config.Confirmations > 0, "zero confirmations is unsafe");
        require(bytes(config.BlockChain).length > 0 && bytes(config.BlockChain).length <= 128, "wrong BlockChain length");
        _;
    }

    modifier checkTokenConfig(TokenConfig memory config) {
        require(config.ContractAddress != address(0));
        _;
    }

    modifier checkSwapConfig(SwapConfig memory config) {
        require(config.MaximumSwap > 0, "zero MaximumSwap");
        require(config.MinimumSwap > 0, "zero MinimumSwap");
        require(config.BigValueThreshold > 0, "zero BigValueThreshold");
        require(config.MaximumSwap >= config.MinimumSwap, "MaximumSwap < MinimumSwap");
        require(config.MaximumSwapFee >= config.MinimumSwapFee, "MaximumSwapFee < MinimumSwapFee");
        require(config.MinimumSwap >= config.MinimumSwapFee, "MinimumSwap < MinimumSwapFee");
        require(config.SwapFeeRatePerMillion < 1000000, "SwapFeeRatePerMillion >= 1000000");
        require(config.SwapFeeRatePerMillion > 0 || config.MinimumSwapFee == 0, "wrong MinimumSwapFee");
        _;
    }
}

contract RouterConfig is IConfigQuery {
    uint256[] private _allChainIDs;
    bytes32[] private _allTokenIDs;
    mapping (bytes32 => MultichainToken[]) private _allMultichainTokens; // key is tokenID
    mapping (uint256 => ChainConfig) private _chainConfig; // key is chainID
    mapping (bytes32 => mapping(uint256 => TokenConfig)) private _tokenConfig; // key is tokenID,chainID
    mapping (bytes32 => mapping(uint256 => TokenConfig)) private _userTokenConfig; // key is tokenID,chainID
    mapping (bytes32 => mapping(uint256 => SwapConfig)) private _swapConfig; // key is tokenID,toChainID
    mapping (uint256 => mapping(string => string)) private _customConfig; // key is chainID,customKey
    mapping (uint256 => mapping(address => bytes32)) private _tokenIDMap; // key is chainID,tokenAddress
    mapping (address => string) private _mpcPubkey; // key is mpc address

    address[2] public owners;
    modifier onlyOwner() {
        require(msg.sender == owners[0] || msg.sender == owners[1], "only owner");
        _;
    }

    event UpdateConfig();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Constructor with two owners
    constructor (address[2] memory newOwners) {
        require(newOwners[0] != newOwners[1], "CTOR: owners are same");
        owners = newOwners;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(msg.sender, newOwner);
        if (msg.sender == owners[0]) {
            owners[0] = newOwner;
        } else {
            owners[1] = newOwner;
        }
    }

    function getAllChainIDs() external override view returns (uint256[] memory) {
        return _allChainIDs;
    }

    function getAllTokenIDs() external override view returns (string[] memory result) {
        uint256 length = _allTokenIDs.length;
        result = new string[](length);
        for (uint256 i = 0; i < length; ++i) {
            result[i] = bytes32ToString(_allTokenIDs[i]);
        }
    }

    function getAllMultichainTokens(string calldata tokenID) external override view returns (MultichainToken[] memory) {
        return _allMultichainTokens[stringToBytes32(tokenID)];
    }

    function getMultichainToken(string calldata tokenID, uint256 chainID) public override view returns (address) {
        MultichainToken[] storage _mcTokens = _allMultichainTokens[stringToBytes32(tokenID)];
        for (uint256 i = 0; i < _mcTokens.length; ++i) {
            if (_mcTokens[i].ChainID == chainID) {
                return _mcTokens[i].TokenAddress;
            }
        }
        return address(0);
    }

    function getTokenID(uint256 chainID, address tokenAddress) external override view returns (string memory) {
        return bytes32ToString(_tokenIDMap[chainID][tokenAddress]);
    }

    function getChainConfig(uint256 chainID) external override view returns (ChainConfig memory) {
        return _chainConfig[chainID];
    }

    function getTokenConfig(string calldata tokenID, uint256 chainID) external override view returns (TokenConfig memory) {
        return _tokenConfig[stringToBytes32(tokenID)][chainID];
    }

    function getUserTokenConfig(string calldata tokenID, uint256 chainID) external override view returns (TokenConfig memory) {
        return _userTokenConfig[stringToBytes32(tokenID)][chainID];
    }

    function getSwapConfig(string calldata tokenID, uint256 toChainID) external override view returns (SwapConfig memory) {
        return _swapConfig[stringToBytes32(tokenID)][toChainID];
    }

    function getCustomConfig(uint256 chainID, string calldata key) external override view returns (string memory) {
        return _customConfig[chainID][key];
    }

    function getMPCPubkey(address mpcAddress) external override view returns (string memory) {
        return _mpcPubkey[mpcAddress];
    }

    function isChainIDExist(uint256 chainID) public override view returns (bool) {
        for (uint256 i = 0; i < _allChainIDs.length; ++i) {
            if (_allChainIDs[i] == chainID) {
                return true;
            }
        }
        return false;
    }

    function _isTokenIDExist(bytes32 tokenID) internal view returns (bool) {
        for (uint256 i = 0; i < _allTokenIDs.length; ++i) {
            if (_allTokenIDs[i] == tokenID) {
                return true;
            }
        }
        return false;
    }

    function isTokenIDExist(string calldata tokenID) public override view returns (bool) {
        return _isTokenIDExist(stringToBytes32(tokenID));
    }

    function updateConfig() external onlyOwner {
        emit UpdateConfig();
    }

    function setChainConfig(uint256 chainID, ChainConfig calldata config) external onlyOwner checkChainconfig(config) returns (bool) {
        require(chainID > 0, "zero chainID");
        _chainConfig[chainID] = config;
        if (!isChainIDExist(chainID)) {
            _allChainIDs.push(chainID);
        }
        return true;
    }

    function _setTokenConfig(bytes32 tokenID, uint256 chainID, TokenConfig memory config, bool isUser) internal checkTokenConfig(config) returns (bool) {
        require(tokenID != bytes32(0), "empty tokenID");
        require(chainID > 0, "zero chainID");
        if (isUser) {
            _userTokenConfig[tokenID][chainID] = config;
        } else {
            _tokenConfig[tokenID][chainID] = config;
            if (!_isTokenIDExist(tokenID)) {
                _allTokenIDs.push(tokenID);
            }
            _setMultichainToken(tokenID, chainID, config.ContractAddress);
        }
        return true;
    }

    function _setSwapConfig(bytes32 tokenID, uint256 toChainID, SwapConfig memory config) internal checkSwapConfig(config) returns (bool) {
        require(tokenID != bytes32(0), "empty tokenID");
        require(toChainID > 0, "zero chainID");
        _swapConfig[tokenID][toChainID] = config;
        return true;
    }

    function setTokenConfig(string calldata tokenID, uint256 chainID, TokenConfig calldata config) external onlyOwner returns (bool) {
        return _setTokenConfig(stringToBytes32(tokenID), chainID, config, false);
    }

    function setUserTokenConfig(string calldata tokenID, uint256 chainID, TokenConfig calldata config) external checkTokenConfig(config) returns (bool) {
        return _setTokenConfig(stringToBytes32(tokenID), chainID, config, true);
    }

    function pickUserTokenConfig(string calldata tokenID, uint256 chainID) external onlyOwner returns (bool) {
        bytes32 bsTokenID = stringToBytes32(tokenID);
        return _setTokenConfig(bsTokenID, chainID, _userTokenConfig[bsTokenID][chainID], false);
    }

    function setSwapConfig(string calldata tokenID, uint256 toChainID, SwapConfig calldata config) external onlyOwner returns (bool) {
        return _setSwapConfig(stringToBytes32(tokenID), toChainID, config);
    }

    function setCustomConfig(uint256 chainID, string calldata key, string calldata data) external onlyOwner returns (bool) {
        require(chainID > 0, "zero chainID");
        _customConfig[chainID][key] = data;
        return true;
    }

    function setMPCPubkey(address addr, string calldata pubkey) external onlyOwner returns (bool) {
        require(addr != address(0), "zero address");
        _mpcPubkey[addr] = pubkey;
        return true;
    }

    function addChainID(uint256 chainID) external onlyOwner returns (bool) {
        require(!isChainIDExist(chainID), "chain ID exist");
        _allChainIDs.push(chainID);
        return true;
    }

    function removeChainID(uint256 chainID) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _allChainIDs.length; ++i) {
            if (_allChainIDs[i] == chainID) {
                for (; i+1 < _allChainIDs.length; ++i) {
                    _allChainIDs[i] = _allChainIDs[i+1];
                }
                _allChainIDs.pop();
                return true;
            }
        }
        return false;
    }

    function addTokenID(string calldata tokenID) external onlyOwner returns (bool) {
        bytes32 bsTokenID = stringToBytes32(tokenID);
        require(!_isTokenIDExist(bsTokenID), "token ID exist");
        _allTokenIDs.push(bsTokenID);
        return true;
    }

    function removeTokenID(string calldata tokenID) external onlyOwner returns (bool) {
        bytes32 bsTokenID = stringToBytes32(tokenID);
        for (uint256 i = 0; i < _allTokenIDs.length; ++i) {
            if (_allTokenIDs[i] == bsTokenID) {
                for (; i+1 < _allTokenIDs.length; ++i) {
                    _allTokenIDs[i] = _allTokenIDs[i+1];
                }
                _allTokenIDs.pop();
                return true;
            }
        }
        return false;
    }

    function _setMultichainToken(bytes32 tokenID, uint256 chainID, address token) internal {
        require(tokenID != bytes32(0), "empty tokenID");
        require(chainID > 0, "zero chainID");
        MultichainToken[] storage _mcTokens = _allMultichainTokens[tokenID];
        for (uint256 i = 0; i < _mcTokens.length; ++i) {
            if (_mcTokens[i].ChainID == chainID) {
                address oldToken = _mcTokens[i].TokenAddress;
                if (token != oldToken) {
                    _mcTokens[i].TokenAddress = token;
                    _tokenIDMap[chainID][oldToken] = bytes32(0);
                    _tokenIDMap[chainID][token] = tokenID;
                }
                return;
            }
        }
        _mcTokens.push(MultichainToken(chainID, token));
        _tokenIDMap[chainID][token] = tokenID;
    }

    function setMultichainToken(string calldata tokenID, uint256 chainID, address token) public onlyOwner {
        _setMultichainToken(stringToBytes32(tokenID), chainID, token);
    }

    function removeAllMultichainTokens(string calldata tokenID) external onlyOwner {
        bytes32 bsTokenID = stringToBytes32(tokenID);
        MultichainToken[] storage _mcTokens = _allMultichainTokens[bsTokenID];
        for (uint256 i = 0; i < _mcTokens.length; ++i) {
            MultichainToken memory _mcToken = _mcTokens[i];
            _tokenIDMap[_mcToken.ChainID][_mcToken.TokenAddress] = bytes32(0);
        }
        delete _allMultichainTokens[bsTokenID];
    }

    function removeMultichainToken(string calldata tokenID, uint256 chainID) external onlyOwner returns (bool) {
        MultichainToken[] storage _mcTokens = _allMultichainTokens[stringToBytes32(tokenID)];
        for (uint256 i = 0; i < _mcTokens.length; ++i) {
            if (_mcTokens[i].ChainID == chainID) {
                _tokenIDMap[chainID][_mcTokens[i].TokenAddress] = bytes32(0);
                for (; i+1 < _mcTokens.length; ++i) {
                    _mcTokens[i] = _mcTokens[i+1];
                }
                _mcTokens.pop();
                return true;
            }
        }
        return false;
    }

    function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(str, 32))
        }
    }

    function bytes32ToString(bytes32 data) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && data[i] != 0) {
            ++i;
        }
        bytes memory bs = new bytes(i);
        for (uint8 j = 0; j < i; ++j) {
            bs[j] = data[j];
        }
        return string(bs);
    }
}