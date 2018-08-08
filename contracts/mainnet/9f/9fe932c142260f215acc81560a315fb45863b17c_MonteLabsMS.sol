pragma solidity ^0.4.24;

library DS {
  struct Proof {
    uint level;         // Audit level
    uint insertedBlock; // Audit&#39;s block
    bytes32 ipfsHash;   // IPFS dag-cbor proof
    address auditedBy;  // Audited by address
  }
}

contract Audit {
  event AttachedEvidence(address indexed auditorAddr, bytes32 indexed codeHash, bytes32 ipfsHash);
  event NewAudit(address indexed auditorAddr, bytes32 indexed codeHash);

  // Maps auditor address and code&#39;s keccak256 to Audit
  mapping (address => mapping (bytes32 => DS.Proof)) public auditedContracts;
  // Maps auditor address to a list of audit code hashes
  mapping (address => bytes32[]) public auditorContracts;
  
  // Returns code audit level, 0 if not present
  function isVerifiedAddress(address _auditorAddr, address _contractAddr) public view returns(uint) {
    bytes32 codeHash = keccak256(codeAt(_contractAddr));
    return auditedContracts[_auditorAddr][codeHash].level;
  }

  function isVerifiedCode(address _auditorAddr, bytes32 _codeHash) public view returns(uint) {
    return auditedContracts[_auditorAddr][_codeHash].level;
  }
  
  // Add audit information
  function addAudit(bytes32 _codeHash, uint _level, bytes32 _ipfsHash) public {
    address auditor = msg.sender;
    require(auditedContracts[auditor][_codeHash].insertedBlock == 0);
    auditedContracts[auditor][_codeHash] = DS.Proof({ 
        level: _level,
        auditedBy: auditor,
        insertedBlock: block.number,
        ipfsHash: _ipfsHash
    });
    auditorContracts[auditor].push(_codeHash);
    emit NewAudit(auditor, _codeHash);
  }
  
  // Add evidence to audited code, only author, if _newLevel is different from original
  // updates the contract&#39;s level
  function addEvidence(bytes32 _codeHash, uint _newLevel, bytes32 _ipfsHash) public {
    address auditor = msg.sender;
    require(auditedContracts[auditor][_codeHash].insertedBlock != 0);
    if (auditedContracts[auditor][_codeHash].level != _newLevel)
      auditedContracts[auditor][_codeHash].level = _newLevel;
    emit AttachedEvidence(auditor, _codeHash, _ipfsHash);
  }

  function codeAt(address _addr) public view returns (bytes code) {
    assembly {
      // retrieve the size of the code, this needs assembly
      let size := extcodesize(_addr)
      // allocate output byte array - this could also be done without assembly
      // by using o_code = new bytes(size)
      code := mload(0x40)
      // new "memory end" including padding
      mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      // store length in memory
      mstore(code, size)
      // actually retrieve the code, this needs assembly
      extcodecopy(_addr, add(code, 0x20), 0, size)
    }
  }
}

contract MonteLabsMS {
  // MonteLabs owners
  mapping (address => bool) public owners;
  uint8 constant quorum = 2;
  Audit public auditContract;

  constructor(address[] _owners, Audit _auditContract) public {
    auditContract = _auditContract;
    require(_owners.length == 3);
    for (uint i = 0; i < _owners.length; ++i) {
      owners[_owners[i]] = true;
    }
  }

  function addAuditOrEvidence(bool audit, bytes32 _codeHash, uint _level,
                              bytes32 _ipfsHash, uint8 _v, bytes32 _r, 
                              bytes32 _s) internal {
    address sender = msg.sender;
    require(owners[sender]);

    bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n32",
                           keccak256(audit, _codeHash, _level, _ipfsHash));

    address other = ecrecover(prefixedHash, _v, _r, _s);
    // At least 2 different owners
    assert(other != sender);
    if (audit)
      auditContract.addAudit(_codeHash, _level, _ipfsHash);
    else
      auditContract.addEvidence(_codeHash, _level, _ipfsHash);
  }

  function addAudit(bytes32 _codeHash, uint _level, bytes32 _ipfsHash,
                    uint8 _v, bytes32 _r, bytes32 _s) public {
    addAuditOrEvidence(true, _codeHash, _level, _ipfsHash, _v, _r, _s);
  }

  function addEvidence(bytes32 _codeHash, uint _version, bytes32 _ipfsHash,
                    uint8 _v, bytes32 _r, bytes32 _s) public {
    addAuditOrEvidence(false, _codeHash, _version, _ipfsHash, _v, _r, _s);
  }
}