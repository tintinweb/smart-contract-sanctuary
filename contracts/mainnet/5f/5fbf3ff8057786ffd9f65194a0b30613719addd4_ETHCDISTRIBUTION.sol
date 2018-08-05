pragma solidity 0.4.24;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

}

interface token {
    function transfer(address to, uint tokens) external;
    function balanceOf(address tokenOwner) external returns(uint balance);
}




contract ETHCDISTRIBUTION is Owned{
    address public ETCHaddress;
    token public  rewardToken;
    //uint public ContractTokenBalance = rewardToken.balanceOf(this);
    
    
    constructor() public{
    ETCHaddress = 0x673F2F89840b93D2b2b0100f9E35e5CE371Faf54;
    rewardToken = token(ETCHaddress);
    
    }
    
    function() public payable{
        uint tokensToBeSent = msg.value * 2000;
        require(rewardToken.balanceOf(this)>= tokensToBeSent);
        rewardToken.transfer(msg.sender, tokensToBeSent);
        uint amount = address(this).balance;
        owner.transfer(amount);
        
    }
    
}