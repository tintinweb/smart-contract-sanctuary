pragma solidity 0.4.24;
contract TokenMaster
{
    address public owner;
    
    uint256 public tokenCostInEth = 0.001 ether;
    uint256 public actualTokenValue = 0.00095 ether;
    uint256 public devCut = 0.00005 ether;
    
    mapping(address => uint256) public allTokens;
    uint256 public tokenSupply;
    address[] allAddresses;
    
    address devAddress = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
    
    /* ------------------------------------------------
    //              EVENTS
    ---------------------------------------------------*/ 
    event MyTokens(uint256 tokens);
    event SentTokens(bool didSend);
    
    /* ------------------------------------------------
    //              MAIN FUNCTIONS
    ---------------------------------------------------*/ 
    
    constructor() public
    {
       owner = msg.sender; 
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function buyTokens(uint256 _amount) public payable
    {
        require(_amount * tokenCostInEth == msg.value); //Make sure we are paying the right amount
        require(tokenSupply >= _amount);   //Make sure there are master tokens available (token supply)
        
        if(allTokens[msg.sender] == 0)
            allAddresses.push(msg.sender);
        
        devAddress.transfer(devCut); //5% of the cost of the token goes to devs
        
        allTokens[msg.sender] += _amount;
        tokenSupply -= _amount;
        
    }
    
    function stockSupply(uint256 _amount) public payable onlyOwner
    {
        require(_amount * tokenCostInEth == msg.value); // Make sure we are paying the right amount
        
        tokenSupply += _amount;
    }
    
    function cashOut() public 
    {
        require(allTokens[msg.sender] != 0);    //Make sure we have tokens to cash out
        
        uint256 amountToCashOut = allTokens[msg.sender];
        msg.sender.transfer(amountToCashOut * actualTokenValue);
        allTokens[msg.sender] = 0;
    }
    
    function payTokens(uint256 _amount) external 
    {
        require(_amount > 0);
        require(allTokens[msg.sender] > _amount);
        
        allTokens[msg.sender] -= _amount;
        tokenSupply += _amount;
        
        emit SentTokens(true);
    }
    
    /* ------------------------------------------------
    //              HELPER FUNCTIONS
    ---------------------------------------------------*/   
    function changeDevAddress(address _newAddress) public onlyOwner
    {
        devAddress = _newAddress;
    }
    
    //To change the token information:
    //Calculate and change the actual token cost (changeTokenCostInEth)
    //THEN, change the devCut (changeDevCut)
    //FINALLY, change the actual token value (changeActualTokenValue) using tokenCost - devCut
    //Ex. tokens will not cost 0.01 eth, and dev&#39;s take 10%
    //  changeTokenCostInEth(0.01 ether)
    //  changeDevCut(0.001 ether)  ||| this is 10% of 0.01
    //  changeActualTokenValue(0.009 ether) ||| this is 0.01 - 0.001 
    //Doing this is on a non-empty contract will screw everything up!
    //  Always EMPTY the contract FIRST (emptyContract)
    //  Then change the token information
    //  Then RESTOCK the contract!
    
    //WARNING! If you do this on a non-empty contract you can screw up the internals!!
    function changeTokenCostInEth(uint256 _costInEth) public onlyOwner
    {
        tokenCostInEth = _costInEth;
    }
    
    //WARNING! If you do this on a non-empty contract you can screw up the internals!!
    function changeActualTokenValue(uint256 _actualValue) public onlyOwner
    {
        actualTokenValue = _actualValue;
    }
    
    //WARNING! If you do this on a non-empty contract you can screw up the internals!!
    function changeDevCut(uint256 _devCut) public onlyOwner
    {
        devCut = _devCut;
    }
    
    //WARNING! This deletes ALL tokens, cashes out the contract to owner, and resets the token supply
    function emptyContract() public onlyOwner
    {
        //Cash out the contract into the owner -- THIS IS BAD
        //TODO: Change this so the owner can&#39;t cash out the contract
        //However, when the contract is reset, use the balance in the contract
        //to buy as many tokens as possible, then cash out the remaining balance
        //This loses the least amount of tokens as possible
        owner.transfer(address(this).balance);
        
        //Delete everyones tokens
        for(uint256 i = 0; i < allAddresses.length; i++)
        {
            allTokens[allAddresses[i]] = 0;
        }
        
        delete allAddresses;
        
        //Reset token supply
        tokenSupply = 0;
        
    }

    /* ------------------------------------------------
    //              GETTER FUNCTIONS
    ---------------------------------------------------*/   
    function getMyTokens() external view returns(uint256)
    {
        emit MyTokens(allTokens[msg.sender]);
        return(allTokens[msg.sender]);
    }
    
    function getMyTokensValue() view public returns(uint256)
    {
        return(allTokens[msg.sender] * tokenCostInEth);
    }
    
}