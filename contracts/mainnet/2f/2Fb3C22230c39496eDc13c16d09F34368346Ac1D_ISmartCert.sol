pragma solidity ^0.4.17;

contract ISmartCert {
	// state variables
	mapping (bytes32 => SignedData) hashes;
	mapping (address => AccessStruct) accessList;
	mapping (bytes32 => RevokeStruct) revoked;
	mapping (bytes32 => Lvl2Struct[]) idMap;
	address owner;

	// constants
	string constant CODE_ACCESS_DENIED = "A001";
	string constant CODE_ACCESS_POSTER_NOT_AUTHORIZED = "A002";
	string constant CODE_ACCESS_ISSUER_NOT_AUTHORIZED = "A003";
	string constant CODE_ACCESS_VERIFY_NOT_AUTHORIZED = "A004";
	string constant MSG_ISSUER_SIG_NOT_MATCHED = "E001"; //"Issuer&#39;s address not matched with signed hash";
	string constant MSG_DOC_REGISTERED = "E002"; //"Document already registered"; 
	string constant MSG_REVOKED = "E003"; //"Document already revoked"; 	
	string constant MSG_NOTREG = "E004"; //"Document not registered";
	string constant MSG_INVALID = "E005";  //"Document not valid"; 
	string constant MSG_NOFOUND = "E006"; //"No record found";
	string constant MSG_INVALID_CERT_MERKLE_NOT_MATCHED = "E007";
	string constant MSG_INVALID_ACCESS_RIGHT = "E008";
	string constant MSG_BATCH_REVOKED = "E009"; //"Batch that the document belong to has already been revoked";
	string constant MSG_MERKLE_CANNOT_EMPTY = "E010";
	string constant MSG_MERKLE_NOT_REGISTERED = "E011";
	string constant STATUS_PASS = "PASS";
	string constant STATUS_FAIL = "FAIL";
	bytes1 constant ACCESS_ISSUER = 0x04;
	bytes1 constant ACCESS_POSTER = 0x02;
	bytes1 constant ACCESS_VERIFIER = 0x01;
	bytes1 constant ACCESS_ALL = 0x07;
	bytes1 constant ACCESS_ISSUER_POSTER = 0x05;
	bytes1 constant ACCESS_NONE = 0x00;

	struct SignedData {
		// string data;
		bytes sig;
		uint registerDate;
		bool exists; // empty entry to this struct initially set to false
	}

	struct RecordStruct {
		bytes32 recordId; // ref id to hashstore
		bool exists; // empty entry to this struct initially set to false
	}

	struct Lvl2Struct {
		bytes32 recordId;
		bytes32 certhash;
		bool exists;
	}

	struct RevokeStruct {
		bool exists;
		bytes32 merkleHash;
		bool batchFlag;
		uint date;
	}

	struct AccessStruct {
		bytes1 accessRight;
		uint date;
		bool isValue;
	}

	function ISmartCert() public {
		owner = msg.sender;
	}

	event LogUserRight(string, string);
	function userRight(address userAddr, bytes1 accessRight, uint date) public {
		if (owner != msg.sender) {
			LogUserRight(STATUS_FAIL, CODE_ACCESS_DENIED);
			return;
		}
		if (accessRight != ACCESS_ISSUER && accessRight != ACCESS_POSTER && accessRight != ACCESS_VERIFIER && accessRight != ACCESS_ALL && accessRight != ACCESS_ISSUER_POSTER && accessRight != ACCESS_NONE) {
			LogUserRight(STATUS_FAIL, MSG_INVALID_ACCESS_RIGHT);
			return;
		}
		accessList[userAddr].accessRight = accessRight;
		accessList[userAddr].date = date;
		accessList[userAddr].isValue = true;
		LogUserRight(STATUS_PASS, "");
	}

	function checkAccess(address user, bytes1 access) internal view returns (bool) {
		if (accessList[user].isValue) {
			if (accessList[user].accessRight & access == access) {
				return true;
			}
		}
		return false;
	}

	function internalRegisterCert(bytes32 certHash, bytes sig, uint registrationDate) internal returns (string, string) {
		address issuer;

		if (!checkAccess(msg.sender, ACCESS_POSTER)) {
			return (STATUS_FAIL, CODE_ACCESS_POSTER_NOT_AUTHORIZED);
		}
		
		issuer =  recoverAddr(certHash, sig);
		if (!checkAccess(issuer, ACCESS_ISSUER)) {
			return (STATUS_FAIL, CODE_ACCESS_ISSUER_NOT_AUTHORIZED);
		}

		if (hashes[certHash].exists) {
			// check if doc has already been revoked
			if (revoked[certHash].exists) {
				return (STATUS_FAIL, MSG_REVOKED);
			} else {
				return (STATUS_FAIL, MSG_DOC_REGISTERED);
			}		
		}	

		// signed data (in r, s, v)
		hashes[certHash].sig = sig;
		// certificate registration date (YYYYmmdd)
		hashes[certHash].registerDate = registrationDate;
		// indicate the record exists
		hashes[certHash].exists = true;
		return (STATUS_PASS, "");
	}

	function internalRegisterCertWithID(bytes32 certHash, bytes sig, bytes32 merkleHash, uint registrationDate, bytes32 id) internal returns (string, string) {
		string memory status;
		string memory message;

		// check if any record associated with id
		for (uint i = 0; i < idMap[id].length; i++) {
			if (idMap[id][i].exists == true && idMap[id][i].certhash == certHash) {
				return (STATUS_FAIL, MSG_DOC_REGISTERED);
			}
		}

		// check if merkle root has already been revoked
		if (merkleHash != 0x00) {
			if (revoked[merkleHash].exists && revoked[merkleHash].batchFlag) {
				return (STATUS_FAIL, MSG_BATCH_REVOKED);
			}		
		}

		// check if merkle root is empty
		if (merkleHash == 0x00) {
			return (STATUS_FAIL, MSG_MERKLE_CANNOT_EMPTY);
		}

		// check if merkle is exists
		if (!hashes[merkleHash].exists) {
			return (STATUS_FAIL, MSG_MERKLE_NOT_REGISTERED);
		}	

		// register certificate
		(status, message) = internalRegisterCert(certHash, sig, registrationDate);
		if (keccak256(status) != keccak256(STATUS_PASS)) {
			return (status, message);		
		}

		// store record id by ID
		idMap[id].push(Lvl2Struct({recordId:merkleHash, certhash:certHash, exists:true}));

		return (STATUS_PASS, "");
	}

	function internalRevokeCert(bytes32 certHash, bytes sigCertHash, bytes32 merkleHash, bool batchFlag, uint revocationDate) internal returns (string, string) {
		address issuer1;
		address issuer2;
		// check poster access right
		if (!checkAccess(msg.sender, ACCESS_POSTER)) {
			return (STATUS_FAIL, CODE_ACCESS_POSTER_NOT_AUTHORIZED);
		}
		// check issuer access right
		issuer1 = recoverAddr(certHash, sigCertHash);
		if (!checkAccess(issuer1, ACCESS_ISSUER)) {
			return (STATUS_FAIL, CODE_ACCESS_ISSUER_NOT_AUTHORIZED);
		}
		// if batch, ensure both certHash and merkleHash are same
		if (batchFlag) {
			if (certHash != merkleHash) {
				return (STATUS_FAIL, MSG_INVALID_CERT_MERKLE_NOT_MATCHED);
			}
			if (merkleHash == 0x00) {
				return (STATUS_FAIL, MSG_MERKLE_CANNOT_EMPTY);
			}
		}
		if (merkleHash != 0x00) {
			// check if doc (merkle root) is registered
			if (hashes[merkleHash].exists == false) {
				return (STATUS_FAIL, MSG_NOTREG);
			}
			// check if requested signature and stored signature is same by comparing two issuer addresses
			issuer2 = recoverAddr(merkleHash, hashes[merkleHash].sig);
			if (issuer1 != issuer2) {
				return (STATUS_FAIL, MSG_ISSUER_SIG_NOT_MATCHED);
			}
		}				
		// check if doc has already been revoked
		if (revoked[certHash].exists) {
			return (STATUS_FAIL, MSG_REVOKED);
		}
		// store / update
		if (batchFlag) {
			revoked[certHash].batchFlag = true;
		} else {			
			revoked[certHash].batchFlag = false;
		}
		revoked[certHash].exists = true;
		revoked[certHash].merkleHash = merkleHash;
		revoked[certHash].date = revocationDate;

		return (STATUS_PASS, "");
	}

	// event as a form of return value, state mutating function cannot return value to external party
	event LogRegisterCert(string, string);
	function registerCert(bytes32 certHash, bytes sig, uint registrationDate) public {		
		string memory status;
		string memory message;

		(status, message) = internalRegisterCert(certHash, sig, registrationDate);		
		LogRegisterCert(status, message);
	}

	event LogRegisterCertWithID(string, string);
	function registerCertWithID(bytes32 certHash, bytes sig, bytes32 merkleHash, uint registrationDate, bytes32 id) public {
		string memory status;
		string memory message;

		// register certificate
		(status, message) = internalRegisterCertWithID(certHash, sig, merkleHash, registrationDate, id);
		LogRegisterCertWithID(status, message);
	}

	// for verification 
	function internalVerifyCert(bytes32 certHash, bytes32 merkleHash, address issuer) internal view returns (string, string) {
		bytes32 tmpCertHash;

		// check if doc has already been revoked
		if (revoked[certHash].exists && !revoked[certHash].batchFlag) {
			return (STATUS_FAIL, MSG_REVOKED);
		}
		if (merkleHash != 0x00) {
			// check if merkle root has already been revoked
			if (revoked[merkleHash].exists && revoked[merkleHash].batchFlag) {
				return (STATUS_FAIL, MSG_REVOKED);
			}
			tmpCertHash = merkleHash;
		} else {
			tmpCertHash = certHash;
		}		
		// check if doc in hash store
		if (hashes[tmpCertHash].exists) {
			if (recoverAddr(tmpCertHash, hashes[tmpCertHash].sig) != issuer) {			
				return (STATUS_FAIL, MSG_INVALID);
			}
			return (STATUS_PASS, "");
		} else {
			return (STATUS_FAIL, MSG_NOTREG);
		}
	}

	function verifyCert(bytes32 certHash, bytes32 merkleHash, address issuer) public view returns (string, string) {
		string memory status;
		string memory message;
		bool isAuthorized;

		// check verify access
		isAuthorized = checkVerifyAccess();
		if (!isAuthorized) {
			return (STATUS_FAIL, CODE_ACCESS_VERIFY_NOT_AUTHORIZED);
		}

		(status, message) = internalVerifyCert(certHash, merkleHash, issuer);
		return (status, message);
	}

	function verifyCertWithID(bytes32 certHash, bytes32 merkleHash, bytes32 id, address issuer) public view returns (string, string) {
		string memory status;
		string memory message;
		bool isAuthorized;

		// check verify access
		isAuthorized = checkVerifyAccess();
		if (!isAuthorized) {
			return (STATUS_FAIL, CODE_ACCESS_VERIFY_NOT_AUTHORIZED);
		}

		// check if any record associated with id
		for (uint i = 0; i < idMap[id].length; i++) {
			if (idMap[id][i].exists == true && idMap[id][i].certhash == certHash) {
				(status, message) = internalVerifyCert(certHash, merkleHash, issuer);
				return (status, message);
			}
		}
		// no record found
		return (STATUS_FAIL, MSG_NOFOUND);
	}

	function checkVerifyAccess() internal view returns (bool) {
		// check if sender is authorized for cert verification
		return checkAccess(msg.sender, ACCESS_VERIFIER);
	}

	// event as a form of return value, state mutating function cannot return value to external party
	event LogRevokeCert(string, string);
	function revokeCert(bytes32 certHash, bytes sigCertHash, bytes32 merkleHash, bool batchFlag, uint revocationDate) public {
		string memory status;
		string memory message;

		(status, message) = internalRevokeCert(certHash, sigCertHash, merkleHash, batchFlag, revocationDate);
		LogRevokeCert(status, message);
	}

	// event LogReissueCert(string, bytes32, string);
	event LogReissueCert(string, string);
	function reissueCert(bytes32 revokeCertHash, bytes revokeSigCertHash, bytes32 revokeMerkleHash, uint revocationDate, bytes32 registerCertHash, bytes registerSig, uint registrationDate) public {
		string memory status;
		string memory message;

		// revoke certificate
		(status, message) = internalRevokeCert(revokeCertHash, revokeSigCertHash, revokeMerkleHash, false, revocationDate);
		if (keccak256(status) != keccak256(STATUS_PASS)) {
			LogReissueCert(status, message);
			return;
		}

		// register certificate
		(status, message) = internalRegisterCert(registerCertHash, registerSig, registrationDate);
		LogReissueCert(status, message);
		if (keccak256(status) != keccak256(STATUS_PASS)) {
			revert();			
		}

		LogReissueCert(STATUS_PASS, "");
	}

	event LogReissueCertWithID(string, string);
	function reissueCertWithID(bytes32 revokeCertHash, bytes revokeSigCertHash, bytes32 revokeMerkleHash, uint revocationDate, bytes32 registerCertHash, bytes registerSig, bytes32 registerMerkleHash, uint registrationDate, bytes32 id) public {
		string memory status;
		string memory message;

		// revoke certificate
		(status, message) = internalRevokeCert(revokeCertHash, revokeSigCertHash, revokeMerkleHash, false, revocationDate);
		if (keccak256(status) != keccak256(STATUS_PASS)) {
			LogReissueCertWithID(status, message);
			return;
		}

		// register certificate
		(status, message) = internalRegisterCertWithID(registerCertHash, registerSig, registerMerkleHash, registrationDate, id);
		LogReissueCertWithID(status, message);
		if (keccak256(status) != keccak256(STATUS_PASS)) {
			revert();
		}

		LogReissueCertWithID(STATUS_PASS, "");
	}

	function recoverAddr(bytes32 hash, bytes sig) internal pure returns (address) {
		bytes32 r;
		bytes32 s;
		uint8 v;

		//Check the signature length
		if (sig.length != 65) {
			return (address(0));
		}
		
		// Divide the signature in r, s and v variables
        assembly {
          r := mload(add(sig, 33))
          s := mload(add(sig, 65))
          v := mload(add(sig, 1))
        }
        
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
          v += 27;
        }

		// If the version is correct return the signer address
		if (v != 27 && v != 28) {
			return (address(1));
		} else {
			return ecrecover(hash, v, r, s);
		}
	}
}