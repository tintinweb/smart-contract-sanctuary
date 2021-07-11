// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IAsciiArt.sol";

// ................'''..''',,'''.....''',,,,'................  ..   ...............''.......  ...    ..........             .
// .................''...'''''''....'',,,,'''................      ..........................  ...   .....  ...   .
// ..............'''''''......'''''',,,'''......''............          ..........................          ..........
// '',,'......''''''''''..''''''',,''''.......',;;'.........       ..     ..    .................  .    ..  .   .......
// coxxc'.....''''''''..',,,,',;:cc;'..'.......'''..... ...  .     ......'''''''''','''.........     .....        ...
// okKXk:...........''..',,,,,,;:c:,'.................   ....',;;::cllloddxxxkkkkkkkkkkkxxdoolc;,'.....''.
// loddo;............''..',,,'''',,'............... ..',;cllooddddddxxxxkkOOOO000OOOkkkxxxxxxxxxddoc;,......              ...
// ;::;;'............','''''''''''''.............';cloddddooooddxxkkOOO0000OOkkkxxdddooooooodddddddddool:;'..                                ..
// .'.................,,,'.',,,''''..........':ldxxddoooodddxxkkOO000000Okxxddddddddddddddddddddddxxddddxxxoc,..
// ...................'''',,,',''.........;ldkkxdoooooddxkkOO0000000OOkxxxxxxxxxdol::;,,'''.':looooodddxkkkOOOxl,.         .'.
// ...................'.'',''','.......,lxOOxdollooddxkkOO00KKK00OOkkkkkkxdoc;,,'.............;lllllllllodxkO0KK0d;.       ...           ...
// ...................''''''',,''....:dOOkxollloodxxkO000KKKKK0OOOkkOkdl:,.....',;;::cc:cc:;'',clllllllllllldxO0KK0d,.                   ..
// ..............'''''',,'''',,''.';dOOkdoccllodxkkO00KKKKKK0000OOkdc,.....',:cclllllooooooollllllllllllllllllodk0K0Ol.
// .............'''''',,,,''',,,,:dOOkdoccllodxxkO00KKKKXKKKKK00Oxc.  ..',:clllllooooooddddxddddolllllllllllllllldkO0Od,.
// ........''''''''''',,,,''',,:okOkxolccloddxkO00KKKKKKKXXXKKK0xo:'..';:cloooooooodooodxdxkOkkkdollllllllllllllllodkkkd;.
// ''.....',:c:,,',,,',;;;;;,;cxOOxolccloodxkO00KKKKKKKKXXXKK00KKOdl:::clooooddddddxxdodkkx0KK0kdddddooooooooooolllloxxxd;.                        ..
// ;;,'''';cdOkl;,,,'',;::cc:lkOkdlcccooddxOO0KKKKK000KKKKKOkxkOKK0kxdooooodxddxxxdxxxddkO0KXKOxddddddxkxxxdddooooolloxxdo;.      ......            .
// ,;,,,,,;cldoc:;;;,,;:cllldOOxdl::loddxkO0KKKXK00000000kxkkxkkO0K0OkxddddxkkxxkOOkkOkxOKXX0xoooddoodk000Okdddooooooldddol'    ...';:c:'.
// '',,,,,,;;:;;;;;:::cllllxOOxoc:clodxxk0KKKXKKOOOOOOkdlcd0OkOOkO0KKKOkkkxxkO0OO00OO0OO0KK0kxxxkkkxdxO0KKKK0kxddooooooddooc.   ..,:lx0Kx;.
// ;;',,'''''',,,;;:ccllloxOOxoc:clodxkO0KKXXK0kkkkkkxl:;:d0OkOOkkkO0KOkkxddxkOOkOOOkkkkkOOO000OOO00OOOOOO0000kdoooooolodoll;.  ..,:ldkOxc..      ....
// ,,,,,,'...'',,;;:ccllldOOxoc::loddxO0KKXXKOkxkkkxocc::ck0kkOkxdoddddxddddxxxxkkkkxxxkkkkkOOO00000OOOOkkkkkOkxdxkOOkxxxdllc.  ...';:;;,'...        ....
// '''''''..'''',,,;:cccoOOxoc::codxkO0KKXX0kxxxxxdlc:llcoO0kxOkkkxxxxxdddxxddxxxxxdddxxxxxxkxxxxxxxxxxxxkkkxxxxxkkkkkkkkxocc;.  .......  .....         .
// .''''''''',,'',,,;:;ckOkdc:;coddxO0KXXX0kxxxxxdlcccododO0kxkOkkddxkkxxxxxxxxxxxxxdxdddddxxddoooddddddddddddddxxxxkkkkkxocc:.       .      ..... ...  .
// ...',,''''',''''',,;oOOxl:;:lodxk0KXXX0kxxxxxdl:clldxdxOkkkkkkOxoddxOkkkxkkkOOOO000OOOOOOkkkkkkkkkkkkkxxkkxxxxxxxxxxkkxoc::,.      . ... ......  ..
// .....'''''''...'''.:kOxo:;:lodxk0KXXX0kxddxdolc;clllcclclxxddxOko::xOx00kodxkOOOOO0K00000000000000000OOO00OOOOOOOOOOOOkoc::,.         ..  ...    . ..
// .........''.......'oOkdc;;coddkOKXXX0xdddddl:cl:lc:;;;;;okkdxkOxl:lOOkKXOoccoxkOxdxkOOOO00000KKKKKK0000000000000000000kdc::;.           ..
// ..................;kkdl:;:lodxO0XXX0xdddddolll:::;';clxkkOkxkkdoldOOxOKK0dc:coxxxxdxxkkkkkkOOO0000000000OOOO0000OOkkxoll:;;,.
// ..................lkxo:;;cldxk0KXXKkdddddlcol::cccloodk00OkkdoclxOkxkO0OKOdoooooodddddddxxxxxxxkxkkkkkkOOOOOOOkkkxxdolll:,,,....          ....
// .................,dkdc;,;lodkOKXXKkddddddc;::;cllcccclk0OOkxddk00xdk00kOKKkdxxxddolllodxxkkkOOO0OOOOOOOOO000KKKKKKKK000d;''...             .....
// ......';,........cxxl:,,:ldxO0KXXOdddoddo::::cccllcoodOOkxdoxXNKOdxO0OkOK0dcldxxxxdxxxxkO000KKKKKKKKKKKKKKKKKKKXXXXXKKKkoccllc:,...          .,;.
// ......','.......'dkoc;,;:ldkOKXXKxddoddl:;clllclcc:cld0Odood0XK0kdk0OOkO0x:;lk0OdcclodxddxxkkOOOOO000000000000000000000OOOO00OOOkdl;'.       ..'.    .
// ................lxdc;,,;codkOKXXkdodddo:,;clc,,;;ccoxkOkooxOK00Oxk0OOOkkxooxk0OOkddxkkOOkkkxkkkkkOOOOOOOOOOOOOOkkxxxxxkkkOkkxxxxxkkxdo:'.           ..
// ..............,odoc,'',;codkOKK0dooodo:,;c:;;;::clodddxdodk00OxddOkkOkdxxxkOkOkkkOOOOOOOOOOOOOO000000000000K0Okddddddddddollllc;::coxxdoc,.         ..
// .............cddl:,''',;codxk00koooooc,;:;',ccc::odllcccokkkxxdoxxdk0kkkkkkkkkkOOkxdddkOOO00000000000KKKKKXXXK0OOxdoooooodddddl;,,.;xOdddo:.     .....
// ...........'oxo:,,''',,:clodxkkdooooo;,;''.,::c:oxc:oo::okOO0KK0OkOOOOOOOkkOOOkxoccc:lxO00O000000O000000000KKKXXXXKOxolooooool:;,.'oOdodddd:.       ..
// ...........lko:,'''',;:llooddxxdooool,,,,'',,;;;collodooxkkkkOOOOOOOOOOOkxxdxxolldoc:oOkkOkdxO0000O0OOOOO0O00000KKKKK0kdlc::c;'',cxOdcoxxddl. .     ..
// '.........;ol:,'',,;:codddxxxxdooooo;..,'.''''..,;:::cldO00O0000000000Odlcllododkko:;oO0OkkddOO000OOkkOkOOkOOOOOOOOO00KKOkdlc;;dO0koloxkxxxl. ....  ..
// ''.......'::,,,,,,;:lodxkkkkkkdoolol,..''....;,','''.';:lxO00K000O00Oxc;;::coxdllxOo:x0OOkkkOOkkkkkkkkOOkOOOOOOOOOOO00000000OkO0OdooxO0OOkxl.  .......
// '''......,c,...',;:codxkO00000xllllc'...''''.,';;'''''',;cx0KKK00OOOkdooolllll:::ckkdO0kOkxxO0O0KKKKK00000000O000000000KKKK00KKOxdxO0KK0xdd:.   ......
// '........,:,......,:ldxO0KKKKKxlccc:'.....''.''',,'';;,,'':dxk0KK00OOOOOOOOkxl;;::okxOOkkxxxkOKXXXKKKKK00000000000000KKKKKKKK0OxxxkkOOkdloo'    .   ..
// .........':'.......':ldk0KXXXKkllc::,...............',,,..';::ldxO000OOOkOOOkxoododkO000000000KKKKKKKKKKKK00OOkkkOKKKXXXXXX0kxdddddxxdolloc.       ...
// ..........,'.........;ldk0KXXX0dlc:ccclooll:;''..''',,''.''.....;oxO000OOOOOO0OOOOOOOOOOOOOOOO00O000000OOOkxdolccldOKKK0Oxdollloodddollllo,.       ...
// ..........''....;cc'..,ldxO0KKKOdollodkOOkxdoooolllcc:::;;::;;;,,;:ldooddxkkkkkkOkkkOOOOkkkOO000KK0Okxdoddxxxxc,;cdkxdlc::clooddddoolccloc'.....    .
// ...........''..;;,,,...'codxkOOOkkxxkkkkxxkkdddxdlllloddddddddxxddddolc:;;;;;;:cc::cllcc;,;clcloxO0kdolc:;:cldo;..cxdcclodxxxxxdoollccclo;.......
// ............''.;::,.....,cloodddooox0KKK0Od:;coddodxxkxxxxddddddddxxxddoc,..........'...........;x00Oxolc;'.'cddc';oddkOOOkkxxdoolcc:ccol'............
// ............',.',;;'.....;:::c:;,'';dKXXXKo';olldooxxxxxxxxdddddddddxddooc:;;,;:cccc:;'..     ..lkkOxddxdo:'.,dxdl:ldxkOOkkxddoollc::coo:,','.........
// ............;:..',,'.....:c;,'...  .'oKKK0x:;odlllcllcclooddooooooddddddddddddxxxxdolc:;,''...':lool;:oddolc:lxkxdoodxkkkkxddollc::;:ldl,,;;;,'.......
// ...........'oo'...'... .;lc;..       ;xkkxdc;clolllooolllc::::ccloddddxxxxxxxxxkkkxxddooollc::cc:;,...',,''',:oxxddddxkkkxddollc:;;:loo:,;;;;,,'......
// ...........:xdc,.   ...'ll;.         .cooolc::::ccclooooolc:,,''',,;lxOOOOOOOkkxxxxxxxdddooooolc;... ...''.. .,ododddxkkxdoolc:;;;:lodc::;;;,''''.....
// ..........,dkdoc,.   .'ldl'           .:ccc:::;,',,;::;;,''......,:oxkxollclllooddxxkkkkkxxddol:,....',;,,'.  .coododxxxdoll:;,,,;codc;;;;;;,...,,'...
// ..........lkxdol;.   .lddc.       ... ..,:c::;;;,''.'.......';:ldxdlc;,,,,;;:cloodxxxxkkkxxddol:'...;cooc'..  'clolldxddolc:;,,,:lodc;,,;:cl:'..';,'..
// .........;ddool:,.  .cxxd:.       .''....',;:ccccccccccclloddddlc;,,'''''',,;:loodxxxxkxxxxddol:'..,coodl.. .';clccoddolc:;,,,,:ldoc;;;,;:cc;,''','...
// .........:dolc:,.. .cxkxo;.      ..';;;'...';::ccccllllloolllc:;;;,,'''..'',,:cloddxxxxxxxxddoc;...':cc:.. .';:l:;ldolc:;,,,',:ldo;',::,','''..',,,...
// .........;oc:;'.. .:xOOxl'.     ..'',;ccc;,',,;;::ccccclllllllllc:;,,''...''',:coodddxxxddddol:,....,cl;. ..',;;:lolc::,,,',;codl'..';c:;'........'..'
// .........'c:'.....,dO0kdc.     ..,:ccccllooolccccclloooddddddooolc:;,''.....',;:cloooooooooolc;'.....:do:,...';cllc:;,''',,:ldo:.....,:::;,'''.......'
// ..........;;.... .lO0Oxl,.     ..;cloooooddxxxxxxxxxxxkkkkxxxddoolc;,'.....'',,;:cllllllllllc:;'....'lxdo:..;cllc:,'....,;codl'.  ....',;;;,'.........
// .....  ....,..  .:k00ko;.      ..;loooodddxxkkkkkkOOOOOOOOOkxxdool:;,'.....'''',;;::ccllcclcc:;,....cxxdl'.;cc:;,'....',:ldo;.      ................''
// ...'.   ....'. .'o0Kko;..      ..;looddddxxkOOOOO000000000Okkxdolc;,'........''',;;::cclllllcc;'....:ooc,..,,'.......,:lddc.    .........    . .......
// ...       .... .:kK0d:..      ..':loodddxxkOO00000KKKKK00OOkxdolc;,'..........',,;;:cclloolllc:'.....,,............,:looc'.     .....     ......  ....
// ....      . ...,dKKOl'. ........';lodddxxkkOO0000000000OOkxddoc:;,'..........'',;::cclllooollc;'.................,:loo:..        .  .... ........   ..
// ....        ..'lOXKk:. .':lool:'.,codddxxkkOOOOOkkkkkkkxxdooc:;,'............',;:clllllooolll:,...............';cool;.             .'cc'.    ..... ...
// ......     . .;x0K0d;..'coxkkko,.';odddxkkkOkkkxxxddddoollc:;,'...... ......',;:cllllllooollc;'.............,:lolc,.               ..''..      ......,
// :cc:,....  ...:dxkxl'..,:cclll:...;oddxxkkkOOkxxdooollc::;,''......  .....'',;:cllllllooooll:,'........'',:ccc;'....                .           .  ...
// xkOxo:'..    .;clc;'......''''''..,oddxxkkOOOkkxdollc:;;,'...............',,;::clllloooooolc,'....',,;ccc:;,.    ...                       ...   ...
// kKXKko;..     .','.          .....:oddxxxkOO0OOkxdolc;;,'.............'',;:::cclllllooooolc;'...,:ccc:,'.       ...                        ...... ..
// dkkxdl;..      .;,....          .'lddxxxxxkO000Okdooc:;,'...........',;:ccclllllllllllllll:'..';;'...           ...                       ........
// :ccc:;'..      .;c,';;'''... ...':oddxxxxxxxk000Oxdol:;,'.........'',;ccllllooolllllllllc:'..':,.               ...                ...    .. .. ...
// '''''....       .cccllcclc;'.':::lodddxxdddddkO0Okdolc;,'........',;:cllooooooollllllcc:,'..';;.                ....               ..... ..
// ........        .;ol:::cllc:,,;:cloooddooolloxkOOkxolc:,''.......',;:cloooooollllc::;;,'...',:'                 ....                 ......  ......
// ......          .,ooc;,;;,,,,,,''';:llllccccloxkkkxolc:,'........';:clooooooolllc;,'......',;'                  .''.                ...........
// ....             .:lc;;:;,,;clol:,...',;:::::ldxxxdolc;,'........,;:clllolloolc:;'.......';:.                   ..'.                  .........
// .        .     . ..;;;,;;;;;;;::;,'.''''''..':ldddolc:,'........',;:clllllllc:;,'......',:;.                    ..''.              ...... .....
// .  ..             ..''........''...',:loo:'..;looolc:,'..........',;:cccc::;;,'......';cc,.                      ..'.            ..';:,.   ...
// ..  .              .....       .....,loddl:,,:loolc:,'............',,,;;,''.......',;cc;.                      ....''.          ..'ckOd,.
//  .......           .................,:oooc:,,:clcc:,'.........................',;:cc:'.                     ........',..         .'cdxo,.
//   .                ....';clolll:;''.',:cc:;,,;:::;,'....................',;;::cc:,'.         ........     ..........',,'.        ...''..
//   ..               ....;ldxkOOkxdl:,'',,''''',,,,'................'',;::c::;,'...        ....................'',,,'''',;,..       ..                .
//  ... ...           .'..,codxkOkkxdoc;'.....................',,,;;;;;;,'....            ....'''''............',;;::;,,'',,;,.
//      ....          .''..';:clooooolc;'............'',,,,,,,,'......                   ...'',,,,,,'.........';;:cccc:;;,,,,;;'.
//                     .......'',,;;:;,'.......',,,,,,,'......          .........       ...',,,;;;;,'........';:cllllllc:;,,',;:;.
//                         ........'......'',,,,'....      ............''',,'.....    ....',;;;;;;;,'......'',:cllooooollc:;,'';::;.
//                               ..............         .......''',,;;;:::;,'......  ...'',;;;:::;;,''...''',;cllooodddooolc:,'',;::,.
// .                                             .     ...',,;;;;::ccllllc:,'.....  ...'',;:::::::;,''..''',;cloooodddddddoolc;'.',:c:'
// .              ....                  .        ...   ..,;:cccclllooooolc:,'.... ....',,;;:::::::,,'''.'',;:clooodddxxxxdddool:,..';cc;.
//                ....       ..                  ...   ..,:cllllooodddoolc;'....  ....',,;::cccc:;,,''''',;:cloooddddxxxxxxdddolc,..';:cc'
contract ArtExample {
    address public asciiArtAddress;

    constructor(address _asciiArtAddress, address mintTo) public {
        asciiArtAddress = _asciiArtAddress;
        IAsciiArt ascii = IAsciiArt(_asciiArtAddress);
        ascii.mint(mintTo);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IAsciiArt {
    function mint(address mintTo) external;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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