pragma solidity ^0.4.24;

/*
    Sale(address ethwallet)   // this will send the received ETH funds to this address
  @author Yumerium Ltd
*/
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

contract YumeriumManager {
    function getYumerium(address sender) external payable returns (uint256);
}
contract Sale {
    uint public saleEnd4 = 1539129600; //10/10/2018 @ 12:00am (UTC)
    uint256 public minEthValue = 10 ** 15; // 0.001 eth
    
    using SafeMath for uint256;
    uint256 public maxSale;
    uint256 public totalSaled;
    YumeriumManager public manager;
    address public ETHWallet;

    address public creator;

    event Contribution(address from, uint256 amount);

    constructor(address _wallet, address _manager_address) public {
        maxSale = 316906850 * 10 ** 8; 
        ETHWallet = _wallet;
        manager = YumeriumManager(_manager_address);
        creator = msg.sender;
    }

    function () external payable {
        buy();
    }

    // CONTRIBUTE FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the sender
    function contribute() external payable {
        buy();
    }
    
    
    function buy() internal {
        require(msg.value>=minEthValue);
        require(now < saleEnd4); // main sale postponed
        
        uint256 amount = manager.getYumerium.value(msg.value)(msg.sender);
        uint256 total = totalSaled + amount;
        
        require(total<=maxSale);
        
        totalSaled = total;
        
        emit Contribution(msg.sender, amount);
    }

    // change yumo address
    function changeManagerAddress(address _manager_address) external {
        require(msg.sender==creator, "You are not a creator!");
        manager = YumeriumManager(_manager_address);
    }
}