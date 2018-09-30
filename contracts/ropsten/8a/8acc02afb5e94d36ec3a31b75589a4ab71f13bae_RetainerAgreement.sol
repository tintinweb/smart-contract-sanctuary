/**

Copyright Michael Rice (smartcontractslayer.com), open sourced under the MIT License.

Note that there are certain statements and opinions related to the legal effects
of certain functions and terms. These are "opinions" in the truest sense that 
they are simply the musings of the author. They have not been fully research as
of this writing nor should they ever be considered legal advice. Only a lawyer
actually looking at your unique circumstances can give you effective legal advice.

To the extent that I have time and ethically can, I&#39;m happy to try answer 
questions at michaelrice (at) protonmail (dot) com

Also, I only know this code compiles -- not sure if it would actually work as 
I hope it will.

*/
pragma solidity ^0.4.24;

contract RetainerAgreement {
	/* address of the attorney */
	address counsel = 0;
	/* address of the client who signed 
		(might need an array to hold multiples) */
	address client = 0;
	bool clientSigned = false;
	bool attorneySigned = false;

	string terms;

	bool feePaid = false;
	uint requiredFee;
	uint fee;

	/* notice how we don&#39;t assign the client at construction so we 
	   don&#39;t violate confidentiality rules */
	constructor(uint _requiredFee, string _terms) public {
		counsel = msg.sender;
		requiredFee = _requiredFee;
		terms = _terms;
	}

	function clientSign() public {
		assignClientIfNotAssigned(msg.sender);
		clientSigned = true;
		evaluateContract();
	}

	/* this is the attorney&#39;s entry point to sign. includes a check to ensure
		that only the original counsel can sign */
	function attorneySign() public {
		if (msg.sender == counsel) {
			attorneySigned = true;
		} else {
			revert();	//TODO - how to handle this more elegantly
		}
		evaluateContract();
	}

	/* notice how this will accept payment from anyone and that it will assume
		the payee is the client, unless it was previously signed by someone 
		else -- might be a ethics issue in some instances */
	function fund() public payable {
		assignClientIfNotAssigned(msg.sender);
		if (msg.value == requiredFee) {
			fee = msg.value;
		} else {
			revert();
		}
		evaluateContract();
	}

	function assignClientIfNotAssigned(address _sender) private {
		if (client == 0) {
			client = _sender;
		}
	}

	function evaluateContract() private {
		if (clientSigned && attorneySigned && feePaid) {
			counsel.transfer(fee);
		}
	}

	function returnFundsToClient() public {
		if (fee != 0) {
		    client.transfer(fee);
		}
	}

}