pragma solidity ^0.4.24;

contract TokenInterface {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
}

contract AltTokenInterface {
    function name() public view returns (bytes32);
    function symbol() public view returns (bytes32);
    function decimals() public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
}

contract Utils {
    function contractuallyOf(address _address) public view returns(bool) {
        uint length;
        assembly {
            length := extcodesize(_address)
        }
        return (length > 0);
    }

    function tokenOf(address _contract, address _owner) public view returns(
        bool contractually,
        bool tokenized,
        string name,
        string symbol,
        uint256 decimals,
        uint256 totalSupply,
        uint256 balance
    ) {
        contractually = contractuallyOf(_contract);
        if (contractually) {
            TokenInterface token = TokenInterface(_contract);
            name = token.name();
            symbol = token.symbol();
            decimals = token.decimals();
            totalSupply = token.totalSupply();
            balance = token.balanceOf(_owner);
            
            if (bytes(name).length > 0 && bytes(symbol).length > 0) {
                tokenized = true;
            }
        }
    }

    function altTokenOf(address _contract, address _owner) public view returns(
        bool contractually,
        bool tokenized,
        string name,
        string symbol,
        uint256 decimals,
        uint256 totalSupply,
        uint256 balance
    ) {
        contractually = contractuallyOf(_contract);
        if (contractually) {
            AltTokenInterface token = AltTokenInterface(_contract);
            decimals = token.decimals();
            totalSupply = token.totalSupply();
            balance = token.balanceOf(_owner);

            bytes32 _name = token.name();
            bytes32 _symbol = token.symbol();

            if (_name.length > 0 && _symbol.length > 0) {
                tokenized = true;
            }
            
            name = bytes32ToString(_name);
            symbol = bytes32ToString(_symbol);
        }
    }
    
    function balanceOf(address[] _contracts, address _owner) public view returns(uint256[]) {
        uint8 count = uint8(_contracts.length);
        if (count > 0) {
            uint256[] memory balances = new uint256[](count);
            for (uint8 i = 0; i < count; i++) {
                TokenInterface token = TokenInterface(_contracts[i]);
                balances[i] = token.balanceOf(_owner);
            }
            return balances;
        }
        return new uint256[](0);
    }

    function recover(bytes32 _hash, bytes _sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (_sig.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }

    function bytes32ToString(bytes32 _input) internal constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_input) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}