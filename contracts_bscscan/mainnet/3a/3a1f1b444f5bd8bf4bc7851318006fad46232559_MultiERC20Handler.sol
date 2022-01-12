// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./EnumerableMap.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IMultiERC20Handler.sol";
import "./IERC20.sol";

contract MultiERC20Handler is Ownable, IMultiERC20Handler {
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Address for address;
    event OperationResult(bool result);

    EnumerableMap.UintToAddressMap private _map;

    mapping(uint256 => ERC20Available) public ERC20Tokens;
    mapping(string => uint256) public tokenSymbolToKey;

    struct ERC20Available {
        string symbol;
        address addrs;
        uint256 key;
    }

    function registerERC20Token(address value) external override onlyOwner {
        require(value.isContract(), "set contract address");
        require(
            !isValidToken(value),
            "token or symbol has already been registered"
        );
        setERC20Tokens(ERC20TokensLength() + 1, value);
    }

    function isValidToken(address value) public view override returns (bool) {
        return isValidSymbol(IERC20(value).symbol());
    }

    function isValidSymbol(string memory symbol)
        public
        view
        override
        returns (bool)
    {
        return tokenSymbolToKey[symbol] != 0;
    }

    function isValidSymbols(string[] memory symbols)
        public
        view
        override
        returns (bool)
    {
        for (uint256 i = 0; i < symbols.length; i++) {
            if (!isValidSymbol(symbols[i])) return false;
        }
        return true;
    }

    function setERC20Tokens(uint256 key, address value) internal {
        require(key > 0, "the key must be greater than zero");
        IERC20 tokenHandler = IERC20(value);
        bool result = _map.set(key, value);
        ERC20Available storage token_ = ERC20Tokens[key];
        token_.symbol = tokenHandler.symbol();
        token_.addrs = value;
        token_.key = key;
        tokenSymbolToKey[tokenHandler.symbol()] = key;
        emit OperationResult(result);
    }

    function removeERC20Token(uint256 key) public override onlyOwner {
        _map.remove(key);
        delete tokenSymbolToKey[ERC20Tokens[key].symbol];
        delete ERC20Tokens[key];
    }

    function ERC20TokensContainsKey(uint256 key)
        public
        view
        override
        returns (bool)
    {
        return _map.contains(key);
    }

    function ERC20TokensLength() public view override returns (uint256) {
        return _map.length();
    }

    function ERC20TokensAt(uint256 index)
        public
        view
        override
        returns (uint256 key, address value)
    {
        return _map.at(index);
    }

    function tryGetERC20Token(uint256 key)
        public
        view
        override
        returns (bool, address)
    {
        return _map.tryGet(key);
    }

    function getERC20Token(uint256 key) public view override returns (address) {
        return _map.get(key);
    }

    function getERC20TokenWithMessage(uint256 key, string calldata errorMessage)
        public
        view
        override
        returns (address)
    {
        return _map.get(key, errorMessage);
    }

    function getTokenBySymbol(string memory symbol)
        public
        view
        returns (ERC20Available memory)
    {
        (uint256 _key, ) = ERC20TokensAt(tokenSymbolToKey[symbol]);
        return ERC20Tokens[_key];
    }

    function symbolToIERC20(string memory symbol)
        public
        view
        override
        returns (IERC20)
    {
        require(isValidSymbol(symbol), "token is not valid");
        return IERC20(getERC20Token(tokenSymbolToKey[symbol]));
    }

    function symbolToAddress(string memory symbol)
        public
        view
        override
        returns (address)
    {
        require(isValidSymbol(symbol), "token is not valid");
        return getERC20Token(tokenSymbolToKey[symbol]);
    }

    function getAllAvatibleTokens()
        public
        view
        returns (ERC20Available[] memory)
    {
        ERC20Available[] memory allTokens = new ERC20Available[](
            ERC20TokensLength()
        );
        for (uint256 i; i < allTokens.length; i++) {
            (uint256 _key, ) = ERC20TokensAt(i);
            allTokens[i] = ERC20Tokens[_key];
        }
        return allTokens;
    }

    function getAllSymbols() public view override returns (string[] memory) {
        string[] memory allSymbols = new string[](ERC20TokensLength());
        for (uint256 i; i < allSymbols.length; i++) {
            (uint256 _key, ) = ERC20TokensAt(i);
            allSymbols[i] = ERC20Tokens[_key].symbol;
        }
        return allSymbols;
    }

    function getCurrentKeys() public view override returns (uint256[] memory) {
        uint256[] memory allSymbols = new uint256[](ERC20TokensLength());
        for (uint256 i; i < allSymbols.length; i++) {
            (uint256 _key, ) = ERC20TokensAt(i);
            allSymbols[i] = _key;
        }
        return allSymbols;
    }
}