// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC2981ContractWideRoyalties.sol";
import "./Utils.sol";
import "./ERC721Tradable.sol";

import "./data-blocks/BackgroundImageData.sol";
import "./data-blocks/BodyImageData.sol";
import "./data-blocks/ArmsImageData.sol";
import "./data-blocks/HeadImageData.sol";
import "./data-blocks/FaceImageData.sol";
import "./data-blocks/HeadwearImageData.sol";

// import "hardhat/console.sol";

/**************                                                                                             
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                   
                                                                                           <@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@<                                                                                           
                                                                                           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?                                                                                           
                                                                                           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?                                                                                           
                                                                                           [email protected]@@@@@}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]@@@@@?                                                                                           
                                                                                           [email protected]@@@@@^                               ^@@@@@@?                                                                                           
                                                                                           [email protected]@@@@@^                               ^@@@@@@|                                                                                           
                                                                              ,[email protected]@@@@@[email protected]@@@@@Djjjjjjjjjjjj,                                                                              
                                                                              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+                                                                              
                                                                              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+                                                                              
                                                                        ~;;;;;ibbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbi;;;;;~                                                                        
                                                                       `#@@@@@X                                                                       [email protected]@@@@#`                                                                       
                                                                       `#@@@@@X                                                                       [email protected]@@@@#`                                                                       
                                                                       `[email protected]@@@@k                                                                       [email protected]@@@@N`                                                                       
                                                                 ~QQQQQB;'''''`                                                                       `''''';BQQQQQ;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                  [email protected]@@@@@@@@@@@8`                                                  ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                  [email protected]@@@@@@@@@@@8`                                                  ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                  [email protected]@@@@@@@@@@@8`                                                  ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                  [email protected]@@@@@@@@@@@8`                  %@@@@@@@@@@@@*                  ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                  [email protected]@@@@@@@@@@@8`                  [email protected]@@@@@@@@@@@?                  ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                  [email protected]@@@@@@@@@@@8`                  [email protected]@@@@@@@@@@@?                  ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                         [email protected]@@@@8`                  [email protected]@@@@6                         ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                         [email protected]@@@@8`                  [email protected]@@@@6                         ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                         7qqqqqm.                  mqqqqq7                         ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                               [email protected]@@@@@@@@@@@@@@@@@@_                               ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                               [email protected]@@@@@@@@@@@@@@@@@@_                               ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                               :@@@@@@@@@@@@@@@@@@@:                               ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 ;@@@@@@,                                                                                   ,@@@@@@;                                                                 
                                                                 .<<<<<*5EEEEEL                                                                       |EEEEE5*<<<<<.                                                                 
                                                                       `#@@@@@X                                                                       [email protected]@@@@#`                                                                       
                                                                       `#@@@@@X                                                                       [email protected]@@@@#`                                                                       
                                                                        |JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ|                                                                        
                                                                              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+                                                                              
                                                                              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+                                                                              
                                                                              ;%%%%%%[email protected]@@@@Q%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%[email protected]@@@@Q%%%%%%;                                                                              
                                                                                     [email protected]@@@@Z                                             [email protected]@@@@w                                                                                     
                                                                                     [email protected]@@@@a                                             [email protected]@@@@w                                                                                     
                                                                                     [email protected]@@@@Z                                             [email protected]@@@@w                                                                                     
                                                    ,&&&&&&&&&&&&o     `UB&&&&&&&&&&&@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@&&&&&&&&&&BBU`     oB&&&&&&&&&&&?                                                    
                                                    [email protected]@@@@@@@@@@@b     `#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#`     [email protected]@@@@@@@@@@@z                                                    
                                                    [email protected]@@@@@@@@@@@b     `#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#`     [email protected]@@@@@@@@@@@z                                                    
                                              zqqqqqS!!!!!!!!!!!!LqqqqqU*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*Uqqqqq|!!!!!!!!!!!!xqqqqqz                                              
                                              [email protected]@@@@g            ;@@@@@@,                                                                                   ,@@@@@@;            [email protected]@@@@K                                              
                                              [email protected]@@@@g            ;@@@@@@,                                                                                   ,@@@@@@;            [email protected]@@@@K                                              
                                       ,LLLLLL{yyyyy\            ;@@@@@@,                                                                                   ,@@@@@@;            !yyyyy{LLLLLL,                                       
                                       [email protected]@@@@@!                  ;@@@@@@,                                                                                   ,@@@@@@;                  [email protected]@@@@@L                                       
                                       [email protected]@@@@@!                  ;@@@@@@,                                                                                   ,@@@@@@;                  [email protected]@@@@@L                                       
                                       [email protected]@@@@@!                  ;@@@@@@,                                                                                   ,@@@@@@;                  [email protected]@@@@@L                                       
                                       [email protected]@@@@@!                  ;@@@@@@,                                                                                   ,@@@@@@;                  [email protected]@@@@@L                                       
                                       [email protected]@@@@@!                  ;@@@@@@,                                                                                   ,@@@@@@;                  [email protected]@@@@@L                                       
                                       [email protected]@@@@@;                  [email protected]@@@@Q,                                                                                   ,[email protected]@@@@!                  ;@@@@@@i                                  
                                 yQQQQQj                   6QQQQQU                                                                                                 UQQQQQU                   jQQQQQy                                 
                                 [email protected]@@@@y                   [email protected]@@@@b                                                                                                 [email protected]@@@@%                   [email protected]@@@@k                                 
                                 [email protected]@@@@y                   [email protected]@@@@b                                                                                                 [email protected]@@@@%                   [email protected]@@@@k                                 
                                 ~*****~                   !*****;                                                                                                 ;*****!                   ~*****~                                 
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
              ~}ffffffff=           ~f}fff};        *fffffff^             *fffffffff+   |fffff? ;ffffffff,  !ffffff~    ~fffffn,        zffffffffffffff,       :{}fffffffI.    +ffffffffffffc`            ~fffffffff}f~              
            ,P#@@@@@@@@@QUUE,      J#@@@@@@QU~  [email protected]@@@@@@QUUP'     `[email protected]@@@@@@@@[email protected]@@@@[email protected]@@@@@@@[email protected]@@@@@Nh',k#@@@@@@!      [email protected]@@@@@@@@@@@@@@g5.    [email protected]@@@@@@@@@Ds ;[email protected]@@@@@@@@@@@@KUU!      ,[email protected]@@@@@@@@@@#UU}           
           [email protected]@@z.       ^[email protected]@@@QX'[email protected]@@z.  [email protected]@@>'[email protected]@@@U~   <@@@@@QZ  `[email protected]@@@Q!    [email protected]@@@@w  ;[email protected]@@@7    [email protected]@@@@@*  [email protected]@@~;@@@z [email protected]    `[email protected]@6          [email protected]@@By`[email protected]@@{    [email protected]@@[email protected]@Q            [email protected]@QR`     '[email protected]@@7       [email protected]@@Nz         
          ,[email protected]@S.`         [email protected]@Qj [email protected]@S.`   [email protected]@[email protected]@Qz           [email protected],[email protected]@Qz          [email protected]@@^`   `[email protected]@Q!     [email protected]@z.     [email protected]@m.   [email protected]~''}[email protected] [email protected]@@[email protected]@Qo'`      `’#@@@@               [email protected] [email protected]@QI            '[email protected]@Z         
         [email protected]@@RL   ;;;      `[email protected]@d;[email protected] [email protected]@@@q    .;;;`     `[email protected]@@@@@             }@@@      ;@}       ;[email protected]@i      [email protected]@@@y     `[email protected]@@@@@#m`             ;[email protected]@@@QD~          `[email protected]@@@*                |[email protected];[email protected]@D       ;;;   '[email protected]@Z         
         [email protected]@%`    @@@!     `[email protected]@@@@@;     .>[email protected]@@6i   ;[email protected]@@n!     [email protected]@@%o       *<<*[email protected]@@@@      ,ar      [email protected]@@@i      <wwww=      [email protected]@@@@@;      =<<<<<<<[email protected]@@@@@t      ;**~   [email protected]@@*     `^*<<=.     `@@@@@@D      [email protected]@@y**[email protected]@@h*         
         [email protected]@%`    nux,    ;[email protected]@@@@@;     ;@@@@Q'    [email protected]@@@@8`     [email protected]@@<      [email protected]@@@@@@@@@              [email protected]@@@i                  [email protected]@@@@@;      @@@@@@@@@@@@@Qf;    ;[email protected]@Z    [email protected]@@*     '[email protected]@@@m?`    [email protected]@@@QJ;     x%@@@@@@@N`          
       [email protected]@R`            }@@@@@@@@;    [email protected]@@@Q'    [email protected]@@@@8`     [email protected]@@<      [email protected]@@@@@@@@@@6           [email protected]@@@@@i                  [email protected]@@@@@;      [email protected]@@@@@K`     [email protected]@@@Z    [email protected]@@*     '[email protected]@@@@Q.     [email protected]@@@@@Ny:     [email protected]@Qa=         
       |@@@\~             ,[email protected]@@@Z;`   [email protected]@@@@Q'    [email protected]@@7~      [email protected]@@<      [email protected]@@@@@@@@@@@j          ;[email protected]@@@@@i                  ~|[email protected]@E;`           [email protected]@@@@@q`     ,!!\@a    [email protected]@@*     '[email protected]@@@@B.     [email protected]@@@@@@@NKKJ`      +&@@QK;       
       |@@@_      @@Q;      `[email protected]@i     `[email protected]@Q'      ```        [email protected]@@J,      !88R;``^[email protected]@j            `[email protected]@@i      [email protected]@@@@@=     '[email protected]@7      }@@@@@@@@@@@@Q,`                [email protected]@@@Q     `!88%;`      [email protected]@@Qa.``f88gD*      `[email protected]@@|       
       |@@@_      6qX        ,[email protected]@i         ^AQQ|~               ;[email protected]@@@@               [email protected]@j      '^.      [email protected]@i      [email protected]@@@@@<     '[email protected]@7      *[email protected]@Q'     <@@@z;      [email protected]@@@@                  [email protected]@Q,                 [email protected]@@|       
       |@@@_                 ,[email protected]@i           [email protected]@q               [email protected]@@@@@i            ,[email protected]@j      [email protected]+      [email protected]@i      [email protected]@@@@@<     '[email protected]@7                [email protected]@@I!   [email protected]@@@8`     [email protected]@@@@                 |[email protected]@Q,                ^[email protected]@@|       
       |@@@hL             [email protected]@@Dn        ;[email protected]@Qjjj,        [email protected]@@@gj        [email protected]@@@Nj_  'n%@Kz`   [email protected]@R}    j&@[email protected]@@dn   *[email protected]@@%u.             n%@@@@[email protected]@@@@Qyr   [email protected]@@@@                [email protected]@@@@E|           [email protected]@gT,       
       '[email protected]@[email protected]@Q|[email protected]@@DXXXXXXX&@@[email protected]@@%[email protected]@@@%`'++*@@@@@[email protected]@@E*[email protected]@[email protected]@@@@[email protected]@@@@@[email protected]@@~`[email protected]@@[email protected]@@[email protected]@@[email protected]@@@@%=+<[email protected]@[email protected]@@@@@@[email protected]@@@@@@[email protected]@@@Q<_         
         ';#@@@@@@@@@@@@@@y~~: `[email protected]@@@@@@@@@@z~ `[email protected]@@@@@@@@@@{~~,     ~~;[email protected]@@@@@@@@q~. ,[email protected]@@@@@[email protected]@@@@@[email protected]@@@@@}~`  .;[email protected]@@@v_ `[email protected]@@@@@@@@@@@@@@@w~` _~~~~~'   ,[email protected]@@@@@8;[email protected]@@@@@@@@@@@@@@@j~~~~~^[email protected]@@@@@@@@@@@@@j~~:           
            ''''''''''''''`      `'''''''''''`    `'''''''''''`           `'''''''''`    `''''''` `''''''`  `''''''`      `''''`    `''''''''''''''''`               ''''''    `''''''''''''''''`       ''''''''''''''`              
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                     
******************/

