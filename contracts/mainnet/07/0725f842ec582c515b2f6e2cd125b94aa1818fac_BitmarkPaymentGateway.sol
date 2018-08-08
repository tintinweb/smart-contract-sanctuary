pragma solidity ^0.4.19;

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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract BitmarkPaymentGateway is Ownable {
    using SafeMath for uint256;

    event SettleFund(address _targetContract, uint256 amount);

    address public masterWallet;
    bool public paused;

    /* main function */
    function BitmarkPaymentGateway(address _masterWallet) public {
        paused = false;
        masterWallet = _masterWallet;
    }

    function SetMasterWallet(address _newWallet) public onlyOwner {
        masterWallet = _newWallet;
    }

    function PausePayment() public onlyOwner {
        paused = true;
    }

    function ResumePayment() public onlyOwner {
        paused = false;
    }

    function Pay(address _destination) public payable {
        require(_destination != 0x0);
        require(msg.value > 0);
        require(!paused);
        masterWallet.transfer(msg.value.div(9));
        _destination.call.value(msg.value.div(9).mul(8))();

        SettleFund(_destination, msg.value);
    }

    function () public {}
}