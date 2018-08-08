pragma solidity ^0.4.21;

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

contract UnicornManagementInterface {

    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
    function blackBoxAddress() external view returns (address);
    function unicornBreedingAddress() external view returns (address);
    function geneLabAddress() external view returns (address);
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function candyPowerToken() external view returns (address);

    function createDividendPercent() external view returns (uint);
    function sellDividendPercent() external view returns (uint);
    function subFreezingPrice() external view returns (uint);
    function subFreezingTime() external view returns (uint64);
    function subTourFreezingPrice() external view returns (uint);
    function subTourFreezingTime() external view returns (uint64);
    function createUnicornPrice() external view returns (uint);
    function createUnicornPriceInCandy() external view returns (uint);
    function oraclizeFee() external view returns (uint);

    function paused() external view returns (bool);
    //    function locked() external view returns (bool);

    function isTournament(address _tournamentAddress) external view returns (bool);

    function getCreateUnicornFullPrice() external view returns (uint);
    function getHybridizationFullPrice(uint _price) external view returns (uint);
    function getSellUnicornFullPrice(uint _price) external view returns (uint);
    function getCreateUnicornFullPriceInCandy() external view returns (uint);


    //service
    function registerInit(address _contract) external;

}

contract UnicornAccessControl {

    UnicornManagementInterface public unicornManagement;

    function UnicornAccessControl(address _unicornManagementAddress) public {
        unicornManagement = UnicornManagementInterface(_unicornManagementAddress);
        unicornManagement.registerInit(this);
    }

    modifier onlyOwner() {
        require(msg.sender == unicornManagement.ownerAddress());
        _;
    }

    modifier onlyManager() {
        require(msg.sender == unicornManagement.managerAddress());
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == unicornManagement.communityAddress());
        _;
    }

    modifier onlyTournament() {
        require(unicornManagement.isTournament(msg.sender));
        _;
    }

    modifier whenNotPaused() {
        require(!unicornManagement.paused());
        _;
    }

    modifier whenPaused {
        require(unicornManagement.paused());
        _;
    }


    modifier onlyManagement() {
        require(msg.sender == address(unicornManagement));
        _;
    }

    modifier onlyBreeding() {
        require(msg.sender == unicornManagement.unicornBreedingAddress());
        _;
    }

    modifier onlyGeneLab() {
        require(msg.sender == unicornManagement.geneLabAddress());
        _;
    }

    modifier onlyBlackBox() {
        require(msg.sender == unicornManagement.blackBoxAddress());
        _;
    }

    modifier onlyUnicornToken() {
        require(msg.sender == unicornManagement.unicornTokenAddress());
        _;
    }

    function isGamePaused() external view returns (bool) {
        return unicornManagement.paused();
    }
}

contract UnicornBreedingInterface {
    function deleteOffer(uint _unicornId) external;
    function deleteHybridization(uint _unicornId) external;
}


