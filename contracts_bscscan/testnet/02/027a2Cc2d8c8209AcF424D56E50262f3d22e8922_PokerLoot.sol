// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./IERC721.sol";
import "./strings.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ERC721.sol";
import "./IERC20.sol";



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


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



/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract PokerLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
   uint256 _totalSupply = 8888;
   string _desc = 'PokerLoot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.';
   uint256 minted = 0;
   mapping(uint256=>uint16[5]) public minted_pokers;
   mapping(uint256=>string) public minted_poker_images;
   
   event MintNum(uint256 tokenId,uint16[5] cards);
 
   string header = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400"> <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%"> <stop offset="0%" style="stop-color:#d16ba5;" /> <stop offset="10%" style="stop-color:#c777b9;" /> <stop offset="20%" style="stop-color:#ba83ca;" /> <stop offset="30%" style="stop-color:#aa8fd8;" /> <stop offset="40%" style="stop-color: #9a9ae1;" /> <stop offset="50%" style="stop-color:#8aa7ec;" /> <stop offset="60%" style="stop-color:#79b3f4;" /> <stop offset="70%" style="stop-color:#69bff8;" /> <stop offset="80%" style="stop-color: #52cffe;" /> <stop offset="90%" style="stop-color:#41dfff;" /> <stop offset="100%" style="stop-color:#46eefa;" /> <stop offset="100%" style="stop-color:#5ffbf1;" /> </linearGradient> <g transform="translate(10,10) scale(0.04)" id="heart"> <path d="M321.86716464 128.16887414c-0.7724762 2.08568573-1.46770478 4.86660004-3.78513336 4.86660003-2.24018097 0-3.01265717-2.7809143-3.70788575-4.86660003-22.55630493-76.93862915-84.74063873-110.85033417-155.19046783-110.85033417-85.43586731 0-156.65817261 72.76725769-156.65817261 167.00935363 0 101.88961029 89.22100068 176.04732514 145.38002014 225.94928742C216.11517337 470.60757195 288.80518344 553.0307821 316.53707889 594.59000146c0.7724762 1.39045716 2.24018097 1.39045716 3.01265716 0 27.73189545-41.55921936 100.42190552-124.05967713 168.63155365-184.31282043 56.23626709-49.90196228 145.38002014-123.36444855 145.38002014-225.94928743 0-94.24209594-71.22230529-167.00935364-156.6581726-167.00935364-70.37258149 0-133.32939148 33.91170503-155.0359726 110.85033417z" fill="#d81e06"></path> </g> <g transform="translate(10,10) scale(0.03)" id="block"> <path d="M512 0c98.304 183.296 294.912 416.768 393.216 512-98.304 95.232-293.888 328.704-393.216 512-98.304-183.296-294.912-416.768-393.216-512C217.088 416.768 413.696 183.296 512 0z m0 0" fill="#d81e06"></path> </g> <g transform="translate(10,10) scale(0.03)" id="flower"> <path d="M450.56 758.784C407.552 827.392 328.704 880.64 235.52 880.64c-132.096 1.024-235.52-98.304-235.52-238.592 0-134.144 101.376-239.616 237.568-239.616 34.816 0 73.728 13.312 101.376 26.624 0 0 6.144 2.048 8.192-2.048 3.072-6.144-3.072-10.24-3.072-10.24-40.96-38.912-72.704-98.304-72.704-168.96C270.336 113.664 376.832 3.072 512 3.072 646.144 3.072 753.664 112.64 753.664 245.76c0 70.656-31.744 131.072-72.704 169.984 0 0-7.168 5.12-3.072 10.24 2.048 7.168 8.192 4.096 8.192 4.096 26.624-14.336 66.56-26.624 99.328-26.624 139.264 0 238.592 105.472 238.592 239.616 0 139.264-103.424 238.592-235.52 238.592-88.064 0-166.912-47.104-215.04-121.856-10.24-16.384-9.216-25.6-18.432-25.6-8.192 0-7.168 18.432-7.168 21.504 8.192 121.856 50.176 186.368 116.736 241.664 14.336 11.264 5.12 23.552 0 23.552H361.472c-6.144 0-14.336-11.264-1.024-23.552 65.536-55.296 109.568-119.808 116.736-241.664 0-2.048 1.024-21.504-7.168-21.504-9.216-1.024-8.192 8.192-19.456 24.576z m0 0" fill="black"> </path> </g> <g transform="translate(10,10) scale(0.03)" id="peach"> <path d="M327.587432 220.772172c57.982576-50.237171 123.532501-92.906993 194.793498-129.862673 160.681586 89.019453 382.049323 240.745063 385.765971 492.712725 1.645476 111.480001-59.566654 208.369701-183.334515 210.07146-14.004969 0-28.009937 0-42.013883 0-50.021254-3.453658-85.384669-21.560038-118.404714-42.014906 14.150278 67.332525 35.998889 126.966717 53.473889 190.973496 0 2.548032 0 5.091972 0 7.637957-63.657832 0-127.317711 0-190.974519 0 18.332531-65.695235 36.681434-131.376143 57.291844-194.791451-31.18014 5.765307-69.307506 37.619806-118.404714 38.194904-15.276938 0-30.5549 0-45.833885 0-113.203248-7.743358-169.133072-72.768327-179.515536-183.335539 0-14.002922 0-28.010961 0-42.014906 10.980076-134.159536 72.189136-218.090087 137.500631-297.919227C296.079834 255.470439 312.631812 238.918461 327.587432 220.772172z" fill="black"></path> <path d="M381.602649 791.933597c-12.081153 6.010901-71.143317 4.427846-82.886779-2.221598C326.346161 790.45185 353.975429 791.192723 381.602649 791.933597z" fill="black"></path> <path d="M277.933545 271.447319c14.95562-18.145266 31.507598-34.697243 49.652863-49.65184C312.631812 239.941767 296.079834 256.493745 277.933545 271.447319z" fill="black"></path> <path d="M744.842581 791.100626c-11.958356 6.251378-71.039963 5.854335-82.913385-0.558725C689.567673 790.729166 717.20615 790.915407 744.842581 791.100626z" fill="black"></path> </g> </defs> <style> .txt { font-size: 40; height: 20; line-height: 20; font-weight: bold; font-family: serif; } .red { fill: rgb(199, 7, 7); } .black { fill: rgb(0, 0, 0); } .card { fill: white; stroke-width: 4; stroke: rgb(0, 0, 0); opacity: 0.95; } </style> <rect x="0" y="0" width="400" height="400" fill="url(#grad1)"></rect>';   
   
   function gen(uint256 tokenId) private view returns (uint16[5] memory) {
        uint16[51] memory arr = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,
        27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,4647,48,49,50,51];
       
        uint16 last = 0;
        for(uint8 i = 0; i < 5; i++) {
            uint8 len = 51 - i;
            uint256 rand = random(string(abi.encodePacked(toString(tokenId),toString(block.timestamp),toString(uint256(last)))));
            uint8 index = uint8(rand % len) + i;
            // swap 
            uint16 value = arr[index];
            arr[index] = arr[i];
            arr[i] = value;
            last = value;
        }
        // emit MintNum(tokenId, [arr[0],arr[1],arr[2],arr[3],arr[4]]);
        uint16[5] memory result = [arr[0],arr[1],arr[2],arr[3],arr[4]];
        // sort cards by exact value
        for(uint8 i = 0; i < 5; i++) {
            for(uint8 j = i; j <5; j++) {
                if((result[i]%13) > (result[j]%13)) {
                    uint16 temp = result[j];
                    result[j] = result[i];
                    result[i] = temp;
                }
            }
        }
        return result;
   }


  IERC20  public tokenAddress;
  uint256 public luckyPrice;
  
  function setLuckPrice(uint256 price) public onlyOwner{
    require(price > 100, "price must be gt 100!");
    luckyPrice = price;
  }
  
  function setTokenAddress(address token) public onlyOwner{
    require(token != address(tokenAddress), "token address Currently in use!");
    tokenAddress = IERC20(token);
  }
  
  function tokenAddressTransFrom() internal{
    if (address(tokenAddress) != address(0)){
        // token
        IERC20(tokenAddress).transferFrom(_msgSender(), owner(), luckyPrice);
    }else{
        // eth
        require(msg.value >= luckyPrice, "msg.value Too little");
        payable(owner()).transfer(address(this).balance);
    }
  }
   
   function mint() public payable {
       tokenAddressTransFrom();
       minted += 1;
       // save cards
       uint16[5] memory arr;
       string memory svg;
       (arr,svg) = genSVG(minted);
       _mint(msg.sender, minted);
       minted_pokers[minted] = arr;
       minted_poker_images[minted] = svg;
       // todo safemint
   }
   function genSVG(uint256 tokenId) private view returns (uint16[5] memory arr, string memory svg) {
       arr = gen(tokenId);
       
       svg = string(abi.encodePacked(
           header,
           '<g transform="translate(140,75) rotate(-50,61.8,200)"><rect x="0" y="0"  width="124" height="200" rx="8" ry="8" class="card"></rect>',
           fill(arr[0]),
           '<g transform="translate(140,75) rotate(-25,61.8,200)">',
            '<rect x="0" y="0"  width="124" height="200" rx="8" ry="8" class="card"></rect>',
            fill(arr[1]),
        '<g transform="translate(140,75) rotate(0,61.8,200)">',
            '<rect x="0" y="0"  width="124" height="200" rx="8" ry="8" class="card"></rect>',
            fill(arr[2]),
        '<g transform="translate(140,75) rotate(25,61.8,200)">',
            '<rect x="0" y="0"  width="124" height="200" rx="8" ry="8" class="card"></rect>',
            fill(arr[3]),
        '<g transform="translate(140,75) rotate(50,61.8,200)">',
            '<rect x="0" y="0"  width="124" height="200" rx="8" ry="8" class="card"></rect>',
            fill(arr[4]),
        '</svg>'
        ));
   }
   
   string[] _nums = ["A","2","3","4","5","6","7","8","9","10","J","Q","K"];
   
   function fill(uint16 num) private view returns (string memory){
       string memory color;
       string memory numstr = _nums[num % 13];
       string memory icon;
       if(num < 13) {
           color = "black";
           icon = "peach";
       } else if( num < 26) {
           color = "red";
           icon = "heart";
       } else if(num < 39) {
           color = "black";
           icon = "flower";
       } else {
           color = "red";
           icon = "block";
       }
       
       return string(abi.encodePacked(
           '<use width="20" height="20" xlink:href="#',
           icon,
           '"></use>',
           '<text x="40" y="36" class="txt ',
           color,
           '">',
           numstr,
           '</text></g>>'
        ));
       
   }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7777 && tokenId < 8001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
   
   

    function tokenURI(uint256 tokenId)  override public view returns  (string memory){
        require(tokenId<=minted,"token has not been minted");
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
             '{"name": "PokerLoot #', 
             toString(tokenId), 
             '", "description": "',
             _desc,
             '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(minted_poker_images[tokenId])), '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
    
    function totalSupply() public view override  returns (uint256) {
        return _totalSupply;
    }

   
   function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
   
   function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

     receive()payable external{}

  function OwnerSafeWithdrawalEth(uint256 amount) public onlyOwner{
        if (amount == 0){
            payable(owner()).transfer(address(this).balance);
            return;
        }
        payable(owner()).transfer(amount);
    }

  function OwnerSafeWithdrawalToken(address token_address, uint256 amount) public onlyOwner{
        IERC20 token_t = IERC20(token_address);
        if (amount == 0){
            token_t.transfer(owner(), token_t.balanceOf(address(this)));
            return;
        }
        token_t.transfer(owner(), amount);
    }

    constructor() ERC721("PokerLoot", "POKER_LOOT") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }

}