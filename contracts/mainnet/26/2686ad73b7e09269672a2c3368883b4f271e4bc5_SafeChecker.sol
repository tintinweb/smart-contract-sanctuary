// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract VatLike {
    function hope(address usr) external;
    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external;
    function fork(bytes32 ilk, address src, address dst, int dink, int dart) external;
    function ilks(bytes32 ilk) public view returns(uint Art, uint rate, uint spot, uint line, uint dust);
    function urns(bytes32 ilk, address urn) public view returns(uint art, uint ink);
}


contract SafeChecker {
    bytes32 constant ILK = bytes32(0x4554482d41000000000000000000000000000000000000000000000000000000);
    VatLike vat = VatLike(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    event IsSafe(address urn, bool isSafe, uint ink, uint art, uint time);
    function safe(address[] memory urns) public {
        (, uint rate, uint spot,,) = vat.ilks(ILK);
        for(uint i = 0 ; i < urns.length ; i++) {
            (uint ink, uint art) = vat.urns(ILK, urns[i]);
            uint tab = art * rate;
            bool isSafe = (tab <= (ink * spot));
            emit IsSafe(urns[i], isSafe, ink, art, now);
        }
    }
}