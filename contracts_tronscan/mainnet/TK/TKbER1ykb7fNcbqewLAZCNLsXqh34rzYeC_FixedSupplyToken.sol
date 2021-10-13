//SourceUnit: tt.sol

pragma solidity ^0.4.8;

  // ----------------------------------------------------------------------------------------------
  // Sample fixed supply token contract
  // Enjoy. (c) BokkyPooBah 2017. The MIT Licence.
  // ----------------------------------------------------------------------------------------------

   // ERC Token Standard #20 Interface
  // https://github.com/ethereum/EIPs/issues/20
  contract ERC20Interface {
      // ��ȡ�ܵ�֧����
      function totalSupply() constant returns (uint256 totalSupply);

      // ��ȡ������ַ�����
      function balanceOf(address _owner) constant returns (uint256 balance);

      // ��������ַ����token
      function transfer(address _to, uint256 _value) returns (bool success);

      // ��һ����ַ����һ����ַ�������
      function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

      //����_spender������˻�ת��_value�������ö�λḲ�ǿ�������ĳЩDEX������Ҫ�˹���
      function approve(address _spender, uint256 _value) returns (bool success);

      // ����_spender��Ȼ������_owner�˳����������
      function allowance(address _owner, address _spender) constant returns (uint256 remaining);

      // tokenת����ɺ����
      event Transfer(address indexed _from, address indexed _to, uint256 _value);

      // approve(address _spender, uint256 _value)���ú󴥷�
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  }

   //�̳нӿں��ʵ��
   contract FixedSupplyToken is ERC20Interface {
      string public constant symbol = "SFIS"; //��λ
      string public constant name = "SFIS Token"; //����
      uint8 public constant decimals = 6; //С������λ��
      uint256 _totalSupply = 21000000000000; //��������

      // ���ܺ�Լ��������
      address public owner;

      // ÿ���˻������
      mapping(address => uint256) balances;

      // �ʻ�����������׼�����ת����һ���ʻ����������˵�����ǿ��Ե�֪allowed[��ת�Ƶ��˻�][ת��Ǯ���˻�]
      mapping(address => mapping (address => uint256)) allowed;

      // ֻ��ͨ�����ܺ�Լ�������߲��ܵ��õķ���
      modifier onlyOwner() {
          if (msg.sender != owner) {
              throw;
          }
          _;
      }

      // ���캯��
      function FixedSupplyToken() {
          owner = msg.sender;
          balances[owner] = _totalSupply;
      }

      function totalSupply() constant returns (uint256 totalSupply) {
          totalSupply = _totalSupply;
      }

      // �ض��˻������
      function balanceOf(address _owner) constant returns (uint256 balance) {
          return balances[_owner];
      }

      // ת���������˻�
      function transfer(address _to, uint256 _amount) returns (bool success) {
          if (balances[msg.sender] >= _amount 
              && _amount > 0
              && balances[_to] + _amount > balances[_to]) {
              balances[msg.sender] -= _amount;
              balances[_to] += _amount;
              Transfer(msg.sender, _to, _amount);
              return true;
          } else {
              return false;
          }
      }

      //��һ���˻�ת�Ƶ���һ���˻���ǰ������Ҫ������ת�Ƶ����
      function transferFrom(
          address _from,
          address _to,
          uint256 _amount
      ) returns (bool success) {
          if (balances[_from] >= _amount
              && allowed[_from][msg.sender] >= _amount
              && _amount > 0
              && balances[_to] + _amount > balances[_to]) {
              balances[_from] -= _amount;
              allowed[_from][msg.sender] -= _amount;
              balances[_to] += _amount;
              Transfer(_from, _to, _amount);
              return true;
          } else {
              return false;
          }
      }

      //�����˻��ӵ�ǰ�û�ת�����Ǹ��˻�����ε��ûḲ��
      function approve(address _spender, uint256 _amount) returns (bool success) {
          allowed[msg.sender][_spender] = _amount;
          Approval(msg.sender, _spender, _amount);
          return true;
      }

      //���ر�����ת�Ƶ��������
      function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
      }
  }