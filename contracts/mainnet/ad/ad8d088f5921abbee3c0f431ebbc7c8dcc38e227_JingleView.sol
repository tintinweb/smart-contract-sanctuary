/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract IMarketplace {
    struct Order {
        uint price;
        address seller;
        uint timestamp;
        bool exists;
    }

    function getAllJinglesOnSale() public view virtual returns(uint[] memory);

    function sellOrders(uint256) public view virtual returns (Order memory);
}

abstract contract ISample {
    function getTokenType(uint _sampleId) public virtual view returns (uint);
    function getSamplesForOwner(address _owner) public virtual view returns (uint[] memory);
}

abstract contract IJingle {

    mapping(uint => uint8[20]) public settings;

    function ownerOf(uint256 _tokenId) public virtual view returns (address owner);
    function getAllJingles(address _owner) external virtual view returns(uint[] memory);
    function getMetaInfo(uint _jingleId) external virtual view returns(string memory, string memory);

    function getSamplesForJingle(uint _jingleId) external virtual view returns(uint[] memory);

}

contract JingleView {

    address public constant SAMPLE_V1_ADDR = 0x57FD3480581F72B0DF1AdeAd72B4181a52A1D7dE;
    address public constant MARKET_PLACE_V1 = 0xC1EF465527343f68Bb1841F99b9aDEb061cc7Ac9;
    address public constant JINGLE_V1_ADDR = 0x5B6660ca047Cc351BFEdCA4Fc864d0A88F551485;

    struct JingleData {
        uint256 id;
        string name;
        string author;
        bool onSale;
        uint256 price;
        address owner;
        uint256[] sampleIds;
        uint256[] sampleTypes;
        uint8[20] settings;
    }

    struct SampleData {
        uint sampleId;
        uint sampleType;
    }

    function getFullJingleData(uint256 _jingleId) public view returns (JingleData memory) {
        IJingle jingleContract = IJingle(JINGLE_V1_ADDR);

        (string memory name, string memory author) = jingleContract.getMetaInfo(_jingleId);

        uint256[] memory sampleIds = jingleContract.getSamplesForJingle(_jingleId);

        uint256[] memory sampleTypes = new uint256[](sampleIds.length);

        for(uint256 i = 0; i < sampleIds.length; ++i) {
            sampleTypes[i] = ISample(SAMPLE_V1_ADDR).getTokenType(sampleIds[i]);
        }

        IMarketplace.Order memory order = IMarketplace(MARKET_PLACE_V1).sellOrders(_jingleId);

        uint8[20] memory settings;

        for(uint256 i = 0; i < settings.length; ++i) {
            settings[i] = jingleContract.settings(_jingleId, i);
        }

        return JingleData({
            id: _jingleId,
            name: name,
            author: author,
            onSale: order.exists,
            price: order.price,
            owner: jingleContract.ownerOf(_jingleId),
            sampleIds: sampleIds,
            sampleTypes: sampleTypes,
            settings: settings
        });
    }

    function getFullJingleDataForUser(address _user) public view returns (JingleData[] memory jingles) {
        IJingle jingleContract = IJingle(JINGLE_V1_ADDR);

        uint256[] memory jingleIds = jingleContract.getAllJingles(_user);

        jingles = new JingleData[](jingleIds.length);

        for(uint256 i = 0; i < jingles.length; ++i) {
            jingles[i] = getFullJingleData(jingleIds[i]);
        }
    }

    function getSamplesForUser(address _owner) public view returns (SampleData[] memory samples) {
        uint256[] memory sampleIds = ISample(SAMPLE_V1_ADDR).getSamplesForOwner(_owner);

        samples = new SampleData[](sampleIds.length);

        for(uint256 i = 0; i < samples.length; ++i) {
            samples[i] = SampleData({
                sampleId: sampleIds[i],
                sampleType: ISample(SAMPLE_V1_ADDR).getTokenType(sampleIds[i])
            });
        }
    }

    function getPaginatedJingles(uint _page, uint _perPage) public view returns (JingleData[] memory) {
        JingleData[] memory strategiesPerPage = new JingleData[](_perPage);

        uint start = _page * _perPage;
        uint end = start + _perPage;

        end = (end > strategiesPerPage.length) ? strategiesPerPage.length : end;

        uint count = 0;
        for (uint i = start; i < end; i++) {
            strategiesPerPage[count] = getFullJingleData(i);
            count++;
        }

        return strategiesPerPage;
    }

    function getJinglesOnSale() public view returns (JingleData[] memory jinglesOnSale) {
        uint256[] memory jingleIds = IMarketplace(MARKET_PLACE_V1).getAllJinglesOnSale();

        jinglesOnSale = new JingleData[](jingleIds.length);

        for(uint256 i = 0; i < jinglesOnSale.length; ++i) {
            jinglesOnSale[i] = getFullJingleData(jingleIds[i]);
        }

        return jinglesOnSale;
    }
}