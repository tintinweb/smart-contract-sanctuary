/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Accessible is Ownable {
    mapping(address => bool) private access;
    
    constructor() {
        access[msg.sender] = true;
    }
    
     modifier hasAccess() {
        require(checkAccess(msg.sender));
        _;
    }
    
    function checkAccess(address sender) public view returns (bool) {
        if (access[sender] == true) 
            return true;
        return false;
    }
    
    function removeAccess(address addr) public hasAccess returns (bool success) {
        access[addr] = false;
        return true;
    }
    
    function addAccess(address addr) public hasAccess returns (bool) {
        access[addr] = true;
        return true;
    }
}