//SourceUnit: BusinessCompany.sol

/***********************************************************
************************************************************
*                                                          *
*            ███████╗     ██████╗      ██████╗             *
*            ██╔═══██╗   ██╔═══██╗    ██╔═══██╗            *
*            ███████╔╝   ██║   ╚═╝    ██║   ╚═╝            *
*            ██╔═══██╗   ██║          ██║ ████╗            *
*            ██║   ██║   ██║   ██╗    ██║ ╚═██║            *
*            ███████╔╝    ██████╔╝     ██████╔╝            *
*            ╚══════╝     ╚═════╝      ╚═════╝             *
*                                                          *
*                www.BusinessCompany.Global                *
*                                                          *
************************************************************ 
***********************************************************/



pragma solidity >=0.4.23 <0.6.0;



/**
* @title SafeMath
**/
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
        uint256 c = a / b;

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
**/
contract Ownable  {

    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }


    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

}



/**
* @title BusinessCompany
**/
contract BusinessCompany is Ownable {

    using SafeMath for uint;
    event amountTransfered(address indexed fromAddress,address contractAddress,address indexed toAddress, uint256 indexed amount);
    event TrxDeposited(address indexed beneficiary, uint amount);
    event amountWithdrawed(address indexed fromAddress,address contractAddress,address indexed toAddress, uint256 indexed amount);


    function depositCrypto() payable public returns (bool){
        uint256 amount = msg.value;
        address userAddress = msg.sender;
        emit TrxDeposited(userAddress, amount);

        return true;
    }


    function withdrawCrypto(address payable beneficiary, uint256 amount) public onlyOwner returns (bool) {
        beneficiary.transfer(amount);
        emit amountWithdrawed(msg.sender,address(this) ,beneficiary,amount);

        return true;
    }


    function transferCrypto(uint256[] memory amounts, address payable[] memory receivers) payable public  onlyOwner returns (bool){
        uint total = 0;
        
        require(amounts.length == receivers.length);
        require(receivers.length <= 100);
        
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


    function cryptoBalance() public view returns (uint256){
        return address(this).balance;
    }

}



/**
* @end Powered By: Neurs Technologies
**/