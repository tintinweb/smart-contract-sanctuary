/**
 *
 *  Reward Tracks
 *
 *
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.4;

contract RewardTracks {
    // counter for Track Ids
    //using CountersUpgradeable for CountersUpgradeable.Counter;
    //CountersUpgradeable.Counter private _trackIds;
    uint256 private _trackIds;

    mapping(address => TrackMeta[]) genericContractTracks;
    mapping(address => mapping(uint256 => TrackMeta[])) specificCardTracks;
    mapping(address => mapping(uint256 => uint256)) NftTracksCount;
    mapping(address => uint256) ContractTracksCount;
    // mapping from trackId to Track metadata
    mapping(uint256 => TrackMeta) id2Meta;

    // Track Metadata
    struct TrackMeta {
        uint256 id;
        bool isNftSpecific; // true when track is Nft specific
        address contractAddress; // nft contract address
        uint256 tokenId;    // is zero when it's Not Nft specific
        string name;
        string image;
        string description;
        string source;
        uint256 rewardsRate;
        uint256 trackDuration;
        bool isAdvertisement;
    }

    /**
     * @dev adds track to Token Owned Tracks
     * @param _tokenId uint256 tokenID
     * @param _name string track name
     * @param _image string track image URI
     * @param _description string track description
     * @param _source string track source
     */
    function _addTrackToSpecificCard(
        address _nftContract,
        uint256 _tokenId,
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _source,
        uint256 _rewards,
        uint256 _trackDuration,
        bool isAdvertisement
    ) external
      returns (uint256){
        // increment Track id by one
        _trackIds = _trackIds + 1 ;
        // set new track id
        uint256 newTrackId = _trackIds;
        // Create a new struct of type "TrackMeta" 
        TrackMeta memory meta = TrackMeta(newTrackId , true, _nftContract, _tokenId,_name, _image, _description, _source, _rewards, _trackDuration, isAdvertisement);
        specificCardTracks[_nftContract][_tokenId].push(meta);
        NftTracksCount[_nftContract][_tokenId] = NftTracksCount[_nftContract][_tokenId] + 1;
        
        // add trackMeta to "id2Meta" mapping
        id2Meta[newTrackId] = meta;

        return newTrackId;
    }

    function _addTrackToContract(
        address _nftContract,
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _source,
        uint256 _rewards,
        uint256 _trackDuration,
        bool isAdvertisement
    ) external 
      returns(uint256) {
        // increment Track id by one
        _trackIds = _trackIds + 1;
        // set new track id
        uint256 newTrackId = _trackIds;
        // Create a new struct of type "TrackMeta" 
        TrackMeta memory meta = TrackMeta(newTrackId , false, _nftContract, 0,_name, _image, _description, _source, _rewards, _trackDuration, isAdvertisement);
        genericContractTracks[_nftContract].push(meta);
        //specificCardTracks[_nftContract][_tokenId].push(meta);
        //AddressTokenTracksCount[_nftContract][_tokenId] = AddressTokenTracksCount[_nftContract][_tokenId] + 1;
        ContractTracksCount[_nftContract] = ContractTracksCount[_nftContract] + 1;
        // add Id2MetaContract 
        id2Meta[newTrackId] = meta;
        return newTrackId;
    }
    
    /** get tracks added specificily for Nft card */
    function getSpecificNftTracks(
      address _nftContract,
      uint256 _tokenId
    )public view returns(TrackMeta[] memory){
      uint nftTracksCount = NftTracksCount[_nftContract][_tokenId];
      TrackMeta[] memory nftTracksMeta = new TrackMeta[](nftTracksCount);
      //uint Counter = 0;
      
      nftTracksMeta = specificCardTracks[_nftContract][_tokenId];
      return nftTracksMeta;
    }

    /** get generic tracks added to contract */
    function getGenericContractTracks(
        address _nftContract
    ) public view returns(TrackMeta[] memory) {
        uint contractTrackCount = ContractTracksCount[_nftContract];
        TrackMeta[] memory nftTracksMeta = new TrackMeta[](contractTrackCount);
        //uint Counter = 0;
        
        nftTracksMeta = genericContractTracks[_nftContract];
        return nftTracksMeta;
    }
    
    function getAllTracks() public view returns(TrackMeta[] memory){
        TrackMeta[] memory allTracks = new TrackMeta[](_trackIds);
        uint256 counter = 0;

        for (uint256 i = 1; i < _trackIds + 1; i++) {
            allTracks[counter] = id2Meta[i];
            counter++;
        }
        return allTracks;
    }

    
    function _getTrackDuration(
      uint256 _trackId
    ) external
      view
     returns(uint256){
       // return trackId metadata
       return id2Meta[_trackId].trackDuration;
    }

    function _getTrackRewards(
      uint256 _trackId
    )external
      view
     returns(uint256){
       // return trackId metadata
       return id2Meta[_trackId].rewardsRate;
    }
}