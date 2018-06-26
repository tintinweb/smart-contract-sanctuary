pragma solidity ^0.4.24;

contract locaToken {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public constant returns (uint);
}


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



// de transfer van tokens verloopt via de originele token
// import &quot;./MyToken.sol&quot;;
// import &quot;.SafeMath.sol&quot; ;
//
contract Donation  {
    using SafeMath for uint;
    // maak een copie
    locaToken private token = locaToken(0xEd1C9a256f5F84fA8ec7D29F66a0F1d32B3499dC);
    address  private owner;

    uint private _tokenGift;

    event Donated(address buyer, uint tokens);
     // Voor het bijhouden van de beschikbare tokens
    uint private _tokenDonation;

    // de conversie en wei deler voorhet zetten van de juiste hoeveelheid tokens
    // uint private constant _convrate = 1250000000000;
    // uint private constant Devider = 10 ** 18;

// constructor voor het zetten van de eigenaar
    constructor () public {

        owner = msg.sender; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier allowStart() {
        require(_tokenDonation == 0);
        _;
    }

    modifier allowSale(){
        require(_tokenDonation >= 25000000000);
        _;
    }

    modifier validDonation {
        require (msg.value >= 20000000000000000 && msg.value <= 30000000000000000);                                                                                        
        _;
    }


    function startCrowdSale () public onlyOwner allowStart returns (uint) {

        _tokenDonation = token.allowance(owner, address(this));
    }


    function DonateEther() public allowSale validDonation payable {

       //  _tokensold = msg.value.mul(_convrate).div(Devider);
        _tokenGift = 25000000000;
        _tokenDonation = _tokenDonation.sub(_tokenGift);
        
        emit Donated(msg.sender, _tokenGift);

        token.transferFrom(owner, msg.sender, _tokenGift);

        

    }

    function () public payable {
        revert();
    }


    function TokenBalance () public view returns(uint){

        return _tokenDonation;

    }

    function getDonation(address _to) public onlyOwner {
        // Deze functie verzendt de ontvangen Ether naar de contract eigenaar
        _to.transfer(address(this).balance);
    
    } 

    function CloseSale() public onlyOwner {

        selfdestruct(owner);
    }

}