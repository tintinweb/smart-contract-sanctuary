pragma solidity ^0.4.25;

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c;
    }
}

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Interface {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract CodeExamples_02 {
    using SafeMath for uint256;
    
    address owner = msg.sender;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    event Send(uint256 _amount, address indexed _receiver);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function() public payable {
        
    }
    
    function wdEthereum(uint256 amount, address[] list) onlyOwner external returns (bool) {
        uint256 totalList = list.length;
        uint256 totalAmount = amount.mul(totalList);
        require(address(this).balance > totalAmount);
        
        for (uint256 i = 0; i < list.length; i++) {
            require(list[i] != address(0));
            require(list[i].send(amount));
            
            emit Send(amount, list[i]);
        }
        return true;
    }
    
    function wdToken(address _tokenContract, address _to, uint256 _wdamount) onlyOwner public returns (bool) {
        require(_to != address(0));
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 wantAmount = _wdamount;
        return token.transfer(_to, wantAmount);
    }
    
    function multisend(ERC20Interface _tokenAddr, address[] dests, uint256[] values) onlyOwner public returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
            _tokenAddr.transferFrom(msg.sender, dests[i], values[i]);
            i += 1;
        }
        return(i);
    }

}