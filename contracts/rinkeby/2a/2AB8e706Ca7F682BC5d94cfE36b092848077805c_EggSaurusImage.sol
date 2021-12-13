//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EggSaurusImage is Ownable {
  mapping(address => bool) private _permittedAddress;

  function setPermittedAddress(address contractAddress_, bool permit) external onlyOwner{
    _permittedAddress[contractAddress_] = permit;
  }

  function generateSVG(uint256 id, uint256 saurusItem, uint256 saurusCollar) external view returns(string memory) {
    require(_permittedAddress[_msgSender()]);

    string memory backColor;
    uint256 backNum = id % 11;
    if(backNum == 0){
      backColor = '4d4d4d';
    }else if(backNum == 1){
      backColor = 'b9a48b';
    }else if(backNum == 2){
      backColor = '39a74a';
    }else if(backNum == 3){
      backColor = '006837';
    }else if(backNum == 4){
      backColor = 'e34044';
    }else if(backNum == 5){
      backColor = '754c24';
    }else if(backNum == 6){
      backColor = 'c48f2c';
    }else if(backNum == 7){
      backColor = '299dd4';
    }else if(backNum == 8){
      backColor = '213368';
    }else if(backNum == 9){
      backColor = 'ffb633';
    }else{
      backColor = 'e68b9d';
    }

    string memory svg = string(abi.encodePacked(
      "<svg xmlns='http://www.w3.org/2000/svg' width='1000px' height='1000px' viewBox='0 0 1000 1000' style='background-color:#",
      backColor,
      // a base_line stroke:#000;stroke-width:5px
      // b tooth_color fill:#929492
      // d hand_color fill:#909090
      // r stroke-linejoin:round
      // w fill:#fff
      // g gold_collar_color fill:#eee021
      "'><defs><style>.a{stroke:#000;stroke-width:5px}.b{fill:#929492}.d{fill:#909090}.r{stroke-linejoin:round}.w{fill:#fff}.g{fill:#eee021}</style></defs>",
      saurus(id, saurusItem, saurusCollar),
      eye(id),
      hat(id),
      "</svg>"
    ));

    return svg;
  }

  function generateEggSVG() external view returns(string memory) {
    return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1000 1000'><path fill='#FFF' d='M3 3h1000v1000H3z'/><path d='M837 501c26 215-113 418-335 421-222-3-360-206-335-421C189 284 327 85 502 83c176 2 314 201 335 418Z' fill='#fcd525' stroke='#000' stroke-width='5'/><path d='M837 501c26 215-113 418-335 421-222-3-360-206-335-421C189 284 327 85 502 83c176 2 314 201 335 418Z' fill='#fcd525' stroke='#000' stroke-width='5'/><path fill='none' stroke='#000' stroke-width='5' d='m168 512 37-29 35 47 52-71 66 79 60-60 14 32 41-51 96 51 63-32 49 32 45-51 46 79 59-73M697 176l-49 65M665 218l5 54 3 29M717 288l-47-16'/></svg>";
  }

  function saurus(uint256 id, uint256 saurusItem, uint256 saurusCollar) internal view returns(string memory) {
    string memory saurusColor;
    uint256 colorNum = id % 8;
    if(colorNum == 0){
      saurusColor = '657c80';
    }else if(colorNum == 1){
      saurusColor = 'b88e6d';
    }else if(colorNum == 2){
      saurusColor = 'efbdb8';
    }else if(colorNum == 3){
      saurusColor = '0071ae';
    }else if(colorNum == 4){
      saurusColor = 'e9851e';
    }else if(colorNum == 5){
      saurusColor = 'bdd05d';
    }else if(colorNum == 6){
      saurusColor = 'b3272d';
    }else{
      saurusColor = '8b8b8b';
    }

    string memory eggColor;
    uint256 eggColorNum = id % 5;
    if(eggColorNum == 1){
      eggColor = "80b83f";
    }else if(eggColorNum == 2){
      eggColor = "df1c24";
    }else if(eggColorNum == 3){
      eggColor = "eee021";
    }else if(eggColorNum == 4){
      eggColor = "299dd4";
    }

    string memory egg;
    if(eggColorNum == 0) {
      // gold
      egg = "<path d='M836 1000c17-47 27-102 26-164a577 577 0 0 0-5-85h-1l-51 40-78-89-46 70-18-21-27 38-26-43-20 45-68-70-62 70-76-45-29 25-86-70-44 64-49 11-48-25a577 577 0 0 0-6 85c0 62 9 117 26 164' class='a' fill='#eec825'/><path d='m843 803-45 33-60-85-43 60-14-20-22 28q0 25-2 48c-4 50-14 94-28 133h189c12-35 21-75 24-120a558 558 0 0 0 1-77Z' fill='#eeba26'/><path d='M157 848a520 520 0 0 1 3-58v-7l1-4-24-12h-1a534 534 0 0 0-5 81c-1 58 8 108 23 152h27c-16-44-25-95-24-152Z' fill='#eeeb88'/><path d='M184 848a507 507 0 0 1 2-58l-24-11v4l-1 7a509 509 0 0 0-3 58c0 57 9 108 25 152h25c-16-44-25-95-24-152Z' fill='#eed915'/>";
    }else{
      egg = string(abi.encodePacked(
        "<path d='M836 1000c17-47 27-102 26-164a577 577 0 0 0-5-85h-1l-51 40-78-89-46 70-18-21-27 38-26-43-20 45-68-70-62 70-76-45-29 25-86-70-44 64-49 11-48-25a577 577 0 0 0-6 85c0 62 9 117 26 164' class='a w'/><path d='M361 1000a120 120 0 0 0 0-13c0-66-53-119-119-119a120 120 0 0 0-109 69 409 409 0 0 0 18 63ZM498 957c67 0 120-54 120-119a118 118 0 0 0-18-64l-10 20-67-69-62 69-55-33a118 118 0 0 0-28 77c0 65 54 119 120 119ZM736 884c-65 0-118 52-120 116h218a400 400 0 0 0 12-42 120 120 0 0 0-110-74Z' fill='#",
        eggColor,
        "'/>"
      ));
    }

    return string(abi.encodePacked(
      "<path d='M532 396s-3-31 60-28l314 1-11 48-14-28-17 48-22-20-7 28-14-18-12 25-15-14-25 10 16 12 4-9 19 18 16-18 10 18 13-16 5 19 7 9-121 32-205-107Z'/><path d='M890 205c-207 39-242-52-242-52-20-4-55 18-80 36l-108-33-85 60-74-4-5 76-31 23 18 37-29 42 26 38-17 44c20 34 55 111 33 124s-76 197-76 197v93l557-139-85-89c-37-11-20-73-20-73L533 397c5-63 253-3 253-3 42-32 128-24 128-24 46-19-24-165-24-165Z' class='a' fill='#",
      saurusColor,
      "'/><path d='m723 505-99-56s23-30 51-2c0 0 15-20 28-14 0 0 80 37 80 45 0 0-33 37-60 27Z' fill='#e5a189'/><path d='M545 380s29-12 46-10l-34 40ZM656 373l-42 37-22-42 64 5zM702 378l-46-5-5 6 17 38 34-39zM753 386l-31 37-18-46 49 9zM817 381s-33 11-31 15-1 0-1 0l-32-9 26 29ZM846 373l-28 7 7 27 21-34zM872 370l-24 2 7 27 17-29zM894 369l-20 1 3 25 17-26zM582 429l14-19 20 38-34-19z' class='b'/><path class='a b' d='m633 454 11-8 8 19-19-11zM678 479l14-18 20 37-34-19zM721 503l18-22 15 25-33-3z'/><path class='a b' d='m804 492-25-17-28 28'/><path class='b' d='m827 489-19-16-13 24 32-8zM848 483l-11-10-7 15 18-5z'/><path d='M527 404c-85 10-148 37-110 114s164 83 164 83 93-30 126-24 82 20 101 14 104-75 63-112c0 0-129 34-147 25Z' class='a' fill='#eedfa8'/><path d='M569 188s78 39 116 38 73 2 91 14' class='a' fill='none'/><path class='a' d='m883 229-3 2M853 242l11 1'/>",
      collar(saurusCollar),
      egg,
      item(saurusItem),
      "<path d='M183 759c-12-56 118-123 138 4' class='a' fill='#",
      saurusColor,
      "'/><path d='M184 763s32-59 70-7l-37 91s-42-71-33-84ZM319 764s-29-78-67 0l5 72s65-63 61-73' class='a d'/><path d='M687 762c-9-81 88-82 126-18' class='a' fill='#",
      saurusColor,
      "'/><path d='M689 764s37-55 67-20-40 103-40 103 1-79-27-83Z' class='a d'/><path d='M761 749s112-53 18 96c0 0 9-83-18-96Z' class='a d'/>"
    ));
  }

  function eye(uint256 id) internal view returns(string memory) {
    uint256 num = id % 9;
    if(num == 0){
      // normal
      return "<path d='M439 353c-18-67 10-84 33-93s70 20 63 76c0 0 3 14-43 24s-53-7-53-7Z' class='a w'/><path d='M495 355s-22-76-2-80 46 35 39 63c0 0-25 21-37 17Z' fill='#eac9eb' class='a'/><path d='M512 351s-14-58-3-57 32 35 25 46-22 11-22 11Z' class='a'/><ellipse cx='512.1' cy='292.7' rx='6.2' ry='12.3' transform='rotate(-15 512 293)' class='w'/>";
    }else if(num == 1){
      // pirate
      return "<path class='r' stroke='#000' stroke-linecap='round' stroke-width='14' d='m565 229 31-26M407 271l158-42s41 88-49 112c0 0-98 34-109-70ZM405 271l-111-13'/>";
    }else if(num == 2){
      // cry
      return "<path d='M439 353c-18-67 10-84 33-93s70 20 63 76c0 0 3 14-43 24s-53-7-53-7Z' class='a w'/><path d='M495 355s-22-76-2-80 46 35 39 63c0 0-25 21-37 17Z' fill='#eac9eb' class='a'/><path d='M512 351s-14-58-3-57 32 35 25 46-22 11-22 11Z' class='a'/><ellipse cx='512.1' cy='292.7' rx='6.2' ry='12.3' transform='rotate(-15 512 293)' class='w'/><path d='M521 233a4 4 0 0 0-6 0c-5 6-63 34-116 58a6 6 0 0 0-2 6c0 2 2 4 4 5a153 153 0 0 0 21 0 117 117 0 0 0 100-62 6 6 0 0 0-1-7Z'/><ellipse cx='459' cy='366.5' rx='28.5' ry='15' fill='#299dd4' class='a'/>";
    }else if(num == 3){
      // eyebrows
      return "<circle cx='489' cy='316' r='50.4' class='a w'/><circle cx='501.6' cy='312.9' r='35.3'/><circle cx='510.9' cy='303.7' r='12.7' class='w'/><path d='M430 253s59 54 136 27' fill='none' stroke='#000' stroke-miterlimit='10' stroke-width='22'/>";
    }else if(num == 4){
      // angry
      return "<path d='M439 353c-18-67 10-84 33-93s70 20 63 76c0 0 3 14-43 24s-53-7-53-7Z' fill='red' class='a'/><path d='M495 355s-22-76-2-80 46 35 39 63c0 0-25 21-37 17Z' fill='#eac9eb' class='a'/><path d='M512 351s-14-58-3-57 32 35 25 46-22 11-22 11Z' class='a'/><ellipse cx='512.1' cy='292.7' rx='6.2' ry='12.3' transform='rotate(-15 512 293)' class='w'/><path d='M550 266a4 4 0 0 0-5-3c-7 1-72-9-129-19-2-1-5 1-6 3s-2 5 0 7a141 141 0 0 0 16 13 116 116 0 0 0 121 6 7 7 0 0 0 3-7Z'/>";
    }else if(num == 5){
      // star
      return "<path d='M553 289a3 3 0 0 0-3-2c-42-2-50-7-66-46a3 3 0 0 0-6 1c-2 42-7 51-46 67a3 3 0 0 0-2 4 3 3 0 0 0 3 2c42 2 50 7 67 46a3 3 0 0 0 3 2 3 3 0 0 0 1 0 3 3 0 0 0 2-3c1-42 7-51 46-67a3 3 0 0 0 1-4Z' class='a' fill='#eee021'/>";
    }else if(num == 6){
      // heart
      return "<circle cx='482' cy='303' r='56' class='a w'/><path d='M516 276c-26-12-33 12-34 14-1-2-9-26-34-14 0 0-30 22 34 68 64-46 34-68 34-68Z' fill='#df1c24' class='a r'/>";
    }else if(num == 7){
      // circle
      return "<circle cx='486' cy='307' r='50.4' class='a w'/><circle cx='498.6' cy='303.9' r='35.3'/><circle cx='504.9' cy='300.7' r='21.2' class='w'/>";
    }else{
      // twinkle
      return "<circle cx='486' cy='304' r='55.6'/><path d='M527 288c0 12-9 24-21 24a21 21 0 1 1 0-42c12 0 21 7 21 18ZM495 329c0 10-5 18-15 18s-20-8-20-18a18 18 0 1 1 35 0ZM480 291a17 17 0 0 1-17 17c-10 0-17-5-17-14s7-20 17-20a17 17 0 0 1 17 17Z' class='w'/>";
    }
  }

  function hat(uint256 id) internal view returns(string memory) {
    uint256 num = id % 7;
    if(num == 0){
      // devil
      return "<path d='M351 257s-130 0-166-154c0 0-88 223 128 278 0 0 81-40 38-124ZM655 163s58-42 61-117c0 0 49 85 24 160 0 0-50 9-85-43Z' class='a r' fill='red'/><path d='m229 592-20-81a8 8 0 0 0-13-3l-59 64a7 7 0 0 0 4 12l29 7a187 187 0 0 0-5 31c-2 38 8 72 31 98l15-14c-19-21-28-49-26-82a166 166 0 0 1 5-29l30 6h1a8 8 0 0 0 8-9Z'/>";
    }else if(num == 1){
      // rabit
      return "<path d='M166 178s108-198 325-53c0 0-151 144-325 53Z' class='a' fill='#ffd2cc'/><path d='M353 174S139 43 57 274c0 0-56 160 31 175 0 0 38 19 89-135 0 0 30-53 76 3Z' class='a' fill='#ffd2cc'/><path d='M260 477s-155-133 97-323c0 0 219-164 313 19 0 0-85-34-261 118 0 0-106 90-149 186Z' class='a r' fill='#ffd2cc'/>";
    }else if(num == 2){
      // reindeer
      return "<path d='M776 142a21 21 0 0 0-24-17l-46 6h1l51-68a21 21 0 0 0-34-25l-29 40-19-41a21 21 0 1 0-38 17l28 62-28 37 32 27 1-1 87-13a21 21 0 0 0 18-24ZM386 226l-81-50 3-67a21 21 0 1 0-41-3l-3 45-42-26a21 21 0 0 0-22 36l73 44-45 11a21 21 0 1 0 9 40l87-20 40 25a21 21 0 1 0 22-35Z' class='a' fill='#603813'/>";
    }else if(num == 3){
      // green
      return "<path d='M142 189s30-116 143-73c0 0-1-60 49-66 0 0 34 42-13 88l25 38-21 13-27-34s-59 88-156 34Z' class='a' fill='#80b83f'/><path d='M258 479s-154-134 98-326c0 0 219-166 313 20 0 0-85-35-261 119 0 0-107 90-150 187Z' class='a r' fill='#603813'/>";
    }else if(num == 4){
      // sleep
      return "<path d='M270 122s-148 89-83 311a31 31 0 1 0 7-1c5-35 19-116 56-147 0 0 20 46 20 86 0 0 150-219 410-183 0-1-172-246-410-66Z' class='a r' fill='#ecf'/>";
    }else if(num == 5){
      // red artist
      return "<path d='M644 39S472 19 323 77l-3 1c-8-28-28-71-65-25 0 0-25 30 31 41a308 308 0 0 0-178 263S89 517 263 484c0 0 67-299 353-308 0 0 67-3 90 24 0 0 110-135-62-161Z' class='a r' fill='#df1c24'/>";
    }else{
      // baseball
      return "<path d='M236 488S35 299 290 118c0 0 273-196 382 51 0 0-298 14-436 319Z' class='a' fill='#2e3184'/><circle cx='283.3' cy='102.1' r='27.8' class='a' fill='#2e3184'/><path d='m264 477 16-48-8-10-36 66s-93 113-67 140c0 0 16 56 123-86Z' class='a' fill='#1b1f4a'/>";
    }
  }

  function collar(uint256 saurusCollar) internal view returns(string memory) {
    uint256 num = saurusCollar % 6;

    if(saurusCollar == 0){
      return "";
    }else if(num ==  0) {
      // gold
      return "<ellipse cx='418.7' cy='700.1' rx='20.6' ry='26.8' transform='rotate(-67 419 700)' class='a g'/><ellipse cx='372.3' cy='680.6' rx='20.4' ry='27' transform='rotate(-59 372 681)' class='a g'/><ellipse cx='329.5' cy='658.6' rx='20.2' ry='27.2' transform='rotate(-52 329 660)' class='a g'/><ellipse cx='292.6' cy='635.2' rx='19.9' ry='27.7' transform='rotate(-40 293 635)' class='a g'/><ellipse cx='670.4' cy='655.6' rx='27' ry='20.4' transform='rotate(-31 670 656)' class='a g'/><ellipse cx='631.7' cy='681.7' rx='27.2' ry='20.2' transform='rotate(-38 632 682)' class='a g'/><ellipse cx='590.8' cy='705.1' rx='27.7' ry='19.9' transform='rotate(-30 591 705)' class='a g'/><circle cx='502.6' cy='753.6' r='76.1' fill='#eec825' class='a'/><circle cx='502.6' cy='753.6' r='54.8' fill='#eeed37' class='a'/><path fill='#eed224' class='a' d='m517 713-43 23 31 21-24 30 58-28-32-23 10-23z'/>";
    }else if(num == 1) {
      // ribbon
      return "<path d='M301 579s36 79 269 77l-1 20s-151 42-290-55c0 0-4-24 22-42Z' fill='#df1c24' class='a'/><path d='m702 669-16-79a5 5 0 0 0-3-3 4 4 0 0 0-3 0l-92 43-112-7a4 4 0 0 0-3 2 5 5 0 0 0-1 4l20 78a5 5 0 0 0 2 3 4 4 0 0 0 2 1 4 4 0 0 0 1 0l103-33 98-3a4 4 0 0 0 3-2 5 5 0 0 0 1-4Z' fill='#df1c24' class='a'/><path d='m632 674-14-57c0-3-3-4-5-4l-51 11c-2 1-3 3-3 6l8 57a6 6 0 0 0 1 3 4 4 0 0 0 3 1h1l57-10a4 4 0 0 0 3-3 6 6 0 0 0 0-4Z' fill='#df1c24' class='a'/>";
    }else if(num == 2) {
      // sleep
      return "<path d='m215 716 71-123s144 73 388 21l137 179s-414 186-596-77' fill='#ecf' class='a r'/><path d='M286 593s161 224 246 39c0 0 71 164 142-18' fill='none' class='a r'/>";
    }else if(num == 3) {
      // scarf
      return "<path d='m267 626 18-43s158 52 400 21l10 43s-161 36-204 92c0 0-64-69-224-113Z' fill='#df1c24' class='a r'/><path fill='none' stroke='#b3272d' class='r' stroke-width='9' d='m316 634 13-30M359 650l17-42M399 670l21-57M437 690l26-72M481 716l30-90M538 695l23-69M589 672l18-53M641 652l11-37M307 604l282 68M338 637l200 58M514 622l126 26'/>";
    }else if(num == 4) {
      // bell
      return "<path d='M291 581s196 58 389 21l14 57s-232 44-425-31Z' fill='#df1c24' class='a'/><path d='M538 690h-4v-36c0-16-12-30-28-33a8 8 0 1 0-13 0c-16 3-28 16-28 33a33 33 0 0 0 0 6v30h-3a11 11 0 1 0 0 21h76a11 11 0 0 0 0-21Z' fill='#ff0' class='a'/>";
    }else{
      // ore
      return "<path d='M291 581s196 58 389 21l14 57s-232 44-425-31Z' fill='#b88e6d' class='a'/><path fill='#bebebe' d='M490 622h26l10-18h-46l10 18z'/><path fill='#a5a5a5' d='m490 622-10-18-24 40h22l12-22z'/><path fill='#d8d8d8' d='M528 644h22l-24-40-10 18 12 22zM478 644h-22l24 40 10-18-12-22z'/><path fill='#a5a5a5' d='m528 644-12 22 10 18 24-40h-22z'/><path fill='#bebebe' d='M516 666h-26l-10 18v1h46v-1l-10-18z'/><path class='w' d='M516 623v-1h-26l1 1-1-1-12 22 12 22h1-1 26l12-22-12-22v1z'/><path fill='none' class='a' d='M526 604h-46l-24 40 24 40v1h46v-1l24-40-24-40z'/>";
    }
  }

  function item(uint256 saurusItem) internal view returns(string memory) {
    uint256 num = saurusItem % 8;
    if(saurusItem == 0){
      return "";
    }
    else if(num == 0) {
      // artist
      return "<path d='M361 774s44-70 102-27c0 0-20 50-102 27Z' class='a' fill='#603813'/><rect x='95' y='778' width='302' height='41' rx='12' transform='rotate(-14 246 799)' class='a' fill='#0071ae'/><path d='M444 736s-12 23 8 26l17-16Z' class='a' fill='#39a74a'/><ellipse cx='679.5' cy='840.8' rx='119.2' ry='165.9' transform='rotate(-82 680 841)' fill='#fff' class='a'/><ellipse cx='696.3' cy='918.9' rx='34.8' ry='22' fill='#eee021'/><ellipse cx='778.3' cy='896.3' rx='34.8' ry='22' transform='rotate(-23 778 896)' fill='#299dd4'/><ellipse cx='616.7' cy='894.3' rx='25.3' ry='34.8' transform='rotate(-60 617 894)' fill='#df1c24'/><ellipse cx='558.5' cy='833.7' rx='25.3' ry='34.8' transform='rotate(-23 558 834)' fill='#39a74a'/>";
    }else if(num == 1) {
      // baseball
      return "<circle cx='260' cy='854' r='88' class='a r w'/><path d='M308 780s-60 79 15 135M190 803s85 50 37 131' fill='none' stroke='#df1c24' stroke-width='5'/>";
    }else if(num == 2) {
      // candy
      return "<circle cx='734.8' cy='840' r='70.2' class='a r' fill='#df1c24'/><path fill='#b3272d' class='a r' d='m692 802-78-85-54 150 117-11M793 824l107-42-17 158-100-61'/>";
    }else if(num == 3) {
      // apple
      return "<circle cx='297.1' cy='847.3' r='89.1' class='a r' fill='#df1c24'/><path class='a r' fill='#603813' d='m338 798 49-49-16-18-46 64'/><path d='M344 782s60-41 71 16c0 0-39 39-71-16Z' class='a r' fill='#39a74a'/>";
    }else if(num == 4) {
      // carrot
      return "<path d='M324 770s153-122 230 41c0 0 19 29-28 25 0 0 49 71-35 45 0 0 17 77-44 15 0 0-57-101-117-101Z' fill='#80b83f' class='a'/><path d='M99 880s235-219 277-103c0 0 43 84-277 103Z' fill='#e9851e' class='a'/>";
    }else if(num == 5) {
      // meat
      return "<path d='M157 918h-1l52-31-22-38-52 30-1-1a30 30 0 1 0-31 45 30 30 0 1 0 55-5Z' class='a w'/><rect x='152.4' y='735.8' width='217.7' height='195.2' rx='93' transform='rotate(-25 261 833)' fill='#754c24' class='a r'/>";
    }else if(num == 6) {
      // knife
      return "<rect x='146.8' y='806.6' width='170.3' height='49.4' rx='12' transform='rotate(-9 232 831)' fill='#333' stroke='#231f20' stroke-miterlimit='10' stroke-width='5'/><path d='m298 796 184-28s31 88-85 106l-81 12-4 1Z' class='w' stroke='#231f20' stroke-miterlimit='10' stroke-width='5'/>";
    }else{
      // book
      return "<path d='M283 688v-28l6-24s128-46 187 48h42s47-91 187-48l6 24v72H283Z' class='a w'/><path d='M711 660s-128-45-193 48h-42c-65-94-193-48-193-48l-2 257c104-14 195 50 195 50h42s91-64 195-50ZM476 708v259M518 708v259' fill='#a58ebe' class='a'/><path d='M707 648s-126-44-189 47h-42c-63-91-189-47-189-47' fill='none' class='a'/>";
    }
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