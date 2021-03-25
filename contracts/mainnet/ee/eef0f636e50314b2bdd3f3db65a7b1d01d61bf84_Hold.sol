/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity >=0.4.22 <0.6.0;

contract Token {
    function decimals() public view returns (uint);
    function balanceOf(address) public view returns (uint);
    function transfer(address, uint) public returns (bool);
}

contract Hold
{
    uint256 public time;
    address payable public owner;
    
    constructor () public {
        
        owner = msg.sender;
        time = now + 5 minutes;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    modifier checkTime(uint256 _time) {
        require(time < _time);
		require(_time - time <= 31536000);
        _;
    }
    
    function setTime(uint256 _time) public checkTime(_time) onlyOwner {
		time = _time;
    }
    
    function getEthereum() public onlyOwner {
        if(now < time)
		{
			revert();
        }
		else
		{
			owner.transfer(address(this).balance);
		}
    }

    function getToken(address _token) public onlyOwner {
        if(now < time)
        {
            revert();
        }
        else
        {
            Token(_token).transfer(owner, Token(_token).balanceOf(address(this)));
        }
    }
    
    function () payable external {
        
    }
}