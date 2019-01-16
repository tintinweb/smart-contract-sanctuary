pragma solidity ^0.4.20;

// made by <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f2969d9f979c9b919db2909e9d91999c9b8adc919d9f">[email&#160;protected]</a>

contract VotacaoAbcripto {

    struct Eleitor {
        uint peso;
        bool votado;
        uint8 voto;
        address delegar;
    }
    struct Proposta {
        uint contagemVotos;
    }

    address secretario;
    mapping(address => Eleitor) eleitores;
    Proposta[] propostas;

    /// Criar uma nova votacao com $(_numPropostas) diferentes propostas.
    function VotacaoAbcripto(uint8 _numPropostas) public {
        secretario = msg.sender;
        eleitores[secretario].peso = 1;
        propostas.length = _numPropostas;
    }

    /// Dar $(toEleitor) o direito ao voto nesta vota&#231;&#227;o.
    /// Pode ser chamada apenas pelo $(secretario).
    function darDireitoAoVoto(address toEleitor) public {
        if (msg.sender != secretario || eleitores[toEleitor].votado) return;
        eleitores[toEleitor].peso = 1;
    }

    /// Delegar o seu voto para outro eleitor $(to).
    function delegar(address to) public {
        Eleitor storage sender = eleitores[msg.sender];
        if (sender.votado) return;
        while (eleitores[to].delegar != address(0) && eleitores[to].delegar != msg.sender)
            to = eleitores[to].delegar;
        if (to == msg.sender) return;
        sender.votado = true;
        sender.delegar = to;
        Eleitor storage delegarPara = eleitores[to];
        if (delegarPara.votado)
            propostas[delegarPara.voto].contagemVotos += sender.peso;
        else
            delegarPara.peso += sender.peso;
    }

    /// Dar um &#250;nico voto &#224; proposta $(paraProposta).
    function voto(uint8 paraProposta) public {
        Eleitor storage sender = eleitores[msg.sender];
        if (sender.votado || paraProposta >= propostas.length) return;
        sender.votado = true;
        sender.voto = paraProposta;
        propostas[paraProposta].contagemVotos += sender.peso;
    }

    function propostaVencedora() public constant returns (uint8 _propostaVencedora) {
        uint256 contagemVotosVencedor = 0;
        for (uint8 prop = 0; prop < propostas.length; prop++)
            if (propostas[prop].contagemVotos > contagemVotosVencedor) {
                contagemVotosVencedor = propostas[prop].contagemVotos;
                _propostaVencedora = prop;
            }
    }
}