// Interface that all the data blocks exported from figma fulfill
// ImageDataBlocks contain
// - A giant blob of PNG encoded data of each image in the set concatenated together
// - An array of offsets and lengths indicating the substring of bytes representing each image
// - An array of human readable names for each image, to be passed to the attributes json
interface ImageDataBlock {
    // // Offset that the image at each slot starts at in bytes
    // function getOffsets() external view returns (uint32[] memory);

    // // Length of image at each slot in bytes
    // function getLengths() external view returns (uint32[] memory);

    // // Human readable names matching the image at each index
    // function getNames() external view returns (string[] memory);

    // // The hex data representing png encoded images.
    // // You can slice this and base64 encode it to put it into an svg.
    // function getData() external pure returns (bytes memory);

    function getData(uint256 slot) external pure returns (bytes memory);

    function getLabel(uint256 slot) external pure returns (string memory);
}

contract Blockheads is
    ERC721Tradable,
    ERC2981ContractWideRoyalties,
    BackgroundImageDataSize,
    BodyImageDataSize,
    ArmsImageDataSize,
    HeadImageDataSize,
    FaceImageDataSize,
    HeadwearImageDataSize
{
    event BlockheadReconfigured(uint256 tokenId);

    uint256 public constant totalAvailable = 10000;
    uint256 public mintCost = 0.05 ether;
    uint256 public nextTokenId = 1; // 1, for friendship

    /**
    Attributes can be referenced by an index into the labels and image data
    the xxxIndex(uint256) functions will return what index that particular trait should be for a token.  It can be
    used to find image data or labels via the blocks of data exported from figma at the bottom.
    It default to a random value, but can be swapped and overridden using the maps below.
     */

    // Override mappings for each attribute.
    // If there is an override we use that, otherwise we fall back to `initialValueFor`
    // Since all values are initialized to 0, we need a flag to know if we've actually set
    // the override.
    struct Overrides {
        // Storing uint16s is cheaper and should be enough for representing all options for each slot
        uint16 background;
        uint16 body;
        uint16 arms;
        uint16 head;
        uint16 face;
        uint16 headwear;
        bool backgroundOverridden;
        bool bodyOverridden;
        bool armsOverridden;
        bool headOverridden;
        bool faceOverridden;
        bool headwearOverridden;
    }

    // Storing 1 big mapping instead of different mappings for everything makes successive
    // swaps much cheaper since we don't need to call the expensive random function
    mapping(uint256 => Overrides) overrides;
    mapping(uint256 => string) nameOverrides;

    // All the data blocks are deployed to separate contracts because its too big to put all this data in one contract.
    // They're deployed separately and referenced here, to be used with the ImageDataBlock interface.
    address backgroundDataBlock;
    address bodyDataBlock;
    address armsDataBlock;
    address headDataBlock;
    address faceDataBlock;
    address headwearDataBlock;

    // Constructor requires the proxy for opensea, and all the data blocks
    constructor(
        address proxyRegistryAddress,
        address _backgroundDataBlock,
        address _bodyDataBlock,
        address _armsDataBlock,
        address _headDataBlock,
        address _faceDataBlock,
        address _headwearDataBlock
    ) ERC721Tradable("Blockheads", "BLOK", proxyRegistryAddress) {
        // 10% royalties for ERC2981.  Not sure if anyone supports this yet.
        _setRoyalties(msg.sender, 1000);
        backgroundDataBlock = _backgroundDataBlock;
        bodyDataBlock = _bodyDataBlock;
        armsDataBlock = _armsDataBlock;
        headDataBlock = _headDataBlock;
        faceDataBlock = _faceDataBlock;
        headwearDataBlock = _headwearDataBlock;
    }

    // Mint a single blockhead
    function mint() public payable {
        require(msg.value >= mintCost, "Save up your quarters");
        require(nextTokenId <= totalAvailable, "Sold out");
        _safeMint(msg.sender, nextTokenId);
        nextTokenId++;
    }

    // Mint 5 for the price of 4
    function buy4get1free() public payable {
        // Ensure they've paid for 4
        require(msg.value >= mintCost * 4, "Save up your quarters");
        require(nextTokenId + 5 < totalAvailable, "Sold out");
        // But give them 5
        for (uint256 i = 0; i < 5; i++) {
            _safeMint(msg.sender, nextTokenId);
            nextTokenId++;
        }
    }

    // Allow owners to update the mint cost if needed
    function setMintCost(uint256 newCost) public onlyOwner {
        mintCost = newCost;
    }

    // Withdraw balance to the owners
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //
    // xxxIndex functions will return the current index of this tokens property.
    // If there is an override we'll use that otherwise we'll fall back to the pseudorandom `initialValueFor`.
    //

    function backgroundIndex(uint256 tokenId) public view returns (uint256) {
        if (overrides[tokenId].backgroundOverridden) {
            return overrides[tokenId].background;
        }
        return initialValueFor(tokenId, getNumBackgroundValues(), "bg");
    }

    function bodyIndex(uint256 tokenId) public view returns (uint256) {
        if (overrides[tokenId].bodyOverridden) {
            return overrides[tokenId].body;
        }
        return initialValueFor(tokenId, getNumBodyValues(), "body");
    }

    function armsIndex(uint256 tokenId) public view returns (uint256) {
        if (overrides[tokenId].armsOverridden) {
            return overrides[tokenId].arms;
        }
        return initialValueFor(tokenId, getNumArmsValues(), "arms");
    }

    function headIndex(uint256 tokenId) public view returns (uint256) {
        if (overrides[tokenId].headOverridden) {
            return overrides[tokenId].head;
        }
        return initialValueFor(tokenId, getNumHeadValues(), "head");
    }

    function faceIndex(uint256 tokenId) public view returns (uint256) {
        if (overrides[tokenId].faceOverridden) {
            return overrides[tokenId].face;
        }
        return initialValueFor(tokenId, getNumFaceValues(), "face");
    }

    function headwearIndex(uint256 tokenId) public view returns (uint256) {
        if (overrides[tokenId].headwearOverridden) {
            return overrides[tokenId].headwear;
        }
        return initialValueFor(tokenId, getNumHeadwearValues(), "headwear");
    }

    function random(bytes memory input) internal pure returns (uint256) {
        return uint256(keccak256(input));
    }

    // The randomly selected initial value for this token.
    // Can be overridden by overrides.
    function initialValueFor(
        uint256 tokenId,
        uint16 modulo,
        string memory keyPrefix
    ) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked(keyPrefix, tokenId));
        uint256 index = rand % modulo;
        return uint256(index);
    }

    modifier ownsBoth(uint256 token1, uint256 token2) {
        require(ownerOf(token1) == msg.sender);
        require(ownerOf(token2) == msg.sender);
        _;
    }

    function swapBGs(uint256 token1, uint256 token2)
        public
        ownsBoth(token1, token2)
    {
        uint256 newBG1 = backgroundIndex(token2);
        uint256 newBG2 = backgroundIndex(token1);
        overrides[token1].background = uint16(newBG1);
        overrides[token2].background = uint16(newBG2);
        overrides[token1].backgroundOverridden = true;
        overrides[token2].backgroundOverridden = true;
        emit BlockheadReconfigured(token1);
        emit BlockheadReconfigured(token2);
    }

    function swapBodies(uint256 token1, uint256 token2)
        public
        ownsBoth(token1, token2)
    {
        uint256 newBody1 = bodyIndex(token2);
        uint256 newBody2 = bodyIndex(token1);
        overrides[token1].body = uint16(newBody1);
        overrides[token2].body = uint16(newBody2);
        overrides[token1].bodyOverridden = true;
        overrides[token2].bodyOverridden = true;
        emit BlockheadReconfigured(token1);
        emit BlockheadReconfigured(token2);
    }

    function swapArms(uint256 token1, uint256 token2)
        public
        ownsBoth(token1, token2)
    {
        uint256 newArm1 = armsIndex(token2);
        uint256 newArm2 = armsIndex(token1);
        overrides[token1].arms = uint16(newArm1);
        overrides[token2].arms = uint16(newArm2);
        overrides[token1].armsOverridden = true;
        overrides[token2].armsOverridden = true;
        emit BlockheadReconfigured(token1);
        emit BlockheadReconfigured(token2);
    }

    function swapHeads(uint256 token1, uint256 token2)
        public
        ownsBoth(token1, token2)
    {
        uint256 newHead1 = headIndex(token2);
        uint256 newHead2 = headIndex(token1);
        overrides[token1].head = uint16(newHead1);
        overrides[token2].head = uint16(newHead2);
        overrides[token1].headOverridden = true;
        overrides[token2].headOverridden = true;
        emit BlockheadReconfigured(token1);
        emit BlockheadReconfigured(token2);
    }

    function swapFaces(uint256 token1, uint256 token2)
        public
        ownsBoth(token1, token2)
    {
        uint256 newFace1 = faceIndex(token2);
        uint256 newFace2 = faceIndex(token1);
        overrides[token1].face = uint16(newFace1);
        overrides[token2].face = uint16(newFace2);
        overrides[token1].faceOverridden = true;
        overrides[token2].faceOverridden = true;
        emit BlockheadReconfigured(token1);
        emit BlockheadReconfigured(token2);
    }

    function swapHeadwears(uint256 token1, uint256 token2)
        public
        ownsBoth(token1, token2)
    {
        uint256 newHeadwear1 = headwearIndex(token2);
        uint256 newHeadwear2 = headwearIndex(token1);
        overrides[token1].headwear = uint16(newHeadwear1);
        overrides[token2].headwear = uint16(newHeadwear2);
        overrides[token1].headwearOverridden = true;
        overrides[token2].headwearOverridden = true;
        emit BlockheadReconfigured(token1);
        emit BlockheadReconfigured(token2);
    }

    function setName(uint256 tokenId, string memory name) public {
        require(ownerOf(tokenId) == msg.sender);
        nameOverrides[tokenId] = name;
        emit BlockheadReconfigured(tokenId);
    }

    function getName(uint256 tokenId) public view returns (string memory) {
        if (bytes(nameOverrides[tokenId]).length > 0) {
            return nameOverrides[tokenId];
        }
        return string(abi.encodePacked("Blockhead #", Utils.toString(tokenId)));
    }

    function getProfession(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        // Storing these here saves a good amount of gas by not needing to create storage slots for them
        // Since you can't really do constants for string arrays
        string[35] memory professions = [
            "Firefighter",
            "Teacher",
            "Solidity Engineer",
            "Architect",
            "Philosopher",
            "Dog Trainer",
            "Pilot",
            "Spy",
            "Astronaut",
            "Groundskeeper",
            "Doctor",
            "Investor",
            "Curator",
            "Chef",
            "Artist",
            "Police Officer",
            "Fisherman",
            "Nurse",
            "Botanist",
            "Influencer",
            "Graphic Designer",
            "Businessman",
            "Podcaster",
            "Racecar Driver",
            "Plumber",
            "Product Manager",
            "Founder",
            "Comedian",
            "Super Hero",
            "Scuba Diver",
            "Photographer",
            "Yoga Instructor",
            "Carpenter",
            "Singer",
            "Therapist"
        ];
        return
            professions[
                initialValueFor(
                    tokenId,
                    uint16(professions.length),
                    "profession"
                )
            ];
    }

    function image(bytes memory buf, bytes memory b64ImageData)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                buf,
                "<image style='image-rendering: pixelated' href='data:image/jpeg;charset=utf-8;base64,",
                Utils.base64Encode(b64ImageData),
                "' width='1000' height='1000'/>"
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bytes
            memory svg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 25 25' width='500' height='500'>";
        svg = abi.encodePacked(svg, getBgData(tokenId));
        svg = abi.encodePacked(svg, getBodyData(tokenId));
        svg = abi.encodePacked(svg, getArmsData(tokenId));
        svg = abi.encodePacked(svg, getHeadData(tokenId));
        svg = abi.encodePacked(svg, getFaceData(tokenId));
        svg = abi.encodePacked(svg, getHeadwearData(tokenId));
        svg = abi.encodePacked(svg, "</svg>");
        // Need to break up the json generation into 2 encodePackeds to avoid stack too deep errors
        bytes memory jsonPt1 = abi.encodePacked(
            '{"name": "',
            getName(tokenId),
            '", "description": "Blockheads", "image": "data:image/svg+xml;base64,',
            Utils.base64Encode(svg),
            '", "attributes": [{"trait_type": "Background", "value": "',
            getBgLabel(tokenId),
            '"}, ',
            '{"trait_type": "Profession", "value": "',
            getProfession(tokenId),
            '"}, '
        );
        string memory json = Utils.base64Encode(
            abi.encodePacked(
                jsonPt1,
                '{"trait_type": "Body", "value": "',
                getBodyLabel(tokenId),
                '"}, ',
                '{"trait_type": "Arms", "value": "',
                getArmsLabel(tokenId),
                '"}, ',
                '{"trait_type": "Head", "value": "',
                getHeadLabel(tokenId),
                '"}, ',
                '{"trait_type": "Face", "value": "',
                getFaceLabel(tokenId),
                '"}, ',
                '{"trait_type": "Headwear", "value": "',
                getHeadwearLabel(tokenId),
                '"}]}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function getBgData(uint256 tokenId) public view returns (bytes memory) {
        ImageDataBlock bgData = ImageDataBlock(backgroundDataBlock);
        return bgData.getData(backgroundIndex(tokenId));
    }

    function getBodyData(uint256 tokenId) public view returns (bytes memory) {
        ImageDataBlock bodyData = ImageDataBlock(bodyDataBlock);
        return bodyData.getData(bodyIndex(tokenId));
    }

    function getArmsData(uint256 tokenId) public view returns (bytes memory) {
        ImageDataBlock armsData = ImageDataBlock(armsDataBlock);
        return armsData.getData(armsIndex(tokenId));
    }

    function getHeadData(uint256 tokenId) public view returns (bytes memory) {
        HeadImageData headData = HeadImageData(headDataBlock);
        return headData.getData(headIndex(tokenId));
    }

    function getFaceData(uint256 tokenId) public view returns (bytes memory) {
        ImageDataBlock faceData = ImageDataBlock(faceDataBlock);
        return faceData.getData(faceIndex(tokenId));
    }

    function getHeadwearData(uint256 tokenId)
        public
        view
        returns (bytes memory)
    {
        ImageDataBlock dataBlock = ImageDataBlock(headwearDataBlock);
        return dataBlock.getData(headwearIndex(tokenId));
    }

    function getBgLabel(uint256 tokenId) public view returns (string memory) {
        ImageDataBlock bgData = ImageDataBlock(backgroundDataBlock);
        return bgData.getLabel(backgroundIndex(tokenId));
    }

    function getBodyLabel(uint256 tokenId) public view returns (string memory) {
        ImageDataBlock bodyData = ImageDataBlock(bodyDataBlock);
        return bodyData.getLabel(bodyIndex(tokenId));
    }

    function getArmsLabel(uint256 tokenId) public view returns (string memory) {
        ImageDataBlock armsData = ImageDataBlock(armsDataBlock);
        return armsData.getLabel(armsIndex(tokenId));
    }

    function getHeadLabel(uint256 tokenId) public view returns (string memory) {
        ImageDataBlock headData = ImageDataBlock(headDataBlock);
        return headData.getLabel(headIndex(tokenId));
    }

    function getFaceLabel(uint256 tokenId) public view returns (string memory) {
        ImageDataBlock faceData = ImageDataBlock(faceDataBlock);
        return faceData.getLabel(faceIndex(tokenId));
    }

    function getHeadwearLabel(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        ImageDataBlock dataBlock = ImageDataBlock(headwearDataBlock);
        return dataBlock.getLabel(headwearIndex(tokenId));
    }

    function setBackgroundDataBlockAddress(address newAddr) public onlyOwner {
        backgroundDataBlock = newAddr;
    }

    function setBodyDataBlockAddress(address newAddr) public onlyOwner {
        bodyDataBlock = newAddr;
    }

    function setHeadDataBlockAddress(address newAddr) public onlyOwner {
        headDataBlock = newAddr;
    }

    function setFaceDataBlockAddress(address newAddr) public onlyOwner {
        faceDataBlock = newAddr;
    }

    function setArmsDataBlockAddress(address newAddr) public onlyOwner {
        armsDataBlock = newAddr;
    }

    function setHeadwearDataBlockAddress(address newAddr) public onlyOwner {
        headwearDataBlock = newAddr;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import './IERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is IERC2981Royalties {
    address private _royaltiesRecipient;
    uint256 private _royaltiesValue;

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royaltiesRecipient = recipient;
        _royaltiesValue = value;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltiesRecipient, (value * _royaltiesValue) / 10000);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Utils {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function base64Encode(bytes memory data)
        internal
        pure
        returns (string memory)
    {
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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BackgroundImageDataSize {
    function getNumBackgroundValues() public pure returns (uint16) {
        // Returning constant instead of asking the data for its length saves gas
        return 24;
    }
}

contract BackgroundImageData {
    function getLabel(uint256 slot) public pure returns (string memory) {
        string[24] memory names = [
            "Aqua",
            "Light Blue",
            "Bright Blue",
            "Dark Blue",
            "Light Grey",
            "Medium Grey",
            "Dark Grey",
            "White",
            "Light Pink",
            "Deep Blush",
            "Yellow Green",
            "Bright Green",
            "Dark Green",
            "Olive Green",
            "Light Nougat",
            "Nougat",
            "Brick Yellow",
            "Light Brown",
            "Dark Brown",
            "Light Yellow",
            "Yellow",
            "Bright Yellow",
            "Bright Orange",
            "Bright Red"
        ];
        return names[slot];
    }

    function getData(uint256 slot) public pure returns (bytes memory) {
        string[24] memory colors = [
            "C1E4DA",
            "78BFEA",
            "00A3DA",
            "006CB7",
            "A0A19F",
            "646765",
            "42423E",
            "F4F4F4",
            "F6ADCD",
            "E95DA2",
            "9ACA3C",
            "00AF4D",
            "009247",
            "828353",
            "FCC39E",
            "DE8B5F",
            "DDC48E",
            "AF7446",
            "692E14",
            "FFF579",
            "FEE716",
            "FFCD03",
            "F57D20",
            "DD1A21"
        ];
        return abi.encodePacked(
                '<rect width="25" height="25" fill="#',
                colors[slot],
                '"/>');
    }

}

// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BodyImageDataSize {
    function getNumBodyValues() public pure returns (uint16) {
        // Returning constant instead of asking the data for its length saves gas
        return 24;
    }
}

contract BodyImageData {
    function getLabel(uint256 slot) public pure returns (string memory) {
        string[24] memory names = [
            "Aqua",
            "Light Blue",
            "Bright Blue",
            "Dark Blue",
            "Light Grey",
            "Medium Grey",
            "Dark Grey",
            "White",
            "Light Pink",
            "Deep Blush",
            "Yellow Green",
            "Bright Green",
            "Dark Green",
            "Olive Green",
            "Light Nougat",
            "Nougat",
            "Brick Yellow",
            "Light Brown",
            "Dark Brown",
            "Light Yellow",
            "Yellow",
            "Bright Yellow",
            "Bright Orange",
            "Bright Red"
        ];
        return names[slot];
    }

    function getData(uint256 slot) public pure returns (bytes memory) {
        string[24] memory colors = [
            "C1E4DA",
            "78BFEA",
            "00A3DA",
            "006CB7",
            "A0A19F",
            "646765",
            "42423E",
            "F4F4F4",
            "F6ADCD",
            "E95DA2",
            "9ACA3C",
            "00AF4D",
            "009247",
            "828353",
            "FCC39E",
            "DE8B5F",
            "DDC48E",
            "AF7446",
            "692E14",
            "FFF579",
            "FEE716",
            "FFCD03",
            "F57D20",
            "DD1A21"
        ];
        return
            abi.encodePacked(
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M15 15V20H19V21H6V20H10V15H15ZM5 24V21H6V24H5ZM5 24V25H4V24H5ZM20 24V21H19V24H20ZM20 24V25H21V24H20ZM11 20H14V16H11V20Z" fill="black"/>'
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M11 16H14V20H11V16ZM19 21V24H20V25H5V24H6V21H19Z" fill="#',
                colors[slot],
                '"/>'
            );
    }
}

// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ArmsImageDataSize {
    function getNumArmsValues() public pure returns (uint16) {
        // Returning constant instead of asking the data for its length saves gas
        return 24;
    }
}

contract ArmsImageData {
    function getLabel(uint256 slot) public pure returns (string memory) {
        string[24] memory names = [
            "Aqua",
            "Light Blue",
            "Bright Blue",
            "Dark Blue",
            "Light Grey",
            "Medium Grey",
            "Dark Grey",
            "White",
            "Light Pink",
            "Deep Blush",
            "Yellow Green",
            "Bright Green",
            "Dark Green",
            "Olive Green",
            "Light Nougat",
            "Nougat",
            "Brick Yellow",
            "Light Brown",
            "Dark Brown",
            "Light Yellow",
            "Yellow",
            "Bright Yellow",
            "Bright Orange",
            "Bright Red"
        ];
        return names[slot];
    }

    function getData(uint256 slot) public pure returns (bytes memory) {
        string[24] memory colors = [
            "C1E4DA",
            "78BFEA",
            "00A3DA",
            "006CB7",
            "A0A19F",
            "646765",
            "42423E",
            "F4F4F4",
            "F6ADCD",
            "E95DA2",
            "9ACA3C",
            "00AF4D",
            "009247",
            "828353",
            "FCC39E",
            "DE8B5F",
            "DDC48E",
            "AF7446",
            "692E14",
            "FFF579",
            "FEE716",
            "FFCD03",
            "F57D20",
            "DD1A21"
        ];
        return
            abi.encodePacked(
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M3 21H5V24H4V25H1V24H2V22H3V21ZM22 21H20V24H21V25H24V24H23V22H22V21Z" fill="#',
                colors[slot],
                '"/>'
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M5 20H3V21H2V22H1V24H0V25H1V24H2V22H3V21H5V24H4V25H5V24H6V21H5V20ZM22 20H20V21H19V24H20V25H21V24H20V21H22V22H23V24H24V25H25V24H24V22H23V21H22V20Z" fill="black"/>'
            );
    }

    //////// Data blobs
    // We use uint32s for all the lengths and offsets since it indexes into the png data blob which can be quite large.  32-bit values (up to 2.1M) seem large enough we won't have more than 2 megs of data in here.
    bytes constant data =
        hex"89504e470d0a1a0a0000000d4948445200000019000000190806000000c4e98563000000644944415448c763601805a360148c8251300a46c100034628a699198c40f01f8429b088096ac63f6c66802d38f8e4161803f9ffc9f101cc8c038f6f62b5086e01352c81590414fb4794248996fc03e9c7e69b7f40413826d302148b6066012d0299f517003b5560d3878056140000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e9856300000063494441544889ed8f410a80300c04133fadafabefa97f30b50d6945c84183e26507f6604b679008000000003fc3b6cf1c4ccc45170f4de610cfa18165dd74f5bb0402a72365373402af447a88486e5d3e8c487beffd8dd4c3b160e01a32d79c7273ed0734ab58b8793b69dc0000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e985630000005f494441544889ed8f410ac0200c0427fdff2bf455fa97c61e54a4e0a1b52dbdecc09e02330484104208f133d6f699c3302b989507a1ad397ce6a88198eba02c048623a4696804de88f410f8a5e3cd8813d2f41b27e6b1b5c039d45d2139b01fc73e4aa179d72ad80000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e985630000005b4944415448c7ed8f410ac0300804d7be37ef33afabe9c148a07848a5a5971dd893308300218410427e46e63e730820c3570e1dd36199c303adfb8051fb201c9a8656e0954884605bc7871143d3f41b43eb6bb5c02d143e3500e7050c3942dfc50d20540000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e98563000000614944415448c7ed8f410e80200c04c1ffbf01f0a116b7849298f480a8f1b293ec8136eca42110420821e46762cf671d1154cd03d1d63bc4eb6882b2e716bcebca05d6914b724543f086c44498c9d4f2a644f4bf778d6038b228b888ac0b22ed3a4e2a335329e1f004c50000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e985630000005549444154488963601805a360148c8251300a46c100034628a699192089ff504cae454c50fdffb09901b620253d158ca10a4905e86660580497a496254816119624d1927f58cc01fb062401c7645a806e11b2797f01e4af43f7e6dae0330000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e985630000005549444154488963601805a360148c8251300a46c100034628a699192089ff504cae454c50fdffb09901b6c0c9c90e8ca10a4905e86660580497a496254816119624d1927f58cc01fb062401c7645a806e11b2797f01eca43a831ed256070000000049454e44ae42608289504e470d0a1a0a0000000d49484452000000190000001908040000006ee04de80000004d4944415438cbedcd310e80300c43519bfbdf365eb15990e840abb2a2fc2d529e0c745df79b087efb20c32cd1c1d0cf07194541e60b8c52038ab68852815fce09710d3b966579016e24cb659c17e17a3ed5df4444390000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e98563000000644944415448c763601805a360148c8251300a46c100034628a699198c40f01f8429b088096ac63f6c66802df8b6f62c1803f9ffc9f101cc8caf6bce60b5086e01352c81590414fb4794248996fc03e9c7e69b7f40413826d302148b6066012d0299f517004daa5f89fe8720fb0000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e98563000000644944415448c7ed8f410a80300c0413ffd9c7e9ebf4114d4d4a531072a855f1b2037b6842770811000000007e865b3eeb60262e9607a2a57548d4510547da6af45d662ef08e3dada1a80bde90b8486732b4bc2911fb1f5d233aec99145c44dea522ebca27a7eb53d3006c25f20000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e98563000000644944415448c7ed8f410a80300c0413dfd58fea8ff44f4d4d4a531072a855f1b2037b6842770811000000007e865b3eeb60662a9607a2a57548d45105db916af45d662ef08e754fa1a80bde90b8486732b4bc2911fb1f5d233aec99145c44dea522ebca2719ef4da3187b84f80000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e985630000005d4944415448c7ed8f410a80300c0427fe2f5f6d5f68eaa12d45e841abe26507f614982120841042889fb1b6cf1c865130ca83d0d61c3173d440f63a284b1f7447f2696804de88f410c4a5e3cd48907cfa4d907d6c2d700e7557f200f6039ca63f856692c3b50000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e985630000005d4944415448c7ed8f410a80300c04277e2eef6bff6beaa12d45e841abe26507f614982120841042889fb1b6cf1c865130ca83d0d61c3173d440f63a284b1f7447f2696804de88f410c4a5e3cd48907cfa4d907d6c2d700e7557f200f60365643c836c6de9270000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e98563000000624944415448c7ed8f410ac0200c04937ed117d5bebbb18918a19083da965e76600f26b8438800000000f033dcf259073353b13c106dad43a28e2ac847aad17759b9c03bf69c425117bc217191ce6468392911fb1f5d233aec5914dc44dea522eb3a2f85da4773ef8ec2a00000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e9856300000063494441544889ed8f410e80200c0481ff7f411f23cf528b5b024d4c7a50d478d949f6d092ee841008218410f233b1e5b38e088ae68128b50ef13aaa60cb730de63220b08e75995c9109de9074117672e9f1a644f4defb8d606919149c44bd0b22edda0f1e015de75d6e740c0000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e98563000000644944415448c7ed8f410a80300c04133fdaffe81bf5274d4d4a531072a855f1b2037b6842770811000000007e865b3eeb60662a9607a2a57548d45105c7966af45d662ef08e7d4da1a80bde90b8486732b4bc2911fb1f5d233aec99145c44dea522ebca27a5a351136b2a09790000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e9856300000063494441544889ed8f410e80200c0481ffeba7e419fa148b5b024d4c7a50d478d949f6d092ee841008218410f233b1e5b38e088ae68128b50ef13aaa60cb730de63220b08e75995c9109de9074117672e9f1a644f4defb8d606919149c44bd0b22edda0f327a59f3575575c80000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e9856300000063494441544889ed8f4b0ac0200c05630fd70bb5e74a4fd8d8346ab02088fdd0cd1b781b03334804000000809f09799f39825ee2b907a1293ba4e5b0c0b6ce364aa151dcc1ba56c8036f444a8852a87f1c8c08579efa37a28fbe9b814ba8b87831df7e00948a48e2e3239abe0000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e985630000005549444154488963601805a360148c8251300a46c100034628a699192089ff504cae454c50fdffb09901b620534f048ca10a4905e86660580497a496254816119624d1927f58cc01fb062401c7645a806e11b2797f017e83388931b21be60000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e98563000000614944415448c7ed8f410a80301003135fedfebb3d9a786905a107ad8a971dc8696186059224499224f919b67de6200993f083d0d21c1a3948c2ae61d73000cf7cd01d2a310c1d8137223d0440978e37235289e137728d63938153a8bb545601d8761af45f407461ce080000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e9856300000062494441544889ed8f410ac0200c04933ec2ffbfae7d85d1443420e4d06a4b2f3bb08744b2834400000000f819eef9ac8399a958364447ef90a8a309e44a2d3a97058177e433852217bc211922ddc9adc78712b1fbe837a24bcfa260128d2e155957aee9fe5575bb97964b0000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e98563000000614944415448c7ed8f410a8030100313f7ff3f6b9f64e2a52d083d6855bcec404e0b332c9024499224c9cfb0ed33074998841f84b6e6d0cc4112760dbb860178e583ee5089696804de88f410005d3ade8c4825a6dfc835c61603a75077a98400ec0721f851addfc97aac0000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e9856300000065494441544889ed8f4b0e80200c055b4fc241f5d67569b556692061217ee2e64df23690cc0011000000007e86cf7de660bb59f73d080dee60d296c303f3947c74847a0987d85aa108bc11c9213bd34b975d117bbd149ef2376a87b19b812a945d32ba6fd9003acf4c6d48ae06150000000049454e44ae42608289504e470d0a1a0a0000000d4948445200000019000000190806000000c4e9856300000062494441544889ed8f4b0ac0200c05638fd15def7fa5f428c6a646830541ec876edec0db1898412200000000fc4c28fbcc11f492ce3d082dc5213d470eeceb9647169ac51daceb853cf046a486c842e3e36444b8f1b4bf117df4dd0c5c42d5c5e68b0779b041ed1629ac930000000049454e44ae426082";

    // taken from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function slice(
        bytes memory _bytes,
        uint32 _start,
        uint32 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)
                let lengthmod := and(_length, 31)
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }
                mstore(tempBytes, _length)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)
                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract HeadImageDataSize {
    function getNumHeadValues() public pure returns (uint16) {
        // Returning constant instead of asking the data for its length saves gas
        return 13;
    }
}

