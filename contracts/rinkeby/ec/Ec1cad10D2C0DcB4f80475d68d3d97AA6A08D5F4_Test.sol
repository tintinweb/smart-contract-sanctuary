contract Test {
    
    function payme() payable public {}
    
    function withdraw() public {
    	payable(msg.sender).transfer(address(this).balance);
	}
}

