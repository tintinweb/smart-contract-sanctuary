pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Certificate is Ownable {

  event LogAddCertificateAuthority(address indexed ca_address);
  event LogRemoveCertificateAuthority(address indexed ca_address);
  event LogAddCertificate(address indexed ca_address, bytes32 certificate_hash);
  event LogRevokeCertificate(address indexed ca_address, bytes32 certificate_hash);
  event LogBindCertificate2Wallet(address indexed ca_address, bytes32 certificate_hash, address indexed wallet);

  struct CertificateAuthority {
    string lookup_api;
    string organization;
    string common_name;
    string country;
    string province;
    string locality;
  }

  struct CertificateMeta {
    address ca_address;
    uint256 expires;
    bytes32 sealed_hash;
    bytes32 certificate_hash;
  }

  // Mapping of certificate authority address to the certificate authority
  mapping(address => CertificateAuthority) private certificate_authority;

  // Mapping of Ethereum wallet address to mapping of certificate authority address to wallet certificate hash
  mapping(address => mapping(address => bytes32)) private wallet_authority_certificate;

  // Mapping of wallet certificate hash to wallet certificate meta data
  mapping(bytes32 => CertificateMeta) private certificates;

  modifier onlyCA() {
    require(bytes(certificate_authority[msg.sender].lookup_api).length != 0);
    _;
  }

  /// @dev Adds a new approved certificate authority
  /// @param ca_address Address of certificate authority to add
  /// @param lookup_api certificate lookup API for the given authority
  /// @param organization Name of the organization this certificate authority represents
  /// @param common_name Common name of this certificate authority
  /// @param country Certificate authority jurisdiction country
  /// @param province Certificate authority jurisdiction state/province
  /// @param locality Certificate authority jurisdiction locality
  function addCA(
    address ca_address,
    string lookup_api,
    string organization,
    string common_name,
    string country,
    string province,
    string locality
  ) public onlyOwner {
    require (ca_address != 0x0);
    require (ca_address != msg.sender);
    require (bytes(lookup_api).length != 0);
    require (bytes(organization).length > 3);
    require (bytes(common_name).length > 3);
    require (bytes(country).length > 1);

    certificate_authority[ca_address] = CertificateAuthority(
      lookup_api,
      organization,
      common_name,
      country,
      province,
      locality
    );
    LogAddCertificateAuthority(ca_address);
  }

  /// @dev Removes an existing certificate authority, preventing it from issuing new certificates
  /// @param ca_address Address of certificate authority to remove
  function removeCA(address ca_address) public onlyOwner {
    delete certificate_authority[ca_address];
    LogRemoveCertificateAuthority(ca_address);
  }

  /// @dev Checks whether an address represents a certificate authority
  /// @param ca_address Address to check
  /// @return true if the address is a valid certificate authority; false otherwise
  function isCA(address ca_address) public view returns (bool) {
    return bytes(certificate_authority[ca_address].lookup_api).length != 0;
  }

  /// @dev Returns the certificate lookup API for the certificate authority
  /// @param ca_address Address of certificate authority
  /// @return lookup api, organization name, common name, country, state/province, and locality of the certificate authority
  function getCA(address ca_address) public view returns (string, string, string, string, string, string) {
    CertificateAuthority storage ca = certificate_authority[ca_address];
    return (ca.lookup_api, ca.organization, ca.common_name, ca.country, ca.province, ca.locality);
  }

  /// @dev Adds a new certificate by the calling certificate authority
  /// @param expires seconds from epoch until certificate expires
  /// @param sealed_hash hash of sealed portion of the certificate
  /// @param certificate_hash hash of public portion of the certificate
  function addNewCertificate(uint256 expires, bytes32 sealed_hash, bytes32 certificate_hash) public onlyCA {
    require(expires > now);

    CertificateMeta storage cert = certificates[certificate_hash];
    require(cert.expires == 0);

    certificates[certificate_hash] = CertificateMeta(msg.sender, expires, sealed_hash, certificate_hash);
    LogAddCertificate(msg.sender, certificate_hash);
  }

  /// @dev Adds a new certificate by the calling certificate authority and binds to given wallet
  /// @param wallet Wallet to which the certificate is being bound to
  /// @param expires seconds from epoch until certificate expires
  /// @param sealed_hash hash of sealed portion of the certificate
  /// @param certificate_hash hash of public portion of the certificate
  function addCertificateAndBind2Wallet(address wallet, uint256 expires, bytes32 sealed_hash, bytes32 certificate_hash) public onlyCA {
    require(expires > now);

    CertificateMeta storage cert = certificates[certificate_hash];
    require(cert.expires == 0);

    certificates[certificate_hash] = CertificateMeta(msg.sender, expires, sealed_hash, certificate_hash);
    LogAddCertificate(msg.sender, certificate_hash);
    wallet_authority_certificate[wallet][msg.sender] = certificate_hash;
    LogBindCertificate2Wallet(msg.sender, certificate_hash, wallet);
  }

  /// @dev Bind an existing certificate to a wallet - can be called by certificate authority that issued the certificate or a wallet already bound to the certificate
  /// @param wallet Wallet to which the certificate is being bound to
  /// @param certificate_hash hash of public portion of the certificate
  function bindCertificate2Wallet(address wallet, bytes32 certificate_hash) public {
    CertificateMeta storage cert = certificates[certificate_hash];
    require(cert.expires > now);

    bytes32 sender_certificate_hash = wallet_authority_certificate[msg.sender][cert.ca_address];

    require(cert.ca_address == msg.sender || cert.certificate_hash == sender_certificate_hash);

    wallet_authority_certificate[wallet][cert.ca_address] = certificate_hash;
    LogBindCertificate2Wallet(msg.sender, certificate_hash, wallet);
  }

  /// @dev Revokes an existing certificate - can be called by certificate authority that issued the certificate
  /// @param certificate_hash hash of public portion of the certificate
  function revokeCertificate(bytes32 certificate_hash) public onlyCA {
    CertificateMeta storage cert = certificates[certificate_hash];
    require(cert.ca_address == msg.sender);
    cert.expires = 0;
    LogRevokeCertificate(msg.sender, certificate_hash);
  }

  /// @dev returns certificate metadata given the certificate hash
  /// @param certificate_hash hash of public portion of the certificate
  /// @return certificate authority address, certificate expiration time, hash of sealed portion of the certificate, hash of public portion of the certificate
  function getCertificate(bytes32 certificate_hash) public view returns (address, uint256, bytes32, bytes32) {
    CertificateMeta storage cert = certificates[certificate_hash];
    if (isCA(cert.ca_address)) {
      return (cert.ca_address, cert.expires, cert.sealed_hash, cert.certificate_hash);
    } else {
      return (0x0, 0, 0x0, 0x0);
    }
  }

  /// @dev returns certificate metadata for a given wallet from a particular certificate authority
  /// @param wallet Wallet for which the certificate is being looked up
  /// @param ca_address Address of certificate authority
  /// @return certificate expiration time, hash of sealed portion of the certificate, hash of public portion of the certificate
  function getCertificateForWallet(address wallet, address ca_address) public view returns (uint256, bytes32, bytes32) {
    bytes32 certificate_hash = wallet_authority_certificate[wallet][ca_address];
    CertificateMeta storage cert = certificates[certificate_hash];
    if (isCA(cert.ca_address)) {
      return (cert.expires, cert.sealed_hash, cert.certificate_hash);
    } else {
      return (0, 0x0, 0x0);
    }
  }
}