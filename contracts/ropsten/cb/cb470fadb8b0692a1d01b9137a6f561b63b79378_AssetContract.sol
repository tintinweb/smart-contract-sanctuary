pragma solidity ^0.4.23;

contract KTC_Contract {
    
    function transfer(address _to, uint256 _value) returns(bool ok) ;
    function balanceOf(address _address ) returns(uint256) ;
    function treasurer() returns(address);
    
    
}


contract KTCWhitelist {
    
    function checkAddress ( address _address ) public returns(bool);
    
    
}



contract BuyOffer {
    
    
    string public offertype = &quot;Offer to Buy&quot;;
    address public AssetContractAddress;
    address public OfferAddress;
    uint public numberofdays;
    uint public offeramount;
    uint public sharenumber;
    
    address public KTC_Address;
    KTC_Contract public ktccontract;
    
    
    AssetContract public assetcontract;
    
    bool public OfferActive;
    bool public OfferFunded;
    uint public offerNumber;
    
    
    modifier onlyOfferer() {
		require( msg.sender == OfferAddress );
		_;
	}
    
    
    function BuyOffer ( address _AssetContractAddress, address _OfferAddress , uint _numberofdays, uint _offeramount, uint _sharenumber, uint _offernumber ){
        
        KTC_Address = 0x394Ab23984D9dDF7C4b9E6d02E0d9E65F38027C5;
        ktccontract = KTC_Contract ( KTC_Address);
        
        AssetContractAddress = _AssetContractAddress;
        assetcontract = AssetContract( AssetContractAddress );
        
        OfferAddress = _OfferAddress;
        numberofdays = _numberofdays;
        offeramount = _offeramount;
        OfferActive = true;
        sharenumber = _sharenumber;
        offerNumber = _offernumber;
        
       
        
    }
    
    function tokenFallback ( address _address, uint _value  ){
       
       require ( offeramount == _value );
       OfferFunded = true;
       
       
        
    }
    
    function acceptOffer( uint _share, string _dochash ){
        
        require ( OfferActive == true );
        if ( sharenumber != 0 ) require ( _share == sharenumber );
        require (  assetcontract.isMember( msg.sender) );
        require (  assetcontract.memberShare( _share ) == msg.sender );
        
        OfferActive = false;
        ktccontract.transfer( msg.sender,  ktccontract.balanceOf(this) );
      //  assetcontract.updateMember( msg.sender, OfferAddress, _share,  offeramount, _dochash, offerNumber );
        
        
        
    }
   
    function cancelOffer() public onlyOfferer {
       
       require ( OfferActive == true );
       OfferActive = false;
       ktccontract.transfer( msg.sender,  ktccontract.balanceOf(this) );
       
       
    }
   
    
    
    
}

contract WhiteListChecker {
    
      address public whiteListContractAddress = 0x4C4F7914fA951e6DfE3a8D688dbc6197831495f4;
      KTCWhitelist public whitelistcontract = KTCWhitelist ( whiteListContractAddress );
      
}



contract SellOffer  {
    
    
    string public offertype = &quot;Offer to Sell&quot;;
    address public AssetContractAddress;
    address public OffererAddress;
    uint public numberofdays;
    uint public offeramount;
    uint public sharenumber;
    
    address public KTC_Address;
    KTC_Contract public ktccontract;
    
    
    AssetContract public assetcontract;
    
    bool public OfferActive;
    uint public offerNumber;
    
    
    modifier onlyOfferer() {
		require( msg.sender == OffererAddress );
		_;
	}
	

    
    
    function SellOffer ( address _AssetContractAddress, address _OffererAddress , uint _numberofdays, uint _offeramount, uint _sharenumber, uint _offernumber ){
        
        KTC_Address = 0x394Ab23984D9dDF7C4b9E6d02E0d9E65F38027C5;
        ktccontract = KTC_Contract ( KTC_Address);
        
        AssetContractAddress = _AssetContractAddress;
        assetcontract = AssetContract( AssetContractAddress );
        
        OffererAddress = _OffererAddress;
        numberofdays = _numberofdays;
        offeramount = _offeramount;
        OfferActive = true;
        sharenumber = _sharenumber;
        offerNumber = _offernumber;
        
    }
    
    
    
    function acceptOffer( string _dochash ){
        
        require ( ktccontract.balanceOf( msg.sender ) >= offeramount ) ;
      //  assetcontract.updateMember( OffererAddress , msg.sender , sharenumber, offeramount, _dochash, offerNumber );
        ktccontract.transfer ( OffererAddress, offeramount );
        
    }
   
    function cancelOffer() public onlyOfferer {
       
       OfferActive = false;
    
        
    }
   
    
    
    
}




