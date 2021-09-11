pragma solidity 0.7.5;
import './Ownable.sol';
import './IAuthorizers.sol';

contract Authorizers is Ownable, IAuthorizers {

    struct Authorizer {
        uint256 index;
        bool isAuthorizer;
    }

    // mapping(address => bool) public authorizers;
    mapping(address => Authorizer) public authorizers;
    uint256 public authorizerCount = 0;
    uint256[] vacatedAuthorizers;

    /**
    *@dev verify the signers adress of a message
    *@param message - the the message that was signed
    *@param signature - the signature
    *@return address - the address of the signer
    */
    function recoverSigner(bytes32 message, bytes calldata signature)
        public
        returns (address)
    {
        require(signature.length == 65);
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        
        return ecrecover(message, v, r, s);
    }
    /**
    *@dev get the minimum signatures required to authorize a transaction
    *@return minimum number of signatures required
    */
    function minThreshold()
        public
        returns (uint256)
    {
        if (authorizerCount <3)
            return authorizerCount;
        uint i = authorizerCount/3;
        uint r = authorizerCount%3;
        if (r>0)
            return (i*2) + r;
        else {
            return i*2;
        }
    }

    /**
    *@dev checks if parameters have the minimum number of required signatures
    *@param message - the message that is being authorized
    *@param signatures the concanted signatures
    *@return bool - true if the message has been authorized, else false
    */
    function authorize(bytes32 message, bytes calldata signatures)
        external
        override
        returns (bool) 
    {
            require(signatures.length%65 == 0, "Data not expected size");
            uint256 sigCount = signatures.length/65;
            require(sigCount>=minThreshold(), "Sig count too low");
            bool[] memory used = new bool[](authorizerCount);
            for (uint256 x=0; x<sigCount; x++) {
                //signature is x*65 starting index?
                //ends at start + 64
                uint256 index = x*65;
                uint256 end = index + 65;

                address signer = recoverSigner(message, signatures[index:end]);
                //signer is an authorizer
                require(authorizers[signer].isAuthorizer, "Message Not Authorized");
                //This is authorizer is unique 
                require(!used[authorizers[signer].index], "Duplicate Authorizer Used");
                used[authorizers[signer].index] = true;
            }
            return true;

    }

    

    /**
    *@dev generates an ethereum signature format message hash from tx param
    *@param _to - the address to mint to
    *@param _amount - the amount to mint
    *@param _txid - the txid of the ZCN chain burn tx
    *@param _nonce - the nonce used to sign the message
    */
    function message(address _to, uint256 _amount, bytes calldata _txid, uint256 _nonce)
        external
        override
        returns (bytes32) 
    {
            return prefixed(keccak256(abi.encodePacked(_to, _amount, _txid, _nonce)));

    }

    /**
    *@dev the appends the etherem signature prefix to the message hash
    *param hash - the hash of the message
    *return the prefixed message hash
    */
    function prefixed(bytes32 hash)
        internal
        pure
        returns (bytes32)
        {
            return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        }
    /**
    *@dev splits the signature into its component parts
    *param signature - the signature to split
    * returns v, r, s of the signature
    */
    function splitSignature(bytes memory signature)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return (v, r, s);
    }

    /**
    *@dev adds an authorizer to the set of authorizers 
    *@param _new_authorizer - the address of the authorizer to add
    */
    function addAuthorizers(address _new_authorizer)
        onlyOwner
        external
    {
        require(!authorizers[_new_authorizer].isAuthorizer, "Address is Already Authorizer");
        if (vacatedAuthorizers.length > 0) {
            authorizers[_new_authorizer] = Authorizer(vacatedAuthorizers[vacatedAuthorizers.length-1], true);
            vacatedAuthorizers.pop();
            authorizerCount +=1;
        } else {
            authorizers[_new_authorizer] = Authorizer(authorizerCount, true);
            authorizerCount += 1;
        }
    }
    /**
    *@dev removes an authorizer from the set of authorizers
    *@param _authorizer - the address of the authorizer to remove
    */
    function removeAuthorizers(address _authorizer)
        onlyOwner
        external
    {
        require(authorizers[_authorizer].isAuthorizer, "Address not an Authorizers");
        authorizers[_authorizer].isAuthorizer = false;
        vacatedAuthorizers.push(authorizers[_authorizer].index);        
        authorizerCount -= 1;
    }
}