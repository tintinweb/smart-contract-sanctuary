pragma solidity ^0.4.24;

/*
  @author Yumerium Ltd
*/

contract Test {
    using SafeMath for uint256;
    ERC20 public yumerium;
    address public teamWallet;
    address public creator;

    event ReceiveApproval(address _from, uint256 _value, address _token, bytes _extraData);

    constructor(address _teamWallet, address _yumerium) public {
        yumerium = ERC20(_yumerium);
        teamWallet = _teamWallet;
        creator = msg.sender;
    }

    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        require(yumerium.transferFrom(_from, teamWallet, _value), "check the balance");
        emit ReceiveApproval(_from, _value, _token, _extraData);
    }
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

contract ERC20 {
    mapping (address => uint256) public balanceOf;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}