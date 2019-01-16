pragma solidity >=0.4.24 <0.6.0;

contract inputdata{
    uint blocknumber;
    bytes32 TxHash;
    address currentaddress;
    uint waktu;
    string nama;
    string alamat;
    
    function setdata(string memory _nama, string memory _alamat) public {
        blocknumber = block.number;
        TxHash = blockhash (blocknumber);
        currentaddress = block.coinbase;
        waktu = block.timestamp;
        nama = _nama;
        alamat = _alamat;
    }
    
    function getdata() public view returns(uint, bytes32, address, uint, string memory, string memory) {
        return (blocknumber, TxHash, currentaddress, waktu,  nama, alamat);
    }
}