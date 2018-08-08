pragma solidity ^0.4.13;

contract Sudokoin {
  uint supply = 203462379904501283815424;
  uint public boards = 0; // max 6670903752021072936960

  string public constant name = "Sudokoin";
  string public constant symbol = "SDK";
  uint8 public constant decimals = 12;

  mapping (address => mapping (address => uint)) allowances;
  mapping (address => uint) balances;
  mapping (uint => bool) public claimedBoards;

  event Approval(address indexed _owner, address indexed _spender, uint _value);
  event BoardClaimed(uint _board, uint _no, address _by);
  event Burn(address indexed _from, uint _value);
  event Transfer(address indexed _from, address indexed _to, uint _value);

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    remaining = allowances[_owner][_spender];
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    balance = balances[_owner];
  }

  function totalSupply() constant returns (uint totalSupply) {
    totalSupply = supply;
  }

  function claimBoard(uint[81] _b) returns (bool success) {
    require(validateBoard(_b));
    uint cb = compressBoard(_b);
    if (!claimedBoards[cb]) {
      claimedBoards[cb] = true;
      balances[msg.sender] += nextReward(boards);
      boards += 1;
      BoardClaimed(boards, cb, msg.sender);
      return true;
    }
    return false;
  }

  function approve(address _spender, uint _value) returns (bool success) {
      require(msg.data.length >= 68);
      allowances[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
      require(msg.data.length >= 68);
      require(_to != 0x0); // use burn!
      require(_value <= balances[msg.sender]);
      require(_value + balances[_to] >= balances[_to]);
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
      require(msg.data.length >= 100);
      require(_to != 0x0); // use burnFrom!
      require(_value <= balances[_from]);
      require(_value <= allowances[_from][msg.sender]);
      require(_value + balances[_to] >= balances[_to]);
      balances[_from] -= _value;
      balances[_to] += _value;
      allowances[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
  }

  function burn(uint _value) returns (bool success) {
      require(_value <= balances[msg.sender]);
      balances[msg.sender] -= _value;
      supply -= _value;
      Burn(msg.sender, _value);
      return true;
  }

  function burnFrom(address _from, uint _value) returns (bool success) {
      require(_value <= balances[_from]);
      require(_value <= allowances[_from][msg.sender]);
      balances[_from] -= _value;
      allowances[_from][msg.sender] -= _value;
      supply -= _value;
      Burn(_from, _value);
      return true;
  }

  // compressBoard removes last col and last row and joins digits into one number.
  function compressBoard(uint[81] _b) constant returns (uint) {
    uint cb = 0;
    uint mul = 1000000000000000000000000000000000000000000000000000000000000000;
    for (uint i = 0; i < 72; i++) {
      if (i % 9 == 8) {
        continue;
      }
      cb = cb + mul * _b[i];
      mul = mul / 10;
    }
    return cb;
  }

  function validateBoard(uint[81] _b) constant returns (bool) {
    return
      // rows
      validateSet( _b[0], _b[1], _b[2], _b[3], _b[4], _b[5], _b[6], _b[7], _b[8]) &&
      validateSet( _b[9],_b[10],_b[11],_b[12],_b[13],_b[14],_b[15],_b[16],_b[17]) &&
      validateSet(_b[18],_b[19],_b[20],_b[21],_b[22],_b[23],_b[24],_b[25],_b[26]) &&
      validateSet(_b[27],_b[28],_b[29],_b[30],_b[31],_b[32],_b[33],_b[34],_b[35]) &&
      validateSet(_b[36],_b[37],_b[38],_b[39],_b[40],_b[41],_b[42],_b[43],_b[44]) &&
      validateSet(_b[45],_b[46],_b[47],_b[48],_b[49],_b[50],_b[51],_b[52],_b[53]) &&
      validateSet(_b[54],_b[55],_b[56],_b[57],_b[58],_b[59],_b[60],_b[61],_b[62]) &&
      validateSet(_b[63],_b[64],_b[65],_b[66],_b[67],_b[68],_b[69],_b[70],_b[71]) &&
      validateSet(_b[72],_b[73],_b[74],_b[75],_b[76],_b[77],_b[78],_b[79],_b[80]) &&

      // cols
      validateSet(_b[0], _b[9],_b[18],_b[27],_b[36],_b[45],_b[54],_b[63],_b[72]) &&
      validateSet(_b[1],_b[10],_b[19],_b[28],_b[37],_b[46],_b[55],_b[64],_b[73]) &&
      validateSet(_b[2],_b[11],_b[20],_b[29],_b[38],_b[47],_b[56],_b[65],_b[74]) &&
      validateSet(_b[3],_b[12],_b[21],_b[30],_b[39],_b[48],_b[57],_b[66],_b[75]) &&
      validateSet(_b[4],_b[13],_b[22],_b[31],_b[40],_b[49],_b[58],_b[67],_b[76]) &&
      validateSet(_b[5],_b[14],_b[23],_b[32],_b[41],_b[50],_b[59],_b[68],_b[77]) &&
      validateSet(_b[6],_b[15],_b[24],_b[33],_b[42],_b[51],_b[60],_b[69],_b[78]) &&
      validateSet(_b[7],_b[16],_b[25],_b[34],_b[43],_b[52],_b[61],_b[70],_b[79]) &&
      validateSet(_b[8],_b[17],_b[26],_b[35],_b[44],_b[53],_b[62],_b[71],_b[80]) &&

      // blocks
      validateSet( _b[0], _b[1], _b[2], _b[9],_b[10],_b[11],_b[18],_b[19],_b[20]) &&
      validateSet(_b[27],_b[28],_b[29],_b[36],_b[37],_b[38],_b[45],_b[46],_b[47]) &&
      validateSet(_b[54],_b[55],_b[56],_b[63],_b[64],_b[65],_b[72],_b[73],_b[74]) &&
      validateSet( _b[3], _b[4], _b[5],_b[12],_b[13],_b[14],_b[21],_b[22],_b[23]) &&
      validateSet(_b[30],_b[31],_b[32],_b[39],_b[40],_b[41],_b[48],_b[49],_b[50]) &&
      validateSet(_b[57],_b[58],_b[59],_b[66],_b[67],_b[68],_b[75],_b[76],_b[77]) &&
      validateSet( _b[6], _b[7], _b[8],_b[15],_b[16],_b[17],_b[24],_b[25],_b[26]) &&
      validateSet(_b[33],_b[34],_b[35],_b[42],_b[43],_b[44],_b[51],_b[52],_b[53]) &&
      validateSet(_b[60],_b[61],_b[62],_b[69],_b[70],_b[71],_b[78],_b[79],_b[80]);
  }

  function validateSet(uint _v1, uint _v2, uint _v3, uint _v4, uint _v5, uint _v6, uint _v7, uint _v8, uint _v9) private returns (bool) {
    uint set = addToSet(0, _v1);
    if (setIncludes(set, _v2)) { return false; }
    set = addToSet(set, _v2);
    if (setIncludes(set, _v3)) { return false; }
    set = addToSet(set, _v3);
    if (setIncludes(set, _v4)) { return false; }
    set = addToSet(set, _v4);
    if (setIncludes(set, _v5)) { return false; }
    set = addToSet(set, _v5);
    if (setIncludes(set, _v6)) { return false; }
    set = addToSet(set, _v6);
    if (setIncludes(set, _v7)) { return false; }
    set = addToSet(set, _v7);
    if (setIncludes(set, _v8)) { return false; }
    set = addToSet(set, _v8);
    if (setIncludes(set, _v9)) { return false; }
    return true;
  }

  function setIncludes(uint _set, uint _number) private returns (bool success) {
    return _number == 0 || _number > 9 || _set & (1 << _number) != 0;
  }

  function addToSet(uint _set, uint _number) private returns (uint set) {
    return _set | (1 << _number);
  }

  // returns reward for the next submitted board, so reward first and then increase boards!
  function nextReward(uint _bNo) constant returns (uint) {
    if (_bNo < 11572) { return 576460752303423488; } // tier 1
    if (_bNo < 23144) { return 288230376151711744; } // tier 2
    if (_bNo < 46288) { return 144115188075855872; } // tier 3
    if (_bNo < 92577) { return 72057594037927936; } // tier 4
    if (_bNo < 185154) { return 36028797018963968; } // tier 5
    if (_bNo < 370309) { return 18014398509481984; } // tier 6
    if (_bNo < 740619) { return 9007199254740992; } // tier 7
    if (_bNo < 1481238) { return 4503599627370496; } // tier 8
    if (_bNo < 2962476) { return 2251799813685248; } // tier 9
    if (_bNo < 5924952) { return 1125899906842624; } // tier 10
    if (_bNo < 11849905) { return 562949953421312; } // tier 11
    if (_bNo < 23699811) { return 281474976710656; } // tier 12
    if (_bNo < 47399622) { return 140737488355328; } // tier 13
    if (_bNo < 94799244) { return 70368744177664; } // tier 14
    if (_bNo < 189598488) { return 35184372088832; } // tier 15
    if (_bNo < 379196976) { return 17592186044416; } // tier 16
    if (_bNo < 758393952) { return 8796093022208; } // tier 17
    if (_bNo < 1516787904) { return 4398046511104; } // tier 18
    if (_bNo < 3033575809) { return 2199023255552; } // tier 19
    if (_bNo < 6067151618) { return 1099511627776; } // tier 20
    if (_bNo < 12134303237) { return 549755813888; } // tier 21
    if (_bNo < 24268606474) { return 274877906944; } // tier 22
    if (_bNo < 48537212948) { return 137438953472; } // tier 23
    if (_bNo < 97074425896) { return 68719476736; } // tier 24
    if (_bNo < 194148851792) { return 34359738368; } // tier 25
    if (_bNo < 388297703584) { return 17179869184; } // tier 26
    if (_bNo < 776595407168) { return 8589934592; } // tier 27
    if (_bNo < 1553190814336) { return 4294967296; } // tier 28
    if (_bNo < 3106381628672) { return 2147483648; } // tier 29
    if (_bNo < 6212763257344) { return 1073741824; } // tier 30
    if (_bNo < 12425526514688) { return 536870912; } // tier 31
    if (_bNo < 24851053029377) { return 268435456; } // tier 32
    if (_bNo < 49702106058754) { return 134217728; } // tier 33
    if (_bNo < 99404212117509) { return 67108864; } // tier 34
    if (_bNo < 198808424235018) { return 33554432; } // tier 35
    if (_bNo < 397616848470036) { return 16777216; } // tier 36
    if (_bNo < 795233696940073) { return 8388608; } // tier 37
    if (_bNo < 1590467393880146) { return 4194304; } // tier 38
    if (_bNo < 3180934787760292) { return 2097152; } // tier 39
    if (_bNo < 6361869575520585) { return 1048576; } // tier 40
    if (_bNo < 12723739151041170) { return 524288; } // tier 41
    if (_bNo < 25447478302082340) { return 262144; } // tier 42
    if (_bNo < 50894956604164680) { return 131072; } // tier 43
    if (_bNo < 101789913208329360) { return 65536; } // tier 44
    if (_bNo < 203579826416658720) { return 32768; } // tier 45
    if (_bNo < 407159652833317440) { return 16384; } // tier 46
    if (_bNo < 814319305666634880) { return 8192; } // tier 47
    if (_bNo < 1628638611333269760) { return 4096; } // tier 48
    if (_bNo < 3257277222666539520) { return 2048; } // tier 49
    if (_bNo < 6514554445333079040) { return 1024; } // tier 50
    if (_bNo < 13029108890666158080) { return 512; } // tier 51
    if (_bNo < 26058217781332316160) { return 256; } // tier 52
    if (_bNo < 52116435562664632320) { return 128; } // tier 53
    if (_bNo < 104232871125329264640) { return 64; } // tier 54
    if (_bNo < 208465742250658529280) { return 32; } // tier 55
    if (_bNo < 416931484501317058560) { return 16; } // tier 56
    if (_bNo < 833862969002634117120) { return 8; } // tier 57
    if (_bNo < 1667725938005268234240) { return 4; } // tier 58
    if (_bNo < 3335451876010536468480) { return 2; } // tier 59
    if (_bNo < 6670903752021072936960) { return 1; } // tier 60
    return 0;
  }
}