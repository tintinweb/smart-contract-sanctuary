pragma solidity ^0.4.20;

contract st4ck {
    address[][] public wereld;
    address public owner = 0x5372260584003e8Ae3a24E9dF09fa96037a04c2b;
    mapping(address => uint) public balance; 
    bool public rowQuiter = false;
    
    function st4ckCount() public view returns (uint) {
        return wereld.length;
    }
    
    function st4ckHeight(uint x) public view returns (uint) {
        return wereld[x].length;
    }
    
    function price(uint y) public pure returns(uint)   {
        return 0.005 ether * (uint(2)**y);
    }
    
    function setRowQuiter(bool newValue) public {
        require(msg.sender == owner);
        rowQuiter = newValue;
    }
    
    function buyBlock(uint x, uint y) public payable {
        balance[msg.sender] += msg.value;
        require(balance[msg.sender] >= price(y));
        balance[msg.sender] -= price(y);
        if(x == wereld.length) {
            require(rowQuiter == false);
            wereld.length++;
        }
        else if (x > wereld.length) {
            revert();
        }
        require(y == wereld[x].length);
        wereld[x].push(msg.sender);
            
        if(y == 0) {
            balance[owner] += price(y);
        }
        else {
            balance[wereld[x][y - 1]] += price(y) * 99 / 100;
            balance[owner] += price(y) * 1 / 100;
        }  
        
    }
    
    function withdraw() public {
        msg.sender.transfer(balance[msg.sender]);
        balance[msg.sender] = 0;
    }
}