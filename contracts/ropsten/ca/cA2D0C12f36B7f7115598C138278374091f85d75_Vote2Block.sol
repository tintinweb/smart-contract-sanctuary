/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier:MIT
pragma solidity 0.7.0;

contract Vote2Block {
    // deklarasi address dari admin vote2block
    address adminAddress;

    event RegisterKandidat(
        uint256 _kandidatID,
        uint256 _totalVote,
        bytes32 _kandidatName,
        address _ownerAddress
    );
    event RegisterPemilih(
        address _pemilihAddress,
        uint256 _statusHakPilih,
        bool statusVoting,
        address _ownerAddress
    );
    event VotingTime(
        uint256 _registerstart,
        uint256 _registerfinis,
        uint256 _votingstart,
        uint256 _votingfinis,
        address _ownerAddress
    );
    event Voted(
        address voterAddress,
        uint256 kandidatID,
        bool statusVoting
    );

    struct VotingTimeData {
        uint256 registerstart;
        uint256 registerfinis;
        uint256 votingstart;
        uint256 votingfinis;
    }
    VotingTimeData votingtimedata;
    struct KandidatData {
        uint256 kandidatID;
        uint256 totalVote;
        bytes32 kandidatName;
    }
    struct PemilihData {
        uint256 hakPilih;
        uint256 kandidatPilihan;
        bool votingStatus;
    }

    // create array dari KandidatData
    KandidatData[] public kandidat;
    // mapping address pemilih ke PemilihData
    mapping(address => PemilihData) public pemilihData;

    // modifier pada smart-contract
    modifier onlyRegisterStart(uint256 livetime) {
        require(livetime > votingtimedata.registerstart && livetime < votingtimedata.registerfinis, "Waktu pendaftaran belum dibuka");
        _;
    }
    modifier onlyRegisterFinis(uint256 livetime) {
        require(livetime > votingtimedata.registerstart && livetime > votingtimedata.registerfinis,"Waktu pendaftaran telah ditutup");
        _;
    }
    modifier onlyVotingStart(uint256 livetime) {
        require(livetime > votingtimedata.votingstart && livetime < votingtimedata.votingfinis,"Waktu Voting belum dibuka");
        _;
    }
    modifier onlyVotingFinis(uint256 livetime) {
        require(livetime > votingtimedata.votingfinis,"Waktu Voting telah didutup");
        _;
    }

    constructor(address _adminAddress) {
        adminAddress = _adminAddress;
    }

    function SetupTimedata(
        uint256 _registerstart,
        uint256 _registerfinis,
        uint256 _votingstart,
        uint256 _votingfinis,
        uint256 nonce,
        bytes memory signature
    ) public {
        bytes32 message =
            prefixed(
                keccak256(
                    abi.encodePacked(
                        _registerstart,
                        _registerfinis,
                        _votingstart,
                        _votingfinis,
                        nonce
                    )
                )
            );
        address _ownerAddress = recoverSigner(message, signature);
        require(_ownerAddress == adminAddress,"Non Admin Address");
        votingtimedata = VotingTimeData(
            _registerstart,
            _registerfinis,
            _votingstart,
            _votingfinis
        );
        emit VotingTime(
            _registerstart,
            _registerfinis,
            _votingstart,
            _votingfinis,
            _ownerAddress
        );
    }

    function KandidatRegister(
        uint256 _kandidatID,
        uint256 nonce,
        uint256 _livetime,
        bytes32 _kandidatName,
        bytes memory signature
    ) public onlyRegisterStart(_livetime) {
        bytes32 message =
            prefixed(
                keccak256(abi.encodePacked(_kandidatID, _kandidatName, nonce))
            );
        address _ownerAddress = recoverSigner(message, signature);
        require(_ownerAddress == adminAddress,"Non Admin Address");
        kandidat.push(
            KandidatData({
                kandidatID: _kandidatID,
                totalVote: 0,
                kandidatName: _kandidatName
            })
        );
        emit RegisterKandidat(_kandidatID, 0, _kandidatName, _ownerAddress);
    }

    function PemilihRegister(
        address _pemilihAddress,
        uint256 nonce,
        uint256 _livetime,
        bytes memory signature
    ) public onlyRegisterStart(_livetime) {
        bytes32 message =
            prefixed(keccak256(abi.encodePacked(_pemilihAddress, nonce)));
        address _ownerAddress = recoverSigner(message, signature);
        require(_ownerAddress == adminAddress,"Non Admin Address");
        require(
            pemilihData[_pemilihAddress].hakPilih == 0,
            "Pemilih telah memiliki hak pilih"
        );
        pemilihData[_pemilihAddress].hakPilih = 1;
        pemilihData[_pemilihAddress].votingStatus = false;
        emit RegisterPemilih(_pemilihAddress, 1, false, _ownerAddress);
    }

    function Voting(
        uint256 _kandidatID,
        uint256 nonce,
        uint256 _livetime,
        bytes memory signature
    ) public onlyRegisterFinis(_livetime) onlyVotingStart(_livetime) {
        bytes32 message =
            prefixed(keccak256(abi.encodePacked(_kandidatID, nonce)));
        address voterAddress = recoverSigner(message, signature);
        require(!pemilihData[voterAddress].votingStatus, "Pemilih sudah menggunakan hak pilih");
        require(pemilihData[voterAddress].hakPilih != 0, "Pemilih tidak memiliki hak pilih");
        pemilihData[voterAddress].votingStatus = true;
        pemilihData[voterAddress].kandidatPilihan = _kandidatID;
        uint256 kandidatIndex = _kandidatID - 1;
        kandidat[kandidatIndex].totalVote += pemilihData[voterAddress].hakPilih;
        emit Voted(voterAddress, _kandidatID, true);
    }

    function _HitungTotalSuara() internal view returns (uint256 totalSuara_) {
        uint256 totalSuaraKandidat = 0;
        for (uint256 p = 0; p < kandidat.length; p++) {
            if (kandidat[p].totalVote > totalSuaraKandidat) {
                totalSuaraKandidat = kandidat[p].totalVote;
                totalSuara_ = p;
            }
        }
    }

    function KandidatTerpilih(uint256 _livetime)
        public
        view
        onlyRegisterFinis(_livetime)
        onlyVotingFinis(_livetime)
        returns (uint256 kandidatID_)
    {
        kandidatID_ = kandidat[_HitungTotalSuara()].kandidatID;
    }

    function GetPemilihData(address _pemilihAddress)
        public
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (
            pemilihData[_pemilihAddress].hakPilih,
            pemilihData[_pemilihAddress].kandidatPilihan,
            pemilihData[_pemilihAddress].votingStatus
        );
    }

    function GetVotingTimeData()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            votingtimedata.registerstart,
            votingtimedata.registerfinis,
            votingtimedata.votingstart,
            votingtimedata.votingfinis
        );
    }

    function GetTotalKandidat() public view returns(uint256) {
        return kandidat.length;
    }

    function GetKandidatData(uint256 kandidatIndex) public view returns(uint256, uint256) {
        return (kandidat[kandidatIndex].kandidatID, kandidat[kandidatIndex].totalVote);
    }

    // Handle signature data
    function splitSignature(bytes memory signature)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(signature.length == 65);
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}