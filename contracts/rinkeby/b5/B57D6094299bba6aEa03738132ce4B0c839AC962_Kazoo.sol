//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./SVGKazoo.sol";


struct KazooObject
{

    address owner;
    uint256 id;
    uint256 masterNumber;
    string kazoo;
    string name;
    string[] names;
    uint256[] sponsors;
    uint256 sponsorNumber;
    bool sponsorsEnabled;
    string[] backgroundColours;
    string[] borderColours;
}

struct SponsorObject
{

    address owner; //person who pays this NFT royalties
    uint256 royaltyTotal;
    uint256 royaltyFee;
    string _sponsoredName;
    string _sponsoredContent;
}

//written by Llydia Cross
contract Kazoo is ERC721URIStorage, Ownable {

    uint256 public constant MAX_KAZOOS = 1879;
    uint256 public constant MAX_SPONSORS = 16;
    uint256 public constant MAX_NAMES = 4; //"Kazoo" is also a name
    uint256 public constant RANDOM_NUMBER = 1048575; //0xfffff

    //100 matic tokens per Kazoo to sponsor them
    uint256 public constant ROYALTY_FEE = 100 * (18 ** 0);

    uint256 public kazooId;
    uint256 private sponsoredContentId;
    uint256 private randomSeed;

    mapping(uint256 => KazooObject) kazoos;
    mapping(uint256 => KazooObject) kazooMetadata;
    mapping(uint256 => SponsorObject) activeSponsoredContent;

    string[] private possibleNames;
    string[] private hexCombinations;

    //events
    event mintedKazoo(uint256 kazooId, KazooObject kazoo);
    event namedKazoo(uint256 kazooId, string name);
    event generatedSVGForKazoo(uint256 kazooId, string svg);
    event tokenURISet(uint256 kazooId, string uri);

    constructor() ERC721("Kazoo","KAZ")
    {

        kazooId = 0;
        sponsoredContentId = 0;
        randomSeed = 1337;
        possibleNames = [
            "Fun",
            "Frens",
            "Dance",
            "Run",
            "Jump",
            "Wow",
            "Oh",
            "Hai",
            "Who",
            "Secret",
            "Quiet",
            "Sing",
            "Pretend",
            "Just",
            "Hilda",
            "Jonathan",
            "Karl",
            "Kid",
            "Crazy",
            "Animal",
            "Spirit",
            "Hips",
            "Toes",
            "Thanks",
            "Partner",
            "Sing",
            "Special",
            "Time",
            "Always",
            "Bye",
            "Much",
            "Loud",
            "Spicy",
            "Happy",
            "Sad",
            "Gay",
            "DIVA",
            "Meme",
            "Trap",
            "Lifted",
            "Boosted",
            "Gangked",
            "Busted",
            "Hood",
            "Certified",
            "Classical",
            "Erect",
            "Ke",
            "Kek",
            "El",
            "Woke"
        ];
    }

    function _mint(address addr, bool isSponsored) private
    {

        require(kazooId != MAX_KAZOOS, "max number of kazoos");

        uint256 _mNumber = randomNumber(RANDOM_NUMBER);

        KazooObject memory object = KazooObject(addr, kazooId, _mNumber, "<svg></svg>","Unnamed Kazoo", new string[](MAX_NAMES), new uint256[](15), 0, isSponsored, new string[](13), new string[](13));
        //sponsors initially disabled
        kazoos[kazooId] = object;

        //then name the kazoo
        nameKazoo(kazooId, _mNumber);

        //build the SVG
        buildKazooSVG(kazooId, _mNumber);

        emit mintedKazoo(kazooId, kazoos[kazooId]);

        //finally, mint the finished kazoo ending the transaction request
        _safeMint(addr, kazooId++);
    }

    function buildKazooSVG(uint256 _kazooId, uint256 _mNumber) private {
        require(_kazooId >= 0 && _kazooId <= kazooId, "invalid kazooId");
        KazooObject memory _kaz = kazoos[_kazooId];

        string[] memory _styles = new string[](13);
        //will effectively make the border darker
        string memory _staticBorder = SVGKazoo.getHexCode( _mNumber >> 1 );

        for(uint256 i = 0; i < 13; i++){
            //will make the background colours brigher than the static border and basically step up in the colour char to a ligher colour (0xfffff)
            _kaz.backgroundColours[i] = SVGKazoo.getHexCode((( _mNumber << 1 ) * (i + 12) * 12));
            _kaz.borderColours[i] = _staticBorder;
        }

        for(uint256 i = 0; i < 13; i++){
            _styles[i] = SVGKazoo.getStyle( _kaz.backgroundColours[i], _kaz.borderColours[i], 2);
        }

        _kaz.kazoo = SVGKazoo.buildKazoo(_styles, _kaz.names, _mNumber);

        //emit an event
        emit generatedSVGForKazoo(_kazooId, _kaz.kazoo);

        kazoos[_kazooId] = _kaz;
    }

    function remintKazoo(uint256 _kazooId) public payable {

        require(_isApprovedOrOwner(_msgSender(), _kazooId));
        require(_kazooId >= 0 && _kazooId <= kazooId, "invalid kazooId");
        uint256 _mNumber = randomNumber(RANDOM_NUMBER); //a random number between 1 and 64000

        buildKazooSVG(_kazooId, _mNumber );
        nameKazoo(_kazooId, _mNumber);
    }

    function setTokenURI(uint256 _kazooId, string memory _tokenURI) public
    {

        require (
            _isApprovedOrOwner( _msgSender(), _kazooId),
            "You do not have permission to call this function"
        );

        emit tokenURISet(kazooId, _tokenURI);

        _setTokenURI(_kazooId, _tokenURI);
    }

    function nameKazoo(uint256 _kazooId, uint256 _mNumber) private {
        require(_kazooId >= 0 && _kazooId <= kazooId, "invalid kazooId");
        KazooObject memory _kaz = kazoos[_kazooId];

        uint256 _randomNameNumber = ( _mNumber % 1000 ) * randomSeed;
        uint256 _times = _randomNameNumber % ( MAX_NAMES - 1);
        _kaz.names = spinName(_times, _mNumber, _randomNameNumber);
        _kaz.names[_times + 1] = "Kazoo"; //kazoo at the end

        string memory _name;
        for(uint256 i = 0; i <= _times + 1; i++){

            if(i != _times + 1)
                _name = string(abi.encodePacked(_name, _kaz.names[i], " "));
            else
                _name = string(abi.encodePacked(_name, _kaz.names[i]));
        }

        _kaz.name = _name;

       //emit an event
        emit namedKazoo(kazooId, _kaz.name);

        //set it
        kazoos[_kazooId] = _kaz;
    }

    function spinName(uint256 _times, uint256 _mNumber, uint256 _randomNameNumber) private view returns(string[] memory){

        string[] memory _names = new string[](MAX_NAMES);
        uint256 _randomNumber;

        for(uint256 i = 0; i <= _times; i++){
            _randomNumber = (_mNumber + i + _randomNameNumber ) % possibleNames.length; //a number between one and the length of the possible name array
            _names[i] = possibleNames[_randomNumber];
        }

        return _names;
    }

    function startSponsorship(string memory _sponsoredName, string memory _sponsoredContent) public payable
    {

        uint256 royaltyTotal;
        SponsorObject memory object = SponsorObject(_msgSender(), royaltyTotal, ROYALTY_FEE, _sponsoredName, _sponsoredContent);
        activeSponsoredContent[sponsoredContentId++] = object;
    }

    function randomNumber(uint _modulus) private returns(uint256)
    {

        return uint256(keccak256(abi.encodePacked(block.timestamp,
            block.difficulty,
            block.number,
            kazooId,
            _msgSender(),
            randomSeed++))
            ) % _modulus;
    }

    function sponsorKazoo(uint256 _sponsorId, uint256 _kazooId) public
    {

        require(_kazooId >= 0 && _kazooId <= kazooId, "invalid kazooId");
        require(_sponsorId >= 0 && _sponsorId <= sponsoredContentId, "invalid sponsorId");
        SponsorObject memory _obj = activeSponsoredContent[_sponsorId];
        KazooObject memory _kaz = kazoos[_kazooId];

        require(_msgSender() == _obj.owner, "you are not the owner of this sponsor id");
        require( _obj.royaltyTotal <= 0, "you have ran out of funds!");
        require(_kaz.sponsorsEnabled, "sponsorship on this Kazoo is disallowed");
        require(_kaz.sponsorNumber < MAX_SPONSORS, "maximum amount of sponsors met on this NFT");

        _obj.royaltyTotal = _obj.royaltyTotal - _obj.royaltyFee;
        _kaz.sponsors[_kaz.sponsorNumber++] = _sponsorId;

        kazoos[_kazooId] = _kaz;
        activeSponsoredContent[_sponsorId] = _obj;
    }

    function getKazoo(uint256 _kazooId) public view returns(KazooObject memory)
    {

        return kazoos[_kazooId];
    }

    //returns a list of ids of all the sponsored kazoos that can have sponsoring on them
    function getSponsoredKazoos() public view returns(uint256[] memory)
    {

        uint256 _count = 0;

        //since we need to return a memory array we first need to work out how long to make our turn array
        for(uint256 i = 0; i < kazooId; i++)
            if(kazoos[i].sponsorsEnabled)
                _count++;

        uint256[] memory _kazoos  = new uint256[](_count);
        _count = 0;

        //then, we set the indexes accoridngly
        for(uint256 i = 0; i < kazooId; i++)
            if(kazoos[i].sponsorsEnabled)
                _kazoos[_count++] = i;

        return _kazoos;
    }

    //retursn true if the address has sponsored content
    function hasSponsoredContent(address _sender) public view returns(bool)
    {

        for(uint256 i = 0; i < sponsoredContentId; i++)
            if(activeSponsoredContent[i].owner == _sender)
                return true;

        return false;
    }

    //gets the sponsored content at that id
    function getSponsoredContent(uint256 _sponsorId) public view returns(SponsorObject memory)
    {

        return activeSponsoredContent[_sponsorId];
    }

    //gets all the active sponsored content by an address
    function getActiveSponsoredContent(address _sender) public view returns(uint256[] memory)
    {

        uint256 _count = 0;

        for(uint256 i = 0; i < sponsoredContentId; i++)
            if(activeSponsoredContent[i].owner == _sender)
                _count++;

        uint256[] memory _sponsoredContent = new uint256[](_count);
        _count = 0;

        for(uint256 i = 0; i < sponsoredContentId; i++)
            if(activeSponsoredContent[i].owner == _sender)
                _sponsoredContent[_count++] = i;

        return _sponsoredContent;
    }

    function mintToSender(bool _isSponsored) public payable
    {

        _mint(_msgSender(), _isSponsored );
    }

    function mint(address _addr, bool _isSponsored) public onlyOwner
    {

        _mint(_addr, _isSponsored );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity 0.8.0;

import "./Base64.sol";

/**
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!-- Created with Inkscape (http://www.inkscape.org/) -->

<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   id="svg2"
   version="1.1"
   inkscape:version="0.47 r22583"
   width="524.90448"
   height="274.68848"
   sodipodi:docname="Kazoo.jpg">
  <metadata
	 id="metadata8">
	<rdf:RDF>
	  <cc:Work
		 rdf:about="">
		<dc:format>image/svg+xml</dc:format>
		<dc:type
		   rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
		<dc:title></dc:title>
	  </cc:Work>
	</rdf:RDF>
  </metadata>
  <defs
	 id="defs6">
	<inkscape:perspective
	   sodipodi:type="inkscape:persp3d"
	   inkscape:vp_x="0 : 0.5 : 1"
	   inkscape:vp_y="0 : 1000 : 0"
	   inkscape:vp_z="1 : 0.5 : 1"
	   inkscape:persp3d-origin="0.5 : 0.33333333 : 1"
	   id="perspective10" />
  </defs>
  <sodipodi:namedview
	 pagecolor="#ffffff"
	 bordercolor="#666666"
	 borderopacity="1"
	 objecttolerance="10"
	 gridtolerance="10"
	 guidetolerance="10"
	 inkscape:pageopacity="0"
	 inkscape:pageshadow="2"
	 inkscape:window-width="1280"
	 inkscape:window-height="968"
	 id="namedview4"
	 showgrid="false"
	 inkscape:zoom="1.50625"
	 inkscape:cx="310.94014"
	 inkscape:cy="112.94821"
	 inkscape:window-x="-4"
	 inkscape:window-y="-4"
	 inkscape:window-maximized="1"
	 inkscape:current-layer="svg2" />

</svg>

<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   id="svg2"
   version="1.1"
   inkscape:version="0.47 r22583"
   width="524.90448"
   height="274.68848"
   sodipodi:docname="Kazoo.jpg">
 */

library SVGKazoo {
    function getHeader() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    //the header of the SVG
                    '<svg xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:cc="http://creativecommons.org/ns#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" id="svg2" version="1.1" inkscape:version="0.47 r22583" viewBox="-10 -10 512 512">',
                    "<style>.italic { font: italic 50px sans-serif; } .bold{ font: bold 50px sans-serif; } .comic-sans{font-family:Comic Sans MS, Comic Sans, cursive;font-size:50px;text-shadow:0 1px 0 #ccc, 0 2px 0 #c9c9c9, 0 3px 0 #bbb, 0 4px 0 #b9b9b9, 0 5px 0 #aaa, 0 6px 1px rgba(0,0,0,.1), 0 0 5px rgba(0,0,0,.1), 0 1px 3px rgba(0,0,0,.3), 0 3px 5px rgba(0,0,0,.2), 0 5px 10px rgba(0,0,0,.25), 0 10px 10px rgba(0,0,0,.2), 0 20px 20px rgba(0,0,0,.15)}.impact{font-family:Impact, fantasy;font-size:50px}</style>"
                )
            );
    }

    function buildKazoo(
        string[] memory _styles,
        string[] memory _names,
        uint256 _nonce
    ) public pure returns (string memory) {
        string[] memory paths = buildPaths(_styles);
        bytes memory _s;

        for (uint256 i = 0; i < 13; i++) {
            _s = abi.encodePacked(_s, paths[i]);
        }

        return (
            string(
                abi.encodePacked(
                    getHeader(),
                    //paths
                    _s,
                    //text area
                    buildTextArea(_names, _nonce),
                    getFooter()
                )
            )
        );
    }

    function buildTextArea(string[] memory _names, uint256 _nonce)
        public
        pure
        returns (string memory)
    {
        string memory class = "bold";
        string[] memory textAreas = new string[](_names.length);
        uint256 _nonceNumber = _nonce + 1;

        for (uint256 i = 0; i < _names.length; i++) {
            bytes memory _n = bytes(_names[i]);
            if (_n.length == 0) continue;

            if (_nonceNumber % 5 == 0) class = "italic";
            else if (_nonceNumber % 5 == 1) class = "bold";
            else if (_nonceNumber % 5 == 2) class = "impact";
            else class = "comic-sans"; //most probab

            textAreas[i] = string(
                abi.encodePacked(
                    '<text x="',
                    toString(75 + (i * 20 + 5)),
                    '" y="',
                    toString(216 + (i * 50 + 2)),
                    '" class="',
                    class,
                    '">',
                    _names[i],
                    "</text>"
                )
            );
            _nonceNumber++;
        }

        string memory _ta;

        for (uint256 i = 0; i < _names.length; i++) {
            bytes memory _n = bytes(textAreas[i]);
            if (_n.length == 0) continue;

            _ta = string(abi.encodePacked(_ta, textAreas[i]));
        }

        return _ta;
    }

    function getHexCode(uint256 _mNumber) public pure returns (string memory) {
        return string(abi.encodePacked("#", _intToHexString(uint24(_mNumber))));
    }

    function _intToHexString(uint24 i) internal pure returns (string memory) {
        bytes memory o = new bytes(6);
        uint24 mask = 0x00000f;
        o[5] = bytes1(_toHexChar(uint8(i & mask)));
        i = i >> 4;
        o[4] = bytes1(_toHexChar(uint8(i & mask)));
        i = i >> 4;
        o[3] = bytes1(_toHexChar(uint8(i & mask)));
        i = i >> 4;
        o[2] = bytes1(_toHexChar(uint8(i & mask)));
        i = i >> 4;
        o[1] = bytes1(_toHexChar(uint8(i & mask)));
        i = i >> 4;
        o[0] = bytes1(_toHexChar(uint8(i & mask)));
        return string(o);
    }

    function _toHexChar(uint8 i) internal pure returns (uint8) {
        return
            (i > 9)
                ? (i + 87) // ascii a-f
                : (i + 48); // ascii 0-9
    }

    function toString(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function buildPaths(string[] memory _styles)
        public
        pure
        returns (string[] memory)
    {
        string[] memory _cords = getKazooCords();
        string[] memory _return = new string[](13);

        for (uint256 i = 0; i < 13; i++) {
            _return[i] = buildPath(
                _styles[i],
                _cords[i],
                string(abi.encodePacked('id="', toString(i), '"'))
            );
        }

        return _return;
    }

    function getKazooCords() internal pure returns (string[] memory) {
        //the cords for the kazoo
        //maybe move this to the kazoo NFT as its kinda just sitting here LOL
        string[] memory _cords = new string[](13);
        _cords[0] = "M 1.438897,10.358418 0.5,35.23919 c 112.25619,93.33457 376.72295,214.61628 477.89856,238.94928 L 483.09304,254.47163 1.438897,10.358418 z";
        _cords[1] = "M 1.438897,9.88897 C 141.71843,124.29882 393.13787,225.22368 483.5625,254.00218 l 40.37256,-67.13113 C 361.26882,110.35993 180.66139,43.74209 13.644558,0.5 7.69821,2.377794 3.629657,5.507451 1.438897,9.88897 z";
        _cords[2] = "m 231.51711,111.4692 c 43.91004,11.65092 82.22192,6.91486 116.84647,-5.3112 l 0,21.07884 c -1.69764,27.25255 -83.22573,50.02984 -116.51453,3.9834 l -0.33194,-19.75104 z";
        _cords[3] = "m 229.35943,100.8468 120.82988,-0.33195 c -3.09393,47.80139 -118.51047,50.55913 -120.82988,0.33195 z";
        _cords[4] = "m 229.19345,100.1829 c 31.73314,44.04316 102.08864,32.31802 119.17013,2.6556 l -119.17013,-2.6556 z";
        _cords[5] = "M 206.80027,57.80154 C 226.31958,6.152344 343.06582,6.841636 372.85315,54.54711 c 1.22328,4.60971 2.1986,8.51524 1.5834,13.12495 -10.07214,61.41638 -147.71093,68.27081 -168.92529,2.80083 -0.51337,-3.91081 -0.0606,-8.99526 1.28901,-12.67135 z";
        _cords[6] = "m 230.25772,38.14111 c 61.73061,-37.985219 137.94067,-3.27901 133.85143,29.25534 -1.42523,8.27975 -6.38744,15.69384 -7.88418,16.81582 -15.67222,25.15589 -160.24039,27.85808 -137.94466,-31.41792 3.66586,-7.58193 6.61051,-9.79059 11.97741,-14.65324 z";
        _cords[7] = "M 226.69257,69.59763 C 225.98301,106.32248 349.2278,113.31095 353.08019,71.1731 345.17218,26.406275 237.09425,20.744939 226.69257,69.59763 z";
        _cords[8] = "m 232.93477,82.61512 c 9.65844,-53.18144 115.43585,-31.4868 113.84354,0.12727 -9.92783,18.57446 -89.89843,28.11135 -113.84354,-0.12727 z";
        _cords[9] = "m 239.47137,87.92636 c 21.41038,17.75501 76.03527,18.71165 99.25455,1.40041 -16.86878,-28.02994 -88.51338,-23.48461 -99.25455,-1.40041 z";
        _cords[10] = "m 245.07304,91.25235 c 12.15269,-23.33902 78.67774,-18.2816 88.40131,0.7002 -7.98436,10.15978 -67.45455,16.53878 -88.40131,-0.7002 z";
        _cords[11] = "m 259.42731,97.84079 c 14.57454,-13.96873 48.90685,-11.56993 64.41918,-1.20721 -18.97981,6.42898 -39.40963,9.62067 -64.41918,1.20721 z";
        _cords[12] = "m 519.24058,207.05734 5.16393,-19.24739 -40.84202,66.19223 -5.16393,19.71684 40.84202,-66.66168 z";

        return _cords;
    }

    function buildPath(
        string memory _style,
        string memory _cord,
        string memory _extras
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path ",
                    _style,
                    ' d="',
                    _cord,
                    '" ',
                    _extras,
                    "/>"
                )
            );
    }

    function getStyle(
        string memory fill,
        string memory stroke,
        uint256 strokewidth
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'style="fill:',
                    fill,
                    ";stroke:",
                    stroke,
                    ";stroke-width:",
                    strokewidth,
                    'px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"'
                )
            );
    }

    function getFooter() public pure returns (string memory) {
        return string("</svg>");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
* @dev Library to help with base64 functions.
* This seems to be increasingly useful for things like on-chain images.
*
* Adapted from https://github.com/OpenZeppelin/solidity-jwt/blob/master/contracts/Base64.sol
*/

library Base64 {
    bytes private constant base64stdchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes private constant base64urlchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    function encode(string memory _str) internal pure returns (string memory) {
        bytes memory _bs = bytes(_str);
        uint256 rem = _bs.length % 3;

        uint256 res_length = ((_bs.length + 2) / 3) * 4 - ((3 - rem) % 3);
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= _bs.length; i += 3) {
            (res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(
                uint8(_bs[i]),
                uint8(_bs[i + 1]),
                uint8(_bs[i + 2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(_bs[_bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(_bs[_bs.length - 1]);
            }

            //(bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) = encode3(la0, la1, 0);
            (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j + 1] = b1;
            if (rem == 2) {
                res[j + 2] = b2;
            }
        }

        // Add base64 padding.
        uint256 resRemainder = res.length;
        if (resRemainder % 4 != 0) {
            if (4 - (resRemainder % 4) == 1) {
                res = abi.encodePacked(res, '=');
            } else if (4 - (resRemainder % 4) == 2) {
                res = abi.encodePacked(res, '==');
            }
        }

        return string(res);
    }

    function encode3(
        uint256 a0,
        uint256 a1,
        uint256 a2
    )
        private
        pure
        returns (
            bytes1 b0,
            bytes1 b1,
            bytes1 b2,
            bytes1 b3
        )
    {
        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >> 6) & 63;
        uint256 c3 = (n) & 63;

        b0 = base64stdchars[c0];
        b1 = base64stdchars[c1];
        b2 = base64stdchars[c2];
        b3 = base64stdchars[c3];
    }
}