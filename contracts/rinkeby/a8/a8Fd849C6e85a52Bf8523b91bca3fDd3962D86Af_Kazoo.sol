//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./KazooBuilder.sol";
import "./KazooGlobals.sol";
import "./KazooData.sol";

//written by Llydia Cross
contract Kazoo is ERC721URIStorage, Ownable {
    //kaz data
    KazooData dataContract;
    //accessible
    //the id of the kazoo next to be minted.
    uint256 public kazooId;

    //the id of the next sponsored content to be created
    uint256 public sponsoredContentId;
    //inaccessible
    //this is the total profit from minted Kazoos
    uint256 public mintedBalance;
    uint256 public sponsorBalance;
    //the random seed of which we base all randomisation off of
    uint256 private randomSeed;

    uint256 private shift;
    uint256 private previewCount;

    //matches KazooData
    uint256 private securityPass;

    KazooObject private _current;

    //this is the master wallet aka the wallet we can withdraw mint profits too
    address payable private masterWallet;

    //events
    event mintedKazoo(uint256 kazooId, KazooObject kazoo); //self explanatory
    event startedSponsorship(uint256 sponsorId, SponsorObject sponsor); //self explanatory

    constructor(
        address _contractLocation,
        uint256 _shift,
        uint256 _pass
    ) ERC721("Kazoo", "KAZ") {
        shift = _shift;
        securityPass = _pass << _shift;
        dataContract = KazooData(_contractLocation); //address
        masterWallet = payable(msg.sender); //set the master wallet to the sender
        kazooId = 0; //set kazoo id to 0
        previewCount = 0; //set preview count to zero
        sponsoredContentId = 1; //this starts at one so any zeros can be ignored as "invalid unset sponsored content"
        mintedBalance = 0; //this starts at one so any zeros can be ignored as "invalid unset sponsored content"
        sponsorBalance = 0; //this starts at one so any zeros can be ignored as "invalid unset sponsored content"
        randomSeed = 1337; //the random seed to base all randomness off
        //the names you can get from the name generator, definately over 25~
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _kazooId,
        bytes memory _data
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), _kazooId));

        dataContract.transfer(_to, _kazooId, parsePass(securityPass));
        _safeTransfer(_from, _to, _kazooId, _data);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _kazooId
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), _kazooId));
        dataContract.transfer(_to, _kazooId, parsePass(securityPass));
        _transfer(_from, _to, _kazooId);
    }

    //this is what actually creates and then mints our token
    function _mint(address _addr, bool _isSponsored) private {
        require(_msgSender() != address(0));
        require(kazooId != KazooGlobals.MAX_KAZOOS); //max kaz have been met

        //get a random number using the senders address, followed by the cap for the random number, then a nonce (kazooId) which basically acts as a salt, and them the randomSeed which we keep changing
        //to further more variate the randomness
        uint256 _randomNumber = KazooBuilder.randomNumber(
            _msgSender(),
            KazooGlobals.RANDOM_NUMBER,
            kazooId,
            randomSeed++
        );

        KazooObject memory object = dataContract.createKazooObject(
            payable(_addr),
            kazooId,
            _randomNumber,
            _isSponsored,
            (_randomNumber % KazooGlobals.SPECIAL_NUMBER == 0)
        );

        //generate a new random number
        uint256 _randomNameNumber = KazooBuilder.randomNumber(
            _msgSender(),
            object.masterNumber >> 2,
            kazooId,
            randomSeed++
        );
        uint256 _times = _randomNameNumber % (KazooGlobals.MAX_NAMES - 1); //will be either 1, 2 or 3 times

        //then name the kazoo and build its SVG
        object = dataContract.nameKazoo(
            kazooId,
            kazooId + 1,
            _times,
            _randomNameNumber,
            object
        );
        object = setKazooNumber(object, _times);
        object = buildKazooSVG(kazooId, object);

        //then we set the kazoo inside the kazoos array and check the returned result matches our count, if it does
        //not then malicious data has potentially been injected and we will not allow any more mints
        require(
            kazooId + 1 !=
                dataContract.addKazoo(object, parsePass(securityPass))
        ); //adds a Kazoo

        //finally, mint
        _safeMint(_addr, kazooId);
        _setTokenURI(kazooId, "{}"); //setting it to some invalid json apparently makes open sea refresh the thumbnails instead of having you hit the "refresh button"

        //emit we are done and finally increment the kaz id for the next token boi
        emit mintedKazoo(kazooId++, object); //emit the updated method
    }

    //this will rebuild the kazoo and is designed to be called when new sponsorships begin or end or you just want to rebuild the SVG of the kazoo
    function _rebuildKazoo(uint256 _kazooId, bool _isOwner) private {
        //if this kazooID is valid
        require(_kazooId >= 0 && _kazooId <= kazooId);

        KazooObject memory _kaz = dataContract.get(_kazooId);

        //there are 14 points to the kazoo that we need to fill a background colour and a border colour, so we loop 13
        string[] memory _styles = new string[](13);
        for (uint256 i = 0; i < 13; i++) {
            _styles[i] = string(
                KazooBuilder.getStyle(
                    _kaz.backgroundColours[i], //these are saved when we first mint the NFT
                    _kaz.borderColour, //these are saved when we first mint the NFT
                    2
                )
            );
        }

        //rebuilds the kazoo
        _kaz.kazoo = KazooBuilder.buildKazoo(
            //returns a DrawData struct which is defined in  KazooBuilder.sol
            KazooBuilder.createDrawData(
                _styles, //the styles array
                _kaz.names, //the names array holding all of our names
                KazooBuilder.getHexCode(_kaz.masterNumber >> 2), //this is confusingly not the backgroundColour of the kazoo but the ACTUAL background colour of the SVG
                _kaz.masterNumber < (KazooGlobals.RANDOM_NUMBER >> 1) //this is a small tennary function which figures out if our random number is close to 0xFFFFFF (black), if it is, it will make //the text colour while, it will do the oposite if it is closer to white, and make the text colour black
                    ? KazooBuilder.getHexCode(KazooGlobals.RANDOM_NUMBER) //white
                    : abi.encodePacked("#000000"),
                _kaz.masterNumber //black
            ),
            //returns a SponsorData struct which is defined in SVGKazoo
            KazooBuilder.createSponsorData(
                _kaz.sponsors, //the array which holds our sponsor Ids, please be aware that 0 is not a valid sponsorId
                //NOTE: need to also pass the name
                dataContract.getSponsorContent(
                    _kaz.sponsors,
                    sponsoredContentId
                ) //gets the raw SVG content for our sponsors, please be area that 0 is not a valid sponsorId
            ),
            _kaz.isSpecial
        );

        if (_isOwner == false) dataContract.set(_kazooId, _kaz);
        else dataContract.forced(_kazooId, _kaz);
    }

    //caller must be token owner
    function rebuildKazoo(uint256 _kazooId) public {
        _rebuildKazoo(_kazooId, false);
    }

    //caller must be owner
    function forceRebuildKazoo(uint256 _kazooId) public onlyOwner {
        _rebuildKazoo(_kazooId, true);
    }

    function toggleAdvertising(uint256 _kazooId) public {
        require(_isApprovedOrOwner(_msgSender(), _kazooId));
        dataContract.toggleAdvertising(_kazooId, parsePass(securityPass));
    }

    function previewKazoo()
        public
        returns (KazooObject memory kaz, uint256 pCount)
    {
        require(_msgSender() != address(0));

        dataContract.deleteOldRequests(_msgSender(), previewCount);

        uint256 _randomNumber = KazooBuilder.randomNumber(
            _msgSender(),
            KazooGlobals.RANDOM_NUMBER,
            kazooId,
            randomSeed++
        );

        //create a initial kazoo object
        kaz = dataContract.createKazooObject(
            payable(_msgSender()),
            kazooId,
            _randomNumber,
            false,
            (_randomNumber % KazooGlobals.SPECIAL_NUMBER == 0)
        );

        //generate a new random number
        uint256 _randomNameNumber = KazooBuilder.randomNumber(
            _msgSender(),
            kaz.masterNumber >> 2,
            kazooId,
            randomSeed++
        );
        uint256 _times = _randomNameNumber % (KazooGlobals.MAX_NAMES - 1); //will be either 1, 2 or 3 times

        //then name the kazoo and build its SVG
        kaz = dataContract.nameKazoo(
            kazooId,
            kazooId + 1,
            _times,
            _randomNameNumber,
            kaz
        );
        kaz = setKazooNumber(kaz, _times);
        kaz = buildKazooSVG(kazooId, kaz);

        dataContract.addPreviewKazoo(
            _msgSender(),
            kaz,
            previewCount,
            parsePass(securityPass)
        );

        pCount = previewCount;
        previewCount = previewCount + 1;
    }

    function getPreviewCount() public view returns (uint256) {
        return previewCount;
    }

    function getPreview(uint256 _previewId)
        public
        view
        returns (KazooObject memory)
    {
        return dataContract._getPreviewKazoo(_previewId);
    }

    function mintPreview(uint256 _previewId) public payable {
        //this will throw if anything is bad and also delete it from the views if its okay
        dataContract.addKazoo(
            dataContract.getPreviewKazoo(
                _msgSender(),
                msg.value,
                _previewId,
                previewCount,
                kazooId //the new kazoo id to set it too
            ),
            parsePass(securityPass)
        );

        //finally, mint
        _safeMint(_msgSender(), kazooId);
        _setTokenURI(kazooId, "{}"); //setting it to some invalid json apparently makes open sea refresh the thumbnails instead of having you hit the "refresh button"

        //emit we are done and finally increment the kaz id for the next token boi
        emit mintedKazoo(kazooId, dataContract.get(kazooId)); //emit the updated method
        kazooId++; //increment
    }

    //this is the main function which builds the SVG code for our kazoo, it will always build the same Kazoo as long as the initial masterNumber has not been modified
    function buildKazooSVG(uint256 _kazooId, KazooObject memory _kaz)
        private
        view
        returns (KazooObject memory result)
    {
        //if it is a valid kazoo
        require(_kazooId >= 0 && _kazooId <= kazooId);

        //just like before we need 14 styles to build the kazoo.
        string[] memory _styles = new string[](13);
        //will effectively make the border darker
        _kaz.borderColour = KazooBuilder.getHexCode(_kaz.masterNumber >> 1);

        for (uint256 i = 0; i < 13; i++) {
            //will make the background colours brigher than the static border and basically step up in the colour char to a ligher colour (0xfffff)
            _kaz.backgroundColours[i] = KazooBuilder.getHexCode(
                (_kaz.masterNumber >> 1) * ((((i + 4)) << 1) >> 1)
            );

            //set it
            _styles[i] = string( //cast it
                KazooBuilder.getStyle(
                    _kaz.backgroundColours[i],
                    _kaz.borderColour,
                    _kaz.masterNumber % 3 //this will set the stroke width of the lines on the Kazoo to either 0, 1, 2 or 3
                )
            );
        }

        //once we have got our styles its time to build our kazoo, this is exactly the same as rebuildSVG
        //TODO: Branch this into its own function to remove duplicated code
        _kaz.kazoo = KazooBuilder.buildKazoo(
            KazooBuilder.createDrawData( //see rebuildSVG function above for the comments on how this works
                _styles,
                _kaz.names,
                KazooBuilder.getHexCode(_kaz.masterNumber >> 2),
                _kaz.masterNumber < (KazooGlobals.RANDOM_NUMBER >> 1)
                    ? KazooBuilder.getHexCode(KazooGlobals.RANDOM_NUMBER) //white
                    : abi.encodePacked("#000000"),
                _kaz.masterNumber //black
            ),
            KazooBuilder.createSponsorData(
                _kaz.sponsors,
                dataContract.getSponsorContent(
                    _kaz.sponsors,
                    sponsoredContentId
                )
            ),
            _kaz.isSpecial
        );

        //set result
        result = _kaz;
    }

    //this will generate the TokenURI on the chain for us and then return it as a string
    //due to Base64.encode(Base64.encode( data )) breaking things for me, I've had to change my logic and
    //instead have you manually call a tokenURI setter method. It results in lower gas fees anyway, but does mean
    //the user needs to make sure they set their TokenURI.
    function generateTokenURI(uint256 _kazooId)
        public
        view
        returns (string memory)
    {
        require(_kazooId >= 0 && _kazooId <= kazooId);

        bytes memory _name;
        string memory _kazoo;

        (_name, _kazoo) = dataContract.getNameAndKazoo(_kazooId);

        return
            KazooBuilder.getMetadata(
                _name,
                abi.encodePacked(
                    "This Kazoo is number ",
                    KazooBuilder.toString(_kazooId),
                    " in the collection!"
                ),
                _kazoo
            );
    }

    //the thinking with this method is that we can call it through a server which has
    //owner or approved access to this contract and essentially forcefully set the kazoos
    //metadata. This would be used in a chain with getTokenURI to ensure the metadata is correct
    //as per the contracts standards on a node server which has owner acccess.
    function forceTokenURI(uint256 _kazooId, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(_kazooId, _tokenURI);
    }

    function setTokenURI(uint256 _kazooId, string memory _tokenURI) public {
        require(_isApprovedOrOwner(_msgSender(), _kazooId));
        _setTokenURI(_kazooId, _tokenURI);
    }

    function setKazooNumber(KazooObject memory _kaz, uint256 _times)
        public
        view
        returns (KazooObject memory kazoo)
    {
        //will return a number of names which are the same as this, if it isn't zero then we'll add an number to denote its not unique
        uint256 _dupes = dataContract.countNames(_kaz.uniqueName, kazooId);
        if (_dupes != 0) {
            //if dupes arent zero
            _kaz.names[_times + 1] = string(
                abi.encodePacked("Kazoo #", KazooBuilder.toString(_dupes + 1)) //set the Kazoo right at the end to add the number, we plus one it as we are creating an ew one
            );
            _kaz.name = abi.encodePacked(
                _kaz.name,
                " #",
                KazooBuilder.toString(_dupes + 1)
            ); //also change the raw name over too
        } else {
            _kaz.name = _kaz.name; //just set it if there are no dupes and do not change anything
        }

        kazoo = _kaz;
    }

    function startSponsorship(
        string memory _sponsoredName,
        string memory _sponsoredContent,
        uint256 _environment
    ) public payable {
        require(msg.value == KazooGlobals.SPONSOR_PRICE);

        //
        require(
            sponsoredContentId + 1 !=
                dataContract.addSponsor(
                    SponsorObject(
                        sponsoredContentId,
                        payable(_msgSender()),
                        msg.value,
                        _sponsoredName,
                        _environment,
                        abi.encodePacked(_sponsoredContent)
                    ),
                    parsePass(securityPass)
                )
        );

        //emit we are done and increment the kaz id
        emit startedSponsorship(
            sponsoredContentId++,
            dataContract.getSponsor(sponsoredContentId)
        );
    }

    function setSponsorEnvironment(uint256 _sponsorId, uint256 _env) public {
        require(_sponsorId >= 1 && _sponsorId <= sponsoredContentId);

        dataContract.setSponsorEnvironment(
            _sponsorId,
            _env,
            parsePass(securityPass)
        );
    }

    function setKazooEnvironment(uint256 _kazooId, uint256 _env) public {
        require(_kazooId >= 0 && _kazooId <= kazooId);

        dataContract.setKazooEnvironment(
            _kazooId,
            _env,
            parsePass(securityPass)
        );
    }

    function sponsorKazoo(uint256 _sponsorId, uint256 _kazooId) public {
        require(_kazooId >= 0 && _kazooId <= kazooId);
        require(_sponsorId >= 1 && _sponsorId <= sponsoredContentId, "2");

        dataContract.sponsorKazoo(_msgSender(), _sponsorId, _kazooId);
    }

    function getSponsorIds(uint256 _kazooId)
        public
        view
        returns (uint256[] memory)
    {
        require(_kazooId >= 0 && _kazooId <= kazooId);

        return dataContract.getSponsorIds(_kazooId);
    }

    function getKazoo(uint256 _kazooId)
        public
        view
        returns (KazooObject memory kaz)
    {
        kaz = dataContract.get(_kazooId);
    }

    function findKazoo(address _addr) public view returns (uint256) {
        return dataContract.getKazoo(payable(_addr));
    }

    function findEarliestKazoo(address _addr) public view returns (uint256) {
        return dataContract.getEarliestKazoo(payable(_addr));
    }

    function getMaxKazoos() public pure returns (uint256) {
        return KazooGlobals.MAX_KAZOOS;
    }

    function getSponsorPrice() public pure returns (uint256) {
        return KazooGlobals.SPONSOR_PRICE;
    }

    function getMintPrice() public pure returns (uint256) {
        return KazooGlobals.MINT_PRICE;
    }

    function getSponsorCreationPrice() public pure returns (uint256) {
        return KazooGlobals.SPONSOR_CREATION_PRICE;
    }

    function withdraw() public payable onlyOwner {
        payable(_msgSender()).transfer(mintedBalance);
        mintedBalance = 0.0;
    }

    function withdrawProfits(uint256 _kazooId) public payable {
        require(_isApprovedOrOwner(_msgSender(), _kazooId));
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //we do the adverse inside KazooData
    function parsePass(uint256 _pass) private view returns (uint256) {
        return (_pass >> shift);
    }

    function getMintBalance() public view returns (uint256) {
        return mintedBalance;
    }

    //apparently its automatically handled
    function mintToSender(bool _isSponsored) public payable {
        require(msg.value == KazooGlobals.MINT_PRICE); //they have paid

        _mint(_msgSender(), _isSponsored);
        mintedBalance = mintedBalance + KazooGlobals.MINT_PRICE;
    }

    function mint(address _addr, bool _isSponsored) public onlyOwner {
        _mint(_addr, _isSponsored);
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
import "./KazooGlobals.sol";

library KazooBuilder {
    struct SponsorData {
        uint256[] sponsorId;
        string[] sponsorContent;
    }

    struct DrawData {
        string[] names;
        string[] styles;
        uint256 specialNumber;
        bytes paths;
        bytes backgroundColour;
        bytes textColour;
    }

    function getHeader(bytes memory _backgroundColour)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                //the header of the SVG
                '<svg xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:cc="http://creativecommons.org/ns#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" id="svg2" version="1.1" inkscape:version="0.47 r22583" viewBox="-45 -25 600 320">',
                getStyles(_backgroundColour)
            );
    }

    function getStyles(bytes memory _backgroundColor)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "<style>",
                "svg{ background-color:",
                _backgroundColor,
                ";}",
                ".italic{font:italic 18px sans-serif}.bold{font:bold 18px sans-serif}.comic-sans{font-family:Comic Sans MS, Comic Sans, cursive;font-size:18px}.impact{font-family:Impact, fantasy;font-size:18px}.dark-outline{filter: drop-shadow( 1px 0px 0px rgba(0, 0, 0, 0.5)) drop-shadow( 1px 0px 1px rgba(255, 0, 0, 0.5)) drop-shadow( 1px 1px 1px rgba(0, 255, 0, 0.5))}.white-outline{filter: drop-shadow( 1px 0px 0px rgba(255, 255, 255, 0.5)) drop-shadow( 1px 0px 1px rgba(255, 0, 0, 0.5)) drop-shadow( 1px 1px 1px rgba(0, 255, 0, 0.5))}"
                "</style>"
            );
    }

    function getSpecialStyles() private pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<style>",
                "path{animation-name:special;animation-duration:1000ms;animation-iteration-count:infinite !important;animation-direction:normal}@keyframes special{0%{filter: hue-rotate(90deg)}25%{filter: hue-rotate(45deg)}50%{filter: hue-rotate(180deg)}100%{filter: hue-rotate(90deg)}}",
                "</style>"
            );
    }

    function createDrawData(
        string[] memory _styles,
        string[] memory _names,
        bytes memory _backgroundColour,
        bytes memory _textColour,
        uint256 _specialNumber
    ) external pure returns (DrawData memory _r) {
        _r = DrawData(
            _names,
            _styles,
            _specialNumber,
            "",
            _backgroundColour,
            _textColour
        );
        string[] memory _paths = buildPaths(_styles);

        for (uint256 i = 0; i < 13; i++) {
            _r.paths = abi.encodePacked(_r.paths, _paths[i]);
        }
    }

    function isDarker(uint256 _masterNumber) public pure returns (bool) {
        return (_masterNumber < (KazooGlobals.RANDOM_NUMBER >> 1));
    }

    function createSponsorData(
        uint256[] memory _sponsorIds,
        string[] memory _sponsorContent
    ) external pure returns (SponsorData memory _r) {
        _r = SponsorData(_sponsorIds, _sponsorContent);
    }

    function buildKazoo(
        DrawData memory _drawData,
        SponsorData memory _sponsorData,
        bool _isSpecial
    ) external pure returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    getHeader(_drawData.backgroundColour),
                    //add special styles
                    _isSpecial ? getSpecialStyles() : bytes(""),
                    //paths
                    _drawData.paths,
                    //text area
                    buildTextArea(
                        _drawData.names,
                        _drawData.textColour,
                        isDarker(_drawData.specialNumber),
                        _sponsorData
                    ),
                    getFooter()
                )
            )
        );
    }

    function buildTextArea(
        string[] memory _names,
        bytes memory _textColour,
        bool _isDarker,
        SponsorData memory _sponsorData
    ) private pure returns (string memory) {
        string memory class = "bold";
        string[] memory textAreas = new string[](_names.length);
        uint256 _cl;

        for (uint256 i = 0; i < _names.length; i++) {
            bytes memory _n = bytes(_names[i]);
            if (_n.length == 0) continue;

            if (i < 2) class = "comic-sans";
            else class = "bold";

            if (!_isDarker)
                class = string(abi.encodePacked(class, " white-outline"));
            else class = string(abi.encodePacked(class, " dark-outline"));

            uint256 _sp = 40;
            //dont do it for the first element
            if (i != 0) _sp = (stringLength(_names[i - 1]) * 18); //comic sans is a bit larger and more cursive so we add a bit of padding
            _cl = _cl + ((_sp / 2) + 18); //padding

            //if the current location + the length of the current name sets us over
            if (
                i != 0 &&
                _cl + (stringLength(_names[i]) * 10) > 245 &&
                _cl < 345
            )
                //if 345 continue from there
                _cl = 345;

            if (
                i != 0 &&
                _cl + (stringLength(_names[i]) * 10) > 490 &&
                _cl < 635
            )
                //if its greater than 490 then we want to skip to 475 and continue from there
                _cl = 635;

            if (
                i != 0 &&
                _cl + (stringLength(_names[i]) * 10) > 750 &&
                _cl < 965
            )
                //skip the top middle part of the kazoo nozzle :D
                _cl = 965;

            textAreas[i] = string(
                abi.encodePacked(
                    '<text dy="-2%" fill="',
                    string(_textColour),
                    '">',
                    '<textPath href="#1" startOffset="',
                    toString(_cl),
                    '" class="',
                    class,
                    '">',
                    _names[i],
                    "</textPath>"
                    "</text>"
                )
            );
        }

        string memory _ta;

        for (uint256 i = 0; i < _names.length; i++) {
            bytes memory _n = bytes(textAreas[i]);
            if (_n.length == 0) continue;

            _ta = string(abi.encodePacked(_ta, textAreas[i]));
        }

        return _ta;
    }

    function getMetadata(
        bytes memory _name,
        bytes memory _description,
        string memory _kazoo
    ) external pure returns (string memory _r) {
        _r = string(
            abi.encodePacked(
                '{"name":"',
                _name,
                '", "description":"',
                _description,
                '", "image":"data:image/svg+xml;base64,',
                Base64.encode(_kazoo),
                '", "attributes": []}'
            )
        );
    }

    function finalizeMetadata(string memory _encodedMetadata)
        external
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(_encodedMetadata)
                )
            );
    }

    function kazooToBase64(string memory _kazoo)
        external
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(_kazoo)
                )
            );
    }

    function base64Encode(string memory _d)
        external
        pure
        returns (string memory)
    {
        return Base64.encode(_d);
    }

    function randomNumber(
        address _address,
        uint256 _modulus,
        uint256 _nonce,
        uint256 _randomSeed
    ) external view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        block.number,
                        _nonce,
                        _address,
                        _randomSeed++
                    )
                )
            ) % _modulus;
    }

    function placeholderMetadata() external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        string(
                            abi.encodePacked(
                                '{ "name": "Metadata Missing Kazoo", "description": "This kazoo needs its metadata set! Go to kazookid.club and request a metadata refresh!", "image": "http://i.stack.imgur.com/ajwm5.png", "attributes": []}'
                            )
                        )
                    )
                )
            );
    }

    function stringLength(string memory str)
        private
        pure
        returns (uint256 length)
    {
        bytes memory _b = bytes(str);
        uint256 i;

        while (i < _b.length) {
            uint256 b = bytesToInt(_b[i]);

            if (b >> 7 == 0) i += 1;
            else if (b >> 5 == 0x6) i += 2;
            else if (b >> 4 == 0xE) i += 3;
            else if (b >> 3 == 0x1E)
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    function bytesToInt(bytes1 b) public pure returns (uint256) {
        uint256 number;
        for (uint256 i = 0; i < b.length; i++) {
            number = number + uint8(b[i]);
        }
        return number;
    }

    function getHexCode(uint256 _mNumber)
        external
        pure
        returns (bytes memory _r)
    {
        _r = abi.encodePacked("#", _intToHexString(uint24(_mNumber)));
    }

    function _intToHexString(uint24 i) private pure returns (string memory) {
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

    function _toHexChar(uint8 i) private pure returns (uint8) {
        return
            (i > 9)
                ? (i + 87) // ascii a-f
                : (i + 48); // ascii 0-9
    }

    function toString(uint256 _i)
        public
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
        private
        pure
        returns (string[] memory)
    {
        string[13] memory _cords = getKazooCords();
        string[] memory _return = new string[](13);

        for (uint256 i = 0; i < 13; i++) {
            _return[i] = string(
                buildPath(
                    _styles[i],
                    _cords[i],
                    abi.encodePacked('id="', toString(i), '"')
                )
            );
        }

        return _return;
    }

    function getKazooCords() private pure returns (string[13] memory _cords) {
        _cords = [
            "M 1.438897,10.358418 0.5,35.23919 c 112.25619,93.33457 376.72295,214.61628 477.89856,238.94928 L 483.09304,254.47163 1.438897,10.358418 z",
            "M 1.438897,9.88897 C 141.71843,124.29882 393.13787,225.22368 483.5625,254.00218 l 40.37256,-67.13113 C 361.26882,110.35993 180.66139,43.74209 13.644558,0.5 7.69821,2.377794 3.629657,5.507451 1.438897,9.88897 z",
            "m 231.51711,111.4692 c 43.91004,11.65092 82.22192,6.91486 116.84647,-5.3112 l 0,21.07884 c -1.69764,27.25255 -83.22573,50.02984 -116.51453,3.9834 l -0.33194,-19.75104 z",
            "m 229.35943,100.8468 120.82988,-0.33195 c -3.09393,47.80139 -118.51047,50.55913 -120.82988,0.33195 z",
            "m 229.19345,100.1829 c 31.73314,44.04316 102.08864,32.31802 119.17013,2.6556 l -119.17013,-2.6556 z",
            "M 206.80027,57.80154 C 226.31958,6.152344 343.06582,6.841636 372.85315,54.54711 c 1.22328,4.60971 2.1986,8.51524 1.5834,13.12495 -10.07214,61.41638 -147.71093,68.27081 -168.92529,2.80083 -0.51337,-3.91081 -0.0606,-8.99526 1.28901,-12.67135 z",
            "m 230.25772,38.14111 c 61.73061,-37.985219 137.94067,-3.27901 133.85143,29.25534 -1.42523,8.27975 -6.38744,15.69384 -7.88418,16.81582 -15.67222,25.15589 -160.24039,27.85808 -137.94466,-31.41792 3.66586,-7.58193 6.61051,-9.79059 11.97741,-14.65324 z",
            "M 226.69257,69.59763 C 225.98301,106.32248 349.2278,113.31095 353.08019,71.1731 345.17218,26.406275 237.09425,20.744939 226.69257,69.59763 z",
            "m 232.93477,82.61512 c 9.65844,-53.18144 115.43585,-31.4868 113.84354,0.12727 -9.92783,18.57446 -89.89843,28.11135 -113.84354,-0.12727 z",
            "m 239.47137,87.92636 c 21.41038,17.75501 76.03527,18.71165 99.25455,1.40041 -16.86878,-28.02994 -88.51338,-23.48461 -99.25455,-1.40041 z",
            "m 245.07304,91.25235 c 12.15269,-23.33902 78.67774,-18.2816 88.40131,0.7002 -7.98436,10.15978 -67.45455,16.53878 -88.40131,-0.7002 z",
            "m 259.42731,97.84079 c 14.57454,-13.96873 48.90685,-11.56993 64.41918,-1.20721 -18.97981,6.42898 -39.40963,9.62067 -64.41918,1.20721 z",
            "m 519.24058,207.05734 5.16393,-19.24739 -40.84202,66.19223 -5.16393,19.71684 40.84202,-66.66168 z"
        ];
    }

    function buildPath(
        string memory _style,
        string memory _cord,
        bytes memory _extras
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<path ",
                _style,
                ' d="',
                _cord,
                '" ',
                _extras,
                "/>"
            );
    }

    function getStyle(
        bytes memory fill,
        bytes memory stroke,
        uint256 strokewidth
    ) external pure returns (bytes memory) {
        return
            abi.encodePacked(
                'style="fill:',
                string(fill),
                ";stroke:",
                string(stroke),
                ";stroke-width:",
                toString(strokewidth),
                'px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"'
            );
    }

    function getFooter() private pure returns (bytes memory) {
        return abi.encodePacked("</svg>");
    }
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity 0.8.0;

import "./Base64.sol";

library KazooGlobals {
    //the value of one token on the network is exactly 1000000000000000000
    uint256 public constant TOKEN_VALUE = 0.1 * 10**19; //the same as 1 eth
    //the maximum amount of Kazoos that can be minted
    uint256 public constant MAX_KAZOOS = 1879;
    //the maximum amount of sponsors a kazoo can have (up to 16 ad spots)
    uint256 public constant MAX_SPONSORS = 16;
    //this number is divided by the kazoos special number and if there are no remainders it means this kazoo is special and has SVG animations
    uint256 public constant SPECIAL_NUMBER = 16;
    //how long the kazoos name will be, need to also include a spot for kazoo, with 4 max names it will spin a name up to three times.
    uint256 public constant MAX_NAMES = 7; //"Kazoo" is also a name so include a number for it
    //this is essentially the largest a random number can be and is the integer equivilent of 0xffffff
    uint256 public constant RANDOM_NUMBER = 16777215; //0xffffff
    //prices
    //this is how much it costs to mint a new Kazoo
    uint256 public constant MINT_PRICE = TOKEN_VALUE / 10; //1 eth or matic or what ever
    //this is how much it costs to create a new sponsor object which is then used to sponsor an object
    uint256 public constant SPONSOR_CREATION_PRICE = TOKEN_VALUE / 50; //half of an eth or matic what ever
    //this is how much it costs to sponsor a kazoo
    uint256 public constant SPONSOR_PRICE = TOKEN_VALUE / 100; //can roughly sponsor 16 Kazoos
    uint256 public constant MAX_PREVIEWS = 164;

    uint256 public constant ENVIRONMENT_WEBSITE = 0;
    uint256 public constant ENVIRONMENT_OPENSEA = 1;
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity 0.8.0;

import "./KazooGlobals.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//the kazoo object its self! this is the data for our NFT
struct KazooObject {
    address payable owner;
    uint256 id; //id of mint
    uint256 masterNumber; //randomsation base number
    string kazoo; //the actual SVG code
    string uniqueName; //the unique name (does not have number appended)
    string[] names; //names array
    uint256[] sponsors; //holds the ids to the sponsored content of this kazoo
    uint256 sponsorNumber; //the number of sponsors for this kazoo
    uint256 sponsorEnvironment;
    bool sponsorsEnabled; //if you can advertise on the Kazoo
    bool isSpecial; //if it is special
    bytes[] backgroundColours; //pre calculated colours which are transformed into colour hex codes
    bytes borderColour; //the same as the above except its just one colour for the border
    bytes name; //the name with numbers appended
}

//this is an object to keep hold of all of our ad data
struct SponsorObject {
    uint256 id;
    address payable owner; //person who pays this NFT royalties
    uint256 royaltyTotal; //the total monies left to spend on sponsorships (will first be equal to SPONSOR_CREATION_PRICE)
    string sponsorName; //the name of this sponsorship content
    uint256 sponsorEnvironment;
    bytes sponsorContent; //the sponsored content to be put into the kazoo (SVG form)
}

contract KazooData is Ownable {
    //the kazoos them selves are stored here indexed by their kazooId
    mapping(uint256 => KazooObject) public kazoos;
    //active sponsored content;
    mapping(uint256 => SponsorObject) public activeSponsoredContent;
    string[] private possibleNames;
    //preview kazoos
    mapping(uint256 => KazooObject) previewKazoos;
    //this holds all of the possible names that we can get from the name generator
    address[] private previewRequests;
    uint256 private kazooPosition;
    uint256 private sponsorPosition;
    uint256 private securityPass;
    uint256 private shift;

    constructor(uint256 _shift, uint256 _pass) {
        shift = _shift;
        securityPass = _pass << _shift;
        previewRequests = new address[](KazooGlobals.MAX_PREVIEWS);
        kazooPosition = 0; //set kazoo id to 0
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
            "Bass",
            "Moist",
            "Meme",
            "Trap",
            "Lifted",
            "Super",
            "Mega",
            "Dumb",
            "Gangked",
            "Busted",
            "Weed",
            "Horny",
            "Radical",
            "DAO",
            "Hood",
            "Certified",
            "Erect",
            "Ke",
            "Kek",
            "El",
            "Woke",
            "Sick",
            "System",
            "Acid",
            "8-Bit",
            "16-Bit",
            "64",
            "Darkness"
        ];
    }

    function deleteOldRequests(address _addr, uint256 _previewCount) public {
        require(_addr != address(0), "invalid address given");

        //delete old
        for (uint256 i = 0; i < _previewCount; i++)
            if (previewRequests[i] == _addr) {
                delete previewKazoos[i];
                delete previewRequests[i];
            }
    }

    function toggleAdvertising(uint256 _kazooId, uint256 _pass) public {
        require(parsePass(_pass) == securityPass, "invalid pass");

        kazoos[_kazooId].sponsorsEnabled = !kazoos[_kazooId].sponsorsEnabled;
    }

    function set(uint256 _position, KazooObject memory _kaz) public {
        require(
            _position >= 0 && _position < kazooPosition,
            "invalid position"
        );
        require(
            kazoos[_position].owner == _msgSender(),
            "address does not have permission to write to Kazoo"
        );

        kazoos[_position] = _kaz;
    }

    function forced(uint256 _position, KazooObject memory _kaz)
        public
        onlyOwner
    {
        kazoos[_position] = _kaz;
    }

    function transfer(
        address _to,
        uint256 _kazooId,
        uint256 _pass
    ) public {
        require(parsePass(_pass) == securityPass, "invalid pass");
        require(kazoos[_kazooId].owner == _msgSender());
        kazoos[_kazooId].owner = payable(_to);
    }

    function setSponsor(uint256 _position, SponsorObject memory _obj) public {
        require(
            activeSponsoredContent[_position].owner == _msgSender(),
            "sender does not own this content"
        );
        activeSponsoredContent[_position] = _obj;
    }

    //sets the position of the kazoo cursor
    function setKazooPosition(uint256 _position) public onlyOwner {
        kazooPosition = _position;
    }

    //sets the position of the sponsored cursor
    function setSponsorPosition(uint256 _position) public onlyOwner {
        sponsorPosition = _position;
    }

    //removes a kazoo (for moderation)
    function deleteKazoo(uint256 _positon) public onlyOwner {
        delete kazoos[_positon];
    }

    //deletes a sponsored content
    function deleteSponsored(uint256 _positon) public onlyOwner {
        delete activeSponsoredContent[_positon];
    }

    function addSponsor(SponsorObject memory _obj, uint256 _pass)
        public
        returns (uint256 newPosition)
    {
        require(parsePass(_pass) == securityPass, "invalid pass");
        //the kazoo id must be what this next kazoo position must be
        require(_obj.id == sponsorPosition, "miscount");

        activeSponsoredContent[sponsorPosition] = _obj;
        newPosition = sponsorPosition++;
    }

    //Kazoo does the opposite
    function parsePass(uint256 _pass) private view returns (uint256) {
        return (_pass << shift);
    }

    //adds a new Kazoo to the internal count
    function addKazoo(KazooObject memory _kaz, uint256 _pass)
        public
        returns (uint256 newPosition)
    {
        require(parsePass(_pass) == securityPass, "invalid pass"); //the kazoo id must be what this next kazoo position must be
        require(_kaz.id == kazooPosition, "miscount");

        kazoos[kazooPosition] = _kaz;
        newPosition = kazooPosition++;
    }

    function toString(uint256 _i)
        public
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

    function get(uint256 _positon)
        public
        view
        returns (KazooObject memory _kaz)
    {
        _kaz = kazoos[_positon];
    }

    function getSponsor(uint256 _positon)
        public
        view
        returns (SponsorObject memory _obj)
    {
        _obj = activeSponsoredContent[_positon];
    }

    function getNameAndKazoo(uint256 _kazooId)
        public
        view
        returns (bytes memory name, string memory kazoo)
    {
        name = kazoos[_kazooId].name;
        kazoo = kazoos[_kazooId].kazoo;
    }

    //counts the times a name has previously been minted
    function countNames(string memory _name, uint256 _cKazooId)
        public
        view
        returns (uint256 number)
    {
        for (uint256 i = 0; i < _cKazooId; i++) {
            if (stringCompare(_name, kazoos[i].uniqueName)) {
                number++; //increment result
            }
        }
    }

    function sponsorKazoo(
        address _sender,
        uint256 _sponsorId,
        uint256 _kazooId
    ) public {
        SponsorObject memory _obj = getSponsor(_sponsorId);
        KazooObject memory _kaz = get(_kazooId);

        require(_sender == _obj.owner, "3");
        require(_obj.royaltyTotal - KazooGlobals.SPONSOR_PRICE < 0, "4");

        require(_kaz.sponsorsEnabled, "5");
        require(_kaz.sponsorNumber < KazooGlobals.MAX_SPONSORS, "6");

        _obj.royaltyTotal = _obj.royaltyTotal - KazooGlobals.SPONSOR_PRICE;

        _kaz.sponsors[_kaz.sponsorNumber++] = _sponsorId;

        set(_kazooId, _kaz);
        setSponsor(_sponsorId, _obj);
    }

    function getSponsorContent(
        uint256[] memory _sponsorIds,
        uint256 _cSponsoredContentId
    ) public view returns (string[] memory content) {
        content = new string[](KazooGlobals.MAX_SPONSORS);

        for (uint256 i = 0; i < KazooGlobals.MAX_SPONSORS; i++) {
            uint256 _index = _sponsorIds[i];

            if (_index == 0 && _index > _cSponsoredContentId) {
                content[i] = "";
                continue;
            }

            content[i] = string(getSponsor(_index).sponsorContent);
        }
    }

    function stringCompare(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        if (bytes(a).length != bytes(b).length) return false;
        else
            return
                keccak256(abi.encodePacked(a)) ==
                keccak256(abi.encodePacked(b));
    }

    function addPreviewKazoo(
        address _addr,
        KazooObject memory _kaz,
        uint256 _previewCount,
        uint256 _securityPass
    ) public {
        require(securityPass == parsePass(_securityPass), "invalid pass");

        previewRequests[_previewCount] = _addr;
        previewKazoos[_previewCount] = _kaz;
    }

    function getPreviewKazoo(
        address _addr,
        uint256 _val,
        uint256 _previewId,
        uint256 _previewCount,
        uint256 _newKazooId
    ) public returns (KazooObject memory _kaz) {
        require(_val == KazooGlobals.MINT_PRICE, "0"); //not paid the mint price
        require(previewRequests[_previewId] == _addr, "2"); //wrong address

        _kaz = previewKazoos[_previewId];
        _kaz.id = _newKazooId;

        deleteOldRequests(_addr, _previewCount);
    }

    function _getPreviewKazoo(uint256 _previewId)
        public
        view
        returns (KazooObject memory _kaz)
    {
        return previewKazoos[_previewId];
    }

    function getSponsorIds(uint256 _kazooId)
        public
        view
        returns (uint256[] memory sponsorIds)
    {
        KazooObject memory kaz = get(_kazooId);
        uint256 counter = 0;

        for (uint256 i = 0; i < KazooGlobals.MAX_SPONSORS; i++)
            if (kaz.sponsors[i] != 0) sponsorIds[counter++] = kaz.sponsors[i];
    }

    function setSponsorEnvironment(
        uint256 _sponsorId,
        uint256 _env,
        uint256 _pass
    ) public {
        require(parsePass(_pass) == securityPass, "invalid pass");
        require(
            activeSponsoredContent[_sponsorId].owner == _msgSender(),
            "sender does not own this content"
        );

        activeSponsoredContent[_sponsorId].sponsorEnvironment = _env;
    }

    function setKazooEnvironment(
        uint256 _kazooId,
        uint256 _env,
        uint256 _pass
    ) public {
        require(parsePass(_pass) == securityPass, "invalid pass");
        require(
            activeSponsoredContent[_kazooId].owner == _msgSender(),
            "sender does not own this content"
        );

        kazoos[_kazooId].sponsorEnvironment = _env;
    }

    function spinName(
        uint256 _times,
        uint256 _mNumber,
        uint256 _randomNameNumber,
        string[] memory _possibleNames,
        uint256 _maxNames
    ) public pure returns (string[] memory) {
        string[] memory _names = new string[](_maxNames);
        uint256 _randomNumber;

        for (uint256 i = 0; i <= _times; i++) {
            _randomNumber =
                (_mNumber + i * _randomNameNumber) %
                _possibleNames.length; //a number between one and the length of the possible name array
            _names[i] = _possibleNames[_randomNumber];
        }

        return _names;
    }

    //gets the latest
    function getKazoo(address payable _addr) public view returns (uint256) {
        for (uint256 i = kazooPosition; i >= 0; i--) {
            if (kazoos[i].owner == _addr) {
                return i;
            }
        }

        return KazooGlobals.MAX_KAZOOS + 1;
    }

    //gets the latest
    function getEarliestKazoo(address payable _addr)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < kazooPosition; i--) {
            if (kazoos[i].owner == _addr) {
                return i;
            }
        }

        return KazooGlobals.MAX_KAZOOS + 1;
    }

    //this is the method which names our kazoo! It can generate up to 3 names (+1 as Kazoo is also counted as a name) depending on if we stick with that or not.
    //names cannot be rerolled and are only done when the Kazoo is first minted.
    function nameKazoo(
        uint256 _kazooId,
        uint256 _cKazooId,
        uint256 _times,
        uint256 _randomNameNumber,
        KazooObject memory _kaz
    ) public view returns (KazooObject memory result) {
        require(_kazooId >= 0 && _kazooId <= _cKazooId, "1");

        //how many times we are going to roll the name using the very useful modulus
        _kaz.names = spinName(
            _times, //the amount of times to spin (1, 2 or 3)
            _kaz.masterNumber, //a bit of salt to make the randomnes spicy
            _randomNameNumber, //the random number to base the name off of,
            possibleNames, //the array of possible names to choose from
            KazooGlobals.MAX_NAMES //the max names there can be in total, actually used to initialise a fixed size array inside the method
        );
        _kaz.names[_times + 1] = "Kazoo"; //add kazoo at the end

        _kaz.name = ""; //reset the name to be blank and not the initial starting name
        for (uint256 i = 0; i <= _times + 1; i++) {
            //for as many times as we have including zero and +1 for the Kazoo
            if (i != _times + 1)
                _kaz.name = abi.encodePacked(_kaz.name, _kaz.names[i], " "); //add space as long as it isn't the last word
            else _kaz.name = abi.encodePacked(_kaz.name, _kaz.names[i]); //this will add Kazoo to the name
        }

        //set the unique name which is used to compare with other kazoos and check if the name we have generated is unique
        _kaz.uniqueName = string(_kaz.name);

        //set result
        result = _kaz;
    }

    function createKazooObject(
        address payable _owner,
        uint256 _kazooId,
        uint256 _randomNumber,
        bool _isSponsored,
        bool _isSpecial
    ) external pure returns (KazooObject memory kaz) {
        kaz = KazooObject(
            _owner,
            _kazooId,
            _randomNumber,
            "<svg></svg>",
            "Unnamed Kazoo",
            new string[](KazooGlobals.MAX_NAMES),
            new uint256[](KazooGlobals.MAX_SPONSORS),
            0,
            KazooGlobals.ENVIRONMENT_WEBSITE,
            _isSponsored,
            _isSpecial,
            new bytes[](13),
            "",
            ""
        );
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
pragma solidity 0.8.0;

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
        res = abi.encodePacked(res, "=");
      } else if (4 - (resRemainder % 4) == 2) {
        res = abi.encodePacked(res, "==");
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