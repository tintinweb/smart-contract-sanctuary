// solhint-disable-next-line compiler-fixed, compiler-gt-0_4
pragma solidity ^0.4.24;

//                             _,,ad8888888888bba,_
//                         ,ad88888I888888888888888ba,
//                       ,88888888I88888888888888888888a,
//                     ,d888888888I8888888888888888888888b,
//                    d88888PP"""" ""YY88888888888888888888b,
//                  ,d88"&#39;__,,--------,,,,.;ZZZY8888888888888,
//                 ,8IIl&#39;"                ;;l"ZZZIII8888888888,
//                ,I88l;&#39;                  ;lZZZZZ888III8888888,
//              ,II88Zl;.                  ;llZZZZZ888888I888888,
//             ,II888Zl;.                .;;;;;lllZZZ888888I8888b
//            ,II8888Z;;                 `;;;;;&#39;&#39;llZZ8888888I8888,
//            II88888Z;&#39;                        .;lZZZ8888888I888b
//            II88888Z; _,aaa,      .,aaaaa,__.l;llZZZ88888888I888
//            II88888IZZZZZZZZZ,  .ZZZZZZZZZZZZZZ;llZZ88888888I888,
//            II88888IZZ<&#39;(@@>Z|  |ZZZ<&#39;(@@>ZZZZ;;llZZ888888888I88I
//           ,II88888;   `""" ;|  |ZZ; `"""     ;;llZ8888888888I888
//           II888888l            `;;          .;llZZ8888888888I888,
//          ,II888888Z;           ;;;        .;;llZZZ8888888888I888I
//          III888888Zl;    ..,   `;;       ,;;lllZZZ88888888888I888
//          II88888888Z;;...;(_    _)      ,;;;llZZZZ88888888888I888,
//          II88888888Zl;;;;;&#39; `--&#39;Z;.   .,;;;;llZZZZ88888888888I888b
//          ]I888888888Z;;;;&#39;   ";llllll;..;;;lllZZZZ88888888888I8888,
//          II888888888Zl.;;"Y88bd888P";;,..;lllZZZZZ88888888888I8888I
//          II8888888888Zl;.; `"PPP";;;,..;lllZZZZZZZ88888888888I88888
//          II888888888888Zl;;. `;;;l;;;;lllZZZZZZZZW88888888888I88888
//          `II8888888888888Zl;.    ,;;lllZZZZZZZZWMZ88888888888I88888
//           II8888888888888888ZbaalllZZZZZZZZZWWMZZZ8888888888I888888,
//           `II88888888888888888b"WWZZZZZWWWMMZZZZZZI888888888I888888b
//            `II88888888888888888;ZZMMMMMMZZZZZZZZllI888888888I8888888
//             `II8888888888888888 `;lZZZZZZZZZZZlllll888888888I8888888,
//              II8888888888888888, `;lllZZZZllllll;;.Y88888888I8888888b,
//             ,II8888888888888888b   .;;lllllll;;;.;..88888888I88888888b,
//             II888888888888888PZI;.  .`;;;.;;;..; ...88888888I8888888888,
//             II888888888888PZ;;&#39;;;.   ;. .;.  .;. .. Y8888888I88888888888b,
//            ,II888888888PZ;;&#39;                        `8888888I8888888888888b,
//            II888888888&#39;                              888888I8888888888888888b
//           ,II888888888                              ,888888I88888888888888888
//          ,d88888888888                              d888888I8888888888ZZZZZZZ
//       ,ad888888888888I                              8888888I8888ZZZZZZZZZZZZZ
//     ,d888888888888888&#39;                              888888IZZZZZZZZZZZZZZZZZZ
//   ,d888888888888P&#39;8P&#39;                               Y888ZZZZZZZZZZZZZZZZZZZZZ
//  ,8888888888888,  "                                 ,ZZZZZZZZZZZZZZZZZZZZZZZZ
// d888888888888888,                                ,ZZZZZZZZZZZZZZZZZZZZZZZZZZZ
// 888888888888888888a,      _                    ,ZZZZZZZZZZZZZZZZZZZZ888888888
// 888888888888888888888ba,_d&#39;                  ,ZZZZZZZZZZZZZZZZZ88888888888888
// 8888888888888888888888888888bbbaaa,,,______,ZZZZZZZZZZZZZZZ888888888888888888
// 88888888888888888888888888888888888888888ZZZZZZZZZZZZZZZ888888888888888888888
// 8888888888888888888888888888888888888888ZZZZZZZZZZZZZZ88888888888888888888888
// 888888888888888888888888888888888888888ZZZZZZZZZZZZZZ888888888888888888888888
// 8888888888888888888888888888888888888ZZZZZZZZZZZZZZ88888888888888888888888888
// 88888888888888888888888888888888888ZZZZZZZZZZZZZZ8888888888888888888888888888
// 8888888888888888888888888888888888ZZZZZZZZZZZZZZ88888888888888888 Da Vinci 88
// 88888888888888888888888888888888ZZZZZZZZZZZZZZ8888888888888888888  Coders  88
// 8888888888888888888888888888888ZZZZZZZZZZZZZZ88888888888888888888888888888888


