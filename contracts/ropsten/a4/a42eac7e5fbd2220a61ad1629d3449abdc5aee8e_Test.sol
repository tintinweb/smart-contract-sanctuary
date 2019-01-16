pragma solidity >=0.4.24 <0.6.0;

contract Test {
    string namalengkap;
    string alamat;
    uint umur;

    function setName(string memory newNama) public {
        namalengkap = newNama;
    }
    
    function getName() public view returns (string memory) {
        return namalengkap;
    
    }
    
    function setAlamat(string memory newalamat) public {
        alamat = newalamat;
    }
    
    function getAlamat() public view returns (string memory){
        return alamat;
    }
    
        function setAge(uint newUmur) public {
        umur = newUmur;
    }
    
    function getAge() public view returns (uint) {
        return umur;
    }
}