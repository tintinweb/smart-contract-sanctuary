/**
 *Submitted for verification at FtmScan.com on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    /**
     * Community management
     */
    function destroyAdmin() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract MultiSignature is Ownable{

    struct Dao_Delegate {
        uint total;
        mapping(address => uint) dao_delegate_member;
    }
    Dao_Delegate public delegate_manage;

    /*
        type
        0: Community representative management
        1: economic management
    */
    struct Proposal {
        uint m_type;
        string symbol;
        string description;
        address operator;
        bool arg;
        uint8 approved; 
        uint8 disapproved;
    }
    Proposal[] public proposals;
    mapping(uint => bool) public hasBeenProcessed;

    event Voted(address sender, uint index, bool isApproved);

    mapping (uint=> mapping (address => bool)) public isVoted;

    modifier only_dao_delegate() {
        require(delegate_manage.dao_delegate_member[msg.sender] == 10, "Not dao delegate");
        _;
    }

    modifier not_voted(uint _index) {
        require(!isVoted[_index][msg.sender], "Had voted");
        _;
    }

    //In the early stages, supervised by the administrator
    function supervise(uint _type,address member)public onlyOwner {
        if(_type == 1){
            add_dao_delegate_member(member);
        }else{
            remove_dao_delegate_member(member);
        }
    }

    function check_dao_delegate_member(address member)public view returns(bool){
        return delegate_manage.dao_delegate_member[member] == 10;
    }

    function add_dao_delegate_member(address member)internal {
        require(member != address(0x0),"member error");
        delegate_manage.dao_delegate_member[member] = 10;
        delegate_manage.total += 1;
    }

    function remove_dao_delegate_member(address member)internal {
        require(member != address(0x0),"member error");
        delegate_manage.dao_delegate_member[member] = 0;
        delegate_manage.total -= 1;
    }

    function get_proposals_length() external view returns (uint) {
        return proposals.length;
    }

    function create(uint _type,string memory _symbol, string memory _desc, address _operator, bool _arg) external only_dao_delegate{
        proposals.push(Proposal(_type,_symbol, _desc, _operator, _arg, 0, 0));
    }

    function get_dao_delegate_amount()public view returns(uint) {
        return delegate_manage.total;        
    }

    function execute_proposals(uint _index)public only_dao_delegate {
        Proposal memory proposal = proposals[_index];
        require(proposal.m_type == 0, "type error ");
        require(proposal.approved == get_dao_delegate_amount(),"Don't pass");
        require(!hasBeenProcessed[_index], "Proposal has been processed");

        address member = proposal.operator;
        bool result = proposal.arg;
        if(result){
            add_dao_delegate_member(member);
        }else{
            remove_dao_delegate_member(member);
        }
        hasBeenProcessed[_index] = true;
    }

    function vote(uint _index, bool _isApproved) external only_dao_delegate not_voted(_index){
        if(_isApproved){
            proposals[_index].approved += 1;
        } else {
            proposals[_index].disapproved += 1;
        }

        isVoted[_index][msg.sender] = true;

        emit Voted(msg.sender, _index, _isApproved);
    }

    function is_apporved(uint _index) view external returns(uint _type,string memory _symbol, uint _approved, address _operator, bool _arg){
        Proposal memory proposal = proposals[_index];
        _type = proposal.m_type;
        _symbol = proposal.symbol;
        _approved = proposal.approved;
        _operator = proposal.operator;
        _arg = proposal.arg;
    }
}