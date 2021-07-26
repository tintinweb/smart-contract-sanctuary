/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

// File: contracts/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() internal returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/EContract.sol

pragma solidity ^0.5.0;


contract EContract is Ownable {
     uint256 contractId;
     mapping (string => bool) _contractUriExists;
     mapping (uint256 => string) public _contract;
     mapping (uint256 => string) public _contractSender;
     struct signature {
         bool assign;
         bool signAccepted;
         bool signRejected;
         uint256 expiry;
     }
    mapping (uint256 => mapping (bytes32 => signature)) _signaturesReviewer;
    mapping (uint256 => mapping (bytes32 => signature)) _signaturesReciever;
    mapping (uint256 => uint256) public _reviewTotalCount;
    mapping (uint256 => uint256) public _receiverTotalCount;
    mapping (uint256 => bytes32[]) _reviewedBy;
    mapping (uint256 => bytes32[]) _signedBy;

    constructor () public {
         contractId = 0; 
         _owner = msg.sender;
    }

    function startContractSignatures(string memory _contractUri, string memory sender, bytes32[] memory receivers, bytes32[] memory reviewers, uint256 _type) onlyOwner public {
       _contractUriExists[_contractUri] = true;
        if(_type == 1){
            _contract[++contractId] = _contractUri;
            _contractSender[contractId] = sender;
            _reviewTotalCount[contractId] = reviewers.length;
            for(uint256 i = 0; i < reviewers.length; i++){
                _signaturesReviewer[contractId][reviewers[i]].assign = true;
                _signaturesReviewer[contractId][reviewers[i]].expiry = now + (2 * 1 hours);
            }
            _reviewTotalCount[contractId] = receivers.length;
            for(uint256 i = 0; i < receivers.length; i++){
                _signaturesReviewer[contractId][receivers[i]].assign = true;
                _signaturesReviewer[contractId][receivers[i]].expiry = now + (60 * 1 days);
            }
        }else {
            for(uint256 i = 0; i < receivers.length; i++){
            _contract[++contractId] = _contractUri;
            _contractSender[contractId] = sender;
            _reviewTotalCount[contractId] = reviewers.length;
            for(uint256 j = 0; j < reviewers.length; j++){
                _signaturesReviewer[contractId][reviewers[j]].assign = true;
                _signaturesReviewer[contractId][reviewers[j]].expiry = now + (2 * 1 hours);
            }
                _reviewTotalCount[contractId] = 1;
                _signaturesReviewer[contractId][receivers[i]].assign = true;
                _signaturesReviewer[contractId][receivers[i]].expiry = now + (60 * 1 days);
            }
        }
    }

    function reviewerSignature(bytes32 reviewer,uint256 _contractId, bool accepted) onlyOwner public {
        signature storage _reviewer = _signaturesReviewer[_contractId][reviewer];
        require(_reviewedBy[contractId].length < _reviewTotalCount[_contractId], "E-104");
        require(_reviewer.assign, "E-101");
        require(!_reviewer.signAccepted && !_reviewer.signRejected, "E-102");
        require(now <= _reviewer.expiry, "E-103");
        _reviewer.signAccepted= accepted;
        _reviewer.signRejected= !accepted;
        _reviewedBy[contractId].push(reviewer);
    }

    function receiverSignature(bytes32 reciever,uint256 _contractId, bool accepted) onlyOwner public {
        signature storage _reciever = _signaturesReviewer[_contractId][reciever];
        require(_reviewedBy[contractId].length == _reviewTotalCount[_contractId], "E-105");
        require(_signedBy[contractId].length <  _receiverTotalCount[_contractId], "E-109");
        require(_reciever.assign, "E-106");
        require(!_reciever.signAccepted && !_reciever.signRejected, "E-107");
        require(now <= _reciever.expiry, "E-108");
        _reciever.signAccepted= accepted;
        _reciever.signRejected= !accepted;
        _signedBy[contractId].push(reciever);
    }

    function getContractOwner(uint256 _contractId) public view returns(string memory) {
        return _contractSender[_contractId];
    }

    function getReviewedBy(uint256 _contractId) public view returns(bytes32[] memory) {
        return _reviewedBy[contractId];
    }

    function getSignedBy(uint256 _contractId) public view returns(bytes32[] memory) {
        return _signedBy[contractId];
    }


}