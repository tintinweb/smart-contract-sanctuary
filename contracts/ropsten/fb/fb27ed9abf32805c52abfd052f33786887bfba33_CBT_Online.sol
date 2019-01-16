pragma solidity >=0.4.24 <0.6.0;

contract CBT_Online {
    uint id_soal;
    string soal;
    string pilihan_a;
    string pilihan_b;
    string pilihan_c;
    string pilihan_d;
    string pilihan_e;
    string jawaban;
    
    function setSoal(uint _id_soal, string memory _soal, string memory _pilihan_A, string memory _pilihan_B, string memory _pilihan_C, string memory _pilihan_D, string memory _pilihan_E) public {
        id_soal = _id_soal;
        soal = _soal;
        pilihan_a = _pilihan_A;
        pilihan_b = _pilihan_B;
        pilihan_c = _pilihan_C;
        pilihan_d = _pilihan_D;
        pilihan_e = _pilihan_E;
    
    }
    function getSoal() public view returns(uint, string memory, string memory, string memory, string memory, string memory, string memory) {
        return (id_soal, soal, pilihan_a, pilihan_b, pilihan_c, pilihan_d, pilihan_e);
    }
}