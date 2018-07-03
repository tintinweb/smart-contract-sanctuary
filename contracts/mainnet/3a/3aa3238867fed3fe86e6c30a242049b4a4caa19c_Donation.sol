pragma solidity ^0.4.24;


// The contract for the locaToken instance
contract locaToken {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint);
}

// Safemath library  
library SafeMath {
    function sub(uint _base, uint _value)
    internal
    pure
    returns (uint) {
        assert(_value <= _base);
        return _base - _value;
    }

    function add(uint _base, uint _value)
    internal
    pure
    returns (uint _ret) {
        _ret = _base + _value;
        assert(_ret >= _base);
    }

    function div(uint _base, uint _value)
    internal
    pure
    returns (uint) {
        assert(_value > 0 && (_base % _value) == 0);
        return _base / _value;
    }

    function mul(uint _base, uint _value)
    internal
    pure
    returns (uint _ret) {
        _ret = _base * _value;
        assert(0 == _base || _ret / _base == _value);
    }
}



// The donation contract

contract Donation  {
    using SafeMath for uint;
    // instance the locatoken
    locaToken private token = locaToken(0xcDf9bAff52117711B33210AdE38f1180CFC003ed);
    address  private owner;

    uint private _tokenGift;
    // every donation is logged in the Blockchain
    event Donated(address indexed buyer, uint tokens);
     // Available tokens for donation
    uint private _tokenDonation;
  

    // constructor to set the contract owner
    constructor() public {

        owner = msg.sender; 
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    // Allow the donation to start
    modifier allowStart() {
        require(_tokenDonation == 0);
        _;
    }
    // There have at least to be 25000000000 Loca tokens in balance to allow a valid donation
    modifier allowDonation(){
        require(_tokenDonation >= 25000000000);
        _;
    }
    // Donation amount has to be between 0.02 and 0.03 ETH
    // regardless the donation amount,  250 LOCAs will be send 
    modifier validDonation {
        require (msg.value >= 20000000000000000 && msg.value <= 30000000000000000);                                                                                        
        _;
    }


    function startDonation() public onlyOwner allowStart returns (uint) {

        _tokenDonation = token.allowance(owner, address(this));
    }


    function DonateEther() public allowDonation validDonation payable {

       //  _tokensold = msg.value.mul(_convrate).div(Devider);
        _tokenGift = 25000000000;
        _tokenDonation = _tokenDonation.sub(_tokenGift);
        
        emit Donated(msg.sender, _tokenGift);

        token.transferFrom(owner, msg.sender, _tokenGift);

        

    }

    // Falsely send Ether will be reverted
    function () public payable {
        revert();
    }


    function TokenBalance () public view returns(uint){

        return _tokenDonation;

    }

    // Withdraw Ether from the contract
    function getDonation(address _to) public onlyOwner {
       
        _to.transfer(address(this).balance);
    
    } 

    function CloseDonation() public onlyOwner {

        selfdestruct(owner);
    }

}