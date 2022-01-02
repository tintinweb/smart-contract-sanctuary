// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

contract POCWoodtrack {
    enum WoodType {
        Acra,
        Aman,
        Epel
    }

    enum TranType {
        Darat,
        Sungai
    }

    enum DebarkType {
        Kupas,
        NonKupas
    }

    enum CertificateType {
        PEFCCertified,
        PEFCControlledSources,
        ControlledSources
    }

    struct Woodtrack {
        bytes32 SP;
        bytes32 SKSHHK;
        uint256 Volume; // m3
        bytes32 Petak;
        bytes32 AsalKayu;
        CertificateType Certificate;
        DebarkType Debark;
        TranType Tran;
        uint256 bulanTebang;
        uint256 tahunTebang;
        WoodType JenisKayu;
    }

    event WoodtrackRegistered(bytes32 indexed skshhk);

    mapping(bytes32 => Woodtrack) public woodtracks;
    mapping(address => bool) public Owners;
    address public Owner;

    modifier onlyOwner() {
        require(
            Owners[msg.sender] == true,
            "Only owner can call this function."
        );
        _;
    }

    constructor() {
        Owners[msg.sender] = true;
    }

    function AddOwner(address add) external onlyOwner {
        Owners[add] = true;
    }

    function Register(Woodtrack memory wt) external onlyOwner {
        woodtracks[wt.SKSHHK].SP = wt.SP;
        woodtracks[wt.SKSHHK].SKSHHK = wt.SKSHHK;
        woodtracks[wt.SKSHHK].Volume = wt.Volume;
        woodtracks[wt.SKSHHK].AsalKayu = wt.AsalKayu;
        woodtracks[wt.SKSHHK].Petak = wt.Petak;
        woodtracks[wt.SKSHHK].Certificate = wt.Certificate;
        woodtracks[wt.SKSHHK].Debark = wt.Debark;
        woodtracks[wt.SKSHHK].Tran = wt.Tran;
        woodtracks[wt.SKSHHK].bulanTebang = wt.bulanTebang;
        woodtracks[wt.SKSHHK].tahunTebang = wt.tahunTebang;

        woodtracks[wt.SKSHHK].JenisKayu = wt.JenisKayu;

        emit WoodtrackRegistered(wt.SKSHHK);
    }

    function searchSkshhk(bytes32 sKSHHK)
        public
        view
        returns (Woodtrack memory)
    {
        return (
            /// search ???

            woodtracks[sKSHHK]
        );
    }

    //function searchAdal(string memory AsalKayu)
}