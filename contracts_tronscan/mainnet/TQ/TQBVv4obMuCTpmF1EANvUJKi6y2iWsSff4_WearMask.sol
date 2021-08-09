//SourceUnit: 123.sol


/*    For the sake of your health and the health of others,
     please wear a mask                                  */ 

 /*                                    
                                  dBb   
          dBB   BBBBBbb         dB               
                 BBBBBBBBb    B                  
                     BBBBBB B                     
                      BBB  B
              BBBBBBBBB  B   BBBBBBBBB
           BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
         BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
        BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
        BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
        BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
         BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
          BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
           BBBBBBBBBBBBBBBBBBBBBBBBBBBBB
             BBBBBBBBBBBB BBBBBBBBBBBB
               BBBBBBBBB   BBBBBBBBB                       */

/*    For the sake of your health and the health of others,
     please wear a mask                                  */ 

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    Wear mask coins
M         MMMMM                 MMMMMM             M         WM                                           
W                                                  W
M         M M M                  M M M             M   
W        M      M              M       M           M   
M       M        M            M         M          M    
M       M        M            M         M          M  
M        M      M              M       M           M   
M          MMMM                  MMMMM             M    
M                                                  M
WWW                                              WWM
W   WWW                                     WWW    M 
W       WWW                             WWW        M
W           WWMMMMMMMMMMMMMMMMMMMMMMMMM            M
M           M                         M            M
M           W                         W            M
M           W                         M            M
M           W                         W            M
M           M                         W            M
M           WWWWWWWWWWWWWWWWWWWWMMMMMMM            M
M         M                             M          M
M      M                                   M       M
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      */

/*  The WearmaskCoins project calls on people to wear masks.
 Stop the spread of the new coronavirus.
 And distribute masks to people on the road.
 Overcoming the new crown pneumonia is the voice of this era.
 The new coronavirus is a global pandemic with the widest impact that humans have encountered in the past 100 years. 
It spreads quickly, and the infected people die because of breathing difficulties.
 The new coronavirus is a single-stranded RNA virus.
 Prone to mutation. This poses a huge challenge to the development of vaccines.
 Currently. There were more than 4 million deaths and more than 189,350,424 infections. And it's still spreading. At present, there is no medical institution,
 scientific research unit, medical expert or government at home and abroad claiming that they can completely solve this plague.
 Make people survive this catastrophe. Mankind has reached the most dangerous time.
 This needs to rely on ourselves. This is the business of all of us. Today in history also gives each of us the responsibility to contain the virus and stop the spread.
 This is closely related to the health and life safety of each of us. Our family, relatives, and friends all hope that we can survive the plague safely.
 Everyone should be called on to let them wear masks. In the future,
 we will distribute masks on the streets. Popularize epidemic prevention knowledge.
 This is what we want to do. As long as everyone gives a little love, the world will become a better place with a little effort.     */

pragma solidity ^0.4.25;
contract Token{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public constant returns 
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract WearMask is Token {
    
    string public name;                   //���ƣ�����"My token"
    uint8 public decimals;               //����tokenʹ�õ�С�����λ�������������Ϊ3������֧��0.001��ʾ.
    string public symbol;               //token���,
    
    function WearMask(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);         // ���ó�ʼ����
        balances[msg.sender] = totalSupply; // ��ʼtoken����������Ϣ�����ߣ���Ϊ�ǹ��캯������������Ҳ�Ǻ�Լ�Ĵ�����
        
        name = _tokenName;                   
        decimals = _decimalUnits;          
        symbol = _tokenSymbol;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Ĭ��totalSupply ���ᳬ�����ֵ (2^256 - 1).
        //�������ʱ������ƽ������µ�token���ɣ������������������������쳣
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value;//����Ϣ�������˻��м�ȥtoken����_value
        balances[_to] += _value;//�������˻�����token����_value
        Transfer(msg.sender, _to, _value);//����ת�ҽ����¼�
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//�����˻�����token����_value
        balances[_from] -= _value; //֧���˻�_from��ȥtoken����_value
        allowed[_from][msg.sender] -= _value;//��Ϣ�����߿��Դ��˻�_from��ת������������_value
        Transfer(_from, _to, _value);//����ת�ҽ����¼�
        return true;
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];//����_spender��_owner��ת����token��
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}
 /*                                    
                                  dBb   
          dBB   BBBBBbb         dB               
                 BBBBBBBBb    B                  
                     BBBBBB B                     
                      BBB  B
              BBBBBBBBB  B   BBBBBBBBB
           BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
         BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
        BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
        BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
        BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
         BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
          BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
           BBBBBBBBBBBBBBBBBBBBBBBBBBBBB
             BBBBBBBBBBBB BBBBBBBBBBBB
               BBBBBBBBB   BBBBBBBBB                       */

/*    For the sake of your health and the health of others,
     please wear a mask                                  */