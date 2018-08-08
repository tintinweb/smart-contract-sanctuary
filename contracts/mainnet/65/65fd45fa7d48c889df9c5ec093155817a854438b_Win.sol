contract Win {
    string public name;
    string public symbol;
    uint8 public decimals = 5;  
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    

    constructor() public {
        totalSupply = 2100000000 * 10 ** uint256(decimals); 
        uint256 creatBalance=10000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] =creatBalance;
        address boss=0xe64d668c2d8aba2eab3e33d64e5b8d0327bae583;
        balanceOf[boss]=totalSupply-creatBalance;
        name = "WIN";                                  
        symbol = "WIN";                               
    }

    

    function transfer(address _to, uint256 _value) public returns (bool success){
         require(_to != 0x0);
         require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint previousBalances = balanceOf[msg.sender] + balanceOf[_to];
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        assert(balanceOf[msg.sender] + balanceOf[_to] == previousBalances);
        return true;
    }

    


    
}