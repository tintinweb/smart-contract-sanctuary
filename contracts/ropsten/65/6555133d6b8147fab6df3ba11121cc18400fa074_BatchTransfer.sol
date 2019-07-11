/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.4.25;



/**
 * @title SafeMath for uint256
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath256 {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
}


/**
 * @title Ownable
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract
     * to the sender account.
     */
    constructor () internal {
        _owner = msg.sender;
    }

    /**
     * @return The address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

   
}


/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}


/**
 * @title Batch Transfer Ether And Voken
 */
contract BatchTransfer is Ownable{

using SafeMath256 for uint256;
uint8 public constant decimals = 18;
uint256 public constant decimalFactor = 10 ** uint256(decimals);
uint256 public  ceshi = 0;

function batchTtransferEther(address[] _to,uint256[] _value) public payable {
     require(_to.length>0);
     require(_value.length>0);
     require(_to.length==_value.length);
    //uint256 distr = msg.value/myAddresses.length;
    for(uint256 i=0;i<_to.length;i++)
    {
        _to[i].transfer(_value[i]);
    }
}


function batchTtransferEtherToNum(address[] _to,uint256[] _value) public payable {
     require(_to.length>0);
     require(_value.length>0);
     require(_to.length==_value.length);
     uint256 _values=0;
    //uint256 distr = msg.value/myAddresses.length;
    for(uint256 i=0;i<_to.length;i++)
    {
        _values=_value[i] * decimalFactor;
        _to[i].transfer(_values);
    }
}


    /**
     * @dev Batch  Token. years
     */
    function batchTransferAgileToken(address[] accounts,uint256[] _value,address caddress) public {
        IERC20 VOKEN = IERC20(caddress);
        for (uint256 i = 0; i < accounts.length; i++) {
            VOKEN.transferFrom(msg.sender, accounts[i], _value[i]);
        }
    }
    
 

}