pragma solidity 0.5.11;

interface IRaffle {

    function mint(address _user, uint256 _amount) external;

}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MultiMintRaffle is Ownable {

    IRaffle public raffle ;
    constructor(IRaffle _raffle) public {
        raffle = IRaffle(_raffle);
    }


    function mint(address[] memory _users, uint256[] memory _amounts) public onlyOwner {
        require(_users.length == _amounts.length, "input length missmatch");
        for(uint i = 0; i < _users.length; i++) {
            raffle.mint(_users[i], _amounts[i]);
        }
        
    }

}