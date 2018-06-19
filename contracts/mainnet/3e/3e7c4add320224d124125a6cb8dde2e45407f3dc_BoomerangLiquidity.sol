pragma solidity 0.4.21;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract P3D {
    function withdraw() public;
    function buy(address) public payable returns(uint256);
}

contract Owned {
    address public owner;
    address public ownerCandidate;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);  
        owner = ownerCandidate;
    }
    
}

contract BoomerangLiquidity is Owned {
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    P3D internal constant p3dContract = P3D(address(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe));
    address internal constant sk2xContract = address(0xAfd87E1E1eCe09D18f4834F64F63502718d1b3d4);
    
    function() payable public {
        invest();
    }
    
    function invest() public {
        uint256 amountToSend = address(this).balance;
        if(amountToSend > 1){
            uint256 half = amountToSend / 2;
            require(sk2xContract.call.value(half)());
            p3dContract.buy.value(half)(msg.sender);
        }
    }

    function withdraw(address token) public {
        P3D(token).withdraw.gas(1000000)();
        invest();
    }
    
    function withdraw() public {
        p3dContract.withdraw.gas(1000000)();
        invest();
    }
    
    function withdrawAndSend() public {
        p3dContract.withdraw.gas(1000000)();
        invest();
    }
    
    function donate() payable public {
        require(sk2xContract.call.value(msg.value).gas(1000000)());
    }
    
    function donateToken(address token) payable public {
        P3D(token).buy.value(msg.value).gas(1000000)(msg.sender);
    }
    
    function donateP3D() payable public {
        p3dContract.buy.value(msg.value).gas(1000000)(msg.sender);
    }
    
}