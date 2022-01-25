pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./NFTImage.sol";
import "./Utils.sol";
import "./PlexSubset.sol";
import "./PlexSansLatin.sol";
import "./ContractInfo.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import 'base64-sol/base64.sol';

contract ForeverMessage is ERC721, IERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    
    /**
        There are two kinds of Forever Messages, Basic and Fancy. Fancy are ERC-721 NFTs with "fancyIDs"
        (aka tokenIds) and Basic messages exist only in logs, both have unique messageIds in the same
        id-space.
    
        These counters are one-indexed so that we can interpret a message replying to messageId 0
        as a mesage replying to no message and a message that has a fancyMessageId of 0 as not being
        a fancy message.
        
        Plus it's always kind of fun to use one-indexed arrays because this is how we naturally count!
    */
    
    Counters.Counter public oneIndexedFancyMessageIdCounter;
    Counters.Counter public oneIndexedTotalMessageIdCounter;
    
    constructor() ERC721(ContractInfo.name, ContractInfo.symbol) {
        oneIndexedFancyMessageIdCounter.increment();
        oneIndexedTotalMessageIdCounter.increment();
    }
    
    struct FancyMessage {
        // It would be nice to have 11 gradient steps because then you could do 0%, 10%, 20%, etc.
        // However 11 24-bit numbers is 33 bytes which would make this take two words.
        // The purpose of having these stops is to give the user more fine-grained control over what
        // gradients look like because the default browser way of rendering gradients in 2022 is to
        // use the rgb color space which no serious gradient person will tell you is a good idea.
        uint24[10] gradientColors;
        bool isRadialGradient;
        uint24 textColor;
        uint8 fontSize;
        uint16 linearGradientAngleDeg;
        address sender;
        address recipient;
        string text;
        uint256 sentAt;
        uint256 messageId;
        uint256 inReplyToMessageId;
    }
    
    event CreateMessage(
        string text,
        uint24 textColor,
        bool isRadialGradient,
        uint8 fontSize,
        uint16 linearGradientAngleDeg,
        uint24[10] gradientColors,
        uint indexed messageId,
        uint inReplyToMessageId,
        address indexed sender,
        address recipient,
        uint sentAt,
        
        // All message creations emit this event. You can tell which are Fancy and which are Basic
        // based on whether this field is greater than 0.
        uint indexed fancyMessageId
    );
    
    // Arbitrary 10kb limit. Always good to use the "real" kilobyte definition of 1024 for cred.
    uint16 public constant fancyMessageMaxTextLengthBytes = 2 ** 10 * 10;
    uint16 public constant basicMessageMaxTextLengthBytes = fancyMessageMaxTextLengthBytes / 2;
    
    mapping(uint => FancyMessage) public messageIdToFancyMessageMapping;
    mapping(uint => uint) public fancyMessageIdToTotalMessageIdMapping;
    
    // I made the mapping public because why not but you also need a getter when a struct
    // has internal data structures like arrays
    function getFancyMessageFromMessageId(uint messageId) public view returns (FancyMessage memory) {
        require(_exists(messageId), "doesn't exist");
        return messageIdToFancyMessageMapping[messageId];
    }
    
    function getFancyMessageFromFancyMessageId(uint fancyMessageId) public view returns (FancyMessage memory) {
        uint messageId = fancyMessageIdToTotalMessageIdMapping[fancyMessageId];
        return getFancyMessageFromMessageId(messageId);
    }
    
    function createBasicMessage(string memory text, address recipient, uint inReplyToMessageId) public returns (uint) {
        bytes memory textBytes = bytes(text);
        require(textBytes.length > 0 && textBytes.length <= basicMessageMaxTextLengthBytes, "Invalid message text");
        
        uint messageId = oneIndexedTotalMessageIdCounter.current();
        oneIndexedTotalMessageIdCounter.increment();
        
        require(inReplyToMessageId == 0 || inReplyToMessageId < messageId, "Invalid inReplyToMessageId");
        
        uint24[10] memory emptyColorSteps;
        
        // Log with default values for fields that don't apply to Basic Messages like colors etc.
        logMessageCreation(
            text,
            0,
            false,
            16,
            45,
            emptyColorSteps,
            messageId,
            inReplyToMessageId,
            msg.sender,
            recipient,
            block.timestamp,
            0
        );
        
        return messageId;
    }
    
    // This makes it so any transaction you send will create a basic method with your
    // calldata. It's nice to be able to communicate with just the contract address
    // if necessary
    fallback (bytes calldata _inputText) external returns (bytes memory _output) {
        createBasicMessage(string(_inputText), address(0), 0);
    }
    
    function getFancyMessagePrice(string calldata text) public pure returns (uint) {
        return 21600 gwei * bytes(text).length + 8758200 gwei;
    }
    
    function createFancyMessage(string calldata text,
                      uint24 textColor,
                      bool isRadialGradient,
                      uint8 fontSize,
                      uint16 linearGradientAngleDeg,
                      uint24[10] calldata gradientColors,
                      address recipient,
                      uint inReplyToMessageId
    ) external payable returns (uint) {
        require(msg.value == getFancyMessagePrice(text), "Wrong price");
        
        bytes memory textBytes = bytes(text);
        require(textBytes.length > 0 && 
               textBytes.length <= fancyMessageMaxTextLengthBytes,
               "Invalid message text");
        
        uint messageId = oneIndexedTotalMessageIdCounter.current();
        oneIndexedTotalMessageIdCounter.increment();
        
        require(inReplyToMessageId == 0 || inReplyToMessageId < messageId, "Invalid inReplyToMessageId");
        
        uint fancyMessageId = oneIndexedFancyMessageIdCounter.current();
        oneIndexedFancyMessageIdCounter.increment();
        
        FancyMessage memory newFancyMessage = FancyMessage({
            messageId: messageId,
            text: text,
            textColor: textColor,
            fontSize: fontSize,
            isRadialGradient: isRadialGradient,
            linearGradientAngleDeg: linearGradientAngleDeg,
            gradientColors: gradientColors,
            sentAt: block.timestamp,
            sender: msg.sender,
            recipient: recipient,
            inReplyToMessageId: inReplyToMessageId
        });
        
        messageIdToFancyMessageMapping[messageId] = newFancyMessage;
        
        fancyMessageIdToTotalMessageIdMapping[fancyMessageId] = messageId;
        
        // Should this be _mint() or _safeMint()! You could Google for a million years and still
        // not know the answer to this...
        _mint(msg.sender, messageId);
        
        // I thought it would use less gas to take the function parameters and pass them on to this
        // other function but actually it's cheaper to pull them off the struct.
        logMessageCreation(
            newFancyMessage.text,
            newFancyMessage.textColor,
            newFancyMessage.isRadialGradient,
            newFancyMessage.fontSize,
            newFancyMessage.linearGradientAngleDeg,
            newFancyMessage.gradientColors,
            newFancyMessage.messageId,
            newFancyMessage.inReplyToMessageId,
            newFancyMessage.sender,
            newFancyMessage.recipient,
            newFancyMessage.sentAt,
            fancyMessageId
        );
        
        return messageId;
    }
    
    function logMessageCreation(
        string memory text,
        uint24 textColor,
        bool isRadialGradient,
        uint8 fontSize,
        uint16 linearGradientAngleDeg,
        uint24[10] memory gradientColors,
        uint messageId,
        uint inReplyToMessageId,
        address sender,
        address recipient,
        uint sentAt,
        uint fancyMessageId) internal {
        emit CreateMessage(
            text,
            textColor,
            isRadialGradient,
            fontSize,
            linearGradientAngleDeg,
            gradientColors,
            messageId,
            inReplyToMessageId,
            sender,
            recipient,
            sentAt,
            fancyMessageId
        );
    }
    
    // Here and below I'm implementing more gas-efficient versions of the ERC721Enumerable
    // functions. The OZ implementation of ERC721Enumerable costs minters a lot to build a
    // few specific data structures that make it easy for enumerators. I borrowed these ideas from
    // https://github.com/chiru-labs/ERC721A/blob/main/ERC721A.sol
    function totalSupply() public view override returns (uint256) {
        return oneIndexedFancyMessageIdCounter.current() - 1;
    }
    
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), "Out of bounds");
        
        return fancyMessageIdToTotalMessageIdMapping[index + 1];
    }
    
      /**
    Adapted from https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol. Their comments:
   * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
        uint256 numFancyMessages = totalSupply();
        uint256 tokenIdsIdx = 0;
        
        for (uint256 fancyMessageId = 1; fancyMessageId <= numFancyMessages; fancyMessageId++) {
            uint messageId = fancyMessageIdToTotalMessageIdMapping[fancyMessageId];
            
            if (_exists(messageId) && owner == ownerOf(messageId)) {
                if (tokenIdsIdx == index) {
                    return messageId;
                }
                tokenIdsIdx++;
            }
        }
        
        revert("ERC721A: unable to get token of owner by index");
    }
    
    // If you're anything like I am, when you're reading one of these contracts what you are
    // thinking the whole time is "get to the part where it generates the on-chain SVG!"
    // Here is the start! The rest is in the other file. Good to have optional width in here
    // for flexibility
    function tokenImage(uint messageId, uint16 imageWidth) public view returns (string memory) {
        require(_exists(messageId), "doesn't exist");
        require(imageWidth > 0 && imageWidth < 20_000, "Invalid imageWidth");
        FancyMessage memory fancyMessage = messageIdToFancyMessageMapping[messageId];
        
        string memory height = Strings.toString(imageWidth * 5 / 4);
        string memory width = Strings.toString(imageWidth);
        
        string[2] memory widthAndHeight = [width, height];
        string[2] memory messageIdandText = [Strings.toString(messageId), fancyMessage.text];
        
        return NFTImage.tokenImage(
            messageIdandText,
            fancyMessage.textColor,
            fancyMessage.isRadialGradient,
            fancyMessage.fontSize,
            fancyMessage.linearGradientAngleDeg,
            fancyMessage.gradientColors,
            fancyMessage.sentAt,
            Utils.addressToString(fancyMessage.sender),
            widthAndHeight
        );
    }
    
    // Good to pass all of this stuff around as arrays to avoid stack depth issues
    function tokenURI(uint256 messageId) public view override(ERC721) returns (string memory) {
        require(_exists(messageId), "doesn't exist");
        
        FancyMessage memory fancyMessage = messageIdToFancyMessageMapping[messageId];
        
        string[12] memory tokenAttributes = [
            ContractInfo.tokenName(messageId),
            ContractInfo.tokenDescription(messageId),
            tokenImage(messageId, 1200),
            ContractInfo.tokenExternalURL(messageId),
            Utils.addressToString(fancyMessage.sender),
            string(abi.encodePacked("#", Utils.toHexColor(fancyMessage.textColor))),
            Strings.toString(bytes(fancyMessage.text).length),
            string(abi.encodePacked("#", Utils.toHexColor(fancyMessage.gradientColors[0]))),
            string(abi.encodePacked("#", Utils.toHexColor(fancyMessage.gradientColors[1]))),
            Strings.toString(fancyMessage.sentAt),
            Utils.hashText(fancyMessage.text),
            Strings.toString(fancyMessageMaxTextLengthBytes)
        ];
        
        return ContractInfo.generateTokenURI(tokenAttributes);
    }
    
    function contractImage() public pure returns (string memory) {
        string[2] memory messageIdandText = ["0", "\n\n   Forever\n   Message"];
        uint24[10] memory gradientColors = [3618925, 5323636, 6962805, 8471152,
                                            9914469, 11096406, 11951683, 12414765,
                                            12419859, 11835667];
                                            
        return NFTImage.tokenImage(
            messageIdandText,
            2 ** 24 - 1,
            false,
            60,
            0,
            gradientColors,
            1642983107,
            "middlemarch.eth",
            ["1200", "1500"]
        );
    }
    
    function contractURI() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', ContractInfo.name, '",'
                                '"description":"', ContractInfo.contractDescription(), '",'
                                '"image":"', contractImage(), '",'
                                '"external_link":"', ContractInfo.contractExternalURL(), '"'
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Address: insufficient balance");
        
        // Ah yes, the super-weird idiom for doing the most important thing!
        // When I first saw this I definitely said "huh?" and I can't be the only one
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    // Inspired by 0xacd3cf818efe8ddce84c585ddcb147c4c844d3b3
    function tributeToMySweetCat() external pure returns (string memory) {
        return unicode'Sky Masterson\n2019–2021\n\nYou were a sweet cat with a gentle soul and you were my friend. I will never forget you.\n\nYour buddy,\nT';
    }
}

pragma solidity >=0.8.0 <0.9.0;

import 'base64-sol/base64.sol';
import "./Utils.sol";
import "./PlexSansLatin.sol";
import "./PlexSubset.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library NFTImage {
    // For the UGC aspect we have available all the Latin characters. For the other two fonts
    // I extracted only the characters I needed with a tool called subfont. The declarations
    // should use unique font names because you can't be sure that what you say in SVGs "stays
    // in SVGs"
    function fontDeclarations() public pure returns (string memory) {
        string memory plexSans = PlexSansLatin.getIBMPlexSansLatin();
        string memory plexMono = PlexSubset.getIBMPlexMonoSubset();
        string memory plexSansCondensed = PlexSubset.getIBMPlexSansCondensedSubset();
        
        string memory plexSansUnicodeRange = PlexSansLatin.getIBMPlexSansLatinUnicodeRange();
        string memory plexMonoUnicodeRange = PlexSubset.getIBMPlexMonoSubsetUnicodeRange();
        string memory plexSansCondensedUnicodeRange = PlexSubset.getIBMPlexSansCondensedSubsetUnicodeRange();
        
        bytes memory plexSansDeclaration = abi.encodePacked(
            "@font-face{font-family:'IBM Plex Sans_ww4az6WSyhEj3oM7';src:url(",
            plexSans,
            ") format('woff2');unicode-range:",
            plexSansUnicodeRange,
            ";}"
        );
        
        bytes memory plexMonoDeclaration = abi.encodePacked(
            "@font-face{font-family:'IBM Plex Mono_ww4az6WSyhEj3oM7';src:url(",
            plexMono,
            ") format('woff2');unicode-range:",
            plexMonoUnicodeRange,
            ";}"
        );
        
        bytes memory plexSansCondensedDeclaration = abi.encodePacked(
            "@font-face{font-family:'IBM Plex Sans Condensed_ww4az6WSyhEj3oM7';src:url(",
            plexSansCondensed,
            ") format('woff2');unicode-range:",
            plexSansCondensedUnicodeRange,
            ";}"
        );
        
        return string(abi.encodePacked(plexSansDeclaration, plexMonoDeclaration, plexSansCondensedDeclaration));
    }
    
    function sansFontStack() public pure returns (string memory) {
        return 'font-family:"IBM Plex Sans_ww4az6WSyhEj3oM7","Helvetica Neue",Arial,sans-serif;';
    }
    
    function monoFontStack() public pure returns (string memory) {
        return 'font-family:"IBM Plex Mono_ww4az6WSyhEj3oM7","Menlo","DejaVu Sans Mono","Bitstream Vera Sans Mono",Courier,monospace;';
    }
    
    function sansCondensedFontStack() public pure returns (string memory) {
        return 'font-family:"IBM Plex Sans Condensed_ww4az6WSyhEj3oM7","Helvetica Neue",Arial,sans-serif;';
    }
    
    function normalizedFontSize(uint8 fs) internal pure returns (uint8) {
        if (
               fs == 14
            || fs == 20
            || fs == 24
            || fs == 28
            || fs == 32
            || fs == 42
            || fs == 60
            || fs == 76
            || fs == 92
         ) {
            return fs;
        } else {
            return 16;
        }
    }
    
    // If you want to you can play around with line heights for a very long time, it turns out
    function buildLineHeight(uint8 fontSize) internal pure returns (string memory) {
        uint8 fs = normalizedFontSize(fontSize);
        
        if (fs == 14) {
            return "1.429";
        } else if (fs == 16) {
            return "1.5";
        } else if (fs == 20) {
            return "1.4";
        } else if (fs == 24) {
            return "1.3";
        } else if (fs == 28) {
            return "1.275";
        } else if (fs == 32) {
            return "1.25";
        } else if (fs == 42) {
            return "1.2";
        } else if (fs == 60) {
            return "1.15";
        } else if (fs == 76) {
            return "1.13";
        } else if (fs == 92) {
            return "1.1";
        } else {
            return "1.5";
        }
    }
    
    function buildFontMetrics(uint8 fontSize) internal pure returns (bytes memory) {
        string memory nfs = Strings.toString(normalizedFontSize(fontSize));
        string memory lineHeight = buildLineHeight(fontSize);
        
        bytes memory output = abi.encodePacked(
            "font-size:", nfs,
            "px;line-height:", lineHeight,
            ";"
        );
        
        if (fontSize == 14) {
            output = abi.encodePacked(output, "letter-spacing:.16px;");
        }
        
        return output;
    }
    
    // You can't get 11.111111% from 100 / 9 in Solidity so we do the calculation in CSS
    // Probably could have just hard coded the string...
    function buildGradientColorStepBytes(uint24[10] memory gradientColors) internal pure returns (bytes memory) {
        bytes memory colorSteps;
        
        for (uint8 i = 0; i < gradientColors.length; i++) {
            if (i > 0) {
                colorSteps = abi.encodePacked(colorSteps, ", ");
            }
            
            colorSteps = abi.encodePacked(
                colorSteps,
                "#",
                Utils.toHexColor(gradientColors[i]),
                " ",
                abi.encodePacked("calc(", Strings.toString(i), "*100%/", Strings.toString(gradientColors.length - 1), ")")
            );
        }
        
        return colorSteps;
    }
    
    function buildGradientString(
      bool isRadialGradient,
      uint16 linearGradientAngleDeg,
      uint24[10] memory gradientColors
    ) internal pure returns (bytes memory) {
        bytes memory colorStepString = buildGradientColorStepBytes(gradientColors);
        
        if (isRadialGradient) {
            return abi.encodePacked(
                "radial-gradient(at 50% 100%, ", colorStepString, ")"
            );
        } else {
            return abi.encodePacked(
                "linear-gradient(",
                Strings.toString(linearGradientAngleDeg),
                "deg, ",
                colorStepString,
                ")"
            );
        }
    }
    
    // Ok finally! The image! There are a few key points here.
    // First, the foundation of this approach is the <foreignObject> tag. This element gives you the
    // ability to use arbitrary HTML in an SVG which is essential for a project like this because
    // HTML has built-in line wrapping and you need line wrapping if you're going to put user input
    // into a box and have it look reasonable.
    //
    // foreignObject is not without quirks, however. The biggest issue is that when you use an SVG
    // with a foreignObject as an <img> src you cannot resize the image correctly in Safari (it will crop).
    // This almost sunk the project until, after a very long time of trying random things, I stumbled on
    // a random thing that worked!
    //
    // You take the SVG containing the foreignObject, you base64 it, you create *another* SVG with an <image>
    // element. You put the first SVG as the href of the <image> element. Then you base64 *that* SVG
    // (the second one) and use that base64 value as the src on your HTML <img> tag! This is
    // wasteful as each base64 increases the file size by a factor of 4/3, but I promise I couldn't
    // find another way to do it!
    function tokenImage(
      string[2] memory messageIdandText,
      uint24 textColor,
      bool isRadialGradient,
      uint8 fontSize,
      uint16 linearGradientAngleDeg,
      uint24[10] memory gradientColors,
      uint mintedAt,
      string memory minter,
      string[2] memory widthAndHeight
    ) internal pure returns (string memory) {
        string[14] memory parts;
        
        parts[0] = string(buildGradientString(
            isRadialGradient,
            linearGradientAngleDeg,
            gradientColors
        ));
        
        parts[1] = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 487.5' class='x3fvufWE1e3H1xpo'><foreignObject x='0' y='0' width='390' height='487.5'><div style='background:";
        
        parts[2] = ";color:#";
        
        parts[3] = string(abi.encodePacked(";position:absolute;top:0;left:0;width:100%;height:100%;display:flex;flex-direction:column' xmlns='http://www.w3.org/1999/xhtml'><style>",
        
        fontDeclarations(),
        
        // That's right, I'm pro -webkit-font-smoothing:antialiased! Sorry haters! Also note that I'm
        // using white-space: pre-wrap here in order to preserve the user's formatting. This is what
        // textareas do for whitespace so the message will look like the input. This is important because
        // converting user-input to actual HTML with <p> tags and everything is not feasible in Solidity
        "svg.x3fvufWE1e3H1xpo,svg.x3fvufWE1e3H1xpo *{", monoFontStack(), "box-sizing:border-box;margin:0;padding:0;border:0;-webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility;overflow-wrap:break-word}</style><div style='", buildFontMetrics(fontSize), sansFontStack(), "flex:1;padding:16px;white-space:pre-wrap;overflow:hidden'>"));
        
        parts[4] = string(abi.encodePacked("</div><div style='white-space:pre;background:rgba(0,0,0,.5);color:#fff;padding:16px;font-size:12px;line-height:calc(4/3);display:flex;flex-direction:column'><div style='", sansCondensedFontStack(), "letter-spacing:1.25px;font-weight:500;margin-bottom:8px'>FOREVER MSG #"));
        
        parts[5] = "</div><div>from   ";
        
        parts[6] = "\ndate   ";
        
        parts[7] = "</div></div></div></foreignObject></svg>";
        
        parts[8] = Base64.encode(abi.encodePacked(
            abi.encodePacked(parts[1], parts[0]),
            abi.encodePacked(parts[2], Utils.toHexColor(textColor)),
            abi.encodePacked(parts[3], Utils.escapeHTML(messageIdandText[1])),
            abi.encodePacked(parts[4], messageIdandText[0]),
            abi.encodePacked(parts[5], minter),
            abi.encodePacked(parts[6], Utils.timestampToString(mintedAt)),
            parts[7]
        ));
        
        parts[9] = string(abi.encodePacked("<svg viewBox='0 0 390 487.5' width='", widthAndHeight[0], "' height='", widthAndHeight[1], "' xmlns='http://www.w3.org/2000/svg'><image width='100%' height='100%' href='data:image/svg+xml;base64,"));
        parts[10] = "' /></svg>";
        
        parts[11] = Base64.encode(abi.encodePacked(
            parts[9],
            parts[8],
            parts[10]
        ));
        
        return string(abi.encodePacked("data:image/svg+xml;base64,", parts[11]));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import 'base64-sol/base64.sol';
import "./BokkyPooBahsDateTimeLibrary.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library Utils {
    bytes16 internal constant ALPHABET = '0123456789abcdef';
    
    function timestampToString(uint timestamp) internal pure returns (string memory) {
        (uint year, uint month, uint day, uint hour, uint minute, uint second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
        
        return string(abi.encodePacked(
          Strings.toString(year), "-",
          zeroPadTwoDigits(month), "-",
          zeroPadTwoDigits(day)
        ));
    }
    
    function zeroPadTwoDigits(uint number) internal pure returns (string memory) {
        string memory numberString = Strings.toString(number);
        
        if (bytes(numberString).length < 2) {
            numberString = string(abi.encodePacked("0", numberString));
        }
        
        return numberString;
    }
    
    function addressToString(address addr)
        internal
        pure
        returns (string memory)
    {
        return Strings.toHexString(uint160(addr), 20);
    }
    
    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
    
    function toHexColor(uint24 value) internal pure returns (string memory) {
      return toHexStringNoPrefix(value, 3);
    }
    
    // You don't see a lot of HTML escaping in smart contracts these days, and for good reason!
    // This approach is adapted from the escapeQuotes() method in Uniswap's NFTDescriptor.sol
    // https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/NFTDescriptor.sol#L85
    //
    // The conceptually-simpler version would be to go through the input string one time and
    // abi.encodePacked() each byte or escape sequence on to the output. This approach
    // is more complicated for the computer though and isn't so great with long strings.
    //
    // Notably I am not escaping quotes. Based on my understanding you only need to escape quotes
    // if the input string might be used in an HTML attribute, but still this is a dice roll.
    // HTML is kind of a beautiful format for how simple it is to escape! Just (if I'm right) three
    // special characters to worry about. Compare this to JSON where you have to worry about
    // escaping, for example, the iconic bell character (U+0007)
    //
    // However this does not make HTML easier to write by hand because you have to remember
    // that " & " is not valid! If you write an amperstand you have to follow through
    // with the escape sequence or you risk your thing breaking in a weird way eventually.
    function escapeHTML(string memory input)
        internal
        pure
        returns (string memory)
    {
        bytes memory inputBytes = bytes(input);
        uint extraCharsNeeded = 0;
        
        for (uint i = 0; i < inputBytes.length; i++) {
            bytes1 currentByte = inputBytes[i];
            
            if (currentByte == "&") {
                extraCharsNeeded += 4;
            } else if (currentByte == "<") {
                extraCharsNeeded += 3;
            } else if (currentByte == ">") {
                extraCharsNeeded += 3;
            }
        }
        
        if (extraCharsNeeded > 0) {
            bytes memory escapedBytes = new bytes(
                inputBytes.length + extraCharsNeeded
            );
            
            uint256 index;
            
            for (uint i = 0; i < inputBytes.length; i++) {
                if (inputBytes[i] == "&") {
                    escapedBytes[index++] = "&";
                    escapedBytes[index++] = "a";
                    escapedBytes[index++] = "m";
                    escapedBytes[index++] = "p";
                    escapedBytes[index++] = ";";
                } else if (inputBytes[i] == "<") {
                    escapedBytes[index++] = "&";
                    escapedBytes[index++] = "l";
                    escapedBytes[index++] = "t";
                    escapedBytes[index++] = ";";
                } else if (inputBytes[i] == ">") {
                    escapedBytes[index++] = "&";
                    escapedBytes[index++] = "g";
                    escapedBytes[index++] = "t";
                    escapedBytes[index++] = ";";
                } else {
                    escapedBytes[index++] = inputBytes[i];
                }
            }
            return string(escapedBytes);
        }
        
        return input;
    }
    
    function hashText(string memory text) public pure returns (string memory) {
        return Strings.toHexString(uint256(keccak256(bytes(text))), 32);
    }
}

// Copyright © 2017 IBM Corp. with Reserved Font Name "Plex"

// This Font Software is licensed under the SIL Open Font License, Version 1.1.

// This license is copied below, and is also available with a FAQ at: http://scripts.sil.org/OFL


// -----------------------------------------------------------
// SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
// -----------------------------------------------------------

// PREAMBLE
// The goals of the Open Font License (OFL) are to stimulate worldwide
// development of collaborative font projects, to support the font creation
// efforts of academic and linguistic communities, and to provide a free and
// open framework in which fonts may be shared and improved in partnership
// with others.

// The OFL allows the licensed fonts to be used, studied, modified and
// redistributed freely as long as they are not sold by themselves. The
// fonts, including any derivative works, can be bundled, embedded, 
// redistributed and/or sold with any software provided that any reserved
// names are not used by derivative works. The fonts and derivatives,
// however, cannot be released under any other type of license. The
// requirement for fonts to remain under this license does not apply
// to any document created using the fonts or their derivatives.

// DEFINITIONS
// "Font Software" refers to the set of files released by the Copyright
// Holder(s) under this license and clearly marked as such. This may
// include source files, build scripts and documentation.

// "Reserved Font Name" refers to any names specified as such after the
// copyright statement(s).

// "Original Version" refers to the collection of Font Software components as
// distributed by the Copyright Holder(s).

// "Modified Version" refers to any derivative made by adding to, deleting,
// or substituting -- in part or in whole -- any of the components of the
// Original Version, by changing formats or by porting the Font Software to a
// new environment.

// "Author" refers to any designer, engineer, programmer, technical
// writer or other person who contributed to the Font Software.

// PERMISSION & CONDITIONS
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of the Font Software, to use, study, copy, merge, embed, modify,
// redistribute, and sell modified and unmodified copies of the Font
// Software, subject to the following conditions:

// 1) Neither the Font Software nor any of its individual components,
// in Original or Modified Versions, may be sold by itself.

// 2) Original or Modified Versions of the Font Software may be bundled,
// redistributed and/or sold with any software, provided that each copy
// contains the above copyright notice and this license. These can be
// included either as stand-alone text files, human-readable headers or
// in the appropriate machine-readable metadata fields within text or
// binary files as long as those fields can be easily viewed by the user.

// 3) No Modified Version of the Font Software may use the Reserved Font
// Name(s) unless explicit written permission is granted by the corresponding
// Copyright Holder. This restriction only applies to the primary font name as
// presented to the users.

// 4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
// Software shall not be used to promote, endorse or advertise any
// Modified Version, except to acknowledge the contribution(s) of the
// Copyright Holder(s) and the Author(s) or with their explicit written
// permission.

// 5) The Font Software, modified or unmodified, in part or in whole,
// must be distributed entirely under this license, and must not be
// distributed under any other license. The requirement for fonts to
// remain under this license does not apply to any document created
// using the Font Software.

// TERMINATION
// This license becomes null and void if any of the above conditions are
// not met.

// DISCLAIMER
// THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
// OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
// COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
// DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
// OTHER DEALINGS IN THE FONT SOFTWARE.
pragma solidity >=0.8.0 <0.9.0;

library PlexSubset {
  function getIBMPlexMonoSubset() public pure returns (string memory) {
    return IBMPlexMonoSubset;
  }
  
  function getIBMPlexSansCondensedSubset() public pure returns (string memory) {
    return IBMPlexSansCondensedSubset;
  }
  
  function getIBMPlexMonoSubsetUnicodeRange() public pure returns (string memory) {
    return IBMPlexMonoSubset;
  }
  
  function getIBMPlexSansCondensedSubsetUnicodeRange() public pure returns (string memory) {
    return IBMPlexSansCondensedSubsetUnicodeRange;
  }
  
  string private constant IBMPlexSansCondensedSubsetUnicodeRange = "U+20,U+23,U+30-39,U+45-47,U+4d,U+4f,U+52-53,U+56";
  
  string private constant IBMPlexSansCondensedSubset = "data:font/woff2;base64,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";
  
  string private constant IBMPlexMonoSubsetUnicodeRange = "U+20,U+2d,U+30-39,U+61-66,U+6d,U+6f,U+72,U+74,U+78";
  
  string private constant IBMPlexMonoSubset = "data:font/woff2;base64,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";
}

// Copyright © 2017 IBM Corp. with Reserved Font Name "Plex"

// This Font Software is licensed under the SIL Open Font License, Version 1.1.

// This license is copied below, and is also available with a FAQ at: http://scripts.sil.org/OFL


// -----------------------------------------------------------
// SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
// -----------------------------------------------------------

// PREAMBLE
// The goals of the Open Font License (OFL) are to stimulate worldwide
// development of collaborative font projects, to support the font creation
// efforts of academic and linguistic communities, and to provide a free and
// open framework in which fonts may be shared and improved in partnership
// with others.

// The OFL allows the licensed fonts to be used, studied, modified and
// redistributed freely as long as they are not sold by themselves. The
// fonts, including any derivative works, can be bundled, embedded, 
// redistributed and/or sold with any software provided that any reserved
// names are not used by derivative works. The fonts and derivatives,
// however, cannot be released under any other type of license. The
// requirement for fonts to remain under this license does not apply
// to any document created using the fonts or their derivatives.

// DEFINITIONS
// "Font Software" refers to the set of files released by the Copyright
// Holder(s) under this license and clearly marked as such. This may
// include source files, build scripts and documentation.

// "Reserved Font Name" refers to any names specified as such after the
// copyright statement(s).

// "Original Version" refers to the collection of Font Software components as
// distributed by the Copyright Holder(s).

// "Modified Version" refers to any derivative made by adding to, deleting,
// or substituting -- in part or in whole -- any of the components of the
// Original Version, by changing formats or by porting the Font Software to a
// new environment.

// "Author" refers to any designer, engineer, programmer, technical
// writer or other person who contributed to the Font Software.

// PERMISSION & CONDITIONS
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of the Font Software, to use, study, copy, merge, embed, modify,
// redistribute, and sell modified and unmodified copies of the Font
// Software, subject to the following conditions:

// 1) Neither the Font Software nor any of its individual components,
// in Original or Modified Versions, may be sold by itself.

// 2) Original or Modified Versions of the Font Software may be bundled,
// redistributed and/or sold with any software, provided that each copy
// contains the above copyright notice and this license. These can be
// included either as stand-alone text files, human-readable headers or
// in the appropriate machine-readable metadata fields within text or
// binary files as long as those fields can be easily viewed by the user.

// 3) No Modified Version of the Font Software may use the Reserved Font
// Name(s) unless explicit written permission is granted by the corresponding
// Copyright Holder. This restriction only applies to the primary font name as
// presented to the users.

// 4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
// Software shall not be used to promote, endorse or advertise any
// Modified Version, except to acknowledge the contribution(s) of the
// Copyright Holder(s) and the Author(s) or with their explicit written
// permission.

// 5) The Font Software, modified or unmodified, in part or in whole,
// must be distributed entirely under this license, and must not be
// distributed under any other license. The requirement for fonts to
// remain under this license does not apply to any document created
// using the Font Software.

// TERMINATION
// This license becomes null and void if any of the above conditions are
// not met.

// DISCLAIMER
// THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
// OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
// COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
// DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
// OTHER DEALINGS IN THE FONT SOFTWARE.
pragma solidity >=0.8.0 <0.9.0;

library PlexSansLatin {
  function getIBMPlexSansLatin() public pure returns (string memory) {
    return IBMPlexSansLatin;
  }
  
  function getIBMPlexSansLatinUnicodeRange() public pure returns (string memory) {
    return IBMPlexSansLatinUnicodeRange;
  }
  
  string private constant IBMPlexSansLatinUnicodeRange = "U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD";
  
  string private constant IBMPlexSansLatin = "data:font/woff2;base64,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";
}

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

library ContractInfo {
    string internal constant name = "Forever Message";
    string internal constant symbol = "FMSG";
    string internal constant base_external_url = "https://forevermessage.xyz/";

    function tokenName(uint tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(name, " #", Strings.toString(tokenId)));
    }
    
    function tokenDescription(uint tokenId) public pure returns (string memory) {
        return string(abi.encodePacked("Message #", Strings.toString(tokenId)," in the Forever Message series, a collection of messages that will live forever on the Ethereum blockchain."));
    }
    
    function contractDescription() public pure returns (string memory) {
        return 'What would you say if you knew it would last forever?\\n\\nForever Message is an Ethereum-based application that allows anyone to send messages that cannot be deleted, restricted, or tampered with in any way. All of your Forever Messages will be available forever to the entire world exactly as you composed them.\\n\\nThere is no limit to the number of Forever Messages that can be sent, so send a message that lasts forever today!';
    }
    
    function tokenExternalURL(uint tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(base_external_url, Strings.toString(tokenId)));
    }
    
    function contractExternalURL() public pure returns (string memory) {
        return base_external_url;
    }
    
    function generateTokenURI(
      string[12] memory tokenAttributes
    ) public pure returns (string memory) { 
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', tokenAttributes[0], '",'
                                '"description":"', tokenAttributes[1], '",'
                                '"image_data":"', tokenAttributes[2], '",'
                                '"external_url":"', tokenAttributes[3], '",'
                                    '"attributes": [',
                                        '{',
                                            '"trait_type": "author",',
                                            '"value": "', tokenAttributes[4], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "text_color",',
                                            '"value": "', tokenAttributes[5], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "text_length_in_bytes",',
                                            '"display_type": "number",',
                                            '"max_value": "', tokenAttributes[11], '",',
                                            '"value": "', tokenAttributes[6], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "mint_time",',
                                            '"display_type": "date",',
                                            '"value": "', tokenAttributes[9], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "text_keccak256",',
                                            '"value": "', tokenAttributes[10], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "gradient_color_one",',
                                            '"value": "', tokenAttributes[7], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "gradient_color_two",',
                                            '"value": "', tokenAttributes[8], '"',
                                        '}',
                                    ']'
                                '}'
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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