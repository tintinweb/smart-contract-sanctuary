// SPDX-License-Identifier: MIT


/*
Contract by steviep.eth
*/

import "./Dependencies.sol";

pragma solidity ^0.8.2;


contract AnimatedOctoGarden is ERC721, ERC721Burnable, Ownable {
  using Strings for uint256;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  uint private _tokenIdCounter;

  bool public useURIPointer;

  string public baseUrl;
  string public baseUrlExtension;
  string public baseExternalUrl;
  string public imgExtension;
  string public animationExtension;
  string public projectDescription;
  string public metadataExtension;
  string public baseNamePrefix;
  string public baseNameSuffix;
  string public license;
  address public mintingAddress;

  address public royaltyBenificiary;
  uint public royaltyBasisPoints;

  mapping(uint256 => string) public imageUrls;
  mapping(uint256 => string) public animationUrls;
  mapping(uint256 => string) public tokenIdToMetadata;

  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);

  constructor() ERC721('AnimatedOctoGarden', 'OCTO', msg.sender) {
    useURIPointer = false;
    baseNamePrefix = 'Animated Octo Garden #';
    baseNameSuffix = '';
    baseUrlExtension = '';
    baseUrl = 'https://';
    baseExternalUrl = 'https://www.richlord.com/octo-garden#';
    imgExtension = '.png';
    animationExtension = '.mp4';
    projectDescription = 'Animated and raytraced versions of the original artblocks.io Octo Gardens.';
    license = 'CC BY-NC 4.0';

    imageUrls[0] = 'ipfs://bafybeibwnsyepw5kpds5ve3vc6zg7camfbdlrcfzyizay4j4ehq5hkk4hm/octo_';
    imageUrls[1] = 'ipfs://bafybeia6zpkyp4q2fff6quraohowoxboz3nafcmogcxkzc37sbzywzgili/octo_';
    imageUrls[2] = 'ipfs://bafybeia55z6cs3tchwhjvxmanr3c34mszwzt2yyi3tblxcc5s3622nlrme/octo_';
    imageUrls[3] = 'ipfs://bafybeih3fkeh7nsy3r2irxyrgq355utwfta5cnbszexocfx7bs3lrwuxgm/octo_';

    animationUrls[0] = 'ipfs://bafybeieinfh4bfkywv72tx4zbit22n7nx3omamqyifzcwmygcix6tkm7eu/octo_';
    animationUrls[1] = 'ipfs://bafybeiclqn7okdnqg7rvys5pnzt65eloyiux4ymjzernn3qjwyt6t5endy/octo_';
    animationUrls[2] = 'ipfs://bafybeic3denj5wj5r74rluojhuej2j7rkxucgeje2od3fhu2r3mvbyonb4/octo_';

    royaltyBasisPoints = 750;
    royaltyBenificiary = msg.sender;

    _tokenIdCounter = 0;
  }

  function totalSupply() public view virtual returns (uint256) {
    return _tokenIdCounter;
  }

  function batchMint(address[] memory addresses) public onlyOwner {
    require(_tokenIdCounter + addresses.length <= 333, 'Batch mint would push token count above 333');

    for (uint i = 0; i < addresses.length; i++) {
      _mint(addresses[i], _tokenIdCounter);
      _tokenIdCounter++;
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory tokenString = tokenId.toString();

    if (useURIPointer) {
      return string(abi.encodePacked(baseUrl, tokenString, baseUrlExtension));
    }
    string memory animationString = string(abi.encodePacked(getAnimationUrl(tokenId), tokenString, animationExtension));
    string memory imgString = string(abi.encodePacked(getImageUrl(tokenId), tokenString, imgExtension));

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "', baseNamePrefix, tokenString, baseNameSuffix,
            '", "description": "', projectDescription,
            '", "image": "', imgString,
            '", "animation_url": "', animationString,
            '", "external_url": "', baseExternalUrl, tokenString,
            '", "license": "', license,
            '", "tokenId": "', tokenString,
            '"}'
          )
        )
      )
    );
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function getImageUrl(uint tokenId) private view returns (string memory) {
    uint bucketNumber;
    if (tokenId < 111) {
      bucketNumber = 0;
    } else if (tokenId < 162) {
      bucketNumber = 1;
    } else if (tokenId < 222) {
      bucketNumber = 2;
    } else {
      bucketNumber = 3;
    }

    return imageUrls[bucketNumber];
  }

  function getAnimationUrl(uint tokenId) private view returns (string memory) {
    uint bucketNumber;
    if (tokenId < 111) {
      bucketNumber = 0;
    } else if (tokenId < 222) {
      bucketNumber = 1;
    } else {
      bucketNumber = 2;
    }

    return animationUrls[bucketNumber];
  }

  function updateImageUrl(uint256 bucketNumber, string memory _imageUrl) public onlyOwner {
    imageUrls[bucketNumber] = _imageUrl;
  }

  function updateAnimationUrl(uint256 bucketNumber, string memory _animationUrl) public onlyOwner {
    animationUrls[bucketNumber] = _animationUrl;
  }


  function flipUseURIPointer() public onlyOwner {
    useURIPointer = !useURIPointer;
  }

  function updateBaseUrl(string memory _baseUrl, string memory _baseUrlExtension) public onlyOwner {
    baseUrl = _baseUrl;
    baseUrlExtension = _baseUrlExtension;
  }

  function updateProjectDescription(
    string memory _projectDescription
  ) public onlyOwner {
    projectDescription = _projectDescription;
  }

  function updateMetadataParams(
    string memory _baseNamePrefix,
    string memory _baseNameSuffix,
    string memory _imgExtension,
    string memory _animationExtension,
    string memory _baseExternalUrl,
    string memory _license
  ) public onlyOwner {
    baseNamePrefix = _baseNamePrefix;
    baseNameSuffix = _baseNameSuffix;
    imgExtension = _imgExtension;
    animationExtension = _animationExtension;
    baseExternalUrl = _baseExternalUrl;
    license = _license;
  }

  function emitProjectEvent(string memory _eventType, string memory _content) public onlyOwner {
    emit ProjectEvent(_msgSender(), _eventType, _content);
  }

  function emitTokenEvent(uint256 tokenId, string memory _eventType, string memory _content) public {
    require(
      owner() == _msgSender() || ERC721.ownerOf(tokenId) == _msgSender(),
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(_msgSender(), tokenId, _eventType, _content);
  }

  function updatRoyaltyInfo(
    address _royaltyBenificiary,
    uint256 _royaltyBasisPoints
  ) public onlyOwner {
    royaltyBenificiary = _royaltyBenificiary;
    royaltyBasisPoints = _royaltyBasisPoints;
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
    return (royaltyBenificiary, _salePrice * royaltyBasisPoints / 10000);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
  }
}