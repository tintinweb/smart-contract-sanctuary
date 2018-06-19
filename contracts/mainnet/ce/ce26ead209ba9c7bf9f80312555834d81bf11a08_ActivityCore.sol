pragma solidity ^0.4.21;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract StorageBase is Ownable {

    function withdrawBalance() external onlyOwner returns (bool) {
        // The owner has a method to withdraw balance from multiple contracts together,
        // use send here to make sure even if one withdrawBalance fails the others will still work
        bool res = msg.sender.send(address(this).balance);
        return res;
    }
}

// owner of ActivityStorage should be ActivityCore contract address
contract ActivityStorage is StorageBase {

    struct Activity {
        // accept bid or not
        bool isPause;
        // limit max num of monster buyable per address
        uint16 buyLimit;
        // price (in wei)
        uint128 packPrice;
        // startDate (in seconds)
        uint64 startDate;
        // endDate (in seconds)
        uint64 endDate;
        // packId => address of bid winner
        mapping(uint16 => address) soldPackToAddress;
        // address => number of success bid
        mapping(address => uint16) addressBoughtCount;
    }

    // limit max activityId to 65536, big enough
    mapping(uint16 => Activity) public activities;

    function createActivity(
        uint16 _activityId,
        uint16 _buyLimit,
        uint128 _packPrice,
        uint64 _startDate,
        uint64 _endDate
    ) 
        external
        onlyOwner
    {
        // activity should not exist and can only be initialized once
        require(activities[_activityId].buyLimit == 0);

        activities[_activityId] = Activity({
            isPause: false,
            buyLimit: _buyLimit,
            packPrice: _packPrice,
            startDate: _startDate,
            endDate: _endDate
        });
    }

    function sellPackToAddress(
        uint16 _activityId, 
        uint16 _packId, 
        address buyer
    ) 
        external 
        onlyOwner
    {
        Activity storage activity = activities[_activityId];
        activity.soldPackToAddress[_packId] = buyer;
        activity.addressBoughtCount[buyer]++;
    }

    function pauseActivity(uint16 _activityId) external onlyOwner {
        activities[_activityId].isPause = true;
    }

    function unpauseActivity(uint16 _activityId) external onlyOwner {
        activities[_activityId].isPause = false;
    }

    function deleteActivity(uint16 _activityId) external onlyOwner {
        delete activities[_activityId];
    }

    function getAddressBoughtCount(uint16 _activityId, address buyer) external view returns (uint16) {
        return activities[_activityId].addressBoughtCount[buyer];
    }

    function getBuyerAddress(uint16 _activityId, uint16 packId) external view returns (address) {
        return activities[_activityId].soldPackToAddress[packId];
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract HasNoContracts is Pausable {

    function reclaimContract(address _contractAddr) external onlyOwner whenPaused {
        Ownable contractInst = Ownable(_contractAddr);
        contractInst.transferOwnership(owner);
    }
}

contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract LogicBase is HasNoContracts {

    /// The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 constant InterfaceSignature_NFC = bytes4(0x9f40b779);

    // Reference to contract tracking NFT ownership
    ERC721 public nonFungibleContract;

    // Reference to storage contract
    StorageBase public storageContract;

    function LogicBase(address _nftAddress, address _storageAddress) public {
        // paused by default
        paused = true;

        setNFTAddress(_nftAddress);

        require(_storageAddress != address(0));
        storageContract = StorageBase(_storageAddress);
    }

    // Very dangerous action, only when new contract has been proved working
    // Requires storageContract already transferOwnership to the new contract
    // This method is only used to transfer the balance to owner
    function destroy() external onlyOwner whenPaused {
        address storageOwner = storageContract.owner();
        // owner of storageContract must not be the current contract otherwise the storageContract will forever not accessible
        require(storageOwner != address(this));
        // Transfers the current balance to the owner and terminates the contract
        selfdestruct(owner);
    }

    // Very dangerous action, only when new contract has been proved working
    // Requires storageContract already transferOwnership to the new contract
    // This method is only used to transfer the balance to the new contract
    function destroyAndSendToStorageOwner() external onlyOwner whenPaused {
        address storageOwner = storageContract.owner();
        // owner of storageContract must not be the current contract otherwise the storageContract will forever not accessible
        require(storageOwner != address(this));
        // Transfers the current balance to the new owner of the storage contract and terminates the contract
        selfdestruct(storageOwner);
    }

    // override to make sure everything is initialized before the unpause
    function unpause() public onlyOwner whenPaused {
        // can not unpause when the logic contract is not initialzed
        require(nonFungibleContract != address(0));
        require(storageContract != address(0));
        // can not unpause when ownership of storage contract is not the current contract
        require(storageContract.owner() == address(this));

        super.unpause();
    }

    function setNFTAddress(address _nftAddress) public onlyOwner {
        require(_nftAddress != address(0));
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_NFC));
        nonFungibleContract = candidateContract;
    }

    // Withdraw balance to the Core Contract
    function withdrawBalance() external returns (bool) {
        address nftAddress = address(nonFungibleContract);
        // either Owner or Core Contract can trigger the withdraw
        require(msg.sender == owner || msg.sender == nftAddress);
        // The owner has a method to withdraw balance from multiple contracts together,
        // use send here to make sure even if one withdrawBalance fails the others will still work
        bool res = nftAddress.send(address(this).balance);
        return res;
    }

    function withdrawBalanceFromStorageContract() external returns (bool) {
        address nftAddress = address(nonFungibleContract);
        // either Owner or Core Contract can trigger the withdraw
        require(msg.sender == owner || msg.sender == nftAddress);
        // The owner has a method to withdraw balance from multiple contracts together,
        // use send here to make sure even if one withdrawBalance fails the others will still work
        bool res = storageContract.withdrawBalance();
        return res;
    }
}

