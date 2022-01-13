//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./ERC721.sol";
// import "hardhat/console.sol";

contract FilthyPins is ERC721 {

    struct Post {
        address poster;
        uint256 pinPrice;
        uint32 pinLimit;
        uint32 id;
        uint32 pinToId;
        uint8 x;
        uint8 y;
        uint8 w;
        uint8 h;
        string text;
        string url;
        string imageUri;
    }

    // board version (increments with every post)
    uint32 public version;
    uint256 public tileFill;

    // number of pintypes currently known - init as 1 for standard, non-tradable pins
    uint32 public pinTypeCount;

    // posts (post id, post, url, image, posted_x, posted_y, posted_w_, posted_z, board_version)
    mapping (uint256 => Post) public posts;

    //contract keeps fraction of pin price (if applicable)
    uint8 public fractionDenomFeeToContractForPins; //i.e. 10 = 1/10 = contract keeps 10% for pins

    //discounted price on reposting (as fractional denominator).... i.e. 4==75% discount or price is 25% of full price
    uint8 public fractionDenomDiscountForRepost;

    uint256 public baseTilePrice;
    uint256 public incrementPrice;
    uint32 public incrementInterval;
    uint32 public incrementCap;

    //how many pins are there for this post?
    mapping(uint32 => uint32) public postPinCount;

    //what is the pin type for this pin 721
    mapping(uint256 => uint32) pin721Type;

    //mapping of post > owner > pinType
    mapping(uint32 => mapping(address => uint256)) public postAddressPin721;

    string public baseTokenURI;
    address public owner;
    bool public paused;

    uint8 constant SIZE_X=64;
    uint8 constant SIZE_Y=64;

    uint256 constant padTypeBase=100000000000000000000;
    uint256 constant padTypePost=padTypeBase;
    uint256 constant padTypePin =200000000000000000000;
    uint256 constant padPostBase=          10000000000;

    event NewPost(
        uint32 indexed _postId,
        uint256 indexed _721Id,
        address indexed _owner
        );

    event NewPin(
        uint32 indexed _postId,
        uint32 indexed _pinId,
        uint256 indexed _721Id,
        address _owner
        );

    event Pause();
    event Unpause();

    constructor () 
    ERC721("Filthy Pins", "FPX") {

        //version & pintypes start at 1
        version=1;
        pinTypeCount=1;
        paused=false;
        tileFill=0;
        baseTokenURI="https://filthypins.xyz/token/";
        fractionDenomFeeToContractForPins=10; //10% to contract for pins
        fractionDenomDiscountForRepost=4; //repost price is 25% of full price
        baseTilePrice=0.015625 ether;
        incrementPrice=0.015625 ether;
        incrementInterval=1024;
        incrementCap=8192;

        owner=msg.sender;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function pause() external {
        require(msg.sender==owner);
        paused=true;
        emit Pause();
    }

    function unpause() external {
        require(msg.sender==owner);
        paused=false;
        emit Unpause();
    }

    function changeOwner(address _newOwner) external {
        require(msg.sender==owner); //, "caller is not owner");
        owner=_newOwner;
    }

    function withdraw(address _to, uint256 _amount) external {
        require(msg.sender==owner); //, "caller is not owner");
        (bool sent, bytes memory data) = _to.call{value: _amount}("");
        require(sent); //, "failed to withdraw");
    }

    function setPinTypeCount(uint32 _newPinTypeCount) external {
        require(msg.sender==owner); //, "caller is not owner");
        pinTypeCount=_newPinTypeCount;
    }

    function setPrices(uint256 _baseTilePrice, uint256 _incrementPrice, uint32 _incrementInterval, 
        uint32 _incrementCap, uint8 _denomPinFeeToContract, uint8 _denomDiscountForRepost) external {
        require(msg.sender==owner);
        baseTilePrice=_baseTilePrice;
        incrementPrice=_incrementPrice;
        incrementInterval=_incrementInterval;
        incrementCap=_incrementCap;
        fractionDenomFeeToContractForPins=_denomPinFeeToContract;
        fractionDenomDiscountForRepost=_denomDiscountForRepost;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external {
        require(msg.sender==owner);
        baseTokenURI=_baseTokenURI;
    }

    function postSomething(uint8 _x, uint8 _y, uint8 _w, uint8 _h, 
        uint256 _pinPrice, uint32 _pinLimit,
        string memory _text, string memory _url, string memory _imageUri)
        payable external {

        require(!paused);
        require(_w>0); //, "width is zero");
        require(_h>0); //, "height is zero");
        require((_x+_w) <= SIZE_X); //, "x out of bounds");
        require((_y+_h) <= SIZE_Y); //, "y out of bounds");

        //work out dimensions
        uint16 _tileCount=uint16(_w)*uint16(_h);

        // //payable fee is count * current price
        uint256 _totalFee=_tileCount * getCurrentTilePrice();

        // contract owner can post for free (cheaper than flash loan gas)
        require(msg.value==_totalFee || msg.sender==owner); //, "insufficient payment for required fee");

        //new post gets id that is current board version; version is then incremented
        posts[version]=Post(
            msg.sender,
            _pinPrice, //pinPrice, default 0
            _pinLimit, //pinLImit, default 0
            version, //id
            version, //pinToId (same for original post)
            _x,
            _y,
            _w,
            _h,
            _text,
            _url,
            _imageUri
        );

        // post 1, is, for e.g., 
        // 100000000010000000000

        // a pin for post 1, pin 1 is, for e.g., 
        // 200000000010000000001

        //id of post 721 is type (1) + version * 10000000000

        //mint 721 to sender
        uint256 _721Id=padTypePost + (uint256(version) * padPostBase);
        _mint(msg.sender, _721Id);

        emit NewPost(version, _721Id, msg.sender);

        version+=1;
        tileFill+=uint256(_tileCount);
    }

    function repostSomething(uint32 _origPostId) payable external {
        require(!paused);

        Post memory _origPost=posts[_origPostId];

        //check original exists
        require(_origPost.id>0); //, "original post not found");

        //calc fee based on original
        //work out dimensions
        uint16 _tileCount=uint16(_origPost.w)*uint16(_origPost.h);

        //payable fee is (count * currentPrice) / fractionDenomDiscountForRepost
        uint256 _totalFee=(_tileCount * getCurrentTilePrice()) / uint256(fractionDenomDiscountForRepost);

        //require correct fee (or admin as caller)
        require(msg.value==_totalFee || msg.sender==owner);

        //make a new post with the same fields as original apart from version (Which is this new post)
        posts[version]=Post(
            msg.sender,
            _origPost.pinPrice,
            _origPost.pinLimit,
            version,
            _origPost.pinToId,
            _origPost.x,
            _origPost.y,
            _origPost.w,
            _origPost.h,
            _origPost.text,
            _origPost.url,
            _origPost.imageUri
        );

        //mint 721 to sender
        uint256 _721Id=padTypePost + (uint256(version) * padPostBase);
        _mint(msg.sender, _721Id);

        emit NewPost(version, _721Id, msg.sender);

        version+=1;
        tileFill+=uint256(_tileCount);

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused);

        //get pin type from token id (math)
        uint8 _tokenType=uint8(tokenId / padTypeBase);

        uint32 _postId=0;
        //get post id from token id (math)
        if(_tokenType==2) {
            _postId=uint32((tokenId - padTypePin) / padPostBase);
        }

        //reject if this is a pin & to already has a pin for this post
        require(_tokenType != 2 || (!(postAddressPin721[_postId][to] > 0))); //, "to already has pinned this post");

        //for (non-mint) pin type tokens update the post > address > 721 mapping
        if(_tokenType==2 && from != address(0)) {
            //get 721 from (post>from-addr)
            uint256 _currentPin721=postAddressPin721[_postId][from];

            //change to (post>to-addr = pintype)
            //  this is only for actual transfers (mints are handled in pin())
            postAddressPin721[_postId][to]=_currentPin721;

            //change from (post>from-addr = 0)
            postAddressPin721[_postId][from]=0;
        }
    }

    function pin(uint32 _postId, uint16 _pinType) payable external {
        require(!paused);

        Post memory reqPost = posts[_postId];
        Post memory pinToPost = reqPost;
        if(reqPost.pinToId!=reqPost.id) {
            pinToPost=posts[reqPost.pinToId];
        }
        uint32 currentPinCount = postPinCount[pinToPost.id];

        require(pinToPost.id > 0); //, "post not found";

        require(pinToPost.pinLimit==0 || currentPinCount < pinToPost.pinLimit); //, "no pins remaining for post");
        require(currentPinCount < 2**32-1); //, "no pins remaining for post (at absolute limit)");

        //check pinType <= allowed pins (global)
        require(_pinType>0); //, "must specify pin type");
        require(_pinType<=pinTypeCount); //, "must specify known pin type");

        require(pinToPost.pinPrice==0 || msg.value==pinToPost.pinPrice); //, "incorrect pin price");
        require(pinToPost.pinPrice>0 || msg.value==0); //, "incorrect pin price (only gas required)");

        require(!(postAddressPin721[pinToPost.id][msg.sender] > 0)); //, "only 1 pin per post per address");

        //increment pin count for this post
        uint32 newPinCount=currentPinCount+1;
        postPinCount[pinToPost.id]=newPinCount;

        uint256 _721Id=padTypePin + (uint256(pinToPost.id) * padPostBase) + newPinCount;

        //store the pin type
        pin721Type[_721Id]=_pinType;

        //make the pin NFT
        _mint(msg.sender, _721Id);

        //nft then used for tracking owner of the pin
        postAddressPin721[pinToPost.id][msg.sender]=_721Id;

        //then payout fee (if any message value)
        if(msg.value>0) {
            //e.g. if contract keeps 10% we subtract that from msg.value to send to poster
            uint256 _sendAmount=msg.value - (msg.value / uint256(fractionDenomFeeToContractForPins));
            (bool sent, bytes memory data) = pinToPost.poster.call{value: _sendAmount}("");
            require(sent); //, "failed to send pin fee (poster)");
        }

        emit NewPin(pinToPost.id, newPinCount, _721Id, msg.sender);
    }

    function getPost (uint256 _postId) public view returns(Post memory) {
        return posts[_postId];
    }

    function getCurrentTilePrice() public view returns(uint256) {
        uint256 useFill=tileFill;
        if(tileFill>uint256(incrementCap)) useFill=uint256(incrementCap);

        return baseTilePrice + ((incrementPrice) * ((useFill / incrementInterval)));
        // return ((0.03125 ether) * ((tileFill / 1024) + 1));
    }

    function getCurrentPinsForPost(uint32 _postId) public view returns(uint32) {
        //pin count comes from the pinto post
        return postPinCount[posts[_postId].pinToId];
    }

    function getPinTypeFor721(uint256 _721) public view returns(uint32) {
        return pin721Type[_721];
    }

    function get721ForPostAndAddress(uint32 _post, address _address) public view returns(uint256) {
        // use this to check a whitelist item -- if the address of interest currently owns a pin for the
        // specified post it will return a non-zero address. Note that this can be transfered away
        // so any whitelist should record which addresses were used so as to not re-issue to the same
        // whitelist token/721

        // if you're interested in a specific pin type (FP deploys with only 1 known pin type, but it
        // might increase over time) then use this address to get with getPinTypeFor721.
        return postAddressPin721[_post][_address];
    }
}