contract UnicornBase is UnicornAccessControl {
    using SafeMath for uint;
    UnicornBreedingInterface public unicornBreeding; //set on deploy

    event Transfer(address indexed from, address indexed to, uint256 unicornId);
    event Approval(address indexed owner, address indexed approved, uint256 unicornId);
    event UnicornGeneSet(uint indexed unicornId);
    event UnicornGeneUpdate(uint indexed unicornId);
    event UnicornFreezingTimeSet(uint indexed unicornId, uint time);
    event UnicornTourFreezingTimeSet(uint indexed unicornId, uint time);


    struct Unicorn {
        bytes gene;
        uint64 birthTime;
        uint64 freezingEndTime;
        uint64 freezingTourEndTime;
        string name;
    }

    uint8 maxFreezingIndex = 7;
    uint32[8] internal freezing = [
    uint32(1 hours),    //1 hour
    uint32(2 hours),    //2 - 4 hours
    uint32(8 hours),    //8 - 12 hours
    uint32(16 hours),   //16 - 24 hours
    uint32(36 hours),   //36 - 48 hours
    uint32(72 hours),   //72 - 96 hours
    uint32(120 hours),  //120 - 144 hours
    uint32(168 hours)   //168 hours
    ];

    //count for random plus from 0 to ..
    uint32[8] internal freezingPlusCount = [
    0, 3, 5, 9, 13, 25, 25, 0
    ];

    // Total amount of unicorns
    uint256 private totalUnicorns;

    // Incremental counter of unicorns Id
    uint256 private lastUnicornId;

    //Mapping from unicorn ID to Unicorn struct
    mapping(uint256 => Unicorn) public unicorns;

    // Mapping from unicorn ID to owner
    mapping(uint256 => address) private unicornOwner;

    // Mapping from unicorn ID to approved address
    mapping(uint256 => address) private unicornApprovals;

    // Mapping from owner to list of owned unicorn IDs
    mapping(address => uint256[]) private ownedUnicorns;

    // Mapping from unicorn ID to index of the owner unicorns list
    // т.е. ID уникорна => порядковый номер в списке владельца
    mapping(uint256 => uint256) private ownedUnicornsIndex;

    // Mapping from unicorn ID to approval for GeneLab
    mapping(uint256 => bool) private unicornApprovalsForGeneLab;

    modifier onlyOwnerOf(uint256 _unicornId) {
        require(owns(msg.sender, _unicornId));
        _;
    }

    /**
    * @dev Gets the owner of the specified unicorn ID
    * @param _unicornId uint256 ID of the unicorn to query the owner of
    * @return owner address currently marked as the owner of the given unicorn ID
    */
    function ownerOf(uint256 _unicornId) public view returns (address) {
        return unicornOwner[_unicornId];
        //        address owner = unicornOwner[_unicornId];
        //        require(owner != address(0));
        //        return owner;
    }

    function totalSupply() public view returns (uint256) {
        return totalUnicorns;
    }

    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return ownedUnicorns[_owner].length;
    }

    /**
    * @dev Gets the list of unicorns owned by a given address
    * @param _owner address to query the unicorns of
    * @return uint256[] representing the list of unicorns owned by the passed address
    */
    function unicornsOf(address _owner) public view returns (uint256[]) {
        return ownedUnicorns[_owner];
    }

    /**
    * @dev Gets the approved address to take ownership of a given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to query the approval of
    * @return address currently approved to take ownership of the given unicorn ID
    */
    function approvedFor(uint256 _unicornId) public view returns (address) {
        return unicornApprovals[_unicornId];
    }

    /**
    * @dev Tells whether the msg.sender is approved for the given unicorn ID or not
    * This function is not private so it can be extended in further implementations like the operatable ERC721
    * @param _owner address of the owner to query the approval of
    * @param _unicornId uint256 ID of the unicorn to query the approval of
    * @return bool whether the msg.sender is approved for the given unicorn ID or not
    */
    function allowance(address _owner, uint256 _unicornId) public view returns (bool) {
        return approvedFor(_unicornId) == _owner;
    }

    /**
    * @dev Approves another address to claim for the ownership of the given unicorn ID
    * @param _to address to be approved for the given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be approved
    */
    function approve(address _to, uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        //модификатор onlyOwnerOf гарантирует, что owner = msg.sender
        //        address owner = ownerOf(_unicornId);
        require(_to != msg.sender);
        if (approvedFor(_unicornId) != address(0) || _to != address(0)) {
            unicornApprovals[_unicornId] = _to;
            emit Approval(msg.sender, _to, _unicornId);
        }
    }

    /**
    * @dev Claims the ownership of a given unicorn ID
    * @param _unicornId uint256 ID of the unicorn being claimed by the msg.sender
    */
    function takeOwnership(uint256 _unicornId) public {
        require(allowance(msg.sender, _unicornId));
        clearApprovalAndTransfer(ownerOf(_unicornId), msg.sender, _unicornId);
    }

    /**
    * @dev Transfers the ownership of a given unicorn ID to another address
    * @param _to address to receive the ownership of the given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be transferred
    */
    function transfer(address _to, uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        clearApprovalAndTransfer(msg.sender, _to, _unicornId);
    }


    /**
    * @dev Internal function to clear current approval and transfer the ownership of a given unicorn ID
    * @param _from address which you want to send unicorns from
    * @param _to address which you want to transfer the unicorn to
    * @param _unicornId uint256 ID of the unicorn to be transferred
    */
    function clearApprovalAndTransfer(address _from, address _to, uint256 _unicornId) internal {
        require(owns(_from, _unicornId));
        require(_to != address(0));
        require(_to != ownerOf(_unicornId));

        clearApproval(_from, _unicornId);
        removeUnicorn(_from, _unicornId);
        addUnicorn(_to, _unicornId);
        emit Transfer(_from, _to, _unicornId);
    }

    /**
    * @dev Internal function to clear current approval of a given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be transferred
    */
    function clearApproval(address _owner, uint256 _unicornId) private {
        require(owns(_owner, _unicornId));
        unicornApprovals[_unicornId] = 0;
        emit Approval(_owner, 0, _unicornId);
    }

    /**
    * @dev Internal function to add a unicorn ID to the list of a given address
    * @param _to address representing the new owner of the given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be added to the unicorns list of the given address
    */
    function addUnicorn(address _to, uint256 _unicornId) private {
        require(unicornOwner[_unicornId] == address(0));
        unicornOwner[_unicornId] = _to;
        //        uint256 length = balanceOf(_to);
        uint256 length = ownedUnicorns[_to].length;
        ownedUnicorns[_to].push(_unicornId);
        ownedUnicornsIndex[_unicornId] = length;
        totalUnicorns = totalUnicorns.add(1);
    }

    /**
    * @dev Internal function to remove a unicorn ID from the list of a given address
    * @param _from address representing the previous owner of the given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be removed from the unicorns list of the given address
    */
    function removeUnicorn(address _from, uint256 _unicornId) private {
        require(owns(_from, _unicornId));

        uint256 unicornIndex = ownedUnicornsIndex[_unicornId];
        //        uint256 lastUnicornIndex = balanceOf(_from).sub(1);
        uint256 lastUnicornIndex = ownedUnicorns[_from].length.sub(1);
        uint256 lastUnicorn = ownedUnicorns[_from][lastUnicornIndex];

        unicornOwner[_unicornId] = 0;
        ownedUnicorns[_from][unicornIndex] = lastUnicorn;
        ownedUnicorns[_from][lastUnicornIndex] = 0;
        // Note that this will handle single-element arrays. In that case, both unicornIndex and lastUnicornIndex are going to
        // be zero. Then we can make sure that we will remove _unicornId from the ownedUnicorns list since we are first swapping
        // the lastUnicorn to the first position, and then dropping the element placed in the last position of the list

        ownedUnicorns[_from].length--;
        ownedUnicornsIndex[_unicornId] = 0;
        ownedUnicornsIndex[lastUnicorn] = unicornIndex;
        totalUnicorns = totalUnicorns.sub(1);

        //deleting sale offer, if exists
        //TODO check if contract exists?
        //        if (address(unicornBreeding) != address(0)) {
        unicornBreeding.deleteOffer(_unicornId);
        unicornBreeding.deleteHybridization(_unicornId);
        //        }
    }

    //specific
    //    function burnUnicorn(uint256 _unicornId) onlyOwnerOf(_unicornId) public  {
    //        if (approvedFor(_unicornId) != 0) {
    //            clearApproval(msg.sender, _unicornId);
    //        }
    //        removeUnicorn(msg.sender, _unicornId);
    //        //destroy unicorn data
    //        delete unicorns[_unicornId];
    //        emit Transfer(msg.sender, 0x0, _unicornId);
    //    }


    function createUnicorn(address _owner) onlyBreeding external returns (uint) {
        require(_owner != address(0));
        uint256 _unicornId = lastUnicornId++;
        addUnicorn(_owner, _unicornId);
        //store new unicorn data
        unicorns[_unicornId] = Unicorn({
            gene : new bytes(0),
            birthTime : uint64(now),
            freezingEndTime : 0,
            freezingTourEndTime: 0,
            name: &#39;&#39;
            });
        emit Transfer(0x0, _owner, _unicornId);
        return _unicornId;
    }


    function owns(address _claimant, uint256 _unicornId) public view returns (bool) {
        return ownerOf(_unicornId) == _claimant && ownerOf(_unicornId) != address(0);
    }


    function transferFrom(address _from, address _to, uint256 _unicornId) public {
        require(_to != address(this));
        require(allowance(msg.sender, _unicornId));
        clearApprovalAndTransfer(_from, _to, _unicornId);
    }


    function fromHexChar(uint8 _c) internal pure returns (uint8) {
        return _c - (_c < 58 ? 48 : (_c < 97 ? 55 : 87));
    }


    function getUnicornGenByte(uint _unicornId, uint _byteNo) public view returns (uint8) {
        uint n = _byteNo << 1; // = _byteNo * 2
        //        require(unicorns[_unicornId].gene.length >= n + 1);
        if (unicorns[_unicornId].gene.length < n + 1) {
            return 0;
        }
        return fromHexChar(uint8(unicorns[_unicornId].gene[n])) << 4 | fromHexChar(uint8(unicorns[_unicornId].gene[n + 1]));
    }


    function setName(uint256 _unicornId, string _name ) public onlyOwnerOf(_unicornId) returns (bool) {
        bytes memory tmp = bytes(unicorns[_unicornId].name);
        require(tmp.length == 0);

        unicorns[_unicornId].name = _name;
        return true;
    }


    function getGen(uint _unicornId) external view returns (bytes){
        return unicorns[_unicornId].gene;
    }

    function setGene(uint _unicornId, bytes _gene) onlyBlackBox external  {
        if (unicorns[_unicornId].gene.length == 0) {
            unicorns[_unicornId].gene = _gene;
            emit UnicornGeneSet(_unicornId);
        }
    }

    function updateGene(uint _unicornId, bytes _gene) onlyGeneLab public {
        require(unicornApprovalsForGeneLab[_unicornId]);
        delete unicornApprovalsForGeneLab[_unicornId];
        unicorns[_unicornId].gene = _gene;
        emit UnicornGeneUpdate(_unicornId);
    }

    function approveForGeneLab(uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        unicornApprovalsForGeneLab[_unicornId] = true;
    }

    function clearApprovalForGeneLab(uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        delete unicornApprovalsForGeneLab[_unicornId];
    }

    //transfer by market
    function marketTransfer(address _from, address _to, uint256 _unicornId) onlyBreeding external {
        clearApprovalAndTransfer(_from, _to, _unicornId);
    }

    function plusFreezingTime(uint _unicornId) onlyBreeding external  {
        unicorns[_unicornId].freezingEndTime = uint64(_getFreezeTime(getUnicornGenByte(_unicornId, 163)) + now);
        emit UnicornFreezingTimeSet(_unicornId, unicorns[_unicornId].freezingEndTime);
    }

    function plusTourFreezingTime(uint _unicornId) onlyBreeding external {
        unicorns[_unicornId].freezingTourEndTime = uint64(_getFreezeTime(getUnicornGenByte(_unicornId, 168)) + now);
        emit UnicornTourFreezingTimeSet(_unicornId, unicorns[_unicornId].freezingTourEndTime);
    }

    function _getFreezeTime(uint8 freezingIndex) internal view returns (uint time) {
        freezingIndex %= maxFreezingIndex;
        time = freezing[freezingIndex];
        if (freezingPlusCount[freezingIndex] != 0) {
            time += (uint(block.blockhash(block.number - 1)) % freezingPlusCount[freezingIndex]) * 1 hours;
        }
    }


    //change freezing time for candy
    function minusFreezingTime(uint _unicornId, uint64 _time) onlyBreeding public {
        //не минусуем на уже размороженных конях
        require(unicorns[_unicornId].freezingEndTime > now);
        //не используем safeMath, т.к. subFreezingTime в теории не должен быть больше now %)
        unicorns[_unicornId].freezingEndTime -= _time;
    }

    //change tour freezing time for candy
    function minusTourFreezingTime(uint _unicornId, uint64 _time) onlyBreeding public {
        //не минусуем на уже размороженных конях
        require(unicorns[_unicornId].freezingTourEndTime > now);
        //не используем safeMath, т.к. subTourFreezingTime в теории не должен быть больше now %)
        unicorns[_unicornId].freezingTourEndTime -= _time;
    }

    function isUnfreezed(uint _unicornId) public view returns (bool) {
        return (unicorns[_unicornId].birthTime > 0 && unicorns[_unicornId].freezingEndTime <= uint64(now));
    }

    function isTourUnfreezed(uint _unicornId) public view returns (bool) {
        return (unicorns[_unicornId].birthTime > 0 && unicorns[_unicornId].freezingTourEndTime <= uint64(now));
    }

}

contract UnicornToken is UnicornBase {
    string public constant name = "UnicornGO";
    string public constant symbol = "UNG";

    function UnicornToken(address _unicornManagementAddress) UnicornAccessControl(_unicornManagementAddress) public {

    }

    function init() onlyManagement whenPaused external {
        unicornBreeding = UnicornBreedingInterface(unicornManagement.unicornBreedingAddress());
    }

    function() public {

    }
}