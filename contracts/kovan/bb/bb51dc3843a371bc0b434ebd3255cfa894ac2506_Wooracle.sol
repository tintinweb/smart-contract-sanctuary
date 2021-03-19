pragma solidity 0.6.9;
import {IERC20} from "./IERC20.sol";
import {InitializableOwnable} from "./InitializableOwnable.sol";

contract Wooracle is InitializableOwnable{
        
    struct Quote{
        uint256 price;
        uint256 timestamp;
        bool isValid;
    }

    mapping(address => mapping(address => Quote)) private mapQuotes_;

    constructor() public{
        initOwner(msg.sender);
    }


    function postPrice(address base,address quote,uint256 newPrice) 
        public onlyOwner 
        returns (bool)
    {
        mapQuotes_[base][quote].price = newPrice;
        mapQuotes_[base][quote].timestamp = block.timestamp;
        mapQuotes_[base][quote].isValid = true;
        return true;
    }

    function postInvalid(address base,address quote) 
        public onlyOwner 
        returns (bool)
    {
        mapQuotes_[base][quote].isValid = false;
        return true;
    }

    function getPrice(address base,address quote)
        public view
        returns (string memory baseSymbol,string memory quoteSymbol,uint256 latestPrice,bool isValid,bool isStale,uint256 timestamp)
    {
        baseSymbol = getTokenSymbol_(base);
        quoteSymbol = getTokenSymbol_(quote);
        latestPrice = mapQuotes_[base][quote].price;
        timestamp = mapQuotes_[base][quote].timestamp;
        isValid = mapQuotes_[base][quote].isValid;
        isStale = isPriceStaleNow_(base,quote);
    }

    function getTokenSymbol_(address token) private view returns (string memory)
    {
        return IERC20(token).symbol();
    }
    function isPriceStaleNow_(address base,address quote)
        private view returns (bool)
    {
        if (block.timestamp > mapQuotes_[base][quote].timestamp + 5 minutes)
        {
            return true;
        }
        else
        {
            return false;
        }
    }
}