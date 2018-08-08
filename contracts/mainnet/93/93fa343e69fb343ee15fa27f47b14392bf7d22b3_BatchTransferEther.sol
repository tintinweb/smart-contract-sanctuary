pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
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


contract BatchTransferEther is Ownable {
    using SafeMath for uint256;
    
    event LogTransfer(address indexed sender, address indexed receiver, uint256 amount);
    
    function batchTransferEtherWithSameAmount(address[] _addresses, uint _amoumt) public payable onlyOwner {
        require(_addresses.length != 0 && _amoumt != 0);
        uint checkAmount = msg.value.div(_addresses.length);
        require(_amoumt == checkAmount);
        
        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0));
            _addresses[i].transfer(_amoumt);
            emit LogTransfer(msg.sender, _addresses[i], _amoumt);
        }
    }
    
    function batchTransferEther(address[] _addresses, uint[] _amoumts) public payable onlyOwner {
        require(_addresses.length == _amoumts.length || _addresses.length != 0);
        uint total = sumAmounts(_amoumts);
        require(total == msg.value);
        
        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != 0x0);
            _addresses[i].transfer(_amoumts[i]);
            emit LogTransfer(msg.sender, _addresses[i], _amoumts[i]);
        }
    }
    
    function sumAmounts(uint[] _amoumts) private pure returns (uint sumResult) {
        for (uint i = 0; i < _amoumts.length; i++) {
            require(_amoumts[i] > 0);
            sumResult = sumResult.add(_amoumts[i]);
        }
    }

}