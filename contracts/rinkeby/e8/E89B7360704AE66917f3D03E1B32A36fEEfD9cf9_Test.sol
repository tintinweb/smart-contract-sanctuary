// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library chainBeingFactory {

  function art(uint256 seed) public pure returns (string memory) {
    uint256 rand = uint256(keccak256(abi.encodePacked(seed)));

    string[28] memory hairs =  [
      unicode"     _______",
      unicode"     ///////",
      unicode"     !!!!!!!",
      unicode"     %%%%%%%",
      unicode"     ║║║║║║║",
      unicode"     ▄▄▄▄▄▄▄",
      unicode"     ███████",
      unicode"     ┌─────┐   \n"
      unicode"     │     │  \n"
      unicode"    ─┴─────┴─  ",       
      unicode"     ┌─────┐   \n"       
      unicode"     ├─────│    \n"
      unicode"    ─┴─────┴─ ",       
      unicode"     ┌▄▄▄▄▄┐  \n"       
      unicode"     ├─────┤  \n"       
      unicode"    ─┴─────┴─ ",       
      unicode"     ┌─────┐  \n"
      unicode"     ├─────┤  \n"
      unicode"    ─┴▀▀▀▀▀┴─ ",
      unicode"     ┌▄▄▄▄▄┐  \n"
      unicode"     ├─────┤  \n"
      unicode"    ─┴▀▀▀▀▀┴─ ",
      unicode"     ┌▄▄▄▄▄┐  \n"
      unicode"     ├█████┤  \n"
      unicode"    ─┴▀▀▀▀▀┴─ ",
      unicode"     ┌─────┐  \n"
      unicode"     │     │  \n"
      unicode"    ─┴▀▀▀▀▀┴─ ",
      unicode"              \n"
      unicode"     ┌─────┐  \n"
      unicode"    ─┴─────┴─ ",
      unicode"              \n"
      unicode"     ┌─────┐  \n"
      unicode"    ─┴▀▀▀▀▀┴─ ",
      unicode"              \n"
      unicode"      /███    \n"
      unicode"    ─┴▀▀▀▀▀┴─  ",
      unicode"               \n"
      unicode"      /▓▓▓    \n"
      unicode"    ─┴▀▀▀▀▀┴─  ",
      unicode"               \n"
      unicode"      ┌───┐    \n"
      unicode"   └─┴─────┴── ",
      unicode"            ,/ \n"
      unicode"      ┌───┐/'  \n"
      unicode"   └─┴─────┴── ",
      unicode"               \n"
      unicode"      .▄▄▄.    \n"
      unicode"   └─┴▀▀▀▀▀┴── ",
      unicode"            ,/ \n"
      unicode"      .▄▄▄./'  \n"
      unicode"   └─┴▀▀▀▀▀┴── ",
      unicode"               \n"
      unicode"      /ˇˇˇ    \n"
      unicode"     ┴─────┴   ",
      unicode"     ┌─────┐   \n"
      unicode"    ┌┴─────┴┐  \n"
      unicode"    └───────┘  ",
      unicode"               \n"
      unicode"     ┌─────┐   \n"
      unicode"    |░░░░░░░|  ",
      unicode"      ,.O.,    \n"
      unicode"     /»»»»»   \n"
      unicode"    /«««««««  ",
      unicode"      ,.O.,    \n"
      unicode"     /AAAAA   \n"
      unicode"    /VVVVVVV  ",
      unicode"      ,.O.,   \n"
      unicode"     /WWWWW   \n"
      unicode"    /MMMMMMM  "
    ];
    
    uint256 id = rand%9;
 
    string memory hair =  string(abi.encodePacked(hairs[rand%28], unicode" \n"));

    string memory brows = _chooseEyeBrows(rand,id);
    string memory eyes = _chooseEyes(rand,id);
    string memory mouth = _chooseMouth(rand,id);
    string memory nose = _chooseNose(rand,id);
    
    return string(abi.encodePacked(hair, brows,eyes,nose, mouth));
    
  }

  function _chooseEyeBrows(uint256 rand,uint256 id) internal pure returns(string memory){

    string[3] memory brows = [
      unicode"_",
      unicode"~",
      unicode"¬"
    ];
    
    if(id == 0) {
      return string(abi.encodePacked("    # ",brows[rand%3], "   ",brows[rand%3]," #" , unicode" \n"));
    }
    else if(id == 1) {
      return string(abi.encodePacked("    ! ",brows[rand%3], "   ",brows[rand%3]," !" , unicode" \n"));
    }
    else if(id == 2){
      return string(abi.encodePacked("    | ",brows[rand%3], "   ",brows[rand%3]," |" , unicode" \n"));
    }
    else if(id == 3) {
      return string(abi.encodePacked("    { ",brows[rand%3], "   ",brows[rand%3]," }" , unicode" \n"));
    }
    else if(id == 4) {
      return string(abi.encodePacked(unicode"    ║ ",brows[rand%3], "   ",brows[rand%3],unicode" ║" , unicode" \n"));
    }
    else if(id == 5) {
      return string(abi.encodePacked(unicode"    # ",brows[rand%3], "   ",brows[rand%3],unicode" #" , unicode" \n"));
    }
    else if(id == 6) {
      return string(abi.encodePacked(unicode"    ) ",brows[rand%3], "   ",brows[rand%3],unicode"  )" , unicode" \n"));
    }
    else if(id == 7) {
      return string(abi.encodePacked("   (# ",brows[rand%3], "   ",brows[rand%3]," #)" , unicode" \n"));
    }
    else if(id == 8) {
      return string(abi.encodePacked(unicode"   |  ",brows[rand%3], "   ",brows[rand%3],unicode"  |" , unicode" \n"));
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }
  }

  function _chooseEyes(uint256 rand,uint256 id) internal pure returns (string memory) {

    string[23] memory leftEyes =
      [
        unicode"0",
        unicode"9",
        unicode"o",
        unicode"O",
        unicode"p",
        unicode"P",
        unicode"q",
        unicode"°",
        unicode"Q",
        unicode"Ö",
        unicode"ö",
        unicode"ó",
        unicode"Ô",
        unicode"■",
        unicode"Ó",
        unicode"Ő",
        unicode"ő",
        unicode"○",
        unicode"⊙",
        unicode"╬",
        unicode"♥",
        unicode"¤",
        unicode"đ"
      ];

    string[23] memory rightEyes =
      [
        unicode"0",
        unicode"9",
        unicode"o",
        unicode"O",
        unicode"p",
        unicode"P",
        unicode"q",
        unicode"°",
        unicode"Q",
        unicode"Ö",
        unicode"ö",
        unicode"ó",
        unicode"Ô",
        unicode"■",
        unicode"Ó",
        unicode"Ő",
        unicode"ő",
        unicode"○",
        unicode"⊙",
        unicode"╬",
        unicode"♥",
        unicode"¤",
        unicode"đ"
      ];


    string memory leftEye = leftEyes[rand % 23];
    string memory rightEye = rightEyes[rand % 23];

    if(rand % 2 == 0) {
      return _chooseGlasses(rand,id);
    }

    if(id == 0) {
       return
        string(
          abi.encodePacked(
            "   d| ",
            leftEye,
            "   ",
            rightEye,
            " |b",
            unicode" \n"
          )
      );
    }
    else if(id == 1) {
      return
        string(
          abi.encodePacked(
            unicode"   «│ ",
            leftEye,
            "   ",
            rightEye,
            unicode" │»",
            unicode" \n"
          )
        );
    
    }
    else if(id == 2){
       return
        string(
          abi.encodePacked(
            "    ( ",
            leftEye,
            "   ",
            rightEye,
            " )",
            unicode" \n"
          )
        );
    }
    else if(id == 3) {
      return
        string(
          abi.encodePacked(
            "   d| ",
            leftEye,
            "   ",
            rightEye,
            " |b",
            unicode" \n"
          )
      );
    }
    else if(id == 4) {
      return
      string(
        abi.encodePacked(
          unicode"   d║ ",
          leftEye,
          "   ",
          rightEye,
          unicode" ║b",
          unicode" \n"
        )
      );
    }
    else if(id == 5) {
      return
      string(
        abi.encodePacked(
          unicode"   d| ",
          leftEye,
          "   ",
          rightEye,
          unicode" |b",
          unicode" \n"
        )
      );
    }
    else if(id == 6) {
      return
      string(
        abi.encodePacked(
          unicode"   (  ",
          leftEye,
          "   ",
          rightEye,
          unicode" (",
          unicode" \n"
        )
      );
    }
    else if(id == 7) {
      return
        string(
          abi.encodePacked(
            unicode"   @| ",
            leftEye,
            "   ",
            rightEye,
            unicode" |@",
            unicode" \n"
          )
        );
    }
    else if(id == 8) {
      return
      string(
        abi.encodePacked(
          unicode" |\\|  ",
          leftEye,
          "   ",
          rightEye,
          unicode"  |/|",
          unicode" \n"
        )
      );
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }
    
  }

  function _chooseNose(uint256 rand,uint256 id) internal pure returns (string memory) {

    string[15] memory noses =
      [
        unicode" < ",
        unicode" > ",
        unicode" V ",
        unicode" W ",
        unicode" v ",
        unicode" u ",
        unicode" c ",
        unicode" C ",
        unicode" ┴ ",
        unicode" L ",
        unicode" Ł ",
        unicode" └ ",
        unicode" ┘ ",
        unicode" ╚ ",
        unicode" ╝ "
    ];

    if(id == 0) {
      return string(abi.encodePacked("    (  ",noses[rand % 15],"  )", unicode" \n"));
    }
    else if(id == 1){
      return string(abi.encodePacked("    \\  ",noses[rand % 15],"  /", unicode" \n"));
    }
    else if(id == 2){
      return string(abi.encodePacked("  <(   ",noses[rand % 15],"   )>", unicode" \n"));
    }
    else if(id == 3) {
      return string(abi.encodePacked("    \\  ",noses[rand % 15],"  /", unicode" \n"));
    }
    else if(id == 4) {
      return string(abi.encodePacked(unicode"    ║  ",noses[rand % 15],unicode"  ║", unicode" \n"));
    }
    else if(id == 5) {
      return string(abi.encodePacked(unicode"    (  ",noses[rand % 15],unicode"  )", unicode" \n"));
    }
    else if(id == 6) {
      return string(abi.encodePacked(unicode"    )  ",noses[rand % 15],unicode"   )", unicode" \n"));
    }
    else if(id == 7){
      return string(abi.encodePacked("   (/  ",noses[rand % 15],"  \\)", unicode" \n"));
    }
    else if(id == 8) {
      return string(abi.encodePacked(unicode"  \\│   ",noses[rand % 15],unicode"   │/", unicode" \n"));
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }

  }

  
  function _chooseMouth(uint256 rand,uint256 id) internal pure returns (string memory) {
   
    string[5] memory mouths =
      [
      unicode"---",
      unicode"___",
      unicode"===",
      unicode"~~~",
      unicode"═══"
      ];

    if(id == 0){
      return string(abi.encodePacked("     ) ",mouths[rand % 5]," (",unicode" \n",unicode"     (_____)"));
    }
    else if (id == 1){
      return string(abi.encodePacked(unicode"     ├ ",mouths[rand % 5],unicode" ┤",unicode"  \n",unicode"      \'───\'"));
    }
    else if(id == 2) {
      return string(abi.encodePacked("    \\  ",mouths[rand % 5],"  /",unicode" \n",unicode"      \\ˍˍˍ/"));
    }
    else if(id == 3){
      return string(abi.encodePacked("     { ",mouths[rand % 5]," }",unicode" \n",unicode"      └~~~┘"));
    }
    else if(id == 4){
      return string(abi.encodePacked(unicode"    ╚╗ ",mouths[rand % 5],unicode" ╔╝",unicode" \n",unicode"     ╚═════╝"));
    }
    else if(id == 5){
      return string(abi.encodePacked(unicode"     |\\",mouths[rand % 5],unicode"/|",unicode" \n",unicode"      \\_‿_/"));
    }
    else if(id == 6){
      return string(abi.encodePacked(unicode"   (   ",mouths[rand % 5],unicode"  (",unicode" \n",unicode"     `─ ─ ─´"));
    }
    else if(id == 7){
      return string(abi.encodePacked(unicode"   (|  ",mouths[rand % 5],unicode"  |)",unicode" \n",unicode"     `─────´"));
    }
    else if(id == 8){
      return string(abi.encodePacked(unicode"    \\  ",mouths[rand % 5],unicode"  /",unicode" \n",unicode"      \\___/"));
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }
    
  }


  function _chooseGlasses(uint256 rand,uint256 id) internal pure returns(string memory) {
    string[16] memory glasses = [
      unicode"-O---O-",
      unicode"-O-_-O-",
      unicode"-┴┴-┴┴-",
      unicode"-┬┬-┬┬-",
      unicode"-▄---▄-",
      unicode"-▄-_-▄-",
      unicode"-▀---▀-",
      unicode"-▀-_-▀-",
      unicode"-█---█-",
      unicode"-█-_-█-",
      unicode"-▓---▓-",
      unicode"-▓-_-▓-",
      unicode"-▒---▒-",
      unicode"-▒-_-▒-",
      unicode"-░---░-",
      unicode"-░-_-░-"
    ];

  string memory glass = glasses[rand%16];

    if(id == 0) {
       return
        string(
          abi.encodePacked(
            "   d|",
            glass,
            "|b",
            unicode" \n"
          )
      );
    }
    else if(id == 1) {
      return
        string(
          abi.encodePacked(
            unicode"   «│",
            glass,
            unicode"│»",
            unicode" \n"
          )
        );
    
    }
    else if(id == 2){
       return
        string(
          abi.encodePacked(
            "    (",
            glass,
            ")",
            unicode" \n"
          )
        );
    }else if(id == 3) {
      return
        string(
          abi.encodePacked(
            "   d|",
            glass,
            "|b",
            unicode" \n"
          )
      );
    }else if(id == 4) {
      return
      string(
        abi.encodePacked(
          unicode"   d║",
          glass,
          unicode"║b",
          unicode" \n"
        )
      );
    }else if(id == 5) {
      return
      string(
        abi.encodePacked(
          unicode"   d|",
          glass,
          unicode"|b",
          unicode" \n"
        )
      );
    }else if(id == 6) {
      return
      string(
        abi.encodePacked(
          unicode"   ( ",
          glass,
          unicode"(",
          unicode" \n"
        )
      );
    }
    else if(id == 7) {
      return
        string(
          abi.encodePacked(
            unicode"  @| ",
            glass,
            unicode" |@",
            unicode" \n"
          )
        );
    }
    else if(id == 8) {
      return
      string(
        abi.encodePacked(
          unicode" |\\| ",
          glass,
          unicode" |/|",
          unicode" \n"
        )
      );
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }

  } 
}

//  SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

import './Ascii_Man/chainBeingFactory.sol';

contract Test {
    function testingDraw(uint256 seed) public pure returns(string memory) {
        return chainBeingFactory.art(seed);
    }
}

