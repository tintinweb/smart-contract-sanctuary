/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Vote is Ownable{
    struct candidate{
        string name;
        string party;
    }

    struct voter{
        string name;
        string nic;
        uint256 refNo;
        string province;
    }

    address[] public candidates;
    uint public candidatesCount;
    mapping(address=>uint256) public votes;
    mapping(address=>candidate) public candidateData;
    mapping(address=> voter) public voterData;
    mapping(address=>bool) public isApproved;
    mapping(address=>bool) public voted;
    

    constructor(){

    }

    modifier isVoter(address voterAddress){
        require(isApproved[voterAddress]==true,'Not Approved!');
        _;
    }

    modifier isVoted(address voterAddress){
        require(voted[voterAddress]==false,'Already voted!');
        _;
    }

    function addCandidate(address candidateAddress,string memory name,string memory party) external onlyOwner returns(bool){
        candidates.push(candidateAddress);
        candidateData[candidateAddress].name = name;
        candidateData[candidateAddress].party = party;
        candidatesCount +=1;
        return true;
    }

    function addVoter(address voterAddress,string memory name, string memory nic,uint256 refNo,string memory province) external onlyOwner returns(bool){
        isApproved[voterAddress]=true;
        voterData[voterAddress].name = name;
        voterData[voterAddress].nic = nic;
        voterData[voterAddress].refNo = refNo;
        voterData[voterAddress].province = province;
        return true;
    }

    function vote(address candidateAddress) external isVoted(msg.sender) isVoter(msg.sender) returns(bool){
        votes[candidateAddress]+=1;
        voted[msg.sender]=true;
        return true;
    }
    
    function getCandidates() public view returns(address[] memory registeredCandidates){
        registeredCandidates = candidates;
    }
}