contract HeadImageData {
    function getLabel(uint256 slot) public pure returns (string memory) {
        string[13] memory names = [
            "Light Grey",
            "Dark Grey",
            "White",
            "Light Pink",
            "Light Nougat",
            "Nougat",
            "Brick Yellow",
            "Light Brown",
            "Dark Brown",
            "Light Yellow",
            "Yellow",
            "Bright Yellow",
            "Bright Orange"
        ];
        return names[slot];
    }

    function getData(uint256 slot) public pure returns (bytes memory) {
        string[13] memory colors = [
            "A0A19F",
            "42423E",
            "F4F4F4",
            "F6ADCD",
            "FCC39E",
            "DE8B5F",
            "DDC48E",
            "AF7446",
            "692E14",
            "FFF579",
            "FEE716",
            "FFCD03",
            "F57D20"
        ];
        return
            abi.encodePacked(
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M10 5H15V6H10V5ZM18 8V7H7V8H6V17H7V18H18V17H19V8H18ZM16 19H9V20H16V19Z" fill="#',
                colors[slot],
                '"/>'
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M18 6V7H7V6H9V4H16V6H18ZM6 8V7H7V8H6ZM6 17H5V8H6V17ZM7 18H6V17H7V18ZM18 18V19H17V20H16V19H9V20H8V19H7V18H18ZM19 17H18V18H19V17ZM19 8H18V7H19V8ZM19 8V17H20V8H19ZM15 5H10V6H15V5Z" fill="black"/>'
            );
    }
}

// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// The main contract can extend this so that it can just get the constant value
// rather than having to call the datablock contract.
contract FaceImageDataSize {
    function getNumFaceValues() public pure returns (uint16) {
        // Returning constant instead of asking the data for its length saves gas
        return 30;
    }
}

contract FaceImageData {
    function getLabel(uint256 slot) public pure returns (string memory) {
        string[30] memory names = [
            "Red Lipstick",
            "Light Blue Goggles",
            "Black Goggles",
            "Fashion Glasses",
            "Light Blue Wrap Around Shades",
            "Black Wrap Around Shades",
            "Disguise",
            "3D Glasses",
            "Smile",
            "Serious",
            "Smile with Beard",
            "Serious with Beard",
            "Wink",
            "Wink with Beard",
            "Eyebrows",
            "Eyebrows with Beard",
            "Mustache",
            "Mustache",
            "Skeleton",
            "Monocle",
            "Monocle with Beard",
            "Eyepatch",
            "Eyepatch with Beard",
            "Smoking",
            "Sunglasses",
            "Sunglasses with Beard",
            "Round Glasses",
            "Round Glasses with Beard",
            "Black Round Glasses",
            "Black Round Glasses with Beard"
        ];
        return names[slot];
    }

    struct PathData {
        string d;
        string fill;
    }

    struct SVGComposition {
        PathData[3] paths;
    }

    function pathDataToSVG(PathData memory pathData)
        private
        pure
        returns (bytes memory)
    {
        if (bytes(pathData.d).length == 0) return bytes("");
        
        return
            abi.encodePacked(
                '<path fill-rule="evenodd" clip-rule="evenodd" d="',
                pathData.d,
                '" fill="',
                bytes(pathData.fill).length > 0 ? pathData.fill : "black",
                '" />'
            );
    }

    function getData(uint256 slot) public pure returns (bytes memory) {
        SVGComposition[30] memory svgData = [
            SVGComposition(
                [
                    PathData("M10 16H11V17H14V16H15V15H10V16Z", "#DD1A21"),
                    PathData("M9 11H11V13H9V11ZM14 11H16V13H14V11Z", "black"),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData("M17 11V13H13V12H12V13H8V11H17Z", "#78BFEA"),
                    PathData(
                        "M8 10H17V11H8V10ZM8 13V11H6V12H7V13H8ZM12 13V14H8V13H12ZM13 13H12V12H13V13ZM17 13V14H13V13H17ZM17 13H18V12H19V11H17V13ZM14 15H11V16H14V15Z",
                        ""
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M17 10V11H19V12H18V13H17V14H13V13H12V14H8V13H7V12H6V11H8V10H17ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M18 10V11H19V12H18V13H17V14H14V13H13V12H12V13H11V14H8V13H7V12H6V11H7V10H8V9H11V10H12V11H13V10H14V9H17V10H18ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M19 10V11H18V12H17V13H14V12H11V13H8V12H7V11H6V10H19Z",
                        "#78BFEA"
                    ),
                    PathData(
                        "M19 9H6V10H5V11H6V12H7V13H8V14H11V13H14V14H17V13H18V12H19V11H20V10H19V9ZM19 10V11H18V12H17V13H14V12H11V13H8V12H7V11H6V10H19ZM14 15H11V16H14V15Z",
                        ""
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M19 10V9H6V10H5V11H6V12H7V13H8V14H11V13H14V14H17V13H18V12H19V11H20V10H19Z",
                        ""
                    ),
                    PathData("M14 15H11V16H14V15Z", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 8H11V9H9V8ZM9 10H8V9H9V10ZM11 11V10H9V11H8V13H9V14H11V15H10V16H15V15H14V14H16V13H17V11H16V10H17V9H16V8H14V9H16V10H14V11H11ZM11 13V14H14V13H16V11H14V13H13V12H12V13H11ZM11 13H9V11H11V13Z",
                        ""
                    ),
                    PathData("M9 11H11V13H9V11ZM14 11H16V13H14V11Z", "#F4F4F4"),
                    PathData("M13 13V12H12V13H11V14H14V13H13Z", "#FCC39E")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M7 14V10H18V14H13V12H12V14H7ZM8 13H11V11H8V13ZM14 13H17V11H14V13ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData("M11 11H8V13H11V11Z", "#00A3DA"),
                    PathData("M17 11H14V13H17V11Z", "#DD1A21")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 11H14V13H16V11ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 11H14V13H16V11ZM10 15H15V16H10V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 11H14V13H16V11ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 11H14V13H16V11ZM10 15H15V16H10V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 12H14V13H16V12ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 12H14V13H16V12ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 9H9V10H8V11H9V13H11V11H9V10H11V9ZM16 11H14V13H16V11ZM16 10H17V11H16V10ZM16 10H14V9H16V10ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 9H9V10H8V11H9V13H11V11H9V10H11V9ZM16 11H14V13H16V11ZM16 10H17V11H16V10ZM16 10H14V9H16V10ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 11H11V13H9V11ZM14 11H16V13H14V11ZM10 15H9V16H12V14H10V15ZM16 16H13V14H15V15H16V16Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 11H11V13H9V11ZM14 11H16V13H14V11ZM10 15H9V16H12V14H10V15ZM16 16H13V14H15V15H16V16Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 11H11V13H9V11ZM14 11H16V13H14V11ZM13 13H12V15H13V13ZM8 15V14H10V16H9V15H8ZM10 16H11V17H10V16ZM15 16H16V15H17V14H15V16ZM15 16V17H14V16H15ZM13 16H12V17H13V16Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData("M16 11H14V13H16V11Z", "#78BFEA"),
                    PathData(
                        "M16 10H14V11H13V13H14V14H16V13H17V11H16V10ZM16 11V13H14V11H16ZM11 11H9V13H11V11ZM14 15H11V14H10V15H11V16H14V15Z",
                        ""
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData("M16 11H14V13H16V11Z", "#78BFEA"),
                    PathData(
                        "M16 10H14V11H13V13H14V14H16V13H17V11H16V10ZM16 11V13H14V11H16ZM11 11H9V13H11V11ZM14 15H11V14H10V15H11V16H14V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    )
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 7H10V8H9V7ZM11 9H10V8H11V9ZM12 10H11V9H12V10ZM18 10H12V11H13V13H17V11H18V10ZM18 10H19V9H18V10ZM9 11V13H11V11H9ZM15 14H14V15H11V14H10V15H11V16H14V15H15V14Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 7H10V8H9V7ZM11 9H10V8H11V9ZM12 10H11V9H12V10ZM18 10H12V11H13V13H17V11H18V10ZM18 10H19V9H18V10ZM9 11V13H11V11H9ZM15 14H14V15H11V14H10V15H11V16H14V15H15V14Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 11H11V13H9V11ZM14 11H16V13H14V11ZM14 14H10V15H14V16H15V15H14V14Z",
                        ""
                    ),
                    PathData("M16 16H15V17H16V16Z", "#DD1A21"),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M17 10V11H18V12H17V13H14V12H13V11H12V12H11V13H8V12H7V11H8V10H17ZM10 14H11V15H10V14ZM14 15V16H11V15H14ZM14 15V14H15V15H14Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M17 10V11H18V12H17V13H14V12H13V11H12V12H11V13H8V12H7V11H8V10H17ZM10 14H11V15H10V14ZM14 15V16H11V15H14ZM14 15V14H15V15H14Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData("M9 11H11V13H9V11ZM14 11H16V13H14V11Z", "#78BFEA"),
                    PathData(
                        "M9 10H11V11H9V10ZM9 13H8V12H7V11H9V13ZM11 13V14H9V13H11ZM14 13H13V12H12V13H11V11H14V13ZM16 13H14V14H16V13ZM16 11H18V12H17V13H16V11ZM16 11H14V10H16V11ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData("M9 11H11V13H9V11ZM14 11H16V13H14V11Z", "#78BFEA"),
                    PathData(
                        "M9 10H11V11H9V10ZM9 13H8V12H7V11H9V13ZM11 13V14H9V13H11ZM14 13H13V12H12V13H11V11H14V13ZM16 13H14V14H16V13ZM16 11H18V12H17V13H16V11ZM16 11H14V10H16V11ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    )
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M16 10V11H18V12H17V13H16V14H14V13H13V12H12V13H11V14H9V13H8V12H7V11H9V10H11V11H14V10H16ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M16 10V11H18V12H17V13H16V14H14V13H13V12H12V13H11V14H9V13H8V12H7V11H9V10H11V11H14V10H16ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            )
        ];
        SVGComposition memory comp = svgData[slot];
        bytes memory svg = "";
        svg = abi.encodePacked(svg, pathDataToSVG(comp.paths[0]));
        svg = abi.encodePacked(svg, pathDataToSVG(comp.paths[1]));
        svg = abi.encodePacked(svg, pathDataToSVG(comp.paths[2]));
        return svg;
    }
}

// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";

// The main contract can extend this so that it can just get the constant value
// rather than having to call the datablock contract.
contract HeadwearImageDataSize {
    function getNumHeadwearValues() public pure returns (uint16) {
        // Returning constant instead of asking the data for its length saves gas
        return 45;
    }
}

contract HeadwearImageData {
    uint16 constant numHair = 45;
    uint16 constant numHats = 4 * 13;

    function random(bytes memory input) private pure returns (uint256) {
        return uint256(keccak256(input));
    }

    struct PathData {
        // d is the path for the svg path element, or empty meaning dont output a path
        string d;
        // fill is either a hex string or empty for black
        string fill;
    }

    function pathDataToSVG(string memory d, string memory fill)
        private
        pure
        returns (bytes memory)
    {
        if (bytes(d).length == 0) return bytes("");

        return
            abi.encodePacked(
                '<path fill-rule="evenodd" clip-rule="evenodd" d="',
                d,
                '" fill="',
                bytes(fill).length > 0 ? fill : "black",
                '" />'
            );
    }

    /** HAIR */

    function hairColorIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("haircolor", slot));
        return rand % 17;
    }

    function hairTypeIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("hairtype", slot));
        return rand % 5;
    }

    function getHairLabel(uint256 slot) private pure returns (string memory) {
        string[17] memory hairColors = [
            "Light Blue",
            "Bright Blue",
            "Light Grey",
            "Dark Grey",
            "White",
            "Light Pink",
            "Yellow Green",
            "Bright Green",
            "Light Nougat",
            "Nougat",
            "Light Brown",
            "Dark Brown",
            "Light Yellow",
            "Yellow",
            "Bright Yellow",
            "Bright Orange",
            "Bright Red"
        ];

        string[5] memory hairTypes = [
            "Short Hair",
            "Long Hair",
            "Wavy Hair",
            "Bowl Cut",
            "Puffy Hair"
        ];

        return
            string(
                abi.encodePacked(
                    hairColors[hairColorIndex(slot)],
                    " ",
                    hairTypes[hairTypeIndex(slot)]
                )
            );
    }

    function getHairSVG(uint256 slot) private pure returns (bytes memory) {
        string[5] memory outlinePaths = [
            /* Short Hair */
            "M17 2H8V3H6V4H5V6H4V8H3V13H4V14H5V13H6V10H7V9H16V8H18V10H19V13H20V14H21V13H22V8H21V6H20V4H19V3H17V2ZM17 3V4H19V6H20V8H21V13H20V10H19V8H18V7H16V8H7V9H6V10H5V13H4V8H5V6H6V4H8V3H17Z",
            /* Long hair */
            "M9 2H16V3H9V2ZM7 4V3H9V4H7ZM6 5V4H7V5H6ZM5 7V5H6V7H5ZM4 15V7H5V15H4ZM3 16V15H4V16H3ZM3 17H2V16H3V17ZM5 17V18H3V17H5ZM6 16V17H5V16H6ZM7 11V16H6V11H7ZM8 10V11H7V10H8ZM10 9V10H8V9H10ZM11 8V9H10V8H11ZM14 8H11V7H14V8ZM15 9H14V8H15V9ZM17 10H15V9H17V10ZM18 11H17V10H18V11ZM19 16H18V11H19V16ZM20 17V16H19V17H20ZM22 17V18H20V17H22ZM22 16H23V17H22V16ZM21 15H22V16H21V15ZM20 7H21V15H20V7ZM19 5H20V7H19V5ZM18 4H19V5H18V4ZM18 4V3H16V4H18Z",
            /* Wavy Hair */
            "M9 2H16V3H9V2ZM7 4V3H9V4H7ZM6 5V4H7V5H6ZM5 7V5H6V7H5ZM4 14V7H5V14H4ZM3 16H4V14H3V16ZM3 20V16H2V20H3ZM5 21H3V20H5V21ZM6 21V22H5V21H6ZM8 20V21H6V20H8ZM8 19H9V20H8V19ZM7 18H8V19H7V18ZM7 11V18H6V11H7ZM8 10V11H7V10H8ZM9 9V10H8V9H9ZM11 8V9H9V8H11ZM14 8H11V7H14V8ZM16 9H14V8H16V9ZM17 10H16V9H17V10ZM18 11H17V10H18V11ZM18 18V11H19V18H18ZM17 19V18H18V19H17ZM17 20H16V19H17V20ZM19 21H17V20H19V21ZM20 21V22H19V21H20ZM22 20V21H20V20H22ZM22 16H23V20H22V16ZM21 14H22V16H21V14ZM20 7H21V14H20V7ZM19 5H20V7H19V5ZM18 4H19V5H18V4ZM18 4V3H16V4H18Z",
            /* Bowl Cut */
            "M9 2H16V3H9V2ZM7 4V3H9V4H7ZM6 5V4H7V5H6ZM5 7H6V5H5V7ZM5 13V7H4V13H5ZM6 13V14H5V13H6ZM7 10V13H6V10H7ZM18 10H7V9H18V10ZM19 13H18V10H19V13ZM20 13V14H19V13H20ZM20 7H21V13H20V7ZM19 5H20V7H19V5ZM18 4H19V5H18V4ZM18 4V3H16V4H18Z",
            /* Puffy Hair */
            "M18 2H7V3H5V4H4V5H3V7H2V11H3V13H4V14H5V13H6V10H7V9H16V8H18V10H19V13H20V14H21V13H22V11H23V7H22V5H21V4H20V3H18V2ZM18 3V4H20V5H21V7H22V11H21V13H20V10H19V8H18V7H16V8H7V9H6V10H5V13H4V11H3V7H4V5H5V4H7V3H18Z"
        ];

        string[5] memory fillPaths = [
            /* Short Hair */
            "M20 8V6H19V4H17V3H8V4H6V6H5V8H4V13H5V10H6V9H7V8H16V7H18V8H19V10H20V13H21V8H20Z",
            /* Long hair */
            "M21 16V15H20V7H19V5H18V4H16V3H9V4H7V5H6V7H5V15H4V16H3V17H5V16H6V15V11H7V10H8V9H10V8H11V7H14V8H15V9H17V10H18V11H19V15V16H20V17H22V16H21Z",
            /* Wavy Hair */
            "M6 11V18H7V19H8V20H6V21H5V20H3V16H4V14H5V7H6V5H7V4H9V3H16V4H18V5H19V7H20V14H21V16H22V20H20V21H19V20H17V19H18V18H19V11H18V10H17V9H16V8H14V7H11V8H9V9H8V10H7V11H6Z",
            /* Bowl Cut */
            "M20 7V13H19V10H18V9H7V10H6V13H5V7H6V5H7V4H9V3H16V4H18V5H19V7H20Z",
            /* Puffy Hair */
            "M22 7V11H21V13H20V10H19V8H18V7H16V8H7V9H6V10H5V13H4V11H3V7H4V5H5V4H7V3H18V4H20V5H21V7H22Z"
        ];

        string[17] memory hairColors = [
            "#78BFEA",
            "#00A3DA",
            "#A0A19F",
            "#42423E",
            "#F4F4F4",
            "#F6ADCD",
            "#9ACA3C",
            "#00AF4D",
            "#FCC39E",
            "#DE8B5F",
            "#AF7446",
            "#692E14",
            "#FFF579",
            "#FEE716",
            "#FFCD03",
            "#F57D20",
            "#DD1A21"
        ];

        uint256 hairIndex = hairTypeIndex(slot);
        return
            abi.encodePacked(
                pathDataToSVG(outlinePaths[hairIndex], "black"),
                pathDataToSVG(
                    fillPaths[hairIndex],
                    hairColors[hairColorIndex(slot)]
                )
            );
    }

    /** HAT */
    function hatColorIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("hatcolor", slot));
        return rand % 12;
    }

    function hatTypeIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("hattype", slot));
        return rand % 5;
    }

    function getHatLabel(uint256 slot) private pure returns (string memory) {
        string[5] memory hatTypes = [
            "Cap",
            "Peaked Cap",
            "Hard Hat",
            "Bucket Hat",
            "Helmet"
        ];
        string[12] memory hatColors = [
            "Bright Blue",
            "Dark Blue",
            "Light Grey",
            "Medium Grey",
            "Dark Grey",
            "White",
            "Light Pink",
            "Deep Blush",
            "Bright Green",
            "Bright Yellow",
            "Bright Orange",
            "Bright Red"
        ];

        return
            string(
                abi.encodePacked(
                    hatColors[hatColorIndex(slot)],
                    " ",
                    hatTypes[hatTypeIndex(slot)]
                )
            );
    }

    function getHatSVG(uint256 slot) private pure returns (bytes memory) {
        string[5] memory outlinePaths = [
            /* Cap */
            "M9 2H16V3H9V2ZM7 4V3H9V4H7ZM6 5V4H7V5H6ZM5 7H6V5H5V7ZM5 9V7H4V9H5ZM23 9V10H5V9H23ZM23 8H24V9H23V8ZM20 7H23V8H20V7ZM19 5H20V7H19V5ZM18 4H19V5H18V4ZM18 4V3H16V4H18Z",
            /* Peaked Cap */
            "M3 2H22V3H3V2ZM3 5V3H2V5H3ZM5 6H3V5H5V6ZM20 6H5V7H4V9H5V10H20V9H21V7H20V6ZM22 5V6H20V5H22ZM22 5H23V3H22V5ZM20 7H5V9H20V7Z",
            /* Hard Hat */
            "M16 2H9V3H7V4H6V5H5V7H4V8H3V9H4V10H21V9H22V8H21V7H20V5H19V4H18V3H16V2ZM16 3V4H18V5H19V7H20V8H21V9H4V8H5V7H6V5H7V4H9V3H16Z",
            /* Bucket Hat */
            "M8 2H17V3H8V2ZM7 4V3H8V4H7ZM6 7V4H7V7H6ZM5 8V7H6V8H5ZM3 9H5V8H3V9ZM3 10V9H2V10H3ZM6 10V11H3V10H6ZM19 10H6V9H19V10ZM22 10V11H19V10H22ZM22 9H23V10H22V9ZM20 8H22V9H20V8ZM19 7H20V8H19V7ZM18 4H19V7H18V4ZM18 4V3H17V4H18Z",
            /* Helmet */
            "M8 3H17V4H8V3ZM7 5V4H8V5H7ZM6 6V5H7V6H6ZM5 8H6V6H5V8ZM5 19V8H4V19H5ZM6 20H5V19H6V20ZM19 20V21H6V20H19ZM20 19V20H19V19H20ZM20 8H21V19H20V8ZM19 6H20V8H19V6ZM18 5H19V6H18V5ZM18 5V4H17V5H18ZM18 10H19V17H18V10ZM7 10V9H18V10H7ZM7 17H6V10H7V17ZM7 17V18H18V17H7Z"
        ];

        string[5] memory fillPaths = [
            /* Cap */
            "M23 8V9H5V7H6V5H7V4H9V3H16V4H18V5H19V7H20V8H23Z",
            /* Peaked Cap */
            "M3 5V3H22V5H20V6H5V5H3ZM5 7H20V9H5V7Z",
            /* Hard Hat */
            "M21 8V9H4V8H5V7H6V5H7V4H9V3H16V4H18V5H19V7H20V8H21Z",
            /* Bucket Hat */
            "M22 9V10H19V9H6V10H3V9H5V8H6V7H7V4H8V3H17V4H18V7H19V8H20V9H22Z",
            /* Helmet */
            "M18 18V17H19V10H18V9H7V10H6V17H7V18H18ZM20 8V19H19V20H6V19H5V8H6V6H7V5H8V4H17V5H18V6H19V8H20Z"
        ];

        string[12] memory hatColors = [
            "#00A3DA",
            "#006CB7",
            "#A0A19F",
            "#646765",
            "#42423E",
            "#F4F4F4",
            "#F6ADCD",
            "#E95DA2",
            "#00AF4D",
            "#FFCD03",
            "#F57D20",
            "#DD1A21"
        ];

        uint256 hatIndex = hatTypeIndex(slot);
        return
            abi.encodePacked(
                pathDataToSVG(outlinePaths[hatIndex], "black"),
                pathDataToSVG(
                    fillPaths[hatIndex],
                    hatColors[hatColorIndex(slot)]
                )
            );
    }

    /** HELMET */

    function helmetStyleIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("helmet", slot));
        return rand % 17;
    }

    function getHelmetLabel(uint256 slot) private pure returns (string memory) {
        string[17] memory helmetLabels = [
            // Blue Visor
            "Bright Blue",
            "Light Grey ",
            "Dark Grey",
            "Bright Blue",
            "Light Pink",
            "Deep Blush",
            "White",
            "Bright Yellow",
            "Bright Red",
            "Bright Green",
            // Red Visor
            "White",
            "Bright Yellow",
            "Bright Blue",
            // Dark Visor
            "Bright Blue",
            "White",
            "Bright Red",
            "Bright Green"
        ];
        uint256 styleIndex = helmetStyleIndex(slot);
        string memory visorColor = "Blue";
        if (styleIndex > 12) {
            visorColor = "Dark";
        } else if (styleIndex > 9) {
            visorColor = "Red";
        }
        return
            string(
                abi.encodePacked(
                    helmetLabels[styleIndex],
                    " Helmet with ",
                    visorColor,
                    " Visor"
                )
            );
    }

    function getHelmetSVG(uint256 slot) private pure returns (bytes memory) {
        string
            memory outlinePath = "M17 3H8V4H7V5H6V6H5V8H4V9V10H3V18H4V19H5V20H6V21H19V20H20V19H21V18H22V10H21V9V8H20V6H19V5H18V4H17V3ZM17 4V5H18V6H19V8H20V9H5V8H6V6H7V5H8V4H17ZM20 15V14H21V10H19V15H20ZM18 16H20V15H21V18H20V19H19V20H6V19H5V18H4V15H5V16H7V17H9V18H16V17H18V16ZM18 16H16V17H9V16H7V10H18V16ZM5 15H6V10H4V14H5V15Z";
        string
            memory fill = "M19 8H20V9H5V8H6V6H7V5H8V4H17V5H18V6H19V8ZM4 14V10H6V15H5V14H4ZM20 15V16H18V17H16V18H9V17H7V16H5V15H4V18H5V19H6V20H19V19H20V18H21V15H20ZM20 15H19V10H21V14H20V15Z";
        string
            memory visor = "M21 10V14H20V15H18V16H16V17H9V16H7V15H5V14H4V10H21Z";
        string[17] memory colors = [
            "#00A3DA",
            "#A0A19F",
            "#42423E",
            "#F6ADCD",
            "#E95DA2",
            "#F4F4F4",
            "#FFCD03",
            "#DD1A21",
            "#00AF4D",
            "#F4F4F4",
            "#FFCD03",
            "#00A3DA",
            "#00A3DA",
            "#42423E",
            "#F4F4F4",
            "#DD1A21",
            "#00AF4D"
        ];

        uint256 styleIndex = helmetStyleIndex(slot);
        string memory visorColor = "#00A3DA7F"; // Transparent blue
        if (styleIndex > 12) {
            visorColor = "#42423E";
        } else if (styleIndex > 9) {
            visorColor = "#DD1A217F";
        }

        return
            abi.encodePacked(
                pathDataToSVG(outlinePath, "black"),
                pathDataToSVG(fill, colors[styleIndex]),
                pathDataToSVG(visor, visorColor)
            );
    }

    /** EXTRAS */

    function extrasStyleIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("extras", slot));
        return rand % 5;
    }

    function getExtrasSVG(uint256 slot) public pure returns (bytes memory) {
        string[5] memory extraSVGs = [
            // VR Helmet
            '<path d="M7 9H6V10H7V9Z" fill="#DD1A21"/>'
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M7 6H18V4H16V3H9V4H7V6ZM20 7H5V8H4V14H5V15H20V14H21V8H20V7ZM7 10V11H6V10H5V9H6V8H7V9H8V10H7Z" fill="#42423E"/>'
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M16 2H9V3H7V4H6V6H5V7H4V8H3V14H4V15H5V16H20V15H21V14H22V8H21V7H20V6H19V4H18V3H16V2ZM16 3V4H18V6H7V4H9V3H16ZM20 7V8H21V14H20V15H5V14H4V8H5V7H20ZM8 9H7V8H6V9H5V10H6V11H7V10H8V9ZM7 10H6V9H7V10Z" fill="black"/>',
            // Ghost
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M11 10V13H10V14H8V12H9V11H10V10H11ZM16 12H17V14H15V13H14V10H15V11H16V12ZM16 15V16H15V15H16ZM10 16H15V17H14V18H11V17H10V16ZM10 16V15H9V16H10ZM5 25H20V24H21V25H24V24H23V22H22V21H20V11H19V8H18V6H17V4H15V3H10V4H8V6H7V8H6V11H5V21H3V22H2V24H1V25H4V24H5V25ZM5 24H6V21H5V24ZM20 21H19V24H20V21Z" fill="#F4F4F4"/>'
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M15 2H10V3H8V4H7V6H6V8H5V11H4V20H3V21H2V22H1V24H0V25H1V24H2V22H3V21H5V24H4V25H5V24H6V21H5V11H6V8H7V6H8V4H10V3H15V4H17V6H18V8H19V11H20V21H19V24H20V25H21V24H20V21H22V22H23V24H24V25H25V24H24V22H23V21H22V20H21V11H20V8H19V6H18V4H17V3H15V2ZM16 15H15V16H10V15H9V16H10V17H11V18H14V17H15V16H16V15ZM15 11H16V12H17V14H15V13H14V10H15V11ZM10 13H11V10H10V11H9V12H8V14H10V13Z" fill="black"/>',
            // Pumpkin
            '<path d="M19 11H18V10H17V9H16V10H15V11H14V12H16V13H17V12H19V11ZM18 7V8H19V9H20V8H19V7H18V6H17V7H18ZM18 18V17H19V16H20V14H19V16H18V17H17V18H18ZM13 10V7H12V10H13ZM14 13H13V12H12V13H11V14H14V13ZM7 10V11H6V12H8V13H9V12H11V11H10V10H9V9H8V10H7ZM7 6V7H6V8H5V9H6V8H7V7H8V6H7ZM8 18V17H7V16H6V14H5V16H6V17H7V18H8ZM8 15V16H9V17H10V18H11V17H12V18H13V17H14V18H15V17H16V16H17V15H15V16H14V15H11V16H10V15H8ZM4 15H3V9H4V7H5V6H6V5H8V4H11V5H12V6H13V5H14V4H17V5H19V6H20V7H21V9H22V15H21V17H20V18H19V19H18V20H7V19H6V18H5V17H4V15Z" fill="#F57D20"/>'
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M12 1H13V2H12V1ZM12 5V2H11V3H8V4H6V5H5V6H4V7H3V9H2V15H3V17H4V18H5V19H6V20H7V21H18V20H19V19H20V18H21V17H22V15H23V9H22V7H21V6H20V5H19V4H17V3H14V2H13V5H12ZM12 5V6H13V5H14V4H17V5H19V6H20V7H21V9H22V15H21V17H20V18H19V19H18V20H7V19H6V18H5V17H4V15H3V9H4V7H5V6H6V5H8V4H11V5H12ZM20 8H19V7H18V6H17V7H18V8H19V9H20V8ZM19 14H20V16H19V14ZM18 17V16H19V17H18ZM18 17V18H17V17H18ZM17 13H16V12H14V11H15V10H16V9H17V10H18V11H19V12H17V13ZM13 7H12V10H13V7ZM11 14H14V13H13V12H12V13H11V14ZM15 16V15H17V16H16V17H15V18H14V17H13V18H12V17H11V18H10V17H9V16H8V15H10V16H11V15H14V16H15ZM8 6H7V7H6V8H5V9H6V8H7V7H8V6ZM8 10H7V11H6V12H8V13H9V12H11V11H10V10H9V9H8V10ZM7 17H8V18H7V17ZM6 16H7V17H6V16ZM6 16V14H5V16H6Z" fill="black"/>'
            '<path d="M13 2H12V5H13V2Z" fill="#692E14"/>',
            // Fishbowl
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M6 3H19V4H6V3ZM14 10V9H15V10H14ZM14 7V8H13V7H14ZM15 7V6H16V7H15ZM12 16V17H11V16H10H9V15H8V16H7V15H6V14H7V13H6V12H7V11H8V12H9V11H10V10H11V9H12V10H13V11H14V12H15V13V14H14V15H13V16H12ZM4 15V17H5V18H6V19H7V20H18V19H19V18H20V17H21V15H22V9H21V7H20V6H19V5H6V6H5V7H4V9H3V15H4Z" fill="#78BFEA"/>'
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M13 12V13H12V12H13ZM8 14H9V15H10H11V16H12V15H13V14H14V13V12H13V11H12V10H11V11H10V12H9V13H8V12H7V13H8V14ZM8 14V15H7V14H8Z" fill="#F57D20"/>'
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M6 2H19V3H6V2ZM6 4H5V3H6V4ZM19 4H6V5H5V6H4V7H3V9H2V15H3V17H4V18H5V19H6V20H7V21H18V20H19V19H20V18H21V17H22V15H23V9H22V7H21V6H20V5H19V4ZM19 4H20V3H19V4ZM19 5V6H20V7H21V9H22V15H21V17H20V18H19V19H18V20H7V19H6V18H5V17H4V15H3V9H4V7H5V6H6V5H19ZM16 6H15V7H16V6ZM14 9H15V10H14V9ZM14 13V14H13V15H12V16H11V15H10H9V14H8V13H9V12H10V11H11V10H12V11H13V12H12V13H13V12H14V13ZM14 12V11H13V10H12V9H11V10H10V11H9V12H8V11H7V12H6V13H7V14H6V15H7V16H8V15H9V16H10H11V17H12V16H13V15H14V14H15V13V12H14ZM8 15H7V14H8V15ZM7 13V12H8V13H7ZM14 7H13V8H14V7Z" fill="black"/>',
            // Chef Hat
            '<path d="M22 5V7H20V9H5V7H3V5H4V4H6V3H9V2H16V3H19V4H21V5H22Z" fill="#F4F4F4"/>'
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M16 1H9V2H6V3H4V4H3V5H2V7H3V8H4V9H5V10H20V9H21V8H22V7H23V5H22V4H21V3H19V2H16V1ZM16 2V3H19V4H21V5H22V7H20V9H5V7H3V5H4V4H6V3H9V2H16Z" fill="black"/>'
        ];
        return bytes(extraSVGs[extrasStyleIndex(slot)]);
    }

    function getExtrasLabel(uint256 slot) private pure returns (string memory) {
        string[5] memory labels = [
            "VR Helmet",
            "Ghost",
            "Pumpkin",
            "Fish Bowl",
            "Chef Hat"
        ];
        return labels[extrasStyleIndex(slot)];
    }

    string constant RAND_SEED = "hwlabel";

    function typeOffset(uint256 slot) private pure returns (uint256) {
        return random(abi.encodePacked(RAND_SEED, slot)) % 100;
    }

    function getData(uint256 slot) public pure returns (bytes memory) {
        uint256 section = typeOffset(slot);
        if (section < 1) {
            return getExtrasSVG(slot);
        } else if (section < 30) {
            return getHairSVG(slot);
        } else if (section < 80) {
            return getHatSVG(slot);
        } else if (section < 90) {
            return getHelmetSVG(slot);
        } else {
            return bytes("");
        }
    }

    function getLabel(uint256 slot) public pure returns (string memory) {
        uint256 section = typeOffset(slot);
        if (section < 1) {
            // 1% get extras
            return getExtrasLabel(slot);
        } else if (section < 30) {
            // 29% get hair
            return getHairLabel(slot);
        } else if (section < 60) {
            // 30% get hats
            return getHatLabel(slot);
        } else if (section < 70) {
            // 10% get helmets
            return getHelmetLabel(slot);
        } else {
            // 30% get none
            return "None";
        }
    }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Initializable } from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}