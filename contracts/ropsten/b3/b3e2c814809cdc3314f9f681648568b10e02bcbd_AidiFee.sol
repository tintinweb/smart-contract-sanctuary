/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: UNLICENSED



pragma solidity ^0.8.0;

interface IInterfaceAidiFee {
    function getServiceFee() external view returns (uint256);
    function getTokenFee(string memory _type)external view returns(uint256);
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public{
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) internal onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AidiFee is Ownable, IInterfaceAidiFee{
    struct tokenfee {
       address tokenAddress;
       uint256 tokenfee;
   }
    // struct TokenList {
    //     string  TokenName; 
    // }

    string[] tokendata;
   mapping(string => tokenfee) public Tokendetail;
   mapping(string => address) private tokentype;
   uint256 public  serviceValue ;


    function getServiceFee()public view virtual override returns(uint256){
        return serviceValue;
    }
    function serviceFunction(uint256 _serviceValue) public onlyOwner{
        serviceValue = _serviceValue;
    }


    function addTokenType(string memory _type,uint256 fee)
        public
        onlyOwner
    {
        tokenfee memory tokenfees;
        // tokenfees.tokenAddress = tokenAddress;
        tokenfees.tokenfee = fee;
        Tokendetail[_type] = tokenfees;
        tokendata.push(_type);
    }

    function getTokenFee(string memory _type)public view virtual override returns(uint256){
        return Tokendetail[_type].tokenfee;
    }

    function EditTokenType (string memory _type,uint256 fee)public onlyOwner{
        Tokendetail[_type].tokenfee=fee;
    }

    function DeleteTokenType (string memory _type) public onlyOwner{
        delete Tokendetail[_type];
         for (uint256 i = 0; i < tokendata.length; i++) { 
            if(keccak256(bytes(tokendata[i])) == keccak256(bytes(_type))){
                tokendata[i] = tokendata[tokendata.length - 1];
                tokendata.pop();
                break;
            }

        }
    }

    function getAllTokens() public view returns (string[] memory) {
        return tokendata;
    }
    
}