contract Bookings {
    
    
    mapping ( uint => address ) public allBookings;  
    mapping ( uint => uint )    public bookingReference;
    
    uint public totalbookings;
    address[] public bookingsAddress;
    
    
}

contract Offerable {
    
    
    mapping ( address => bool ) public allOffers;   
    
    
    
    uint public offers;
    address[] public offerAddress;
    
    
    struct transaction  {
        
        address buyer;
        address seller;
        uint price;
        string dochash;
        uint trantime;
        uint offernumber;
        
    }
    
    
    transaction[] public transactions;
    
    
    
    function createTransaction ( address _buyer, address _seller, uint _price, string _dochash, uint _trantime, uint _offernumber ) internal {
        
        transactions.push (  transaction( _buyer, _seller, _price, _dochash, _trantime, _offernumber )  );
        
        
    }
    
    
    
    
}


//contract AssetContract is Bookings, Offerable, WhiteListChecker  {

contract AssetContract  is Bookings, Offerable, WhiteListChecker  {
    
    address public KTC_Address;
    KTC_Contract public ktccontract;
    address[] public members;
    
    bool public initialize;
    
    event Say ( address _address );
    
  

    
    
    modifier onlyOffers() {
		require( allOffers[msg.sender] == true );
		_;
	}
    
   
    
    
    
    
    function AssetContract () {
        
          KTC_Address = 0x394Ab23984D9dDF7C4b9E6d02E0d9E65F38027C5;
          ktccontract = KTC_Contract ( KTC_Address);
       
          init();
        
    }
    
    function init() internal  {
       
        
        for ( uint i = 0; i < 13; i++ ){
          
            
            members.push( ktccontract.treasurer());
            
        }
        
        
       offers = 0;
        
    }
    
    
   
    
    
    function tokenFallback ( address _address, uint _value, bytes _data, string _stringdata, uint256 _numdata ){
        
        require ( _numdata != 0x0 );
        require ( msg.sender == KTC_Address );
        
        if ( keccak256( _data ) == keccak256(&quot;1&quot;) ) { book ( _address, _value, _numdata ); }
        
    }
    
   
   
   function book ( address _address, uint _value, uint _numdata ) internal {
       
      totalbookings++;
      bookingReference[ totalbookings ] = _numdata;
      allBookings[ _numdata ] = _address;
       
       
       
       uint share = _value/13;
       
       for ( uint i = 0; i < 13; i++ ){
           
           ktccontract.transfer( members[i] , share);
           
       }
       
   } 
   
   
   
   function isMember( address _address) public returns(bool) {
       
        for ( uint i = 0; i < 13; i++ ){
           if( members[i] == _address ) return true;
        }
       return false;
       
   }
   
   function memberShare( uint _share ) public returns (address) {
       
          return members[_share];
       
   }

 
    
    function Buy_Offer ( uint _offeramount, uint _numberofdays, uint _sharenumber ) {
        
        require ( whitelistcontract.checkAddress ( msg.sender ) );
        offers++;
        BuyOffer buyoffer = new BuyOffer( address(this), msg.sender , _numberofdays,  _offeramount, _sharenumber, offers );
        allOffers[ buyoffer ] = true;
        offerAddress.push(buyoffer);
        
        ktccontract.transfer( buyoffer,  _offeramount );
        
    }  
    
    
    function Sell_Offer ( uint _offeramount, uint _numberofdays, uint _sharenumber ) {
        
        require ( memberShare ( _sharenumber ) == msg.sender );
        offers++;
        SellOffer selloffer = new SellOffer( address(this), msg.sender , _numberofdays,  _offeramount, _sharenumber, offers );
        allOffers[ selloffer ] = true;
        offerAddress.push(selloffer);
        
    }
    
    
    function updateMember( address _oldmember, address _newmember, uint _numbershare, uint _price, string _dochash, uint _offernumber ) onlyOffers{
        
        require ( whitelistcontract.checkAddress ( _newmember ) );
        require ( members[_numbershare] == _oldmember );
        createTransaction ( _newmember, _oldmember,  _price,  _dochash, now ,  _offernumber );
        
        members[_numbershare] = _newmember;
        
    }
    
    
    
    
}