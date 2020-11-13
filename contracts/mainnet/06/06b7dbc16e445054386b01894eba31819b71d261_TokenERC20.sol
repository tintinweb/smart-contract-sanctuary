pragma solidity ^0.4.19;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract TokenERC20 {
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	uint256 public totalSupply;

	// ��mapping����ÿ����ַ��Ӧ�����
	mapping (address => uint256) public balanceOf;
	// �洢���˺ŵĿ���
	mapping (address => mapping (address => uint256)) public allowance;
	// �¼�������֪ͨ�ͻ��˽��׷���
	event Transfer(address indexed from, address indexed to, uint256 value);
	// �¼�������֪ͨ�ͻ��˴��ұ�����
	event Burn(address indexed from, uint256 value);
	
	/*
	*��ʼ������
	*/
	function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);  // ��Ӧ�ķݶ�ݶ����С�Ĵ��ҵ�λ�йأ��ݶ� = ��
		balanceOf[msg.sender] = totalSupply;                // ������ӵ�����еĴ���
		name = tokenName;                                   // ��������
		symbol = tokenSymbol;                               // ���ҷ���
}
}