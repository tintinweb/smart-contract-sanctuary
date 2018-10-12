pragma solidity 0.4.25;

interface COSS {
  function sendTokens(address _destination, address _token, uint256 _amount) public;
  function sendEther(address _destination, uint256 _amount) payable public;
}

contract FSAContract{
    address owner = 0xc17cbf9917ca13d5263a8d4069e566be23db1b09;
    address cossContract = 0x9e96604445ec19ffed9a5e8dd7b50a29c899a10c;
 
     modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function sendTokens(address _destination, address _token, uint256 _amount) public onlyOwner {
         COSS(cossContract).sendTokens(_destination,_token,_amount);
    }
    
    function sendEther(address _destination, uint256 _amount) payable public onlyOwner {
        COSS(cossContract).sendEther(_destination,_amount);
    }
}