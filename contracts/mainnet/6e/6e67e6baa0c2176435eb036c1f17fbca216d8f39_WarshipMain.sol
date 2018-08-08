pragma solidity ^0.4.18;
pragma solidity ^0.4.18;

//It&#39;s open source,but... ;) Good luck! :P
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

contract Beneficiary is Ownable {

    address public beneficiary;

    function setBeneficiary(address _beneficiary) onlyOwner public {
        beneficiary = _beneficiary;
    }


}


contract Pausable is Beneficiary{
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
} 

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


contract WarshipAccess is Pausable{
	address[] public OfficialApps;
	//Official games & services

	function AddOfficialApps(address _app) onlyOwner public{
		require(_app != address(0));
		OfficialApps.push(_app);
	}
	
	function nukeApps()onlyOwner public{
	    for(uint i = 0; i < OfficialApps.length; i++){
			delete OfficialApps[i];
	        
	    }
	}

	function _isOfficialApps(address _app) internal view returns (bool){
		for(uint i = 0; i < OfficialApps.length; i++){
			if( _app == OfficialApps[i] ){
				return true;
			}
		}
		return false;
	}

	modifier OnlyOfficialApps {
        require(_isOfficialApps(msg.sender));
        _;
    }



}




//main contract for warship

contract WarshipMain is WarshipAccess{
    
    using SafeMath for uint256;

    struct Warship {
        uint128 appearance; //wsic code for producing warship outlook
        uint32 profile;//profile including ship names
        uint8 firepower;
        uint8 armor;
        uint8 hitrate;
        uint8 speed;
        uint8 duration;//ship strength
        uint8 shiptype;//ship class
        uint8 level;//strengthening level
        uint8 status;//how it was built
        uint16 specials;//16 specials
        uint16 extend;
    }//128+32+8*8+16*2=256

    Warship[] public Ships;
    mapping (uint256 => address) public ShipIdToOwner;
    //Supporting 2^32 ships at most.
    mapping (address => uint256) OwnerShipCount;
    //Used internally inside balanceOf() to resolve ownership count.
    mapping (uint256 => address) public ShipIdToApproval;
    //Each ship can only have one approved address for transfer at any time.
    mapping (uint256 => uint256) public ShipIdToStatus;
    //0 for sunk, 1 for live, 2 for min_broken, 3 for max_broken, 4 for on_marketing, 5 for in_pvp
    //256 statuses at most.
    

    //SaleAuction
    address public SaleAuction;
    function setSaleAuction(address _sale) onlyOwner public{
        require(_sale != address(0));
        SaleAuction = _sale;
    }



    //event emitted when ship created or updated
    event NewShip(address indexed owner, uint indexed shipId, uint256 wsic);
    event ShipStatusUpdate(uint indexed shipId, uint8 newStatus);
    event ShipStructUpdate(uint indexed shipId, uint256 wsic);

    //----erc721 interface
    bool public implementsERC721 = true;
    string public constant name = "EtherWarship";
    string public constant symbol = "SHIP";
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); 
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    function balanceOf(address _owner) public view returns (uint256 _balance){
        return OwnerShipCount[_owner];
    }
    function ownerOf(uint256 _tokenId) public view returns (address _owner){
        return ShipIdToOwner[_tokenId];
    }
    //function transfer(address _to, uint256 _tokenId) public;   //see below
    //function approve(address _to, uint256 _tokenId) public;    //see below
    //function takeOwnership(uint256 _tokenId) public;      //see below
    //----erc721 interface


    

    //check if owned/approved
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ShipIdToOwner[_tokenId] == _claimant;
    }
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ShipIdToApproval[_tokenId] == _claimant;
    }


    /// @dev Assigns ownership of a specific ship to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        OwnerShipCount[_to]=OwnerShipCount[_to].add(1);
        ShipIdToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            OwnerShipCount[_from]=OwnerShipCount[_from].sub(1);
            // clear any previously approved ownership exchange
            delete ShipIdToApproval[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    function _approve(uint256 _tokenId, address _approved) internal {
        ShipIdToApproval[_tokenId] = _approved;
    }

    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId) external whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));
        // You can only send your own cat.
        require(_owns(msg.sender, _tokenId));
        // Reassign ownership, clear pending approvals, emit Transfer event.
        require(ShipIdToStatus[_tokenId]==1||msg.sender==SaleAuction);
        // Ship must be alive.

        if(msg.sender == SaleAuction){
            ShipIdToStatus[_tokenId] = 1;
        }

        _transfer(msg.sender, _to, _tokenId);

    }

    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _tokenId) external whenNotPaused {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));
        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);
        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));
        // Check for approval and valid ownersh ip
        //p.s. SaleAuction can call transferFrom for anyone
        require(_approvedFor(msg.sender, _tokenId)||msg.sender==SaleAuction); 

        require(_owns(_from, _tokenId));

        require(ShipIdToStatus[_tokenId]==1);
        // Ship must be alive.

        if(msg.sender == SaleAuction){
            ShipIdToStatus[_tokenId] = 4;
        }


        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return Ships.length;
    }

    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _tokenId) public {
        // check approvals
        require(ShipIdToApproval[_tokenId] == msg.sender);

        require(ShipIdToStatus[_tokenId]==1);
        // Ship must be alive.

        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }


    //------------all ERC-721 requirement are present----------------------





    /// @dev uint256 WSIC to warship structure 
    function _translateWSIC (uint256 _wsic) internal pure returns(Warship){
  //    uint128 _appearance = uint128(_wsic >> 128);
  //    uint32 _profile = uint32((_wsic>>96)&0xffffffff);
  //    uint8 _firepower = uint8((_wsic>>88)&0xff);
        // uint8 _armor = uint8((_wsic>>80)&0xff);
        // uint8 _hitrate = uint8((_wsic>>72)&0xff);
        // uint8 _speed = uint8((_wsic>>64)&0xff);
        // uint8 _duration = uint8((_wsic>>56)&0xff);
        // uint8 _shiptype = uint8((_wsic>>48)&0xff);
        // uint8 _level = uint8((_wsic>>40)&0xff);
        // uint8 _status = uint8((_wsic>>32)&0xff);
        // uint16 _specials = uint16((_wsic>>16)&0xffff);
        // uint16 _extend = uint16(_wsic&0xffff);
        Warship memory  _ship = Warship(uint128(_wsic >> 128), uint32((_wsic>>96)&0xffffffff), uint8((_wsic>>88)&0xff), uint8((_wsic>>80)&0xff), uint8((_wsic>>72)&0xff), uint8((_wsic>>64)&0xff),
         uint8((_wsic>>56)&0xff), uint8((_wsic>>48)&0xff), uint8((_wsic>>40)&0xff), uint8((_wsic>>32)&0xff),  uint16((_wsic>>16)&0xffff), uint16(_wsic&0xffff));
        return _ship;
    }
    function _encodeWSIC(Warship _ship) internal pure returns(uint256){
        uint256 _wsic = 0x00;
        _wsic = _wsic ^ (uint256(_ship.appearance) << 128);
        _wsic = _wsic ^ (uint256(_ship.profile) << 96);
        _wsic = _wsic ^ (uint256(_ship.firepower) << 88);
        _wsic = _wsic ^ (uint256(_ship.armor) << 80);
        _wsic = _wsic ^ (uint256(_ship.hitrate) << 72);
        _wsic = _wsic ^ (uint256(_ship.speed) << 64);
        _wsic = _wsic ^ (uint256(_ship.duration) << 56);
        _wsic = _wsic ^ (uint256(_ship.shiptype) << 48);
        _wsic = _wsic ^ (uint256(_ship.level) << 40);
        _wsic = _wsic ^ (uint256(_ship.status) << 32);
        _wsic = _wsic ^ (uint256(_ship.specials) << 16);
        _wsic = _wsic ^ (uint256(_ship.extend));
        return _wsic;
    }


    

    // @dev An internal method that creates a new ship and stores it. This
    ///  method doesn&#39;t do any checking and should only be called when the
    ///  input data is known to be valid. 
    function _createship (uint256 _wsic, address _owner) internal returns(uint){
        //wsic2ship
        Warship memory _warship = _translateWSIC(_wsic);
        //push into ships
        uint256 newshipId = Ships.push(_warship) - 1;
        //emit event
        NewShip(_owner, newshipId, _wsic);
        //set to alive
        ShipIdToStatus[newshipId] = 1;
        //transfer 0 to owner
        _transfer(0, _owner, newshipId);
        //"Where is the counter?Repeat that.Where is the counter?Everyone want to know it.----Troll XI"
       
        

        return newshipId; 
    }

    /// @dev An internal method that update a new ship. 
    function _update (uint256 _wsic, uint256 _tokenId) internal returns(bool){
        //check if id is valid
        require(_tokenId <= totalSupply());
        //wsic2ship
        Warship memory _warship = _translateWSIC(_wsic);
        //emit event
        ShipStructUpdate(_tokenId, _wsic);
        //update
        Ships[_tokenId] = _warship;

        return true;
    }


    /// @dev Allow official apps to create ship.
    function createship(uint256 _wsic, address _owner) external OnlyOfficialApps returns(uint){
        //check address
        require(_owner != address(0));
        return _createship(_wsic, _owner);
    }

    /// @dev Allow official apps to update ship.
    function updateship (uint256 _wsic, uint256 _tokenId) external OnlyOfficialApps returns(bool){
        return _update(_wsic, _tokenId);
    }
    /// @dev Allow official apps to update ship.
    function SetStatus(uint256 _tokenId, uint256 _status) external OnlyOfficialApps returns(bool){
        require(uint8(_status)==_status);
        ShipIdToStatus[_tokenId] = _status;
        ShipStatusUpdate(_tokenId, uint8(_status));
        return true;
    }






    /// @dev Get wsic code for a ship.
    function Getwsic(uint256 _tokenId) external view returns(uint256){
        //check if id is valid
        require(_tokenId < Ships.length);
        uint256 _wsic = _encodeWSIC(Ships[_tokenId]);
        return _wsic;
    }

    /// @dev Get ships for a specified user.
    function GetShipsByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](OwnerShipCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < Ships.length; i++) {
          if (ShipIdToOwner[i] == _owner) {
            result[counter] = i;
            counter++;
          }
        }
    return result;
    }

    /// @dev Get status
    function GetStatus(uint256 _tokenId) external view returns(uint){
        return ShipIdToStatus[_tokenId];
    }



}