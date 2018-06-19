pragma solidity ^0.4.18;

contract ForeignToken {
    function balanceOf(address _owner) public constant returns (uint256);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract AMLOveCoinVoting is Owned {
    address private _tokenAddress;
    bool public votingAllowed = false;

    mapping (address => bool) yaVoto;
    uint256 public votosTotales;
    uint256 public donacionCruzRoja;
    uint256 public donacionTeleton;
    uint256 public inclusionEnExchange;

    function AMLOveCoinVoting(address tokenAddress) public {
        _tokenAddress = tokenAddress;
        votingAllowed = true;
    }

    function enableVoting() onlyOwner public {
        votingAllowed = true;
    }

    function disableVoting() onlyOwner public {
        votingAllowed = false;
    }

    function vote(uint option) public {
        require(votingAllowed);
        require(option < 3);
        require(!yaVoto[msg.sender]);
        yaVoto[msg.sender] = true;
        ForeignToken token = ForeignToken(_tokenAddress);
        uint256 amount = token.balanceOf(msg.sender);
        require(amount > 0);
        votosTotales += amount;
        if (option == 0){
            donacionCruzRoja += amount;
        } else if (option == 1) {
            donacionTeleton += amount;
        } else if (option == 2) {
            inclusionEnExchange += amount;
        } else {
            assert(false);
        }        
    }
    
    function getStats() public view returns (
        uint256 _votosTotales,
        uint256 _donacionCruzRoja,
        uint256 _donacionTeleton,
        uint256 _inclusionEnExchange)
    {
        return (votosTotales, donacionCruzRoja, donacionTeleton, inclusionEnExchange);
    }
}