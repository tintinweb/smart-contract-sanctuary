/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

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
        address tokenA,
        address tokenB,
        uint256 _amount
    ) external view returns (uint256);
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function defaultPrice(string memory rarity) external view returns (uint256 price);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintCustom(
        address _to,
        string memory rarity,
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
        address vodkaToken_,
        address cocktailNFT_,
        address bankAddress_,
        address busdAddress,
        address wbnbAddress,
        address wbtcAddress,
        address tokenConverter_
    ) {
        owner = msg.sender;

        vodkaToken = IERC20(vodkaToken_);
        cocktailNFT = IERC721(cocktailNFT_);
        tokenConverter = ITokenConverter(tokenConverter_);
        bankAddress = bankAddress_;

        BUSD = busdAddress;
        addCoin('BUSD', busdAddress);
        addCoin('WBNB', wbnbAddress);
        addCoin('WBTC', wbtcAddress);
    }

    function mix(
        string memory rarity,
        string memory symbol,
        uint256 cocktailAmount
    ) public {
        (uint256 vodkaAmount, uint256 coinAmount) = calculatePrices(rarity, symbol, cocktailAmount);

        IERC20 token = IERC20(symbolToAddress[symbol]);

        require(token.balanceOf(msg.sender) >= coinAmount, 'You dont have enough coins');
        require(vodkaToken.balanceOf(msg.sender) >= vodkaAmount, 'You dont have enough VODKA tokens');

        vodkaToken.transferFrom(msg.sender, address(this), vodkaAmount);
        token.transferFrom(msg.sender, bankAddress, coinAmount);

        cocktailNFT.mintCustom(msg.sender, rarity, cocktailAmount);
        vodkaToken.burn(vodkaAmount);

        emit Mixed(msg.sender, rarity, symbol, cocktailAmount);
    }

    function calculatePrices(
        string memory rarity,
        string memory symbol,
        uint256 cocktailAmount
    ) public view returns (uint256, uint256) {
        require(cocktailNFT.defaultPrice(rarity) != 0, 'Illegal rarity');
        require(symbolToAddress[symbol] != address(0), 'Illegal symbol');
        require(cocktailAmount > 0, 'Amount of cocktails must be greater then zero');

        uint256 BUSDAmount = cocktailNFT.defaultPrice(rarity) * cocktailAmount * ONE_DOLLAR;
        uint256 BUSDInVodka = BUSDAmount / 2;
        uint256 BUSDInCoin = BUSDAmount - BUSDInVodka;

        uint256 vodkaAmount = tokenConverter.convertTwoUniversal(BUSD, address(vodkaToken), BUSDInVodka);
        uint256 coinAmount = tokenConverter.convertTwoUniversal(BUSD, symbolToAddress[symbol], BUSDInCoin);

        return (vodkaAmount, coinAmount);
    }

    function getBalance(string memory symbol) public view returns (uint256 _balance) {
        require(symbolToAddress[symbol] != address(0), 'Illegal symbol');
        IERC20 token = IERC20(symbolToAddress[symbol]);
        return token.balanceOf(msg.sender);
    }

    function changeBank(address newBankAddress) public onlyOwner {
        require(newBankAddress != address(0), 'New bank address cannot be address 0x0');
        emit BankChanged(bankAddress, newBankAddress);
        bankAddress = newBankAddress;
    }

    function addCoin(string memory symbol, address coinAddress) public onlyOwner {
        require(coinAddress != address(0), 'Illegal address');
        symbolToAddress[symbol] = coinAddress;
    }

    function removeCoin(string memory symbol) public onlyOwner {
        symbolToAddress[symbol] = address(0);
    }

    function changeTokenConverter(address tokenConverter_) public onlyOwner {
        tokenConverter = ITokenConverter(tokenConverter_);
    }
}