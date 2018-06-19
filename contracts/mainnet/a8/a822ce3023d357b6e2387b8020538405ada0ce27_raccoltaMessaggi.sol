pragma solidity ^0.4.21;

contract raccoltaMessaggi {
    
    event nuovoMsg (
        address mittente,
        string testo
    );
    
    struct messaggio {
        address mittente;
        string testo;
    }
    
    address internal proprietario;
    mapping (uint256 => messaggio) internal messaggi;
    uint256 internal msgTotali = 0;
    
    function raccoltaMessaggi() public {
        proprietario = msg.sender;
    }
    
    function aggiungiMsg(string _msg) public returns (uint256) {
        emit nuovoMsg(msg.sender, _msg);
        messaggi[msgTotali] = messaggio(msg.sender, _msg);
        msgTotali++;
        return msgTotali-1;
    }
    
    function totaleMsg() public view returns (uint256) {
        return msgTotali;
    }
    
    function leggiMsg(uint256 _numeroMsg) public view returns (address _mittente, string _testo) {
        _testo = messaggi[_numeroMsg].testo;
        _mittente = messaggi[_numeroMsg].mittente;
    }
    
    function kill() public {
        if (proprietario == msg.sender)
            selfdestruct(proprietario);
    }
}