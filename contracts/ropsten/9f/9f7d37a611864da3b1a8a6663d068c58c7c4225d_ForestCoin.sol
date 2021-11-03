pragma solidity ^0.5.0;

import "./ForestContract.sol";

contract ForestCoin {
    
    // carteira do fundo onde será enviado os valores em ethereum
    address investmentFund;

    // mapeamento de carteiras
    mapping(address => uint) wallets;
    address[] listWallets;
    
    // mapeamento de contratos
    mapping(address => ForestContract) contracts;
    ForestContract[] listContracts;                 
    
    // ------------------------------------------------------------------------------------
    
    constructor(uint initialCoins) public {
        // sempre quem irá executar o contrato de ICO será o fundo de investimento
        investmentFund = msg.sender;
    
        // define a quantidade máxima de forest tokens que serão transacionados (ICO)
        // inicializa a quantidade de tokens existentes na carteira do fundo
        wallets[msg.sender] = initialCoins;
        listWallets.push(msg.sender);
    }
    
    // ------------------------------------------------------------------------------------
    
    function getAccountBalance(address wallet) public view returns(uint) {
        // qualquer um pode ver o saldo de uma carteira
        return wallets[wallet];
    }
    
    function transferBalance(address from, address to, uint value) private {
        // obtemos quantos tokens existem na carteira de origem
        uint tokens = this.getAccountBalance(from);
        
        // não podemos transferir forest se não houver tokens suficientes
        require(
            value <= tokens,
            "Não há tokens suficientes para executar essa função"
        );
        
        // transfere o forest token
        wallets[from] -= value;
        wallets[to] += value;
    }
    
    // ------------------------------------------------------------------------------------

    function mockCompulsoryDonateCryptos() public {
        require(
            msg.sender == investmentFund,
            "Essa função só pode ser executada pelo fundo de investimento"
        );
        
        // a doação compulsória das criptomoedas para o contrato é feita em todos os contratos
        for (uint i = 0; i < listWallets.length; i++) {
            address from = listWallets[i];
            
            // ignoramos se for a carteira do fundo
            // não faz sentido fazer uma doação para si própria
            if (from == investmentFund) {
                continue;
            }
        
            // obtêm o saldo disponível
            uint balance = this.getAccountBalance(from);
        
            // retira uma porcentagem que será doada
            uint percentage = 10;
            uint amountDonated = balance * percentage / 100;
        
            // doa esse valor ao fundo
            // retirando dessa i-ésima carteira e enviando ao fundo
            transferBalance(from, investmentFund, amountDonated);
        }
    }
    
    // ------------------------------------------------------------------------------------

    function walletExists(address wallet) public view returns(bool) {
        for (uint i = 0; i < listWallets.length; i++) {
            if (listWallets[i] == wallet) {
                return true;
            }
        }
        
        return false;
    }

    function createWallet(address wallet) public {
        if (!walletExists(wallet)) {
            // inicializamos essa carteira com 0 tokens
            wallets[wallet] = 0;
            
            // adicionamos a carteira na lista de carteiras
            listWallets.push(wallet);
        }
    }

    // ~> Comprar Criptomoeda
    function buyForest(uint value) public {
        // cria a carteira se ela não houver ainda
        createWallet(msg.sender);
        
        // se permitido, faz a transferência dos tokens
        transferBalance(investmentFund, msg.sender, value);
    }

    function sendForestToWallet(address destination, uint value) public {
        // realiza a transferência do valor a uma carteira
        transferBalance(msg.sender, destination, value);
    }
    
    // ------------------------------------------------------------------------------------
    
    function signContract(address landOwner) public returns (address) {
        require(
           msg.sender == investmentFund,
           "Apenas o fundo de investimento pode criar um contrato"
        );

        // criamos um novo contrato
        ForestContract newContract = new ForestContract(landOwner); 
        address contractAddress = address(newContract);
        
        // adicionamos esse contrato aos contratos
        contracts[contractAddress] = newContract;
        
        // precisamos adicionar esse contrato à uma lista para facilitar
        // na hora de selecionar um contrato aleatório a ser investido
        listContracts.push(newContract);
        
        // endereço do contrato que foi criado
        return contractAddress;
    }
    
    // ~> Investir em Projeto (Fundo)
    function getRandomContract() private view returns(ForestContract) {
        // obtemos a posição que está o contrato que será investido
        // essa obtenção de índice é realizada de maneira aleatória/arbitrária
        uint indexContract = uint(
            keccak256(abi.encodePacked(block.difficulty, now, listContracts))
        ) % listContracts.length;
        
        return listContracts[indexContract];
    }

    function donateToContract(address investor, address contractAddress, uint value) public {
        // obtemos quantos tokens o investidor tem
        uint tokens = getAccountBalance(investor);
        
        require(
            value <= tokens,
            "Não há tokens suficientes para executar essa função"
        );
        
        // obtemos o contrato que será doado o valor
        ForestContract _contract = contracts[contractAddress];
        
        // faz o saque da carteira do investidor e joga na do contrato
        wallets[investor] -= value;
        _contract.invest(investor, value);
    }

    // ~> Doar para o fundo
    function donateToFund(uint value) public returns(address) {
        // nesse caso, o investidor donatará ao fundo, para qualquer contrato
        // então selecionamos um contrato arbitrariamente da lista de contratos
        ForestContract _contract = getRandomContract();
        
        // obtemos o endereço desse contrato
        address contractAddress = address(_contract);
        
        // executamos a doação à esse contrato
        donateToContract(msg.sender, contractAddress, value);
        
        return contractAddress;
    }
    
    // ------------------------------------------------------------------------------------
    
    function getContractIsActive(address contractAddress) public view returns(bool) {
        // obtemos o contrato pelo mapeamento de endereço ~> contrato
        ForestContract _contract = contracts[contractAddress];
        
        // obtemos se o contrato está em execução
        return _contract.isContractRunning();
    }
    
    function getContractBalance(address contractAddress) public view returns(uint) {
        // obtemos o contrato pelo mapeamento de endereço ~> contrato
        ForestContract _contract = contracts[contractAddress];
        
        // obtemos o saldo atual do contrato
        return _contract.getContractBalance();
    }
    
    // ------------------------------------------------------------------------------------
    
    // ~> Pagar beneficiário
    function payForestContractLandOwner(ForestContract _contract) private {
        // obtemos o saldo atual do contrato
        uint tokens = _contract.getContractBalance();
        
        // obtemos o endereço da carteira do dono de terra do contrato
        address _landowner = _contract.getContractLandOwner();
        
        // fazemos a retirada do valor
        _contract.withdrawalContractBalance(tokens);
        
        // adicionamos o valor à carteira do dono de terra
        wallets[_landowner] += tokens;
    }
    
    // ~> Retornar valor ao Fundo de Preservação
    function returnForestContractInvestment(ForestContract _contract) private {
        // obtemos o saldo atual do contrato
        uint tokens = _contract.getContractBalance();
        
        // fazemos a retirada do valor
        _contract.withdrawalContractBalance(tokens);
        
        // retornamos o valor arrecadado à carteira do fundo
        wallets[investmentFund] += tokens;
    }
    
    // ~> Consultar Oráculo
    function processForestContract(address contractAddress) public returns(bool) {
        // obtemos o contrato
        ForestContract _contract = contracts[contractAddress];
        
        // obtemos a carteira do dono de terra desse contrato
        address _landowner = _contract.getContractLandOwner();
        
        // essa função deve ser executada pelo dono de terra
        require(
            msg.sender == _landowner,
            "Apenas o dono do contrato pode processar um contrato"
        );
        require(
            _contract.isContractRunning(),
            "O contrato já foi finalizado. Não pode ser processado"
        );
        
        // consulta o oráculo
        _contract.mockConsultOracle();
        
        if (_contract.isContractAccomplished()) {
            // se conseguiu, então pagamos o dono do contrato
            payForestContractLandOwner(_contract);
        } else if (_contract.isContractCancelled()) {
            // se não conseguiu, retornamos o valor para o fundo
            returnForestContractInvestment(_contract);
        }
        
        // retorna se o contrato foi cumprido ou não
        return _contract.isContractAccomplished();
    }
    
}