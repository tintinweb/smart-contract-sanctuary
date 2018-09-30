pragma solidity ^ 0.4.20;


contract Ownable {
    address public owner;
    mapping(address => bool) public admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
        admins[owner] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }
    function changeAdmin(address _newAdmin, bool _approved) onlyOwner public {
        admins[_newAdmin] = _approved;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract LoveWallet is Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function () payable public {}

    function initWallet(address _owner) public {
        owner = _owner;
    }

    function changeOwner(address _newOwner) internal {
        if (msg.sender == owner) {
            owner = _newOwner;
        }
    }

    function withdraw(uint amount) internal returns(bool success) {
        if (msg.sender == owner) {
            return owner.send(amount);
        } else {
            return false;
        }
    }

    function NextBabyIs(address _origin, uint _nonce) private pure returns (address) {
        if(_nonce == 0x00)     return address(keccak256(byte(0xd6), byte(0x94), _origin, byte(0x80)));
        if(_nonce <= 0x7f)     return address(keccak256(byte(0xd6), byte(0x94), _origin, byte(_nonce)));
        if(_nonce <= 0xff)     return address(keccak256(byte(0xd7), byte(0x94), _origin, byte(0x81), uint8(_nonce)));
        if(_nonce <= 0xffff)   return address(keccak256(byte(0xd8), byte(0x94), _origin, byte(0x82), uint16(_nonce)));
        if(_nonce <= 0xffffff) return address(keccak256(byte(0xd9), byte(0x94), _origin, byte(0x83), uint24(_nonce)));
        return address(keccak256(byte(0xda), byte(0x94), _origin, byte(0x84), uint32(_nonce))); // more than 2^32 nonces not realistic
    }
    

    function FuckYou() onlyOwner() public{
        selfdestruct(address(this));
    }


}