/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IV2Strategy {
    function name() external view returns (string memory);

    function apiVersion() external view returns (string memory);

    function strategist() external view returns (address);

    function rewards() external view returns (address);

    function vault() external view returns (address);

    function keeper() external view returns (address);

    function want() external view returns (address);

    function emergencyExit() external view returns (bool);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);
    
    function doHealthCheck() external view returns (bool);
    
    function healthCheck() external view returns (address);
}

interface IAddressesGenerator {
    function assetsAddresses() external view returns (address[] memory);
}

interface IV2Vault {
    function withdrawalQueue(uint256 arg0) external view returns (address);
}

interface IAddressMergeHelper {
    function mergeAddresses(address[][] memory addressesSets)
        external
        view
        returns (address[] memory);
}

interface IERC20 {
    function decimals() external view returns (uint8);
    
    function symbol() external view returns (string memory);
}

interface IOracle {
    function getNormalizedValueUsdc(
        address tokenAddress,
        uint256 amount,
        uint256 priceUsdc
    ) external view returns (uint256);
    
    function getPriceUsdcRecommended(
        address tokenAddress
    ) external view returns (uint256);
}

contract StrategiesHelper {
    address public addressesGeneratorAddress;
    address public addressesMergeHelperAddress;
    address public oracleAddress;
    address public ownerAddress;

    struct StrategyMetadata {
        string name;
        address id;
        string apiVersion;
        address strategist;
        address rewards;
        address vault;
        address keeper;
        address want;
        uint256 wantPriceUsdc;
        uint8 wantDecimals;
        string wantSymbol;
        bool emergencyExit;
        bool isActive;
        uint256 delegatedAssets;
        uint256 estimatedTotalAssets;
        uint256 estimatedTotalAssetsUsdc;
        bool doHealthCheck;
        address healthCheckAddress;
    }

    constructor(address _addressesGeneratorAddress, address _addressesMergeHelperAddress, address _oracleAddress) {
        addressesGeneratorAddress = _addressesGeneratorAddress;
        addressesMergeHelperAddress = _addressesMergeHelperAddress;
        oracleAddress = _oracleAddress;
        ownerAddress = msg.sender;
    }

    /**
     * Fetch the number of strategies for a vault
     */
    function assetStrategiesLength(address assetAddress)
        public
        view
        returns (uint256)
    {
        IV2Vault vault = IV2Vault(assetAddress);
        uint256 strategyIdx;
        while (true) {
            address strategyAddress = vault.withdrawalQueue(strategyIdx);
            if (strategyAddress == address(0)) {
                break;
            }
            strategyIdx++;
        }
        return strategyIdx;
    }

    /**
     * Fetch the total number of strategies for all vaults
     */
    function assetsStrategiesLength() public view returns (uint256) {
        return assetsStrategiesAddresses().length;
    }

    /**
     * Fetch strategy addresses given a vault address
     */
    function assetStrategiesAddresses(address assetAddress)
        public
        view
        returns (address[] memory)
    {
        IV2Vault vault = IV2Vault(assetAddress);
        uint256 numberOfStrategies = assetStrategiesLength(assetAddress);
        address[] memory _strategiesAddresses =
            new address[](numberOfStrategies);
        for (
            uint256 strategyIdx = 0;
            strategyIdx < numberOfStrategies;
            strategyIdx++
        ) {
            address strategyAddress = vault.withdrawalQueue(strategyIdx);
            _strategiesAddresses[strategyIdx] = strategyAddress;
        }
        return _strategiesAddresses;
    }

    /**
     * Fetch all strategy addresses for all vaults
     */
     function assetsStrategiesAddresses() public view returns (address[] memory) {
        address[] memory _assetsAddresses = IAddressesGenerator(addressesGeneratorAddress).assetsAddresses();
        return assetsStrategiesAddresses(_assetsAddresses);
     }
     
    /**
     * Convert an ASCII string to a number given a string and a base
     */
    function atoi(string memory a, uint8 base) internal pure returns (uint256 i) {
        require(base == 2 || base == 8 || base == 10 || base == 16);
        bytes memory buf = bytes(a);
        for (uint256 p = 0; p < buf.length; p++) {
            uint8 digit = uint8(buf[p]) - 0x30;
            if (digit > 10) {
                digit -= 7;
            }
            require(digit < base);
            i *= base;
            i += digit;
        }
        return i;
    }
    
    /**
     * Check to see if two strings are exactly equal
     */
    function stringsEqual(string memory input1, string memory input2) internal pure returns (bool) {
        bytes32 input1Bytes32;
        bytes32 input2Bytes32;
        assembly {
            input1Bytes32 := mload(add(input1, 32))
            input2Bytes32 := mload(add(input2, 32))
        }
        return input1Bytes32 == input2Bytes32;
    }

    /**
     * Fetch strategy addresses by filter
     */
     function assetsStrategiesAddressesByFilter(string[][] memory filter) public view returns (address[] memory) {
        address[] memory _assetsStrategiesAddresses =
            assetsStrategiesAddresses();
        return assetsStrategiesAddressesByFilter(_assetsStrategiesAddresses, filter);
    }
    
    /**
     * Fetch strategy addresses by filter
     */
    function assetsStrategiesAddressesByFilter(address[] memory _strategiesAddresses, string[][] memory filter) public view returns (address[] memory) {
        uint256 numberOfStrategies = _strategiesAddresses.length;
        uint256 numberOfFilteredStrategies;
        for (
            uint256 strategyIdx = 0;
            strategyIdx < numberOfStrategies;
            strategyIdx++
        ) {
            address strategyAddress = _strategiesAddresses[strategyIdx];
            if (strategyPassesFilter(strategyAddress, filter)) {
                _strategiesAddresses[numberOfFilteredStrategies] = strategyAddress;
                numberOfFilteredStrategies++;
            }
        }
        bytes memory encodedAddresses = abi.encode(_strategiesAddresses);
        assembly {
            mstore(add(encodedAddresses, 0x40), numberOfFilteredStrategies)
        }
        address[] memory filteredAddresses =
            abi.decode(encodedAddresses, (address[]));
        return filteredAddresses;
     }

    /**
     * Fetch all strategy addresses given an array of vaults
     */
    function assetsStrategiesAddresses(address[] memory _assetsAddresses)
        public
        view
        returns (address[] memory)
    {
        uint256 numberOfAssets = _assetsAddresses.length;
        address[][] memory _strategiesForAssets =
            new address[][](numberOfAssets);
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            address[] memory _assetStrategiessAddresses =
                assetStrategiesAddresses(assetAddress);
            _strategiesForAssets[assetIdx] = _assetStrategiessAddresses;
        }
        address[] memory mergedAddresses =
            IAddressMergeHelper(addressesMergeHelperAddress).mergeAddresses(_strategiesForAssets);
        return mergedAddresses;
    }

    /**
     * Fetch total delegated balance for all strategies
     */
    function assetsStrategiesDelegatedBalance()
        external
        view
        returns (uint256)
    {
        address[] memory _assetsAddresses = IAddressesGenerator(addressesGeneratorAddress).assetsAddresses();
        uint256 numberOfAssets = _assetsAddresses.length;
        uint256 assetsDelegatedBalance;
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            uint256 assetDelegatedBalance =
                assetStrategiesDelegatedBalance(assetAddress);
            assetsDelegatedBalance += assetDelegatedBalance;
        }
        return assetsDelegatedBalance;
    }

    /**
     * Fetch delegated balance for all of a vault's strategies
     */
    function assetStrategiesDelegatedBalance(address assetAddress)
        public
        view
        returns (uint256)
    {
        address[] memory _assetStrategiesAddresses =
            assetStrategiesAddresses(assetAddress);
        uint256 numberOfStrategies = _assetStrategiesAddresses.length;
        uint256 strategiesDelegatedBalance;
        for (
            uint256 strategyIdx = 0;
            strategyIdx < numberOfStrategies;
            strategyIdx++
        ) {
            address strategyAddress = _assetStrategiesAddresses[strategyIdx];
            IV2Strategy _strategy = IV2Strategy(strategyAddress);
            uint256 strategyDelegatedBalance = _strategy.delegatedAssets();
            strategiesDelegatedBalance += strategyDelegatedBalance;
        }
        return strategiesDelegatedBalance;
    }

    /**
     * Fetch metadata for all strategies scoped to a vault
     */
    function assetStrategies(address assetAddress)
        external
        view
        returns (StrategyMetadata[] memory)
    {
        IV2Vault vault = IV2Vault(assetAddress);
        uint256 numberOfStrategies = assetStrategiesLength(assetAddress);
        StrategyMetadata[] memory _strategies =
            new StrategyMetadata[](numberOfStrategies);
        for (
            uint256 strategyIdx = 0;
            strategyIdx < numberOfStrategies;
            strategyIdx++
        ) {
            address strategyAddress = vault.withdrawalQueue(strategyIdx);
            StrategyMetadata memory _strategy = strategy(strategyAddress);
            _strategies[strategyIdx] = _strategy;
        }
        return _strategies;
    }

    /**
     * Fetch metadata for all strategies
     */
    function assetsStrategies()
        external
        view
        returns (StrategyMetadata[] memory)
    {
        address[] memory _assetsStrategiesAddresses =
            assetsStrategiesAddresses();
        return strategies(_assetsStrategiesAddresses);
    }
    
    /**
     * Fetch metadata for all strategies
     */
    function assetsStrategiesByFilter(string[][] memory _filter)
        external
        view
        returns (StrategyMetadata[] memory)
    {
        address[] memory _assetsStrategiesAddresses =
            assetsStrategiesAddressesByFilter(_filter);
        return strategies(_assetsStrategiesAddresses);
    }
    
    /**
     * Fetch metadata for strategies given an array of vault addresses
     */
    function assetsStrategies(address[] memory _assetsAddresses)
        public
        view
        returns (StrategyMetadata[] memory)
    {
        return strategies(assetsStrategiesAddresses(_assetsAddresses));
    }
    
    /**
     * Fetch metadata for strategies given an array of vault addresses and a filter
     */
    function assetsStrategiesByFilter(address[] memory _assetsAddresses, string[][] memory _filter)
        public
        view
        returns (StrategyMetadata[] memory)
    {
        return strategies(assetsStrategiesAddressesByFilter(_assetsAddresses, _filter));
    }
    
    /**
     * Fetch metadata for a strategy given a strategy address
     */
    function strategy(address strategyAddress)
        public
        view
        returns (StrategyMetadata memory)
    {
        IV2Strategy _strategy = IV2Strategy(strategyAddress);
        IOracle _oracle = IOracle(oracleAddress);
        bool _doHealthCheck;
        address _healthCheckAddress;
        address _wantAddress = _strategy.want();
        IERC20 _want = IERC20(_wantAddress);
        uint256 _wantPriceUsdc = _oracle.getPriceUsdcRecommended(_wantAddress);
        uint256 _estimatedTotalAssets = _strategy.estimatedTotalAssets();
        try _strategy.doHealthCheck() {
            _doHealthCheck = _strategy.doHealthCheck();
        } catch {}
        try _strategy.healthCheck() {
             _healthCheckAddress = _strategy.healthCheck();
        } catch {}
        return
            StrategyMetadata({
                name: _strategy.name(),
                id: strategyAddress,
                apiVersion: _strategy.apiVersion(),
                strategist: _strategy.strategist(),
                rewards: _strategy.rewards(),
                vault: _strategy.vault(),
                keeper: _strategy.keeper(),
                want: _wantAddress,
                wantPriceUsdc: _wantPriceUsdc,
                wantDecimals: _want.decimals(),
                wantSymbol: _want.symbol(),
                emergencyExit: _strategy.emergencyExit(),
                isActive: _strategy.isActive(),
                delegatedAssets: _strategy.delegatedAssets(),
                estimatedTotalAssets: _estimatedTotalAssets,
                estimatedTotalAssetsUsdc: _oracle.getNormalizedValueUsdc(_wantAddress, _estimatedTotalAssets, _wantPriceUsdc),
                doHealthCheck: _doHealthCheck,
                healthCheckAddress: _healthCheckAddress
            });
    }

    /**
     * Fetch metadata for strategies given an array of strategy addresses
     */
    function strategies(address[] memory _strategiesAddresses)
        public
        view
        returns (StrategyMetadata[] memory)
    {
        uint256 numberOfStrategies = _strategiesAddresses.length;
        StrategyMetadata[] memory _strategies =
            new StrategyMetadata[](numberOfStrategies);
        for (
            uint256 strategyIdx = 0;
            strategyIdx < numberOfStrategies;
            strategyIdx++
        ) {
            address strategyAddress = _strategiesAddresses[strategyIdx];
            StrategyMetadata memory _strategy = strategy(strategyAddress);
            _strategies[strategyIdx] = _strategy;
        }
        return _strategies;
    }
    
    /**
     * Filter a strategy using a reverse polish notation (RPM) query language
     *
     * Each instruction is a tuple of either two or three strings.
     *
     * Argument 0 - Operand type
     * -------------------------
     * KEY      - Denotes a value should be fetched using a function sighash derived from argument 1
     * VALUE    - A value to be added directly to the stack
     * OPERATOR - The name of the instruction to execute
     *
     * Argument 1 - Key/Value or operator
     * ----------------------------------
     * Data     - If KEY or VALUE are specified in argument 0, argument 1 represents either the key
     *            to fetch data with or the value to be added to the stack
     * Operator - If OPERATOR is specified in argument 0, argument 1 represents the operator to execute.
     *            Valid operators are: EQ, GT, GTE, LT, LTE, OR, AND, NE and LIKE
     *
     * Argument 2 - Value type
     * -----------------------
     * For key/value operands argument 2 describes how to parse a value to be placed on the stack.
     * Valid options are: STRING, HEX, DECIMAL
     *
     * Note: The stack size is 32 bytes. Any values beyond this will be truncated.
     *
     * Example Filter
     * ==============
     * Description: Find all strategies whose apiVersion is like 0.3.5 or 0.3.3
     *              where strategist address is C3D6880fD95E06C816cB030fAc45b3ffe3651Cb0
     * filter = [
     *     ["KEY",        "apiVersion", "STRING"],
     *     ["VALUE",      "0.3.5", "STRING"],
     *     ["OPERATOR",   "LIKE"],
     *     ["KEY",        "apiVersion", "STRING"],
     *     ["VALUE",      "0.3.3", "STRING"],
     *     ["OPERATOR",   "LIKE"],
     *     ["OPERATOR",   "OR"],
     *     ["KEY",        "strategist", "HEX"],
     *     ["VALUE",      "C3D6880fD95E06C816cB030fAc45b3ffe3651Cb0", "HEX"],
     *     ["OPERATOR",   "EQ"],
     *     ["OPERATOR",   "AND"]
     * ];
     */
    function strategyPassesFilter(address strategyAddress, string[][] memory instructions) public view returns (bool) {
        bytes32[] memory stack = new bytes32[](instructions.length * 3);
        uint256 stackLength;
        for (uint256 instructionsIdx; instructionsIdx < instructions.length; instructionsIdx++) {
            string[] memory instruction = instructions[instructionsIdx];
            string memory instructionPart1 = instruction[1];
            bool operandIsOperator = stringsEqual(instruction[0], "OPERATOR");
            if (operandIsOperator) {
                bool result;
                bytes32 operandTwo = stack[stackLength - 1];
                bytes32 operandOne = stack[stackLength - 2];
                if (stringsEqual(instruction[1], "EQ")) {
                    result = uint256(operandTwo) == uint256(operandOne);
                }
                if (stringsEqual(instruction[1], "NE")) {
                    result = uint256(operandTwo) != uint256(operandOne);
                }
                if (stringsEqual(instruction[1], "GT")) {
                    result = uint256(operandTwo) > uint256(operandOne);
                }
                if (stringsEqual(instruction[1], "GTE")) {
                    result = uint256(operandTwo) >= uint256(operandOne);
                }
                if (stringsEqual(instruction[1], "LT")) {
                    result = uint256(operandTwo) < uint256(operandOne);
                }
                if (stringsEqual(instruction[1], "LTE")) {
                    result = uint256(operandTwo) <= uint256(operandOne);
                }
                if (stringsEqual(instruction[1], "AND")) {
                    result = uint256(operandTwo & operandOne) == 1;
                }
                if (stringsEqual(instruction[1], "OR")) {
                    result = uint256(operandTwo | operandOne) == 1;
                }
                if (stringsEqual(instruction[1], "LIKE")) {
                    string memory haystack = String.bytes32ToString(operandOne);
                    string memory needle = String.bytes32ToString(operandTwo);
                    result = String.contains(haystack, needle);
                }
                if (result) {
                    stack[stackLength - 2] = bytes32(uint256(1));
                } else {
                    stack[stackLength - 2] = bytes32(uint256(0));
                }
                stackLength--;
            } else {
                bytes32 stackItem;
                bool operandIsKey = stringsEqual(instruction[0], "KEY");
                bytes memory data;
                if (operandIsKey) {
                    (, bytes memory matchBytes) =
                        address(strategyAddress).staticcall(abi.encodeWithSignature(string(abi.encodePacked(instruction[1], "()"))));
                    data = matchBytes;
                }
                if (stringsEqual(instruction[2], "HEX")) {
                    if (operandIsKey == true) {
                        assembly {
                            stackItem := mload(add(data, 0x20))
                        }
                    } else {
                        stackItem = bytes32(atoi(String.uppercase(instruction[1]), 16));
                    }
                } else if (stringsEqual(instruction[2], "STRING")) {
                    if (operandIsKey == true) {
                        assembly {
                            stackItem := mload(add(data, 0x60))
                        }
                    } else {
                        assembly {
                            stackItem := mload(add(instructionPart1, 0x20))
                        }                        
                    }
                } else if (stringsEqual(instruction[2], "DECIMAL")) {
                    if (operandIsKey == true) {
                        assembly {
                            stackItem := mload(add(data, 0x20))
                        }
                    } else {
                        stackItem = bytes32(atoi(instruction[1], 10));
                    }
                }
                stack[stackLength] = stackItem;
                stackLength++;
            }
        }
        if (uint256(stack[0]) == 1) {
            return true;
        }
        return false;
    }
    
    /**
     * Allow storage slots to be manually updated
     */
    function updateSlot(bytes32 slot, bytes32 value) external {
        require(msg.sender == ownerAddress, "Caller is not the owner");
        assembly {
            sstore(slot, value)
        }
    }
}

