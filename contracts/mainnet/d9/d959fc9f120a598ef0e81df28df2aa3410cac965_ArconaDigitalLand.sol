pragma solidity 0.4.24;

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

contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    //    function renounceOwnership() public onlyOwner {
    //        emit OwnershipRenounced(owner);
    //        owner = address(0);
    //    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



contract LandTokenInterface {
    //ERC721
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _landId) public view returns (address _owner);
    function transfer(address _to, uint256 _landId) public;
    function approve(address _to, uint256 _landId) public;
    function takeOwnership(uint256 _landId) public;
    function totalSupply() public view returns (uint);
    function owns(address _claimant, uint256 _landId) public view returns (bool);
    function allowance(address _claimant, uint256 _landId) public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _landId) public;
    function createLand(address _owner) external returns (uint);
}

interface tokenRecipient {
    function receiveApproval(address _from, address _token, uint _value, bytes _extraData) external;
    function receiveCreateAuction(address _from, address _token, uint _landId, uint _startPrice, uint _duration) external;
    function receiveCreateAuctionFromArray(address _from, address _token, uint[] _landIds, uint _startPrice, uint _duration) external;
}

contract LandBase is Ownable {
    using SafeMath for uint;

    event Transfer(address indexed from, address indexed to, uint256 landId);
    event Approval(address indexed owner, address indexed approved, uint256 landId);
    event NewLand(address indexed owner, uint256 landId);

    struct Land {
        uint id;
    }


    // Total amount of lands
    uint256 private totalLands;

    // Incremental counter of lands Id
    uint256 private lastLandId;

    //Mapping from land ID to Land struct
    mapping(uint256 => Land) public lands;

    // Mapping from land ID to owner
    mapping(uint256 => address) private landOwner;

    // Mapping from land ID to approved address
    mapping(uint256 => address) private landApprovals;

    // Mapping from owner to list of owned lands IDs
    mapping(address => uint256[]) private ownedLands;

    // Mapping from land ID to index of the owner lands list
    // т.е. ID земли => порядковый номер в списке владельца
    mapping(uint256 => uint256) private ownedLandsIndex;


    modifier onlyOwnerOf(uint256 _landId) {
        require(owns(msg.sender, _landId));
        _;
    }

    /**
    * @dev Gets the owner of the specified land ID
    * @param _landId uint256 ID of the land to query the owner of
    * @return owner address currently marked as the owner of the given land ID
    */
    function ownerOf(uint256 _landId) public view returns (address) {
        return landOwner[_landId];
    }

    function totalSupply() public view returns (uint256) {
        return totalLands;
    }

    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return ownedLands[_owner].length;
    }

    /**
    * @dev Gets the list of lands owned by a given address
    * @param _owner address to query the lands of
    * @return uint256[] representing the list of lands owned by the passed address
    */
    function landsOf(address _owner) public view returns (uint256[]) {
        return ownedLands[_owner];
    }

    /**
    * @dev Gets the approved address to take ownership of a given land ID
    * @param _landId uint256 ID of the land to query the approval of
    * @return address currently approved to take ownership of the given land ID
    */
    function approvedFor(uint256 _landId) public view returns (address) {
        return landApprovals[_landId];
    }

    /**
    * @dev Tells whether the msg.sender is approved for the given land ID or not
    * This function is not private so it can be extended in further implementations like the operatable ERC721
    * @param _owner address of the owner to query the approval of
    * @param _landId uint256 ID of the land to query the approval of
    * @return bool whether the msg.sender is approved for the given land ID or not
    */
    function allowance(address _owner, uint256 _landId) public view returns (bool) {
        return approvedFor(_landId) == _owner;
    }

    /**
    * @dev Approves another address to claim for the ownership of the given land ID
    * @param _to address to be approved for the given land ID
    * @param _landId uint256 ID of the land to be approved
    */
    function approve(address _to, uint256 _landId) public onlyOwnerOf(_landId) returns (bool) {
        require(_to != msg.sender);
        if (approvedFor(_landId) != address(0) || _to != address(0)) {
            landApprovals[_landId] = _to;
            emit Approval(msg.sender, _to, _landId);
            return true;
        }
    }


    function approveAndCall(address _spender, uint256 _landId, bytes _extraData) public returns (bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _landId)) {
            spender.receiveApproval(msg.sender, this, _landId, _extraData);
            return true;
        }
    }


    function createAuction(address _auction, uint _landId, uint _startPrice, uint _duration) public returns (bool) {
        tokenRecipient auction = tokenRecipient(_auction);
        if (approve(_auction, _landId)) {
            auction.receiveCreateAuction(msg.sender, this, _landId, _startPrice, _duration);
            return true;
        }
    }


    function createAuctionFromArray(address _auction, uint[] _landIds, uint _startPrice, uint _duration) public returns (bool) {
        tokenRecipient auction = tokenRecipient(_auction);

        for (uint i = 0; i < _landIds.length; ++i)
            require(approve(_auction, _landIds[i]));

        auction.receiveCreateAuctionFromArray(msg.sender, this, _landIds, _startPrice, _duration);
        return true;
    }

    /**
    * @dev Claims the ownership of a given land ID
    * @param _landId uint256 ID of the land being claimed by the msg.sender
    */
    function takeOwnership(uint256 _landId) public {
        require(allowance(msg.sender, _landId));
        clearApprovalAndTransfer(ownerOf(_landId), msg.sender, _landId);
    }

    /**
    * @dev Transfers the ownership of a given land ID to another address
    * @param _to address to receive the ownership of the given land ID
    * @param _landId uint256 ID of the land to be transferred
    */
    function transfer(address _to, uint256 _landId) public onlyOwnerOf(_landId) returns (bool) {
        clearApprovalAndTransfer(msg.sender, _to, _landId);
        return true;
    }


    /**
    * @dev Internal function to clear current approval and transfer the ownership of a given land ID
    * @param _from address which you want to send lands from
    * @param _to address which you want to transfer the land to
    * @param _landId uint256 ID of the land to be transferred
    */
    function clearApprovalAndTransfer(address _from, address _to, uint256 _landId) internal {
        require(owns(_from, _landId));
        require(_to != address(0));
        require(_to != ownerOf(_landId));

        clearApproval(_from, _landId);
        removeLand(_from, _landId);
        addLand(_to, _landId);
        emit Transfer(_from, _to, _landId);
    }

    /**
    * @dev Internal function to clear current approval of a given land ID
    * @param _landId uint256 ID of the land to be transferred
    */
    function clearApproval(address _owner, uint256 _landId) private {
        require(owns(_owner, _landId));
        landApprovals[_landId] = address(0);
        emit Approval(_owner, address(0), _landId);
    }

    /**
    * @dev Internal function to add a land ID to the list of a given address
    * @param _to address representing the new owner of the given land ID
    * @param _landId uint256 ID of the land to be added to the lands list of the given address
    */
    function addLand(address _to, uint256 _landId) private {
        require(landOwner[_landId] == address(0));
        landOwner[_landId] = _to;

        uint256 length = ownedLands[_to].length;
        ownedLands[_to].push(_landId);
        ownedLandsIndex[_landId] = length;
        totalLands = totalLands.add(1);
    }

    /**
    * @dev Internal function to remove a land ID from the list of a given address
    * @param _from address representing the previous owner of the given land ID
    * @param _landId uint256 ID of the land to be removed from the lands list of the given address
    */
    function removeLand(address _from, uint256 _landId) private {
        require(owns(_from, _landId));

        uint256 landIndex = ownedLandsIndex[_landId];
        //        uint256 lastLandIndex = balanceOf(_from).sub(1);
        uint256 lastLandIndex = ownedLands[_from].length.sub(1);
        uint256 lastLand = ownedLands[_from][lastLandIndex];

        landOwner[_landId] = address(0);
        ownedLands[_from][landIndex] = lastLand;
        ownedLands[_from][lastLandIndex] = 0;
        // Note that this will handle single-element arrays. In that case, both landIndex and lastLandIndex are going to
        // be zero. Then we can make sure that we will remove _landId from the ownedLands list since we are first swapping
        // the lastLand to the first position, and then dropping the element placed in the last position of the list

        ownedLands[_from].length--;
        ownedLandsIndex[_landId] = 0;
        ownedLandsIndex[lastLand] = landIndex;
        totalLands = totalLands.sub(1);
    }


    function createLand(address _owner, uint _id) onlyOwner public returns (uint) {
        require(_owner != address(0));
        uint256 _landId = lastLandId++;
        addLand(_owner, _landId);
        //store new land data
        lands[_landId] = Land({
            id : _id
            });
        emit Transfer(address(0), _owner, _landId);
        emit NewLand(_owner, _landId);
        return _landId;
    }

    function createLandAndAuction(address _owner, uint _id, address _auction, uint _startPrice, uint _duration) onlyOwner public
    {
        uint id = createLand(_owner, _id);
        require(createAuction(_auction, id, _startPrice, _duration));
    }


    function owns(address _claimant, uint256 _landId) public view returns (bool) {
        return ownerOf(_landId) == _claimant && ownerOf(_landId) != address(0);
    }


    function transferFrom(address _from, address _to, uint256 _landId) public returns (bool) {
        require(_to != address(this));
        require(allowance(msg.sender, _landId));
        clearApprovalAndTransfer(_from, _to, _landId);
        return true;
    }

}


contract ArconaDigitalLand is LandBase {
    string public constant name = " Arcona Digital Land";
    string public constant symbol = "ARDL";

    function() public payable{
        revert();
    }
}