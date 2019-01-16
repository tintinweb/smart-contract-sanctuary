contract SimpleContract { 
    function getEther() public { 
      msg.sender.transfer(address(this).balance);    
    }
}