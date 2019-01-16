pragma solidity ^0.4.24;

// File: contracts/interfaces/Token.sol

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

// File: contracts/interfaces/TokenConverter.sol

contract TokenConverter {
    address public constant ETH_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    function getReturn(Token _fromToken, Token _toToken, uint256 _fromAmount) external view returns (uint256 amount);
    function convert(Token _fromToken, Token _toToken, uint256 _fromAmount, uint256 _minReturn) external payable returns (uint256 amount);
}

// File: contracts/interfaces/AvailableProvider.sol

interface AvailableProvider {
   function isAvailable(Token _from, Token _to, uint256 _amount) external view returns (bool);
}

// File: contracts/utils/Ownable.sol

contract Ownable {
    address public owner;

    event SetOwner(address _owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender is not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
        emit SetOwner(msg.sender);
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0), "Can&#39;t transfer to address 0x0");
        emit SetOwner(_to);
        owner = _to;
        return true;
    }
}

// File: contracts/TokenConverterRouter.sol

contract TokenConverterRouter is TokenConverter, Ownable {
    address public constant ETH_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    TokenConverter[] public converters;
    
    mapping(address => uint256) private converterToIndex;    
    mapping (address => AvailableProvider) public availability;

    uint256 extraLimit;
    
    event AddedConverter(address _converter);
    event Converted(address _converter, address _from, address _to, uint256 _amount, uint256 _return);
    event SetAvailableProvider(address _converter, address _provider);
    event SetExtraLimit(uint256 _extraLimit);
    event RemovedConverter(address _converter);

    event ConverterEvaluated(address _converter, address _from, address _to, uint256 _srcQty, uint256 _destQty);
    event ConverterNotAvailable(address _converter, address _provider, address _from, address _to, uint256 _srcQty);
    event ConverterError(address _converter, address _from, address _to, uint256 _srcQty);
    event ConverterAvailableError(address _converter, address _provider, address _from, address _to, uint256 _srcQty);

    event WithdrawTokens(address _token, address _to, uint256 _amount);
    event WithdrawEth(address _to, uint256 _amount);

    /*
     *  @notice External function isWorker.
     *  @dev Takes _worker, checks if the worker is valid. 
     *  @param _worker Worker address.
     *  @return bool True if worker is valid, false otherwise.
     */
    function _issetConverter(address _converter) internal view returns (bool) {
        return converterToIndex[_converter] != 0;
    }
    
    /*
    *  @notice External function allConverters.
    *  @dev Return all convertes.
    *  @return array with all address the converters.
    */
    function getConverters() external view returns (address[] memory result) {
        result = new address[](converters.length - 1);
        for (uint256 i = 1; i < converters.length; i++) {
            result[i - 1] = converters[i];
        }
    }
    
    /*
     *  @notice External function addConverter.
     *  @dev Takes _converter.
     *       Add converter.
     *  @param _converter Converter address.
     *  @return bool True if converter is added, false otherwise.
     */
    function addConverter(TokenConverter _converter) external onlyOwner returns (bool) {
        require(!_issetConverter(_converter), "The converter it already exist");
        uint256 index = converters.push(_converter) - 1;
        converterToIndex[_converter] = index;
        emit AddedConverter(_converter);
        return true;
    }
    
    /*
     *  @notice External function removeConverter.
     *  @dev Takes _converter and removes the converter.
     *  @param _worker Converter address.
     *  @return bool true if existed, false otherwise.
     */
    function removeConverter(address _converter) external onlyOwner returns (bool) {
        require(_issetConverter(_converter), "The converter is not exist.");
        uint256 index = converterToIndex[_converter];
        TokenConverter lastConverter = converters[converters.length - 1];
        converterToIndex[lastConverter] = index;
        converters[index] = lastConverter;
        converters.length--;
        delete converterToIndex[_converter];
        emit RemovedConverter(_converter);
        return true;
    }
    
    function setAvailableProvider(
        TokenConverter _converter,
        AvailableProvider _provider
    ) external onlyOwner {
        emit SetAvailableProvider(_converter, _provider);
        availability[_converter] = _provider;        
    }
    
    function setExtraLimit(uint256 _extraLimit) external onlyOwner {
        emit SetExtraLimit(_extraLimit);
        extraLimit = _extraLimit;
    }

    function convert(Token _from, Token _to, uint256 _amount, uint256 _minReturn) external payable returns (uint256 result) {
        TokenConverter converter = _getBestConverter(_from, _to, _amount);
        require(converter != address(0), "No converter candidates");

        if (_from == ETH_ADDRESS) {
            require(msg.value == _amount, "ETH not enought");
        } else {
            require(msg.value == 0, "ETH not required");
            require(_from.transferFrom(msg.sender, this, _amount), "Error pulling Token amount");
            require(_from.approve(converter, _amount), "Error approving token transfer");
        }

        result = converter.convert.value(msg.value)(_from, _to, _amount, _minReturn);
        require(result >= _minReturn, "Funds received below min return");

        emit Converted({
            _converter: converter,
            _from: _from,
            _to: _to,
            _amount: _amount,
            _return: result
        });

        if (_from != ETH_ADDRESS) {
            require(_from.approve(converter, 0), "Error removing approve");
        }

        if (_to == ETH_ADDRESS) {
            msg.sender.transfer(result);
        } else {
            require(_to.transfer(msg.sender, result), "Error sending tokens");
        }

        if (_isSimulation()) {
            // this is a simulation, we need a pessimistic simulation we add
            // the extraLimit. reasons: this algorithm is not deterministic
            // different gas depending on the best route (Kyber, Bancor, etc)
            _addExtraGasLimit();
        }
    }

    function getReturn(Token _from, Token _to, uint256 _amount) external view returns (uint256) {
        return _getBestConverterView(_from, _to, _amount).getReturn(_from, _to, _amount);
    }

    function _isSimulation() internal view returns (bool) {
        return gasleft() > block.gaslimit;
    }
    
    function _addExtraGasLimit() internal view {
        uint256 startGas = gasleft();
        while (startGas - gasleft() < extraLimit) {          
            assembly {
                let x := mload(0x0)
            }
        }
    }

    function _getBestConverterView(Token _from, Token _to, uint256 _amount) internal view returns (TokenConverter best) {
        uint256 length = converters.length;
        bytes32 bestReturn;

        for (uint256 i = 0; i < length; i++) {
            TokenConverter converter = converters[i];
            if (_isAvailableView(converter, _from, _to, _amount)) {
                (uint256 success, bytes32 newReturn) = _safeStaticCall(
                    converter,
                    abi.encodeWithSelector(
                        converter.getReturn.selector,
                        _from,
                        _to,
                        _amount
                    )
                );

                if (success == 1 && newReturn > bestReturn) {
                    bestReturn = newReturn;
                    best = converter;
                }
            }
        }
    }

    function _getBestConverter(Token _from, Token _to, uint256 _amount) internal returns (TokenConverter best) {
        uint256 length = converters.length;
        bytes32 bestReturn;

        for (uint256 i = 0; i < length; i++) {
            TokenConverter converter = converters[i];
            if (_isAvailable(converter, _from, _to, _amount)) {
                (uint256 success, bytes32 newReturn) = _safeCall(
                    converter,
                    abi.encodeWithSelector(
                        converter.getReturn.selector,
                        _from,
                        _to,
                        _amount
                    )
                );

                if (success == 1) {
                    emit ConverterEvaluated(converter, _from, _to, _amount, uint256(newReturn));
                    if (newReturn > bestReturn) {
                        bestReturn = newReturn;
                        best = converter;
                    }
                } else {
                    emit ConverterError(converter, _from, _to, _amount);
                }
            }
        }
    }

    function _isAvailable(address converter, Token _from, Token _to, uint256 _amount) internal returns (bool) {
        AvailableProvider provider = availability[converter];
        if (provider == address(0)) return true;
        (uint256 success,bytes32 available) = _safeCall(
            provider, abi.encodeWithSelector(
                provider.isAvailable.selector,
                _from,
                _to,
                _amount
            )
        );

        if (success != 1) {
            emit ConverterAvailableError(converter, provider, _from, _to, _amount);
            return false;
        }

        if (available != bytes32(1)) {
            emit ConverterNotAvailable(converter, provider, _from, _to, _amount);
            return false;
        }
        
        return true;
    }

    function _isAvailableView(address converter, Token _from, Token _to, uint256 _amount) internal view returns (bool) {
        AvailableProvider provider = availability[converter];
        if (provider == address(0)) return true;
        (uint256 success,bytes32 available) = _safeStaticCall(
            provider, abi.encodeWithSelector(
                provider.isAvailable.selector,
                _from,
                _to,
                _amount
            )
        );
        return success == 1 && available == bytes32(1);
    }

    function withdrawEther(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        emit WithdrawEth(_to, _amount);
        _to.transfer(_amount);
    }

    function withdrawTokens(
        Token _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        emit WithdrawTokens(_token, _to, _amount);
        return _token.transfer(_to, _amount);
    }

    function _safeStaticCall(
        address _contract,
        bytes _data
    ) internal view returns (uint256 success, bytes32 result) {
        assembly {
            let x := mload(0x40)
            success := staticcall(
                            gas,                  // Send almost all gas
                            _contract,            // To addr
                            add(0x20, _data),     // Input is data past the first 32 bytes
                            mload(_data),         // Input size is the lenght of data
                            x,                    // Store the ouput on x
                            0x20                  // Output is a single bytes32, has 32 bytes
                        )

            result := mload(x)
        }
    }

    function _safeCall(
        address _contract,
        bytes _data
    ) internal returns (uint256 success, bytes32 result) {
        assembly {
            let x := mload(0x40)
            success := call(
                            gas,                  // Send almost all gas
                            _contract,            // To addr
                            0,                    // Send ETH
                            add(0x20, _data),     // Input is data past the first 32 bytes
                            mload(_data),         // Input size is the lenght of data
                            x,                    // Store the ouput on x
                            0x20                  // Output is a single bytes32, has 32 bytes
                        )

            result := mload(x)
        }
    }

    function() external payable {}
}