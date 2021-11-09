/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

pragma solidity 0.8.0;

library SafeMath {

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract multiSend {
    
    
     event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
        mapping (address => uint256) public balanceOf;
    
      function transfer(address _to, uint256 _value) public {
        require(_to != address(this));
        require(_to != address(0), "Cannot use zero address");
        require(_value > 0, "Cannot use zero value");

        require (balanceOf[msg.sender] >= _value, "Balance not enough");         // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to], "Overflow" );        // Check for overflows
        
        uint previousBalances = balanceOf[msg.sender] + balanceOf[_to];          
        
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);               // Add the same to the recipient
        
        emit Transfer(msg.sender, _to, _value);                                  // Notify anyone listening that this transfer took place
        
        assert(balanceOf[msg.sender] + balanceOf[_to] == previousBalances);
    }
    
     function multiTransfer(address[] memory _receivers, uint256 _value) public returns (bool success) {
        uint256 toSend = _value * 10**18;

        require(_receivers.length <= 200, "Too many recipients");

        for(uint256 i = 0; i < _receivers.length; i++) {
            transfer(_receivers[i], toSend);
        }
}

}