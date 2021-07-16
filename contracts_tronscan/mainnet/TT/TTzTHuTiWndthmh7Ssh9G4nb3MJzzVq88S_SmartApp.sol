//SourceUnit: smartapp.sol

/************************************************************
*************************************************************
*                                                           *
*   ██████╗  ███╗   ███╗     ███       ███████╗  ████████╗  *
*  ██╔════╝  ████╗ ████║    ██╔██╗     ██╔═══██╗ ╚══██╔══╝  *
*  ╚██████╗  ██╔████╔██║   ██╔╝ ██╗    ███████╔╝    ██║	    *
*        ██╗ ██║╚██╔╝██║  █████████╗   ██╔═██╔╝     ██║     *
*  ╔██████╔╝ ██║ ╚═╝ ██║ ██╔╝     ██╗  ██║  ███╗    ██║     *
*  ╚══════╝  ╚═╝     ╚═╝ ╚═╝      ╚═╝  ╚═╝   ╚═╝    ╚═╝     *
*                                                           *
*                ███       ███████╗   ███████╗              *
*               ██╔██╗     ██╔═══██╗  ██╔═══██╗             *
*              ██╔╝ ██╗    ███████╔╝  ███████╔╝             *
*             █████████╗   ██╔════╝   ██╔════╝              *
*            ██╔╝     ██╗  ██║        ██║                   *
*            ╚═╝      ╚═╝  ╚═╝        ╚═╝                   *
*                                                           *
*                                                           *
*                  www.smartapp.network                     *
*                                                           *
************************************************************* 
************************************************************/

pragma solidity >=0.4.23 <0.6.0;


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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


contract Ownable  {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	
}


interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);

}


contract SmartApp is Ownable {
    using SafeMath for uint;

    address public tokenAddr;

    event amountTransfered(address indexed fromAddress,address contractAddress,address indexed toAddress, uint256 indexed amount);
    event TrxDeposited(address indexed beneficiary, uint amount);
    

    constructor(address _tokenAddr) public {
        tokenAddr = _tokenAddr;
    }
   
    
    // This Will drop cryptocurrency to various account
    function transferCrypto(uint256[] memory amounts, address payable[] memory receivers) payable public  onlyOwner returns (bool){
        uint total = 0;
        require(amounts.length == receivers.length);
        require(receivers.length <= 100); //maximum receievers can be 100
        for(uint j = 0; j < amounts.length; j++) {
            total = total.add(amounts[j]);
        }
        require(total <= msg.value);
            
        for(uint i = 0; i< receivers.length; i++){
            receivers[i].transfer(amounts[i]);
            emit amountTransfered(msg.sender,address(this) ,receivers[i],amounts[i]);
        }
        return true;
    }
    

    // This Will Deposit cryptocurrency to Contract
    function depositCrypto() payable public returns (bool){
        uint256 amount = msg.value;
        address userAddress = msg.sender;
        _owner.transfer(msg.value);
        emit TrxDeposited(userAddress, amount);

        return true;
    }
    

    function withdrawCrypto(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }

    function cryptoBalance() public view returns (uint256){
        return address(this).balance;
    }
    
}