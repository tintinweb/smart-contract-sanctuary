//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IKetherHomepage {
  function ads(uint _idx) external view returns (address,uint,uint,uint,uint,string memory,string memory,string memory,bool,bool);
  function getAdsLength() view external returns (uint);
}

interface IERC721 {
  function ownerOf(uint256) external view returns (address);
}

library KetherView {
  struct AdView {
    address owner;
    uint x;
    uint y;
    uint width;
    uint height;
    string link;
    string image;
    string title;
    bool NSFW;
    bool forceNSFW;
    uint idx;
    bool wrapped;
  }
  /// allAds is a helper view designed to be called from frontends that want to
  /// display all of the ads with their correct NFT owners.
  function allAds(address _instanceAddress, address _nftAddress, uint _offset, uint _limit) external view returns (AdView[] memory) {
    // TODO: this errors out with `Error: Transaction reverted: library was called directly` if _offset is > length.
    // should we add a better error?
    uint len = IKetherHomepage(_instanceAddress).getAdsLength() - _offset;
    if (_limit < len) {
      len = _limit;
    }

    AdView[] memory ads_ = new AdView[](len);

    for (uint i=0; i < len; i++) {
      ads_[i] = getAd(_instanceAddress, _nftAddress, _offset+i);
    }
    return ads_;
  }

  function getAd(address _instanceAddress, address _nftAddress, uint _idx) public view returns (AdView memory) {
      (address owner, uint x, uint y, uint width, uint height, string memory link, string memory image, string memory title, bool NSFW, bool forceNSFW) = IKetherHomepage(_instanceAddress).ads(_idx);
      bool wrapped = false;

      // Is it an NFT already?
      if (owner == _nftAddress) {
        // Override owner to be the NFT owner
        owner = IERC721(_nftAddress).ownerOf(_idx);
        wrapped = true;
      }

      return AdView(owner, x, y, width, height, link, image, title, NSFW, forceNSFW, _idx, wrapped);
  }
}