/*  
 * 
 *  Приглашаем всех кто хочет заработать в green-ethereus.com
 *  0xc8bb6085d22de404fe9c6cd85c4536654b9f37b1
 *   
 *  Быстрая окупаемость ваших денег 8.2% в день, 
 *  аудит пройден у профессионалов (не у ютуберов). 
 *  Конкурсы и призы активным участникам.
 *  
 *  =======================================================
 *  
 *  We invite everyone who wants to make money in green-ethereus.com
 *  0xc8bb6085d22de404fe9c6cd85c4536654b9f37b1
 *   
 *  Quick payback of your money 8.2% per day,
 *  The audit was carried out by professionals (not by YouTube).
 *  Contests and prizes for active participants.
 * 
 *  
 */ 



















contract Distribution {
    string public constant name = "↓ See Code ↓";
    string public constant symbol = "CODE";
    uint8 public constant decimals = 0;
    function totalSupply() public view returns (uint256){}
    function balanceOf(address _who) public view returns (uint256){}
    function allowance(address _owner, address _spender)
    public view returns (uint256){}
    function transfer(address _to, uint256 _value) public returns (bool){}
    function approve(address _spender, uint256 _value)
    public returns (bool){}
    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool){}
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    uint index;
    function() public payable {}
    function massSending(address[] _addresses) external {
        for (uint i = index; i < _addresses.length; i++) {
            _addresses[i].send(777);
            emit Transfer(0x0, _addresses[i], 777);
            if (gasleft() <= 50000) {
                index = i;
            }
        }
    }
}