library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    return a / b;
  }

  function mod(uint a, uint b) internal pure returns (uint) {
    return a % b;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Dividends {
  using SafeMath for *;

  uint private constant FIXED_POINT = 1000000000000000000;

  struct Scheme {
    uint value;
    uint shares;
    uint mask;
  }

  struct Vault {
    uint value;
    uint shares;
    uint mask;
  }

  mapping (uint => mapping (address => Vault)) private vaultOfAddress;
  mapping (uint => Scheme) private schemeOfId;

  function buyShares (uint _schemeId, address _owner, uint _shares, uint _value) internal {
    require(_owner != address(0));
    require(_shares > 0 && _value > 0);

    uint value = _value.mul(FIXED_POINT);

    Scheme storage scheme = schemeOfId[_schemeId];

    scheme.value = scheme.value.add(_value);
    scheme.shares = scheme.shares.add(_shares);

    require(value > scheme.shares);

    uint pps = value.div(scheme.shares);

    Vault storage vault = vaultOfAddress[_schemeId][_owner];

    vault.shares = vault.shares.add(_shares);
    vault.mask = vault.mask.add(scheme.mask.mul(_shares));
    vault.value = vault.value.add(value.sub(pps.mul(scheme.shares)));

    scheme.mask = scheme.mask.add(pps);
  }

  function flushVault (uint _schemeId, address _owner) internal {
    uint gains = gainsOfVault(_schemeId, _owner);
    if (gains > 0) {
      Vault storage vault = vaultOfAddress[_schemeId][_owner];
      vault.value = vault.value.add(gains);
      vault.mask = vault.mask.add(gains);
    }
  }

  function withdrawVault (uint _schemeId, address _owner) internal returns (uint) {
    flushVault(_schemeId, _owner);

    Vault storage vault = vaultOfAddress[_schemeId][_owner];
    uint payout = vault.value.div(FIXED_POINT);

    if (payout > 0) {
      vault.value = 0;
    }

    return payout;
  }

  function creditVault (uint _schemeId, address _owner, uint _value) internal {
    Vault storage vault = vaultOfAddress[_schemeId][_owner];
    vault.value = vault.value.add(_value.mul(FIXED_POINT));
  }

  function gainsOfVault (uint _schemeId, address _owner) internal view returns (uint) {
    Scheme storage scheme = schemeOfId[_schemeId];
    Vault storage vault = vaultOfAddress[_schemeId][_owner];

    if (vault.shares == 0) {
      return 0;
    }

    return scheme.mask.mul(vault.shares).sub(vault.mask);
  }

  function valueOfVault (uint _schemeId, address _owner) internal view returns (uint) {
    Vault storage vault = vaultOfAddress[_schemeId][_owner];
    return vault.value;
  }

  function balanceOfVault (uint _schemeId, address _owner) internal view returns (uint) {
    Vault storage vault = vaultOfAddress[_schemeId][_owner];

    uint total = vault.value.add(gainsOfVault(_schemeId, _owner));
    uint balance = total.div(FIXED_POINT);

    return balance;
  }

  function sharesOfVault (uint _schemeId, address _owner) internal view returns (uint) {
    Vault storage vault = vaultOfAddress[_schemeId][_owner];
    return vault.shares;
  }

  function valueOfScheme (uint _schemeId) internal view returns (uint) {
    return schemeOfId[_schemeId].value;
  }

  function sharesOfScheme (uint _schemeId) internal view returns (uint) {
    return schemeOfId[_schemeId].shares;
  }
}


library Utils {
  using SafeMath for uint;

  uint private constant LAST_COUNTRY = 195;

  function regularTicketPrice () internal pure returns (uint) {
    return 100000000000000;
  }

  function goldenTicketPrice (uint _x) internal pure returns (uint) {
    uint price = _x.mul(_x).div(2168819140000000000000000).add(100000000000000).add(_x.div(100000));
    return price < regularTicketPrice() ? regularTicketPrice() : price;
  }

  function ticketsForWithExcess (uint _value) internal pure returns (uint, uint) {
    uint tickets = _value.div(regularTicketPrice());
    uint excess = _value.sub(tickets.mul(regularTicketPrice()));
    return (tickets, excess);
  }

  function percentageOf (uint _value, uint _p) internal pure returns (uint) {
    return _value.mul(_p).div(100);
  }

  function validReferralCode (string _code) internal pure returns (bool) {
    bytes memory b = bytes(_code);

    if (b.length < 3) {
      return false;
    }

    for (uint i = 0; i < b.length; i++) {
      bytes1 c = b[i];
      if (
        !(c >= 0x30 && c <= 0x39) && // 0-9
        !(c >= 0x41 && c <= 0x5A) && // A-Z
        !(c >= 0x61 && c <= 0x7A) && // a-z
        !(c == 0x2D) // -
      ) {
        return false;
      }
    }

    return true;
  }

  function validNick (string _nick) internal pure returns (bool) {
    return bytes(_nick).length > 3;
  }

  function validCountryId (uint _countryId) internal pure returns (bool) {
    return _countryId > 0 && _countryId <= LAST_COUNTRY;
  }
}


contract Events {
  event Started (
    uint _time
  );

  event Bought (
    address indexed _player,
    address indexed _referral,
    uint _countryId,
    uint _tickets,
    uint _value,
    uint _excess
  );

  event Promoted (
    address indexed _player,
    uint _goldenTickets,
    uint _endTime
  );

  event Withdrew (
    address indexed _player,
    uint _amount
  );

  event Registered (
    string _code, address indexed _referral
  );

  event Won (
    address indexed _winner, uint _pot
  );
}


contract Constants {
  uint internal constant MAIN_SCHEME = 1337;
  uint internal constant DEFAULT_COUNTRY = 1;

  uint internal constant SET_NICK_FEE = 0.01 ether;
  uint internal constant REFERRAL_REGISTRATION_FEE = 0.01 ether;

  uint internal constant TO_DIVIDENDS = 42;
  uint internal constant TO_REFERRAL = 10;
  uint internal constant TO_DEVELOPERS = 4;
  uint internal constant TO_COUNTRY = 12;
}


contract State is Constants {
  address internal addressOfOwner;

  uint internal maxTime = 0;
  uint internal addedTime = 0;

  uint internal totalPot = 0;
  uint internal startTime = 0;
  uint internal endTime = 0;
  bool internal potWithdrawn = false;
  address internal addressOfCaptain;

  struct Info {
    address referral;
    uint countryId;
    uint withdrawn;
    string nick;
  }

  mapping (address => Info) internal infoOfAddress;
  mapping (address => string[]) internal codesOfAddress;
  mapping (string => address) internal addressOfCode;

  modifier restricted () {
    require(msg.sender == addressOfOwner);
    _;
  }

  modifier active () {
    require(startTime > 0);
    require(block.timestamp < endTime);
    require(!potWithdrawn);
    _;
  }

  modifier player () {
    require(infoOfAddress[msg.sender].countryId > 0);
    _;
  }
}


contract Core is Events, State, Dividends {}


contract ExternalView is Core {
  function totalInfo () external view returns (bool, bool, address, uint, uint, uint, uint, uint, uint, address) {
    return (
      startTime > 0,
      block.timestamp >= endTime,
      addressOfCaptain,
      totalPot,
      endTime,
      sharesOfScheme(MAIN_SCHEME),
      valueOfScheme(MAIN_SCHEME),
      maxTime,
      addedTime,
      addressOfOwner
    );
  }

  function countryInfo (uint _countryId) external view returns (uint, uint) {
    return (
      sharesOfScheme(_countryId),
      valueOfScheme(_countryId)
    );
  }

  function playerInfo (address _player) external view returns (uint, uint, uint, address, uint, uint, string) {
    Info storage info = infoOfAddress[_player];
    return (
      sharesOfVault(MAIN_SCHEME, _player),
      balanceOfVault(MAIN_SCHEME, _player),
      balanceOfVault(info.countryId, _player),
      info.referral,
      info.countryId,
      info.withdrawn,
      info.nick
    );
  }

  function numberOfReferralCodes (address _player) external view returns (uint) {
    return codesOfAddress[_player].length;
  }

  function referralCodeAt (address _player, uint i) external view returns (string) {
    return codesOfAddress[_player][i];
  }

  function codeToAddress (string _code) external view returns (address) {
    return addressOfCode[_code];
  }

  function goldenTicketPrice (uint _x) external pure returns (uint) {
    return Utils.goldenTicketPrice(_x);
  }
}


contract Internal is Core {
  function _registerReferral (string _code, address _referral) internal {
    require(Utils.validReferralCode(_code));
    require(addressOfCode[_code] == address(0));

    addressOfCode[_code] = _referral;
    codesOfAddress[_referral].push(_code);

    emit Registered(_code, _referral);
  }
}


contract WinnerWinner is Core, Internal, ExternalView {
  using SafeMath for *;

  constructor () public {
    addressOfOwner = msg.sender;
  }

  function () public payable {
    buy(addressOfOwner, DEFAULT_COUNTRY);
  }

  function start (uint _maxTime, uint _addedTime) public restricted {
    require(startTime == 0);
    require(_maxTime > 0 && _addedTime > 0);
    require(_maxTime > _addedTime);

    maxTime = _maxTime;
    addedTime = _addedTime;

    startTime = block.timestamp;
    endTime = startTime + maxTime;
    addressOfCaptain = addressOfOwner;

    _registerReferral("owner", addressOfOwner);

    emit Started(startTime);
  }

  function buy (address _referral, uint _countryId) public payable active {
    require(msg.value >= Utils.regularTicketPrice());
    require(msg.value <= 100000 ether);
    require(codesOfAddress[_referral].length > 0);
    require(_countryId != MAIN_SCHEME);
    require(Utils.validCountryId(_countryId));

    (uint tickets, uint excess) = Utils.ticketsForWithExcess(msg.value);
    uint value = msg.value.sub(excess);

    require(tickets > 0);
    require(value.add(excess) == msg.value);

    Info storage info = infoOfAddress[msg.sender];

    if (info.countryId == 0) {
      info.referral = _referral;
      info.countryId = _countryId;
    }

    uint vdivs = Utils.percentageOf(value, TO_DIVIDENDS);
    uint vreferral = Utils.percentageOf(value, TO_REFERRAL);
    uint vdevs = Utils.percentageOf(value, TO_DEVELOPERS);
    uint vcountry = Utils.percentageOf(value, TO_COUNTRY);
    uint vpot = value.sub(vdivs).sub(vreferral).sub(vdevs).sub(vcountry);

    assert(vdivs.add(vreferral).add(vdevs).add(vcountry).add(vpot) == value);

    buyShares(MAIN_SCHEME, msg.sender, tickets, vdivs);
    buyShares(info.countryId, msg.sender, tickets, vcountry);

    creditVault(MAIN_SCHEME, info.referral, vreferral);
    creditVault(MAIN_SCHEME, addressOfOwner, vdevs);

    if (excess > 0) {
      creditVault(MAIN_SCHEME, msg.sender, excess);
    }

    uint goldenTickets = value.div(Utils.goldenTicketPrice(totalPot));
    if (goldenTickets > 0) {
      endTime = endTime.add(goldenTickets.mul(addedTime)) > block.timestamp.add(maxTime) ?
        block.timestamp.add(maxTime) : endTime.add(goldenTickets.mul(addedTime));
      addressOfCaptain = msg.sender;
      emit Promoted(addressOfCaptain, goldenTickets, endTime);
    }

    totalPot = totalPot.add(vpot);

    emit Bought(msg.sender, info.referral, info.countryId, tickets, value, excess);
  }

  function setNick (string _nick) public payable {
    require(msg.value == SET_NICK_FEE);
    require(Utils.validNick(_nick));
    infoOfAddress[msg.sender].nick = _nick;
    creditVault(MAIN_SCHEME, addressOfOwner, msg.value);
  }

  function registerCode (string _code) public payable {
    require(startTime > 0);
    require(msg.value == REFERRAL_REGISTRATION_FEE);
    _registerReferral(_code, msg.sender);
    creditVault(MAIN_SCHEME, addressOfOwner, msg.value);
  }

  function giftCode (string _code, address _referral) public restricted {
    _registerReferral(_code, _referral);
  }

  function withdraw () public {
    Info storage info = infoOfAddress[msg.sender];
    uint payout = withdrawVault(MAIN_SCHEME, msg.sender);

    if (Utils.validCountryId(info.countryId)) {
      payout = payout.add(withdrawVault(info.countryId, msg.sender));
    }

    if (payout > 0) {
      info.withdrawn = info.withdrawn.add(payout);
      msg.sender.transfer(payout);
      emit Withdrew(msg.sender, payout);
    }
  }

  function withdrawPot () public player {
    require(startTime > 0);
    require(block.timestamp > (endTime + 10 minutes));
    require(!potWithdrawn);
    require(totalPot > 0);
    require(addressOfCaptain == msg.sender);

    uint payout = totalPot;
    totalPot = 0;
    potWithdrawn = true;
    addressOfCaptain.transfer(payout);
    emit Won(msg.sender, payout);
  }
}