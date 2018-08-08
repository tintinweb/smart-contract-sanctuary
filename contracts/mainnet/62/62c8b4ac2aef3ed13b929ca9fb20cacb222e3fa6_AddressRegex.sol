pragma solidity ^0.4.11;

contract AddressRegex {
  struct State {
    bool accepts;
    function (byte) constant internal returns (State memory) func;
  }

  string public constant regex = "0x[0-9a-fA-F]{40}";

  function s0(byte c) constant internal returns (State memory) {
    c = c;
    return State(false, s0);
  }

  function s1(byte c) constant internal returns (State memory) {
    if (c == 48) {
      return State(false, s2);
    }

    return State(false, s0);
  }

  function s2(byte c) constant internal returns (State memory) {
    if (c == 120) {
      return State(false, s3);
    }

    return State(false, s0);
  }

  function s3(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s4);
    }

    return State(false, s0);
  }

  function s4(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s5);
    }

    return State(false, s0);
  }

  function s5(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s6);
    }

    return State(false, s0);
  }

  function s6(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s7);
    }

    return State(false, s0);
  }

  function s7(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s8);
    }

    return State(false, s0);
  }

  function s8(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s9);
    }

    return State(false, s0);
  }

  function s9(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s10);
    }

    return State(false, s0);
  }

  function s10(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s11);
    }

    return State(false, s0);
  }

  function s11(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s12);
    }

    return State(false, s0);
  }

  function s12(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s13);
    }

    return State(false, s0);
  }

  function s13(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s14);
    }

    return State(false, s0);
  }

  function s14(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s15);
    }

    return State(false, s0);
  }

  function s15(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s16);
    }

    return State(false, s0);
  }

  function s16(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s17);
    }

    return State(false, s0);
  }

  function s17(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s18);
    }

    return State(false, s0);
  }

  function s18(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s19);
    }

    return State(false, s0);
  }

  function s19(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s20);
    }

    return State(false, s0);
  }

  function s20(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s21);
    }

    return State(false, s0);
  }

  function s21(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s22);
    }

    return State(false, s0);
  }

  function s22(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s23);
    }

    return State(false, s0);
  }

  function s23(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s24);
    }

    return State(false, s0);
  }

  function s24(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s25);
    }

    return State(false, s0);
  }

  function s25(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s26);
    }

    return State(false, s0);
  }

  function s26(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s27);
    }

    return State(false, s0);
  }

  function s27(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s28);
    }

    return State(false, s0);
  }

  function s28(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s29);
    }

    return State(false, s0);
  }

  function s29(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s30);
    }

    return State(false, s0);
  }

  function s30(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s31);
    }

    return State(false, s0);
  }

  function s31(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s32);
    }

    return State(false, s0);
  }

  function s32(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s33);
    }

    return State(false, s0);
  }

  function s33(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s34);
    }

    return State(false, s0);
  }

  function s34(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s35);
    }

    return State(false, s0);
  }

  function s35(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s36);
    }

    return State(false, s0);
  }

  function s36(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s37);
    }

    return State(false, s0);
  }

  function s37(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s38);
    }

    return State(false, s0);
  }

  function s38(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s39);
    }

    return State(false, s0);
  }

  function s39(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s40);
    }

    return State(false, s0);
  }

  function s40(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s41);
    }

    return State(false, s0);
  }

  function s41(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(false, s42);
    }

    return State(false, s0);
  }

  function s42(byte c) constant internal returns (State memory) {
    if (c >= 48 && c <= 57 || c >= 65 && c <= 70 || c >= 97 && c <= 102) {
      return State(true, s43);
    }

    return State(false, s0);
  }

  function s43(byte c) constant internal returns (State memory) {
    // silence unused var warning
    c = c;

    return State(false, s0);
  }

  function matches(string input) constant returns (bool) {
    var cur = State(false, s1);

    for (uint i = 0; i < bytes(input).length; i++) {
      var c = bytes(input)[i];

      cur = cur.func(c);
    }

    return cur.accepts;
  }
}