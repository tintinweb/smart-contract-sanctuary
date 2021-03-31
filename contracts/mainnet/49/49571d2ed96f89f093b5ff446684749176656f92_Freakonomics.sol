/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.3;


struct FreakerBirtherInfo {
	uint256 creationSalt;
	uint8 fortune;
}


interface IEtherFreaker {
	function numTokens() external view returns (uint128 total);
	function birthCertificates(uint256 index) external view returns (uint256 cost);
	function middlePrice() external view returns (uint256);
	function birthTo(address payable to) payable external;
}


contract FreakerBirther {
	IEtherFreaker internal _etherFreaker = IEtherFreaker(
		0x3A275655586A049FE860Be867D10cdae2Ffc0f33
	);

	constructor(address payable owner) payable {
		_etherFreaker.birthTo{value: msg.value}(owner);
		selfdestruct(owner);
	}
}


contract Freakonomics {
	IEtherFreaker internal _etherFreaker = IEtherFreaker(
		0x3A275655586A049FE860Be867D10cdae2Ffc0f33
	);

	address payable immutable owner;
	bytes32 immutable initCodeHash;

	constructor() {
		owner = payable(tx.origin);
		initCodeHash = keccak256(abi.encodePacked(
			type(FreakerBirther).creationCode,
			bytes12(0),
			tx.origin
		));
	}

	function birthingCost() public view returns (uint256 totalCost) {
		uint256 totalCertificates = _etherFreaker.numTokens() - 8;
		if (totalCertificates % 2 == 0) {
			totalCost = (
				2 * (1 + _etherFreaker.birthCertificates(totalCertificates / 2) * 1005 / 1000) +
				2 * (1 + _etherFreaker.birthCertificates(1 + totalCertificates / 2) * 1005 / 1000) +
				2 * (1 + _etherFreaker.birthCertificates(2 + totalCertificates / 2) * 1005 / 1000) +
				2 * (1 + _etherFreaker.birthCertificates(3 + totalCertificates / 2) * 1005 / 1000)
			);
		} else {
			totalCost = (
				1 + _etherFreaker.birthCertificates(totalCertificates / 2) * 1005 / 1000 +
				2 * (1 + _etherFreaker.birthCertificates(1 + totalCertificates / 2) * 1005 / 1000) +
				2 * (1 + _etherFreaker.birthCertificates(2 + totalCertificates / 2) * 1005 / 1000) +
				2 * (1 + _etherFreaker.birthCertificates(3 + totalCertificates / 2) * 1005 / 1000) +
				1 + _etherFreaker.birthCertificates(4 + totalCertificates / 2) * 1005 / 1000
			);
		}
	}

	function findSet(uint8 minimumFortune) public view returns (FreakerBirtherInfo[8] memory freakers, uint256 totalCost, uint256 gasSpent) {
		uint256 initialGas = gasleft();
		uint256 foundFreakers = 0;
		uint256 creationSalt = 0;
		address caller;
		uint8 speciesDie;
		uint8 species;
		uint8 fortune;
		uint256 cost;

		while (foundFreakers < 8) {
			creationSalt++;
			caller = _findCaller(creationSalt);
			speciesDie = uint8(_randomishIntLessThan("species", caller, 20));
	        species = (
	         (speciesDie < 1 ? 0 :
	          (speciesDie < 3 ? 1 :
	           (speciesDie < 5 ? 2 :
	            (speciesDie < 8 ? 3 :
	             (speciesDie < 11 ? 4 :
	              (speciesDie < 15 ? 5 :
	               (speciesDie < 19 ? 6 : 7))))))));
        	fortune = uint8(
        		_randomishIntLessThan(
        			"fortune", caller, species < 3 ? 30 : 10
        		) + 1
        	);

        	if (freakers[species].fortune < fortune) {
        		if (
        			freakers[species].creationSalt == 0 &&
        			fortune >= minimumFortune
        		) {
        			foundFreakers++;
        		}

        		freakers[species].creationSalt = creationSalt;
        		freakers[species].fortune = fortune;
        	}
		}

		for (uint256 i = 0; i < 8; i++) {
			cost = (_etherFreaker.middlePrice() * 1005 / 1000) + 1;
			totalCost += cost;
		}

		gasSpent = initialGas - gasleft();
	}

	function birthSet(uint8 minimumFortune) public payable {
		require(msg.value >= birthingCost(), "Not enough ether provided");

		FreakerBirtherInfo[8] memory freakers;
		uint256 foundFreakers = 0;
		uint256 creationSalt = 0;
		address caller;
		uint8 speciesDie;
		uint8 species;
		uint8 fortune;
		uint256 cost;

		while (foundFreakers < 8) {
			creationSalt++;
			caller = _findCaller(creationSalt);
			speciesDie = uint8(_randomishIntLessThan("species", caller, 20));
	        species = (
	         (speciesDie < 1 ? 0 :
	          (speciesDie < 3 ? 1 :
	           (speciesDie < 5 ? 2 :
	            (speciesDie < 8 ? 3 :
	             (speciesDie < 11 ? 4 :
	              (speciesDie < 15 ? 5 :
	               (speciesDie < 19 ? 6 : 7))))))));
        	fortune = uint8(
        		_randomishIntLessThan(
        			"fortune", caller, species < 3 ? 30 : 10
        		) + 1
        	);

        	if (freakers[species].fortune < fortune) {
        		if (
        			freakers[species].creationSalt == 0 &&
        			fortune >= minimumFortune
        		) {
        			foundFreakers++;
        		}

        		freakers[species].creationSalt = creationSalt;
        		freakers[species].fortune = fortune;
        	}
		}

		for (uint256 i = 0; i < 8; i++) {
			cost = (_etherFreaker.middlePrice() * 1005 / 1000) + 1;
			new FreakerBirther{salt: bytes32(freakers[i].creationSalt), value: cost}(owner);
		}

		(bool ok,) = owner.call{value: address(this).balance}("");
	    if (!ok) {
	        assembly {
	            returndatacopy(0, 0, returndatasize())
	            revert(0, returndatasize())
	        }
	    }
	}

	function _findCaller(uint256 creationSalt) internal view returns (address) {
      return address(            // derive the target deployment address.
        uint160(                 // downcast to match the address type.
          uint256(               // cast to uint to truncate upper digits.
            keccak256(           // compute CREATE2 hash using 4 inputs.
              abi.encodePacked(  // pack all inputs to the hash together.
                bytes1(0xff),    // pass in the control character.
                address(this),   // pass in the address of this contract.
                creationSalt,    // pass in the salt from above.
                initCodeHash     // pass in hash of contract creation code.
              )
            )
          )
        )
      );
	}

    function _randomishIntLessThan(bytes32 salt, address caller, uint256 n) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, caller, salt))) % n;
    }
}