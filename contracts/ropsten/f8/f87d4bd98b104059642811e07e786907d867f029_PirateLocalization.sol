pragma solidity ^0.4.25;

contract Localization {
  mapping(bytes32 => string) internal dictionary_;

  constructor() public {}

  function set(bytes32 _code, string _message) public {
    dictionary_[_code] = _message;
  }

  function textFor(bytes32 _code) external view returns (string _message) {
    return dictionary_[_code];
  }
}

contract FissionLocalization is Localization {
    event FissionCode(bytes32 indexed code, string message);

    function log(bytes32 _code) public {
        emit FissionCode(_code, dictionary_[_code]);
    }
}

contract PirateLocalization is FissionLocalization {
  constructor() public {
    set(hex"00", "Nay!");
    set(hex"01", "Aye!");
    set(hex"02", "Arr jolly crew have begun");
    set(hex"03", "Awaitin&#39;");
    set(hex"04", "Ye need ta do something");
    set(hex"05", "Has walked thar plank an expired");

    set(hex"0F", "Only this here metadata");

    set(hex"10", "Ye can nay do that");
    set(hex"11", "Ye be permitted");
    set(hex"12", "Ye have requested thar go ahead");
    set(hex"13", "Yer waitin&#39; fer the go ahead");
    set(hex"14", "Thar awaiting yer signal");
    set(hex"15", "No Longer Allowed");

    set(hex"20", "Nay plunder found");
    set(hex"21", "Plunder found");
    set(hex"22", "Yer match request be sent");
    set(hex"23", "Ye need t&#39; wait fer yer match");
    set(hex"24", "Thar jolly crew got yer message");
    set(hex"25", "That be outta range");

    set(hex"30", "No deal, matey");
    set(hex"31", "The other crew has agreed to yer terms");
    set(hex"32", "Yer offer has been sent");
    set(hex"33", "Yer awaitin&#39; thar agreement");
    set(hex"34", "Thar awaitin&#39; yer agreement");
    set(hex"35", "Offer nay longer on the table");

    set(hex"40", "Nay ready yet");
    set(hex"41", "&#39;tis ready, matey");
    set(hex"42", "Ye may start");
    set(hex"43", "Nay yet ready");
    set(hex"44", "We be awaitin&#39; yer signal");
    set(hex"45", "Nay available anymore");

    set(hex"E0", "Yer message can nay be unscrambled");
    set(hex"E1", "Yer message be unscrambled");
    set(hex"E2", "Yer payload be signed");
    set(hex"E3", "Ye need a signin&#39; from thar other crew");
    set(hex"E4", "Yer signature be needed");
    set(hex"E5", "That there token be nay jolly good no more");

    set(hex"F0", "Off chain excursion be a failure");
    set(hex"F1", "Off chain excursion be a success");
    set(hex"F2", "Yer process has begun off chain");
    set(hex"F3", "Awaitin&#39; fer completion off chain");
    set(hex"F4", "Yer action be needed off chain");
    set(hex"F5", "Off chain service be not around");

    set(hex"FF", "Data source be off chain (ie: nay guaranteed)");
  }
}