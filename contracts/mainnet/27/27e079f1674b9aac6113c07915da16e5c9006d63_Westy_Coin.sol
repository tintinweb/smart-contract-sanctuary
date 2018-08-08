contract Westy_Coin {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint public nextMint;

    address public treasurer;
    address public entrepreneur;
    uint public secondsBetweenMints;

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event TotalSupply(uint oldAmount, uint newAmount, address mintAddress);
    event NextMint(uint nextMint);

    function WestCoin() {
        address brotherhoodAddress = 0xd7c5009bc884e39748f2326fdc35bc4e0e7f7428;
        address treasurerAddress =  0x0Bc0477dB950Eae9C8024EFbbf1D35C4C23Dd96B;
        
        uint256 brotherhoodSupply = 30000000;
        uint256 treasurySupply = 30000000;
        uint256 venerationSupply = 3000000;
        
        var tokenName = "Sample28";
        var decimalUnits = 18;
        var tokenSymbol = "SMP";
        secondsBetweenMints = 1200;//63072000;
        
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        totalSupply = 0;
        treasurer = treasurerAddress;
        entrepreneur = msg.sender;
        nextMint = block.timestamp + secondsBetweenMints;
        
        var newSupply = totalSupply + brotherhoodSupply;
        TotalSupply(totalSupply, newSupply, brotherhoodAddress);
        totalSupply = newSupply;
        balanceOf[brotherhoodAddress] = brotherhoodSupply;
        Transfer(0, brotherhoodAddress, brotherhoodSupply);
        
        newSupply = totalSupply + treasurySupply;
        TotalSupply(totalSupply, newSupply, treasurerAddress);
        totalSupply = newSupply;
        balanceOf[treasurerAddress] = treasurySupply;
        Transfer(0, treasurerAddress, treasurySupply);
        
        newSupply = totalSupply + venerationSupply;
        TotalSupply(totalSupply, newSupply, msg.sender);
        totalSupply = newSupply;
        balanceOf[msg.sender] = venerationSupply;
        Transfer(0, msg.sender, venerationSupply);
        
    }

    function transfer(address _to, uint256 _value) {
        
        if (balanceOf[msg.sender] < _value){
          revert();  
        } 
        
        if (balanceOf[_to] + _value < balanceOf[_to]){
          revert();  
        } 
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function mintToken(uint256 mintedAmount) {
        
        if(msg.sender != treasurer){
            revert();            
        }
        
        if(block.timestamp < nextMint){
            revert();
        }
        
        nextMint = block.timestamp + secondsBetweenMints;
        
        var newSupply = totalSupply + mintedAmount;
        TotalSupply(totalSupply, newSupply, treasurer);
        totalSupply = newSupply;
        balanceOf[treasurer] += mintedAmount;
        Transfer(0, treasurer, mintedAmount);
        
        var venerationMint = mintedAmount / 20;
        newSupply = totalSupply + venerationMint;
        TotalSupply(totalSupply, newSupply, msg.sender);
        totalSupply = newSupply;
        balanceOf[entrepreneur] = venerationMint;
        Transfer(0, entrepreneur, venerationMint);
        
    }
    
    function transferTreasury(address newTreasurer){

        if(msg.sender != treasurer){
            revert();
        }
        
        var balance = balanceOf[treasurer];
        balanceOf[newTreasurer] = balance;
        balanceOf[treasurer] = 0;
        Transfer(treasurer, newTreasurer, balance);
        
        treasurer = newTreasurer;
    }
   
    function treasuryBalance() returns (uint256){
        return balanceOf[treasurer];
    }
}