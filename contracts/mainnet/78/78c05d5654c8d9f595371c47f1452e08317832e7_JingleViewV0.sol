/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract IMarketplaceV0 {
    struct Order {
        uint price;
        address seller;
        uint timestamp;
        bool exists;
    }

    function jinglesOnSale(uint256) public view virtual returns(uint);

    function numOrders() public view virtual returns (uint);

    function sellOrders(uint256) public view virtual returns (Order memory);
}

abstract contract ISampleV0 {
    function getTokenType(uint _sampleId) public virtual view returns (uint);
    function getSamplesForOwner(address _owner) public virtual view returns (uint[] memory);
}

abstract contract IJingleV0 {

    function ownerOf(uint256 _tokenId) public virtual view returns (address owner);
    function getAllJingles(address _owner) external virtual view returns(uint[] memory);
    function getMetaInfo(uint _jingleId) external virtual view returns(string memory, string memory);

    function getSamplesForJingle(uint _jingleId) external virtual view returns(uint[] memory);

}

contract JingleViewV0 {

    address public constant SAMPLE_V0_ADDR = 0x6ac9E08B3AA6b501E5FB29B3D65E4c12305Ba721;
    address public constant MARKET_PLACE_V0 = 0xb8E392da7aBb836CfF06d827531A7e5F1B00BeD2;
    address public constant JINGLE_V0_ADDR = 0x5AF7Af54E8Bc34b293e356ef11fffE51d6f9Ae78;

    struct JingleData {
        uint256 id;
        string name;
        string author;
        bool onSale;
        uint256 price;
        address owner;
        uint256[] sampleIds;
        uint256[] sampleTypes;
    }

    struct SampleData {
        uint sampleId;
        uint sampleType;
    }

    function getFullJingleData(uint256 _jingleId) public view returns (JingleData memory) {
        IJingleV0 jingleContract = IJingleV0(JINGLE_V0_ADDR);

        (string memory name, string memory author) = jingleContract.getMetaInfo(_jingleId);

        uint256[] memory sampleIds = jingleContract.getSamplesForJingle(_jingleId);

        uint256[] memory sampleTypes = new uint256[](sampleIds.length);

        for(uint256 i = 0; i < sampleIds.length; ++i) {
            sampleTypes[i] = ISampleV0(SAMPLE_V0_ADDR).getTokenType(sampleIds[i]);
        }

        IMarketplaceV0.Order memory order = IMarketplaceV0(MARKET_PLACE_V0).sellOrders(_jingleId);
        return JingleData({
            id: _jingleId,
            name: name,
            author: author,
            onSale: order.exists,
            price: order.price,
            owner: jingleContract.ownerOf(_jingleId),
            sampleIds: sampleIds,
            sampleTypes: sampleTypes
        });
    }

    function getFullJingleDataForUser(address _user) public view returns (JingleData[] memory jingles) {
        IJingleV0 jingleContract = IJingleV0(JINGLE_V0_ADDR);

        uint256[] memory jingleIds = jingleContract.getAllJingles(_user);

        jingles = new JingleData[](jingleIds.length);

        for(uint256 i = 0; i < jingles.length; ++i) {
            jingles[i] = getFullJingleData(jingleIds[i]);
        }
    }

    function getSamplesForUser(address _owner) public view returns (SampleData[] memory samples) {
        uint256[] memory sampleIds = ISampleV0(SAMPLE_V0_ADDR).getSamplesForOwner(_owner);

        samples = new SampleData[](sampleIds.length);

        for(uint256 i = 0; i < samples.length; ++i) {
            samples[i] = SampleData({
                sampleId: sampleIds[i],
                sampleType: ISampleV0(SAMPLE_V0_ADDR).getTokenType(sampleIds[i])
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
        uint numOrders = IMarketplaceV0(MARKET_PLACE_V0).numOrders();
        uint256[] memory jingleIds = new uint256[](numOrders);

        for (uint i = 0; i < jingleIds.length; ++i) {
            jingleIds[i] = IMarketplaceV0(MARKET_PLACE_V0).jinglesOnSale(i);
        }

        jinglesOnSale = new JingleData[](jingleIds.length);

        for(uint256 i = 0; i < jinglesOnSale.length; ++i) {
            jinglesOnSale[i] = getFullJingleData(jingleIds[i]);
        }

        return jinglesOnSale;
    }
}