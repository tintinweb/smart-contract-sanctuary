pragma solidity 0.4.24;

contract CarDataInterface {
    // 保存MetaData
    function saveMetaData(address _walletAddress, bytes32 _dataPublicKey, bytes32 _metaDataHash,
        bytes32 _metaRootHash, bytes _vehicleType, uint32 _vehicleYear,
        uint256 _startTime, uint256 _endTime, bytes _stateList, uint256 _dataType) public;

    // 保存CarData的交易索引
    function saveCarDataTransaction(address _buyerAddress, address _contractAddress) public;
}

contract CarData {
    struct MetaData {
        address sellerAddress;
        bytes dataPublicKey;
        bytes32 metaDataHash;
        bytes32 metaRootHash;
        bytes vehicleType;
        uint32 vehicleYear;
        uint256 startTime;
        uint256 endTime;
        bytes stateList;
        uint256 dataType;
    }

    address public ownerAddress;

    // (sellerAddress => (dataPublicKey Hash => MetaDataList))
    mapping(address => mapping(bytes32 => MetaData[])) public metaDataList;

    // (buyerAddress => carDataTransactionAddressList)
    mapping(address => address[]) public carDataTransactionList;

    event DeployContract(address addr);
    event SaveMetaData(address sellerAddress, bytes dataPublicKey, bytes32 metaDataHash);
    event SaveCarDataTransaction(address buyerAddress, address contractAddress);

    constructor() public {
        ownerAddress = msg.sender;
        emit DeployContract(msg.sender);
    }

    modifier onlyOwner()  {
        require(msg.sender == ownerAddress);
        _;
    }

    function saveMetaData(address _sellerAddress, bytes _dataPublicKey, bytes32 _dataPublicKeyHash, bytes32 _metaDataHash,
        bytes32 _metaRootHash, bytes _vehicleType, uint32 _vehicleYear,
        uint256 _startTime, uint256 _endTime, bytes _stateList, uint256 _dataType) public onlyOwner {

        require(_sellerAddress != address(0));
        require(_startTime > 0);
        require(_endTime > 0);
        require(_endTime > _startTime);

        metaDataList[_sellerAddress][_dataPublicKeyHash].push(MetaData({
            sellerAddress : _sellerAddress,
            dataPublicKey : _dataPublicKey,
            metaDataHash : _metaDataHash,
            metaRootHash : _metaRootHash,
            vehicleType : _vehicleType,
            vehicleYear : _vehicleYear,
            startTime : _startTime,
            endTime : _endTime,
            stateList : _stateList,
            dataType : _dataType
            }));

        emit SaveMetaData(_sellerAddress, _dataPublicKey, _metaDataHash);
    }

    function saveCarDataTransaction(address _buyerAddress, address _contractAddress) public onlyOwner {
        require(_buyerAddress != address(0));
        require(_contractAddress != address(0));

        carDataTransactionList[_buyerAddress].push(_contractAddress);

        emit SaveCarDataTransaction(_buyerAddress, _contractAddress);
    }

    function getMetaDataCount(address _sellerAddress, bytes32 _dataPublicKeyHash) public view returns (uint256) {
        MetaData[] memory dataList = metaDataList[_sellerAddress][_dataPublicKeyHash];
        return dataList.length;
    }
}