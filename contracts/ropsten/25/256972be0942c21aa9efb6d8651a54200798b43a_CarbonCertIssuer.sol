pragma solidity ^0.4.24;

contract CarbonCertIssuer{

  struct Certificate {
    string project;
    string memo;
    uint amount;
  }

  Certificate[] public Certificates;

  constructor() public { }

  function issueCertificate(string _project, string _memo, uint256 _amount) public returns(bool) {
    Certificate memory cert = Certificate(_project, _memo, _amount);
    Certificates.push(cert);
    // SendCert(cert)
    return true;
  }

  function getCertificate(uint256 _index) public view returns(uint256){
    if (Certificates.length ==0) { 
      return 0;
    } else {
      return Certificates[_index].amount;
    }
  }
}