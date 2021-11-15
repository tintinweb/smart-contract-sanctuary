//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Custom utils for Blob
import "./BlobGenerator.sol";

contract Blob is ERC721Enumerable, Ownable, BlobGenerator {
  // price per blob 0.08
  uint256 public constant NFT_PRICE = 80000000000000000;
  // discount price per. discount when minting >= 8;
  uint256 public constant NFT_DISCOUNT_PRICE = 50000000000000000;
  uint256 public constant NFT_DISCOUNT_THRESHOLD = 8;

  // max supply
  uint256 public constant MAX_SUPPLY = 8108;

  constructor(string memory name, string memory symbol)
    ERC721(name, symbol)
    BlobGenerator()
  {
    //owner gets first 10
    for (uint256 i = 0; i < 10; i++) {
      _safeMint(_msgSender(), totalSupply());
    }
  }

  //smart minting: "try" to mint up to a number requested then return change
  function mint(uint256 numberToMint) public payable {
    require(totalSupply() < MAX_SUPPLY, "Blobs are sold out!!");
    require(numberToMint > 0, "At least 1 should be minted");

    uint256 _msgValue = msg.value;
    uint256 _unitPrice = NFT_PRICE;

    //check if discount applies
    if (numberToMint >= NFT_DISCOUNT_THRESHOLD) {
      _unitPrice = NFT_DISCOUNT_PRICE;
    }

    require(_msgValue >= numberToMint * _unitPrice, "Requires more funding");

    uint256 numberMinted = 0;
    do {
      _safeMint(_msgSender(), totalSupply());
      numberMinted++;
    } while (numberMinted < numberToMint && totalSupply() < MAX_SUPPLY);

    uint256 payment = numberMinted * _unitPrice;
    uint256 remainder = _msgValue - payment;
    if (remainder > 0) {
      //return any change
      payable(_msgSender()).transfer(remainder);
    }
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(_msgSender()).transfer(balance);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return generateTokenURI(tokenId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Color.sol";
import "./Base64.sol";
import "./PRBMathSD59x18.sol";

contract BlobGenerator {
  constructor() {}

  using PRBMathSD59x18 for int256;

  struct Points {
    int256 x;
    int256 y;
  }

  function uintToStr(uint256 v) private pure returns (string memory) {
    uint256 maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint256 i = 0;

    if (v == 0) {
      return "0";
    }

    while (v != 0) {
      uint256 remainder = v % 10;
      v = v / 10;
      reversed[i % maxlength] = bytes1(uint8(48 + remainder));
      i++;
    }
    bytes memory s = new bytes(i);
    for (uint256 j = 1; j <= i % maxlength; j++) {
      s[j - 1] = reversed[i - j];
    }
    return string(s);
  }

  function intToStr(int256 v) private pure returns (string memory) {
    uint256 maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint256 i = 0;
    uint256 x;

    if (v == 0) {
      return "0";
    }

    if (v < 0) x = uint256(-v);
    else x = uint256(v);
    while (x != 0) {
      uint256 remainder = uint256(x % 10);
      x = x / 10;
      reversed[i % maxlength] = bytes1(uint8(48 + remainder));
      i++;
    }
    if (v < 0) reversed[(i++) % maxlength] = "-";
    bytes memory s = new bytes(i);
    for (uint256 j = 1; j <= i % maxlength; j++) {
      s[j - 1] = reversed[i - j];
    }
    return string(s);
  }

  function fromInt(int256 original) private pure returns (int256) {
    return PRBMathSD59x18.fromInt(original);
  }

  function fromUInt(uint256 original) private pure returns (int256) {
    return fromInt(int256(original));
  }

  function pi() internal pure returns (int256) {
    return PRBMathSD59x18.pi();
  }

  function generateZeroPad(uint256 size) private pure returns (string memory) {
    bytes memory padding = new bytes(size);

    for (uint256 i = 0; i < size; i++) {
      padding[i] = "0";
    }

    return string(padding);
  }

  function padFraction(int256 fraction) private pure returns (string memory) {
    bytes memory fractionString = bytes(abi.encodePacked(intToStr(fraction)));

    uint256 padSize = 18 - fractionString.length;
    string memory paddedFraction = concatToString(
      generateZeroPad(padSize),
      string(fractionString)
    );

    return paddedFraction;
  }

  function toPrecision(string memory fraction, uint256 precision)
    private
    pure
    returns (string memory)
  {
    bytes memory fractionBytes = bytes(fraction);
    bytes memory result = new bytes(precision);
    for (uint256 i = 0; i < precision; i++) {
      result[i] = fractionBytes[0];
    }

    return string(abi.encodePacked(".", string(result)));
  }

  function toDecimalString(int256 fixedInt, uint256 precision)
    private
    pure
    returns (string memory)
  {
    int256 fraction = fixedInt.frac();
    int256 exponent = fixedInt.toInt();
    string memory expStr = intToStr(exponent);
    if (fixedInt < 0) {
      fraction = fraction.mul(fromInt(-1));
      if (exponent == 0) {
        expStr = "-";
      }
    }

    string memory paddedFraction = padFraction(fraction);
    return
      string(abi.encodePacked(expStr, toPrecision(paddedFraction, precision)));
  }

  function toDecimalString(int256 exponent)
    private
    pure
    returns (string memory)
  {
    return toDecimalString(exponent, 3);
  }

  function getSeed(string memory feature, uint256 tokenId)
    private
    pure
    returns (uint256)
  {
    return uint256(keccak256(abi.encodePacked(feature, tokenId)));
  }

  function random(
    uint256 seed,
    uint256 start,
    uint256 end
  ) private pure returns (uint256) {
    return (seed % (end - start + 1)) + start;
  }

  function concatToString(string memory A, string memory B)
    private
    pure
    returns (string memory)
  {
    return string(abi.encodePacked(A, B));
  }

  function sin(int256 degrees) private pure returns (int256) {
    int256 x = degrees % fromInt(180);
    int256 dividend = fromInt(4).mul(x).mul(fromInt(180) - x);
    int256 divisor = fromInt(40500) - x.mul(fromInt(180) - x);

    int256 result = dividend.div(divisor);
    return degrees > fromInt(180) ? result.mul(fromInt(-1)) : result;
  }

  function cos(int256 degrees) private pure returns (int256) {
    return sin(degrees - fromInt(90));
  }

  function addToIArray(int256[] memory original, int256 newItem)
    private
    pure
    returns (int256[] memory)
  {
    int256[] memory newArray = new int256[](original.length + 1);

    for (uint256 i = 0; i < original.length; i++) {
      newArray[i] = original[i];
    }

    newArray[original.length] = newItem;

    return newArray;
  }

  //pull should be in 59.18 int
  function createPoints(
    string memory prefix,
    uint256 tokenId,
    uint256 numPoints,
    uint256 radius
  ) private pure returns (Points[] memory) {
    Points[] memory pointsArr = new Points[](numPoints);

    int256 angleStep = fromInt(360).div(fromUInt(numPoints));
    // console.log("rad step",toDecimalString(angleStep));
    for (uint256 i = 1; i <= numPoints; i++) {
      //random pull;
      int256 pull = fromUInt(
        random(
          getSeed(
            string(abi.encodePacked(prefix, "PULL", uintToStr(i))),
            tokenId
          ),
          5,
          15
        )
      ).div(fromInt(10));

      int256 x = fromInt(200) +
        cos(fromUInt(i).mul(angleStep)).mul(fromUInt(radius).mul(pull));
      int256 y = fromInt(200) +
        sin(fromUInt(i).mul(angleStep)).mul(fromUInt(radius).mul(pull));

      pointsArr[i - 1] = Points(x, y);
    }

    return pointsArr;
  }

  function loopPoints(Points[] memory pointsArr)
    private
    pure
    returns (Points[] memory)
  {
    Points memory lastPoint = pointsArr[pointsArr.length - 1];
    Points memory secondToLastPoint = pointsArr[pointsArr.length - 2];

    Points memory firstPoint = pointsArr[0];
    Points memory secondPoint = pointsArr[1];

    Points[] memory loopedPoints = new Points[](pointsArr.length + 4);

    // console.log("loopedPoints");
    loopedPoints[0] = secondToLastPoint;
    loopedPoints[1] = lastPoint;
    // console.log(toDecimalString(loopedPoints[0].x),toDecimalString(loopedPoints[0].y));
    // onsole.log(toDecimalString(loopedPoints[1].x),toDecimalString(loopedPoints[1].y));

    //TODO missing points
    for (uint256 i = 0; i < pointsArr.length; i++) {
      loopedPoints[i + 2] = pointsArr[i];
      // console.log(toDecimalString(loopedPoints[i+2].x),toDecimalString(loopedPoints[i+2].y));
    }

    loopedPoints[loopedPoints.length - 2] = firstPoint;
    loopedPoints[loopedPoints.length - 1] = secondPoint;
    // console.log(toDecimalString(loopedPoints[loopedPoints.length - 2].x),toDecimalString(loopedPoints[loopedPoints.length - 2].y));
    // console.log(toDecimalString(loopedPoints[loopedPoints.length - 1].x),toDecimalString(loopedPoints[loopedPoints.length - 1].y));

    return loopedPoints;
  }

  function concatStringArray(string[] memory stringArr)
    private
    pure
    returns (string memory)
  {
    string memory result = stringArr[0];

    for (uint256 i = 1; i < stringArr.length; i++) {
      result = string(abi.encodePacked(result, stringArr[i]));
    }

    return result;
  }

  function generateCPath(
    Points[] memory pointsArr,
    uint256 startIteration,
    uint256 maxIteration,
    uint256 tension
  ) private pure returns (string memory) {
    Points[] memory cPathPoints = new Points[](2);
    string[] memory pathParts = new string[](12);
    string memory cPathString = "";

    for (uint256 i = startIteration; i < maxIteration; i++) {
      //TODO BUGGED
      Points memory p0 = i > 0 ? pointsArr[i - startIteration] : pointsArr[0];
      Points memory p1 = pointsArr[i];
      Points memory p2 = pointsArr[i + 1];
      Points memory p3 = i != maxIteration ? pointsArr[i + 2] : p2;

      cPathPoints[0].x =
        p1.x +
        (p2.x - p0.x).div(fromInt(6)).mul(fromUInt(tension));
      cPathPoints[0].y =
        p1.y +
        (p2.y - p0.y).div(fromInt(6)).mul(fromUInt(tension));

      cPathPoints[1].x =
        p2.x -
        (p3.x - p1.x).div(fromInt(6)).mul(fromUInt(tension));
      cPathPoints[1].y =
        p2.y -
        (p3.y - p1.y).div(fromInt(6)).mul(fromUInt(tension));

      pathParts[0] = "C";
      pathParts[1] = toDecimalString(cPathPoints[0].x);
      pathParts[2] = ",";
      pathParts[3] = toDecimalString(cPathPoints[0].y);
      pathParts[4] = ",";
      pathParts[5] = toDecimalString(cPathPoints[1].x);
      pathParts[6] = ",";
      pathParts[7] = toDecimalString(cPathPoints[1].y);
      pathParts[8] = ",";
      pathParts[9] = toDecimalString(p2.x);
      pathParts[10] = ",";
      pathParts[11] = toDecimalString(p2.y);
      cPathString = concatToString(cPathString, concatStringArray(pathParts));
    }

    return cPathString;
  }

  function closedSpline(Points[] memory pointsArr, uint256 tension)
    private
    pure
    returns (string memory)
  {
    Points[] memory loopedPoints = loopPoints(pointsArr);

    //start with M path
    string memory path = string(
      abi.encodePacked(
        "M",
        toDecimalString(loopedPoints[1].x),
        ",",
        toDecimalString(loopedPoints[1].y)
      )
    );

    //issueswith pointsArr arithmetic
    path = concatToString(
      path,
      generateCPath(loopedPoints, 1, loopedPoints.length - 2, tension)
    );
    return path;
  }

  function generateFilter(string memory spread)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '<filter id="lightSource">',
          '<feTurbulence type="turbulence" baseFrequency="0.05" numOctaves="10" result="turbulence"/>',
          '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="',
          spread,
          '" result="turbResult" xChannelSelector="R" yChannelSelector="G"/>',
          "</filter>"
        )
      );
  }

  function generateStopColor(string memory color1, string memory color2)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '<stop offset="0%" stop-opacity="1" stop-color="',
          color1,
          '" />',
          '<stop offset="100%" stop-opacity="1" stop-color="',
          color2,
          '" />'
        )
      );
  }

  function generateGradients(
    string memory speed,
    string memory color1,
    string memory color2,
    string memory color3,
    string memory color4
  ) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<linearGradient id="grad0">'
          '<animateTransform attributeName="gradientTransform" attributeType="XML" type="rotate" from="0 0.5 0.5" to="-360 0.5 0.5" dur="',
          speed,
          's" repeatCount="indefinite"/>',
          generateStopColor(color1, color2),
          "</linearGradient>",
          '<linearGradient id="grad1">',
          '<animateTransform attributeName="gradientTransform" attributeType="XML" type="rotate" from="0 0.5 0.5" to="360 0.5 0.5" dur="',
          speed,
          's" repeatCount="indefinite"/>',
          generateStopColor(color3, color4),
          "</linearGradient>"
        )
      );
  }

  function generateBackground() private pure returns (string memory) {
    return '<rect width="400" height="400" fill="url(#grad0)"/>';
  }

  function generatePath(
    string memory path,
    string memory objectSpeed,
    string memory objectRotation
  ) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "<g>",
          '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 200 200" to="360 200 200" dur="',
          objectRotation,
          's" repeatCount="indefinite"/>',
          '<path id="path" fill="url(#grad1)" filter="url(#lightSource)">',
          '<animate repeatCount="indefinite" attributeName="d" values="',
          path,
          '" dur="',
          objectSpeed,
          's"/>',
          "</path></g>"
        )
      );
  }

  function generateSVG(string memory dPath, Features memory features)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '<svg xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="0 0 400 400">',
          generateFilter(features.colorFeatures[0]),
          generateGradients(
            features.colorFeatures[1],
            features.colors[0],
            features.colors[1],
            features.colors[2],
            features.colors[3]
          ),
          generateBackground(),
          generatePath(
            dPath,
            features.colorFeatures[2],
            features.colorFeatures[3]
          ),
          "</svg>"
        )
      );
  }

  function generateColors(uint256 tokenId)
    private
    pure
    returns (string[] memory)
  {
    string[] memory colors = new string[](4);
    colors[0] = Color.generateColorHexCode("COLOR1", tokenId);
    colors[1] = Color.generateColorHexCode("COLOR2", tokenId);
    colors[2] = Color.generateColorHexCode("COLOR3", tokenId);
    colors[3] = Color.generateColorHexCode("COLOR4", tokenId);
    return colors;
  }

  function generateColorFeatures(uint256 tokenId)
    private
    pure
    returns (string[] memory)
  {
    string[] memory colorFeatures = new string[](4);

    uint256 speed2 = random(getSeed("SPEED2", tokenId), 1, 20);
    colorFeatures[0] = uintToStr(random(getSeed("SPREAD", tokenId), 0, 20));
    colorFeatures[1] = uintToStr(random(getSeed("SPEED1", tokenId), 5, 20));
    colorFeatures[2] = uintToStr(speed2);
    colorFeatures[3] = uintToStr(speed2 * 5);

    return colorFeatures;
  }

  function generateDPath(
    uint256 tokenId,
    uint256 numPoints,
    uint256 numFrames,
    uint256 radius
  ) private pure returns (string memory) {
    string memory firstFrame;
    string memory dPath;

    for (uint256 i = 0; i < numFrames; i++) {
      Points[] memory pointsArr = createPoints(
        uintToStr(i),
        tokenId,
        numPoints,
        radius
      );
      dPath = concatToString(dPath, closedSpline(pointsArr, 1));
      if (i == 0) firstFrame = dPath;
      dPath = concatToString(dPath, ";");
    }
    //add back first frame
    dPath = concatToString(dPath, firstFrame);
    return dPath;
  }

  function generateBlobFeatures(uint256 tokenId)
    private
    pure
    returns (uint256[] memory)
  {
    uint256[] memory blobFeatures = new uint256[](3);

    uint256 maxPoints = 11;
    uint256 minPoints = 3;
    uint256 numPoints = random(
      getSeed("NUMPOINTS", tokenId),
      minPoints,
      maxPoints
    );
    uint256 numFrames = 5;
    uint256 radius = random(getSeed("RADIUS", tokenId), 25, 100);

    blobFeatures[0] = numPoints;
    blobFeatures[1] = numFrames;
    blobFeatures[2] = radius;
    return blobFeatures;
  }

  struct Features {
    string[] colors;
    string[] colorFeatures;
    uint256[] blobFeatures;
  }

  struct JSONMeta {
    string texture;
    string energy;
    string blob_color_1;
    string blob_color_2;
    string back_color_1;
    string back_color_2;
    string close;
  }

  function generateColorFeatures(Features memory features)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"Blob color #1","value":"',
          features.colors[2],
          '"},',
          '{"trait_type":"Blob color #2","value":"',
          features.colors[3],
          '"},',
          '{"trait_type":"Background color #1","value":"',
          features.colors[0],
          '"},',
          '{"trait_type":"Background color #2","value":"',
          features.colors[1]
        )
      );
  }

  function generateColorAttributes(Features memory features)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"Texture","value":',
          features.colorFeatures[0],
          "},",
          '{"trait_type":"Energy","value":',
          features.colorFeatures[2],
          "},",
          generateColorFeatures(features),
          '"}'
        )
      );
  }

  function generateAttributes(Features memory features)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '"attributes": [',
          '{"trait_type":"Entropy","value":',
          uintToStr(features.blobFeatures[0]),
          "},",
          '{"trait_type":"Girth","value":',
          uintToStr(features.blobFeatures[2]),
          "},",
          generateColorAttributes(features),
          "]"
        )
      );
  }

  function generateJSONMeta(
    Features memory features,
    string memory svgData,
    uint256 tokenId
  ) internal pure returns (string memory) {
    string memory jsonMeta = string(
      abi.encodePacked(
        '{"name": "BLOB #',
        uintToStr(tokenId),
        '",',
        '"description": "8108 (BLOB) is the first on-chain generative animated NFT",',
        generateAttributes(features),
        ",",
        '"image": "',
        svgData,
        '"',
        "}"
      )
    );

    return jsonMeta;
  }

  function generateTokenURI(uint256 tokenId)
    internal
    pure
    returns (string memory)
  {
    Features memory features;
    features.colors = generateColors(tokenId);
    features.colorFeatures = generateColorFeatures(tokenId);
    features.blobFeatures = generateBlobFeatures(tokenId);

    //59.18 int
    string memory dPath = generateDPath(
      tokenId,
      features.blobFeatures[0],
      features.blobFeatures[1],
      features.blobFeatures[2]
    );

    string memory svgData = concatToString(
      "data:image/svg+xml;base64,",
      Base64.encode(bytes(generateSVG(dPath, features)))
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(bytes(generateJSONMeta(features, svgData, tokenId)))
        )
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Color {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  function generateColorValue(string memory prefix, uint256 tokenId)
    private
    pure
    returns (uint256)
  {
    return uint256(keccak256(abi.encodePacked(prefix, tokenId))) % 4096;
  }

  function getColorHexCode(uint256 value)
    internal
    pure
    returns (string memory)
  {
    uint16 red = uint16((value >> 8) & 0xf);
    uint16 green = uint16((value >> 4) & 0xf);
    uint16 blue = uint16(value & 0xf);

    bytes memory buffer = new bytes(7);

    buffer[0] = "#";
    buffer[1] = _HEX_SYMBOLS[red];
    buffer[2] = _HEX_SYMBOLS[red];
    buffer[3] = _HEX_SYMBOLS[green];
    buffer[4] = _HEX_SYMBOLS[green];
    buffer[5] = _HEX_SYMBOLS[blue];
    buffer[6] = _HEX_SYMBOLS[blue];

    return string(buffer);
  }

  function generateColorHexCode(string memory prefix, uint256 tokenId)
    internal
    pure
    returns (string memory)
  {
    uint256 colorValue = generateColorValue(prefix, tokenId);
    return getColorHexCode(colorValue);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
  string internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
  /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
  int256 internal constant LOG2_E = 1442695040888963407;

  /// @dev Half the SCALE number.
  int256 internal constant HALF_SCALE = 5e17;

  /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
  int256 internal constant MAX_SD59x18 =
    57896044618658097711785492504343953926634992332820282019728792003956564819967;

  /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
  int256 internal constant MAX_WHOLE_SD59x18 =
    57896044618658097711785492504343953926634992332820282019728000000000000000000;

  /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
  int256 internal constant MIN_SD59x18 =
    -57896044618658097711785492504343953926634992332820282019728792003956564819968;

  /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
  int256 internal constant MIN_WHOLE_SD59x18 =
    -57896044618658097711785492504343953926634992332820282019728000000000000000000;

  /// @dev How many trailing decimals can be represented.
  int256 internal constant SCALE = 1e18;

  /// INTERNAL FUNCTIONS ///

  /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
  ///
  /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
  ///
  /// Requirements:
  /// - All from "PRBMath.mulDiv".
  /// - None of the inputs can be MIN_SD59x18.
  /// - The denominator cannot be zero.
  /// - The result must fit within int256.
  ///
  /// Caveats:
  /// - All from "PRBMath.mulDiv".
  ///
  /// @param x The numerator as a signed 59.18-decimal fixed-point number.
  /// @param y The denominator as a signed 59.18-decimal fixed-point number.
  /// @param result The quotient as a signed 59.18-decimal fixed-point number.
  function div(int256 x, int256 y) internal pure returns (int256 result) {
    require(
      !(x == MIN_SD59x18 || y == MIN_SD59x18),
      "PRBMathSD59x18__DivInputTooSmall"
    );

    // Get hold of the absolute values of x and y.
    uint256 ax;
    uint256 ay;
    unchecked {
      ax = x < 0 ? uint256(-x) : uint256(x);
      ay = y < 0 ? uint256(-y) : uint256(y);
    }

    // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
    uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
    require(!(rAbs > uint256(MAX_SD59x18)), "PRBMathSD59x18__DivOverflow");

    // Get the signs of x and y.
    uint256 sx;
    uint256 sy;
    assembly {
      sx := sgt(x, sub(0, 1))
      sy := sgt(y, sub(0, 1))
    }

    // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
    // should be positive. Otherwise, it should be negative.
    result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
  }

  /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
  /// of the radix point for negative numbers.
  /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
  /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
  /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
  function frac(int256 x) internal pure returns (int256 result) {
    unchecked {
      result = x % SCALE;
    }
  }

  /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
  ///
  /// @dev Requirements:
  /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
  /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
  ///
  /// @param x The basic integer to convert.
  /// @param result The same number in signed 59.18-decimal fixed-point representation.
  function fromInt(int256 x) internal pure returns (int256 result) {
    unchecked {
      require(!(x < MIN_SD59x18 / SCALE), "PRBMathSD59x18__FromIntUnderflow");
      require(!(x > MAX_SD59x18 / SCALE), "PRBMathSD59x18__FromIntOverflow");
      result = x * SCALE;
    }
  }

  /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
  /// fixed-point number.
  ///
  /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
  /// always 1e18.
  ///
  /// Requirements:
  /// - All from "PRBMath.mulDivFixedPoint".
  /// - None of the inputs can be MIN_SD59x18
  /// - The result must fit within MAX_SD59x18.
  ///
  /// Caveats:
  /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
  ///
  /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
  /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
  /// @return result The product as a signed 59.18-decimal fixed-point number.
  function mul(int256 x, int256 y) internal pure returns (int256 result) {
    require(
      !(x == MIN_SD59x18 || y == MIN_SD59x18),
      "PRBMathSD59x18__MulInputTooSmall"
    );

    unchecked {
      uint256 ax;
      uint256 ay;
      ax = x < 0 ? uint256(-x) : uint256(x);
      ay = y < 0 ? uint256(-y) : uint256(y);

      uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
      require(!(rAbs > uint256(MAX_SD59x18)), "PRBMathSD59x18__MulOverflow");

      uint256 sx;
      uint256 sy;
      assembly {
        sx := sgt(x, sub(0, 1))
        sy := sgt(y, sub(0, 1))
      }
      result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }
  }

  /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
  function pi() internal pure returns (int256 result) {
    result = 3141592653589793238;
  }

  /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
  function scale() internal pure returns (int256 result) {
    result = SCALE;
  }

  /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
  /// @param x The signed 59.18-decimal fixed-point number to convert.
  /// @return result The same number in basic integer form.
  function toInt(int256 x) internal pure returns (int256 result) {
    unchecked {
      result = x / SCALE;
    }
  }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explictly mentioned in the NatSpec documentation.
library PRBMath {
  /// STRUCTS ///

  struct SD59x18 {
    int256 value;
  }

  struct UD60x18 {
    uint256 value;
  }

  /// STORAGE ///

  /// @dev How many trailing decimals can be represented.
  uint256 internal constant SCALE = 1e18;

  /// @dev Largest power of two divisor of SCALE.
  uint256 internal constant SCALE_LPOTD = 262144;

  /// @dev SCALE inverted mod 2^256.
  uint256 internal constant SCALE_INVERSE =
    78156646155174841979727994598816262306175212592076161876661508869554232690281;

  /// FUNCTIONS ///

  /// @notice Calculates floor(x*y÷denominator) with full precision.
  ///
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
  ///
  /// Requirements:
  /// - The denominator cannot be zero.
  /// - The result must fit within uint256.
  ///
  /// Caveats:
  /// - This function does not work with fixed-point numbers.
  ///
  /// @param x The multiplicand as an uint256.
  /// @param y The multiplier as an uint256.
  /// @param denominator The divisor as an uint256.
  /// @return result The result as an uint256.
  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(x, y, not(0))
      prod0 := mul(x, y)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
      unchecked {
        result = prod0 / denominator;
      }
      return result;
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    require(!(prod1 >= denominator), "PRBMath__MulDivOverflow");

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly {
      // Compute remainder using mulmod.
      remainder := mulmod(x, y, denominator)

      // Subtract 256 bit number from 512 bit number.
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
    // See https://cs.stackexchange.com/q/138556/92363.
    unchecked {
      // Does not overflow because the denominator cannot be zero at this stage in the function.
      uint256 lpotdod = denominator & (~denominator + 1);
      assembly {
        // Divide denominator by lpotdod.
        denominator := div(denominator, lpotdod)

        // Divide [prod1 prod0] by lpotdod.
        prod0 := div(prod0, lpotdod)

        // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
        lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
      }

      // Shift in bits from prod1 into prod0.
      prod0 |= prod1 * lpotdod;

      // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
      // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
      // four bits. That is, denominator * inv = 1 mod 2^4.
      uint256 inverse = (3 * denominator) ^ 2;

      // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
      // in modular arithmetic, doubling the correct bits in each step.
      inverse *= 2 - denominator * inverse; // inverse mod 2^8
      inverse *= 2 - denominator * inverse; // inverse mod 2^16
      inverse *= 2 - denominator * inverse; // inverse mod 2^32
      inverse *= 2 - denominator * inverse; // inverse mod 2^64
      inverse *= 2 - denominator * inverse; // inverse mod 2^128
      inverse *= 2 - denominator * inverse; // inverse mod 2^256

      // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
      // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
      // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inverse;
      return result;
    }
  }

  /// @notice Calculates floor(x*y÷1e18) with full precision.
  ///
  /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
  /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
  /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
  ///
  /// Requirements:
  /// - The result must fit within uint256.
  ///
  /// Caveats:
  /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
  /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
  ///     1. x * y = type(uint256).max * SCALE
  ///     2. (x * y) % SCALE >= SCALE / 2
  ///
  /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
  /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
  /// @return result The result as an unsigned 60.18-decimal fixed-point number.
  function mulDivFixedPoint(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 result)
  {
    uint256 prod0;
    uint256 prod1;
    assembly {
      let mm := mulmod(x, y, not(0))
      prod0 := mul(x, y)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    require(!(prod1 >= SCALE), "PRBMath__MulDivFixedPointOverflow");

    uint256 remainder;
    uint256 roundUpUnit;
    assembly {
      remainder := mulmod(x, y, SCALE)
      roundUpUnit := gt(remainder, 499999999999999999)
    }

    if (prod1 == 0) {
      unchecked {
        result = (prod0 / SCALE) + roundUpUnit;
        return result;
      }
    }

    assembly {
      result := add(
        mul(
          or(
            div(sub(prod0, remainder), SCALE_LPOTD),
            mul(
              sub(prod1, gt(remainder, prod0)),
              add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1)
            )
          ),
          SCALE_INVERSE
        ),
        roundUpUnit
      )
    }
  }
}