contract ActivityCore is LogicBase {

    bool public isActivityCore = true;

    ActivityStorage activityStorage;

    event ActivityCreated(uint16 activityId);
    event ActivityBidSuccess(uint16 activityId, uint16 packId, address winner);

    function ActivityCore(address _nftAddress, address _storageAddress) 
        LogicBase(_nftAddress, _storageAddress) public {
            
        activityStorage = ActivityStorage(_storageAddress);
    }

    function createActivity(
        uint16 _activityId,
        uint16 _buyLimit,
        uint128 _packPrice,
        uint64 _startDate,
        uint64 _endDate
    ) 
        external
        onlyOwner
        whenNotPaused
    {
        activityStorage.createActivity(_activityId, _buyLimit, _packPrice, _startDate, _endDate);

        emit ActivityCreated(_activityId);
    }

    // Very dangerous action and should be only used for testing
    // Must pause the contract first 
    function deleteActivity(
        uint16 _activityId
    )
        external 
        onlyOwner
        whenPaused
    {
        activityStorage.deleteActivity(_activityId);
    }

    function getActivity(
        uint16 _activityId
    ) 
        external 
        view  
        returns (
            bool isPause,
            uint16 buyLimit,
            uint128 packPrice,
            uint64 startDate,
            uint64 endDate
        )
    {
        return activityStorage.activities(_activityId);
    }
    
    function bid(uint16 _activityId, uint16 _packId)
        external
        payable
        whenNotPaused
    {
        bool isPause;
        uint16 buyLimit;
        uint128 packPrice;
        uint64 startDate;
        uint64 endDate;
        (isPause, buyLimit, packPrice, startDate, endDate) = activityStorage.activities(_activityId);
        // not allow to bid when activity is paused
        require(!isPause);
        // not allow to bid when activity is not initialized (buyLimit == 0)
        require(buyLimit > 0);
        // should send enough ether
        require(msg.value >= packPrice);
        // verify startDate & endDate
        require(now >= startDate && now <= endDate);
        // this pack is not sold out
        require(activityStorage.getBuyerAddress(_activityId, _packId) == address(0));
        // buyer not exceed buyLimit
        require(activityStorage.getAddressBoughtCount(_activityId, msg.sender) < buyLimit);
        // record in blockchain
        activityStorage.sellPackToAddress(_activityId, _packId, msg.sender);
        // emit the success event
        emit ActivityBidSuccess(_activityId, _packId, msg.sender);
    }
}