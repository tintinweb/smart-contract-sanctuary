// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract VatLike {
    function hope(address usr) external;
    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external;
    function fork(bytes32 ilk, address src, address dst, int dink, int dart) external;
    function ilks(bytes32 ilk) public view returns(uint Art, uint rate, uint spot, uint line, uint dust);
    function urns(bytes32 ilk, address urn) public view returns(uint art, uint ink);
}

contract Hoper {
    constructor(VatLike vat) public {
        vat.hope(msg.sender);
        selfdestruct(address(0));
    }
}

contract Experiment {
    VatLike vat = VatLike(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    address admin;
    bytes32 constant ILK = bytes32(0x4554482d41000000000000000000000000000000000000000000000000000000);

    constructor() public {
        admin = msg.sender;
        vat.hope(msg.sender);
    }

    function liquidationPrice(uint ink, uint art) public view returns(uint) {
        (,uint rate,,,) = vat.ilks(ILK);
        uint daiDebt = rate * art / 1e27;
        return 1e18 * daiDebt * 15 / (ink * 10);
    }

    function openVault(uint ink, uint dart) public {
        require(msg.sender == admin);
        address me = address(this);
        vat.frob(ILK,me,me,me,int(ink),int(dart));
    }

    event NewAddress(address a);

    function splitVault(uint numVaults, uint vaultInk, uint vaultArt) public {
        require(msg.sender == admin);
        VatLike theVat = vat;
        address me = address(this);
        for(uint i = 0 ; i < numVaults ; i++) {
            address h = address(new Hoper(theVat));
            emit NewAddress(h);
            theVat.fork(ILK,me,h,int(vaultInk),int(vaultArt));
            //theVat.frob(ILK,h,me,me,int(vaultInk),int(vaultArt));
        }
    }

    function repay(address[] memory urns, uint ink, uint art) public {
        require(msg.sender == admin);
        VatLike theVat = vat;
        address me = address(this);
        for(uint i = 0 ; i < urns.length ; i++) {
            theVat.frob(ILK,urns[i],me,me,-int(ink),-int(art));
        }
    }

    event IsSafe(address urn, bool isSafe);
    function safe(address[] memory urns) public {
        (, uint rate, uint spot,,) = vat.ilks(ILK);
        for(uint i = 0 ; i < urns.length ; i++) {
            (uint art, uint ink) = vat.urns(ILK, urns[i]);
            uint tab = art * rate;
            bool isSafe = (tab <= ink * spot);
            emit IsSafe(urns[i], isSafe);
        }
    }
}