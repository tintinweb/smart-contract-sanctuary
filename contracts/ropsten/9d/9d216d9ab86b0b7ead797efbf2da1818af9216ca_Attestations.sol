pragma solidity ^0.4.25;

contract Attestations {
    struct Validation {
            address validator;
            uint addDate;
            uint removeDate;
        }

	mapping (address => mapping (bytes32 => bool)) public nonce;
	mapping(address => mapping(bytes32 => Validation[])) public attestations;
	/* iddigital => hash de documento => validador */



	function addVal(address _id, bytes32 _docHash,address _validatorAddr)  private {
        Validation memory validation;
        validation.validator = _validatorAddr;
        validation.addDate = block.timestamp;	    
	    attestations[_id][_docHash].push(validation);
	}

	function removeVal(address _id, bytes32 _docHash,address _validatorAddr)  private {
		for (uint i = 0; i < attestations[_id][_docHash].length; i++) {
		    if (attestations[_id][_docHash][i].validator == _validatorAddr && attestations[_id][_docHash][i].removeDate == 0) {
		        attestations[_id][_docHash][i].removeDate=block.timestamp;
		    }
		}
	}


	function addValidation(address _id, bytes32 _docHash)  public {
        addVal(_id,_docHash,msg.sender);
	}
	

	function removeValidation(address _id, bytes32 _docHash)  public {
        removeVal(_id, _docHash, msg.sender);		
	}

	function addValidationPreSigned(address _id, bytes32 _docHash,uint8 _v, bytes32 _r, bytes32 _s, bytes32 _nonce)  public {
        //"bb3d13c5": "addValidation(address,bytes32)"
        
        bytes32 messageHash = keccak256(abi.encodePacked(address(this), bytes4(0xbb3d13c5), _id, _docHash, _nonce));
        
        if (_v < 27) {
            _v += 27;
        }
        address recovered = ecrecover(messageHash, _v, _r, _s);

        if (recovered!=address(0) && !nonce[recovered][_nonce]) {
            nonce[recovered][_nonce]=true;
            addVal(_id,_docHash,recovered);
        }
	}

	function removeValidationPreSigned(address _id, bytes32 _docHash,uint8 _v, bytes32 _r, bytes32 _s, bytes32 _nonce)  public {
        //"54bec662": "removeValidation(address,bytes32)"
        bytes32 messageHash = keccak256(abi.encodePacked(address(this), bytes4(0xbb3d13c5), _id, _docHash, _nonce));
        
        if (_v < 27) {
            _v += 27;
        }
        address recovered = ecrecover(messageHash, _v, _r, _s);

        if (recovered!=address(0) && !nonce[recovered][_nonce]) {
            nonce[recovered][_nonce]=true;
            removeVal(_id, _docHash, recovered);		
		}
	}

	function getValidations(address _id, bytes32 _docHash) view public returns(address[])  {
	    uint c = 0;
		for (uint i = 0; i < attestations[_id][_docHash].length; i++) {
		    if (attestations[_id][_docHash][i].removeDate == 0) {c++;}
		}
	    
	    address[] memory activeValidations = new address[](c);

	    uint d = 0;
		for (uint ii = 0; ii < attestations[_id][_docHash].length; ii++) {
		    if (attestations[_id][_docHash][ii].removeDate == 0) {
		        activeValidations[d]=attestations[_id][_docHash][ii].validator;
		        d++;
		    }
		}

		return(activeValidations);
	}

}