library String {
    /**
     * Convert a string to lowercase
     */
    function lowercase(string memory input) internal pure returns (string memory) {
        bytes memory _input = bytes(input);
        for (uint inputIdx = 0; inputIdx < _input.length; inputIdx++) {
            uint8 character = uint8(_input[inputIdx]);
            if (character >= 65 && character <= 90) {
                character += 0x20;
                _input[inputIdx] = bytes1(character);
            }
        }
        return string(_input);
    }

    /**
     * Convert a string to uppercase
     */
    function uppercase(string memory input) internal pure returns (string memory) {
        bytes memory _input = bytes(input);
        for (uint inputIdx = 0; inputIdx < _input.length; inputIdx++) {
            uint8 character = uint8(_input[inputIdx]);
            if (character >= 97 && character <= 122) {
                character -= 0x20;
                _input[inputIdx] = bytes1(character);
            }
        }
        return string(_input);
    }

    /**
     * Search for a needle in a haystack
     */
    function contains(string memory haystack, string memory needle) internal pure returns (bool) {
        return indexOf(needle, haystack) >= 0;
    }
    
    /**
     * Convert bytes32 to string and remove padding
     */
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /**
     * Case insensitive string search
     *
     * @param needle The string to search for
     * @param haystack The string to search in
     * @return Returns -1 if no match is found, otherwise returns the index of the match 
     */
    function indexOf(string memory needle, string memory haystack) internal pure returns (int256) {
        bytes memory _needle = bytes(lowercase(needle));
        bytes memory _haystack = bytes(lowercase(haystack));
        if (_haystack.length < _needle.length) {
            return -1;
        }
        bool _match;
        for (uint256 haystackIdx; haystackIdx < _haystack.length; haystackIdx++) {
            for (uint256 needleIdx; needleIdx < _needle.length; needleIdx++) {
                uint8 needleChar = uint8(_needle[needleIdx]);
                if (haystackIdx + needleIdx >= _haystack.length) {
                    return -1;
                }
                uint8 haystackChar = uint8(_haystack[haystackIdx + needleIdx]);
                if (needleChar == haystackChar) {
                    _match = true;
                    if (needleIdx == _needle.length - 1) {
                        return int(haystackIdx);
                    }
                } else {
                    _match = false;
                    break;
                }
            }
        }
        return -1;
    }
}