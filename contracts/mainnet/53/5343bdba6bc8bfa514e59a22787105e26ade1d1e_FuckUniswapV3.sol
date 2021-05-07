/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.5.0;

// https://www.fuckv3.com/----------------------------
//
//                                                                                                                               
//                                         ,--.                      .--,-``-.                                                    
//    ,---,.               ,----..     ,--/  /|                     /   /     '.                                                  
//  ,'  .' |         ,--, /   /   \ ,---,': / '               ,---./ ../        ;                                                 
//,---.'   |       ,'_ /||   :     ::   : '/ /               /__./|\ ``\  .`-    '                                                
//|   |   .'  .--. |  | :.   |  ;. /|   '   ,           ,---.;  ; | \___\/   \   :                                                
//:   :  :  ,'_ /| :  . |.   ; /--` '   |  /           /___/ \  | |      \   :   |                                                
//:   |  |-,|  ' | |  . .;   | ;    |   ;  ;           \   ;  \ ' |      /  /   /                                                 
//|   :  ;/||  | ' |  | ||   : |    :   '   \           \   \  \: |      \  \   \                                                 
//|   |   .':  | | :  ' ;.   | '___ |   |    '           ;   \  ' .  ___ /   :   |                                                
//'   :  '  |  ; ' |  | ''   ; : .'|'   : |.  \           \   \   ' /   /\   /   :                                                
//|   |  |  :  | : ;  ; |'   | '/  :|   | '_\.'            \   `  ;/ ,,/  ',-    .                                                
//|   :  \  '  :  `--'   \   :    / '   : |                 :   \ |\ ''\        ;                                                 
//|   | ,'  :  ,      .-./\   \ .'  ;   |,'                  '---"  \   \     .'                                                  
//`----'     `--`----'     `---`    '---'  ,--.                ,--,  `--`-,,-'                                               ,--. 
//    ,---,.               ,----..     ,--/  /|              ,--.'|   ,---,                      ,---,        ,---,.       ,--.'| 
//  ,'  .' |         ,--, /   /   \ ,---,': / '           ,--,  | :  '  .' \            ,---,  .'  .' `\    ,'  .' |   ,--,:  : | 
//,---.'   |       ,'_ /||   :     ::   : '/ /         ,---.'|  : ' /  ;    '.         /_ ./|,---.'     \ ,---.'   |,`--.'`|  ' : 
//|   |   .'  .--. |  | :.   |  ;. /|   '   ,          |   | : _' |:  :       \  ,---, |  ' :|   |  .`\  ||   |   .'|   :  :  | | 
//:   :  :  ,'_ /| :  . |.   ; /--` '   |  /           :   : |.'  |:  |   /\   \/___/ \.  : |:   : |  '  |:   :  |-,:   |   \ | : 
//:   |  |-,|  ' | |  . .;   | ;    |   ;  ;           |   ' '  ; :|  :  ' ;.   :.  \  \ ,' '|   ' '  ;  ::   |  ;/||   : '  '; | 
//|   :  ;/||  | ' |  | ||   : |    :   '   \          '   |  .'. ||  |  ;/  \   \\  ;  `  ,''   | ;  .  ||   :   .''   ' ;.    ; 
//|   |   .':  | | :  ' ;.   | '___ |   |    '         |   | :  | ''  :  | \  \ ,' \  \    ' |   | :  |  '|   |  |-,|   | | \   | 
//'   :  '  |  ; ' |  | ''   ; : .'|'   : |.  \        '   : |  : ;|  |  '  '--'    '  \   | '   : | /  ; '   :  ;/|'   : |  ; .' 
//|   |  |  :  | : ;  ; |'   | '/  :|   | '_\.'        |   | '  ,/ |  :  :           \  ;  ; |   | '` ,/  |   |    \|   | '`--'   
//|   :  \  '  :  `--'   \   :    / '   : |            ;   : ;--'  |  | ,'            :  \  \;   :  .'    |   :   .''   : |       
//|   | ,'  :  ,      .-./\   \ .'  ;   |,'            |   ,/      `--''               \  ' ;|   ,.'      |   | ,'  ;   |.'       
//`----'     `--`----'     `---`    '---'              '---'                            `--` '---'        `----'    '---'         
//                                                                                                                               
//                                                                                                                                
//                                                                                                                                
//
//.d00000000000000000000000000000000000000OkkkkOOOOOOOkkxoc'..,,'''.....         ......''...............',c:'........,:lok0KKXXXXXXXXXXXXXXXXKKKKXKKKKKK
//.d0000000000000000000000000000000000000Okxkkkxooolc::;;;'..''.......           ............................'......    .,oOKXXXXXXXXXXXXXXXXKKKKXXKKKKK
//.d000000000000000000000000000000000000Okdddo:,....... .........                                      .............     ..;oOKXXXXXXXXXXXXXXXXXXXXXXKKK
//.d00000000000000000000000000000000000Okdll:'.......',....                                              ....................:xKXXXXXXXXXXXXXXXXXXXXXKKK
//.d0000000000000000000000000000000000Okdlc;.........'....                                                     ..........''...ckKXXXXXXXXXXXXXXXXXXXXXKK
//.d000000000000000000000000OOOO00000Oxoc;,'..  ...'...                                                         ..............;d0KKXXXXXXXXXXXXXXXXXXXXK
//.d00000000000000OOOO0000OOOOOOO000kdl:;,;,.  ......                                                               ......  ..cxO0KXXXXXXXXXXXXXXXXKKKKK
//.d00000000000000OOOOOOOOOOOOOkkxddoll:,;;'.  ..                                                                ..  ...... ..,oxO0KKXXXXXXXXXXXXXXXKKKK
//.d0000000000000OOOOOkxxxkkkkkxdlcclc:,....                                                                        ............,coxOKXXXXXXXXXXXXXXXKKK
//.d00000000000000OOkkkdlllooolc;,'.....                                                                                  ........,:ok0KXXXXXXXXXXXXXXXX
//.d00000000000OOkdlc:;:;,''........                                 ...................                                    ........,:dOKXXXXXXXXXXXXXXX
//.d00000000000Oxl:;;;,'...                           .................'''''''',,,,;;;,,'......                              .........;oOKXXXXXXXXXXXXKK
//.d00000000OOOxc:cl:,....                         ....''',,''''''',,,;;:::::::cccllllllccc:;,'......       .....              ........'ckKKKKXXXXXXXXXK
//.d000000000Okl;c:'.....                       ...',,;::::cccccccccccllooooddddddxxxxxxxxxxxdoc:;,'................              ......'cxOKKKXXXXXXXXX
//.o00O0000OOOxc,'..'..                      ...',;::clllloooodddddddddxxxkkkkkkkOOOOOOOO0000Okkxxolc:,',;;,''.........             .....'lOKKXXXXXXXXXX
//.oOOOOOOOOOko;.....                      ...';::cclloooodddddxxxxxxkkkkkOO00000000KKKKKKKKKK0000Okkkdolcccc:::;;;;,'..              ....;kKXXXXXXXXXXX
//.oOOOOOOOOkoc,...                      ...';:cllloooooddddxxxxxkkkkkkkOOO00000KKKKKXXXXXXXKKKKKK00000OOkkxxxdddooool:'..             ...'l0KKXXXXXXXXX
//.oOOOOOOOkdlc;..                     ...';:cllloooooodddddxxxxkkkkOOOOOO0000KKKKXXXXXXXXXXXXXKKKKKKKKKKK0000000OOkkxdl;'.             ...,d0KXXXXXXXXX
//.oOOOOOOOxolc'                      ...,;:cllooooodddddddxxxxkkkOOOOOO0000KKKKXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKK00Okkdl,.             ...cOKXXXXXXXKK
//.oOOOOOOOdoo;.                     ...,;:cllooooooddddddxxxxkkkOOOOO000000KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKK0OOko;..          ....,xKXXXXXXXXK
//.oOOOOOOkxdo,.                     ..',;:cllooooooodddddxxxxkkOOOOO00000KKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK00Od:.         .....'dKXXXXXXXKK
//.oOOOOOOkkkd;                     ...',;:cloooooooodddddxxxkkOOOOO00000KKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKK0x;.        .... .oKXKXXKKKKK
//.oOOOOOOOkkkc.                   ...',;;:clooooooodddddxxxxkkOOOO000000KKKKKKXXXXXXXXXXXXXXXXXNNNNXXXXXXXXXXXXXXXXXXXXKKKK0d,.       ......dKXXXKKKKKK
//.oOOOOOOOOOOd'                   ..'',;:cloooooddddddddxxxkkOOOOO000000KKKKKKKXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNXXXXXXXXXKKKK0o'.       .....c0KKKKKKKKK
//.oOOOOOOOOOOkc.                 ...',;;:clooooodddddddxxxxkkOOOO000000KKKKKKKKXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNXXXXXXXXXKKKOc..        ...:OKKKKKKKKK
//.oOOOOOOOOOOOd.                 ..',,;;:cllooooodddddxxxxxkkOOOO000000KKKKKKKKXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNXXXXXXXKK0x:....       .:OKKKKKKKKK
//.oOOOOOOOOOOOd'                 ..',;;::cclloooodddddxxxxxkkOOOO0000000KKKKKKKXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNXXXXKK0Oo,....       ;OKKKKKKKKK
//.oOOOOOOOOOOOd.                ...',;;;:cclllooodddddxxxxxkkOOOO0000000KKKKKKKKKXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXK0Od:'...   ..  ,kKKKKKKKKK
//.oOOOOOOOOOO0x'                ...',;;;::cclllooodddxxxxxxkkkOOO0000000KKKKKKKKKXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXK0Oxl;'...  ... 'xKKKKKKKKK
//.oOOOOOOOOOOOk:                ....',;;::cclllooodddxxxxxxkkkOOO000000000KKKKKKKXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXK0Okd:'...  ....'dKKKKKKKKK
//.okOOOOOOOOOOOo.               ....',,;;:ccllllooodddxxxxxkkOOOO000000000KKKKKKKXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXK0Okdc,........ 'dKKKKKKK00
//.oOOOOOOOOOOOOd.               ....'',,;::cclllloodddxxxxxkkOOO000000000KKKKKKKKXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXK0Okdl;......   'xKKKKK0000
//.oOOOOOOOOOOOOl.               .....'',;;::cclllloodddxxxxkkkOO0000000KKKKKKKKKKXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNXXXK0Oxdo:....     ,kKKKK00000
//.oOOOOOOOOOOOk:               ......'',,;::ccclllooodddxxxxkkOO000000KKKKKKKKKKXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNXXXXXXKOkdl:'.       ;OK00000000
//.oOOOOOOOOOOOkc.              ......'',,;;::cclllloooddddxxkkOO00000KKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNXXXXXXK0koc;'..     .cO000000000
//.oOOOOOOOOOOOOd'               .....'',,;;::ccllllllooodddxxkOOO000KKKKKKXKKKKKXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNXXXXXXXXK0xl;'..     .cO0000OOOOO
//.okkkkkkOOOOOOk:               ....''',,,;;:cclllllllooooddxxkkOO00KKKKKKXXXXKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOd:'..     .lOOOOOOOOOO
//.okkkkkkOOOOOOOd'             .....'''',,,;::cccccccccccclloodxkkO0000KKKXXXXKKXXXXXXXXXXXXXXXXXXKKKKKKKKK0KKKKKKKKKKKKXXXXXXXKKkc..      'dOOOOOOOOOO
//.okkkkkkOOOOOOOk:            .....''''',,,;;:::::;;;;;,,,,,,;:clodxkO00KKKKKKKKXXXXXXXXXXXXXKKKKK0OOOOOOkkkkOO00KKKK00000KKXXKKKOc..     .;xOOOOOOOOOO
//.lkkkkOOOOOOOOOkc.           .....''''''',,;;;,,,,,,'''...''',,;:cloxkO000KKKKKKKXXXXXXXXKKKKKKKK0OOOkkkkOO0000KKKKKKK0Okk0KKKK0Oc..     .ckOOOOOOOOOO
//.lkkkkkkOOOOOOOOo.           .....'''''''''''''',,,,,;;;;;;;;;;;;::codxkkOO0000KKKKXXXXXXKKKKKKKKK000000KKKXXXXNNNXXXXK0OkO0KKK0k:..     .okOOOOOOOOOO
//.lkkkkkkkkkkkkkkx:.          .......''.....'''',,;:cllooooollcc::::cllodxxkkkOO00KKKKXXXKKKKKKKKKKKKKKKKKKKKXXXXNNNNNXXXKK0000Oxc.      .;xOOOOOOOOkkk
//.lkkkkkkkkkkkkkkxl,           .............'''',;:clodxxxxxddolc::;;::clloddxkkO00KKKKKKKKKKKK0000OOOOOOOO0000KKKKKKK000Okxdoc;'.      .'cxOOOOkkkkkkk
//.lkkkkkkkkkkkkkd:'...           .................',,;;::cclllolc:;,'.'',,;:ccodxO00KKKKK0OOkkxdolcc:;;;;::clc:::;;;,,,''......     ..  .,ck000OOOkkkkk
//.lxxxkkxxkkkkkd:'....                           .............''.....    ......,:lodxxxdoc;,'...........',:cloolc:;;;;,,,,,,,'..    ..  .,lddx00OOOOkkk
//.lxxxkkxkkkkkko;.....                  ........''',,,,;:clllc:,''.........       .......   ..,;:::;;;,;;;:codkOOxl;,,,,;;;:cc:,,,.     'okxclk0OOOOOOk
//.lkxxxxxkxkkkkd:......                ............'',,;;;;;:;,'........'','...            'okOkdlc:;'.... .',;clol:,,;;:cloxxl;lx,   .:kKXkclk0OOOOOOO
//.lxxxxkkkkkxxkd:'......      ...     .'..................  ..........''',,,,,..          .o000Oxdolc:;;,'',;:clc:;,;coxkO00K0dcdk:  'xKNXXkclk0OOkkOOO
//.lxxxxkkkkkxkkxl,.......    .......  ';....................',;,''..''',,,,,,,'.    ...   .oK00OkxddoooddxxkO0000OkddkO00KKKK0koxOc..l0XNXXkloO0OOkkkOO
//.lxxxxxxkkkkkxkd:''''''.    ........ ,;'..........'',;;::cllol:;,''',,,,,,,,,'.  .;oxxl' .c0KK00OkxxdddxxkO000KKK0kO0KKXXXKKKOdkOc..dKXXXXkox00OOOOOkk
//.lxxxxxxxxxkkxkxl,'',,,..   ....''...,c,''''''''',,;::cllooolc:,,,,,;;;,,,,,,.  .:x0KXXO;.,kKKKK0000OOkkkOOOO000OOkOKXXXXXKKKOxOO; .cOKXXKkxO00OOOOOkk
//.lxxxxxxxxxxxxkkd:,,,,'..   ....'''..,c;,,;;;;;:::::::ccllllc:;;;;;;;;;;;;,,'. .;ok0KXNNk,.lKKKKKKK0KK000000000000OO0KXXXXXKKOk0k' 'cx0KXKOO00OOOOOOOO
//.lxxxxxxxxxxxxxxxo;,,'.........''''...cc;;:::cllllllllllllllc:::::::;;;;;;,'. .,ldk0KXNNXd.'xKKKKKKK00KK0000000KKK000KXXXXXKKOOOl.,oook0XKO0K0OOOOOOOO
//.lxxxxxxxxxxxxxxxxc,,'...''....'''''..;oc:cclloooooooooooollcc:::::;;;;;:;.. .'codk0KXXNNXo.,kKKKKK00000000000KKKKKK00KXXXXXK0Ox''d0xod0KK0K0OOOOOOOOO
//.lxxxxxxxxxxxxxxxxl,,'...',,....'''''..odccclooddddddddddoollcc::::;;:::;.  .'cloxk0KXXNNNKo,c0KKKKKK00000K00KKKKKKK0OKXXXXXKOo,.oK0dodOKKKKOkkkkkkkkk
//.lxxxxxxxxxxxxxxxxl,,,'..',,'...'''','.',;:cloodddxxxxxxxddolccccccccc;'. .',clodxO0KXXNNNNXxc:ldkO0KKK0000000000OOOkO00Okdl:;,;d0Kkodk0KKK0Okkkkkkkkk
//.cxxxxxxxxxxxxxxxxl,,,,,''','...'''',,'....'',,;;:ccllooolcc:;;;,,''.....':llooddkO0KXXNNNNNXOo;,,;;;:::::ccccc::::::cllcclloxO00K0OO00KKKK0kkkkkkkkkk
//.cxxxxxxxxxxxxxxxxl;',,;;,,,'...'''',,,,,,,,,,,'''''''''''............';cloooddxxkO0KXXXNNNNNXX0OkxdoollllllllooddxkO00KXXXXXKK00KKKKXKKKK0Okkkkkkkkkk
//.cxdxxdxxdddddddxxo:,,,;;;;,'....'''',,,,;;::cllllllllcc:::;;;,,'''',;cooooooddxkO00KKXXNNNNNNXXXXKKK0000000KKXXXXXXNNNXXXXKKKK00KXXXXKKK0Okkkkkkkkkkk
//.cdddddddddxdddddxdl;,,;;;;,,....''''',,,,;;::cllllllcc::::;;,,''''';clllllllodxkO00KKXXNNNNNNNXXXXXK0OxxkOO00KKXXXXXXXXXXKKKKK00KXXXXKK0Okkkkkkkkkkkk
//.cdddddxxxxxddddddddl;,;;;;;,'...''''''',,,;;::cccccc:::::;;,,'''''',;:::::::cldxO000KKXNNNNNXXXXXXXXK0xoodxkO0KKKXXXXXXXKKKKKK0KXXXXXK0kkkkkkkkkkkkkk
//.cdddddk0K0kxxdddddddo:;,;;;,'..'''''''',,,;;;::ccc:::;;;;,,''''''''',,,,,,,,;:coxkO00KXXNXXXKKKKKXXXXX0klccoxkO0KKKKXXXXKKKKKK00KXXK0Okkkkkkkkxxxxkkk
//.cddddx0NNN0xddddddddddocc:::;'.'''''''',,,;;;::cc:::;;;;,,'''''''''''''..'''',;:oxkOO0KKKKKKKKKKKXXXXXXKOd:;:oxk00KKKKKKKKKKKK00000Okkxkkkkxxxxxxxxxx
//.cddddkKNWXOxddddddddddddddddo;.''''',,,,,,;;;::cccc::;;,''''''''''''''.......'',:loxkO00KKKKKKKKXXXXXXXXXKkc,,cdO0KKKKKKKKKKKK0Okkkkxxxxxxxxxxxxxxxxx
//.cdddxONWNKkdddddddddddddddxxdc'.'''',,,,,,,;;:ccllllll:,''',,,,,,,''''''''''',,;:lodxkO0KKKKKKKKXXXXXXXXXXKOl,,cx0KKKKKKKKKKKK0kkkxxxxxxxxxxxxxxxxxxx
//.cdddkKNWXOxdddddddddddddddddxl,.''''',,,,,,;;:cloodxxo:,,,,,,,,,,,,,,,,,;;::clooddxxkkO0KKKXXXXXXXXXXXXXXXK0kc';oOKKKKKKKKKKKKOkkkxxxxxxxxxxxxxxxxxxx
//.cdddOXWNKkddddddddddddddddddxd:''''',,,,,,,;;:clldkOd:;;;;;;;;;;,,,,,,;;::ccldxkkkOOOO00KKXXXXXKKKKKKKKK00Okxo;;oOKKXXXKKKKKK0Okxxxxxxxxxxxxxxxxxxxxx
//.cddx0NWN0xddddddddddddddddddddl,.'''',,,,,,;;:::cdOOo:::;;;;,,,,'''''''',,;;:clodxxkkOOO000KK000OOOkdc::c:cldo::dOKXXXXKKKKKKOkxxxxxxxxxxxxxxxxxxxxxx
//.lxdkKNWXOdddddddddddddddddddddo:''''',,,,,,;;;;;:oO0kool:;,'...........'';;:::ccloodxkOKXKXXKKK0000kc..':odkkdllk0KXXXXKKKKK0Oxxxxxxxxxxxxxxxxxxxxxxx
//.dkxOXWNKkddddddddddddddddddddddc,'''',,,,,,,;;;;:lk00kxxl;'..  ....'',;;;:cloooddxxxk0KXXXXXXKXXXXKkc;cdO0K00kdx0KKKKXKKKKK0Okxxxxxxxxxxxxxxxxxxxxxxx
//'xKOKNWN0xddddddddddddddddddddddo:'''',,,,,,,;;;;;coOK0Okdc,.......',;:lc:cloxxxxkkOO0KXXXXXXXKXXXKOxxk0KKKXK0OkOKKKKKKKKKK00kxxxxxxxxxxxxxxxxxxxxxxxx
//'kNXXNNKkddddddddddddddddddddddddl;''',,,,,,,;;;;;:cd0K0Oxoc;,'....',;:llcodk0Okk00000KXNXXXXKOOK0OOO0KXXXXXKK00KKKKKKKKKK00Oxxxxxxxxxxxxxxxdddddddddd
//'kWNNWN0xdooooooooddddddddddddddddl,'''',,,,,,;;;;;:cxO0Oxdlc:;,''...',;;,:lxOkdxO0K00KXXKOkOkdxOO0KXXXXXXXXXKKKKKKKKKKK000kxxxxxxxxxxxxxxxxxddddddddd
//.kWWWWXOdooooooooooddddddddddddddddc,'''',,,,,,,;;;;:cdOOkdolc::;;,'''',,',;:lc:codxxxxkkxddxkO0KKXXXXXXXXXXXXKKKKKKKKK00Okxxdddddxxxxxdxxxxxddddddddd
//.dXNNNKxoooooooooooooooodddddddddddo:''''',,,,,,,;;;;:coxxdolc::;;;,,,,;;:ccllllloooodddxkOO0KXXXXNNXXXXXXXXXKKKKKKKKK00Okxddddddddddddddddddddddddddd
//.ckOOkxdoooooooooooooooooddddddddddoc,''''',,,,,,,,;;;;clollcc::;;;;;;;;;:ccloddxxxxxkkkkO0KXXXXNNNXXXXXXXXXXKKKKKKKK00kxxxddddddddddddddddddddddddddd
//.:ooooooooooooooooooooooooooooddddoo:''''''',,,,,,,,;;;;:ccccc::::;;;;;;::cclooddxxkkkkkO00KXXXXXXNXXXXXXXXXXKKKKKKK0Okxdddddddddddddddddddddddddddddd
//.:oooooooooooooooooooooooooooooddool;''''''',,,,,,,,,;;;;;:::ccccc::;;;::clloddxkkkkOOO000KKXXXXXXXXXXXXXXXXXKKKKKK0Oxdddddddddddddddddddddddddddooooo
//.:ooooooooooooooooooooooooddddddoool;''''''',,,,,,,,,,,,;;;::::ccccc:::::cloodxxkkkkkOO000KKXXXXXXXXXXXXXXXXKKKKK00kxddddddddddddddddddooooodooooooooo
//.:lllooooooooooooooooooooodooooooool;'''',,,,,,,,,,,,,,,,,;;;:::ccllllccclooodxkkkkOOOO000KKKXXXXXXXXXNXXXXKKKK00Okddddddddddddddddooooooooooooooooooo
//.:oooooooooooooooooooooooooooooooooc,''',,,,,,,,,,,,,,,,,,,,;;;:::clooooooooodxkkkOOOO0000KKXXXXXXXXXXXXXXKKKK000Oxdddddddddddddddoooooooooooooooooooo
//.:ooooolooooooooooooooooooooooooool:''',,,,,,,,,,'''''',,,,,,,;;;::clodddddddxxkkkkOOO0000KKKXXXXXXXXXXXXKK0000KKOdoddooodddddddoooooooooooooooooooooo
//.:ooooooooooloooooooooooooooooooooc,'',,,,,,,,,,,''''''''''',,,;;;;:cloddxxxxxxkkkkkOOO000KKXXXXXXXXXXXXKK0OO0KKKkoooooooooooooooooooooooooooooooooooo
//.:lloooooooooooooooooooooooooooool:,',,,,,,,,,,,,,,,''''''''''',,,;;;:codddxxxxkkkkOOOO000KKXXXXXXNXXXKK0OOO0KKK0xoolllllllllllllooooooooooooooooooooo
//.:lllooooollloolooooooooooooooool:,',,,,,;,,,,,,,,,,,,'''''''''''',,,;:clooodxxkkkOOO00000KKKXXXXXXXKK0OOO00KKKK0dllllllllllllllllllllllllllllllllllll
//.:oloooollllllllllllooooooolllc:;'',,,,;,;;,,,,,,,,,,,,,,'''''''''''',,;:clloodxkOOO000000KKKKXXXKK00OOOO0KKKKKKOdllllllccccccccccccccllllccclcccccccc
//.:lllolllllllllllllooooooollcc;,,,',,,;;,,;;;;;,,,,,,,,,,,,,''''''''''',,;:cclodxkkOO000000KKKK000OOOOO00KKKKXKKOdlllllllccccccccccccccccccccccccccccc
//.:llllllllllllllllllc:;;;:ccc:,,,,,,,,;;;;;;;;;;;;,,,,,,,,,,,,,'''''''''',;;;:clodxkkkOOOOO000OOOOOO0000KKKKKXKKkdoollllllllllllccclcccccccccccccc::::
//.;lllllllllllllc:;,....',:cc:;,,,,,,,;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,''''''',,;;:cloddxxxkkkkkkkOO00000KKKKKKKXKKkolllllllllloollllllllllllcccccccc::::
//.:lcc:;;,,,,,,'......';:llc:;,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,;;::::;;;:ccllooodxkO00KKKKKKKKKKKKXXXKKklcccccccccllllllllllllllllllccccccccc
//.','................':lllc:;;;,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::ccldxkkkkxxxxxxxkkkO0KKXXXKKKKKKKXXXXXXXKKklcccccccccccccccccccccccccccccccccccc
// ..................':ccc::;;;;;,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::cllodxkOOO0000000000KKKXXXXXXXKKKKKXXXXXXXKKOocc:::::::::::::::::::::::::::::::ccc
//  ...   .     . ..'::::::::;;;;;;;;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;:::cloddxkkOO000000KKKKKKXXXXXXXXKKKKXXXXXXXXKK0klc:::::::::::;;;;;;;;;;;;;;;;;;;;;;;
//  ...           ..;::::::::;;;;;;;;;;;;;;:::;;:::;;;;;;;;;;;;;;;:::ccloodxxkkOO000KKKKKKXXXXXXXXXKKKKXXXXXXXXXKKKOdc:::::::::;;;;;;;;;;;;,,,,,,,,,,,,,
// ....           .,:::ccccc:;;;;;;;;;;;;;:::;:::::::;;;;;;;;;;;;;:::cclooddxxxkOO00KKKKKKXXXXXXXXKKKKXXXXXXXXXKKKK0koc::::::;;;;;;;;;;;;,,,,,,,,,,,,,,,
// ----------------------------------------------------------------------------

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}
contract FuckUniswapV3 is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "FuckV3";
        symbol = "FV3";
        decimals = 18;
        _totalSupply = 100000000000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}