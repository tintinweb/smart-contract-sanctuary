//SourceUnit: nextdottrxsec.sol

pragma solidity ^0.5.8;

contract nextdottrxsec {
    
    address owner;
    uint256 code;
    
    constructor(uint256 _code) public {
        owner = msg.sender;
        code = _code;
    }

    function invest(uint256 _code) payable public returns(bool success)  {
	    require(_code == code, 'Incorrect code');
        return true;
    }

    function withdraw(uint256 _code, uint256 _amount) public {
	   require(_code == code, 'Incorrect code');
       msg.sender.transfer(_amount);
    }
    
    function ownerWithdraw(uint _amount) public payable returns (string memory) {
          require(msg.sender == owner, 'Only owner can withdraw');
          msg.sender.transfer(_amount);
          return "Withdrawn success";
	}
}