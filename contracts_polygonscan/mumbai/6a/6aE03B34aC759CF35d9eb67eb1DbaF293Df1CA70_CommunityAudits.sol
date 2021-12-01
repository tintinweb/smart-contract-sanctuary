// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.6 <0.9.0;

import "Asset.sol";

// store a map of asset contracts
// onboard assets to master if not available

contract CommunityAudits {
    Asset[] public assetContracts;
    mapping(address => address) public assetContractsMap;

    function create(
        address _contract,
        string memory _name,
        string memory _symbol,
        string memory _imageURL,
        CATEGORY _category
    ) public {
        Asset newContract = new Asset(
            _contract,
            _name,
            _symbol,
            _imageURL,
            _category
        );
        assetContracts.push(newContract);
        assetContractsMap[_contract] = address(newContract);
    }

    modifier checkAsset(address _contract) {
        require(
            assetContractsMap[_contract] != address(0),
            "Sorry this asset is not available, Please consider adding it to the system."
        );
        _;
    }

    function getData(address _contract)
        public
        view
        checkAsset(_contract)
        returns (Data memory)
    {
        Asset assetContract = Asset(address(assetContractsMap[_contract]));
        return assetContract.data();
    }

    function rateAsset(
        address _contract,
        uint256 _technicalImplementation,
        uint256 _trustFactor,
        uint256 _founderReliability
    ) public checkAsset(_contract) {
        Asset assetContract = Asset(address(assetContractsMap[_contract]));
        assetContract.rate(
            msg.sender,
            _technicalImplementation,
            _trustFactor,
            _founderReliability
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.6 <0.9.0;

struct Rating {
    uint256 overallScore;
    uint256 technicalImplementation;
    uint256 trustFactor;
    uint256 founderReliability;
}
enum CATEGORY {
    Token,
    DApp,
    NFT
}
struct Data{
    address assetAddress;
    string name;
    string symbol;
    string imageURL;
    CATEGORY category;
    Rating rating;
}

contract Asset {
    address public assetAddress;
    string public name;
    string public symbol;
    string public imageURL;
    CATEGORY public category;
    Rating public rating;
    address [] ratedUsers;
    mapping(address => bool) ratedUsersMap;

    constructor(
        address _contract,
        string memory _name,
        string memory _symbol,
        string memory _imageURL,
        CATEGORY _category
    ) {
        assetAddress=_contract;
        name = _name;
        symbol = _symbol;
        imageURL = _imageURL;
        category = _category;
    }

    function data() public view returns(Data memory){
        Data memory returnData = Data(assetAddress,name,symbol,imageURL,category,rating);
        return returnData;
    }


    modifier UniqueRater(address _address) {
        require(ratedUsersMap[_address] == false, "You can only rate once!!!");
        ratedUsersMap[_address]=true;        
        _;
    }

    function rate(
        address _address,
        uint256 _technicalImplementation,
        uint256 _trustFactor,
        uint256 _founderReliability
    ) public UniqueRater(_address) {
        uint256 n = ratedUsers.length;
        rating.technicalImplementation = appendMetric(
            rating.technicalImplementation,
            _technicalImplementation,
            n
        );
        rating.trustFactor = appendMetric(rating.trustFactor, _trustFactor, n);
        rating.founderReliability = appendMetric(
            rating.founderReliability,
            _founderReliability,
            n
        );
        uint256 overallScore = (_technicalImplementation +
            _trustFactor +
            _founderReliability) / 3;
        rating.overallScore = appendMetric(
            rating.overallScore,
            overallScore,
            n
        );
        ratedUsers.push(msg.sender);
    }

    function appendMetric(
        uint256 a,
        uint256 b,
        uint256 n
    ) pure private returns (uint256) {
        return (a * n + b) / (n + 1);
    }
}