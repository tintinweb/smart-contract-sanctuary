pragma solidity ^0.4.24;

contract demo1 {
    
    
    mapping(address => uint256) private playerVault;
   
    modifier hasEarnings()
    {
        require(playerVault[msg.sender] > 0);
        _;
    }
    
    function myEarnings()
        external
        view
        hasEarnings
        returns(uint256)
    {
        return playerVault[msg.sender];
    }
    
    function withdraw()
        external
        hasEarnings
    {

        uint256 amount = playerVault[msg.sender];
        playerVault[msg.sender] = 0;

        msg.sender.transfer(amount);
    }
    
   

     function deposit() public payable returns (uint) {
        // Use &#39;require&#39; to test user inputs, &#39;assert&#39; for internal invariants
        // Here we are making sure that there isn&#39;t an overflow issue
        require((playerVault[msg.sender] + msg.value) >= playerVault[msg.sender]);

        playerVault[msg.sender] += msg.value;
        // no "this." or "self." required with state variable
        // all values set to data type&#39;s initial value by default

        return playerVault[msg.sender];
    }
    
}