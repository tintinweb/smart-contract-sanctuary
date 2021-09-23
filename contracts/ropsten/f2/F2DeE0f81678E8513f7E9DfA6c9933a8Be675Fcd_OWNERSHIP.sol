/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

contract OWNERSHIP {
    address public Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        Owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function transferOwnership(address _address) public virtual onlyOwner {
        emit OwnershipTransferred(Owner, _address);
        Owner = _address;
    }
    modifier onlyOwner() {
        require(msg.sender == Owner, "Ownable: caller is not the owner");
        _;
    }                                                                                           
}