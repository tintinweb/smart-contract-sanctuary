/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Homepage {
    /// Buy is emitted when an ad unit is reserved.
    event Buy(
        uint indexed idx,
        address owner,
        uint x,
        uint y,
        uint width,
        uint height
    );

    /// Publish is emitted whenever the contents of an ad is changed.
    event Publish(
        uint indexed idx,
        string link,
        string image,
        string title,
        bool NSFW
    );

    /// SetAdOwner is emitted whenever the ownership of an ad is transfered
    event SetAdOwner(
        uint indexed idx,
        address from,
        address to
    );

    event SetBlackListed(
        address BlackListed
    );

    event SetPixelPrice(
        uint weiPixelPrice
    );

    mapping(address => bool) public blackList;

    /// Price is 1 kether divided by 1,000,000 pixels
    uint public weiPixelPrice = 1;

    /// Each grid cell represents 100 pixels (10x10).
    uint public constant pixelsPerCell = 100;

    bool[100][100] public grid;

    address contractOwner;

    address withdrawWallet;

    struct Ad {
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
    }

    /// ads are stored in an array, the id of an ad is its index in this array.
    Ad[] public ads;

    constructor(address _contractOwner, address _withdrawWallet) {
        require(_contractOwner != address(0));
        require(_withdrawWallet != address(0));

        contractOwner = _contractOwner;
        withdrawWallet = _withdrawWallet;
    }

    function setWeiPixelPrice(uint weiPixelPrice_) external {
        require( msg.sender == contractOwner );
        weiPixelPrice = weiPixelPrice_;
    }

    function setBlackListed(address address_) external {
        require( msg.sender == contractOwner );
        blackList[address_] = true;
        emit SetBlackListed(address_);
    }

    function getBlackListed(address address_) public view returns (bool){
        return blackList[address_];
    }

    /// getAdsLength tells you how many ads there are
    function getAdsLength() public view returns (uint) {
        return ads.length;
    }

    /// Ads must be purchased in 10x10 pixel blocks.
    /// Each coordinate represents 10 pixels. That is,
    ///   _x=5, _y=10, _width=3, _height=3
    /// Represents a 30x30 pixel ad at coordinates (50, 100)
    function buy(uint _x, uint _y, uint _width, uint _height) external payable returns (uint idx) {
        require( ( msg.sender == contractOwner ) ||  ( !getBlackListed(msg.sender) ) );

        uint cost = _width * _height * pixelsPerCell * weiPixelPrice;
        require(cost > 0);
        require(msg.value >= cost);

        // Loop over relevant grid entries
        for(uint i=0; i<_width; i++) {
            for(uint j=0; j<_height; j++) {
                if (grid[_x+i][_y+j]) {
                    // Already taken, undo.
                    revert();
                }
                grid[_x+i][_y+j] = true;
            }
        }

        // We reserved space in the grid, now make a placeholder entry.
        Ad memory ad = Ad(msg.sender, _x, _y, _width, _height, "", "", "", false, false);
        ads.push(ad);
        idx =  ads.length - 1;
        emit Buy(idx, msg.sender, _x, _y, _width, _height);
        return idx;
    }

    /// Publish allows for setting the link, image, and NSFW status for the ad
    /// unit that is identified by the idx which was returned during the buy step.
    /// The link and image must be full web3-recognizeable URLs, such as:
    ///  - bzz://a5c10851ef054c268a2438f10a21f6efe3dc3dcdcc2ea0e6a1a7a38bf8c91e23
    ///  - bzz://mydomain.eth/ad.png
    ///  - https://cdn.mydomain.com/ad.png
    /// Images should be valid PNG.
    function publish(uint _idx, string calldata _link, string calldata _image, string calldata _title, bool _NSFW) external {

        Ad storage ad = ads[_idx];

        require(
            ( msg.sender == contractOwner ) ||
            ( ( !getBlackListed(ad.owner) ) && ( msg.sender == ad.owner ) )
        );

        ad.link = _link;
        ad.image = _image;
        ad.title = _title;
        ad.NSFW = _NSFW;

        emit Publish(_idx, ad.link, ad.image, ad.title, ad.NSFW || ad.forceNSFW);
    }

    /// setAdOwner changes the owner of an ad unit
    function setAdOwner(uint _idx, address _newOwner) public {
        Ad storage ad = ads[_idx];

        require(
            msg.sender == ad.owner
            ||
            msg.sender == contractOwner
        );

        ad.owner = _newOwner;

        emit SetAdOwner(_idx, msg.sender, _newOwner);
    }

    /// forceNSFW allows the owner to override the NSFW status for a specific ad unit.
    function forceNSFW(uint _idx, bool _NSFW) public {
        require(msg.sender == contractOwner);
        Ad storage ad = ads[_idx];
        ad.forceNSFW = _NSFW;

        emit Publish(_idx, ad.link, ad.image, ad.title, ad.NSFW || ad.forceNSFW);
    }

    /// withdraw allows the owner to transfer out the balance of the contract.
    function withdraw() external {
        require(msg.sender == contractOwner);
        payable(withdrawWallet).transfer(address(this).balance);
    }
}