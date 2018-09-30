pragma solidity ^0.4.24;

/*
    YumeriumManager(address ethwallet, address YUM Token)   
    @author Yumerium Ltd
*/
contract YumeriumManager {
    using SafeMath for uint256;
    address public creator;

    YUM public Yumerium;
    address public YumeriumTeamWallet;
    mapping (address => bool) public YumeriumProducts;
    address[] public arrProducts; // array of players to tract and distribute them tokens when the game ends

    uint public eventSaleEnd = 1537920000; // 09/26/2018 @ 12:00am (UTC)

    uint256 public saleExchangeRate4 = 3333;
    uint256 public saleExchangeRate5 = 3158;
    
    uint256 public volumeType1 = 1429 * 10 ** 16; //14.29 eth
    uint256 public volumeType2 = 7143 * 10 ** 16;
    uint256 public volumeType3 = 14286 * 10 ** 16;
    uint256 public volumeType4 = 42857 * 10 ** 16;
    uint256 public volumeType5 = 71429 * 10 ** 16;
    uint256 public volumeType6 = 142857 * 10 ** 16;
    uint256 public volumeType7 = 428571 * 10 ** 16;

    event GetYumerium(address product, address sender, uint256 amount);

    constructor(address _wallet, address _token_address) public {
        creator = msg.sender;
        Yumerium = YUM(_token_address);
        YumeriumTeamWallet = _wallet;
        YumeriumProducts[this] = true;
    }

    function () external payable {
        getYumerium(msg.sender);
    }
    
    
    function getYumerium(address sender) public payable returns (uint256) {
        require(YumeriumProducts[msg.sender], "This isn&#39;t our product!");
        uint256 amount;
        uint256 exchangeRate;
        if(now < eventSaleEnd) {
            exchangeRate = saleExchangeRate4;
        } else { // this must be applied even after the sale period is done
            exchangeRate = saleExchangeRate5;
        }
        
        amount = msg.value.mul(exchangeRate).div(10 ** 10);
        
        if(msg.value >= volumeType7) {
            amount = amount.mul(180).div(100);
        } else if(msg.value >= volumeType6) {
            amount = amount.mul(160).div(100);
        } else if(msg.value >= volumeType5) {
            amount = amount.mul(140).div(100);
        } else if(msg.value >= volumeType4) {
            amount = amount.mul(130).div(100);
        } else if(msg.value >= volumeType3) {
            amount = amount.mul(120).div(100);
        } else if(msg.value >= volumeType2) {
            amount = amount.mul(110).div(100);
        } else if(msg.value >= volumeType1) {
            amount = amount.mul(105).div(100);
        }

        YumeriumTeamWallet.transfer(msg.value);
        Yumerium.sale(sender, amount);
        
        emit GetYumerium(msg.sender, sender, amount);
        return amount;
    }

    function calculateToken(uint256 ethValue) public returns (uint256) {
        uint256 amount;
        uint256 exchangeRate;
        if(now < eventSaleEnd) {
            exchangeRate = saleExchangeRate4;
        } else { // this must be applied even after the sale period is done
            exchangeRate = saleExchangeRate5;
        }
        
        amount = ethValue.mul(exchangeRate).div(10 ** 10);
        
        if(ethValue >= volumeType7) {
            amount = amount.mul(180).div(100);
        } else if(ethValue >= volumeType6) {
            amount = amount.mul(160).div(100);
        } else if(ethValue >= volumeType5) {
            amount = amount.mul(140).div(100);
        } else if(ethValue >= volumeType4) {
            amount = amount.mul(130).div(100);
        } else if(ethValue >= volumeType3) {
            amount = amount.mul(120).div(100);
        } else if(ethValue >= volumeType2) {
            amount = amount.mul(110).div(100);
        } else if(ethValue >= volumeType1) {
            amount = amount.mul(105).div(100);
        }

        return amount;
    }

    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender==creator, "You&#39;re not a creator!");
        creator = _creator;
    }
    // change creator address
    function changeTeamWallet(address _teamWallet) external {
        require(msg.sender==creator, "You&#39;re not a creator!");
        YumeriumTeamWallet = _teamWallet;
    }
    // change creator address
    function addProduct(address _contractAddress) external {
        require(msg.sender==creator, "You&#39;re not a creator!");
        require(!YumeriumProducts[_contractAddress], "This product is already in the manager");
        if (!YumeriumProducts[_contractAddress])
        {
            YumeriumProducts[_contractAddress] = true;
            arrProducts.push(_contractAddress);
        }
    }
    // change creator address
    function removeProduct(address _contractAddress) external {
        require(msg.sender==creator, "You&#39;re not a creator!");
        require(YumeriumProducts[_contractAddress], "This product isn&#39;t already in the manager");
        if (YumeriumProducts[_contractAddress])
        {
            YumeriumProducts[_contractAddress] = false;
            for (uint256 i = 0; i < arrProducts.length; i++) {
                if (arrProducts[i] == _contractAddress) {
                    delete arrProducts[i];
                    break;
                }
            }
        }
    }

    function getNumProducts() public view returns(uint256) {
        return arrProducts.length;
    }
}

contract YUM {
    function sale(address to, uint256 value) public;
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}