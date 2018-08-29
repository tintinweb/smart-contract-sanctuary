contract Coin {
    // La palabra clave "public" hace que dichas variables
    // puedan ser le&#237;das desde fuera.
    address public minter;
    mapping (address => uint) public balances;

    // Los eventos permiten a los clientes ligeros reaccionar
    // de forma eficiente a los cambios.
    event Sent(address from, address to, uint amount);

    // Este es el constructor cuyo c&#243;digo
    // s&#243;lo se ejecutar&#225; cuando se cree el contrato.
    function Coin() {
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) {
        if (msg.sender != minter) return;
        balances[receiver] += amount;
    }

    function send(address receiver, uint amount) {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        Sent(msg.sender, receiver, amount);
    }
}