/*
**   Signed Digital Asset - A contract to store signatures of digital assets.
**   Martin Stellnberger
**   05-Dec-2016
**   martinstellnberger.co
**
**   This software is distributed in the hope that it will be useful,
**   but WITHOUT ANY WARRANTY; without even the implied warranty of
**   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**   GNU lesser General Public License for more details.
**   <http://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.2;

contract SignedDigitalAsset {
    // The owner of the contract
    address owner = msg.sender;
    // Name of the institution (for reference purposes only)
    string public institution;
    // Storage for linking the signatures to the digital fingerprints
	mapping (bytes32 => string) fingerprintSignatureMapping;

    // Event functionality
	event SignatureAdded(string digitalFingerprint, string signature, uint256 timestamp);
    // Modifier restricting only the owner of this contract to perform certain operations
    modifier isOwner() { if (msg.sender != owner) throw; _; }

    // Constructor of the Signed Digital Asset contract
    function SignedDigitalAsset(string _institution) {
        institution = _institution;
    }
    // Adds a new signature and links it to its corresponding digital fingerprint
	function addSignature(string digitalFingerprint, string signature)
        isOwner {
        // Add signature to the mapping
        fingerprintSignatureMapping[sha3(digitalFingerprint)] = signature;
        // Broadcast the token added event
        SignatureAdded(digitalFingerprint, signature, now);
	}

    // Removes a signature from this contract
	function removeSignature(string digitalFingerprint)
        isOwner {
        // Replaces an existing Signature with empty string
		fingerprintSignatureMapping[sha3(digitalFingerprint)] = "";
	}

    // Returns the corresponding signature for a specified digital fingerprint
	function getSignature(string digitalFingerprint) constant returns(string){
		return fingerprintSignatureMapping[sha3(digitalFingerprint)];
	}

    // Removes the entire contract from the blockchain and invalidates all signatures
    function removeSdaContract()
        isOwner {
        selfdestruct(owner);
    }
}