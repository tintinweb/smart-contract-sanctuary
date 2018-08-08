pragma solidity 0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/*
 * Price band
 * 5 ETH       @ $550 = 10,000 ZMN 
 * 10 ETH      @ $545 = 10,000 ZMN
 * 25 ETH      @ $540 = 10,000 ZMN
 * 50 ETH      @ $530 = 10,000 ZMN
 * 250 ETH     @ $520 = 10,000 ZMN
 * 500 ETH     @ $510 = 10,000 ZMN
 * 1,000 ETH   @ $500 = 10,000 ZMN
*/
contract PrivateSaleExchangeRate is Ownable {
    using SafeMath for uint256;
    uint256 public rate;
    uint256 public timestamp;
    event UpdateUsdEthRate(uint256 _rate);
    
    function PrivateSaleExchangeRate(uint256 _rate) public {
        require(_rate > 0);
        rate = _rate;
        timestamp = now;
    }
    
    /*
     * @param _rate USD/ETH
     */
    function updateUsdEthRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        require(rate != _rate);
        emit UpdateUsdEthRate(_rate);
        rate = _rate;
        timestamp = now;
    }
    
     /*
     * @dev return amount of ZMN token derive from price band and current exchange rate
     * @param _weiAmount purchase amount of ETH
     */
    function getTokenAmount(uint256 _weiAmount) public view returns (uint256){
        
        // US cost for 10,000 tokens
        uint256 cost = 550;
        
        if(_weiAmount < 10 ether){ 
            cost = 550; 
        }else if(_weiAmount < 25 ether){ 
            cost = 545; 
        }else if(_weiAmount < 50 ether){ 
            cost = 540; 
        }else if(_weiAmount < 250 ether){ 
            cost = 530; 
        }else if(_weiAmount < 500 ether){ 
            cost = 520; 
        }else if(_weiAmount < 1000 ether){ 
            cost = 510;
        }else{
            cost = 500;
        }
        return _weiAmount.mul(rate).mul(10000).div(cost);
    }
}