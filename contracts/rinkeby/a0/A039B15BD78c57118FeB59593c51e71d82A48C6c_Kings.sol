// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Sacramento Kings
/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "./core/IERC721CreatorCore.sol";
import "./extensions/ICreatorExtensionTokenURI.sol";
import "./fonts/IFontWOFF.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                           ╦                                             //
//                         ╔╬╬                                             //
//                        ╔╬╣  ╔╗                   ╔╗  ╦╦╦    ╔╬╬╗        //
//                ╔╦╬   ╔╬╬╬╬  ╬╬         ╔╬╬╗   ╔╬╬╬╬╬╬╬╣   ╔╬╬╬╬╬        //
//            ╔╦╬╬╬╬╝  ╔╬╬╬╬╝       ╔╦╬╦╬╬╬╬╬╣  ╔╬╬╩  ╬╬╬╝ ╦╬╬╩ ╠╬╬╣       //
//           ╠╬╬╬╬╬╬  ╬╬╬╬╩   ╔╦╬   ╬╬╬╬╝ ╠╬╬  ╔╬╬╣  ╬╬╬╣╔╬╬╩   ╠╬╬╣       //
//           ╚╩╩╬╬╬╬╦╬╬╬╩     ╠╬╬  ╠╬╬╝   ╬╬╣ ╔╬╬╬╬╦╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//              ╬╬╬╬╬╬╝      ╠╬╬╝  ╬╬╣   ╠╬╬╬╬╩╩╬╬╬╩╬╬╬╬╩   ╚╩╩╩╩╩  ╬╬╬╬   //
//              ╬╬╬╬╬╣       ╠╬╬   ╬╬╣   ╚╬╩╩      ╬╬╬╬╗      ╔╦╦╦╬╬╬╝╙    //
//             ╬╬╬╣╬╬╬╬╦    ╔╦╬╬╦╦╦╬╬╝      ╔╦╦╬╬╬╬╬╬╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩       //
//             ╠╬╬╝ ╬╬╬╬╬╦╦╬╬╩╬╬╬╩╩╩   ╔╦╬╬╩╩╬╬╬╬╝╠╬╬⌐                     //
//             ╬╬╬   ╙╬╬╬╬╬╬╝     ╔╦╦╬╬╬╩╝ ╔╬╬╬╩╝╔╬╬╝                      //
//            ╬╬╬╣           ╔╦╦╬╬╬╬╩╝    ╔╬╬╬╝ ╔╬╬╩                       //
//      ╬    ╬╬╬╬╝        ╔╦╬╬╬╬╬╬╩      ╔╬╬╬╬╦╦╬╬╩                        //
//      ╬╦╦╦╬╬╬╬╝     ╔╦╬╬╬╬╬╬╬╩╩        ╬╬╬╬╬╬╬╬╝                         //
//      ╚╬╬╬╬╬╬╩    ╔╬╬╬╬╬╬╬╬╩            ╚╩╩╩╝                            //
//       ╚╩╩╩╩╝   ╔╦╬╬╬╬╬╬╬╝                                               //
//             ╔╬╬╬╬╬╬╬╬╬╬╩                                                //
//           ╔╬╬╬╬╬╬╬╬╩╩╩╝                                                 //
//         ╔╬╬╬╬╬╩╩╝                                                       //
//       ╔╬╬╬╩╩                                                            //
//      ╬╬╩╝                                                               //
//    ╩╩╝                                                                  //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

/**
 * 1985 Inaugural Season Opening Night Pin – Rare Edition
 */
