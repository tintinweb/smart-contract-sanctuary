pragma solidity 0.6.2;

/**
 * @title Dexter Capital
 * @notice Contract Publish Doc Hashes
 * @author Mayank Saxena
 */
contract Dexter {
    
    // Owner's name
    string public name ;

    // Algorithm used to Hash Docs
     string public hashingAlgo;
    
    // address of Deployer - publisher of Document_Hashes
    address public owner;
    
    // mapping of all Document_Hashes
    mapping (bytes32 => bool) public docsCheck;
    
    // kycId -> Document_Hash Array
    mapping (string => bytes32[]) private kycIdDocMap;
    
    // Document_Hash -> kycId
    mapping (bytes32 => string) private docKycIdMap;

    /**
     *  @notice Constructor to initialize owner
     *  @dev Deployer is Owner
     *  @param _name: Name of the Contract Owner
     */
    constructor ( string memory _name, string memory _hashingAlgo) public {
        owner = msg.sender;
        name = _name;
        hashingAlgo = _hashingAlgo;
    }
    
    /**
     * @dev modifier to check if the signer is owner
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Signer Not Owner");
        _;
    }

    /**
     * @notice publish doc hashes against KycId
     *  @param _kycId: key for hashes
     *  @param _hash: Array of Hashes
     *  @param _ops: type of Operation - append/replace
     */
    function docOps(string memory _kycId, bytes32[] memory _hash, uint8 _ops) public onlyOwner {
        require(_ops == 1 || _ops == 2, "Invalid Ops requested");
        if( _ops == 1){
            // append hashes
            addDocs(_kycId, _hash);
        } else if( _ops == 2){
            // replace hashes
            deleteHashes(_kycId);
            addDocs(_kycId, _hash);
        }
    }
    
    /**
     *  @notice To append docs against a KycId - Internal Function
     *  @param  _kycId: key against which docs are added
     *  @param  _hash: Array of Hashes
     */
    function addDocs(string memory _kycId, bytes32[] memory _hash) internal{
        for(uint256 i = 0; i < _hash.length; i++){
            require(docsCheck[_hash[i]] == false, "Previously Published Hash Detected");
            docsCheck[_hash[i]] = true;
            docKycIdMap[_hash[i]] = _kycId;
            kycIdDocMap[_kycId].push(_hash[i]);
        }
    }

    /**
     * @notice To delete existing hashes against a _KycId
     * @param _kycId: key against which hashes are stored
     */
    function deleteHashes(string memory _kycId) internal {
        for(uint256 i = 0; i < kycIdDocMap[_kycId].length; i++){
            bytes32 docHash = kycIdDocMap[_kycId][i];
            docsCheck[docHash] = false;
        }
        delete kycIdDocMap[_kycId];
    }
    
    /**
     * @notice Get Key(KycId) against which Hash is stored
     * @param _hash: doc hash
     */
    function getKycId(bytes32 _hash) public view returns(string memory){
        string memory kycId = docKycIdMap[_hash];
        return kycId;
    }
    
    /**
     * @notice Get Hashes against _kycId
     * @param _kycId: key against which hashes are stored
     */
    function getDocHashes(string memory _kycId) public view returns(bytes32[] memory){
        return kycIdDocMap[_kycId];
    }

    /**
     * @notice Get count of hashes against a KycId
     * @param _kycId: key against which hashes are stored
     */
    function getDocCountAgainstKycId(string memory _kycId) public view returns(uint256){
        return kycIdDocMap[_kycId].length;
    }
    
}