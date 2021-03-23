/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract ArrayTest {
    
    uint[] uint_v;
    uint[3] uint_3;
    uint[3][] uint_3_v;
    uint[][4] uint_v_4;
    uint[3][4] uint_3_4;
    uint[3][][] uint_3_v_v;
    uint[3][4][] uint_3_4_v;
    uint[3][][5] uint_3_v_5;
    uint[3][4][][] uint_3_4_v_v;
    uint[3][][5][] uint_3_v_5_v;
    uint[3][][][] uint_3_v_v_v;
    uint[3][4][5][] uint_3_4_5_v;
    uint[3][][][6] uint_3_v_v_6;
    
    function setUintV(uint[] calldata u) public { uint_v = u;  }
    function getUintV() public view returns (uint[] memory u) { return uint_v; }
    function getUintV(uint[] memory v) public pure returns (uint[] memory u) { return v; }
    
    function setUint3(uint[3] calldata u) public { uint_3 = u;  }
    function getUint3() public view returns (uint[3] memory u) { return uint_3; }
    function getUint3(uint[3] memory v) public pure returns (uint[3] memory u) { return v; }
    
    function setUint3v(uint[3][] calldata u) public { uint_3_v = u;  }
    function getUint3v() public view returns (uint[3][] memory u) { return uint_3_v; }
    function getUint3v(uint[3][] memory v) public pure returns (uint[3][] memory u) { return v; }
    
    function setUintv4(uint[][4] memory u) public { uint_v_4 = u;  }
    function getUintv4() public view returns (uint[][4] memory u) { return uint_v_4; }
    function getUintv4(uint[][4] memory v) public pure returns (uint[][4] memory u) { return v; }
    
    function setUint34(uint[3][4] calldata u) public { uint_3_4 = u;  }
    function getUint34() public view returns (uint[3][4] memory u) { return uint_3_4; }
    function getUint34(uint[3][4] memory v) public pure returns (uint[3][4] memory u) { return v; }
    
    function setUint3vv(uint[3][][] memory u) public { uint_3_v_v = u;  }
    function getUint3vv() public view returns (uint[3][][] memory u) { return uint_3_v_v; }
    function getUint3vv(uint[3][][] memory v) public pure returns (uint[3][][] memory u) { return v; }
    
    function setUint34v(uint[3][4][] calldata u) public { uint_3_4_v = u;  }
    function getUint34v() public view returns (uint[3][4][] memory u) { return uint_3_4_v; }
    function getUint34v(uint[3][4][] memory v) public pure returns (uint[3][4][] memory u) { return v; }
    
    function setUint3v5(uint[3][][5] memory u) public { uint_3_v_5 = u;  }
    function getUint3v5() public view returns (uint[3][][5] memory u) { return uint_3_v_5; }
    function getUint3v5(uint[3][][5] memory v) public pure returns (uint[3][][5] memory u) { return v; }
    
    function setUint34vv(uint[3][4][][] memory u) public { uint_3_4_v_v = u;  }
    function getUint34vv() public view returns (uint[3][4][][] memory u) { return uint_3_4_v_v; }
    function getUint34vv(uint[3][4][][] memory v) public pure returns (uint[3][4][][] memory u) { return v; }
    
    function setUint3v5v(uint[3][][5][] memory u) public { uint_3_v_5_v = u;  }
    function getUint3v5v() public view returns (uint[3][][5][] memory u) { return uint_3_v_5_v; }
    function getUint3v5v(uint[3][][5][] memory v) public pure returns (uint[3][][5][] memory u) { return v; }
    
    function setUint3vvv(uint[3][][][] memory u) public { uint_3_v_v_v = u;  }
    function getUint3vvv() public view returns (uint[3][][][] memory u) { return uint_3_v_v_v; }
    function getUint3vvv(uint[3][][][] memory v) public pure returns (uint[3][][][] memory u) { return v; }
    
    function setUint345v(uint[3][4][5][] calldata u) public { uint_3_4_5_v = u;  }
    function getUint345v() public view returns (uint[3][4][5][] memory u) { return uint_3_4_5_v; }
    function getUint345v(uint[3][4][5][] memory v) public pure returns (uint[3][4][5][] memory u) { return v; }
    
    function setUint3vv6(uint[3][][][6] memory u) public { uint_3_v_v_6 = u;  }
    function getUint3vv6() public view returns (uint[3][][][6] memory u) { return uint_3_v_v_6; }
    function getUint3vv6(uint[3][][][6] memory v) public pure returns (uint[3][][][6] memory u) { return v; }

}