contract Kings is AdminControl, ICreatorExtensionTokenURI {

    using Strings for uint256;

    // The creator mint contract
    address private _creator;

    // URI Tags
    string constant private _BANNER_TAG = '<BANNER>';

    // Banner Tags
    string constant private _FONT_TAG = '<FONT>';
    string constant private _FONT_NAME_ONLY_TAG = '<FONT_NAME_ONLY>';
    string constant private _NAME_FONT_SIZE_TAG = '<SIZENAME>';
    string constant private _KINGS_FONT_SIZE_TAG = '<SIZEKINGS>';
    string constant private _FIRST_NAME_TAG = '<FIRSTNAME>';
    string constant private _LAST_NAME_TAG = '<LASTNAME>';
    string constant private _NUMBER_TAG = '<NUMBER>';
    string constant private _KINGS_TEXT1_TAG = '<KINGSTEXT1>';
    string constant private _KINGS_TEXT2_TAG = '<KINGSTEXT2>';

    uint256 private _changeInterval = 604800;
    
    // Dynamic construction data
    string[] private _uriParts;
    string[] private _bannerParts;

    // Owner updates submitted for approval
    bool private _pending;
    string private _pendingFirstName;
    string private _pendingLastName;
    uint256 private _pendingNumber;
    uint256 private _pendingNameFontSize;
    bool private _pendingRejected;
    string private _pendingRejectedReason;

    // Dynamic variables for banner construction
    string private _firstName;
    string private _lastName;
    uint256 private _number;
    uint256 private _nameFontSize;
    address private _font;
    address private _fontNameOnly;
    string private _kingsText1;
    string private _kingsText2;
    uint256 private _kingsFontSize;
    uint256 private _lastChangeRequest;

    uint256 private _tokenId;

    uint256[] public restrictedNumbers;

    event ChangeOwnerInfo(address sender, string firstName, string lastName, uint256 number, uint256 nameFontSize);
    event ApproveOwnerInfo(address sender, string firstName, string lastName, uint256 number, uint256 nameFontSize);
    event RejectOwnerInfo(address sender, string firstName, string lastName, uint256 number, uint256 nameFontSize, string reason);
    event ChangeOwnerInfoRequest(address sender, string firstName, string lastName, uint256 number, uint256 nameFontSize);

    constructor() {
        _bannerParts = [
          "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='1170' height='1450' viewBox='0 0 1170 1450'>",
            "<defs>",
              "<style type='text/css'>",
                "@font-face {font-family: 'Kings';src: url(","<FONT>",") format('woff');}",
                "@font-face {font-family: 'KingsName';src: url(","<FONT_NAME_ONLY>",") format('woff');}",
              "</style>",
              "<linearGradient id='lg1' x1='0' x2='100%'><stop offset='0' style='stop-color:#D5D5D5'/><stop offset='33%' style='stop-color:white'/><stop offset='66%' style='stop-color:white'/><stop offset='100%' style='stop-color:#D5D5D5'/></linearGradient><linearGradient id='lg2' x1='0' y1='100%' x2='0' y2='0'><stop offset='0' style='stop-color:#13171B'/><stop offset='0.0547' style='stop-color:#0E1114'/><stop offset='0.2045' style='stop-color:#060709'/><stop offset='0.4149' style='stop-color:#010202'/><stop offset='1' style='stop-color:black'/></linearGradient>",
              "<linearGradient id='flg1' gradientUnits='userSpaceOnUse'><stop offset='0.0956' style='stop-color:#EFB927'/><stop offset='0.1014' style='stop-color:#C99C25'/><stop offset='0.1079' style='stop-color:#A68224'/><stop offset='0.1151' style='stop-color:#896C22'/><stop offset='0.123' style='stop-color:#715921'/><stop offset='0.1318' style='stop-color:#5E4B20'/><stop offset='0.1423' style='stop-color:#51411F'/><stop offset='0.1558' style='stop-color:#493C1F'/><stop offset='0.1834' style='stop-color:#473A1F'/><stop offset='0.2657' style='stop-color:#D2C7B2'/><stop offset='0.3686' style='stop-color:#F6DF8C'/><stop offset='0.6245' style='stop-color:#3C2F0D'/><stop offset='0.8151' style='stop-color:#BF9C1C'/></linearGradient><linearGradient id='flg2' gradientUnits='userSpaceOnUse'><stop offset='0' style='stop-color:white'/><stop offset='0.3729' style='stop-color:#FDFDFD;stop-opacity:0.6274'/><stop offset='0.5071' style='stop-color:#F6F6F6;stop-opacity:0.4931'/><stop offset='0.6027' style='stop-color:#EBEBEB;stop-opacity:0.3974'/><stop offset='0.6801' style='stop-color:#DADADA;stop-opacity:0.32'/><stop offset='0.7464' style='stop-color:#C4C4C4;stop-opacity:0.2537'/><stop offset='0.8051' style='stop-color:#A8A8A8;stop-opacity:0.195'/><stop offset='0.8582' style='stop-color:#888888;stop-opacity:0.1419'/><stop offset='0.9069' style='stop-color:#626262;stop-opacity:0.0931'/><stop offset='0.9523' style='stop-color:#373737;stop-opacity:0.0477'/><stop offset='1' style='stop-color:black;stop-opacity:0'/></linearGradient><linearGradient id='tfg1' href='#flg1' x1='0' y1='98' x2='0' y2='76'/><linearGradient id='bfg1' href='#flg1' x1='0' y1='1166' x2='0' y2='1190'/><linearGradient id='lfg1' href='#flg1' x1='98' y1='0' x2='122' y2='0'/><linearGradient id='rfg1' href='#flg1' x1='1044' y1='0' x2='1068' y2='0'/><linearGradient id='tfg2a' href='#flg2' x1='123' y1='89' x2='1041' y2='89'/><linearGradient id='tfg2b' href='#flg2' x1='128' y1='0' x2='592' y2='0'/><linearGradient id='bfg2a' href='#flg2' x1='123' y1='0' x2='1047' y2='0'/><linearGradient id='bfg2b' href='#flg2' x1='495' y1='0' x2='1036' y2='0'/><linearGradient id='sfg2' href='#flg2'  x1='0' y1='960' x2='0' y2='96'/>",
              "<g id='bolt'><path fill='#141414' d='M3.8,0h-6.27l-3.58,4.06l2.7,4.07h6.29l3.57-4.07L3.8,0z M0,6.18c-1.56,0-2.73-0.95-2.6-2.11c0.13-1.17,1.49-2.11,3.05-2.11c1.56,0,2.72,0.95,2.6,2.11C2.93,5.23,1.56,6.18,0,6.18z'/><path d='M0.46,1.95c-1.56,0-2.93,0.95-3.05,2.11c-0.13,1.17,1.04,2.11,2.6,2.11s2.93-0.95,3.05-2.11C3.18,2.89,2.02,1.95,0.45,1.95z'/></g>",
              "<g id='logo'><rect width='86' height='51' fill='black'/><path d='M56.47,23.69H53.64l6-5.06-4.39-4.71-6.64,5.54-5.49-5.54L33.42,23.7H30.75l5.49-5.59-4.15-4.19-6.15,6-9.59-5,5.23,18.31a90.79,90.79,0,0,1,21.33-3,81.66,81.66,0,0,1,20.68,3l5.4-19Z' fill='#fff'/><path d='M63.14,34.72A79.33,79.33,0,0,0,43,31.87,86.17,86.17,0,0,0,22,34.7l.75,2.76A85.28,85.28,0,0,1,43,34.83,81.47,81.47,0,0,1,62.4,37.38Z' fill='#fff'/><path d='M86,50.81H0V0H86Zm-84-2H84V2H2Z' fill='#fff'/></g>",
              "<linearGradient id='seatlg' x1='0' y1='60.43' x2='0' y2='1.25' gradientTransform='matrix(1, 0, 0, -1, 0, 60.43)' gradientUnits='userSpaceOnUse'><stop offset='0' stop-color='#414142' stop-opacity='0.8'/><stop offset='0.09' stop-color='#323233' stop-opacity='0.73'/><stop offset='0.27' stop-color='#1c1c1c' stop-opacity='0.58'/><stop offset='0.47' stop-color='#0d0e0e' stop-opacity='0.42'/><stop offset='0.7' stop-color='#040404' stop-opacity='0.24'/><stop offset='1' stop-color='#010101' stop-opacity='0'/></linearGradient><path id='seat' d='M34.86,59.18H7.6A7.6,7.6,0,0,1,0,51.58V7.6A7.6,7.6,0,0,1,7.6,0H34.86a7.6,7.6,0,0,1,7.6,7.6v44A7.61,7.61,0,0,1,34.86,59.18Z' fill='url(#seatlg)'/><pattern id='seatp1' x='0' y='0' width='50' height='35' patternUnits='userSpaceOnUse'><use href='#seat'/></pattern><pattern id='seatp2' x='25' y='0' width='50' height='35' patternUnits='userSpaceOnUse'><use href='#seat'/></pattern>",
              "<linearGradient id='raftlg' gradientUnits='userSpaceOnUse'><stop offset='0' style='stop-color:white'/><stop offset='1' style='stop-color:black'/></linearGradient><linearGradient id='raft1' href='#raftlg' x1='0' y1='144' x2='0' y2='102'/><linearGradient id='raft2' href='#raftlg' x1='0' y1='200' x2='0' y2='159'/>",
              "<linearGradient id='burn1' x1='-25%' y1='0' x2='125%' y2='0'><stop offset='-1' style='stop-color:#F1A958'><animate attributeName='offset' values='-1;-0.75;-0.5;-0.25;0' dur='3s' repeatCount='indefinite'/></stop><stop offset='-0.75' style='stop-color:#F9F9A3'><animate attributeName='offset' values='-0.75;-0.5;-0.25;0;0.25' dur='3s' repeatCount='indefinite'/></stop><stop offset='-0.25' style='stop-color:#F9F9A3'><animate attributeName='offset' values='-0.25;0;0.25;0.5;0.75' dur='3s' repeatCount='indefinite'/></stop><stop offset='0' style='stop-color:#F1A958'><animate attributeName='offset' values='0;0.25;0.5;0.75;1' dur='3s' repeatCount='indefinite'/></stop><stop offset='0.25' style='stop-color:#F9F9A3'><animate attributeName='offset' values='0.25;0.5;0.75;1;1.25' dur='3s' repeatCount='indefinite'/></stop><stop offset='0.75' style='stop-color:#F9F9A3'><animate attributeName='offset' values='0.75;1;1.25;1.5;1.75' dur='3s' repeatCount='indefinite'/></stop><stop offset='1' style='stop-color:#F1A958'><animate attributeName='offset' values='1;1.25;1.5;.75;2' dur='3s' repeatCount='indefinite'/></stop></linearGradient><linearGradient id='burn2' x1='-25%' y1='0' x2='125%' y2='0'><stop offset='0' style='stop-color:#F9F9A3'><animate attributeName='offset' values='-1;-1;0;' dur='3s' repeatCount='indefinite'/></stop><stop offset='0' style='stop-color:#F1A958'><animate attributeName='offset' values='-1;0;1' dur='3s' repeatCount='indefinite'/></stop><stop offset='0' style='stop-color:#F9F9A3'><animate attributeName='offset' values='0;1;1;' dur='3s' repeatCount='indefinite'/></stop></linearGradient>",
            "</defs>",
            "<rect width='1170' height='1450'/>",
            "<rect x='98' y='76' width='968' height='22' fill='url(#tfg1)'/><polygon points='98,1166 1067,1166 1067,1190 98,1190' fill='url(#bfg1)'/><polygon points='98,1190 98,76 122,76 122,1190' fill='url(#lfg1)'/><polygon points='1044,1190 1044,76 1068,76 1068,1190' fill='url(#rfg1)'/>",
            "<g opacity='0.8'><polygon points='1041,95 123,89 1041,84' fill='url(#tfg2a)'/><polygon points='592,87 128,82 592,76' fill='url(#tfg2b)'/><polygon points='1047,1177 123,1170 1047,1165' fill='url(#bfg2a)'/><polygon points='1037,1189 496,1183 1037,1178' fill='url(#bfg2b)'/><polygon points='124,96 117,960 112,96' fill='url(#sfg2)'/><polygon points='1055,76 1049,941 1043,76' fill='url(#sfg2)'/></g>",
            "<rect x='122' y='100' width='922' height='1068' fill='url(#lg2)'/>",
            "<g opacity='0.4'><rect x='122.25' y='99.25' width='921.5' height='4' fill='#282828'/><rect x='122.25' y='100' width='921.5' height='42.25' fill='url(#raft1)' opacity='0.1'/><rect x='122.25' y='145' width='921.5' height='5' fill='#282828'/><rect x='122.25' y='150' width='921.5' height='18.75' fill='#3A3A3A'/></g>",
            "<g opacity='0.1'><rect x='122.25' y='159' width='921.5' height='42.25' fill='url(#raft2)' opacity='0.1'/><rect x='122.25' y='200' width='921.5' height='5' fill='#282828'/><rect x='122.25' y='205' width='921.5' height='18.75' fill='#3A3A3A'/></g>",
            "<g opacity='0.4'><use href='#bolt' x='152.65' y='186.78'/><use href='#bolt' x='385.99' y='186.78'/><use href='#bolt' x='584.34' y='186.78'/><use href='#bolt' x='780.18' y='186.78'/><use href='#bolt' x='1016.02' y='186.78'/></g>",
            "<use href='#bolt' x='152.65' y='109.15'/><use href='#bolt' x='154.95' y='130.71'/><use href='#bolt' x='385.99' y='109.15'/><use href='#bolt' x='384.85' y='130.71'/><use href='#bolt' x='584.34' y='109.15'/><use href='#bolt' x='584.34' y='130.71'/><use href='#bolt' x='780.18' y='109.15'/><use href='#bolt' x='781.32' y='130.71'/><use href='#bolt' x='1016.02' y='109.15'/><use href='#bolt' x='1013.72' y='130.71'/>",
            "<rect x='122' y='875' width='922' height='35' fill='url(#seatp2)' opacity='0.2'/><rect x='122' y='910' width='922' height='35' fill='url(#seatp1)' opacity='0.3'/><rect x='122' y='945' width='922' height='35' fill='url(#seatp2)' opacity='0.4'/><rect x='122' y='980' width='922' height='35' fill='url(#seatp1)' opacity='0.5'/><rect x='122' y='1015' width='922' height='35' fill='url(#seatp2)' opacity='0.6'/><rect x='122' y='1050' width='922' height='35' fill='url(#seatp1)' opacity='0.7'/><rect x='122' y='1085' width='922' height='35' fill='url(#seatp2)' opacity='0.8'/><rect x='122' y='1120' width='922' height='35' fill='url(#seatp1)' opacity='0.9'/>",
            "<rect x='359.5' y='99.25' width='1.13' height='167' fill='#939393'/><rect x='808' y='99.25' width='1.13' height='167' fill='#939393'/><rect width='595' height='805' x='287.5' y='275' stroke='#0678A7' stroke-width='17.5'/><rect width='560' height='770' x='305' y='292.5' stroke='#EE1E3A' stroke-width='17.5' fill='url(#lg1)'/>",
            "<use href='#logo' x='542.5' y='160'/>",
            "<svg width='538.75' height='752.5' x='313.25' y='300.25' font-family='Kings' stroke='#EE1E3A' fill='#0678A7'>",
                "<path id='curve' d='M 0 140 Q 264.25 80.5 528.5 140' stroke-width='0' fill='transparent'/>",
                "<svg x='7' y='0' width='524.75'><text id='first_name' font-size='","<SIZENAME>","px' stroke-width='1.2' letter-spacing='1.8'><textPath xlink:href='#curve' text-anchor='middle' startOffset='50%'>","<FIRSTNAME>","</textPath></text></svg>",
                "<svg x='7' y='87.5' width='524.75'><text id='last_name' font-size='","<SIZENAME>","px' stroke-width='1.2' letter-spacing='1.8'><textPath xlink:href='#curve' text-anchor='middle' startOffset='50%'>","<LASTNAME>","</textPath></text></svg>",
                "<text id='number' x='50%' y='472.5' font-size='280px' text-anchor='middle' stroke-width='5.4'>","<NUMBER>","</text>",
                "<text id='kings_text1' x='50%' y='612.5' font-size='","<SIZEKINGS>","px' text-anchor='middle' stroke-width='1.2' letter-spacing='1.8'>","<KINGSTEXT1>","</text>",
                "<text id='kings_text2' x='50%' y='700' font-size='","<SIZEKINGS>","px' text-anchor='middle' stroke-width='1.2' letter-spacing='1.8'>","<KINGSTEXT2>","</text>",
            "</svg>",
            "<text font-size='17' font-family='KingsName' letter-spacing='4' fill='white' x='125' y='1252.5'>SACRAMENTO KINGS</text><rect x='125' y='1275' width='55' height='5' fill='white'/><g font-family='Kings' letter-spacing='3'><text x='125' y='1330' font-family='Kings' font-size='40px' fill='url(#burn1)'>COMMEMORATIVE NFT BANNER</text></g><text x='885' y='1255' font-family='Kings' font-size='20px' letter-spacing='2.5' fill='url(#burn1)'>RARE EDITION</text><rect x='885' y='1265' width='160' height='110' stroke-width='3' stroke='white'/><svg x='885' y='1265' width='160' height='110'><text x='50%' y='80' font-family='Kings' font-size='70px' letter-spacing='17.5' text-anchor='middle' fill='url(#burn1)'>1 1</text><text x='50%' y='70' font-family='Kings' font-size='40px' text-anchor='middle' fill='url(#burn2)'>/</text></svg>",
            "<filter id='glow' x='-50%' y='-50%' width='200%' height='200%'><feGaussianBlur in='SourceGraphic' stdDeviation='5'/></filter><circle cx='885' cy='1265' r='7' fill='white' filter='url(#glow)'><animate attributeName='cx' values='885;1045;1045' dur='6s' repeatCount='indefinite'/><animate attributeName='cy' values='1265;1265;1375' dur='6s' repeatCount='indefinite'/></circle><circle cx='885' cy='1265' r='2' fill='white'><animate attributeName='cx' values='885;1045;1045' dur='6s' repeatCount='indefinite'/><animate attributeName='cy' values='1265;1265;1375' dur='6s' repeatCount='indefinite'/></circle><circle cx='1045' cy='1375' r='7' fill='white' filter='url(#glow)'><animate attributeName='cx' values='1045;885;885' dur='6s' repeatCount='indefinite'/><animate attributeName='cy' values='1375;1375;1265' dur='6s' repeatCount='indefinite'/></circle><circle cx='1045' cy='1375' r='2' fill='white'><animate attributeName='cx' values='1045;885;885' dur='6s' repeatCount='indefinite'/><animate attributeName='cy' values='1375;1375;1265' dur='6s' repeatCount='indefinite'/></circle>",
          "</svg>"];

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Activate the contract and mint the token
     */
    function activate(address creator_) public adminRequired {
        // Mint the first one to the owner
        require(_tokenId == 0, "Already active");
        _creator = creator_;

        _uriParts = ['data:application/json;utf8,{"name":"1985 Inaugural Season Opening Night Pin - Rare Edition","created_by":"Sacramento Kings","description":"Be part of Kings history with the franchise\'s first-ever NFTs commemorating the inaugural season in Sacramento. This is the rarest NFT in the 1985 Inaugural Pin Collection, allowing the owner to make their mark on Golden 1 Center, the home of the Sacramento Kings.\\n\\nThe owner of this NFT can customize the name and number on the banner, reflected on the NFT itself as well as the Kings website and inside Golden 1 Center.\\n\\nThe original owner of this NFT will also receive a physical replica of the 1985 inaugural season pin as well as a pair of tickets to the 2021-22 Opening Night game, with seats guaranteed in the first three rows.","image":"data:image/svg+xml;utf8,','<BANNER>','","animation":"https://arweave.net/4BZpgaPIVBQQaLLhJU3fx-F3LtvWDEeqd_9lxlUd7ws","animation_url":"https://arweave.net/4BZpgaPIVBQQaLLhJU3fx-F3LtvWDEeqd_9lxlUd7ws","animation_details":{"sha256":"d8613f014931da7fa04ee4c87b3db1b53a83d636c1aea1ac43740b05cbf1cd6a","bytes":18733746,"width":2500,"height":3100,"duration":14,"format":"MP4","codecs":["H.264","AAC"]},"attributes":[{"trait_type":"Team","value":"Sacramento Kings"},{"trait_type":"Collection","value":"Sacramento Kings 1985 Inaugural Pin"},{"trait_type":"Year","value":"2021"}]}'];

        _nameFontSize = 80;
        _kingsFontSize = 80;
        _firstName = "FIRST NAME";
        _lastName = "LAST NAME";
        _number = 1;
        _kingsText1 = "NFT";
        _kingsText2 = "OWNER";

        _tokenId = IERC721CreatorCore(_creator).mintExtension(owner());
    }

    /**
     * @dev Get the creator contract
     */
    function creator() public view returns(address) {
        return _creator;
    }

    /**
     * @dev Get owner info
     */
    function ownerInfo() public view returns(string memory, string memory, uint256, uint256) {
        return (_firstName, _lastName, _number, _nameFontSize);
    }

    /**
     * @dev Get kings text
     */
    function kingsText() public view returns(string memory, string memory, uint256) {
       return (_kingsText1, _kingsText2, _kingsFontSize);
    }

    /**
     * @dev update the URI data
     */
    function updateURIParts(string[] memory uriParts) public adminRequired {
        _uriParts = uriParts;
    }

    /**
     * @dev update the banner data
     */
    function updateBannerParts(string[] memory bannerParts) public adminRequired {
        _bannerParts = bannerParts;
    }

    /**
     * @dev add banner parts data
     */
    function addBannerParts(string[] memory bannerParts) public adminRequired {
        for (uint i = 0; i < bannerParts.length; i++) {
            _bannerParts.push(bannerParts[i]);
        }
    }

    /**
     * @dev update the font
     */
    function updateFont(address font, address fontNameOnly) public adminRequired {
        _font = font;
        _fontNameOnly = fontNameOnly;
    }

    /**
     * @dev update Kings text
     */
    function updateKingsText(string memory text1, string memory text2, uint256 fontSize) public adminRequired {
        _kingsText1 = upper(text1);
        _kingsText2 = upper(text2);
        _kingsFontSize = fontSize;
    }

    /**
     * @dev update Kings restricted numbers
     */
    function updateRestrictedNumbers(uint256[] memory numbers) public adminRequired {
        restrictedNumbers = numbers;
    }

    /**
     * @dev update owner information
     */
    function changeOwnerInfo(string memory firstName, string memory lastName, uint256 number, uint256 nameFontSize) public {
        require(IERC721(_creator).ownerOf(_tokenId) == msg.sender, "Only owner can update info");
        require(!_pending, "You already have a pending request");
        require(block.timestamp > _lastChangeRequest+_changeInterval, "You must wait to request another change");

        for (uint i = 0; i < restrictedNumbers.length; i++) {
            if (number == restrictedNumbers[i]) revert("Restricted number");
        }
        _pendingFirstName = upper(firstName);
        _pendingLastName = upper(lastName);
        _pendingNumber = number;
        _pendingNameFontSize = nameFontSize;
        _pendingRejected = false;
        _pendingRejectedReason = '';
        _lastChangeRequest = block.timestamp;
        _pending = true;

        emit ChangeOwnerInfoRequest(msg.sender, firstName, lastName, number, nameFontSize);
    }

    /**
     * @dev returns amount of time you need to wait until you can make another change request
     */
    function timeToNextChange() public view returns(uint256) {
        if (block.timestamp < _lastChangeRequest+_changeInterval) return _lastChangeRequest+_changeInterval-block.timestamp;
        return 0;
    }

    /**
     * @dev get pending owner info
     */
    function pendingOwnerInfo() public view returns(bool, string memory, string memory, uint256, uint256, bool, string memory) {
        return (_pending, _pendingFirstName, _pendingLastName, _pendingNumber, _pendingNameFontSize, _pendingRejected, _pendingRejectedReason);
    }

    /**
     * @dev approve owner info
     */
    function approveOwnerInfo() public adminRequired {
         require(_pending, "No requests pending");

         _firstName = _pendingFirstName;
         _lastName = _pendingLastName;
         _number = _pendingNumber;
         _nameFontSize = _pendingNameFontSize;

         _pending = false;
         _pendingFirstName = '';
         _pendingLastName = '';
         _pendingNumber = 0;
         _pendingNameFontSize = 0;
         _pendingRejected = false;
         _pendingRejectedReason = '';

         emit ApproveOwnerInfo(msg.sender, _firstName, _lastName, _number, _nameFontSize);
     }

    /**
     * @dev reject owner info
     */
    function rejectOwnerInfo(string memory reason, bool resetChangeTime) public adminRequired {
         _pending = false;
         _pendingRejected = true;
         _pendingRejectedReason = reason;
         if (resetChangeTime) _lastChangeRequest = 0;

         emit RejectOwnerInfo(msg.sender, _firstName, _lastName, _number, _nameFontSize, reason);
     }

    /**
     * @dev override owner info
     */
    function overrideOwnerInfo(string memory firstName, string memory lastName, uint256 number, uint256 nameFontSize) public adminRequired {
         _firstName = upper(firstName);
         _lastName = upper(lastName);
         _number = number;
         _nameFontSize = nameFontSize;
         
         emit ChangeOwnerInfo(msg.sender, firstName, lastName, number, nameFontSize);
     }

    /**
     * @dev Generate uri
     */
    function _generateURI() private view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _uriParts.length; i++) {
            if (_checkTag(_uriParts[i], _BANNER_TAG)) {
               byteString = abi.encodePacked(byteString, bannerSVG());
            } else {
              byteString = abi.encodePacked(byteString, _uriParts[i]);
            }
        }
        return string(byteString);
    }

    /**
     * @dev get banner SVG
     */
    function bannerSVG() public view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _bannerParts.length; i++) {
            if (_checkTag(_bannerParts[i], _FONT_TAG)) {
               byteString = abi.encodePacked(byteString, IFontWOFF(_font).woff());
            } else if (_checkTag(_bannerParts[i], _FONT_NAME_ONLY_TAG)) {
               byteString = abi.encodePacked(byteString, IFontWOFF(_fontNameOnly).woff());
            } else if (_checkTag(_bannerParts[i], _NAME_FONT_SIZE_TAG)) {
               byteString = abi.encodePacked(byteString, _nameFontSize.toString());
            } else if (_checkTag(_bannerParts[i], _KINGS_FONT_SIZE_TAG)) {
               byteString = abi.encodePacked(byteString, _kingsFontSize.toString());
            } else if (_checkTag(_bannerParts[i], _FIRST_NAME_TAG)) {
               byteString = abi.encodePacked(byteString, _firstName);
            } else if (_checkTag(_bannerParts[i], _LAST_NAME_TAG)) {
               byteString = abi.encodePacked(byteString, _lastName);
            } else if (_checkTag(_bannerParts[i], _NUMBER_TAG)) {
               byteString = abi.encodePacked(byteString, _number.toString());
            } else if (_checkTag(_bannerParts[i], _KINGS_TEXT1_TAG)) {
               byteString = abi.encodePacked(byteString, _kingsText1);
            } else if (_checkTag(_bannerParts[i], _KINGS_TEXT2_TAG)) {
               byteString = abi.encodePacked(byteString, _kingsText2);
            } else {
              byteString = abi.encodePacked(byteString, _bannerParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator_, uint256 tokenId) external view override returns (string memory) {
        require(creator_ == _creator && tokenId == _tokenId, "Invalid token");
        return _generateURI();
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */    
    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     * 
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAdminControl.sol";

abstract contract AdminControl is Ownable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdminControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public override view returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorCore.sol";

/**
 * @dev Core ERC721 creator interface
 */
interface IERC721CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to) external returns (uint256);

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenIds minted
     */
    function mintExtensionBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implement this if you want your extension to have overloadable URI's
 */
interface ICreatorExtensionTokenURI is IERC165 {

    /**
     * Get the uri for a given creator/tokenId
     */
    function tokenURI(address creator, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Font interface
 */
interface IFontWOFF {
    function woff() external view returns(string memory);
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
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for admin control
 */
interface IAdminControl is IERC165 {

    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address admin) external;

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address admin) external;

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address admin) external view returns (bool);

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

/*
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

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {

    event ExtensionRegistered(address indexed extension, address indexed sender);
    event ExtensionUnregistered(address indexed extension, address indexed sender);
    event ExtensionBlacklisted(address indexed extension, address indexed sender);
    event MintPermissionsUpdated(address indexed extension, address indexed permissions, address indexed sender);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ExtensionRoyaltiesUpdated(address indexed extension, address payable[] receivers, uint256[] basisPoints);
    event ExtensionApproveTransferUpdated(address indexed extension, bool enabled);

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev blacklist an extension.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified extension. It will also unregister the extension if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistExtension(address extension) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     */
    function setBaseTokenURIExtension(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256[] memory tokenId, string[] calldata uri) external;

    /**
     * @dev set the baseTokenURI for tokens with no extension.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no extension.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions) external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be extension) gets approval
     * from the extension before transferring
     */
    function setApproveTransferExtension(bool enabled) external;

    /**
     * @dev get the extension of a given token
     */
    function tokenExtension(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

}

{
  "optimizer": {
    "enabled": true,
    "runs": 25
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}