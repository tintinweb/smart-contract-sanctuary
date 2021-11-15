// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'You cant tranfer ownerships to address 0x0');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface ITokenConverter {
    function convertTwoUniversal(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) external view returns (uint256);
}

interface IERC721 {
    function rarityToDollars(string memory _rarity) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getRarity(string memory _tokenURI) external view returns (string memory);

    function burn(uint256 _tokenId) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function mint(
        address _to,
        string memory _rarity,
        uint256 _amount
    ) external;
}

interface IERC20 {
    function balanceOf(address who) external view returns (uint256 balance);

    function transfer(address to, uint256 value) external returns (bool trans1);

    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool trans);

    function approve(address spender, uint256 value) external returns (bool hello);

    function burn(uint256 _amount) external;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Mixing is Ownable {
    IERC20 private vodkaToken;
    IERC721 private cocktailNFT;
    ITokenConverter public tokenConverter;

    mapping(string => address) public symbolToAddress;

    address public bankAddress;

    address public BUSD;
    address public TOKEN_CONVERTER;

    uint256 public constant ONE_DOLLAR = 1e18;

    event Mixed(address indexed sender, string rarity, string symbol, uint256 cocktailAmount);
    event BankChanged(address indexed previousBankAddress, address indexed newBankAddress);

    constructor(
        address _vodkaToken,
        address _cocktailNFT,
        address _bankAddress,
        address busdAddress,
        address wbnbAddress,
        address wbtcAddress,
        address tokenConverter_
    ) {
        owner = msg.sender;

        vodkaToken = IERC20(_vodkaToken);
        cocktailNFT = IERC721(_cocktailNFT);
        tokenConverter = ITokenConverter(tokenConverter_);
        bankAddress = _bankAddress;

        BUSD = busdAddress;
        addCoin('BUSD', busdAddress);
        addCoin('WBNB', wbnbAddress);
        addCoin('WBTC', wbtcAddress);
    }

    function mix(
        string memory _rarity,
        string memory _symbol,
        uint256 _cocktailAmount
    ) public {
        (uint256 _vodkaAmount, uint256 _coinAmount) = calculatePrices(_rarity, _symbol, _cocktailAmount);

        IERC20 _token = IERC20(symbolToAddress[_symbol]);

        require(_token.balanceOf(msg.sender) >= _coinAmount, 'You dont have enough coins');
        require(vodkaToken.balanceOf(msg.sender) >= _vodkaAmount, 'You dont have enough VODKA tokens');

        vodkaToken.transferFrom(msg.sender, address(this), _vodkaAmount);
        _token.transferFrom(msg.sender, bankAddress, _coinAmount);

        cocktailNFT.mint(msg.sender, _rarity, _cocktailAmount);
        vodkaToken.burn(_vodkaAmount);

        emit Mixed(msg.sender, _rarity, _symbol, _cocktailAmount);
    }

    function calculatePrices(
        string memory _rarity,
        string memory _symbol,
        uint256 _cocktailAmount
    ) public view returns (uint256, uint256) {
        require(cocktailNFT.rarityToDollars(_rarity) != 0, 'Illegal rarity');
        require(symbolToAddress[_symbol] != address(0), 'Illegal _symbol');
        require(_cocktailAmount > 0, 'Amount of cocktails must be greater then zero');

        uint256 _BUSDAmount = cocktailNFT.rarityToDollars(_rarity) * _cocktailAmount * ONE_DOLLAR;
        uint256 _BUSDInVodka = _BUSDAmount / 2;
        uint256 _BUSDInCoin = _BUSDAmount - _BUSDInVodka;

        uint256 _vodkaAmount = tokenConverter.convertTwoUniversal(BUSD, address(vodkaToken), _BUSDInVodka);
        uint256 _coinAmount = tokenConverter.convertTwoUniversal(BUSD, symbolToAddress[_symbol], _BUSDInCoin);

        return (_vodkaAmount, _coinAmount);
    }

    function getBalance(string memory _symbol) public view returns (uint256 _balance) {
        require(symbolToAddress[_symbol] != address(0), 'Illegal _symbol');
        IERC20 _token = IERC20(symbolToAddress[_symbol]);
        return _token.balanceOf(msg.sender);
    }

    function changeBank(address _newBankAddress) public onlyOwner {
        require(_newBankAddress != address(0), 'New bank address cannot be address 0x0');
        emit BankChanged(bankAddress, _newBankAddress);
        bankAddress = _newBankAddress;
    }

    function addCoin(string memory _symbol, address _coinAddress) public onlyOwner {
        require(_coinAddress != address(0), 'Illegal address');
        symbolToAddress[_symbol] = _coinAddress;
    }

    function removeCoin(string memory _symbol) public onlyOwner {
        symbolToAddress[_symbol] = address(0);
    }

    function changeTokenConverter(address tokenConverter_) public onlyOwner {
        tokenConverter = ITokenConverter(tokenConverter_);
    }
}

