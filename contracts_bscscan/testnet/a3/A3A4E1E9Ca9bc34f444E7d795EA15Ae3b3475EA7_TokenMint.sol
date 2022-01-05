pragma solidity ^0.8.4;

import "./Whitelist.sol";
import "./Token.sol";
import "./IERC20.sol";


contract TokenMint is Whitelist {

//    using Address for address;

    event Mint(address indexed source, address indexed to, uint256 amount);

    address public tokenAddress;
    Token private token;
    address public exchangeableToken;
    //TODO maybe add function that can disable exchangeable token/exchange mint

    
    constructor(address _tokenAddress) Ownable() public {

        tokenAddress = _tokenAddress;

        //Only the mint should own its paired token
        token = Token(tokenAddress);
    }

    
    function mint(address beneficiary, uint256 tokenAmount) onlyWhitelisted public returns (uint256){
        require(tokenAmount > 0, "can't mint 0");

        if (token.mint(beneficiary, tokenAmount)) {
            emit Mint(msg.sender, beneficiary, tokenAmount);
            return tokenAmount;
        }

        return 0;

    }
    function mintForExchange(address beneficiary, uint256 tokenAmount) internal {
        if (token.mint(beneficiary, tokenAmount)) {
            emit Mint(msg.sender, beneficiary, tokenAmount);
            //return tokenAmount;
        }
    }
    function setExchangeableToken(address _exchangeableToken) public onlyOwner() {
        exchangeableToken = _exchangeableToken;
    }

    function exchangeTokens(uint amount) public {
        require(amount > 0, "can't exchange 0 tokens");
        address beneficiary = msg.sender;
        IERC20(exchangeableToken).transferFrom(beneficiary, address(this), amount);

        mintForExchange(beneficiary, amount);
    }
    
    function remainingMintableSupply() public view returns (uint256) {
        return token.remainingMintableSupply();
    }

}