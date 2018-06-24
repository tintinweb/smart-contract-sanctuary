pragma solidity ^0.4.18;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract FootCoin {
    // Vari&#225;veis p&#250;blicas do token
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    // 8 casas decimais
    uint256 public totalSupply;

    // Cria&#231;&#227;o de uma matriz com todos os saldos
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // Gera&#231;&#227;o de um evento p&#250;blico no blockchain que notificar&#225; os clientes
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Notifica&#231;&#227;o aos clientes sobre a quantidade queimada
    event Burn(address indexed from, uint256 value);

    /**
     * Fun&#231;&#227;o Constrctor
     *
     * Inicializa o contrato com n&#250;mero inicial dos tokens para o criador do contrato
     */
    function FootCoin(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Atualiza a oferta total com os valores decimais
        balanceOf[msg.sender] = totalSupply;                // Envia ao criador todos os tokens iniciais
        name = tokenName;                                   // Define o nome para fins de exibi&#231;&#227;o
        symbol = tokenSymbol;                               //  Definir o s&#237;mbolo para fins de exibi&#231;&#227;o
    }

    /**
     * Transfer&#234;ncia interna, s&#243; pode ser chamada por este contrato
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Impede a transfer&#234;ncia para o endere&#231;o 0x0
        require(_to != 0x0);
        // Verifica o saldo do remetente
        require(balanceOf[_from] >= _value);
        // Verifica overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Guarda para confer&#234;ncia futura
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtrai do remetente
        balanceOf[_from] -= _value;
        // Adiciona o mesmo valor ao destinat&#225;rio
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Verifica&#231;&#227;o usada para usar a an&#225;lise est&#225;tica do contrato, elas nunca devem falhar
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer&#234;ncia dos tokens
     *
     * Envio `_value` tokens para `_to` da sua conta
     *
     * @param _to O endere&#231;o do destinat&#225;rio
     * @param _value O valor a enviar
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    /**
     * Destrui&#231;&#227;o dos Tokens
     *
     * Remove `_value` tokens do sistema irreversivelmente
     *
     * @param _value O valor a ser queimado
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Verifique se tem o suficiente
        balanceOf[msg.sender] -= _value;            // Subtrair do remetente
        totalSupply -= _value;                      // Atualiza o totalSupply
        Burn(msg.sender, _value);
        return true;
    }
}