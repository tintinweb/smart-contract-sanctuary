pragma solidity ^0.4.24;

contract TokenInterface {
    function name() public view returns (string);
    function symbol() public view returns (string);
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
            
            if (bytes(name).length > 0 && bytes(symbol).length > 0 && totalSupply > 0) {
                tokenized = true;
            }
        }
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
            return ecrecover(_hash, v, r, s);
        }
    }
}