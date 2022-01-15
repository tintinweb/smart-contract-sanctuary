// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PhotosbyNumber
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//    [size=9px][font=monospace][color=#515b72]▒[/color][color=#515b71]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#555e70]▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#303b4f]▄[/color][color=#223141]█[/color][color=#3a4b60]▌[/color][color=#546274]▒[/color][color=#546275]▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#525d73]▒▒▒▒▒[/color][color=#525c70]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#455060]▒[/color][color=#384453]▄▄[/color][color=#525e71]▒[/color][color=#535e70]▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#505a69]▒[/color][color=#4f5867]▒[/color][color=#1e2835]█[/color][color=#08121c]██[/color][color=#515b6d]▒[/color][color=#515b6c]▒▒▒▒▒▒▒[/color][color=#495567]░[/color][color=#475364]░[/color][color=#445061]░[/color][color=#414d5d]▄[/color][color=#3e4a5b]▄[/color][color=#3a4555]▄[/color][color=#364250]▄[/color][color=#333f4e]▄[/color][color=#303a4b]▄[/color][color=#1f2736]█[/color][color=#070f18]█[/color][color=#08121b]█[/color][color=#0a1620]█[/color][color=#283645]█[/color][color=#263443]█[/color][color=#253241]██[/color][color=#233140]█[/color][color=#202d3d]█[/color][color=#1f2c3b]███[/color][color=#1a2737]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                         //
//    [color=#515c71]▒[/color][color=#505b70]▒▒▒▒▒▒[/color][color=#4e5869]▒[/color][color=#4d5767]▒[/color][color=#1a2537]█[/color][color=#0c1523]██[/color][color=#4a576b]▒[/color][color=#4c586a]▒▒[/color][color=#4f5a6d]▒[/color][color=#505a6d]▒▒▒▒▒▒▒▒[/color][color=#495364]▒[/color][color=#454f5e]▒[/color][color=#434c5a]▒[/color][color=#0f1921]█[/color][color=#071015]█[/color][color=#0b131c]█[/color][color=#384453]▒[/color][color=#384553]▄▄▄[/color][color=#35414e]▄[/color][color=#333e4b]▄[/color][color=#303c4a]▄[/color][color=#2d3a45]▄[/color][color=#2b3642]█[/color][color=#28333f]█[/color][color=#26313c]█[/color][color=#232f3a]█[/color][color=#202a34]█[/color][color=#1d262f]█[/color][color=#1a232b]█[/color][color=#141c25]█[/color][color=#070e15]█[/color][color=#080f16]██[/color][color=#0c121b]█[/color][color=#0b121b]█[/color][color=#070d15]█[/color][color=#060d13]████████████████████[/color][color=#0a131a]█[/color][color=#0b1218]███████[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#2b384c]▄[/color][color=#293548]█[/color][color=#273245]█[/color][color=#253040]█[/color][color=#212b3b]█[/color][color=#202a39]██[/color][color=#1c2734]█[/color][color=#19232f]█[/color][color=#070f16]█[/color][color=#060c14]█[/color][color=#03040e]█[/color][color=#0d121d]█[/color][color=#0d1520]████[/color][color=#071019]█[/color][color=#061015]███████████[/color][color=#03050f]████████████████[/color][color=#0c0f14]█[/color][color=#080e15]██[/color][color=#131214]█[/color][color=#151514]█[/color][color=#191817]█[/color][color=#1c1a18]██[/color][color=#231d19]█[/color][color=#27201b]█[/color][color=#29211c]██[/color][color=#2f271f]█[/color][color=#342a21]█[/color][color=#362c22]█[/color][color=#392f25]▀[/color][color=#3c3227]▀▀[/color][color=#423529]▀[/color][color=#45382c]▒[/color][color=#493c2f]▒▒[/color][color=#0f1315]█[/color][color=#0d1517]█[/color][color=#544332]▒[/color][color=#594a3c]▒[/color][color=#5c4e3f]▒[/color][color=#615241]▒╢[/color][color=#645341]╢╢╢[/color][color=#343130]█[/color][color=#0a121c]█[/color][color=#090e19]█[/color]                                                                                                                                                                                            //
//    [color=#060d19]████[/color][color=#1a1516]█[/color][color=#1d191b]█[/color][color=#1d1a1b]██[/color][color=#211f1d]██[/color][color=#070e14]███[/color][color=#2a241f]█[/color][color=#2c2620]█[/color][color=#2f2924]▀█[/color][color=#302924]▀▀[/color][color=#372f27]▀[/color][color=#393129]▀▀[/color][color=#3d342c]▒[/color][color=#3f372d]▀[/color][color=#433a30]▒[/color][color=#453d31]▒▒[/color][color=#282621]█[/color][color=#0b1315]█[/color][color=#4e4233]▒[/color][color=#524638]▒[/color][color=#554839]▒[/color][color=#584b3b]▒[/color][color=#5a4d3c]▒[/color][color=#5c4e3f]▒[/color][color=#282725]█[/color][color=#070f17]█[/color][color=#03040b]██[/color][color=#353127]▌[/color][color=#645441]╢[/color][color=#64533f]╢▒╢╢╢[/color][color=#151515]█[/color][color=#1b1c19]█[/color][color=#635340]╣[/color][color=#635442]╢╢╢▒╢╣╣╢╣╢╣╢╫[/color][color=#624d38]╣╢╢╢[/color][color=#5f4c39]╫[/color][color=#0c0d10]█[/color][color=#1e1d18]█[/color][color=#5a4127]▓[/color][color=#635443]╣[/color][color=#635647]╢▒▒[/color][color=#62482c]▓▒╢[/color][color=#202126]█[/color][color=#09121b]█[/color][color=#151e2b]█[/color]                                                                                                                                              //
//    [color=#050713]█[/color][color=#050712]███[/color][color=#60523d]╢[/color][color=#5a4d3c]▒[/color][color=#5c4b3a]╫╣[/color][color=#5e5142]╢[/color][color=#4c4235]▒[/color][color=#070b10]█[/color][color=#5a4c3c]╣[/color][color=#5f5141]╢[/color][color=#5f5141]╢[/color][color=#5e472e]▓╢╢╢╢╢╢╢╢[/color][color=#5e4e3b]╣[/color][color=#605342]╢[/color][color=#605343]╢╢[/color][color=#3a342b]█[/color][color=#101413]█[/color][color=#5f4e3b]╣[/color][color=#625344]╢[/color][color=#615243]╢[/color][color=#5b4b3a]▒[/color][color=#604c36]▓[/color][color=#625343]╢[/color][color=#252321]█[/color][color=#070f16]█[/color][color=#03050a]██[/color][color=#413a2f]▌[/color][color=#675035]▓[/color][color=#685237]╣[/color][color=#64543d]╢[/color][color=#645340]╢╢[/color][color=#604b32]▓[/color][color=#161513]█[/color][color=#342e25]▌[/color][color=#64543f]╢[/color][color=#645340]╢╢╢[/color][color=#624a2c]▓╢╢╢╢╢╢╢╢[/color][color=#66513a]╢[/color][color=#634e37]╣[/color][color=#635341]╢[/color][color=#635441]╢╢[/color][color=#604a34]▓[/color][color=#090e0e]█[/color][color=#372f22]▌[/color][color=#604b31]▓[/color][color=#645747]╣[/color][color=#645748]╢╢╣[/color][color=#645442]▒╣╬[/color][color=#0c131a]█[/color][color=#09131b]█[/color][color=#485c74]▒[/color]    //
//    [color=#212739]█[/color][color=#242837]█[/color][color=#1d2230]█[/color][color=#070c13]█[/color][color=#564834]╣[/color][color=#5e4d39]╢[/color][color=#5e4b37]▓╣[/color][color=#5e5040]╣╢[/color][color=#080e10]█[/color][color=#5a4a3a]╣[/color][color=#5f5040]╣[/color][color=#605141]╢[/color][color=#5e4e3b]╢╢╢╢╢╢╢╢╢[/color][color=#5f4d3a]╢[/color][color=#605240]╢[/color][color=#605140]╢╣[/color][color=#3a3329]█[/color][color=#1c1c18]█[/color][color=#605040]╣[/color][color=#615242]╣╢╢╢╢[/color][color=#1e1d1a]█[/color][color=#070f13]█[/color][color=#060a10]██[/color][color=#4b3f30]▒[/color][color=#65523a]╢[/color][color=#665238]╢[/color][color=#645035]▒╣╢[/color][color=#634c32]╢[/color][color=#0e0d0e]█[/color][color=#423626]▌[/color][color=#66523a]╢[/color][color=#665239]╢╣╢╢╢╣╣╫╬╬╬╣╣╢╫╣[/color][color=#645035]╢[/color][color=#59412c]▓[/color][color=#0b0b0a]█[/color][color=#473a29]▌[/color][color=#634b30]▓[/color][color=#655035]╣[/color][color=#65563f]▒[/color][color=#5b4e3b]▒▒[/color][color=#655944]▒[/color][color=#665a46]▒[/color][color=#5a4c3d]▒[/color][color=#0a1318]█[/color][color=#0b1926]█[/color][color=#4d6078]▒[/color]                                                                                                                       //
//    [color=#3d465d]╣[/color][color=#42485a]╣╫[/color][color=#060c13]█[/color][color=#4d3f2b]▌[/color][color=#604f36]▒[/color][color=#63523a]╣[/color][color=#63523c]╢╢[/color][color=#604c35]╢[/color][color=#201a12]█[/color][color=#58452c]╣[/color][color=#655037]▓[/color][color=#645137]▓▓╢▓╢▓▓▓▓▓▓▓[/color][color=#685031]▓[/color][color=#684e2d]▓[/color][color=#543e21]▓[/color][color=#46321b]█[/color][color=#694f2f]▓[/color][color=#6a5231]▓[/color][color=#6c5534]▓╢[/color][color=#6d5737]╣[/color][color=#6b583c]╢[/color][color=#1e1e18]█[/color][color=#060e13]█[/color][color=#050a0e]██[/color][color=#534730]▒[/color][color=#6d5d3f]╢[/color][color=#6d5c3e]╢▒[/color][color=#6d5a3b]╫[/color][color=#6d5634]╢[/color][color=#6c5434]╣[/color][color=#574127]╢╣[/color][color=#6b583a]╢[/color][color=#6b583c]╢╢╢╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢[/color][color=#685336]▒▒╢[/color][color=#635a48]╣[/color][color=#625a4b]╢▒[/color][color=#625b4e]▒▒[/color][color=#38362f]█[/color][color=#091319]█[/color][color=#1d2d3e]▌[/color][color=#50627e]▒[/color]                                                                                                                                                                                                                                          //
//    [color=#3e485f]╢[/color][color=#444b5d]╢╫[/color][color=#060c14]█[/color][color=#4b402d]▒[/color][color=#66553c]╢[/color][color=#66553d]╢╢╫[/color][color=#695232]▓[/color][color=#6a5331]▓▓▓▓[/color][color=#694f2d]▓[/color][color=#694e2a]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#6e5430]▓[/color][color=#6e5734]╢▓[/color][color=#6c583c]╢╣[/color][color=#191a16]█[/color][color=#060c12]█[/color][color=#04060a]██[/color][color=#614a2d]▓[/color][color=#6d5a3a]╣[/color][color=#6d5b3a]╢▒╫[/color][color=#6d5735]╣╢╣╢╢╢╢╢╢╢╢╢[/color][color=#685335]╢╣╢╣╣╢╣[/color][color=#6a573a]╣[/color][color=#6a573b]╢╢╢╢╢╢[/color][color=#665841]╢[/color][color=#625a4b]▒[/color][color=#615a4c]▒▒[/color][color=#625b52]▒▒[/color][color=#1e211f]█[/color][color=#071219]█[/color][color=#32445b]▌[/color][color=#516483]░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#3e495d]▓[/color][color=#434b5d]╢╫[/color][color=#040a12]█[/color][color=#36281c]█[/color][color=#65543a]╣[/color][color=#66563d]╢[/color][color=#5c4a33]▒╫[/color][color=#664d2c]▓▓[/color][color=#674d2b]▓[/color][color=#644828]▓▓▓▓[/color][color=#624627]▓[/color][color=#654b2d]▓[/color][color=#664c2d]▓▓▓▓▓▓[/color][color=#685031]▓[/color][color=#685133]▓▓[/color][color=#6b5535]▓▓▓[/color][color=#6a502d]╣▓╫[/color][color=#6a583d]╣[/color][color=#63533b]╢[/color][color=#151714]█[/color][color=#050c10]█[/color][color=#090b0e]██[/color][color=#6a5d41]╢[/color][color=#6c5e44]╣╣▒[/color][color=#69583d]╢[/color][color=#654d2d]▓╢[/color][color=#6c5837]╢[/color][color=#6d5938]╣╢[/color][color=#644827]▓╢▓╣[/color][color=#655033]╢[/color][color=#635136]▓[/color][color=#675538]╢▒[/color][color=#67543a]▒▒╢╢▒▒▒[/color][color=#64553f]▒[/color][color=#60472d]▓▒▒▒[/color][color=#604c37]╫[/color][color=#5d513f]▒[/color][color=#615a4d]▒[/color][color=#615b50]▒[/color][color=#605b52]▒▒▒[/color][color=#0b1013]█[/color][color=#060f15]█[/color][color=#465a77]░[/color][color=#516583]░[/color]                                                                                                                                                                     //
//    [color=#3d4a5f]▓[/color][color=#424a5d]╣╫[/color][color=#03070e]█[/color][color=#332d22]▌[/color][color=#64553e]╢[/color][color=#64553e]╢╣[/color][color=#645645]╣[/color][color=#674e2f]▓[/color][color=#685031]▓[/color][color=#685436]╣[/color][color=#685639]╫╢▓[/color][color=#664c2a]▓[/color][color=#63492a]▓[/color][color=#67573b]╣[/color][color=#69593d]╢╢╢╣[/color][color=#685a42]╣[/color][color=#685c45]╢╣╣╢[/color][color=#675c47]▒╢╣[/color][color=#6b5432]▓[/color][color=#6c5737]╣[/color][color=#6c5737]╫╣[/color][color=#675840]╣[/color][color=#121614]█[/color][color=#03090d]█[/color][color=#030609]██[/color][color=#685c43]╢[/color][color=#6a5e45]╣╣▒[/color][color=#68573d]╢[/color][color=#685133]▓[/color][color=#6b5535]╣▒[/color][color=#6c5939]╢[/color][color=#6b593b]╢╢▒[/color][color=#6a5030]▓╢[/color][color=#635137]▓[/color][color=#685a42]╣[/color][color=#6a5c43]╣╣╣[/color][color=#665b48]▒╢╢╣╢╢▒╣╢[/color][color=#5f4f39]▒╣[/color][color=#5f4d39]▓[/color][color=#605a4e]▒[/color][color=#5f5a52]▒[/color][color=#605b53]▒▒▒▒[/color][color=#050b0f]█[/color][color=#050c13]█[/color][color=#4f6382]▒[/color][color=#516583]░[/color]                                                                                                                       //
//    [color=#3c495e]▓[/color][color=#41485b]╣▓[/color][color=#04070c]█[/color][color=#2e271d]▌[/color][color=#64553c]╣[/color][color=#66563f]╢╢[/color][color=#655947]╣[/color][color=#66543a]╣[/color][color=#634f34]▓[/color][color=#634e33]╣[/color][color=#66543a]╣[/color][color=#67553a]╣▓[/color][color=#695433]▓[/color][color=#61482b]╣[/color][color=#67563a]╣[/color][color=#68553a]╣╢╢╣[/color][color=#675b45]╣[/color][color=#665a44]╢╣╢╢╢[/color][color=#665438]▒╢[/color][color=#695030]▓[/color][color=#6d5b3c]╣[/color][color=#6d5b3d]╢[/color][color=#695335]╢╣[/color][color=#0d0f0f]█[/color][color=#02070b]█[/color][color=#030609]██[/color][color=#6a5e45]╢[/color][color=#695d44]╣╣▒[/color][color=#69593e]╢╢[/color][color=#695438]╫[/color][color=#695435]╣[/color][color=#6a593c]╢[/color][color=#6a593c]╢╢[/color][color=#665336]▒[/color][color=#675338]▒[/color][color=#6b5a40]╢▓[/color][color=#685b45]╢╢╢[/color][color=#665b47]╣▒║╣╢▒▒▒▒╣[/color][color=#615b4e]▒▒[/color][color=#54402e]▓▒▒▒▒▒[/color][color=#514b41]▒[/color][color=#03090e]█[/color][color=#111c28]█[/color][color=#4f6381]▒[/color][color=#516583]░[/color]                                                                                                                                              //
//    [color=#3d4a5e]╫[/color][color=#414658]╣▓[/color][color=#080a11]█[/color][color=#251e16]█[/color][color=#63533b]╣[/color][color=#64543d]╢╣[/color][color=#645846]▓╢╢[/color][color=#614d33]▓[/color][color=#635035]▓[/color][color=#65543b]╢[/color][color=#665539]╣▓[/color][color=#644f30]╢╣╢[/color][color=#67583f]╢[/color][color=#68593f]╢╣╣▒╢▒║[/color][color=#675c47]╣[/color][color=#675b47]╢╢[/color][color=#685337]▓[/color][color=#6d5d3f]╢[/color][color=#6d5c3f]╣╢╣[/color][color=#06090a]█[/color][color=#020509]█[/color][color=#020508]██[/color][color=#695d47]▒[/color][color=#68583d]▒▒▒[/color][color=#6b5b41]╢[/color][color=#6b5c41]╣╢[/color][color=#604426]▓[/color][color=#685537]▒[/color][color=#6a593d]╢[/color][color=#6a593e]╢╢╢[/color][color=#6b5b42]╣▓[/color][color=#675d4b]▒╢╢╣[/color][color=#645c4a]▒[/color][color=#625844]▒╢[/color][color=#635945]╢[/color][color=#645b48]╢[/color][color=#625b4b]▒╢▒[/color][color=#605b4f]▒▒╢[/color][color=#584633]▓▒▒▒▒╢[/color][color=#393630]▐[/color][color=#03090e]█[/color][color=#243344]▌[/color][color=#506485]▒[/color][color=#516687]░[/color]                                                                                                                                                                     //
//    [color=#3d4b5d]╫[/color][color=#3f4656]▓▓[/color][color=#101218]█[/color][color=#1b1611]█[/color][color=#615039]╣[/color][color=#64533b]╢╣[/color][color=#635645]▓╢╢╢[/color][color=#604e34]▓[/color][color=#624f35]▓[/color][color=#655439]╣[/color][color=#665539]╣▓╣[/color][color=#69593c]╢╢[/color][color=#67583e]╢╣[/color][color=#665a45]╣╢╢[/color][color=#685a43]╣╢╢╣╢[/color][color=#69553b]╣▒╢[/color][color=#6c583a]╢[/color][color=#6a5a40]╣[/color][color=#030509]█[/color][color=#020307]██[/color][color=#090a0a]█[/color][color=#695d48]▒[/color][color=#6a5c44]╣╢▒[/color][color=#6a5a43]▒[/color][color=#6b5a3e]╣╢╣[/color][color=#665136]╫[/color][color=#675439]╣[/color][color=#69593e]╢[/color][color=#69593e]╢╢╢[/color][color=#685a43]▓[/color][color=#695d4a]╢╢╢╣╢╢╣╣╢╣[/color][color=#625b4c]╢▒▒▒╢[/color][color=#564635]▌▒[/color][color=#5f5c52]▒[/color][color=#5f5a4f]▒▒[/color][color=#615948]╢[/color][color=#20201d]█[/color][color=#02080d]█[/color][color=#384b66]░[/color][color=#506687]░[/color][color=#516788]░[/color]                                                                                                                                                                                                                                          //
//    [color=#3d4c5e]╫[/color][color=#3e4555]▓▓[/color][color=#12151a]█[/color][color=#16130e]█[/color][color=#605138]▓[/color][color=#625137]╢╣[/color][color=#625542]▓[/color][color=#64543e]╢[/color][color=#64553c]╢╢╢[/color][color=#604b2f]▓[/color][color=#5f4d32]▒[/color][color=#65543a]╣[/color][color=#64543a]╣▒[/color][color=#6b5a3d]▓╫[/color][color=#644825]▓[/color][color=#675437]╣[/color][color=#665944]╢[/color][color=#66573e]╫╣╢╢╢▒╢[/color][color=#6a5538]╣▒[/color][color=#6d5c40]╢[/color][color=#6c593d]╢╣[/color][color=#020409]█[/color][color=#020206]██[/color][color=#171512]█[/color][color=#695d48]▒[/color][color=#695c47]╢▒▒[/color][color=#6b5b43]╣[/color][color=#6b5a3e]╣╢╣╢[/color][color=#624b31]▓[/color][color=#685538]▒[/color][color=#625238]▒[/color][color=#69583e]╢[/color][color=#69573d]╢[/color][color=#62523a]▒[/color][color=#6a5c45]╣[/color][color=#6b5d46]╢[/color][color=#685941]╢╣╣[/color][color=#645740]▒╣[/color][color=#645c49]▒[/color][color=#645b49]╢▒▒▒▒▒[/color][color=#5e5546]╫[/color][color=#594d3d]▌[/color][color=#5e5b54]▒[/color][color=#5e5a51]                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract pbn is ERC721Creator {
    constructor() ERC721Creator("PhotosbyNumber", "pbn") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}