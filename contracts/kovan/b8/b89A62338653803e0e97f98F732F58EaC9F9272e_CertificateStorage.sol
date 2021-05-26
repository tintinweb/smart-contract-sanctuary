/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity 0.6.1;
pragma experimental ABIEncoderV2;

/*

- certificate hash should be unsigned certificate hash
  and there should be a way add signer to that certificate

// - 

*/

contract CertificateStorage {
  struct Certificate {
    bytes32 name;
    bytes32 qualification;
    bytes32 extraData;
    bytes signers;
  }

  struct CertifyingAuthority {
    bytes32 name;
    bool isAuthorised;
  }

  mapping(bytes32 => Certificate) public certificates;
  mapping(address => CertifyingAuthority) public certifyingAuthorities;

  address public manager;
  bytes constant public PERSONAL_PREFIX = "\x19Ethereum Signed Message:\n96";
  uint256 constant CERTIFICATE_DETAILS_LENGTH = 96;
  uint256 constant SIGNATURE_LENGTH = 65;

  event Certified(
    bytes32 indexed _certificateHash,
    address indexed _certifyingAuthority
  );

  event Authorization(
    address indexed _certifyingAuthority,
    bool _newStatus
  );

  modifier onlyManager() {
    require(msg.sender == manager, 'only manager can call');
    _;
  }

  constructor() public {
    manager = msg.sender;
  }

  function addCertifyingAuthority(address _authorityAddress, bytes32 _name) public onlyManager {
    certifyingAuthorities[_authorityAddress] = CertifyingAuthority({
      name: _name,
      isAuthorised: true
    });
    emit Authorization(_authorityAddress, true);
  }

  function newManager(address _newManagerAddress) public onlyManager {
    manager = _newManagerAddress;
  }

  function updateCertifyingAuthorityAuthorization(
    address _authorityAddress,
    bool _newStatus
  ) public onlyManager {
    certifyingAuthorities[_authorityAddress].isAuthorised = _newStatus;
  }

  function updateCertifyingAuthority(
    bytes32 _name
  ) public {
    require(
      certifyingAuthorities[msg.sender].isAuthorised
      , 'not authorised'
    );
    certifyingAuthorities[msg.sender].name = _name;
  }

  function registerCertificate(bytes memory _signedCertificate) public {
    require(
      _signedCertificate.length > CERTIFICATE_DETAILS_LENGTH
      && (_signedCertificate.length - CERTIFICATE_DETAILS_LENGTH) % SIGNATURE_LENGTH == 0
      , 'invalid certificate length'
    );

    Certificate memory _certificateObj = parseSignedCertificate(_signedCertificate, true);

    bytes32 _certificateHash = keccak256(abi.encodePacked(_signedCertificate));

    require(
      certificates[_certificateHash].signers.length == 0
      , 'certificate registered already'
    );

    bytes memory _signers = _certificateObj.signers;

    for(uint256 _i = 0; _i < _signers.length; _i += 20) {
      address _signer;
      assembly {
        _signer := mload(add(_signers, add(0x14, _i)))
      }
      emit Certified(
        _certificateHash,
        _signer
      );
    }

    certificates[_certificateHash] = _certificateObj;
  }

  function parseSignedCertificate(
    bytes memory _signedCertificate,
    bool _allowedSignersOnly
  ) public view returns (Certificate memory _certificateObj) {
    bytes32 _name;
    bytes32 _qualification;
    bytes32 _extraData;
    bytes memory _signers;

    assembly {
      let _pointer := add(_signedCertificate, 0x20)
      _name := mload(_pointer)
      _qualification := mload(add(_pointer, 0x20))
      _extraData := mload(add(_pointer, 0x40))
    }

    bytes32 _messageDigest = keccak256(abi.encodePacked(
      PERSONAL_PREFIX,
      _name,
      _qualification,
      _extraData
    ));

    for(uint256 _i = CERTIFICATE_DETAILS_LENGTH; _i < _signedCertificate.length; _i += SIGNATURE_LENGTH) {
      bytes32 _r;
      bytes32 _s;
      uint8 _v;

      assembly {
        let _pointer := add(_signedCertificate, add(0x20, _i))
        _r := mload(_pointer)
        _s := mload(add(_pointer, 0x20))
        _v := byte(0, mload(add(_pointer, 0x40)))
        if lt(_v, 27) { _v := add(_v, 27) }
      }

      require(_v == 27 || _v == 28, 'invalid recovery value');

      address _signer = ecrecover(_messageDigest, _v, _r, _s);

      require(checkUniqueSigner(_signer, _signers), 'each signer should be unique');

      if(_allowedSignersOnly) {
        require(certifyingAuthorities[_signer].isAuthorised, 'certifier not authorised');
      }

      _signers = abi.encodePacked(_signers, _signer);
    }

    _certificateObj.name = _name;
    _certificateObj.qualification = _qualification;
    _certificateObj.extraData = _extraData;
    _certificateObj.signers = _signers;
  }

  function checkUniqueSigner(address _signer, bytes memory _packedSigners) private pure returns (bool){
    require(_packedSigners.length % 20 == 0, 'invalid packed signers length');

    address _tempSigner;
    for(uint256 _i = 0; _i < _packedSigners.length; _i += 20) {
      assembly {
        _tempSigner := mload(add(_packedSigners, add(0x14, _i)))
      }
      if(_tempSigner == _signer) return false;
    }

    return true;
  }
}